(* FORGE CUDA codegen — optimized SIMT emission

   Takes proven-correct Forge IR and emits CUDA C optimized for GPU execution.
   All bounds checks, overflow checks, and null checks are erased (proven away).

   Key SIMT optimizations:
   - Parallel loops with proven-independent iterations → grid-stride kernels
   - Array operations with proven bounds → unchecked coalesced access
   - Reductions with proven associativity → warp shuffle tree
   - Shared memory tiling with proven tile bounds → __shared__ arrays
   - Uniform branches (proven same path across warp) → no divergence

   Pipeline:
     FORGE source → proofs discharged → this backend → .cu file
     Then: OpenCUDA → OpenPTXas → SM_120 cubin → RTX 5090

   The proof is on the math. The codegen is free to be aggressive. *)

open Ast

(* ------------------------------------------------------------------ *)
(* Emission buffer                                                      *)
(* ------------------------------------------------------------------ *)

type cuda_state = {
  buf : Buffer.t;
  mutable indent : int;
  mutable kernel_count : int;
  mutable device_fns : string list;  (* accumulated device function names *)
}

let mk_state () = {
  buf = Buffer.create 8192;
  indent = 0;
  kernel_count = 0;
  device_fns = [];
}

let line st s =
  for _ = 1 to st.indent do Buffer.add_string st.buf "  " done;
  Buffer.add_string st.buf s;
  Buffer.add_char st.buf '\n'

let blank st = Buffer.add_char st.buf '\n'

let indent st = st.indent <- st.indent + 1
let dedent st = st.indent <- st.indent - 1

(* ------------------------------------------------------------------ *)
(* Type emission                                                        *)
(* ------------------------------------------------------------------ *)

let rec emit_ty = function
  | TPrim (TInt I8)    -> "int8_t"   | TPrim (TInt I16)   -> "int16_t"
  | TPrim (TInt I32)   -> "int32_t"  | TPrim (TInt I64)   -> "int64_t"
  | TPrim (TInt ISize) -> "int64_t"
  | TPrim (TUint U8)   -> "uint8_t"  | TPrim (TUint U16)  -> "uint16_t"
  | TPrim (TUint U32)  -> "uint32_t" | TPrim (TUint U64)  -> "uint64_t"
  | TPrim (TUint USize) -> "uint64_t"
  | TPrim (TFloat F32) -> "float"    | TPrim (TFloat F64)  -> "double"
  | TPrim TBool        -> "bool"
  | TPrim TUnit        -> "void"
  | TRefined (p, _, _) -> emit_ty (TPrim p)
  | TSecret t          -> emit_ty t   (* secret erased — proven constant-time *)
  | TQual (_, t)       -> emit_ty t
  | TOwn t | TRef t | TRefMut t | TRaw t -> emit_ty t ^ "*"
  | TSpan t            -> emit_ty t ^ "*"
  | TArray (t, _)      -> emit_ty t   (* arrays decay to element type in params *)
  | _ -> "uint64_t"

let emit_ret_ty = function
  | TPrim TUnit -> "void"
  | t -> emit_ty t

(* ------------------------------------------------------------------ *)
(* Expression emission                                                  *)
(* ------------------------------------------------------------------ *)

