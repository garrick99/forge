exception Error
type token =
    WITNESS
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
  | STRING of string
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
  | INT_SUFF of (int64 * string)
  | INT of int64
  | INDUCTION
  | IN
  | IMPLIES
  | IMPL
  | IFF
  | IF
  | IDENT of string
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
  | FLOAT of float
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
val menhir_begin_marker : int
val xv_type_params : Ast.ident list
val xv_type_def : Ast.type_def
val xv_type_args : Ast.ty list
val xv_ty : Ast.ty
val xv_tlist_ty_ : Ast.ty list
val xv_tlist_struct_field_init_ : (Ast.ident * Ast.expr) list
val xv_tlist_param_ : (Ast.ident * Ast.ty) list
val xv_tlist_expr_ : Ast.expr list
val xv_struct_field_init : Ast.ident * Ast.expr
val xv_struct_field : Ast.ident * Ast.ty
val xv_struct_def : Ast.struct_def
val xv_stmt : Ast.stmt
val xv_separated_nonempty_list_DCOLON_ident_ : Ast.ident list
val xv_separated_nonempty_list_COMMA_ty_ : Ast.ty list
val xv_separated_nonempty_list_COMMA_proof_term_ : Ast.proof_term list
val xv_separated_nonempty_list_COMMA_pred_ : Ast.pred list
val xv_separated_nonempty_list_COMMA_pattern_ : Ast.pattern list
val xv_separated_nonempty_list_COMMA_kind_param_ :
  (Ast.ident * Ast.kind) list
val xv_separated_nonempty_list_COMMA_ident_ : Ast.ident list
val xv_separated_nonempty_list_COMMA_expr_ : Ast.expr list
val xv_separated_nonempty_list_COMMA_IDENT_ : string list
val xv_separated_list_COMMA_proof_term_ : Ast.proof_term list
val xv_separated_list_COMMA_pred_ : Ast.pred list
val xv_separated_list_COMMA_pattern_ : Ast.pattern list
val xv_separated_list_COMMA_expr_ : Ast.expr list
val xv_separated_list_COMMA_IDENT_ : string list
val xv_return_expr : Ast.expr
val xv_requires_clause : Ast.pred
val xv_raw_expr : Ast.expr
val xv_proof_term : Ast.proof_term
val xv_proof_expr : Ast.expr
val xv_proof_contents : Ast.proof_block
val xv_program : Ast.program
val xv_prim_ty_kw : Ast.prim_ty
val xv_pred : Ast.pred
val xv_preceded_INVARIANT_pred_ : Ast.pred
val xv_preceded_IF_pred_ : Ast.pred
val xv_preceded_ELSE_else_branch_ : Ast.expr
val xv_preceded_DECREASES_pred_ : Ast.pred
val xv_preceded_COLON_ty_ : Ast.ty
val xv_preceded_ARROW_ty_ : Ast.ty
val xv_pattern : Ast.pattern
val xv_param : Ast.ident * Ast.ty
val xv_option_preceded_INVARIANT_pred__ : Ast.pred option
val xv_option_preceded_IF_pred__ : Ast.pred option
val xv_option_preceded_ELSE_else_branch__ : Ast.expr option
val xv_option_preceded_DECREASES_pred__ : Ast.pred option
val xv_option_preceded_COLON_ty__ : Ast.ty option
val xv_option_preceded_ARROW_ty__ : Ast.ty option
val xv_option_extern_link_ : string option
val xv_option_expr_ : Ast.expr option
val xv_option_decreases_clause_ : Ast.pred option
val xv_option_STRING_ : string option
val xv_match_expr : Ast.expr
val xv_match_arm : Ast.match_arm
val xv_loption_separated_nonempty_list_COMMA_proof_term__ :
  Ast.proof_term list
val xv_loption_separated_nonempty_list_COMMA_pred__ : Ast.pred list
val xv_loption_separated_nonempty_list_COMMA_pattern__ : Ast.pattern list
val xv_loption_separated_nonempty_list_COMMA_expr__ : Ast.expr list
val xv_loption_separated_nonempty_list_COMMA_IDENT__ : string list
val xv_loop_expr : Ast.expr
val xv_list_struct_field_ : (Ast.ident * Ast.ty) list
val xv_list_stmt_ : Ast.stmt list
val xv_list_requires_clause_ : Ast.pred list
val xv_list_proof_term_ : Ast.proof_term list
val xv_list_match_arm_ : Ast.match_arm list
val xv_list_lemma_def_ : Ast.lemma list
val xv_list_item_ : Ast.item list
val xv_list_invariant_clause_ : Ast.pred list
val xv_list_enum_variant_ : (Ast.ident * Ast.ty list) list
val xv_list_ensures_clause_ : Ast.pred list
val xv_list_attr_clause_ : Ast.attr list
val xv_list_assume_in_proof_ : Ast.assume_stmt list
val xv_linearity : Ast.linearity
val xv_lemma_def : Ast.lemma
val xv_kind_params : (Ast.ident * Ast.kind) list
val xv_kind_param : Ast.ident * Ast.kind
val xv_item : Ast.item
val xv_invariant_clause : Ast.pred
val xv_impl_def : Ast.impl_def
val xv_if_expr : Ast.expr
val xv_ident : Ast.ident
val xv_fn_def : Ast.fn_def
val xv_fn_body : Ast.expr option
val xv_extern_link : string
val xv_extern_def : Ast.extern_def
val xv_expr : Ast.expr
val xv_enum_variant : Ast.ident * Ast.ty list
val xv_enum_def : Ast.enum_def
val xv_ensures_clause : Ast.pred
val xv_else_branch : Ast.expr
val xv_decreases_clause : Ast.pred
val xv_block_stmts : Ast.stmt list * Ast.expr option
val xv_block_expr : Ast.expr
val xv_attr_clause : Ast.attr
val xv_atom_expr : Ast.expr
val xv_assume_in_proof : Ast.assume_stmt
val xv_assume_expr : Ast.expr
val xv_arm_body : Ast.expr
val xv_alt_pattern : Ast.pattern
val menhir_end_marker : int
