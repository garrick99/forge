(* FORGE Codegen — emits C99 or CUDA C

   Proofs are fully erased before this stage.
   The output is exactly what you'd write in C/CUDA if you were perfect.

   No bounds checks. No null checks. No overflow checks.
   They were proven away.

   Mode selection:
     - If any function has #[kernel] or #[device]: emit CUDA C (.cu)
     - Otherwise: emit plain C99 (.c) *)

open Ast

(* ------------------------------------------------------------------ *)
(* Type name mangling — produces a C-identifier-safe name for a type  *)
(* ------------------------------------------------------------------ *)

let rec mangle_ty_id = function
  | TPrim (TInt I8)    -> "i8"   | TPrim (TInt I16)   -> "i16"
  | TPrim (TInt I32)   -> "i32"  | TPrim (TInt I64)   -> "i64"
  | TPrim (TInt I128)  -> "i128" | TPrim (TInt ISize)  -> "isize"
  | TPrim (TUint U8)   -> "u8"   | TPrim (TUint U16)  -> "u16"
  | TPrim (TUint U32)  -> "u32"  | TPrim (TUint U64)  -> "u64"
  | TPrim (TUint U128) -> "u128" | TPrim (TUint USize) -> "usize"
  | TPrim (TFloat F32) -> "f32"  | TPrim (TFloat F64)  -> "f64"
  | TPrim TBool        -> "bool" | TPrim TUnit         -> "unit"
  | TPrim TNever       -> "never"
  | TRefined (p, _, _) -> mangle_ty_id (TPrim p)
  | TRef t             -> "ref_" ^ mangle_ty_id t
  | TRefMut t          -> "refmut_" ^ mangle_ty_id t
  | TOwn t             -> mangle_ty_id t
  | TRaw t             -> "ptr_" ^ mangle_ty_id t
  | TSlice t           -> "slice_" ^ mangle_ty_id t
  | TArray (t, _)      -> "arr_" ^ mangle_ty_id t
  | TNamed ({name="secret"; _}, [t]) -> mangle_ty_id t
  | TNamed (id, _)     -> id.name
  | TSpan t            -> "span_" ^ mangle_ty_id t
  | TShared (t, _)     -> mangle_ty_id t
  | TQual (_, t)       -> mangle_ty_id t
  | TSecret t          -> mangle_ty_id t
  | _                  -> "opaque"

(* ------------------------------------------------------------------ *)
(* Collect all unique span element types used in the program           *)
(* ------------------------------------------------------------------ *)

let rec collect_span_elems_ty acc = function
  | TSpan t  ->
      let key = mangle_ty_id t in
      if List.mem_assoc key acc then acc
      else (key, t) :: collect_span_elems_ty acc t
  | TRef t | TRefMut t | TOwn t | TRaw t | TSlice t -> collect_span_elems_ty acc t
  | TArray (t, _) | TShared (t, _) -> collect_span_elems_ty acc t
  | TQual (_, t) | TSecret t -> collect_span_elems_ty acc t
  | TFn fty ->
      let acc = List.fold_left (fun a (_, t) -> collect_span_elems_ty a t) acc fty.params in
      collect_span_elems_ty acc fty.ret
  | _ -> acc

let collect_span_elems_item acc item =
  match item.item_desc with
  | IFn fn ->
      let acc = List.fold_left (fun a (_, t) -> collect_span_elems_ty a t) acc fn.fn_params in
      collect_span_elems_ty acc fn.fn_ret
  | IStruct sd ->
      List.fold_left (fun a (_, t) -> collect_span_elems_ty a t) acc sd.sd_fields
  | IExtern ex -> collect_span_elems_ty acc ex.ex_ty
  | IType td   -> collect_span_elems_ty acc td.td_ty
  | _ -> acc

(* ------------------------------------------------------------------ *)
(* Enum constructor registry                                           *)
(*                                                                     *)
(* Maps ctor_name -> (enum_name, tag_index, field_types).             *)
(* Populated at emit_program time; used in emit_expr and emit_match.  *)
(* ------------------------------------------------------------------ *)

let enum_ctors : (string * (string * int * ty list)) list ref = ref []

(* Maps enum_cname -> variant_names in tag order.
   Used by or_return / or_fail to identify Ok/Err variants. *)
let enum_order : (string * string list) list ref = ref []

(* Reset all global codegen state.  Call at the start of each compilation
   to prevent stale state from a previous build (e.g., in check-only mode
   that never calls emit_program / build_enum_registry). *)
let reset_codegen_state () =
  enum_ctors := [];
  enum_order := []

let build_enum_registry items =
  enum_ctors := [];
  enum_order := [];
  List.iter (fun item ->
    match item.item_desc with
    | IEnum ed when ed.ed_params = [] ->
        (* Non-generic: register constructors under their own names *)
        let vnames = List.map (fun (vname, _) -> vname.name) ed.ed_variants in
        enum_order := (ed.ed_name.name, vnames) :: !enum_order;
        List.iteri (fun tag (vname, fields) ->
          enum_ctors := (vname.name, (ed.ed_name.name, tag, fields)) :: !enum_ctors
        ) ed.ed_variants
    | _ -> ()
  ) items

(* Register a monomorphized generic enum instance.
   e.g., Option<u32>: adds ("None", ("Option_u32", 0, [])) etc.
   Uses expr_ty on call sites to pick the right enum struct. *)
let register_generic_instance enum_name concrete_name tag_fields =
  (* Register variant order for this concrete instance *)
  if not (List.mem_assoc concrete_name !enum_order) then begin
    let vnames = List.map (fun (vname, _) -> vname.name) tag_fields in
    enum_order := (concrete_name, vnames) :: !enum_order
  end;
  List.iteri (fun tag (vname, fields) ->
    (* Only register if not already there for this concrete type *)
    let key = vname.name ^ "__" ^ concrete_name in
    if not (List.mem_assoc key !enum_ctors) then
      enum_ctors := (key, (concrete_name, tag, fields)) :: !enum_ctors;
    (* Also register without suffix as fallback, first instance wins *)
    if not (List.mem_assoc vname.name !enum_ctors) then
      enum_ctors := (vname.name, (concrete_name, tag, fields)) :: !enum_ctors;
    ignore enum_name
  ) tag_fields

(* Substitute type variables in a type (codegen side) *)
let rec subst_ty_c (s : (string * ty) list) = function
  | TNamed (id, []) when List.mem_assoc id.name s -> List.assoc id.name s
  | TNamed (id, args) -> TNamed (id, List.map (subst_ty_c s) args)
  | TSpan t     -> TSpan (subst_ty_c s t)
  | TRef t      -> TRef (subst_ty_c s t)
  | TRefMut t   -> TRefMut (subst_ty_c s t)
  | TOwn t      -> TOwn (subst_ty_c s t)
  | TRaw t      -> TRaw (subst_ty_c s t)
  | TArray (t, e) -> TArray (subst_ty_c s t, e)
  | TSlice t    -> TSlice (subst_ty_c s t)
  | other       -> other

(* Emit a concrete (monomorphized) generic enum, e.g. Option<u32> → Option_u32 *)
let emit_generic_enum_instance ed ty_args =
  let param_names = List.map (fun (p, _) -> p.name) ed.ed_params in
  let type_subst = List.combine param_names ty_args in
  let mangled = ed.ed_name.name ^ "_" ^ String.concat "_" (List.map mangle_ty_id ty_args) in
  let concrete_variants = List.map (fun (vname, fields) ->
    (vname, List.map (subst_ty_c type_subst) fields)
  ) ed.ed_variants in
  (* Register in enum_ctors *)
  register_generic_instance ed.ed_name.name mangled concrete_variants;
  (* Emit the concrete typedef *)
  let concrete_ed = {
    ed_name     = { ed.ed_name with name = mangled };
    ed_params   = [];
    ed_variants = concrete_variants;
  } in
  concrete_ed  (* returned for emit_enum call *)

(* ------------------------------------------------------------------ *)
(* C type emission                                                      *)
(* ------------------------------------------------------------------ *)

