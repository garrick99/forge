(* FORGE Proof Engine

   Three-tier proof discharge:
     Tier 1 — SMT (Z3): automatic, no user input
     Tier 2 — Guided: compiler suggests, user supplies one hint
     Tier 3 — Manual: full Calculus of Constructions proof term

   The proof engine is the gatekeeper. Nothing reaches codegen
   unless every obligation has been discharged. *)

open Ast

(* ------------------------------------------------------------------ *)
(* Proof obligations                                                    *)
(* ------------------------------------------------------------------ *)

type obligation_kind =
  | OPrecondition  of string   (* function name *)
  | OPostcondition of string
  | OBoundsCheck   of string   (* array name *)
  | ONoOverflow    of string   (* operation *)
  | OTermination   of string   (* loop/function name *)
  | OLinear        of string   (* linear value usage *)
  | OInvariant     of string   (* struct/loop invariant *)

type tier = Tier1_SMT | Tier2_Guided | Tier3_Manual

type proof_status =
  | Discharged of tier
  | Failed     of string       (* why it failed *)
  | Pending                    (* not yet attempted *)

type obligation = {
  ob_pred:    pred;
  ob_kind:    obligation_kind;
  ob_loc:     loc;
  ob_ctx:     (string * ty) list;   (* variables in scope — name -> type *)
  ob_assumes: pred list;            (* known-true facts at obligation site *)
  ob_status:  proof_status;
}

(* ------------------------------------------------------------------ *)
(* Proof context — variables and their types/refinements in scope      *)
(* ------------------------------------------------------------------ *)

type proof_ctx = {
  pc_vars:    (string * ty) list;
  pc_assumes: pred list;           (* known-true predicates *)
  pc_lemmas:  (string * (ident * ty) list * pred) list;
}

let empty_ctx = { pc_vars = []; pc_assumes = []; pc_lemmas = [] }

let ctx_add_var ctx name ty =
  { ctx with pc_vars = (name, ty) :: ctx.pc_vars }

let ctx_add_assume ctx pred =
  { ctx with pc_assumes = pred :: ctx.pc_assumes }

(* ------------------------------------------------------------------ *)
(* SMT translation — pred -> Z3 formula                                *)
(* ------------------------------------------------------------------ *)

