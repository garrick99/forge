(* FORGE Type Checker + Proof Obligation Generator

   Walks the AST and:
   1. Resolves and infers types for all expressions
   2. Generates proof obligations at each potentially-unsafe site
   3. Tracks linear value usage
   4. Logs assume() calls to the audit trail

   The proof engine is invoked on each obligation.
   Any undischarged obligation is a hard error — compilation stops. *)

open Ast
open Proof_engine

(* ------------------------------------------------------------------ *)
(* Type environment                                                     *)
(* ------------------------------------------------------------------ *)

type var_info = {
  vi_ty:      ty;
  vi_linearity: linearity;
  vi_used:    bool ref;    (* for linear tracking *)
  vi_loc:     loc;
}

type fn_sig = {
  fs_name:        string;           (* for self-call detection *)
  fs_type_params: string list;      (* type parameter names; [] if not generic *)
  fs_generics:    (string * kind) list; (* generic param kinds — for bound checking *)
  fs_params:      (ident * ty) list;
  fs_ret:         ty;
  fs_requires:    pred list;
  fs_ensures:     pred list;
  fs_decreases:   pred option;      (* termination measure *)
}

type env = {
  vars:    (string * var_info) list;
  fns:     (string * fn_sig) list;
  types:   (string * ty) list;
  structs: (string * struct_def) list;
  enums:   (string * enum_def) list;   (* enum name → definition *)
  traits:  (string * trait_def) list;  (* trait name → definition *)
  (* Trait implementation registry: (ty_name, trait_name) pairs *)
  impls:   (string * string) list;
  (* Associated type registry: (ty_name, trait_name, assoc_name) → concrete ty *)
  assoc_tys: (string * string * string * ty) list;
  (* Self type — set when inside an impl block *)
  self_ty: ty option;
  (* Current function context for checking ensures *)
  current_fn: fn_sig option;
  (* Downward-propagated expected type — used to resolve zero-arg generic constructors *)
  expected_ty: ty option;
  (* Proof context — what we know is true here *)
  proof_ctx: proof_ctx;
  (* GPU execution context *)
  is_gpu_fn:         bool;   (* inside a #[kernel] function *)
  after_barrier:     bool;   (* __syncthreads() has been called *)
  in_varying_branch: bool;   (* inside a branch on a varying condition *)
  coalesced_fn:      bool;   (* #[coalesced] annotation active *)
  (* Mutual recursion group — SCC id for this function *)
  scc_id: int option;
  (* Value-returning loop context — Some ref means we're inside a loop { break val } *)
  loop_break_ty: ty option ref option;
}

let empty_env = {
  vars               = [];
  fns                = [];
  types              = [];
  structs            = [];
  enums              = [];
  traits             = [];
  impls              = [];
  assoc_tys          = [];
  self_ty            = None;
  current_fn         = None;
  expected_ty        = None;
  proof_ctx          = empty_ctx;
  is_gpu_fn          = false;
  after_barrier      = false;
  in_varying_branch  = false;
  coalesced_fn       = false;
  scc_id             = None;
  loop_break_ty      = None;
}

let env_add_var env name ty lin loc =
  let vi = { vi_ty = ty; vi_linearity = lin; vi_used = ref false; vi_loc = loc } in
  { env with vars = (name, vi) :: env.vars;
             proof_ctx = ctx_add_var env.proof_ctx name ty }

let env_lookup_var env name =
  List.assoc_opt name env.vars

let env_lookup_fn env name =
  List.assoc_opt name env.fns

let env_add_fn env name sig_ =
  { env with fns = (name, sig_) :: env.fns }

let env_add_fact env pred =
  { env with proof_ctx = ctx_add_assume env.proof_ctx pred }

(* Trait/assoc type helpers *)
let env_add_impl env ty_name trait_name =
  { env with impls = (ty_name, trait_name) :: env.impls }

let env_has_impl env ty_name trait_name =
  List.mem (ty_name, trait_name) env.impls

let env_add_assoc_ty env ty_name trait_name assoc_name concrete_ty =
  { env with assoc_tys = (ty_name, trait_name, assoc_name, concrete_ty) :: env.assoc_tys }

let resolve_assoc_ty env ty assoc_name =
  let ty_name = match ty with TNamed (id, _) -> id.name | _ -> "" in
  List.find_map (fun (tn, _trait, an, ct) ->
    if tn = ty_name && an = assoc_name then Some ct else None
  ) env.assoc_tys

(* Resolve Self type and associated types using current impl context *)
let rec resolve_self env ty =
  match ty with
  | TNamed ({name="Self"; _}, []) ->
      (match env.self_ty with Some t -> t | None -> ty)
  | TAssoc (TNamed ({name="Self"; _}, []), assoc_name) ->
      (match env.self_ty with
       | Some self_t ->
           (match resolve_assoc_ty env self_t assoc_name with
            | Some t -> t
            | None   -> ty)
       | None -> ty)
  | TAssoc (base, assoc_name) ->
      (match resolve_assoc_ty env base assoc_name with
       | Some t -> t
       | None   -> TAssoc (resolve_self env base, assoc_name))
  | TRef t          -> TRef (resolve_self env t)
  | TRefMut t       -> TRefMut (resolve_self env t)
  | TOwn t          -> TOwn (resolve_self env t)
  | TSpan t         -> TSpan (resolve_self env t)
  | TNamed (id, args) -> TNamed (id, List.map (resolve_self env) args)
  | TTuple tys      -> TTuple (List.map (resolve_self env) tys)
  | t -> t

(* SSA counter — gives fresh names for renamed variables *)
let fresh_counter : int ref = ref 0

(* SSA-lite assignment tracking.
   When a variable x is assigned (x = rhs), we:
   1. Rename all existing proof facts mentioning x to __x_pN (a fresh alias)
   2. Add __x_pN to the variable context (same type as x)
   3. Add the new fact  x == renamed(rhs)
   This prevents Z3 contradictions from x = x - 1 style updates. *)
let env_assign_var env (var_id : ident) (rhs_pred : pred) =
  let n = !fresh_counter in
  incr fresh_counter;
  let old_name = Printf.sprintf "__%s_p%d" var_id.name n in
  let old_ty = match List.assoc_opt var_id.name env.vars with
    | Some vi -> vi.vi_ty
    | None    -> TPrim (TUint U64)
  in
  let rec rename_pred pred = match pred with
    | PVar id when id.name = var_id.name -> PVar { id with name = old_name }
    | PBinop (op, l, r) -> PBinop (op, rename_pred l, rename_pred r)
    | PUnop (op, p)     -> PUnop (op, rename_pred p)
    | PIte (c, t, e)    -> PIte (rename_pred c, rename_pred t, rename_pred e)
    | PApp (f, args)    -> PApp (f, List.map rename_pred args)
    | PLex ps           -> PLex (List.map rename_pred ps)
    | PField (p, f)     -> PField (rename_pred p, f)
    | PStruct (n, flds) -> PStruct (n, List.map (fun (f, p) -> (f, rename_pred p)) flds)
    | PIndex (arr, idx) -> PIndex (rename_pred arr, rename_pred idx)
    | PForall (x, ty, p) ->
        (* Don't rename inside a quantifier that shadows var_id *)
        if x.name = var_id.name then PForall (x, ty, p)
        else PForall (x, ty, rename_pred p)
    | PExists (x, ty, p) ->
        if x.name = var_id.name then PExists (x, ty, p)
        else PExists (x, ty, rename_pred p)
    | _                 -> pred
  in
  let renamed_assumes = List.map rename_pred env.proof_ctx.pc_assumes in
  let renamed_rhs     = rename_pred rhs_pred in
  let new_fact        = PBinop (Eq, PVar var_id, renamed_rhs) in
  let new_ctx = { env.proof_ctx with
    pc_vars    = (old_name, old_ty) :: env.proof_ctx.pc_vars;
    pc_assumes = new_fact :: renamed_assumes;
  } in
  { env with proof_ctx = new_ctx }

(* Field-write SSA: model base.field = rhs as a renamed snapshot.
   Renames PField(base, field) -> PVar "__base__field__pN" in all existing
   facts, then adds the new fact PField(base, field) == rhs.
   This preserves semantic consistency: old facts about base.field use
   the renamed version, while new facts use the current value. *)
let env_assign_field env (base_pred : pred) (field_name : string) (rhs_pred : pred) =
  let n = !fresh_counter in
  incr fresh_counter;
  (* Build the flat SMT name for this field access, e.g. c__state or r__br__x *)
  let rec flatten_base = function
    | PVar id        -> id.name
    | PField (p, f)  -> flatten_base p ^ "__" ^ f
    | _              -> "__unknown"
  in
  let flat_name = flatten_base base_pred ^ "__" ^ field_name in
  let old_name  = Printf.sprintf "__%s_p%d" flat_name n in
  let old_ty    = TPrim (TUint U64) in
  (* Rename every occurrence of PField(base, field_name) in a pred.
     We match structurally using pred equality on the base. *)
  let rec pred_eq a b = match a, b with
    | PVar ia, PVar ib -> ia.name = ib.name
    | PField (pa, fa), PField (pb, fb) -> fa = fb && pred_eq pa pb
    | _ -> false
  in
  let target = PField (base_pred, field_name) in
  let rename_to = PVar { name = old_name; loc = dummy_loc } in
  let rec rename_pred pred =
    if pred_eq pred target then rename_to
    else match pred with
    | PBinop (op, l, r) -> PBinop (op, rename_pred l, rename_pred r)
    | PUnop (op, p)     -> PUnop (op, rename_pred p)
    | PIte (c, t, e)    -> PIte (rename_pred c, rename_pred t, rename_pred e)
    | PApp (f, args)    -> PApp (f, List.map rename_pred args)
    | PLex ps           -> PLex (List.map rename_pred ps)
    | PField (p, f)     -> PField (rename_pred p, f)
    | PStruct (s, flds) -> PStruct (s, List.map (fun (f, p) -> (f, rename_pred p)) flds)
    | PIndex (arr, idx) -> PIndex (rename_pred arr, rename_pred idx)
    | PForall (x, ty, p) -> PForall (x, ty, rename_pred p)
    | PExists (x, ty, p) -> PExists (x, ty, rename_pred p)
    | _                 -> pred
  in
  let renamed_assumes = List.map rename_pred env.proof_ctx.pc_assumes in
  let renamed_rhs     = rename_pred rhs_pred in
  let new_fact        = PBinop (Eq, target, renamed_rhs) in
  let new_ctx = { env.proof_ctx with
    pc_vars    = (old_name, old_ty) :: env.proof_ctx.pc_vars;
    pc_assumes = new_fact :: renamed_assumes;
  } in
  { env with proof_ctx = new_ctx }

(* Array-write SSA: model s[i] = v as s_new = store(s_old, i, v).
   Renames current s → __s_pN, then adds:
     s[idx] == rhs              (the write)
     forall j != idx, s[j] == __s_pN[j]   (frame: other elements unchanged)
     s.len == __s_pN.len        (length invariant)
   This gives Z3 enough to reason about swaps and multi-write loops. *)
let env_array_write env (arr_id : ident) (idx_pred : pred) (rhs_pred : pred) =
  let n = !fresh_counter in
  incr fresh_counter;
  let old_name = Printf.sprintf "__%s_p%d" arr_id.name n in
  let old_arr  = PVar { arr_id with name = old_name } in
  let new_arr  = PVar arr_id in
  let rec rename_pred pred = match pred with
    | PVar id when id.name = arr_id.name -> old_arr
    | PField (PIndex (PVar base_id, idx), field_name)
        when base_id.name ^ "__" ^ field_name = arr_id.name ->
        (* struct-of-arrays: PField(PIndex(PVar "arr", idx), "field") encodes as
           (select arr__field idx) in SMT — same variable as arr_id "arr__field".
           Rename it to (select __arr__field_pN idx) so SSA stays consistent. *)
        PIndex (old_arr, rename_pred idx)
    | PBinop (op, l, r) -> PBinop (op, rename_pred l, rename_pred r)
    | PUnop (op, p)     -> PUnop (op, rename_pred p)
    | PIte (c, t, e)    -> PIte (rename_pred c, rename_pred t, rename_pred e)
    | PApp (f, args)    -> PApp (f, List.map rename_pred args)
    | PLex ps           -> PLex (List.map rename_pred ps)
    | PField (p, f)     -> PField (rename_pred p, f)
    | PStruct (nm, flds)-> PStruct (nm, List.map (fun (f, p) -> (f, rename_pred p)) flds)
    | PIndex (arr, idx) -> PIndex (rename_pred arr, rename_pred idx)
    | PForall (x, ty, p) ->
        if x.name = arr_id.name then PForall (x, ty, p)
        else PForall (x, ty, rename_pred p)
    | PExists (x, ty, p) ->
        if x.name = arr_id.name then PExists (x, ty, p)
        else PExists (x, ty, rename_pred p)
    | _ -> pred
  in
  let renamed_assumes = List.map rename_pred env.proof_ctx.pc_assumes in
  let idx_pred' = rename_pred idx_pred in
  let rhs_pred' = rename_pred rhs_pred in
  (* Frame quantifier variable — unique per write *)
  let j_name = Printf.sprintf "__fj_%d" n in
  let j_id   = { name = j_name; loc = arr_id.loc } in
  let write_fact = PBinop (Eq, PIndex (new_arr, idx_pred'), rhs_pred') in
  let frame_fact = PForall (j_id, TPrim (TUint U64),
    PBinop (Implies,
      PBinop (Ne, PVar j_id, idx_pred'),
      PBinop (Eq, PIndex (new_arr, PVar j_id), PIndex (old_arr, PVar j_id)))) in
  let len_fact = PBinop (Eq, PField (new_arr, "len"), PField (old_arr, "len")) in
  let old_arr_ty = match List.assoc_opt arr_id.name env.vars with
    | Some vi -> vi.vi_ty
    | None    -> TSpan (TPrim (TUint U64))
  in
  let new_ctx = { env.proof_ctx with
    pc_vars    = (old_name, old_arr_ty) :: env.proof_ctx.pc_vars;
    pc_assumes = len_fact :: frame_fact :: write_fact :: renamed_assumes;
  } in
  { env with proof_ctx = new_ctx }

(* ------------------------------------------------------------------ *)
(* Error type                                                           *)
(* ------------------------------------------------------------------ *)

type tc_error =
  | TypeError       of loc * string
  | ProofError      of proof_error
  | LinearityError  of loc * string
  | UnboundVar      of loc * string
  | UnboundFn       of loc * string
  | ArityMismatch   of loc * string * int * int

exception TypeCheckFailed of tc_error list

let errors : tc_error list ref = ref []

(* Global type alias registry — populated by IType items, used in normalize_ty *)
let type_aliases : (string * ty) list ref = ref []

let report_error e =
  errors := e :: !errors

let fail loc msg =
  report_error (TypeError (loc, msg))

(* ------------------------------------------------------------------ *)
(* Primitive type utilities                                             *)
(* ------------------------------------------------------------------ *)

(* Strip uniform/varying qualifier — qualifiers are proof-time only *)
let strip_qual = function TQual (_, t) -> t | t -> t

(* Secret taint helpers *)
let is_secret = function TSecret _ -> true | _ -> false
let strip_secret = function TSecret t -> t | t -> t

(* Normalize: convert TNamed("secret", [t]) from parser → TSecret t in AST *)
(* Mangle a type to a C-identifier-safe string, matching codegen's mangle_ty_id.
   Used to compute impl method prefixes for generic types like Option<u64> → "Option_u64". *)
let rec mangle_ty_name = function
  | TPrim (TUint U8)  -> "u8"  | TPrim (TUint U16) -> "u16"
  | TPrim (TUint U32) -> "u32" | TPrim (TUint U64) -> "u64"
  | TPrim (TUint U128)-> "u128"| TPrim (TInt I8)   -> "i8"
  | TPrim (TInt I16)  -> "i16" | TPrim (TInt I32)  -> "i32"
  | TPrim (TInt I64)  -> "i64" | TPrim (TInt I128) -> "i128"
  | TPrim TBool       -> "bool"| TPrim (TFloat F32)-> "f32"
  | TPrim (TFloat F64)-> "f64" | TPrim TUnit       -> "unit"
  | TNamed (id, [])   -> id.name
  | TNamed (id, args) -> id.name ^ "_" ^ String.concat "_" (List.map mangle_ty_name args)
  | TRef t            -> "ref_" ^ mangle_ty_name t
  | TRefMut t         -> "refmut_" ^ mangle_ty_name t
  | TSpan t           -> "span_" ^ mangle_ty_name t
  | TStr              -> "str"
  | _                 -> "ty"

let rec normalize_ty = function
  | TNamed ({name="secret"; _}, [t]) -> TSecret (normalize_ty t)
  | TRef t -> TRef (normalize_ty t)
  | TRefMut t -> TRefMut (normalize_ty t)
  | TOwn t -> TOwn (normalize_ty t)
  | TRaw t -> TRaw (normalize_ty t)
  | TArray (t, e) -> TArray (normalize_ty t, e)
  | TSlice t -> TSlice (normalize_ty t)
  | TNamed (id, []) when List.mem_assoc id.name !type_aliases ->
      normalize_ty (List.assoc id.name !type_aliases)
  | TNamed (id, args) -> TNamed (id, List.map normalize_ty args)
  | TSpan t -> TSpan (normalize_ty t)
  | TShared (t, e) -> TShared (normalize_ty t, e)
  | TQual (q, t) -> TQual (q, normalize_ty t)
  | TSecret t -> TSecret (normalize_ty t)
  | TTuple tys -> TTuple (List.map normalize_ty tys)
  | TStr -> TStr
  | TAssoc (base, assoc) -> TAssoc (normalize_ty base, assoc)
  | t -> t

let rec prim_of_ty = function
  | TPrim p            -> Some p
  | TRefined (p, _, _) -> Some p
  | TQual (_, t)       -> (match t with TPrim p | TRefined (p,_,_) -> Some p | _ -> None)
  | TSecret t          -> prim_of_ty t
  | _                  -> None

(* GPU uniformity: Varying propagates — if any operand is Varying, result is Varying *)
let qual_of_ty = function
  | TQual (q, _) -> q
  | _            -> Uniform   (* unqualified → treat as uniform *)

let combine_qual q1 q2 = match q1, q2 with
  | Uniform, Uniform -> Uniform
  | _                -> Varying

let is_numeric ty =
  match prim_of_ty (strip_qual ty) with
  | Some (TInt _) | Some (TUint _) | Some (TFloat _) -> true
  | _ -> false

let is_bool ty =
  match prim_of_ty (strip_qual ty) with
  | Some TBool -> true
  | _ -> false

let is_integer ty =
  match prim_of_ty (strip_qual ty) with
  | Some (TInt _) | Some (TUint _) -> true
  | _ -> false

(* Widen a refined type to its base *)
let base_ty = function
  | TRefined (p, _, _) -> TPrim p
  | TQual (_, t)       -> t    (* strip qualifier *)
  | t -> t

(* Type equality (structural) — strip qualifiers before comparing *)
let rec ty_eq t1 t2 =
  let t1 = normalize_ty (strip_qual t1)
  and t2 = normalize_ty (strip_qual t2) in
  match t1, t2 with
  | TPrim p1, TPrim p2 -> p1 = p2
  | TRefined (p1, _, _), TRefined (p2, _, _) -> p1 = p2
  | TRefined (p1, _, _), TPrim p2 -> p1 = p2
  | TPrim p1, TRefined (p2, _, _) -> p1 = p2
  | TRef t1, TRef t2 -> ty_eq t1 t2
  | TRefMut t1, TRefMut t2 -> ty_eq t1 t2
  | TRaw t1, TRaw t2 -> ty_eq t1 t2
  | TOwn t1, TOwn t2 -> ty_eq t1 t2
  | TSlice t1, TSlice t2 -> ty_eq t1 t2
  | TSpan t1, TSpan t2 -> ty_eq t1 t2
  | TShared (t1, _), TShared (t2, _) -> ty_eq t1 t2
  | TArray (t1, _), TArray (t2, _) -> ty_eq t1 t2
  | TNamed (n1, args1), TNamed (n2, args2) ->
      n1.name = n2.name &&
      List.length args1 = List.length args2 &&
      List.for_all2 ty_eq args1 args2
  | TSecret t1, TSecret t2 -> ty_eq t1 t2
  | TTuple ts1, TTuple ts2 ->
      List.length ts1 = List.length ts2 && List.for_all2 ty_eq ts1 ts2
  (* str == span<u8> *)
  | TStr, TStr -> true
  | TStr, TSpan (TPrim (TUint U8)) | TSpan (TPrim (TUint U8)), TStr -> true
  | TAssoc (b1, n1), TAssoc (b2, n2) -> n1 = n2 && ty_eq b1 b2
  | TFn fty1, TFn fty2 ->
      ty_eq fty1.ret fty2.ret &&
      List.length fty1.params = List.length fty2.params &&
      List.for_all2 (fun (_, t1) (_, t2) -> ty_eq t1 t2) fty1.params fty2.params
  | TDepArr (_, dom1, cod1), TDepArr (_, dom2, cod2) ->
      (* Structural equality on domain and codomain; binder name is irrelevant *)
      ty_eq dom1 dom2 && ty_eq cod1 cod2
  | TDepArr (_, dom, cod), TFn fty ->
      (* TDepArr is compatible with an anonymous TFn of the same domain/codomain *)
      (match fty.params with
       | [(_, p)] -> ty_eq dom p && ty_eq cod fty.ret
       | _        -> false)
  | TFn fty, TDepArr (_, dom, cod) ->
      (match fty.params with
       | [(_, p)] -> ty_eq p dom && ty_eq fty.ret cod
       | _        -> false)
  | _ -> false

(* Numeric coercion: integer literals default to u64, but when used alongside a
   narrower type in an if-branch or let-binding, we prefer the narrower type.
   This is safe because FORGE proofs use untyped SMT integers; width only affects
   C codegen output. *)
let ty_unify t1 t2 =
  if ty_eq t1 t2 then t1
  else match base_ty t1, base_ty t2 with
  | TPrim (TUint U64), TPrim (TUint w) -> TPrim (TUint w)
  | TPrim (TUint w), TPrim (TUint U64) -> TPrim (TUint w)
  | TPrim (TInt I64),  TPrim (TInt w)  -> TPrim (TInt w)
  | TPrim (TInt w),  TPrim (TInt I64)  -> TPrim (TInt w)
  | _ -> t1

(* Two integer types are compatible if they unify (narrower wins over u64 default).
   secret<T> is compatible with T in both directions: classification (T→secret<T>)
   is free everywhere; the taint rules and declassify() enforce discipline at use. *)
let ty_compatible t1 t2 =
  let t1 = strip_secret t1 and t2 = strip_secret t2 in
  ty_eq (base_ty t1) (base_ty t2)
  || (match base_ty t1, base_ty t2 with
      | TPrim (TUint _), TPrim (TUint _) -> true
      | TPrim (TInt _),  TPrim (TInt _)  -> true
      | _ -> false)

(* Numeric type for binary operation result *)
let numeric_result_ty t1 t2 =
  (* Pointer arithmetic: raw<T> +/- integer = raw<T> *)
  match t1, t2 with
  | TRaw t, _ -> TRaw t
  | _, TRaw t -> TRaw t
  | _ ->
  match base_ty t1, base_ty t2 with
  | TPrim (TUint U64), _ | _, TPrim (TUint U64) -> TPrim (TUint U64)
  | TPrim (TUint U32), _ | _, TPrim (TUint U32) -> TPrim (TUint U32)
  | TPrim (TInt I64),  _ | _, TPrim (TInt I64)  -> TPrim (TInt I64)
  | TPrim (TInt I32),  _ | _, TPrim (TInt I32)  -> TPrim (TInt I32)
  | TPrim (TFloat F64),_ | _, TPrim (TFloat F64)-> TPrim (TFloat F64)
  | TPrim (TFloat F32),_ | _, TPrim (TFloat F32)-> TPrim (TFloat F32)
  | t, _ -> t

(* ------------------------------------------------------------------ *)
(* Proof obligation generation                                          *)
(* ------------------------------------------------------------------ *)

let obligations : obligation list ref = ref []
(* Synthesized default method implementations, added to the program before codegen *)
let synthesized_items : item list ref = ref []

let add_obligation pred kind loc ctx =
  obligations := {
    ob_pred    = pred;
    ob_kind    = kind;
    ob_loc     = loc;
    ob_ctx     = ctx.proof_ctx.pc_vars;
    ob_assumes = ctx.proof_ctx.pc_assumes;
    ob_status  = Pending;
  } :: !obligations

(* Collect free variable names from a predicate. *)
let rec pred_free_vars p =
  match p with
  | PVar id              -> [id.name]
  | PBinop (_, l, r)    -> pred_free_vars l @ pred_free_vars r
  | PUnop (_, q)        -> pred_free_vars q
  | PIte (c, t, e)      -> pred_free_vars c @ pred_free_vars t @ pred_free_vars e
  | PApp (_, args)      -> List.concat_map pred_free_vars args
  | PLex ps             -> List.concat_map pred_free_vars ps
  | PField (q, _)       -> pred_free_vars q
  | PStruct (_, flds)   -> List.concat_map (fun (_, q) -> pred_free_vars q) flds
  | PIndex (a, i)       -> pred_free_vars a @ pred_free_vars i
  | POld q              -> pred_free_vars q
  | PForall (x, _, q)   -> List.filter (fun n -> n <> x.name) (pred_free_vars q)
  | PExists (x, _, q)   -> List.filter (fun n -> n <> x.name) (pred_free_vars q)
  | _                   -> []

(* Return the match-arm condition predicate for a pattern.
   scrut_pred: the scrutinee as a pred (from expr_to_pred_simple).
   Used by expr_to_pred_simple for EMatch PIte construction. *)
let rec pattern_to_cond_pred scrut_pred pat =
  match pat with
  | PWild | PBind _ -> PBool true
  | PLit (LInt (n, _))  -> PBinop (Eq, scrut_pred, PInt n)
  | PLit (LBool b)      -> PBinop (Eq, scrut_pred, PBool b)
  | PLit _              -> PBool true
  | PCtor (id, _)       ->
      (* Enum discriminant check: scrut.tag == CtorId *)
      PBinop (Eq, PField (scrut_pred, "tag"), PVar id)
  | PLitRange (LInt (lo, _), LInt (hi, _)) ->
      PBinop (And,
        PBinop (Ge, scrut_pred, PInt lo),
        PBinop (Le, scrut_pred, PInt hi))
  | PLitRange _ -> PBool true
  | PAs (inner, _)      -> pattern_to_cond_pred scrut_pred inner
  | POr  (p1, p2)       ->
      PBinop (Or, pattern_to_cond_pred scrut_pred p1,
                  pattern_to_cond_pred scrut_pred p2)
  | PTuple _ -> PBool true

(* Translate expression to pred for obligation generation — defined first,
   used by check_division / check_bounds / check_preconditions below *)
let rec expr_to_pred_simple e =
  match e.expr_desc with
  | ELit (LInt (n, _))    -> PInt n
  | ELit (LFloat (f, _))  -> PFloat f
  | ELit (LBool b)        -> PBool b
  | EVar id             -> PVar id
  | EBinop (op, l, r)   -> PBinop (op, expr_to_pred_simple l, expr_to_pred_simple r)
  | EUnop (op, e)       -> PUnop (op, expr_to_pred_simple e)
  | EBlock (_, Some ret) ->
      (* For block bodies: just use the trailing expression.
         Let-binding values are in the proof env, not inlined here. *)
      expr_to_pred_simple ret
  | EIf (cond, then_, Some else_) ->
      PIte (expr_to_pred_simple cond,
            expr_to_pred_simple then_,
            expr_to_pred_simple else_)
  | EBlock (stmts, None) ->
      (* last SReturn in stmts, if any *)
      let rec last_return = function
        | [] -> PVar { name = "__expr"; loc = e.expr_loc }
        | [{ stmt_desc = SReturn (Some r); _ }] -> expr_to_pred_simple r
        | _ :: rest -> last_return rest
      in
      last_return stmts
  | EField (obj, field) -> PField (expr_to_pred_simple obj, field.name)
  (* Dereference is identity in the proof model (value-based SMT encoding) *)
  | EDeref e  -> expr_to_pred_simple e
  | ERef e    -> expr_to_pred_simple e
  | ERefMut e -> expr_to_pred_simple e
  | EStruct (name, inits) ->
      PStruct (name.name,
        List.map (fun (fid, fe) -> (fid.name, expr_to_pred_simple fe)) inits)
  | EIndex (arr, idx)   -> PIndex (expr_to_pred_simple arr, expr_to_pred_simple idx)
  (* Cast: in Int mode the value is unchanged (no truncation assumed); use inner pred *)
  | ECast (inner, _)    -> expr_to_pred_simple inner
  | ESync               -> PTrue   (* syncthreads is a side effect, no pred value *)
  | EMatch (scrut, arms) ->
      (* Build a PIte chain so postconditions on match-returning functions
         can be checked by Z3.
         For binding patterns (PBind id, PAs _ id) substitute the bound
         variable with scrut_pred in the arm body pred, so e.g.
           match x { 0 as z => z, _ => x }
         becomes  PIte(x==0, x, x)  which Z3 proves equal to x.
         PCtor field vars are left unsubstituted (insufficient info here). *)
      let scrut_pred = expr_to_pred_simple scrut in
      let rec make_ite = function
        | [] -> PVar { name = "__expr"; loc = e.expr_loc }
        | arm :: rest ->
            let cond = pattern_to_cond_pred scrut_pred arm.pattern in
            let raw  = expr_to_pred_simple arm.body in
            (* If the body is just the bound variable itself, replace it with
               scrut_pred.  This handles the common  0 as z => z  idiom.
               Full substitution (for e.g. z + 1) requires subst_pred which
               is defined later; that case falls back to the raw pred. *)
            let body_pred = match arm.pattern with
              | PBind id | PAs (_, id) ->
                  (match arm.body.expr_desc with
                   | EVar v when v.name = id.name -> scrut_pred
                   | _ -> raw)
              | _ -> raw
            in
            (match cond with
             | PBool true -> body_pred   (* wildcard / default — terminates chain *)
             | _          -> PIte (cond, body_pred, make_ite rest))
      in
      make_ite arms
  (* Tuple construction: (e1, e2) → PStruct("__tuple", [("_0", p1), ("_1", p2)])
     This allows PField(PResult, "_0") postconditions to reduce correctly via subst_pred. *)
  | ETuple elems ->
      let fields = List.mapi (fun i e ->
        ("_" ^ string_of_int i, expr_to_pred_simple e)
      ) elems in
      PStruct ("__tuple", fields)
  | EField_n (tup, idx) ->
      let tp = expr_to_pred_simple tup in
      (match tp with
       | PStruct (_, fields) ->
           let key = "_" ^ string_of_int idx in
           (match List.assoc_opt key fields with
            | Some p -> p
            | None   -> PField (tp, key))
       | _ -> PField (tp, "_" ^ string_of_int idx))
  | _                   -> PVar { name = "__expr"; loc = e.expr_loc }

(* Substitute type variables in a type *)
let rec subst_ty (s : (string * ty) list) = function
  | TNamed (id, []) when List.mem_assoc id.name s -> List.assoc id.name s
  | TNamed (id, args) -> TNamed (id, List.map (subst_ty s) args)
  | TSpan t     -> TSpan (subst_ty s t)
  | TRef t      -> TRef (subst_ty s t)
  | TRefMut t   -> TRefMut (subst_ty s t)
  | TOwn t      -> TOwn (subst_ty s t)
  | TRaw t      -> TRaw (subst_ty s t)
  | TArray (t, e) -> TArray (subst_ty s t, e)
  | TSlice t    -> TSlice (subst_ty s t)
  | TSecret t   -> TSecret (subst_ty s t)
  | TTuple tys  -> TTuple (List.map (subst_ty s) tys)
  | other       -> other

(* Infer type parameter substitutions by matching template param types against
   actual arg types.  Collects {name → concrete_ty} for each type variable. *)
let infer_type_params (type_params : string list) (param_tys : ty list)
    (arg_tys : ty list) : (string * ty) list =
  let subst = ref [] in
  let rec match_ tmpl act =
    match tmpl with
    | TNamed (id, []) when List.mem id.name type_params ->
        (* Only bind if not already inferred (first arg wins) *)
        if not (List.mem_assoc id.name !subst) then
          subst := (id.name, act) :: !subst
    | TNamed (id1, args1) ->
        (match act with
         | TNamed (id2, args2) when id1.name = id2.name ->
             List.iter2 match_ args1 args2
         | _ -> ())
    | TSpan t1 -> (match act with TSpan t2 -> match_ t1 t2 | _ -> ())
    | TRef t1  -> (match act with TRef t2  -> match_ t1 t2 | _ -> ())
    | TRefMut t1 -> (match act with TRefMut t2 -> match_ t1 t2 | _ -> ())
    | _ -> ()
  in
  List.iter2 match_ param_tys arg_tys;
  !subst

(* Substitute variables in a pred *)
let rec subst_pred (subst : (string * pred) list) pred =
  match pred with
  | PResult ->
      (match List.assoc_opt "result" subst with
       | Some p -> p
       | None   -> pred)
  | PVar id ->
      (match List.assoc_opt id.name subst with
       | Some p -> p
       | None   -> pred)
  | PBinop (op, l, r) -> PBinop (op, subst_pred subst l, subst_pred subst r)
  | PUnop (op, p)     -> PUnop (op, subst_pred subst p)
  | PForall (x, t, p) -> PForall (x, t, subst_pred (List.remove_assoc x.name subst) p)
  | PExists (x, t, p) -> PExists (x, t, subst_pred (List.remove_assoc x.name subst) p)
  | PIte (c, t, e)    -> PIte (subst_pred subst c, subst_pred subst t, subst_pred subst e)
  | POld p            -> POld (subst_pred subst p)
  | PApp (f, args)    -> PApp (f, List.map (subst_pred subst) args)
  | PLex ps           -> PLex (List.map (subst_pred subst) ps)
  | PField (p, f) ->
      let p' = subst_pred subst p in
      (* Eagerly reduce field access *)
      let reduce_field_on inner =
        match inner with
        | PStruct (_, fields) ->
            (match List.assoc_opt f fields with
             | Some v -> v
             | None   -> PField (inner, f))
        | _ -> PField (inner, f)
      in
      (match p' with
       | PStruct _ -> reduce_field_on p'
       (* Distribute field access over if-then-else: (if c then a else b).f
          becomes (if c then a.f else b.f) — reduces further if branches are structs *)
       | PIte (c, t, e) -> PIte (c, reduce_field_on t, reduce_field_on e)
       | _ -> PField (p', f))
  | PStruct (name, fields) ->
      PStruct (name, List.map (fun (f, p) -> (f, subst_pred subst p)) fields)
  | PIndex (arr, idx) -> PIndex (subst_pred subst arr, subst_pred subst idx)
  | _                 -> pred

(* Resolve old(e) expressions in a callee postcondition being injected
   into the caller context. For each old(field_access), look up the
   current known value of that field in the caller's assumption list
   and substitute it. This enables count == old(count) + 1 to become
   count == 0 + 1 (when count was 0 at the call site).

   Operates on the substituted postcondition (after arg_subst). *)
let resolve_old_for_injection env pred =
  (* Structural equality on pred (for matching field targets) *)
  let rec pred_eq a b = match a, b with
    | PVar ia, PVar ib -> ia.name = ib.name
    | PField (pa, fa), PField (pb, fb) -> fa = fb && pred_eq pa pb
    | PResult, PResult -> true
    | _ -> false
  in
  (* Look up the most recent equality fact for a pred expression *)
  let lookup_value target =
    List.find_map (fun p ->
      match p with
      | PBinop (Eq, lhs, rhs) when pred_eq lhs target -> Some rhs
      | PBinop (Eq, lhs, rhs) when pred_eq rhs target -> Some lhs
      | _ -> None
    ) env.proof_ctx.pc_assumes
  in
  let rec go p = match p with
    | POld inner ->
        (match lookup_value inner with
         | Some v -> v
         | None   -> p)
    | PBinop (op, l, r) -> PBinop (op, go l, go r)
    | PUnop (op, q)     -> PUnop (op, go q)
    | PIte (c, t, e)    -> PIte (go c, go t, go e)
    | PApp (f, args)    -> PApp (f, List.map go args)
    | PLex ps           -> PLex (List.map go ps)
    | PField (q, f)     -> PField (go q, f)
    | PIndex (q, i)     -> PIndex (go q, go i)
    | PForall (x, t, q) -> PForall (x, t, go q)
    | PExists (x, t, q) -> PExists (x, t, go q)
    | _                 -> p
  in
  go pred

(* ------------------------------------------------------------------ *)
(* Post-expression environment — for postcondition checking            *)
(*                                                                      *)
(* Mirror check_stmt/check_stmts without generating proof obligations. *)
(* Called in check_fn AFTER check_expr to get post-body facts so       *)
(* postconditions can be checked against post-loop state.               *)
(* ------------------------------------------------------------------ *)

(* Collect all directly-assigned variable names in a stmt list.
   Used to strip stale pre-loop facts from post-loop env.
   Scans inside EIf bodies so that vars assigned in conditional
   branches are also stripped (preventing stale ITE facts). *)
let rec collect_assigned_vars stmts =
  List.concat_map (fun s -> match s.stmt_desc with
    | SExpr { expr_desc = EAssign ({ expr_desc = EVar v; _ }, _); _ } -> [v.name]
    (* Array element write s[i] = v — mark the array variable s as modified *)
    | SExpr { expr_desc = EAssign ({ expr_desc = EIndex ({ expr_desc = EVar arr_id; _ }, _); _ }, _); _ } ->
        [arr_id.name]
    | SGhostAssign (name, _) -> [name.name]  (* ghost updates modify ghost proof state *)
    | SExpr e -> collect_expr_mod_vars e
    | SWhile (_, _, _, body) | SFor (_, _, _, _, body) ->
        collect_assigned_vars body
    | _ -> []) stmts

and collect_expr_mod_vars expr =
  match expr.expr_desc with
  | EIf (_, then_, else_opt) ->
      collect_block_mod_vars then_ @
      (match else_opt with Some e -> collect_block_mod_vars e | None -> [])
  | _ -> []

and collect_block_mod_vars expr =
  match expr.expr_desc with
  | EBlock (stmts, _) -> collect_assigned_vars stmts
  | _ -> []

(* Strip facts whose only variable is in the 'modified' set.
   Removes stale pre-loop equalities like x == 0 when x is a loop variable. *)
let strip_stale_facts env modified =
  let clean assumes =
    List.filter (fun p ->
      match p with
      | PBinop (Eq, PVar id, _) | PBinop (Eq, _, PVar id) ->
          not (List.mem id.name modified)
      | _ -> true
    ) assumes
  in
  { env with proof_ctx = { env.proof_ctx with
      pc_assumes = clean env.proof_ctx.pc_assumes } }

(* Extract simple (var_id, rhs_pred) assignments from a block expression.
   Only handles EVar = expr; ignores index writes, nested ifs, etc.
   Used for ITE modeling of if-statement branches. *)
let extract_block_var_assigns expr =
  match expr.expr_desc with
  | EBlock (stmts, _) ->
      List.filter_map (fun s -> match s.stmt_desc with
        | SExpr { expr_desc = EAssign ({ expr_desc = EVar v; _ }, rhs); _ } ->
            Some (v, expr_to_pred_simple rhs)
        | SGhostAssign (v, rhs) ->
            (* Mutable ghost updates participate in ITE modeling just like runtime assigns *)
            Some (v, expr_to_pred_simple rhs)
        | _ -> None
      ) stmts
  | _ -> []

(* Extract array element writes (arr_id, idx_pred, rhs_pred) from a block.
   Handles SExpr(EAssign(EIndex(EVar arr_id, idx), rhs)).
   Let-bindings inside the block are collected first so their values can be
   substituted into subsequent write expressions (enabling `let tmp=s[i]; s[j]=tmp`). *)
let rec extract_block_arr_assigns expr =
  match expr.expr_desc with
  | EBlock (stmts, _) ->
      (* First pass: collect let-binding substitutions so we can inline
         tmp variables defined within the same if-block. *)
      let let_subst = List.filter_map (fun s -> match s.stmt_desc with
        | SLet (v, _, rhs, _) | SGhost (v, _, rhs) -> Some (v.name, expr_to_pred_simple rhs)
        | _ -> None
      ) stmts in
      let rec apply_subst p = match p with
        | PVar id -> (match List.assoc_opt id.name let_subst with
            | Some p2 -> p2 | None -> p)
        | PBinop (op, l, r) -> PBinop (op, apply_subst l, apply_subst r)
        | PUnop (op, q)     -> PUnop (op, apply_subst q)
        | PIte (c, t, e)    -> PIte (apply_subst c, apply_subst t, apply_subst e)
        | PIndex (a, i)     -> PIndex (apply_subst a, apply_subst i)
        | PField (q, f)     -> PField (apply_subst q, f)
        | _                 -> p
      in
      (* Second pass: collect array writes, substituting let-bound vars.
         Also handles SExpr(EIf(...)) by recursively extracting from
         both branches and wrapping in PIte — this enables swap patterns
         inside conditional blocks (e.g. if s[0] > s[1] { swap }). *)
      List.concat_map (fun s -> match s.stmt_desc with
        | SExpr { expr_desc = EAssign (
            { expr_desc = EIndex ({ expr_desc = EVar arr_id; _ }, idx_expr); _ },
            rhs_expr); _ } ->
            [(arr_id,
              apply_subst (expr_to_pred_simple idx_expr),
              apply_subst (expr_to_pred_simple rhs_expr))]
        | SExpr { expr_desc = EIf (cond, then_, else_opt); _ } ->
            let cond_pred = apply_subst (expr_to_pred_simple cond) in
            let then_arr = extract_block_arr_assigns then_ in
            let else_arr = match else_opt with
              | Some el -> extract_block_arr_assigns el | None -> [] in
            let same_key (a1, i1, _) (a2, i2, _) =
              a1.name = a2.name && i1 = i2 in
            let then_keys = List.map (fun (a, i, _) -> (a, i)) then_arr in
            List.map (fun (arr_id, idx_p, v_then) ->
              let v_else = match List.find_opt
                (fun x -> same_key (arr_id, idx_p, v_then) x) else_arr with
                | Some (_, _, v) -> v
                | None -> PIndex (PVar arr_id, idx_p) in
              (arr_id, idx_p, PIte (cond_pred, v_then, v_else))
            ) then_arr @
            List.filter_map (fun (arr_id, idx_p, v_else) ->
              if List.exists (fun (a2, i2) ->
                a2.name = arr_id.name && i2 = idx_p) then_keys
              then None
              else Some (arr_id, idx_p,
                PIte (cond_pred, PIndex (PVar arr_id, idx_p), v_else))
            ) else_arr
        | _ -> []
      ) stmts
  | _ -> []

(* Apply conditional array writes as ITE store operations.
   For each arr[idx] = v_then in the then-branch:
     if arr[idx] = v_else in the else-branch: write PIte(cond, v_then, v_else)
     if no else write:                        write PIte(cond, v_then, arr_old[idx])
   For each arr[idx] = v_else in the else-branch (then-branch absent):
                                              write PIte(cond, arr_old[idx], v_else)
   Calls env_array_write which renames arr → __arr_pN and adds write + frame facts. *)
let apply_if_arr_assigns env cond_pred then_arr_assigns else_arr_assigns =
  let same_arr_idx (a1, i1, _) (a2, i2, _) = a1.name = a2.name && i1 = i2 in
  let then_keys = List.map (fun (a, i, _) -> (a, i)) then_arr_assigns in
  let ordered =
    List.filter_map (fun (arr_id, idx_p, v_then) ->
      let v_else = match List.find_opt (fun x -> same_arr_idx (arr_id, idx_p, v_then) x) else_arr_assigns with
        | Some (_, _, v) -> v
        | None -> PIndex (PVar arr_id, idx_p)
      in
      Some (arr_id, idx_p, PIte (cond_pred, v_then, v_else))
    ) then_arr_assigns @
    List.filter_map (fun (arr_id, idx_p, v_else) ->
      if List.exists (fun (a2, i2) -> a2.name = arr_id.name && i2 = idx_p) then_keys then None
      else Some (arr_id, idx_p, PIte (cond_pred, PIndex (PVar arr_id, idx_p), v_else))
    ) else_arr_assigns
  in
  List.fold_left (fun e (arr_id, idx_p, val_p) ->
    env_array_write e arr_id idx_p val_p
  ) env ordered

(* Recursively collect (var_id, ite_pred) for all vars assigned anywhere in
   an if-else-if chain.  The else_val of each level is the ITE from the
   next level down, giving correct nested PIte structure for chains like
     if c1 { x=v1 } else if c2 { x=v2 } else { x=v3 }
   which maps to  x = PIte(c1, v1, PIte(c2, v2, v3)).
   Falls through to extract_block_var_assigns for any non-EIf expression. *)
let rec collect_chain_var_assigns expr =
  match expr.expr_desc with
  | EIf (cond, then_, else_opt) ->
      let cond_pred = expr_to_pred_simple cond in
      let then_assigns = extract_block_var_assigns then_ in
      let else_assigns = match else_opt with
        | None   -> []
        | Some e -> collect_chain_var_assigns e
      in
      let all_names = List.sort_uniq String.compare
        (List.map (fun (v, _) -> v.name) then_assigns @
         List.map (fun (v, _) -> v.name) else_assigns)
      in
      let find_var_id name =
        match List.find_opt (fun (v, _) -> v.name = name)
                            (then_assigns @ else_assigns) with
        | Some (v, _) -> v
        | None        -> { name; loc = expr.expr_loc }
      in
      List.map (fun vname ->
        let var_id  = find_var_id vname in
        let then_val = match List.find_opt (fun (v,_) -> v.name = vname) then_assigns with
          | Some (_, p) -> p | None -> PVar var_id
        in
        let else_val = match List.find_opt (fun (v,_) -> v.name = vname) else_assigns with
          | Some (_, p) -> p | None -> PVar var_id
        in
        (var_id, PIte (cond_pred, then_val, else_val))
      ) all_names
  | _ -> extract_block_var_assigns expr

(* Recursively collect (arr_id, idx_pred, ite_pred) from an if-else-if chain.
   For each unique (arr, idx) written in any branch, the value becomes a
   nested PIte: PIte(c1, v1, PIte(c2, v2, arr[idx])).
   Falls through to extract_block_arr_assigns for non-EIf expressions. *)
let rec collect_chain_arr_assigns expr =
  match expr.expr_desc with
  | EIf (cond, then_, else_opt) ->
      let cond_pred  = expr_to_pred_simple cond in
      let then_arr   = extract_block_arr_assigns then_ in
      let else_arr   = match else_opt with
        | None   -> []
        | Some e -> collect_chain_arr_assigns e
      in
      let same_key (a1, i1, _) (a2, i2, _) = a1.name = a2.name && i1 = i2 in
      let then_keys  = List.map (fun (a, i, _) -> (a, i)) then_arr in
      List.map (fun (arr_id, idx_p, v_then) ->
        let v_else = match List.find_opt (fun x -> same_key (arr_id, idx_p, v_then) x) else_arr with
          | Some (_, _, v) -> v
          | None -> PIndex (PVar arr_id, idx_p)
        in
        (arr_id, idx_p, PIte (cond_pred, v_then, v_else))
      ) then_arr @
      List.filter_map (fun (arr_id, idx_p, v_else) ->
        if List.exists (fun (a2, i2) -> a2.name = arr_id.name && i2 = idx_p) then_keys then None
        else Some (arr_id, idx_p, PIte (cond_pred, PIndex (PVar arr_id, idx_p), v_else))
      ) else_arr
  | _ -> extract_block_arr_assigns expr

(* Collect the branches of an if-else/elif chain as (guard_pred, stmt list) pairs.
   The guard_pred for branch k is: !cond_0 && !cond_1 && ... && cond_k
   (or PBool true for the final else).

   Used to generate per-branch while_preserved obligations that avoid the
   ITE-in-array-index problem: when a while body is an elif chain, each
   conditional update produces  new_i = ite(c, i+1, i),  which appears as
   a[ite(...)] in any frontier invariant, making Z3's quantifier instantiation
   fail.  By verifying each branch in isolation (branch condition in hypothesis,
   concrete non-ITE index updates), Z3 can prove frontier invariants that the
   ITE-encoded unified approach cannot. *)
let rec collect_elif_branches acc_neg (expr : expr) : (pred * stmt list) list =
  let mk_and a b = PBinop (And, a, b) in
  let mk_not p   = PUnop  (Not, p)   in
  match expr.expr_desc with
  | EIf (cond, then_, else_opt) ->
      let cp = expr_to_pred_simple cond in
      (* guard = !acc_neg[0] && !acc_neg[1] && ... && cp *)
      let guard =
        List.fold_right (fun neg acc -> mk_and (mk_not neg) acc) acc_neg cp
      in
      let stmts = match then_.expr_desc with
        | EBlock (ss, _) -> ss
        | _              -> []
      in
      let rest = match else_opt with
        | None   -> []
        | Some e -> collect_elif_branches (cp :: acc_neg) e
      in
      (guard, stmts) :: rest
  | EBlock (ss, _) ->
      (* Final else block *)
      let guard =
        List.fold_right (fun neg acc -> mk_and (mk_not neg) acc)
          acc_neg (PBool true)
      in
      [(guard, ss)]
  | _ ->
      (* Final else is a single expression — treat as no statements *)
      let guard =
        List.fold_right (fun neg acc -> mk_and (mk_not neg) acc)
          acc_neg (PBool true)
      in
      [(guard, [])]

(* Apply a (var_id, ite_pred) list produced by collect_chain_var_assigns.
   Mirrors the cond-vars-last ordering of apply_if_assigns so that SSA
   renaming of condition variables propagates correctly. *)
let apply_chain_var_assigns env cond_pred chain_assigns =
  let cond_vars  = pred_free_vars cond_pred in
  let in_cond v  = List.mem v.name cond_vars in
  let non_cond, cond_last =
    List.partition (fun (v, _) -> not (in_cond v)) chain_assigns
  in
  List.fold_left (fun e (v_id, val_pred) ->
    env_assign_var e v_id val_pred
  ) env (non_cond @ cond_last)

(* Model `if cond { x = v_then; ... } [else { x = v_else; ... }]` as ITE updates.
   For each var assigned in either branch, adds:
     x = PIte(cond, v_then, v_else)
   where missing-branch vars use the current (pre-if) value: PIte(cond, x, x).
   Assignments are processed in source order so that env_assign_var renames
   are applied correctly (later assignments see already-renamed earlier vars). *)
let apply_if_assigns env cond_pred then_assigns else_assigns =
  (* Build ordered, deduplicated list of (var_id, then_pred, else_pred).
     Source order from then_assigns, then else-only vars at the end. *)
  let then_names = List.map (fun (v, _) -> v.name) then_assigns in
  let ordered = List.filter_map (fun (v, tp) ->
    let ep = match List.find_opt (fun (v2, _) -> v2.name = v.name) else_assigns with
      | Some (_, p) -> p | None -> PVar v
    in
    Some (v, tp, ep)
  ) then_assigns @
  List.filter_map (fun (v, ep) ->
    if List.mem v.name then_names then None
    else Some (v, PVar v, ep)
  ) else_assigns
  in
  (* Variables that appear in cond_pred must be processed LAST.
     When env_assign_var renames a variable, it renames it in all existing
     pc_assumes — so by processing non-cond vars first, their ITE facts land in
     pc_assumes before the cond vars are renamed.  That way the rename for, say,
     cur_max propagates into the already-added gmax ITE, giving the correct
     pre-assign SSA name in gmax's condition. *)
  let cond_vars = pred_free_vars cond_pred in
  let in_cond v_id = List.mem v_id.name cond_vars in
  let not_cond, in_cond_last = List.partition (fun (v, _, _) -> not (in_cond v)) ordered in
  let sorted = not_cond @ in_cond_last in
  List.fold_left (fun e (v_id, then_val, else_val) ->
    env_assign_var e v_id (PIte (cond_pred, then_val, else_val))
  ) env sorted

let rec expr_final_env env expr =
  match expr.expr_desc with
  | EBlock (stmts, trailing) ->
      let env' = stmts_final_env env stmts in
      (match trailing with Some e -> expr_final_env env' e | None -> env')
  | EIf (cond, then_, else_opt) ->
      (* Mirror the SExpr(EIf) ITE-modeling path so that top-level EIf
         function bodies (e.g. sift_down_root's elif chain) capture
         conditional array and scalar mutations into the proof env. *)
      let cond_pred = expr_to_pred_simple cond in
      let is_elif = match else_opt with
        | Some { expr_desc = EIf _; _ } -> true | _ -> false
      in
      let env1 =
        if is_elif then
          let chain = collect_chain_var_assigns expr in
          if chain = [] then env
          else apply_chain_var_assigns env cond_pred chain
        else begin
          let then_assigns = extract_block_var_assigns then_ in
          let else_assigns = match else_opt with
            | Some el -> extract_block_var_assigns el | None -> []
          in
          if then_assigns = [] && else_assigns = [] then env
          else apply_if_assigns env cond_pred then_assigns else_assigns
        end
      in
      let env2 =
        if is_elif then
          let chain_arr = collect_chain_arr_assigns expr in
          List.fold_left (fun env_ (arr_id, idx_p, val_p) ->
            env_array_write env_ arr_id idx_p val_p
          ) env1 chain_arr
        else begin
          let then_arr = extract_block_arr_assigns then_ in
          let else_arr = match else_opt with
            | Some el -> extract_block_arr_assigns el | None -> []
          in
          if then_arr = [] && else_arr = [] then env1
          else apply_if_arr_assigns env1 cond_pred then_arr else_arr
        end
      in
      env2
  | _ -> env

and stmts_final_env env stmts =
  List.fold_left stmt_final_env env stmts

and stmt_final_env env stmt =
  match stmt.stmt_desc with
  | SLet (name, ann, rhs, lin) ->
      let ty = match ann with
        | Some t -> t
        | None   -> (match rhs.expr_ty with Some t -> t | None -> TPrim (TUint U64))
      in
      let env' = env_add_var env name.name ty lin stmt.stmt_loc in
      let env'' = env_add_fact env' (PBinop (Eq, PVar name, expr_to_pred_simple rhs)) in
      (* For struct literals, also add field projection facts *)
      let env''' = match rhs.expr_desc with
       | EStruct (_, fields) ->
           List.fold_left (fun e (fid, fexpr) ->
             env_add_fact e (PBinop (Eq,
               PField (PVar name, fid.name),
               expr_to_pred_simple fexpr))
           ) env'' fields
       | ESubspan (_, lo, hi) ->
           let len_pred = PField (PVar name, "len") in
           let len_eq = PBinop (Eq, len_pred,
             PBinop (Sub, expr_to_pred_simple hi, expr_to_pred_simple lo)) in
           env_add_fact (env_add_fact env'' len_eq) (PBinop (Ge, len_pred, PInt 0L))
       | ECast (inner, _) ->
           (* Widening cast: inject upper-bound fact for the let-bound variable.
              E.g. let x: u64 = some_u8 as u64  →  add fact  x <= 255 *)
           let src_ty = match inner.expr_ty with Some t -> t | None -> TPrim TUnit in
           (match src_ty with
            | TPrim (TUint U8)  ->
                env_add_fact env'' (PBinop (Le, PVar name, PInt 255L))
            | TPrim (TUint U16) ->
                env_add_fact env'' (PBinop (Le, PVar name, PInt 65535L))
            | TPrim (TUint U32) ->
                env_add_fact env'' (PBinop (Le, PVar name, PInt 4294967295L))
            | _ -> env'')
       | EBinop (Mod, _, divisor) ->
           (* x % n  →  result < n  (when n is a positive literal) *)
           (match expr_to_pred_simple divisor with
            | PInt n when n > 0L ->
                env_add_fact env'' (PBinop (Lt, PVar name, PInt n))
            | _ -> env'')
       | EBinop (Div, dividend, divisor) ->
           (* x / n  →  result <= x  (when n >= 1, unsigned division is non-increasing) *)
           (match expr_to_pred_simple divisor with
            | PInt n when n >= 1L ->
                let _ = n in
                env_add_fact env'' (PBinop (Le, PVar name, expr_to_pred_simple dividend))
            | _ -> env'')
       | EBinop (BitAnd, lhs, rhs) ->
           (* x & mask <= mask  and  x & mask <= x  (bitwise AND masks both operands) *)
           let lp = expr_to_pred_simple lhs in
           let rp = expr_to_pred_simple rhs in
           let e1 = env_add_fact env'' (PBinop (Le, PVar name, lp)) in
           env_add_fact e1 (PBinop (Le, PVar name, rp))
       | EBinop (Shr, lhs, shift) ->
           (* x >> n  ≤  x  (right-shift is non-increasing for unsigned) *)
           let _ = shift in
           env_add_fact env'' (PBinop (Le, PVar name, expr_to_pred_simple lhs))
       | _ -> env'' in
      (* For function calls: inject callee postconditions as facts about name.
         E.g. `let x = f(a, b)` where f ensures result < q  →  adds fact x < q.
         This lets downstream postcondition checks on the caller use callee results. *)
      let inject_postconds env_in sig_ all_args =
        if sig_.fs_ensures = [] then env_in
        else if List.length sig_.fs_params <> List.length all_args then env_in
        else begin
          let arg_subst = List.map2 (fun (pid, _) arg ->
            (pid.name, expr_to_pred_simple arg)
          ) sig_.fs_params all_args in
          let result_subst = ("result", PVar name) :: arg_subst in
          List.fold_left (fun e ens ->
            env_add_fact e (subst_pred result_subst ens)
          ) env_in sig_.fs_ensures
        end
      in
      (* Helper: inject postconditions from a fn-pointer variable's fn_ty.ensures *)
      let inject_postconds_fty env_in fty all_args =
        if fty.ensures = [] then env_in
        else if List.length fty.params <> List.length all_args then env_in
        else begin
          let arg_subst = List.map2 (fun (pid, _) arg ->
            (pid.name, expr_to_pred_simple arg)
          ) fty.params all_args in
          let result_subst = ("result", PVar name) :: arg_subst in
          List.fold_left (fun e ens ->
            env_add_fact e (subst_pred result_subst ens)
          ) env_in fty.ensures
        end
      in
      (match rhs.expr_desc with
       | ECall ({ expr_desc = EVar fn_id; _ }, call_args) ->
           (match env_lookup_fn env fn_id.name with
            | Some sig_ -> inject_postconds env''' sig_ call_args
            | None ->
                (* fn_id may be a variable of fn-pointer type with ensures clauses *)
                (match env_lookup_var env fn_id.name with
                 | Some { vi_ty = TFn fty; _ } ->
                     inject_postconds_fty env''' fty call_args
                 | _ -> env'''))
       | ECall ({ expr_desc = EField (obj, method_name); _ }, call_args) ->
           (* Method call: a.method(args) → TypeName__method(a, args) *)
           (* obj.expr_ty is set by the main typecheck pass *)
           let obj_ty = match obj.expr_ty with Some t -> t | None -> TPrim TUnit in
           let type_name = mangle_ty_name (normalize_ty obj_ty) in
           let mangled = type_name ^ "__" ^ method_name.name in
           (* Search inherent impl first, then trait impls *)
           let sig_opt =
             match env_lookup_fn env mangled with
             | Some _ as s -> s
             | None ->
                 let prefix = type_name ^ "__" in
                 let suffix = "__" ^ method_name.name in
                 List.find_map (fun (fname, sig_) ->
                   let pn = String.length prefix in
                   let sn = String.length suffix in
                   let fn = String.length fname in
                   if fn > pn + sn &&
                      String.sub fname 0 pn = prefix &&
                      String.sub fname (fn - sn) sn = suffix
                   then Some sig_
                   else None
                 ) env.fns
           in
           (match sig_opt with
            | Some sig_ ->
                (* Build all_args = receiver :: call_args.
                   Receiver is matched against first param (self / ref<Self>). *)
                let all_args = obj :: call_args in
                inject_postconds env''' sig_ all_args
            | _ -> env''')
       | _ -> env''')
  | SGhost (name, ann, rhs) ->
      (* Ghost variables: add to proof context exactly like SLet, but marked ghost.
         They participate in invariants / postconditions but are erased in codegen. *)
      let ty = match ann with
        | Some t -> t
        | None   -> (match rhs.expr_ty with Some t -> t | None -> TPrim (TUint U64))
      in
      let env' = env_add_var env name.name ty Unr stmt.stmt_loc in
      env_add_fact env' (PBinop (Eq, PVar name, expr_to_pred_simple rhs))
  | SGhostAssign (name, rhs) ->
      env_assign_var env name (expr_to_pred_simple rhs)
  | SExpr e ->
      (match e.expr_desc with
       | EAssign (lhs, rhs) ->
           (match lhs.expr_desc with
            | EVar v ->
                let env' = env_assign_var env v (expr_to_pred_simple rhs) in
                (* Inject callee postconditions for x = f(args) assignments.
                   After SSA rename, v refers to the new value, so substitute
                   "result" with PVar v in the callee's ensures clauses. *)
                (match rhs.expr_desc with
                 | ECall ({ expr_desc = EVar fn_id; _ }, call_args) ->
                     (match env_lookup_fn env fn_id.name with
                      | Some sig_ when sig_.fs_ensures <> [] &&
                          List.length sig_.fs_params = List.length call_args ->
                          let arg_subst = List.map2 (fun (pid, _) arg ->
                            (pid.name, expr_to_pred_simple arg)
                          ) sig_.fs_params call_args in
                          let result_subst = ("result", PVar v) :: arg_subst in
                          List.fold_left (fun e ens ->
                            env_add_fact e (subst_pred result_subst ens)
                          ) env' sig_.fs_ensures
                      | _ -> env')
                 | _ -> env')
            (* Scalar dereference assignment: *v = rhs  →  SSA-update v *)
            | EDeref deref_inner ->
                (match deref_inner.expr_desc with
                 | EVar v -> env_assign_var env v (expr_to_pred_simple rhs)
                 | _      -> env)
            (* Field assignment inside an array element: arr[i].field = rhs.
               Struct-of-arrays encoding: treat as a write to the virtual field array
               arr__field[i] = rhs.  env_array_write creates SSA rename + frame facts
               for the virtual array, which are later resolved by the SMT encoder's
               PField(PIndex(...)) → (select arr__field i) translation. *)
            | EField ({ expr_desc = EIndex ({ expr_desc = EVar arr_id; _ }, idx); _ }, fld) ->
                let idx_pred = expr_to_pred_simple idx in
                let rhs_pred = expr_to_pred_simple rhs in
                let virtual_field_id = { arr_id with name = arr_id.name ^ "__" ^ fld.name } in
                env_array_write env virtual_field_id idx_pred rhs_pred
            (* Field assignment: c.field = rhs, or deref-then-field = rhs *)
            | EField (outer, fld) ->
                let base_pred = match outer.expr_desc with
                  | EDeref inner -> expr_to_pred_simple inner
                  | _            -> expr_to_pred_simple outer
                in
                env_assign_field env base_pred fld.name (expr_to_pred_simple rhs)
            | EIndex ({ expr_desc = EVar arr_id; _ }, idx) ->
                let idx_pred = expr_to_pred_simple idx in
                let rhs_pred = expr_to_pred_simple rhs in
                let env' = env_array_write env arr_id idx_pred rhs_pred in
                (* Inject callee postconditions as facts about rhs_pred when the
                   RHS is a direct function call (s[k] = f(args) pattern).
                   This mirrors the SLet inject_postconds path. *)
                (match rhs.expr_desc with
                 | ECall ({ expr_desc = EVar fn_id; _ }, call_args) ->
                     (match env_lookup_fn env fn_id.name with
                      | Some sig_ when sig_.fs_ensures <> [] &&
                          List.length sig_.fs_params = List.length call_args ->
                          let arg_subst = List.map2 (fun (pid, _) arg ->
                            (pid.name, expr_to_pred_simple arg)
                          ) sig_.fs_params call_args in
                          let result_subst = ("result", rhs_pred) :: arg_subst in
                          List.fold_left (fun e ens ->
                            env_add_fact e (subst_pred result_subst ens)
                          ) env' sig_.fs_ensures
                      | _ -> env')
                 | _ -> env')
            | _      -> expr_final_env env e)
       | EIf (cond, then_, else_opt) ->
           (* Model conditional updates as ITE facts (scalar vars and array elements). *)
           let cond_pred = expr_to_pred_simple cond in
           let is_elif = match else_opt with
             | Some { expr_desc = EIf _; _ } -> true | _ -> false
           in
           let env1 =
             if is_elif then
               let chain = collect_chain_var_assigns e in
               if chain = [] then env
               else apply_chain_var_assigns env cond_pred chain
             else begin
               let then_assigns = extract_block_var_assigns then_ in
               let else_assigns = match else_opt with
                 | Some el -> extract_block_var_assigns el | None -> []
               in
               if then_assigns = [] && else_assigns = [] then env
               else apply_if_assigns env cond_pred then_assigns else_assigns
             end
           in
           let env2 =
             if is_elif then
               let chain_arr = collect_chain_arr_assigns e in
               List.fold_left (fun env_ (arr_id, idx_p, val_p) ->
                 env_array_write env_ arr_id idx_p val_p
               ) env1 chain_arr
             else begin
               let then_arr = extract_block_arr_assigns then_ in
               let else_arr = match else_opt with
                 | Some el -> extract_block_arr_assigns el | None -> []
               in
               if then_arr = [] && else_arr = [] then env1
               else apply_if_arr_assigns env1 cond_pred then_arr else_arr
             end
           in
           env2
       | ECall ({ expr_desc = EVar fn_id; _ }, call_args) ->
           (* Void function call as a statement: inject callee postconditions.
              resolve_old_for_injection substitutes old(x.f) with the current
              value of x.f from the proof context, so postconditions like
              "ensures b.count == old(b.count) + 1" chain correctly. *)
           (match env_lookup_fn env fn_id.name with
            | Some sig_ when sig_.fs_ensures <> [] &&
                List.length sig_.fs_params = List.length call_args ->
                let arg_subst = List.map2 (fun (pid, _) arg ->
                  (pid.name, expr_to_pred_simple arg)
                ) sig_.fs_params call_args in
                List.fold_left (fun e ens ->
                  let subst_ens = subst_pred arg_subst ens in
                  let resolved  = resolve_old_for_injection e subst_ens in
                  env_add_fact e resolved
                ) env sig_.fs_ensures
            | _ -> env)
       | _ -> expr_final_env env e)
  | SWhile (cond, invs, _, body) ->
      (* Strip stale pre-loop value equalities for loop-modified vars *)
      let modified = collect_assigned_vars body in
      let env_clean = strip_stale_facts env modified in
      let cond_pred = expr_to_pred_simple cond in
      let env_exit = env_add_fact env_clean (PUnop (Not, cond_pred)) in
      List.fold_left env_add_fact env_exit invs
  | SFor (name, iter, invs, _, _body) ->
      let elem_ty = match iter.expr_ty with
        | Some (TSpan t)           -> t
        | Some TStr                -> TPrim (TUint U8)
        | Some (TSlice t | TArray (t, _)) -> t
        | Some (TNamed _ as it)    ->
            (match resolve_assoc_ty env it "Item" with
             | Some t -> t | None -> TPrim (TUint U64))
        | _ -> TPrim (TUint U64)
      in
      (* After the loop, i == n (all iterations ran). Substitute n for i in
         invariants so quantified props like (forall k, k < i => P) become
         (forall k, k < n => P) — directly proving the postcondition. *)
      let _ = env_add_var env name.name elem_ty Unr stmt.stmt_loc in
      let n_pred = match iter.expr_desc with
        | ERange (_, hi) -> expr_to_pred_simple hi
        | _ ->
            (match iter.expr_ty with
             | Some _ -> expr_to_pred_simple iter
             | None   -> PVar { name = "__n"; loc = stmt.stmt_loc })
      in
      let final_invs = List.map (fun p ->
        subst_pred [(name.name, n_pred)] p
      ) invs in
      List.fold_left env_add_fact env final_invs
  | SReturn _ | SBreak _ | SContinue -> env

(* Generate division-by-zero obligation *)
let check_division divisor fn_name loc ctx =
  let pred = PBinop (Ne, expr_to_pred_simple divisor, PInt 0L) in
  add_obligation pred (OPrecondition fn_name) loc ctx

(* Generate array bounds obligation *)
let check_bounds arr_expr idx_expr loc ctx =
  let idx_pred = expr_to_pred_simple idx_expr in
  let len_pred = PApp ({ name = "len"; loc }, [expr_to_pred_simple arr_expr]) in
  let pred = PBinop (Lt, idx_pred, len_pred) in
  add_obligation pred (OBoundsCheck "array") loc ctx

(* Check preconditions at a call site *)
let check_preconditions fn_name reqs args params loc ctx =
  let subst = List.combine
    (List.map (fun (id, _) -> id.name) params)
    (List.map expr_to_pred_simple args) in
  List.iter (fun req ->
    let pred = subst_pred subst req in
    add_obligation pred (OPrecondition fn_name) loc ctx
  ) reqs

(* ------------------------------------------------------------------ *)
(* Coalescing analysis                                                  *)
(* ------------------------------------------------------------------ *)

(* Check whether an index is of the form: uniform_base + threadIdx_x
   (or threadIdx_x alone, or uniform_base + threadIdx_x * 1).
   A stride-1 access is coalesced; anything else is a warning.         *)
let rec pred_uses_threadidx = function
  | PVar id when id.name = "threadIdx_x" -> true
  | PBinop (_, l, r) -> pred_uses_threadidx l || pred_uses_threadidx r
  | PUnop (_, p) -> pred_uses_threadidx p
  | _ -> false

let check_coalescing env arr_pred idx_pred loc =
  (* Check if idx_pred (or a variable it refers to through the proof context)
     depends on threadIdx_x.  This handles: let i = base + threadIdx_x; arr[i].
     arr_pred identifies which array has the potentially non-coalesced access. *)
  let reaches_threadidx p =
    (* Direct check *)
    if pred_uses_threadidx p then true
    else
      (* Follow one level of equality facts: if p = PVar v and we know v == e,
         check whether e contains threadIdx_x *)
      match p with
      | PVar id ->
          List.exists (fun fact ->
            match fact with
            | PBinop (Eq, PVar lhs, rhs) when lhs.name = id.name ->
                pred_uses_threadidx rhs
            | PBinop (Eq, lhs, PVar rhs) when rhs.name = id.name ->
                pred_uses_threadidx lhs
            | _ -> false
          ) env.proof_ctx.pc_assumes
      | _ -> false
  in
  if env.coalesced_fn && not (reaches_threadidx idx_pred) then begin
    let arr_str = match arr_pred with
      | PVar id -> Printf.sprintf "'%s'" id.name
      | _       -> "(expression)"
    in
    report_error (TypeError (loc,
      Printf.sprintf "coalesced function: index into array %s does not depend on \
        threadIdx_x — access may not be coalesced" arr_str))
  end

(* ------------------------------------------------------------------ *)
(* Format helpers                                                       *)
(* ------------------------------------------------------------------ *)

let rec format_ty = function
  | TPrim (TUint U8)   -> "u8"   | TPrim (TUint U16)  -> "u16"
  | TPrim (TUint U32)  -> "u32"  | TPrim (TUint U64)  -> "u64"
  | TPrim (TUint U128) -> "u128" | TPrim (TUint USize)-> "usize"
  | TPrim (TInt I8)    -> "i8"   | TPrim (TInt I16)   -> "i16"
  | TPrim (TInt I32)   -> "i32"  | TPrim (TInt I64)   -> "i64"
  | TPrim (TInt I128)  -> "i128" | TPrim (TInt ISize) -> "isize"
  | TPrim (TFloat F32) -> "f32"  | TPrim (TFloat F64) -> "f64"
  | TPrim TBool        -> "bool" | TPrim TUnit        -> "()"
  | TPrim TNever       -> "Never"
  | TRefined (p, id, _) ->
      Printf.sprintf "%s { %s | ... }" (format_ty (TPrim p)) id.name
  | TRef t    -> Printf.sprintf "ref<%s>" (format_ty t)
  | TRefMut t -> Printf.sprintf "refmut<%s>" (format_ty t)
  | TOwn t    -> Printf.sprintf "own<%s>" (format_ty t)
  | TRaw t    -> Printf.sprintf "raw<%s>" (format_ty t)
  | TSlice t  -> Printf.sprintf "[%s]" (format_ty t)
  | TArray (t, _) -> Printf.sprintf "[%s; N]" (format_ty t)
  | TNamed (id, []) -> id.name
  | TNamed (id, args) ->
      Printf.sprintf "%s<%s>" id.name
        (String.concat ", " (List.map format_ty args))
  | TFn _     -> "fn(...)"
  | TDepArr _ -> "(...) -> ..."
  | TSpan t   -> Printf.sprintf "span<%s>" (format_ty t)
  | TShared (t, _) -> Printf.sprintf "shared<%s>" (format_ty t)
  | TQual (Uniform, t) -> Printf.sprintf "uniform %s" (format_ty t)
  | TQual (Varying, t) -> Printf.sprintf "varying %s" (format_ty t)
  | TSecret t          -> Printf.sprintf "secret<%s>" (format_ty t)
  | TTuple tys         -> Printf.sprintf "(%s)" (String.concat ", " (List.map format_ty tys))
  | TStr               -> "str"
  | TAssoc (base, name) -> Printf.sprintf "%s::%s" (format_ty base) name

let format_obligation_kind = function
  | OPrecondition f  -> "precondition of " ^ f
  | OPostcondition f -> "postcondition of " ^ f
  | OBoundsCheck a   -> "bounds check: " ^ a
  | ONoOverflow op   -> "no overflow: " ^ op
  | OTermination f   -> "termination: " ^ f
  | OLinear v        -> "linear: " ^ v
  | OInvariant "assert" -> "assert"
  | OInvariant i     -> "invariant: " ^ i

(* ------------------------------------------------------------------ *)
(* Type checking expressions                                            *)
(* ------------------------------------------------------------------ *)

(* Walk an expression collecting EVar references to names that are neither
   in `param_names` (the lambda's own bindings) nor in `top_level_names`
   (functions / globals / imports — resolvable at C link time), and that
   exist in `outer_var_names` (the enclosing scope's let-bindings).
   Such references would become undefined-symbol errors in the generated C
   after lambda-lifting, since the lifted function has no access to the
   enclosing frame.  Returns (name, location) pairs.

   Tracks nested let-bindings inside `body` by carrying a `bound` set that
   grows as the walk enters scopes that introduce new names. *)
let find_lambda_captures body param_names outer_var_names =
  let captures : (string * loc) list ref = ref [] in
  let already_reported : string list ref = ref [] in
  let report name loc =
    if List.mem name outer_var_names
       && not (List.mem name !already_reported) then begin
      already_reported := name :: !already_reported;
      captures := (name, loc) :: !captures
    end
  in
  let rec walk_expr bound e =
    match e.expr_desc with
    | EVar id ->
        if not (List.mem id.name bound) then report id.name id.loc
    | ELit _ | ESync -> ()
    | EBinop (_, a, b) | EAssign (a, b) | EIndex (a, b) ->
        walk_expr bound a; walk_expr bound b
    | EUnop (_, x) | EField (x, _) | ERef x | ERefMut x | EDeref x
    | EField_n (x, _) | ECast (x, _) ->
        walk_expr bound x
    | ECall (f, xs) ->
        walk_expr bound f; List.iter (walk_expr bound) xs
    | EBlock (stmts, tail) ->
        let bound' = walk_stmts bound stmts in
        (match tail with Some t -> walk_expr bound' t | None -> ())
    | EIf (c, t, e_opt) ->
        walk_expr bound c; walk_expr bound t;
        (match e_opt with Some x -> walk_expr bound x | None -> ())
    | EMatch (scrut, arms) ->
        walk_expr bound scrut;
        List.iter (fun arm ->
          let bound' = pattern_bindings bound arm.pattern in
          walk_expr bound' arm.body) arms
    | EProof _ | ERaw _ | EAssume _ | EAssert _ -> ()
    | ELoop stmts -> let _ = walk_stmts bound stmts in ()
    | EStruct (_, fields) ->
        List.iter (fun (_, v) -> walk_expr bound v) fields
    | EArrayLit xs | ETuple xs ->
        List.iter (walk_expr bound) xs
    | EArrayRepeat (v, n) ->
        walk_expr bound v; walk_expr bound n
    | ESubspan (s, lo, hi) ->
        walk_expr bound s; walk_expr bound lo; walk_expr bound hi
    | ERange (lo, hi) ->
        walk_expr bound lo; walk_expr bound hi
    | ELambda (inner_params, inner_body, _) ->
        (* Nested lambda — its own params shadow outer names in its body. *)
        let bound' = List.fold_left (fun acc (id, _) -> id.name :: acc)
                       bound inner_params in
        walk_expr bound' inner_body
    | EAsm asm ->
        List.iter (fun (_, e) -> walk_expr bound e) asm.asm_inputs
  and walk_stmts bound stmts =
    List.fold_left walk_stmt bound stmts
  and walk_stmt bound stmt =
    match stmt.stmt_desc with
    | SLet (id, _, e, _) | SGhost (id, _, e) ->
        walk_expr bound e; id.name :: bound
    | SGhostAssign (_, e) | SExpr e -> walk_expr bound e; bound
    | SReturn (Some e) -> walk_expr bound e; bound
    | SReturn None -> bound
    | SWhile (c, _, _, body) ->
        walk_expr bound c;
        let _ = walk_stmts bound body in bound
    | SFor (id, iter, _, _, body) ->
        walk_expr bound iter;
        let _ = walk_stmts (id.name :: bound) body in bound
    | SBreak (Some e) -> walk_expr bound e; bound
    | SBreak None | SContinue -> bound
  and pattern_bindings bound p =
    match p with
    | PWild | PLit _ | PLitRange _ -> bound
    | PBind id -> id.name :: bound
    | PCtor (_, ps) | PTuple ps ->
        List.fold_left pattern_bindings bound ps
    | PAs (p, id) -> pattern_bindings (id.name :: bound) p
    | POr (p, _) -> pattern_bindings bound p  (* both sides bind same names *)
  in
  walk_expr param_names body;
  List.rev !captures

let rec check_expr env expr : ty =
  let ty = infer_expr env expr in
  expr.expr_ty <- Some ty;
  ty

and infer_expr env expr : ty =
  match expr.expr_desc with

  (* Literals *)
  | ELit (LInt (_, hint)) ->
      (match hint with
       | Some p -> TPrim p
       | None   -> TPrim (TUint U64))
  | ELit (LFloat (_, hint)) ->
      (match hint with
       | Some w -> TPrim (TFloat w)
       | None   -> TPrim (TFloat F64))
  | ELit (LBool _) -> TPrim TBool
  | ELit LUnit     -> TPrim TUnit
  | ELit (LStr _)  -> TStr

  (* Variables *)
  | EVar id ->
      (match env_lookup_var env id.name with
       | Some vi ->
           (* Mark as used for linearity tracking.
              Lin: exactly once — error on second use.
              Aff: at most once — error on second use.  *)
           if (vi.vi_linearity = Lin || vi.vi_linearity = Aff) && !(vi.vi_used) then
             report_error (LinearityError (id.loc,
               Printf.sprintf "%s variable '%s' used more than once"
                 (if vi.vi_linearity = Lin then "linear" else "affine") id.name));
           vi.vi_used := true;
           vi.vi_ty
       | None ->
           (match env_lookup_fn env id.name with
            | Some sig_ when sig_.fs_params = [] ->
                (* Zero-arg constructor/function: return its type as a value.
                   For generic constructors (e.g. None : Option<T>), try to
                   resolve type params from the expected return type. *)
                if sig_.fs_type_params = [] then sig_.fs_ret
                else
                  (match env.expected_ty with
                   | Some exp_ty ->
                       let type_subst = infer_type_params sig_.fs_type_params
                                          [sig_.fs_ret] [exp_ty] in
                       if type_subst = [] then sig_.fs_ret
                       else subst_ty type_subst sig_.fs_ret
                   | None -> sig_.fs_ret)
            | Some sig_ -> TFn { params   = sig_.fs_params;
                                   ret      = sig_.fs_ret;
                                   requires = sig_.fs_requires;
                                   ensures  = sig_.fs_ensures; }
            | None ->
                fail id.loc (Printf.sprintf "unbound variable '%s'" id.name);
                TPrim (TUint U64)))  (* error recovery type *)

  (* Binary operations — propagate uniform/varying qualifier and secret taint *)
  | EBinop (Div, lhs, rhs) ->
      let lt = check_expr env lhs in
      let rt = check_expr env rhs in
      check_division rhs "__div__" expr.expr_loc env;
      let q = combine_qual (qual_of_ty lt) (qual_of_ty rt) in
      let base = lt in
      let result = if q = Varying then TQual (Varying, strip_qual base) else base in
      if is_secret lt || is_secret rt then TSecret (strip_secret result) else result

  | EBinop (op, lhs, rhs) ->
      let lt = check_expr env lhs in
      (* Short-circuit semantics for && and ==>: when evaluating the RHS, the LHS
         is known to be true (otherwise the operator short-circuits to false/vacuous).
         This lets bounds checks in the RHS use facts established by the LHS.
         Example: `i < na && a[i] <= x` — bounds check on a[i] can use `i < na`. *)
      let env_rhs = match op with
        | And | Implies -> env_add_fact env (expr_to_pred_simple lhs)
        | _             -> env
      in
      let rt = check_expr env_rhs rhs in
      let q = combine_qual (qual_of_ty lt) (qual_of_ty rt) in
      let result_ty = match op with
        | Eq | Ne | Lt | Le | Gt | Ge -> TPrim TBool
        | And | Or | Implies | Iff    -> TPrim TBool
        | _ -> numeric_result_ty (strip_qual (strip_secret lt)) (strip_qual (strip_secret rt))
      in
      let result = if q = Varying then TQual (Varying, result_ty) else result_ty in
      if is_secret lt || is_secret rt then TSecret (strip_secret result) else result

  (* Unary operations — propagate secret taint *)
  | EUnop (Not, e) ->
      let t = check_expr env e in
      if is_secret t then TSecret (TPrim TBool) else TPrim TBool
  | EUnop (Neg, e) ->
      check_expr env e   (* secret propagates: TSecret t → TSecret t *)
  | EUnop (BitNot, e) ->
      check_expr env e   (* secret propagates: TSecret t → TSecret t *)

  (* Array indexing — must prove index in bounds; secret index is a timing channel *)
  | EIndex (arr, idx) ->
      let arr_ty = check_expr env arr in
      let idx_ty = check_expr env idx in
      if is_secret idx_ty then
        fail expr.expr_loc "array index must not be secret (cache timing channel)";
      (match strip_qual arr_ty with
       | TStr ->
           (* str indexing — same as span<u8> *)
           let arr_pred = expr_to_pred_simple arr in
           let idx_pred = expr_to_pred_simple idx in
           let len_pred = PField (arr_pred, "len") in
           add_obligation (PBinop (Lt, idx_pred, len_pred))
             (OBoundsCheck "str") expr.expr_loc env;
           TPrim (TUint U8)
       | TSpan elem ->
           (* Span indexing: generate obligation idx < arr.len *)
           let arr_pred = expr_to_pred_simple arr in
           let idx_pred = expr_to_pred_simple idx in
           let len_pred = PField (arr_pred, "len") in
           add_obligation (PBinop (Lt, idx_pred, len_pred))
             (OBoundsCheck "span") expr.expr_loc env;
           (* Coalescing check: if in a #[coalesced] function, verify stride-1 *)
           (if env.coalesced_fn then
             check_coalescing env arr_pred idx_pred expr.expr_loc);
           elem
       | TShared (elem, len_expr) ->
           (* Shared memory: bounds check (idx < smem_size).
              Ownership is enforced by __syncthreads() placement —
              Forge already verifies syncthreads is not in divergent branches.
              Special case: if the index IS threadIdx_x (or a variable known
              equal to it), skip the bounds check — the 1D access pattern
              smem[threadIdx_x] is the canonical safe shared memory access
              (threadIdx_x < blockDim_x <= smem_size is a launch invariant). *)
           let idx_pred = expr_to_pred_simple idx in
           let is_tid_access = match idx_pred with
             | PVar v when v.name = "threadIdx_x" -> true
             | PVar v ->
                 List.exists (fun p -> match p with
                   | PBinop (Eq, PVar a, PVar b) ->
                       (a.name = v.name && b.name = "threadIdx_x") ||
                       (b.name = v.name && a.name = "threadIdx_x")
                   | _ -> false
                 ) env.proof_ctx.pc_assumes
             | _ -> false
           in
           if not is_tid_access then
             (match len_expr with
              | Some n ->
                  let n_pred = expr_to_pred_simple n in
                  add_obligation (PBinop (Lt, idx_pred, n_pred))
                    (OBoundsCheck "shared") expr.expr_loc env
              | None -> ());
           elem
       | TArray (elem, Some n_expr) ->
           (* Static-size array: generate idx < N directly (Z3 Tier-1 dischargeable) *)
           let idx_pred = expr_to_pred_simple idx in
           let n_pred   = expr_to_pred_simple n_expr in
           add_obligation (PBinop (Lt, idx_pred, n_pred))
             (OBoundsCheck "array") expr.expr_loc env;
           elem
       | TArray (elem, None) -> check_bounds arr idx expr.expr_loc env; elem
       | TSlice elem -> check_bounds arr idx expr.expr_loc env; elem
       | TRef (TArray (elem, Some n_expr)) ->
           let idx_pred = expr_to_pred_simple idx in
           let n_pred   = expr_to_pred_simple n_expr in
           add_obligation (PBinop (Lt, idx_pred, n_pred))
             (OBoundsCheck "array") expr.expr_loc env;
           elem
       | TRef (TArray (elem, None)) -> check_bounds arr idx expr.expr_loc env; elem
       | TRef (TSlice elem) -> check_bounds arr idx expr.expr_loc env; elem
       | TRefMut (TArray (elem, Some n_expr)) ->
           let idx_pred = expr_to_pred_simple idx in
           let n_pred   = expr_to_pred_simple n_expr in
           add_obligation (PBinop (Lt, idx_pred, n_pred))
             (OBoundsCheck "array") expr.expr_loc env;
           elem
       | TRefMut (TArray (elem, None)) -> check_bounds arr idx expr.expr_loc env; elem
       | _ ->
           fail expr.expr_loc "indexing non-array type";
           TPrim (TUint U8))

  (* Field access *)
  | EField (obj, field) ->
      let obj_ty = check_expr env obj in
      check_field_access obj_ty field expr.expr_loc env

  (* Function call *)
  | ECall (f, args) ->
      (* ---- Special intrinsics: or_return / or_fail / declassify ---- *)
      let intrinsic_result = match f.expr_desc with
        (* declassify(x) — explicit secret stripping; required to use secret value
           as an if condition, array index, or return from a non-secret function *)
        | EVar id when id.name = "declassify" ->
            (match args with
             | [arg] ->
                 let arg_ty = check_expr env arg in
                 Some (strip_secret arg_ty)
             | _ ->
                 fail expr.expr_loc "declassify takes exactly one argument";
                 Some (TPrim (TUint U64)))
        | EVar id when id.name = "__or_return__" || id.name = "__or_fail__" ->
            (match args with
             | [value_expr; alt_expr] ->
                 let value_ty = check_expr env value_expr in
                 let _ = check_expr env alt_expr in
                 (* Extract Ok payload type from the enum's first variant *)
                 let ok_ty = match value_ty with
                   | TNamed (enum_id, type_args) ->
                       (match List.assoc_opt enum_id.name env.enums with
                        | Some ed ->
                            (match ed.ed_variants with
                             | (_, payload_fields) :: _ when payload_fields <> [] ->
                                 let type_params = List.map (fun (p,_) -> p.name) ed.ed_params in
                                 let sub = if type_params = [] then []
                                           else List.combine type_params type_args in
                                 let t = List.nth payload_fields 0 in
                                 if sub = [] then t else subst_ty sub t
                             | _ -> TPrim TUnit)
                        | None -> TPrim TUnit)
                   | _ -> TPrim TUnit
                 in
                 Some ok_ty
             | _ -> None)
        (* ---- own<T> heap intrinsics ---- *)
        (* own_alloc(val: T) -> own<T>  — allocates T on heap, linear ownership *)
        | EVar id when id.name = "own_alloc" ->
            (match args with
             | [arg] ->
                 let t = check_expr env arg in
                 Some (TOwn t)
             | _ ->
                 fail expr.expr_loc "own_alloc takes exactly one argument";
                 Some (TOwn (TPrim (TUint U64))))
        (* own_into(p: own<T>) -> T  — destructive read: copies value, frees allocation *)
        | EVar id when id.name = "own_into" ->
            (match args with
             | [arg] ->
                 let t = check_expr env arg in
                 (match t with
                  | TOwn inner -> Some inner
                  | _ ->
                      fail expr.expr_loc "own_into requires an own<T> argument";
                      Some (TPrim (TUint U64)))
             | _ ->
                 fail expr.expr_loc "own_into takes exactly one argument";
                 Some (TPrim (TUint U64)))
        (* own_free(p: own<T>) -> ()  — frees allocation without reading value *)
        | EVar id when id.name = "own_free" ->
            (match args with
             | [arg] ->
                 let t = check_expr env arg in
                 (match t with
                  | TOwn _ -> Some (TPrim TUnit)
                  | _ ->
                      fail expr.expr_loc "own_free requires an own<T> argument";
                      Some (TPrim TUnit))
             | _ ->
                 fail expr.expr_loc "own_free takes exactly one argument";
                 Some (TPrim TUnit))
        (* own_get(p: own<T>) -> (T, own<T>)  — peek: reads value, returns pointer back
           Usage: let (val, p) = own_get(p);  — consumes old p, rebinds fresh p *)
        | EVar id when id.name = "own_get" ->
            (match args with
             | [arg] ->
                 let t = check_expr env arg in
                 (match t with
                  | TOwn inner -> Some (TTuple [inner; TOwn inner])
                  | _ ->
                      fail expr.expr_loc "own_get requires an own<T> argument";
                      Some (TTuple [TPrim (TUint U64); TOwn (TPrim (TUint U64))]))
             | _ ->
                 fail expr.expr_loc "own_get takes exactly one argument";
                 Some (TTuple [TPrim (TUint U64); TOwn (TPrim (TUint U64))]))
        (* own_borrow(p: own<T>) -> (ref<T>, own<T>)
           Affine immutable borrow: returns a const pointer + the original own back.
           The ref<T> binding is Unr (can read multiple times); own<T> must be freed/consumed. *)
        | EVar id when id.name = "own_borrow" ->
            (match args with
             | [arg] ->
                 let t = check_expr env arg in
                 (match t with
                  | TOwn inner -> Some (TTuple [TRef inner; TOwn inner])
                  | _ ->
                      fail expr.expr_loc "own_borrow requires an own<T> argument";
                      Some (TTuple [TRef (TPrim (TUint U64)); TOwn (TPrim (TUint U64))]))
             | _ ->
                 fail expr.expr_loc "own_borrow takes exactly one argument";
                 Some (TTuple [TRef (TPrim (TUint U64)); TOwn (TPrim (TUint U64))]))
        (* own_borrow_mut(p: own<T>) -> (refmut<T>, own<T>)
           Affine mutable borrow: returns a mutable pointer + the original own back.
           The refmut<T> binding is Aff (at-most-once); own<T> must be freed/consumed. *)
        | EVar id when id.name = "own_borrow_mut" ->
            (match args with
             | [arg] ->
                 let t = check_expr env arg in
                 (match t with
                  | TOwn inner -> Some (TTuple [TRefMut inner; TOwn inner])
                  | _ ->
                      fail expr.expr_loc "own_borrow_mut requires an own<T> argument";
                      Some (TTuple [TRefMut (TPrim (TUint U64)); TOwn (TPrim (TUint U64))]))
             | _ ->
                 fail expr.expr_loc "own_borrow_mut takes exactly one argument";
                 Some (TTuple [TRefMut (TPrim (TUint U64)); TOwn (TPrim (TUint U64))]))
        (* ---- Method call dispatch: obj.method(args) → TypeName__method(obj,args) ---- *)
        | EField (obj, method_name) ->
            let obj_ty = check_expr env obj in
            let norm_obj_ty = normalize_ty obj_ty in
            let type_name = mangle_ty_name norm_obj_ty in
            let mangled = type_name ^ "__" ^ method_name.name in
            (* Also search for TypeName__Trait__method when no inherent method found *)
            let mangled_sig =
              match env_lookup_fn env mangled with
              | Some _ as s -> s
              | None ->
                  (* Search env.fns for TypeName__*__method pattern *)
                  let prefix = type_name ^ "__" in
                  let suffix = "__" ^ method_name.name in
                  List.find_map (fun (fname, sig_) ->
                    let pn = String.length prefix in
                    let sn = String.length suffix in
                    let fn = String.length fname in
                    if fn > pn + sn &&
                       String.sub fname 0 pn = prefix &&
                       String.sub fname (fn - sn) sn = suffix
                    then Some sig_
                    else None
                  ) env.fns
            in
            (match mangled_sig with
             | Some sig_ ->
                 (* Auto-ref the receiver if the first param expects ref<T> or refmut<T> *)
                 let receiver = match sig_.fs_params with
                   | (_, TRef _) :: _ ->
                       { obj with expr_desc = ERef obj;
                                  expr_ty   = Some (TRef obj_ty) }
                   | (_, TRefMut _) :: _ ->
                       { obj with expr_desc = ERefMut obj;
                                  expr_ty   = Some (TRefMut obj_ty) }
                   | _ -> obj
                 in
                 let all_args = receiver :: args in
                 if List.length sig_.fs_params <> List.length all_args then
                   report_error (ArityMismatch (expr.expr_loc, "method",
                     List.length sig_.fs_params, List.length all_args));
                 List.iter2 (fun (_, pty) aexpr ->
                   let aty = check_expr env aexpr in
                   if not (ty_compatible pty aty) then
                     fail expr.expr_loc "method argument type mismatch"
                 ) sig_.fs_params all_args;
                 Some sig_.fs_ret
             | None -> None)
        | _ -> None
      in
      (match intrinsic_result with
       | Some ty -> ty
       | None ->
      let f_ty = check_expr env f in
      (* Look up fn_sig if f is a named function (for type param info) *)
      let sig_opt = match f.expr_desc with
        | EVar id -> env_lookup_fn env id.name
        | _ -> None
      in
      (match f_ty with
       | TFn fty ->
           (* Check arg count *)
           if List.length fty.params <> List.length args then
             report_error (ArityMismatch (expr.expr_loc,
               "function", List.length fty.params, List.length args));
           (* Type-check arguments and infer generic type params if needed *)
           let arg_tys = List.map (check_expr env) args in
           let type_subst = match sig_opt with
             | Some sig_ when sig_.fs_type_params <> [] ->
                 infer_type_params sig_.fs_type_params
                   (List.map snd fty.params) arg_tys
             | _ -> []
           in
           (* Check arg compatibility against (potentially substituted) param types *)
           List.iter2 (fun (_, param_ty) arg_ty ->
             let concrete_param = if type_subst = [] then param_ty
                                  else subst_ty type_subst param_ty in
             if not (ty_compatible concrete_param arg_ty) then
               fail expr.expr_loc
                 (Printf.sprintf "argument type mismatch: expected %s"
                   (format_ty concrete_param))
           ) fty.params arg_tys;
           (* Check generic bounds: for each KBounded generic, verify the concrete type satisfies it *)
           (match sig_opt with
            | Some sig_ when sig_.fs_generics <> [] ->
                List.iter (fun (param_name, k) ->
                  match k with
                  | KBounded bounds ->
                      (* Find what concrete type was substituted for this param *)
                      let concrete_ty_opt = List.assoc_opt param_name type_subst in
                      (match concrete_ty_opt with
                       | None -> ()
                       | Some concrete_ty ->
                           let ty_nm = match concrete_ty with
                             | TNamed (id, _) -> id.name | _ -> "" in
                           if ty_nm <> "" then
                             List.iter (fun bound_id ->
                               if not (env_has_impl env ty_nm bound_id.name) then
                                 fail expr.expr_loc
                                   (Printf.sprintf "type '%s' does not implement trait '%s' \
                                     (required by generic bound on '%s')"
                                     ty_nm bound_id.name param_name)
                             ) bounds)
                  | _ -> ()
                ) sig_.fs_generics
            | _ -> ());
           (* Check fn-pointer contract compliance:
              When a named function is passed as an argument to a param of type
              fn(T)->U ensures pred, verify the named function's postconditions
              imply the required pred.  E.g. passing clamp255 where
              fn(u64)->u64 ensures result<=255u64 is expected generates an
              obligation: given clamp255's ensures, prove result<=255.
              PResult is substituted to PVar "__fnret" to make it a real SMT variable. *)
           List.iter2 (fun (_, param_ty) arg ->
             let concrete_param = if type_subst = [] then param_ty
                                  else subst_ty type_subst param_ty in
             (match concrete_param, arg.expr_desc with
              | TFn fty_param, EVar fn_id when fty_param.ensures <> [] ->
                  (match env_lookup_fn env fn_id.name with
                   | Some sig_ ->
                       let ret_nm = "__fnret" in
                       let ret_pred = PVar { name = ret_nm; loc = arg.expr_loc } in
                       let result_subst = [("result", ret_pred)] in
                       let check_env =
                         let e = env_add_var env ret_nm sig_.fs_ret Unr arg.expr_loc in
                         List.fold_left (fun e ens ->
                           env_add_fact e (subst_pred result_subst ens)
                         ) e sig_.fs_ensures
                       in
                       List.iter (fun req_ens ->
                         let req_ens' = subst_pred result_subst req_ens in
                         add_obligation req_ens'
                           (OPrecondition ("fn contract for " ^ fn_id.name))
                           arg.expr_loc check_env
                       ) fty_param.ensures
                   | None -> ())
              | _ -> ())
           ) fty.params args;
           (* Generate precondition obligations *)
           check_preconditions "fn" fty.requires args fty.params
             expr.expr_loc env;
           (* Termination: at a recursive self-call, prove D[params:=args] < D *)
           (match f.expr_desc with
            | EVar id ->
                (match env.current_fn with
                 | Some sig_ when sig_.fs_name = id.name ->
                     (match sig_.fs_decreases with
                      | None ->
                          fail expr.expr_loc
                            (Printf.sprintf
                              "recursive call to '%s' requires a 'decreases:' clause"
                              id.name)
                      | Some measure ->
                          let subst = List.combine
                            (List.map (fun (p, _) -> p.name) sig_.fs_params)
                            (List.map expr_to_pred_simple args) in
                          let measure_at_call = subst_pred subst measure in
                          let decrease_ob = match measure with
                            | PLex ms ->
                                let ms_at_call = match measure_at_call with
                                  | PLex ps -> ps | p -> [p]
                                in
                                let rec lex_lt ns os = match ns, os with
                                  | [], _ | _, [] -> PFalse
                                  | [n], [o]      -> PBinop (Lt, n, o)
                                  | n :: ns', o :: os' ->
                                      PBinop (Or,
                                        PBinop (Lt, n, o),
                                        PBinop (And, PBinop (Eq, n, o),
                                                     lex_lt ns' os'))
                                in
                                lex_lt ms_at_call ms
                            | _ ->
                                PBinop (Lt, measure_at_call, measure)
                          in
                          add_obligation decrease_ob (OTermination id.name)
                            expr.expr_loc env)
                 | _ -> ())
            | _ -> ());
           (* Return concrete type: apply type-param substitution to declared ret.
              If some type params were not inferrable from args alone, try to fill
              them in from the expected return type (e.g. Ok(x) in Result<T,E>
              where E can't be inferred from x). *)
           let partial_ret = if type_subst = [] then fty.ret
                             else subst_ty type_subst fty.ret in
           (match sig_opt with
            | Some sig_ when sig_.fs_type_params <> [] ->
                (match env.expected_ty with
                 | Some exp_ty ->
                     let extra = infer_type_params sig_.fs_type_params
                                   [partial_ret] [exp_ty] in
                     if extra = [] then partial_ret
                     else subst_ty extra partial_ret
                 | None -> partial_ret)
            | _ -> partial_ret)
       | TDepArr (param_id, dom_ty, cod_ty) ->
           (* Dependent function type call: (x: dom) -> cod applied to one argument. *)
           (match args with
            | [arg] ->
                let arg_ty = check_expr env arg in
                if not (ty_compatible dom_ty arg_ty) then
                  fail expr.expr_loc
                    (Printf.sprintf "argument type mismatch: expected %s"
                      (format_ty dom_ty));
                (* Substitute the argument value into the codomain type.
                   Full dependent substitution is left as future work;
                   the unsubstituted codomain is returned as an approximation. *)
                ignore param_id;
                cod_ty
            | _ ->
                report_error (ArityMismatch (expr.expr_loc, "dependent function", 1,
                  List.length args));
                cod_ty)
       | _ ->
           (* EVar lookup returns sig_.fs_ret directly for zero-param functions.
              If sig_opt has the signature, use it to dispatch the call. *)
           (match sig_opt with
            | Some sig_ ->
                if List.length sig_.fs_params <> List.length args then
                  report_error (ArityMismatch (expr.expr_loc,
                    "function", List.length sig_.fs_params, List.length args));
                List.iter (fun a -> check_expr env a |> ignore) args;
                check_preconditions "fn" sig_.fs_requires args sig_.fs_params
                  expr.expr_loc env;
                sig_.fs_ret
            | None ->
                fail expr.expr_loc "calling non-function";
                TPrim TUnit)))

  (* Assignment — returns unit *)
  | EAssign (lhs, rhs) ->
      let lt = check_expr env lhs in
      let rt = check_expr env rhs in
      if not (ty_eq (base_ty lt) (base_ty rt)) then
        fail expr.expr_loc "assignment type mismatch";
      TPrim TUnit

  (* References *)
  | ERef e ->
      let t = check_expr env e in
      TRef t
  | ERefMut e ->
      let t = check_expr env e in
      TRefMut t
  | EDeref e ->
      (match check_expr env e with
       | TRef t | TRefMut t | TRaw t | TOwn t -> t
       | _ ->
           fail expr.expr_loc "dereferencing non-pointer";
           TPrim TUnit)

  (* Cast *)
  | ECast (e, target_ty) ->
      let _ = check_expr env e in
      target_ty

  (* Block *)
  | EBlock (stmts, ret) ->
      (* Process stmts WITHOUT the must-use check — we'll do it after the
         trailing expression so that Lin vars can be consumed there. *)
      let env' = List.fold_left check_stmt env stmts in
      let ret_ty = match ret with
        | Some e -> check_expr env' e
        | None   -> TPrim TUnit
      in
      (* Must-use check: fires after the trailing expression has had a chance
         to consume linear vars (vi_used refs are updated in place by check_expr). *)
      check_lin_vars env env';
      ret_ty

  (* If expression — secret condition is a timing channel *)
  | EIf (cond, then_, else_) ->
      let cond_ty = check_expr env cond in
      if is_secret cond_ty then
        fail expr.expr_loc "if condition must not be secret (control-flow timing channel)";
      if not (is_bool (strip_secret cond_ty)) then
        fail expr.expr_loc "if condition must be bool";
      let cond_pred = expr_to_pred_simple cond in
      (* If condition is varying (per-thread), branches are divergent:
         __syncthreads() becomes UB inside them. *)
      let is_varying_cond = qual_of_ty cond_ty = Varying in
      (* Add branch condition to proof context for each branch *)
      let env_then = env_add_fact env cond_pred in
      let env_else = env_add_fact env (PUnop (Not, cond_pred)) in
      let env_then =
        if is_varying_cond then { env_then with in_varying_branch = true }
        else env_then
      in
      let env_else =
        if is_varying_cond then { env_else with in_varying_branch = true }
        else env_else
      in
      let then_ty = check_expr env_then then_ in
      (match else_ with
       | None -> TPrim TUnit
       | Some else_e ->
           let else_ty = check_expr env_else else_e in
           if not (ty_compatible then_ty else_ty) then
             fail expr.expr_loc "if branches must have same type";
           ty_unify then_ty else_ty)

  (* Match *)
  | EMatch (scrut, arms) ->
      let scrut_ty = check_expr env scrut in
      let scrut_pred = expr_to_pred_simple scrut in
      let arm_tys = List.map (fun arm ->
        let env'  = bind_pattern_vars env scrut_ty arm.pattern in
        (* Inject pattern path conditions into the arm's proof context *)
        let facts = pattern_to_path_facts env scrut_pred arm.pattern in
        let env'' = List.fold_left env_add_fact env' facts in
        (* Also inject arm guard if present *)
        let env''' = match arm.guard with
          | Some g -> env_add_fact env'' g | None -> env''
        in
        check_expr env''' arm.body
      ) arms in
      (match arm_tys with
       | []     -> TPrim TNever
       | t :: _ -> t)

  (* Proof block — type Unit, side effect is obligation generation *)
  | EProof pb ->
      check_proof_block env pb;
      TPrim TUnit

  (* Raw block — no type checking inside, trust the programmer *)
  | ERaw rb ->
      let _ = check_stmts env rb.rb_stmts in
      TPrim TUnit

  (* Struct literal — struct TypeName { field: val, ... } *)
  | EStruct (name, field_inits) ->
      (match List.assoc_opt name.name env.structs with
       | None ->
           fail expr.expr_loc
             (Printf.sprintf "unknown struct type '%s'" name.name);
           TPrim TUnit
       | Some sd ->
           (* Check each field value type *)
           List.iter (fun (fname, fexpr) ->
             match List.assoc_opt fname.name
                     (List.map (fun (id, ty) -> (id.name, ty)) sd.sd_fields) with
             | None ->
                 fail expr.expr_loc
                   (Printf.sprintf "no field '%s' on struct '%s'"
                     fname.name name.name)
             | Some expected_ty ->
                 let actual_ty = check_expr env fexpr in
                 if not (ty_compatible actual_ty expected_ty) then
                   fail expr.expr_loc
                     (Printf.sprintf "field '%s': expected %s, got %s"
                       fname.name (format_ty expected_ty) (format_ty actual_ty))
           ) field_inits;
           (* Check struct invariants at construction site *)
           let field_subst = List.map (fun (fname, fexpr) ->
             (fname.name, expr_to_pred_simple fexpr)
           ) field_inits in
           List.iter (fun inv ->
             let ob_pred = subst_pred field_subst inv in
             add_obligation ob_pred (OInvariant ("struct:" ^ name.name))
               expr.expr_loc env
           ) sd.sd_invars;
           TNamed (name, []))

  (* Assume — logs to audit, adds fact to proof context *)
  | EAssume (pred, ctx_str) ->
      log_assume pred ctx_str expr.expr_loc;
      (* NOTE: assume is trusted — logged for audit, does not generate a proof obligation.
         The fact is added at the check_stmt level when SExpr(EAssume) is processed. *)
      TPrim TUnit

  | EAssert (pred, _ctx_str) ->
      (* assert(pred): generates a proof obligation, does NOT add to env here.
         The fact is added at check_stmt | SExpr level after check_expr returns. *)
      add_obligation pred (OInvariant "assert") expr.expr_loc env;
      TPrim TUnit

  (* Inline assembly — opaque, returns unit, no proof obligations *)
  | EAsm _ab ->
      TPrim TUnit

  (* __syncthreads() — GPU warp barrier.
     Forbidden inside divergent (varying-condition) branches. *)
  | ESync ->
      if env.in_varying_branch then
        fail expr.expr_loc
          "__syncthreads() inside a divergent branch (varying condition) — undefined behavior";
      TPrim TUnit

  | EArrayLit elems ->
      let n = List.length elems in
      if n = 0 then (fail expr.expr_loc "empty array literal []"; TArray (TPrim (TUint U64), None))
      else
        let elem_tys = List.map (check_expr env) elems in
        let elem_ty = List.fold_left (fun acc t ->
          if ty_compatible acc t then acc
          else (fail expr.expr_loc
            (Printf.sprintf "array literal: element types don't match: %s vs %s"
              (format_ty acc) (format_ty t)); acc)
        ) (List.hd elem_tys) (List.tl elem_tys) in
        let n_expr = { expr_desc = ELit (LInt (Int64.of_int n, None));
                       expr_loc = expr.expr_loc;
                       expr_ty  = Some (TPrim (TUint U64)) } in
        TArray (elem_ty, Some n_expr)

  | EArrayRepeat (v, n) ->
      let elem_ty = check_expr env v in
      let _ = check_expr env n in
      TArray (elem_ty, Some n)

  (* Tuple construction: (e1, e2, ...) *)
  | ETuple elems ->
      let elem_tys = List.map (check_expr env) elems in
      TTuple elem_tys

  (* Tuple field projection: t.0, t.1, ... *)
  | EField_n (tup, idx) ->
      let tup_ty = check_expr env tup in
      (match tup_ty with
       | TTuple tys ->
           if idx >= 0 && idx < List.length tys then List.nth tys idx
           else (fail expr.expr_loc
             (Printf.sprintf "tuple index %d out of range (len %d)" idx (List.length tys));
             TPrim TUnit)
       | _ ->
           fail expr.expr_loc
             (Printf.sprintf "numeric field access on non-tuple type %s" (format_ty tup_ty));
           TPrim TUnit)

  (* loop { stmts } — value-returning loop; type is the break value type *)
  | ELoop stmts ->
      let break_ty_ref = ref None in
      let env_loop = { env with loop_break_ty = Some break_ty_ref } in
      let _ = check_stmts env_loop stmts in
      (match !break_ty_ref with
       | Some t -> t
       | None   -> TPrim TNever)

  (* Sub-span: s[lo..hi] → span<T>
     Obligations: lo >= 0, lo <= hi, hi <= s.len *)
  | ESubspan (arr, lo, hi) ->
      let arr_ty = check_expr env arr in
      let _ = check_expr env lo in
      let _ = check_expr env hi in
      let elem_ty = match arr_ty with
        | TSpan t -> t
        | _ ->
            fail expr.expr_loc "subspan s[lo..hi] requires a span<T> operand";
            TPrim (TUint U64)
      in
      let lo_p  = expr_to_pred_simple lo in
      let hi_p  = expr_to_pred_simple hi in
      let len_p = PField (expr_to_pred_simple arr, "len") in
      add_obligation (PBinop (Ge, lo_p, PInt 0L))
        (OBoundsCheck "subspan lo >= 0") expr.expr_loc env;
      add_obligation (PBinop (Le, lo_p, hi_p))
        (OBoundsCheck "subspan lo <= hi") expr.expr_loc env;
      add_obligation (PBinop (Le, hi_p, len_p))
        (OBoundsCheck "subspan hi <= len") expr.expr_loc env;
      TSpan elem_ty

  | ERange (lo, hi) ->
      (* lo..hi range — only valid as a for-loop iterator; typechecks lo and hi *)
      let _ = check_expr env lo in
      let _ = check_expr env hi in
      TPrim (TUint U64)

  | ELambda (params, body, name_ref) ->
      (* Lift \(x: T, ...) -> body to a synthesized top-level function __forge_lambda_N.
         Typecheck the body in an env extended with the lambda params.
         Return TFn type; the lifted name is recorded in name_ref for codegen. *)
      let n = List.length !synthesized_items in
      let lam_name = Printf.sprintf "__forge_lambda_%d" n in
      name_ref := Some lam_name;
      (* Build inner env with params bound *)
      let inner_env = List.fold_left
        (fun e (id, t) -> env_add_var e id.name t Unr id.loc)
        env params
      in
      let ret_ty = check_expr inner_env body in
      (* Closure-capture check: Forge lambdas currently lift to plain top-level
         C functions with no environment.  If the body references a local
         variable from the enclosing scope (not a top-level symbol and not in
         the lambda's own parameter list), the generated C is not compilable
         — the lifted function has no way to see the captured value.
         Detect this and emit a clear error instead of silently producing
         broken C.  Full closure support (fat fn-pointer with env struct +
         thunk) is tracked as future work.  *)
      let param_names = List.map (fun (id, _) -> id.name) params in
      let outer_var_names = List.map fst env.vars in
      let captures = find_lambda_captures body param_names outer_var_names in
      List.iter (fun (name, loc) ->
        fail loc
          (Printf.sprintf
             "lambda captures local variable '%s' from enclosing scope, \
              but Forge lambdas do not yet support environment capture. \
              Pass '%s' as an explicit parameter instead, or use a named \
              top-level function." name name)
      ) captures;
      (* Synthesize the top-level IFn *)
      let lam_fn : fn_def = {
        fn_name     = { name = lam_name; loc = expr.expr_loc };
        fn_generics = [];
        fn_params   = params;
        fn_ret      = ret_ty;
        fn_requires = [];
        fn_ensures  = [];
        fn_decreases = None;
        fn_body     = Some body;
        fn_attrs    = [];
      } in
      let synth_item = { item_desc = IFn lam_fn; item_loc = expr.expr_loc } in
      synthesized_items := synth_item :: !synthesized_items;
      TFn { params; ret = ret_ty; requires = []; ensures = [] }

and check_stmts env stmts : env =
  let env' = List.fold_left check_stmt env stmts in
  (* Must-use check: Lin variables introduced in this block must be consumed.
     Walk vars added since this block started and flag any unused Lin bindings.
     NOTE: for EBlock (stmts, Some trailing_expr) this check is deferred until
     after the trailing expression is evaluated — see EBlock handler above.
     This function is called directly for while/for/raw bodies (no trailing expr). *)
  check_lin_vars env env';
  env'

(* Check that all Lin variables newly introduced since `outer_env` are used.
   `vi_used` is a `bool ref`, so uses recorded by check_expr are visible here. *)
and check_lin_vars outer_env inner_env =
  let outer_names = List.map fst outer_env.vars in
  List.iter (fun (name, vi) ->
    if not (List.mem name outer_names)
       && vi.vi_linearity = Lin
       && not !(vi.vi_used) then
      report_error (LinearityError (vi.vi_loc,
        Printf.sprintf "linear variable '%s' is never used \
          (linear values must be consumed exactly once)" name))
  ) inner_env.vars

and check_stmt env stmt : env =
  match stmt.stmt_desc with
  | SLet (name, ann, expr_, lin) ->
      (* Normalize annotation: convert TNamed("secret", [t]) → TSecret t *)
      let ann = match ann with Some t -> Some (normalize_ty t) | None -> None in
      (* Pass annotation as expected_ty so zero-arg generic constructors
         (e.g. None : Option<T>) resolve to the annotated type. *)
      let env_rhs = match ann with
        | Some t -> { env with expected_ty = Some t }
        | None   -> env
      in
      let inferred = check_expr env_rhs expr_ in
      let ty = match ann with
        | Some t ->
            (* shared<T>[N] declarations use a placeholder expression — skip compat check *)
            if (match t with TShared _ -> false | _ -> true)
               && not (ty_compatible t inferred) then
              fail stmt.stmt_loc
                (Printf.sprintf "type annotation %s doesn't match inferred %s"
                  (format_ty t) (format_ty inferred));
            (* Annotation wins for the base type (numeric coercion etc.).
               But if the annotation has no explicit qualifier and the RHS is
               varying, propagate the varying qualifier — otherwise `let i: u64
               = threadIdx_x` would silently drop the varying tag. *)
            (match t with
             | TQual _ -> t   (* annotation is explicitly qualified — use it *)
             | _ ->
                 let q = qual_of_ty inferred in
                 if q = Varying then TQual (Varying, t) else t)
        | None -> inferred
      in
      (* If the type has a refinement, generate an obligation *)
      (match ty with
       | TRefined (_, binder, pred) ->
           let subst = [(binder.name, expr_to_pred_simple expr_)] in
           let ob_pred = subst_pred subst pred in
           add_obligation ob_pred (OInvariant ("refinement:" ^ name.name))
             stmt.stmt_loc env
       | _ -> ());
      (* refmut<T> bindings are automatically affine: they cannot be copied or
         aliased. If the user didn't declare a stronger linearity, promote to Aff. *)
      let lin' = match ty with
        | TRefMut _ when lin = Unr -> Aff
        | _ -> lin
      in
      (* Add the binding's value as a known fact: name == rhs *)
      let env' = env_add_var env name.name ty lin' stmt.stmt_loc in
      let val_fact = PBinop (Eq, PVar name, expr_to_pred_simple expr_) in
      let env'' = env_add_fact env' val_fact in
      (* For struct literals, also add field projection facts: name.f == val *)
      (* For subspan s[lo..hi], add name.len == hi - lo (enables while_entry proof) *)
      let env_base =
        match expr_.expr_desc with
        | EStruct (_, fields) ->
            List.fold_left (fun e (fid, fexpr) ->
              env_add_fact e (PBinop (Eq,
                PField (PVar name, fid.name),
                expr_to_pred_simple fexpr))
            ) env'' fields
        | ESubspan (_, lo, hi) ->
            let len_pred = PField (PVar name, "len") in
            let len_eq_fact = PBinop (Eq, len_pred,
              PBinop (Sub, expr_to_pred_simple hi, expr_to_pred_simple lo)) in
            let len_nonneg_fact = PBinop (Ge, len_pred, PInt 0L) in
            env_add_fact (env_add_fact env'' len_eq_fact) len_nonneg_fact
        | ECast (inner, _) ->
            let src_ty = match inner.expr_ty with Some t -> t | None -> TPrim TUnit in
            (match src_ty with
             | TPrim (TUint U8)  -> env_add_fact env'' (PBinop (Le, PVar name, PInt 255L))
             | TPrim (TUint U16) -> env_add_fact env'' (PBinop (Le, PVar name, PInt 65535L))
             | TPrim (TUint U32) -> env_add_fact env'' (PBinop (Le, PVar name, PInt 4294967295L))
             | _ -> env'')
        | EBinop (Mod, _, divisor) ->
            (match expr_to_pred_simple divisor with
             | PInt n when n > 0L ->
                 env_add_fact env'' (PBinop (Lt, PVar name, PInt n))
             | _ -> env'')
        | EBinop (Div, dividend, divisor) ->
            (match expr_to_pred_simple divisor with
             | PInt n when n >= 1L ->
                 let _ = n in
                 env_add_fact env'' (PBinop (Le, PVar name, expr_to_pred_simple dividend))
             | _ -> env'')
        | EBinop (BitAnd, lhs, rhs) ->
            let lp = expr_to_pred_simple lhs in
            let rp = expr_to_pred_simple rhs in
            let e1 = env_add_fact env'' (PBinop (Le, PVar name, lp)) in
            env_add_fact e1 (PBinop (Le, PVar name, rp))
        | EBinop (Shr, lhs, _) ->
            env_add_fact env'' (PBinop (Le, PVar name, expr_to_pred_simple lhs))
        | _ -> env''
      in
      (* Inject callee postconditions as facts about `name`.
         Mirrors the same logic in stmt_final_env | SLet.
         E.g. `let c2 = conn_accept(c1, 4444u64)` where conn_accept ensures
         result.state == 2u64  →  adds fact c2.state == 2u64.
         This lets downstream precondition checks see the callee result. *)
      let inject_postconds env_in sig_ all_args =
        if sig_.fs_ensures = [] then env_in
        else if List.length sig_.fs_params <> List.length all_args then env_in
        else begin
          let arg_subst = List.map2 (fun (pid, _) arg ->
            (pid.name, expr_to_pred_simple arg)
          ) sig_.fs_params all_args in
          let result_subst = ("result", PVar name) :: arg_subst in
          List.fold_left (fun e ens ->
            env_add_fact e (subst_pred result_subst ens)
          ) env_in sig_.fs_ensures
        end
      in
      (* Helper: inject postconditions from a fn-pointer variable's fn_ty.ensures *)
      let inject_postconds_fty env_in fty all_args =
        if fty.ensures = [] then env_in
        else if List.length fty.params <> List.length all_args then env_in
        else begin
          let arg_subst = List.map2 (fun (pid, _) arg ->
            (pid.name, expr_to_pred_simple arg)
          ) fty.params all_args in
          let result_subst = ("result", PVar name) :: arg_subst in
          List.fold_left (fun e ens ->
            env_add_fact e (subst_pred result_subst ens)
          ) env_in fty.ensures
        end
      in
      (match expr_.expr_desc with
       | ECall ({ expr_desc = EVar fn_id; _ }, call_args) ->
           (match env_lookup_fn env fn_id.name with
            | Some sig_ -> inject_postconds env_base sig_ call_args
            | None ->
                (match env_lookup_var env fn_id.name with
                 | Some { vi_ty = TFn fty; _ } ->
                     inject_postconds_fty env_base fty call_args
                 | _ -> env_base))
       | ECall ({ expr_desc = EField (obj, method_name); _ }, call_args) ->
           let obj_ty = match obj.expr_ty with Some t -> t | None -> TPrim TUnit in
           let type_name = mangle_ty_name (normalize_ty obj_ty) in
           let mangled = type_name ^ "__" ^ method_name.name in
           let sig_opt =
             match env_lookup_fn env mangled with
             | Some _ as s -> s
             | None ->
                 let prefix = type_name ^ "__" in
                 let suffix = "__" ^ method_name.name in
                 List.find_map (fun (fname, sig_) ->
                   let pn = String.length prefix in
                   let sn = String.length suffix in
                   let fn_ = String.length fname in
                   if fn_ > pn + sn &&
                      String.sub fname 0 pn = prefix &&
                      String.sub fname (fn_ - sn) sn = suffix
                   then Some sig_
                   else None
                 ) env.fns
           in
           (match sig_opt with
            | Some sig_ -> inject_postconds env_base sig_ (obj :: call_args)
            | _ -> env_base)
       | _ -> env_base)

  | SGhost (name, ann, rhs) ->
      (* Ghost let: type-check the RHS (to catch expression errors), then add to
         proof context without generating runtime code. No obligations generated
         beyond what the RHS expression itself requires. *)
      let inferred = check_expr env rhs in
      let ty = match ann with
        | Some t -> normalize_ty t
        | None   -> inferred
      in
      let env' = env_add_var env name.name ty Unr stmt.stmt_loc in
      env_add_fact env' (PBinop (Eq, PVar name, expr_to_pred_simple rhs))

  | SGhostAssign (name, rhs) ->
      (* Mutable ghost update: SSA-rename the ghost variable with its new value.
         Identical to a regular variable assignment in the proof engine — the new
         binding shadows the old one via env_assign_var. Erased in codegen. *)
      let _ = check_expr env rhs in
      env_assign_var env name (expr_to_pred_simple rhs)

  | SExpr e ->
      let _ = check_expr env e in
      (* SSA-lite: if this is an assignment, track the new value as a fact.
         ESync: mark barrier reached so subsequent shared[] accesses are unrestricted.
         EAssert: add the proved predicate as a known fact for subsequent code.
         EAssume: add the trusted predicate as a known fact for subsequent code. *)
      (match e.expr_desc with
       | EAssign (lhs, rhs) ->
           (match lhs.expr_desc with
            | EVar v ->
                let env' = env_assign_var env v (expr_to_pred_simple rhs) in
                (* Inject callee postconditions for x = f(args) assignments
                   so downstream precondition checks see the callee's ensures. *)
                (match rhs.expr_desc with
                 | ECall ({ expr_desc = EVar fn_id; _ }, call_args) ->
                     (match env_lookup_fn env fn_id.name with
                      | Some sig_ when sig_.fs_ensures <> [] &&
                          List.length sig_.fs_params = List.length call_args ->
                          let arg_subst = List.map2 (fun (pid, _) arg ->
                            (pid.name, expr_to_pred_simple arg)
                          ) sig_.fs_params call_args in
                          let result_subst = ("result", PVar v) :: arg_subst in
                          List.fold_left (fun e ens ->
                            env_add_fact e (subst_pred result_subst ens)
                          ) env' sig_.fs_ensures
                      | _ -> env')
                 | _ -> env')
            (* Scalar dereference assignment: *v = rhs *)
            | EDeref deref_inner ->
                (match deref_inner.expr_desc with
                 | EVar v -> env_assign_var env v (expr_to_pred_simple rhs)
                 | _      -> env)
            (* Field assignment: c.field = rhs, or deref-then-field = rhs.
               Uses SSA renaming via env_assign_field so old field values
               are captured and new facts are consistent. *)
            | EField (outer, fld) ->
                let base_pred = match outer.expr_desc with
                  | EDeref inner -> expr_to_pred_simple inner
                  | _            -> expr_to_pred_simple outer
                in
                env_assign_field env base_pred fld.name (expr_to_pred_simple rhs)
            | EIndex (arr, idx) ->
                (* Array element assignment: use SSA-style store model.
                   For a simple EVar base, use env_array_write which renames
                   the old array and adds a frame axiom so that elements not
                   written at idx are known to be unchanged (enabling swap proofs).
                   For complex base expressions fall back to a single equality. *)
                let idx_pred = expr_to_pred_simple idx in
                let rhs_pred = expr_to_pred_simple rhs in
                let inject_call_posts env_base =
                  match rhs.expr_desc with
                  | ECall ({ expr_desc = EVar fn_id; _ }, call_args) ->
                      (match env_lookup_fn env fn_id.name with
                       | Some sig_ when sig_.fs_ensures <> [] &&
                           List.length sig_.fs_params = List.length call_args ->
                           let arg_subst = List.map2 (fun (pid, _) arg ->
                             (pid.name, expr_to_pred_simple arg)
                           ) sig_.fs_params call_args in
                           let result_subst = ("result", rhs_pred) :: arg_subst in
                           List.fold_left (fun e ens ->
                             env_add_fact e (subst_pred result_subst ens)
                           ) env_base sig_.fs_ensures
                       | _ -> env_base)
                  | _ -> env_base
                in
                (match arr.expr_desc with
                 | EVar arr_id ->
                     inject_call_posts (env_array_write env arr_id idx_pred rhs_pred)
                 | _ ->
                     let arr_pred = expr_to_pred_simple arr in
                     inject_call_posts (env_add_fact env
                       (PBinop (Eq, PIndex (arr_pred, idx_pred), rhs_pred))))
            | _      -> env)
       | ESync -> { env with after_barrier = true }
       | EAssert (pred, _) ->
           (* Fact is proved (obligation generated in check_expr); now add it to context *)
           env_add_fact env pred
       | EAssume (pred, _) ->
           (* Fact is trusted; add it to context so downstream proofs can use it *)
           env_add_fact env pred
       | EIf (cond, then_, else_opt) ->
           (* Model conditional updates as ITE facts (scalar vars and array elements). *)
           let cond_pred = expr_to_pred_simple cond in
           let is_elif = match else_opt with
             | Some { expr_desc = EIf _; _ } -> true | _ -> false
           in
           let env1 =
             if is_elif then
               let chain = collect_chain_var_assigns e in
               if chain = [] then env
               else apply_chain_var_assigns env cond_pred chain
             else begin
               let then_assigns = extract_block_var_assigns then_ in
               let else_assigns = match else_opt with
                 | Some el -> extract_block_var_assigns el | None -> []
               in
               if then_assigns = [] && else_assigns = [] then env
               else apply_if_assigns env cond_pred then_assigns else_assigns
             end
           in
           let env2 =
             if is_elif then
               let chain_arr = collect_chain_arr_assigns e in
               List.fold_left (fun env_ (arr_id, idx_p, val_p) ->
                 env_array_write env_ arr_id idx_p val_p
               ) env1 chain_arr
             else begin
               let then_arr = extract_block_arr_assigns then_ in
               let else_arr = match else_opt with
                 | Some el -> extract_block_arr_assigns el | None -> []
               in
               if then_arr = [] && else_arr = [] then env1
               else apply_if_arr_assigns env1 cond_pred then_arr else_arr
             end
           in
           env2
       (* Void function call as statement: inject callee postconditions.
          Handles cases like  conn_listen(&mut c, port)  where ensures clauses
          describe mutations to refmut params that the caller needs downstream. *)
       | ECall ({ expr_desc = EVar fn_id; _ }, call_args) ->
           (match env_lookup_fn env fn_id.name with
            | Some sig_ when sig_.fs_ensures <> [] &&
                List.length sig_.fs_params = List.length call_args ->
                let arg_subst = List.map2 (fun (pid, _) arg ->
                  (pid.name, expr_to_pred_simple arg)
                ) sig_.fs_params call_args in
                List.fold_left (fun e ens ->
                  let subst_ens  = subst_pred arg_subst ens in
                  let resolved   = resolve_old_for_injection e subst_ens in
                  env_add_fact e resolved
                ) env sig_.fs_ensures
            | _ -> env)
       | _ ->
           (* For EBlock (which wraps while/for loops from the parser),
              use expr_final_env to propagate loop exit facts (NOT cond,
              invariant) to subsequent code without re-generating obligations. *)
           expr_final_env env e)

  | SReturn e ->
      (match env.current_fn with
       | None -> fail stmt.stmt_loc "return outside function"; env
       | Some sig_ ->
           let env_ret = { env with expected_ty = Some sig_.fs_ret } in
           let ret_ty = match e with
             | Some expr_ -> check_expr env_ret expr_
             | None       -> TPrim TUnit
           in
           if not (ty_compatible ret_ty sig_.fs_ret) then
             fail stmt.stmt_loc "return type mismatch";
           (* Check postconditions — substitute result → return expression
              so that ensures clauses like 'result == 2*x' are checked
              against the actual returned value, not the literal name.
              For `return f(args)`, inject callee postconditions so Z3 can
              use them to discharge the caller's ensures clauses. *)
           let ret_pred, ret_env = match e with
             | None -> (PBool true, env)
             | Some expr_ ->
                 (match expr_.expr_desc with
                  | ECall ({ expr_desc = EVar fn_id; _ }, call_args) ->
                      let call_pred = PVar { name = "__ret_call"; loc = expr_.expr_loc } in
                      let enriched =
                        match env_lookup_fn env fn_id.name with
                        | Some csig
                          when csig.fs_ensures <> []
                            && List.length csig.fs_params = List.length call_args ->
                            let arg_subst = List.map2 (fun (pid, _) arg ->
                              (pid.name, expr_to_pred_simple arg)
                            ) csig.fs_params call_args in
                            let rsubst = ("result", call_pred) :: arg_subst in
                            List.fold_left (fun e2 ens ->
                              env_add_fact e2 (subst_pred rsubst ens)
                            ) env csig.fs_ensures
                        | _ -> env
                      in
                      (call_pred, enriched)
                  | _ -> (expr_to_pred_simple expr_, env))
           in
           List.iter (fun ens ->
             let ob_pred = subst_pred [("result", ret_pred)] ens in
             add_obligation ob_pred (OPostcondition sig_.fs_name)
               stmt.stmt_loc ret_env
           ) sig_.fs_ensures;
           env)

  | SWhile (cond, invs, dec, body) ->
      let cond_ty = check_expr env cond in
      if not (is_bool cond_ty) then
        fail stmt.stmt_loc "while condition must be bool";
      let cond_pred = expr_to_pred_simple cond in
      (* 1. Each invariant holds at loop entry — prove from pre-loop env *)
      List.iter (fun p ->
        add_obligation p (OInvariant "while_entry") stmt.stmt_loc env
      ) invs;
      (* 2. Termination measure is non-negative when loop condition holds.
            The measure only needs to be >= 0 at iterations that actually execute,
            i.e., when the loop condition is true. This enables grid-stride loops
            where idx starts at gid (possibly >= n): the measure n-idx is only
            checked when idx < n, making it trivially non-negative.
            PLex (a, b) expands to: a >= 0 AND b >= 0 (each component non-negative). *)
      let env_for_dec = env_add_fact env cond_pred in
      (match dec with
       | None -> ()
       | Some (PLex ms) ->
           List.iter (fun m ->
             add_obligation (PBinop (Ge, m, PInt 0L))
               (OTermination "while") stmt.stmt_loc env_for_dec
           ) ms
       | Some measure ->
           add_obligation (PBinop (Ge, measure, PInt 0L))
             (OTermination "while") stmt.stmt_loc env_for_dec);
      (* 3. Check body in env extended with cond AND all invariants as facts *)
      let env_body = env_add_fact env cond_pred in
      let env_body = List.fold_left env_add_fact env_body invs in
      let env_after = check_stmts env_body body in
      (* 4. Each invariant is preserved: prove it holds after body.
            When the body is a single elif chain, generate per-branch obligations
            instead of the ITE-encoded unified obligation.  This avoids the
            ITE-in-array-index problem where  a[ite(c, i+1, i)]  is opaque to
            Z3's E-matching, causing frontier-style invariants to fail. *)
      (match body with
       | [{ stmt_desc = SExpr ({ expr_desc = EIf _; _ } as if_expr); _ }] ->
           let branches = collect_elif_branches [] if_expr in
           List.iter (fun (guard, branch_stmts) ->
             let env_br = env_add_fact env_body guard in
             let env_after_br = stmts_final_env env_br branch_stmts in
             List.iter (fun p ->
               add_obligation p (OInvariant "while_preserved") stmt.stmt_loc env_after_br
             ) invs
           ) branches
       | _ ->
           List.iter (fun p ->
             add_obligation p (OInvariant "while_preserved") stmt.stmt_loc env_after
           ) invs);
      (* 5. After the loop: strip stale initial-value facts for loop-modified
            vars (same as stmt_final_env does), then add ¬cond AND all invariants.
            This ensures nested-loop exit facts use the invariant, not the
            initial let-binding equalities from the surrounding scope. *)
      let modified = collect_assigned_vars body in
      let env_clean = strip_stale_facts env modified in
      let env_exit = env_add_fact env_clean (PUnop (Not, cond_pred)) in
      List.fold_left env_add_fact env_exit invs

  | SFor (name, iter, invs, dec, body) ->
      let is_range = match iter.expr_desc with ERange _ -> true | _ -> false in
      let iter_ty = check_expr env iter in
      let is_span_iter = match iter_ty with TSpan _ | TStr -> true | _ -> false in
      let is_iterator = match iter_ty with
        | TNamed (id, _) -> env_has_impl env id.name "Iterator"
        | _ -> false
      in
      let elem_ty = match iter_ty with
        | TSpan t -> t
        | TStr    -> TPrim (TUint U8)
        | TSlice t | TArray (t, _) -> t
        | TRef (TSlice t) | TRef (TArray (t, _)) -> t
        | TNamed _ when is_iterator ->
            (match resolve_assoc_ty env iter_ty "Item" with
             | Some t -> t
             | None   -> TPrim (TUint U64))
        | _ -> TPrim (TUint U64)
      in
      (* 1. Each invariant holds at loop entry (i = lo, or 0 for plain for-in-n) *)
      let entry_val = match iter.expr_desc with
        | ERange (lo, _) -> expr_to_pred_simple lo
        | _              -> PInt 0L
      in
      let env_entry = env_add_var env name.name elem_ty Unr stmt.stmt_loc in
      let env_entry = env_add_fact env_entry (PBinop (Eq, PVar name, entry_val)) in
      List.iter (fun p ->
        add_obligation p (OInvariant "for_entry") stmt.stmt_loc env_entry
      ) invs;
      (match dec with
       | None -> ()
       | Some (PLex ms) ->
           List.iter (fun m ->
             add_obligation (PBinop (Ge, m, PInt 0L))
               (OTermination "for") stmt.stmt_loc env
           ) ms
       | Some measure ->
           add_obligation (PBinop (Ge, measure, PInt 0L))
             (OTermination "for") stmt.stmt_loc env);
      (* 2. Build body env: loop var in scope + range bounds + invariants *)
      let env' = env_add_var env name.name elem_ty Unr stmt.stmt_loc in
      let env_body = match iter.expr_desc with
        | ERange (lo, hi) ->
            (* for i in lo..hi: inject lo <= i < hi *)
            let lo_p = expr_to_pred_simple lo in
            let hi_p = expr_to_pred_simple hi in
            let i_pred = PVar name in
            let e = env_add_fact env' (PBinop (Lt, i_pred, hi_p)) in
            env_add_fact e (PBinop (Ge, i_pred, lo_p))
        | _ ->
            if is_span_iter || is_iterator then env'
            else begin
              (* for i in n: inject 0 <= i < n so arr[i] bounds are auto-provable *)
              let n_pred = expr_to_pred_simple iter in
              let i_pred = PVar name in
              let e = env_add_fact env' (PBinop (Lt, i_pred, n_pred)) in
              env_add_fact e (PBinop (Ge, i_pred, PInt 0L))
            end
      in
      let env_body = List.fold_left env_add_fact env_body invs in
      let env_after = check_stmts env_body body in
      (* 3. Invariant preserved: check with i incremented to model the loop step.
            env_assign_var renames i -> i_pN = i_old + 1, so any invariant
            referencing i naturally sees the post-increment value. *)
      let env_after_incr =
        if is_span_iter || is_iterator then env_after
        else if is_range then
          env_assign_var env_after name (PBinop (Add, PVar name, PInt 1L))
        else
          env_assign_var env_after name (PBinop (Add, PVar name, PInt 1L))
      in
      List.iter (fun p ->
        add_obligation p (OInvariant "for_preserved") stmt.stmt_loc env_after_incr
      ) invs;
      (* 4. Post-loop env: strip stale facts, add invariants with i=hi substituted.
            For for i in n: substitute n for i.
            For for i in lo..hi: substitute hi for i.
            Either way, quantified invariants like (forall k, k < i => P)
            become (forall k, k < n/hi => P). *)
      let modified = collect_assigned_vars body in
      let env_clean = strip_stale_facts env modified in
      let n_pred = match iter.expr_desc with
        | ERange (_, hi) -> expr_to_pred_simple hi
        | _              -> expr_to_pred_simple iter
      in
      let final_invs = List.map (fun p ->
        subst_pred [(name.name, n_pred)] p
      ) invs in
      List.fold_left env_add_fact env_clean final_invs

  | SBreak (Some e) ->
      (* break val — type-check the value; set the loop result type *)
      let break_ty = check_expr env e in
      (match env.loop_break_ty with
       | Some r -> (match !r with
           | None   -> r := Some break_ty
           | Some _ -> ())
       | None -> fail stmt.stmt_loc "break with value outside of loop { }");
      env
  | SBreak None | SContinue -> env

and check_field_access obj_ty field loc env =
  (* Strip qualifiers before checking *)
  match strip_qual obj_ty with
  | TStr ->
      (* str has .data (raw<u8>) and .len (usize) — same layout as span<u8> *)
      (match field.name with
       | "data" -> TRaw (TPrim (TUint U8))
       | "len"  -> TPrim (TUint USize)
       | _      ->
           fail loc (Printf.sprintf "str has no field '%s' (only 'data' and 'len')" field.name);
           TPrim TUnit)
  | TSpan t ->
      (* span<T> has synthetic fields: .data (raw<T>) and .len (usize) *)
      (match field.name with
       | "data" -> TRaw t
       | "len"  -> TPrim (TUint USize)
       | _      ->
           fail loc (Printf.sprintf "span<T> has no field '%s' (only 'data' and 'len')" field.name);
           TPrim TUnit)
  | TShared (_t, _) ->
      (* shared<T>[N] array: .len only *)
      (match field.name with
       | "len" -> TPrim (TUint USize)
       | _ ->
           fail loc (Printf.sprintf "shared<T> has no field '%s'" field.name);
           TPrim TUnit)
  | TNamed (name, ty_args) | TRef (TNamed (name, ty_args))
  | TRefMut (TNamed (name, ty_args)) | TOwn (TNamed (name, ty_args)) ->
      (match List.assoc_opt name.name env.structs with
       | Some sd ->
           (* Build type-param substitution if the struct is generic *)
           let param_subst =
             if ty_args = [] then []
             else
               let param_names = List.map (fun (p, _) -> p.name) sd.sd_params in
               if List.length param_names = List.length ty_args then
                 List.combine param_names ty_args
               else []
           in
           (match List.assoc_opt field.name
                    (List.map (fun (id, ty) -> (id.name, ty)) sd.sd_fields) with
            | Some ft ->
                if param_subst = [] then ft else subst_ty param_subst ft
            | None ->
                fail loc (Printf.sprintf "no field '%s' on struct '%s'"
                  field.name name.name);
                TPrim TUnit)
       | None ->
           fail loc (Printf.sprintf "unknown struct '%s'" name.name);
           TPrim TUnit)
  | _ ->
      fail loc (Printf.sprintf "field access on non-struct type (%s)" (format_ty obj_ty));
      TPrim TUnit

(* Build a list of proof facts implied by a match arm pattern.
   Injected into the arm's proof context so Z3 can reason inside the arm.
   scrut_pred: pred for the scrutinee expression.
   env: typecheck env (needed for PCtor field-name lookup). *)
and pattern_to_path_facts env scrut_pred pat =
  match pat with
  | PWild    -> []
  | PLit (LInt (n, _)) -> [PBinop (Eq, scrut_pred, PInt n)]
  | PLit (LBool b)     -> [PBinop (Eq, scrut_pred, PBool b)]
  | PLit _             -> []
  | PLitRange (LInt (lo, _), LInt (hi, _)) ->
      [ PBinop (Ge, scrut_pred, PInt lo);
        PBinop (Le, scrut_pred, PInt hi) ]
  | PLitRange _ -> []
  | PBind id -> [PBinop (Eq, PVar id, scrut_pred)]
  | PCtor (ctor_id, subpats) ->
      (* Tag discriminant fact *)
      let tag_fact = PBinop (Eq, PField (scrut_pred, "tag"), PVar ctor_id) in
      (* Field binding facts: for each PBind subpat, bind subvar == scrut.field *)
      let field_facts = match List.assoc_opt ctor_id.name env.fns with
        | Some sig_ ->
            List.filter_map (fun (subpat, (param, _)) ->
              match subpat with
              | PBind id ->
                  Some (PBinop (Eq, PVar id,
                    PField (scrut_pred, param.name)))
              | _ -> None
            ) (try List.combine subpats sig_.fs_params
               with Invalid_argument _ -> [])
        | None -> []
      in
      tag_fact :: field_facts
  | PTuple _ -> []
  | PAs (inner, alias) ->
      (* alias == scrutinee, plus inner pattern facts *)
      PBinop (Eq, PVar alias, scrut_pred)
      :: pattern_to_path_facts env scrut_pred inner
  | POr (p1, p2) ->
      (* Either sub-pattern may have fired; only disjunction is sound *)
      let c1 = pattern_to_cond_pred scrut_pred p1 in
      let c2 = pattern_to_cond_pred scrut_pred p2 in
      [PBinop (Or, c1, c2)]

and bind_pattern_vars env scrut_ty pat =
  match pat with
  | PWild    -> env
  | PLit _   -> env
  | PLitRange _ -> env
  | PBind name ->
      env_add_var env name.name scrut_ty Unr name.loc
  | PCtor (ctor_id, subpats) ->
      (* Look up constructor signature to get field types.
         For generic enums, substitute type params from the scrutinee type. *)
      let field_pairs = match List.assoc_opt ctor_id.name env.fns with
        | Some sig_ ->
            (* Build type substitution from scrutinee type if it's a generic TNamed *)
            let type_subst = match scrut_ty with
              | TNamed (enum_id, ty_args) when ty_args <> [] ->
                  (match List.assoc_opt enum_id.name env.enums with
                   | Some ed when ed.ed_params <> [] ->
                       List.map2 (fun (p, _) arg -> (p.name, arg))
                         ed.ed_params ty_args
                   | _ -> [])
              | _ -> []
            in
            let rec zip ps qs = match ps, qs with
              | [], _ | _, [] -> []
              | p :: pr, (_, t) :: qr ->
                  let t' = if type_subst = [] then t else subst_ty type_subst t in
                  (p, t') :: zip pr qr
            in
            zip subpats sig_.fs_params
        | None ->
            List.map (fun p -> (p, TPrim (TUint U64))) subpats
      in
      List.fold_left (fun e (sp, fty) ->
        bind_pattern_vars e fty sp
      ) env field_pairs
  | PTuple pats ->
      let elem_tys = match scrut_ty with
        | TTuple ts when List.length ts = List.length pats -> ts
        | _ -> List.map (fun _ -> TPrim (TUint U64)) pats
      in
      List.fold_left2 (fun e p et -> bind_pattern_vars e et p) env pats elem_tys
  | PAs (inner, name) ->
      let env' = bind_pattern_vars env scrut_ty inner in
      env_add_var env' name.name scrut_ty Unr name.loc
  | POr (p1, p2) ->
      (* Both branches must bind the same names; bind from first branch. *)
      let env1 = bind_pattern_vars env scrut_ty p1 in
      ignore (bind_pattern_vars env scrut_ty p2);
      env1

and check_proof_block env pb =
  (* Assumes: log to audit trail, add as proof facts *)
  List.iter (fun (a : assume_stmt) ->
    log_assume a.as_pred a.as_context a.as_loc;
  ) pb.pb_assumes;
  (* Lemmas: check each proof term against its stated proposition.
     On success, the lemma is registered and available via PTBy. *)
  List.iter (fun (lem : lemma) ->
    (match check_lemma env.proof_ctx lem with
     | None ->
         Printf.printf "  [proof] lemma '%s' verified\n%!" lem.lem_name.name
     | Some msg ->
         report_error (TypeError (lem.lem_name.loc, msg)))
  ) pb.pb_lemmas

(* ------------------------------------------------------------------ *)
(* Top-level item type checking                                         *)
(* ------------------------------------------------------------------ *)

let collect_fn_sig (fn : fn_def) : fn_sig =
  (* KNat and KConst generic params become leading parameters so they
     participate in precondition checking and can be used in the body. *)
  let nat_params = List.filter_map (fun (id, k) ->
    match k with
    | KNat       -> Some (id, TPrim (TUint U64))
    | KConst t   -> Some (id, normalize_ty t)
    | KType      -> None
    | KBounded _ -> None
  ) fn.fn_generics in
  let type_param_names = List.filter_map (fun (id, k) ->
    match k with
    | KType | KBounded _ -> Some id.name
    | _ -> None
  ) fn.fn_generics in
  {
    fs_name        = fn.fn_name.name;
    fs_type_params = type_param_names;
    fs_generics    = List.map (fun (id, k) -> (id.name, k)) fn.fn_generics;
    fs_params      = nat_params @ List.map (fun (id, t) -> (id, normalize_ty t)) fn.fn_params;
    fs_ret         = normalize_ty fn.fn_ret;
    fs_requires    = fn.fn_requires;
    fs_ensures     = fn.fn_ensures;
    fs_decreases   = fn.fn_decreases;
  }

(* ------------------------------------------------------------------ *)
(* IND-CPA structural verification                                    *)
(* ------------------------------------------------------------------ *)

(* Scan an expression for declassify(name) where name is in key_params.
   Reports an error if the key is explicitly declassified — that would
   leak secret key material into the ciphertext computation. *)
let rec ind_cpa_scan_expr key_params expr =
  (match expr.expr_desc with
   | ECall ({ expr_desc = EVar id; _ }, args) when id.name = "declassify" ->
       List.iter (fun arg ->
         match arg.expr_desc with
         | EVar v when List.mem v.name key_params ->
             fail arg.expr_loc
               (Printf.sprintf
                  "ind_cpa: key parameter '%s' must not be declassified \
                   (declassify strips secret — key material would be exposed)"
                  v.name)
         | _ -> ind_cpa_scan_expr key_params arg
       ) args
   | _ -> ());
  match expr.expr_desc with
  | ELit _ | EVar _ | ESync -> ()
  | ECall (f, args)         -> ind_cpa_scan_expr key_params f;
                               List.iter (ind_cpa_scan_expr key_params) args
  | EBinop (_, l, r)        -> ind_cpa_scan_expr key_params l;
                               ind_cpa_scan_expr key_params r
  | EUnop (_, e) | ECast (e, _) | EField (e, _)
  | ERef e | ERefMut e | EDeref e -> ind_cpa_scan_expr key_params e
  | EAssign (l, r)          -> ind_cpa_scan_expr key_params l;
                               ind_cpa_scan_expr key_params r
  | EIndex (a, i)            -> ind_cpa_scan_expr key_params a;
                               ind_cpa_scan_expr key_params i
  | EIf (c, t, e)           -> ind_cpa_scan_expr key_params c;
                               ind_cpa_scan_expr key_params t;
                               (match e with Some e -> ind_cpa_scan_expr key_params e | None -> ())
  | EMatch (s, arms)        -> ind_cpa_scan_expr key_params s;
                               List.iter (fun arm -> ind_cpa_scan_expr key_params arm.body) arms
  | EBlock (stmts, ret)     ->
      List.iter (ind_cpa_scan_stmt key_params) stmts;
      (match ret with Some e -> ind_cpa_scan_expr key_params e | None -> ())
  | EStruct (_, fs)         -> List.iter (fun (_, e) -> ind_cpa_scan_expr key_params e) fs
  | EArrayLit elems         -> List.iter (ind_cpa_scan_expr key_params) elems
  | EArrayRepeat (v, n)     -> ind_cpa_scan_expr key_params v;
                               ind_cpa_scan_expr key_params n
  | ETuple elems            -> List.iter (ind_cpa_scan_expr key_params) elems
  | EField_n (e, _)         -> ind_cpa_scan_expr key_params e
  | ESubspan (e2, lo, hi)   -> ind_cpa_scan_expr key_params e2;
                               ind_cpa_scan_expr key_params lo;
                               ind_cpa_scan_expr key_params hi
  | ERange (lo, hi)         -> ind_cpa_scan_expr key_params lo;
                               ind_cpa_scan_expr key_params hi
  | ELoop stmts             -> List.iter (ind_cpa_scan_stmt key_params) stmts
  | EAssume _ | EAssert _ | EProof _ | ERaw _ | EAsm _ -> ()
  | ELambda (_, body, _) -> ind_cpa_scan_expr key_params body
and ind_cpa_scan_stmt key_params stmt =
  match stmt.stmt_desc with
  | SLet (_, _, e, _)          -> ind_cpa_scan_expr key_params e
  | SExpr e                    -> ind_cpa_scan_expr key_params e
  | SReturn (Some e)           -> ind_cpa_scan_expr key_params e
  | SWhile (c, _, _, body)     -> ind_cpa_scan_expr key_params c;
                                  List.iter (ind_cpa_scan_stmt key_params) body
  | SFor (_, e, _, _, body)    -> ind_cpa_scan_expr key_params e;
                                  List.iter (ind_cpa_scan_stmt key_params) body
  | SBreak (Some e)            -> ind_cpa_scan_expr key_params e
  | _ -> ()

(* Verify IND-CPA structural requirements on a function:
   1. At least one secret<T> parameter (key/message material).
   2. Return type is secret<T> (ciphertext must remain opaque).
   3. No key parameter is passed to declassify() in the body.
   4. Log an audit entry for the assume log (security claim is explicit).
   Parameters named 'nonce' or 'nonce_*' are identified as nonces in the log. *)
let check_ind_cpa fn =
  let name = fn.fn_name.name in
  (* Classify parameters:
     - nonce: any param named 'nonce' or 'nonce_*' (public or secret)
     - key:   secret<T> params that are not nonces
     - input: non-secret, non-nonce params (plaintext, associated data, etc.) *)
  let is_nonce_name n =
    n = "nonce" || (String.length n >= 6 && String.sub n 0 6 = "nonce_")
  in
  let nonce_params = List.filter_map (fun (id, _ty) ->
    if is_nonce_name id.name then Some id.name else None
  ) fn.fn_params in
  let key_params = List.filter_map (fun (id, ty) ->
    if is_secret (normalize_ty ty) && not (is_nonce_name id.name)
    then Some id.name else None
  ) fn.fn_params in
  let pure_key_params = key_params in
  (* Check 1: at least one secret param *)
  if key_params = [] then
    fail fn.fn_name.loc
      (Printf.sprintf "ind_cpa: '%s' has no secret<T> parameter — \
                       key/plaintext must be marked secret" name);
  (* Check 2: return type must be secret<T> *)
  let ret = normalize_ty fn.fn_ret in
  if not (is_secret ret) then
    fail fn.fn_name.loc
      (Printf.sprintf "ind_cpa: '%s' return type must be secret<T> — \
                       ciphertext must remain opaque (got %s)"
         name (format_ty ret));
  (* Check 3: no declassify of key params in body *)
  (match fn.fn_body with
   | Some body -> ind_cpa_scan_expr pure_key_params body
   | None -> ());
  (* Check 4: log as an explicit security assumption (visible in forge audit) *)
  let nonce_str = match nonce_params with
    | [] -> "none (name params 'nonce'/'nonce_*' to identify; use lin bindings at call sites)"
    | ns -> String.concat ", " ns ^ " (enforce single-use via lin bindings at call sites)"
  in
  let ctx = Printf.sprintf
    "ind_cpa: '%s' — keys: [%s], nonces: %s, ciphertext: %s"
    name
    (String.concat ", " pure_key_params)
    nonce_str
    (format_ty ret)
  in
  log_assume (PApp ({ name = "ind_cpa_secure"; loc = fn.fn_name.loc },
                    [PVar fn.fn_name]))
             (Some ctx) fn.fn_name.loc

let check_fn env fn =
  let sig_ = collect_fn_sig fn in
  (* Process function attributes *)
  let is_kernel    = List.exists (fun a -> a.attr_name = "kernel")    fn.fn_attrs in
  let is_device_fn = List.exists (fun a -> a.attr_name = "device")   fn.fn_attrs in
  let is_coalesced = List.exists (fun a -> a.attr_name = "coalesced") fn.fn_attrs in
  let is_ind_cpa   = List.exists (fun a -> a.attr_name = "ind_cpa")   fn.fn_attrs in
  let env = if is_kernel || is_device_fn then { env with is_gpu_fn = true } else env in
  let env = if is_coalesced then { env with coalesced_fn = true } else env in
  (* Inject GPU built-in variables for kernel functions.
     threadIdx_x/y/z are varying (per-thread); blockIdx/blockDim/gridDim are uniform. *)
  let env =
    if is_kernel || is_device_fn then begin
      let mk nm = { name = nm; loc = dummy_loc } in
      let varying_u32 = TQual (Varying, TPrim (TUint U32)) in
      let uniform_u32 = TPrim (TUint U32) in
      let e = env in
      let e = env_add_var e "threadIdx_x" varying_u32 Unr dummy_loc in
      let e = env_add_var e "threadIdx_y" varying_u32 Unr dummy_loc in
      let e = env_add_var e "threadIdx_z" varying_u32 Unr dummy_loc in
      let e = env_add_var e "blockIdx_x"  uniform_u32 Unr dummy_loc in
      let e = env_add_var e "blockIdx_y"  uniform_u32 Unr dummy_loc in
      let e = env_add_var e "blockIdx_z"  uniform_u32 Unr dummy_loc in
      let e = env_add_var e "blockDim_x"  uniform_u32 Unr dummy_loc in
      let e = env_add_var e "blockDim_y"  uniform_u32 Unr dummy_loc in
      let e = env_add_var e "blockDim_z"  uniform_u32 Unr dummy_loc in
      let e = env_add_var e "gridDim_x"   uniform_u32 Unr dummy_loc in
      let e = env_add_var e "gridDim_y"   uniform_u32 Unr dummy_loc in
      let e = env_add_var e "gridDim_z"   uniform_u32 Unr dummy_loc in
      (* Thread indices are in range: 0 <= threadIdx_x < blockDim_x, etc. *)
      let e = env_add_fact e (PBinop (Lt, PVar (mk "threadIdx_x"), PVar (mk "blockDim_x"))) in
      let e = env_add_fact e (PBinop (Lt, PVar (mk "threadIdx_y"), PVar (mk "blockDim_y"))) in
      let e = env_add_fact e (PBinop (Lt, PVar (mk "threadIdx_z"), PVar (mk "blockDim_z"))) in
      (* Block and grid dimensions are always positive (GPU launch invariant).
         This is critical for proving grid-stride loop termination:
         stride = blockDim_x * gridDim_x > 0 follows from both > 0. *)
      let e = env_add_fact e (PBinop (Gt, PVar (mk "blockDim_x"), PInt 0L)) in
      let e = env_add_fact e (PBinop (Gt, PVar (mk "blockDim_y"), PInt 0L)) in
      let e = env_add_fact e (PBinop (Gt, PVar (mk "blockDim_z"), PInt 0L)) in
      let e = env_add_fact e (PBinop (Gt, PVar (mk "gridDim_x"), PInt 0L)) in
      let e = env_add_fact e (PBinop (Gt, PVar (mk "gridDim_y"), PInt 0L)) in
      let e = env_add_fact e (PBinop (Gt, PVar (mk "gridDim_z"), PInt 0L)) in
      (* GPU intrinsic functions *)
      let mk_p n t = ({ name = n; loc = dummy_loc }, t) in
      let gpu_fn name params ret = {
        fs_name = name; fs_type_params = []; fs_generics = [];
        fs_params = params; fs_ret = ret;
        fs_requires = []; fs_ensures = []; fs_decreases = None;
      } in
      let u32 = TPrim (TUint U32) in
      let u64 = TPrim (TUint U64) in
      let _f32 = TPrim (TFloat F32) in
      (* Warp shuffles: shfl_down_sync(val, delta, width) -> val *)
      let e = env_add_fn e "shfl_down_sync"
        (gpu_fn "shfl_down_sync" [mk_p "val" u32; mk_p "delta" u32; mk_p "width" u32] u32) in
      let e = env_add_fn e "shfl_xor_sync"
        (gpu_fn "shfl_xor_sync" [mk_p "val" u32; mk_p "mask" u32; mk_p "width" u32] u32) in
      let e = env_add_fn e "shfl_up_sync"
        (gpu_fn "shfl_up_sync" [mk_p "val" u32; mk_p "delta" u32; mk_p "width" u32] u32) in
      (* Atomics: atom_add(ptr, val) -> old *)
      let e = env_add_fn e "atom_add"
        (gpu_fn "atom_add" [mk_p "ptr" (TRaw u64); mk_p "val" u64] u64) in
      let e = env_add_fn e "atom_cas"
        (gpu_fn "atom_cas" [mk_p "ptr" (TRaw u64); mk_p "val" u64] u64) in
      let e = env_add_fn e "atom_max"
        (gpu_fn "atom_max" [mk_p "ptr" (TRaw u64); mk_p "val" u64] u64) in
      let e = env_add_fn e "atom_min"
        (gpu_fn "atom_min" [mk_p "ptr" (TRaw u64); mk_p "val" u64] u64) in
      let e = env_add_fn e "atom_or"
        (gpu_fn "atom_or" [mk_p "ptr" (TRaw u64); mk_p "val" u64] u64) in
      let e = env_add_fn e "atom_xor"
        (gpu_fn "atom_xor" [mk_p "ptr" (TRaw u64); mk_p "val" u64] u64) in
      let e = env_add_fn e "atom_and"
        (gpu_fn "atom_and" [mk_p "ptr" (TRaw u64); mk_p "val" u64] u64) in
      let e = env_add_fn e "atom_sub"
        (gpu_fn "atom_sub" [mk_p "ptr" (TRaw u64); mk_p "val" u64] u64) in
      let e = env_add_fn e "atom_exch"
        (gpu_fn "atom_exch" [mk_p "ptr" (TRaw u64); mk_p "val" u64] u64) in
      (* Warp vote *)
      let e = env_add_fn e "ballot_sync"
        (gpu_fn "ballot_sync" [mk_p "pred" u64] u32) in
      (* Lane/warp ID *)
      let e = env_add_fn e "lane_id"
        (gpu_fn "lane_id" [] u32) in
      let e = env_add_fn e "warp_id"
        (gpu_fn "warp_id" [] u32) in
      (* Memory fences *)
      let unit_ty = TPrim TUnit in
      let e = env_add_fn e "threadfence"
        (gpu_fn "threadfence" [] unit_ty) in
      let e = env_add_fn e "threadfence_block"
        (gpu_fn "threadfence_block" [] unit_ty) in
      let e = env_add_fn e "threadfence_system"
        (gpu_fn "threadfence_system" [] unit_ty) in
      (* Async copy (SM_80+) *)
      let u8 = TPrim (TUint U8) in
      let e = env_add_fn e "cp_async_cg"
        (gpu_fn "cp_async_cg" [mk_p "dst" (TRaw u8); mk_p "src" (TRaw u8); mk_p "bytes" u64] unit_ty) in
      let e = env_add_fn e "cp_async_commit"
        (gpu_fn "cp_async_commit" [] unit_ty) in
      let e = env_add_fn e "cp_async_wait_group"
        (gpu_fn "cp_async_wait_group" [mk_p "n" u64] unit_ty) in
      (* Cooperative groups (SM_90+) *)
      let e = env_add_fn e "cluster_sync"
        (gpu_fn "cluster_sync" [] unit_ty) in
      let e = env_add_fn e "cluster_dim_x"
        (gpu_fn "cluster_dim_x" [] u64) in
      let e = env_add_fn e "cluster_rank"
        (gpu_fn "cluster_rank" [] u64) in
      let e = env_add_fn e "cluster_map_shared"
        (gpu_fn "cluster_map_shared" [mk_p "ptr" (TRaw u8); mk_p "rank" u64] (TRaw u8)) in
      (* FP16/BF16 conversions *)
      let u16 = TPrim (TUint U16) in
      let f32 = TPrim (TFloat F32) in
      let e = env_add_fn e "f32_to_fp16"
        (gpu_fn "f32_to_fp16" [mk_p "x" f32] u16) in
      let e = env_add_fn e "fp16_to_f32"
        (gpu_fn "fp16_to_f32" [mk_p "x" u16] f32) in
      let e = env_add_fn e "f32_to_bf16"
        (gpu_fn "f32_to_bf16" [mk_p "x" f32] u16) in
      let e = env_add_fn e "bf16_to_f32"
        (gpu_fn "bf16_to_f32" [mk_p "x" u16] f32) in
      (* FP16 arithmetic *)
      let e = env_add_fn e "fp16_add"
        (gpu_fn "fp16_add" [mk_p "a" u16; mk_p "b" u16] u16) in
      let e = env_add_fn e "fp16_sub"
        (gpu_fn "fp16_sub" [mk_p "a" u16; mk_p "b" u16] u16) in
      let e = env_add_fn e "fp16_mul"
        (gpu_fn "fp16_mul" [mk_p "a" u16; mk_p "b" u16] u16) in
      let e = env_add_fn e "fp16_fma"
        (gpu_fn "fp16_fma" [mk_p "a" u16; mk_p "b" u16; mk_p "c" u16] u16) in
      let e = env_add_fn e "fp16_neg"
        (gpu_fn "fp16_neg" [mk_p "a" u16] u16) in
      let e = env_add_fn e "fp16_abs"
        (gpu_fn "fp16_abs" [mk_p "a" u16] u16) in
      let e = env_add_fn e "fp16_max"
        (gpu_fn "fp16_max" [mk_p "a" u16; mk_p "b" u16] u16) in
      let e = env_add_fn e "fp16_min"
        (gpu_fn "fp16_min" [mk_p "a" u16; mk_p "b" u16] u16) in
      (* BF16 arithmetic *)
      let e = env_add_fn e "bf16_add"
        (gpu_fn "bf16_add" [mk_p "a" u16; mk_p "b" u16] u16) in
      let e = env_add_fn e "bf16_sub"
        (gpu_fn "bf16_sub" [mk_p "a" u16; mk_p "b" u16] u16) in
      let e = env_add_fn e "bf16_mul"
        (gpu_fn "bf16_mul" [mk_p "a" u16; mk_p "b" u16] u16) in
      let e = env_add_fn e "bf16_fma"
        (gpu_fn "bf16_fma" [mk_p "a" u16; mk_p "b" u16; mk_p "c" u16] u16) in
      let e = env_add_fn e "bf16_neg"
        (gpu_fn "bf16_neg" [mk_p "a" u16] u16) in
      e
    end else env
  in
  (* Add KNat/KConst generic params as value variables in the body env.
     They are treated as leading parameters — passed explicitly by callers. *)
  let env_with_generics = List.fold_left (fun e (id, k) ->
    match k with
    | KNat       -> env_add_var e id.name (TPrim (TUint U64)) Unr id.loc
    | KConst t   -> env_add_var e id.name (normalize_ty t) Unr id.loc
    | KType      -> e
    | KBounded _ -> e
  ) { env with current_fn = Some sig_ } fn.fn_generics in
  (* Build env with params in scope — normalize types so secret<T> → TSecret t *)
  let env' = List.fold_left (fun e (id, ty) ->
    env_add_var e id.name (normalize_ty ty) Unr id.loc
  ) env_with_generics fn.fn_params in
  (* Extract refinement predicates from param types as known facts *)
  let env' = List.fold_left (fun e (id, ty) ->
    match normalize_ty ty with
    | TRefined (_, binder, pred) ->
        let fact = subst_pred [(binder.name, PVar { name = id.name; loc = id.loc })] pred in
        env_add_fact e fact
    | _ -> e
  ) env' fn.fn_params in
  (* Inject struct invariants for struct-typed parameters.
     If param `p: S` and S has invariant `pred` with fields f1, f2, ...,
     inject `pred` with fields substituted as `p.f1`, `p.f2`, etc.
     This lets the function body rely on struct invariants without explicit requires. *)
  let env' = List.fold_left (fun e (id, ty) ->
    match normalize_ty ty with
    | TNamed (s_id, []) ->
        (match List.assoc_opt s_id.name e.structs with
         | Some sd when sd.sd_invars <> [] ->
             let field_names = List.map (fun (fid, _) -> fid.name) sd.sd_fields in
             let subst = List.map (fun fname ->
               (fname, PField (PVar id, fname))
             ) field_names in
             List.fold_left (fun e2 inv ->
               env_add_fact e2 (subst_pred subst inv)
             ) e sd.sd_invars
         | _ -> e)
    | _ -> e
  ) env' fn.fn_params in
  (* Add requires as known facts *)
  let env' = List.fold_left env_add_fact env' fn.fn_requires in
  (* Init-snapshot for span params: enables old(s[i]) in postconditions.
     For each span<T> param p, add __p_init with:
       forall k, __p_init[k] == p[k]   (element equality at entry)
       __p_init.len == p.len            (length equality at entry)
     env_array_write renames p→__p_pN in these facts, keeping the chain intact. *)
  let env' = List.fold_left (fun e (id, ty) ->
    match normalize_ty ty with
    | TSpan _ as span_ty ->
        let init_name = "__" ^ id.name ^ "_init" in
        let k_name = Printf.sprintf "__oi_k_%d" !fresh_counter in
        incr fresh_counter;
        let k_id = { name = k_name; loc = id.loc } in
        let init_var = PVar { name = init_name; loc = id.loc } in
        let param_var = PVar id in
        let eq_fact = PForall (k_id, TPrim (TUint U64),
          PBinop (Eq, PIndex (init_var, PVar k_id), PIndex (param_var, PVar k_id))) in
        let len_fact = PBinop (Eq, PField (init_var, "len"), PField (param_var, "len")) in
        let e = env_add_var e init_name span_ty Unr id.loc in
        let e = env_add_fact e eq_fact in
        env_add_fact e len_fact
    | _ -> e
  ) env' fn.fn_params in
  (* Init-snapshot for refmut<Struct> params: enables old() in postconditions.
     For each refmut<S> param c, add __c_init__field constants equal to c__field
     at function entry. The SMT encoder handles old(x.f) as __x_init__f.
     Field mutations (env_add_fact with PField) add new facts but the init
     constants remain unchanged, so old() continues to refer to entry values. *)
  let env' = List.fold_left (fun e (id, ty) ->
    match normalize_ty ty with
    | TRefMut (TNamed (s_id, [])) ->
        (match List.assoc_opt s_id.name e.structs with
         | Some sd ->
             List.fold_left (fun e2 (fid, fty) ->
               let init_name = "__" ^ id.name ^ "_init__" ^ fid.name in
               let field_pred = PField (PVar id, fid.name) in
               let init_var   = PVar { name = init_name; loc = id.loc } in
               let e3 = env_add_var e2 init_name (normalize_ty fty) Unr id.loc in
               env_add_fact e3 (PBinop (Eq, init_var, field_pred))
             ) e sd.sd_fields
         | None -> e)
    | _ -> e
  ) env' fn.fn_params in
  (* Init-snapshot for span<Struct> params: enables old(s[i].field) in postconditions.
     For each span<S> param p, and for each field f of S, add __p_init__f of type
     span<f_ty> with forall k, __p_init__f[k] == p[k].f.
     The SMT encoder handles old(p[i].f) as (select __p_init__f i). *)
  let env' = List.fold_left (fun e (id, ty) ->
    match normalize_ty ty with
    | TSpan (TNamed (s_id, [])) ->
        (match List.assoc_opt s_id.name e.structs with
         | Some sd ->
             List.fold_left (fun e2 (fid, fty) ->
               let arr_name = "__" ^ id.name ^ "_init__" ^ fid.name in
               let k_name = Printf.sprintf "__oi_k_%d" !fresh_counter in
               incr fresh_counter;
               let k_id = { name = k_name; loc = id.loc } in
               let arr_var   = PVar { name = arr_name; loc = id.loc } in
               let param_var = PVar id in
               let elem_field = PField (PIndex (param_var, PVar k_id), fid.name) in
               let eq_fact = PForall (k_id, TPrim (TUint U64),
                 PBinop (Eq, PIndex (arr_var, PVar k_id), elem_field)) in
               let e3 = env_add_var e2 arr_name (TSpan (normalize_ty fty)) Unr id.loc in
               env_add_fact e3 eq_fact
             ) e sd.sd_fields
         | None -> e)
    | _ -> e
  ) env' fn.fn_params in
  (* Termination measure(s) must be non-negative at function entry *)
  (match fn.fn_decreases with
   | Some (PLex ms) ->
       List.iter (fun m ->
         add_obligation (PBinop (Ge, m, PInt 0L))
           (OTermination fn.fn_name.name) fn.fn_name.loc env'
       ) ms
   | Some measure ->
       add_obligation (PBinop (Ge, measure, PInt 0L))
         (OTermination fn.fn_name.name) fn.fn_name.loc env'
   | None -> ());
  (* Check body — use sig_.fs_ret (normalized) for expected_ty and type checks *)
  let env' = { env' with expected_ty = Some sig_.fs_ret } in
  (match fn.fn_body with
   | None -> ()  (* extern — no body to check *)
   | Some body ->
       let body_ty = check_expr env' body in
       if not (ty_compatible body_ty sig_.fs_ret) then
         fail fn.fn_name.loc
           (Printf.sprintf "function '%s' body type %s doesn't match declared return type %s"
             fn.fn_name.name (format_ty body_ty) (format_ty sig_.fs_ret));
       (* Post-body env carries loop postconditions, SSA-assigned values, etc. *)
       let body_env = expr_final_env env' body in
       (* Inject recursive self-call postconditions as induction hypotheses.
          For well-founded recursive functions (with decreases), any `let x = fn(args)`
          recursive call within the body is assumed to satisfy the function's own
          postconditions with args substituted.  This lets Z3 prove postconditions that
          require the IH — e.g. max_array_rec result >= all elements, count_le result <= n.
          Sound because: the decreases clause guarantees termination, so strong induction
          applies — the postcondition holds for smaller inputs by hypothesis. *)
       let body_env =
         if sig_.fs_ensures = [] then body_env
         else begin
           let rec inject_rec env_in e =
             match e.expr_desc with
             | EBlock (stmts, trailing) ->
                 let env' = List.fold_left (fun acc stmt ->
                   match stmt.stmt_desc with
                   | SLet (name, _, rhs, _) ->
                       (match rhs.expr_desc with
                        | ECall ({ expr_desc = EVar fn_id; _ }, call_args)
                            when fn_id.name = fn.fn_name.name &&
                                 List.length sig_.fs_params = List.length call_args ->
                            let acc' = env_add_var acc name.name sig_.fs_ret Unr stmt.stmt_loc in
                            let arg_subst = List.map2 (fun (pid, _) arg ->
                              (pid.name, expr_to_pred_simple arg)
                            ) sig_.fs_params call_args in
                            let result_subst = ("result", PVar name) :: arg_subst in
                            List.fold_left (fun e ens ->
                              env_add_fact e (subst_pred result_subst ens)
                            ) acc' sig_.fs_ensures
                        | _ -> acc)
                   | _ -> acc
                 ) env_in stmts in
                 (match trailing with Some t -> inject_rec env' t | None -> env')
             | EIf (_, then_e, else_opt) ->
                 let e1 = inject_rec env_in then_e in
                 (match else_opt with Some el -> inject_rec e1 el | None -> e1)
             | _ -> env_in
           in
           inject_rec body_env body
         end
       in
       (* result pred: trailing expression of block, or whole body for simple exprs.
          For trailing ECall, inject callee postconditions into body_env so the
          caller's postcondition check can see them (mirrors the SLet injection). *)
       let inject_trailing_call base_env fn_name_str call_args call_loc =
         let call_pred = PVar { name = "__ret_call"; loc = call_loc } in
         (* Register __ret_call in pc_vars with the correct return type so Z3
            declares it with the right sort (Bool, not Int) in Int-mode queries. *)
         let enrich_with ensures params all_args ret_ty env_in =
           let env_in = env_add_var env_in "__ret_call" ret_ty Unr call_loc in
           if ensures = [] then env_in
           else if List.length params <> List.length all_args then env_in
           else begin
             let arg_subst = List.map2 (fun (pid, _) arg ->
               (pid.name, expr_to_pred_simple arg)
             ) params all_args in
             let result_subst = ("result", call_pred) :: arg_subst in
             List.fold_left (fun e ens ->
               env_add_fact e (subst_pred result_subst ens)
             ) env_in ensures
           end
         in
         let enriched =
           match env_lookup_fn base_env fn_name_str with
           | Some sig_ ->
               enrich_with sig_.fs_ensures sig_.fs_params call_args sig_.fs_ret base_env
           | None ->
               (* fn_name_str may be a variable of fn-pointer type with ensures *)
               (match env_lookup_var base_env fn_name_str with
                | Some { vi_ty = TFn fty; _ } ->
                    enrich_with fty.ensures fty.params call_args fty.ret base_env
                | _ -> base_env)
         in
         (call_pred, enriched)
       in
       (* Inject cast range facts into env when trailing expr is a cast *)
       let inject_trailing_cast base_env cast_expr =
         let ret_p = expr_to_pred_simple cast_expr in
         let enriched = match cast_expr.expr_desc with
           | ECast (inner, _) ->
               let src_ty = match inner.expr_ty with Some t -> t | None -> TPrim TUnit in
               (match src_ty with
                | TPrim (TUint U8)  -> env_add_fact base_env (PBinop (Le, ret_p, PInt 255L))
                | TPrim (TUint U16) -> env_add_fact base_env (PBinop (Le, ret_p, PInt 65535L))
                | TPrim (TUint U32) -> env_add_fact base_env (PBinop (Le, ret_p, PInt 4294967295L))
                | _ -> base_env)
           | _ -> base_env
         in
         (ret_p, enriched)
       in
       let ret_pred, proof_env = match body.expr_desc with
         | EBlock (_, Some ret) ->
             (match ret.expr_desc with
              | ECall ({ expr_desc = EVar fn_id; _ }, call_args) ->
                  inject_trailing_call body_env fn_id.name call_args ret.expr_loc
              | ECast _ -> inject_trailing_cast body_env ret
              | _ -> (expr_to_pred_simple ret, body_env))
         | ECast _ -> inject_trailing_cast body_env body
         | _ -> (expr_to_pred_simple body, body_env)
       in
       (* Generate postcondition obligations using the (possibly enriched) env *)
       List.iter (fun ens ->
         let subst = [("result", ret_pred)] in
         let ob_pred = subst_pred subst ens in
         add_obligation ob_pred (OPostcondition fn.fn_name.name)
           fn.fn_name.loc proof_env
       ) fn.fn_ensures);
  (* IND-CPA structural verification — runs after body typecheck *)
  if is_ind_cpa then check_ind_cpa fn

let rec check_item env item =
  match item.item_desc with
  | IFn fn ->
      let sig_ = collect_fn_sig fn in
      let env' = env_add_fn env fn.fn_name.name sig_ in
      check_fn env' fn;
      env'
  | IConst (name, ty, expr) ->
      let ty = normalize_ty ty in
      let actual_ty = check_expr env expr in
      if not (ty_compatible actual_ty ty) then
        fail name.loc (Printf.sprintf "const '%s': declared type %s doesn't match value type %s"
          name.name (format_ty ty) (format_ty actual_ty));
      (* Add const value as a proof fact so Z3 knows its concrete value.
         e.g. `const A_TILE_BYTES: u64 = 1024u64;` injects
         fact: A_TILE_BYTES == 1024  into all subsequent proof queries. *)
      let env1 = env_add_var env name.name ty Unr name.loc in
      let val_pred = expr_to_pred_simple expr in
      env_add_fact env1 (PBinop (Eq, PVar name, val_pred))
  | IType td ->
      (* Register in global alias table so normalize_ty can unfold it *)
      type_aliases := (td.td_name.name, td.td_ty) :: !type_aliases;
      { env with types = (td.td_name.name, td.td_ty) :: env.types }
  | IStruct sd ->
      { env with structs = (sd.sd_name.name, sd) :: env.structs }
  | IEnum ed  ->
      (* Register the enum type *)
      let env = { env with enums = (ed.ed_name.name, ed) :: env.enums } in
      (* Register each variant as a constructor function in the fn table.
         For generic enums (ed_params ≠ []), the return type carries the type
         parameters: Option<T>.  Callers infer the concrete type from arguments. *)
      let type_param_names = List.map (fun (p, _) -> p.name) ed.ed_params in
      let enum_ty = TNamed (ed.ed_name,
        List.map (fun (p, _) -> TNamed (p, [])) ed.ed_params) in
      List.fold_left (fun e (vname, vfields) ->
        let params = List.mapi (fun i t ->
          ({ name = Printf.sprintf "_v%d" i; loc = vname.loc }, t)
        ) vfields in
        let sig_ = {
          fs_name        = vname.name;
          fs_type_params = type_param_names;
          fs_generics    = [];
          fs_params      = params;
          fs_ret         = enum_ty;
          fs_requires    = [];
          fs_ensures     = [];
          fs_decreases   = None;
        } in
        env_add_fn e vname.name sig_
      ) env ed.ed_variants
  | ITrait td ->
      (* Register the trait definition; no code generated *)
      { env with traits = (td.tr_name.name, td) :: env.traits }
  | IImpl im  ->
      let ty_name = mangle_ty_name (normalize_ty im.im_ty) in
      let prefix = match im.im_trait with
        | None           -> ty_name ^ "__"
        | Some trait_id  -> ty_name ^ "__" ^ trait_id.name ^ "__"
      in
      (* Register the impl in the impls registry *)
      let env = match im.im_trait with
        | None -> env
        | Some trait_id -> env_add_impl env ty_name trait_id.name
      in
      (* Register associated types *)
      let trait_name = match im.im_trait with Some id -> id.name | None -> "" in
      let env = List.fold_left (fun e iat ->
        env_add_assoc_ty e ty_name trait_name iat.iat_name.name (normalize_ty iat.iat_ty)
      ) env im.im_assoc_tys in
      (* Set self_ty for method body checking *)
      let env_with_self = { env with self_ty = Some im.im_ty } in
      (* Build type-param substitution for generic impl types, e.g. impl Pair<u64>:
         look up the struct/enum definition to find generic param names, then build
         a mapping from param names to the concrete types in im_ty. *)
      let ty_param_subst =
        match im.im_ty with
        | TNamed (base_id, concrete_args) when concrete_args <> [] ->
            let param_names =
              (match List.assoc_opt base_id.name env.structs with
               | Some sd -> List.map (fun (p, _) -> p.name) sd.sd_params
               | None ->
                   match List.assoc_opt base_id.name env.enums with
                   | Some ed -> List.map (fun (p, _) -> p.name) ed.ed_params
                   | None -> [])
            in
            if List.length param_names = List.length concrete_args then
              List.combine param_names concrete_args
            else []
        | _ -> []
      in
      let apply_ty_subst t = if ty_param_subst = [] then t else subst_ty ty_param_subst t in
      let env2 = List.fold_left (fun e item ->
        match item.item_desc with
        | IFn fn ->
            let mangled_name = prefix ^ fn.fn_name.name in
            (* Resolve Self and apply generic type-param substitution *)
            let resolved_params = List.map (fun (id, t) ->
              (id, apply_ty_subst (resolve_self env_with_self t))) fn.fn_params in
            let resolved_ret = apply_ty_subst (resolve_self env_with_self fn.fn_ret) in
            (* requires/ensures are pred expressions — type-param substitution not needed *)
            let _ = fn.fn_requires in
            let mangled_fn = { fn with fn_name = { fn.fn_name with name = mangled_name };
                                       fn_params = resolved_params;
                                       fn_ret    = resolved_ret } in
            check_fn e mangled_fn;
            let sig_ = collect_fn_sig mangled_fn in
            env_add_fn e mangled_name sig_
        | _ -> check_item e item
      ) env im.im_items in
      (* Synthesize default methods: for each default method in the trait that
         the impl doesn't override, create a concrete fn_def and register it.
         Each synthesized fn's signature is added to the environment so that
         later items (e.g. main) can call it. *)
      let env3 = match im.im_trait with
        | None -> env2
        | Some trait_id ->
            (match List.assoc_opt trait_id.name env2.traits with
             | None -> env2
             | Some tr ->
                 let provided = List.filter_map (fun item ->
                   match item.item_desc with IFn fn -> Some fn.fn_name.name | _ -> None
                 ) im.im_items in
                 List.fold_left (fun e (mname, fty, default_body_opt) ->
                   match default_body_opt with
                   | None -> e  (* abstract method — impl must provide it *)
                   | Some _ when List.mem mname.name provided -> e
                   | Some default_body ->
                       let mangled_name = prefix ^ mname.name in
                       let resolved_params = List.map (fun (id, t) ->
                         (id, resolve_self env_with_self t)
                       ) fty.params in
                       let resolved_ret = resolve_self env_with_self fty.ret in
                       let synth_fn = {
                         fn_name      = { mname with name = mangled_name };
                         fn_generics  = [];
                         fn_params    = resolved_params;
                         fn_ret       = resolved_ret;
                         fn_requires  = fty.requires;
                         fn_ensures   = fty.ensures;
                         fn_decreases = None;
                         fn_body      = Some default_body;
                         fn_attrs     = [];
                       } in
                       check_fn e synth_fn;
                       let sig_ = collect_fn_sig synth_fn in
                       let synth_item = { item_desc = IFn synth_fn;
                                          item_loc   = mname.loc } in
                       synthesized_items := synth_item :: !synthesized_items;
                       env_add_fn e mangled_name sig_
                 ) env2 tr.tr_methods)
      in
      env3
  | IExtern ex ->
      (match ex.ex_ty with
       | TFn fty ->
           let sig_ = {
             fs_name        = ex.ex_name.name;
             fs_type_params = [];
             fs_generics    = [];
             fs_params      = fty.params;
             fs_ret         = fty.ret;
             fs_requires    = fty.requires;
             fs_ensures     = fty.ensures;
             fs_decreases   = None;
           } in
           env_add_fn env ex.ex_name.name sig_
       | _ -> env)
  | IUse _ -> env

(* ------------------------------------------------------------------ *)
(* Discharge all obligations                                            *)
(* ------------------------------------------------------------------ *)

type discharge_summary = {
  ds_total:     int;
  ds_tier1:     int;
  ds_tier2:     int;
  ds_tier3:     int;
  ds_failed:    int;
  ds_vacuous:   int;   (* obligations blocked due to contradictory context *)
  ds_failures:  proof_error list;
}

let discharge_all (obs : obligation list) (prog_env : env) =
  let total   = List.length obs in
  let tier1   = ref 0 in
  let tier2   = ref 0 in
  let tier3   = ref 0 in
  let failed  = ref 0 in
  let vacuous = ref 0 in
  let failures = ref [] in

  List.iter (fun ob ->
    let ctx = {
      pc_vars    = ob.ob_ctx;
      pc_assumes = ob.ob_assumes @ prog_env.proof_ctx.pc_assumes;
      pc_lemmas  = !proved_lemmas;
    } in
    match discharge ctx ob with
    | Proved Tier1_SMT ->
        incr tier1;
        Printf.printf "  ✓ [SMT]    %s:%d %s\n%!"
          ob.ob_loc.file ob.ob_loc.line
          (format_obligation_kind ob.ob_kind)
    | Proved Tier2_Guided ->
        incr tier2;
        Printf.printf "  ✓ [guided] %s:%d %s\n%!"
          ob.ob_loc.file ob.ob_loc.line
          (format_obligation_kind ob.ob_kind)
    | Proved Tier3_Manual ->
        incr tier3;
        Printf.printf "  ✓ [manual] %s:%d %s\n%!"
          ob.ob_loc.file ob.ob_loc.line
          (format_obligation_kind ob.ob_kind)
    | NeedsHint hint ->
        incr failed;
        let pe = {
          pe_loc     = ob.ob_loc;
          pe_kind    = ob.ob_kind;
          pe_pred    = ob.ob_pred;
          pe_hint    = Some hint;
          pe_message = "cannot discharge automatically";
        } in
        failures := pe :: !failures;
        Printf.printf "  ✗ %s\n%!" (format_error pe)
    | Unproved msg ->
        let is_vac = String.length msg >= 7 &&
                     String.sub msg 0 7 = "vacuous" in
        if is_vac then incr vacuous else incr failed;
        let pe = {
          pe_loc     = ob.ob_loc;
          pe_kind    = ob.ob_kind;
          pe_pred    = ob.ob_pred;
          pe_hint    = None;
          pe_message = msg;
        } in
        failures := pe :: !failures;
        Printf.printf "  %s %s\n%!"
          (if is_vac then "  ⚠ [vacuous]" else "✗")
          (format_error pe)
  ) obs;

  {
    ds_total    = total;
    ds_tier1    = !tier1;
    ds_tier2    = !tier2;
    ds_tier3    = !tier3;
    ds_failed   = !failed;
    ds_vacuous  = !vacuous;
    ds_failures = List.rev !failures;
  }

(* ------------------------------------------------------------------ *)
(* Mutual recursion — Tarjan's SCC on the call graph                   *)
(* ------------------------------------------------------------------ *)

(* Walk a function body and collect direct callees by name. *)
let collect_direct_calls (fn : fn_def) : string list =
  let calls : string list ref = ref [] in
  let rec scan_expr e =
    match e.expr_desc with
    | ECall ({ expr_desc = EVar id; _ }, args) ->
        calls := id.name :: !calls;
        List.iter scan_expr args
    | ECall (f, args) ->
        scan_expr f; List.iter scan_expr args
    | EBinop (_, l, r) -> scan_expr l; scan_expr r
    | EUnop (_, e)     -> scan_expr e
    | EBlock (stmts, ret) ->
        List.iter scan_stmt stmts;
        (match ret with Some e -> scan_expr e | None -> ())
    | EIf (c, t, Some e) -> scan_expr c; scan_expr t; scan_expr e
    | EIf (c, t, None)   -> scan_expr c; scan_expr t
    | EMatch (s, arms)   ->
        scan_expr s; List.iter (fun arm -> scan_expr arm.body) arms
    | EIndex (a, i)  -> scan_expr a; scan_expr i
    | EField (e, _)  -> scan_expr e
    | EAssign (l, r) -> scan_expr l; scan_expr r
    | ERef e | ERefMut e | EDeref e -> scan_expr e
    | ECast (e, _)   -> scan_expr e
    | EStruct (_, fs)    -> List.iter (fun (_, e) -> scan_expr e) fs
    | EArrayLit elems    -> List.iter scan_expr elems
    | EArrayRepeat (v,n)     -> scan_expr v; scan_expr n
    | ETuple elems           -> List.iter scan_expr elems
    | EField_n (e, _)        -> scan_expr e
    | ESubspan (e2, lo, hi)  -> scan_expr e2; scan_expr lo; scan_expr hi
    | ERange (lo, hi)        -> scan_expr lo; scan_expr hi
    | _ -> ()
  and scan_stmt s =
    match s.stmt_desc with
    | SLet (_, _, e, _) | SGhost (_, _, e) | SGhostAssign (_, e) -> scan_expr e
    | SExpr e           -> scan_expr e
    | SReturn (Some e)  -> scan_expr e
    | SWhile (c, _, _, body) -> scan_expr c; List.iter scan_stmt body
    | SFor (_, e, _, _, body) -> scan_expr e; List.iter scan_stmt body
    | _ -> ()
  in
  (match fn.fn_body with Some body -> scan_expr body | None -> ());
  List.sort_uniq String.compare !calls

(* Tarjan's strongly connected components (iterative-friendly via recursive OCaml).
   Returns a list of SCCs; each SCC is a list of function names.
   SCCs of size > 1 are mutual recursion groups. *)
let tarjan_sccs (fns : fn_def list) : string list list =
  let fn_names = List.map (fun fn -> fn.fn_name.name) fns in
  (* Adjacency: only edges to other top-level functions in this program *)
  let adj = List.map (fun fn ->
    (fn.fn_name.name,
     List.filter (fun n -> List.mem n fn_names) (collect_direct_calls fn))
  ) fns in
  let index_cnt = ref 0 in
  let index   : (string, int) Hashtbl.t = Hashtbl.create 16 in
  let lowlink : (string, int) Hashtbl.t = Hashtbl.create 16 in
  let on_stack: (string, bool) Hashtbl.t = Hashtbl.create 16 in
  let stack = ref [] in
  let sccs  = ref [] in
  let rec strongconnect v =
    Hashtbl.add index   v !index_cnt;
    Hashtbl.add lowlink v !index_cnt;
    incr index_cnt;
    stack := v :: !stack;
    Hashtbl.add on_stack v true;
    let neighbors = try List.assoc v adj with Not_found -> [] in
    List.iter (fun w ->
      if not (Hashtbl.mem index w) then begin
        strongconnect w;
        let ll_v = Hashtbl.find lowlink v in
        let ll_w = Hashtbl.find lowlink w in
        Hashtbl.replace lowlink v (min ll_v ll_w)
      end else if (try Hashtbl.find on_stack w with Not_found -> false) then begin
        let ll_v = Hashtbl.find lowlink v in
        let idx_w = Hashtbl.find index w in
        Hashtbl.replace lowlink v (min ll_v idx_w)
      end
    ) neighbors;
    if Hashtbl.find lowlink v = Hashtbl.find index v then begin
      let scc = ref [] in
      let go  = ref true in
      while !go do
        match !stack with
        | [] -> go := false
        | w :: rest ->
            stack := rest;
            Hashtbl.replace on_stack w false;
            scc := w :: !scc;
            if w = v then go := false
      done;
      sccs := !scc :: !sccs
    end
  in
  List.iter (fun name ->
    if not (Hashtbl.mem index name) then strongconnect name
  ) fn_names;
  !sccs

(* ------------------------------------------------------------------ *)
(* Main entry point                                                     *)
(* ------------------------------------------------------------------ *)

let typecheck_program prog =
  errors := [];
  obligations := [];
  synthesized_items := [];  (* reset default-method synthesis list *)
  proved_lemmas := [];    (* reset per-compilation lemma registry *)
  fresh_counter := 0;     (* reset SSA name counter *)
  type_aliases  := [];    (* reset type alias registry *)
  reset_assume_log ();    (* reset proof assumption audit log *)

  (* First pass: collect all top-level function signatures
     so that mutual recursion and forward references work *)
  let env = List.fold_left (fun e item ->
    match item.item_desc with
    | IFn fn ->
        env_add_fn e fn.fn_name.name (collect_fn_sig fn)
    | IExtern ex ->
        (match ex.ex_ty with
         | TFn fty ->
             let sig_ = {
               fs_name        = ex.ex_name.name;
               fs_type_params = [];
               fs_generics    = [];
               fs_params      = fty.params;
               fs_ret         = fty.ret;
               fs_requires    = fty.requires;
               fs_ensures     = fty.ensures;
               fs_decreases   = None;
             } in
             env_add_fn e ex.ex_name.name sig_
         | _ -> e)
    | _ -> e
  ) empty_env prog.prog_items in

  (* Mutual recursion check via Tarjan SCC.
     Every function in a cycle of size > 1 must have a decreases: clause. *)
  let all_fns = List.filter_map (fun item ->
    match item.item_desc with IFn fn -> Some fn | _ -> None
  ) prog.prog_items in
  let sccs = tarjan_sccs all_fns in
  List.iter (fun scc ->
    if List.length scc > 1 then
      List.iter (fun fn_name ->
        match List.find_opt (fun fn -> fn.fn_name.name = fn_name) all_fns with
        | Some fn when fn.fn_decreases = None ->
            report_error (TypeError (fn.fn_name.loc,
              Printf.sprintf
                "'%s' is part of a mutual recursion cycle (%s) — add a 'decreases:' clause"
                fn_name (String.concat ", " scc)))
        | _ -> ()
      ) scc
  ) sccs;

  (* Second pass: full type checking + obligation generation *)
  let _final_env = List.fold_left check_item env prog.prog_items in

  let tc_errors = !errors in
  let obs = List.rev !obligations in
  let extra = !synthesized_items in

  (tc_errors, obs, extra)
