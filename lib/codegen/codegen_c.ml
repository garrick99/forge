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
  | TOwn t             -> "own_" ^ mangle_ty_id t
  | TRaw t             -> "ptr_" ^ mangle_ty_id t
  | TSlice t           -> "slice_" ^ mangle_ty_id t
  | TArray (t, _)      -> "arr_" ^ mangle_ty_id t
  | TNamed ({name="secret"; _}, [t]) -> mangle_ty_id t
  | TNamed (id, [])    -> id.name
  | TNamed (id, args)  -> id.name ^ "_" ^ String.concat "_" (List.map mangle_ty_id args)
  | TSpan t            -> "span_" ^ mangle_ty_id t
  | TShared (t, _)     -> mangle_ty_id t
  | TQual (_, t)       -> mangle_ty_id t
  | TSecret t          -> mangle_ty_id t
  | TTuple tys         -> "tuple_" ^ String.concat "_" (List.map mangle_ty_id tys)
  | TFn fty            ->
      "fn_" ^ String.concat "_" (List.map (fun (_, t) -> mangle_ty_id t) fty.params)
      ^ "_ret_" ^ mangle_ty_id fty.ret
  | TStr               -> "str"
  | TAssoc _           -> "assoc"
  | _                  -> "opaque"

(* ------------------------------------------------------------------ *)
(* Collect all unique span element types used in the program           *)
(* ------------------------------------------------------------------ *)

let rec collect_span_elems_ty acc = function
  | TSpan t  ->
      let key = mangle_ty_id t in
      if List.mem_assoc key acc then acc
      else (key, t) :: collect_span_elems_ty acc t
  | TStr ->
      (* str = span<u8> — ensure forge_span_u8_t typedef is emitted *)
      collect_span_elems_ty acc (TSpan (TPrim (TUint U8)))
  | TRef t | TRefMut t | TOwn t | TRaw t | TSlice t -> collect_span_elems_ty acc t
  | TArray (t, _) | TShared (t, _) -> collect_span_elems_ty acc t
  | TQual (_, t) | TSecret t -> collect_span_elems_ty acc t
  | TTuple tys -> List.fold_left collect_span_elems_ty acc tys
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
(* Collect all unique tuple types used in the program                 *)
(* ------------------------------------------------------------------ *)

let rec collect_tuple_tys acc = function
  | TTuple tys as t ->
      let key = mangle_ty_id t in
      let acc = if List.mem_assoc key acc then acc else (key, tys) :: acc in
      List.fold_left collect_tuple_tys acc tys
  | TRef t | TRefMut t | TOwn t | TRaw t | TSlice t -> collect_tuple_tys acc t
  | TSpan t | TArray (t, _) | TShared (t, _) -> collect_tuple_tys acc t
  | TQual (_, t) | TSecret t -> collect_tuple_tys acc t
  | TFn fty ->
      let acc = List.fold_left (fun a (_, t) -> collect_tuple_tys a t) acc fty.params in
      collect_tuple_tys acc fty.ret
  | _ -> acc

let rec collect_tuple_tys_expr acc e =
  let acc = match e.expr_ty with Some t -> collect_tuple_tys acc t | None -> acc in
  match e.expr_desc with
  | ECall (f, args) ->
      List.fold_left collect_tuple_tys_expr (collect_tuple_tys_expr acc f) args
  | EBinop (_, l, r) -> collect_tuple_tys_expr (collect_tuple_tys_expr acc l) r
  | EUnop (_, e2) | ERef e2 | ERefMut e2 | EDeref e2 | ECast (e2, _) -> collect_tuple_tys_expr acc e2
  | EField (e2, _) | EField_n (e2, _) | EIndex (e2, _) -> collect_tuple_tys_expr acc e2
  | ETuple es | EArrayLit es -> List.fold_left collect_tuple_tys_expr acc es
  | EArrayRepeat (e2, n) -> collect_tuple_tys_expr (collect_tuple_tys_expr acc e2) n
  | ESubspan (e2, lo, hi) -> List.fold_left collect_tuple_tys_expr acc [e2; lo; hi]
  | ERange (lo, hi) -> collect_tuple_tys_expr (collect_tuple_tys_expr acc lo) hi
  | EAssign (l, r) -> collect_tuple_tys_expr (collect_tuple_tys_expr acc l) r
  | EIf (c, t, else_opt) ->
      let acc = collect_tuple_tys_expr (collect_tuple_tys_expr acc c) t in
      (match else_opt with Some e2 -> collect_tuple_tys_expr acc e2 | None -> acc)
  | EBlock (stmts, ret) ->
      let acc = List.fold_left collect_tuple_tys_stmt acc stmts in
      (match ret with Some e2 -> collect_tuple_tys_expr acc e2 | None -> acc)
  | EMatch (scrut, arms) ->
      let acc = collect_tuple_tys_expr acc scrut in
      List.fold_left (fun a arm -> collect_tuple_tys_expr a arm.body) acc arms
  | EStruct (_, fields) ->
      List.fold_left (fun a (_, e2) -> collect_tuple_tys_expr a e2) acc fields
  | ELoop stmts -> List.fold_left collect_tuple_tys_stmt acc stmts
  | ELambda (_, body, _) -> collect_tuple_tys_expr acc body
  | _ -> acc
and collect_tuple_tys_stmt acc s =
  match s.stmt_desc with
  | SGhost _ | SGhostAssign _ -> acc  (* ghost bindings have no C output *)
  | SLet (_, ann, e, _) ->
      let acc = match ann with Some t -> collect_tuple_tys acc t | None -> acc in
      collect_tuple_tys_expr acc e
  | SExpr e | SReturn (Some e) | SBreak (Some e) -> collect_tuple_tys_expr acc e
  | SWhile (c, _, _, body) ->
      List.fold_left collect_tuple_tys_stmt (collect_tuple_tys_expr acc c) body
  | SFor (_, e, _, _, body) ->
      List.fold_left collect_tuple_tys_stmt (collect_tuple_tys_expr acc e) body
  | _ -> acc

let collect_tuple_types items =
  List.fold_left (fun acc item ->
    match item.item_desc with
    | IFn fn ->
        let acc = List.fold_left (fun a (_, t) -> collect_tuple_tys a t) acc fn.fn_params in
        let acc = collect_tuple_tys acc fn.fn_ret in
        (match fn.fn_body with Some e -> collect_tuple_tys_expr acc e | None -> acc)
    | IStruct sd ->
        List.fold_left (fun a (_, t) -> collect_tuple_tys a t) acc sd.sd_fields
    | IExtern ex -> collect_tuple_tys acc ex.ex_ty
    | _ -> acc
  ) [] items

(* ------------------------------------------------------------------ *)
(* Collect all unique own<T> element types used in the program        *)
(* Used to emit __forge_own_alloc_T / __forge_own_into_T helpers.    *)
(* ------------------------------------------------------------------ *)

let rec collect_own_tys acc = function
  | TOwn t ->
      let key = mangle_ty_id t in
      let acc = if List.mem_assoc key acc then acc else (key, t) :: acc in
      collect_own_tys acc t
  | TRef t | TRefMut t | TRaw t | TSlice t -> collect_own_tys acc t
  | TSpan t | TArray (t, _) | TShared (t, _) -> collect_own_tys acc t
  | TQual (_, t) | TSecret t -> collect_own_tys acc t
  | TTuple tys -> List.fold_left collect_own_tys acc tys
  | TFn fty ->
      let acc = List.fold_left (fun a (_, t) -> collect_own_tys a t) acc fty.params in
      collect_own_tys acc fty.ret
  | _ -> acc

