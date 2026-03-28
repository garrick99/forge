
type token = 
  | WITNESS
  | WHILE
  | VARYING
  | USIZE
  | USE
  | UNIFORM
  | UNDERSCORE
  | U8
  | U64
  | U32
  | U16
  | U128
  | TYPE
  | TRUE
  | TRANS
  | TILDE
  | TASK
  | SYNCTHREADS
  | SYMM
  | STRUCT
  | STRING of (
# 18 "lib/parser/parser.mly"
       (string)
# 27 "q1.ml"
)
  | STAREQ
  | STAR
  | SPAN
  | SLASHEQ
  | SLASH
  | SHR
  | SHL
  | SHARED
  | SEMI
  | RPAREN
  | RETURN
  | RESULT
  | REQUIRES
  | REFMUT
  | REF
  | RBRACKET
  | RBRACE
  | RAW_TY
  | RAW
  | PROOF
  | PLUSEQ
  | PLUS
  | PIPE
  | PERCENT
  | OWN
  | OR_RETURN
  | OR_FAIL
  | OLD
  | NEVER
  | NEQ
  | MUT
  | MINUSEQ
  | MINUS
  | MATCH
  | LT
  | LPAREN
  | LOR
  | LOOP
  | LIN
  | LET
  | LEMMA
  | LE
  | LBRACKET
  | LBRACE
  | LAND
  | KERNEL
  | ISIZE
  | INVARIANT
  | INT_SUFF of (
# 16 "lib/parser/parser.mly"
       (int64 * string)
# 80 "q1.ml"
)
  | INT of (
# 15 "lib/parser/parser.mly"
       (int64)
# 85 "q1.ml"
)
  | INDUCTION
  | IN
  | IMPLIES
  | IMPL
  | IFF
  | IF
  | IDENT of (
# 19 "lib/parser/parser.mly"
       (string)
# 96 "q1.ml"
)
  | I8
  | I64
  | I32
  | I16
  | I128
  | HASH
  | GT
  | GE
  | FORALL
  | FOR
  | FN
  | FLOAT of (
# 17 "lib/parser/parser.mly"
       (float)
# 112 "q1.ml"
)
  | FATARROW
  | FALSE
  | F64
  | F32
  | EXTERN
  | EXISTS
  | EQEQ
  | EQ
  | EOF
  | ENUM
  | ENSURES
  | ELSE
  | DOTDOT
  | DOT
  | DECREASES
  | DCOLON
  | CONTINUE
  | COMMA
  | COLON
  | COALESCED
  | CHAN
  | CARET
  | BY
  | BREAK
  | BOOL_TY
  | BANG
  | AXIOM
  | AUTO
  | AT
  | ASSUME
  | AS
  | ARROW
  | AMP
  | AFF

# 1 "lib/parser/parser.mly"
  
(* FORGE Parser — Menhir LR(1) grammar
   Full grammar: types, expressions, statements, proof blocks, contracts *)

open Ast
open Parse_util
open Lexing

# 158 "q1.ml"

let menhir_begin_marker =
  0

and (xv_type_params, xv_type_def, xv_type_args, xv_ty, xv_tlist_ty_, xv_tlist_struct_field_init_, xv_tlist_param_, xv_tlist_expr_, xv_struct_field_init, xv_struct_field, xv_struct_def, xv_stmt, xv_separated_nonempty_list_DCOLON_ident_, xv_separated_nonempty_list_COMMA_ty_, xv_separated_nonempty_list_COMMA_proof_term_, xv_separated_nonempty_list_COMMA_pred_, xv_separated_nonempty_list_COMMA_pattern_, xv_separated_nonempty_list_COMMA_kind_param_, xv_separated_nonempty_list_COMMA_ident_, xv_separated_nonempty_list_COMMA_expr_, xv_separated_nonempty_list_COMMA_IDENT_, xv_separated_list_COMMA_proof_term_, xv_separated_list_COMMA_pred_, xv_separated_list_COMMA_pattern_, xv_separated_list_COMMA_expr_, xv_separated_list_COMMA_IDENT_, xv_return_expr, xv_requires_clause, xv_raw_expr, xv_proof_term, xv_proof_expr, xv_proof_contents, xv_program, xv_prim_ty_kw, xv_pred, xv_preceded_INVARIANT_pred_, xv_preceded_IF_pred_, xv_preceded_ELSE_else_branch_, xv_preceded_DECREASES_pred_, xv_preceded_COLON_ty_, xv_preceded_ARROW_ty_, xv_pattern, xv_param, xv_option_preceded_INVARIANT_pred__, xv_option_preceded_IF_pred__, xv_option_preceded_ELSE_else_branch__, xv_option_preceded_DECREASES_pred__, xv_option_preceded_COLON_ty__, xv_option_preceded_ARROW_ty__, xv_option_extern_link_, xv_option_expr_, xv_option_decreases_clause_, xv_option_STRING_, xv_match_expr, xv_match_arm, xv_loption_separated_nonempty_list_COMMA_proof_term__, xv_loption_separated_nonempty_list_COMMA_pred__, xv_loption_separated_nonempty_list_COMMA_pattern__, xv_loption_separated_nonempty_list_COMMA_expr__, xv_loption_separated_nonempty_list_COMMA_IDENT__, xv_loop_expr, xv_list_struct_field_, xv_list_stmt_, xv_list_requires_clause_, xv_list_proof_term_, xv_list_match_arm_, xv_list_lemma_def_, xv_list_item_, xv_list_invariant_clause_, xv_list_enum_variant_, xv_list_ensures_clause_, xv_list_attr_clause_, xv_list_assume_in_proof_, xv_linearity, xv_lemma_def, xv_kind_params, xv_kind_param, xv_item, xv_invariant_clause, xv_impl_def, xv_if_expr, xv_ident, xv_fn_def, xv_fn_body, xv_extern_link, xv_extern_def, xv_expr, xv_enum_variant, xv_enum_def, xv_ensures_clause, xv_else_branch, xv_decreases_clause, xv_block_stmts, xv_block_expr, xv_attr_clause, xv_atom_expr, xv_assume_in_proof, xv_assume_expr, xv_arm_body, xv_alt_pattern) =
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 167 "q1.ml"
   : 'tv_separated_nonempty_list_DCOLON_ident_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 171 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
  x
# 175 "q1.ml"
   : 'tv_ident) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 180 "q1.ml"
     : 'tv_separated_nonempty_list_DCOLON_ident_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 240 "<standard.mly>"
  x
# 185 "q1.ml"
   : 'tv_ident) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 190 "q1.ml"
     : 'tv_separated_nonempty_list_DCOLON_ident_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 195 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_ty_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 199 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 242 "<standard.mly>"
  x
# 203 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 207 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 212 "q1.ml"
     : 'tv_separated_nonempty_list_COMMA_ty_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 240 "<standard.mly>"
  x
# 217 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 221 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 226 "q1.ml"
     : 'tv_separated_nonempty_list_COMMA_ty_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 231 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_proof_term_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 235 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
  x
# 239 "q1.ml"
   : 'tv_proof_term) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 244 "q1.ml"
     : 'tv_separated_nonempty_list_COMMA_proof_term_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 240 "<standard.mly>"
  x
# 249 "q1.ml"
   : 'tv_proof_term) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 254 "q1.ml"
     : 'tv_separated_nonempty_list_COMMA_proof_term_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 259 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_pred_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 263 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 242 "<standard.mly>"
  x
# 267 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 271 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 276 "q1.ml"
     : 'tv_separated_nonempty_list_COMMA_pred_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 240 "<standard.mly>"
  x
# 281 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 285 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 290 "q1.ml"
     : 'tv_separated_nonempty_list_COMMA_pred_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 295 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_pattern_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 299 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
  x
# 303 "q1.ml"
   : 'tv_pattern) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 308 "q1.ml"
     : 'tv_separated_nonempty_list_COMMA_pattern_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 240 "<standard.mly>"
  x
# 313 "q1.ml"
   : 'tv_pattern) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 318 "q1.ml"
     : 'tv_separated_nonempty_list_COMMA_pattern_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 323 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_kind_param_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 327 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
  x
# 331 "q1.ml"
   : 'tv_kind_param) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 336 "q1.ml"
     : 'tv_separated_nonempty_list_COMMA_kind_param_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 240 "<standard.mly>"
  x
# 341 "q1.ml"
   : 'tv_kind_param) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 346 "q1.ml"
     : 'tv_separated_nonempty_list_COMMA_kind_param_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 351 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_ident_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 355 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
  x
# 359 "q1.ml"
   : 'tv_ident) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 364 "q1.ml"
     : 'tv_separated_nonempty_list_COMMA_ident_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 240 "<standard.mly>"
  x
# 369 "q1.ml"
   : 'tv_ident) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 374 "q1.ml"
     : 'tv_separated_nonempty_list_COMMA_ident_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 379 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_expr_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 383 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 242 "<standard.mly>"
  x
# 387 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 391 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 396 "q1.ml"
     : 'tv_separated_nonempty_list_COMMA_expr_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 240 "<standard.mly>"
  x
# 401 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 405 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 410 "q1.ml"
     : 'tv_separated_nonempty_list_COMMA_expr_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
                    xs
# 415 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_IDENT_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
        _2
# 419 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 242 "<standard.mly>"
  x
