%{
(* FORGE Parser — Menhir LR(1) grammar
   Full grammar: types, expressions, statements, proof blocks, contracts *)

open Ast
open Parse_util
open Lexing
%}

(* ------------------------------------------------------------------ *)
(* Token declarations — names must match Token.token constructors      *)
(* --external-tokens Token tells Menhir to use Token.token, not gen.  *)
(* ------------------------------------------------------------------ *)

%token <int64>           INT
%token <int64 * string>  INT_SUFF   (* 42u32, 100i64 *)
%token <float>  FLOAT
%token <string> STRING
%token <string> IDENT

(* Declaration keywords *)
%token FN TYPE STRUCT ENUM IMPL USE EXTERN TASK CHAN
%token SPAN SHARED UNIFORM VARYING KERNEL COALESCED SYNCTHREADS

(* Control flow *)
%token LET MUT RETURN IF ELSE MATCH FOR WHILE LOOP IN BREAK CONTINUE
%token OR_RETURN OR_FAIL

(* Proof keywords *)
%token REQUIRES ENSURES DECREASES INVARIANT
%token PROOF ASSUME LEMMA WITNESS BY AUTO AXIOM SYMM TRANS INDUCTION
%token RAW FORALL EXISTS OLD RESULT

(* Linearity *)
%token AS
%token LIN AFF

(* Literals *)
%token TRUE FALSE

(* Ownership type keywords *)
%token REF REFMUT OWN RAW_TY

(* Primitive types *)
%token U8 U16 U32 U64 U128 USIZE
%token I8 I16 I32 I64 I128 ISIZE
%token F32 F64
%token BOOL_TY NEVER

(* Grouping *)
%token LPAREN RPAREN LBRACE RBRACE LBRACKET RBRACKET

(* Punctuation *)
%token COMMA SEMI COLON DCOLON DOT DOTDOT
%token PIPE AT HASH UNDERSCORE
%token ARROW FATARROW

(* Comparison *)
%token LT LE GT GE EQEQ NEQ

(* Assignment *)
%token EQ PLUSEQ MINUSEQ STAREQ SLASHEQ

(* Arithmetic / bitwise *)
%token PLUS MINUS STAR SLASH PERCENT
%token AMP CARET TILDE SHL SHR

(* Logical *)
%token BANG LAND LOR IMPLIES IFF

%token EOF

(* ------------------------------------------------------------------ *)
(* Operator precedence — lowest to highest                             *)
(* ------------------------------------------------------------------ *)

(* Assignment and control-flow operators — LOWEST precedence *)
%right EQ PLUSEQ MINUSEQ STAREQ SLASHEQ
%right OR_RETURN OR_FAIL

(* Predicate-level logical operators *)
%right IFF
%right IMPLIES
%left  LOR
%left  LAND

(* Comparison *)
%left  EQEQ NEQ
%left  LT LE GT GE

(* Bitwise *)
%left  PIPE
%left  CARET
%left  AMP
%left  SHL SHR

(* Arithmetic *)
%left  PLUS MINUS
%left  STAR SLASH PERCENT

(* Type cast — binds tighter than arithmetic, looser than unary *)
%left  AS

(* Unary — highest binary-ish *)
%nonassoc UMINUS UBANG UTILDE UDEREF UREF

(* Postfix — field access, indexing, call *)
%left  DOT LBRACKET LPAREN

(* ------------------------------------------------------------------ *)
(* Start symbol                                                         *)
(* ------------------------------------------------------------------ *)

%start <Ast.program> program
%type  <Ast.item>    item
%type  <Ast.expr>    expr
%type  <Ast.ty>      ty
%type  <Ast.pred>    pred

%%

(* ------------------------------------------------------------------ *)
(* Trailing-comma-tolerant list                                        *)
(* tlist(x) matches:  ε | x | x,x | x,x, | x,x,x | x,x,x,  etc.   *)
(* ------------------------------------------------------------------ *)

tlist(x):
  | { [] }
  | x = x { [x] }
  | x = x COMMA rest = tlist(x) { x :: rest }

(* ------------------------------------------------------------------ *)
(* Program                                                              *)
(* ------------------------------------------------------------------ *)

program:
  | items = list(item) EOF
    { { prog_items = items; prog_file = $startpos.pos_fname } }

(* ------------------------------------------------------------------ *)
(* Top-level items                                                      *)
(* ------------------------------------------------------------------ *)