let rec collect_own_tys_expr acc e =
  let acc = match e.expr_ty with Some t -> collect_own_tys acc t | None -> acc in
  match e.expr_desc with
  | ECall (f, args) ->
      List.fold_left collect_own_tys_expr (collect_own_tys_expr acc f) args
  | EBinop (_, l, r) -> collect_own_tys_expr (collect_own_tys_expr acc l) r
  | EUnop (_, e2) | ERef e2 | ERefMut e2 | EDeref e2 | ECast (e2, _) -> collect_own_tys_expr acc e2
  | EField (e2, _) | EField_n (e2, _) | EIndex (e2, _) -> collect_own_tys_expr acc e2
  | ETuple es | EArrayLit es -> List.fold_left collect_own_tys_expr acc es
  | EArrayRepeat (e2, n) -> collect_own_tys_expr (collect_own_tys_expr acc e2) n
  | ESubspan (e2, lo, hi) -> List.fold_left collect_own_tys_expr acc [e2; lo; hi]
  | ERange (lo, hi) -> collect_own_tys_expr (collect_own_tys_expr acc lo) hi
  | EAssign (l, r) -> collect_own_tys_expr (collect_own_tys_expr acc l) r
  | EIf (c, t, else_opt) ->
      let acc = collect_own_tys_expr (collect_own_tys_expr acc c) t in
      (match else_opt with Some e2 -> collect_own_tys_expr acc e2 | None -> acc)
  | EBlock (stmts, ret) ->
      let acc = List.fold_left collect_own_tys_stmt acc stmts in
      (match ret with Some e2 -> collect_own_tys_expr acc e2 | None -> acc)
  | EMatch (scrut, arms) ->
      let acc = collect_own_tys_expr acc scrut in
      List.fold_left (fun a arm -> collect_own_tys_expr a arm.body) acc arms
  | EStruct (_, fields) ->
      List.fold_left (fun a (_, e2) -> collect_own_tys_expr a e2) acc fields
  | ELoop stmts -> List.fold_left collect_own_tys_stmt acc stmts
  | ELambda (_, body, _) -> collect_own_tys_expr acc body
  | _ -> acc
and collect_own_tys_stmt acc s =
  match s.stmt_desc with
  | SGhost _ | SGhostAssign _ -> acc
  | SLet (_, ann, e, _) ->
      let acc = match ann with Some t -> collect_own_tys acc t | None -> acc in
      collect_own_tys_expr acc e
  | SExpr e | SReturn (Some e) | SBreak (Some e) -> collect_own_tys_expr acc e
  | SWhile (c, _, _, body) ->
      List.fold_left collect_own_tys_stmt (collect_own_tys_expr acc c) body
  | SFor (_, e, _, _, body) ->
      List.fold_left collect_own_tys_stmt (collect_own_tys_expr acc e) body
  | _ -> acc

let collect_own_types items =
  List.fold_left (fun acc item ->
    match item.item_desc with
    | IFn fn ->
        let acc = List.fold_left (fun a (_, t) -> collect_own_tys a t) acc fn.fn_params in
        let acc = collect_own_tys acc fn.fn_ret in
        (match fn.fn_body with Some e -> collect_own_tys_expr acc e | None -> acc)
    | IExtern ex -> collect_own_tys acc ex.ex_ty
    | _ -> acc
  ) [] items

(* ------------------------------------------------------------------ *)
(* Collect all unique fn(...)->T function pointer types                *)
(* Used to emit C typedefs: typedef ret_t (forge_fn_..._t)(params);   *)
(* ------------------------------------------------------------------ *)

let rec collect_fn_ptr_tys acc = function
  | TFn fty as t ->
      let key = mangle_ty_id t in
      let acc = if List.mem_assoc key acc then acc else (key, fty) :: acc in
      let acc = List.fold_left (fun a (_, pt) -> collect_fn_ptr_tys a pt) acc fty.params in
      collect_fn_ptr_tys acc fty.ret
  | TRef t | TRefMut t | TOwn t | TRaw t | TSlice t -> collect_fn_ptr_tys acc t
  | TSpan t | TArray (t, _) | TShared (t, _) -> collect_fn_ptr_tys acc t
  | TQual (_, t) | TSecret t -> collect_fn_ptr_tys acc t
  | TTuple tys -> List.fold_left collect_fn_ptr_tys acc tys
  | _ -> acc

let collect_fn_ptr_types items =
  List.fold_left (fun acc item ->
    match item.item_desc with
    | IFn fn ->
        let acc = List.fold_left (fun a (_, t) -> collect_fn_ptr_tys a t) acc fn.fn_params in
        collect_fn_ptr_tys acc fn.fn_ret
    | IExtern ex -> collect_fn_ptr_tys acc ex.ex_ty
    | IStruct sd -> List.fold_left (fun a (_, t) -> collect_fn_ptr_tys a t) acc sd.sd_fields
    | _ -> acc
  ) [] items

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
  | TTuple tys  -> TTuple (List.map (subst_ty_c s) tys)
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

(* Type param names for the current generic function — emitted as void* in C *)
let current_type_params : string list ref = ref []

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
  | TOwn t             -> emit_ty t ^ "*"  (* own<T> → T* on heap *)
  | TRaw t             -> Printf.sprintf "%s*" (emit_ty t)
  | TArray (t, Some _n) ->
      (* In type-only position (param decls, forward decls): arrays decay to pointer.
         SLet declaration sites emit T name[N] directly — see emit_stmt. *)
      emit_ty t ^ "*"
  | TSlice t           -> emit_ty t ^ "*"
  | TNamed ({name="secret"; _}, [t]) -> "volatile " ^ emit_ty t
  | TNamed (id, []) when List.mem id.name !current_type_params -> "void"
  | TNamed (id, [])    -> id.name
  | TNamed (id, args)  ->
      (* Monomorphized generic: Option<u32> → Option_u32 *)
      id.name ^ "_" ^ String.concat "_" (List.map mangle_ty_id args)
  | TArray (t, None)   -> emit_ty t ^ "*"
  | TDepArr (_, _, r)  -> emit_ty r
  | TFn fty            -> Printf.sprintf "forge_%s_t" (mangle_ty_id (TFn fty))
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
  | TTuple tys     -> Printf.sprintf "__forge_%s_t" (mangle_ty_id (TTuple tys))
  | TStr           -> "forge_span_u8_t"         (* str = span<u8> fat pointer *)
  | TAssoc _       ->
      (* TAssoc should be resolved to a concrete type before codegen.
         Fall back to uint64_t to produce compilable output. *)
      "uint64_t"

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

(* Counter for unique loop-result variable names *)
let loop_result_counter : int ref = ref 0
let match_default_counter : int ref = ref 0

(* Iterator impl registry: (ty_name, item_ty) — populated by emit_program *)
let iterator_impls : (string * ty) list ref = ref []
(* Maps "TypeName__method" → "TypeName__Trait__method" for trait method dispatch *)
let method_map : (string * string) list ref = ref []
(* Maps function name → true if first parameter is ref<T> or refmut<T>. *)
let fn_first_param_is_ref : (string, bool) Hashtbl.t = Hashtbl.create 64