module Z3Bridge = struct
  (* We build Z3 formulas programmatically.
     This module translates FORGE predicates to Z3 AST nodes. *)

  type z3_result =
    | Sat                        (* formula is satisfiable *)
    | Unsat                      (* formula is unsatisfiable — negation proves original *)
    | Unknown of string          (* Z3 gave up — escalate to Tier 2 *)

  (* SMT sort — tracks whether a variable/expression is Int, Bool, or BitVec *)
  type smt_sort =
    | SInt
    | SBool
    | SBV of int * bool   (* width, is_signed *)

  let sort_to_smt = function
    | SInt        -> "Int"
    | SBool       -> "Bool"
    | SBV (n, _)  -> Printf.sprintf "(_ BitVec %d)" n

  (* Map a FORGE type to its SMT sort *)
  let rec ty_to_sort = function
    | TPrim (TUint U8)    -> SBV (8,   false)
    | TPrim (TUint U16)   -> SBV (16,  false)
    | TPrim (TUint U32)   -> SBV (32,  false)
    | TPrim (TUint U64)   -> SBV (64,  false)
    | TPrim (TUint U128)  -> SBV (128, false)
    | TPrim (TUint USize) -> SBV (64,  false)
    | TPrim (TInt  I8)    -> SBV (8,   true)
    | TPrim (TInt  I16)   -> SBV (16,  true)
    | TPrim (TInt  I32)   -> SBV (32,  true)
    | TPrim (TInt  I64)   -> SBV (64,  true)
    | TPrim (TInt  I128)  -> SBV (128, true)
    | TPrim (TInt  ISize) -> SBV (64,  true)
    | TRefined (TUint U8,  _, _) -> SBV (8,  false)
    | TRefined (TUint U16, _, _) -> SBV (16, false)
    | TRefined (TUint U32, _, _) -> SBV (32, false)
    | TRefined (TUint U64, _, _) -> SBV (64, false)
    | TRefined (TInt  I32, _, _) -> SBV (32, true)
    | TRefined (TInt  I64, _, _) -> SBV (64, true)
    | TPrim TBool -> SBool
    | TSecret t   -> ty_to_sort t   (* secret<T> has same SMT sort as T *)
    | _           -> SInt

  (* Detect if a pred contains quantifiers — forall / exists *)
  let rec has_quantifiers = function
    | PForall _ | PExists _ -> true
    | PBinop (_, l, r)       -> has_quantifiers l || has_quantifiers r
    | PUnop (_, p)           -> has_quantifiers p
    | PIte (c, t, e)         -> has_quantifiers c || has_quantifiers t || has_quantifiers e
    | PApp (_, args)         -> List.exists has_quantifiers args
    | PField (p, _) | POld p -> has_quantifiers p
    | PIndex (a, i)          -> has_quantifiers a || has_quantifiers i
    | PLex args              -> List.exists has_quantifiers args
    | PStruct (_, fs)        -> List.exists (fun (_, p) -> has_quantifiers p) fs
    | _ -> false

  (* Detect if a pred contains any bitwise operator — signals BV mode needed *)
  let rec has_bitwise_ops = function
    | PBinop ((BitAnd|BitOr|BitXor|Shl|Shr), l, r) ->
        true || has_bitwise_ops l || has_bitwise_ops r
    | PUnop (BitNot, _) -> true
    | PBinop (_, l, r) -> has_bitwise_ops l || has_bitwise_ops r
    | PUnop (_, p) | PForall (_, _, p) | PExists (_, _, p) -> has_bitwise_ops p
    | PIte (c, t, e) -> has_bitwise_ops c || has_bitwise_ops t || has_bitwise_ops e
    | PApp (_, args) | PLex args -> List.exists has_bitwise_ops args
    | PField (p, _) | POld p -> has_bitwise_ops p
    | PStruct (_, fields) -> List.exists (fun (_, p) -> has_bitwise_ops p) fields
    | PIndex (a, i) -> has_bitwise_ops a || has_bitwise_ops i
    | _ -> false

  (* Infer the SMT sort of an expression in the current context.
     bv=true: use BV sorts for typed variables (for bitwise-heavy formulas).
     bv=false: everything is Int (for pure arithmetic formulas). *)
  let rec infer_sort ~bv ctx pred =
    if not bv then SInt
    else match pred with
    | PVar id ->
        (match List.assoc_opt id.name ctx.pc_vars with
         | Some ty -> ty_to_sort ty
         | None    -> SInt)
    | PBool _ -> SBool
    | PBinop ((Add|Sub|Mul|Div|Mod|BitAnd|BitOr|BitXor|Shl|Shr), l, r) ->
        let ls = infer_sort ~bv ctx l in
        (match ls with SBV _ -> ls | _ -> infer_sort ~bv ctx r)
    | PBinop ((Eq|Ne|Lt|Le|Gt|Ge|And|Or|Implies|Iff), _, _) -> SBool
    | PUnop ((Neg|BitNot), p) -> infer_sort ~bv ctx p
    | PUnop (Not, _) -> SBool
    | _ -> SInt

  (* Emit an integer literal in the right sort.
     In BV context we need the `(_ bvN W)` syntax.
     n is int64 to support full u64 range. *)
  let emit_int_lit hint_sort n =
    match hint_sort with
    | SBV (w, _) -> Printf.sprintf "(_ bv%s %d)" (Int64.to_string n) w
    | _          -> Int64.to_string n

  (* Translate a FORGE pred to a Z3 SMT-LIB2 string.
     ~bv: true = bitvector mode (for formulas with bitwise ops)
          false = integer mode (for pure arithmetic — default, faster)
     ~hint_sort: expected sort of this sub-expression (from parent binop). *)
  let rec pred_to_smtlib ?(hint_sort=SInt) ?(bv=false) ctx pred =
    let infer p = infer_sort ~bv ctx p in
    match pred with
    | PTrue          -> "true"
    | PFalse         -> "false"
    | PVar id        -> id.name
    | PInt n         -> if bv then emit_int_lit hint_sort n else Int64.to_string n
    | PBool b        -> string_of_bool b
    | PBinop (op, l, r) ->
        (* In BV mode: determine sort from operand types.
           In Int mode: everything is SInt (infer returns SInt when bv=false). *)
        let arith_sort =
          let ls = infer l in
          match ls with SBV _ -> ls | _ -> infer r
        in
        let ls = pred_to_smtlib ~hint_sort:arith_sort ~bv ctx l in
        let rs = pred_to_smtlib ~hint_sort:arith_sort ~bv ctx r in
        (match arith_sort with
         | SBV (_, signed) ->
             (match op with
              | Add    -> Printf.sprintf "(bvadd %s %s)"  ls rs
              | Sub    -> Printf.sprintf "(bvsub %s %s)"  ls rs
              | Mul    -> Printf.sprintf "(bvmul %s %s)"  ls rs
              | Div    -> if signed then Printf.sprintf "(bvsdiv %s %s)" ls rs
                          else           Printf.sprintf "(bvudiv %s %s)" ls rs
              | Mod    -> if signed then Printf.sprintf "(bvsrem %s %s)" ls rs
                          else           Printf.sprintf "(bvurem %s %s)" ls rs
              | BitAnd -> Printf.sprintf "(bvand %s %s)"  ls rs
              | BitOr  -> Printf.sprintf "(bvor %s %s)"   ls rs
              | BitXor -> Printf.sprintf "(bvxor %s %s)"  ls rs
              | Shl    -> Printf.sprintf "(bvshl %s %s)"  ls rs
              | Shr    -> if signed then Printf.sprintf "(bvashr %s %s)" ls rs
                          else           Printf.sprintf "(bvlshr %s %s)" ls rs
              | Eq     -> Printf.sprintf "(= %s %s)"      ls rs
              | Ne     -> Printf.sprintf "(not (= %s %s))" ls rs
              | Lt     -> if signed then Printf.sprintf "(bvslt %s %s)" ls rs
                          else           Printf.sprintf "(bvult %s %s)" ls rs
              | Le     -> if signed then Printf.sprintf "(bvsle %s %s)" ls rs
                          else           Printf.sprintf "(bvule %s %s)" ls rs
              | Gt     -> if signed then Printf.sprintf "(bvsgt %s %s)" ls rs
                          else           Printf.sprintf "(bvugt %s %s)" ls rs
              | Ge     -> if signed then Printf.sprintf "(bvsge %s %s)" ls rs
                          else           Printf.sprintf "(bvuge %s %s)" ls rs
              | And     -> Printf.sprintf "(and %s %s)"   ls rs
              | Or      -> Printf.sprintf "(or %s %s)"    ls rs
              | Implies -> Printf.sprintf "(=> %s %s)"    ls rs
              | Iff     -> Printf.sprintf "(= %s %s)"     ls rs)
         | _ ->
             (* Int / Bool sort — standard SMT-LIB arithmetic *)
             (match op with
              | Add     -> Printf.sprintf "(+ %s %s)"          ls rs
              | Sub     -> Printf.sprintf "(- %s %s)"          ls rs
              | Mul     -> Printf.sprintf "(* %s %s)"          ls rs
              | Div     -> Printf.sprintf "(div %s %s)"        ls rs
              | Mod     -> Printf.sprintf "(mod %s %s)"        ls rs
              | Eq      -> Printf.sprintf "(= %s %s)"          ls rs
              | Ne      -> Printf.sprintf "(not (= %s %s))"    ls rs
              | Lt      -> Printf.sprintf "(< %s %s)"          ls rs
              | Le      -> Printf.sprintf "(<= %s %s)"         ls rs
              | Gt      -> Printf.sprintf "(> %s %s)"          ls rs
              | Ge      -> Printf.sprintf "(>= %s %s)"         ls rs
              | And     -> Printf.sprintf "(and %s %s)"        ls rs
              | Or      -> Printf.sprintf "(or %s %s)"         ls rs
              | Implies -> Printf.sprintf "(=> %s %s)"         ls rs
              | Iff     -> Printf.sprintf "(= %s %s)"          ls rs
              | BitAnd  -> Printf.sprintf "(bvand %s %s)"      ls rs
              | BitOr   -> Printf.sprintf "(bvor %s %s)"       ls rs
              | BitXor  -> Printf.sprintf "(bvxor %s %s)"      ls rs
              | Shl     -> Printf.sprintf "(bvshl %s %s)"      ls rs
              | Shr     -> Printf.sprintf "(bvlshr %s %s)"     ls rs))
    | PUnop (Not, p)    -> Printf.sprintf "(not %s)" (pred_to_smtlib ~bv ctx p)
    | PUnop (Neg, p)    ->
        let s = infer p in
        (match s with
         | SBV _ -> Printf.sprintf "(bvneg %s)" (pred_to_smtlib ~hint_sort:s ~bv ctx p)
         | _     -> Printf.sprintf "(- %s)"     (pred_to_smtlib ~bv ctx p))
    | PUnop (BitNot, p) ->
        let s = infer p in
        Printf.sprintf "(bvnot %s)" (pred_to_smtlib ~hint_sort:s ~bv ctx p)
    | PForall (x, ty, body) ->
        let qs = if bv then sort_to_smt (ty_to_sort ty) else "Int" in
        let body_s = pred_to_smtlib ~bv ctx body in
        (* In Int mode, add non-negativity guard for unsigned binders *)
        (* In Int mode, add non-negativity guard for unsigned binders *)
        let unsigned_binder =
          (not bv) && (match ty with
            | TPrim (TUint _) | TRefined (TUint _, _, _) -> true | _ -> false)
        in
        if unsigned_binder then
          Printf.sprintf "(forall ((%s %s)) (=> (>= %s 0) %s))" x.name qs x.name body_s
        else
          Printf.sprintf "(forall ((%s %s)) %s)" x.name qs body_s
    | PExists (x, ty, body) ->
        let qs = if bv then sort_to_smt (ty_to_sort ty) else "Int" in
        let body_s = pred_to_smtlib ~bv ctx body in
        let unsigned_binder =
          (not bv) && (match ty with
            | TPrim (TUint _) | TRefined (TUint _, _, _) -> true | _ -> false)
        in
        if unsigned_binder then
          Printf.sprintf "(exists ((%s %s)) (and (>= %s 0) %s))" x.name qs x.name body_s
        else
          Printf.sprintf "(exists ((%s %s)) %s)" x.name qs body_s
    | PIte (c, t, e) ->
        let ts = infer t in
        Printf.sprintf "(ite %s %s %s)"
          (pred_to_smtlib ~bv ctx c)
          (pred_to_smtlib ~hint_sort:ts ~bv ctx t)
          (pred_to_smtlib ~hint_sort:ts ~bv ctx e)
    | PResult -> "result__"
    | POld p  ->
        (* Flatten POld into a valid SMT identifier.
           Supported shapes:
             old(x)        → old__x
             old(x.f)      → old__x__f
             old(x.f.g)    → old__x__f__g   (recursive)
           Anything more complex (array indexing, arithmetic) collapses to
           old__expr to stay syntactically valid; the Z3 context may not
           have a declared constant for it, but at least the SMT won't
           be malformed. *)
        let rec flatten_old_id = function
          | PVar id          -> id.name
          | PField (inner, f) -> flatten_old_id inner ^ "__" ^ f
          | _                -> "expr"
        in
        "old__" ^ flatten_old_id p
    | PApp (f, args) ->
        let arg_strs = List.map (pred_to_smtlib ~bv ctx) args in
        Printf.sprintf "(%s %s)" f.name (String.concat " " arg_strs)
    | PLex [] -> "true"
    | PLex [p] -> pred_to_smtlib ~bv ctx p
    | PLex ps ->
        (* PLex should be expanded by typecheck before reaching Z3.
           If it reaches here, encode all components as a conjunction so
           PLex(a,b) >= 0 becomes (and a b) rather than vacuously true. *)
        Printf.sprintf "(and %s)"
          (String.concat " " (List.map (pred_to_smtlib ~bv ctx) ps))
    | PField (p, f) ->
        let base = match p with
          | PVar id -> id.name
          | PResult -> "result__"
          | _       -> pred_to_smtlib ~bv ctx p
        in
        base ^ "__" ^ f
    | PStruct (_, fields) ->
        (* Struct literals in predicates: encode as conjunction of field equalities.
           (= __struct__field value) per field, combined with (and ...).
           This is a field-projection approximation — not a proper ADT encoding —
           but far better than the constant "0" it replaces. *)
        (match fields with
         | [] -> "true"
         | _ ->
             let eqs = List.map (fun (f, p) ->
               Printf.sprintf "(= __struct__%s %s)" f (pred_to_smtlib ~bv ctx p)
             ) fields in
             Printf.sprintf "(and %s)" (String.concat " " eqs))
    | PIndex (arr, idx) ->
        Printf.sprintf "(select %s %s)" (pred_to_smtlib ~bv ctx arr) (pred_to_smtlib ~bv ctx idx)

  (* Collect all PVar names in a pred (for free-variable declarations) *)
  let rec pred_vars acc = function
    | PVar id -> id.name :: acc
    | PBinop (_, l, r) -> pred_vars (pred_vars acc l) r
    | PUnop (_, p) -> pred_vars acc p
    | PIte (c, t, e) -> pred_vars (pred_vars (pred_vars acc c) t) e
    | PApp (_, args) -> List.fold_left pred_vars acc args
    | PForall (x, _, p) | PExists (x, _, p) ->
        List.filter ((<>) x.name) (pred_vars acc p)
    | PLex ps -> List.fold_left pred_vars acc ps
    | PField (p, f) ->
        let base = match p with
          | PVar id -> id.name
          | PResult -> "result__"
          | _       -> "__struct"
        in
        (base ^ "__" ^ f) :: acc
    | PStruct (_, fields) ->
        List.fold_left (fun a (_, p) -> pred_vars a p) acc fields
    | PIndex (arr, idx) -> pred_vars (pred_vars acc arr) idx
    | _ -> acc

  (* Collect names of variables used as array base in (select arr idx). *)
  let rec collect_array_var_names acc pred =
    match pred with
    | PIndex (PVar id, idx) ->
        collect_array_var_names (id.name :: acc) idx
    | PIndex (arr, idx) ->
        collect_array_var_names (collect_array_var_names acc arr) idx
    | PBinop (_, l, r) ->
        collect_array_var_names (collect_array_var_names acc l) r
    | PUnop (_, p) -> collect_array_var_names acc p
    | PIte (c, t, e) ->
        collect_array_var_names
          (collect_array_var_names (collect_array_var_names acc c) t) e
    | PApp (_, args) -> List.fold_left collect_array_var_names acc args
    | PForall (_, _, p) | PExists (_, _, p) -> collect_array_var_names acc p
    | PLex ps -> List.fold_left collect_array_var_names acc ps
    | PField (p, _) -> collect_array_var_names acc p
    | PStruct (_, fields) ->
        List.fold_left (fun a (_, p) -> collect_array_var_names a p) acc fields
    | _ -> acc

  (* Range constraints for unsigned types in Int mode *)
  let is_unsigned = function
    | TPrim (TUint _) | TRefined (TUint _, _, _) -> true
    | _ -> false

  (* Upper bounds as strings to avoid OCaml int overflow on u64/u128. *)
  let uint_max_str = function
    | U8    -> Some "255"
    | U16   -> Some "65535"
    | U32   -> Some "4294967295"
    | U64   -> Some "18446744073709551615"
    | U128  -> Some "340282366920938463463374607431768211455"
    | USize -> Some "18446744073709551615"

  let build_query ctx pred =
    (* BV mode: use bitvector sorts when the formula involves bitwise ops.
       Int mode: use unbounded integer sorts with range constraints (faster for Z3). *)
    let all_preds = pred :: ctx.pc_assumes in
    let use_bv = List.exists has_bitwise_ops all_preds in
    let known_vars = List.map fst ctx.pc_vars in
    let all_pred_vars =
      let goal_vars   = pred_vars [] pred in
      let assume_vars = List.concat_map (pred_vars []) ctx.pc_assumes in
      List.sort_uniq String.compare (goal_vars @ assume_vars)
    in
    let free_vars = List.filter (fun v -> not (List.mem v known_vars)) all_pred_vars in
    let array_var_names =
      let goal_avs   = collect_array_var_names [] pred in
      let assume_avs = List.concat_map (collect_array_var_names []) ctx.pc_assumes in
      List.sort_uniq String.compare (goal_avs @ assume_avs)
    in
    (* Variable declarations — BV sort when in BV mode, Int otherwise *)
    let decl_sort name ty =
      if List.mem name array_var_names then
        if use_bv then "(Array (_ BitVec 64) (_ BitVec 64))" else "(Array Int Int)"
      else if use_bv then sort_to_smt (ty_to_sort ty)
      else "Int"
    in
    let decls = List.map (fun (name, ty) ->
      Printf.sprintf "(declare-const %s %s)" name (decl_sort name ty)
    ) ctx.pc_vars in
    let free_decls = List.map (fun name ->
      (* In BV mode QF_BV does not allow Int sort — use (_ BitVec 64) for unknowns.
         In Int mode, free variables are plain Int. *)
      if use_bv then Printf.sprintf "(declare-const %s (_ BitVec 64))" name
      else Printf.sprintf "(declare-const %s Int)" name
    ) free_vars in
    (* In Int mode: add non-negativity and upper-bound constraints for unsigned types.
       In BV mode: sort enforces range. *)
    let range_constraints =
      if use_bv then []
      else
        let nonneg = List.filter_map (fun (name, ty) ->
          if is_unsigned ty then Some (Printf.sprintf "(assert (>= %s 0))" name)
          else None
        ) ctx.pc_vars in
        let upper = List.filter_map (fun (name, ty) ->
          match ty with
          | TPrim (TUint w) | TRefined (TUint w, _, _) ->
              (match uint_max_str w with
               | Some m -> Some (Printf.sprintf "(assert (<= %s %s))" name m)
               | None   -> None)
          | _ -> None
        ) ctx.pc_vars in
        nonneg @ upper
    in
    let assumes = List.map (fun p ->
      Printf.sprintf "(assert %s)" (pred_to_smtlib ~bv:use_bv ctx p)
    ) ctx.pc_assumes in
    (* Inject proved lemmas as axioms.
       Skip quantified lemmas in BV mode (QF_BV disallows forall/exists).
       Alpha-rename lemma bound variables to avoid shadowing local decls. *)
    let lemma_asserts =
      List.filter_map (fun (lname, lparams, lp) ->
        if use_bv && (lparams <> [] || has_quantifiers lp) then None
        else
          (* Freshen bound variables: rename all PForall/PExists binders
             with prefix "__lem_<name>_" to avoid clashes with local decls.
             Inline substitution of a single variable old_name → new_var. *)
          let rec rename_var old_name new_var = function
            | PVar id when id.name = old_name -> new_var
            | PBinop (op, l, r) ->
                PBinop (op, rename_var old_name new_var l,
                            rename_var old_name new_var r)
            | PUnop  (op, p)    -> PUnop (op, rename_var old_name new_var p)
            | PIte   (c, t, e)  ->
                PIte (rename_var old_name new_var c,
                      rename_var old_name new_var t,
                      rename_var old_name new_var e)
            | PForall (x, ty, body) when x.name <> old_name ->
                PForall (x, ty, rename_var old_name new_var body)
            | PExists (x, ty, body) when x.name <> old_name ->
                PExists (x, ty, rename_var old_name new_var body)
            | PField (p, f)  -> PField (rename_var old_name new_var p, f)
            | POld   p       -> POld   (rename_var old_name new_var p)
            | PIndex (a, i)  -> PIndex (rename_var old_name new_var a,
                                        rename_var old_name new_var i)
            | PApp (f, args) -> PApp (f, List.map (rename_var old_name new_var) args)
            | PLex args      -> PLex (List.map (rename_var old_name new_var) args)
            | other -> other
          in
          let rec freshen prefix = function
            | PForall (x, ty, body) ->
                let x' = { x with name = prefix ^ x.name } in
                PForall (x', ty, freshen prefix (rename_var x.name (PVar x') body))
            | PExists (x, ty, body) ->
                let x' = { x with name = prefix ^ x.name } in
                PExists (x', ty, freshen prefix (rename_var x.name (PVar x') body))
            | PBinop (op, l, r) -> PBinop (op, freshen prefix l, freshen prefix r)
            | PUnop  (op, p)    -> PUnop  (op, freshen prefix p)
            | PIte   (c, t, e)  ->
                PIte (freshen prefix c, freshen prefix t, freshen prefix e)
            | PField (p, f)     -> PField (freshen prefix p, f)
            | POld   p          -> POld   (freshen prefix p)
            | PIndex (a, i)     -> PIndex (freshen prefix a, freshen prefix i)
            | PApp (f, args)    -> PApp   (f, List.map (freshen prefix) args)
            | PLex args         -> PLex   (List.map (freshen prefix) args)
            | other -> other
          in
          let prefix = Printf.sprintf "__lem_%s_" lname in
          (* Wrap stmt with PForall over params so free variables are quantified *)
          let quantified = List.fold_right (fun (param, ty) body ->
            PForall (param, ty, body)
          ) lparams lp in
          let fresh_p = freshen prefix quantified in
          Some (Printf.sprintf "(assert %s)" (pred_to_smtlib ~bv:use_bv ctx fresh_p))
      ) ctx.pc_lemmas
    in
    let negated = Printf.sprintf "(assert (not %s))" (pred_to_smtlib ~bv:use_bv ctx pred) in
    let check = "(check-sat)" in
    (* QF_BV logic hint helps Z3 pick the right solver tactic for bitwise queries *)
    let logic_decl = if use_bv then ["(set-logic QF_BV)"] else [] in
    String.concat "\n" (logic_decl @ decls @ free_decls @ range_constraints @ assumes @ lemma_asserts @ [negated; check])

  (* Build a consistency check query — same Int/BV mode detection *)
  let build_consistency_query ctx =
    let use_bv = List.exists has_bitwise_ops ctx.pc_assumes in
    let decls = List.map (fun (name, ty) ->
      let s = if use_bv then sort_to_smt (ty_to_sort ty) else "Int" in
      Printf.sprintf "(declare-const %s %s)" name s
    ) ctx.pc_vars in
    let range_constraints =
      if use_bv then []
      else
        let nonneg = List.filter_map (fun (name, ty) ->
          if is_unsigned ty then Some (Printf.sprintf "(assert (>= %s 0))" name)
          else None) ctx.pc_vars in
        let upper = List.filter_map (fun (name, ty) ->
          match ty with
          | TPrim (TUint w) | TRefined (TUint w, _, _) ->
              (match uint_max_str w with
               | Some m -> Some (Printf.sprintf "(assert (<= %s %s))" name m)
               | None   -> None)
          | _ -> None) ctx.pc_vars in
        nonneg @ upper
    in
    let assumes = List.map (fun p ->
      Printf.sprintf "(assert %s)" (pred_to_smtlib ~bv:use_bv ctx p)) ctx.pc_assumes in
    let logic_decl = if use_bv then ["(set-logic QF_BV)"] else [] in
    String.concat "\n" (logic_decl @ decls @ range_constraints @ assumes @ ["(check-sat)"])

  let check_consistent ctx : bool =
    (* Returns true if context is consistent (satisfiable) *)
    let query = build_consistency_query ctx in
    let tmp = Filename.temp_file "forge_smt_cons" ".smt2" in
    let oc = open_out tmp in
    output_string oc query;
    close_out oc;
    let result_tmp = Filename.temp_file "forge_smt_cons_r" ".txt" in
    let cmd = Printf.sprintf "z3 -T:10 %s > %s 2>&1" tmp result_tmp in
    let rc = Sys.command cmd in
    let consistent =
      if rc = 0 then begin
        let ic = open_in result_tmp in
        let line = try input_line ic with End_of_file -> "" in
        close_in ic;
        match String.trim line with
        | "unsat" -> false   (* assumes are unsatisfiable — inconsistent *)
        | _       -> true    (* sat or unknown — treat as consistent *)
      end else true          (* Z3 failed — assume consistent *)
    in
    Sys.remove tmp;
    Sys.remove result_tmp;
    consistent

  let check_valid ctx pred : z3_result =
    let query = build_query ctx pred in
    let tmp = Filename.temp_file "forge_smt" ".smt2" in
    let oc = open_out tmp in
    output_string oc query;
    close_out oc;
    let result_tmp = Filename.temp_file "forge_smt_result" ".txt" in
    let cmd = Printf.sprintf "z3 -T:10 %s > %s 2>&1" tmp result_tmp in
    let rc = Sys.command cmd in
    let result =
      if rc = 0 then begin
        let ic = open_in result_tmp in
        let line = try input_line ic with End_of_file -> "" in
        close_in ic;
        match String.trim line with
        | "unsat"   -> Unsat        (* negation unsat = original valid *)
        | "sat"     -> Sat          (* counterexample exists *)
        | s         -> Unknown s    (* timeout, unknown, or error *)
      end else
        Unknown (Printf.sprintf "z3 exited with code %d" rc)
    in
    Sys.remove tmp;
    Sys.remove result_tmp;
    result