item:
  | f = fn_def
    { mk_item (IFn f) $startpos }
  | t = type_def
    { mk_item (IType t) $startpos }
  | s = struct_def
    { mk_item (IStruct s) $startpos }
  | e = enum_def
    { mk_item (IEnum e) $startpos }
  | i = impl_def
    { mk_item (IImpl i) $startpos }
  | e = extern_def
    { mk_item (IExtern e) $startpos }
  | USE path = separated_nonempty_list(DCOLON, ident) SEMI
    { mk_item (IUse path) $startpos }

(* ------------------------------------------------------------------ *)
(* Function definition                                                  *)
(* ------------------------------------------------------------------ *)

fn_def:
  | attrs = list(attr_clause) FN name = ident
    LPAREN params = tlist(param) RPAREN
    ret = option(preceded(ARROW, ty))
    reqs  = list(requires_clause)
    enss  = list(ensures_clause)
    dec   = option(decreases_clause)
    body  = fn_body
    {
      let ret_ty = match ret with Some t -> t | None -> TPrim TUnit in
      {
        fn_name     = name;
        fn_params   = params;
        fn_ret      = ret_ty;
        fn_requires = reqs;
        fn_ensures  = enss;
        fn_decreases = dec;
        fn_body     = body;
        fn_attrs    = attrs;
      }
    }

attr_clause:
  | HASH LBRACKET name = ident RBRACKET
    { { attr_name = name.name; attr_args = [] } }
  | HASH LBRACKET name = ident LPAREN args = separated_list(COMMA, IDENT) RPAREN RBRACKET
    { { attr_name = name.name; attr_args = args } }

param:
  | name = ident COLON t = ty
    { (name, t) }

requires_clause:
  | REQUIRES p = pred { p }

ensures_clause:
  | ENSURES p = pred { p }

decreases_clause:
  | DECREASES p = pred { p }

fn_body:
  | SEMI         { None }
  | e = block_expr { Some e }

(* ------------------------------------------------------------------ *)
(* Type definition                                                      *)
(* ------------------------------------------------------------------ *)

type_def:
  | TYPE name = ident params = type_params EQ t = ty SEMI
    {
      {
        td_name   = name;
        td_params = params;
        td_ty     = t;
      }
    }

type_params:
  | { [] }
  | LT ps = separated_nonempty_list(COMMA, ident) GT { ps }

(* ------------------------------------------------------------------ *)
(* Struct definition                                                    *)
(* ------------------------------------------------------------------ *)

struct_def:
  | STRUCT name = ident params = kind_params
    LBRACE
      fields = list(struct_field)
      invars = list(invariant_clause)
    RBRACE
    {
      {
        sd_name   = name;
        sd_params = params;
        sd_fields = fields;
        sd_invars = invars;
      }
    }

struct_field:
  | name = ident COLON t = ty COMMA
    { (name, t) }
  | name = ident COLON t = ty
    { (name, t) }

invariant_clause:
  | INVARIANT p = pred SEMI { p }
  | INVARIANT p = pred      { p }

kind_params:
  | { [] }
  | LT ps = separated_nonempty_list(COMMA, kind_param) GT { ps }

kind_param:
  | name = ident                   { (name, KType) }
  | name = ident COLON USIZE       { (name, KNat) }

(* ------------------------------------------------------------------ *)
(* Enum definition                                                      *)
(* ------------------------------------------------------------------ *)

enum_def:
  | ENUM name = ident params = kind_params
    LBRACE variants = list(enum_variant) RBRACE
    {
      {
        ed_name     = name;
        ed_params   = params;
        ed_variants = variants;
      }
    }

enum_variant:
  | name = ident COMMA
    { (name, []) }
  | name = ident LPAREN fields = tlist(ty) RPAREN COMMA
    { (name, fields) }
  | name = ident
    { (name, []) }
  | name = ident LPAREN fields = tlist(ty) RPAREN
    { (name, fields) }

(* ------------------------------------------------------------------ *)
(* Impl block                                                           *)
(* ------------------------------------------------------------------ *)

impl_def:
  | IMPL t = ty LBRACE items = list(item) RBRACE
    {
      {
        im_ty    = t;
        im_items = items;
      }
    }

(* ------------------------------------------------------------------ *)
(* Extern declaration                                                   *)
(* ------------------------------------------------------------------ *)

