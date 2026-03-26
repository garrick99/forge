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
  fs_params:   (string * ty) list;
  fs_ret:      ty;
  fs_requires: pred list;
  fs_ensures:  pred list;
}

type env = {
  vars:    (string * var_info) list;
  fns:     (string * fn_sig) list;
  types:   (string * ty) list;
  structs: (string * struct_def) list;
  (* Current function context for checking ensures *)
  current_fn: fn_sig option;
  (* Proof context — what we know is true here *)
  proof_ctx: proof_ctx;
}

let empty_env = {
  vars       = [];
  fns        = [];
  types      = [];
  structs    = [];
  current_fn = None;
  proof_ctx  = empty_ctx;
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

let prim_of_ty = function
  | TPrim p            -> Some p
  | TRefined (p, _, _) -> Some p
  | _                  -> None

let is_numeric ty =
  match prim_of_ty ty with
  | Some (TInt _) | Some (TUint _) | Some (TFloat _) -> true
  | _ -> false

let is_bool ty =
  match prim_of_ty ty with
  | Some TBool -> true
  | _ -> false

let is_integer ty =
  match prim_of_ty ty with
  | Some (TInt _) | Some (TUint _) -> true
  | _ -> false

(* Widen a refined type to its base *)
let base_ty = function
  | TRefined (p, _, _) -> TPrim p
  | t -> t

(* Type equality (structural) *)
let rec ty_eq t1 t2 =
  match t1, t2 with
  | TPrim p1, TPrim p2 -> p1 = p2
  | TRefined (p1, _, _), TRefined (p2, _, _) -> p1 = p2
  | TRefined (p1, _, _), TPrim p2 -> p1 = p2
  | TPrim p1, TRefined (p2, _, _) -> p1 = p2
  | TRef t1, TRef t2 -> ty_eq t1 t2
  | TRefMut t1, TRefMut t2 -> ty_eq t1 t2
  | TOwn t1, TOwn t2 -> ty_eq t1 t2
  | TSlice t1, TSlice t2 -> ty_eq t1 t2
  | TArray (t1, _), TArray (t2, _) -> ty_eq t1 t2
  | TNamed (n1, _), TNamed (n2, _) -> n1.name = n2.name
  | _ -> false

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
    ob_pred   = pred;
    ob_kind   = kind;
    ob_loc    = loc;
    ob_ctx    = ctx.proof_ctx.pc_vars;
    ob_status = Pending;
  } :: !obligations

(* Generate division-by-zero obligation *)
let check_division divisor fn_name loc ctx =
  let pred = PBinop (Ne, expr_to_pred_simple divisor, PInt 0) in
  add_obligation pred (OPrecondition fn_name) loc ctx

(* Translate expression to pred for obligation generation *)
and expr_to_pred_simple e =
  match e.expr_desc with
  | ELit (LInt (n, _))  -> PInt n
  | ELit (LBool b)      -> PBool b
  | EVar id             -> PVar id
  | EBinop (op, l, r)   -> PBinop (op, expr_to_pred_simple l, expr_to_pred_simple r)
  | EUnop (op, e)       -> PUnop (op, expr_to_pred_simple e)
  | _                   -> PVar { name = "__expr"; loc = e.expr_loc }

(* Generate array bounds obligation *)
let check_bounds arr_expr idx_expr loc ctx =
  (* idx < arr.len *)
  let idx_pred = expr_to_pred_simple idx_expr in
  let len_pred = PApp (
    { name = "len"; loc },
    [expr_to_pred_simple arr_expr]
  ) in
  let pred = PBinop (Lt, idx_pred, len_pred) in
  add_obligation pred (OBoundsCheck "array") loc ctx

(* Check preconditions at a call site *)
let check_preconditions fn_name reqs args params loc ctx =
  (* Substitute actual arguments for formal parameters in each requires pred *)
  let subst = List.combine (List.map fst params) (List.map expr_to_pred_simple args) in
  List.iter (fun req ->
    let pred = subst_pred subst req in
    add_obligation pred (OPrecondition fn_name) loc ctx
  ) reqs

(* Substitute variables in a pred *)
and subst_pred (subst : (string * pred) list) pred =
  match pred with
  | PVar id ->
      (match List.assoc_opt id.name subst with
       | Some p -> p
       | None   -> pred)
  | PBinop (op, l, r) -> PBinop (op, subst_pred subst l, subst_pred subst r)
  | PUnop (op, p)     -> PUnop (op, subst_pred subst p)
  | PForall (x, t, p) -> PForall (x, t, subst_pred (List.remove_assoc x.name subst) p)
  | PExists (x, t, p) -> PExists (x, t, subst_pred (List.remove_assoc x.name subst) p)
  | POld p            -> POld (subst_pred subst p)
  | PApp (f, args)    -> PApp (f, List.map (subst_pred subst) args)
  | _                 -> pred

