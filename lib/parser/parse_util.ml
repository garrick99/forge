(* FORGE parse utilities — helpers for building AST nodes from parser actions *)

open Ast

(* Build a loc from Menhir's $startpos *)
let loc_of_pos (p : Lexing.position) : loc = {
  file = p.pos_fname;
  line = p.pos_lnum;
  col  = p.pos_cnum - p.pos_bol;
}

let mk_loc startpos = loc_of_pos startpos

(* Build an ident *)
let mk_ident name startpos : ident =
  { name; loc = loc_of_pos startpos }

(* Build an expr node *)
let mk_expr desc startpos : expr =
  { expr_desc = desc; expr_loc = loc_of_pos startpos; expr_ty = None }

(* Build a stmt node *)
let mk_stmt desc startpos : stmt =
  { stmt_desc = desc; stmt_loc = loc_of_pos startpos }

(* Build an item node *)
let mk_item desc startpos : item =
  { item_desc = desc; item_loc = loc_of_pos startpos }

(* Desugar augmented assignment: x += e  =>  x = x + e *)
let desugar_aug_assign lhs op rhs pos =
  let binop_expr = mk_expr (EBinop (op, lhs, rhs)) pos in
  mk_expr (EAssign (lhs, binop_expr)) pos

(* Build a block expression from a list of stmts and optional final expr *)
let mk_block stmts ret pos =
  mk_expr (EBlock (stmts, ret)) pos

(* Convert a pred-in-expression context to a pred.
   Expressions used as predicates (in requires/ensures) go through this. *)
let rec expr_to_pred (e : expr) : pred =
  match e.expr_desc with
  | ELit (LBool true)  -> PTrue
  | ELit (LBool false) -> PFalse
  | ELit (LInt (n, _)) -> PInt n
  | EVar id            -> PVar id
  | EBinop (op, l, r)  -> PBinop (op, expr_to_pred l, expr_to_pred r)
  | EUnop (Not, e)     -> PUnop (Not, expr_to_pred e)
  | EUnop (Neg, e)     -> PUnop (Neg, expr_to_pred e)
  | EUnop (BitNot, e)  -> PUnop (BitNot, expr_to_pred e)
  | ECall ({ expr_desc = EVar f; _ }, args) ->
      PApp (f, List.map expr_to_pred args)
  | _ ->
      (* For complex expressions, wrap in a predicate variable —
         type checker will handle this *)
      PVar { name = "__expr__"; loc = e.expr_loc }

(* Build a function type from components *)
let mk_fn_ty params ret requires ensures : fn_ty =
  { params; ret; requires; ensures }

(* Intersperse: build a sequence of binary operations left-associatively *)
let left_assoc op l r pos =
  mk_expr (EBinop (op, l, r)) pos