extern_def:
  | EXTERN FN name = ident
    LPAREN params = tlist(param) RPAREN
    ret = option(preceded(ARROW, ty))
    reqs = list(requires_clause)
    enss = list(ensures_clause)
    link = option(extern_link)
    SEMI
    {
      let ret_ty = match ret with Some t -> t | None -> TPrim TUnit in
      let link_name = match link with Some s -> s | None -> name.name in
      let fn_ty = TFn (mk_fn_ty params ret_ty reqs enss) in
      {
        ex_name = name;
        ex_ty   = fn_ty;
        ex_link = link_name;
      }
    }

extern_link:
  | EQ s = STRING { s }

(* ------------------------------------------------------------------ *)
(* Types                                                                *)
(* ------------------------------------------------------------------ *)

ty:
  (* Primitive with optional refinement *)
  | b = prim_ty_kw
    { TPrim b }
  | b = prim_ty_kw LBRACKET binder = ident PIPE p = pred RBRACKET
    { TRefined (b, binder, p) }

  (* Ownership types *)
  | REF LT t = ty GT
    { TRef t }
  | REFMUT LT t = ty GT
    { TRefMut t }
  | OWN LT t = ty GT
    { TOwn t }
  | RAW LT t = ty GT
    { TRaw t }

  (* Array and slice *)
  | LBRACKET t = ty RBRACKET
    { TSlice t }
  | LBRACKET t = ty SEMI n = expr RBRACKET
    { TArray (t, Some n) }

  (* Unit and never *)
  | LPAREN RPAREN
    { TPrim TUnit }
  | NEVER
    { TPrim TNever }

  (* span<T> — fat pointer with length *)
  | SPAN LT t = ty GT
    { TSpan t }

  (* shared<T>[N] — GPU shared memory array *)
  | SHARED LT t = ty GT LBRACKET n = expr RBRACKET
    { TShared (t, Some n) }
  | SHARED LT t = ty GT
    { TShared (t, None) }

  (* uniform/varying qualifiers *)
  | UNIFORM t = ty
    { TQual (Uniform, t) }
  | VARYING t = ty
    { TQual (Varying, t) }

  (* Named type with optional generic args *)
  | name = ident args = type_args
    {
      match args with
      | [] -> TNamed (name, [])
      | _  -> TNamed (name, args)
    }

  (* Parenthesized type *)
  | LPAREN t = ty RPAREN
    { t }

type_args:
  | { [] }
  | LT args = separated_nonempty_list(COMMA, ty) GT { args }

prim_ty_kw:
  | U8    { TUint U8  }  | U16   { TUint U16  }
  | U32   { TUint U32 }  | U64   { TUint U64  }
  | U128  { TUint U128 } | USIZE { TUint USize }
  | I8    { TInt I8   }  | I16   { TInt I16   }
  | I32   { TInt I32  }  | I64   { TInt I64   }
  | I128  { TInt I128 }  | ISIZE { TInt ISize }
  | F32   { TFloat F32 } | F64   { TFloat F64 }
  | BOOL_TY { TBool }

(* ------------------------------------------------------------------ *)
(* Predicates (logical assertions)                                      *)
(* Used in requires/ensures/invariant/refinements/assume                *)
(* ------------------------------------------------------------------ *)

