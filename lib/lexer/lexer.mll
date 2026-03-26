(* FORGE Lexer — ocamllex *)

{
open Token
open Lexing

exception LexError of string * position

let kw_table = Hashtbl.of_seq @@ List.to_seq [
  "fn",         FN;
  "type",       TYPE;
  "struct",     STRUCT;
  "enum",       ENUM;
  "impl",       IMPL;
  "use",        USE;
  "extern",     EXTERN;
  "task",       TASK;
  "chan",        CHAN;
  "let",        LET;
  "mut",        MUT;
  "return",     RETURN;
  "if",         IF;
  "else",       ELSE;
  "match",      MATCH;
  "for",        FOR;
  "while",      WHILE;
  "loop",       LOOP;
  "in",         IN;
  "break",      BREAK;
  "continue",   CONTINUE;
  "or_return",  OR_RETURN;
  "or_fail",    OR_FAIL;
  "requires",   REQUIRES;
  "ensures",    ENSURES;
  "decreases",  DECREASES;
  "invariant",  INVARIANT;
  "proof",      PROOF;
  "assume",     ASSUME;
  "lemma",      LEMMA;
  "witness",    WITNESS;
  "by",         BY;
  "auto",       AUTO;
  "raw",        RAW;
  "forall",     FORALL;
  "exists",     EXISTS;
  "old",        OLD;
  "result",     RESULT;
  "lin",        LIN;
  "aff",        AFF;
  "true",       TRUE;
  "false",      FALSE;
  "ref",        REF;
  "refmut",     REFMUT;
  "own",        OWN;
  "u8",         U8;   "u16", U16; "u32", U32; "u64", U64;
  "u128",       U128; "usize", USIZE;
  "i8",         I8;   "i16", I16; "i32", I32; "i64", I64;
  "i128",       I128; "isize", ISIZE;
  "f32",        F32;  "f64", F64;
  "bool",       BOOL_TY;
  "Never",      NEVER;
]

let ident_or_kw s =
  match Hashtbl.find_opt kw_table s with
  | Some tok -> tok
  | None     -> IDENT s

let advance_line lexbuf =
  let pos = lexbuf.lex_curr_p in
  lexbuf.lex_curr_p <- {
    pos with
    pos_lnum = pos.pos_lnum + 1;
    pos_bol  = pos.pos_cnum;
  }
}

let digit     = ['0'-'9']
let hex       = ['0'-'9' 'a'-'f' 'A'-'F']
let alpha     = ['a'-'z' 'A'-'Z']
let alnum     = alpha | digit | '_'
let ident     = (alpha | '_') alnum*
let ws        = [' ' '\t' '\r']
let newline   = '\n' | "\r\n"
let int_lit   = digit+ | "0x" hex+
let float_lit = digit+ '.' digit* (['e' 'E'] ['+' '-']? digit+)?
              | digit+ ['e' 'E'] ['+' '-']? digit+

rule token = parse
  | ws+     { token lexbuf }
  | newline { advance_line lexbuf; token lexbuf }
  | "//" [^'\n']* { token lexbuf }
  | "/*"    { block_comment 1 lexbuf }

  (* Literals *)
  | int_lit as n   { INT (int_of_string n) }
  | float_lit as f { FLOAT (float_of_string f) }
  | '"'            { string_tok (Buffer.create 64) lexbuf }

  (* Identifiers / keywords *)
  | ident as s { ident_or_kw s }

  (* Three-character tokens *)
  | "==>" { IMPLIES }
  | "<=>" { IFF }

  (* Two-character tokens *)
  | "::" { DCOLON }
  | ".." { DOTDOT }
  | "->" { ARROW }
  | "=>" { FATARROW }
  | "==" { EQEQ }
  | "!=" { NEQ }
  | "<=" { LE }
  | ">=" { GE }
  | "<<" { SHL }
  | ">>" { SHR }
  | "&&" { LAND }
  | "||" { LOR }
  | "+=" { PLUSEQ }
  | "-=" { MINUSEQ }
  | "*=" { STAREQ }
  | "/=" { SLASHEQ }

  (* Single-character tokens *)
  | '(' { LPAREN }   | ')' { RPAREN }
  | '{' { LBRACE }   | '}' { RBRACE }
  | '[' { LBRACKET } | ']' { RBRACKET }
  | '<' { LT }       | '>' { GT }
  | ',' { COMMA }    | ';' { SEMI }
  | ':' { COLON }    | '.' { DOT }
  | '|' { PIPE }     | '&' { AMP }
  | '*' { STAR }     | '!' { BANG }
  | '+' { PLUS }     | '-' { MINUS }
  | '/' { SLASH }    | '%' { PERCENT }
  | '^' { CARET }    | '~' { TILDE }
  | '=' { EQ }       | '@' { AT }
  | '#' { HASH }     | '_' { UNDERSCORE }

  | eof { EOF }
  | _ as c {
      raise (LexError (
        Printf.sprintf "unexpected character '%c' (0x%02X)" c (Char.code c),
        lexbuf.lex_curr_p))
    }

and block_comment depth = parse
  | "/*"    { block_comment (depth + 1) lexbuf }
  | "*/"    { if depth = 1 then token lexbuf
              else block_comment (depth - 1) lexbuf }
  | newline { advance_line lexbuf; block_comment depth lexbuf }
  | eof     { raise (LexError ("unterminated block comment", lexbuf.lex_curr_p)) }
  | _       { block_comment depth lexbuf }

and string_tok buf = parse
  | '"'        { STRING (Buffer.contents buf) }
  | '\\' 'n'  { Buffer.add_char buf '\n'; string_tok buf lexbuf }
  | '\\' 't'  { Buffer.add_char buf '\t'; string_tok buf lexbuf }
  | '\\' '"'  { Buffer.add_char buf '"';  string_tok buf lexbuf }
  | '\\' '\\' { Buffer.add_char buf '\\'; string_tok buf lexbuf }
  | '\\' 'r'  { Buffer.add_char buf '\r'; string_tok buf lexbuf }
  | '\\' '0'  { Buffer.add_char buf '\000'; string_tok buf lexbuf }
  | newline   { advance_line lexbuf; Buffer.add_char buf '\n'; string_tok buf lexbuf }
  | eof       { raise (LexError ("unterminated string literal", lexbuf.lex_curr_p)) }
  | _ as c   { Buffer.add_char buf c; string_tok buf lexbuf }