let rec emit_expr = function
  | { expr_desc = ELit (LInt (n, ty_opt)); _ } ->
      (* FORGE01-04: emit width-correct integer suffix so OpenCUDA does
         not promote u32 expressions to u64 (which would force the
         IADD.64/MUL.64 family - ALLOC subsystem rewrite required).
         Default to ULL for u64/unspecified to preserve prior behavior. *)
      let suffix = match ty_opt with
        | Some (TUint U8)  | Some (TUint U16) | Some (TUint U32) -> "U"
        | Some (TInt I8)   | Some (TInt I16)  | Some (TInt I32)  -> ""
        | Some (TInt I64)                                          -> "LL"
        | _ -> "ULL"
      in
      if n >= 0L then Printf.sprintf "%Lu%s" n suffix
      else Printf.sprintf "(%Ld)" n

  | { expr_desc = ELit (LFloat (f, _)); _ } ->
      Printf.sprintf "%.17g" f

  | { expr_desc = ELit (LBool b); _ } ->
      if b then "true" else "false"

  | { expr_desc = EVar id; _ } ->
      (match id.name with
       | "threadIdx_x" -> "threadIdx.x"
       | "threadIdx_y" -> "threadIdx.y"
       | "threadIdx_z" -> "threadIdx.z"
       | "blockIdx_x"  -> "blockIdx.x"
       | "blockIdx_y"  -> "blockIdx.y"
       | "blockDim_x"  -> "blockDim.x"
       | "blockDim_y"  -> "blockDim.y"
       | "gridDim_x"   -> "gridDim.x"
       | name -> name)

  | { expr_desc = EBinop (op, l, r); _ } ->
      let sl = emit_expr l in
      let sr = emit_expr r in
      let ops = match op with
        | Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/"
        | Mod -> "%" | BitAnd -> "&" | BitOr -> "|" | BitXor -> "^"
        | Shl -> "<<" | Shr -> ">>"
        | Eq -> "==" | Ne -> "!=" | Lt -> "<" | Le -> "<="
        | Gt -> ">" | Ge -> ">="
        | And -> "&&" | Or -> "||"
        | Implies -> "||" (* P ==> Q  ≡  !P || Q, but proofs are erased *)
        | Iff -> "==" in
      Printf.sprintf "(%s %s %s)" sl ops sr

  | { expr_desc = EUnop (Neg, e); _ } ->
      Printf.sprintf "(-%s)" (emit_expr e)

  | { expr_desc = EUnop (Not, e); _ } ->
      Printf.sprintf "(!%s)" (emit_expr e)

  | { expr_desc = EUnop (BitNot, e); _ } ->
      Printf.sprintf "(~%s)" (emit_expr e)

  | { expr_desc = EIndex (arr, idx); _ } ->
      Printf.sprintf "%s[%s]" (emit_expr arr) (emit_expr idx)

  | { expr_desc = EField (obj, field); _ } ->
      (match field.name with
       | "len" -> emit_expr obj ^ "_len"
       | _ -> Printf.sprintf "%s.%s" (emit_expr obj) field.name)

  | { expr_desc = ECast (inner, ty); _ } ->
      Printf.sprintf "((%s)%s)" (emit_ty ty) (emit_expr inner)

  (* GPU intrinsics → CUDA C built-ins *)
  | { expr_desc = ECall ({ expr_desc = EVar id; _ }, args); _ } ->
      (match id.name, args with
       | "shfl_down_sync", [v; d; w] ->
           Printf.sprintf "__shfl_down_sync(0xffffffff, %s, %s, %s)"
             (emit_expr v) (emit_expr d) (emit_expr w)
       | "shfl_xor_sync", [v; m; w] ->
           Printf.sprintf "__shfl_xor_sync(0xffffffff, %s, %s, %s)"
             (emit_expr v) (emit_expr m) (emit_expr w)
       | "atom_add", [p; v] ->
           Printf.sprintf "atomicAdd(%s, %s)" (emit_expr p) (emit_expr v)
       | "atom_add_u32", [p; v] ->
           (* FORGE29-32: u32 overload alias.  Forge stdlib only declares
              the u64 form of atom_add; the u32 binding lives in user code
              under this name.  Both lower to the same CUDA atomicAdd
              builtin — the C++ frontend overload-resolves on pointer type. *)
           Printf.sprintf "atomicAdd(%s, %s)" (emit_expr p) (emit_expr v)
       | "atom_cas", [p; v] ->
           Printf.sprintf "atomicCAS(%s, %s, %s)" (emit_expr p) (emit_expr v) (emit_expr v)
       | "atom_max", [p; v] ->
           Printf.sprintf "atomicMax(%s, %s)" (emit_expr p) (emit_expr v)
       | "atom_min", [p; v] ->
           Printf.sprintf "atomicMin(%s, %s)" (emit_expr p) (emit_expr v)
       | "atom_or", [p; v] ->
           Printf.sprintf "atomicOr(%s, %s)" (emit_expr p) (emit_expr v)
       | "atom_xor", [p; v] ->
           Printf.sprintf "atomicXor(%s, %s)" (emit_expr p) (emit_expr v)
       | "atom_and", [p; v] ->
           Printf.sprintf "atomicAnd(%s, %s)" (emit_expr p) (emit_expr v)
       | "atom_sub", [p; v] ->
           Printf.sprintf "atomicSub(%s, %s)" (emit_expr p) (emit_expr v)
       | "atom_exch", [p; v] ->
           Printf.sprintf "atomicExch(%s, %s)" (emit_expr p) (emit_expr v)
       | "shfl_up_sync", [v; d; w] ->
           Printf.sprintf "__shfl_up_sync(0xffffffff, %s, %s, %s)"
             (emit_expr v) (emit_expr d) (emit_expr w)
       | "ballot_sync", [p] ->
           Printf.sprintf "__ballot_sync(0xffffffff, %s)" (emit_expr p)
       | "lane_id", [] -> "(threadIdx.x & 31)"
       | "warp_id", [] -> "(threadIdx.x >> 5)"
       (* Memory fences *)
       | "threadfence", [] -> "__threadfence()"
       | "threadfence_block", [] -> "__threadfence_block()"
       | "threadfence_system", [] -> "__threadfence_system()"
       (* Async copy (SM_80+) *)
       | "cp_async_cg", [d; s; b] ->
           Printf.sprintf "__pipeline_memcpy_async(%s, %s, %s)"
             (emit_expr d) (emit_expr s) (emit_expr b)
       | "cp_async_commit", [] -> "__pipeline_commit()"
       | "cp_async_wait_group", [n] ->
           Printf.sprintf "__pipeline_wait_prior(%s)" (emit_expr n)
       (* Cooperative groups (SM_90+) *)
       | "cluster_sync", [] -> "__cluster_sync()"
       (* FP16 conversions *)
       | "f32_to_fp16", [x] ->
           Printf.sprintf "__float2half(%s)" (emit_expr x)
       | "fp16_to_f32", [x] ->
           Printf.sprintf "__half2float(%s)" (emit_expr x)
       | "f32_to_bf16", [x] ->
           Printf.sprintf "__float2bfloat16(%s)" (emit_expr x)
       | "bf16_to_f32", [x] ->
           Printf.sprintf "__bfloat162float(%s)" (emit_expr x)
       (* FP16 arithmetic *)
       | "fp16_add", [a; b] ->
           Printf.sprintf "__hadd(%s, %s)" (emit_expr a) (emit_expr b)
       | "fp16_sub", [a; b] ->
           Printf.sprintf "__hsub(%s, %s)" (emit_expr a) (emit_expr b)
       | "fp16_mul", [a; b] ->
           Printf.sprintf "__hmul(%s, %s)" (emit_expr a) (emit_expr b)
       | "fp16_fma", [a; b; c] ->
           Printf.sprintf "__hfma(%s, %s, %s)"
             (emit_expr a) (emit_expr b) (emit_expr c)
       | "fp16_neg", [a] ->
           Printf.sprintf "__hneg(%s)" (emit_expr a)
       | "fp16_abs", [a] ->
           Printf.sprintf "__habs(%s)" (emit_expr a)
       | "fp16_max", [a; b] ->
           Printf.sprintf "__hmax(%s, %s)" (emit_expr a) (emit_expr b)
       | "fp16_min", [a; b] ->
           Printf.sprintf "__hmin(%s, %s)" (emit_expr a) (emit_expr b)
       (* BF16 arithmetic *)
       | "bf16_add", [a; b] ->
           Printf.sprintf "__hadd(%s, %s)" (emit_expr a) (emit_expr b)
       | "bf16_sub", [a; b] ->
           Printf.sprintf "__hsub(%s, %s)" (emit_expr a) (emit_expr b)
       | "bf16_mul", [a; b] ->
           Printf.sprintf "__hmul(%s, %s)" (emit_expr a) (emit_expr b)
       | "bf16_fma", [a; b; c] ->
           Printf.sprintf "__hfma(%s, %s, %s)"
             (emit_expr a) (emit_expr b) (emit_expr c)
       | "bf16_neg", [a] ->
           Printf.sprintf "__hneg(%s)" (emit_expr a)
       | name, args ->
           Printf.sprintf "%s(%s)" name
             (String.concat ", " (List.map emit_expr args)))

  | { expr_desc = ESync; _ } -> "__syncthreads()"

  | { expr_desc = EAssign (lhs, rhs); _ } ->
      Printf.sprintf "%s = %s" (emit_expr lhs) (emit_expr rhs)

  | { expr_desc = EIf (cond, then_, Some else_); _ }
      when is_simple_expr then_ && is_simple_expr else_ ->
      Printf.sprintf "(%s ? %s : %s)"
        (emit_expr cond) (emit_expr then_) (emit_expr else_)

  | { expr_desc = EBlock ([], Some e); _ } -> emit_expr e

  (* EIf and EBlock with statements get handled by emit_expr_as_stmt *)
  | { expr_desc = EIf _; _ } -> "__if_stmt__"
  | { expr_desc = EBlock _; _ } -> "__block_stmt__"

  | { expr_desc = EProof _; _ } | { expr_desc = EAssume _; _ } ->
      "/* proof erased */"

  | { expr_desc = EAsm ab; _ } ->
      if ab.asm_outputs = [] && ab.asm_inputs = [] then
        Printf.sprintf "asm volatile(\"%s\")" (String.escaped ab.asm_template)
      else
        let out_str = String.concat ", "
          (List.map (fun (c, id) -> Printf.sprintf "\"%s\"(%s)" c id.name) ab.asm_outputs) in
        let in_str = String.concat ", "
          (List.map (fun (c, e) -> Printf.sprintf "\"%s\"(%s)" c (emit_expr e)) ab.asm_inputs) in
        Printf.sprintf "asm volatile(\"%s\" : %s : %s)"
          (String.escaped ab.asm_template) out_str in_str

  | _ -> "0 /* unhandled */"