pred:
  (* Logical connectives — lowest precedence *)
  | l = pred IFF r = pred
    { PBinop (Iff, l, r) }
  | l = pred IMPLIES r = pred
    { PBinop (Implies, l, r) }
  | l = pred LOR r = pred
    { PBinop (Or, l, r) }
  | l = pred LAND r = pred
    { PBinop (And, l, r) }

  (* Comparison *)
  | l = pred EQEQ r = pred  { PBinop (Eq,  l, r) }
  | l = pred NEQ  r = pred  { PBinop (Ne,  l, r) }
  | l = pred LT   r = pred  { PBinop (Lt,  l, r) }
  | l = pred LE   r = pred  { PBinop (Le,  l, r) }
  | l = pred GT   r = pred  { PBinop (Gt,  l, r) }
  | l = pred GE   r = pred  { PBinop (Ge,  l, r) }

  (* Arithmetic *)
  | l = pred PLUS    r = pred { PBinop (Add, l, r) }
  | l = pred MINUS   r = pred { PBinop (Sub, l, r) }
  | l = pred STAR    r = pred { PBinop (Mul, l, r) }
  | l = pred SLASH   r = pred { PBinop (Div, l, r) }
  | l = pred PERCENT r = pred { PBinop (Mod, l, r) }

  (* Bitwise *)
  | l = pred PIPE    r = pred { PBinop (BitOr,  l, r) }
  | l = pred AMP     r = pred { PBinop (BitAnd, l, r) }
  | l = pred CARET   r = pred { PBinop (BitXor, l, r) }
  | l = pred SHL     r = pred { PBinop (Shl,    l, r) }
  | l = pred SHR     r = pred { PBinop (Shr,    l, r) }

  (* Unary *)
  | BANG p = pred  { PUnop (Not, p) }
  | MINUS p = pred { PUnop (Neg, p) }

  (* Quantifiers *)
  | FORALL name = ident COLON t = ty COMMA p = pred
    { PForall (name, t, p) }
  | EXISTS name = ident COLON t = ty COMMA p = pred
    { PExists (name, t, p) }

  (* Special pred atoms *)
  | OLD LPAREN p = pred RPAREN
    { POld p }
  | RESULT
    { PResult }

  (* Lex tuple — for lexicographic termination: (a, b) *)
  | LPAREN p1 = pred COMMA ps = separated_nonempty_list(COMMA, pred) RPAREN
    { PLex (p1 :: ps) }

  (* Field access — higher precedence than arithmetic (uses %left DOT) *)
  | p = pred DOT name = ident
    { PField (p, name.name) }

  (* Array index in pred position: arr[i] *)
  | p = pred LBRACKET idx = pred RBRACKET
    { PIndex (p, idx) }

  (* Atoms *)
  | TRUE              { PBool true }
  | FALSE             { PBool false }
  | n = INT           { PInt n }
  | name = ident LPAREN args = separated_list(COMMA, pred) RPAREN
    { PApp (name, args) }
  | name = ident
    { PVar name }
  | LPAREN p = pred RPAREN
    { p }

(* ------------------------------------------------------------------ *)
(* Expressions                                                          *)
(* ------------------------------------------------------------------ *)

