
type token = Token.token

# 1 "lib/parser/parser.mly"
  
(* FORGE Parser — Menhir LR(1) grammar
   Full grammar: types, expressions, statements, proof blocks, contracts *)

open Ast
open Parse_util
open Lexing

# 14 "lib/parser/q2_inferred.mli"

let menhir_begin_marker =
  0

and (xv_type_params, xv_type_def, xv_type_args, xv_ty, xv_tlist_ty_, xv_tlist_struct_field_init_, xv_tlist_param_, xv_tlist_expr_, xv_struct_field_init, xv_struct_field, xv_struct_def, xv_stmt, xv_separated_nonempty_list_DCOLON_ident_, xv_separated_nonempty_list_COMMA_ty_, xv_separated_nonempty_list_COMMA_proof_term_, xv_separated_nonempty_list_COMMA_pred_, xv_separated_nonempty_list_COMMA_pattern_, xv_separated_nonempty_list_COMMA_kind_param_, xv_separated_nonempty_list_COMMA_ident_, xv_separated_nonempty_list_COMMA_expr_, xv_separated_nonempty_list_COMMA_IDENT_, xv_separated_list_COMMA_proof_term_, xv_separated_list_COMMA_pred_, xv_separated_list_COMMA_pattern_, xv_separated_list_COMMA_expr_, xv_separated_list_COMMA_IDENT_, xv_return_expr, xv_requires_clause, xv_raw_expr, xv_proof_term, xv_proof_expr, xv_proof_contents, xv_program, xv_prim_ty_kw, xv_pred, xv_preceded_INVARIANT_pred_, xv_preceded_IF_pred_, xv_preceded_ELSE_else_branch_, xv_preceded_DECREASES_pred_, xv_preceded_COLON_ty_, xv_preceded_ARROW_ty_, xv_pattern, xv_param, xv_option_preceded_IF_pred__, xv_option_preceded_ELSE_else_branch__, xv_option_preceded_DECREASES_pred__, xv_option_preceded_COLON_ty__, xv_option_preceded_ARROW_ty__, xv_option_extern_link_, xv_option_expr_, xv_option_decreases_clause_, xv_option_STRING_, xv_match_expr, xv_match_arm, xv_loption_separated_nonempty_list_COMMA_proof_term__, xv_loption_separated_nonempty_list_COMMA_pred__, xv_loption_separated_nonempty_list_COMMA_pattern__, xv_loption_separated_nonempty_list_COMMA_expr__, xv_loption_separated_nonempty_list_COMMA_IDENT__, xv_loop_expr, xv_list_struct_field_, xv_list_stmt_, xv_list_requires_clause_, xv_list_proof_term_, xv_list_preceded_INVARIANT_pred__, xv_list_match_arm_, xv_list_lemma_def_, xv_list_item_, xv_list_invariant_clause_, xv_list_enum_variant_, xv_list_ensures_clause_, xv_list_attr_clause_, xv_list_assume_in_proof_, xv_linearity, xv_lemma_def, xv_kind_params, xv_kind_param, xv_item, xv_invariant_clause, xv_impl_def, xv_if_expr, xv_ident, xv_fn_def, xv_fn_body, xv_extern_link, xv_extern_def, xv_expr, xv_enum_variant, xv_enum_def, xv_ensures_clause, xv_else_branch, xv_decreases_clause, xv_block_stmts, xv_block_expr, xv_attr_clause, xv_atom_expr, xv_assume_in_proof, xv_assume_expr, xv_arm_body, xv_alt_pattern) =
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 23 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_DCOLON_ident_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 27 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
  x
# 31 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 36 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_DCOLON_ident_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 240 "<standard.mly>"
  x
# 41 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 46 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_DCOLON_ident_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 51 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_ty_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 55 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 242 "<standard.mly>"
  x
# 59 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 63 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 68 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_COMMA_ty_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 240 "<standard.mly>"
  x
# 73 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 77 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 82 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_COMMA_ty_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 87 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_proof_term_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 91 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
  x
# 95 "lib/parser/q2_inferred.mli"
   : 'tv_proof_term) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 100 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_COMMA_proof_term_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 240 "<standard.mly>"
  x
# 105 "lib/parser/q2_inferred.mli"
   : 'tv_proof_term) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 110 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_COMMA_proof_term_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 115 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_pred_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 119 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 242 "<standard.mly>"
  x
# 123 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 127 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 132 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_COMMA_pred_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 240 "<standard.mly>"
  x
# 137 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 141 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 146 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_COMMA_pred_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 151 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_pattern_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 155 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
  x
# 159 "lib/parser/q2_inferred.mli"
   : 'tv_pattern) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 164 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_COMMA_pattern_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 240 "<standard.mly>"
  x
# 169 "lib/parser/q2_inferred.mli"
   : 'tv_pattern) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 174 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_COMMA_pattern_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 179 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_kind_param_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 183 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
  x
# 187 "lib/parser/q2_inferred.mli"
   : 'tv_kind_param) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 192 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_COMMA_kind_param_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 240 "<standard.mly>"
  x
# 197 "lib/parser/q2_inferred.mli"
   : 'tv_kind_param) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 202 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_COMMA_kind_param_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 207 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_ident_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 211 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
  x
# 215 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 220 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_COMMA_ident_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 240 "<standard.mly>"
  x
# 225 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 230 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_COMMA_ident_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 235 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_expr_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 239 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 242 "<standard.mly>"
  x
# 243 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 247 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 252 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_COMMA_expr_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 240 "<standard.mly>"
  x
# 257 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 261 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 266 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_COMMA_expr_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 271 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_IDENT_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 275 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
  x