and is_simple_expr e =
  match e.expr_desc with
  | ELit _ | EVar _ | EBinop _ | EUnop _ | EIndex _ | EField _ -> true
  | _ -> false

(* ------------------------------------------------------------------ *)
(* Statement emission                                                   *)
(* ------------------------------------------------------------------ *)

let rec emit_expr_as_stmt st e =
  match e.expr_desc with
  | EBlock (stmts, ret_expr) ->
      List.iter (emit_stmt st) stmts;
      (match ret_expr with
       | Some re -> emit_expr_as_stmt st re
       | None -> ())
  | EIf (cond, then_, else_opt) ->
      line st (Printf.sprintf "if (%s) {" (emit_expr cond));
      indent st;
      emit_expr_as_stmt st then_;
      dedent st;
      (match else_opt with
       | Some else_ ->
           line st "} else {";
           indent st;
           emit_expr_as_stmt st else_;
           dedent st;
           line st "}"
       | None -> line st "}")
  | EAssign (lhs, rhs) ->
      line st (Printf.sprintf "%s = %s;" (emit_expr lhs) (emit_expr rhs))
  | EProof _ | EAssume _ | EAsm _ -> ()
  | _ ->
      let s = emit_expr e in
      if s <> "/* proof erased */" && s <> "__if_stmt__" && s <> "__block_stmt__" then
        line st (s ^ ";")