expr:
  (* Binary operators — in precedence order via %left/%right above *)
  | l = expr IFF     r = expr  { mk_expr (EBinop (Iff,     l, r)) $startpos }
  | l = expr IMPLIES r = expr  { mk_expr (EBinop (Implies, l, r)) $startpos }
  | l = expr LOR     r = expr  { mk_expr (EBinop (Or,      l, r)) $startpos }
  | l = expr LAND    r = expr  { mk_expr (EBinop (And,     l, r)) $startpos }
  | l = expr EQEQ    r = expr  { mk_expr (EBinop (Eq,      l, r)) $startpos }
  | l = expr NEQ     r = expr  { mk_expr (EBinop (Ne,      l, r)) $startpos }
  | l = expr LT      r = expr  { mk_expr (EBinop (Lt,      l, r)) $startpos }
  | l = expr LE      r = expr  { mk_expr (EBinop (Le,      l, r)) $startpos }
  | l = expr GT      r = expr  { mk_expr (EBinop (Gt,      l, r)) $startpos }
  | l = expr GE      r = expr  { mk_expr (EBinop (Ge,      l, r)) $startpos }
  | l = expr PIPE    r = expr  { mk_expr (EBinop (BitOr,   l, r)) $startpos }
  | l = expr CARET   r = expr  { mk_expr (EBinop (BitXor,  l, r)) $startpos }
  | l = expr AMP     r = expr  { mk_expr (EBinop (BitAnd,  l, r)) $startpos }
  | l = expr SHL     r = expr  { mk_expr (EBinop (Shl,     l, r)) $startpos }
  | l = expr SHR     r = expr  { mk_expr (EBinop (Shr,     l, r)) $startpos }
  | l = expr PLUS    r = expr  { mk_expr (EBinop (Add,     l, r)) $startpos }
  | l = expr MINUS   r = expr  { mk_expr (EBinop (Sub,     l, r)) $startpos }
  | l = expr STAR    r = expr  { mk_expr (EBinop (Mul,     l, r)) $startpos }
  | l = expr SLASH   r = expr  { mk_expr (EBinop (Div,     l, r)) $startpos }
  | l = expr PERCENT r = expr  { mk_expr (EBinop (Mod,     l, r)) $startpos }

  (* Assignment *)
  | l = expr EQ      r = expr  { mk_expr (EAssign (l, r))                            $startpos }
  | l = expr PLUSEQ  r = expr  { desugar_aug_assign l Add r $startpos }
  | l = expr MINUSEQ r = expr  { desugar_aug_assign l Sub r $startpos }
  | l = expr STAREQ  r = expr  { desugar_aug_assign l Mul r $startpos }
  | l = expr SLASHEQ r = expr  { desugar_aug_assign l Div r $startpos }

  (* Unary *)
  | MINUS e = expr %prec UMINUS  { mk_expr (EUnop (Neg,    e)) $startpos }
  | BANG  e = expr %prec UBANG   { mk_expr (EUnop (Not,    e)) $startpos }
  | TILDE e = expr %prec UTILDE  { mk_expr (EUnop (BitNot, e)) $startpos }
  | STAR  e = expr %prec UDEREF  { mk_expr (EDeref e)          $startpos }
  | AMP   e = expr %prec UREF    { mk_expr (ERef e)             $startpos }

  (* Postfix: field, index, call *)
  | e = expr DOT name = ident
    { mk_expr (EField (e, name)) $startpos }
  | e = expr LBRACKET idx = expr RBRACKET
    { mk_expr (EIndex (e, idx)) $startpos }
  | f = expr LPAREN args = tlist(expr) RPAREN
    { mk_expr (ECall (f, args)) $startpos }

  (* or_return / or_fail *)
  | e = expr OR_RETURN alt = expr
    { mk_expr (ECall (
        mk_expr (EVar (mk_ident "__or_return__" $startpos)) $startpos,
        [e; alt])) $startpos }
  | e = expr OR_FAIL alt = expr
    { mk_expr (ECall (
        mk_expr (EVar (mk_ident "__or_fail__" $startpos)) $startpos,
        [e; alt])) $startpos }

  (* Block, control flow, proof, raw *)
  | e = block_expr    { e }
  | e = if_expr       { e }
  | e = match_expr    { e }
  | e = loop_expr     { e }
  | e = proof_expr    { e }
  | e = raw_expr      { e }
  | e = assume_expr   { e }
  | e = return_expr   { e }

  (* __syncthreads() — GPU warp barrier *)
  | SYNCTHREADS LPAREN RPAREN
    { mk_expr ESync $startpos }

  (* Type cast — expr as Type *)
  | e = expr AS t = ty
    { mk_expr (ECast (e, t)) $startpos }

  (* Struct literal — struct TypeName { field: val, ... } *)
  | STRUCT name = ident LBRACE
      fields = tlist(struct_field_init)
    RBRACE
    { mk_expr (EStruct (name, fields)) $startpos }

  (* Atomic expressions *)
  | e = atom_expr     { e }

struct_field_init:
  | name = ident COLON e = expr { (name, e) }

atom_expr:
  | n = INT
    { mk_expr (ELit (LInt (n, None))) $startpos }
  | ns = INT_SUFF
    { let (n, s) = ns in mk_expr (ELit (LInt (n, Some (prim_of_suffix s)))) $startpos }
  | f = FLOAT
    { mk_expr (ELit (LFloat (f, None))) $startpos }
  | s = STRING
    { mk_expr (ELit (LStr s)) $startpos }
  | TRUE
    { mk_expr (ELit (LBool true)) $startpos }
  | FALSE
    { mk_expr (ELit (LBool false)) $startpos }
  | LPAREN RPAREN
    { mk_expr (ELit LUnit) $startpos }
  | name = ident
    { mk_expr (EVar name) $startpos }
  | LPAREN e = expr RPAREN
    { e }
  (* Fixed-size array literals: [a, b, c] and [val; N] *)
  | LBRACKET elems = separated_list(COMMA, expr) RBRACKET
    { mk_expr (EArrayLit elems) $startpos }
  | LBRACKET v = expr SEMI n = expr RBRACKET
    { mk_expr (EArrayRepeat (v, n)) $startpos }

(* ------------------------------------------------------------------ *)
(* Block expression: { stmt* expr? }                                    *)
(* ------------------------------------------------------------------ *)

block_expr:
  | LBRACE stmts = block_stmts RBRACE
    {
      let (ss, ret) = stmts in
      mk_expr (EBlock (ss, ret)) $startpos
    }

(* A block's body: stmts followed by an optional trailing expression.
   LR shift/reduce resolution handles the ambiguity correctly:
   - shift SEMI  → expression statement, continue
   - reduce at } → trailing expression                                 *)