end

(* ------------------------------------------------------------------ *)
(* Assume audit log                                                     *)
(* ------------------------------------------------------------------ *)

type assume_entry = {
  ae_pred:    pred;
  ae_context: string option;
  ae_loc:     loc;
  ae_smtlib:  string;    (* serialized for binary embedding *)
}

let assume_log : assume_entry list ref = ref []

let log_assume pred context loc =
  let entry = {
    ae_pred    = pred;
    ae_context = context;
    ae_loc     = loc;
    ae_smtlib  = Z3Bridge.pred_to_smtlib empty_ctx pred;
  } in
  assume_log := entry :: !assume_log

let reset_assume_log () =
  assume_log := []

let dump_assume_log () =
  List.rev !assume_log

(* ------------------------------------------------------------------ *)
(* Tier 1: SMT discharge                                               *)
(* ------------------------------------------------------------------ *)

let try_smt ctx ob : proof_status =
  (* Detect vacuous proofs from inconsistent hypotheses.
     An inconsistent context makes every Z3 query trivially unsat (ex falso).
     Block immediately — the user must fix the contradiction rather than
     silently "prove" everything. *)
  if not (Z3Bridge.check_consistent ctx) then
    Failed (Printf.sprintf
      "vacuous proof: the hypothesis context at %s:%d is contradictory \
       (Z3 found unsat on assumptions alone) — check assume() calls, \
       loop invariants, and refinement types for conflicting constraints"
      ob.ob_loc.file ob.ob_loc.line)
  else
  match Z3Bridge.check_valid ctx ob.ob_pred with
  | Z3Bridge.Unsat   -> Discharged Tier1_SMT
  | Z3Bridge.Sat     ->
      Failed (Printf.sprintf
        "SMT found counterexample for %s"
        (match ob.ob_kind with
         | OPrecondition f  -> "precondition of " ^ f
         | OPostcondition f -> "postcondition of " ^ f
         | OBoundsCheck a   -> "bounds check on " ^ a
         | ONoOverflow op   -> "no-overflow on " ^ op
         | OTermination f   -> "termination of " ^ f
         | OLinear v        -> "linear usage of " ^ v
         | OInvariant i     -> "invariant " ^ i))
  | Z3Bridge.Unknown msg ->
      (* Can't decide — escalate *)
      Failed (Printf.sprintf "SMT timeout/unknown: %s — needs Tier 2" msg)

(* ------------------------------------------------------------------ *)
(* Tier 2: Guided proof                                                *)
(* ------------------------------------------------------------------ *)

(* When Tier 1 fails, we analyze why and suggest what hint is needed.
   The compiler tells the user exactly what to write. *)

type tier2_hint =
  | HintDecreases  of string   (* "add 'decreases: <expr>'" *)
  | HintInvariant  of string   (* "add 'invariant: <pred>'" *)
  | HintWitness    of string   (* "add 'witness(<expr>)'" *)
  | HintLemma      of string   (* "apply lemma X" *)
  | HintAssume     of string   (* "cannot prove — use assume() with justification" *)

let suggest_hint ob : tier2_hint =
  match ob.ob_kind with
  | OTermination f ->
      HintDecreases (Printf.sprintf
        "function '%s' may not terminate — add 'decreases: <measure>' \
         where measure strictly decreases on each recursive call" f)
  | OPrecondition f ->
      HintAssume (Printf.sprintf
        "cannot automatically prove precondition of '%s' — \
         either strengthen the caller's type or use assume() with justification" f)
  | OInvariant i ->
      HintInvariant (Printf.sprintf
        "loop invariant '%s' cannot be proven automatically — \
         add 'invariant: <pred>' to the loop" i)
  | OBoundsCheck a ->
      HintAssume (Printf.sprintf
        "cannot prove array '%s' access is in bounds — \
         refine the index type or add a bounds precondition" a)
  | _ ->
      HintAssume "cannot prove automatically — consider assume() with justification"

(* ------------------------------------------------------------------ *)
(* Main discharge function                                             *)
(* ------------------------------------------------------------------ *)

type discharge_result =
  | Proved    of tier
  | NeedsHint of tier2_hint
  | Unproved  of string

let discharge ctx ob : discharge_result =
  (* Try Tier 1 first *)
  match try_smt ctx ob with
  | Discharged t -> Proved t
  | Failed _msg ->
      let hint = suggest_hint ob in
      NeedsHint hint
  | Pending ->
      (* Not yet attempted — escalate to hint *)
      let hint = suggest_hint ob in
      NeedsHint hint

(* ------------------------------------------------------------------ *)
(* Proof checker for Tier 3 manual proof terms                        *)
(* ------------------------------------------------------------------ *)

(* ------------------------------------------------------------------ *)
(* Proof kernel helpers                                                *)
(* ------------------------------------------------------------------ *)

let dummy_loc_pk = { file = ""; line = 0; col = 0 }

(* Substitute variable x with pred repl inside a pred (no type-check, structural only) *)
let rec subst_pred_in x repl = function
  | PVar id when id.name = x -> repl
  | PBinop (op, l, r) -> PBinop (op, subst_pred_in x repl l, subst_pred_in x repl r)
  | PUnop (op, p)     -> PUnop (op, subst_pred_in x repl p)
  | PIte (c, t, e)    -> PIte (subst_pred_in x repl c,
                               subst_pred_in x repl t,
                               subst_pred_in x repl e)
  | PField (p, f)     -> PField (subst_pred_in x repl p, f)
  | PIndex (a, i)     -> PIndex (subst_pred_in x repl a, subst_pred_in x repl i)
  | PApp (f, args)    -> PApp (f, List.map (subst_pred_in x repl) args)
  | PForall (bv, ty, body) when bv.name = x -> PForall (bv, ty, body)
  | PForall (bv, ty, body) -> PForall (bv, ty, subst_pred_in x repl body)
  | PExists (bv, ty, body) when bv.name = x -> PExists (bv, ty, body)
  | PExists (bv, ty, body) -> PExists (bv, ty, subst_pred_in x repl body)
  | other -> other

(* Structural expr → pred conversion for use in proof terms.
   No type-checking; used only for providing witnesses / case scrutinees. *)
let rec proof_expr_to_pred e =
  match e.expr_desc with
  | EVar id              -> PVar id
  | ELit (LInt (n, _))   -> PInt n
  | ELit (LBool b)       -> PBool b
  | EBinop (op, l, r)    -> PBinop (op, proof_expr_to_pred l, proof_expr_to_pred r)
  | EUnop (op, e)        -> PUnop (op, proof_expr_to_pred e)
  | EField (e, f)        -> PField (proof_expr_to_pred e, f.name)
  | EIndex (a, i)        -> PIndex (proof_expr_to_pred a, proof_expr_to_pred i)
  | _                    -> PVar { name = "__proof_expr"; loc = dummy_loc_pk }

(* Minimal kernel — checks proof terms over FORGE predicates.
   This is the trusted core. Small, auditable.
   Tier 3 proofs are user-supplied structural argument; Tier 1 (SMT) is
   available as PTAuto for arithmetic leaf steps. *)

type prop =
  | PAtom    of pred
  | PAnd     of prop * prop
  | POr      of prop * prop
  | PImpl    of prop * prop
  | PNot     of prop
  | PForallP of string * prop
  | PExistsP of string * prop

type judgment =
  | Proved_by of prop * proof_term

(* Convert a FORGE pred to a prop for the proof checker *)
let rec pred_to_prop p = match p with
  | PBinop (And, a, b) -> PAnd (pred_to_prop a, pred_to_prop b)
  | PBinop (Or,  a, b) -> POr  (pred_to_prop a, pred_to_prop b)
  | PUnop  (Not, a)    -> PNot (pred_to_prop a)
  | PForall (x, _, b)  -> PForallP (x.name, pred_to_prop b)
  | PExists (x, _, b)  -> PExistsP (x.name, pred_to_prop b)
  | _                  -> PAtom p

(* Structural predicate equality — used for reflexivity checks *)
let rec pred_eq a b = match a, b with
  | PTrue,  PTrue  -> true
  | PFalse, PFalse -> true
  | PInt n,  PInt m  -> n = m
  | PBool a, PBool b -> a = b
  | PVar x,  PVar y  -> x.name = y.name
  | PResult, PResult -> true
  | PBinop (op1, l1, r1), PBinop (op2, l2, r2) ->
      op1 = op2 && pred_eq l1 l2 && pred_eq r1 r2
  | PUnop (op1, p1), PUnop (op2, p2) ->
      op1 = op2 && pred_eq p1 p2
  | PIte (c1, t1, e1), PIte (c2, t2, e2) ->
      pred_eq c1 c2 && pred_eq t1 t2 && pred_eq e1 e2
  | PField (p1, f1), PField (p2, f2) -> f1 = f2 && pred_eq p1 p2
  | PIndex (a1, i1), PIndex (a2, i2) -> pred_eq a1 a2 && pred_eq i1 i2
  | _ -> false

(* Substitute variable x with pred repl inside a prop *)
let rec subst_prop x repl = function
  | PAtom p -> PAtom (subst_pred_in x repl p)
  | PAnd (a, b) -> PAnd (subst_prop x repl a, subst_prop x repl b)
  | POr  (a, b) -> POr  (subst_prop x repl a, subst_prop x repl b)
  | PImpl(a, b) -> PImpl(subst_prop x repl a, subst_prop x repl b)
  | PNot a      -> PNot (subst_prop x repl a)
  | PForallP (y, body) when y = x -> PForallP (y, body)
  | PForallP (y, body) -> PForallP (y, subst_prop x repl body)
  | PExistsP (y, body) when y = x -> PExistsP (y, body)
  | PExistsP (y, body) -> PExistsP (y, subst_prop x repl body)

(* Convert prop back to pred so it can be added to the proof context.
   For PForallP/PExistsP the type is approximated as u64 — sufficient for Z3 Int mode. *)
let rec prop_to_pred = function
  | PAtom p -> p
  | PAnd (a, b)  -> PBinop (And,     prop_to_pred a, prop_to_pred b)
  | POr  (a, b)  -> PBinop (Or,      prop_to_pred a, prop_to_pred b)
  | PImpl(a, b)  -> PBinop (Implies, prop_to_pred a, prop_to_pred b)
  | PNot a       -> PUnop  (Not, prop_to_pred a)
  | PForallP (x, body) ->
      PForall ({name=x; loc=dummy_loc_pk}, TPrim (TUint U64), prop_to_pred body)
  | PExistsP (x, body) ->
      PExists ({name=x; loc=dummy_loc_pk}, TPrim (TUint U64), prop_to_pred body)

(* Global proved-lemma registry: name → (params, pred statement)
   Params are stored so the pred can be universally quantified over them
   when injected as Z3 axioms: forall p1 : t1, ..., stmt. *)
let proved_lemmas : (string * (ident * ty) list * pred) list ref = ref []

let register_lemma name params stmt =
  proved_lemmas := (name, params, stmt) :: !proved_lemmas

(* Check a proof term against a proposition.
   ctx: proof context (vars + assumes) for SMT leaf steps.
   Returns Ok () if the proof term is valid, Error msg otherwise. *)
let rec check_proof ctx prop term : (unit, string) result =
  match prop, term with

  (* ---- Axiom — accepted unconditionally (audit trail entry) ---- *)
  | _, PTAxiom -> Ok ()

  (* ---- Auto — delegate to SMT (Tier 1) ---- *)
  | _, PTAuto ->
      (* Convert the full prop (including compound connectives) to a pred and
         check with Z3. prop_to_pred handles PAnd/POr/PImpl/PNot/PForallP/PExistsP. *)
      let p = prop_to_pred prop in
      (match Z3Bridge.check_valid ctx p with
       | Z3Bridge.Unsat -> Ok ()
       | Z3Bridge.Sat ->
           Error "PTAuto: SMT found counterexample — goal is not provable"
       | Z3Bridge.Unknown msg ->
           Error (Printf.sprintf "PTAuto: SMT inconclusive (%s)" msg))

  (* ---- Reflexivity: a = a ---- *)
  | PAtom PTrue, PTRefl -> Ok ()
  | PAtom (PBinop (Eq, l, r)), PTRefl when pred_eq l r -> Ok ()
  | PAtom p, PTRefl when pred_eq p PTrue -> Ok ()

  (* ---- Symmetry: if we can prove Q=P, we can prove P=Q ---- *)
  | PAtom (PBinop (Eq, l, r)), PTSymm inner ->
      check_proof ctx (PAtom (PBinop (Eq, r, l))) inner

  (* ---- Transitivity: a=b and b=c → a=c ---- *)
  (* Requires explicit intermediate term: trans(b_expr, proof_a_eq_b, proof_b_eq_c) *)
  | PAtom (PBinop (Eq, a, c)), PTTrans (mid_expr, p1, p2) ->
      let b = proof_expr_to_pred mid_expr in
      (match check_proof ctx (PAtom (PBinop (Eq, a, b))) p1 with
       | Error e -> Error (Printf.sprintf "PTTrans left sub-proof (a=b): %s" e)
       | Ok () ->
           match check_proof ctx (PAtom (PBinop (Eq, b, c))) p2 with
           | Error e -> Error (Printf.sprintf "PTTrans right sub-proof (b=c): %s" e)
           | Ok () -> Ok ())
  | _, PTTrans _ ->
      Error "PTTrans: goal must be an equality a = c; write trans(b, proof_a_eq_b, proof_b_eq_c)"

  (* ---- Conjunction: prove P and Q separately ---- *)
  | PAnd (p, q), PTCong [tp; tq] ->
      (match check_proof ctx p tp, check_proof ctx q tq with
       | Ok (), Ok () -> Ok ()
       | Error e, _   -> Error e
       | _, Error e   -> Error e)
  | PAnd (p, q), PTCong (tp :: tq :: _) ->
      (* Tolerate extra args *)
      (match check_proof ctx p tp, check_proof ctx q tq with
       | Ok (), Ok () -> Ok ()
       | Error e, _   -> Error e
       | _, Error e   -> Error e)

  (* ---- Implication: assume antecedent, prove consequent ---- *)
  | PImpl (ant, q), _ ->
      (* Add antecedent to context as a fact *)
      let ctx' = match ant with
        | PAtom p -> ctx_add_assume ctx p
        | _ -> ctx
      in
      check_proof ctx' q term

  (* ---- Apply a proved lemma ---- *)
  (* The lemma is injected as a Z3 axiom via ctx.pc_lemmas = !proved_lemmas.
     We verify via SMT that the goal follows from the available axioms (including
     this lemma), so mere name existence is not enough — the lemma must actually
     imply the goal in the current context. *)
  | _, PTBy (lemma_name, _args) ->
      (match List.find_opt (fun (n,_,_) -> n = lemma_name.name) !proved_lemmas with
       | None ->
           Error (Printf.sprintf "lemma '%s' has not been proved" lemma_name.name)
       | Some _ ->
           (* All proved lemmas are in ctx.pc_lemmas (set by check_lemma).
              Ask Z3 whether the goal follows. *)
           let goal_pred = prop_to_pred prop in
           (match Z3Bridge.check_valid ctx goal_pred with
            | Z3Bridge.Unsat -> Ok ()
            | Z3Bridge.Sat ->
                Error (Printf.sprintf
                  "PTBy: lemma '%s' does not imply the goal — \
                   check that the lemma's statement is relevant" lemma_name.name)
            | Z3Bridge.Unknown msg ->
                Error (Printf.sprintf
                  "PTBy: SMT inconclusive when applying lemma '%s' (%s)"
                  lemma_name.name msg)))

  (* ---- Natural number induction on variable x ---- *)
  (* Schema: to prove P(x) for all x : u64,
       base:  prove P(x)[x := 0]           (using base_pt against Z3 / PTAuto)
       step:  given IH = P(x), prove P(x)[x := x+1]  (step_pt in ctx + IH) *)
  | _, PTInduct (x, base_pt, step_pt) ->
      let x_var = { name = x.name; loc = dummy_loc_pk } in
      (* Base case: substitute x := 0 *)
      let base_prop = subst_prop x.name (PInt 0L) prop in
      (match check_proof ctx base_prop base_pt with
       | Error e -> Error (Printf.sprintf "induction base case (%s=0): %s" x.name e)
       | Ok () ->
           (* Step case: add IH to context, substitute x := x+1 in goal *)
           let ih = prop_to_pred prop in
           let ctx_ih = ctx_add_assume ctx ih in
           let step_prop = subst_prop x.name
             (PBinop (Add, PVar x_var, PInt 1L)) prop in
           (match check_proof ctx_ih step_prop step_pt with
            | Ok () -> Ok ()
            | Error e ->
                Error (Printf.sprintf "induction step case (%s → %s+1): %s"
                  x.name x.name e)))

  (* ---- Boolean / enum case analysis ---- *)
  (* case e { proof_true, proof_false } splits on e being truthy or falsy.
     Each branch gets the branch condition added to the context. *)
  | _, PTCase (scrut, cases) ->
      let scrut_pred = proof_expr_to_pred scrut in
      let branch_preds = match cases with
        | [_; _] ->
            (* Two branches: treat as boolean split *)
            [scrut_pred; PUnop (Not, scrut_pred)]
        | _ ->
            (* n branches: add no extra assumption per branch — user must use PTAuto *)
            List.map (fun _ -> PBool true) cases
      in
      let indexed = List.combine branch_preds cases in
      let results = List.mapi (fun i (cond, branch_pt) ->
        let ctx' = ctx_add_assume ctx cond in
        match check_proof ctx' prop branch_pt with
        | Ok () -> Ok ()
        | Error e -> Error (Printf.sprintf "case branch %d: %s" i e)
      ) indexed in
      List.fold_left (fun acc r ->
        match acc, r with Ok (), Ok () -> Ok () | Error e, _ | _, Error e -> Error e
      ) (Ok ()) results

  (* ---- Existential witness: provide concrete value for exists x. P(x) ---- *)
  | PExistsP (x, body), PTWitness w ->
      let w_pred = proof_expr_to_pred w in
      (* Substitute witness for the quantified variable, then auto-check *)
      let instantiated = subst_prop x w_pred body in
      check_proof ctx instantiated PTAuto

  (* ---- Mismatch ---- *)
  | _ ->
      Error (Printf.sprintf "proof term does not match proposition")

(* Check a lemma in a proof block.
   Validates the proof term and, if successful, registers the lemma.
   Returns (Some error_msg) on failure, None on success. *)
let check_lemma ctx (lem : lemma) : string option =
  (* Enrich ctx with previously proved lemmas so 'auto' steps within
     this lemma's proof can use them as axioms. *)
  let ctx' = { ctx with pc_lemmas = !proved_lemmas } in
  let prop = pred_to_prop lem.lem_stmt in
  match check_proof ctx' prop lem.lem_proof with
  | Ok () ->
      register_lemma lem.lem_name.name lem.lem_params lem.lem_stmt;
      None
  | Error msg ->
      Some (Printf.sprintf "%s:%d: lemma '%s' proof failed: %s"
        lem.lem_name.loc.file lem.lem_name.loc.line
        lem.lem_name.name msg)

(* ------------------------------------------------------------------ *)
(* Error reporting                                                      *)
(* ------------------------------------------------------------------ *)

type proof_error = {
  pe_loc:     loc;
  pe_kind:    obligation_kind;
  pe_pred:    pred;
  pe_hint:    tier2_hint option;
  pe_message: string;
}

let format_error e =
  Printf.sprintf "%s:%d:%d: proof obligation failed\n  %s\n%s"
    e.pe_loc.file e.pe_loc.line e.pe_loc.col
    e.pe_message
    (match e.pe_hint with
     | None -> ""
     | Some (HintDecreases s) -> "  hint: " ^ s
     | Some (HintInvariant s) -> "  hint: " ^ s
     | Some (HintWitness s)   -> "  hint: " ^ s
     | Some (HintLemma s)     -> "  hint: " ^ s
     | Some (HintAssume s)    -> "  hint: " ^ s)