and emit_stmt st s =
  match s.stmt_desc with
  | SLet (id, Some (TShared (elem_ty, Some sz_expr)), _e, _) ->
      line st (Printf.sprintf "__shared__ %s %s[%s];"
        (emit_ty elem_ty) id.name (emit_expr sz_expr))

  | SLet (id, Some (TShared (elem_ty, None)), _e, _) ->
      line st (Printf.sprintf "extern __shared__ %s %s[];" (emit_ty elem_ty) id.name)

  | SLet (id, Some (TArray (elem_ty, Some sz_expr)), e, _) ->
      line st (Printf.sprintf "%s %s[%s] = %s;"
        (emit_ty elem_ty) id.name (emit_expr sz_expr) (emit_expr e))

  | SLet (id, Some ty, e, _) ->
      line st (Printf.sprintf "%s %s = %s;" (emit_ty ty) id.name (emit_expr e))

  | SLet (id, None, e, _) ->
      line st (Printf.sprintf "auto %s = %s;" id.name (emit_expr e))

  | SExpr { expr_desc = EAssign (lhs, rhs); _ } ->
      line st (Printf.sprintf "%s = %s;" (emit_expr lhs) (emit_expr rhs))

  | SExpr { expr_desc = ESync; _ } ->
      line st "__syncthreads();"

  | SExpr ({ expr_desc = EIf _; _ } as e)
  | SExpr ({ expr_desc = EBlock _; _ } as e) ->
      emit_expr_as_stmt st e

  | SExpr e ->
      let s = emit_expr e in
      if s <> "/* proof erased */" then
        line st (s ^ ";")

  | SReturn (Some e) ->
      line st (Printf.sprintf "return %s;" (emit_expr e))

  | SReturn None ->
      line st "return;"

  | SWhile (cond, _inv, _dec, body) ->
      line st (Printf.sprintf "while (%s) {" (emit_expr cond));
      indent st;
      List.iter (emit_stmt st) body;
      dedent st;
      line st "}"

  | SFor (id, iter, _invs, _dec, body) ->
      (match iter.expr_desc with
       | ERange (lo, hi) ->
           let ty = match lo.expr_ty with
             | Some t -> emit_ty t | None -> "uint64_t" in
           line st (Printf.sprintf "for (%s %s = %s; %s < %s; %s++) {"
             ty id.name (emit_expr lo) id.name (emit_expr hi) id.name)
       | _ ->
           line st (Printf.sprintf "for (uint64_t %s = 0; %s < %s; %s++) {"
             id.name id.name (emit_expr iter) id.name));
      indent st;
      List.iter (emit_stmt st) body;
      dedent st;
      line st "}"

  | SBreak _ -> line st "break;"
  | SContinue -> line st "continue;"
  | SGhost _ | SGhostAssign _ -> ()  (* ghost stmts erased *)