block_stmts:
  | (* empty *)
    { ([], None) }
  | e = expr
    { ([], Some e) }
  | e = expr SEMI rest = block_stmts
    { let (ss, ret) = rest in (mk_stmt (SExpr e) $startpos :: ss, ret) }
  | LET lin = linearity name = ident ann = option(preceded(COLON, ty))
    EQ e = expr SEMI rest = block_stmts
    { let (ss, ret) = rest in (mk_stmt (SLet (name, ann, e, lin)) $startpos :: ss, ret) }
  | LET name = ident ann = option(preceded(COLON, ty))
    EQ e = expr SEMI rest = block_stmts
    { let (ss, ret) = rest in (mk_stmt (SLet (name, ann, e, Unr)) $startpos :: ss, ret) }
  | BREAK SEMI rest = block_stmts
    { let (ss, ret) = rest in (mk_stmt SBreak $startpos :: ss, ret) }
  | CONTINUE SEMI rest = block_stmts
    { let (ss, ret) = rest in (mk_stmt SContinue $startpos :: ss, ret) }

(* ------------------------------------------------------------------ *)
(* Control flow expressions                                             *)
(* ------------------------------------------------------------------ *)

if_expr:
  | IF cond = expr
    then_ = block_expr
    else_ = option(preceded(ELSE, else_branch))
    { mk_expr (EIf (cond, then_, else_)) $startpos }

else_branch:
  | e = block_expr { e }
  | e = if_expr    { e }

match_expr:
  | MATCH scrut = expr LBRACE
      arms = list(match_arm)
    RBRACE
    { mk_expr (EMatch (scrut, arms)) $startpos }

match_arm:
  | pat = alt_pattern guard = option(preceded(IF, pred)) FATARROW body = arm_body
    { { pattern = pat; guard; body } }

(* OR patterns: Red | Blue | Green => ...  *)
(* Separate from pattern to avoid conflict with expr PIPE expr (BitOr) *)
alt_pattern:
  | p = pattern                              { p }
  | p1 = alt_pattern PIPE p2 = pattern      { POr (p1, p2) }

arm_body:
  | e = block_expr COMMA { e }
  | e = expr COMMA { e }
  | e = expr       { e }

loop_expr:
  | LOOP body = block_expr
    { mk_expr (EBlock (
        [mk_stmt (SWhile (
            mk_expr (ELit (LBool true)) $startpos,
            None, None,
            [mk_stmt (SExpr body) $startpos]
          )) $startpos],
        None)) $startpos }
  | WHILE cond = expr
    inv = option(preceded(INVARIANT, pred))
    dec = option(preceded(DECREASES, pred))
    body = block_expr
    {
      let stmts = match body.expr_desc with
        | EBlock (ss, Some ret) -> ss @ [mk_stmt (SExpr ret) $startpos]
        | EBlock (ss, None)     -> ss
        | _ -> [mk_stmt (SExpr body) $startpos]
      in
      mk_expr (EBlock (
        [mk_stmt (SWhile (cond, inv, dec, stmts)) $startpos],
        None)) $startpos
    }
  | FOR name = ident IN iter = expr
    dec = option(preceded(DECREASES, pred))
    body = block_expr
    {
      let stmts = match body.expr_desc with
        | EBlock (ss, Some ret) -> ss @ [mk_stmt (SExpr ret) $startpos]
        | EBlock (ss, None)     -> ss
        | _ -> [mk_stmt (SExpr body) $startpos]
      in
      mk_expr (EBlock (
        [mk_stmt (SFor (name, iter, dec, stmts)) $startpos],
        None)) $startpos
    }

return_expr:
  | RETURN e = option(expr)
    { mk_expr (EBlock (
        [mk_stmt (SReturn e) $startpos],
        None)) $startpos }

(* ------------------------------------------------------------------ *)
(* Proof block: proof { lemma* assume* }                               *)
(* ------------------------------------------------------------------ *)

proof_expr:
  | PROOF LBRACE pb = proof_contents RBRACE
    { mk_expr (EProof pb) $startpos }

proof_contents:
  | lemmas = list(lemma_def) assumes = list(assume_in_proof)
    {
      {
        pb_lemmas  = lemmas;
        pb_assumes = assumes;
        pb_loc     = mk_loc $startpos;
      }
    }

