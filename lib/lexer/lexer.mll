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
  "requires",   REQUIRES;
  "ensures",    ENSURES;
  "decreases",  DECREASES;
  "invariant",  INVARIANT;
  "proof",      PROOF;
  "assume",     ASSUME;
  "lemma",      LEMMA;
  "witness",    WITNESS;
  "by",         BY;
  "raw",        RAW;
  "forall",     FORALL;
  "exists",     EXISTS;
  "old",        OLD;
  "result",     RESULT;
  "true",       TRUE;
  "false",      FALSE;
  "or_return",  OR_RETURN;
  "or_fail",    OR_FAIL;
  "lin",        LIN;
  "aff",        AFF;
  "task",       TASK;
  "chan",        CHAN;
  "ref",        REF;
  "refmut",     REFMUT;
  "own",        OWN;
  "u8",         U8;
  "u16",        U16;
  "u32",        U32;
  "u64",        U64;
  "u128",       U128;
  "usize",      USIZE;
  "i8",         I8;
  "i16",        I16;
  "i32",        I32;
  "i64",        I64;
  "i128",       I128;
  "isize",      ISIZE;
  "f32",        F32;
  "f64",        F64;
  "bool",       BOOL_TY;
  "Never",      NEVER;
]

let ident_or_kw s =
  match Hashtbl.find_opt kw_table s with
  | Some tok -> tok
  | None     -> IDENT s

let newline lexbuf =
  let pos = lexbuf.lex_curr_p in
  lexbuf.lex_curr_p <- {
    pos with
    pos_lnum = pos.pos_lnum + 1;
    pos_bol  = pos.pos_cnum;
  }
}

let digit     = ['0'-'9']
let hex_digit = ['0'-'9' 'a'-'f' 'A'-'F']
let alpha     = ['a'-'z' 'A'-'Z']
let alnum     = alpha | digit | '_'
let ident     = (alpha | '_') alnum*
let ws        = [' ' '\t' '\r']
let newline   = '\n' | "\r\n"
let int_lit   = digit+ | "0x" hex_digit+
let float_lit = digit+ '.' digit* | '.' digit+

rule token = parse
  (* Whitespace and comments *)
  | ws+       { token lexbuf }
  | newline   { newline lexbuf; token lexbuf }
  | "//" [^'\n']* { token lexbuf }   (* line comment *)
  | "/*"      { block_comment 1 lexbuf }

  (* Literals *)
  | int_lit as n   { INT (int_of_string n) }
  | float_lit as f { FLOAT (float_of_string f) }
  | '"'            { string_lit (Buffer.create 64) lexbuf }

  (* Identifiers and keywords *)
  | ident as s { ident_or_kw s }

  (* Two-character symbols — must come before single-char *)
  | "::"  { DCOLON }
  | ".."  { DOTDOT }
  | "->"  { ARROW }
  | "=>"  { FATARROW }
  | "=="  { EQEQ }
  | "!="  { NEQ }
  | "<="  { LE }
  | ">="  { GE }
  | "<<"  { SHL }
  | ">>"  { SHR }
  | "&&"  { LAND }
  | "||"  { LOR }
  | "<=>" { IFF }
  | "+="  { PLUSEQ }
  | "-="  { MINUSEQ }
  | "*="  { STAREQ }
  | "/="  { SLASHEQ }

  (* Single-character symbols *)
  | '('  { LPAREN }
  | ')'  { RPAREN }
  | '{'  { LBRACE }
  | '}'  { RBRACE }
  | '['  { LBRACKET }
  | ']'  { RBRACKET }
  | '<'  { LANGLE }
  | '>'  { RANGLE }
  | ','  { COMMA }
  | ';'  { SEMI }
  | ':'  { COLON }
  | '.'  { DOT }
  | '|'  { PIPE }
  | '&'  { AMP }
  | '*'  { STAR }
  | '!'  { BANG }
  | '?'  { QUESTION }
  | '@'  { AT }
  | '#'  { HASH }
  | '_'  { UNDERSCORE }
  | '='  { EQ }
  | '+'  { PLUS }
  | '-'  { MINUS }
  | '/'  { SLASH }
  | '%'  { PERCENT }
  | '^'  { CARET }
  | '~'  { TILDE }

  | eof  { EOF }

  | _ as c {
      raise (LexError (
        Printf.sprintf "unexpected character '%c'" c,
        lexbuf.lex_curr_p))
    }

and block_comment depth = parse
  | "/*"      { block_comment (depth + 1) lexbuf }
  | "*/"      { if depth = 1 then token lexbuf
                else block_comment (depth - 1) lexbuf }
  | newline   { newline lexbuf; block_comment depth lexbuf }
  | eof       { raise (LexError ("unterminated block comment",
                                  lexbuf.lex_curr_p)) }
  | _         { block_comment depth lexbuf }

and string_lit buf = parse
  | '"'        { STRING (Buffer.contents buf) }
  | '\\' 'n'  { Buffer.add_char buf '\n'; string_lit buf lexbuf }
  | '\\' 't'  { Buffer.add_char buf '\t'; string_lit buf lexbuf }
  | '\\' '"'  { Buffer.add_char buf '"';  string_lit buf lexbuf }
  | '\\' '\\' { Buffer.add_char buf '\\'; string_lit buf lexbuf }
  | newline    { newline lexbuf; Buffer.add_char buf '\n';
                 string_lit buf lexbuf }
  | eof        { raise (LexError ("unterminated string", lexbuf.lex_curr_p)) }
  | _ as c    { Buffer.add_char buf c; string_lit buf lexbuf }
