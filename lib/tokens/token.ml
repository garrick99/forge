(* FORGE Token types — updated: unified angle bracket tokens *)

type token =
  (* Literals *)
  | INT      of int64
  | INT_SUFF of (int64 * string)  (* 42u32, 100i64 — value + suffix string *)
  | FLOAT    of float
  | STRING   of string

  (* Identifiers *)
  | IDENT  of string

  (* Keywords — declarations *)
  | FN | TYPE | STRUCT | ENUM | IMPL | USE | EXTERN | TASK | CHAN

  (* Keywords — types *)
  | SPAN | SHARED | UNIFORM | VARYING | KERNEL | COALESCED | SYNCTHREADS | STR_TY

  (* Keywords — control flow *)
  | LET | MUT | CONST | RETURN | IF | ELSE | MATCH | FOR | WHILE | LOOP
  | IN | BREAK | CONTINUE | OR_RETURN | OR_FAIL | WHERE

  (* Keywords — proof *)
  | REQUIRES | ENSURES | DECREASES | INVARIANT
  | PROOF | ASSUME | LEMMA | WITNESS | BY | AUTO | AXIOM | SYMM | TRANS | INDUCTION
  | RAW | FORALL | EXISTS | OLD | RESULT

  (* Keywords — linearity *)
  | AS
  | LIN | AFF

  (* Keywords — literals *)
  | TRUE | FALSE

  (* Ownership type keywords *)
  | REF | REFMUT | OWN | RAW_TY

  (* Primitive type keywords *)
  | U8 | U16 | U32 | U64 | U128 | USIZE
  | I8 | I16 | I32 | I64 | I128 | ISIZE
  | F32 | F64
  | BOOL_TY | NEVER

  (* Grouping *)
  | LPAREN   (* ( *)
  | RPAREN   (* ) *)
  | LBRACE   (* { *)
  | RBRACE   (* } *)
  | LBRACKET (* [ *)
  | RBRACKET (* ] *)

  (* Punctuation *)
  | COMMA    (* , *)
  | SEMI     (* ; *)
  | COLON    (* : *)
  | DCOLON   (* :: *)
  | DOT      (* . *)
  | DOTDOT   (* .. *)
  | PIPE     (* | *)
  | AT       (* @ *)
  | HASH     (* # *)
  | UNDERSCORE (* _ *)

  (* Arrows *)
  | ARROW    (* -> *)
  | FATARROW (* => *)

  (* Comparison *)
  | LT       (* < *)
  | LE       (* <= *)
  | GT       (* > *)
  | GE       (* >= *)
  | EQEQ     (* == *)
  | NEQ      (* != *)

  (* Assignment *)
  | EQ       (* = *)
  | PLUSEQ   (* += *)
  | MINUSEQ  (* -= *)
  | STAREQ   (* *= *)
  | SLASHEQ  (* /= *)

  (* Arithmetic *)
  | PLUS | MINUS | STAR | SLASH | PERCENT

  (* Bitwise *)
  | AMP | CARET | TILDE | SHL | SHR

  (* Logical *)
  | BANG     (* ! *)
  | LAND     (* && *)
  | LOR      (* || *)
  | IMPLIES  (* ==> logical implication in predicates *)
  | IFF      (* <=> logical iff in predicates *)

  | EOF