lemma_def:
  | LEMMA name = ident
    LPAREN params = tlist(param) RPAREN
    COLON stmt = pred
    LBRACE pt = proof_term RBRACE
    {
      {
        lem_name   = name;
        lem_params = params;
        lem_stmt   = stmt;
        lem_proof  = pt;
        lem_loc    = mk_loc $startpos;
      }
    }

assume_in_proof:
  | ASSUME LPAREN p = pred RPAREN ctx = option(STRING) SEMI
    {
      {
        as_pred    = p;
        as_context = ctx;
        as_loc     = mk_loc $startpos;
      }
    }

proof_term:
  | AUTO
    { PTAuto }
  | AXIOM
    { PTAxiom }
  | id = IDENT
    { (if id = "refl" then PTRefl
       else raise Error : proof_term) }
  | SYMM LPAREN pt = proof_term RPAREN
    { PTSymm pt }
  | TRANS LPAREN mid = expr COMMA pt1 = proof_term COMMA pt2 = proof_term RPAREN
    { PTTrans (mid, pt1, pt2) }
  | INDUCTION x = ident LBRACE base = proof_term COMMA step = proof_term RBRACE
    { PTInduct (x, base, step) }
  | WITNESS LPAREN e = expr RPAREN
    { PTWitness e }
  | BY name = ident LPAREN args = separated_list(COMMA, proof_term) RPAREN
    { PTBy (name, args) }
  | LBRACE pts = list(proof_term) RBRACE
    { PTCong pts }

(* ------------------------------------------------------------------ *)
(* Raw block: raw { stmts }                                            *)
(* ------------------------------------------------------------------ *)

raw_expr:
  | RAW LBRACE stmts = list(stmt) RBRACE
    {
      mk_expr (ERaw {
        rb_stmts = stmts;
        rb_loc   = mk_loc $startpos;
      }) $startpos
    }

(* ------------------------------------------------------------------ *)
(* Assume expression: assume(pred) "context"                           *)
(* ------------------------------------------------------------------ *)

assume_expr:
  | ASSUME LPAREN p = pred RPAREN ctx = option(STRING)
    { mk_expr (EAssume (p, ctx)) $startpos }

(* ------------------------------------------------------------------ *)
(* Statements                                                           *)
(* ------------------------------------------------------------------ *)

stmt:
  | LET lin = linearity name = ident ann = option(preceded(COLON, ty))
    EQ e = expr SEMI
    { mk_stmt (SLet (name, ann, e, lin)) $startpos }
  | LET name = ident ann = option(preceded(COLON, ty))
    EQ e = expr SEMI
    { mk_stmt (SLet (name, ann, e, Unr)) $startpos }
  | e = expr SEMI
    { mk_stmt (SExpr e) $startpos }
  | BREAK SEMI
    { mk_stmt SBreak $startpos }
  | CONTINUE SEMI
    { mk_stmt SContinue $startpos }

linearity:
  | LIN { Lin }
  | AFF { Aff }
  | MUT { Unr }   (* let mut x = ... treated as unrestricted mutable binding *)

(* ------------------------------------------------------------------ *)
(* Patterns                                                             *)
(* ------------------------------------------------------------------ *)

pattern:
  | UNDERSCORE
    { PWild }
  | name = ident
    { PBind name }
  | n = INT
    { PLit (LInt (n, None)) }
  | TRUE
    { PLit (LBool true) }
  | FALSE
    { PLit (LBool false) }
  | name = ident LPAREN pats = separated_list(COMMA, pattern) RPAREN
    { PCtor (name, pats) }
  | pat = pattern AS name = ident
    { PAs (pat, name) }
  | LPAREN pats = separated_list(COMMA, pattern) RPAREN
    { PTuple pats }

(* ------------------------------------------------------------------ *)
(* Identifiers                                                          *)
(* ------------------------------------------------------------------ *)

ident:
  | name = IDENT
    { mk_ident name $startpos }
  (* Allow some keywords as identifiers in certain positions *)
  | RAW        { mk_ident "raw"        $startpos }
  | BY         { mk_ident "by"         $startpos }
  (* GPU attribute names must be usable as plain identifiers *)
  | KERNEL     { mk_ident "kernel"     $startpos }
  | COALESCED  { mk_ident "coalesced"  $startpos }
  | SPAN       { mk_ident "span"       $startpos }
  | SHARED     { mk_ident "shared"     $startpos }
  | UNIFORM    { mk_ident "uniform"    $startpos }
  | VARYING    { mk_ident "varying"    $startpos }