let rec emit_ty = function
  | TPrim (TInt I8)    -> "int8_t"
  | TPrim (TInt I16)   -> "int16_t"
  | TPrim (TInt I32)   -> "int32_t"
  | TPrim (TInt I64)   -> "int64_t"
  | TPrim (TInt I128)  -> "__int128"
  | TPrim (TInt ISize) -> "intptr_t"
  | TPrim (TUint U8)   -> "uint8_t"
  | TPrim (TUint U16)  -> "uint16_t"
  | TPrim (TUint U32)  -> "uint32_t"
  | TPrim (TUint U64)  -> "uint64_t"
  | TPrim (TUint U128) -> "unsigned __int128"
  | TPrim (TUint USize)-> "uintptr_t"
  | TPrim (TFloat F32) -> "float"
  | TPrim (TFloat F64) -> "double"
  | TPrim TBool        -> "_Bool"
  | TPrim TUnit        -> "void"
  | TPrim TNever       -> "void"  (* unreachable *)
  | TRefined (base, _, _) -> emit_ty (TPrim base)  (* refinements erased *)
  | TRef t             -> Printf.sprintf "const %s*" (emit_ty t)
  | TRefMut t          -> Printf.sprintf "%s*" (emit_ty t)
  | TOwn t             -> emit_ty t     (* ownership erased *)
  | TRaw t             -> Printf.sprintf "%s*" (emit_ty t)
  | TArray (t, Some _n) ->
      (* In type-only position (param decls, forward decls): arrays decay to pointer.
         SLet declaration sites emit T name[N] directly — see emit_stmt. *)
      emit_ty t ^ "*"
  | TSlice t           -> emit_ty t ^ "*"
  | TNamed ({name="secret"; _}, [t]) -> "volatile " ^ emit_ty t
  | TNamed (id, [])    -> id.name
  | TNamed (id, args)  ->
      (* Monomorphized generic: Option<u32> → Option_u32 *)
      id.name ^ "_" ^ String.concat "_" (List.map mangle_ty_id args)
  | TArray (t, None)   -> emit_ty t ^ "*"
  | TDepArr (_, _, r)  -> emit_ty r
  | TFn _              -> "void*"   (* function pointers — TODO *)
  (* GPU / span types *)
  | TSpan t   ->
      (* Use a typedef name: forge_span_<mangled_elem>_t.
         The typedef is emitted by emit_program before first use. *)
      Printf.sprintf "forge_span_%s_t" (mangle_ty_id t)
  | TShared (t, _) ->
      (* __shared__ qualifier added at declaration site; element type here *)
      emit_ty t
  | TQual (_, t)   -> emit_ty t   (* uniform/varying erased — proof artifact *)
  | TSecret t      -> "volatile " ^ emit_ty t  (* secret<T> → volatile T in C *)

(* Return-type emission: volatile is meaningless on function return types in C.
   Strip TSecret / TNamed("secret",[t]) wrappers so gcc -Wignored-qualifiers is silent. *)
let emit_ret_ty = function
  | TSecret t                        -> emit_ty t
  | TNamed ({name="secret"; _}, [t]) -> emit_ty t
  | t                                -> emit_ty t

(* ------------------------------------------------------------------ *)
(* Expression emission                                                  *)
(* ------------------------------------------------------------------ *)

let binop_str = function
  | Add     -> "+"  | Sub     -> "-"  | Mul -> "*"
  | Div     -> "/"  | Mod     -> "%"
  | Eq      -> "==" | Ne      -> "!="
  | Lt      -> "<"  | Le      -> "<=" | Gt  -> ">" | Ge -> ">="
  | And     -> "&&" | Or      -> "||"
  | BitAnd  -> "&"  | BitOr   -> "|"  | BitXor -> "^"
  | Shl     -> "<<" | Shr     -> ">>"
  (* Implies and Iff are proof-only connectives and should not appear at runtime.
     If they somehow reach codegen (e.g., via assume()), emit correct C:
       a ==> b  is  !a || b
       a <=> b  is  a == b  (valid for booleans only)
     Implies is handled specially in emit_expr; this fallback handles Iff. *)
  | Implies -> "||" (* overridden in emit_expr to emit (!a || b) *)
  | Iff     -> "==" (* valid for bool operands *)

let unop_str = function
  | Neg    -> "-"
  | Not    -> "!"
  | BitNot -> "~"

let indent n = String.make (n * 2) ' '

(* C keyword blacklist — FORGE names that clash with C keywords get a 'forge_' prefix *)
let c_keywords = [
  (* C89/C90 *)
  "auto"; "break"; "case"; "char"; "const"; "continue"; "default"; "do";
  "double"; "else"; "enum"; "extern"; "float"; "for"; "goto"; "if";
  "int"; "long"; "register"; "return"; "short"; "signed"; "sizeof";
  "static"; "struct"; "switch"; "typedef"; "union"; "unsigned"; "void";
  "volatile"; "while";
  (* C99 *)
  "inline"; "restrict"; "_Bool"; "_Complex"; "_Imaginary";
  (* C11 *)
  "_Alignas"; "_Alignof"; "_Atomic"; "_Generic"; "_Noreturn";
  "_Static_assert"; "_Thread_local";
  (* Common extensions / C23 keywords used in FORGE-generated headers *)
  "alignas"; "alignof"; "bool"; "noreturn"; "static_assert"; "thread_local";
  (* CUDA extensions that FORGE emits *)
  "__global__"; "__device__"; "__host__"; "__shared__"; "__restrict__"
]

let c_safe_name name =
  if List.mem name c_keywords then "forge_" ^ name else name