(* ------------------------------------------------------------------ *)
(* Type checking expressions                                            *)
(* ------------------------------------------------------------------ *)

let rec check_expr env expr : ty =
  let ty = infer_expr env expr in
  ty

and infer_expr env expr : ty =
  match expr.expr_desc with

  (* Literals *)
  | ELit (LInt (_, hint)) ->
      (match hint with
       | Some w -> TPrim (TUint w)
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
           (* Mark as used for linearity tracking *)
           if vi.vi_linearity = Lin && !(vi.vi_used) then
             report_error (LinearityError (id.loc,
               Printf.sprintf "linear variable '%s' used more than once" id.name));
           vi.vi_used := true;
           vi.vi_ty
       | None ->
           (match env_lookup_fn env id.name with
            | Some sig_ -> TFn (mk_fn_ty sig_.fs_params sig_.fs_ret
                                         sig_.fs_requires sig_.fs_ensures)
            | None ->
                fail id.loc (Printf.sprintf "unbound variable '%s'" id.name);
                TPrim (TUint U64)))  (* error recovery type *)

  (* Binary operations *)
  | EBinop (Div, lhs, rhs) ->
      (* Division: must prove rhs != 0 *)
      let lt = check_expr env lhs in
      let _  = check_expr env rhs in
      check_division rhs "__div__" expr.expr_loc env;
      lt

  | EBinop (op, lhs, rhs) ->
      let lt = check_expr env lhs in
      let rt = check_expr env rhs in
      (match op with
       | Eq | Ne | Lt | Le | Gt | Ge -> TPrim TBool
       | And | Or | Implies | Iff    -> TPrim TBool
       | _ -> numeric_result_ty lt rt)

  (* Unary operations *)
  | EUnop (Not, e) ->
      let _ = check_expr env e in
      TPrim TBool
  | EUnop (Neg, e) ->
      check_expr env e
  | EUnop (BitNot, e) ->
      check_expr env e

  (* Array indexing — must prove index in bounds *)
  | EIndex (arr, idx) ->
      let arr_ty = check_expr env arr in
      let _      = check_expr env idx in
      check_bounds arr idx expr.expr_loc env;
      (match arr_ty with
       | TArray (elem, _) -> elem
       | TSlice elem      -> elem
       | TRef (TArray (elem, _)) -> elem
       | TRef (TSlice elem) -> elem
       | TRefMut (TArray (elem, _)) -> elem
       | _ ->
           fail expr.expr_loc "indexing non-array type";
           TPrim (TUint U8))

  (* Field access *)
  | EField (obj, field) ->
      let obj_ty = check_expr env obj in
      check_field_access obj_ty field expr.expr_loc env

  (* Function call *)
  | ECall (f, args) ->
      let f_ty = check_expr env f in
      (match f_ty with
       | TFn fty ->
           (* Check arg count *)
           if List.length fty.params <> List.length args then
             report_error (ArityMismatch (expr.expr_loc,
               "function", List.length fty.params, List.length args));
           (* Type-check arguments *)
           List.iter2 (fun (_, param_ty) arg ->
             let arg_ty = check_expr env arg in
             if not (ty_eq (base_ty param_ty) (base_ty arg_ty)) then
               fail expr.expr_loc
                 (Printf.sprintf "argument type mismatch: expected %s"
                   (format_ty param_ty))
           ) fty.params args;
           (* Generate precondition obligations *)
           check_preconditions "fn" fty.requires args fty.params
             expr.expr_loc env;
           fty.ret
       | _ ->
           fail expr.expr_loc "calling non-function";
           TPrim TUnit)

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

  (* If expression *)
  | EIf (cond, then_, else_) ->
      let cond_ty = check_expr env cond in
      if not (is_bool cond_ty) then
        fail expr.expr_loc "if condition must be bool";
      let then_ty = check_expr env then_ in
      (match else_ with
       | None -> TPrim TUnit
       | Some else_e ->
           let else_ty = check_expr env else_e in
           if not (ty_eq (base_ty then_ty) (base_ty else_ty)) then
             fail expr.expr_loc "if branches must have same type";
           then_ty)

  (* Match *)
  | EMatch (scrut, arms) ->
      let _ = check_expr env scrut in
      let arm_tys = List.map (fun arm ->
        let env' = bind_pattern_vars env arm.pattern in
        check_expr env' arm.body
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

  (* Assume — logs to audit, adds fact to proof context *)
  | EAssume (pred, ctx_str) ->
      log_assume pred ctx_str expr.expr_loc;
      (* The assume adds the pred as a known fact going forward *)
      (* NOTE: we don't modify env here — callers that need the fact
         should use proof blocks. *)
      TPrim TUnit

and check_stmts env stmts : env =
  List.fold_left check_stmt env stmts

and check_stmt env stmt : env =
  match stmt.stmt_desc with
  | SLet (name, ann, expr_, lin) ->
      let inferred = check_expr env expr_ in
      let ty = match ann with
        | Some t ->
            if not (ty_eq (base_ty t) (base_ty inferred)) then
              fail stmt.stmt_loc
                (Printf.sprintf "type annotation %s doesn't match inferred %s"
                  (format_ty t) (format_ty inferred));
            t
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
      env_add_var env name.name ty lin stmt.stmt_loc

  | SExpr e ->
      let _ = check_expr env e in
      env

  | SReturn e ->
      (match env.current_fn with
       | None -> fail stmt.stmt_loc "return outside function"; env
       | Some sig_ ->
           let ret_ty = match e with
             | Some expr_ -> check_expr env expr_
             | None       -> TPrim TUnit
           in
           if not (ty_eq (base_ty ret_ty) (base_ty sig_.fs_ret)) then
             fail stmt.stmt_loc "return type mismatch";
           (* Check postconditions *)
           List.iter (fun ens ->
             add_obligation ens (OPostcondition "fn")
               stmt.stmt_loc env
           ) sig_.fs_ensures;
           env)

  | SWhile (cond, inv, dec, body) ->
      let cond_ty = check_expr env cond in
      if not (is_bool cond_ty) then
        fail stmt.stmt_loc "while condition must be bool";
      (* Termination obligation *)
      (match dec with
       | None ->
           (* No decreases clause — error unless it's a 'loop' *)
           ()  (* TODO: require decreases for while *)
       | Some measure ->
           add_obligation (PBinop (Ge, measure, PInt 0))
             (OTermination "while") stmt.stmt_loc env);
      (* Invariant as obligation *)
      (match inv with
       | Some p ->
           add_obligation p (OInvariant "while_invariant") stmt.stmt_loc env
       | None -> ());
      let _ = check_stmts env body in
      env

  | SFor (name, iter, dec, body) ->
      let iter_ty = check_expr env iter in
      let elem_ty = match iter_ty with
        | TSlice t | TArray (t, _) -> t
        | TRef (TSlice t) | TRef (TArray (t, _)) -> t
        | _ -> TPrim (TUint U64)
      in
      (match dec with
       | None -> ()
       | Some measure ->
           add_obligation (PBinop (Ge, measure, PInt 0))
             (OTermination "for") stmt.stmt_loc env);
      let env' = env_add_var env name.name elem_ty Unr stmt.stmt_loc in
      let _ = check_stmts env' body in
      env

  | SBreak | SContinue -> env

and check_field_access obj_ty field loc env =
  match obj_ty with
  | TNamed (name, _) | TRef (TNamed (name, _)) | TRefMut (TNamed (name, _)) ->
      (match List.assoc_opt name.name env.structs with
       | Some sd ->
           (match List.assoc_opt field.name sd.sd_fields with
            | Some ft -> ft
            | None ->
                fail loc (Printf.sprintf "no field '%s' on struct '%s'"
                  field.name name.name);
                TPrim TUnit)
       | None ->
           fail loc (Printf.sprintf "unknown struct '%s'" name.name);
           TPrim TUnit)
  | _ ->
      fail loc "field access on non-struct type";
      TPrim TUnit

and bind_pattern_vars env pat =
  match pat with
  | PBind name ->
      env_add_var env name.name (TPrim (TUint U64)) Unr name.loc
  | PCtor (_, pats) ->
      List.fold_left bind_pattern_vars env pats
  | PTuple pats ->
      List.fold_left bind_pattern_vars env pats
  | PAs (pat, name) ->
      let env' = bind_pattern_vars env pat in
      env_add_var env' name.name (TPrim (TUint U64)) Unr name.loc
  | _ -> env

and check_proof_block env pb =
  (* Assumes in proof blocks are logged and added as facts *)
  List.iter (fun (a : assume_stmt) ->
    log_assume a.as_pred a.as_context a.as_loc;
    (* Check any lemmas — TODO: full CoC proof checker *)
  ) pb.pb_assumes;
  ignore env

(* ------------------------------------------------------------------ *)
(* Top-level item type checking                                         *)
(* ------------------------------------------------------------------ *)

let collect_fn_sig (fn : fn_def) : fn_sig =
  {
    fs_params   = List.map (fun (id, ty) -> (id.name, ty)) fn.fn_params;
    fs_ret      = fn.fn_ret;
    fs_requires = fn.fn_requires;
    fs_ensures  = fn.fn_ensures;
  }

let check_fn env fn =
  let sig_ = collect_fn_sig fn in
  (* Build env with params in scope *)
  let env' = List.fold_left (fun e (id, ty) ->
    env_add_var e id.name ty Unr id.loc
  ) { env with current_fn = Some sig_ } fn.fn_params in
  (* Add requires as known facts *)
  let env' = List.fold_left env_add_fact env' fn.fn_requires in
  (* Check body *)
  (match fn.fn_body with
   | None -> ()  (* extern — no body to check *)
   | Some body ->
       let body_ty = check_expr env' body in
       if not (ty_eq (base_ty body_ty) (base_ty fn.fn_ret)) then
         fail fn.fn_name.loc
           (Printf.sprintf "function '%s' body type %s doesn't match declared return type %s"
             fn.fn_name.name (format_ty body_ty) (format_ty fn.fn_ret));
       (* Generate postcondition obligations for each ensures *)
       List.iter (fun ens ->
         let subst = [("result", expr_to_pred_simple body)] in
         let ob_pred = subst_pred subst ens in
         add_obligation ob_pred (OPostcondition fn.fn_name.name)
           fn.fn_name.loc env'
       ) fn.fn_ensures)

let check_item env item =
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
  | IEnum _   -> env   (* TODO *)
  | IImpl im  ->
      List.fold_left check_item env im.im_items
  | IExtern ex ->
      (match ex.ex_ty with
       | TFn fty ->
           let sig_ = {
             fs_params   = List.map (fun (id, ty) -> (id.name, ty)) fty.params;
             fs_ret      = fty.ret;
             fs_requires = fty.requires;
             fs_ensures  = fty.ensures;
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
  ds_failures:  proof_error list;
}

let discharge_all (obs : obligation list) (prog_env : env) =
  let total  = List.length obs in
  let tier1  = ref 0 in
  let tier2  = ref 0 in
  let tier3  = ref 0 in
  let failed = ref 0 in
  let failures = ref [] in

  List.iter (fun ob ->
    let ctx = { empty_ctx with
      pc_vars    = ob.ob_ctx;
      pc_assumes = prog_env.proof_ctx.pc_assumes;
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
        incr failed;
        let pe = {
          pe_loc     = ob.ob_loc;
          pe_kind    = ob.ob_kind;
          pe_pred    = ob.ob_pred;
          pe_hint    = None;
          pe_message = msg;
        } in
        failures := pe :: !failures;
        Printf.printf "  ✗ %s\n%!" (format_error pe)
  ) obs;

  {
    ds_total   = total;
    ds_tier1   = !tier1;
    ds_tier2   = !tier2;
    ds_tier3   = !tier3;
    ds_failed  = !failed;
    ds_failures = List.rev !failures;
  }

(* ------------------------------------------------------------------ *)
(* Format helpers                                                       *)
(* ------------------------------------------------------------------ *)

and format_ty = function
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

and format_obligation_kind = function
  | OPrecondition f  -> "precondition of " ^ f
  | OPostcondition f -> "postcondition of " ^ f
  | OBoundsCheck a   -> "bounds check: " ^ a
  | ONoOverflow op   -> "no overflow: " ^ op
  | OTermination f   -> "termination: " ^ f
  | OLinear v        -> "linear: " ^ v
  | OInvariant i     -> "invariant: " ^ i

(* ------------------------------------------------------------------ *)
(* Main entry point                                                     *)
(* ------------------------------------------------------------------ *)

let typecheck_program prog =
  errors := [];
  obligations := [];

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
               fs_params   = List.map (fun (id, ty) -> (id.name, ty)) fty.params;
               fs_ret      = fty.ret;
               fs_requires = fty.requires;
               fs_ensures  = fty.ensures;
             } in
             env_add_fn e ex.ex_name.name sig_
         | _ -> e)
    | _ -> e
  ) empty_env prog.prog_items in

  (* Second pass: full type checking + obligation generation *)
  let _final_env = List.fold_left check_item env prog.prog_items in

  let tc_errors = !errors in
  let obs = List.rev !obligations in

  (tc_errors, obs)