# 423 "q1.ml"
   : (
# 19 "lib/parser/parser.mly"
       (string)
# 427 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 243 "<standard.mly>"
    ( x :: xs )
# 432 "q1.ml"
     : 'tv_separated_nonempty_list_COMMA_IDENT_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 240 "<standard.mly>"
  x
# 437 "q1.ml"
   : (
# 19 "lib/parser/parser.mly"
       (string)
# 441 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 241 "<standard.mly>"
    ( [ x ] )
# 446 "q1.ml"
     : 'tv_separated_nonempty_list_COMMA_IDENT_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 231 "<standard.mly>"
  xs
# 451 "q1.ml"
   : 'tv_loption_separated_nonempty_list_COMMA_proof_term__) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) ->
    (
# 232 "<standard.mly>"
    ( xs )
# 456 "q1.ml"
     : 'tv_separated_list_COMMA_proof_term_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 231 "<standard.mly>"
  xs
# 461 "q1.ml"
   : 'tv_loption_separated_nonempty_list_COMMA_pred__) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) ->
    (
# 232 "<standard.mly>"
    ( xs )
# 466 "q1.ml"
     : 'tv_separated_list_COMMA_pred_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 231 "<standard.mly>"
  xs
# 471 "q1.ml"
   : 'tv_loption_separated_nonempty_list_COMMA_pattern__) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) ->
    (
# 232 "<standard.mly>"
    ( xs )
# 476 "q1.ml"
     : 'tv_separated_list_COMMA_pattern_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 231 "<standard.mly>"
  xs
# 481 "q1.ml"
   : 'tv_loption_separated_nonempty_list_COMMA_expr__) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) ->
    (
# 232 "<standard.mly>"
    ( xs )
# 486 "q1.ml"
     : 'tv_separated_list_COMMA_expr_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 231 "<standard.mly>"
  xs
# 491 "q1.ml"
   : 'tv_loption_separated_nonempty_list_COMMA_IDENT__) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) ->
    (
# 232 "<standard.mly>"
    ( xs )
# 496 "q1.ml"
     : 'tv_separated_list_COMMA_IDENT_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 182 "<standard.mly>"
           x
# 501 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 505 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) (
# 181 "<standard.mly>"
                                     _1
# 510 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 183 "<standard.mly>"
    ( x )
# 515 "q1.ml"
     : 'tv_preceded_INVARIANT_pred_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 182 "<standard.mly>"
           x
# 520 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 524 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) (
# 181 "<standard.mly>"
                                     _1
# 529 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 183 "<standard.mly>"
    ( x )
# 534 "q1.ml"
     : 'tv_preceded_IF_pred_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 182 "<standard.mly>"
           x
# 539 "q1.ml"
   : 'tv_else_branch) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) (
# 181 "<standard.mly>"
                                     _1
# 544 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 183 "<standard.mly>"
    ( x )
# 549 "q1.ml"
     : 'tv_preceded_ELSE_else_branch_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 182 "<standard.mly>"
           x
# 554 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 558 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) (
# 181 "<standard.mly>"
                                     _1
# 563 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 183 "<standard.mly>"
    ( x )
# 568 "q1.ml"
     : 'tv_preceded_DECREASES_pred_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 182 "<standard.mly>"
           x
# 573 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 577 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) (
# 181 "<standard.mly>"
                                     _1
# 582 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 183 "<standard.mly>"
    ( x )
# 587 "q1.ml"
     : 'tv_preceded_COLON_ty_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 182 "<standard.mly>"
           x
# 592 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 596 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) (
# 181 "<standard.mly>"
                                     _1
# 601 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 183 "<standard.mly>"
    ( x )
# 606 "q1.ml"
     : 'tv_preceded_ARROW_ty_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 611 "q1.ml"
   : 'tv_preceded_INVARIANT_pred_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 616 "q1.ml"
     : 'tv_option_preceded_INVARIANT_pred__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 622 "q1.ml"
     : 'tv_option_preceded_INVARIANT_pred__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 627 "q1.ml"
   : 'tv_preceded_IF_pred_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 632 "q1.ml"
     : 'tv_option_preceded_IF_pred__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 638 "q1.ml"
     : 'tv_option_preceded_IF_pred__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 643 "q1.ml"
   : 'tv_preceded_ELSE_else_branch_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 648 "q1.ml"
     : 'tv_option_preceded_ELSE_else_branch__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 654 "q1.ml"
     : 'tv_option_preceded_ELSE_else_branch__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 659 "q1.ml"
   : 'tv_preceded_DECREASES_pred_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 664 "q1.ml"
     : 'tv_option_preceded_DECREASES_pred__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 670 "q1.ml"
     : 'tv_option_preceded_DECREASES_pred__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 675 "q1.ml"
   : 'tv_preceded_COLON_ty_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 680 "q1.ml"
     : 'tv_option_preceded_COLON_ty__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 686 "q1.ml"
     : 'tv_option_preceded_COLON_ty__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 691 "q1.ml"
   : 'tv_preceded_ARROW_ty_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 696 "q1.ml"
     : 'tv_option_preceded_ARROW_ty__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 702 "q1.ml"
     : 'tv_option_preceded_ARROW_ty__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 707 "q1.ml"
   : 'tv_extern_link) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 712 "q1.ml"
     : 'tv_option_extern_link_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 718 "q1.ml"
     : 'tv_option_extern_link_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 115 "<standard.mly>"
  x
# 723 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 727 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 732 "q1.ml"
     : 'tv_option_expr_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 738 "q1.ml"
     : 'tv_option_expr_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 743 "q1.ml"
   : 'tv_decreases_clause) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 748 "q1.ml"
     : 'tv_option_decreases_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 754 "q1.ml"
     : 'tv_option_decreases_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 115 "<standard.mly>"
  x
# 759 "q1.ml"
   : (
# 18 "lib/parser/parser.mly"
       (string)
# 763 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 116 "<standard.mly>"
    ( Some x )
# 768 "q1.ml"
     : 'tv_option_STRING_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 114 "<standard.mly>"
    ( None )
# 774 "q1.ml"
     : 'tv_option_STRING_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 143 "<standard.mly>"
  x
# 779 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_proof_term_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 144 "<standard.mly>"
    ( x )
# 784 "q1.ml"
     : 'tv_loption_separated_nonempty_list_COMMA_proof_term__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 142 "<standard.mly>"
    ( [] )
# 790 "q1.ml"
     : 'tv_loption_separated_nonempty_list_COMMA_proof_term__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 143 "<standard.mly>"
  x
# 795 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_pred_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 144 "<standard.mly>"
    ( x )
# 800 "q1.ml"
     : 'tv_loption_separated_nonempty_list_COMMA_pred__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 142 "<standard.mly>"
    ( [] )
# 806 "q1.ml"
     : 'tv_loption_separated_nonempty_list_COMMA_pred__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 143 "<standard.mly>"
  x
# 811 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_pattern_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 144 "<standard.mly>"
    ( x )
# 816 "q1.ml"
     : 'tv_loption_separated_nonempty_list_COMMA_pattern__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 142 "<standard.mly>"
    ( [] )
# 822 "q1.ml"
     : 'tv_loption_separated_nonempty_list_COMMA_pattern__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 143 "<standard.mly>"
  x
# 827 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_expr_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 144 "<standard.mly>"
    ( x )
# 832 "q1.ml"
     : 'tv_loption_separated_nonempty_list_COMMA_expr__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 142 "<standard.mly>"
    ( [] )
# 838 "q1.ml"
     : 'tv_loption_separated_nonempty_list_COMMA_expr__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 143 "<standard.mly>"
  x
# 843 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_IDENT_) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 144 "<standard.mly>"
    ( x )
# 848 "q1.ml"
     : 'tv_loption_separated_nonempty_list_COMMA_IDENT__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 142 "<standard.mly>"
    ( [] )
# 854 "q1.ml"
     : 'tv_loption_separated_nonempty_list_COMMA_IDENT__) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 859 "q1.ml"
   : 'tv_list_struct_field_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 863 "q1.ml"
   : 'tv_struct_field) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 868 "q1.ml"
     : 'tv_list_struct_field_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 874 "q1.ml"
     : 'tv_list_struct_field_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 879 "q1.ml"
   : 'tv_list_stmt_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 883 "q1.ml"
   : 'tv_stmt) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 888 "q1.ml"
     : 'tv_list_stmt_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 894 "q1.ml"
     : 'tv_list_stmt_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 899 "q1.ml"
   : 'tv_list_requires_clause_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 903 "q1.ml"
   : 'tv_requires_clause) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 908 "q1.ml"
     : 'tv_list_requires_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 914 "q1.ml"
     : 'tv_list_requires_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 919 "q1.ml"
   : 'tv_list_proof_term_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 923 "q1.ml"
   : 'tv_proof_term) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 928 "q1.ml"
     : 'tv_list_proof_term_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 934 "q1.ml"
     : 'tv_list_proof_term_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 939 "q1.ml"
   : 'tv_list_match_arm_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 943 "q1.ml"
   : 'tv_match_arm) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 948 "q1.ml"
     : 'tv_list_match_arm_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 954 "q1.ml"
     : 'tv_list_match_arm_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 959 "q1.ml"
   : 'tv_list_lemma_def_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 963 "q1.ml"
   : 'tv_lemma_def) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 968 "q1.ml"
     : 'tv_list_lemma_def_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 974 "q1.ml"
     : 'tv_list_lemma_def_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 979 "q1.ml"
   : 'tv_list_item_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) ((
# 212 "<standard.mly>"
  x
# 983 "q1.ml"
   : 'tv_item) : (
# 115 "lib/parser/parser.mly"
       (Ast.item)
# 987 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 992 "q1.ml"
     : 'tv_list_item_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 998 "q1.ml"
     : 'tv_list_item_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 1003 "q1.ml"
   : 'tv_list_invariant_clause_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 1007 "q1.ml"
   : 'tv_invariant_clause) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 1012 "q1.ml"
     : 'tv_list_invariant_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 1018 "q1.ml"
     : 'tv_list_invariant_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 1023 "q1.ml"
   : 'tv_list_enum_variant_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 1027 "q1.ml"
   : 'tv_enum_variant) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 1032 "q1.ml"
     : 'tv_list_enum_variant_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 1038 "q1.ml"
     : 'tv_list_enum_variant_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 1043 "q1.ml"
   : 'tv_list_ensures_clause_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 1047 "q1.ml"
   : 'tv_ensures_clause) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 1052 "q1.ml"
     : 'tv_list_ensures_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 1058 "q1.ml"
     : 'tv_list_ensures_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 1063 "q1.ml"
   : 'tv_list_attr_clause_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 1067 "q1.ml"
   : 'tv_attr_clause) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 1072 "q1.ml"
     : 'tv_list_attr_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 1078 "q1.ml"
     : 'tv_list_attr_clause_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
         xs
# 1083 "q1.ml"
   : 'tv_list_assume_in_proof_) (_startpos_xs_ : Lexing.position) (_endpos_xs_ : Lexing.position) (_startofs_xs_ : int) (_endofs_xs_ : int) (_loc_xs_ : Lexing.position * Lexing.position) (
# 212 "<standard.mly>"
  x
# 1087 "q1.ml"
   : 'tv_assume_in_proof) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 213 "<standard.mly>"
    ( x :: xs )
# 1092 "q1.ml"
     : 'tv_list_assume_in_proof_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 211 "<standard.mly>"
    ( [] )
# 1098 "q1.ml"
     : 'tv_list_assume_in_proof_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 227 "lib/parser/parser.mly"
                                                 _3
# 1103 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 227 "lib/parser/parser.mly"
       ps
# 1107 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_ident_) (_startpos_ps_ : Lexing.position) (_endpos_ps_ : Lexing.position) (_startofs_ps_ : int) (_endofs_ps_ : int) (_loc_ps_ : Lexing.position * Lexing.position) (
# 227 "lib/parser/parser.mly"
   _1
# 1111 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 227 "lib/parser/parser.mly"
                                                     ( ps )
# 1116 "q1.ml"
     : 'tv_type_params) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 226 "lib/parser/parser.mly"
    ( [] )
# 1122 "q1.ml"
     : 'tv_type_params) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 216 "lib/parser/parser.mly"
                                                    _6
# 1127 "q1.ml"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) ((
# 216 "lib/parser/parser.mly"
                                              t
# 1131 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1135 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 216 "lib/parser/parser.mly"
                                          _4
# 1139 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 216 "lib/parser/parser.mly"
                      params
# 1143 "q1.ml"
   : 'tv_type_params) (_startpos_params_ : Lexing.position) (_endpos_params_ : Lexing.position) (_startofs_params_ : int) (_endofs_params_ : int) (_loc_params_ : Lexing.position * Lexing.position) (
# 216 "lib/parser/parser.mly"
         name
# 1147 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 216 "lib/parser/parser.mly"
   _1
# 1151 "q1.ml"
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
# 1162 "q1.ml"
     : 'tv_type_def) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 393 "lib/parser/parser.mly"
                                                _3
# 1167 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 393 "lib/parser/parser.mly"
       args
# 1171 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_ty_) (_startpos_args_ : Lexing.position) (_endpos_args_ : Lexing.position) (_startofs_args_ : int) (_endofs_args_ : int) (_loc_args_ : Lexing.position * Lexing.position) (
# 393 "lib/parser/parser.mly"
   _1
# 1175 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 393 "lib/parser/parser.mly"
                                                    ( args )
# 1180 "q1.ml"
     : 'tv_type_args) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 392 "lib/parser/parser.mly"
    ( [] )
# 1186 "q1.ml"
     : 'tv_type_args) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 388 "lib/parser/parser.mly"
                 _3
# 1191 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 388 "lib/parser/parser.mly"
           t
# 1195 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1199 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 388 "lib/parser/parser.mly"
   _1
# 1203 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 389 "lib/parser/parser.mly"
    ( t )
# 1208 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1212 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 380 "lib/parser/parser.mly"
                 args
# 1217 "q1.ml"
   : 'tv_type_args) (_startpos_args_ : Lexing.position) (_endpos_args_ : Lexing.position) (_startofs_args_ : int) (_endofs_args_ : int) (_loc_args_ : Lexing.position * Lexing.position) (
# 380 "lib/parser/parser.mly"
    name
# 1221 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    ((
# 381 "lib/parser/parser.mly"
    (
      match args with
      | [] -> TNamed (name, [])
      | _  -> TNamed (name, args)
    )
# 1230 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1234 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 376 "lib/parser/parser.mly"
            t
# 1239 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1243 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 376 "lib/parser/parser.mly"
   _1
# 1247 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 377 "lib/parser/parser.mly"
    ( TQual (Varying, t) )
# 1252 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1256 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 374 "lib/parser/parser.mly"
            t
# 1261 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1265 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 374 "lib/parser/parser.mly"
   _1
# 1269 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 375 "lib/parser/parser.mly"
    ( TQual (Uniform, t) )
# 1274 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1278 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 370 "lib/parser/parser.mly"
                    _4
# 1283 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 370 "lib/parser/parser.mly"
              t
# 1287 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1291 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 370 "lib/parser/parser.mly"
          _2
# 1295 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 370 "lib/parser/parser.mly"
   _1
# 1299 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 371 "lib/parser/parser.mly"
    ( TShared (t, None) )
# 1304 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1308 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 368 "lib/parser/parser.mly"
                                         _7
# 1313 "q1.ml"
   : unit) (_startpos__7_ : Lexing.position) (_endpos__7_ : Lexing.position) (_startofs__7_ : int) (_endofs__7_ : int) (_loc__7_ : Lexing.position * Lexing.position) ((
# 368 "lib/parser/parser.mly"
                                 n
# 1317 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 1321 "q1.ml"
  )) (_startpos_n_ : Lexing.position) (_endpos_n_ : Lexing.position) (_startofs_n_ : int) (_endofs_n_ : int) (_loc_n_ : Lexing.position * Lexing.position) (
# 368 "lib/parser/parser.mly"
                       _5
# 1325 "q1.ml"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 368 "lib/parser/parser.mly"
                    _4
# 1329 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 368 "lib/parser/parser.mly"
              t
# 1333 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1337 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 368 "lib/parser/parser.mly"
          _2
# 1341 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 368 "lib/parser/parser.mly"
   _1
# 1345 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 369 "lib/parser/parser.mly"
    ( TShared (t, Some n) )
# 1350 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1354 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 364 "lib/parser/parser.mly"
                  _4
# 1359 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 364 "lib/parser/parser.mly"
            t
# 1363 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1367 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 364 "lib/parser/parser.mly"
        _2
# 1371 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 364 "lib/parser/parser.mly"
   _1
# 1375 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 365 "lib/parser/parser.mly"
    ( TSpan t )
# 1380 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1384 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 360 "lib/parser/parser.mly"
   _1
# 1389 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 361 "lib/parser/parser.mly"
    ( TPrim TNever )
# 1394 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1398 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 358 "lib/parser/parser.mly"
          _2
# 1403 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 358 "lib/parser/parser.mly"
   _1
# 1407 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 359 "lib/parser/parser.mly"
    ( TPrim TUnit )
# 1412 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1416 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 354 "lib/parser/parser.mly"
                                 _5
# 1421 "q1.ml"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) ((
# 354 "lib/parser/parser.mly"
                         n
# 1425 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 1429 "q1.ml"
  )) (_startpos_n_ : Lexing.position) (_endpos_n_ : Lexing.position) (_startofs_n_ : int) (_endofs_n_ : int) (_loc_n_ : Lexing.position * Lexing.position) (
# 354 "lib/parser/parser.mly"
                   _3
# 1433 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 354 "lib/parser/parser.mly"
             t
# 1437 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1441 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 354 "lib/parser/parser.mly"
   _1
# 1445 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 355 "lib/parser/parser.mly"
    ( TArray (t, Some n) )
# 1450 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1454 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 352 "lib/parser/parser.mly"
                   _3
# 1459 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 352 "lib/parser/parser.mly"
             t
# 1463 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1467 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 352 "lib/parser/parser.mly"
   _1
# 1471 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 353 "lib/parser/parser.mly"
    ( TSlice t )
# 1476 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1480 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 348 "lib/parser/parser.mly"
                 _4
# 1485 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 348 "lib/parser/parser.mly"
           t
# 1489 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1493 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 348 "lib/parser/parser.mly"
       _2
# 1497 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 348 "lib/parser/parser.mly"
   _1
# 1501 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 349 "lib/parser/parser.mly"
    ( TRaw t )
# 1506 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1510 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 346 "lib/parser/parser.mly"
                 _4
# 1515 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 346 "lib/parser/parser.mly"
           t
# 1519 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1523 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 346 "lib/parser/parser.mly"
       _2
# 1527 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 346 "lib/parser/parser.mly"
   _1
# 1531 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 347 "lib/parser/parser.mly"
    ( TOwn t )
# 1536 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1540 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 344 "lib/parser/parser.mly"
                    _4
# 1545 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 344 "lib/parser/parser.mly"
              t
# 1549 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1553 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 344 "lib/parser/parser.mly"
          _2
# 1557 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 344 "lib/parser/parser.mly"
   _1
# 1561 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 345 "lib/parser/parser.mly"
    ( TRefMut t )
# 1566 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1570 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 342 "lib/parser/parser.mly"
                 _4
# 1575 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 342 "lib/parser/parser.mly"
           t
# 1579 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1583 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 342 "lib/parser/parser.mly"
       _2
# 1587 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 342 "lib/parser/parser.mly"
   _1
# 1591 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 343 "lib/parser/parser.mly"
    ( TRef t )
# 1596 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1600 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 338 "lib/parser/parser.mly"
                                                        _6
# 1605 "q1.ml"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) ((
# 338 "lib/parser/parser.mly"
                                                p
# 1609 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 1613 "q1.ml"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 338 "lib/parser/parser.mly"
                                          _4
# 1617 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 338 "lib/parser/parser.mly"
                            binder
# 1621 "q1.ml"
   : 'tv_ident) (_startpos_binder_ : Lexing.position) (_endpos_binder_ : Lexing.position) (_startofs_binder_ : int) (_endofs_binder_ : int) (_loc_binder_ : Lexing.position * Lexing.position) (
# 338 "lib/parser/parser.mly"
                  _2
# 1625 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 338 "lib/parser/parser.mly"
    b
# 1629 "q1.ml"
   : 'tv_prim_ty_kw) (_startpos_b_ : Lexing.position) (_endpos_b_ : Lexing.position) (_startofs_b_ : int) (_endofs_b_ : int) (_loc_b_ : Lexing.position * Lexing.position) ->
    ((
# 339 "lib/parser/parser.mly"
    ( TRefined (b, binder, p) )
# 1634 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1638 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 336 "lib/parser/parser.mly"
    b
# 1643 "q1.ml"
   : 'tv_prim_ty_kw) (_startpos_b_ : Lexing.position) (_endpos_b_ : Lexing.position) (_startofs_b_ : int) (_endofs_b_ : int) (_loc_b_ : Lexing.position * Lexing.position) ->
    ((
# 337 "lib/parser/parser.mly"
    ( TPrim b )
# 1648 "q1.ml"
     : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1652 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
                rest
# 1657 "q1.ml"
   : 'tv_tlist_ty_) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
         _2
# 1661 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 130 "lib/parser/parser.mly"
    x
# 1665 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1669 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 130 "lib/parser/parser.mly"
                                ( x :: rest )
# 1674 "q1.ml"
     : 'tv_tlist_ty_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 129 "lib/parser/parser.mly"
    x
# 1679 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1683 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 129 "lib/parser/parser.mly"
          ( [x] )
# 1688 "q1.ml"
     : 'tv_tlist_ty_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 128 "lib/parser/parser.mly"
    ( [] )
# 1694 "q1.ml"
     : 'tv_tlist_ty_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
                rest
# 1699 "q1.ml"
   : 'tv_tlist_struct_field_init_) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
         _2
# 1703 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
    x
# 1707 "q1.ml"
   : 'tv_struct_field_init) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 130 "lib/parser/parser.mly"
                                ( x :: rest )
# 1712 "q1.ml"
     : 'tv_tlist_struct_field_init_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 129 "lib/parser/parser.mly"
    x
# 1717 "q1.ml"
   : 'tv_struct_field_init) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 129 "lib/parser/parser.mly"
          ( [x] )
# 1722 "q1.ml"
     : 'tv_tlist_struct_field_init_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 128 "lib/parser/parser.mly"
    ( [] )
# 1728 "q1.ml"
     : 'tv_tlist_struct_field_init_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
                rest
# 1733 "q1.ml"
   : 'tv_tlist_param_) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
         _2
# 1737 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
    x
# 1741 "q1.ml"
   : 'tv_param) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 130 "lib/parser/parser.mly"
                                ( x :: rest )
# 1746 "q1.ml"
     : 'tv_tlist_param_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 129 "lib/parser/parser.mly"
    x
# 1751 "q1.ml"
   : 'tv_param) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 129 "lib/parser/parser.mly"
          ( [x] )
# 1756 "q1.ml"
     : 'tv_tlist_param_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 128 "lib/parser/parser.mly"
    ( [] )
# 1762 "q1.ml"
     : 'tv_tlist_param_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
                rest
# 1767 "q1.ml"
   : 'tv_tlist_expr_) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 130 "lib/parser/parser.mly"
         _2
# 1771 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 130 "lib/parser/parser.mly"
    x
# 1775 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 1779 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 130 "lib/parser/parser.mly"
                                ( x :: rest )
# 1784 "q1.ml"
     : 'tv_tlist_expr_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 129 "lib/parser/parser.mly"
    x
# 1789 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 1793 "q1.ml"
  )) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) ->
    (
# 129 "lib/parser/parser.mly"
          ( [x] )
# 1798 "q1.ml"
     : 'tv_tlist_expr_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 128 "lib/parser/parser.mly"
    ( [] )
# 1804 "q1.ml"
     : 'tv_tlist_expr_) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 572 "lib/parser/parser.mly"
                       e
# 1809 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 1813 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 572 "lib/parser/parser.mly"
                _2
# 1817 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 572 "lib/parser/parser.mly"
    name
# 1821 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 572 "lib/parser/parser.mly"
                                ( (name, e) )
# 1826 "q1.ml"
     : 'tv_struct_field_init) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 251 "lib/parser/parser.mly"
                       t
# 1831 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1835 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 251 "lib/parser/parser.mly"
                _2
# 1839 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 251 "lib/parser/parser.mly"
    name
# 1843 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 252 "lib/parser/parser.mly"
    ( (name, t) )
# 1848 "q1.ml"
     : 'tv_struct_field) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 249 "lib/parser/parser.mly"
                             _4
# 1853 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 249 "lib/parser/parser.mly"
                       t
# 1857 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 1861 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 249 "lib/parser/parser.mly"
                _2
# 1865 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 249 "lib/parser/parser.mly"
    name
# 1869 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 250 "lib/parser/parser.mly"
    ( (name, t) )
# 1874 "q1.ml"
     : 'tv_struct_field) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 237 "lib/parser/parser.mly"
                                     _7
# 1880 "q1.ml"
   : unit) (_startpos__7_ : Lexing.position) (_endpos__7_ : Lexing.position) (_startofs__7_ : int) (_endofs__7_ : int) (_loc__7_ : Lexing.position * Lexing.position) (
# 237 "lib/parser/parser.mly"
      invars
# 1884 "q1.ml"
   : 'tv_list_invariant_clause_) (_startpos_invars_ : Lexing.position) (_endpos_invars_ : Lexing.position) (_startofs_invars_ : int) (_endofs_invars_ : int) (_loc_invars_ : Lexing.position * Lexing.position) (
# 236 "lib/parser/parser.mly"
      fields
# 1888 "q1.ml"
   : 'tv_list_struct_field_) (_startpos_fields_ : Lexing.position) (_endpos_fields_ : Lexing.position) (_startofs_fields_ : int) (_endofs_fields_ : int) (_loc_fields_ : Lexing.position * Lexing.position) (
# 234 "lib/parser/parser.mly"
                                            _4
# 1893 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 234 "lib/parser/parser.mly"
                        params
# 1897 "q1.ml"
   : 'tv_kind_params) (_startpos_params_ : Lexing.position) (_endpos_params_ : Lexing.position) (_startofs_params_ : int) (_endofs_params_ : int) (_loc_params_ : Lexing.position * Lexing.position) (
# 234 "lib/parser/parser.mly"
           name
# 1901 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 234 "lib/parser/parser.mly"
   _1
# 1905 "q1.ml"
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
# 1917 "q1.ml"
     : 'tv_struct_def) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 810 "lib/parser/parser.mly"
            _2
# 1922 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 810 "lib/parser/parser.mly"
   _1
# 1926 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 811 "lib/parser/parser.mly"
    ( mk_stmt SContinue _startpos )
# 1931 "q1.ml"
     : 'tv_stmt) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 808 "lib/parser/parser.mly"
         _2
# 1936 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 808 "lib/parser/parser.mly"
   _1
# 1940 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 809 "lib/parser/parser.mly"
    ( mk_stmt SBreak _startpos )
# 1945 "q1.ml"
     : 'tv_stmt) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 806 "lib/parser/parser.mly"
            _2
# 1950 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 806 "lib/parser/parser.mly"
    e
# 1954 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 1958 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 807 "lib/parser/parser.mly"
    ( mk_stmt (SExpr e) _startpos )
# 1963 "q1.ml"
     : 'tv_stmt) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 804 "lib/parser/parser.mly"
               _6
# 1968 "q1.ml"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) ((
# 804 "lib/parser/parser.mly"
       e
# 1972 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 1976 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 803 "lib/parser/parser.mly"
                                                      _4
# 1981 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 803 "lib/parser/parser.mly"
                     ann
# 1985 "q1.ml"
   : 'tv_option_preceded_COLON_ty__) (_startpos_ann_ : Lexing.position) (_endpos_ann_ : Lexing.position) (_startofs_ann_ : int) (_endofs_ann_ : int) (_loc_ann_ : Lexing.position * Lexing.position) (
# 803 "lib/parser/parser.mly"
        name
# 1989 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 803 "lib/parser/parser.mly"
   _1
# 1993 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 805 "lib/parser/parser.mly"
    ( mk_stmt (SLet (name, ann, e, Unr)) _startpos )
# 1998 "q1.ml"
     : 'tv_stmt) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 801 "lib/parser/parser.mly"
               _7
# 2003 "q1.ml"
   : unit) (_startpos__7_ : Lexing.position) (_endpos__7_ : Lexing.position) (_startofs__7_ : int) (_endofs__7_ : int) (_loc__7_ : Lexing.position * Lexing.position) ((
# 801 "lib/parser/parser.mly"
       e
# 2007 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 2011 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 800 "lib/parser/parser.mly"
                                                                      _5
# 2016 "q1.ml"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 800 "lib/parser/parser.mly"
                                     ann
# 2020 "q1.ml"
   : 'tv_option_preceded_COLON_ty__) (_startpos_ann_ : Lexing.position) (_endpos_ann_ : Lexing.position) (_startofs_ann_ : int) (_endofs_ann_ : int) (_loc_ann_ : Lexing.position * Lexing.position) (
# 800 "lib/parser/parser.mly"
                        name
# 2024 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 800 "lib/parser/parser.mly"
        lin
# 2028 "q1.ml"
   : 'tv_linearity) (_startpos_lin_ : Lexing.position) (_endpos_lin_ : Lexing.position) (_startofs_lin_ : int) (_endofs_lin_ : int) (_loc_lin_ : Lexing.position * Lexing.position) (
# 800 "lib/parser/parser.mly"
   _1
# 2032 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 802 "lib/parser/parser.mly"
    ( mk_stmt (SLet (name, ann, e, lin)) _startpos )
# 2037 "q1.ml"
     : 'tv_stmt) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 705 "lib/parser/parser.mly"
           e
# 2042 "q1.ml"
   : 'tv_option_expr_) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 705 "lib/parser/parser.mly"
   _1
# 2046 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 706 "lib/parser/parser.mly"
    ( mk_expr (EBlock (
        [mk_stmt (SReturn e) _startpos],
        None)) _startpos )
# 2053 "q1.ml"
     : 'tv_return_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 199 "lib/parser/parser.mly"
             p
# 2058 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2062 "q1.ml"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 199 "lib/parser/parser.mly"
   _1
# 2066 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 199 "lib/parser/parser.mly"
                      ( p )
# 2071 "q1.ml"
     : 'tv_requires_clause) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 779 "lib/parser/parser.mly"
                                 _4
# 2076 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 779 "lib/parser/parser.mly"
               stmts
# 2080 "q1.ml"
   : 'tv_list_stmt_) (_startpos_stmts_ : Lexing.position) (_endpos_stmts_ : Lexing.position) (_startofs_stmts_ : int) (_endofs_stmts_ : int) (_loc_stmts_ : Lexing.position * Lexing.position) (
# 779 "lib/parser/parser.mly"
       _2
# 2084 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 779 "lib/parser/parser.mly"
   _1
# 2088 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 780 "lib/parser/parser.mly"
    (
      mk_expr (ERaw {
        rb_stmts = stmts;
        rb_loc   = mk_loc _startpos;
      }) _startpos
    )
# 2098 "q1.ml"
     : 'tv_raw_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 771 "lib/parser/parser.mly"
                                 _3
# 2103 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 771 "lib/parser/parser.mly"
           pts
# 2107 "q1.ml"
   : 'tv_list_proof_term_) (_startpos_pts_ : Lexing.position) (_endpos_pts_ : Lexing.position) (_startofs_pts_ : int) (_endofs_pts_ : int) (_loc_pts_ : Lexing.position * Lexing.position) (
# 771 "lib/parser/parser.mly"
   _1
# 2111 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 772 "lib/parser/parser.mly"
    ( PTCong pts )
# 2116 "q1.ml"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 769 "lib/parser/parser.mly"
                                                                   _5
# 2121 "q1.ml"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 769 "lib/parser/parser.mly"
                           args
# 2125 "q1.ml"
   : 'tv_separated_list_COMMA_proof_term_) (_startpos_args_ : Lexing.position) (_endpos_args_ : Lexing.position) (_startofs_args_ : int) (_endofs_args_ : int) (_loc_args_ : Lexing.position * Lexing.position) (
# 769 "lib/parser/parser.mly"
                   _3
# 2129 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 769 "lib/parser/parser.mly"
       name
# 2133 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 769 "lib/parser/parser.mly"
   _1
# 2137 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 770 "lib/parser/parser.mly"
    ( PTBy (name, args) )
# 2142 "q1.ml"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 767 "lib/parser/parser.mly"
                           _4
# 2147 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 767 "lib/parser/parser.mly"
                   e
# 2151 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 2155 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 767 "lib/parser/parser.mly"
           _2
# 2159 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 767 "lib/parser/parser.mly"
   _1
# 2163 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 768 "lib/parser/parser.mly"
    ( PTWitness e )
# 2168 "q1.ml"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 765 "lib/parser/parser.mly"
                                                                        _7
# 2173 "q1.ml"
   : unit) (_startpos__7_ : Lexing.position) (_endpos__7_ : Lexing.position) (_startofs__7_ : int) (_endofs__7_ : int) (_loc__7_ : Lexing.position * Lexing.position) (
# 765 "lib/parser/parser.mly"
                                                       step
# 2177 "q1.ml"
   : 'tv_proof_term) (_startpos_step_ : Lexing.position) (_endpos_step_ : Lexing.position) (_startofs_step_ : int) (_endofs_step_ : int) (_loc_step_ : Lexing.position * Lexing.position) (
# 765 "lib/parser/parser.mly"
                                                _5
# 2181 "q1.ml"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 765 "lib/parser/parser.mly"
                               base
# 2185 "q1.ml"
   : 'tv_proof_term) (_startpos_base_ : Lexing.position) (_endpos_base_ : Lexing.position) (_startofs_base_ : int) (_endofs_base_ : int) (_loc_base_ : Lexing.position * Lexing.position) (
# 765 "lib/parser/parser.mly"
                       _3
# 2189 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 765 "lib/parser/parser.mly"
              x
# 2193 "q1.ml"
   : 'tv_ident) (_startpos_x_ : Lexing.position) (_endpos_x_ : Lexing.position) (_startofs_x_ : int) (_endofs_x_ : int) (_loc_x_ : Lexing.position * Lexing.position) (
# 765 "lib/parser/parser.mly"
   _1
# 2197 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 766 "lib/parser/parser.mly"
    ( PTInduct (x, base, step) )
# 2202 "q1.ml"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 763 "lib/parser/parser.mly"
                                                                         _8
# 2207 "q1.ml"
   : unit) (_startpos__8_ : Lexing.position) (_endpos__8_ : Lexing.position) (_startofs__8_ : int) (_endofs__8_ : int) (_loc__8_ : Lexing.position * Lexing.position) (
# 763 "lib/parser/parser.mly"
                                                         pt2
# 2211 "q1.ml"
   : 'tv_proof_term) (_startpos_pt2_ : Lexing.position) (_endpos_pt2_ : Lexing.position) (_startofs_pt2_ : int) (_endofs_pt2_ : int) (_loc_pt2_ : Lexing.position * Lexing.position) (
# 763 "lib/parser/parser.mly"
                                                  _6
# 2215 "q1.ml"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) (
# 763 "lib/parser/parser.mly"
                                  pt1
# 2219 "q1.ml"
   : 'tv_proof_term) (_startpos_pt1_ : Lexing.position) (_endpos_pt1_ : Lexing.position) (_startofs_pt1_ : int) (_endofs_pt1_ : int) (_loc_pt1_ : Lexing.position * Lexing.position) (
# 763 "lib/parser/parser.mly"
                           _4
# 2223 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 763 "lib/parser/parser.mly"
                 mid
# 2227 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 2231 "q1.ml"
  )) (_startpos_mid_ : Lexing.position) (_endpos_mid_ : Lexing.position) (_startofs_mid_ : int) (_endofs_mid_ : int) (_loc_mid_ : Lexing.position * Lexing.position) (
# 763 "lib/parser/parser.mly"
         _2
# 2235 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 763 "lib/parser/parser.mly"
   _1
# 2239 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 764 "lib/parser/parser.mly"
    ( PTTrans (mid, pt1, pt2) )
# 2244 "q1.ml"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 761 "lib/parser/parser.mly"
                               _4
# 2249 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 761 "lib/parser/parser.mly"
                pt
# 2253 "q1.ml"
   : 'tv_proof_term) (_startpos_pt_ : Lexing.position) (_endpos_pt_ : Lexing.position) (_startofs_pt_ : int) (_endofs_pt_ : int) (_loc_pt_ : Lexing.position * Lexing.position) (
# 761 "lib/parser/parser.mly"
        _2
# 2257 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 761 "lib/parser/parser.mly"
   _1
# 2261 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 762 "lib/parser/parser.mly"
    ( PTSymm pt )
# 2266 "q1.ml"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 758 "lib/parser/parser.mly"
    id
# 2271 "q1.ml"
   : (
# 19 "lib/parser/parser.mly"
       (string)
# 2275 "q1.ml"
  )) (_startpos_id_ : Lexing.position) (_endpos_id_ : Lexing.position) (_startofs_id_ : int) (_endofs_id_ : int) (_loc_id_ : Lexing.position * Lexing.position) ->
    (
# 759 "lib/parser/parser.mly"
    ( (if id = "refl" then PTRefl
       else raise Error : proof_term) )
# 2281 "q1.ml"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 756 "lib/parser/parser.mly"
   _1
# 2286 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 757 "lib/parser/parser.mly"
    ( PTAxiom )
# 2291 "q1.ml"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 754 "lib/parser/parser.mly"
   _1
# 2296 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 755 "lib/parser/parser.mly"
    ( PTAuto )
# 2301 "q1.ml"
     : 'tv_proof_term) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 715 "lib/parser/parser.mly"
                                    _4
# 2306 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 715 "lib/parser/parser.mly"
                 pb
# 2310 "q1.ml"
   : 'tv_proof_contents) (_startpos_pb_ : Lexing.position) (_endpos_pb_ : Lexing.position) (_startofs_pb_ : int) (_endofs_pb_ : int) (_loc_pb_ : Lexing.position * Lexing.position) (
# 715 "lib/parser/parser.mly"
         _2
# 2314 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 715 "lib/parser/parser.mly"
   _1
# 2318 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 716 "lib/parser/parser.mly"
    ( mk_expr (EProof pb) _startpos )
# 2323 "q1.ml"
     : 'tv_proof_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 719 "lib/parser/parser.mly"
                             assumes
# 2328 "q1.ml"
   : 'tv_list_assume_in_proof_) (_startpos_assumes_ : Lexing.position) (_endpos_assumes_ : Lexing.position) (_startofs_assumes_ : int) (_endofs_assumes_ : int) (_loc_assumes_ : Lexing.position * Lexing.position) (
# 719 "lib/parser/parser.mly"
    lemmas
# 2332 "q1.ml"
   : 'tv_list_lemma_def_) (_startpos_lemmas_ : Lexing.position) (_endpos_lemmas_ : Lexing.position) (_startofs_lemmas_ : int) (_endofs_lemmas_ : int) (_loc_lemmas_ : Lexing.position * Lexing.position) ->
    (
# 720 "lib/parser/parser.mly"
    (
      {
        pb_lemmas  = lemmas;
        pb_assumes = assumes;
        pb_loc     = mk_loc _startpos;
      }
    )
# 2343 "q1.ml"
     : 'tv_proof_contents) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 137 "lib/parser/parser.mly"
                      _2
# 2348 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 137 "lib/parser/parser.mly"
    items
# 2352 "q1.ml"
   : 'tv_list_item_) (_startpos_items_ : Lexing.position) (_endpos_items_ : Lexing.position) (_startofs_items_ : int) (_endofs_items_ : int) (_loc_items_ : Lexing.position * Lexing.position) ->
    ((
# 138 "lib/parser/parser.mly"
    ( { prog_items = items; prog_file = _startpos.pos_fname } )
# 2357 "q1.ml"
     : 'tv_program) : (
# 114 "lib/parser/parser.mly"
       (Ast.program)
# 2361 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 403 "lib/parser/parser.mly"
   _1
# 2366 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 403 "lib/parser/parser.mly"
            ( TBool )
# 2371 "q1.ml"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 402 "lib/parser/parser.mly"
                          _1
# 2376 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 402 "lib/parser/parser.mly"
                                 ( TFloat F64 )
# 2381 "q1.ml"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 402 "lib/parser/parser.mly"
   _1
# 2386 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 402 "lib/parser/parser.mly"
          ( TFloat F32 )
# 2391 "q1.ml"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 401 "lib/parser/parser.mly"
                          _1
# 2396 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 401 "lib/parser/parser.mly"
                                 ( TInt ISize )
# 2401 "q1.ml"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 401 "lib/parser/parser.mly"
   _1
# 2406 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 401 "lib/parser/parser.mly"
          ( TInt I128 )
# 2411 "q1.ml"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 400 "lib/parser/parser.mly"
                          _1
# 2416 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 400 "lib/parser/parser.mly"
                                 ( TInt I64   )
# 2421 "q1.ml"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 400 "lib/parser/parser.mly"
   _1
# 2426 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 400 "lib/parser/parser.mly"
          ( TInt I32  )
# 2431 "q1.ml"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 399 "lib/parser/parser.mly"
                          _1
# 2436 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 399 "lib/parser/parser.mly"
                                 ( TInt I16   )
# 2441 "q1.ml"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 399 "lib/parser/parser.mly"
   _1
# 2446 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 399 "lib/parser/parser.mly"
          ( TInt I8   )
# 2451 "q1.ml"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 398 "lib/parser/parser.mly"
                          _1
# 2456 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 398 "lib/parser/parser.mly"
                                 ( TUint USize )
# 2461 "q1.ml"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 398 "lib/parser/parser.mly"
   _1
# 2466 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 398 "lib/parser/parser.mly"
          ( TUint U128 )
# 2471 "q1.ml"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 397 "lib/parser/parser.mly"
                          _1
# 2476 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 397 "lib/parser/parser.mly"
                                 ( TUint U64  )
# 2481 "q1.ml"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 397 "lib/parser/parser.mly"
   _1
# 2486 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 397 "lib/parser/parser.mly"
          ( TUint U32 )
# 2491 "q1.ml"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 396 "lib/parser/parser.mly"
                          _1
# 2496 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 396 "lib/parser/parser.mly"
                                 ( TUint U16  )
# 2501 "q1.ml"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 396 "lib/parser/parser.mly"
   _1
# 2506 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 396 "lib/parser/parser.mly"
          ( TUint U8  )
# 2511 "q1.ml"
     : 'tv_prim_ty_kw) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 482 "lib/parser/parser.mly"
                   _3
# 2516 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 482 "lib/parser/parser.mly"
           p
# 2520 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2524 "q1.ml"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 482 "lib/parser/parser.mly"
   _1
# 2528 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 483 "lib/parser/parser.mly"
    ( p )
# 2533 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2537 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 480 "lib/parser/parser.mly"
    name
# 2542 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    ((
# 481 "lib/parser/parser.mly"
    ( PVar name )
# 2547 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2551 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 478 "lib/parser/parser.mly"
                                                          _4
# 2556 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 478 "lib/parser/parser.mly"
                        args
# 2560 "q1.ml"
   : 'tv_separated_list_COMMA_pred_) (_startpos_args_ : Lexing.position) (_endpos_args_ : Lexing.position) (_startofs_args_ : int) (_endofs_args_ : int) (_loc_args_ : Lexing.position * Lexing.position) (
# 478 "lib/parser/parser.mly"
                _2
# 2564 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 478 "lib/parser/parser.mly"
    name
# 2568 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    ((
# 479 "lib/parser/parser.mly"
    ( PApp (name, args) )
# 2573 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2577 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 477 "lib/parser/parser.mly"
    ns
# 2582 "q1.ml"
   : (
# 16 "lib/parser/parser.mly"
       (int64 * string)
# 2586 "q1.ml"
  )) (_startpos_ns_ : Lexing.position) (_endpos_ns_ : Lexing.position) (_startofs_ns_ : int) (_endofs_ns_ : int) (_loc_ns_ : Lexing.position * Lexing.position) ->
    ((
# 477 "lib/parser/parser.mly"
                      ( let (n, _) = ns in PInt n )
# 2591 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2595 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 474 "lib/parser/parser.mly"
    n
# 2600 "q1.ml"
   : (
# 15 "lib/parser/parser.mly"
       (int64)
# 2604 "q1.ml"
  )) (_startpos_n_ : Lexing.position) (_endpos_n_ : Lexing.position) (_startofs_n_ : int) (_endofs_n_ : int) (_loc_n_ : Lexing.position * Lexing.position) ->
    ((
# 474 "lib/parser/parser.mly"
                      ( PInt n )
# 2609 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2613 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 473 "lib/parser/parser.mly"
   _1
# 2618 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 473 "lib/parser/parser.mly"
                      ( PBool false )
# 2623 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2627 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 472 "lib/parser/parser.mly"
   _1
# 2632 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 472 "lib/parser/parser.mly"
                      ( PBool true )
# 2637 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2641 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 468 "lib/parser/parser.mly"
                                _4
# 2646 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 468 "lib/parser/parser.mly"
                      idx
# 2650 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2654 "q1.ml"
  )) (_startpos_idx_ : Lexing.position) (_endpos_idx_ : Lexing.position) (_startofs_idx_ : int) (_endofs_idx_ : int) (_loc_idx_ : Lexing.position * Lexing.position) (
# 468 "lib/parser/parser.mly"
            _2
# 2658 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 468 "lib/parser/parser.mly"
    p
# 2662 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2666 "q1.ml"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) ->
    ((
# 469 "lib/parser/parser.mly"
    ( PIndex (p, idx) )
# 2671 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2675 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 464 "lib/parser/parser.mly"
                 name
# 2680 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 464 "lib/parser/parser.mly"
            _2
# 2684 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 464 "lib/parser/parser.mly"
    p
# 2688 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2692 "q1.ml"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) ->
    ((
# 465 "lib/parser/parser.mly"
    ( PField (p, name.name) )
# 2697 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2701 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 460 "lib/parser/parser.mly"
                                                                    _5
# 2706 "q1.ml"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 460 "lib/parser/parser.mly"
                           ps
# 2710 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_pred_) (_startpos_ps_ : Lexing.position) (_endpos_ps_ : Lexing.position) (_startofs_ps_ : int) (_endofs_ps_ : int) (_loc_ps_ : Lexing.position * Lexing.position) (
# 460 "lib/parser/parser.mly"
                    _3
# 2714 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 460 "lib/parser/parser.mly"
           p1
# 2718 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2722 "q1.ml"
  )) (_startpos_p1_ : Lexing.position) (_endpos_p1_ : Lexing.position) (_startofs_p1_ : int) (_endofs_p1_ : int) (_loc_p1_ : Lexing.position * Lexing.position) (
# 460 "lib/parser/parser.mly"
   _1
# 2726 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 461 "lib/parser/parser.mly"
    ( PLex (p1 :: ps) )
# 2731 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2735 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 456 "lib/parser/parser.mly"
   _1
# 2740 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 457 "lib/parser/parser.mly"
    ( PResult )
# 2745 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2749 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 454 "lib/parser/parser.mly"
                       _4
# 2754 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 454 "lib/parser/parser.mly"
               p
# 2758 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2762 "q1.ml"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 454 "lib/parser/parser.mly"
       _2
# 2766 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 454 "lib/parser/parser.mly"
   _1
# 2770 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 455 "lib/parser/parser.mly"
    ( POld p )
# 2775 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2779 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 450 "lib/parser/parser.mly"
                                           p
# 2784 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2788 "q1.ml"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 450 "lib/parser/parser.mly"
                                    _5
# 2792 "q1.ml"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) ((
# 450 "lib/parser/parser.mly"
                              t
# 2796 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 2800 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 450 "lib/parser/parser.mly"
                       _3
# 2804 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 450 "lib/parser/parser.mly"
           name
# 2808 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 450 "lib/parser/parser.mly"
   _1
# 2812 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 451 "lib/parser/parser.mly"
    ( PExists (name, t, p) )
# 2817 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2821 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 448 "lib/parser/parser.mly"
                                           p
# 2826 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2830 "q1.ml"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 448 "lib/parser/parser.mly"
                                    _5
# 2834 "q1.ml"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) ((
# 448 "lib/parser/parser.mly"
                              t
# 2838 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 2842 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 448 "lib/parser/parser.mly"
                       _3
# 2846 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 448 "lib/parser/parser.mly"
           name
# 2850 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 448 "lib/parser/parser.mly"
   _1
# 2854 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 449 "lib/parser/parser.mly"
    ( PForall (name, t, p) )
# 2859 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2863 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 445 "lib/parser/parser.mly"
          p
# 2868 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2872 "q1.ml"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 445 "lib/parser/parser.mly"
   _1
# 2876 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 445 "lib/parser/parser.mly"
                   ( PUnop (Neg, p) )
# 2881 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2885 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 444 "lib/parser/parser.mly"
         p
# 2890 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2894 "q1.ml"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 444 "lib/parser/parser.mly"
   _1
# 2898 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 444 "lib/parser/parser.mly"
                   ( PUnop (Not, p) )
# 2903 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2907 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 441 "lib/parser/parser.mly"
                     r
# 2912 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2916 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 441 "lib/parser/parser.mly"
            _2
# 2920 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 441 "lib/parser/parser.mly"
    l
# 2924 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2928 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 441 "lib/parser/parser.mly"
                              ( PBinop (Shr,    l, r) )
# 2933 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2937 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 440 "lib/parser/parser.mly"
                     r
# 2942 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2946 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 440 "lib/parser/parser.mly"
            _2
# 2950 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 440 "lib/parser/parser.mly"
    l
# 2954 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2958 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 440 "lib/parser/parser.mly"
                              ( PBinop (Shl,    l, r) )
# 2963 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2967 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 439 "lib/parser/parser.mly"
                     r
# 2972 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2976 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 439 "lib/parser/parser.mly"
            _2
# 2980 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 439 "lib/parser/parser.mly"
    l
# 2984 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2988 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 439 "lib/parser/parser.mly"
                              ( PBinop (BitXor, l, r) )
# 2993 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 2997 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 438 "lib/parser/parser.mly"
                     r
# 3002 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3006 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 438 "lib/parser/parser.mly"
            _2
# 3010 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 438 "lib/parser/parser.mly"
    l
# 3014 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3018 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 438 "lib/parser/parser.mly"
                              ( PBinop (BitAnd, l, r) )
# 3023 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3027 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 437 "lib/parser/parser.mly"
                     r
# 3032 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3036 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 437 "lib/parser/parser.mly"
            _2
# 3040 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 437 "lib/parser/parser.mly"
    l
# 3044 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3048 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 437 "lib/parser/parser.mly"
                              ( PBinop (BitOr,  l, r) )
# 3053 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3057 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 434 "lib/parser/parser.mly"
                     r
# 3062 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3066 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 434 "lib/parser/parser.mly"
            _2
# 3070 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 434 "lib/parser/parser.mly"
    l
# 3074 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3078 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 434 "lib/parser/parser.mly"
                              ( PBinop (Mod, l, r) )
# 3083 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3087 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 433 "lib/parser/parser.mly"
                     r
# 3092 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3096 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 433 "lib/parser/parser.mly"
            _2
# 3100 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 433 "lib/parser/parser.mly"
    l
# 3104 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3108 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 433 "lib/parser/parser.mly"
                              ( PBinop (Div, l, r) )
# 3113 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3117 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 432 "lib/parser/parser.mly"
                     r
# 3122 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3126 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 432 "lib/parser/parser.mly"
            _2
# 3130 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 432 "lib/parser/parser.mly"
    l
# 3134 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3138 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 432 "lib/parser/parser.mly"
                              ( PBinop (Mul, l, r) )
# 3143 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3147 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 431 "lib/parser/parser.mly"
                     r
# 3152 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3156 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 431 "lib/parser/parser.mly"
            _2
# 3160 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 431 "lib/parser/parser.mly"
    l
# 3164 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3168 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 431 "lib/parser/parser.mly"
                              ( PBinop (Sub, l, r) )
# 3173 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3177 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 430 "lib/parser/parser.mly"
                     r
# 3182 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3186 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 430 "lib/parser/parser.mly"
            _2
# 3190 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 430 "lib/parser/parser.mly"
    l
# 3194 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3198 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 430 "lib/parser/parser.mly"
                              ( PBinop (Add, l, r) )
# 3203 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3207 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 427 "lib/parser/parser.mly"
                  r
# 3212 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3216 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 427 "lib/parser/parser.mly"
            _2
# 3220 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 427 "lib/parser/parser.mly"
    l
# 3224 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3228 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 427 "lib/parser/parser.mly"
                            ( PBinop (Ge,  l, r) )
# 3233 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3237 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 426 "lib/parser/parser.mly"
                  r
# 3242 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3246 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 426 "lib/parser/parser.mly"
            _2
# 3250 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 426 "lib/parser/parser.mly"
    l
# 3254 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3258 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 426 "lib/parser/parser.mly"
                            ( PBinop (Gt,  l, r) )
# 3263 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3267 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 425 "lib/parser/parser.mly"
                  r
# 3272 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3276 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 425 "lib/parser/parser.mly"
            _2
# 3280 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 425 "lib/parser/parser.mly"
    l
# 3284 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3288 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 425 "lib/parser/parser.mly"
                            ( PBinop (Le,  l, r) )
# 3293 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3297 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 424 "lib/parser/parser.mly"
                  r
# 3302 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3306 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 424 "lib/parser/parser.mly"
            _2
# 3310 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 424 "lib/parser/parser.mly"
    l
# 3314 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3318 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 424 "lib/parser/parser.mly"
                            ( PBinop (Lt,  l, r) )
# 3323 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3327 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 423 "lib/parser/parser.mly"
                  r
# 3332 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3336 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 423 "lib/parser/parser.mly"
            _2
# 3340 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 423 "lib/parser/parser.mly"
    l
# 3344 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3348 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 423 "lib/parser/parser.mly"
                            ( PBinop (Ne,  l, r) )
# 3353 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3357 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 422 "lib/parser/parser.mly"
                  r
# 3362 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3366 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 422 "lib/parser/parser.mly"
            _2
# 3370 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 422 "lib/parser/parser.mly"
    l
# 3374 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3378 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 422 "lib/parser/parser.mly"
                            ( PBinop (Eq,  l, r) )
# 3383 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3387 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 418 "lib/parser/parser.mly"
                  r
# 3392 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3396 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 418 "lib/parser/parser.mly"
            _2
# 3400 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 418 "lib/parser/parser.mly"
    l
# 3404 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3408 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 419 "lib/parser/parser.mly"
    ( PBinop (And, l, r) )
# 3413 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3417 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 416 "lib/parser/parser.mly"
                 r
# 3422 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3426 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 416 "lib/parser/parser.mly"
            _2
# 3430 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 416 "lib/parser/parser.mly"
    l
# 3434 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3438 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 417 "lib/parser/parser.mly"
    ( PBinop (Or, l, r) )
# 3443 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3447 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 414 "lib/parser/parser.mly"
                     r
# 3452 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3456 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 414 "lib/parser/parser.mly"
            _2
# 3460 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 414 "lib/parser/parser.mly"
    l
# 3464 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3468 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 415 "lib/parser/parser.mly"
    ( PBinop (Implies, l, r) )
# 3473 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3477 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 412 "lib/parser/parser.mly"
                 r
# 3482 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3486 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 412 "lib/parser/parser.mly"
            _2
# 3490 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 412 "lib/parser/parser.mly"
    l
# 3494 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3498 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 413 "lib/parser/parser.mly"
    ( PBinop (Iff, l, r) )
# 3503 "q1.ml"
     : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3507 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 837 "lib/parser/parser.mly"
                                                _3
# 3512 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 837 "lib/parser/parser.mly"
           pats
# 3516 "q1.ml"
   : 'tv_separated_list_COMMA_pattern_) (_startpos_pats_ : Lexing.position) (_endpos_pats_ : Lexing.position) (_startofs_pats_ : int) (_endofs_pats_ : int) (_loc_pats_ : Lexing.position * Lexing.position) (
# 837 "lib/parser/parser.mly"
   _1
# 3520 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 838 "lib/parser/parser.mly"
    ( PTuple pats )
# 3525 "q1.ml"
     : 'tv_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 835 "lib/parser/parser.mly"
                     name
# 3530 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 835 "lib/parser/parser.mly"
                 _2
# 3534 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 835 "lib/parser/parser.mly"
    pat
# 3538 "q1.ml"
   : 'tv_pattern) (_startpos_pat_ : Lexing.position) (_endpos_pat_ : Lexing.position) (_startofs_pat_ : int) (_endofs_pat_ : int) (_loc_pat_ : Lexing.position * Lexing.position) ->
    (
# 836 "lib/parser/parser.mly"
    ( PAs (pat, name) )
# 3543 "q1.ml"
     : 'tv_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 833 "lib/parser/parser.mly"
                                                             _4
# 3548 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 833 "lib/parser/parser.mly"
                        pats
# 3552 "q1.ml"
   : 'tv_separated_list_COMMA_pattern_) (_startpos_pats_ : Lexing.position) (_endpos_pats_ : Lexing.position) (_startofs_pats_ : int) (_endofs_pats_ : int) (_loc_pats_ : Lexing.position * Lexing.position) (
# 833 "lib/parser/parser.mly"
                _2
# 3556 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 833 "lib/parser/parser.mly"
    name
# 3560 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 834 "lib/parser/parser.mly"
    ( PCtor (name, pats) )
# 3565 "q1.ml"
     : 'tv_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 831 "lib/parser/parser.mly"
   _1
# 3570 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 832 "lib/parser/parser.mly"
    ( PLit (LBool false) )
# 3575 "q1.ml"
     : 'tv_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 829 "lib/parser/parser.mly"
   _1
# 3580 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 830 "lib/parser/parser.mly"
    ( PLit (LBool true) )
# 3585 "q1.ml"
     : 'tv_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 827 "lib/parser/parser.mly"
    n
# 3590 "q1.ml"
   : (
# 15 "lib/parser/parser.mly"
       (int64)
# 3594 "q1.ml"
  )) (_startpos_n_ : Lexing.position) (_endpos_n_ : Lexing.position) (_startofs_n_ : int) (_endofs_n_ : int) (_loc_n_ : Lexing.position * Lexing.position) ->
    (
# 828 "lib/parser/parser.mly"
    ( PLit (LInt (n, None)) )
# 3599 "q1.ml"
     : 'tv_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 825 "lib/parser/parser.mly"
    name
# 3604 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 826 "lib/parser/parser.mly"
    ( PBind name )
# 3609 "q1.ml"
     : 'tv_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 823 "lib/parser/parser.mly"
   _1
# 3614 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 824 "lib/parser/parser.mly"
    ( PWild )
# 3619 "q1.ml"
     : 'tv_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 195 "lib/parser/parser.mly"
                       t
# 3624 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 3628 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 195 "lib/parser/parser.mly"
                _2
# 3632 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 195 "lib/parser/parser.mly"
    name
# 3636 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 196 "lib/parser/parser.mly"
    ( (name, t) )
# 3641 "q1.ml"
     : 'tv_param) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 648 "lib/parser/parser.mly"
                            _5
# 3647 "q1.ml"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 648 "lib/parser/parser.mly"
      arms
# 3651 "q1.ml"
   : 'tv_list_match_arm_) (_startpos_arms_ : Lexing.position) (_endpos_arms_ : Lexing.position) (_startofs_arms_ : int) (_endofs_arms_ : int) (_loc_arms_ : Lexing.position * Lexing.position) (
# 647 "lib/parser/parser.mly"
                      _3
# 3655 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 647 "lib/parser/parser.mly"
          scrut
# 3659 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 3663 "q1.ml"
  )) (_startpos_scrut_ : Lexing.position) (_endpos_scrut_ : Lexing.position) (_startofs_scrut_ : int) (_endofs_scrut_ : int) (_loc_scrut_ : Lexing.position * Lexing.position) (
# 647 "lib/parser/parser.mly"
   _1
# 3667 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 650 "lib/parser/parser.mly"
    ( mk_expr (EMatch (scrut, arms)) _startpos )
# 3672 "q1.ml"
     : 'tv_match_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 653 "lib/parser/parser.mly"
                                                                  body
# 3677 "q1.ml"
   : 'tv_arm_body) (_startpos_body_ : Lexing.position) (_endpos_body_ : Lexing.position) (_startofs_body_ : int) (_endofs_body_ : int) (_loc_body_ : Lexing.position * Lexing.position) (
# 653 "lib/parser/parser.mly"
                                                        _3
# 3681 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 653 "lib/parser/parser.mly"
                      guard
# 3685 "q1.ml"
   : 'tv_option_preceded_IF_pred__) (_startpos_guard_ : Lexing.position) (_endpos_guard_ : Lexing.position) (_startofs_guard_ : int) (_endofs_guard_ : int) (_loc_guard_ : Lexing.position * Lexing.position) (
# 653 "lib/parser/parser.mly"
    pat
# 3689 "q1.ml"
   : 'tv_alt_pattern) (_startpos_pat_ : Lexing.position) (_endpos_pat_ : Lexing.position) (_startofs_pat_ : int) (_endofs_pat_ : int) (_loc_pat_ : Lexing.position * Lexing.position) ->
    (
# 654 "lib/parser/parser.mly"
    ( { pattern = pat; guard; body } )
# 3694 "q1.ml"
     : 'tv_match_arm) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 692 "lib/parser/parser.mly"
    body
# 3699 "q1.ml"
   : 'tv_block_expr) (_startpos_body_ : Lexing.position) (_endpos_body_ : Lexing.position) (_startofs_body_ : int) (_endofs_body_ : int) (_loc_body_ : Lexing.position * Lexing.position) (
# 691 "lib/parser/parser.mly"
    dec
# 3703 "q1.ml"
   : 'tv_option_preceded_DECREASES_pred__) (_startpos_dec_ : Lexing.position) (_endpos_dec_ : Lexing.position) (_startofs_dec_ : int) (_endofs_dec_ : int) (_loc_dec_ : Lexing.position * Lexing.position) ((
# 690 "lib/parser/parser.mly"
                        iter
# 3707 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 3711 "q1.ml"
  )) (_startpos_iter_ : Lexing.position) (_endpos_iter_ : Lexing.position) (_startofs_iter_ : int) (_endofs_iter_ : int) (_loc_iter_ : Lexing.position * Lexing.position) (
# 690 "lib/parser/parser.mly"
                    _3
# 3715 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 690 "lib/parser/parser.mly"
        name
# 3719 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 690 "lib/parser/parser.mly"
   _1
# 3723 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 693 "lib/parser/parser.mly"
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
# 3737 "q1.ml"
     : 'tv_loop_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 679 "lib/parser/parser.mly"
    body
# 3742 "q1.ml"
   : 'tv_block_expr) (_startpos_body_ : Lexing.position) (_endpos_body_ : Lexing.position) (_startofs_body_ : int) (_endofs_body_ : int) (_loc_body_ : Lexing.position * Lexing.position) (
# 678 "lib/parser/parser.mly"
    dec
# 3746 "q1.ml"
   : 'tv_option_preceded_DECREASES_pred__) (_startpos_dec_ : Lexing.position) (_endpos_dec_ : Lexing.position) (_startofs_dec_ : int) (_endofs_dec_ : int) (_loc_dec_ : Lexing.position * Lexing.position) (
# 677 "lib/parser/parser.mly"
    inv
# 3750 "q1.ml"
   : 'tv_option_preceded_INVARIANT_pred__) (_startpos_inv_ : Lexing.position) (_endpos_inv_ : Lexing.position) (_startofs_inv_ : int) (_endofs_inv_ : int) (_loc_inv_ : Lexing.position * Lexing.position) ((
# 676 "lib/parser/parser.mly"
          cond
# 3754 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 3758 "q1.ml"
  )) (_startpos_cond_ : Lexing.position) (_endpos_cond_ : Lexing.position) (_startofs_cond_ : int) (_endofs_cond_ : int) (_loc_cond_ : Lexing.position * Lexing.position) (
# 676 "lib/parser/parser.mly"
   _1
# 3762 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 680 "lib/parser/parser.mly"
    (
      let stmts = match body.expr_desc with
        | EBlock (ss, Some ret) -> ss @ [mk_stmt (SExpr ret) _startpos]
        | EBlock (ss, None)     -> ss
        | _ -> [mk_stmt (SExpr body) _startpos]
      in
      mk_expr (EBlock (
        [mk_stmt (SWhile (cond, inv, dec, stmts)) _startpos],
        None)) _startpos
    )
# 3776 "q1.ml"
     : 'tv_loop_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 668 "lib/parser/parser.mly"
         body
# 3781 "q1.ml"
   : 'tv_block_expr) (_startpos_body_ : Lexing.position) (_endpos_body_ : Lexing.position) (_startofs_body_ : int) (_endofs_body_ : int) (_loc_body_ : Lexing.position * Lexing.position) (
# 668 "lib/parser/parser.mly"
   _1
# 3785 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 669 "lib/parser/parser.mly"
    ( mk_expr (EBlock (
        [mk_stmt (SWhile (
            mk_expr (ELit (LBool true)) _startpos,
            None, None,
            [mk_stmt (SExpr body) _startpos]
          )) _startpos],
        None)) _startpos )
# 3796 "q1.ml"
     : 'tv_loop_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 816 "lib/parser/parser.mly"
   _1
# 3801 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 816 "lib/parser/parser.mly"
        ( Unr )
# 3806 "q1.ml"
     : 'tv_linearity) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 815 "lib/parser/parser.mly"
   _1
# 3811 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 815 "lib/parser/parser.mly"
        ( Aff )
# 3816 "q1.ml"
     : 'tv_linearity) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 814 "lib/parser/parser.mly"
   _1
# 3821 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 814 "lib/parser/parser.mly"
        ( Lin )
# 3826 "q1.ml"
     : 'tv_linearity) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 732 "lib/parser/parser.mly"
                          _10
# 3831 "q1.ml"
   : unit) (_startpos__10_ : Lexing.position) (_endpos__10_ : Lexing.position) (_startofs__10_ : int) (_endofs__10_ : int) (_loc__10_ : Lexing.position * Lexing.position) (
# 732 "lib/parser/parser.mly"
           pt
# 3835 "q1.ml"
   : 'tv_proof_term) (_startpos_pt_ : Lexing.position) (_endpos_pt_ : Lexing.position) (_startofs_pt_ : int) (_endofs_pt_ : int) (_loc_pt_ : Lexing.position * Lexing.position) (
# 731 "lib/parser/parser.mly"
                     _8
# 3840 "q1.ml"
   : unit) (_startpos__8_ : Lexing.position) (_endpos__8_ : Lexing.position) (_startofs__8_ : int) (_endofs__8_ : int) (_loc__8_ : Lexing.position * Lexing.position) ((
# 731 "lib/parser/parser.mly"
          stmt
# 3844 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 3848 "q1.ml"
  )) (_startpos_stmt_ : Lexing.position) (_endpos_stmt_ : Lexing.position) (_startofs_stmt_ : int) (_endofs_stmt_ : int) (_loc_stmt_ : Lexing.position * Lexing.position) (
# 730 "lib/parser/parser.mly"
                                       _6
# 3853 "q1.ml"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) (
# 730 "lib/parser/parser.mly"
                                _5
# 3857 "q1.ml"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 730 "lib/parser/parser.mly"
           params
# 3861 "q1.ml"
   : 'tv_tlist_param_) (_startpos_params_ : Lexing.position) (_endpos_params_ : Lexing.position) (_startofs_params_ : int) (_endofs_params_ : int) (_loc_params_ : Lexing.position * Lexing.position) (
# 729 "lib/parser/parser.mly"
                      _3
# 3866 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 729 "lib/parser/parser.mly"
          name
# 3870 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 729 "lib/parser/parser.mly"
   _1
# 3874 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 733 "lib/parser/parser.mly"
    (
      {
        lem_name   = name;
        lem_params = params;
        lem_stmt   = stmt;
        lem_proof  = pt;
        lem_loc    = mk_loc _startpos;
      }
    )
# 3887 "q1.ml"
     : 'tv_lemma_def) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 260 "lib/parser/parser.mly"
                                                      _3
# 3892 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 260 "lib/parser/parser.mly"
       ps
# 3896 "q1.ml"
   : 'tv_separated_nonempty_list_COMMA_kind_param_) (_startpos_ps_ : Lexing.position) (_endpos_ps_ : Lexing.position) (_startofs_ps_ : int) (_endofs_ps_ : int) (_loc_ps_ : Lexing.position * Lexing.position) (
# 260 "lib/parser/parser.mly"
   _1
# 3900 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 260 "lib/parser/parser.mly"
                                                          ( ps )
# 3905 "q1.ml"
     : 'tv_kind_params) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 259 "lib/parser/parser.mly"
    ( [] )
# 3911 "q1.ml"
     : 'tv_kind_params) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 264 "lib/parser/parser.mly"
                      _3
# 3916 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 264 "lib/parser/parser.mly"
                _2
# 3920 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 264 "lib/parser/parser.mly"
    name
# 3924 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 264 "lib/parser/parser.mly"
                                   ( (name, KNat) )
# 3929 "q1.ml"
     : 'tv_kind_param) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 263 "lib/parser/parser.mly"
    name
# 3934 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 263 "lib/parser/parser.mly"
                                   ( (name, KType) )
# 3939 "q1.ml"
     : 'tv_kind_param) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 157 "lib/parser/parser.mly"
                                                     _3
# 3944 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 157 "lib/parser/parser.mly"
        path
# 3948 "q1.ml"
   : 'tv_separated_nonempty_list_DCOLON_ident_) (_startpos_path_ : Lexing.position) (_endpos_path_ : Lexing.position) (_startofs_path_ : int) (_endofs_path_ : int) (_loc_path_ : Lexing.position * Lexing.position) (
# 157 "lib/parser/parser.mly"
   _1
# 3952 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 158 "lib/parser/parser.mly"
    ( mk_item (IUse path) _startpos )
# 3957 "q1.ml"
     : 'tv_item) : (
# 115 "lib/parser/parser.mly"
       (Ast.item)
# 3961 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 155 "lib/parser/parser.mly"
    e
# 3966 "q1.ml"
   : 'tv_extern_def) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 156 "lib/parser/parser.mly"
    ( mk_item (IExtern e) _startpos )
# 3971 "q1.ml"
     : 'tv_item) : (
# 115 "lib/parser/parser.mly"
       (Ast.item)
# 3975 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 153 "lib/parser/parser.mly"
    i
# 3980 "q1.ml"
   : 'tv_impl_def) (_startpos_i_ : Lexing.position) (_endpos_i_ : Lexing.position) (_startofs_i_ : int) (_endofs_i_ : int) (_loc_i_ : Lexing.position * Lexing.position) ->
    ((
# 154 "lib/parser/parser.mly"
    ( mk_item (IImpl i) _startpos )
# 3985 "q1.ml"
     : 'tv_item) : (
# 115 "lib/parser/parser.mly"
       (Ast.item)
# 3989 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 151 "lib/parser/parser.mly"
    e
# 3994 "q1.ml"
   : 'tv_enum_def) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 152 "lib/parser/parser.mly"
    ( mk_item (IEnum e) _startpos )
# 3999 "q1.ml"
     : 'tv_item) : (
# 115 "lib/parser/parser.mly"
       (Ast.item)
# 4003 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 149 "lib/parser/parser.mly"
    s
# 4008 "q1.ml"
   : 'tv_struct_def) (_startpos_s_ : Lexing.position) (_endpos_s_ : Lexing.position) (_startofs_s_ : int) (_endofs_s_ : int) (_loc_s_ : Lexing.position * Lexing.position) ->
    ((
# 150 "lib/parser/parser.mly"
    ( mk_item (IStruct s) _startpos )
# 4013 "q1.ml"
     : 'tv_item) : (
# 115 "lib/parser/parser.mly"
       (Ast.item)
# 4017 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 147 "lib/parser/parser.mly"
    t
# 4022 "q1.ml"
   : 'tv_type_def) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) ->
    ((
# 148 "lib/parser/parser.mly"
    ( mk_item (IType t) _startpos )
# 4027 "q1.ml"
     : 'tv_item) : (
# 115 "lib/parser/parser.mly"
       (Ast.item)
# 4031 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 145 "lib/parser/parser.mly"
    f
# 4036 "q1.ml"
   : 'tv_fn_def) (_startpos_f_ : Lexing.position) (_endpos_f_ : Lexing.position) (_startofs_f_ : int) (_endofs_f_ : int) (_loc_f_ : Lexing.position * Lexing.position) ->
    ((
# 146 "lib/parser/parser.mly"
    ( mk_item (IFn f) _startpos )
# 4041 "q1.ml"
     : 'tv_item) : (
# 115 "lib/parser/parser.mly"
       (Ast.item)
# 4045 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 256 "lib/parser/parser.mly"
              p
# 4050 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 4054 "q1.ml"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 256 "lib/parser/parser.mly"
   _1
# 4058 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 256 "lib/parser/parser.mly"
                            ( p )
# 4063 "q1.ml"
     : 'tv_invariant_clause) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 255 "lib/parser/parser.mly"
                      _3
# 4068 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 255 "lib/parser/parser.mly"
              p
# 4072 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 4076 "q1.ml"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 255 "lib/parser/parser.mly"
   _1
# 4080 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 255 "lib/parser/parser.mly"
                            ( p )
# 4085 "q1.ml"
     : 'tv_invariant_clause) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 296 "lib/parser/parser.mly"
                                         _5
# 4090 "q1.ml"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 296 "lib/parser/parser.mly"
                       items
# 4094 "q1.ml"
   : 'tv_list_item_) (_startpos_items_ : Lexing.position) (_endpos_items_ : Lexing.position) (_startofs_items_ : int) (_endofs_items_ : int) (_loc_items_ : Lexing.position * Lexing.position) (
# 296 "lib/parser/parser.mly"
               _3
# 4098 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 296 "lib/parser/parser.mly"
         t
# 4102 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 4106 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 296 "lib/parser/parser.mly"
   _1
# 4110 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 297 "lib/parser/parser.mly"
    (
      {
        im_ty    = t;
        im_items = items;
      }
    )
# 4120 "q1.ml"
     : 'tv_impl_def) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 639 "lib/parser/parser.mly"
    else_
# 4125 "q1.ml"
   : 'tv_option_preceded_ELSE_else_branch__) (_startpos_else__ : Lexing.position) (_endpos_else__ : Lexing.position) (_startofs_else__ : int) (_endofs_else__ : int) (_loc_else__ : Lexing.position * Lexing.position) (
# 638 "lib/parser/parser.mly"
    then_
# 4129 "q1.ml"
   : 'tv_block_expr) (_startpos_then__ : Lexing.position) (_endpos_then__ : Lexing.position) (_startofs_then__ : int) (_endofs_then__ : int) (_loc_then__ : Lexing.position * Lexing.position) ((
# 637 "lib/parser/parser.mly"
       cond
# 4133 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4137 "q1.ml"
  )) (_startpos_cond_ : Lexing.position) (_endpos_cond_ : Lexing.position) (_startofs_cond_ : int) (_endofs_cond_ : int) (_loc_cond_ : Lexing.position * Lexing.position) (
# 637 "lib/parser/parser.mly"
   _1
# 4141 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 640 "lib/parser/parser.mly"
    ( mk_expr (EIf (cond, then_, else_)) _startpos )
# 4146 "q1.ml"
     : 'tv_if_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 856 "lib/parser/parser.mly"
   _1
# 4151 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 856 "lib/parser/parser.mly"
               ( mk_ident "varying"    _startpos )
# 4156 "q1.ml"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 855 "lib/parser/parser.mly"
   _1
# 4161 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 855 "lib/parser/parser.mly"
               ( mk_ident "uniform"    _startpos )
# 4166 "q1.ml"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 854 "lib/parser/parser.mly"
   _1
# 4171 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 854 "lib/parser/parser.mly"
               ( mk_ident "shared"     _startpos )
# 4176 "q1.ml"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 853 "lib/parser/parser.mly"
   _1
# 4181 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 853 "lib/parser/parser.mly"
               ( mk_ident "span"       _startpos )
# 4186 "q1.ml"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 852 "lib/parser/parser.mly"
   _1
# 4191 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 852 "lib/parser/parser.mly"
               ( mk_ident "coalesced"  _startpos )
# 4196 "q1.ml"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 851 "lib/parser/parser.mly"
   _1
# 4201 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 851 "lib/parser/parser.mly"
               ( mk_ident "kernel"     _startpos )
# 4206 "q1.ml"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 849 "lib/parser/parser.mly"
   _1
# 4211 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 849 "lib/parser/parser.mly"
               ( mk_ident "by"         _startpos )
# 4216 "q1.ml"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 848 "lib/parser/parser.mly"
   _1
# 4221 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 848 "lib/parser/parser.mly"
               ( mk_ident "raw"        _startpos )
# 4226 "q1.ml"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 845 "lib/parser/parser.mly"
    name
# 4231 "q1.ml"
   : (
# 19 "lib/parser/parser.mly"
       (string)
# 4235 "q1.ml"
  )) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 846 "lib/parser/parser.mly"
    ( mk_ident name _startpos )
# 4240 "q1.ml"
     : 'tv_ident) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 172 "lib/parser/parser.mly"
    body
# 4245 "q1.ml"
   : 'tv_fn_body) (_startpos_body_ : Lexing.position) (_endpos_body_ : Lexing.position) (_startofs_body_ : int) (_endofs_body_ : int) (_loc_body_ : Lexing.position * Lexing.position) (
# 171 "lib/parser/parser.mly"
    dec
# 4249 "q1.ml"
   : 'tv_option_decreases_clause_) (_startpos_dec_ : Lexing.position) (_endpos_dec_ : Lexing.position) (_startofs_dec_ : int) (_endofs_dec_ : int) (_loc_dec_ : Lexing.position * Lexing.position) (
# 170 "lib/parser/parser.mly"
    enss
# 4253 "q1.ml"
   : 'tv_list_ensures_clause_) (_startpos_enss_ : Lexing.position) (_endpos_enss_ : Lexing.position) (_startofs_enss_ : int) (_endofs_enss_ : int) (_loc_enss_ : Lexing.position * Lexing.position) (
# 169 "lib/parser/parser.mly"
    reqs
# 4257 "q1.ml"
   : 'tv_list_requires_clause_) (_startpos_reqs_ : Lexing.position) (_endpos_reqs_ : Lexing.position) (_startofs_reqs_ : int) (_endofs_reqs_ : int) (_loc_reqs_ : Lexing.position * Lexing.position) (
# 168 "lib/parser/parser.mly"
    ret
# 4261 "q1.ml"
   : 'tv_option_preceded_ARROW_ty__) (_startpos_ret_ : Lexing.position) (_endpos_ret_ : Lexing.position) (_startofs_ret_ : int) (_endofs_ret_ : int) (_loc_ret_ : Lexing.position * Lexing.position) (
# 167 "lib/parser/parser.mly"
                                _7
# 4265 "q1.ml"
   : unit) (_startpos__7_ : Lexing.position) (_endpos__7_ : Lexing.position) (_startofs__7_ : int) (_endofs__7_ : int) (_loc__7_ : Lexing.position * Lexing.position) (
# 167 "lib/parser/parser.mly"
           params
# 4269 "q1.ml"
   : 'tv_tlist_param_) (_startpos_params_ : Lexing.position) (_endpos_params_ : Lexing.position) (_startofs_params_ : int) (_endofs_params_ : int) (_loc_params_ : Lexing.position * Lexing.position) (
# 166 "lib/parser/parser.mly"
                          _5
# 4274 "q1.ml"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 166 "lib/parser/parser.mly"
    generics
# 4278 "q1.ml"
   : 'tv_kind_params) (_startpos_generics_ : Lexing.position) (_endpos_generics_ : Lexing.position) (_startofs_generics_ : int) (_endofs_generics_ : int) (_loc_generics_ : Lexing.position * Lexing.position) (
# 165 "lib/parser/parser.mly"
                                 name
# 4282 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 165 "lib/parser/parser.mly"
                             _2
# 4286 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 165 "lib/parser/parser.mly"
    attrs
# 4290 "q1.ml"
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
# 4308 "q1.ml"
     : 'tv_fn_def) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 209 "lib/parser/parser.mly"
    e
# 4313 "q1.ml"
   : 'tv_block_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 209 "lib/parser/parser.mly"
                   ( Some e )
# 4318 "q1.ml"
     : 'tv_fn_body) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 208 "lib/parser/parser.mly"
   _1
# 4323 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 208 "lib/parser/parser.mly"
                 ( None )
# 4328 "q1.ml"
     : 'tv_fn_body) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 328 "lib/parser/parser.mly"
       s
# 4333 "q1.ml"
   : (
# 18 "lib/parser/parser.mly"
       (string)
# 4337 "q1.ml"
  )) (_startpos_s_ : Lexing.position) (_endpos_s_ : Lexing.position) (_startofs_s_ : int) (_endofs_s_ : int) (_loc_s_ : Lexing.position * Lexing.position) (
# 328 "lib/parser/parser.mly"
   _1
# 4341 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 328 "lib/parser/parser.mly"
                  ( s )
# 4346 "q1.ml"
     : 'tv_extern_link) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 314 "lib/parser/parser.mly"
                              _11
# 4352 "q1.ml"
   : unit) (_startpos__11_ : Lexing.position) (_endpos__11_ : Lexing.position) (_startofs__11_ : int) (_endofs__11_ : int) (_loc__11_ : Lexing.position * Lexing.position) (
# 314 "lib/parser/parser.mly"
    link
# 4356 "q1.ml"
   : 'tv_option_extern_link_) (_startpos_link_ : Lexing.position) (_endpos_link_ : Lexing.position) (_startofs_link_ : int) (_endofs_link_ : int) (_loc_link_ : Lexing.position * Lexing.position) (
# 313 "lib/parser/parser.mly"
    enss
# 4360 "q1.ml"
   : 'tv_list_ensures_clause_) (_startpos_enss_ : Lexing.position) (_endpos_enss_ : Lexing.position) (_startofs_enss_ : int) (_endofs_enss_ : int) (_loc_enss_ : Lexing.position * Lexing.position) (
# 312 "lib/parser/parser.mly"
    reqs
# 4364 "q1.ml"
   : 'tv_list_requires_clause_) (_startpos_reqs_ : Lexing.position) (_endpos_reqs_ : Lexing.position) (_startofs_reqs_ : int) (_endofs_reqs_ : int) (_loc_reqs_ : Lexing.position * Lexing.position) (
# 311 "lib/parser/parser.mly"
    ret
# 4368 "q1.ml"
   : 'tv_option_preceded_ARROW_ty__) (_startpos_ret_ : Lexing.position) (_endpos_ret_ : Lexing.position) (_startofs_ret_ : int) (_endofs_ret_ : int) (_loc_ret_ : Lexing.position * Lexing.position) (
# 310 "lib/parser/parser.mly"
                                _6
# 4372 "q1.ml"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) (
# 310 "lib/parser/parser.mly"
           params
# 4376 "q1.ml"
   : 'tv_tlist_param_) (_startpos_params_ : Lexing.position) (_endpos_params_ : Lexing.position) (_startofs_params_ : int) (_endofs_params_ : int) (_loc_params_ : Lexing.position * Lexing.position) (
# 309 "lib/parser/parser.mly"
                          _4
# 4381 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 309 "lib/parser/parser.mly"
              name
# 4385 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 309 "lib/parser/parser.mly"
          _2
# 4389 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 309 "lib/parser/parser.mly"
   _1
# 4393 "q1.ml"
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
# 4407 "q1.ml"
     : 'tv_extern_def) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 569 "lib/parser/parser.mly"
    e
# 4412 "q1.ml"
   : 'tv_atom_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 569 "lib/parser/parser.mly"
                      ( e )
# 4417 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4421 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 564 "lib/parser/parser.mly"
                                       _5
# 4427 "q1.ml"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 564 "lib/parser/parser.mly"
      fields
# 4431 "q1.ml"
   : 'tv_tlist_struct_field_init_) (_startpos_fields_ : Lexing.position) (_endpos_fields_ : Lexing.position) (_startofs_fields_ : int) (_endofs_fields_ : int) (_loc_fields_ : Lexing.position * Lexing.position) (
# 563 "lib/parser/parser.mly"
                       _3
# 4435 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 563 "lib/parser/parser.mly"
           name
# 4439 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 563 "lib/parser/parser.mly"
   _1
# 4443 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 566 "lib/parser/parser.mly"
    ( mk_expr (EStruct (name, fields)) _startpos )
# 4448 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4452 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 559 "lib/parser/parser.mly"
                t
# 4457 "q1.ml"
   : 'tv_ty) : (
# 117 "lib/parser/parser.mly"
       (Ast.ty)
# 4461 "q1.ml"
  )) (_startpos_t_ : Lexing.position) (_endpos_t_ : Lexing.position) (_startofs_t_ : int) (_endofs_t_ : int) (_loc_t_ : Lexing.position * Lexing.position) (
# 559 "lib/parser/parser.mly"
            _2
# 4465 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 559 "lib/parser/parser.mly"
    e
# 4469 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4473 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 560 "lib/parser/parser.mly"
    ( mk_expr (ECast (e, t)) _startpos )
# 4478 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4482 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 555 "lib/parser/parser.mly"
                      _3
# 4487 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 555 "lib/parser/parser.mly"
               _2
# 4491 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 555 "lib/parser/parser.mly"
   _1
# 4495 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 556 "lib/parser/parser.mly"
    ( mk_expr ESync _startpos )
# 4500 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4504 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 552 "lib/parser/parser.mly"
    e
# 4509 "q1.ml"
   : 'tv_return_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 552 "lib/parser/parser.mly"
                      ( e )
# 4514 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4518 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 551 "lib/parser/parser.mly"
    e
# 4523 "q1.ml"
   : 'tv_assume_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 551 "lib/parser/parser.mly"
                      ( e )
# 4528 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4532 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 550 "lib/parser/parser.mly"
    e
# 4537 "q1.ml"
   : 'tv_raw_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 550 "lib/parser/parser.mly"
                      ( e )
# 4542 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4546 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 549 "lib/parser/parser.mly"
    e
# 4551 "q1.ml"
   : 'tv_proof_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 549 "lib/parser/parser.mly"
                      ( e )
# 4556 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4560 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 548 "lib/parser/parser.mly"
    e
# 4565 "q1.ml"
   : 'tv_loop_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 548 "lib/parser/parser.mly"
                      ( e )
# 4570 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4574 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 547 "lib/parser/parser.mly"
    e
# 4579 "q1.ml"
   : 'tv_match_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 547 "lib/parser/parser.mly"
                      ( e )
# 4584 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4588 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 546 "lib/parser/parser.mly"
    e
# 4593 "q1.ml"
   : 'tv_if_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 546 "lib/parser/parser.mly"
                      ( e )
# 4598 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4602 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 545 "lib/parser/parser.mly"
    e
# 4607 "q1.ml"
   : 'tv_block_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 545 "lib/parser/parser.mly"
                      ( e )
# 4612 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4616 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 539 "lib/parser/parser.mly"
                     alt
# 4621 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4625 "q1.ml"
  )) (_startpos_alt_ : Lexing.position) (_endpos_alt_ : Lexing.position) (_startofs_alt_ : int) (_endofs_alt_ : int) (_loc_alt_ : Lexing.position * Lexing.position) (
# 539 "lib/parser/parser.mly"
            _2
# 4629 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 539 "lib/parser/parser.mly"
    e
# 4633 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4637 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 540 "lib/parser/parser.mly"
    ( mk_expr (ECall (
        mk_expr (EVar (mk_ident "__or_fail__" _startpos)) _startpos,
        [e; alt])) _startpos )
# 4644 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4648 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 535 "lib/parser/parser.mly"
                       alt
# 4653 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4657 "q1.ml"
  )) (_startpos_alt_ : Lexing.position) (_endpos_alt_ : Lexing.position) (_startofs_alt_ : int) (_endofs_alt_ : int) (_loc_alt_ : Lexing.position * Lexing.position) (
# 535 "lib/parser/parser.mly"
            _2
# 4661 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 535 "lib/parser/parser.mly"
    e
# 4665 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4669 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 536 "lib/parser/parser.mly"
    ( mk_expr (ECall (
        mk_expr (EVar (mk_ident "__or_return__" _startpos)) _startpos,
        [e; alt])) _startpos )
# 4676 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4680 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 531 "lib/parser/parser.mly"
                                      _4
# 4685 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 531 "lib/parser/parser.mly"
                    args
# 4689 "q1.ml"
   : 'tv_tlist_expr_) (_startpos_args_ : Lexing.position) (_endpos_args_ : Lexing.position) (_startofs_args_ : int) (_endofs_args_ : int) (_loc_args_ : Lexing.position * Lexing.position) (
# 531 "lib/parser/parser.mly"
            _2
# 4693 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 531 "lib/parser/parser.mly"
    f
# 4697 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4701 "q1.ml"
  )) (_startpos_f_ : Lexing.position) (_endpos_f_ : Lexing.position) (_startofs_f_ : int) (_endofs_f_ : int) (_loc_f_ : Lexing.position * Lexing.position) ->
    ((
# 532 "lib/parser/parser.mly"
    ( mk_expr (ECall (f, args)) _startpos )
# 4706 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4710 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 529 "lib/parser/parser.mly"
                                _4
# 4715 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 529 "lib/parser/parser.mly"
                      idx
# 4719 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4723 "q1.ml"
  )) (_startpos_idx_ : Lexing.position) (_endpos_idx_ : Lexing.position) (_startofs_idx_ : int) (_endofs_idx_ : int) (_loc_idx_ : Lexing.position * Lexing.position) (
# 529 "lib/parser/parser.mly"
            _2
# 4727 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 529 "lib/parser/parser.mly"
    e
# 4731 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4735 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 530 "lib/parser/parser.mly"
    ( mk_expr (EIndex (e, idx)) _startpos )
# 4740 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4744 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 527 "lib/parser/parser.mly"
                 name
# 4749 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 527 "lib/parser/parser.mly"
            _2
# 4753 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 527 "lib/parser/parser.mly"
    e
# 4757 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4761 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    ((
# 528 "lib/parser/parser.mly"
    ( mk_expr (EField (e, name)) _startpos )
# 4766 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4770 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 524 "lib/parser/parser.mly"
          e
# 4775 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4779 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 524 "lib/parser/parser.mly"
   _1
# 4783 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 524 "lib/parser/parser.mly"
                                 ( mk_expr (ERef e)             _startpos )
# 4788 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4792 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 523 "lib/parser/parser.mly"
          e
# 4797 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4801 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 523 "lib/parser/parser.mly"
   _1
# 4805 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 523 "lib/parser/parser.mly"
                                 ( mk_expr (EDeref e)          _startpos )
# 4810 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4814 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 522 "lib/parser/parser.mly"
          e
# 4819 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4823 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 522 "lib/parser/parser.mly"
   _1
# 4827 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 522 "lib/parser/parser.mly"
                                 ( mk_expr (EUnop (BitNot, e)) _startpos )
# 4832 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4836 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 521 "lib/parser/parser.mly"
          e
# 4841 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4845 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 521 "lib/parser/parser.mly"
   _1
# 4849 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 521 "lib/parser/parser.mly"
                                 ( mk_expr (EUnop (Not,    e)) _startpos )
# 4854 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4858 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 520 "lib/parser/parser.mly"
          e
# 4863 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4867 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 520 "lib/parser/parser.mly"
   _1
# 4871 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    ((
# 520 "lib/parser/parser.mly"
                                 ( mk_expr (EUnop (Neg,    e)) _startpos )
# 4876 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4880 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 517 "lib/parser/parser.mly"
                     r
# 4885 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4889 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 517 "lib/parser/parser.mly"
            _2
# 4893 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 517 "lib/parser/parser.mly"
    l
# 4897 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4901 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 517 "lib/parser/parser.mly"
                               ( desugar_aug_assign l Div r _startpos )
# 4906 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4910 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 516 "lib/parser/parser.mly"
                     r
# 4915 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4919 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 516 "lib/parser/parser.mly"
            _2
# 4923 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 516 "lib/parser/parser.mly"
    l
# 4927 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4931 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 516 "lib/parser/parser.mly"
                               ( desugar_aug_assign l Mul r _startpos )
# 4936 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4940 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 515 "lib/parser/parser.mly"
                     r
# 4945 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4949 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 515 "lib/parser/parser.mly"
            _2
# 4953 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 515 "lib/parser/parser.mly"
    l
# 4957 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4961 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 515 "lib/parser/parser.mly"
                               ( desugar_aug_assign l Sub r _startpos )
# 4966 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4970 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 514 "lib/parser/parser.mly"
                     r
# 4975 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4979 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 514 "lib/parser/parser.mly"
            _2
# 4983 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 514 "lib/parser/parser.mly"
    l
# 4987 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 4991 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 514 "lib/parser/parser.mly"
                               ( desugar_aug_assign l Add r _startpos )
# 4996 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5000 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 513 "lib/parser/parser.mly"
                     r
# 5005 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5009 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 513 "lib/parser/parser.mly"
            _2
# 5013 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 513 "lib/parser/parser.mly"
    l
# 5017 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5021 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 513 "lib/parser/parser.mly"
                               ( mk_expr (EAssign (l, r))                            _startpos )
# 5026 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5030 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 510 "lib/parser/parser.mly"
                     r
# 5035 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5039 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 510 "lib/parser/parser.mly"
            _2
# 5043 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 510 "lib/parser/parser.mly"
    l
# 5047 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5051 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 510 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Mod,     l, r)) _startpos )
# 5056 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5060 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 509 "lib/parser/parser.mly"
                     r
# 5065 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5069 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 509 "lib/parser/parser.mly"
            _2
# 5073 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 509 "lib/parser/parser.mly"
    l
# 5077 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5081 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 509 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Div,     l, r)) _startpos )
# 5086 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5090 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 508 "lib/parser/parser.mly"
                     r
# 5095 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5099 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 508 "lib/parser/parser.mly"
            _2
# 5103 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 508 "lib/parser/parser.mly"
    l
# 5107 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5111 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 508 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Mul,     l, r)) _startpos )
# 5116 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5120 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 507 "lib/parser/parser.mly"
                     r
# 5125 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5129 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 507 "lib/parser/parser.mly"
            _2
# 5133 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 507 "lib/parser/parser.mly"
    l
# 5137 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5141 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 507 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Sub,     l, r)) _startpos )
# 5146 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5150 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 506 "lib/parser/parser.mly"
                     r
# 5155 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5159 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 506 "lib/parser/parser.mly"
            _2
# 5163 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 506 "lib/parser/parser.mly"
    l
# 5167 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5171 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 506 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Add,     l, r)) _startpos )
# 5176 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5180 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 505 "lib/parser/parser.mly"
                     r
# 5185 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5189 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 505 "lib/parser/parser.mly"
            _2
# 5193 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 505 "lib/parser/parser.mly"
    l
# 5197 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5201 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 505 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Shr,     l, r)) _startpos )
# 5206 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5210 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 504 "lib/parser/parser.mly"
                     r
# 5215 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5219 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 504 "lib/parser/parser.mly"
            _2
# 5223 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 504 "lib/parser/parser.mly"
    l
# 5227 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5231 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 504 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Shl,     l, r)) _startpos )
# 5236 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5240 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 503 "lib/parser/parser.mly"
                     r
# 5245 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5249 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 503 "lib/parser/parser.mly"
            _2
# 5253 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 503 "lib/parser/parser.mly"
    l
# 5257 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5261 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 503 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (BitAnd,  l, r)) _startpos )
# 5266 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5270 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 502 "lib/parser/parser.mly"
                     r
# 5275 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5279 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 502 "lib/parser/parser.mly"
            _2
# 5283 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 502 "lib/parser/parser.mly"
    l
# 5287 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5291 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 502 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (BitXor,  l, r)) _startpos )
# 5296 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5300 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 501 "lib/parser/parser.mly"
                     r
# 5305 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5309 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 501 "lib/parser/parser.mly"
            _2
# 5313 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 501 "lib/parser/parser.mly"
    l
# 5317 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5321 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 501 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (BitOr,   l, r)) _startpos )
# 5326 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5330 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 500 "lib/parser/parser.mly"
                     r
# 5335 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5339 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 500 "lib/parser/parser.mly"
            _2
# 5343 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 500 "lib/parser/parser.mly"
    l
# 5347 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5351 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 500 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Ge,      l, r)) _startpos )
# 5356 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5360 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 499 "lib/parser/parser.mly"
                     r
# 5365 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5369 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 499 "lib/parser/parser.mly"
            _2
# 5373 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 499 "lib/parser/parser.mly"
    l
# 5377 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5381 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 499 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Gt,      l, r)) _startpos )
# 5386 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5390 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 498 "lib/parser/parser.mly"
                     r
# 5395 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5399 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 498 "lib/parser/parser.mly"
            _2
# 5403 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 498 "lib/parser/parser.mly"
    l
# 5407 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5411 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 498 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Le,      l, r)) _startpos )
# 5416 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5420 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 497 "lib/parser/parser.mly"
                     r
# 5425 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5429 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 497 "lib/parser/parser.mly"
            _2
# 5433 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 497 "lib/parser/parser.mly"
    l
# 5437 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5441 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 497 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Lt,      l, r)) _startpos )
# 5446 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5450 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 496 "lib/parser/parser.mly"
                     r
# 5455 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5459 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 496 "lib/parser/parser.mly"
            _2
# 5463 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 496 "lib/parser/parser.mly"
    l
# 5467 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5471 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 496 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Ne,      l, r)) _startpos )
# 5476 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5480 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 495 "lib/parser/parser.mly"
                     r
# 5485 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5489 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 495 "lib/parser/parser.mly"
            _2
# 5493 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 495 "lib/parser/parser.mly"
    l
# 5497 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5501 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 495 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Eq,      l, r)) _startpos )
# 5506 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5510 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 494 "lib/parser/parser.mly"
                     r
# 5515 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5519 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 494 "lib/parser/parser.mly"
            _2
# 5523 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 494 "lib/parser/parser.mly"
    l
# 5527 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5531 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 494 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (And,     l, r)) _startpos )
# 5536 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5540 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 493 "lib/parser/parser.mly"
                     r
# 5545 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5549 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 493 "lib/parser/parser.mly"
            _2
# 5553 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 493 "lib/parser/parser.mly"
    l
# 5557 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5561 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 493 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Or,      l, r)) _startpos )
# 5566 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5570 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 492 "lib/parser/parser.mly"
                     r
# 5575 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5579 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 492 "lib/parser/parser.mly"
            _2
# 5583 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 492 "lib/parser/parser.mly"
    l
# 5587 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5591 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 492 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Implies, l, r)) _startpos )
# 5596 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5600 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 491 "lib/parser/parser.mly"
                     r
# 5605 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5609 "q1.ml"
  )) (_startpos_r_ : Lexing.position) (_endpos_r_ : Lexing.position) (_startofs_r_ : int) (_endofs_r_ : int) (_loc_r_ : Lexing.position * Lexing.position) (
# 491 "lib/parser/parser.mly"
            _2
# 5613 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 491 "lib/parser/parser.mly"
    l
# 5617 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5621 "q1.ml"
  )) (_startpos_l_ : Lexing.position) (_endpos_l_ : Lexing.position) (_startofs_l_ : int) (_endofs_l_ : int) (_loc_l_ : Lexing.position * Lexing.position) ->
    ((
# 491 "lib/parser/parser.mly"
                               ( mk_expr (EBinop (Iff,     l, r)) _startpos )
# 5626 "q1.ml"
     : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5630 "q1.ml"
    )) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 288 "lib/parser/parser.mly"
                                          _4
# 5635 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 288 "lib/parser/parser.mly"
                        fields
# 5639 "q1.ml"
   : 'tv_tlist_ty_) (_startpos_fields_ : Lexing.position) (_endpos_fields_ : Lexing.position) (_startofs_fields_ : int) (_endofs_fields_ : int) (_loc_fields_ : Lexing.position * Lexing.position) (
# 288 "lib/parser/parser.mly"
                _2
# 5643 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 288 "lib/parser/parser.mly"
    name
# 5647 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 289 "lib/parser/parser.mly"
    ( (name, fields) )
# 5652 "q1.ml"
     : 'tv_enum_variant) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 286 "lib/parser/parser.mly"
    name
# 5657 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 287 "lib/parser/parser.mly"
    ( (name, []) )
# 5662 "q1.ml"
     : 'tv_enum_variant) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 284 "lib/parser/parser.mly"
                                                 _5
# 5667 "q1.ml"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 284 "lib/parser/parser.mly"
                                          _4
# 5671 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 284 "lib/parser/parser.mly"
                        fields
# 5675 "q1.ml"
   : 'tv_tlist_ty_) (_startpos_fields_ : Lexing.position) (_endpos_fields_ : Lexing.position) (_startofs_fields_ : int) (_endofs_fields_ : int) (_loc_fields_ : Lexing.position * Lexing.position) (
# 284 "lib/parser/parser.mly"
                _2
# 5679 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 284 "lib/parser/parser.mly"
    name
# 5683 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 285 "lib/parser/parser.mly"
    ( (name, fields) )
# 5688 "q1.ml"
     : 'tv_enum_variant) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 282 "lib/parser/parser.mly"
                _2
# 5693 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 282 "lib/parser/parser.mly"
    name
# 5697 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 283 "lib/parser/parser.mly"
    ( (name, []) )
# 5702 "q1.ml"
     : 'tv_enum_variant) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 272 "lib/parser/parser.mly"
                                        _6
# 5707 "q1.ml"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) (
# 272 "lib/parser/parser.mly"
           variants
# 5711 "q1.ml"
   : 'tv_list_enum_variant_) (_startpos_variants_ : Lexing.position) (_endpos_variants_ : Lexing.position) (_startofs_variants_ : int) (_endofs_variants_ : int) (_loc_variants_ : Lexing.position * Lexing.position) (
# 271 "lib/parser/parser.mly"
                                          _4
# 5716 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 271 "lib/parser/parser.mly"
                      params
# 5720 "q1.ml"
   : 'tv_kind_params) (_startpos_params_ : Lexing.position) (_endpos_params_ : Lexing.position) (_startofs_params_ : int) (_endofs_params_ : int) (_loc_params_ : Lexing.position * Lexing.position) (
# 271 "lib/parser/parser.mly"
         name
# 5724 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 271 "lib/parser/parser.mly"
   _1
# 5728 "q1.ml"
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
# 5739 "q1.ml"
     : 'tv_enum_def) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 202 "lib/parser/parser.mly"
            p
# 5744 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 5748 "q1.ml"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 202 "lib/parser/parser.mly"
   _1
# 5752 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 202 "lib/parser/parser.mly"
                     ( p )
# 5757 "q1.ml"
     : 'tv_ensures_clause) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 644 "lib/parser/parser.mly"
    e
# 5762 "q1.ml"
   : 'tv_if_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 644 "lib/parser/parser.mly"
                   ( e )
# 5767 "q1.ml"
     : 'tv_else_branch) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 643 "lib/parser/parser.mly"
    e
# 5772 "q1.ml"
   : 'tv_block_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 643 "lib/parser/parser.mly"
                   ( e )
# 5777 "q1.ml"
     : 'tv_else_branch) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 205 "lib/parser/parser.mly"
              p
# 5782 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 5786 "q1.ml"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 205 "lib/parser/parser.mly"
   _1
# 5790 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 205 "lib/parser/parser.mly"
                       ( p )
# 5795 "q1.ml"
     : 'tv_decreases_clause) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 629 "lib/parser/parser.mly"
                  rest
# 5800 "q1.ml"
   : 'tv_block_stmts) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 629 "lib/parser/parser.mly"
            _2
# 5804 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 629 "lib/parser/parser.mly"
   _1
# 5808 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 630 "lib/parser/parser.mly"
    ( let (ss, ret) = rest in (mk_stmt SContinue _startpos :: ss, ret) )
# 5813 "q1.ml"
     : 'tv_block_stmts) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 627 "lib/parser/parser.mly"
               rest
# 5818 "q1.ml"
   : 'tv_block_stmts) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 627 "lib/parser/parser.mly"
         _2
# 5822 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 627 "lib/parser/parser.mly"
   _1
# 5826 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 628 "lib/parser/parser.mly"
    ( let (ss, ret) = rest in (mk_stmt SBreak _startpos :: ss, ret) )
# 5831 "q1.ml"
     : 'tv_block_stmts) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 625 "lib/parser/parser.mly"
                     rest
# 5836 "q1.ml"
   : 'tv_block_stmts) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 625 "lib/parser/parser.mly"
               _6
# 5840 "q1.ml"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) ((
# 625 "lib/parser/parser.mly"
       e
# 5844 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5848 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 624 "lib/parser/parser.mly"
                                                      _4
# 5853 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 624 "lib/parser/parser.mly"
                     ann
# 5857 "q1.ml"
   : 'tv_option_preceded_COLON_ty__) (_startpos_ann_ : Lexing.position) (_endpos_ann_ : Lexing.position) (_startofs_ann_ : int) (_endofs_ann_ : int) (_loc_ann_ : Lexing.position * Lexing.position) (
# 624 "lib/parser/parser.mly"
        name
# 5861 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 624 "lib/parser/parser.mly"
   _1
# 5865 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 626 "lib/parser/parser.mly"
    ( let (ss, ret) = rest in (mk_stmt (SLet (name, ann, e, Unr)) _startpos :: ss, ret) )
# 5870 "q1.ml"
     : 'tv_block_stmts) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 622 "lib/parser/parser.mly"
                     rest
# 5875 "q1.ml"
   : 'tv_block_stmts) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 622 "lib/parser/parser.mly"
               _7
# 5879 "q1.ml"
   : unit) (_startpos__7_ : Lexing.position) (_endpos__7_ : Lexing.position) (_startofs__7_ : int) (_endofs__7_ : int) (_loc__7_ : Lexing.position * Lexing.position) ((
# 622 "lib/parser/parser.mly"
       e
# 5883 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5887 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 621 "lib/parser/parser.mly"
                                                                      _5
# 5892 "q1.ml"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) (
# 621 "lib/parser/parser.mly"
                                     ann
# 5896 "q1.ml"
   : 'tv_option_preceded_COLON_ty__) (_startpos_ann_ : Lexing.position) (_endpos_ann_ : Lexing.position) (_startofs_ann_ : int) (_endofs_ann_ : int) (_loc_ann_ : Lexing.position * Lexing.position) (
# 621 "lib/parser/parser.mly"
                        name
# 5900 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 621 "lib/parser/parser.mly"
        lin
# 5904 "q1.ml"
   : 'tv_linearity) (_startpos_lin_ : Lexing.position) (_endpos_lin_ : Lexing.position) (_startofs_lin_ : int) (_endofs_lin_ : int) (_loc_lin_ : Lexing.position * Lexing.position) (
# 621 "lib/parser/parser.mly"
   _1
# 5908 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 623 "lib/parser/parser.mly"
    ( let (ss, ret) = rest in (mk_stmt (SLet (name, ann, e, lin)) _startpos :: ss, ret) )
# 5913 "q1.ml"
     : 'tv_block_stmts) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 619 "lib/parser/parser.mly"
                  rest
# 5918 "q1.ml"
   : 'tv_block_stmts) (_startpos_rest_ : Lexing.position) (_endpos_rest_ : Lexing.position) (_startofs_rest_ : int) (_endofs_rest_ : int) (_loc_rest_ : Lexing.position * Lexing.position) (
# 619 "lib/parser/parser.mly"
            _2
# 5922 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 619 "lib/parser/parser.mly"
    e
# 5926 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5930 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 620 "lib/parser/parser.mly"
    ( let (ss, ret) = rest in (mk_stmt (SExpr e) _startpos :: ss, ret) )
# 5935 "q1.ml"
     : 'tv_block_stmts) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 617 "lib/parser/parser.mly"
    e
# 5940 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 5944 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 618 "lib/parser/parser.mly"
    ( ([], Some e) )
# 5949 "q1.ml"
     : 'tv_block_stmts) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ->
    (
# 616 "lib/parser/parser.mly"
    ( ([], None) )
# 5955 "q1.ml"
     : 'tv_block_stmts) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 604 "lib/parser/parser.mly"
                              _3
# 5960 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 604 "lib/parser/parser.mly"
           stmts
# 5964 "q1.ml"
   : 'tv_block_stmts) (_startpos_stmts_ : Lexing.position) (_endpos_stmts_ : Lexing.position) (_startofs_stmts_ : int) (_endofs_stmts_ : int) (_loc_stmts_ : Lexing.position * Lexing.position) (
# 604 "lib/parser/parser.mly"
   _1
# 5968 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 605 "lib/parser/parser.mly"
    (
      let (ss, ret) = stmts in
      mk_expr (EBlock (ss, ret)) _startpos
    )
# 5976 "q1.ml"
     : 'tv_block_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 191 "lib/parser/parser.mly"
                                                                                _7
# 5981 "q1.ml"
   : unit) (_startpos__7_ : Lexing.position) (_endpos__7_ : Lexing.position) (_startofs__7_ : int) (_endofs__7_ : int) (_loc__7_ : Lexing.position * Lexing.position) (
# 191 "lib/parser/parser.mly"
                                                                         _6
# 5985 "q1.ml"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) (
# 191 "lib/parser/parser.mly"
                                      args
# 5989 "q1.ml"
   : 'tv_separated_list_COMMA_IDENT_) (_startpos_args_ : Lexing.position) (_endpos_args_ : Lexing.position) (_startofs_args_ : int) (_endofs_args_ : int) (_loc_args_ : Lexing.position * Lexing.position) (
# 191 "lib/parser/parser.mly"
                              _4
# 5993 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 191 "lib/parser/parser.mly"
                  name
# 5997 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 191 "lib/parser/parser.mly"
        _2
# 6001 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 191 "lib/parser/parser.mly"
   _1
# 6005 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 192 "lib/parser/parser.mly"
    ( { attr_name = name.name; attr_args = args } )
# 6010 "q1.ml"
     : 'tv_attr_clause) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 189 "lib/parser/parser.mly"
                              _4
# 6015 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) (
# 189 "lib/parser/parser.mly"
                  name
# 6019 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) (
# 189 "lib/parser/parser.mly"
        _2
# 6023 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 189 "lib/parser/parser.mly"
   _1
# 6027 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 190 "lib/parser/parser.mly"
    ( { attr_name = name.name; attr_args = [] } )
# 6032 "q1.ml"
     : 'tv_attr_clause) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 596 "lib/parser/parser.mly"
                                   _5
# 6037 "q1.ml"
   : unit) (_startpos__5_ : Lexing.position) (_endpos__5_ : Lexing.position) (_startofs__5_ : int) (_endofs__5_ : int) (_loc__5_ : Lexing.position * Lexing.position) ((
# 596 "lib/parser/parser.mly"
                           n
# 6041 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 6045 "q1.ml"
  )) (_startpos_n_ : Lexing.position) (_endpos_n_ : Lexing.position) (_startofs_n_ : int) (_endofs_n_ : int) (_loc_n_ : Lexing.position * Lexing.position) (
# 596 "lib/parser/parser.mly"
                     _3
# 6049 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 596 "lib/parser/parser.mly"
             v
# 6053 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 6057 "q1.ml"
  )) (_startpos_v_ : Lexing.position) (_endpos_v_ : Lexing.position) (_startofs_v_ : int) (_endofs_v_ : int) (_loc_v_ : Lexing.position * Lexing.position) (
# 596 "lib/parser/parser.mly"
   _1
# 6061 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 597 "lib/parser/parser.mly"
    ( mk_expr (EArrayRepeat (v, n)) _startpos )
# 6066 "q1.ml"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 594 "lib/parser/parser.mly"
                                                _3
# 6071 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) (
# 594 "lib/parser/parser.mly"
             elems
# 6075 "q1.ml"
   : 'tv_separated_list_COMMA_expr_) (_startpos_elems_ : Lexing.position) (_endpos_elems_ : Lexing.position) (_startofs_elems_ : int) (_endofs_elems_ : int) (_loc_elems_ : Lexing.position * Lexing.position) (
# 594 "lib/parser/parser.mly"
   _1
# 6079 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 595 "lib/parser/parser.mly"
    ( mk_expr (EArrayLit elems) _startpos )
# 6084 "q1.ml"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 591 "lib/parser/parser.mly"
                   _3
# 6089 "q1.ml"
   : unit) (_startpos__3_ : Lexing.position) (_endpos__3_ : Lexing.position) (_startofs__3_ : int) (_endofs__3_ : int) (_loc__3_ : Lexing.position * Lexing.position) ((
# 591 "lib/parser/parser.mly"
           e
# 6093 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 6097 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) (
# 591 "lib/parser/parser.mly"
   _1
# 6101 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 592 "lib/parser/parser.mly"
    ( e )
# 6106 "q1.ml"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 589 "lib/parser/parser.mly"
    name
# 6111 "q1.ml"
   : 'tv_ident) (_startpos_name_ : Lexing.position) (_endpos_name_ : Lexing.position) (_startofs_name_ : int) (_endofs_name_ : int) (_loc_name_ : Lexing.position * Lexing.position) ->
    (
# 590 "lib/parser/parser.mly"
    ( mk_expr (EVar name) _startpos )
# 6116 "q1.ml"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 587 "lib/parser/parser.mly"
          _2
# 6121 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 587 "lib/parser/parser.mly"
   _1
# 6125 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 588 "lib/parser/parser.mly"
    ( mk_expr (ELit LUnit) _startpos )
# 6130 "q1.ml"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 585 "lib/parser/parser.mly"
   _1
# 6135 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 586 "lib/parser/parser.mly"
    ( mk_expr (ELit (LBool false)) _startpos )
# 6140 "q1.ml"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 583 "lib/parser/parser.mly"
   _1
# 6145 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 584 "lib/parser/parser.mly"
    ( mk_expr (ELit (LBool true)) _startpos )
# 6150 "q1.ml"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 581 "lib/parser/parser.mly"
    s
# 6155 "q1.ml"
   : (
# 18 "lib/parser/parser.mly"
       (string)
# 6159 "q1.ml"
  )) (_startpos_s_ : Lexing.position) (_endpos_s_ : Lexing.position) (_startofs_s_ : int) (_endofs_s_ : int) (_loc_s_ : Lexing.position * Lexing.position) ->
    (
# 582 "lib/parser/parser.mly"
    ( mk_expr (ELit (LStr s)) _startpos )
# 6164 "q1.ml"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 579 "lib/parser/parser.mly"
    f
# 6169 "q1.ml"
   : (
# 17 "lib/parser/parser.mly"
       (float)
# 6173 "q1.ml"
  )) (_startpos_f_ : Lexing.position) (_endpos_f_ : Lexing.position) (_startofs_f_ : int) (_endofs_f_ : int) (_loc_f_ : Lexing.position * Lexing.position) ->
    (
# 580 "lib/parser/parser.mly"
    ( mk_expr (ELit (LFloat (f, None))) _startpos )
# 6178 "q1.ml"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 577 "lib/parser/parser.mly"
    ns
# 6183 "q1.ml"
   : (
# 16 "lib/parser/parser.mly"
       (int64 * string)
# 6187 "q1.ml"
  )) (_startpos_ns_ : Lexing.position) (_endpos_ns_ : Lexing.position) (_startofs_ns_ : int) (_endofs_ns_ : int) (_loc_ns_ : Lexing.position * Lexing.position) ->
    (
# 578 "lib/parser/parser.mly"
    ( let (n, s) = ns in mk_expr (ELit (LInt (n, Some (prim_of_suffix s)))) _startpos )
# 6192 "q1.ml"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 575 "lib/parser/parser.mly"
    n
# 6197 "q1.ml"
   : (
# 15 "lib/parser/parser.mly"
       (int64)
# 6201 "q1.ml"
  )) (_startpos_n_ : Lexing.position) (_endpos_n_ : Lexing.position) (_startofs_n_ : int) (_endofs_n_ : int) (_loc_n_ : Lexing.position * Lexing.position) ->
    (
# 576 "lib/parser/parser.mly"
    ( mk_expr (ELit (LInt (n, None))) _startpos )
# 6206 "q1.ml"
     : 'tv_atom_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 744 "lib/parser/parser.mly"
                                                      _6
# 6211 "q1.ml"
   : unit) (_startpos__6_ : Lexing.position) (_endpos__6_ : Lexing.position) (_startofs__6_ : int) (_endofs__6_ : int) (_loc__6_ : Lexing.position * Lexing.position) (
# 744 "lib/parser/parser.mly"
                                  ctx
# 6215 "q1.ml"
   : 'tv_option_STRING_) (_startpos_ctx_ : Lexing.position) (_endpos_ctx_ : Lexing.position) (_startofs_ctx_ : int) (_endofs_ctx_ : int) (_loc_ctx_ : Lexing.position * Lexing.position) (
# 744 "lib/parser/parser.mly"
                          _4
# 6219 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 744 "lib/parser/parser.mly"
                  p
# 6223 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 6227 "q1.ml"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 744 "lib/parser/parser.mly"
          _2
# 6231 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 744 "lib/parser/parser.mly"
   _1
# 6235 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 745 "lib/parser/parser.mly"
    (
      {
        as_pred    = p;
        as_context = ctx;
        as_loc     = mk_loc _startpos;
      }
    )
# 6246 "q1.ml"
     : 'tv_assume_in_proof) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 792 "lib/parser/parser.mly"
                                  ctx
# 6251 "q1.ml"
   : 'tv_option_STRING_) (_startpos_ctx_ : Lexing.position) (_endpos_ctx_ : Lexing.position) (_startofs_ctx_ : int) (_endofs_ctx_ : int) (_loc_ctx_ : Lexing.position * Lexing.position) (
# 792 "lib/parser/parser.mly"
                          _4
# 6255 "q1.ml"
   : unit) (_startpos__4_ : Lexing.position) (_endpos__4_ : Lexing.position) (_startofs__4_ : int) (_endofs__4_ : int) (_loc__4_ : Lexing.position * Lexing.position) ((
# 792 "lib/parser/parser.mly"
                  p
# 6259 "q1.ml"
   : 'tv_pred) : (
# 118 "lib/parser/parser.mly"
       (Ast.pred)
# 6263 "q1.ml"
  )) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) (
# 792 "lib/parser/parser.mly"
          _2
# 6267 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 792 "lib/parser/parser.mly"
   _1
# 6271 "q1.ml"
   : unit) (_startpos__1_ : Lexing.position) (_endpos__1_ : Lexing.position) (_startofs__1_ : int) (_endofs__1_ : int) (_loc__1_ : Lexing.position * Lexing.position) ->
    (
# 793 "lib/parser/parser.mly"
    ( mk_expr (EAssume (p, ctx)) _startpos )
# 6276 "q1.ml"
     : 'tv_assume_expr) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) ((
# 665 "lib/parser/parser.mly"
    e
# 6281 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 6285 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 665 "lib/parser/parser.mly"
                   ( e )
# 6290 "q1.ml"
     : 'tv_arm_body) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 664 "lib/parser/parser.mly"
            _2
# 6295 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) ((
# 664 "lib/parser/parser.mly"
    e
# 6299 "q1.ml"
   : 'tv_expr) : (
# 116 "lib/parser/parser.mly"
       (Ast.expr)
# 6303 "q1.ml"
  )) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 664 "lib/parser/parser.mly"
                   ( e )
# 6308 "q1.ml"
     : 'tv_arm_body) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 663 "lib/parser/parser.mly"
                  _2
# 6313 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 663 "lib/parser/parser.mly"
    e
# 6317 "q1.ml"
   : 'tv_block_expr) (_startpos_e_ : Lexing.position) (_endpos_e_ : Lexing.position) (_startofs_e_ : int) (_endofs_e_ : int) (_loc_e_ : Lexing.position * Lexing.position) ->
    (
# 663 "lib/parser/parser.mly"
                         ( e )
# 6322 "q1.ml"
     : 'tv_arm_body) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 660 "lib/parser/parser.mly"
                          p2
# 6327 "q1.ml"
   : 'tv_pattern) (_startpos_p2_ : Lexing.position) (_endpos_p2_ : Lexing.position) (_startofs_p2_ : int) (_endofs_p2_ : int) (_loc_p2_ : Lexing.position * Lexing.position) (
# 660 "lib/parser/parser.mly"
                    _2
# 6331 "q1.ml"
   : unit) (_startpos__2_ : Lexing.position) (_endpos__2_ : Lexing.position) (_startofs__2_ : int) (_endofs__2_ : int) (_loc__2_ : Lexing.position * Lexing.position) (
# 660 "lib/parser/parser.mly"
    p1
# 6335 "q1.ml"
   : 'tv_alt_pattern) (_startpos_p1_ : Lexing.position) (_endpos_p1_ : Lexing.position) (_startofs_p1_ : int) (_endofs_p1_ : int) (_loc_p1_ : Lexing.position * Lexing.position) ->
    (
# 660 "lib/parser/parser.mly"
                                            ( POr (p1, p2) )
# 6340 "q1.ml"
     : 'tv_alt_pattern) in
  let _ = fun (_eRR : exn) (_startpos : Lexing.position) (_endpos : Lexing.position) (_endpos__0_ : Lexing.position) (_symbolstartpos : Lexing.position) (_startofs : int) (_endofs : int) (_endofs__0_ : int) (_symbolstartofs : int) (_sloc : Lexing.position * Lexing.position) (_loc : Lexing.position * Lexing.position) (
# 659 "lib/parser/parser.mly"
    p
# 6345 "q1.ml"
   : 'tv_pattern) (_startpos_p_ : Lexing.position) (_endpos_p_ : Lexing.position) (_startofs_p_ : int) (_endofs_p_ : int) (_loc_p_ : Lexing.position * Lexing.position) ->
    (
# 659 "lib/parser/parser.mly"
                                             ( p )
# 6350 "q1.ml"
     : 'tv_alt_pattern) in
  (raise Not_found : 'tv_type_params * 'tv_type_def * 'tv_type_args * 'tv_ty * 'tv_tlist_ty_ * 'tv_tlist_struct_field_init_ * 'tv_tlist_param_ * 'tv_tlist_expr_ * 'tv_struct_field_init * 'tv_struct_field * 'tv_struct_def * 'tv_stmt * 'tv_separated_nonempty_list_DCOLON_ident_ * 'tv_separated_nonempty_list_COMMA_ty_ * 'tv_separated_nonempty_list_COMMA_proof_term_ * 'tv_separated_nonempty_list_COMMA_pred_ * 'tv_separated_nonempty_list_COMMA_pattern_ * 'tv_separated_nonempty_list_COMMA_kind_param_ * 'tv_separated_nonempty_list_COMMA_ident_ * 'tv_separated_nonempty_list_COMMA_expr_ * 'tv_separated_nonempty_list_COMMA_IDENT_ * 'tv_separated_list_COMMA_proof_term_ * 'tv_separated_list_COMMA_pred_ * 'tv_separated_list_COMMA_pattern_ * 'tv_separated_list_COMMA_expr_ * 'tv_separated_list_COMMA_IDENT_ * 'tv_return_expr * 'tv_requires_clause * 'tv_raw_expr * 'tv_proof_term * 'tv_proof_expr * 'tv_proof_contents * 'tv_program * 'tv_prim_ty_kw * 'tv_pred * 'tv_preceded_INVARIANT_pred_ * 'tv_preceded_IF_pred_ * 'tv_preceded_ELSE_else_branch_ * 'tv_preceded_DECREASES_pred_ * 'tv_preceded_COLON_ty_ * 'tv_preceded_ARROW_ty_ * 'tv_pattern * 'tv_param * 'tv_option_preceded_INVARIANT_pred__ * 'tv_option_preceded_IF_pred__ * 'tv_option_preceded_ELSE_else_branch__ * 'tv_option_preceded_DECREASES_pred__ * 'tv_option_preceded_COLON_ty__ * 'tv_option_preceded_ARROW_ty__ * 'tv_option_extern_link_ * 'tv_option_expr_ * 'tv_option_decreases_clause_ * 'tv_option_STRING_ * 'tv_match_expr * 'tv_match_arm * 'tv_loption_separated_nonempty_list_COMMA_proof_term__ * 'tv_loption_separated_nonempty_list_COMMA_pred__ * 'tv_loption_separated_nonempty_list_COMMA_pattern__ * 'tv_loption_separated_nonempty_list_COMMA_expr__ * 'tv_loption_separated_nonempty_list_COMMA_IDENT__ * 'tv_loop_expr * 'tv_list_struct_field_ * 'tv_list_stmt_ * 'tv_list_requires_clause_ * 'tv_list_proof_term_ * 'tv_list_match_arm_ * 'tv_list_lemma_def_ * 'tv_list_item_ * 'tv_list_invariant_clause_ * 'tv_list_enum_variant_ * 'tv_list_ensures_clause_ * 'tv_list_attr_clause_ * 'tv_list_assume_in_proof_ * 'tv_linearity * 'tv_lemma_def * 'tv_kind_params * 'tv_kind_param * 'tv_item * 'tv_invariant_clause * 'tv_impl_def * 'tv_if_expr * 'tv_ident * 'tv_fn_def * 'tv_fn_body * 'tv_extern_link * 'tv_extern_def * 'tv_expr * 'tv_enum_variant * 'tv_enum_def * 'tv_ensures_clause * 'tv_else_branch * 'tv_decreases_clause * 'tv_block_stmts * 'tv_block_expr * 'tv_attr_clause * 'tv_atom_expr * 'tv_assume_in_proof * 'tv_assume_expr * 'tv_arm_body * 'tv_alt_pattern)

and menhir_end_marker =
  0

# 269 "<standard.mly>"
  

# 6360 "q1.ml"
