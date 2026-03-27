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
}

let empty_env = {
  vars               = [];
  fns                = [];
  types              = [];
  structs            = [];
  enums              = [];
  current_fn         = None;
  expected_ty        = None;
  proof_ctx          = empty_ctx;
  is_gpu_fn          = false;
  after_barrier      = false;
  in_varying_branch  = false;
  coalesced_fn       = false;
  scc_id             = None;
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
let rec normalize_ty = function
  | TNamed ({name="secret"; _}, [t]) -> TSecret (normalize_ty t)
  | TRef t -> TRef (normalize_ty t)
  | TRefMut t -> TRefMut (normalize_ty t)
  | TOwn t -> TOwn (normalize_ty t)
  | TRaw t -> TRaw (normalize_ty t)
  | TArray (t, e) -> TArray (normalize_ty t, e)
  | TSlice t -> TSlice (normalize_ty t)
  | TNamed (id, args) -> TNamed (id, List.map normalize_ty args)
  | TSpan t -> TSpan (normalize_ty t)
  | TShared (t, e) -> TShared (normalize_ty t, e)
  | TQual (q, t) -> TQual (q, normalize_ty t)
  | TSecret t -> TSecret (normalize_ty t)
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
  let t1 = strip_qual t1 and t2 = strip_qual t2 in
  match t1, t2 with
  | TPrim p1, TPrim p2 -> p1 = p2
  | TRefined (p1, _, _), TRefined (p2, _, _) -> p1 = p2
  | TRefined (p1, _, _), TPrim p2 -> p1 = p2
  | TPrim p1, TRefined (p2, _, _) -> p1 = p2
  | TRef t1, TRef t2 -> ty_eq t1 t2
  | TRefMut t1, TRefMut t2 -> ty_eq t1 t2
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

let add_obligation pred kind loc ctx =
  obligations := {
    ob_pred    = pred;
    ob_kind    = kind;
    ob_loc     = loc;
    ob_ctx     = ctx.proof_ctx.pc_vars;
    ob_assumes = ctx.proof_ctx.pc_assumes;
    ob_status  = Pending;
  } :: !obligations

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
  | PAs (inner, _)      -> pattern_to_cond_pred scrut_pred inner
  | POr  (p1, p2)       ->
      PBinop (Or, pattern_to_cond_pred scrut_pred p1,
                  pattern_to_cond_pred scrut_pred p2)
  | PTuple _ -> PBool true

(* Translate expression to pred for obligation generation — defined first,
   used by check_division / check_bounds / check_preconditions below *)
let rec expr_to_pred_simple e =
  match e.expr_desc with
  | ELit (LInt (n, _))  -> PInt n
  | ELit (LBool b)      -> PBool b
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
  | EStruct (name, inits) ->
      PStruct (name.name,
        List.map (fun (fid, fe) -> (fid.name, expr_to_pred_simple fe)) inits)
  | EIndex (arr, idx)   -> PIndex (expr_to_pred_simple arr, expr_to_pred_simple idx)
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

(* ------------------------------------------------------------------ *)
(* Post-expression environment — for postcondition checking            *)
(*                                                                      *)
(* Mirror check_stmt/check_stmts without generating proof obligations. *)
(* Called in check_fn AFTER check_expr to get post-body facts so       *)
(* postconditions can be checked against post-loop state.               *)
(* ------------------------------------------------------------------ *)

(* Collect all directly-assigned variable names in a stmt list.
   Used to strip stale pre-loop facts from post-loop env. *)
let rec collect_assigned_vars stmts =
  List.concat_map (fun s -> match s.stmt_desc with
    | SExpr { expr_desc = EAssign ({ expr_desc = EVar v; _ }, _); _ } -> [v.name]
    | SWhile (_, _, _, body) | SFor (_, _, _, body) ->
        collect_assigned_vars body
    | _ -> []) stmts

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

let rec expr_final_env env expr =
  match expr.expr_desc with
  | EBlock (stmts, trailing) ->
      let env' = stmts_final_env env stmts in
      (match trailing with Some e -> expr_final_env env' e | None -> env')
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
      (match rhs.expr_desc with
       | EStruct (_, fields) ->
           List.fold_left (fun e (fid, fexpr) ->
             env_add_fact e (PBinop (Eq,
               PField (PVar name, fid.name),
               expr_to_pred_simple fexpr))
           ) env'' fields
       | _ -> env'')
  | SExpr e ->
      (match e.expr_desc with
       | EAssign (lhs, rhs) ->
           (match lhs.expr_desc with
            | EVar v -> env_assign_var env v (expr_to_pred_simple rhs)
            | _      -> expr_final_env env e)
       | _ -> expr_final_env env e)
  | SWhile (cond, inv, _, body) ->
      (* Strip stale pre-loop value equalities for loop-modified vars *)
      let modified = collect_assigned_vars body in
      let env_clean = strip_stale_facts env modified in
      let cond_pred = expr_to_pred_simple cond in
      let env_exit = env_add_fact env_clean (PUnop (Not, cond_pred)) in
      (match inv with Some p -> env_add_fact env_exit p | None -> env_exit)
  | SFor (name, iter, _, _body) ->
      let elem_ty = match iter.expr_ty with
        | Some (TSlice t | TArray (t, _)) -> t | _ -> TPrim (TUint U64)
      in
      env_add_var env name.name elem_ty Unr stmt.stmt_loc
  | SReturn _ | SBreak | SContinue -> env

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

let format_obligation_kind = function
  | OPrecondition f  -> "precondition of " ^ f
  | OPostcondition f -> "postcondition of " ^ f
  | OBoundsCheck a   -> "bounds check: " ^ a
  | ONoOverflow op   -> "no overflow: " ^ op
  | OTermination f   -> "termination: " ^ f
  | OLinear v        -> "linear: " ^ v
  | OInvariant i     -> "invariant: " ^ i

(* ------------------------------------------------------------------ *)
(* Type checking expressions                                            *)
(* ------------------------------------------------------------------ *)

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
  | ELit (LStr _)  -> TSlice (TPrim (TUint U8))

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
      let rt = check_expr env rhs in
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
           (* Shared memory: if before barrier, require ownership *)
           let idx_pred = expr_to_pred_simple idx in
           if not env.after_barrier then begin
             (* Thread i owns smem[i*stride .. (i+1)*stride) *)
             (* Generate obligation: threadIdx_x * stride <= idx < (threadIdx_x+1)*stride *)
             (match len_expr with
              | Some n ->
                  let stride = PBinop (Div, expr_to_pred_simple n,
                    PVar { name = "blockDim_x"; loc = expr.expr_loc }) in
                  let tidx = PVar { name = "threadIdx_x"; loc = expr.expr_loc } in
                  let lo = PBinop (Mul, tidx, stride) in
                  let hi = PBinop (Mul, PBinop (Add, tidx, PInt 1L), stride) in
                  let ob = PBinop (And,
                    PBinop (Le, lo, idx_pred),
                    PBinop (Lt, idx_pred, hi)) in
                  add_obligation ob (OInvariant "shared_ownership") expr.expr_loc env
              | None -> ())
           end;
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
        (* ---- Method call dispatch: obj.method(args) → TypeName__method(obj,args) ---- *)
        | EField (obj, method_name) ->
            let obj_ty = check_expr env obj in
            let type_name = match base_ty obj_ty with
              | TNamed (id, _) -> id.name | _ -> "" in
            let mangled = type_name ^ "__" ^ method_name.name in
            (match env_lookup_fn env mangled with
             | Some sig_ ->
                 let all_args = obj :: args in
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
      let env' = check_stmts env stmts in
      (match ret with
       | Some e -> check_expr env' e
       | None   -> TPrim TUnit)

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
      (* The assume adds the pred as a known fact going forward *)
      (* NOTE: we don't modify env here — callers that need the fact
         should use proof blocks. *)
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

and check_stmts env stmts : env =
  let env' = List.fold_left check_stmt env stmts in
  (* Must-use check: Lin variables introduced in this block must be consumed.
     Walk vars added since this block started and flag any unused Lin bindings. *)
  let outer_names = List.map fst env.vars in
  List.iter (fun (name, vi) ->
    if not (List.mem name outer_names)
       && vi.vi_linearity = Lin
       && not !(vi.vi_used) then
      report_error (LinearityError (vi.vi_loc,
        Printf.sprintf "linear variable '%s' is never used \
          (linear values must be consumed exactly once)" name))
  ) env'.vars;
  env'

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
      (match expr_.expr_desc with
       | EStruct (_, fields) ->
           List.fold_left (fun e (fid, fexpr) ->
             env_add_fact e (PBinop (Eq,
               PField (PVar name, fid.name),
               expr_to_pred_simple fexpr))
           ) env'' fields
       | _ -> env'')

  | SExpr e ->
      let _ = check_expr env e in
      (* SSA-lite: if this is an assignment, track the new value as a fact.
         ESync: mark barrier reached so subsequent shared[] accesses are unrestricted. *)
      (match e.expr_desc with
       | EAssign (lhs, rhs) ->
           (match lhs.expr_desc with
            | EVar v -> env_assign_var env v (expr_to_pred_simple rhs)
            | EIndex (arr, idx) ->
                (* Array element assignment: add arr[idx] == rhs as a proof fact.
                   This enables loop invariants of the form
                   invariant forall j < k. arr[j] == val
                   to be verified after arr[k] = val. *)
                let arr_pred = expr_to_pred_simple arr in
                let idx_pred = expr_to_pred_simple idx in
                let rhs_pred = expr_to_pred_simple rhs in
                env_add_fact env
                  (PBinop (Eq, PIndex (arr_pred, idx_pred), rhs_pred))
            | _      -> env)
       | ESync -> { env with after_barrier = true }
       | _ -> env)

  | SReturn e ->
      (match env.current_fn with
       | None -> fail stmt.stmt_loc "return outside function"; env
       | Some sig_ ->
           let ret_ty = match e with
             | Some expr_ -> check_expr env expr_
             | None       -> TPrim TUnit
           in
           if not (ty_compatible ret_ty sig_.fs_ret) then
             fail stmt.stmt_loc "return type mismatch";
           (* Check postconditions — substitute result → return expression
              so that ensures clauses like 'result == 2*x' are checked
              against the actual returned value, not the literal name. *)
           let ret_pred = match e with
             | Some expr_ -> expr_to_pred_simple expr_
             | None       -> PBool true   (* unit return — no result pred *)
           in
           List.iter (fun ens ->
             let ob_pred = subst_pred [("result", ret_pred)] ens in
             add_obligation ob_pred (OPostcondition sig_.fs_name)
               stmt.stmt_loc env
           ) sig_.fs_ensures;
           env)

  | SWhile (cond, inv, dec, body) ->
      let cond_ty = check_expr env cond in
      if not (is_bool cond_ty) then
        fail stmt.stmt_loc "while condition must be bool";
      let cond_pred = expr_to_pred_simple cond in
      (* 1. Invariant holds at loop entry — prove from pre-loop env *)
      (match inv with
       | Some p ->
           add_obligation p (OInvariant "while_entry") stmt.stmt_loc env
       | None -> ());
      (* 2. Termination measure is non-negative at entry.
            PLex (a, b) expands to: a >= 0 AND b >= 0 (each component non-negative). *)
      (match dec with
       | None -> ()
       | Some (PLex ms) ->
           List.iter (fun m ->
             add_obligation (PBinop (Ge, m, PInt 0L))
               (OTermination "while") stmt.stmt_loc env
           ) ms
       | Some measure ->
           add_obligation (PBinop (Ge, measure, PInt 0L))
             (OTermination "while") stmt.stmt_loc env);
      (* 3. Check body in env extended with cond AND invariant as facts *)
      let env_body = env_add_fact env cond_pred in
      let env_body = match inv with
        | Some p -> env_add_fact env_body p
        | None   -> env_body
      in
      let env_after = check_stmts env_body body in
      (* 4. Invariant is preserved: prove inv holds after body *)
      (match inv with
       | Some p ->
           add_obligation p (OInvariant "while_preserved") stmt.stmt_loc env_after
       | None -> ());
      (* 5. After the loop: know ¬cond AND invariant *)
      let env_exit = env_add_fact env (PUnop (Not, cond_pred)) in
      let env_exit = match inv with
        | Some p -> env_add_fact env_exit p
        | None   -> env_exit
      in
      env_exit

  | SFor (name, iter, dec, body) ->
      let iter_ty = check_expr env iter in
      let elem_ty = match iter_ty with
        | TSlice t | TArray (t, _) -> t
        | TRef (TSlice t) | TRef (TArray (t, _)) -> t
        | _ -> TPrim (TUint U64)
      in
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
      let env' = env_add_var env name.name elem_ty Unr stmt.stmt_loc in
      let _ = check_stmts env' body in
      env

  | SBreak | SContinue -> env

and check_field_access obj_ty field loc env =
  (* Strip qualifiers before checking *)
  match strip_qual obj_ty with
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
  | TNamed (name, _) | TRef (TNamed (name, _)) | TRefMut (TNamed (name, _)) ->
      (match List.assoc_opt name.name env.structs with
       | Some sd ->
           (match List.assoc_opt field.name
                    (List.map (fun (id, ty) -> (id.name, ty)) sd.sd_fields) with
            | Some ft -> ft
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
      List.fold_left (fun e p -> bind_pattern_vars e (TPrim (TUint U64)) p) env pats
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
  {
    fs_name        = fn.fn_name.name;
    fs_type_params = [];
    fs_params      = List.map (fun (id, t) -> (id, normalize_ty t)) fn.fn_params;
    fs_ret         = normalize_ty fn.fn_ret;
    fs_requires    = fn.fn_requires;
    fs_ensures     = fn.fn_ensures;
    fs_decreases   = fn.fn_decreases;
  }

let check_fn env fn =
  let sig_ = collect_fn_sig fn in
  (* Process function attributes *)
  let is_kernel    = List.exists (fun a -> a.attr_name = "kernel")    fn.fn_attrs in
  let is_coalesced = List.exists (fun a -> a.attr_name = "coalesced") fn.fn_attrs in
  let env = if is_kernel    then { env with is_gpu_fn    = true } else env in
  let env = if is_coalesced then { env with coalesced_fn = true } else env in
  (* Inject GPU built-in variables for kernel functions.
     threadIdx_x/y/z are varying (per-thread); blockIdx/blockDim/gridDim are uniform. *)
  let env =
    if is_kernel then begin
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
      e
    end else env
  in
  (* Build env with params in scope — normalize types so secret<T> → TSecret t *)
  let env' = List.fold_left (fun e (id, ty) ->
    env_add_var e id.name (normalize_ty ty) Unr id.loc
  ) { env with current_fn = Some sig_ } fn.fn_params in
  (* Extract refinement predicates from param types as known facts *)
  let env' = List.fold_left (fun e (id, ty) ->
    match normalize_ty ty with
    | TRefined (_, binder, pred) ->
        let fact = subst_pred [(binder.name, PVar { name = id.name; loc = id.loc })] pred in
        env_add_fact e fact
    | _ -> e
  ) env' fn.fn_params in
  (* Add requires as known facts *)
  let env' = List.fold_left env_add_fact env' fn.fn_requires in
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
       (* result pred: trailing expression of block, or whole body for simple exprs *)
       let ret_pred = match body.expr_desc with
         | EBlock (_, Some ret) -> expr_to_pred_simple ret
         | _                    -> expr_to_pred_simple body
       in
       (* Generate postcondition obligations using the post-body env *)
       List.iter (fun ens ->
         let subst = [("result", ret_pred)] in
         let ob_pred = subst_pred subst ens in
         add_obligation ob_pred (OPostcondition fn.fn_name.name)
           fn.fn_name.loc body_env
       ) fn.fn_ensures)

let rec check_item env item =
  match item.item_desc with
  | IFn fn ->
      let sig_ = collect_fn_sig fn in
      let env' = env_add_fn env fn.fn_name.name sig_ in
      check_fn env' fn;
      env'
  | IType td ->
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
          fs_params      = params;
          fs_ret         = enum_ty;
          fs_requires    = [];
          fs_ensures     = [];
          fs_decreases   = None;
        } in
        env_add_fn e vname.name sig_
      ) env ed.ed_variants
  | IImpl im  ->
      let ty_name = match im.im_ty with
        | TNamed (id, []) -> id.name
        | _ -> "ImplUnknown"
      in
      List.fold_left (fun e item ->
        match item.item_desc with
        | IFn fn ->
            let mangled_name = ty_name ^ "__" ^ fn.fn_name.name in
            let mangled_fn = { fn with fn_name = { fn.fn_name with name = mangled_name } } in
            check_fn e mangled_fn;
            let sig_ = collect_fn_sig mangled_fn in
            env_add_fn e mangled_name sig_
        | _ -> check_item e item
      ) env im.im_items
  | IExtern ex ->
      (match ex.ex_ty with
       | TFn fty ->
           let sig_ = {
             fs_name        = ex.ex_name.name;
             fs_type_params = [];
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
    | EArrayRepeat (v,n) -> scan_expr v; scan_expr n
    | _ -> ()
  and scan_stmt s =
    match s.stmt_desc with
    | SLet (_, _, e, _) -> scan_expr e
    | SExpr e           -> scan_expr e
    | SReturn (Some e)  -> scan_expr e
    | SWhile (c, _, _, body) -> scan_expr c; List.iter scan_stmt body
    | SFor (_, e, _, body)   -> scan_expr e; List.iter scan_stmt body
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
  proved_lemmas := [];    (* reset per-compilation lemma registry *)
  fresh_counter := 0;     (* reset SSA name counter *)
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

  (tc_errors, obs)