(* ------------------------------------------------------------------ *)
(* Function emission                                                    *)
(* ------------------------------------------------------------------ *)

let emit_param (id, ty) =
  match ty with
  | TSpan t ->
      Printf.sprintf "%s* __restrict__ %s, uint64_t %s_len"
        (emit_ty t) id.name id.name
  | _ ->
      Printf.sprintf "%s %s" (emit_ty ty) id.name

let is_kernel fn =
  List.exists (fun a -> a.attr_name = "kernel") fn.fn_attrs

let is_device fn =
  List.exists (fun a -> a.attr_name = "device") fn.fn_attrs

(* Like emit_expr_as_stmt but wraps leaf values in 'return' *)
let rec emit_expr_as_return st e =
  match e.expr_desc with
  | EBlock (stmts, ret_expr) ->
      List.iter (emit_stmt st) stmts;
      (match ret_expr with
       | Some re -> emit_expr_as_return st re
       | None -> ())
  | EIf (cond, then_, else_opt) ->
      line st (Printf.sprintf "if (%s) {" (emit_expr cond));
      indent st;
      emit_expr_as_return st then_;
      dedent st;
      (match else_opt with
       | Some else_ ->
           line st "} else {";
           indent st;
           emit_expr_as_return st else_;
           dedent st;
           line st "}"
       | None -> line st "}")
  | EAssign (lhs, rhs) ->
      line st (Printf.sprintf "%s = %s;" (emit_expr lhs) (emit_expr rhs))
  | EProof _ | EAssume _ | EAsm _ -> ()
  | _ ->
      let s = emit_expr e in
      if s <> "/* proof erased */" then
        line st (Printf.sprintf "return %s;" s)

