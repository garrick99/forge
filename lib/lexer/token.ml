(* FORGE Token types *)

type token =
  (* Literals *)
  | INT    of int
  | FLOAT  of float
  | BOOL   of bool
  | STRING of string

  (* Identifiers and keywords *)
  | IDENT  of string

  (* Keywords *)
  | FN | TYPE | STRUCT | ENUM | IMPL | USE | EXTERN
  | LET | MUT | RETURN | IF | ELSE | MATCH | FOR | WHILE | LOOP
  | IN | BREAK | CONTINUE
  | REQUIRES | ENSURES | DECREASES | INVARIANT
  | PROOF | ASSUME | LEMMA | WITNESS | BY
  | RAW | FORALL | EXISTS | OLD | RESULT
  | TRUE | FALSE | OR_RETURN | OR_FAIL
  | LIN | AFF
  | TASK | CHAN

  (* Type keywords *)
  | REF | REFMUT | OWN | RAW_TY
  | U8 | U16 | U32 | U64 | U128 | USIZE
  | I8 | I16 | I32 | I64 | I128 | ISIZE
  | F32 | F64
  | BOOL_TY | UNIT_TY | NEVER

  (* Symbols *)
  | LPAREN | RPAREN       (* ( ) *)
  | LBRACE | RBRACE       (* { } *)
  | LBRACKET | RBRACKET   (* [ ] *)
  | LANGLE | RANGLE       (* < > *)
  | COMMA | SEMI | COLON  (* , ; : *)
  | DCOLON                (* :: *)
  | DOT | DOTDOT          (* . .. *)
  | ARROW                 (* -> *)
  | FATARROW              (* => *)
  | PIPE                  (* | *)
  | AMP                   (* & *)
  | STAR                  (* * *)
  | BANG                  (* ! *)
  | QUESTION              (* ? *)
  | AT                    (* @ *)
  | HASH                  (* # *)
  | UNDERSCORE            (* _ *)
  | EQ                    (* = *)
  | EQEQ                  (* == *)
  | NEQ                   (* != *)
  | LT | LE               (* < <= *)
  | GT | GE               (* > >= *)
  | PLUS | MINUS          (* + - *)
  | SLASH | PERCENT       (* / % *)
  | CARET                 (* ^ *)
  | TILDE                 (* ~ *)
  | SHL | SHR             (* << >> *)
  | LAND | LOR            (* && || *)
  | IMPLIES               (* => in pred context *)
  | IFF                   (* <=> *)
  | PLUSEQ | MINUSEQ      (* += -= *)
  | STAREQ | SLASHEQ      (* *= /= *)

  | EOF