let rec emit_expr depth e =
  match e.expr_desc with
  | ELit (LInt (n, _))    -> Int64.to_string n
  | ELit (LFloat (f, _))  -> Printf.sprintf "%g" f
  | ELit (LBool true)     -> "1"
  | ELit (LBool false)    -> "0"
  | ELit LUnit            -> "/* unit */"
  | ELit (LStr s)         ->
      (* Emit str literal as forge_span_u8_t fat pointer with .data and .len *)
      let escaped = String.escaped s in
      let len = String.length s in
      Printf.sprintf "((forge_span_u8_t){ .data = (uint8_t*)\"%s\", .len = %dULL })"
        escaped len
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
  | EBinop (Eq, l, r) when (match l.expr_ty with Some TStr -> true | _ -> false) ->
      (* str equality: pointer + length comparison (same-span identity) *)
      let ls = emit_expr depth l and rs = emit_expr depth r in
      Printf.sprintf "(%s.data == %s.data && %s.len == %s.len)" ls rs ls rs
  | EBinop (Ne, l, r) when (match l.expr_ty with Some TStr -> true | _ -> false) ->
      let ls = emit_expr depth l and rs = emit_expr depth r in
      Printf.sprintf "(%s.data != %s.data || %s.len != %s.len)" ls rs ls rs
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
  (* own<T> heap intrinsics *)
  (* ---- Raw pointer intrinsics ---- *)
  | ECall ({ expr_desc = EVar id; _ }, []) when id.name = "ptr_null" ->
      "((uint64_t)(uintptr_t)(void*)0)"
  | ECall ({ expr_desc = EVar id; _ }, [ptr; offset]) when id.name = "ptr_offset" ->
      Printf.sprintf "((uint64_t)((uint64_t*)((uintptr_t)%s) + %s))"
        (emit_expr depth ptr) (emit_expr depth offset)
  | ECall ({ expr_desc = EVar id; _ }, [ptr]) when id.name = "ptr_read" ->
      Printf.sprintf "(*(uint64_t*)((uintptr_t)%s))" (emit_expr depth ptr)
  | ECall ({ expr_desc = EVar id; _ }, [ptr; value]) when id.name = "ptr_write" ->
      Printf.sprintf "(*(uint64_t*)((uintptr_t)%s) = %s)"
        (emit_expr depth ptr) (emit_expr depth value)
  | ECall ({ expr_desc = EVar id; _ }, [ptr]) when id.name = "ptr_to_u64" ->
      Printf.sprintf "((uint64_t)(uintptr_t)%s)" (emit_expr depth ptr)
  | ECall ({ expr_desc = EVar id; _ }, [v]) when id.name = "u64_to_ptr" ->
      Printf.sprintf "((uint64_t)(uintptr_t)(void*)%s)" (emit_expr depth v)
  (* ---- Volatile read/write ---- *)
  | ECall ({ expr_desc = EVar id; _ }, [ptr]) when id.name = "volatile_read" ->
      Printf.sprintf "(*(volatile uint64_t*)((uintptr_t)%s))" (emit_expr depth ptr)
  | ECall ({ expr_desc = EVar id; _ }, [ptr; value]) when id.name = "volatile_write" ->
      Printf.sprintf "(*(volatile uint64_t*)((uintptr_t)%s) = %s)"
        (emit_expr depth ptr) (emit_expr depth value)
  (* ---- GPU intrinsics (CUDA C) ---- *)
  | ECall ({ expr_desc = EVar id; _ }, [v; lane; width])
      when id.name = "shfl_down_sync" ->
      Printf.sprintf "__shfl_down_sync(0xffffffff, %s, %s, %s)"
        (emit_expr depth v) (emit_expr depth lane) (emit_expr depth width)
  | ECall ({ expr_desc = EVar id; _ }, [v; lane; width])
      when id.name = "shfl_xor_sync" ->
      Printf.sprintf "__shfl_xor_sync(0xffffffff, %s, %s, %s)"
        (emit_expr depth v) (emit_expr depth lane) (emit_expr depth width)
  | ECall ({ expr_desc = EVar id; _ }, [ptr; v])
      when id.name = "atom_add" ->
      Printf.sprintf "atomicAdd((unsigned long long*)%s, %s)"
        (emit_expr depth ptr) (emit_expr depth v)
  | ECall ({ expr_desc = EVar id; _ }, [ptr; v])
      when id.name = "atom_cas" ->
      Printf.sprintf "atomicCAS((unsigned long long*)%s, 0, %s)"
        (emit_expr depth ptr) (emit_expr depth v)
  | ECall ({ expr_desc = EVar id; _ }, [ptr; v])
      when id.name = "atom_max" ->
      Printf.sprintf "atomicMax((unsigned long long*)%s, %s)"
        (emit_expr depth ptr) (emit_expr depth v)
  | ECall ({ expr_desc = EVar id; _ }, [ptr; v])
      when id.name = "atom_min" ->
      Printf.sprintf "atomicMin((unsigned long long*)%s, %s)"
        (emit_expr depth ptr) (emit_expr depth v)
  | ECall ({ expr_desc = EVar id; _ }, [pred])
      when id.name = "ballot_sync" ->
      Printf.sprintf "__ballot_sync(0xffffffff, %s)" (emit_expr depth pred)
  | ECall ({ expr_desc = EVar id; _ }, [])
      when id.name = "lane_id" ->
      "(threadIdx.x & 31)"
  | ECall ({ expr_desc = EVar id; _ }, [])
      when id.name = "warp_id" ->
      "(threadIdx.x >> 5)"
  (* ---- Inline assembly ---- *)
  | ECall ({ expr_desc = EVar id; _ }, [{ expr_desc = ELit (LStr s); _ }])
      when id.name = "asm_volatile" ->
      Printf.sprintf "__asm__ volatile(\"%s\")" (String.escaped s)
  | ECall ({ expr_desc = EVar id; _ }, []) when id.name = "cpu_relax" ->
      "__asm__ volatile(\"pause\" ::: \"memory\")"
  | ECall ({ expr_desc = EVar id; _ }, []) when id.name = "dmb" ->
      "__asm__ volatile(\"dmb sy\" ::: \"memory\")"
  | ECall ({ expr_desc = EVar id; _ }, []) when id.name = "compiler_fence" ->
      "__asm__ volatile(\"\" ::: \"memory\")"
  | ECall ({ expr_desc = EVar id; _ }, []) when id.name = "memory_barrier" ->
      "__sync_synchronize()"
  (* ---- Own<T> intrinsics ---- *)
  | ECall ({ expr_desc = EVar id; _ }, [arg]) when id.name = "own_alloc" ->
      let elem_ty = match arg.expr_ty with Some t -> t | None -> TPrim (TUint U64) in
      let mname = mangle_ty_id elem_ty in
      Printf.sprintf "__forge_own_alloc_%s(%s)" mname (emit_expr depth arg)
  | ECall ({ expr_desc = EVar id; _ }, [arg]) when id.name = "own_into" ->
      let elem_ty = match arg.expr_ty with
        | Some (TOwn t) -> t | Some t -> t | None -> TPrim (TUint U64)
      in
      let mname = mangle_ty_id elem_ty in
      Printf.sprintf "__forge_own_into_%s(%s)" mname (emit_expr depth arg)
  | ECall ({ expr_desc = EVar id; _ }, [arg]) when id.name = "own_free" ->
      Printf.sprintf "(free(%s), (void)0)" (emit_expr depth arg)
  | ECall ({ expr_desc = EVar id; _ }, [arg]) when id.name = "own_get" ->
      let elem_ty = match arg.expr_ty with
        | Some (TOwn t) -> t | Some t -> t | None -> TPrim (TUint U64)
      in
      let mname = mangle_ty_id elem_ty in
      Printf.sprintf "__forge_own_get_%s(%s)" mname (emit_expr depth arg)
  | ECall ({ expr_desc = EVar id; _ }, [arg]) when id.name = "own_borrow" ->
      let elem_ty = match arg.expr_ty with
        | Some (TOwn t) -> t | Some t -> t | None -> TPrim (TUint U64)
      in
      let mname = mangle_ty_id elem_ty in
      Printf.sprintf "__forge_own_borrow_%s(%s)" mname (emit_expr depth arg)
  | ECall ({ expr_desc = EVar id; _ }, [arg]) when id.name = "own_borrow_mut" ->
      let elem_ty = match arg.expr_ty with
        | Some (TOwn t) -> t | Some t -> t | None -> TPrim (TUint U64)
      in
      let mname = mangle_ty_id elem_ty in
      Printf.sprintf "__forge_own_borrow_mut_%s(%s)" mname (emit_expr depth arg)
  (* Method call dispatch: obj.method(args) → TypeName__method(&obj, args)
     The receiver is auto-referenced: typecheck inserts ERef/ERefMut into the
     synthetic receiver arg, so here we just emit all_args as-is. *)
  | ECall ({ expr_desc = EField (obj, method_name); _ }, args) ->
      let type_name = match obj.expr_ty with
        | Some ty -> mangle_ty_id ty
        | None    -> ""
      in
      let base_mangled = if type_name = "" then "" else type_name ^ "__" ^ method_name.name in
      (* Resolve to trait method name if needed *)
      let mangled = if base_mangled = "" then ""
        else match List.assoc_opt base_mangled !method_map with
          | Some resolved -> resolved
          | None          -> base_mangled
      in
      if mangled <> "" then
        let obj_str = emit_expr depth obj in
        (* Determine if the resolved function expects ref<T> or refmut<T> as first param. *)
        let resolved_name = match List.assoc_opt mangled !method_map with
          | Some r -> r | None -> mangled
        in
        let first_is_ref = match Hashtbl.find_opt fn_first_param_is_ref resolved_name with
          | Some b -> b
          | None   ->
              (* Fallback: check short name too *)
              match Hashtbl.find_opt fn_first_param_is_ref mangled with
              | Some b -> b | None -> true  (* default: assume ref for safety *)
        in
        let receiver_str =
          if not first_is_ref then
            (* By-value receiver: pass obj directly *)
            obj_str
          else match obj.expr_desc with
          | EVar _ | EField _ | EIndex _ | EDeref _ ->
              Printf.sprintf "(&%s)" obj_str
          | _ ->
              (* Rvalue receiver: use C99 compound literal array (Type[1]){expr}.
                 This has block scope (not expression scope), so the pointer is
                 valid for the duration of the function call — no dangling pointer. *)
              let ty_str = match obj.expr_ty with
                | Some ty -> emit_ty ty | None -> "void*"
              in
              Printf.sprintf "((%s[1]){%s})" ty_str obj_str
        in
        Printf.sprintf "%s(%s)" mangled
          (String.concat ", " (receiver_str :: List.map (emit_expr depth) args))
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
       | Some (TSpan _) | Some (TQual (_, TSpan _)) | Some TStr ->
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
      (* Check if branches are simple value-returning blocks (no stmts, just
         a trailing expr).  If so, emit as ternary — required when the EIf
         appears as the RHS of an assignment (e.g. s[i] = if c { a } else { b }). *)
      let rec simple_block_val e = match e.expr_desc with
        | EBlock ([], Some ret) -> Some ret
        | EIf (_c2, t2, Some e2) ->
            (* Nested EIf (elif chain): if both sub-branches are simple,
               emit as nested ternary.  Wrap as a synthetic ternary expr. *)
            (match simple_block_val t2, simple_block_val e2 with
             | Some _, Some _ -> Some e  (* the whole EIf is a value expr *)
             | _ -> None)
        | EBlock _ -> None  (* has stmts — not simple *)
        | _ -> Some e       (* bare expression — always simple *)
      in
      let then_simple = simple_block_val then_ in
      let else_simple = simple_block_val else_ in
      (match then_simple, else_simple with
       | Some tv, Some ev ->
           Printf.sprintf "(%s ? %s : %s)"
             (emit_expr depth cond)
             (emit_expr_value depth tv)
             (emit_expr_value depth ev)
       | _ ->
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
               (emit_expr_value depth else_))
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
  | EAssert _ -> "/* assert erased */"  (* proved at compile time — gone at codegen *)
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
  | ETuple elems ->
      (* Emit as C99 compound literal: (__forge_tuple_..._t){ ._0 = e0, ._1 = e1, ... } *)
      let tup_ty = match e.expr_ty with Some t -> t | None ->
        TTuple (List.map (fun _ -> TPrim (TUint U64)) elems)
      in
      let fields = List.mapi (fun i elem ->
        Printf.sprintf "._%d = %s" i (emit_expr depth elem)
      ) elems in
      Printf.sprintf "(%s){ %s }" (emit_ty tup_ty) (String.concat ", " fields)
  | EField_n (tup, idx) ->
      Printf.sprintf "(%s)._%d" (emit_expr depth tup) idx
  | ESubspan (arr, lo, hi) ->
      let elem_ty = match arr.expr_ty with Some (TSpan t) -> t | _ -> TPrim (TUint U64) in
      let span_ty = TSpan elem_ty in
      Printf.sprintf "(%s){ .data = (%s).data + (%s), .len = (uintptr_t)((%s) - (%s)) }"
        (emit_ty span_ty)
        (emit_expr depth arr) (emit_expr depth lo)
        (emit_expr depth hi)  (emit_expr depth lo)

  | ERange _ ->
      (* ERange is only valid as a for-loop iterator; should never be emitted standalone *)
      "/* invalid ERange */"

  | ELambda (_, _, name_ref) ->
      (* Lambda was lifted to a top-level function during typechecking.
         Emit the function pointer value (just its name). *)
      (match !name_ref with
       | Some name -> name
       | None -> "/* unlifted lambda */")  (* should not happen *)

  | ELoop stmts ->
      (* loop { stmts } — emits as GCC statement expression:
         ({ T __loop_result_N; for(;;){ stmts } __loop_result_N; })
         break val;  sets __loop_result_N = val; break; *)
      let n = !loop_result_counter in
      incr loop_result_counter;
      let result_var = Printf.sprintf "__loop_result_%d" n in
      let ty_str = match e.expr_ty with
        | Some t -> emit_ty t
        | None   -> "int64_t"
      in
      let buf = Buffer.create 128 in
      Buffer.add_string buf (Printf.sprintf "({ %s %s;\n" ty_str result_var);
      Buffer.add_string buf (Printf.sprintf "%s  for(;;) {\n" (indent depth));
      List.iter (fun s ->
        Buffer.add_string buf (emit_stmt (depth+2) s);
        Buffer.add_char buf '\n'
      ) stmts;
      Buffer.add_string buf (Printf.sprintf "%s  }\n" (indent depth));
      Buffer.add_string buf (Printf.sprintf "%s  %s; })" (indent depth) result_var);
      Buffer.contents buf

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
           (Printf.sprintf "%s%s %s __attribute__((unused)) = %s.data.%s._v%d;\n"
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

(* Convert a guard predicate to a C expression string.
   Only handles simple cases used in match guards: comparisons, binops, variable references. *)
and pred_to_c = function
  | PVar id            -> id.name
  | PInt n             -> Int64.to_string n
  | PBool true         -> "1"
  | PBool false        -> "0"
  | PTrue              -> "1"
  | PFalse             -> "0"
  | PField (p, f)      -> Printf.sprintf "%s.%s" (pred_to_c p) f
  | PBinop (op, l, r)  ->
      let op_str = match op with
        | Add -> "+" | Sub -> "-" | Mul -> "*" | Div -> "/"
        | Mod -> "%" | BitAnd -> "&" | BitOr -> "|" | BitXor -> "^"
        | Shl -> "<<" | Shr -> ">>" | Eq -> "==" | Ne -> "!="
        | Lt -> "<" | Le -> "<=" | Gt -> ">" | Ge -> ">="
        | And -> "&&" | Or -> "||" | Implies -> "||" | Iff -> "=="
      in
      Printf.sprintf "(%s %s %s)" (pred_to_c l) op_str (pred_to_c r)
  | PUnop (Not, p)     -> Printf.sprintf "(!%s)" (pred_to_c p)
  | PUnop (Neg, p)     -> Printf.sprintf "(-%s)" (pred_to_c p)
  | _                  -> "1"  (* unknown pred → always-true guard *)

and emit_match ?(return_mode=false) depth scrutinee arms =
  let buf = Buffer.create 256 in
  let scrut_str = emit_expr depth scrutinee in
  (* Unique label for guarded-arm fallthrough to default in return_mode *)
  let default_label =
    let n = !match_default_counter in
    incr match_default_counter;
    Printf.sprintf "forge_match_default_%d" n
  in
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
  (* Whether any non-wildcard arm has a guard (these may emit goto to default) *)
  let has_any_ctor_guards = List.exists (fun arm ->
    arm.guard <> None &&
    (match arm.pattern with PWild | PBind _ -> false | _ -> true)
  ) arms in
  let rec pat_has_ctor = function
    | PCtor _ | POr _ -> true
    | PAs (p, _)      -> pat_has_ctor p
    | PBind id        -> List.mem_assoc id.name !enum_ctors   (* unit enum ctor *)
    | _               -> false
  in
  let has_ctor = List.exists (fun arm -> pat_has_ctor arm.pattern) arms in
  if all_ctors && has_ctor then begin
    Buffer.add_string buf (Printf.sprintf "%sswitch (%s.tag) {\n" (indent depth) scrut_str);
    (* PAs wrapping a ctor is a named case arm, not a default. *)
    let is_default_pat = function
      | PWild -> true
      | PBind id -> not (List.mem_assoc id.name !enum_ctors)
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
    (* Group consecutive arms with the same constructor into a single case block.
       This is needed for match guards: multiple Pattern(v) if guard => ... arms
       must share one `case` label and use if-else chains inside. *)
    let rec emit_arms = function
      | [] -> ()
      | arm :: rest ->
          let (inner_pat, alias_opt) = match arm.pattern with
            | PAs (p, id) -> (p, Some id)
            | p           -> (p, None)
          in
          (match inner_pat with
           | PBind id when List.mem_assoc id.name !enum_ctors ->
               (* Unit enum constructor without parens — treat as PCtor(id, []) *)
               let (enum_name, _tag, _fields) = resolve_ctor_enum id.name in
               Buffer.add_string buf
                 (Printf.sprintf "%scase %s_tag_%s: {\n" (indent (depth+1)) enum_name id.name);
               emit_arm_body_with_alias (depth+2) alias_opt arm.body;
               Buffer.add_string buf (Printf.sprintf "%s}\n" (indent (depth+1)));
               emit_arms rest
           | PCtor (ctor_id, subpats) ->
               let (enum_name, _tag, fields) = resolve_ctor_enum ctor_id.name in
               (* Collect all consecutive arms with the same ctor *)
               let rec collect_same acc remaining =
                 match remaining with
                 | next :: tl ->
                     let (np, _) = match next.pattern with
                       | PAs (p, _) -> (p, ()) | p -> (p, ())
                     in
                     (match np with
                      | PCtor (c2, _) when c2.name = ctor_id.name ->
                          collect_same (acc @ [next]) tl
                      | _ -> (acc, remaining))
                 | [] -> (acc, [])
               in
               let (same_arms, remaining) = collect_same [arm] rest in
               Buffer.add_string buf
                 (Printf.sprintf "%scase %s_tag_%s: {\n" (indent (depth+1)) enum_name ctor_id.name);
               (* alias binding (first arm only) *)
               (match alias_opt with
                | Some id ->
                    let scrut_ty_str = match scrutinee.expr_ty with
                      | Some t -> emit_ty t | None -> "void*"
                    in
                    Buffer.add_string buf (Printf.sprintf "%s%s %s __attribute__((unused)) = %s;\n"
                      (indent (depth+2)) scrut_ty_str id.name scrut_str)
                | None -> ());
               (* For guards: emit if-else chain; for a single unguarded arm: emit directly *)
               let has_guards = List.exists (fun a -> a.guard <> None) same_arms in
               if has_guards then begin
                 (* Emit field bindings once (shared across all arms) *)
                 emit_field_bindings buf (depth+2) scrut_str ctor_id.name subpats fields;
                 let rec emit_guard_chain = function
                   | [] ->
                       (* No catch-all in this arm: if there's a default arm in the match,
                          goto it so the wildcard body handles this case too.
                          Otherwise just break (non-exhaustive match). *)
                       if return_mode && has_default_arm then
                         Buffer.add_string buf
                           (Printf.sprintf "%sgoto %s;\n" (indent (depth+2)) default_label)
                       else
                         Buffer.add_string buf (Printf.sprintf "%sbreak;\n" (indent (depth+2)))
                   | [last] when last.guard = None ->
                       (* Unguarded final arm — emit as else *)
                       emit_arm_body_with_alias (depth+2) None last.body
                   | a :: tl ->
                       let (guard_c, kw) = match a.guard with
                         | Some g -> (pred_to_c g, "if")
                         | None   -> ("1", "if")
                       in
                       Buffer.add_string buf
                         (Printf.sprintf "%s%s (%s) {\n" (indent (depth+2)) kw guard_c);
                       emit_arm_body_with_alias (depth+3) None a.body;
                       Buffer.add_string buf (Printf.sprintf "%s} else {\n" (indent (depth+2)));
                       emit_guard_chain tl;
                       Buffer.add_string buf (Printf.sprintf "%s}\n" (indent (depth+2)))
                 in
                 emit_guard_chain same_arms
               end else begin
                 emit_field_bindings buf (depth+2) scrut_str ctor_id.name subpats fields;
                 emit_arm_body_with_alias (depth+2) None arm.body
               end;
               Buffer.add_string buf (Printf.sprintf "%s}\n" (indent (depth+1)));
               emit_arms remaining
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
               Buffer.add_string buf (Printf.sprintf "%s}\n" (indent (depth+1)));
               emit_arms rest
           | PWild | PBind _ ->
               (* PBind that isn't an enum ctor → wildcard/variable binding → default *)
               Buffer.add_string buf (Printf.sprintf "%sdefault: ;\n" (indent (depth+1)));
               (* Only emit goto-label when some guarded arm might jump here *)
               if return_mode && has_any_ctor_guards then
                 Buffer.add_string buf (Printf.sprintf "%s%s:\n" (indent (depth+1)) default_label);
               Buffer.add_string buf (Printf.sprintf "%s{\n" (indent (depth+1)));
               emit_arm_body_with_alias (depth+2) alias_opt arm.body;
               Buffer.add_string buf (Printf.sprintf "%s}\n" (indent (depth+1)));
               emit_arms rest
           | _ ->
               Buffer.add_string buf (Printf.sprintf "%sdefault: break;\n" (indent (depth+1)));
               emit_arms rest)
    in
    emit_arms arms;
    (* If no wildcard/catch-all arm was emitted, add an unreachable default.
       FORGE proves match exhaustiveness — the default is dead code, but
       GCC/Clang need it to suppress "control reaches end of non-void function". *)
    if not has_default_arm then
      Buffer.add_string buf
        (Printf.sprintf "%sdefault: __builtin_unreachable();\n" (indent (depth+1)));
    Buffer.add_string buf (Printf.sprintf "%s}" (indent depth))
  end else begin
    (* Non-enum match: if-else chain.
       First, hoist any PBind variable bindings so guards can reference them. *)
    let scrut_ty_str = match scrutinee.expr_ty with
      | Some t -> emit_ty t | None -> "void*"
    in
    (* Collect unique PBind names across all arms (excluding "_") *)
    let bound_vars = List.filter_map (fun arm ->
      match arm.pattern with
      | PBind id when id.name <> "_" -> Some id.name
      | PAs (_, id) -> Some id.name
      | _ -> None
    ) arms |> List.sort_uniq String.compare in
    List.iter (fun vname ->
      Buffer.add_string buf
        (Printf.sprintf "%s%s %s __attribute__((unused)) = %s;\n"
          (indent depth) scrut_ty_str vname scrut_str)
    ) bound_vars;
    (* Now emit the if-else chain, combining pattern cond and guard *)
    let first = ref true in
    List.iter (fun arm ->
      let kw = if !first then "if" else "else if" in
      first := false;
      let pat_cond = emit_pattern_cond depth scrutinee arm.pattern in
      let guard_cond = match arm.guard with
        | None   -> "1"
        | Some g -> pred_to_c g
      in
      let cond =
        if pat_cond = "1" then guard_cond
        else if guard_cond = "1" then pat_cond
        else Printf.sprintf "(%s && %s)" pat_cond guard_cond
      in
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
            (emit_expr depth arm.body))
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
  | PLitRange (LInt (lo, _), LInt (hi, _)) ->
      (* Skip >= 0 for unsigned types — always true and triggers -Wtype-limits *)
      if Int64.compare lo 0L = 0 then
        Printf.sprintf "(%s <= %s)" s (Int64.to_string hi)
      else
        Printf.sprintf "(%s >= %s && %s <= %s)"
          s (Int64.to_string lo) s (Int64.to_string hi)
  | PLitRange _ -> "1 /* range */"
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
  | EMatch (scrut, arms) ->
      (* match as assign — each arm body assigns to lhs instead of returning *)
      let buf = Buffer.create 256 in
      Buffer.add_string buf (emit_match_as_assign lhs depth scrut arms);
      Buffer.contents buf
  | _ ->
      Printf.sprintf "%s%s = %s;" (indent depth) lhs (emit_expr depth e)

(* Emit a match expression where each arm body assigns to 'lhs' and breaks.
   This handles the desugared ? operator pattern:
     let x: T = match e { Ok(v) => v, Err(e) => return Err(e) }
   where the Ok arm does  lhs = v  and the Err arm does  return Err(e). *)
and emit_match_as_assign lhs depth scrut arms =
  let buf = Buffer.create 256 in
  let all_ctors = List.for_all (fun arm -> pat_is_ctor_or_wild arm.pattern) arms in
  let rec pat_has_ctor = function
    | PCtor _ | POr _ -> true
    | PAs (p, _)      -> pat_has_ctor p
    | _               -> false
  in
  let has_ctor = List.exists (fun arm -> pat_has_ctor arm.pattern) arms in
  let scrut_str = emit_expr depth scrut in
  if all_ctors && has_ctor then begin
    Buffer.add_string buf (Printf.sprintf "%sswitch (%s.tag) {\n" (indent depth) scrut_str);
    List.iter (fun arm ->
      let (inner_pat, _alias_opt) = match arm.pattern with
        | PAs (p, id) -> (p, Some id)
        | p           -> (p, None)
      in
      (match inner_pat with
       | PCtor (ctor_id, subpats) ->
           let resolve_ctor cname =
             match List.assoc_opt cname !enum_ctors with
             | Some (ename, _tag, fields) -> (ename, fields)
             | None -> ("?", [])
           in
           let (enum_name, fields) = resolve_ctor ctor_id.name in
           Buffer.add_string buf
             (Printf.sprintf "%scase %s_tag_%s: {\n"
               (indent (depth+1)) enum_name ctor_id.name);
           emit_field_bindings buf (depth+2) scrut_str ctor_id.name subpats fields;
           (* Arm body: if it's a return, emit as-is; otherwise assign to lhs *)
           (match arm.body.expr_desc with
            | EBlock ([{stmt_desc = SReturn _; _}], None)
            | EBlock (_, None) ->
                Buffer.add_string buf (emit_as_return (depth+2) arm.body);
                Buffer.add_char buf '\n'
            | _ ->
                Buffer.add_string buf (emit_as_assign lhs (depth+2) arm.body);
                Buffer.add_char buf '\n';
                Buffer.add_string buf (Printf.sprintf "%sbreak;\n" (indent (depth+2))));
           Buffer.add_string buf (Printf.sprintf "%s}\n" (indent (depth+1)))
       | PWild | PBind _ ->
           Buffer.add_string buf (Printf.sprintf "%sdefault: {\n" (indent (depth+1)));
           (match arm.body.expr_desc with
            | EBlock ([{stmt_desc = SReturn _; _}], None) ->
                Buffer.add_string buf (emit_as_return (depth+2) arm.body);
                Buffer.add_char buf '\n'
            | _ ->
                Buffer.add_string buf (emit_as_assign lhs (depth+2) arm.body);
                Buffer.add_char buf '\n';
                Buffer.add_string buf (Printf.sprintf "%sbreak;\n" (indent (depth+2))));
           Buffer.add_string buf (Printf.sprintf "%s}\n" (indent (depth+1)))
       | _ ->
           Buffer.add_string buf (Printf.sprintf "%sdefault: break;\n" (indent (depth+1))))
    ) arms;
    Buffer.add_string buf (Printf.sprintf "%s}" (indent depth))
  end else begin
    (* Non-enum: if-else chain, same logic *)
    let first = ref true in
    List.iter (fun arm ->
      let kw = if !first then "if" else "else if" in
      first := false;
      let cond = emit_pattern_cond depth scrut arm.pattern in
      Buffer.add_string buf
        (Printf.sprintf "%s%s (%s) {\n" (indent depth) kw cond);
      Buffer.add_string buf (emit_as_assign lhs (depth+1) arm.body);
      Buffer.add_char buf '\n';
      Buffer.add_string buf (Printf.sprintf "%s}\n" (indent depth))
    ) arms
  end;
  Buffer.contents buf

(* ------------------------------------------------------------------ *)
(* Statement emission                                                   *)
(* ------------------------------------------------------------------ *)

and emit_stmt depth s =
  match s.stmt_desc with
  | SGhost _ | SGhostAssign _ ->
      (* Ghost bindings and ghost assignments exist only in the proof context — erased from C. *)
      ""
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
             Printf.sprintf "%s%s %s __attribute__((unused)) = %s;"
               (indent depth) ty_str (c_safe_name id.name) (emit_expr depth e))
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
  | SFor (id, iter, _invs, _dec, body) ->
      let buf = Buffer.create 128 in
      (match iter.expr_ty with
       | Some TStr ->
           (* for x in str: same layout as span<u8> *)
           let idx_var  = Printf.sprintf "__i_%s" id.name in
           let span_var = Printf.sprintf "__span_%s" id.name in
           Buffer.add_string buf
             (Printf.sprintf "%s{ forge_span_u8_t %s = %s;\n"
               (indent depth) span_var (emit_expr depth iter));
           Buffer.add_string buf
             (Printf.sprintf "%s  for (uint64_t %s = 0; %s < %s.len; %s++) {\n"
               (indent depth) idx_var idx_var span_var idx_var);
           Buffer.add_string buf
             (Printf.sprintf "%s    uint8_t %s __attribute__((unused)) = %s.data[%s];\n"
               (indent depth) id.name span_var idx_var);
           List.iter (fun s ->
             Buffer.add_string buf (emit_stmt (depth+2) s);
             Buffer.add_char buf '\n'
           ) body;
           Buffer.add_string buf (indent depth ^ "  }\n");
           Buffer.add_string buf (indent depth ^ "}")
       | Some (TSpan elem_ty) ->
           (* for x in span<T>:
              Cache span in __span_x to avoid double-eval, then index by hidden __i_x. *)
           let span_ty_str = emit_ty (TSpan elem_ty) in
           let elem_ty_str = emit_ty elem_ty in
           let idx_var = Printf.sprintf "__i_%s" id.name in
           let span_var = Printf.sprintf "__span_%s" id.name in
           Buffer.add_string buf
             (Printf.sprintf "%s{ %s %s = %s;\n"
               (indent depth) span_ty_str span_var (emit_expr depth iter));
           Buffer.add_string buf
             (Printf.sprintf "%s  for (uint64_t %s = 0; %s < %s.len; %s++) {\n"
               (indent depth) idx_var idx_var span_var idx_var);
           Buffer.add_string buf
             (Printf.sprintf "%s    %s %s __attribute__((unused)) = %s.data[%s];\n"
               (indent depth) elem_ty_str id.name span_var idx_var);
           List.iter (fun s ->
             Buffer.add_string buf (emit_stmt (depth+2) s);
             Buffer.add_char buf '\n'
           ) body;
           Buffer.add_string buf (indent depth ^ "  }\n");
           Buffer.add_string buf (indent depth ^ "}")
       | Some (TNamed (type_id, _)) when List.mem_assoc type_id.name !iterator_impls ->
           (* for x in iterator: call TypeName__Iterator__next in a loop *)
           let item_ty = List.assoc type_id.name !iterator_impls in
           let item_ty_str = emit_ty item_ty in
           let iter_ty_str = emit_ty (Option.get iter.expr_ty) in
           let opt_ty_str  = Printf.sprintf "Option_%s" (mangle_ty_id item_ty) in
           let next_fn     = type_id.name ^ "__Iterator__next" in
           let iter_var    = Printf.sprintf "__iter_%s" id.name in
           let opt_var     = Printf.sprintf "__opt_%s" id.name in
           Buffer.add_string buf
             (Printf.sprintf "%s{ %s %s = %s;\n"
               (indent depth) iter_ty_str iter_var (emit_expr depth iter));
           Buffer.add_string buf
             (Printf.sprintf "%s  for(;;) {\n" (indent depth));
           Buffer.add_string buf
             (Printf.sprintf "%s    %s %s = %s(&%s);\n"
               (indent depth) opt_ty_str opt_var next_fn iter_var);
           Buffer.add_string buf
             (Printf.sprintf "%s    if (%s.tag == 1) break;\n"
               (indent depth) opt_var);
           Buffer.add_string buf
             (Printf.sprintf "%s    %s %s __attribute__((unused)) = %s.data.Some._v0;\n"
               (indent depth) item_ty_str id.name opt_var);
           List.iter (fun s ->
             Buffer.add_string buf (emit_stmt (depth+2) s);
             Buffer.add_char buf '\n'
           ) body;
           Buffer.add_string buf (indent depth ^ "  }\n");
           Buffer.add_string buf (indent depth ^ "}")
       | _ ->
           (* for i in lo..hi OR for i in n: emit as uint64_t loop *)
           let (init_s, bound_s) = match iter.expr_desc with
             | ERange (lo, hi) ->
                 (Printf.sprintf "(uint64_t)(%s)" (emit_expr depth lo),
                  Printf.sprintf "(uint64_t)(%s)" (emit_expr depth hi))
             | _ ->
                 ("0", Printf.sprintf "(uint64_t)(%s)" (emit_expr depth iter))
           in
           Buffer.add_string buf
             (Printf.sprintf "%sfor (uint64_t %s = %s; %s < %s; %s++) {\n"
               (indent depth) id.name init_s id.name bound_s id.name);
           List.iter (fun s ->
             Buffer.add_string buf (emit_stmt (depth+1) s);
             Buffer.add_char buf '\n'
           ) body;
           Buffer.add_string buf (indent depth ^ "}"));
      Buffer.contents buf
  | SBreak None    -> indent depth ^ "break;"
  | SBreak (Some e) ->
      (* break val — find the enclosing loop_result_N from the loop counter *)
      let n = !loop_result_counter - 1 in
      let result_var = Printf.sprintf "__loop_result_%d" n in
      Printf.sprintf "%s%s = %s; break;" (indent depth) result_var (emit_expr depth e)
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
  (* Set type params so emit_ty can erase them to void *)
  let saved_type_params = !current_type_params in
  current_type_params := List.filter_map (fun (id, k) ->
    match k with KType | KBounded _ -> Some id.name | _ -> None
  ) fn.fn_generics;
  (* GPU qualifier prefix — erased for non-GPU builds *)
  let qual = gpu_qualifier fn.fn_attrs in
  (* requires/ensures are fully erased — proof was discharged *)
  (* KNat generic params become leading uint64_t parameters *)
  let nat_param_strs = List.filter_map (fun (id, k) ->
    match k with
    | KNat       -> Some (Printf.sprintf "uint64_t %s __attribute__((unused))" (c_safe_name id.name))
    | KConst t   -> Some (Printf.sprintf "%s %s __attribute__((unused))" (emit_ty t) (c_safe_name id.name))
    | KType      -> None
    | KBounded _ -> None
  ) fn.fn_generics in
  (* __attribute__((unused)) suppresses -Wunused-parameter for spec-only params *)
  let val_param_strs = List.map (fun (id, ty) ->
    Printf.sprintf "%s %s __attribute__((unused))" (emit_ty ty) (c_safe_name id.name)
  ) fn.fn_params in
  let params_str = String.concat ", " (nat_param_strs @ val_param_strs) in
  (* __global__ kernels must return void — CUDA enforces this; warn if mismatch *)
  let ret_ty =
    if qual = "__global__ " && fn.fn_ret <> TPrim TUnit then begin
      Printf.eprintf
        "  [warn] kernel '%s' has non-void return type — CUDA requires void; using void\n"
        fn.fn_name.name;
      TPrim TUnit
    end else fn.fn_ret
  in
  (* C99: main() must return int — if FORGE main returns u64, emit int main() *)
  let is_main_fn = fn.fn_name.name = "main" && ret_ty <> TPrim TUnit in
  let c_ret_ty = if is_main_fn then "int" else emit_ret_ty ret_ty in
  Buffer.add_string buf
    (Printf.sprintf "%s%s %s(%s)"
      qual c_ret_ty (c_safe_name fn.fn_name.name) params_str);
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
                 if is_main_fn then begin
                   (* main() returns int — use a temp to avoid switch-in-cast issues *)
                   let is_complex = match e.expr_desc with
                     | EMatch _ | EIf _ | EBlock _ -> true | _ -> false
                   in
                   if is_complex then begin
                     Buffer.add_string buf
                       (Printf.sprintf "  %s __forge_main_result;\n" (emit_ty ret_ty));
                     Buffer.add_string buf (emit_as_assign "__forge_main_result" 1 e);
                     Buffer.add_string buf
                       (Printf.sprintf "  return (int)(__forge_main_result);\n")
                   end else
                     Buffer.add_string buf
                       (Printf.sprintf "  return (int)(%s);\n" (emit_expr 1 e))
                 end else
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
            if is_main_fn then begin
              let is_complex = match body.expr_desc with
                | EMatch _ | EIf _ -> true | _ -> false
              in
              if is_complex then
                Buffer.add_string buf
                  (Printf.sprintf "{\n  %s __forge_main_result;\n%s  return (int)(__forge_main_result);\n}"
                    (emit_ty ret_ty) (emit_as_assign "__forge_main_result" 1 body))
              else
                Buffer.add_string buf
                  (Printf.sprintf "{\n  return (int)(%s);\n}" (emit_expr 1 body))
            end else
              Buffer.add_string buf (Printf.sprintf "{\n%s\n}" (emit_as_return 1 body))
        | _ ->
            Buffer.add_string buf (Printf.sprintf "{ %s; }" (emit_expr 0 body))));
  Buffer.add_char buf '\n';
  current_type_params := saved_type_params;
  Buffer.contents buf