let rec emit_expr depth e =
  match e.expr_desc with
  | ELit (LInt (n, _))    -> Int64.to_string n
  | ELit (LFloat (f, _))  -> Printf.sprintf "%g" f
  | ELit (LBool true)     -> "1"
  | ELit (LBool false)    -> "0"
  | ELit LUnit            -> "/* unit */"
  | ELit (LStr s)         -> Printf.sprintf "\"%s\"" (String.escaped s)
  | EVar id when List.mem_assoc id.name !enum_ctors ->
      (* Unit enum constructor: emit as struct literal.
         Use expr_ty to pick the correct monomorphized name for generic enums. *)
      let concrete_name = match e.expr_ty with
        | Some (TNamed (eid, (_ :: _ as args))) ->
            eid.name ^ "_" ^ String.concat "_" (List.map mangle_ty_id args)
        | Some (TNamed (eid, [])) -> eid.name
        | _ ->
            let (n, _, _) = List.assoc id.name !enum_ctors in n
      in
      let tag_key = id.name ^ "__" ^ concrete_name in
      let (_, _tag, fields) =
        match List.assoc_opt tag_key !enum_ctors with
        | Some v -> v
        | None   -> List.assoc id.name !enum_ctors
      in
      if fields = [] then
        Printf.sprintf "(%s){ .tag = %s_tag_%s, .data.%s = { ._dummy = 0 } }"
          concrete_name concrete_name id.name id.name
      else
        id.name   (* has fields but used as var — unusual, just fall through *)
  | EVar id               -> c_safe_name id.name
  | EBinop (Implies, l, r) ->
      (* a ==> b  ≡  !a || b  (correct C for implication) *)
      Printf.sprintf "(!%s || %s)" (emit_expr depth l) (emit_expr depth r)
  | EBinop (op, l, r)     ->
      Printf.sprintf "(%s %s %s)"
        (emit_expr depth l) (binop_str op) (emit_expr depth r)
  | EUnop (op, e)         ->
      Printf.sprintf "(%s%s)" (unop_str op) (emit_expr depth e)
  | ECall ({ expr_desc = EVar ctor_id; _ }, args)
    when List.mem_assoc ctor_id.name !enum_ctors ->
      (* Enum constructor call: use expr_ty for monomorphized name *)
      let concrete_name = match e.expr_ty with
        | Some (TNamed (eid, (_ :: _ as type_args))) ->
            eid.name ^ "_" ^ String.concat "_" (List.map mangle_ty_id type_args)
        | Some (TNamed (eid, [])) -> eid.name
        | _ ->
            let (n, _, _) = List.assoc ctor_id.name !enum_ctors in n
      in
      let tag_key = ctor_id.name ^ "__" ^ concrete_name in
      let (_, _tag, fields) =
        match List.assoc_opt tag_key !enum_ctors with
        | Some v -> v
        | None   -> List.assoc ctor_id.name !enum_ctors
      in
      let n = min (List.length fields) (List.length args) in
      let field_strs = List.init n (fun i ->
        Printf.sprintf "._v%d = %s" i (emit_expr depth (List.nth args i))
      ) in
      let data_str = if field_strs = [] then "{ ._dummy = 0 }"
                     else Printf.sprintf "{ %s }" (String.concat ", " field_strs) in
      Printf.sprintf "(%s){ .tag = %s_tag_%s, .data.%s = %s }"
        concrete_name concrete_name ctor_id.name ctor_id.name data_str
  (* declassify(x) — strip secret wrapper; emits the argument unchanged *)
  | ECall ({ expr_desc = EVar id; _ }, [arg])
    when id.name = "declassify" ->
      emit_expr depth arg
  (* or_return / or_fail intrinsics *)
  | ECall ({ expr_desc = EVar id; _ }, [value_expr; alt_expr])
    when id.name = "__or_return__" || id.name = "__or_fail__" ->
      let enum_cname = match value_expr.expr_ty with
        | Some t -> emit_ty t | None -> "UnknownEnum"
      in
      (* Look up the variant order: first = Ok/Some, second = Err/None *)
      let (ok_var, err_var) = match List.assoc_opt enum_cname !enum_order with
        | Some (ok :: err :: _) -> (ok, err)
        | Some [ok] -> (ok, "Err")
        | _ -> ("Ok", "Err")
      in
      let tmp = "__or_tmp__" in
      let action = if id.name = "__or_return__" then
        Printf.sprintf "return %s" (emit_expr depth alt_expr)
      else
        Printf.sprintf "(void)(%s); abort()" (emit_expr depth alt_expr)
      in
      (* Check if Ok variant has a payload field *)
      let has_payload =
        let key = ok_var ^ "__" ^ enum_cname in
        match List.assoc_opt key !enum_ctors with
        | Some (_, _, _ :: _) -> true
        | None ->
            (match List.assoc_opt ok_var !enum_ctors with
             | Some (_, _, _ :: _) -> true | _ -> false)
        | _ -> false
      in
      let payload = if has_payload then
        Printf.sprintf "%s.data.%s._v0" tmp ok_var
      else
        Printf.sprintf "((%s)0)" enum_cname
      in
      Printf.sprintf
        "({ %s %s = %s; if (%s.tag == %s_tag_%s) { %s; } %s; })"
        enum_cname tmp (emit_expr depth value_expr)
        tmp enum_cname err_var
        action
        payload
  (* Method call dispatch: obj.method(args) → TypeName__method(obj, args) *)
  | ECall ({ expr_desc = EField (obj, method_name); _ }, args) ->
      let type_name = match obj.expr_ty with
        | Some (TNamed (id, [])) | Some (TQual (_, TNamed (id, []))) -> id.name
        | _ -> ""
      in
      let mangled = if type_name = "" then "" else type_name ^ "__" ^ method_name.name in
      if mangled <> "" then
        Printf.sprintf "%s(%s)" mangled
          (String.concat ", " (List.map (emit_expr depth) (obj :: args)))
      else
        Printf.sprintf "%s.%s(%s)"
          (emit_expr depth obj) method_name.name
          (String.concat ", " (List.map (emit_expr depth) args))
  | ECall (f, args)       ->
      Printf.sprintf "%s(%s)"
        (emit_expr depth f)
        (String.concat ", " (List.map (emit_expr depth) args))
  | EIndex (arr, idx)     ->
      let arr_s = emit_expr depth arr in
      let idx_s = emit_expr depth idx in
      (* span<T> carries data + len; indexing goes through .data *)
      (match arr.expr_ty with
       | Some (TSpan _) | Some (TQual (_, TSpan _)) ->
           Printf.sprintf "%s.data[%s]" arr_s idx_s
       | _ ->
           Printf.sprintf "%s[%s]" arr_s idx_s)
  | EField (s, f)         ->
      Printf.sprintf "%s.%s" (emit_expr depth s) f.name
  | EAssign (l, r)        ->
      Printf.sprintf "%s = %s" (emit_expr depth l) (emit_expr depth r)
  | ERef e                -> Printf.sprintf "(&%s)" (emit_expr depth e)
  | ERefMut e             -> Printf.sprintf "(&%s)" (emit_expr depth e)
  | EDeref e              -> Printf.sprintf "(*%s)" (emit_expr depth e)
  | ECast (e, ty)         ->
      Printf.sprintf "((%s)%s)" (emit_ty ty) (emit_expr depth e)
  | EIf (cond, then_, None) ->
      (* Any EBlock branch → emit as C if-statement (not ternary).
         Ternaries can't contain statement-blocks in standard C99. *)
      (match then_.expr_desc with
       | EBlock _ ->
           Printf.sprintf "if (%s) %s"
             (emit_expr depth cond) (emit_expr depth then_)
       | _ ->
           Printf.sprintf "(%s ? %s : (void)0)"
             (emit_expr depth cond) (emit_expr_value depth then_))
  | EIf (cond, then_, Some else_) ->
      let then_is_block = match then_.expr_desc with EBlock _ -> true | _ -> false in
      let else_is_block = match else_.expr_desc with EBlock _ -> true | _ -> false in
      if then_is_block || else_is_block then
        Printf.sprintf "if (%s) %s else %s"
          (emit_expr depth cond)
          (emit_expr depth then_)
          (emit_expr depth else_)
      else
        Printf.sprintf "(%s ? %s : %s)"
          (emit_expr depth cond)
          (emit_expr_value depth then_)
          (emit_expr_value depth else_)
  | EBlock (stmts, ret) ->
      let buf = Buffer.create 256 in
      Buffer.add_string buf "{\n";
      List.iter (fun s ->
        Buffer.add_string buf (emit_stmt (depth+1) s);
        Buffer.add_char buf '\n'
      ) stmts;
      (match ret with
       | Some e ->
           Buffer.add_string buf (indent (depth+1));
           Buffer.add_string buf (emit_expr (depth+1) e);
           Buffer.add_string buf ";"   (* always valid — expr as stmt in C *)
       | None -> ());
      Buffer.add_string buf ("\n" ^ indent depth ^ "}");
      Buffer.contents buf
  | EMatch (e, arms) ->
      emit_match depth e arms
  | EStruct (name, fields) ->
      (* Emit C designated initializer: (TypeName){ .field = val, ... } *)
      let field_strs = List.map (fun (fname, fexpr) ->
        Printf.sprintf ".%s = %s" fname.name (emit_expr depth fexpr)
      ) fields in
      Printf.sprintf "(%s){ %s }" name.name (String.concat ", " field_strs)
  | EProof _  -> "/* proof erased */"
  | ERaw rb   ->
      let buf = Buffer.create 64 in
      List.iter (fun s ->
        Buffer.add_string buf (emit_stmt depth s)
      ) rb.rb_stmts;
      Buffer.contents buf
  | EAssume _ -> "/* assume erased */"  (* proof artifact — gone at codegen *)
  | ESync     -> "__syncthreads()"
  | EArrayLit elems ->
      "{ " ^ String.concat ", " (List.map (emit_expr depth) elems) ^ " }"
  | EArrayRepeat (v, _n) ->
      (* C99 compound literal initializer: {val} zero-fills remaining elements.
         Correct for val==0; for non-zero val, a loop is needed post-declaration. *)
      (match v.expr_desc with
       | ELit (LInt (0L, _)) -> "{ 0 }"
       | _ -> Printf.sprintf "{ %s /* [val;N] — remaining elements zero */ }"
                (emit_expr depth v))

(* Unwrap EBlock([], Some e) to just e — for use in expression positions
   like ternary arms where a compound statement is not valid C *)
and emit_expr_value depth e =
  match e.expr_desc with
  | EBlock ([], Some ret) -> emit_expr depth ret
  | EBlock ([], None)     -> "0"
  | _                     -> emit_expr depth e

(* Emit an expression in return position.
   FORGE allows if-else, blocks, and match as expressions; C does not.
   We decompose them into statements with explicit 'return' in each branch.
   depth: indentation level of the enclosing function body. *)
and emit_as_return depth e =
  match e.expr_desc with
  | EIf (cond, then_, Some else_) ->
      let buf = Buffer.create 128 in
      Buffer.add_string buf (Printf.sprintf "%sif (%s) {\n"
        (indent depth) (emit_expr depth cond));
      Buffer.add_string buf (emit_as_return (depth+1) then_);
      Buffer.add_char buf '\n';
      Buffer.add_string buf (Printf.sprintf "%s} else {\n" (indent depth));
      Buffer.add_string buf (emit_as_return (depth+1) else_);
      Buffer.add_char buf '\n';
      Buffer.add_string buf (indent depth ^ "}");
      Buffer.contents buf
  | EIf (cond, then_, None) ->
      Printf.sprintf "%sif (%s) {\n%s\n%s}"
        (indent depth) (emit_expr depth cond)
        (emit_as_return (depth+1) then_)
        (indent depth)
  | EMatch (scrut, arms) ->
      (* Match in return position: switch where every case returns *)
      emit_match ~return_mode:true depth scrut arms
  | EBlock (stmts, Some ret) ->
      let buf = Buffer.create 256 in
      List.iter (fun s ->
        Buffer.add_string buf (emit_stmt depth s);
        Buffer.add_char buf '\n'
      ) stmts;
      Buffer.add_string buf (emit_as_return depth ret);
      Buffer.contents buf
  | EBlock (stmts, None) ->
      let buf = Buffer.create 256 in
      List.iter (fun s ->
        Buffer.add_string buf (emit_stmt depth s);
        Buffer.add_char buf '\n'
      ) stmts;
      Buffer.contents buf
  | _ ->
      Printf.sprintf "%sreturn %s;" (indent depth) (emit_expr depth e)

(* Emit field bindings for a PCtor arm.
   Skips wildcard (_) and PWild patterns. *)
and emit_field_bindings buf depth scrut_str ctor_name subpats fields =
  let n = min (List.length subpats) (List.length fields) in
  for i = 0 to n - 1 do
    let sp = List.nth subpats i in
    let ft = List.nth fields i in
    (match sp with
     | PBind id when id.name <> "_" ->
         Buffer.add_string buf
           (Printf.sprintf "%s%s %s = %s.data.%s._v%d;\n"
              (indent depth) (emit_ty ft) id.name
              scrut_str ctor_name i)
     | _ -> ())
  done

(* Emit a match expression.
   ~return_mode:true  → each case ends with 'return expr;'
   ~return_mode:false → each case ends with 'expr; break;'  (statement use) *)
(* Recursively collect PCtor names from an OR/single pattern *)
and ctor_names_of_pat = function
  | PCtor (id, _) -> [id.name]
  | PBind id      -> [id.name]   (* unit enum ctors parse as PBind (no parens) *)
  | PAs (pat, _)  -> ctor_names_of_pat pat
  | POr (p1, p2)  -> ctor_names_of_pat p1 @ ctor_names_of_pat p2
  | _             -> []

(* True if a pattern consists only of PCtor/POr/PWild/PBind/PAs nodes *)
and pat_is_ctor_or_wild = function
  | PCtor _ | PWild | PBind _ -> true
  | PAs (pat, _) -> pat_is_ctor_or_wild pat
  | POr (p1, p2) -> pat_is_ctor_or_wild p1 && pat_is_ctor_or_wild p2
  | _ -> false

and emit_match ?(return_mode=false) depth scrutinee arms =
  let buf = Buffer.create 256 in
  let scrut_str = emit_expr depth scrutinee in
  (* Helper: look up enum_name for a constructor, using the scrutinee's concrete type
     for generic enums (e.g. Option<u32> → Option_u32). *)
  let resolve_ctor_enum cname =
    let scrut_concrete = match scrutinee.expr_ty with
      | Some (TNamed (eid, (_ :: _ as targs))) ->
          Some (eid.name ^ "_" ^ String.concat "_" (List.map mangle_ty_id targs))
      | Some (TNamed (eid, [])) -> Some eid.name
      | _ -> None
    in
    match scrut_concrete with
    | Some cn ->
        let key = cname ^ "__" ^ cn in
        (match List.assoc_opt key !enum_ctors with
         | Some (ename, tag, fields) -> (ename, tag, fields)
         | None ->
             (match List.assoc_opt cname !enum_ctors with
              | Some v -> v | None -> (cn, 0, [])))
    | None ->
        (match List.assoc_opt cname !enum_ctors with
         | Some v -> v | None -> ("?", 0, []))
  in
  let all_ctors = List.for_all (fun arm -> pat_is_ctor_or_wild arm.pattern) arms in
  let rec pat_has_ctor = function
    | PCtor _ | POr _ -> true
    | PAs (p, _)      -> pat_has_ctor p
    | _               -> false
  in
  let has_ctor = List.exists (fun arm -> pat_has_ctor arm.pattern) arms in
  if all_ctors && has_ctor then begin
    Buffer.add_string buf (Printf.sprintf "%sswitch (%s.tag) {\n" (indent depth) scrut_str);
    (* PAs wrapping a ctor is a named case arm, not a default. *)
    let is_default_pat = function
      | PWild | PBind _ -> true
      | PAs (inner, _)  -> not (pat_has_ctor inner)
      | _               -> false
    in
    let has_default_arm = List.exists (fun arm -> is_default_pat arm.pattern) arms in
    (* Helper: emit optional alias binding and then the arm body *)
    let emit_arm_body_with_alias depth_here alias_opt body =
      (match alias_opt with
       | Some id ->
           let scrut_ty_str = match scrutinee.expr_ty with
             | Some t -> emit_ty t | None -> "void*"
           in
           Buffer.add_string buf (Printf.sprintf "%s%s %s __attribute__((unused)) = %s;\n"
             (indent depth_here) scrut_ty_str id.name scrut_str)
       | None -> ());
      if return_mode then begin
        Buffer.add_string buf (emit_as_return depth_here body);
        Buffer.add_char buf '\n'
      end else begin
        Buffer.add_string buf (emit_stmt depth_here
          { stmt_desc = SExpr body; stmt_loc = dummy_loc });
        Buffer.add_char buf '\n';
        Buffer.add_string buf (Printf.sprintf "%sbreak;\n" (indent depth_here))
      end
    in
    List.iter (fun arm ->
      (* Strip a top-level PAs wrapper, keeping the alias identifier *)
      let (inner_pat, alias_opt) = match arm.pattern with
        | PAs (p, id) -> (p, Some id)
        | p           -> (p, None)
      in
      (match inner_pat with
       | PCtor (ctor_id, subpats) ->
           let (enum_name, _tag, fields) = resolve_ctor_enum ctor_id.name in
           Buffer.add_string buf
             (Printf.sprintf "%scase %s_tag_%s: {\n" (indent (depth+1)) enum_name ctor_id.name);
           (* alias binding before field bindings so alias is in scope *)
           (match alias_opt with
            | Some id ->
                let scrut_ty_str = match scrutinee.expr_ty with
                  | Some t -> emit_ty t | None -> "void*"
                in
                Buffer.add_string buf (Printf.sprintf "%s%s %s __attribute__((unused)) = %s;\n"
                  (indent (depth+2)) scrut_ty_str id.name scrut_str)
            | None -> ());
           emit_field_bindings buf (depth+2) scrut_str ctor_id.name subpats fields;
           emit_arm_body_with_alias (depth+2) None arm.body;
           Buffer.add_string buf (Printf.sprintf "%s}\n" (indent (depth+1)))
       | POr _ ->
           (* OR pattern: emit fall-through case labels then a single body block *)
           let names = ctor_names_of_pat inner_pat in
           List.iter (fun cname ->
             let (enum_name, _, _) = resolve_ctor_enum cname in
             if enum_name <> "?" then
               Buffer.add_string buf
                 (Printf.sprintf "%scase %s_tag_%s:\n" (indent (depth+1)) enum_name cname)
           ) names;
           Buffer.add_string buf (Printf.sprintf "%s{\n" (indent (depth+1)));
           emit_arm_body_with_alias (depth+2) alias_opt arm.body;
           Buffer.add_string buf (Printf.sprintf "%s}\n" (indent (depth+1)))
       | PWild | PBind _ ->
           Buffer.add_string buf (Printf.sprintf "%sdefault: {\n" (indent (depth+1)));
           emit_arm_body_with_alias (depth+2) alias_opt arm.body;
           Buffer.add_string buf (Printf.sprintf "%s}\n" (indent (depth+1)))
       | _ ->
           Buffer.add_string buf (Printf.sprintf "%sdefault: break;\n" (indent (depth+1))))
    ) arms;
    (* If no wildcard/catch-all arm was emitted, add an unreachable default.
       FORGE proves match exhaustiveness — the default is dead code, but
       GCC/Clang need it to suppress "control reaches end of non-void function". *)
    if not has_default_arm then
      Buffer.add_string buf
        (Printf.sprintf "%sdefault: __builtin_unreachable();\n" (indent (depth+1)));
    Buffer.add_string buf (Printf.sprintf "%s}" (indent depth))
  end else begin
    (* Non-enum match: if-else chain *)
    let first = ref true in
    List.iter (fun arm ->
      let kw = if !first then "if" else "else if" in
      first := false;
      let cond = emit_pattern_cond depth scrutinee arm.pattern in
      (match arm.pattern with
       | PAs (_, id) ->
           (* PAs(pat, id): block scope so id can be declared before body *)
           let scrut_ty_str = match scrutinee.expr_ty with
             | Some t -> emit_ty t | None -> "void*"
           in
           Buffer.add_string buf
             (Printf.sprintf "%s%s (%s) {\n" (indent depth) kw cond);
           Buffer.add_string buf
             (Printf.sprintf "%s%s %s __attribute__((unused)) = %s;\n"
               (indent (depth+1)) scrut_ty_str id.name (emit_expr depth scrutinee));
           if return_mode then
             Buffer.add_string buf
               (Printf.sprintf "%s\n" (emit_as_return (depth+1) arm.body))
           else
             Buffer.add_string buf
               (Printf.sprintf "%s%s;\n"
                 (indent (depth+1)) (emit_expr (depth+1) arm.body));
           Buffer.add_string buf (Printf.sprintf "%s} " (indent depth))
       | _ ->
           if return_mode then
             Buffer.add_string buf
               (Printf.sprintf "%s%s (%s) {\n%s\n%s}\n"
                 (indent depth) kw cond
                 (emit_as_return (depth+1) arm.body)
                 (indent depth))
           else
             Buffer.add_string buf
               (Printf.sprintf "%s%s (%s) %s\n"
                 (indent depth) kw cond
                 (emit_expr depth arm.body)))
    ) arms
  end;
  Buffer.contents buf

and emit_pattern_cond depth scrutinee pat =
  let s = emit_expr depth scrutinee in
  match pat with
  | PWild        -> "1"
  | PBind _      -> "1"
  | PLit l       -> Printf.sprintf "%s == %s" s (emit_expr depth { expr_desc = ELit l; expr_loc = dummy_loc; expr_ty = None })
  | PCtor (id, _) ->
      (match List.assoc_opt id.name !enum_ctors with
       | Some (enum_name, _tag, _) ->
           Printf.sprintf "%s.tag == %s_tag_%s" s enum_name id.name
       | None ->
           Printf.sprintf "/* ctor %s */" id.name)
  | POr (p1, p2) ->
      Printf.sprintf "(%s || %s)"
        (emit_pattern_cond depth scrutinee p1)
        (emit_pattern_cond depth scrutinee p2)
  | PAs (pat, _) -> emit_pattern_cond depth scrutinee pat
  | _            -> "1 /* pattern */"

(* Emit an expression as an assignment to 'lhs'.
   Used when a value-producing if-else or match can't appear as a C rvalue.
   Mirrors emit_as_return but uses 'lhs = ...' instead of 'return ...'. *)
and emit_as_assign lhs depth e =
  match e.expr_desc with
  | EIf (cond, then_, Some else_) ->
      let buf = Buffer.create 128 in
      Buffer.add_string buf (Printf.sprintf "%sif (%s) {\n"
        (indent depth) (emit_expr depth cond));
      Buffer.add_string buf (emit_as_assign lhs (depth+1) then_);
      Buffer.add_char buf '\n';
      Buffer.add_string buf (Printf.sprintf "%s} else {\n" (indent depth));
      Buffer.add_string buf (emit_as_assign lhs (depth+1) else_);
      Buffer.add_char buf '\n';
      Buffer.add_string buf (indent depth ^ "}");
      Buffer.contents buf
  | EBlock (stmts, Some ret) ->
      let buf = Buffer.create 256 in
      List.iter (fun s ->
        Buffer.add_string buf (emit_stmt depth s);
        Buffer.add_char buf '\n'
      ) stmts;
      Buffer.add_string buf (emit_as_assign lhs depth ret);
      Buffer.contents buf
  | EBlock (_, None) ->
      Printf.sprintf "%s/* unit */" (indent depth)
  | _ ->
      Printf.sprintf "%s%s = %s;" (indent depth) lhs (emit_expr depth e)

(* ------------------------------------------------------------------ *)
(* Statement emission                                                   *)
(* ------------------------------------------------------------------ *)

and emit_stmt depth s =
  match s.stmt_desc with
  | SLet (id, ty, e, _lin) ->
      let ann_ty = match ty with Some t -> Some t | None -> e.expr_ty in
      (match ann_ty with
       | Some (TShared (elem_ty, sz_opt)) ->
           (* GPU shared memory: __shared__ T name[N]; *)
           let sz_str = match sz_opt with
             | Some n -> emit_expr depth n
             | None   -> "0 /* unknown size */"
           in
           Printf.sprintf "%s__shared__ %s %s[%s];"
             (indent depth) (emit_ty elem_ty) id.name sz_str
       | Some (TArray (elem_ty, Some n_expr)) when id.name <> "_" ->
           (* Stack-allocated fixed array: T name[N] = init; *)
           let n_str   = emit_expr depth n_expr in
           let init_str = emit_expr depth e in
           Printf.sprintf "%s%s %s[%s] = %s;"
             (indent depth) (emit_ty elem_ty) (c_safe_name id.name) n_str init_str
       | _ ->
           (* '_' is a throwaway — emit as (void) cast to suppress unused warnings
              and avoid redeclaration errors when multiple let _ = ... appear *)
           if id.name = "_" then
             Printf.sprintf "%s(void)(%s);" (indent depth) (emit_expr depth e)
           else
           let ty_str = match ann_ty with
             | Some t -> emit_ty t
             | None   -> Printf.sprintf "__typeof__(%s)" (emit_expr depth e)
           in
           (* Value-producing if-else/match with block branches can't appear as
              a C rvalue.  Split into: ty name;  if (cond) { name = ...; } ... *)
           let needs_split = match e.expr_desc with
             | EIf (_, then_, _) ->
                 (match then_.expr_desc with EBlock _ -> true | _ -> false)
             | EMatch _ -> true
             | _ -> false
           in
           if needs_split then
             Printf.sprintf "%s%s %s;\n%s"
               (indent depth) ty_str id.name
               (emit_as_assign id.name depth e)
           else
             Printf.sprintf "%s%s %s = %s;"
               (indent depth) ty_str id.name (emit_expr depth e))
  | SExpr e ->
      (* Determine if emit_expr will produce a complete C statement (if/block)
         that doesn't need a trailing semicolon, or an expression that does. *)
      let is_compound_stmt =
        match e.expr_desc with
        | EBlock _ -> true
        | EIf (_, then_, _) ->
            (* If we'll emit as an if-statement (not ternary), no semicolon needed.
               emit_expr uses if-statement form when then-branch is an EBlock. *)
            (match then_.expr_desc with EBlock _ -> true | _ -> false)
        | _ -> false
      in
      if is_compound_stmt then
        Printf.sprintf "%s%s" (indent depth) (emit_expr depth e)
      else
        Printf.sprintf "%s%s;" (indent depth) (emit_expr depth e)
  | SReturn None ->
      Printf.sprintf "%sreturn;" (indent depth)
  | SReturn (Some e) ->
      Printf.sprintf "%sreturn %s;" (indent depth) (emit_expr depth e)
  | SWhile (cond, _inv, _dec, body) ->
      let buf = Buffer.create 128 in
      Buffer.add_string buf
        (Printf.sprintf "%swhile (%s) {\n"
          (indent depth) (emit_expr depth cond));
      List.iter (fun s ->
        Buffer.add_string buf (emit_stmt (depth+1) s);
        Buffer.add_char buf '\n'
      ) body;
      Buffer.add_string buf (indent depth ^ "}");
      Buffer.contents buf
  | SFor (id, iter, _dec, body) ->
      (* Emit as: for (uint64_t id = 0; id < (uint64_t)(iter); id++) *)
      let buf = Buffer.create 128 in
      Buffer.add_string buf
        (Printf.sprintf "%sfor (uint64_t %s = 0; %s < (uint64_t)(%s); %s++) {\n"
          (indent depth) id.name id.name (emit_expr depth iter) id.name);
      List.iter (fun s ->
        Buffer.add_string buf (emit_stmt (depth+1) s);
        Buffer.add_char buf '\n'
      ) body;
      Buffer.add_string buf (indent depth ^ "}");
      Buffer.contents buf
  | SBreak    -> indent depth ^ "break;"
  | SContinue -> indent depth ^ "continue;"

(* ------------------------------------------------------------------ *)
(* Top-level item emission                                              *)
(* ------------------------------------------------------------------ *)

(* Return the CUDA qualifier prefix for a function's attribute list.
   #[kernel]      → __global__        (GPU entry point, called from host)
   #[device]      → __device__        (GPU helper, called from device only)
   #[host_device] → __host__ __device__ (callable from both)
   (no GPU attr)  → ""               (plain C / host function) *)
let gpu_qualifier attrs =
  if List.exists (fun a -> a.attr_name = "kernel") attrs then "__global__ "
  else if List.exists (fun a -> a.attr_name = "host_device") attrs then "__host__ __device__ "
  else if List.exists (fun a -> a.attr_name = "device") attrs then "__device__ "
  else ""

let emit_fn fn =
  let buf = Buffer.create 512 in
  (* GPU qualifier prefix — erased for non-GPU builds *)
  let qual = gpu_qualifier fn.fn_attrs in
  (* requires/ensures are fully erased — proof was discharged *)
  (* __attribute__((unused)) suppresses -Wunused-parameter for spec-only params *)
  let params_str = String.concat ", " (List.map (fun (id, ty) ->
    Printf.sprintf "%s %s __attribute__((unused))" (emit_ty ty) (c_safe_name id.name)
  ) fn.fn_params) in
  (* __global__ kernels must return void — CUDA enforces this; warn if mismatch *)
  let ret_ty =
    if qual = "__global__ " && fn.fn_ret <> TPrim TUnit then begin
      Printf.eprintf
        "  [warn] kernel '%s' has non-void return type — CUDA requires void; using void\n"
        fn.fn_name.name;
      TPrim TUnit
    end else fn.fn_ret
  in
  Buffer.add_string buf
    (Printf.sprintf "%s%s %s(%s)"
      qual (emit_ret_ty ret_ty) (c_safe_name fn.fn_name.name) params_str);
  (* Whether trailing expressions should become 'return expr' or just 'expr;'
     Void functions and kernels have no meaningful return value. *)
  let returns_value = ret_ty <> TPrim TUnit && ret_ty <> TPrim TNever in
  (match fn.fn_body with
   | None ->
       Buffer.add_string buf ";"  (* extern declaration *)
   | Some body ->
       Buffer.add_string buf " ";
       (* Emit function body.
          Value-returning fns: trailing expression → emit_as_return (handles if-else).
          Void fns: trailing expression → statement (no return keyword). *)
       (match body.expr_desc with
        | EBlock (stmts, ret) ->
            Buffer.add_string buf "{\n";
            List.iter (fun s ->
              Buffer.add_string buf (emit_stmt 1 s);
              Buffer.add_char buf '\n'
            ) stmts;
            (match ret with
             | Some e when returns_value ->
                 (* Use emit_as_return to handle if-else-as-expression correctly *)
                 Buffer.add_string buf (emit_as_return 1 e);
                 Buffer.add_char buf '\n'
             | Some e ->
                 (* Void fn trailing expr: side-effecting statement *)
                 let is_compound = match e.expr_desc with
                   | EBlock _ -> true
                   | EIf (_, then_, _) ->
                       (match then_.expr_desc with EBlock _ -> true | _ -> false)
                   | _ -> false
                 in
                 if is_compound then
                   Buffer.add_string buf (Printf.sprintf "  %s\n" (emit_expr 1 e))
                 else
                   Buffer.add_string buf (Printf.sprintf "  %s;\n" (emit_expr 1 e))
             | None -> ());
            Buffer.add_string buf "}"
        | _ when returns_value ->
            (* Simple non-block body: wrap in braces with return *)
            Buffer.add_string buf (Printf.sprintf "{\n%s\n}" (emit_as_return 1 body))
        | _ ->
            Buffer.add_string buf (Printf.sprintf "{ %s; }" (emit_expr 0 body))));
  Buffer.add_char buf '\n';
  Buffer.contents buf

let emit_struct sd =
  let buf = Buffer.create 256 in
  Buffer.add_string buf (Printf.sprintf "typedef struct %s {\n" sd.sd_name.name);
  List.iter (fun (id, ty) ->
    Buffer.add_string buf
      (Printf.sprintf "  %s %s;\n" (emit_ty ty) id.name)
  ) sd.sd_fields;
  (* struct invariants erased — proven at construction sites *)
  Buffer.add_string buf (Printf.sprintf "} %s;\n" sd.sd_name.name);
  Buffer.contents buf

(* Emit a FORGE enum as a C99 tagged union.
   enum Shape { Circle(f32), Rect(f32, f32) } becomes:
     typedef enum { Shape_tag_Circle = 0, Shape_tag_Rect = 1 } Shape_tag_t;
     typedef struct Shape {
       Shape_tag_t tag;
       union {
         struct { float _v0; } Circle;
         struct { float _v0; float _v1; } Rect;
       } data;
     } Shape; *)
let emit_enum ed =
  let n = ed.ed_name.name in
  let buf = Buffer.create 512 in
  (* Tag enum *)
  Buffer.add_string buf (Printf.sprintf "typedef enum {\n");
  List.iteri (fun i (vname, _) ->
    Buffer.add_string buf
      (Printf.sprintf "  %s_tag_%s = %d,\n" n vname.name i)
  ) ed.ed_variants;
  Buffer.add_string buf (Printf.sprintf "} %s_tag_t;\n" n);
  (* Struct with tag + union *)
  Buffer.add_string buf (Printf.sprintf "typedef struct %s {\n" n);
  Buffer.add_string buf (Printf.sprintf "  %s_tag_t tag;\n" n);
  Buffer.add_string buf "  union {\n";
  List.iter (fun (vname, fields) ->
    Buffer.add_string buf "    struct {\n";
    if fields = [] then
      Buffer.add_string buf "      char _dummy;\n"
    else
      List.iteri (fun i fty ->
        Buffer.add_string buf
          (Printf.sprintf "      %s _v%d;\n" (emit_ty fty) i)
      ) fields;
    Buffer.add_string buf (Printf.sprintf "    } %s;\n" vname.name)
  ) ed.ed_variants;
  Buffer.add_string buf "  } data;\n";
  Buffer.add_string buf (Printf.sprintf "} %s;\n" n);
  Buffer.contents buf

let emit_item item =
  match item.item_desc with
  | IFn fn     -> emit_fn fn
  | IStruct sd -> emit_struct sd
  | IType td   ->
      Printf.sprintf "typedef %s %s;\n"
        (emit_ty td.td_ty) td.td_name.name
  | IEnum ed   -> emit_enum ed
  | IImpl im   ->
      let ty_name = match im.im_ty with
        | TNamed (id, []) -> id.name | _ -> "ImplUnknown"
      in
      String.concat "" (List.filter_map (fun item ->
        match item.item_desc with
        | IFn fn ->
            let mangled_fn = { fn with
              fn_name = { fn.fn_name with name = ty_name ^ "__" ^ fn.fn_name.name } }
            in
            Some (emit_fn mangled_fn)
        | _ -> None
      ) im.im_items)
  | IExtern ex ->
      (match ex.ex_ty with
       | TFn fty ->
           (* Emit a proper C prototype for the extern function *)
           let params_str =
             if fty.params = [] then "void"
             else String.concat ", " (List.map (fun (id, ty) ->
               Printf.sprintf "%s %s" (emit_ty ty) id.name
             ) fty.params)
           in
           Printf.sprintf "%s %s(%s);  /* extern: %s */\n"
             (emit_ty fty.ret) ex.ex_name.name params_str ex.ex_link
       | ty ->
           Printf.sprintf "extern %s %s;  /* %s */\n"
             (emit_ty ty) ex.ex_name.name ex.ex_link)
  | IUse _     -> ""

(* ------------------------------------------------------------------ *)
(* Assume audit section emission                                        *)
(* ------------------------------------------------------------------ *)

let emit_assume_audit assumes =
  let buf = Buffer.create 512 in
  Buffer.add_string buf "\n/* ---- FORGE ASSUMPTION AUDIT LOG ----\n";
  Buffer.add_string buf
    (Printf.sprintf "   Total assumptions: %d\n" (List.length assumes));
  List.iter (fun (ae : Proof_engine.assume_entry) ->
    Buffer.add_string buf
      (Printf.sprintf "   [ASSUME] %s:%d  %s\n"
        ae.ae_loc.file ae.ae_loc.line ae.ae_smtlib);
    (match ae.ae_context with
     | Some ctx -> Buffer.add_string buf (Printf.sprintf "             \"%s\"\n" ctx)
     | None -> ())
  ) assumes;
  Buffer.add_string buf "   ---- END AUDIT LOG ---- */\n";
  Buffer.contents buf

(* ------------------------------------------------------------------ *)
(* CUDA detection                                                       *)
(* ------------------------------------------------------------------ *)

(* Returns true if the program contains any GPU-annotated functions.
   If true, we must emit .cu with CUDA runtime headers and built-in aliases. *)
let is_cuda_program prog =
  List.exists (fun item ->
    match item.item_desc with
    | IFn fn ->
        List.exists (fun a ->
          a.attr_name = "kernel" ||
          a.attr_name = "device" ||
          a.attr_name = "host_device"
        ) fn.fn_attrs
    | _ -> false
  ) prog.prog_items

(* CUDA built-in variable aliases.
   FORGE uses flat names (threadIdx_x) internally; CUDA exposes them as
   struct members (threadIdx.x).  These macros bridge the gap. *)
let cuda_builtin_aliases = {|
/* FORGE GPU built-in aliases — FORGE flat names → CUDA struct members */
#define threadIdx_x ((uint32_t)(threadIdx.x))
#define threadIdx_y ((uint32_t)(threadIdx.y))
#define threadIdx_z ((uint32_t)(threadIdx.z))
#define blockIdx_x  ((uint32_t)(blockIdx.x))
#define blockIdx_y  ((uint32_t)(blockIdx.y))
#define blockIdx_z  ((uint32_t)(blockIdx.z))
#define blockDim_x  ((uint32_t)(blockDim.x))
#define blockDim_y  ((uint32_t)(blockDim.y))
#define blockDim_z  ((uint32_t)(blockDim.z))
#define gridDim_x   ((uint32_t)(gridDim.x))
#define gridDim_y   ((uint32_t)(gridDim.y))
#define gridDim_z   ((uint32_t)(gridDim.z))
|}

(* ------------------------------------------------------------------ *)
(* Program emission                                                     *)
(* ------------------------------------------------------------------ *)

(* Returns (c_source, is_cuda).
   Caller uses is_cuda to decide whether to write .c or .cu. *)
(* Collect system headers referenced by extern declarations.
   An extern with ex_link = "<header.h>" contributes that header.
   We emit #include <header.h> instead of re-declaring the function. *)
let collect_system_headers items =
  List.fold_left (fun acc item ->
    match item.item_desc with
    | IExtern ex ->
        let link = ex.ex_link in
        let n = String.length link in
        if n >= 2 && link.[0] = '<' && link.[n-1] = '>' then
          if List.mem link acc then acc else link :: acc
        else acc
    | _ -> acc
  ) [] items

(* True if this extern should be suppressed (comes from a system header) *)
let is_system_extern ex =
  let link = ex.ex_link in
  let n = String.length link in
  n >= 2 && link.[0] = '<' && link.[n-1] = '>'

(* Collect all TNamed(id, non_empty_args) instances from types in the program.
   These are the generic instantiations that need concrete typedefs. *)
let rec collect_generic_named acc ty =
  match ty with
  | TNamed (id, (_ :: _ as args)) ->
      let key = id.name ^ "_" ^ String.concat "_" (List.map mangle_ty_id args) in
      let acc = if List.mem_assoc key acc then acc
                else (key, (id.name, args)) :: acc in
      List.fold_left collect_generic_named acc args
  | TNamed (_, args) -> List.fold_left collect_generic_named acc args
  | TSpan t | TRef t | TRefMut t | TOwn t | TRaw t | TSlice t -> collect_generic_named acc t
  | TArray (t, _) | TShared (t, _) -> collect_generic_named acc t
  | TQual (_, t) -> collect_generic_named acc t
  (* TFn deliberately excluded: constructor TFn types carry unresolved type params
     (e.g. EVar("Some") has TFn{ret=Option<T>}) and must not generate spurious instances *)
  | _ -> acc

let rec collect_generic_named_expr acc e =
  let acc = match e.expr_ty with
    | Some ty -> collect_generic_named acc ty
    | None -> acc
  in
  collect_generic_named_expr_desc acc e.expr_desc

and collect_generic_named_expr_desc acc = function
  | ELit _ | EVar _ | ESync -> acc
  | EBinop (_, l, r) ->
      collect_generic_named_expr (collect_generic_named_expr acc l) r
  | EUnop (_, e) | ERef e | ERefMut e | EDeref e -> collect_generic_named_expr acc e
  | ECast (e, t) -> collect_generic_named (collect_generic_named_expr acc e) t
  | ECall (f, args) ->
      List.fold_left collect_generic_named_expr (collect_generic_named_expr acc f) args
  | EIndex (a, i) ->
      collect_generic_named_expr (collect_generic_named_expr acc a) i
  | EField (e, _) -> collect_generic_named_expr acc e
  | EAssign (l, r) ->
      collect_generic_named_expr (collect_generic_named_expr acc l) r
  | EBlock (stmts, ret) ->
      let acc = List.fold_left collect_generic_named_stmt acc stmts in
      (match ret with Some e -> collect_generic_named_expr acc e | None -> acc)
  | EIf (c, t, e) ->
      let acc = collect_generic_named_expr acc c in
      let acc = collect_generic_named_expr acc t in
      (match e with Some e -> collect_generic_named_expr acc e | None -> acc)
  | EMatch (scrut, arms) ->
      let acc = collect_generic_named_expr acc scrut in
      List.fold_left (fun a arm -> collect_generic_named_expr a arm.body) acc arms
  | EStruct (_, inits) ->
      List.fold_left (fun a (_, e) -> collect_generic_named_expr a e) acc inits
  | EProof _ | ERaw _ | EAssume _ -> acc
  | EArrayLit elems -> List.fold_left collect_generic_named_expr acc elems
  | EArrayRepeat (v, n) ->
      collect_generic_named_expr (collect_generic_named_expr acc v) n

and collect_generic_named_stmt acc s =
  match s.stmt_desc with
  | SLet (_, ty_opt, e, _) ->
      let acc = match ty_opt with Some t -> collect_generic_named acc t | None -> acc in
      collect_generic_named_expr acc e
  | SExpr e | SReturn (Some e) -> collect_generic_named_expr acc e
  | SReturn None | SBreak | SContinue -> acc
  | SWhile (cond, _, _, body) ->
      let acc = collect_generic_named_expr acc cond in
      List.fold_left collect_generic_named_stmt acc body
  | SFor (_, iter, _, body) ->
      let acc = collect_generic_named_expr acc iter in
      List.fold_left collect_generic_named_stmt acc body

let collect_generic_named_item acc item =
  match item.item_desc with
  | IFn fn ->
      let acc = List.fold_left (fun a (_, t) -> collect_generic_named a t) acc fn.fn_params in
      let acc = collect_generic_named acc fn.fn_ret in
      (match fn.fn_body with
       | Some e -> collect_generic_named_expr acc e
       | None -> acc)
  | IStruct sd ->
      List.fold_left (fun a (_, t) -> collect_generic_named a t) acc sd.sd_fields
  | _ -> acc

let emit_program prog =
  (* Build enum constructor registry before any emission *)
  build_enum_registry prog.prog_items;
  let cuda = is_cuda_program prog in
  let buf = Buffer.create 4096 in
  (* Header comment *)
  Buffer.add_string buf
    "/* Generated by FORGE compiler — do not edit.\n";
  Buffer.add_string buf
    "   All proof obligations discharged. This code is correct by construction. */\n\n";
  if cuda then begin
    Buffer.add_string buf "#include <cuda_runtime.h>\n";
    Buffer.add_string buf "#include <stdint.h>\n";
    Buffer.add_string buf "#include <stdbool.h>\n";
    Buffer.add_string buf "#include <stdlib.h>\n";
    (* MSVC doesn't support GCC's __attribute__ — provide no-op macro *)
    Buffer.add_string buf "#ifndef __GNUC__\n";
    Buffer.add_string buf "#  define __attribute__(x)\n";
    Buffer.add_string buf "#endif\n";
    Buffer.add_string buf cuda_builtin_aliases;
    Buffer.add_char buf '\n'
  end else begin
    Buffer.add_string buf "#include <stdint.h>\n";
    Buffer.add_string buf "#include <stdbool.h>\n";
    Buffer.add_string buf "#include <stdlib.h>\n";
    (* MSVC compatibility *)
    Buffer.add_string buf "#ifndef __GNUC__\n";
    Buffer.add_string buf "#  define __attribute__(x)\n";
    Buffer.add_string buf "#endif\n"
  end;
  (* Emit system headers for externs that use <header.h> convention *)
  let sys_headers = List.rev (collect_system_headers prog.prog_items) in
  (* stdlib.h already included above — filter it out *)
  let sys_headers = List.filter (fun h -> h <> "<stdlib.h>") sys_headers in
  if sys_headers <> [] then begin
    List.iter (fun h ->
      Buffer.add_string buf (Printf.sprintf "#include %s\n" h)
    ) sys_headers
  end;
  Buffer.add_char buf '\n';
  (* Emit span<T> typedefs for each unique element type used *)
  let span_elems = List.fold_left collect_span_elems_item [] prog.prog_items in
  if span_elems <> [] then begin
    Buffer.add_string buf "/* span<T> typedefs — fat pointers with proven bounds */\n";
    List.iter (fun (key, elem_ty) ->
      Buffer.add_string buf
        (Printf.sprintf "typedef struct { %s* data; uintptr_t len; } forge_span_%s_t;\n"
           (emit_ty elem_ty) key)
    ) (List.rev span_elems);
    Buffer.add_char buf '\n'
  end;
  (* Collect all generic enum instantiations needed by this program *)
  let generic_instances = List.fold_left collect_generic_named_item [] prog.prog_items in
  (* Build registry for generic enum definitions (name → enum_def) *)
  let generic_enum_defs =
    List.filter_map (fun item -> match item.item_desc with
      | IEnum ed when ed.ed_params <> [] -> Some (ed.ed_name.name, ed)
      | _ -> None) prog.prog_items
  in
  (* Emit monomorphized enum typedefs (e.g. Option_u32) *)
  if generic_instances <> [] then begin
    Buffer.add_string buf "/* Monomorphized generic types */\n";
    List.iter (fun (_key, (base_name, ty_args)) ->
      match List.assoc_opt base_name generic_enum_defs with
      | Some ed ->
          let concrete_ed = emit_generic_enum_instance ed ty_args in
          Buffer.add_string buf (emit_enum concrete_ed ^ "\n")
      | None -> ()
    ) (List.rev generic_instances);
    Buffer.add_char buf '\n'
  end;
  (* Emit in three passes to satisfy C's declaration-before-use rule:
     Pass 1: type definitions (struct, enum, typedef, extern) — no function bodies
             Generic enums are skipped here; their instances were emitted above.
     Pass 2: forward declarations for all functions (handles mutual recursion)
     Pass 3: function definitions *)
  (* Pass 1: type definitions *)
  List.iter (fun item ->
    let code = match item.item_desc with
      | IFn _ | IImpl _ -> ""   (* deferred to passes 2+3 *)
      | IExtern ex when is_system_extern ex -> ""
      | IEnum ed when ed.ed_params <> [] -> ""  (* generic — instances emitted above *)
      | _ -> emit_item item ^ "\n"
    in
    Buffer.add_string buf code
  ) prog.prog_items;
  (* Collect all fns including impl methods for passes 2+3 *)
  let all_fns =
    List.concat_map (fun item ->
      match item.item_desc with
      | IFn fn when fn.fn_body <> None -> [fn]
      | IImpl im ->
          let ty_name = match im.im_ty with
            | TNamed (id, []) -> id.name | _ -> "ImplUnknown"
          in
          List.filter_map (fun it ->
            match it.item_desc with
            | IFn fn when fn.fn_body <> None ->
                Some { fn with fn_name = { fn.fn_name with name = ty_name ^ "__" ^ fn.fn_name.name } }
            | _ -> None
          ) im.im_items
      | _ -> []
    ) prog.prog_items
  in
  (* Pass 2: forward declarations for all functions with bodies *)
  if all_fns <> [] then begin
    Buffer.add_string buf "/* Forward declarations */\n";
    List.iter (fun fn ->
      let qual = gpu_qualifier fn.fn_attrs in
      let ret_ty =
        if qual = "__global__ " && fn.fn_ret <> TPrim TUnit then TPrim TUnit
        else fn.fn_ret
      in
      let fwd_params = String.concat ", " (List.map (fun (id, ty) ->
        Printf.sprintf "%s %s __attribute__((unused))" (emit_ty ty) (c_safe_name id.name)
      ) fn.fn_params) in
      Buffer.add_string buf
        (Printf.sprintf "%s%s %s(%s);\n"
          qual (emit_ret_ty ret_ty) (c_safe_name fn.fn_name.name) fwd_params)
    ) all_fns;
    Buffer.add_char buf '\n'
  end;
  (* Pass 3: function definitions *)
  List.iter (fun fn ->
    Buffer.add_string buf (emit_fn fn ^ "\n")
  ) all_fns;
  (* Assume audit log *)
  let assumes = Proof_engine.dump_assume_log () in
  if assumes <> [] then
    Buffer.add_string buf (emit_assume_audit assumes);
  (Buffer.contents buf, cuda)