# 279 "lib/parser/q2_inferred.mli"
   : (
# 19 "lib/parser/parser.mly"
       (string)
# 283 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 288 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_COMMA_IDENT_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 240 "<standard.mly>"
  x
# 293 "lib/parser/q2_inferred.mli"
   : (
# 19 "lib/parser/parser.mly"
       (string)
# 297 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 302 "lib/parser/q2_inferred.mli"
     : 'tv_separated_nonempty_list_COMMA_IDENT_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 231 "<standard.mly>"
  xs
# 307 "lib/parser/q2_inferred.mli"
   : 'tv_loption_separated_nonempty_list_COMMA_proof_term__) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) ->
    (
# 232 "<standard.mly>"
    ( xs )
# 312 "lib/parser/q2_inferred.mli"
     : 'tv_separated_list_COMMA_proof_term_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 231 "<standard.mly>"
  xs
# 317 "lib/parser/q2_inferred.mli"
   : 'tv_loption_separated_nonempty_list_COMMA_pred__) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) ->
    (
# 232 "<standard.mly>"
    ( xs )
# 322 "lib/parser/q2_inferred.mli"
     : 'tv_separated_list_COMMA_pred_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 231 "<standard.mly>"
  xs
# 327 "lib/parser/q2_inferred.mli"
   : 'tv_loption_separated_nonempty_list_COMMA_pattern__) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) ->
    (
# 232 "<standard.mly>"
    ( xs )
# 332 "lib/parser/q2_inferred.mli"
     : 'tv_separated_list_COMMA_pattern_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 231 "<standard.mly>"
  xs
# 337 "lib/parser/q2_inferred.mli"
   : 'tv_loption_separated_nonempty_list_COMMA_expr__) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) ->
    (
# 232 "<standard.mly>"
    ( xs )
# 342 "lib/parser/q2_inferred.mli"
     : 'tv_separated_list_COMMA_expr_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 231 "<standard.mly>"
  xs
# 347 "lib/parser/q2_inferred.mli"
   : 'tv_loption_separated_nonempty_list_COMMA_IDENT__) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) ->
    (
# 232 "<standard.mly>"
    ( xs )
# 352 "lib/parser/q2_inferred.mli"
     : 'tv_separated_list_COMMA_IDENT_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 182 "<standard.mly>"
           x
# 357 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 361 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) (
# 181 "<standard.mly>"
                                     _1
# 366 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 183 "<standard.mly>"
    ( x )
# 371 "lib/parser/q2_inferred.mli"
     : 'tv_preceded_INVARIANT_pred_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 182 "<standard.mly>"
           x
# 376 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 380 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) (
# 181 "<standard.mly>"
                                     _1
# 385 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 183 "<standard.mly>"
    ( x )
# 390 "lib/parser/q2_inferred.mli"
     : 'tv_preceded_IF_pred_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 182 "<standard.mly>"
           x
# 395 "lib/parser/q2_inferred.mli"
   : 'tv_else_branch) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) (
# 181 "<standard.mly>"
                                     _1
# 400 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 183 "<standard.mly>"
    ( x )
# 405 "lib/parser/q2_inferred.mli"
     : 'tv_preceded_ELSE_else_branch_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 182 "<standard.mly>"
           x
# 410 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 414 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) (
# 181 "<standard.mly>"
                                     _1
# 419 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 183 "<standard.mly>"
    ( x )
# 424 "lib/parser/q2_inferred.mli"
     : 'tv_preceded_DECREASES_pred_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 182 "<standard.mly>"
           x
# 429 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 433 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) (
# 181 "<standard.mly>"
                                     _1
# 438 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 183 "<standard.mly>"
    ( x )
# 443 "lib/parser/q2_inferred.mli"
     : 'tv_preceded_COLON_ty_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 182 "<standard.mly>"
           x
# 448 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 452 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) (
# 181 "<standard.mly>"
                                     _1
# 457 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 183 "<standard.mly>"
    ( x )
# 462 "lib/parser/q2_inferred.mli"
     : 'tv_preceded_ARROW_ty_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 467 "lib/parser/q2_inferred.mli"
   : 'tv_preceded_IF_pred_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 472 "lib/parser/q2_inferred.mli"
     : 'tv_option_preceded_IF_pred__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 478 "lib/parser/q2_inferred.mli"
     : 'tv_option_preceded_IF_pred__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 483 "lib/parser/q2_inferred.mli"
   : 'tv_preceded_ELSE_else_branch_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 488 "lib/parser/q2_inferred.mli"
     : 'tv_option_preceded_ELSE_else_branch__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 494 "lib/parser/q2_inferred.mli"
     : 'tv_option_preceded_ELSE_else_branch__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 499 "lib/parser/q2_inferred.mli"
   : 'tv_preceded_DECREASES_pred_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 504 "lib/parser/q2_inferred.mli"
     : 'tv_option_preceded_DECREASES_pred__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 510 "lib/parser/q2_inferred.mli"
     : 'tv_option_preceded_DECREASES_pred__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 515 "lib/parser/q2_inferred.mli"
   : 'tv_preceded_COLON_ty_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 520 "lib/parser/q2_inferred.mli"
     : 'tv_option_preceded_COLON_ty__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 526 "lib/parser/q2_inferred.mli"
     : 'tv_option_preceded_COLON_ty__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 531 "lib/parser/q2_inferred.mli"
   : 'tv_preceded_ARROW_ty_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 536 "lib/parser/q2_inferred.mli"
     : 'tv_option_preceded_ARROW_ty__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 542 "lib/parser/q2_inferred.mli"
     : 'tv_option_preceded_ARROW_ty__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 547 "lib/parser/q2_inferred.mli"
   : 'tv_extern_link) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 552 "lib/parser/q2_inferred.mli"
     : 'tv_option_extern_link_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 558 "lib/parser/q2_inferred.mli"
     : 'tv_option_extern_link_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 115 "<standard.mly>"
  x
# 563 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 567 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 572 "lib/parser/q2_inferred.mli"
     : 'tv_option_expr_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 578 "lib/parser/q2_inferred.mli"
     : 'tv_option_expr_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 583 "lib/parser/q2_inferred.mli"
   : 'tv_decreases_clause) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 588 "lib/parser/q2_inferred.mli"
     : 'tv_option_decreases_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 594 "lib/parser/q2_inferred.mli"
     : 'tv_option_decreases_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 599 "lib/parser/q2_inferred.mli"
   : (
# 18 "lib/parser/parser.mly"
       (string)
# 603 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 608 "lib/parser/q2_inferred.mli"
     : 'tv_option_STRING_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 614 "lib/parser/q2_inferred.mli"
     : 'tv_option_STRING_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 143 "<standard.mly>"
  x
# 619 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_proof_term_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 144 "<standard.mly>"
    ( x )
# 624 "lib/parser/q2_inferred.mli"
     : 'tv_loption_separated_nonempty_list_COMMA_proof_term__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 142 "<standard.mly>"
    ( [] )
# 630 "lib/parser/q2_inferred.mli"
     : 'tv_loption_separated_nonempty_list_COMMA_proof_term__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 143 "<standard.mly>"
  x
# 635 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_pred_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 144 "<standard.mly>"
    ( x )
# 640 "lib/parser/q2_inferred.mli"
     : 'tv_loption_separated_nonempty_list_COMMA_pred__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 142 "<standard.mly>"
    ( [] )
# 646 "lib/parser/q2_inferred.mli"
     : 'tv_loption_separated_nonempty_list_COMMA_pred__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 143 "<standard.mly>"
  x
# 651 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_pattern_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 144 "<standard.mly>"
    ( x )
# 656 "lib/parser/q2_inferred.mli"
     : 'tv_loption_separated_nonempty_list_COMMA_pattern__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 142 "<standard.mly>"
    ( [] )
# 662 "lib/parser/q2_inferred.mli"
     : 'tv_loption_separated_nonempty_list_COMMA_pattern__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 143 "<standard.mly>"
  x
# 667 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_expr_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 144 "<standard.mly>"
    ( x )
# 672 "lib/parser/q2_inferred.mli"
     : 'tv_loption_separated_nonempty_list_COMMA_expr__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 142 "<standard.mly>"
    ( [] )
# 678 "lib/parser/q2_inferred.mli"
     : 'tv_loption_separated_nonempty_list_COMMA_expr__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 143 "<standard.mly>"
  x
# 683 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_IDENT_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 144 "<standard.mly>"
    ( x )
# 688 "lib/parser/q2_inferred.mli"
     : 'tv_loption_separated_nonempty_list_COMMA_IDENT__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 142 "<standard.mly>"
    ( [] )
# 694 "lib/parser/q2_inferred.mli"
     : 'tv_loption_separated_nonempty_list_COMMA_IDENT__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 699 "lib/parser/q2_inferred.mli"
   : 'tv_list_struct_field_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 703 "lib/parser/q2_inferred.mli"
   : 'tv_struct_field) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 708 "lib/parser/q2_inferred.mli"
     : 'tv_list_struct_field_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 714 "lib/parser/q2_inferred.mli"
     : 'tv_list_struct_field_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 719 "lib/parser/q2_inferred.mli"
   : 'tv_list_stmt_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 723 "lib/parser/q2_inferred.mli"
   : 'tv_stmt) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 728 "lib/parser/q2_inferred.mli"
     : 'tv_list_stmt_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 734 "lib/parser/q2_inferred.mli"
     : 'tv_list_stmt_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 739 "lib/parser/q2_inferred.mli"
   : 'tv_list_requires_clause_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 743 "lib/parser/q2_inferred.mli"
   : 'tv_requires_clause) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 748 "lib/parser/q2_inferred.mli"
     : 'tv_list_requires_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 754 "lib/parser/q2_inferred.mli"
     : 'tv_list_requires_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 759 "lib/parser/q2_inferred.mli"
   : 'tv_list_proof_term_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 763 "lib/parser/q2_inferred.mli"
   : 'tv_proof_term) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 768 "lib/parser/q2_inferred.mli"
     : 'tv_list_proof_term_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 774 "lib/parser/q2_inferred.mli"
     : 'tv_list_proof_term_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 779 "lib/parser/q2_inferred.mli"
   : 'tv_list_preceded_INVARIANT_pred__) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 783 "lib/parser/q2_inferred.mli"
   : 'tv_preceded_INVARIANT_pred_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 788 "lib/parser/q2_inferred.mli"
     : 'tv_list_preceded_INVARIANT_pred__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 794 "lib/parser/q2_inferred.mli"
     : 'tv_list_preceded_INVARIANT_pred__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 799 "lib/parser/q2_inferred.mli"
   : 'tv_list_match_arm_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 803 "lib/parser/q2_inferred.mli"
   : 'tv_match_arm) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 808 "lib/parser/q2_inferred.mli"
     : 'tv_list_match_arm_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 814 "lib/parser/q2_inferred.mli"
     : 'tv_list_match_arm_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 819 "lib/parser/q2_inferred.mli"
   : 'tv_list_lemma_def_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 823 "lib/parser/q2_inferred.mli"
   : 'tv_lemma_def) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 828 "lib/parser/q2_inferred.mli"
     : 'tv_list_lemma_def_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 834 "lib/parser/q2_inferred.mli"
     : 'tv_list_lemma_def_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 839 "lib/parser/q2_inferred.mli"
   : 'tv_list_item_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) ((
# 212 "<standard.mly>"
  x
# 843 "lib/parser/q2_inferred.mli"
   : 'tv_item) : (
# 115 "lib/parser/parser.mly"
       (Ast.item)
# 847 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 852 "lib/parser/q2_inferred.mli"
     : 'tv_list_item_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 858 "lib/parser/q2_inferred.mli"
     : 'tv_list_item_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 863 "lib/parser/q2_inferred.mli"
   : 'tv_list_invariant_clause_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 867 "lib/parser/q2_inferred.mli"
   : 'tv_invariant_clause) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 872 "lib/parser/q2_inferred.mli"
     : 'tv_list_invariant_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 878 "lib/parser/q2_inferred.mli"
     : 'tv_list_invariant_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 883 "lib/parser/q2_inferred.mli"
   : 'tv_list_enum_variant_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 887 "lib/parser/q2_inferred.mli"
   : 'tv_enum_variant) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 892 "lib/parser/q2_inferred.mli"
     : 'tv_list_enum_variant_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 898 "lib/parser/q2_inferred.mli"
     : 'tv_list_enum_variant_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 903 "lib/parser/q2_inferred.mli"
   : 'tv_list_ensures_clause_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 907 "lib/parser/q2_inferred.mli"
   : 'tv_ensures_clause) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 912 "lib/parser/q2_inferred.mli"
     : 'tv_list_ensures_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 918 "lib/parser/q2_inferred.mli"
     : 'tv_list_ensures_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 923 "lib/parser/q2_inferred.mli"
   : 'tv_list_attr_clause_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 927 "lib/parser/q2_inferred.mli"
   : 'tv_attr_clause) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 932 "lib/parser/q2_inferred.mli"
     : 'tv_list_attr_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 938 "lib/parser/q2_inferred.mli"
     : 'tv_list_attr_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 943 "lib/parser/q2_inferred.mli"
   : 'tv_list_assume_in_proof_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 947 "lib/parser/q2_inferred.mli"
   : 'tv_assume_in_proof) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 952 "lib/parser/q2_inferred.mli"
     : 'tv_list_assume_in_proof_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 958 "lib/parser/q2_inferred.mli"
     : 'tv_list_assume_in_proof_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 227 "lib/parser/parser.mly"
                                                 _3
# 963 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 227 "lib/parser/parser.mly"
       ps
# 967 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_ident_) (_startpos_ps_ : Lexing.position) (_endpos_ps_ : Lexing.position) (_startofs_ps_ : int) (_endofs_ps_ : int) (_loc_ps_ : Lexing.position * Lexing.position) (
# 227 "lib/parser/parser.mly"
   _1
# 971 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 227 "lib/parser/parser.mly"
                                                     ( ps )
# 976 "lib/parser/q2_inferred.mli"
     : 'tv_type_params) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 226 "lib/parser/parser.mly"
    ( [] )
# 982 "lib/parser/q2_inferred.mli"
     : 'tv_type_params) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 216 "lib/parser/parser.mly"
                                                    _6
# 987 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) ((
# 216 "lib/parser/parser.mly"
                                              t
# 991 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 995 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 216 "lib/parser/parser.mly"
                                          _4
# 999 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 216 "lib/parser/parser.mly"
                      params
# 1003 "lib/parser/q2_inferred.mli"
   : 'tv_type_params) (_startpos_params_ : Lexing.position) (_endpos_params_ : Lexing.position) (_startofs_params_ : int) (_endofs_params_ : int) (_loc_params_ : Lexing.position * Lexing.position) (
# 216 "lib/parser/parser.mly"
         name
# 1007 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 216 "lib/parser/parser.mly"
   _1
# 1011 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 217 "lib/parser/parser.mly"
    (
      {
        td_name   = name;
        td_params = params;
        td_ty     = t;
      }
    )
# 1022 "lib/parser/q2_inferred.mli"
     : 'tv_type_def) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 397 "lib/parser/parser.mly"
                                                _3
# 1027 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 397 "lib/parser/parser.mly"
       args
# 1031 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_ty_) (_startpos_args_ : Lexing.position) (_endpos_args_ : Lexing.position) (_startofs_args_ : int) (_endofs_args_ : int) (_loc_args_ : Lexing.position * Lexing.position) (
# 397 "lib/parser/parser.mly"
   _1
# 1035 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 397 "lib/parser/parser.mly"
                                                    ( args )
# 1040 "lib/parser/q2_inferred.mli"
     : 'tv_type_args) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 396 "lib/parser/parser.mly"
    ( [] )
# 1046 "lib/parser/q2_inferred.mli"
     : 'tv_type_args) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 392 "lib/parser/parser.mly"
                 _3
# 1051 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 392 "lib/parser/parser.mly"
           t
# 1055 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1059 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 392 "lib/parser/parser.mly"
   _1
# 1063 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 393 "lib/parser/parser.mly"
    ( t )
# 1068 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1072 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 384 "lib/parser/parser.mly"
                 args
# 1077 "lib/parser/q2_inferred.mli"
   : 'tv_type_args) (_startpos_args_ : Lexing.position) (_endpos_args_ : Lexing.position) (_startofs_args_ : int) (_endofs_args_ : int) (_loc_args_ : Lexing.position * Lexing.position) (
# 384 "lib/parser/parser.mly"
    name
# 1081 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    ((
# 385 "lib/parser/parser.mly"
    (
      match args with
      | [] -> TNamed (name, [])
      | _  -> TNamed (name, args)
    )
# 1090 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1094 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 380 "lib/parser/parser.mly"
            t
# 1099 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1103 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 380 "lib/parser/parser.mly"
   _1
# 1107 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 381 "lib/parser/parser.mly"
    ( TQual (Varying, t) )
# 1112 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1116 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 378 "lib/parser/parser.mly"
            t
# 1121 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1125 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 378 "lib/parser/parser.mly"
   _1
# 1129 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 379 "lib/parser/parser.mly"
    ( TQual (Uniform, t) )
# 1134 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1138 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 374 "lib/parser/parser.mly"
                    _4
# 1143 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 374 "lib/parser/parser.mly"
              t
# 1147 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1151 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 374 "lib/parser/parser.mly"
          _2
# 1155 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 374 "lib/parser/parser.mly"
   _1
# 1159 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 375 "lib/parser/parser.mly"
    ( TShared (t, None) )
# 1164 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1168 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 372 "lib/parser/parser.mly"
                                         _7
# 1173 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__7_ : Lexing.position) (_endpos__7_ : Lexing.position) (_startofs__7_ : int) (_endofs__7_ : int) (_loc__7_ : Lexing.position * Lexing.position) ((
# 372 "lib/parser/parser.mly"
                                 n
# 1177 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 1181 "lib/parser/q2_inferred.mli"
  )) (_startpos_n_ : Lexing.position) (_endpos_n_ : Lexing.position) (_startofs_n_ : int) (_endofs_n_ : int) (_loc_n_ : Lexing.position * Lexing.position) (
# 372 "lib/parser/parser.mly"
                       _5
# 1185 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 372 "lib/parser/parser.mly"
                    _4
# 1189 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 372 "lib/parser/parser.mly"
              t
# 1193 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1197 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 372 "lib/parser/parser.mly"
          _2
# 1201 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 372 "lib/parser/parser.mly"
   _1
# 1205 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 373 "lib/parser/parser.mly"
    ( TShared (t, Some n) )
# 1210 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1214 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 368 "lib/parser/parser.mly"
                  _4
# 1219 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 368 "lib/parser/parser.mly"
            t
# 1223 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1227 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 368 "lib/parser/parser.mly"
        _2
# 1231 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 368 "lib/parser/parser.mly"
   _1
# 1235 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 369 "lib/parser/parser.mly"
    ( TSpan t )
# 1240 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1244 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 364 "lib/parser/parser.mly"
   _1
# 1249 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 365 "lib/parser/parser.mly"
    ( TPrim TNever )
# 1254 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1258 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 362 "lib/parser/parser.mly"
          _2
# 1263 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 362 "lib/parser/parser.mly"
   _1
# 1267 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 363 "lib/parser/parser.mly"
    ( TPrim TUnit )
# 1272 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1276 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 358 "lib/parser/parser.mly"
                                                                _5
# 1281 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 358 "lib/parser/parser.mly"
                         ts
# 1285 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_ty_) (_startpos_ts_ : Lexing.position) (_endpos_ts_ : Lexing.position) (_startofs_ts_ : int) (_endofs_ts_ : int) (_loc_ts_ : Lexing.position * Lexing.position) (
# 358 "lib/parser/parser.mly"
                  _3
# 1289 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 358 "lib/parser/parser.mly"
           t1
# 1293 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1297 "lib/parser/q2_inferred.mli"
  )) (_startpos_t1_ : Lexing.position) (_endpos_t1_ : Lexing.position) (_startofs_t1_ : int) (_endofs_t1_ : int) (_loc_t1_ : Lexing.position * Lexing.position) (
# 358 "lib/parser/parser.mly"
   _1
# 1301 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 359 "lib/parser/parser.mly"
    ( TTuple (t1 :: ts) )
# 1306 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1310 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 354 "lib/parser/parser.mly"
                                 _5
# 1315 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) ((
# 354 "lib/parser/parser.mly"
                         n
# 1319 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 1323 "lib/parser/q2_inferred.mli"
  )) (_startpos_n_ : Lexing.position) (_endpos_n_ : Lexing.position) (_startofs_n_ : int) (_endofs_n_ : int) (_loc_n_ : Lexing.position * Lexing.position) (
# 354 "lib/parser/parser.mly"
                   _3
# 1327 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 354 "lib/parser/parser.mly"
             t
# 1331 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1335 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 354 "lib/parser/parser.mly"
   _1
# 1339 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 355 "lib/parser/parser.mly"
    ( TArray (t, Some n) )
# 1344 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1348 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 352 "lib/parser/parser.mly"
                   _3
# 1353 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 352 "lib/parser/parser.mly"
             t
# 1357 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1361 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 352 "lib/parser/parser.mly"
   _1
# 1365 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 353 "lib/parser/parser.mly"
    ( TSlice t )
# 1370 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1374 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 348 "lib/parser/parser.mly"
                 _4
# 1379 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 348 "lib/parser/parser.mly"
           t
# 1383 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1387 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 348 "lib/parser/parser.mly"
       _2
# 1391 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 348 "lib/parser/parser.mly"
   _1
# 1395 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 349 "lib/parser/parser.mly"
    ( TRaw t )
# 1400 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1404 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 346 "lib/parser/parser.mly"
                 _4
# 1409 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 346 "lib/parser/parser.mly"
           t
# 1413 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1417 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 346 "lib/parser/parser.mly"
       _2
# 1421 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 346 "lib/parser/parser.mly"
   _1
# 1425 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 347 "lib/parser/parser.mly"
    ( TOwn t )
# 1430 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1434 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 344 "lib/parser/parser.mly"
                    _4
# 1439 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 344 "lib/parser/parser.mly"
              t
# 1443 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1447 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 344 "lib/parser/parser.mly"
          _2
# 1451 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 344 "lib/parser/parser.mly"
   _1
# 1455 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 345 "lib/parser/parser.mly"
    ( TRefMut t )
# 1460 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1464 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 342 "lib/parser/parser.mly"
                 _4
# 1469 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 342 "lib/parser/parser.mly"
           t
# 1473 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1477 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 342 "lib/parser/parser.mly"
       _2
# 1481 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 342 "lib/parser/parser.mly"
   _1
# 1485 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 343 "lib/parser/parser.mly"
    ( TRef t )
# 1490 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1494 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 338 "lib/parser/parser.mly"
                                                        _6
# 1499 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) ((
# 338 "lib/parser/parser.mly"
                                                p
# 1503 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 1507 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 338 "lib/parser/parser.mly"
                                          _4
# 1511 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 338 "lib/parser/parser.mly"
                            binder
# 1515 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_binder_ : Lexing.position) (_endpos_binder_ : Lexing.position) (_startofs_binder_ : int) (_endofs_binder_ : int) (_loc_binder_ : Lexing.position * Lexing.position) (
# 338 "lib/parser/parser.mly"
                  _2
# 1519 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 338 "lib/parser/parser.mly"
    b
# 1523 "lib/parser/q2_inferred.mli"
   : 'tv_prim_ty_kw) (_startpos_b_ : Lexing.position) (_endpos_b_ : Lexing.position) (_startofs_b_ : int) (_endofs_b_ : int) (_loc_b_ : Lexing.position * Lexing.position) ->
    ((
# 339 "lib/parser/parser.mly"
    ( TRefined (b, binder, p) )
# 1528 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1532 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 336 "lib/parser/parser.mly"
    b
# 1537 "lib/parser/q2_inferred.mli"
   : 'tv_prim_ty_kw) (_startpos_b_ : Lexing.position) (_endpos_b_ : Lexing.position) (_startofs_b_ : int) (_endofs_b_ : int) (_loc_b_ : Lexing.position * Lexing.position) ->
    ((
# 337 "lib/parser/parser.mly"
    ( TPrim b )
# 1542 "lib/parser/q2_inferred.mli"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1546 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
                rest
# 1551 "lib/parser/q2_inferred.mli"
   : 'tv_tlist_ty_) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
         _2
# 1555 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 130 "lib/parser/parser.mly"
    x
# 1559 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1563 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 130 "lib/parser/parser.mly"
                                ( x :: rest )
# 1568 "lib/parser/q2_inferred.mli"
     : 'tv_tlist_ty_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 129 "lib/parser/parser.mly"
    x
# 1573 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1577 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 129 "lib/parser/parser.mly"
          ( [x] )
# 1582 "lib/parser/q2_inferred.mli"
     : 'tv_tlist_ty_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 128 "lib/parser/parser.mly"
    ( [] )
# 1588 "lib/parser/q2_inferred.mli"
     : 'tv_tlist_ty_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
                rest
# 1593 "lib/parser/q2_inferred.mli"
   : 'tv_tlist_struct_field_init_) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
         _2
# 1597 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
    x
# 1601 "lib/parser/q2_inferred.mli"
   : 'tv_struct_field_init) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 130 "lib/parser/parser.mly"
                                ( x :: rest )
# 1606 "lib/parser/q2_inferred.mli"
     : 'tv_tlist_struct_field_init_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 129 "lib/parser/parser.mly"
    x
# 1611 "lib/parser/q2_inferred.mli"
   : 'tv_struct_field_init) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 129 "lib/parser/parser.mly"
          ( [x] )
# 1616 "lib/parser/q2_inferred.mli"
     : 'tv_tlist_struct_field_init_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 128 "lib/parser/parser.mly"
    ( [] )
# 1622 "lib/parser/q2_inferred.mli"
     : 'tv_tlist_struct_field_init_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
                rest
# 1627 "lib/parser/q2_inferred.mli"
   : 'tv_tlist_param_) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
         _2
# 1631 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
    x
# 1635 "lib/parser/q2_inferred.mli"
   : 'tv_param) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 130 "lib/parser/parser.mly"
                                ( x :: rest )
# 1640 "lib/parser/q2_inferred.mli"
     : 'tv_tlist_param_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 129 "lib/parser/parser.mly"
    x
# 1645 "lib/parser/q2_inferred.mli"
   : 'tv_param) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 129 "lib/parser/parser.mly"
          ( [x] )
# 1650 "lib/parser/q2_inferred.mli"
     : 'tv_tlist_param_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 128 "lib/parser/parser.mly"
    ( [] )
# 1656 "lib/parser/q2_inferred.mli"
     : 'tv_tlist_param_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
                rest
# 1661 "lib/parser/q2_inferred.mli"
   : 'tv_tlist_expr_) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
         _2
# 1665 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 130 "lib/parser/parser.mly"
    x
# 1669 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 1673 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 130 "lib/parser/parser.mly"
                                ( x :: rest )
# 1678 "lib/parser/q2_inferred.mli"
     : 'tv_tlist_expr_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 129 "lib/parser/parser.mly"
    x
# 1683 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 1687 "lib/parser/q2_inferred.mli"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 129 "lib/parser/parser.mly"
          ( [x] )
# 1692 "lib/parser/q2_inferred.mli"
     : 'tv_tlist_expr_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 128 "lib/parser/parser.mly"
    ( [] )
# 1698 "lib/parser/q2_inferred.mli"
     : 'tv_tlist_expr_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 581 "lib/parser/parser.mly"
                       e
# 1703 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 1707 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 581 "lib/parser/parser.mly"
                _2
# 1711 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 581 "lib/parser/parser.mly"
    name
# 1715 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 581 "lib/parser/parser.mly"
                                ( (name, e) )
# 1720 "lib/parser/q2_inferred.mli"
     : 'tv_struct_field_init) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 251 "lib/parser/parser.mly"
                       t
# 1725 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1729 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 251 "lib/parser/parser.mly"
                _2
# 1733 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 251 "lib/parser/parser.mly"
    name
# 1737 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 252 "lib/parser/parser.mly"
    ( (name, t) )
# 1742 "lib/parser/q2_inferred.mli"
     : 'tv_struct_field) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 249 "lib/parser/parser.mly"
                             _4
# 1747 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 249 "lib/parser/parser.mly"
                       t
# 1751 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1755 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 249 "lib/parser/parser.mly"
                _2
# 1759 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 249 "lib/parser/parser.mly"
    name
# 1763 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 250 "lib/parser/parser.mly"
    ( (name, t) )
# 1768 "lib/parser/q2_inferred.mli"
     : 'tv_struct_field) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 237 "lib/parser/parser.mly"
                                     _7
# 1774 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__7_ : Lexing.position) (_endpos__7_ : Lexing.position) (_startofs__7_ : int) (_endofs__7_ : int) (_loc__7_ : Lexing.position * Lexing.position) (
# 237 "lib/parser/parser.mly"
      invars
# 1778 "lib/parser/q2_inferred.mli"
   : 'tv_list_invariant_clause_) (_startpos_invars_ : Lexing.position) (_endpos_invars_ : Lexing.position) (_startofs_invars_ : int) (_endofs_invars_ : int) (_loc_invars_ : Lexing.position * Lexing.position) (
# 236 "lib/parser/parser.mly"
      fields
# 1782 "lib/parser/q2_inferred.mli"
   : 'tv_list_struct_field_) (_startpos_fields_ : Lexing.position) (_endpos_fields_ : Lexing.position) (_startofs_fields_ : int) (_endofs_fields_ : int) (_loc_fields_ : Lexing.position * Lexing.position) (
# 234 "lib/parser/parser.mly"
                                            _4
# 1787 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 234 "lib/parser/parser.mly"
                        params
# 1791 "lib/parser/q2_inferred.mli"
   : 'tv_kind_params) (_startpos_params_ : Lexing.position) (_endpos_params_ : Lexing.position) (_startofs_params_ : int) (_endofs_params_ : int) (_loc_params_ : Lexing.position * Lexing.position) (
# 234 "lib/parser/parser.mly"
           name
# 1795 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 234 "lib/parser/parser.mly"
   _1
# 1799 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 239 "lib/parser/parser.mly"
    (
      {
        sd_name   = name;
        sd_params = params;
        sd_fields = fields;
        sd_invars = invars;
      }
    )
# 1811 "lib/parser/q2_inferred.mli"
     : 'tv_struct_def) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 843 "lib/parser/parser.mly"
            _2
# 1816 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 843 "lib/parser/parser.mly"
   _1
# 1820 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 844 "lib/parser/parser.mly"
    ( mk_stmt SContinue _startpos )
# 1825 "lib/parser/q2_inferred.mli"
     : 'tv_stmt) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 841 "lib/parser/parser.mly"
         _2
# 1830 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 841 "lib/parser/parser.mly"
   _1
# 1834 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 842 "lib/parser/parser.mly"
    ( mk_stmt SBreak _startpos )
# 1839 "lib/parser/q2_inferred.mli"
     : 'tv_stmt) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 839 "lib/parser/parser.mly"
            _2
# 1844 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 839 "lib/parser/parser.mly"
    e
# 1848 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 1852 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 840 "lib/parser/parser.mly"
    ( mk_stmt (SExpr e) _startpos )
# 1857 "lib/parser/q2_inferred.mli"
     : 'tv_stmt) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 837 "lib/parser/parser.mly"
               _6
# 1862 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) ((
# 837 "lib/parser/parser.mly"
       e
# 1866 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 1870 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 836 "lib/parser/parser.mly"
                                                      _4
# 1875 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 836 "lib/parser/parser.mly"
                     ann
# 1879 "lib/parser/q2_inferred.mli"
   : 'tv_option_preceded_COLON_ty__) (_startpos_ann_ : Lexing.position) (_endpos_ann_ : Lexing.position) (_startofs_ann_ : int) (_endofs_ann_ : int) (_loc_ann_ : Lexing.position * Lexing.position) (
# 836 "lib/parser/parser.mly"
        name
# 1883 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 836 "lib/parser/parser.mly"
   _1
# 1887 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 838 "lib/parser/parser.mly"
    ( mk_stmt (SLet (name, ann, e, Unr)) _startpos )
# 1892 "lib/parser/q2_inferred.mli"
     : 'tv_stmt) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 834 "lib/parser/parser.mly"
               _7
# 1897 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__7_ : Lexing.position) (_endpos__7_ : Lexing.position) (_startofs__7_ : int) (_endofs__7_ : int) (_loc__7_ : Lexing.position * Lexing.position) ((
# 834 "lib/parser/parser.mly"
       e
# 1901 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 1905 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 833 "lib/parser/parser.mly"
                                                                      _5
# 1910 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 833 "lib/parser/parser.mly"
                                     ann
# 1914 "lib/parser/q2_inferred.mli"
   : 'tv_option_preceded_COLON_ty__) (_startpos_ann_ : Lexing.position) (_endpos_ann_ : Lexing.position) (_startofs_ann_ : int) (_endofs_ann_ : int) (_loc_ann_ : Lexing.position * Lexing.position) (
# 833 "lib/parser/parser.mly"
                        name
# 1918 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 833 "lib/parser/parser.mly"
        lin
# 1922 "lib/parser/q2_inferred.mli"
   : 'tv_linearity) (_startpos_lin_ : Lexing.position) (_endpos_lin_ : Lexing.position) (_startofs_lin_ : int) (_endofs_lin_ : int) (_loc_lin_ : Lexing.position * Lexing.position) (
# 833 "lib/parser/parser.mly"
   _1
# 1926 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 835 "lib/parser/parser.mly"
    ( mk_stmt (SLet (name, ann, e, lin)) _startpos )
# 1931 "lib/parser/q2_inferred.mli"
     : 'tv_stmt) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 738 "lib/parser/parser.mly"
           e
# 1936 "lib/parser/q2_inferred.mli"
   : 'tv_option_expr_) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 738 "lib/parser/parser.mly"
   _1
# 1940 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 739 "lib/parser/parser.mly"
    ( mk_expr (EBlock (
        [mk_stmt (SReturn e) _startpos],
        None)) _startpos )
# 1947 "lib/parser/q2_inferred.mli"
     : 'tv_return_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 199 "lib/parser/parser.mly"
             p
# 1952 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 1956 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 199 "lib/parser/parser.mly"
   _1
# 1960 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 199 "lib/parser/parser.mly"
                      ( p )
# 1965 "lib/parser/q2_inferred.mli"
     : 'tv_requires_clause) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 812 "lib/parser/parser.mly"
                                 _4
# 1970 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 812 "lib/parser/parser.mly"
               stmts
# 1974 "lib/parser/q2_inferred.mli"
   : 'tv_list_stmt_) (_startpos_stmts_ : Lexing.position) (_endpos_stmts_ : Lexing.position) (_startofs_stmts_ : int) (_endofs_stmts_ : int) (_loc_stmts_ : Lexing.position * Lexing.position) (
# 812 "lib/parser/parser.mly"
       _2
# 1978 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 812 "lib/parser/parser.mly"
   _1
# 1982 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 813 "lib/parser/parser.mly"
    (
      mk_expr (ERaw {
        rb_stmts = stmts;
        rb_loc   = mk_loc _startpos;
      }) _startpos
    )
# 1992 "lib/parser/q2_inferred.mli"
     : 'tv_raw_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 804 "lib/parser/parser.mly"
                                 _3
# 1997 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 804 "lib/parser/parser.mly"
           pts
# 2001 "lib/parser/q2_inferred.mli"
   : 'tv_list_proof_term_) (_startpos_pts_ : Lexing.position) (_endpos_pts_ : Lexing.position) (_startofs_pts_ : int) (_endofs_pts_ : int) (_loc_pts_ : Lexing.position * Lexing.position) (
# 804 "lib/parser/parser.mly"
   _1
# 2005 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 805 "lib/parser/parser.mly"
    ( PTCong pts )
# 2010 "lib/parser/q2_inferred.mli"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 802 "lib/parser/parser.mly"
                                                                   _5
# 2015 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 802 "lib/parser/parser.mly"
                           args
# 2019 "lib/parser/q2_inferred.mli"
   : 'tv_separated_list_COMMA_proof_term_) (_startpos_args_ : Lexing.position) (_endpos_args_ : Lexing.position) (_startofs_args_ : int) (_endofs_args_ : int) (_loc_args_ : Lexing.position * Lexing.position) (
# 802 "lib/parser/parser.mly"
                   _3
# 2023 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 802 "lib/parser/parser.mly"
       name
# 2027 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 802 "lib/parser/parser.mly"
   _1
# 2031 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 803 "lib/parser/parser.mly"
    ( PTBy (name, args) )
# 2036 "lib/parser/q2_inferred.mli"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 800 "lib/parser/parser.mly"
                           _4
# 2041 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 800 "lib/parser/parser.mly"
                   e
# 2045 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 2049 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 800 "lib/parser/parser.mly"
           _2
# 2053 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 800 "lib/parser/parser.mly"
   _1
# 2057 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 801 "lib/parser/parser.mly"
    ( PTWitness e )
# 2062 "lib/parser/q2_inferred.mli"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 798 "lib/parser/parser.mly"
                                                                        _7
# 2067 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__7_ : Lexing.position) (_endpos__7_ : Lexing.position) (_startofs__7_ : int) (_endofs__7_ : int) (_loc__7_ : Lexing.position * Lexing.position) (
# 798 "lib/parser/parser.mly"
                                                       step
# 2071 "lib/parser/q2_inferred.mli"
   : 'tv_proof_term) (_startpos_step_ : Lexing.position) (_endpos_step_ : Lexing.position) (_startofs_step_ : int) (_endofs_step_ : int) (_loc_step_ : Lexing.position * Lexing.position) (
# 798 "lib/parser/parser.mly"
                                                _5
# 2075 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 798 "lib/parser/parser.mly"
                               base
# 2079 "lib/parser/q2_inferred.mli"
   : 'tv_proof_term) (_startpos_base_ : Lexing.position) (_endpos_base_ : Lexing.position) (_startofs_base_ : int) (_endofs_base_ : int) (_loc_base_ : Lexing.position * Lexing.position) (
# 798 "lib/parser/parser.mly"
                       _3
# 2083 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 798 "lib/parser/parser.mly"
              x
# 2087 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) (
# 798 "lib/parser/parser.mly"
   _1
# 2091 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 799 "lib/parser/parser.mly"
    ( PTInduct (x, base, step) )
# 2096 "lib/parser/q2_inferred.mli"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 796 "lib/parser/parser.mly"
                                                                         _8
# 2101 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__8_ : Lexing.position) (_endpos__8_ : Lexing.position) (_startofs__8_ : int) (_endofs__8_ : int) (_loc__8_ : Lexing.position * Lexing.position) (
# 796 "lib/parser/parser.mly"
                                                         pt2
# 2105 "lib/parser/q2_inferred.mli"
   : 'tv_proof_term) (_startpos_pt2_ : Lexing.position) (_endpos_pt2_ : Lexing.position) (_startofs_pt2_ : int) (_endofs_pt2_ : int) (_loc_pt2_ : Lexing.position * Lexing.position) (
# 796 "lib/parser/parser.mly"
                                                  _6
# 2109 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) (
# 796 "lib/parser/parser.mly"
                                  pt1
# 2113 "lib/parser/q2_inferred.mli"
   : 'tv_proof_term) (_startpos_pt1_ : Lexing.position) (_endpos_pt1_ : Lexing.position) (_startofs_pt1_ : int) (_endofs_pt1_ : int) (_loc_pt1_ : Lexing.position * Lexing.position) (
# 796 "lib/parser/parser.mly"
                           _4
# 2117 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 796 "lib/parser/parser.mly"
                 mid
# 2121 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 2125 "lib/parser/q2_inferred.mli"
  )) (_startpos_mid_ : Lexing.position) (_endpos_mid_ : Lexing.position) (_startofs_mid_ : int) (_endofs_mid_ : int) (_loc_mid_ : Lexing.position * Lexing.position) (
# 796 "lib/parser/parser.mly"
         _2
# 2129 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 796 "lib/parser/parser.mly"
   _1
# 2133 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 797 "lib/parser/parser.mly"
    ( PTTrans (mid, pt1, pt2) )
# 2138 "lib/parser/q2_inferred.mli"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 794 "lib/parser/parser.mly"
                               _4
# 2143 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 794 "lib/parser/parser.mly"
                pt
# 2147 "lib/parser/q2_inferred.mli"
   : 'tv_proof_term) (_startpos_pt_ : Lexing.position) (_endpos_pt_ : Lexing.position) (_startofs_pt_ : int) (_endofs_pt_ : int) (_loc_pt_ : Lexing.position * Lexing.position) (
# 794 "lib/parser/parser.mly"
        _2
# 2151 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 794 "lib/parser/parser.mly"
   _1
# 2155 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 795 "lib/parser/parser.mly"
    ( PTSymm pt )
# 2160 "lib/parser/q2_inferred.mli"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 791 "lib/parser/parser.mly"
    id
# 2165 "lib/parser/q2_inferred.mli"
   : (
# 19 "lib/parser/parser.mly"
       (string)
# 2169 "lib/parser/q2_inferred.mli"
  )) (_startpos_id_ : Lexing.position) (_endpos_id_ : Lexing.position) (_startofs_id_ : int) (_endofs_id_ : int) (_loc_id_ : Lexing.position * Lexing.position) ->
    (
# 792 "lib/parser/parser.mly"
    ( (if id = "refl" then PTRefl
       else raise Error : proof_term) )
# 2175 "lib/parser/q2_inferred.mli"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 789 "lib/parser/parser.mly"
   _1
# 2180 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 790 "lib/parser/parser.mly"
    ( PTAxiom )
# 2185 "lib/parser/q2_inferred.mli"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 787 "lib/parser/parser.mly"
   _1
# 2190 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 788 "lib/parser/parser.mly"
    ( PTAuto )
# 2195 "lib/parser/q2_inferred.mli"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 748 "lib/parser/parser.mly"
                                    _4
# 2200 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 748 "lib/parser/parser.mly"
                 pb
# 2204 "lib/parser/q2_inferred.mli"
   : 'tv_proof_contents) (_startpos_pb_ : Lexing.position) (_endpos_pb_ : Lexing.position) (_startofs_pb_ : int) (_endofs_pb_ : int) (_loc_pb_ : Lexing.position * Lexing.position) (
# 748 "lib/parser/parser.mly"
         _2
# 2208 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 748 "lib/parser/parser.mly"
   _1
# 2212 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 749 "lib/parser/parser.mly"
    ( mk_expr (EProof pb) _startpos )
# 2217 "lib/parser/q2_inferred.mli"
     : 'tv_proof_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 752 "lib/parser/parser.mly"
                             assumes
# 2222 "lib/parser/q2_inferred.mli"
   : 'tv_list_assume_in_proof_) (_startpos_assumes_ : Lexing.position) (_endpos_assumes_ : Lexing.position) (_startofs_assumes_ : int) (_endofs_assumes_ : int) (_loc_assumes_ : Lexing.position * Lexing.position) (
# 752 "lib/parser/parser.mly"
    lemmas
# 2226 "lib/parser/q2_inferred.mli"
   : 'tv_list_lemma_def_) (_startpos_lemmas_ : Lexing.position) (_endpos_lemmas_ : Lexing.position) (_startofs_lemmas_ : int) (_endofs_lemmas_ : int) (_loc_lemmas_ : Lexing.position * Lexing.position) ->
    (
# 753 "lib/parser/parser.mly"
    (
      {
        pb_lemmas  = lemmas;
        pb_assumes = assumes;
        pb_loc     = mk_loc _startpos;
      }
    )
# 2237 "lib/parser/q2_inferred.mli"
     : 'tv_proof_contents) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 137 "lib/parser/parser.mly"
                      _2
# 2242 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 137 "lib/parser/parser.mly"
    items
# 2246 "lib/parser/q2_inferred.mli"
   : 'tv_list_item_) (_startpos_items_ : Lexing.position) (_endpos_items_ : Lexing.position) (_startofs_items_ : int) (_endofs_items_ : int) (_loc_items_ : Lexing.position * Lexing.position) ->
    ((
# 138 "lib/parser/parser.mly"
    ( { prog_items = items; prog_file = _startpos.pos_fname } )
# 2251 "lib/parser/q2_inferred.mli"
     : 'tv_program) : (
# 114 "lib/parser/parser.mly"
       (Ast.program)
# 2255 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 407 "lib/parser/parser.mly"
   _1
# 2260 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 407 "lib/parser/parser.mly"
            ( TBool )
# 2265 "lib/parser/q2_inferred.mli"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 406 "lib/parser/parser.mly"
                          _1
# 2270 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 406 "lib/parser/parser.mly"
                                 ( TFloat F64 )
# 2275 "lib/parser/q2_inferred.mli"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 406 "lib/parser/parser.mly"
   _1
# 2280 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 406 "lib/parser/parser.mly"
          ( TFloat F32 )
# 2285 "lib/parser/q2_inferred.mli"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 405 "lib/parser/parser.mly"
                          _1
# 2290 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 405 "lib/parser/parser.mly"
                                 ( TInt ISize )
# 2295 "lib/parser/q2_inferred.mli"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 405 "lib/parser/parser.mly"
   _1
# 2300 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 405 "lib/parser/parser.mly"
          ( TInt I128 )
# 2305 "lib/parser/q2_inferred.mli"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 404 "lib/parser/parser.mly"
                          _1
# 2310 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 404 "lib/parser/parser.mly"
                                 ( TInt I64   )
# 2315 "lib/parser/q2_inferred.mli"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 404 "lib/parser/parser.mly"
   _1
# 2320 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 404 "lib/parser/parser.mly"
          ( TInt I32  )
# 2325 "lib/parser/q2_inferred.mli"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 403 "lib/parser/parser.mly"
                          _1
# 2330 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 403 "lib/parser/parser.mly"
                                 ( TInt I16   )
# 2335 "lib/parser/q2_inferred.mli"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 403 "lib/parser/parser.mly"
   _1
# 2340 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 403 "lib/parser/parser.mly"
          ( TInt I8   )
# 2345 "lib/parser/q2_inferred.mli"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 402 "lib/parser/parser.mly"
                          _1
# 2350 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 402 "lib/parser/parser.mly"
                                 ( TUint USize )
# 2355 "lib/parser/q2_inferred.mli"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 402 "lib/parser/parser.mly"
   _1
# 2360 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 402 "lib/parser/parser.mly"
          ( TUint U128 )
# 2365 "lib/parser/q2_inferred.mli"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 401 "lib/parser/parser.mly"
                          _1
# 2370 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 401 "lib/parser/parser.mly"
                                 ( TUint U64  )
# 2375 "lib/parser/q2_inferred.mli"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 401 "lib/parser/parser.mly"
   _1
# 2380 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 401 "lib/parser/parser.mly"
          ( TUint U32 )
# 2385 "lib/parser/q2_inferred.mli"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 400 "lib/parser/parser.mly"
                          _1
# 2390 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 400 "lib/parser/parser.mly"
                                 ( TUint U16  )
# 2395 "lib/parser/q2_inferred.mli"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 400 "lib/parser/parser.mly"
   _1
# 2400 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 400 "lib/parser/parser.mly"
          ( TUint U8  )
# 2405 "lib/parser/q2_inferred.mli"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 489 "lib/parser/parser.mly"
                   _3
# 2410 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 489 "lib/parser/parser.mly"
           p
# 2414 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2418 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 489 "lib/parser/parser.mly"
   _1
# 2422 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 490 "lib/parser/parser.mly"
    ( p )
# 2427 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2431 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 487 "lib/parser/parser.mly"
    name
# 2436 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    ((
# 488 "lib/parser/parser.mly"
    ( PVar name )
# 2441 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2445 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 485 "lib/parser/parser.mly"
                                                          _4
# 2450 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 485 "lib/parser/parser.mly"
                        args
# 2454 "lib/parser/q2_inferred.mli"
   : 'tv_separated_list_COMMA_pred_) (_startpos_args_ : Lexing.position) (_endpos_args_ : Lexing.position) (_startofs_args_ : int) (_endofs_args_ : int) (_loc_args_ : Lexing.position * Lexing.position) (
# 485 "lib/parser/parser.mly"
                _2
# 2458 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 485 "lib/parser/parser.mly"
    name
# 2462 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    ((
# 486 "lib/parser/parser.mly"
    ( PApp (name, args) )
# 2467 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2471 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 484 "lib/parser/parser.mly"
    ns
# 2476 "lib/parser/q2_inferred.mli"
   : (
# 16 "lib/parser/parser.mly"
       (int64 * string)
# 2480 "lib/parser/q2_inferred.mli"
  )) (_startpos_ns_ : Lexing.position) (_endpos_ns_ : Lexing.position) (_startofs_ns_ : int) (_endofs_ns_ : int) (_loc_ns_ : Lexing.position * Lexing.position) ->
    ((
# 484 "lib/parser/parser.mly"
                      ( let (n, _) = ns in PInt n )
# 2485 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2489 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 481 "lib/parser/parser.mly"
    n
# 2494 "lib/parser/q2_inferred.mli"
   : (
# 15 "lib/parser/parser.mly"
       (int64)
# 2498 "lib/parser/q2_inferred.mli"
  )) (_startpos_n_ : Lexing.position) (_endpos_n_ : Lexing.position) (_startofs_n_ : int) (_endofs_n_ : int) (_loc_n_ : Lexing.position * Lexing.position) ->
    ((
# 481 "lib/parser/parser.mly"
                      ( PInt n )
# 2503 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2507 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 480 "lib/parser/parser.mly"
   _1
# 2512 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 480 "lib/parser/parser.mly"
                      ( PBool false )
# 2517 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2521 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 479 "lib/parser/parser.mly"
   _1
# 2526 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 479 "lib/parser/parser.mly"
                      ( PBool true )
# 2531 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2535 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 475 "lib/parser/parser.mly"
                                _4
# 2540 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 475 "lib/parser/parser.mly"
                      idx
# 2544 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2548 "lib/parser/q2_inferred.mli"
  )) (_startpos_idx_ : Lexing.position) (_endpos_idx_ : Lexing.position) (_startofs_idx_ : int) (_endofs_idx_ : int) (_loc_idx_ : Lexing.position * Lexing.position) (
# 475 "lib/parser/parser.mly"
            _2
# 2552 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 475 "lib/parser/parser.mly"
    p
# 2556 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2560 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) ->
    ((
# 476 "lib/parser/parser.mly"
    ( PIndex (p, idx) )
# 2565 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2569 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 471 "lib/parser/parser.mly"
                 n
# 2574 "lib/parser/q2_inferred.mli"
   : (
# 15 "lib/parser/parser.mly"
       (int64)
# 2578 "lib/parser/q2_inferred.mli"
  )) (_startpos_n_ : Lexing.position) (_endpos_n_ : Lexing.position) (_startofs_n_ : int) (_endofs_n_ : int) (_loc_n_ : Lexing.position * Lexing.position) (
# 471 "lib/parser/parser.mly"
            _2
# 2582 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 471 "lib/parser/parser.mly"
    p
# 2586 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2590 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) ->
    ((
# 472 "lib/parser/parser.mly"
    ( PField (p, "_" ^ Int64.to_string n) )
# 2595 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2599 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 468 "lib/parser/parser.mly"
                 name
# 2604 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 468 "lib/parser/parser.mly"
            _2
# 2608 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 468 "lib/parser/parser.mly"
    p
# 2612 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2616 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) ->
    ((
# 469 "lib/parser/parser.mly"
    ( PField (p, name.name) )
# 2621 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2625 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 464 "lib/parser/parser.mly"
                                                                    _5
# 2630 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 464 "lib/parser/parser.mly"
                           ps
# 2634 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_pred_) (_startpos_ps_ : Lexing.position) (_endpos_ps_ : Lexing.position) (_startofs_ps_ : int) (_endofs_ps_ : int) (_loc_ps_ : Lexing.position * Lexing.position) (
# 464 "lib/parser/parser.mly"
                    _3
# 2638 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 464 "lib/parser/parser.mly"
           p1
# 2642 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2646 "lib/parser/q2_inferred.mli"
  )) (_startpos_p1_ : Lexing.position) (_endpos_p1_ : Lexing.position) (_startofs_p1_ : int) (_endofs_p1_ : int) (_loc_p1_ : Lexing.position * Lexing.position) (
# 464 "lib/parser/parser.mly"
   _1
# 2650 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 465 "lib/parser/parser.mly"
    ( PLex (p1 :: ps) )
# 2655 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2659 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 460 "lib/parser/parser.mly"
   _1
# 2664 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 461 "lib/parser/parser.mly"
    ( PResult )
# 2669 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2673 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 458 "lib/parser/parser.mly"
                       _4
# 2678 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 458 "lib/parser/parser.mly"
               p
# 2682 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2686 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 458 "lib/parser/parser.mly"
       _2
# 2690 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 458 "lib/parser/parser.mly"
   _1
# 2694 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 459 "lib/parser/parser.mly"
    ( POld p )
# 2699 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2703 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 454 "lib/parser/parser.mly"
                                           p
# 2708 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2712 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 454 "lib/parser/parser.mly"
                                    _5
# 2716 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) ((
# 454 "lib/parser/parser.mly"
                              t
# 2720 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 2724 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 454 "lib/parser/parser.mly"
                       _3
# 2728 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 454 "lib/parser/parser.mly"
           name
# 2732 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 454 "lib/parser/parser.mly"
   _1
# 2736 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 455 "lib/parser/parser.mly"
    ( PExists (name, t, p) )
# 2741 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2745 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 452 "lib/parser/parser.mly"
                                           p
# 2750 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2754 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 452 "lib/parser/parser.mly"
                                    _5
# 2758 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) ((
# 452 "lib/parser/parser.mly"
                              t
# 2762 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 2766 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 452 "lib/parser/parser.mly"
                       _3
# 2770 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 452 "lib/parser/parser.mly"
           name
# 2774 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 452 "lib/parser/parser.mly"
   _1
# 2778 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 453 "lib/parser/parser.mly"
    ( PForall (name, t, p) )
# 2783 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2787 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 449 "lib/parser/parser.mly"
          p
# 2792 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2796 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 449 "lib/parser/parser.mly"
   _1
# 2800 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 449 "lib/parser/parser.mly"
                   ( PUnop (Neg, p) )
# 2805 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2809 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 448 "lib/parser/parser.mly"
         p
# 2814 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2818 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 448 "lib/parser/parser.mly"
   _1
# 2822 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 448 "lib/parser/parser.mly"
                   ( PUnop (Not, p) )
# 2827 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2831 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 445 "lib/parser/parser.mly"
                     r
# 2836 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2840 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 445 "lib/parser/parser.mly"
            _2
# 2844 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 445 "lib/parser/parser.mly"
    l
# 2848 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2852 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 445 "lib/parser/parser.mly"
                              ( PBinop (Shr,    l, r) )
# 2857 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2861 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 444 "lib/parser/parser.mly"
                     r
# 2866 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2870 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 444 "lib/parser/parser.mly"
            _2
# 2874 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 444 "lib/parser/parser.mly"
    l
# 2878 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2882 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 444 "lib/parser/parser.mly"
                              ( PBinop (Shl,    l, r) )
# 2887 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2891 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 443 "lib/parser/parser.mly"
                     r
# 2896 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2900 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 443 "lib/parser/parser.mly"
            _2
# 2904 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 443 "lib/parser/parser.mly"
    l
# 2908 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2912 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 443 "lib/parser/parser.mly"
                              ( PBinop (BitXor, l, r) )
# 2917 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2921 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 442 "lib/parser/parser.mly"
                     r
# 2926 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2930 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 442 "lib/parser/parser.mly"
            _2
# 2934 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 442 "lib/parser/parser.mly"
    l
# 2938 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2942 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 442 "lib/parser/parser.mly"
                              ( PBinop (BitAnd, l, r) )
# 2947 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2951 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 441 "lib/parser/parser.mly"
                     r
# 2956 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2960 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 441 "lib/parser/parser.mly"
            _2
# 2964 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 441 "lib/parser/parser.mly"
    l
# 2968 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2972 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 441 "lib/parser/parser.mly"
                              ( PBinop (BitOr,  l, r) )
# 2977 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2981 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 438 "lib/parser/parser.mly"
                     r
# 2986 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2990 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 438 "lib/parser/parser.mly"
            _2
# 2994 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 438 "lib/parser/parser.mly"
    l
# 2998 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3002 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 438 "lib/parser/parser.mly"
                              ( PBinop (Mod, l, r) )
# 3007 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3011 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 437 "lib/parser/parser.mly"
                     r
# 3016 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3020 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 437 "lib/parser/parser.mly"
            _2
# 3024 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 437 "lib/parser/parser.mly"
    l
# 3028 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3032 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 437 "lib/parser/parser.mly"
                              ( PBinop (Div, l, r) )
# 3037 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3041 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 436 "lib/parser/parser.mly"
                     r
# 3046 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3050 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 436 "lib/parser/parser.mly"
            _2
# 3054 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 436 "lib/parser/parser.mly"
    l
# 3058 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3062 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 436 "lib/parser/parser.mly"
                              ( PBinop (Mul, l, r) )
# 3067 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3071 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 435 "lib/parser/parser.mly"
                     r
# 3076 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3080 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 435 "lib/parser/parser.mly"
            _2
# 3084 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 435 "lib/parser/parser.mly"
    l
# 3088 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3092 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 435 "lib/parser/parser.mly"
                              ( PBinop (Sub, l, r) )
# 3097 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3101 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 434 "lib/parser/parser.mly"
                     r
# 3106 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3110 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 434 "lib/parser/parser.mly"
            _2
# 3114 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 434 "lib/parser/parser.mly"
    l
# 3118 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3122 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 434 "lib/parser/parser.mly"
                              ( PBinop (Add, l, r) )
# 3127 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3131 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 431 "lib/parser/parser.mly"
                  r
# 3136 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3140 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 431 "lib/parser/parser.mly"
            _2
# 3144 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 431 "lib/parser/parser.mly"
    l
# 3148 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3152 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 431 "lib/parser/parser.mly"
                            ( PBinop (Ge,  l, r) )
# 3157 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3161 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 430 "lib/parser/parser.mly"
                  r
# 3166 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3170 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 430 "lib/parser/parser.mly"
            _2
# 3174 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 430 "lib/parser/parser.mly"
    l
# 3178 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3182 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 430 "lib/parser/parser.mly"
                            ( PBinop (Gt,  l, r) )
# 3187 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3191 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 429 "lib/parser/parser.mly"
                  r
# 3196 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3200 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 429 "lib/parser/parser.mly"
            _2
# 3204 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 429 "lib/parser/parser.mly"
    l
# 3208 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3212 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 429 "lib/parser/parser.mly"
                            ( PBinop (Le,  l, r) )
# 3217 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3221 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 428 "lib/parser/parser.mly"
                  r
# 3226 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3230 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 428 "lib/parser/parser.mly"
            _2
# 3234 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 428 "lib/parser/parser.mly"
    l
# 3238 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3242 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 428 "lib/parser/parser.mly"
                            ( PBinop (Lt,  l, r) )
# 3247 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3251 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 427 "lib/parser/parser.mly"
                  r
# 3256 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3260 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 427 "lib/parser/parser.mly"
            _2
# 3264 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 427 "lib/parser/parser.mly"
    l
# 3268 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3272 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 427 "lib/parser/parser.mly"
                            ( PBinop (Ne,  l, r) )
# 3277 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3281 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 426 "lib/parser/parser.mly"
                  r
# 3286 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3290 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 426 "lib/parser/parser.mly"
            _2
# 3294 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 426 "lib/parser/parser.mly"
    l
# 3298 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3302 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 426 "lib/parser/parser.mly"
                            ( PBinop (Eq,  l, r) )
# 3307 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3311 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 422 "lib/parser/parser.mly"
                  r
# 3316 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3320 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 422 "lib/parser/parser.mly"
            _2
# 3324 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 422 "lib/parser/parser.mly"
    l
# 3328 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3332 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 423 "lib/parser/parser.mly"
    ( PBinop (And, l, r) )
# 3337 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3341 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 420 "lib/parser/parser.mly"
                 r
# 3346 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3350 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 420 "lib/parser/parser.mly"
            _2
# 3354 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 420 "lib/parser/parser.mly"
    l
# 3358 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3362 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 421 "lib/parser/parser.mly"
    ( PBinop (Or, l, r) )
# 3367 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3371 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 418 "lib/parser/parser.mly"
                     r
# 3376 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3380 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 418 "lib/parser/parser.mly"
            _2
# 3384 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 418 "lib/parser/parser.mly"
    l
# 3388 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3392 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 419 "lib/parser/parser.mly"
    ( PBinop (Implies, l, r) )
# 3397 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3401 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 416 "lib/parser/parser.mly"
                 r
# 3406 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3410 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 416 "lib/parser/parser.mly"
            _2
# 3414 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 416 "lib/parser/parser.mly"
    l
# 3418 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3422 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 417 "lib/parser/parser.mly"
    ( PBinop (Iff, l, r) )
# 3427 "lib/parser/q2_inferred.mli"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3431 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 870 "lib/parser/parser.mly"
                                                _3
# 3436 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 870 "lib/parser/parser.mly"
           pats
# 3440 "lib/parser/q2_inferred.mli"
   : 'tv_separated_list_COMMA_pattern_) (_startpos_pats_ : Lexing.position) (_endpos_pats_ : Lexing.position) (_startofs_pats_ : int) (_endofs_pats_ : int) (_loc_pats_ : Lexing.position * Lexing.position) (
# 870 "lib/parser/parser.mly"
   _1
# 3444 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 871 "lib/parser/parser.mly"
    ( PTuple pats )
# 3449 "lib/parser/q2_inferred.mli"
     : 'tv_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 868 "lib/parser/parser.mly"
                     name
# 3454 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 868 "lib/parser/parser.mly"
                 _2
# 3458 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 868 "lib/parser/parser.mly"
    pat
# 3462 "lib/parser/q2_inferred.mli"
   : 'tv_pattern) (_startpos_pat_ : Lexing.position) (_endpos_pat_ : Lexing.position) (_startofs_pat_ : int) (_endofs_pat_ : int) (_loc_pat_ : Lexing.position * Lexing.position) ->
    (
# 869 "lib/parser/parser.mly"
    ( PAs (pat, name) )
# 3467 "lib/parser/q2_inferred.mli"
     : 'tv_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 866 "lib/parser/parser.mly"
                                                             _4
# 3472 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 866 "lib/parser/parser.mly"
                        pats
# 3476 "lib/parser/q2_inferred.mli"
   : 'tv_separated_list_COMMA_pattern_) (_startpos_pats_ : Lexing.position) (_endpos_pats_ : Lexing.position) (_startofs_pats_ : int) (_endofs_pats_ : int) (_loc_pats_ : Lexing.position * Lexing.position) (
# 866 "lib/parser/parser.mly"
                _2
# 3480 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 866 "lib/parser/parser.mly"
    name
# 3484 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 867 "lib/parser/parser.mly"
    ( PCtor (name, pats) )
# 3489 "lib/parser/q2_inferred.mli"
     : 'tv_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 864 "lib/parser/parser.mly"
   _1
# 3494 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 865 "lib/parser/parser.mly"
    ( PLit (LBool false) )
# 3499 "lib/parser/q2_inferred.mli"
     : 'tv_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 862 "lib/parser/parser.mly"
   _1
# 3504 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 863 "lib/parser/parser.mly"
    ( PLit (LBool true) )
# 3509 "lib/parser/q2_inferred.mli"
     : 'tv_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 860 "lib/parser/parser.mly"
    n
# 3514 "lib/parser/q2_inferred.mli"
   : (
# 15 "lib/parser/parser.mly"
       (int64)
# 3518 "lib/parser/q2_inferred.mli"
  )) (_startpos_n_ : Lexing.position) (_endpos_n_ : Lexing.position) (_startofs_n_ : int) (_endofs_n_ : int) (_loc_n_ : Lexing.position * Lexing.position) ->
    (
# 861 "lib/parser/parser.mly"
    ( PLit (LInt (n, None)) )
# 3523 "lib/parser/q2_inferred.mli"
     : 'tv_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 858 "lib/parser/parser.mly"
    name
# 3528 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 859 "lib/parser/parser.mly"
    ( PBind name )
# 3533 "lib/parser/q2_inferred.mli"
     : 'tv_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 856 "lib/parser/parser.mly"
   _1
# 3538 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 857 "lib/parser/parser.mly"
    ( PWild )
# 3543 "lib/parser/q2_inferred.mli"
     : 'tv_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 195 "lib/parser/parser.mly"
                       t
# 3548 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 3552 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 195 "lib/parser/parser.mly"
                _2
# 3556 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 195 "lib/parser/parser.mly"
    name
# 3560 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 196 "lib/parser/parser.mly"
    ( (name, t) )
# 3565 "lib/parser/q2_inferred.mli"
     : 'tv_param) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 676 "lib/parser/parser.mly"
                            _5
# 3571 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 676 "lib/parser/parser.mly"
      arms
# 3575 "lib/parser/q2_inferred.mli"
   : 'tv_list_match_arm_) (_startpos_arms_ : Lexing.position) (_endpos_arms_ : Lexing.position) (_startofs_arms_ : int) (_endofs_arms_ : int) (_loc_arms_ : Lexing.position * Lexing.position) (
# 675 "lib/parser/parser.mly"
                      _3
# 3579 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 675 "lib/parser/parser.mly"
          scrut
# 3583 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 3587 "lib/parser/q2_inferred.mli"
  )) (_startpos_scrut_ : Lexing.position) (_endpos_scrut_ : Lexing.position) (_startofs_scrut_ : int) (_endofs_scrut_ : int) (_loc_scrut_ : Lexing.position * Lexing.position) (
# 675 "lib/parser/parser.mly"
   _1
# 3591 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 678 "lib/parser/parser.mly"
    ( mk_expr (EMatch (scrut, arms)) _startpos )
# 3596 "lib/parser/q2_inferred.mli"
     : 'tv_match_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 681 "lib/parser/parser.mly"
                                                                  body
# 3601 "lib/parser/q2_inferred.mli"
   : 'tv_arm_body) (_startpos_body_ : Lexing.position) (_endpos_body_ : Lexing.position) (_startofs_body_ : int) (_endofs_body_ : int) (_loc_body_ : Lexing.position * Lexing.position) (
# 681 "lib/parser/parser.mly"
                                                        _3
# 3605 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 681 "lib/parser/parser.mly"
                      guard
# 3609 "lib/parser/q2_inferred.mli"
   : 'tv_option_preceded_IF_pred__) (_startpos_guard_ : Lexing.position) (_endpos_guard_ : Lexing.position) (_startofs_guard_ : int) (_endofs_guard_ : int) (_loc_guard_ : Lexing.position * Lexing.position) (
# 681 "lib/parser/parser.mly"
    pat
# 3613 "lib/parser/q2_inferred.mli"
   : 'tv_alt_pattern) (_startpos_pat_ : Lexing.position) (_endpos_pat_ : Lexing.position) (_startofs_pat_ : int) (_endofs_pat_ : int) (_loc_pat_ : Lexing.position * Lexing.position) ->
    (
# 682 "lib/parser/parser.mly"
    ( { pattern = pat; guard; body } )
# 3618 "lib/parser/q2_inferred.mli"
     : 'tv_match_arm) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 725 "lib/parser/parser.mly"
    body
# 3623 "lib/parser/q2_inferred.mli"
   : 'tv_block_expr) (_startpos_body_ : Lexing.position) (_endpos_body_ : Lexing.position) (_startofs_body_ : int) (_endofs_body_ : int) (_loc_body_ : Lexing.position * Lexing.position) (
# 724 "lib/parser/parser.mly"
    dec
# 3627 "lib/parser/q2_inferred.mli"
   : 'tv_option_preceded_DECREASES_pred__) (_startpos_dec_ : Lexing.position) (_endpos_dec_ : Lexing.position) (_startofs_dec_ : int) (_endofs_dec_ : int) (_loc_dec_ : Lexing.position * Lexing.position) ((
# 723 "lib/parser/parser.mly"
                        iter
# 3631 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 3635 "lib/parser/q2_inferred.mli"
  )) (_startpos_iter_ : Lexing.position) (_endpos_iter_ : Lexing.position) (_startofs_iter_ : int) (_endofs_iter_ : int) (_loc_iter_ : Lexing.position * Lexing.position) (
# 723 "lib/parser/parser.mly"
                    _3
# 3639 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 723 "lib/parser/parser.mly"
        name
# 3643 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 723 "lib/parser/parser.mly"
   _1
# 3647 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 726 "lib/parser/parser.mly"
    (
      let stmts = match body.expr_desc with
        | EBlock (ss, Some ret) -> ss @ [mk_stmt (SExpr ret) _startpos]
        | EBlock (ss, None)     -> ss
        | _ -> [mk_stmt (SExpr body) _startpos]
      in
      mk_expr (EBlock (
        [mk_stmt (SFor (name, iter, dec, stmts)) _startpos],
        None)) _startpos
    )
# 3661 "lib/parser/q2_inferred.mli"
     : 'tv_loop_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 707 "lib/parser/parser.mly"
    body
# 3666 "lib/parser/q2_inferred.mli"
   : 'tv_block_expr) (_startpos_body_ : Lexing.position) (_endpos_body_ : Lexing.position) (_startofs_body_ : int) (_endofs_body_ : int) (_loc_body_ : Lexing.position * Lexing.position) (
# 706 "lib/parser/parser.mly"
    dec
# 3670 "lib/parser/q2_inferred.mli"
   : 'tv_option_preceded_DECREASES_pred__) (_startpos_dec_ : Lexing.position) (_endpos_dec_ : Lexing.position) (_startofs_dec_ : int) (_endofs_dec_ : int) (_loc_dec_ : Lexing.position * Lexing.position) (
# 705 "lib/parser/parser.mly"
    invs
# 3674 "lib/parser/q2_inferred.mli"
   : 'tv_list_preceded_INVARIANT_pred__) (_startpos_invs_ : Lexing.position) (_endpos_invs_ : Lexing.position) (_startofs_invs_ : int) (_endofs_invs_ : int) (_loc_invs_ : Lexing.position * Lexing.position) ((
# 704 "lib/parser/parser.mly"
          cond
# 3678 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 3682 "lib/parser/q2_inferred.mli"
  )) (_startpos_cond_ : Lexing.position) (_endpos_cond_ : Lexing.position) (_startofs_cond_ : int) (_endofs_cond_ : int) (_loc_cond_ : Lexing.position * Lexing.position) (
# 704 "lib/parser/parser.mly"
   _1
# 3686 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 708 "lib/parser/parser.mly"
    (
      let inv = match invs with
        | []  -> None
        | [p] -> Some p
        | ps  -> Some (List.fold_left (fun acc p -> PBinop (And, acc, p)) (List.hd ps) (List.tl ps))
      in
      let stmts = match body.expr_desc with
        | EBlock (ss, Some ret) -> ss @ [mk_stmt (SExpr ret) _startpos]
        | EBlock (ss, None)     -> ss
        | _ -> [mk_stmt (SExpr body) _startpos]
      in
      mk_expr (EBlock (
        [mk_stmt (SWhile (cond, inv, dec, stmts)) _startpos],
        None)) _startpos
    )
# 3705 "lib/parser/q2_inferred.mli"
     : 'tv_loop_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 696 "lib/parser/parser.mly"
         body
# 3710 "lib/parser/q2_inferred.mli"
   : 'tv_block_expr) (_startpos_body_ : Lexing.position) (_endpos_body_ : Lexing.position) (_startofs_body_ : int) (_endofs_body_ : int) (_loc_body_ : Lexing.position * Lexing.position) (
# 696 "lib/parser/parser.mly"
   _1
# 3714 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 697 "lib/parser/parser.mly"
    ( mk_expr (EBlock (
        [mk_stmt (SWhile (
            mk_expr (ELit (LBool true)) _startpos,
            None, None,
            [mk_stmt (SExpr body) _startpos]
          )) _startpos],
        None)) _startpos )
# 3725 "lib/parser/q2_inferred.mli"
     : 'tv_loop_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 849 "lib/parser/parser.mly"
   _1
# 3730 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 849 "lib/parser/parser.mly"
        ( Unr )
# 3735 "lib/parser/q2_inferred.mli"
     : 'tv_linearity) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 848 "lib/parser/parser.mly"
   _1
# 3740 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 848 "lib/parser/parser.mly"
        ( Aff )
# 3745 "lib/parser/q2_inferred.mli"
     : 'tv_linearity) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 847 "lib/parser/parser.mly"
   _1
# 3750 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 847 "lib/parser/parser.mly"
        ( Lin )
# 3755 "lib/parser/q2_inferred.mli"
     : 'tv_linearity) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 765 "lib/parser/parser.mly"
                          _10
# 3760 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__10_ : Lexing.position) (_endpos__10_ : Lexing.position) (_startofs__10_ : int) (_endofs__10_ : int) (_loc__10_ : Lexing.position * Lexing.position) (
# 765 "lib/parser/parser.mly"
           pt
# 3764 "lib/parser/q2_inferred.mli"
   : 'tv_proof_term) (_startpos_pt_ : Lexing.position) (_endpos_pt_ : Lexing.position) (_startofs_pt_ : int) (_endofs_pt_ : int) (_loc_pt_ : Lexing.position * Lexing.position) (
# 764 "lib/parser/parser.mly"
                     _8
# 3769 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__8_ : Lexing.position) (_endpos__8_ : Lexing.position) (_startofs__8_ : int) (_endofs__8_ : int) (_loc__8_ : Lexing.position * Lexing.position) ((
# 764 "lib/parser/parser.mly"
          stmt
# 3773 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3777 "lib/parser/q2_inferred.mli"
  )) (_startpos_stmt_ : Lexing.position) (_endpos_stmt_ : Lexing.position) (_startofs_stmt_ : int) (_endofs_stmt_ : int) (_loc_stmt_ : Lexing.position * Lexing.position) (
# 763 "lib/parser/parser.mly"
                                       _6
# 3782 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) (
# 763 "lib/parser/parser.mly"
                                _5
# 3786 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 763 "lib/parser/parser.mly"
           params
# 3790 "lib/parser/q2_inferred.mli"
   : 'tv_tlist_param_) (_startpos_params_ : Lexing.position) (_endpos_params_ : Lexing.position) (_startofs_params_ : int) (_endofs_params_ : int) (_loc_params_ : Lexing.position * Lexing.position) (
# 762 "lib/parser/parser.mly"
                      _3
# 3795 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 762 "lib/parser/parser.mly"
          name
# 3799 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 762 "lib/parser/parser.mly"
   _1
# 3803 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 766 "lib/parser/parser.mly"
    (
      {
        lem_name   = name;
        lem_params = params;
        lem_stmt   = stmt;
        lem_proof  = pt;
        lem_loc    = mk_loc _startpos;
      }
    )
# 3816 "lib/parser/q2_inferred.mli"
     : 'tv_lemma_def) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 260 "lib/parser/parser.mly"
                                                      _3
# 3821 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 260 "lib/parser/parser.mly"
       ps
# 3825 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_kind_param_) (_startpos_ps_ : Lexing.position) (_endpos_ps_ : Lexing.position) (_startofs_ps_ : int) (_endofs_ps_ : int) (_loc_ps_ : Lexing.position * Lexing.position) (
# 260 "lib/parser/parser.mly"
   _1
# 3829 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 260 "lib/parser/parser.mly"
                                                          ( ps )
# 3834 "lib/parser/q2_inferred.mli"
     : 'tv_kind_params) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 259 "lib/parser/parser.mly"
    ( [] )
# 3840 "lib/parser/q2_inferred.mli"
     : 'tv_kind_params) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 264 "lib/parser/parser.mly"
                      _3
# 3845 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 264 "lib/parser/parser.mly"
                _2
# 3849 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 264 "lib/parser/parser.mly"
    name
# 3853 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 264 "lib/parser/parser.mly"
                                   ( (name, KNat) )
# 3858 "lib/parser/q2_inferred.mli"
     : 'tv_kind_param) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 263 "lib/parser/parser.mly"
    name
# 3863 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 263 "lib/parser/parser.mly"
                                   ( (name, KType) )
# 3868 "lib/parser/q2_inferred.mli"
     : 'tv_kind_param) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 157 "lib/parser/parser.mly"
                                                     _3
# 3873 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 157 "lib/parser/parser.mly"
        path
# 3877 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_DCOLON_ident_) (_startpos_path_ : Lexing.position) (_endpos_path_ : Lexing.position) (_startofs_path_ : int) (_endofs_path_ : int) (_loc_path_ : Lexing.position * Lexing.position) (
# 157 "lib/parser/parser.mly"
   _1
# 3881 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 158 "lib/parser/parser.mly"
    ( mk_item (IUse path) _startpos )
# 3886 "lib/parser/q2_inferred.mli"
     : 'tv_item) : (
# 115 "lib/parser/parser.mly"
       (Ast.item)
# 3890 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 155 "lib/parser/parser.mly"
    e
# 3895 "lib/parser/q2_inferred.mli"
   : 'tv_extern_def) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 156 "lib/parser/parser.mly"
    ( mk_item (IExtern e) _startpos )
# 3900 "lib/parser/q2_inferred.mli"
     : 'tv_item) : (
# 115 "lib/parser/parser.mly"
       (Ast.item)
# 3904 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 153 "lib/parser/parser.mly"
    i
# 3909 "lib/parser/q2_inferred.mli"
   : 'tv_impl_def) (_startpos_i_ : Lexing.position) (_endpos_i_ : Lexing.position) (_startofs_i_ : int) (_endofs_i_ : int) (_loc_i_ : Lexing.position * Lexing.position) ->
    ((
# 154 "lib/parser/parser.mly"
    ( mk_item (IImpl i) _startpos )
# 3914 "lib/parser/q2_inferred.mli"
     : 'tv_item) : (
# 115 "lib/parser/parser.mly"
       (Ast.item)
# 3918 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 151 "lib/parser/parser.mly"
    e
# 3923 "lib/parser/q2_inferred.mli"
   : 'tv_enum_def) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 152 "lib/parser/parser.mly"
    ( mk_item (IEnum e) _startpos )
# 3928 "lib/parser/q2_inferred.mli"
     : 'tv_item) : (
# 115 "lib/parser/parser.mly"
       (Ast.item)
# 3932 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 149 "lib/parser/parser.mly"
    s
# 3937 "lib/parser/q2_inferred.mli"
   : 'tv_struct_def) (_startpos_s_ : Lexing.position) (_endpos_s_ : Lexing.position) (_startofs_s_ : int) (_endofs_s_ : int) (_loc_s_ : Lexing.position * Lexing.position) ->
    ((
# 150 "lib/parser/parser.mly"
    ( mk_item (IStruct s) _startpos )
# 3942 "lib/parser/q2_inferred.mli"
     : 'tv_item) : (
# 115 "lib/parser/parser.mly"
       (Ast.item)
# 3946 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 147 "lib/parser/parser.mly"
    t
# 3951 "lib/parser/q2_inferred.mli"
   : 'tv_type_def) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) ->
    ((
# 148 "lib/parser/parser.mly"
    ( mk_item (IType t) _startpos )
# 3956 "lib/parser/q2_inferred.mli"
     : 'tv_item) : (
# 115 "lib/parser/parser.mly"
       (Ast.item)
# 3960 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 145 "lib/parser/parser.mly"
    f
# 3965 "lib/parser/q2_inferred.mli"
   : 'tv_fn_def) (_startpos_f_ : Lexing.position) (_endpos_f_ : Lexing.position) (_startofs_f_ : int) (_endofs_f_ : int) (_loc_f_ : Lexing.position * Lexing.position) ->
    ((
# 146 "lib/parser/parser.mly"
    ( mk_item (IFn f) _startpos )
# 3970 "lib/parser/q2_inferred.mli"
     : 'tv_item) : (
# 115 "lib/parser/parser.mly"
       (Ast.item)
# 3974 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 256 "lib/parser/parser.mly"
              p
# 3979 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3983 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 256 "lib/parser/parser.mly"
   _1
# 3987 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 256 "lib/parser/parser.mly"
                            ( p )
# 3992 "lib/parser/q2_inferred.mli"
     : 'tv_invariant_clause) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 255 "lib/parser/parser.mly"
                      _3
# 3997 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 255 "lib/parser/parser.mly"
              p
# 4001 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 4005 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 255 "lib/parser/parser.mly"
   _1
# 4009 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 255 "lib/parser/parser.mly"
                            ( p )
# 4014 "lib/parser/q2_inferred.mli"
     : 'tv_invariant_clause) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 296 "lib/parser/parser.mly"
                                         _5
# 4019 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 296 "lib/parser/parser.mly"
                       items
# 4023 "lib/parser/q2_inferred.mli"
   : 'tv_list_item_) (_startpos_items_ : Lexing.position) (_endpos_items_ : Lexing.position) (_startofs_items_ : int) (_endofs_items_ : int) (_loc_items_ : Lexing.position * Lexing.position) (
# 296 "lib/parser/parser.mly"
               _3
# 4027 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 296 "lib/parser/parser.mly"
         t
# 4031 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 4035 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 296 "lib/parser/parser.mly"
   _1
# 4039 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 297 "lib/parser/parser.mly"
    (
      {
        im_ty    = t;
        im_items = items;
      }
    )
# 4049 "lib/parser/q2_inferred.mli"
     : 'tv_impl_def) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 667 "lib/parser/parser.mly"
    else_
# 4054 "lib/parser/q2_inferred.mli"
   : 'tv_option_preceded_ELSE_else_branch__) (_startpos_else__ : Lexing.position) (_endpos_else__ : Lexing.position) (_startofs_else__ : int) (_endofs_else__ : int) (_loc_else__ : Lexing.position * Lexing.position) (
# 666 "lib/parser/parser.mly"
    then_
# 4058 "lib/parser/q2_inferred.mli"
   : 'tv_block_expr) (_startpos_then__ : Lexing.position) (_endpos_then__ : Lexing.position) (_startofs_then__ : int) (_endofs_then__ : int) (_loc_then__ : Lexing.position * Lexing.position) ((
# 665 "lib/parser/parser.mly"
       cond
# 4062 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4066 "lib/parser/q2_inferred.mli"
  )) (_startpos_cond_ : Lexing.position) (_endpos_cond_ : Lexing.position) (_startofs_cond_ : int) (_endofs_cond_ : int) (_loc_cond_ : Lexing.position * Lexing.position) (
# 665 "lib/parser/parser.mly"
   _1
# 4070 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 668 "lib/parser/parser.mly"
    ( mk_expr (EIf (cond, then_, else_)) _startpos )
# 4075 "lib/parser/q2_inferred.mli"
     : 'tv_if_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 889 "lib/parser/parser.mly"
   _1
# 4080 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 889 "lib/parser/parser.mly"
               ( mk_ident "varying"    _startpos )
# 4085 "lib/parser/q2_inferred.mli"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 888 "lib/parser/parser.mly"
   _1
# 4090 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 888 "lib/parser/parser.mly"
               ( mk_ident "uniform"    _startpos )
# 4095 "lib/parser/q2_inferred.mli"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 887 "lib/parser/parser.mly"
   _1
# 4100 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 887 "lib/parser/parser.mly"
               ( mk_ident "shared"     _startpos )
# 4105 "lib/parser/q2_inferred.mli"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 886 "lib/parser/parser.mly"
   _1
# 4110 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 886 "lib/parser/parser.mly"
               ( mk_ident "span"       _startpos )
# 4115 "lib/parser/q2_inferred.mli"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 885 "lib/parser/parser.mly"
   _1
# 4120 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 885 "lib/parser/parser.mly"
               ( mk_ident "coalesced"  _startpos )
# 4125 "lib/parser/q2_inferred.mli"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 884 "lib/parser/parser.mly"
   _1
# 4130 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 884 "lib/parser/parser.mly"
               ( mk_ident "kernel"     _startpos )
# 4135 "lib/parser/q2_inferred.mli"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 882 "lib/parser/parser.mly"
   _1
# 4140 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 882 "lib/parser/parser.mly"
               ( mk_ident "by"         _startpos )
# 4145 "lib/parser/q2_inferred.mli"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 881 "lib/parser/parser.mly"
   _1
# 4150 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 881 "lib/parser/parser.mly"
               ( mk_ident "raw"        _startpos )
# 4155 "lib/parser/q2_inferred.mli"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 878 "lib/parser/parser.mly"
    name
# 4160 "lib/parser/q2_inferred.mli"
   : (
# 19 "lib/parser/parser.mly"
       (string)
# 4164 "lib/parser/q2_inferred.mli"
  )) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 879 "lib/parser/parser.mly"
    ( mk_ident name _startpos )
# 4169 "lib/parser/q2_inferred.mli"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 172 "lib/parser/parser.mly"
    body
# 4174 "lib/parser/q2_inferred.mli"
   : 'tv_fn_body) (_startpos_body_ : Lexing.position) (_endpos_body_ : Lexing.position) (_startofs_body_ : int) (_endofs_body_ : int) (_loc_body_ : Lexing.position * Lexing.position) (
# 171 "lib/parser/parser.mly"
    dec
# 4178 "lib/parser/q2_inferred.mli"
   : 'tv_option_decreases_clause_) (_startpos_dec_ : Lexing.position) (_endpos_dec_ : Lexing.position) (_startofs_dec_ : int) (_endofs_dec_ : int) (_loc_dec_ : Lexing.position * Lexing.position) (
# 170 "lib/parser/parser.mly"
    enss
# 4182 "lib/parser/q2_inferred.mli"
   : 'tv_list_ensures_clause_) (_startpos_enss_ : Lexing.position) (_endpos_enss_ : Lexing.position) (_startofs_enss_ : int) (_endofs_enss_ : int) (_loc_enss_ : Lexing.position * Lexing.position) (
# 169 "lib/parser/parser.mly"
    reqs
# 4186 "lib/parser/q2_inferred.mli"
   : 'tv_list_requires_clause_) (_startpos_reqs_ : Lexing.position) (_endpos_reqs_ : Lexing.position) (_startofs_reqs_ : int) (_endofs_reqs_ : int) (_loc_reqs_ : Lexing.position * Lexing.position) (
# 168 "lib/parser/parser.mly"
    ret
# 4190 "lib/parser/q2_inferred.mli"
   : 'tv_option_preceded_ARROW_ty__) (_startpos_ret_ : Lexing.position) (_endpos_ret_ : Lexing.position) (_startofs_ret_ : int) (_endofs_ret_ : int) (_loc_ret_ : Lexing.position * Lexing.position) (
# 167 "lib/parser/parser.mly"
                                _7
# 4194 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__7_ : Lexing.position) (_endpos__7_ : Lexing.position) (_startofs__7_ : int) (_endofs__7_ : int) (_loc__7_ : Lexing.position * Lexing.position) (
# 167 "lib/parser/parser.mly"
           params
# 4198 "lib/parser/q2_inferred.mli"
   : 'tv_tlist_param_) (_startpos_params_ : Lexing.position) (_endpos_params_ : Lexing.position) (_startofs_params_ : int) (_endofs_params_ : int) (_loc_params_ : Lexing.position * Lexing.position) (
# 166 "lib/parser/parser.mly"
                          _5
# 4203 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 166 "lib/parser/parser.mly"
    generics
# 4207 "lib/parser/q2_inferred.mli"
   : 'tv_kind_params) (_startpos_generics_ : Lexing.position) (_endpos_generics_ : Lexing.position) (_startofs_generics_ : int) (_endofs_generics_ : int) (_loc_generics_ : Lexing.position * Lexing.position) (
# 165 "lib/parser/parser.mly"
                                 name
# 4211 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 165 "lib/parser/parser.mly"
                             _2
# 4215 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 165 "lib/parser/parser.mly"
    attrs
# 4219 "lib/parser/q2_inferred.mli"
   : 'tv_list_attr_clause_) (_startpos_attrs_ : Lexing.position) (_endpos_attrs_ : Lexing.position) (_startofs_attrs_ : int) (_endofs_attrs_ : int) (_loc_attrs_ : Lexing.position * Lexing.position) ->
    (
# 173 "lib/parser/parser.mly"
    (
      let ret_ty = match ret with Some t -> t | None -> TPrim TUnit in
      {
        fn_name     = name;
        fn_generics = generics;
        fn_params   = params;
        fn_ret      = ret_ty;
        fn_requires = reqs;
        fn_ensures  = enss;
        fn_decreases = dec;
        fn_body     = body;
        fn_attrs    = attrs;
      }
    )
# 4237 "lib/parser/q2_inferred.mli"
     : 'tv_fn_def) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 209 "lib/parser/parser.mly"
    e
# 4242 "lib/parser/q2_inferred.mli"
   : 'tv_block_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 209 "lib/parser/parser.mly"
                   ( Some e )
# 4247 "lib/parser/q2_inferred.mli"
     : 'tv_fn_body) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 208 "lib/parser/parser.mly"
   _1
# 4252 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 208 "lib/parser/parser.mly"
                 ( None )
# 4257 "lib/parser/q2_inferred.mli"
     : 'tv_fn_body) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 328 "lib/parser/parser.mly"
       s
# 4262 "lib/parser/q2_inferred.mli"
   : (
# 18 "lib/parser/parser.mly"
       (string)
# 4266 "lib/parser/q2_inferred.mli"
  )) (_startpos_s_ : Lexing.position) (_endpos_s_ : Lexing.position) (_startofs_s_ : int) (_endofs_s_ : int) (_loc_s_ : Lexing.position * Lexing.position) (
# 328 "lib/parser/parser.mly"
   _1
# 4270 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 328 "lib/parser/parser.mly"
                  ( s )
# 4275 "lib/parser/q2_inferred.mli"
     : 'tv_extern_link) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 314 "lib/parser/parser.mly"
                              _11
# 4281 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__11_ : Lexing.position) (_endpos__11_ : Lexing.position) (_startofs__11_ : int) (_endofs__11_ : int) (_loc__11_ : Lexing.position * Lexing.position) (
# 314 "lib/parser/parser.mly"
    link
# 4285 "lib/parser/q2_inferred.mli"
   : 'tv_option_extern_link_) (_startpos_link_ : Lexing.position) (_endpos_link_ : Lexing.position) (_startofs_link_ : int) (_endofs_link_ : int) (_loc_link_ : Lexing.position * Lexing.position) (
# 313 "lib/parser/parser.mly"
    enss
# 4289 "lib/parser/q2_inferred.mli"
   : 'tv_list_ensures_clause_) (_startpos_enss_ : Lexing.position) (_endpos_enss_ : Lexing.position) (_startofs_enss_ : int) (_endofs_enss_ : int) (_loc_enss_ : Lexing.position * Lexing.position) (
# 312 "lib/parser/parser.mly"
    reqs
# 4293 "lib/parser/q2_inferred.mli"
   : 'tv_list_requires_clause_) (_startpos_reqs_ : Lexing.position) (_endpos_reqs_ : Lexing.position) (_startofs_reqs_ : int) (_endofs_reqs_ : int) (_loc_reqs_ : Lexing.position * Lexing.position) (
# 311 "lib/parser/parser.mly"
    ret
# 4297 "lib/parser/q2_inferred.mli"
   : 'tv_option_preceded_ARROW_ty__) (_startpos_ret_ : Lexing.position) (_endpos_ret_ : Lexing.position) (_startofs_ret_ : int) (_endofs_ret_ : int) (_loc_ret_ : Lexing.position * Lexing.position) (
# 310 "lib/parser/parser.mly"
                                _6
# 4301 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) (
# 310 "lib/parser/parser.mly"
           params
# 4305 "lib/parser/q2_inferred.mli"
   : 'tv_tlist_param_) (_startpos_params_ : Lexing.position) (_endpos_params_ : Lexing.position) (_startofs_params_ : int) (_endofs_params_ : int) (_loc_params_ : Lexing.position * Lexing.position) (
# 309 "lib/parser/parser.mly"
                          _4
# 4310 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 309 "lib/parser/parser.mly"
              name
# 4314 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 309 "lib/parser/parser.mly"
          _2
# 4318 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 309 "lib/parser/parser.mly"
   _1
# 4322 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 316 "lib/parser/parser.mly"
    (
      let ret_ty = match ret with Some t -> t | None -> TPrim TUnit in
      let link_name = match link with Some s -> s | None -> name.name in
      let fn_ty = TFn (mk_fn_ty params ret_ty reqs enss) in
      {
        ex_name = name;
        ex_ty   = fn_ty;
        ex_link = link_name;
      }
    )
# 4336 "lib/parser/q2_inferred.mli"
     : 'tv_extern_def) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 578 "lib/parser/parser.mly"
    e
# 4341 "lib/parser/q2_inferred.mli"
   : 'tv_atom_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 578 "lib/parser/parser.mly"
                      ( e )
# 4346 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4350 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 573 "lib/parser/parser.mly"
                                       _5
# 4356 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 573 "lib/parser/parser.mly"
      fields
# 4360 "lib/parser/q2_inferred.mli"
   : 'tv_tlist_struct_field_init_) (_startpos_fields_ : Lexing.position) (_endpos_fields_ : Lexing.position) (_startofs_fields_ : int) (_endofs_fields_ : int) (_loc_fields_ : Lexing.position * Lexing.position) (
# 572 "lib/parser/parser.mly"
                       _3
# 4364 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 572 "lib/parser/parser.mly"
           name
# 4368 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 572 "lib/parser/parser.mly"
   _1
# 4372 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 575 "lib/parser/parser.mly"
    ( mk_expr (EStruct (name, fields)) _startpos )
# 4377 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4381 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 568 "lib/parser/parser.mly"
                t
# 4386 "lib/parser/q2_inferred.mli"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 4390 "lib/parser/q2_inferred.mli"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 568 "lib/parser/parser.mly"
            _2
# 4394 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 568 "lib/parser/parser.mly"
    e
# 4398 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4402 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 569 "lib/parser/parser.mly"
    ( mk_expr (ECast (e, t)) _startpos )
# 4407 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4411 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 564 "lib/parser/parser.mly"
                      _3
# 4416 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 564 "lib/parser/parser.mly"
               _2
# 4420 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 564 "lib/parser/parser.mly"
   _1
# 4424 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 565 "lib/parser/parser.mly"
    ( mk_expr ESync _startpos )
# 4429 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4433 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 561 "lib/parser/parser.mly"
    e
# 4438 "lib/parser/q2_inferred.mli"
   : 'tv_return_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 561 "lib/parser/parser.mly"
                      ( e )
# 4443 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4447 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 560 "lib/parser/parser.mly"
    e
# 4452 "lib/parser/q2_inferred.mli"
   : 'tv_assume_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 560 "lib/parser/parser.mly"
                      ( e )
# 4457 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4461 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 559 "lib/parser/parser.mly"
    e
# 4466 "lib/parser/q2_inferred.mli"
   : 'tv_raw_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 559 "lib/parser/parser.mly"
                      ( e )
# 4471 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4475 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 558 "lib/parser/parser.mly"
    e
# 4480 "lib/parser/q2_inferred.mli"
   : 'tv_proof_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 558 "lib/parser/parser.mly"
                      ( e )
# 4485 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4489 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 557 "lib/parser/parser.mly"
    e
# 4494 "lib/parser/q2_inferred.mli"
   : 'tv_loop_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 557 "lib/parser/parser.mly"
                      ( e )
# 4499 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4503 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 556 "lib/parser/parser.mly"
    e
# 4508 "lib/parser/q2_inferred.mli"
   : 'tv_match_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 556 "lib/parser/parser.mly"
                      ( e )
# 4513 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4517 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 555 "lib/parser/parser.mly"
    e
# 4522 "lib/parser/q2_inferred.mli"
   : 'tv_if_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 555 "lib/parser/parser.mly"
                      ( e )
# 4527 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4531 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 554 "lib/parser/parser.mly"
    e
# 4536 "lib/parser/q2_inferred.mli"
   : 'tv_block_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 554 "lib/parser/parser.mly"
                      ( e )
# 4541 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4545 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 548 "lib/parser/parser.mly"
                     alt
# 4550 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4554 "lib/parser/q2_inferred.mli"
  )) (_startpos_alt_ : Lexing.position) (_endpos_alt_ : Lexing.position) (_startofs_alt_ : int) (_endofs_alt_ : int) (_loc_alt_ : Lexing.position * Lexing.position) (
# 548 "lib/parser/parser.mly"
            _2
# 4558 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 548 "lib/parser/parser.mly"
    e
# 4562 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4566 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 549 "lib/parser/parser.mly"
    ( mk_expr (ECall (
        mk_expr (EVar (mk_ident "__or_fail__" _startpos)) _startpos,
        [e; alt])) _startpos )
# 4573 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4577 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 544 "lib/parser/parser.mly"
                       alt
# 4582 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4586 "lib/parser/q2_inferred.mli"
  )) (_startpos_alt_ : Lexing.position) (_endpos_alt_ : Lexing.position) (_startofs_alt_ : int) (_endofs_alt_ : int) (_loc_alt_ : Lexing.position * Lexing.position) (
# 544 "lib/parser/parser.mly"
            _2
# 4590 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 544 "lib/parser/parser.mly"
    e
# 4594 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4598 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 545 "lib/parser/parser.mly"
    ( mk_expr (ECall (
        mk_expr (EVar (mk_ident "__or_return__" _startpos)) _startpos,
        [e; alt])) _startpos )
# 4605 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4609 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 540 "lib/parser/parser.mly"
                                      _4
# 4614 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 540 "lib/parser/parser.mly"
                    args
# 4618 "lib/parser/q2_inferred.mli"
   : 'tv_tlist_expr_) (_startpos_args_ : Lexing.position) (_endpos_args_ : Lexing.position) (_startofs_args_ : int) (_endofs_args_ : int) (_loc_args_ : Lexing.position * Lexing.position) (
# 540 "lib/parser/parser.mly"
            _2
# 4622 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 540 "lib/parser/parser.mly"
    f
# 4626 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4630 "lib/parser/q2_inferred.mli"
  )) (_startpos_f_ : Lexing.position) (_endpos_f_ : Lexing.position) (_startofs_f_ : int) (_endofs_f_ : int) (_loc_f_ : Lexing.position * Lexing.position) ->
    ((
# 541 "lib/parser/parser.mly"
    ( mk_expr (ECall (f, args)) _startpos )
# 4635 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4639 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 538 "lib/parser/parser.mly"
                                _4
# 4644 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 538 "lib/parser/parser.mly"
                      idx
# 4648 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4652 "lib/parser/q2_inferred.mli"
  )) (_startpos_idx_ : Lexing.position) (_endpos_idx_ : Lexing.position) (_startofs_idx_ : int) (_endofs_idx_ : int) (_loc_idx_ : Lexing.position * Lexing.position) (
# 538 "lib/parser/parser.mly"
            _2
# 4656 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 538 "lib/parser/parser.mly"
    e
# 4660 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4664 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 539 "lib/parser/parser.mly"
    ( mk_expr (EIndex (e, idx)) _startpos )
# 4669 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4673 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 536 "lib/parser/parser.mly"
                 n
# 4678 "lib/parser/q2_inferred.mli"
   : (
# 15 "lib/parser/parser.mly"
       (int64)
# 4682 "lib/parser/q2_inferred.mli"
  )) (_startpos_n_ : Lexing.position) (_endpos_n_ : Lexing.position) (_startofs_n_ : int) (_endofs_n_ : int) (_loc_n_ : Lexing.position * Lexing.position) (
# 536 "lib/parser/parser.mly"
            _2
# 4686 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 536 "lib/parser/parser.mly"
    e
# 4690 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4694 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 537 "lib/parser/parser.mly"
    ( mk_expr (EField_n (e, Int64.to_int n)) _startpos )
# 4699 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4703 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 534 "lib/parser/parser.mly"
                 name
# 4708 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 534 "lib/parser/parser.mly"
            _2
# 4712 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 534 "lib/parser/parser.mly"
    e
# 4716 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4720 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 535 "lib/parser/parser.mly"
    ( mk_expr (EField (e, name)) _startpos )
# 4725 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4729 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 531 "lib/parser/parser.mly"
          e
# 4734 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4738 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 531 "lib/parser/parser.mly"
   _1
# 4742 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 531 "lib/parser/parser.mly"
                                 ( mk_expr (ERef e)             _startpos )
# 4747 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4751 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 530 "lib/parser/parser.mly"
          e
# 4756 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4760 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 530 "lib/parser/parser.mly"
   _1
# 4764 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 530 "lib/parser/parser.mly"
                                 ( mk_expr (EDeref e)          _startpos )
# 4769 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4773 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 529 "lib/parser/parser.mly"
          e
# 4778 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4782 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 529 "lib/parser/parser.mly"
   _1
# 4786 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 529 "lib/parser/parser.mly"
                                 ( mk_expr (EUnop (BitNot, e)) _startpos )
# 4791 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4795 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 528 "lib/parser/parser.mly"
          e
# 4800 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4804 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 528 "lib/parser/parser.mly"
   _1
# 4808 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 528 "lib/parser/parser.mly"
                                 ( mk_expr (EUnop (Not,    e)) _startpos )
# 4813 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4817 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 527 "lib/parser/parser.mly"
          e
# 4822 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4826 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 527 "lib/parser/parser.mly"
   _1
# 4830 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 527 "lib/parser/parser.mly"
                                 ( mk_expr (EUnop (Neg,    e)) _startpos )
# 4835 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4839 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 524 "lib/parser/parser.mly"
                     r
# 4844 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4848 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 524 "lib/parser/parser.mly"
            _2
# 4852 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 524 "lib/parser/parser.mly"
    l
# 4856 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4860 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 524 "lib/parser/parser.mly"
                               ( desugar_aug_assign l Div r _startpos )
# 4865 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4869 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 523 "lib/parser/parser.mly"
                     r
# 4874 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4878 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 523 "lib/parser/parser.mly"
            _2
# 4882 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 523 "lib/parser/parser.mly"
    l
# 4886 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4890 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 523 "lib/parser/parser.mly"
                               ( desugar_aug_assign l Mul r _startpos )
# 4895 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4899 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 522 "lib/parser/parser.mly"
                     r
# 4904 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4908 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 522 "lib/parser/parser.mly"
            _2
# 4912 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 522 "lib/parser/parser.mly"
    l
# 4916 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4920 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 522 "lib/parser/parser.mly"
                               ( desugar_aug_assign l Sub r _startpos )
# 4925 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4929 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 521 "lib/parser/parser.mly"
                     r
# 4934 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4938 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 521 "lib/parser/parser.mly"
            _2
# 4942 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 521 "lib/parser/parser.mly"
    l
# 4946 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4950 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 521 "lib/parser/parser.mly"
                               ( desugar_aug_assign l Add r _startpos )
# 4955 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4959 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 520 "lib/parser/parser.mly"
                     r
# 4964 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4968 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 520 "lib/parser/parser.mly"
            _2
# 4972 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 520 "lib/parser/parser.mly"
    l
# 4976 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4980 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 520 "lib/parser/parser.mly"
                               ( mk_expr (EAssign (l, r))                            _startpos )
# 4985 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4989 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 517 "lib/parser/parser.mly"
                     r
# 4994 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4998 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 517 "lib/parser/parser.mly"
            _2
# 5002 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 517 "lib/parser/parser.mly"
    l
# 5006 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5010 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 517 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Mod,     l, r)) _startpos )
# 5015 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5019 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 516 "lib/parser/parser.mly"
                     r
# 5024 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5028 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 516 "lib/parser/parser.mly"
            _2
# 5032 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 516 "lib/parser/parser.mly"
    l
# 5036 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5040 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 516 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Div,     l, r)) _startpos )
# 5045 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5049 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 515 "lib/parser/parser.mly"
                     r
# 5054 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5058 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 515 "lib/parser/parser.mly"
            _2
# 5062 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 515 "lib/parser/parser.mly"
    l
# 5066 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5070 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 515 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Mul,     l, r)) _startpos )
# 5075 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5079 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 514 "lib/parser/parser.mly"
                     r
# 5084 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5088 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 514 "lib/parser/parser.mly"
            _2
# 5092 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 514 "lib/parser/parser.mly"
    l
# 5096 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5100 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 514 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Sub,     l, r)) _startpos )
# 5105 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5109 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 513 "lib/parser/parser.mly"
                     r
# 5114 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5118 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 513 "lib/parser/parser.mly"
            _2
# 5122 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 513 "lib/parser/parser.mly"
    l
# 5126 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5130 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 513 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Add,     l, r)) _startpos )
# 5135 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5139 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 512 "lib/parser/parser.mly"
                     r
# 5144 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5148 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 512 "lib/parser/parser.mly"
            _2
# 5152 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 512 "lib/parser/parser.mly"
    l
# 5156 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5160 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 512 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Shr,     l, r)) _startpos )
# 5165 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5169 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 511 "lib/parser/parser.mly"
                     r
# 5174 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5178 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 511 "lib/parser/parser.mly"
            _2
# 5182 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 511 "lib/parser/parser.mly"
    l
# 5186 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5190 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 511 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Shl,     l, r)) _startpos )
# 5195 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5199 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 510 "lib/parser/parser.mly"
                     r
# 5204 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5208 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 510 "lib/parser/parser.mly"
            _2
# 5212 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 510 "lib/parser/parser.mly"
    l
# 5216 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5220 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 510 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (BitAnd,  l, r)) _startpos )
# 5225 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5229 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 509 "lib/parser/parser.mly"
                     r
# 5234 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5238 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 509 "lib/parser/parser.mly"
            _2
# 5242 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 509 "lib/parser/parser.mly"
    l
# 5246 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5250 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 509 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (BitXor,  l, r)) _startpos )
# 5255 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5259 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 508 "lib/parser/parser.mly"
                     r
# 5264 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5268 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 508 "lib/parser/parser.mly"
            _2
# 5272 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 508 "lib/parser/parser.mly"
    l
# 5276 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5280 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 508 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (BitOr,   l, r)) _startpos )
# 5285 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5289 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 507 "lib/parser/parser.mly"
                     r
# 5294 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5298 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 507 "lib/parser/parser.mly"
            _2
# 5302 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 507 "lib/parser/parser.mly"
    l
# 5306 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5310 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 507 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Ge,      l, r)) _startpos )
# 5315 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5319 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 506 "lib/parser/parser.mly"
                     r
# 5324 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5328 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 506 "lib/parser/parser.mly"
            _2
# 5332 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 506 "lib/parser/parser.mly"
    l
# 5336 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5340 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 506 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Gt,      l, r)) _startpos )
# 5345 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5349 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 505 "lib/parser/parser.mly"
                     r
# 5354 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5358 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 505 "lib/parser/parser.mly"
            _2
# 5362 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 505 "lib/parser/parser.mly"
    l
# 5366 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5370 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 505 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Le,      l, r)) _startpos )
# 5375 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5379 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 504 "lib/parser/parser.mly"
                     r
# 5384 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5388 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 504 "lib/parser/parser.mly"
            _2
# 5392 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 504 "lib/parser/parser.mly"
    l
# 5396 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5400 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 504 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Lt,      l, r)) _startpos )
# 5405 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5409 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 503 "lib/parser/parser.mly"
                     r
# 5414 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5418 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 503 "lib/parser/parser.mly"
            _2
# 5422 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 503 "lib/parser/parser.mly"
    l
# 5426 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5430 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 503 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Ne,      l, r)) _startpos )
# 5435 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5439 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 502 "lib/parser/parser.mly"
                     r
# 5444 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5448 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 502 "lib/parser/parser.mly"
            _2
# 5452 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 502 "lib/parser/parser.mly"
    l
# 5456 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5460 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 502 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Eq,      l, r)) _startpos )
# 5465 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5469 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 501 "lib/parser/parser.mly"
                     r
# 5474 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5478 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 501 "lib/parser/parser.mly"
            _2
# 5482 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 501 "lib/parser/parser.mly"
    l
# 5486 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5490 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 501 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (And,     l, r)) _startpos )
# 5495 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5499 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 500 "lib/parser/parser.mly"
                     r
# 5504 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5508 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 500 "lib/parser/parser.mly"
            _2
# 5512 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 500 "lib/parser/parser.mly"
    l
# 5516 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5520 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 500 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Or,      l, r)) _startpos )
# 5525 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5529 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 499 "lib/parser/parser.mly"
                     r
# 5534 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5538 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 499 "lib/parser/parser.mly"
            _2
# 5542 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 499 "lib/parser/parser.mly"
    l
# 5546 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5550 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 499 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Implies, l, r)) _startpos )
# 5555 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5559 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 498 "lib/parser/parser.mly"
                     r
# 5564 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5568 "lib/parser/q2_inferred.mli"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 498 "lib/parser/parser.mly"
            _2
# 5572 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 498 "lib/parser/parser.mly"
    l
# 5576 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5580 "lib/parser/q2_inferred.mli"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 498 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Iff,     l, r)) _startpos )
# 5585 "lib/parser/q2_inferred.mli"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5589 "lib/parser/q2_inferred.mli"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 288 "lib/parser/parser.mly"
                                          _4
# 5594 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 288 "lib/parser/parser.mly"
                        fields
# 5598 "lib/parser/q2_inferred.mli"
   : 'tv_tlist_ty_) (_startpos_fields_ : Lexing.position) (_endpos_fields_ : Lexing.position) (_startofs_fields_ : int) (_endofs_fields_ : int) (_loc_fields_ : Lexing.position * Lexing.position) (
# 288 "lib/parser/parser.mly"
                _2
# 5602 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 288 "lib/parser/parser.mly"
    name
# 5606 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 289 "lib/parser/parser.mly"
    ( (name, fields) )
# 5611 "lib/parser/q2_inferred.mli"
     : 'tv_enum_variant) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 286 "lib/parser/parser.mly"
    name
# 5616 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 287 "lib/parser/parser.mly"
    ( (name, []) )
# 5621 "lib/parser/q2_inferred.mli"
     : 'tv_enum_variant) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 284 "lib/parser/parser.mly"
                                                 _5
# 5626 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 284 "lib/parser/parser.mly"
                                          _4
# 5630 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 284 "lib/parser/parser.mly"
                        fields
# 5634 "lib/parser/q2_inferred.mli"
   : 'tv_tlist_ty_) (_startpos_fields_ : Lexing.position) (_endpos_fields_ : Lexing.position) (_startofs_fields_ : int) (_endofs_fields_ : int) (_loc_fields_ : Lexing.position * Lexing.position) (
# 284 "lib/parser/parser.mly"
                _2
# 5638 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 284 "lib/parser/parser.mly"
    name
# 5642 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 285 "lib/parser/parser.mly"
    ( (name, fields) )
# 5647 "lib/parser/q2_inferred.mli"
     : 'tv_enum_variant) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 282 "lib/parser/parser.mly"
                _2
# 5652 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 282 "lib/parser/parser.mly"
    name
# 5656 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 283 "lib/parser/parser.mly"
    ( (name, []) )
# 5661 "lib/parser/q2_inferred.mli"
     : 'tv_enum_variant) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 272 "lib/parser/parser.mly"
                                        _6
# 5666 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) (
# 272 "lib/parser/parser.mly"
           variants
# 5670 "lib/parser/q2_inferred.mli"
   : 'tv_list_enum_variant_) (_startpos_variants_ : Lexing.position) (_endpos_variants_ : Lexing.position) (_startofs_variants_ : int) (_endofs_variants_ : int) (_loc_variants_ : Lexing.position * Lexing.position) (
# 271 "lib/parser/parser.mly"
                                          _4
# 5675 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 271 "lib/parser/parser.mly"
                      params
# 5679 "lib/parser/q2_inferred.mli"
   : 'tv_kind_params) (_startpos_params_ : Lexing.position) (_endpos_params_ : Lexing.position) (_startofs_params_ : int) (_endofs_params_ : int) (_loc_params_ : Lexing.position * Lexing.position) (
# 271 "lib/parser/parser.mly"
         name
# 5683 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 271 "lib/parser/parser.mly"
   _1
# 5687 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 273 "lib/parser/parser.mly"
    (
      {
        ed_name     = name;
        ed_params   = params;
        ed_variants = variants;
      }
    )
# 5698 "lib/parser/q2_inferred.mli"
     : 'tv_enum_def) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 202 "lib/parser/parser.mly"
            p
# 5703 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 5707 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 202 "lib/parser/parser.mly"
   _1
# 5711 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 202 "lib/parser/parser.mly"
                     ( p )
# 5716 "lib/parser/q2_inferred.mli"
     : 'tv_ensures_clause) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 672 "lib/parser/parser.mly"
    e
# 5721 "lib/parser/q2_inferred.mli"
   : 'tv_if_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 672 "lib/parser/parser.mly"
                   ( e )
# 5726 "lib/parser/q2_inferred.mli"
     : 'tv_else_branch) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 671 "lib/parser/parser.mly"
    e
# 5731 "lib/parser/q2_inferred.mli"
   : 'tv_block_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 671 "lib/parser/parser.mly"
                   ( e )
# 5736 "lib/parser/q2_inferred.mli"
     : 'tv_else_branch) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 205 "lib/parser/parser.mly"
              p
# 5741 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 5745 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 205 "lib/parser/parser.mly"
   _1
# 5749 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 205 "lib/parser/parser.mly"
                       ( p )
# 5754 "lib/parser/q2_inferred.mli"
     : 'tv_decreases_clause) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 657 "lib/parser/parser.mly"
                  rest
# 5759 "lib/parser/q2_inferred.mli"
   : 'tv_block_stmts) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 657 "lib/parser/parser.mly"
            _2
# 5763 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 657 "lib/parser/parser.mly"
   _1
# 5767 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 658 "lib/parser/parser.mly"
    ( let (ss, ret) = rest in (mk_stmt SContinue _startpos :: ss, ret) )
# 5772 "lib/parser/q2_inferred.mli"
     : 'tv_block_stmts) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 655 "lib/parser/parser.mly"
               rest
# 5777 "lib/parser/q2_inferred.mli"
   : 'tv_block_stmts) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 655 "lib/parser/parser.mly"
         _2
# 5781 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 655 "lib/parser/parser.mly"
   _1
# 5785 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 656 "lib/parser/parser.mly"
    ( let (ss, ret) = rest in (mk_stmt SBreak _startpos :: ss, ret) )
# 5790 "lib/parser/q2_inferred.mli"
     : 'tv_block_stmts) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 642 "lib/parser/parser.mly"
                     rest
# 5795 "lib/parser/q2_inferred.mli"
   : 'tv_block_stmts) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 642 "lib/parser/parser.mly"
               _7
# 5799 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__7_ : Lexing.position) (_endpos__7_ : Lexing.position) (_startofs__7_ : int) (_endofs__7_ : int) (_loc__7_ : Lexing.position * Lexing.position) ((
# 642 "lib/parser/parser.mly"
       e
# 5803 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5807 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 641 "lib/parser/parser.mly"
                                                                   _5
# 5812 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 641 "lib/parser/parser.mly"
                                                            _4
# 5816 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 641 "lib/parser/parser.mly"
               names
# 5820 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_ident_) (_startpos_names_ : Lexing.position) (_endpos_names_ : Lexing.position) (_startofs_names_ : int) (_endofs_names_ : int) (_loc_names_ : Lexing.position * Lexing.position) (
# 641 "lib/parser/parser.mly"
       _2
# 5824 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 641 "lib/parser/parser.mly"
   _1
# 5828 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 643 "lib/parser/parser.mly"
    (
      let tmp_name = Printf.sprintf "__tup_%d_%d"
        _startpos.pos_lnum (_startpos.pos_cnum - _startpos.pos_bol) in
      let tmp = mk_ident tmp_name _startpos in
      let tup_stmt = mk_stmt (SLet (tmp, None, e, Unr)) _startpos in
      let proj_stmts = List.mapi (fun i nm ->
        let proj = mk_expr (EField_n (mk_expr (EVar tmp) _startpos, i)) _startpos in
        mk_stmt (SLet (nm, None, proj, Unr)) _startpos
      ) names in
      let (ss, ret) = rest in
      (tup_stmt :: proj_stmts @ ss, ret)
    )
# 5844 "lib/parser/q2_inferred.mli"
     : 'tv_block_stmts) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 637 "lib/parser/parser.mly"
                     rest
# 5849 "lib/parser/q2_inferred.mli"
   : 'tv_block_stmts) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 637 "lib/parser/parser.mly"
               _6
# 5853 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) ((
# 637 "lib/parser/parser.mly"
       e
# 5857 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5861 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 636 "lib/parser/parser.mly"
                                                      _4
# 5866 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 636 "lib/parser/parser.mly"
                     ann
# 5870 "lib/parser/q2_inferred.mli"
   : 'tv_option_preceded_COLON_ty__) (_startpos_ann_ : Lexing.position) (_endpos_ann_ : Lexing.position) (_startofs_ann_ : int) (_endofs_ann_ : int) (_loc_ann_ : Lexing.position * Lexing.position) (
# 636 "lib/parser/parser.mly"
        name
# 5874 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 636 "lib/parser/parser.mly"
   _1
# 5878 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 638 "lib/parser/parser.mly"
    ( let (ss, ret) = rest in (mk_stmt (SLet (name, ann, e, Unr)) _startpos :: ss, ret) )
# 5883 "lib/parser/q2_inferred.mli"
     : 'tv_block_stmts) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 634 "lib/parser/parser.mly"
                     rest
# 5888 "lib/parser/q2_inferred.mli"
   : 'tv_block_stmts) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 634 "lib/parser/parser.mly"
               _7
# 5892 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__7_ : Lexing.position) (_endpos__7_ : Lexing.position) (_startofs__7_ : int) (_endofs__7_ : int) (_loc__7_ : Lexing.position * Lexing.position) ((
# 634 "lib/parser/parser.mly"
       e
# 5896 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5900 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 633 "lib/parser/parser.mly"
                                                                      _5
# 5905 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 633 "lib/parser/parser.mly"
                                     ann
# 5909 "lib/parser/q2_inferred.mli"
   : 'tv_option_preceded_COLON_ty__) (_startpos_ann_ : Lexing.position) (_endpos_ann_ : Lexing.position) (_startofs_ann_ : int) (_endofs_ann_ : int) (_loc_ann_ : Lexing.position * Lexing.position) (
# 633 "lib/parser/parser.mly"
                        name
# 5913 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 633 "lib/parser/parser.mly"
        lin
# 5917 "lib/parser/q2_inferred.mli"
   : 'tv_linearity) (_startpos_lin_ : Lexing.position) (_endpos_lin_ : Lexing.position) (_startofs_lin_ : int) (_endofs_lin_ : int) (_loc_lin_ : Lexing.position * Lexing.position) (
# 633 "lib/parser/parser.mly"
   _1
# 5921 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 635 "lib/parser/parser.mly"
    ( let (ss, ret) = rest in (mk_stmt (SLet (name, ann, e, lin)) _startpos :: ss, ret) )
# 5926 "lib/parser/q2_inferred.mli"
     : 'tv_block_stmts) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 631 "lib/parser/parser.mly"
                  rest
# 5931 "lib/parser/q2_inferred.mli"
   : 'tv_block_stmts) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 631 "lib/parser/parser.mly"
            _2
# 5935 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 631 "lib/parser/parser.mly"
    e
# 5939 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5943 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 632 "lib/parser/parser.mly"
    ( let (ss, ret) = rest in (mk_stmt (SExpr e) _startpos :: ss, ret) )
# 5948 "lib/parser/q2_inferred.mli"
     : 'tv_block_stmts) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 629 "lib/parser/parser.mly"
    e
# 5953 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5957 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 630 "lib/parser/parser.mly"
    ( ([], Some e) )
# 5962 "lib/parser/q2_inferred.mli"
     : 'tv_block_stmts) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 628 "lib/parser/parser.mly"
    ( ([], None) )
# 5968 "lib/parser/q2_inferred.mli"
     : 'tv_block_stmts) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 616 "lib/parser/parser.mly"
                              _3
# 5973 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 616 "lib/parser/parser.mly"
           stmts
# 5977 "lib/parser/q2_inferred.mli"
   : 'tv_block_stmts) (_startpos_stmts_ : Lexing.position) (_endpos_stmts_ : Lexing.position) (_startofs_stmts_ : int) (_endofs_stmts_ : int) (_loc_stmts_ : Lexing.position * Lexing.position) (
# 616 "lib/parser/parser.mly"
   _1
# 5981 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 617 "lib/parser/parser.mly"
    (
      let (ss, ret) = stmts in
      mk_expr (EBlock (ss, ret)) _startpos
    )
# 5989 "lib/parser/q2_inferred.mli"
     : 'tv_block_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 191 "lib/parser/parser.mly"
                                                                                _7
# 5994 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__7_ : Lexing.position) (_endpos__7_ : Lexing.position) (_startofs__7_ : int) (_endofs__7_ : int) (_loc__7_ : Lexing.position * Lexing.position) (
# 191 "lib/parser/parser.mly"
                                                                         _6
# 5998 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) (
# 191 "lib/parser/parser.mly"
                                      args
# 6002 "lib/parser/q2_inferred.mli"
   : 'tv_separated_list_COMMA_IDENT_) (_startpos_args_ : Lexing.position) (_endpos_args_ : Lexing.position) (_startofs_args_ : int) (_endofs_args_ : int) (_loc_args_ : Lexing.position * Lexing.position) (
# 191 "lib/parser/parser.mly"
                              _4
# 6006 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 191 "lib/parser/parser.mly"
                  name
# 6010 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 191 "lib/parser/parser.mly"
        _2
# 6014 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 191 "lib/parser/parser.mly"
   _1
# 6018 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 192 "lib/parser/parser.mly"
    ( { attr_name = name.name; attr_args = args } )
# 6023 "lib/parser/q2_inferred.mli"
     : 'tv_attr_clause) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 189 "lib/parser/parser.mly"
                              _4
# 6028 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 189 "lib/parser/parser.mly"
                  name
# 6032 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 189 "lib/parser/parser.mly"
        _2
# 6036 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 189 "lib/parser/parser.mly"
   _1
# 6040 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 190 "lib/parser/parser.mly"
    ( { attr_name = name.name; attr_args = [] } )
# 6045 "lib/parser/q2_inferred.mli"
     : 'tv_attr_clause) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 608 "lib/parser/parser.mly"
                                   _5
# 6050 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) ((
# 608 "lib/parser/parser.mly"
                           n
# 6054 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 6058 "lib/parser/q2_inferred.mli"
  )) (_startpos_n_ : Lexing.position) (_endpos_n_ : Lexing.position) (_startofs_n_ : int) (_endofs_n_ : int) (_loc_n_ : Lexing.position * Lexing.position) (
# 608 "lib/parser/parser.mly"
                     _3
# 6062 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 608 "lib/parser/parser.mly"
             v
# 6066 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 6070 "lib/parser/q2_inferred.mli"
  )) (_startpos_v_ : Lexing.position) (_endpos_v_ : Lexing.position) (_startofs_v_ : int) (_endofs_v_ : int) (_loc_v_ : Lexing.position * Lexing.position) (
# 608 "lib/parser/parser.mly"
   _1
# 6074 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 609 "lib/parser/parser.mly"
    ( mk_expr (EArrayRepeat (v, n)) _startpos )
# 6079 "lib/parser/q2_inferred.mli"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 606 "lib/parser/parser.mly"
                                                _3
# 6084 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 606 "lib/parser/parser.mly"
             elems
# 6088 "lib/parser/q2_inferred.mli"
   : 'tv_separated_list_COMMA_expr_) (_startpos_elems_ : Lexing.position) (_endpos_elems_ : Lexing.position) (_startofs_elems_ : int) (_endofs_elems_ : int) (_loc_elems_ : Lexing.position * Lexing.position) (
# 606 "lib/parser/parser.mly"
   _1
# 6092 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 607 "lib/parser/parser.mly"
    ( mk_expr (EArrayLit elems) _startpos )
# 6097 "lib/parser/q2_inferred.mli"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 603 "lib/parser/parser.mly"
                   _3
# 6102 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 603 "lib/parser/parser.mly"
           e
# 6106 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 6110 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 603 "lib/parser/parser.mly"
   _1
# 6114 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 604 "lib/parser/parser.mly"
    ( e )
# 6119 "lib/parser/q2_inferred.mli"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 601 "lib/parser/parser.mly"
                                                                    _5
# 6124 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 601 "lib/parser/parser.mly"
                           es
# 6128 "lib/parser/q2_inferred.mli"
   : 'tv_separated_nonempty_list_COMMA_expr_) (_startpos_es_ : Lexing.position) (_endpos_es_ : Lexing.position) (_startofs_es_ : int) (_endofs_es_ : int) (_loc_es_ : Lexing.position * Lexing.position) (
# 601 "lib/parser/parser.mly"
                    _3
# 6132 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 601 "lib/parser/parser.mly"
           e1
# 6136 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 6140 "lib/parser/q2_inferred.mli"
  )) (_startpos_e1_ : Lexing.position) (_endpos_e1_ : Lexing.position) (_startofs_e1_ : int) (_endofs_e1_ : int) (_loc_e1_ : Lexing.position * Lexing.position) (
# 601 "lib/parser/parser.mly"
   _1
# 6144 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 602 "lib/parser/parser.mly"
    ( mk_expr (ETuple (e1 :: es)) _startpos )
# 6149 "lib/parser/q2_inferred.mli"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 598 "lib/parser/parser.mly"
    name
# 6154 "lib/parser/q2_inferred.mli"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 599 "lib/parser/parser.mly"
    ( mk_expr (EVar name) _startpos )
# 6159 "lib/parser/q2_inferred.mli"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 596 "lib/parser/parser.mly"
          _2
# 6164 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 596 "lib/parser/parser.mly"
   _1
# 6168 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 597 "lib/parser/parser.mly"
    ( mk_expr (ELit LUnit) _startpos )
# 6173 "lib/parser/q2_inferred.mli"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 594 "lib/parser/parser.mly"
   _1
# 6178 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 595 "lib/parser/parser.mly"
    ( mk_expr (ELit (LBool false)) _startpos )
# 6183 "lib/parser/q2_inferred.mli"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 592 "lib/parser/parser.mly"
   _1
# 6188 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 593 "lib/parser/parser.mly"
    ( mk_expr (ELit (LBool true)) _startpos )
# 6193 "lib/parser/q2_inferred.mli"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 590 "lib/parser/parser.mly"
    s
# 6198 "lib/parser/q2_inferred.mli"
   : (
# 18 "lib/parser/parser.mly"
       (string)
# 6202 "lib/parser/q2_inferred.mli"
  )) (_startpos_s_ : Lexing.position) (_endpos_s_ : Lexing.position) (_startofs_s_ : int) (_endofs_s_ : int) (_loc_s_ : Lexing.position * Lexing.position) ->
    (
# 591 "lib/parser/parser.mly"
    ( mk_expr (ELit (LStr s)) _startpos )
# 6207 "lib/parser/q2_inferred.mli"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 588 "lib/parser/parser.mly"
    f
# 6212 "lib/parser/q2_inferred.mli"
   : (
# 17 "lib/parser/parser.mly"
       (float)
# 6216 "lib/parser/q2_inferred.mli"
  )) (_startpos_f_ : Lexing.position) (_endpos_f_ : Lexing.position) (_startofs_f_ : int) (_endofs_f_ : int) (_loc_f_ : Lexing.position * Lexing.position) ->
    (
# 589 "lib/parser/parser.mly"
    ( mk_expr (ELit (LFloat (f, None))) _startpos )
# 6221 "lib/parser/q2_inferred.mli"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 586 "lib/parser/parser.mly"
    ns
# 6226 "lib/parser/q2_inferred.mli"
   : (
# 16 "lib/parser/parser.mly"
       (int64 * string)
# 6230 "lib/parser/q2_inferred.mli"
  )) (_startpos_ns_ : Lexing.position) (_endpos_ns_ : Lexing.position) (_startofs_ns_ : int) (_endofs_ns_ : int) (_loc_ns_ : Lexing.position * Lexing.position) ->
    (
# 587 "lib/parser/parser.mly"
    ( let (n, s) = ns in mk_expr (ELit (LInt (n, Some (prim_of_suffix s)))) _startpos )
# 6235 "lib/parser/q2_inferred.mli"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 584 "lib/parser/parser.mly"
    n
# 6240 "lib/parser/q2_inferred.mli"
   : (
# 15 "lib/parser/parser.mly"
       (int64)
# 6244 "lib/parser/q2_inferred.mli"
  )) (_startpos_n_ : Lexing.position) (_endpos_n_ : Lexing.position) (_startofs_n_ : int) (_endofs_n_ : int) (_loc_n_ : Lexing.position * Lexing.position) ->
    (
# 585 "lib/parser/parser.mly"
    ( mk_expr (ELit (LInt (n, None))) _startpos )
# 6249 "lib/parser/q2_inferred.mli"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 777 "lib/parser/parser.mly"
                                                      _6
# 6254 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) (
# 777 "lib/parser/parser.mly"
                                  ctx
# 6258 "lib/parser/q2_inferred.mli"
   : 'tv_option_STRING_) (_startpos_ctx_ : Lexing.position) (_endpos_ctx_ : Lexing.position) (_startofs_ctx_ : int) (_endofs_ctx_ : int) (_loc_ctx_ : Lexing.position * Lexing.position) (
# 777 "lib/parser/parser.mly"
                          _4
# 6262 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 777 "lib/parser/parser.mly"
                  p
# 6266 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 6270 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 777 "lib/parser/parser.mly"
          _2
# 6274 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 777 "lib/parser/parser.mly"
   _1
# 6278 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 778 "lib/parser/parser.mly"
    (
      {
        as_pred    = p;
        as_context = ctx;
        as_loc     = mk_loc _startpos;
      }
    )
# 6289 "lib/parser/q2_inferred.mli"
     : 'tv_assume_in_proof) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 825 "lib/parser/parser.mly"
                                  ctx
# 6294 "lib/parser/q2_inferred.mli"
   : 'tv_option_STRING_) (_startpos_ctx_ : Lexing.position) (_endpos_ctx_ : Lexing.position) (_startofs_ctx_ : int) (_endofs_ctx_ : int) (_loc_ctx_ : Lexing.position * Lexing.position) (
# 825 "lib/parser/parser.mly"
                          _4
# 6298 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 825 "lib/parser/parser.mly"
                  p
# 6302 "lib/parser/q2_inferred.mli"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 6306 "lib/parser/q2_inferred.mli"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 825 "lib/parser/parser.mly"
          _2
# 6310 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 825 "lib/parser/parser.mly"
   _1
# 6314 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 826 "lib/parser/parser.mly"
    ( mk_expr (EAssume (p, ctx)) _startpos )
# 6319 "lib/parser/q2_inferred.mli"
     : 'tv_assume_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 693 "lib/parser/parser.mly"
    e
# 6324 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 6328 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 693 "lib/parser/parser.mly"
                   ( e )
# 6333 "lib/parser/q2_inferred.mli"
     : 'tv_arm_body) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 692 "lib/parser/parser.mly"
            _2
# 6338 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 692 "lib/parser/parser.mly"
    e
# 6342 "lib/parser/q2_inferred.mli"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 6346 "lib/parser/q2_inferred.mli"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 692 "lib/parser/parser.mly"
                   ( e )
# 6351 "lib/parser/q2_inferred.mli"
     : 'tv_arm_body) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 691 "lib/parser/parser.mly"
                  _2
# 6356 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 691 "lib/parser/parser.mly"
    e
# 6360 "lib/parser/q2_inferred.mli"
   : 'tv_block_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 691 "lib/parser/parser.mly"
                         ( e )
# 6365 "lib/parser/q2_inferred.mli"
     : 'tv_arm_body) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 688 "lib/parser/parser.mly"
                          p2
# 6370 "lib/parser/q2_inferred.mli"
   : 'tv_pattern) (_startpos_p2_ : Lexing.position) (_endpos_p2_ : Lexing.position) (_startofs_p2_ : int) (_endofs_p2_ : int) (_loc_p2_ : Lexing.position * Lexing.position) (
# 688 "lib/parser/parser.mly"
                    _2
# 6374 "lib/parser/q2_inferred.mli"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 688 "lib/parser/parser.mly"
    p1
# 6378 "lib/parser/q2_inferred.mli"
   : 'tv_alt_pattern) (_startpos_p1_ : Lexing.position) (_endpos_p1_ : Lexing.position) (_startofs_p1_ : int) (_endofs_p1_ : int) (_loc_p1_ : Lexing.position * Lexing.position) ->
    (
# 688 "lib/parser/parser.mly"
                                            ( POr (p1, p2) )
# 6383 "lib/parser/q2_inferred.mli"
     : 'tv_alt_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 687 "lib/parser/parser.mly"
    p
# 6388 "lib/parser/q2_inferred.mli"
   : 'tv_pattern) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) ->
    (
# 687 "lib/parser/parser.mly"
                                             ( p )
# 6393 "lib/parser/q2_inferred.mli"
     : 'tv_alt_pattern) in
  (raise Not_found : 'tv_type_params * 'tv_type_def * 'tv_type_args * 'tv_ty * 'tv_tlist_ty_ * 'tv_tlist_struct_field_init_ * 'tv_tlist_param_ * 'tv_tlist_expr_ * 'tv_struct_field_init * 'tv_struct_field * 'tv_struct_def * 'tv_stmt * 'tv_separated_nonempty_list_DCOLON_ident_ * 'tv_separated_nonempty_list_COMMA_ty_ * 'tv_separated_nonempty_list_COMMA_proof_term_ * 'tv_separated_nonempty_list_COMMA_pred_ * 'tv_separated_nonempty_list_COMMA_pattern_ * 'tv_separated_nonempty_list_COMMA_kind_param_ * 'tv_separated_nonempty_list_COMMA_ident_ * 'tv_separated_nonempty_list_COMMA_expr_ * 'tv_separated_nonempty_list_COMMA_IDENT_ * 'tv_separated_list_COMMA_proof_term_ * 'tv_separated_list_COMMA_pred_ * 'tv_separated_list_COMMA_pattern_ * 'tv_separated_list_COMMA_expr_ * 'tv_separated_list_COMMA_IDENT_ * 'tv_return_expr * 'tv_requires_clause * 'tv_raw_expr * 'tv_proof_term * 'tv_proof_expr * 'tv_proof_contents * 'tv_program * 'tv_prim_ty_kw * 'tv_pred * 'tv_preceded_INVARIANT_pred_ * 'tv_preceded_IF_pred_ * 'tv_preceded_ELSE_else_branch_ * 'tv_preceded_DECREASES_pred_ * 'tv_preceded_COLON_ty_ * 'tv_preceded_ARROW_ty_ * 'tv_pattern * 'tv_param * 'tv_option_preceded_IF_pred__ * 'tv_option_preceded_ELSE_else_branch__ * 'tv_option_preceded_DECREASES_pred__ * 'tv_option_preceded_COLON_ty__ * 'tv_option_preceded_ARROW_ty__ * 'tv_option_extern_link_ * 'tv_option_expr_ * 'tv_option_decreases_clause_ * 'tv_option_STRING_ * 'tv_match_expr * 'tv_match_arm * 'tv_loption_separated_nonempty_list_COMMA_proof_term__ * 'tv_loption_separated_nonempty_list_COMMA_pred__ * 'tv_loption_separated_nonempty_list_COMMA_pattern__ * 'tv_loption_separated_nonempty_list_COMMA_expr__ * 'tv_loption_separated_nonempty_list_COMMA_IDENT__ * 'tv_loop_expr * 'tv_list_struct_field_ * 'tv_list_stmt_ * 'tv_list_requires_clause_ * 'tv_list_proof_term_ * 'tv_list_preceded_INVARIANT_pred__ * 'tv_list_match_arm_ * 'tv_list_lemma_def_ * 'tv_list_item_ * 'tv_list_invariant_clause_ * 'tv_list_enum_variant_ * 'tv_list_ensures_clause_ * 'tv_list_attr_clause_ * 'tv_list_assume_in_proof_ * 'tv_linearity * 'tv_lemma_def * 'tv_kind_params * 'tv_kind_param * 'tv_item * 'tv_invariant_clause * 'tv_impl_def * 'tv_if_expr * 'tv_ident * 'tv_fn_def * 'tv_fn_body * 'tv_extern_link * 'tv_extern_def * 'tv_expr * 'tv_enum_variant * 'tv_enum_def * 'tv_ensures_clause * 'tv_else_branch * 'tv_decreases_clause * 'tv_block_stmts * 'tv_block_expr * 'tv_attr_clause * 'tv_atom_expr * 'tv_assume_in_proof * 'tv_assume_expr * 'tv_arm_body * 'tv_alt_pattern)

and menhir_end_marker =
  0

# 269 "<standard.mly>"
  

# 6403 "lib/parser/q2_inferred.mli"