let emit_struct sd =
  (* Generic structs (with type parameters) are erased — only concrete
     monomorphizations (e.g. Stack4_u64) are emitted. *)
  let has_type_params = List.exists (fun (_, k) ->
    match k with KType | KBounded _ -> true | _ -> false
  ) sd.sd_params in
  if has_type_params then "" else begin
    let buf = Buffer.create 256 in
    let keyword = if sd.sd_is_union then "union" else "struct" in
    Buffer.add_string buf (Printf.sprintf "typedef %s %s {\n" keyword sd.sd_name.name);
    List.iter (fun (id, ty) ->
      Buffer.add_string buf
        (Printf.sprintf "  %s %s;\n" (emit_ty ty) id.name)
    ) sd.sd_fields;
    let packed_attr = if sd.sd_is_packed then " __attribute__((packed))" else "" in
    Buffer.add_string buf (Printf.sprintf "} %s%s;\n" sd.sd_name.name packed_attr);
    Buffer.contents buf
  end

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
  | IConst (name, ty, e) ->
      Printf.sprintf "static const %s %s = %s;\n"
        (emit_ty ty) name.name (emit_expr 0 e)
  | IType td   ->
      Printf.sprintf "typedef %s %s;\n"
        (emit_ty td.td_ty) td.td_name.name
  | IEnum ed   -> emit_enum ed
  | ITrait _   -> "" (* traits are erased at codegen *)
  | IImpl im   ->
      let ty_name = mangle_ty_id im.im_ty in
      let prefix = match im.im_trait with
        | None          -> ty_name ^ "__"
        | Some trait_id -> ty_name ^ "__" ^ trait_id.name ^ "__"
      in
      String.concat "" (List.filter_map (fun item ->
        match item.item_desc with
        | IFn fn ->
            let mangled_fn = { fn with
              fn_name = { fn.fn_name with name = prefix ^ fn.fn_name.name } }
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
  | EProof _ | ERaw _ | EAssume _ | EAssert _ -> acc
  | EArrayLit elems -> List.fold_left collect_generic_named_expr acc elems
  | EArrayRepeat (v, n) ->
      collect_generic_named_expr (collect_generic_named_expr acc v) n
  | ETuple elems -> List.fold_left collect_generic_named_expr acc elems
  | EField_n (e, _) -> collect_generic_named_expr acc e
  | ESubspan (e2, lo, hi) -> List.fold_left collect_generic_named_expr acc [e2; lo; hi]
  | ERange (lo, hi) -> collect_generic_named_expr (collect_generic_named_expr acc lo) hi
  | ELoop stmts -> List.fold_left collect_generic_named_stmt acc stmts
  | ELambda (_, body, _) -> collect_generic_named_expr acc body

and collect_generic_named_stmt acc s =
  match s.stmt_desc with
  | SGhost _ | SGhostAssign _ -> acc
  | SLet (_, ty_opt, e, _) ->
      let acc = match ty_opt with Some t -> collect_generic_named acc t | None -> acc in
      collect_generic_named_expr acc e
  | SExpr e | SReturn (Some e) -> collect_generic_named_expr acc e
  | SReturn None | SBreak None | SContinue -> acc
  | SBreak (Some e) -> collect_generic_named_expr acc e
  | SWhile (cond, _, _, body) ->
      let acc = collect_generic_named_expr acc cond in
      List.fold_left collect_generic_named_stmt acc body
  | SFor (_, iter, _, _, body) ->
      let acc = collect_generic_named_expr acc iter in
      List.fold_left collect_generic_named_stmt acc body

let rec collect_generic_named_item acc item =
  match item.item_desc with
  | IFn fn ->
      let acc = List.fold_left (fun a (_, t) -> collect_generic_named a t) acc fn.fn_params in
      let acc = collect_generic_named acc fn.fn_ret in
      (match fn.fn_body with
       | Some e -> collect_generic_named_expr acc e
       | None -> acc)
  | IStruct sd ->
      List.fold_left (fun a (_, t) -> collect_generic_named a t) acc sd.sd_fields
  | IImpl im ->
      (* Collect generic instances from impl method bodies and associated types *)
      let acc = List.fold_left (fun a iat -> collect_generic_named a iat.iat_ty) acc im.im_assoc_tys in
      List.fold_left collect_generic_named_item acc im.im_items
  | _ -> acc

let emit_program prog =
  (* Build enum constructor registry before any emission *)
  build_enum_registry prog.prog_items;
  (* Build fn_first_param_is_ref: true if first param is ref<T> or refmut<T> *)
  Hashtbl.clear fn_first_param_is_ref;
  let register_fn_params prefix (fn : fn_def) =
    let name = prefix ^ fn.fn_name.name in
    let is_ref = match fn.fn_params with
      | (_, TRef _) :: _ | (_, TRefMut _) :: _ -> true
      | _ -> false
    in
    Hashtbl.replace fn_first_param_is_ref name is_ref
  in
  List.iter (fun item ->
    match item.item_desc with
    | IFn fn -> register_fn_params "" fn
    | IImpl im ->
        let ty_name = mangle_ty_id im.im_ty in
        let prefix = match im.im_trait with
          | None          -> ty_name ^ "__"
          | Some trait_id -> ty_name ^ "__" ^ trait_id.name ^ "__"
        in
        List.iter (fun it -> match it.item_desc with
          | IFn fn -> register_fn_params prefix fn
          | _ -> ()) im.im_items
    | _ -> ()
  ) prog.prog_items;
  (* Build method dispatch map: "TypeName__method" → "TypeName__Trait__method" *)
  method_map := List.concat_map (fun item ->
    match item.item_desc with
    | IImpl im when im.im_trait <> None ->
        let ty_name = mangle_ty_id im.im_ty in
        let trait_name = (Option.get im.im_trait).name in
        let full_prefix = ty_name ^ "__" ^ trait_name ^ "__" in
        let short_prefix = ty_name ^ "__" in
        List.filter_map (fun it ->
          match it.item_desc with
          | IFn fn ->
              let full  = full_prefix  ^ fn.fn_name.name in
              let short = short_prefix ^ fn.fn_name.name in
              Some (short, full)
          | _ -> None
        ) im.im_items
    | _ -> []
  ) prog.prog_items;
  (* Build iterator impl registry: ty_name → Item type *)
  iterator_impls := List.filter_map (fun item ->
    match item.item_desc with
    | IImpl im when (match im.im_trait with Some {name="Iterator";_} -> true | _ -> false) ->
        let ty_name = match im.im_ty with TNamed (id, _) -> id.name | _ -> "" in
        let item_ty = List.find_map (fun iat ->
          if iat.iat_name.name = "Item" then Some iat.iat_ty else None
        ) im.im_assoc_tys in
        (match ty_name, item_ty with
         | "", _ | _, None -> None
         | name, Some t    -> Some (name, t))
    | _ -> None
  ) prog.prog_items;
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
  (* Pre-collect all span, generic, and tuple types BEFORE emitting struct defs,
     so typedefs are available when structs reference them. *)
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
  (* Emit type definitions (struct, enum, typedef, extern) — after span typedefs
     so structs that contain span<T> fields can reference forge_span_T_t.
     Generic enums are skipped here (already emitted above after monomorphization).
     Functions and impl blocks are deferred to passes 2+3. *)
  List.iter (fun item ->
    let code = match item.item_desc with
      | IFn _ | IImpl _ -> ""
      | IExtern ex when is_system_extern ex -> ""
      | IEnum ed when ed.ed_params <> [] -> ""
      | _ -> emit_item item ^ "\n"
    in
    Buffer.add_string buf code
  ) prog.prog_items;
  (* Emit tuple typedefs for each unique tuple type used *)
  let tuple_types = collect_tuple_types prog.prog_items in
  if tuple_types <> [] then begin
    Buffer.add_string buf "/* Tuple typedefs */\n";
    List.iter (fun (_key, elem_tys) ->
      let tup_ty = TTuple elem_tys in
      let fields = List.mapi (fun i t ->
        Printf.sprintf "%s _%d;" (emit_ty t) i
      ) elem_tys in
      Buffer.add_string buf
        (Printf.sprintf "typedef struct { %s } %s;\n"
           (String.concat " " fields) (emit_ty tup_ty))
    ) (List.rev tuple_types);
    Buffer.add_char buf '\n'
  end;
  (* Emit function pointer typedefs for each unique fn(...)->T type used *)
  let fn_ptr_types = collect_fn_ptr_types prog.prog_items in
  if fn_ptr_types <> [] then begin
    Buffer.add_string buf "/* Function pointer typedefs */\n";
    List.iter (fun (key, fty) ->
      let ret_str = emit_ty fty.ret in
      let params_str =
        if fty.params = [] then "void"
        else String.concat ", " (List.map (fun (_, t) -> emit_ty t) fty.params)
      in
      Buffer.add_string buf
        (Printf.sprintf "typedef %s (*forge_%s_t)(%s);\n" ret_str key params_str)
    ) (List.rev fn_ptr_types);
    Buffer.add_char buf '\n'
  end;
  (* Emit own<T> heap helpers for each unique element type.
     own_alloc(val) → T* heap-allocated, initialised to val.
     own_into(p)    → reads *p, frees p, returns value.          *)
  let own_tys = collect_own_types prog.prog_items in
  if own_tys <> [] then begin
    Buffer.add_string buf "/* own<T> heap helpers (linear ownership) */\n";
    List.iter (fun (key, elem_ty) ->
      let ty_str = emit_ty elem_ty in
      Buffer.add_string buf
        (Printf.sprintf
           "static inline %s* __forge_own_alloc_%s(%s __val) \
            { %s* __p = (%s*)malloc(sizeof(%s)); *__p = __val; return __p; }\n"
           ty_str key ty_str   ty_str ty_str ty_str);
      Buffer.add_string buf
        (Printf.sprintf
           "static inline %s  __forge_own_into_%s(%s* __p) \
            { %s __v = *__p; free(__p); return __v; }\n"
           ty_str key ty_str   ty_str);
      (* own_get: only emit if the (T, own<T>) tuple type is actually used *)
      let tup_ty = TTuple [elem_ty; TOwn elem_ty] in
      let tup_key = mangle_ty_id tup_ty in
      if List.mem_assoc tup_key tuple_types then
        Buffer.add_string buf
          (Printf.sprintf
             "static inline %s __forge_own_get_%s(%s* __p) \
              { return (%s){ ._0 = *__p, ._1 = __p }; }\n"
             (emit_ty tup_ty) key ty_str   (emit_ty tup_ty));
      (* own_borrow: only emit if the (ref<T>, own<T>) tuple type is used *)
      let borrow_tup_ty = TTuple [TRef elem_ty; TOwn elem_ty] in
      let borrow_tup_key = mangle_ty_id borrow_tup_ty in
      if List.mem_assoc borrow_tup_key tuple_types then
        Buffer.add_string buf
          (Printf.sprintf
             "static inline %s __forge_own_borrow_%s(%s* __p) \
              { return (%s){ ._0 = __p, ._1 = __p }; }\n"
             (emit_ty borrow_tup_ty) key ty_str   (emit_ty borrow_tup_ty));
      (* own_borrow_mut: only emit if the (refmut<T>, own<T>) tuple type is used *)
      let borrow_mut_tup_ty = TTuple [TRefMut elem_ty; TOwn elem_ty] in
      let borrow_mut_tup_key = mangle_ty_id borrow_mut_tup_ty in
      if List.mem_assoc borrow_mut_tup_key tuple_types then
        Buffer.add_string buf
          (Printf.sprintf
             "static inline %s __forge_own_borrow_mut_%s(%s* __p) \
              { return (%s){ ._0 = __p, ._1 = __p }; }\n"
             (emit_ty borrow_mut_tup_ty) key ty_str   (emit_ty borrow_mut_tup_ty))
    ) (List.rev own_tys);
    Buffer.add_char buf '\n'
  end;
  (* Collect all fns including impl methods for passes 2+3 *)
  let all_fns =
    List.concat_map (fun item ->
      match item.item_desc with
      | IFn fn when fn.fn_body <> None -> [fn]
      | IImpl im ->
          let ty_name = mangle_ty_id im.im_ty in
          let prefix = match im.im_trait with
            | None          -> ty_name ^ "__"
            | Some trait_id -> ty_name ^ "__" ^ trait_id.name ^ "__"
          in
          List.filter_map (fun it ->
            match it.item_desc with
            | IFn fn when fn.fn_body <> None ->
                Some { fn with fn_name = { fn.fn_name with name = prefix ^ fn.fn_name.name } }
            | _ -> None
          ) im.im_items
      | _ -> []
    ) prog.prog_items
  in
  (* Pass 2: forward declarations for all functions with bodies *)
  if all_fns <> [] then begin
    Buffer.add_string buf "/* Forward declarations */\n";
    List.iter (fun fn ->
      current_type_params := List.filter_map (fun (id, k) ->
        match k with KType | KBounded _ -> Some id.name | _ -> None
      ) fn.fn_generics;
      let qual = gpu_qualifier fn.fn_attrs in
      let ret_ty =
        if qual = "__global__ " && fn.fn_ret <> TPrim TUnit then TPrim TUnit
        else fn.fn_ret
      in
      let nat_fwd = List.filter_map (fun (id, k) ->
        match k with
        | KNat       -> Some (Printf.sprintf "uint64_t %s __attribute__((unused))" (c_safe_name id.name))
        | KConst t   -> Some (Printf.sprintf "%s %s __attribute__((unused))" (emit_ty t) (c_safe_name id.name))
        | KType      -> None
        | KBounded _ -> None
      ) fn.fn_generics in
      let val_fwd = List.map (fun (id, ty) ->
        Printf.sprintf "%s %s __attribute__((unused))" (emit_ty ty) (c_safe_name id.name)
      ) fn.fn_params in
      let fwd_params = String.concat ", " (nat_fwd @ val_fwd) in
      (* C99: main() must return int *)
      let fwd_ret_ty = if fn.fn_name.name = "main" && ret_ty <> TPrim TUnit
                       then "int" else emit_ret_ty ret_ty in
      Buffer.add_string buf
        (Printf.sprintf "%s%s %s(%s);\n"
          qual fwd_ret_ty (c_safe_name fn.fn_name.name) fwd_params);
      current_type_params := []
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