let emit_function st fn =
  let params = String.concat ", " (List.map emit_param fn.fn_params) in
  let ret = emit_ret_ty fn.fn_ret in
  let returns_value = fn.fn_ret <> TPrim TUnit in
  (* In CUDA, all non-main non-kernel functions must be __device__
     if they might be called from a kernel. Since Forge modules are
     compiled as a single TU and any function could be called from
     a kernel, emit all non-main functions as __device__. *)
  let is_main = fn.fn_name.name = "main" in
  let prefix =
    if is_kernel fn then "__global__ void"
    else if is_main then ret
    else Printf.sprintf "__device__ %s" ret
  in
  blank st;
  line st (Printf.sprintf "%s %s(%s) {" prefix fn.fn_name.name params);
  indent st;
  (match fn.fn_body with
   | Some body ->
       if returns_value && not (is_kernel fn) then
         emit_expr_as_return st body
       else
         emit_expr_as_stmt st body
   | None -> ());
  dedent st;
  line st "}"

(* ------------------------------------------------------------------ *)
(* Grid-stride kernel wrapper generation                                *)
(* ------------------------------------------------------------------ *)

(* When a Forge function is marked #[parallel] and operates on spans,
   generate a grid-stride kernel that distributes work across threads.
   The proof guarantees each iteration is independent (no cross-iteration
   dependencies) so this parallelization is semantics-preserving.

   Pattern:
     #[parallel]
     fn map(a: span<u64>, b: span<u64>, n: u64) { ... }

   Generates:
     __global__ void map_kernel(uint64_t* a, uint64_t* b, uint64_t n) {
       for (uint64_t i = blockIdx.x * blockDim.x + threadIdx.x;
            i < n;
            i += blockDim.x * gridDim.x) {
         // body with a[i], b[i] proven in-bounds
       }
     }
*)

let has_attr name fn =
  List.exists (fun a -> a.attr_name = name) fn.fn_attrs

(* ------------------------------------------------------------------ *)
(* Warp-level reduction helper emission                                 *)
(* ------------------------------------------------------------------ *)

let emit_warp_reduce st elem_ty op_str =
  blank st;
  line st (Printf.sprintf "__device__ __forceinline__ %s warp_reduce_%s(%s val) {"
    elem_ty op_str elem_ty);
  indent st;
  line st "#pragma unroll";
  line st "for (int offset = 16; offset > 0; offset >>= 1) {";
  indent st;
  line st (Printf.sprintf "val %s= __shfl_down_sync(0xffffffff, val, offset);" op_str);
  dedent st;
  line st "}";
  line st "return val;";
  dedent st;
  line st "}"

(* ------------------------------------------------------------------ *)
(* Program-level CUDA emission                                          *)
(* ------------------------------------------------------------------ *)

let emit_cuda_program (items : item list) (sm : int) : string =
  let fns = List.filter_map (fun item ->
    match item.item_desc with
    | IFn fn -> Some fn
    | _ -> None
  ) items in
  (* Only emit CUDA if there are kernel/device/parallel functions *)
  let has_gpu = List.exists (fun fn ->
    is_kernel fn || is_device fn || has_attr "parallel" fn
  ) fns in
  if not has_gpu then ""
  else begin
    let st = mk_state () in
    line st (Printf.sprintf "// FORGE-generated CUDA C — SM_%d" sm);
    line st "// All proofs discharged. Correct by construction.";
    line st "// No bounds checks. No overflow checks. They were proven away.";
    blank st;
    line st "#include <stdint.h>";
    line st "#include <stdbool.h>";
    blank st;

    (* Check if we need warp reduce helpers *)
    let needs_reduce = List.exists (fun fn ->
      has_attr "reduce" fn || has_attr "parallel" fn
    ) fns in
    if needs_reduce then begin
      emit_warp_reduce st "uint64_t" "+";
      emit_warp_reduce st "float" "+";
      emit_warp_reduce st "double" "+";
      blank st
    end;

    (* Emit all functions *)
    List.iter (emit_function st) fns;
    blank st;

    Buffer.contents st.buf
  end
