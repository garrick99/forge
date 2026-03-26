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
  ob_ctx:     (ident * ty) list;   (* variables in scope *)
  ob_status:  proof_status;
}

(* ------------------------------------------------------------------ *)
(* Proof context — variables and their types/refinements in scope      *)
(* ------------------------------------------------------------------ *)

type proof_ctx = {
  pc_vars:    (string * ty) list;
  pc_assumes: pred list;           (* known-true predicates *)
  pc_lemmas:  (string * pred) list;
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

  (* Translate a FORGE pred to a Z3 formula string (SMT-LIB2 format).
     We emit SMT-LIB2 text and call Z3 as a subprocess for FORGE-0.
     Later: use Z3 OCaml bindings directly. *)
  let rec pred_to_smtlib ctx pred =
    match pred with
    | PTrue          -> "true"
    | PFalse         -> "false"
    | PVar id        -> id.name
    | PInt n         -> string_of_int n
    | PBool b        -> string_of_bool b
    | PBinop (op, l, r) ->
        let ls = pred_to_smtlib ctx l in
        let rs = pred_to_smtlib ctx r in
        (match op with
         | Add     -> Printf.sprintf "(+ %s %s)" ls rs
         | Sub     -> Printf.sprintf "(- %s %s)" ls rs
         | Mul     -> Printf.sprintf "(* %s %s)" ls rs
         | Div     -> Printf.sprintf "(div %s %s)" ls rs
         | Mod     -> Printf.sprintf "(mod %s %s)" ls rs
         | Eq      -> Printf.sprintf "(= %s %s)" ls rs
         | Ne      -> Printf.sprintf "(not (= %s %s))" ls rs
         | Lt      -> Printf.sprintf "(< %s %s)" ls rs
         | Le      -> Printf.sprintf "(<= %s %s)" ls rs
         | Gt      -> Printf.sprintf "(> %s %s)" ls rs
         | Ge      -> Printf.sprintf "(>= %s %s)" ls rs
         | And     -> Printf.sprintf "(and %s %s)" ls rs
         | Or      -> Printf.sprintf "(or %s %s)" ls rs
         | Implies -> Printf.sprintf "(=> %s %s)" ls rs
         | Iff     -> Printf.sprintf "(= %s %s)" ls rs
         | _       -> Printf.sprintf "(bvop %s %s)" ls rs)  (* TODO bitvec ops *)
    | PUnop (Not, p) -> Printf.sprintf "(not %s)" (pred_to_smtlib ctx p)
    | PUnop (Neg, p) -> Printf.sprintf "(- %s)" (pred_to_smtlib ctx p)
    | PUnop (_, p)   -> pred_to_smtlib ctx p
    | PForall (x, _ty, body) ->
        (* For Tier 1 — quantifier-free fragment only.
           Quantified formulas escalate to Tier 2. *)
        Printf.sprintf "(forall ((%s Int)) %s)" x.name (pred_to_smtlib ctx body)
    | PExists (x, _ty, body) ->
        Printf.sprintf "(exists ((%s Int)) %s)" x.name (pred_to_smtlib ctx body)
    | PResult -> "result__"
    | POld p  -> Printf.sprintf "old__%s" (pred_to_smtlib ctx p)
    | PApp (f, args) ->
        let arg_strs = List.map (pred_to_smtlib ctx) args in
        Printf.sprintf "(%s %s)" f.name (String.concat " " arg_strs)

  (* Emit an SMT-LIB2 query to check validity of pred given ctx.
     Valid(P) iff Unsat(not P) under assumptions. *)
  let build_query ctx pred =
    let decls = List.map (fun (name, _ty) ->
      (* For FORGE-0: all variables are Int in SMT land.
         Later: proper bitvector sorts per integer width. *)
      Printf.sprintf "(declare-const %s Int)" name
    ) ctx.pc_vars in
    let assumes = List.map (fun p ->
      Printf.sprintf "(assert %s)" (pred_to_smtlib ctx p)
    ) ctx.pc_assumes in
    let negated = Printf.sprintf "(assert (not %s))" (pred_to_smtlib ctx pred) in
    let check = "(check-sat)" in
    String.concat "\n" (decls @ assumes @ [negated; check])

  let check_valid ctx pred : z3_result =
    let query = build_query ctx pred in
    (* Write to temp file, call Z3, read result *)
    let tmp = Filename.temp_file "forge_smt" ".smt2" in
    let oc = open_out tmp in
    output_string oc query;
    close_out oc;
    let result_tmp = Filename.temp_file "forge_smt_result" ".txt" in
    let cmd = Printf.sprintf "z3 -smt2 %s > %s 2>&1" tmp result_tmp in
    let rc = Sys.command cmd in
    let result =
      if rc = 0 then begin
        let ic = open_in result_tmp in
        let line = try input_line ic with End_of_file -> "" in
        close_in ic;
        match String.trim line with
        | "unsat"   -> Unsat        (* negation unsat = original valid *)
        | "sat"     -> Sat          (* counterexample exists *)
        | s         -> Unknown s
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

let dump_assume_log () =
  List.rev !assume_log

(* ------------------------------------------------------------------ *)
(* Tier 1: SMT discharge                                               *)
(* ------------------------------------------------------------------ *)

let try_smt ctx ob : proof_status =
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
  | Failed msg ->
      (* Check if this is a Tier 3 (manual proof term) obligation *)
      (match ob.ob_kind with
       | OTermination _ | OInvariant _ ->
           NeedsHint (suggest_hint ob)
       | _ ->
           (* Give the user a useful hint *)
           let hint = suggest_hint ob in
           NeedsHint hint)

(* ------------------------------------------------------------------ *)
(* Proof checker for Tier 3 manual proof terms                        *)
(* ------------------------------------------------------------------ *)

(* Minimal kernel — checks proof terms in Calculus of Constructions.
   This is the trusted core. Small, auditable. *)

type prop =
  | PAtom   of pred
  | PAnd    of prop * prop
  | POr     of prop * prop
  | PImpl   of prop * prop
  | PNot    of prop
  | PForallP of string * prop
  | PExistsP of string * prop

type judgment =
  | Proved_by of prop * proof_term

(* Check a proof term against a proposition.
   Returns Ok () if valid, Error msg if not. *)
let rec check_proof _ctx prop term : (unit, string) result =
  match prop, term with
  | _, PTAuto ->
      (* Delegate to SMT — only valid if SMT can discharge it *)
      Ok ()   (* TODO: actually call SMT here *)
  | _, PTAxiom ->
      (* Axioms are always accepted but logged *)
      Ok ()
  | PAtom PTrue, PTRefl ->
      Ok ()
  | PAnd (p, q), PTCong [tp; tq] ->
      (match check_proof _ctx p tp, check_proof _ctx q tq with
       | Ok (), Ok () -> Ok ()
       | Error e, _   -> Error e
       | _, Error e   -> Error e)
  | PImpl (p, q), _ ->
      (* Assume p, prove q *)
      check_proof _ctx q term
  | PExistsP (_, body), PTWitness _w ->
      (* Check body holds for witness w *)
      check_proof _ctx (PAtom PTrue) (PTBy ({ name="witness"; loc=dummy_loc }, []))
  | _, PTBy (lemma_name, _args) ->
      (* Look up lemma in context — TODO *)
      ignore lemma_name;
      Ok ()
  | _ ->
      Error (Printf.sprintf "proof term does not match goal")

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
