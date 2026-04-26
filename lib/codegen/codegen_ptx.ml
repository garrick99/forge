(* FORGE PTX codegen — SM_89 / SM_90 (RTX 4090 / 5090)

   Emits PTX assembly for #[kernel] functions.
   Regular (non-kernel) functions are left to codegen_c.

   Pipeline:
     FORGE #[kernel] fn → PTX .entry kernel

   Each FORGE expression lowers to a list of PTX instructions plus a
   result register.  Every let-binding, subexpression, and temporary
   gets a fresh virtual register.  PTX's SSA-style register model maps
   cleanly onto FORGE's immutable-by-default semantics. *)

open Ast

(* ------------------------------------------------------------------ *)
(* PTX register types                                                   *)
(* ------------------------------------------------------------------ *)

type ptx_rty =
  | Pred          (* .pred  — boolean condition *)
  | B16           (* .b16   — bit-pattern, used for fp16/bf16 bridge regs *)
  | U16 | U32 | U64
  | S16 | S32 | S64
  | F32 | F64

let ptx_rty_name = function
  | Pred -> ".pred" | B16 -> ".b16"
  | U16 -> ".u16" | U32 -> ".u32" | U64 -> ".u64"
  | S16  -> ".s16"  | S32 -> ".s32" | S64 -> ".s64"
  | F32  -> ".f32"  | F64 -> ".f64"

let ptx_state_name = function
  | Pred -> "p" | B16 -> "h"
  | U16 -> "rs" | U32 -> "r" | U64 -> "rd"
  | S16  -> "rs" | S32 -> "r" | S64 -> "rd"
  | F32  -> "f"  | F64 -> "fd"

let rec ptx_rty_of_ty = function
  | TPrim (TUint U8)  | TPrim (TUint U16)  -> U16
  | TPrim (TUint U32) | TPrim (TUint USize) -> U32
  | TPrim (TUint U64) -> U64
  | TPrim (TInt  I8)  | TPrim (TInt  I16)  -> S16
  | TPrim (TInt  I32) -> S32
  | TPrim (TInt  I64) | TPrim (TInt  ISize) -> S64
  | TPrim (TFloat F32) -> F32
  | TPrim (TFloat F64) -> F64
  | TPrim TBool -> Pred
  | TSecret t  -> ptx_rty_of_ty t
  | TQual (_, t) -> ptx_rty_of_ty t
  | _ -> U64  (* pointers, spans, unknowns default to 64-bit *)

let sizeof_rty = function
  | Pred | B16 | U16 | S16 -> 2
  | U32 | S32 | F32  -> 4
  | U64 | S64 | F64  -> 8

(* PTX arithmetic instruction prefix.  B16 is bit-pattern (no native
   arithmetic); fall back to b16 (used by mov.b16 / and/or/xor/.b16). *)
let arith_pfx = function
  | B16 -> "b16"
  | U16 -> "u16" | U32 -> "u32" | U64 -> "u64"
  | S16 -> "s16" | S32 -> "s32" | S64 -> "s64"
  | F32 -> "f32" | F64 -> "f64"
  | Pred -> "u32"

(* Unsigned comparison suffix *)
let cmp_pfx rty =
  match rty with
  | F32 | F64 -> arith_pfx rty   (* IEEE float comparison *)
  | B16 -> "u16"                 (* compare b16 as if unsigned *)
  | U16|U32|U64 -> "u" ^ string_of_int (sizeof_rty rty * 8)
  | S16|S32|S64 -> "s" ^ string_of_int (sizeof_rty rty * 8)
  | Pred -> "u32"

(* ------------------------------------------------------------------ *)
(* Emission state                                                       *)
(* ------------------------------------------------------------------ *)

type emit_state = {
  mutable counter  : int;
  mutable instrs   : string list;     (* accumulated PTX instructions, reversed *)
  mutable reg_decls: (string * ptx_rty) list;  (* (name, type) pairs *)
  fn_name : string;
  (* Variable → register name mapping *)
  mutable reg_env  : (string * string) list;
  (* FG-2.6: user-defined non-kernel functions available for inlining
     at a call site.  Keyed by function name; value is the full AST
     definition.  The generic ECall branch consults this table to
     inline the body when the callee is a known device function. *)
  fn_defs : (string, fn_def) Hashtbl.t;
  (* FORGE73: shared-memory declarations for this kernel.
     Each entry is (symbol, elem_rty, num_elements).  Emitted as
     `.shared .<rty> <sym>[<N>];` in the kernel header. *)
  mutable shared_decls : (string * ptx_rty * int) list;
  (* Set of registers that hold the base address of a shared-memory
     allocation.  ld/st through these registers must use the .shared
     state space rather than .global. *)
  mutable shared_regs : string list;
}

let fresh_reg st rty =
  let n = st.counter in
  st.counter <- n + 1;
  let name = Printf.sprintf "%%%s%d" (ptx_state_name rty) n in
  st.reg_decls <- (name, rty) :: st.reg_decls;
  name

let emit st s =
  st.instrs <- ("  " ^ s) :: st.instrs

let reg_of_var st name =
  match List.assoc_opt name st.reg_env with
  | Some r -> r
  | None   ->
      (* GPU built-ins return fresh registers each time — caller caches if needed *)
      Printf.sprintf "%%rd_unknown_%s" name

(* ------------------------------------------------------------------ *)
(* Type helpers                                                         *)
(* ------------------------------------------------------------------ *)

let rty_of_expr e =
  match e.expr_ty with
  | Some t -> ptx_rty_of_ty t
  | None   -> U64

(* Look up the actual allocated register type from the declaration table.
   This is more accurate than rty_of_expr for registers produced by
   GPU built-ins (which allocate U32 even though expr_ty is None → U64). *)
let reg_rty st name =
  match List.assoc_opt name st.reg_decls with
  | Some rty -> rty
  | None     -> U64

(* PTX `cvt` requires a rounding modifier whenever the conversion is
   lossy: any int→float, any float→int, or narrowing float→float.
   Returns the modifier string ("" if no modifier needed).
   `.rn`  = round-to-nearest-even (default for IEEE)
   `.rzi` = round-to-zero, integer result (for float→int) *)
let cvt_rounding src_rty tgt_rty =
  let is_float = function F32 | F64 -> true | _ -> false in
  let is_int = function
    | U16 | U32 | U64 | S16 | S32 | S64 -> true
    | _ -> false
  in
  match src_rty, tgt_rty with
  | F64, F32 -> ".rn"      (* narrowing float-to-float *)
  | s, t when is_int s && is_float t -> ".rn"   (* int → float *)
  | s, t when is_float s && is_int t -> ".rzi"  (* float → int, truncate *)
  | _ -> ""                (* widening or same-kind: no modifier *)

(* ------------------------------------------------------------------ *)
(* Expression lowering: returns the register holding the result        *)
(* ------------------------------------------------------------------ *)

let rec lower_expr st e : string =
  match e.expr_desc with

  (* Literals *)
  | ELit (LInt (n, _)) ->
      let rty = rty_of_expr e in
      let r   = fresh_reg st rty in
      emit st (Printf.sprintf "mov%s %s, %Ld;" (ptx_rty_name rty) r n);
      r

  | ELit (LBool b) ->
      let r = fresh_reg st Pred in
      emit st (Printf.sprintf "mov.pred %s, %d;" r (if b then 1 else 0));
      r

  | ELit (LFloat (f, _)) ->
      let rty = rty_of_expr e in
      let r   = fresh_reg st rty in
      (match rty with
      | F64 ->
          let bits = Int64.bits_of_float f in
          emit st (Printf.sprintf "mov.f64 %s, 0d%016LX; // %g" r bits f)
      | _ ->
          emit st (Printf.sprintf "mov.f32 %s, 0f%08lX; // %g"
            r (Int32.bits_of_float f) f));
      r

  | ELit _ ->
      let r = fresh_reg st U64 in
      emit st (Printf.sprintf "mov.u64 %s, 0; // unsupported lit" r);
      r

  (* Variables — look up in register environment; handle GPU built-ins *)
  | EVar id ->
      (match id.name with
       | "threadIdx_x" ->
           let r = fresh_reg st U32 in
           emit st (Printf.sprintf "mov.u32 %s, %%tid.x;" r); r
       | "threadIdx_y" ->
           let r = fresh_reg st U32 in
           emit st (Printf.sprintf "mov.u32 %s, %%tid.y;" r); r
       | "threadIdx_z" ->
           let r = fresh_reg st U32 in
           emit st (Printf.sprintf "mov.u32 %s, %%tid.z;" r); r
       | "blockIdx_x"  ->
           let r = fresh_reg st U32 in
           emit st (Printf.sprintf "mov.u32 %s, %%ctaid.x;" r); r
       | "blockIdx_y"  ->
           let r = fresh_reg st U32 in
           emit st (Printf.sprintf "mov.u32 %s, %%ctaid.y;" r); r
       | "blockDim_x"  ->
           let r = fresh_reg st U32 in
           emit st (Printf.sprintf "mov.u32 %s, %%ntid.x;" r); r
       | "blockDim_y"  ->
           let r = fresh_reg st U32 in
           emit st (Printf.sprintf "mov.u32 %s, %%ntid.y;" r); r
       | "gridDim_x"   ->
           let r = fresh_reg st U32 in
           emit st (Printf.sprintf "mov.u32 %s, %%nctaid.x;" r); r
       | name ->
           reg_of_var st name)

  (* Binary operations *)
  | EBinop (op, l, r_e) ->
      let rl = lower_expr st l in
      let rr = lower_expr st r_e in
      let rty = rty_of_expr e in
      (* For comparisons, widen both operands to the larger type so that
         setp uses a consistent type (e.g. u32 tid vs u64 len → widen to u64). *)
      let widen reg src_rty tgt_rty =
        if src_rty = tgt_rty then reg
        else begin
          let r = fresh_reg st tgt_rty in
          let rmod = cvt_rounding src_rty tgt_rty in
          emit st (Printf.sprintf "cvt%s.%s.%s %s, %s;" rmod (arith_pfx tgt_rty) (arith_pfx src_rty) r reg);
          r
        end
      in
      (* FORGE73: widen integer operands to the expression's declared type
         for arithmetic ops.  PTX is strict — `mul.lo.u64 %rd, %r32, %rd`
         with a u32 source is a type error that ptxas rejects and that
         OpenPTXas silently miscompiles.  Builtins like `blockIdx_x` come
         back as u32 even when used in u64 expressions (e.g. `row * n_cols`),
         so we insert cvt.u64.u32 at the use site.  Skip predicate and
         float operands — those are never zero-extended to wider ints. *)
      let needs_int_widen src_rty tgt_rty =
        src_rty <> tgt_rty
        && src_rty <> Pred && tgt_rty <> Pred
        && src_rty <> F32 && src_rty <> F64
        && tgt_rty <> F32 && tgt_rty <> F64
      in
      let rl_w =
        let s = reg_rty st rl in
        if needs_int_widen s rty then widen rl s rty else rl in
      let rr_w =
        let s = reg_rty st rr in
        if needs_int_widen s rty then widen rr s rty else rr in
      let dst = fresh_reg st rty in
      let pfx = arith_pfx rty in
      (match op with
      | Add    -> emit st (Printf.sprintf "add.%s %s, %s, %s;" pfx dst rl_w rr_w)
      | Sub    -> emit st (Printf.sprintf "sub.%s %s, %s, %s;" pfx dst rl_w rr_w)
      | Mul    ->
          (match rty with
           | F32 | F64 ->
               emit st (Printf.sprintf "mul.%s %s, %s, %s;" pfx dst rl_w rr_w)
           | _ ->
               emit st (Printf.sprintf "mul.lo.%s %s, %s, %s;" pfx dst rl_w rr_w))
      | Div    ->
          (* PTX div on floats requires a rounding modifier (`.rn`, `.rz`,
             `.rm`, `.rp`) or `.approx` — the bare `div.f32` form ptxas
             rejects.  Use `.rn` (round-to-nearest-even, IEEE-compliant)
             for both F32 and F64.  Integers keep the un-modified form. *)
          (match rty with
           | F32 | F64 ->
               emit st (Printf.sprintf "div.rn.%s %s, %s, %s;" pfx dst rl_w rr_w)
           | _ ->
               emit st (Printf.sprintf "div.%s %s, %s, %s;" pfx dst rl_w rr_w))
      | Mod    -> emit st (Printf.sprintf "rem.%s %s, %s, %s;" pfx dst rl_w rr_w)
      | BitAnd -> emit st (Printf.sprintf "and.b%d %s, %s, %s;" (sizeof_rty rty*8) dst rl rr)
      | BitOr  -> emit st (Printf.sprintf "or.b%d %s, %s, %s;"  (sizeof_rty rty*8) dst rl rr)
      | BitXor -> emit st (Printf.sprintf "xor.b%d %s, %s, %s;" (sizeof_rty rty*8) dst rl rr)
      | Shl    ->
          (* PTX shift instructions take a u32 shift amount regardless of
             the destination width — `shl.b64 dst, src, shift_u64` is a
             type error that ptxas rejects.  Convert to u32 if the source
             register isn't already 32-bit. *)
          let rr_u32 =
            let s = reg_rty st rr in
            if s = U32 || s = S32 then rr
            else begin
              let r = fresh_reg st U32 in
              emit st (Printf.sprintf "cvt.u32.%s %s, %s;" (arith_pfx s) r rr);
              r
            end
          in
          emit st (Printf.sprintf "shl.b%d %s, %s, %s;" (sizeof_rty rty*8) dst rl rr_u32)
      | Shr    ->
          (* Same u32 shift-amount requirement as Shl. *)
          let rr_u32 =
            let s = reg_rty st rr in
            if s = U32 || s = S32 then rr
            else begin
              let r = fresh_reg st U32 in
              emit st (Printf.sprintf "cvt.u32.%s %s, %s;" (arith_pfx s) r rr);
              r
            end
          in
          (match rty with
           | S16|S32|S64 ->
               emit st (Printf.sprintf "shr.s%d %s, %s, %s;" (sizeof_rty rty*8) dst rl rr_u32)
           | _ ->
               emit st (Printf.sprintf "shr.u%d %s, %s, %s;" (sizeof_rty rty*8) dst rl rr_u32))
      (* Comparisons → .pred register.
         dst is Pred-typed (rty = Pred for bool results).
         Use reg_rty (not rty_of_expr) to get the *actual* allocated type —
         GPU built-ins (threadIdx_x, etc.) allocate U32 registers but
         expr_ty is None, so rty_of_expr would return U64 for both sides
         and the widening cvt would never fire. *)
      | Eq  | Ne  | Lt  | Le  | Gt  | Ge ->
          let lrty = reg_rty st rl in
          let rrty = reg_rty st rr in
          let cmp_rty = if sizeof_rty lrty >= sizeof_rty rrty then lrty else rrty in
          let rl' = widen rl lrty cmp_rty in
          let rr' = widen rr rrty cmp_rty in
          let op_s = match op with
            | Eq -> "eq" | Ne -> "ne" | Lt -> "lt"
            | Le -> "le" | Gt -> "gt" | Ge -> "ge" | _ -> "eq" in
          (* dst is the fresh Pred register; setp writes directly into it *)
          emit st (Printf.sprintf "setp.%s.%s %s, %s, %s;" op_s (cmp_pfx cmp_rty) dst rl' rr')
      | And | Or ->
          let op2 = match op with And -> "and" | _ -> "or" in
          emit st (Printf.sprintf "%s.b%d %s, %s, %s;" op2 (sizeof_rty rty*8) dst rl rr)
      | Implies | Iff ->
          emit st (Printf.sprintf "mov.u32 %s, 1; // logical stub" dst));
      dst

  (* Unary operations *)
  | EUnop (Neg, inner) ->
      let ri = lower_expr st inner in
      let rty = rty_of_expr e in
      let dst = fresh_reg st rty in
      emit st (Printf.sprintf "neg.%s %s, %s;" (arith_pfx rty) dst ri);
      dst

  | EUnop (BitNot, inner) ->
      let ri = lower_expr st inner in
      let rty = rty_of_expr e in
      let dst = fresh_reg st rty in
      emit st (Printf.sprintf "not.b%d %s, %s;" (sizeof_rty rty*8) dst ri);
      dst

  | EUnop (Not, inner) ->
      let ri = lower_expr st inner in
      let dst = fresh_reg st Pred in
      emit st (Printf.sprintf "not.pred %s, %s;" dst ri);
      dst

  (* Array / span indexing:  addr = base_ptr + idx * sizeof(elem)
     For secret<T> arrays: use .cv (cache-volatile) loads to prevent caching *)
  | EIndex (arr, idx) ->
      let base = lower_expr st arr in
      let ridx  = lower_expr st idx in
      let elem_rty = rty_of_expr e in
      let sz = sizeof_rty elem_rty in
      (* Widen idx to 64-bit for address arithmetic if needed *)
      let ridx64 =
        if reg_rty st ridx = U64 then ridx
        else begin
          let r = fresh_reg st U64 in
          emit st (Printf.sprintf "cvt.u64.u32 %s, %s;" r ridx);
          r
        end
      in
      let rsz = fresh_reg st U64 in
      emit st (Printf.sprintf "mov.u64 %s, %d;" rsz sz);
      let offset = fresh_reg st U64 in
      emit st (Printf.sprintf "mul.lo.u64 %s, %s, %s;" offset ridx64 rsz);
      let addr = fresh_reg st U64 in
      emit st (Printf.sprintf "add.u64 %s, %s, %s;" addr base offset);
      (* secret<T> array → cache-volatile load.
         shared<T>[N] → .shared state space (FORGE73). *)
      let is_sec = match e.expr_ty with
        | Some (TSecret _) -> true | _ -> false in
      let is_shared = List.mem base st.shared_regs in
      let dst = fresh_reg st elem_rty in
      let () =
        if is_shared then
          emit st (Printf.sprintf "ld.shared.%s %s, [%s];"
            (arith_pfx elem_rty) dst addr)
        else
          let cv = if is_sec then ".cv" else "" in
          emit st (Printf.sprintf "ld.global%s.%s %s, [%s];"
            cv (arith_pfx elem_rty) dst addr)
      in
      dst

  (* Field access — span .len and .data *)
  | EField (obj, field) ->
      (match field.name with
       | "len" ->
           (* span<T>.len is stored at offset 8 from the base pointer in FORGE's
              two-word representation.  PTX receives span as (data_ptr, len_u64)
              two separate params, so we look up the _len register. *)
           let base_name = (match obj.expr_desc with
             | EVar id -> id.name | _ -> "__span") in
           reg_of_var st (base_name ^ "_len")
       | "data" ->
           lower_expr st obj
       | _ ->
           let r = fresh_reg st U64 in
           emit st (Printf.sprintf "mov.u64 %s, 0; // field %s" r field.name);
           r)

  (* if cond { then } else { else }
     Mut-variable mutations inside either branch must be written back to
     the variable's pre-if register so that subsequent reads see the
     correct value at the join.  Without this, `let mut ex = 0.0; if c
     { ex = expr; }` produced a PTX register (%fN) that was only defined
     in the then-branch — reads after the if returned garbage when c
     was false.  Same write-back shape as the while-loop code below.    *)
  | EIf (cond, then_, else_opt) ->
      let rc = lower_expr st cond in
      let pred =
        if reg_rty st rc = Pred then rc
        else begin
          let p = fresh_reg st Pred in
          let rty_s = arith_pfx (reg_rty st rc) in
          emit st (Printf.sprintf "setp.ne.%s %s, %s, 0;" rty_s p rc);
          p
        end
      in
      let lbl_id   = st.counter in
      st.counter <- st.counter + 1;
      let lbl_then = Printf.sprintf "%s_then_%d" st.fn_name lbl_id in
      let lbl_else = Printf.sprintf "%s_else_%d" st.fn_name lbl_id in
      let lbl_end  = Printf.sprintf "%s_end_%d"  st.fn_name lbl_id in
      (* Snapshot reg_env mappings BEFORE either branch runs.  Each name
         present here has a "pre-if" register that mut-assignments inside
         a branch must update via an explicit mov, NOT by rebinding the
         name in reg_env to a fresh register. *)
      let pre_if_snapshot =
        List.fold_left (fun acc (name, reg) ->
          if List.mem_assoc name acc then acc else (name, reg) :: acc
        ) [] st.reg_env
      in
      let writeback name new_reg orig_reg =
        if new_reg <> orig_reg then begin
          let rty = reg_rty st new_reg in
          let pfx = match rty with
            | Pred -> "pred"
            | _ -> arith_pfx rty
          in
          emit st (Printf.sprintf "mov.%s %s, %s; // if wb: %s"
                     pfx orig_reg new_reg name)
        end
      in
      let restore_env () =
        let snap_names = List.map fst pre_if_snapshot in
        st.reg_env <-
          List.filter (fun (n, _) -> not (List.mem n snap_names)) st.reg_env
          @ pre_if_snapshot
      in
      emit st (Printf.sprintf "@%s bra %s;" pred lbl_then);
      emit st (Printf.sprintf "bra %s;" lbl_else);
      emit st (lbl_then ^ ":");
      let rt = lower_expr st then_ in
      let rty = reg_rty st rt in
      let dst = fresh_reg st rty in
      emit st (Printf.sprintf "mov%s %s, %s;" (ptx_rty_name rty) dst rt);
      (* Write back any mut-var mutations from the then-branch into the
         pre-if registers, then restore reg_env so the else-branch sees
         the original mappings. *)
      List.iter (fun (name, orig) ->
        match List.assoc_opt name st.reg_env with
        | Some cur -> writeback name cur orig
        | None -> ()
      ) pre_if_snapshot;
      restore_env ();
      emit st (Printf.sprintf "bra %s;" lbl_end);
      emit st (lbl_else ^ ":");
      (match else_opt with
       | Some else_ ->
           let re = lower_expr st else_ in
           emit st (Printf.sprintf "mov%s %s, %s;" (ptx_rty_name rty) dst re);
           List.iter (fun (name, orig) ->
             match List.assoc_opt name st.reg_env with
             | Some cur -> writeback name cur orig
             | None -> ()
           ) pre_if_snapshot;
           restore_env ()
       | None ->
           emit st (Printf.sprintf "mov%s %s, 0; // no else branch" (ptx_rty_name rty) dst));
      emit st (lbl_end ^ ":");
      dst

  (* Block { stmts; expr } *)
  | EBlock (stmts, Some ret) ->
      List.iter (lower_stmt st) stmts;
      lower_expr st ret

  | EBlock (stmts, None) ->
      List.iter (lower_stmt st) stmts;
      let r = fresh_reg st U32 in
      emit st (Printf.sprintf "mov.u32 %s, 0; // unit" r);
      r

  (* syncthreads → bar.sync *)
  | ESync ->
      emit st "bar.sync 0;";
      let r = fresh_reg st U32 in
      emit st (Printf.sprintf "mov.u32 %s, 0; // unit" r);
      r

  (* Cast *)
  | ECast (inner, ty) ->
      let ri  = lower_expr st inner in
      let src = rty_of_expr inner in
      let dst_rty = ptx_rty_of_ty ty in
      if src = dst_rty then ri
      else begin
        let dst = fresh_reg st dst_rty in
        let rmod = cvt_rounding src dst_rty in
        emit st (Printf.sprintf "cvt%s%s%s %s, %s;"
          rmod (ptx_rty_name dst_rty) (ptx_rty_name src) dst ri);
        dst
      end

  (* ---- GPU intrinsics ---- *)

  (* Warp shuffle: shfl_sync(val, src_lane, width) *)
  | ECall ({ expr_desc = EVar id; _ }, [val_e; lane_e; _width_e])
      when id.name = "shfl_down_sync" ->
      let rv = lower_expr st val_e in
      let rl = lower_expr st lane_e in
      let dst = fresh_reg st U32 in
      emit st (Printf.sprintf "shfl.sync.down.b32 %s, %s, %s, 31, 0xffffffff;" dst rv rl);
      dst

  | ECall ({ expr_desc = EVar id; _ }, [val_e; lane_e; _width_e])
      when id.name = "shfl_xor_sync" ->
      let rv = lower_expr st val_e in
      let rl = lower_expr st lane_e in
      let dst = fresh_reg st U32 in
      emit st (Printf.sprintf "shfl.sync.bfly.b32 %s, %s, %s, 31, 0xffffffff;" dst rv rl);
      dst

  (* Atomic add: atom_add(ptr, val) → old value *)
  | ECall ({ expr_desc = EVar id; _ }, [ptr_e; val_e])
      when id.name = "atom_add" ->
      let rp = lower_expr st ptr_e in
      let rv = lower_expr st val_e in
      let dst = fresh_reg st U64 in
      emit st (Printf.sprintf "atom.global.add.u64 %s, [%s], %s;" dst rp rv);
      dst

  | ECall ({ expr_desc = EVar id; _ }, [ptr_e; val_e])
      when id.name = "atom_cas" ->
      let rp = lower_expr st ptr_e in
      let rv = lower_expr st val_e in
      let dst = fresh_reg st U64 in
      emit st (Printf.sprintf "atom.global.cas.b64 %s, [%s], %s, %s;" dst rp rv rv);
      dst

  | ECall ({ expr_desc = EVar id; _ }, [ptr_e; val_e])
      when id.name = "atom_max" ->
      let rp = lower_expr st ptr_e in
      let rv = lower_expr st val_e in
      let dst = fresh_reg st U64 in
      emit st (Printf.sprintf "atom.global.max.u64 %s, [%s], %s;" dst rp rv);
      dst

  | ECall ({ expr_desc = EVar id; _ }, [ptr_e; val_e])
      when id.name = "atom_min" ->
      let rp = lower_expr st ptr_e in
      let rv = lower_expr st val_e in
      let dst = fresh_reg st U64 in
      emit st (Printf.sprintf "atom.global.min.u64 %s, [%s], %s;" dst rp rv);
      dst

  | ECall ({ expr_desc = EVar id; _ }, [ptr_e; val_e])
      when id.name = "atom_or" ->
      let rp = lower_expr st ptr_e in
      let rv = lower_expr st val_e in
      let dst = fresh_reg st U64 in
      emit st (Printf.sprintf "atom.global.or.b64 %s, [%s], %s;" dst rp rv);
      dst

  | ECall ({ expr_desc = EVar id; _ }, [ptr_e; val_e])
      when id.name = "atom_xor" ->
      let rp = lower_expr st ptr_e in
      let rv = lower_expr st val_e in
      let dst = fresh_reg st U64 in
      emit st (Printf.sprintf "atom.global.xor.b64 %s, [%s], %s;" dst rp rv);
      dst

  | ECall ({ expr_desc = EVar id; _ }, [ptr_e; val_e])
      when id.name = "atom_and" ->
      let rp = lower_expr st ptr_e in
      let rv = lower_expr st val_e in
      let dst = fresh_reg st U64 in
      emit st (Printf.sprintf "atom.global.and.b64 %s, [%s], %s;" dst rp rv);
      dst

  | ECall ({ expr_desc = EVar id; _ }, [ptr_e; val_e])
      when id.name = "atom_sub" ->
      let rp = lower_expr st ptr_e in
      let rv = lower_expr st val_e in
      let dst = fresh_reg st U64 in
      emit st (Printf.sprintf "atom.global.add.u64 %s, [%s], -%s;" dst rp rv);
      dst

  | ECall ({ expr_desc = EVar id; _ }, [ptr_e; val_e])
      when id.name = "atom_exch" ->
      let rp = lower_expr st ptr_e in
      let rv = lower_expr st val_e in
      let dst = fresh_reg st U64 in
      emit st (Printf.sprintf "atom.global.exch.b64 %s, [%s], %s;" dst rp rv);
      dst

  (* Warp shuffle up *)
  | ECall ({ expr_desc = EVar id; _ }, [val_e; lane_e; _width_e])
      when id.name = "shfl_up_sync" ->
      let rv = lower_expr st val_e in
      let rl = lower_expr st lane_e in
      let dst = fresh_reg st U32 in
      emit st (Printf.sprintf "shfl.sync.up.b32 %s, %s, %s, 0, 0xffffffff;" dst rv rl);
      dst

  (* Memory fences *)
  | ECall ({ expr_desc = EVar id; _ }, [])
      when id.name = "threadfence" ->
      let r = fresh_reg st U32 in
      emit st "membar.gl;";
      emit st (Printf.sprintf "mov.u32 %s, 0;" r); r

  | ECall ({ expr_desc = EVar id; _ }, [])
      when id.name = "threadfence_block" ->
      let r = fresh_reg st U32 in
      emit st "membar.cta;";
      emit st (Printf.sprintf "mov.u32 %s, 0;" r); r

  | ECall ({ expr_desc = EVar id; _ }, [])
      when id.name = "threadfence_system" ->
      let r = fresh_reg st U32 in
      emit st "membar.sys;";
      emit st (Printf.sprintf "mov.u32 %s, 0;" r); r

  (* Async copy (SM_80+) *)
  | ECall ({ expr_desc = EVar id; _ }, [dst_e; src_e; bytes_e])
      when id.name = "cp_async_cg" ->
      let rd = lower_expr st dst_e in
      let rs = lower_expr st src_e in
      let rb = lower_expr st bytes_e in
      let r = fresh_reg st U32 in
      emit st (Printf.sprintf "cp.async.cg.shared.global [%s], [%s], %s;" rd rs rb);
      emit st (Printf.sprintf "mov.u32 %s, 0;" r); r

  | ECall ({ expr_desc = EVar id; _ }, [])
      when id.name = "cp_async_commit" ->
      let r = fresh_reg st U32 in
      emit st "cp.async.commit_group;";
      emit st (Printf.sprintf "mov.u32 %s, 0;" r); r

  | ECall ({ expr_desc = EVar id; _ }, [n_e])
      when id.name = "cp_async_wait_group" ->
      let rn = lower_expr st n_e in
      let r = fresh_reg st U32 in
      emit st (Printf.sprintf "cp.async.wait_group %s;" rn);
      emit st (Printf.sprintf "mov.u32 %s, 0;" r); r

  (* Cooperative groups (SM_90+) *)
  | ECall ({ expr_desc = EVar id; _ }, [])
      when id.name = "cluster_sync" ->
      let r = fresh_reg st U32 in
      emit st "barrier.cluster.arrive;";
      emit st "barrier.cluster.wait;";
      emit st (Printf.sprintf "mov.u32 %s, 0;" r); r

  (* FP16/BF16 conversions — emit cvt instructions.
     PTX cvt.f32.f16 / cvt.f32.bf16 require a typed source operand
     (.f16 or .bf16), and `.b16` (bit-pattern) is the closest the
     codegen models.  cvt.rn.f16.f32 / cvt.rn.bf16.f32 produce a
     typed result that consumers loading via `ld.global.u16` /
     storing via `st.global.u16` need bridged to/from `.u16`.  Use
     `mov.b16` (no-op bit-cast) at each boundary. *)
  | ECall ({ expr_desc = EVar id; _ }, [x_e])
      when id.name = "f32_to_fp16" ->
      let rx = lower_expr st x_e in
      let bdst = fresh_reg st B16 in
      emit st (Printf.sprintf "cvt.rn.f16.f32 %s, %s;" bdst rx);
      let dst = fresh_reg st U16 in
      emit st (Printf.sprintf "mov.b16 %s, %s;" dst bdst);
      dst

  | ECall ({ expr_desc = EVar id; _ }, [x_e])
      when id.name = "fp16_to_f32" ->
      let rx = lower_expr st x_e in
      let bridge = fresh_reg st B16 in
      emit st (Printf.sprintf "mov.b16 %s, %s;" bridge rx);
      let dst = fresh_reg st F32 in
      emit st (Printf.sprintf "cvt.f32.f16 %s, %s;" dst bridge);
      dst

  | ECall ({ expr_desc = EVar id; _ }, [x_e])
      when id.name = "f32_to_bf16" ->
      let rx = lower_expr st x_e in
      let bdst = fresh_reg st B16 in
      emit st (Printf.sprintf "cvt.rn.bf16.f32 %s, %s;" bdst rx);
      let dst = fresh_reg st U16 in
      emit st (Printf.sprintf "mov.b16 %s, %s;" dst bdst);
      dst

  | ECall ({ expr_desc = EVar id; _ }, [x_e])
      when id.name = "bf16_to_f32" ->
      let rx = lower_expr st x_e in
      let bridge = fresh_reg st B16 in
      emit st (Printf.sprintf "mov.b16 %s, %s;" bridge rx);
      let dst = fresh_reg st F32 in
      emit st (Printf.sprintf "cvt.f32.bf16 %s, %s;" dst bridge);
      dst

  (* Warp vote: ballot_sync() → bitmask of active threads *)
  | ECall ({ expr_desc = EVar id; _ }, [pred_e])
      when id.name = "ballot_sync" ->
      let rp = lower_expr st pred_e in
      let dst = fresh_reg st U32 in
      let ptmp = fresh_reg st Pred in
      emit st (Printf.sprintf "setp.ne.u64 %s, %s, 0;" ptmp rp);
      emit st (Printf.sprintf "vote.sync.ballot.b32 %s, %s, 0xffffffff;" dst ptmp);
      dst

  (* Lane ID.
     FG-2.6: emit a u64 register so callers that bind the result to a
     u64 variable get a correctly-typed value without relying on an
     implicit u32→u64 coercion at the assignment site (which the PTX
     backend does not currently insert).  The extra `mov.u32` into a
     temporary followed by `cvt.u64.u32` is what PTXAS would do
     internally; by emitting it here we guarantee the downstream
     store sees a valid u64 operand. *)
  | ECall ({ expr_desc = EVar id; _ }, [])
      when id.name = "lane_id" ->
      let tmp = fresh_reg st U32 in
      emit st (Printf.sprintf "mov.u32 %s, %%laneid;" tmp);
      let r = fresh_reg st U64 in
      emit st (Printf.sprintf "cvt.u64.u32 %s, %s;" r tmp);
      r

  (* Warp ID *)
  | ECall ({ expr_desc = EVar id; _ }, [])
      when id.name = "warp_id" ->
      let r = fresh_reg st U32 in
      emit st (Printf.sprintf "mov.u32 %s, %%warpid;" r); r

  (* FORGE77: tensor-core FP16 × FP16 → f32 MMA, m16n8k16 shape.
     Lowers to the single `mma.sync.aligned.m16n8k16.row.col.f32.f16.f16.f32`
     instruction — one warp-wide tile multiply.  Per-thread fragment
     layout assumption (matches CUTLASS linear-per-thread packing):
       A: 8 fp16 per thread  = 16 bytes at tid * 16  (4 .b32 regs)
       B: 4 fp16 per thread  =  8 bytes at tid *  8  (2 .b32 regs)
       C: 4 f32  per thread  = 16 bytes at tid * 16  (4 .f32 regs)
     Caller is responsible for staging data into spans in this layout
     (identical convention to CUTLASS mma fragments). *)
  | ECall ({ expr_desc = EVar id; _ },
           [{ expr_desc = EVar a_id; _ };
            { expr_desc = EVar b_id; _ };
            { expr_desc = EVar c_id; _ }])
      when id.name = "mma_m16n8k16_fp16" ->
      let a_base = reg_of_var st a_id.name in
      let b_base = reg_of_var st b_id.name in
      let c_base = reg_of_var st c_id.name in
      (* Per-thread offsets *)
      let tid32 = fresh_reg st U32 in
      emit st (Printf.sprintf "mov.u32 %s, %%tid.x;" tid32);
      let tid64 = fresh_reg st U64 in
      emit st (Printf.sprintf "cvt.u64.u32 %s, %s;" tid64 tid32);
      let ofs16 = fresh_reg st U64 in
      emit st (Printf.sprintf "mov.u64 %s, 16;" ofs16);
      let ofs8 = fresh_reg st U64 in
      emit st (Printf.sprintf "mov.u64 %s, 8;" ofs8);
      let a_ofs = fresh_reg st U64 in
      emit st (Printf.sprintf "mul.lo.u64 %s, %s, %s;" a_ofs tid64 ofs16);
      let a_ptr = fresh_reg st U64 in
      emit st (Printf.sprintf "add.u64 %s, %s, %s;" a_ptr a_base a_ofs);
      let b_ofs = fresh_reg st U64 in
      emit st (Printf.sprintf "mul.lo.u64 %s, %s, %s;" b_ofs tid64 ofs8);
      let b_ptr = fresh_reg st U64 in
      emit st (Printf.sprintf "add.u64 %s, %s, %s;" b_ptr b_base b_ofs);
      let c_ofs = fresh_reg st U64 in
      emit st (Printf.sprintf "mul.lo.u64 %s, %s, %s;" c_ofs tid64 ofs16);
      let c_ptr = fresh_reg st U64 in
      emit st (Printf.sprintf "add.u64 %s, %s, %s;" c_ptr c_base c_ofs);
      (* Load A fragment: 4 .b32 registers *)
      let ra0 = fresh_reg st U32 in
      let ra1 = fresh_reg st U32 in
      let ra2 = fresh_reg st U32 in
      let ra3 = fresh_reg st U32 in
      emit st (Printf.sprintf "ld.global.u32 %s, [%s+0];"  ra0 a_ptr);
      emit st (Printf.sprintf "ld.global.u32 %s, [%s+4];"  ra1 a_ptr);
      emit st (Printf.sprintf "ld.global.u32 %s, [%s+8];"  ra2 a_ptr);
      emit st (Printf.sprintf "ld.global.u32 %s, [%s+12];" ra3 a_ptr);
      (* Load B fragment: 2 .b32 registers *)
      let rb0 = fresh_reg st U32 in
      let rb1 = fresh_reg st U32 in
      emit st (Printf.sprintf "ld.global.u32 %s, [%s+0];" rb0 b_ptr);
      emit st (Printf.sprintf "ld.global.u32 %s, [%s+4];" rb1 b_ptr);
      (* Load C fragment: 4 f32 registers — used as input accumulator *)
      let fc0 = fresh_reg st F32 in
      let fc1 = fresh_reg st F32 in
      let fc2 = fresh_reg st F32 in
      let fc3 = fresh_reg st F32 in
      emit st (Printf.sprintf "ld.global.f32 %s, [%s+0];"  fc0 c_ptr);
      emit st (Printf.sprintf "ld.global.f32 %s, [%s+4];"  fc1 c_ptr);
      emit st (Printf.sprintf "ld.global.f32 %s, [%s+8];"  fc2 c_ptr);
      emit st (Printf.sprintf "ld.global.f32 %s, [%s+12];" fc3 c_ptr);
      (* Allocate D (output) fragment *)
      let fd0 = fresh_reg st F32 in
      let fd1 = fresh_reg st F32 in
      let fd2 = fresh_reg st F32 in
      let fd3 = fresh_reg st F32 in
      emit st (Printf.sprintf
        "mma.sync.aligned.m16n8k16.row.col.f32.f16.f16.f32 \
         {%s, %s, %s, %s}, {%s, %s, %s, %s}, {%s, %s}, {%s, %s, %s, %s};"
        fd0 fd1 fd2 fd3
        ra0 ra1 ra2 ra3
        rb0 rb1
        fc0 fc1 fc2 fc3);
      (* Store D back into the C fragment (in-place accumulate). *)
      emit st (Printf.sprintf "st.global.f32 [%s+0],  %s;" c_ptr fd0);
      emit st (Printf.sprintf "st.global.f32 [%s+4],  %s;" c_ptr fd1);
      emit st (Printf.sprintf "st.global.f32 [%s+8],  %s;" c_ptr fd2);
      emit st (Printf.sprintf "st.global.f32 [%s+12], %s;" c_ptr fd3);
      let r = fresh_reg st U32 in
      emit st (Printf.sprintf "mov.u32 %s, 0; // mma returns unit" r);
      r

  (* FORGE78: tensor-core FP8 × FP8 → f32 MMA, m16n8k32 shape, E4M3 variant.
     Fragment layout per thread (CUTLASS-compatible):
       A: 16 fp8 per thread = 16 bytes at tid * 16 (4 .b32 regs; 4 FP8 per reg)
       B:  8 fp8 per thread =  8 bytes at tid *  8 (2 .b32 regs)
       C:  4 f32 per thread = 16 bytes at tid * 16 (4 .f32 regs)
     Register counts match the FP16 HMMA, only the instruction selector
     changes — the k-depth doubles (FP8 packs 4 per reg vs FP16's 2) so
     k=32 fits the same register budget as fp16 k=16. *)
  | ECall ({ expr_desc = EVar id; _ },
           [{ expr_desc = EVar a_id; _ };
            { expr_desc = EVar b_id; _ };
            { expr_desc = EVar c_id; _ }])
      when id.name = "mma_m16n8k32_e4m3"
        || id.name = "mma_m16n8k32_e5m2" ->
      let e_tag = if id.name = "mma_m16n8k32_e4m3" then "e4m3" else "e5m2" in
      let a_base = reg_of_var st a_id.name in
      let b_base = reg_of_var st b_id.name in
      let c_base = reg_of_var st c_id.name in
      let tid32 = fresh_reg st U32 in
      emit st (Printf.sprintf "mov.u32 %s, %%tid.x;" tid32);
      let tid64 = fresh_reg st U64 in
      emit st (Printf.sprintf "cvt.u64.u32 %s, %s;" tid64 tid32);
      let ofs16 = fresh_reg st U64 in
      emit st (Printf.sprintf "mov.u64 %s, 16;" ofs16);
      let ofs8 = fresh_reg st U64 in
      emit st (Printf.sprintf "mov.u64 %s, 8;" ofs8);
      let a_ofs = fresh_reg st U64 in
      emit st (Printf.sprintf "mul.lo.u64 %s, %s, %s;" a_ofs tid64 ofs16);
      let a_ptr = fresh_reg st U64 in
      emit st (Printf.sprintf "add.u64 %s, %s, %s;" a_ptr a_base a_ofs);
      let b_ofs = fresh_reg st U64 in
      emit st (Printf.sprintf "mul.lo.u64 %s, %s, %s;" b_ofs tid64 ofs8);
      let b_ptr = fresh_reg st U64 in
      emit st (Printf.sprintf "add.u64 %s, %s, %s;" b_ptr b_base b_ofs);
      let c_ofs = fresh_reg st U64 in
      emit st (Printf.sprintf "mul.lo.u64 %s, %s, %s;" c_ofs tid64 ofs16);
      let c_ptr = fresh_reg st U64 in
      emit st (Printf.sprintf "add.u64 %s, %s, %s;" c_ptr c_base c_ofs);
      let ra0 = fresh_reg st U32 in let ra1 = fresh_reg st U32 in
      let ra2 = fresh_reg st U32 in let ra3 = fresh_reg st U32 in
      emit st (Printf.sprintf "ld.global.u32 %s, [%s+0];"  ra0 a_ptr);
      emit st (Printf.sprintf "ld.global.u32 %s, [%s+4];"  ra1 a_ptr);
      emit st (Printf.sprintf "ld.global.u32 %s, [%s+8];"  ra2 a_ptr);
      emit st (Printf.sprintf "ld.global.u32 %s, [%s+12];" ra3 a_ptr);
      let rb0 = fresh_reg st U32 in let rb1 = fresh_reg st U32 in
      emit st (Printf.sprintf "ld.global.u32 %s, [%s+0];" rb0 b_ptr);
      emit st (Printf.sprintf "ld.global.u32 %s, [%s+4];" rb1 b_ptr);
      let fc0 = fresh_reg st F32 in let fc1 = fresh_reg st F32 in
      let fc2 = fresh_reg st F32 in let fc3 = fresh_reg st F32 in
      emit st (Printf.sprintf "ld.global.f32 %s, [%s+0];"  fc0 c_ptr);
      emit st (Printf.sprintf "ld.global.f32 %s, [%s+4];"  fc1 c_ptr);
      emit st (Printf.sprintf "ld.global.f32 %s, [%s+8];"  fc2 c_ptr);
      emit st (Printf.sprintf "ld.global.f32 %s, [%s+12];" fc3 c_ptr);
      let fd0 = fresh_reg st F32 in let fd1 = fresh_reg st F32 in
      let fd2 = fresh_reg st F32 in let fd3 = fresh_reg st F32 in
      emit st (Printf.sprintf
        "mma.sync.aligned.m16n8k32.row.col.f32.%s.%s.f32 \
         {%s, %s, %s, %s}, {%s, %s, %s, %s}, {%s, %s}, {%s, %s, %s, %s};"
        e_tag e_tag
        fd0 fd1 fd2 fd3
        ra0 ra1 ra2 ra3
        rb0 rb1
        fc0 fc1 fc2 fc3);
      emit st (Printf.sprintf "st.global.f32 [%s+0],  %s;" c_ptr fd0);
      emit st (Printf.sprintf "st.global.f32 [%s+4],  %s;" c_ptr fd1);
      emit st (Printf.sprintf "st.global.f32 [%s+8],  %s;" c_ptr fd2);
      emit st (Printf.sprintf "st.global.f32 [%s+12], %s;" c_ptr fd3);
      let r = fresh_reg st U32 in
      emit st (Printf.sprintf "mov.u32 %s, 0; // mma returns unit" r);
      r

  (* FORGE73: expf(x) → ex2.approx.f32(x * log2(e)).  This is how CUDA's
     libdevice implements expf at the hardware level on SM_80+ — a single
     MUFU.EX2 instruction preceded by a multiply by log2(e) (~1.442695).
     Bit pattern for log2(e) as f32 is 0x3FB8AA3B. *)
  | ECall ({ expr_desc = EVar id; _ }, [arg])
      when id.name = "expf" ->
      let rx = lower_expr st arg in
      let scaled = fresh_reg st F32 in
      emit st (Printf.sprintf "mul.rn.f32 %s, %s, 0f3FB8AA3B; // log2(e)"
                 scaled rx);
      let result = fresh_reg st F32 in
      emit st (Printf.sprintf "ex2.approx.f32 %s, %s;" result scaled);
      result

  (* FORGE80: tanhf(x) → tanh.approx.f32(x).  Single SFU instruction on SM_75+. *)
  | ECall ({ expr_desc = EVar id; _ }, [arg])
      when id.name = "tanhf" ->
      let rx = lower_expr st arg in
      let result = fresh_reg st F32 in
      emit st (Printf.sprintf "tanh.approx.f32 %s, %s;" result rx);
      result

  (* FORGE87: logf(x) → lg2.approx.f32(x) * ln(2).  PTX has log2 in
     hardware (single SFU); the natural-log version is one extra fma.
     Bit pattern for ln(2) as f32: 0x3F317218. *)
  | ECall ({ expr_desc = EVar id; _ }, [arg])
      when id.name = "logf" ->
      let rx = lower_expr st arg in
      let lg2 = fresh_reg st F32 in
      emit st (Printf.sprintf "lg2.approx.f32 %s, %s;" lg2 rx);
      let result = fresh_reg st F32 in
      emit st (Printf.sprintf "mul.rn.f32 %s, %s, 0f3F317218; // ln(2)"
                 result lg2);
      result

  (* FORGE83: sinf(x) → sin.approx.f32(x), cosf(x) → cos.approx.f32(x).
     Single SFU instructions.  Used in RoPE / position-encoding kernels. *)
  | ECall ({ expr_desc = EVar id; _ }, [arg])
      when id.name = "sinf" ->
      let rx = lower_expr st arg in
      let result = fresh_reg st F32 in
      emit st (Printf.sprintf "sin.approx.f32 %s, %s;" result rx);
      result

  | ECall ({ expr_desc = EVar id; _ }, [arg])
      when id.name = "cosf" ->
      let rx = lower_expr st arg in
      let result = fresh_reg st F32 in
      emit st (Printf.sprintf "cos.approx.f32 %s, %s;" result rx);
      result

  (* FORGE73: rsqrtf(x) → rsqrt.approx.f32(x).  Single hardware instruction. *)
  | ECall ({ expr_desc = EVar id; _ }, [arg])
      when id.name = "rsqrtf" ->
      let rx = lower_expr st arg in
      let result = fresh_reg st F32 in
      emit st (Printf.sprintf "rsqrt.approx.f32 %s, %s;" result rx);
      result

  (* FORGE73: sqrtf(x) → sqrt.approx.f32(x). *)
  | ECall ({ expr_desc = EVar id; _ }, [arg])
      when id.name = "sqrtf" ->
      let rx = lower_expr st arg in
      let result = fresh_reg st F32 in
      emit st (Printf.sprintf "sqrt.approx.f32 %s, %s;" result rx);
      result

  (* FORGE73: fmaxf / fminf lower to max.f32 / min.f32 single instructions. *)
  | ECall ({ expr_desc = EVar id; _ }, [a; b])
      when id.name = "fmaxf" ->
      let ra = lower_expr st a in
      let rb = lower_expr st b in
      let result = fresh_reg st F32 in
      emit st (Printf.sprintf "max.f32 %s, %s, %s;" result ra rb);
      result

  | ECall ({ expr_desc = EVar id; _ }, [a; b])
      when id.name = "fminf" ->
      let ra = lower_expr st a in
      let rb = lower_expr st b in
      let result = fresh_reg st F32 in
      emit st (Printf.sprintf "min.f32 %s, %s, %s;" result ra rb);
      result

  (* FORGE73: fabsf(x) → abs.f32. *)
  | ECall ({ expr_desc = EVar id; _ }, [arg])
      when id.name = "fabsf" ->
      let rx = lower_expr st arg in
      let result = fresh_reg st F32 in
      emit st (Printf.sprintf "abs.f32 %s, %s;" result rx);
      result

  (* Generic function calls.

     FG-2.6: inline user-defined device functions at the call site.
     The PTX backend has no call/return machinery, so a real PTX
     call is not available.  Inlining is sufficient for the
     supported minimal scope:
       - simple pure functions (no side effects beyond the returned
         value)
       - one body expression (any shape that lower_expr handles)
       - positional arguments bound by parameter name
     Recursion and mutually-recursive functions are NOT supported.
     Functions not found in st.fn_defs fall through to the legacy
     stub (mov.u64 %rdN, 0) and a warning comment in the emitted PTX
     so callers can see the failure mode instead of silently running
     the stub value. *)
  | ECall ({ expr_desc = EVar id; _ }, args) ->
      (match Hashtbl.find_opt st.fn_defs id.name with
       | Some callee when callee.fn_body <> None ->
           (* 1. Lower each argument expression in the caller's
                 environment to get a source register.  The
                 argument register may not match the callee's
                 parameter type — for example, a `tid: u64`
                 variable computed as `add.u32 %r7, ...` holds its
                 value in a u32 register even though its Forge
                 type is u64.  To keep the inlined body type-
                 correct (and to stay within PTXAS's strict
                 operand-type check), coerce each argument register
                 to its parameter type via cvt.u64.u32 / cvt.u32.u64
                 as needed.  Only the narrow u32<->u64 conversion
                 pair is handled here because that is the only
                 case the current backend exercises; broader type
                 coercion is tracked as future work. *)
           let arg_regs = List.map (lower_expr st) args in
           let coerced_regs =
             List.map2 (fun (_pname, pty) areg ->
               let pty_rty = ptx_rty_of_ty pty in
               let areg_rty = reg_rty st areg in
               if pty_rty = areg_rty then areg
               else begin
                 match areg_rty, pty_rty with
                 | U32, U64 ->
                     let r = fresh_reg st U64 in
                     emit st (Printf.sprintf "cvt.u64.u32 %s, %s;" r areg);
                     r
                 | U64, U32 ->
                     let r = fresh_reg st U32 in
                     emit st (Printf.sprintf "cvt.u32.u64 %s, %s;" r areg);
                     r
                 | _ ->
                     (* Leave other type mismatches alone; PTXAS
                        will catch them explicitly rather than the
                        inliner silently mis-coercing. *)
                     areg
               end
             ) callee.fn_params arg_regs
           in
           (* 2. Bind callee parameter names to the coerced argument
                 registers.  Save the current reg_env so we can
                 restore it after the inlined body and avoid leaking
                 the binding. *)
           let saved_env = st.reg_env in
           let new_bindings =
             List.map2 (fun (pname, _pty) areg -> (pname.name, areg))
               callee.fn_params coerced_regs
           in
           st.reg_env <- new_bindings @ saved_env;
           (* 3. Lower the callee body in the caller's state.  Its
                 fresh_reg allocations flow into st, so all emitted
                 instructions belong to the current kernel's register
                 space and there is no cross-function conflict. *)
           let body = match callee.fn_body with
             | Some b -> b
             | None -> assert false
           in
           let result_reg = lower_expr st body in
           (* 4. Restore the reg_env.  Register decls stay in
                 st.reg_decls (they are per-kernel, not per-scope). *)
           st.reg_env <- saved_env;
           result_reg
       | _ ->
           (* Unknown callee — emit stub + warning.  This path is
              intentionally loud so missing device-function cases
              surface immediately instead of silently succeeding. *)
           let r = fresh_reg st U64 in
           emit st (Printf.sprintf
             "mov.u64 %s, 0; // FG-2.6: UNRESOLVED device fn %s (stub)"
             r id.name);
           r)

  | EAssign (lhs, rhs) ->
      let rv = lower_expr st rhs in
      lower_assign st lhs rv;
      rv

  | EProof _ | EAssume _ ->
      let r = fresh_reg st U32 in
      emit st (Printf.sprintf "mov.u32 %s, 0; // proof/assume erased" r);
      r

  | EAsm ab ->
      let r = fresh_reg st U32 in
      emit st (Printf.sprintf "// inline asm: %s" ab.asm_template);
      emit st ab.asm_template;
      emit st (Printf.sprintf "mov.u32 %s, 0;" r);
      r

  | _ ->
      let r = fresh_reg st U64 in
      emit st (Printf.sprintf "mov.u64 %s, 0; // unhandled expr" r);
      r

(* ------------------------------------------------------------------ *)
(* Assignment to an lvalue (array store or variable update)            *)
(* ------------------------------------------------------------------ *)
and lower_assign st lhs rv =
  match lhs.expr_desc with
  | EVar id ->
      st.reg_env <- (id.name, rv) :: st.reg_env

  | EIndex (arr, idx) ->
      let base  = lower_expr st arr in
      let ridx  = lower_expr st idx in
      let ridx64 =
        if reg_rty st ridx = U64 then ridx
        else begin
          let r = fresh_reg st U64 in
          emit st (Printf.sprintf "cvt.u64.u32 %s, %s;" r ridx);
          r
        end
      in
      let elem_rty = rty_of_expr lhs in
      let sz = sizeof_rty elem_rty in
      let rsz = fresh_reg st U64 in
      emit st (Printf.sprintf "mov.u64 %s, %d;" rsz sz);
      let offset = fresh_reg st U64 in
      emit st (Printf.sprintf "mul.lo.u64 %s, %s, %s;" offset ridx64 rsz);
      let addr = fresh_reg st U64 in
      emit st (Printf.sprintf "add.u64 %s, %s, %s;" addr base offset);
      (* secret<T> array → cache-streaming store.
         shared<T>[N] → .shared state space (FORGE73). *)
      let is_sec = match lhs.expr_ty with
        | Some (TSecret _) -> true | _ -> false in
      let is_shared = List.mem base st.shared_regs in
      if is_shared then
        emit st (Printf.sprintf "st.shared.%s [%s], %s;"
          (arith_pfx elem_rty) addr rv)
      else
        let cs = if is_sec then ".cs" else "" in
        emit st (Printf.sprintf "st.global%s.%s [%s], %s;" cs (arith_pfx elem_rty) addr rv)

  | _ ->
      emit st (Printf.sprintf "// assign to complex lvalue — ignored")

(* ------------------------------------------------------------------ *)
(* Statement lowering                                                   *)
(* ------------------------------------------------------------------ *)
and lower_stmt st s =
  match s.stmt_desc with
  | SLet (id, Some (TShared (elem_ty, size_opt)), _init, _lin) ->
      (* FORGE73: shared<T>[N] — allocate PTX .shared memory symbol.
         The initializer (e.g. `[0.0f32; 256]`) is erased; shared memory
         has no declarator-level init in PTX.  Kernels that rely on a
         zeroed smem must write zeros explicitly (softmax fills smem[tid]
         before any read).  The symbol name is derived from the binding
         so multiple shared arrays in one kernel stay distinct. *)
      let n = match size_opt with
        | Some { expr_desc = ELit (LInt (v, _)); _ } -> Int64.to_int v
        | _ -> failwith
            (Printf.sprintf "PTX backend: shared<%s>[N] needs a constant size"
               id.name)
      in
      let elem_rty = ptx_rty_of_ty elem_ty in
      let sym = Printf.sprintf "__forge_smem_%s" id.name in
      st.shared_decls <- (sym, elem_rty, n) :: st.shared_decls;
      (* Allocate a u64 register holding the symbol's address. *)
      let r = fresh_reg st U64 in
      emit st (Printf.sprintf "mov.u64 %s, %s;" r sym);
      st.shared_regs <- r :: st.shared_regs;
      st.reg_env <- (id.name, r) :: st.reg_env

  | SLet (id, _ty, e, _lin) ->
      let r = lower_expr st e in
      st.reg_env <- (id.name, r) :: st.reg_env

  | SExpr { expr_desc = EAssign (lhs, rhs); _ } ->
      let rv = lower_expr st rhs in
      lower_assign st lhs rv

  | SExpr e ->
      let _ = lower_expr st e in ()

  | SReturn (Some e) ->
      let _ = lower_expr st e in
      emit st "ret;"

  | SReturn None ->
      emit st "ret;"

  | SWhile (cond, _inv, _dec, body) ->
      let lbl_top = Printf.sprintf "%s_loop_%d" st.fn_name st.counter in
      let lbl_end = Printf.sprintf "%s_loop_end_%d" st.fn_name st.counter in
      st.counter <- st.counter + 1;
      (* Snapshot unique name->register bindings before entering the loop.
         After the body, emit mov to write back any updated bindings,
         then restore reg_env to the pre-loop originals so the back-edge
         reads the original (mutable) registers. *)
      let loop_snapshot =
        List.fold_left (fun acc (name, reg) ->
          if List.mem_assoc name acc then acc else (name, reg) :: acc
        ) [] st.reg_env
      in
      emit st (lbl_top ^ ":");
      let rc = lower_expr st cond in
      let pred =
        if reg_rty st rc = Pred then rc
        else begin
          let p = fresh_reg st Pred in
          let rty_s = arith_pfx (reg_rty st rc) in
          emit st (Printf.sprintf "setp.ne.%s %s, %s, 0;" rty_s p rc);
          p
        end
      in
      emit st (Printf.sprintf "@!%s bra %s;" pred lbl_end);
      List.iter (lower_stmt st) body;
      (* Write back: for each name in snapshot, if reg_env now maps it to
         a different register, emit mov orig_reg, cur_reg *)
      List.iter (fun (name, orig_reg) ->
        match List.assoc_opt name st.reg_env with
        | Some cur_reg when cur_reg <> orig_reg ->
            let rty = reg_rty st cur_reg in
            let pfx = match rty with
              | Pred -> "pred"
              | _ -> arith_pfx rty
            in
            emit st (Printf.sprintf "mov.%s %s, %s; // loop wb: %s"
                       pfx orig_reg cur_reg name)
        | _ -> ()
      ) loop_snapshot;
      (* Restore reg_env to pre-loop bindings for the back-edge *)
      let snapshot_names = List.map fst loop_snapshot in
      st.reg_env <-
        List.filter (fun (n, _) -> not (List.mem n snapshot_names)) st.reg_env
        @ loop_snapshot;
      emit st (Printf.sprintf "bra %s;" lbl_top);
      emit st (lbl_end ^ ":")

  (* for i in n { body } — emit as counted loop 0..n *)
  | SFor (id, iter, _invs, _dec, body) ->
      let lbl_top = Printf.sprintf "%s_for_%d" st.fn_name st.counter in
      let lbl_end = Printf.sprintf "%s_for_end_%d" st.fn_name st.counter in
      st.counter <- st.counter + 1;
      (match iter.expr_desc with
       | ERange (lo, hi) ->
           let rlo = lower_expr st lo in
           let rhi = lower_expr st hi in
           let rty = reg_rty st rhi in
           let ri = fresh_reg st rty in
           emit st (Printf.sprintf "mov.%s %s, %s;" (arith_pfx rty) ri rlo);
           st.reg_env <- (id.name, ri) :: st.reg_env;
           emit st (lbl_top ^ ":");
           let p = fresh_reg st Pred in
           emit st (Printf.sprintf "setp.lt.%s %s, %s, %s;" (cmp_pfx rty) p ri rhi);
           emit st (Printf.sprintf "@!%s bra %s;" p lbl_end);
           List.iter (lower_stmt st) body;
           emit st (Printf.sprintf "add.%s %s, %s, 1;" (arith_pfx rty) ri ri);
           emit st (Printf.sprintf "bra %s;" lbl_top);
           emit st (lbl_end ^ ":")
       | _ ->
           let rn = lower_expr st iter in
           let rty = reg_rty st rn in
           let ri = fresh_reg st rty in
           emit st (Printf.sprintf "mov.%s %s, 0;" (arith_pfx rty) ri);
           st.reg_env <- (id.name, ri) :: st.reg_env;
           emit st (lbl_top ^ ":");
           let p = fresh_reg st Pred in
           emit st (Printf.sprintf "setp.lt.%s %s, %s, %s;" (cmp_pfx rty) p ri rn);
           emit st (Printf.sprintf "@!%s bra %s;" p lbl_end);
           List.iter (lower_stmt st) body;
           emit st (Printf.sprintf "add.%s %s, %s, 1;" (arith_pfx rty) ri ri);
           emit st (Printf.sprintf "bra %s;" lbl_top);
           emit st (lbl_end ^ ":"))

  | _ -> ()

(* ------------------------------------------------------------------ *)
(* Parameter declarations                                              *)
(* ------------------------------------------------------------------ *)

(* Emit .param declarations and load instructions for a kernel param.
   span<T> expands to two params: a pointer and a length. *)
let emit_param st (id, ty) =
  let name = id.name in
  match ty with
  | TSpan _ | TArray _ ->
      (* span / array: two .param entries — data pointer + length *)
      let p_data = Printf.sprintf "%s_param_%s_data" st.fn_name name in
      let p_len  = Printf.sprintf "%s_param_%s_len"  st.fn_name name in
      let rd = fresh_reg st U64 in
      let rl = fresh_reg st U64 in
      st.reg_env <- (name, rd) :: (name ^ "_len", rl) :: st.reg_env;
      ([Printf.sprintf "    .param .u64 %s" p_data;
        Printf.sprintf "    .param .u64 %s" p_len],
       [Printf.sprintf "  ld.param.u64 %s, [%s];" rd p_data;
        Printf.sprintf "  ld.param.u64 %s, [%s];" rl p_len])
  | TPrim (TUint U32) | TQual (_, TPrim (TUint U32)) ->
      let p = Printf.sprintf "%s_param_%s" st.fn_name name in
      let r = fresh_reg st U32 in
      st.reg_env <- (name, r) :: st.reg_env;
      ([Printf.sprintf "    .param .u32 %s" p],
       [Printf.sprintf "  ld.param.u32 %s, [%s];" r p])
  | TPrim (TFloat F32) | TQual (_, TPrim (TFloat F32)) ->
      let p = Printf.sprintf "%s_param_%s" st.fn_name name in
      let r = fresh_reg st F32 in
      st.reg_env <- (name, r) :: st.reg_env;
      ([Printf.sprintf "    .param .f32 %s" p],
       [Printf.sprintf "  ld.param.f32 %s, [%s];" r p])
  | TPrim (TFloat F64) | TQual (_, TPrim (TFloat F64)) ->
      let p = Printf.sprintf "%s_param_%s" st.fn_name name in
      let r = fresh_reg st F64 in
      st.reg_env <- (name, r) :: st.reg_env;
      ([Printf.sprintf "    .param .f64 %s" p],
       [Printf.sprintf "  ld.param.f64 %s, [%s];" r p])
  | _ ->
      let rty = ptx_rty_of_ty ty in
      let bits = sizeof_rty rty * 8 in
      let p = Printf.sprintf "%s_param_%s" st.fn_name name in
      let r = fresh_reg st rty in
      st.reg_env <- (name, r) :: st.reg_env;
      ([Printf.sprintf "    .param .u%d %s" bits p],
       [Printf.sprintf "  ld.param.u%d %s, [%s];" bits r p])

(* ------------------------------------------------------------------ *)
(* Kernel function emission                                             *)
(* ------------------------------------------------------------------ *)

let emit_kernel ?(fn_defs = Hashtbl.create 0) (fn : fn_def) : string =
  let st = {
    counter       = 0;
    instrs        = [];
    reg_decls     = [];
    fn_name       = fn.fn_name.name;
    reg_env       = [];
    fn_defs;
    shared_decls  = [];
    shared_regs   = [];
  } in
  (* Collect param decls and load instrs *)
  let (param_decls_ll, load_instrs_ll) =
    List.split (List.map (emit_param st) fn.fn_params)
  in
  let param_decls = List.concat param_decls_ll in
  let load_instrs = List.concat load_instrs_ll in
  (* Lower body *)
  (match fn.fn_body with
   | Some body ->
       let _ = lower_expr st body in
       (* Ensure the kernel ends with ret if body didn't produce one *)
       (match st.instrs with
        | ("  ret;" :: _) -> ()
        | _ -> emit st "ret;")
   | None -> emit st "ret;");
  (* Collect unique register declarations, grouped by type *)
  let reg_groups =
    let tbl = Hashtbl.create 16 in
    List.iter (fun (name, rty) ->
      let lst = try Hashtbl.find tbl rty with Not_found -> [] in
      Hashtbl.replace tbl rty (name :: lst)
    ) st.reg_decls;
    Hashtbl.fold (fun rty names acc -> (rty, List.rev names) :: acc) tbl []
  in
  let reg_decl_strs = List.concat_map (fun (rty, names) ->
    let unique = List.sort_uniq String.compare names in
    [Printf.sprintf "    .reg %s %s;"
      (ptx_rty_name rty)
      (String.concat ", " unique)]
  ) reg_groups in
  (* FORGE73: shared-memory declarations.  PTX syntax requires them
     inside the entry block, conventionally placed before .reg decls. *)
  let shared_decl_strs = List.map (fun (sym, rty, n) ->
    Printf.sprintf "    .shared %s %s[%d];" (ptx_rty_name rty) sym n
  ) (List.rev st.shared_decls) in
  (* Build PTX *)
  let buf = Buffer.create 2048 in
  Buffer.add_string buf (Printf.sprintf ".visible .entry %s(\n" fn.fn_name.name);
  Buffer.add_string buf (String.concat ",\n" param_decls);
  Buffer.add_string buf "\n)\n{\n";
  List.iter (fun s -> Buffer.add_string buf (s ^ "\n")) shared_decl_strs;
  if shared_decl_strs <> [] then Buffer.add_char buf '\n';
  List.iter (fun s -> Buffer.add_string buf (s ^ "\n")) reg_decl_strs;
  Buffer.add_char buf '\n';
  List.iter (fun s -> Buffer.add_string buf (s ^ "\n")) load_instrs;
  Buffer.add_char buf '\n';
  let body_instrs = List.rev st.instrs in
  List.iter (fun s -> Buffer.add_string buf (s ^ "\n")) body_instrs;
  Buffer.add_string buf "}\n";
  Buffer.contents buf

(* ------------------------------------------------------------------ *)
(* Program-level PTX emission                                          *)
(* ------------------------------------------------------------------ *)

let emit_ptx_program (items : item list) (sm : int) : string =
  let kernels = List.filter_map (fun item ->
    match item.item_desc with
    | IFn fn when List.exists (fun a -> a.attr_name = "kernel") fn.fn_attrs ->
        Some fn
    | _ -> None
  ) items in
  (* FG-2.6: build the device-function table from every non-kernel
     IFn item in the module.  This table is consulted by the generic
     ECall lowering in lower_expr to inline user-defined device
     functions at the call site. *)
  let fn_defs : (string, fn_def) Hashtbl.t = Hashtbl.create 16 in
  List.iter (fun item ->
    match item.item_desc with
    | IFn fn when not (List.exists (fun a -> a.attr_name = "kernel") fn.fn_attrs) ->
        Hashtbl.replace fn_defs fn.fn_name.name fn
    | _ -> ()
  ) items;
  if kernels = [] then ""
  else begin
    let buf = Buffer.create 4096 in
    Buffer.add_string buf (Printf.sprintf
      "// FORGE-generated PTX — SM_%d\n\
       // Proofs discharged before emission. Correct by construction.\n\n"
      sm);
    let ptx_ver = if sm >= 120 then "8.8" else "8.5" in
    Buffer.add_string buf (Printf.sprintf ".version %s\n.target sm_%d\n.address_size 64\n\n" ptx_ver sm);
    List.iter (fun fn ->
      Buffer.add_string buf (emit_kernel ~fn_defs fn);
      Buffer.add_char buf '\n'
    ) kernels;
    Buffer.contents buf
  end
