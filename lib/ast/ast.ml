(* FORGE AST
   The abstract syntax tree. Every node carries a source location.
   Proof obligations are attached to nodes during type elaboration —
   they start empty and get filled in by the proof engine. *)

(* ------------------------------------------------------------------ *)
(* Source locations                                                     *)
(* ------------------------------------------------------------------ *)

type loc = {
  file: string;
  line: int;
  col:  int;
}

let dummy_loc = { file = "<builtin>"; line = 0; col = 0 }

(* ------------------------------------------------------------------ *)
(* Identifiers                                                          *)
(* ------------------------------------------------------------------ *)

type ident = {
  name: string;
  loc:  loc;
}

(* ------------------------------------------------------------------ *)
(* Primitive types                                                      *)
(* ------------------------------------------------------------------ *)

type int_width = I8 | I16 | I32 | I64 | I128 | ISize
type uint_width = U8 | U16 | U32 | U64 | U128 | USize
type float_width = F32 | F64

type prim_ty =
  | TInt   of int_width
  | TUint  of uint_width
  | TFloat of float_width
  | TBool
  | TUnit
  | TNever

(* ------------------------------------------------------------------ *)
(* Refinement predicates (first-order logic over values)               *)
(* ------------------------------------------------------------------ *)

(* The logical expressions used in refinements, requires, ensures.
   These are over integers and booleans — the SMT fragment. *)
type pred =
  | PTrue
  | PFalse
  | PVar    of ident                        (* bound variable *)
  | PInt    of int64                        (* integer literal *)
  | PFloat  of float                        (* float literal — Real sort in SMT *)
  | PBool   of bool
  | PBinop  of binop * pred * pred
  | PUnop   of unop * pred
  | PApp    of ident * pred list            (* predicate application *)
  | POld    of pred                         (* old(expr) — pre-state value *)
  | PResult                                 (* 'result' — return value *)
  | PIte    of pred * pred * pred           (* if cond then t else e — for SMT ite *)
  | PForall of ident * ty * pred           (* forall x: T, P *)
  | PExists of ident * ty * pred           (* exists x: T, P *)
  | PLex    of pred list                   (* (a, b) — lexicographic termination measure *)
  | PField  of pred * string               (* pred.field — field projection in pred *)
  | PStruct of string * (string * pred) list (* struct literal in pred position *)
  | PIndex  of pred * pred                 (* pred[pred] — array index in pred *)

(* GPU uniformity qualifier — tracks whether a value is same across all threads *)
and qual = Uniform | Varying

and binop =
  | Add | Sub | Mul | Div | Mod
  | Eq | Ne | Lt | Le | Gt | Ge
  | And | Or | Implies | Iff
  | BitAnd | BitOr | BitXor | Shl | Shr

and unop =
  | Neg | Not | BitNot

(* ------------------------------------------------------------------ *)
(* Types                                                                *)
(* ------------------------------------------------------------------ *)

and ty =
  | TPrim    of prim_ty
  | TRefined of prim_ty * ident * pred      (* base { binder | pred } *)
  | TRef     of ty                          (* ref<T> — immutable borrow *)
  | TRefMut  of ty                          (* refmut<T> — mutable borrow *)
  | TOwn     of ty                          (* own<T> — owned, linear *)
  | TRaw     of ty                          (* raw<T> — unsafe pointer *)
  | TArray   of ty * expr option            (* [T; N] *)
  | TSlice   of ty                          (* [T] *)
  | TNamed   of ident * ty list             (* named type with params *)
  | TFn      of fn_ty                       (* function type *)
  | TDepArr  of ident * ty * ty            (* (x: T) -> U(x) dependent *)
  | TTuple   of ty list                    (* (T1, T2, ...) — anonymous product type *)
  | TSpan    of ty                          (* span<T> — fat pointer {raw<T>*, usize} *)
  | TShared  of ty * expr option            (* shared<T>[N] — GPU __shared__ memory *)
  | TQual    of qual * ty                   (* uniform/varying qualifier *)
  | TSecret  of ty                          (* secret<T> — constant-time taint wrapper *)
  | TStr                                    (* str — UTF-8 byte span (sugar for span<u8>) *)
  | TAssoc   of ty * string                 (* T::Item — associated type projection *)

and fn_ty = {
  params:   (ident * ty) list;
  ret:      ty;
  requires: pred list;
  ensures:  pred list;
}

(* ------------------------------------------------------------------ *)
(* Expressions                                                          *)
(* ------------------------------------------------------------------ *)

and expr = {
  expr_desc: expr_desc;
  expr_loc:  loc;
  mutable expr_ty: ty option;     (* filled in by type checker *)
}

and expr_desc =
  | ELit    of lit
  | EVar    of ident
  | EBinop  of binop * expr * expr
  | EUnop   of unop * expr
  | ECall   of expr * expr list
  | EIndex  of expr * expr                  (* arr[i] *)
  | EField  of expr * ident                 (* s.field *)
  | EAssign of expr * expr
  | EBlock  of stmt list * expr option      (* { stmts; expr } *)
  | EIf     of expr * expr * expr option
  | EMatch  of expr * match_arm list
  | ERef    of expr                         (* &expr *)
  | ERefMut of expr                         (* &mut expr *)
  | EDeref  of expr                         (* *expr *)
  | ECast   of expr * ty
  | EProof  of proof_block                  (* proof { ... } *)
  | ERaw    of raw_block                    (* raw { ... } *)
  | EAssume of pred * string option         (* assume(pred) "context" — trusted, logged *)
  | EAssert of pred * string option         (* assert(pred) "context" — proved, then added as fact *)
  | ELoop   of stmt list                    (* loop { stmts } — break val; returns loop result *)
  | EStruct of ident * (ident * expr) list  (* StructName { field: val, ... } *)
  | ESync                                   (* __syncthreads() — GPU barrier *)
  | EArrayLit    of expr list               (* [a, b, c] — fixed-size array literal *)
  | EArrayRepeat of expr * expr             (* [val; N]  — repeat-value array init *)
  | ETuple       of expr list               (* (e1, e2, ...) — tuple construction *)
  | EField_n     of expr * int              (* t.0, t.1 — tuple field projection *)
  | ESubspan     of expr * expr * expr      (* s[lo..hi] — sub-span with proven bounds *)
  | ERange       of expr * expr             (* lo..hi — integer range for for-loops *)
  | ELambda     of (ident * ty) list * expr * string option ref
    (* \(x: T, y: U) -> body  — lifted to __forge_lambda_N; ref filled by typechecking *)
  | EAsm  of asm_block
    (* asm("template", in("r") val, ..., out("r") name, ...) — inline assembly *)

and asm_block = {
  asm_template: string;                         (* assembly template string *)
  asm_outputs:  (string * ident) list;          (* constraint, variable name *)
  asm_inputs:   (string * expr) list;           (* constraint, value expr *)
  asm_clobbers: string list;                    (* clobbered registers *)
  asm_loc:      loc;
}

and lit =
  | LInt   of int64 * prim_ty option        (* 42u32, 5i64 — suffix sets type *)
  | LFloat of float * float_width option
  | LBool  of bool
  | LUnit
  | LStr   of string

and match_arm = {
  pattern: pattern;
  guard:   pred option;
  body:    expr;
}

and pattern =
  | PWild
  | PBind   of ident
  | PLit    of lit
  | PLitRange of lit * lit                  (* lo..=hi — integer range pattern *)
  | PCtor   of ident * pattern list         (* Ctor(p1, p2) *)
  | PTuple  of pattern list
  | PAs     of pattern * ident              (* p as x *)
  | POr     of pattern * pattern            (* p1 | p2 *)

(* ------------------------------------------------------------------ *)
(* Statements                                                           *)
(* ------------------------------------------------------------------ *)

and stmt = {
  stmt_desc: stmt_desc;
  stmt_loc:  loc;
}

and stmt_desc =
  | SLet      of ident * ty option * expr * linearity (* let x: T = e *)
  | SGhost    of ident * ty option * expr             (* ghost let x: T = e — proof only, erased in codegen *)
  | SGhostAssign of ident * expr                      (* ghost x = e — mutable ghost update, erased in codegen *)
  | SExpr     of expr
  | SReturn   of expr option
  | SWhile    of expr * pred list * pred option * stmt list
                 (* while cond invariant: P* decreases: Q { body } *)
  | SFor      of ident * expr * pred list * pred option * stmt list
                 (* for x in iter invariant: P* decreases: Q { body } *)
  | SBreak    of expr option                          (* break [val] — value is loop result *)
  | SContinue

and linearity = Lin | Aff | Unr   (* linear, affine, unrestricted *)

(* ------------------------------------------------------------------ *)
(* Proof blocks                                                         *)
(* ------------------------------------------------------------------ *)

and proof_block = {
  pb_lemmas:  lemma list;
  pb_assumes: assume_stmt list;
  pb_loc:     loc;
}

and lemma = {
  lem_name: ident;
  lem_params: (ident * ty) list;
  lem_stmt: pred;
  lem_proof: proof_term;
  lem_loc: loc;
}

and assume_stmt = {
  as_pred:    pred;
  as_context: string option;        (* human-readable justification *)
  as_loc:     loc;
}

and proof_term =
  | PTAxiom                         (* trust me *)
  | PTRefl                          (* reflexivity *)
  | PTSymm   of proof_term
  | PTTrans  of expr * proof_term * proof_term  (* intermediate term, proof a=b, proof b=c *)
  | PTCong   of proof_term list
  | PTWitness of expr               (* exists witness *)
  | PTCase   of expr * proof_term list
  | PTInduct of ident * proof_term * proof_term  (* var, base, step *)
  | PTBy     of ident * proof_term list   (* by lemma_name(args) *)
  | PTAuto                          (* discharge to SMT *)

(* ------------------------------------------------------------------ *)
(* Raw blocks (unsafe)                                                  *)
(* ------------------------------------------------------------------ *)

and raw_block = {
  rb_stmts: stmt list;
  rb_loc:   loc;
}

(* ------------------------------------------------------------------ *)
(* Top-level items                                                      *)
(* ------------------------------------------------------------------ *)

type item = {
  item_desc: item_desc;
  item_loc:  loc;
}

and item_desc =
  | IFn     of fn_def
  | IType   of type_def
  | IConst  of ident * ty * expr    (* const NAME: ty = expr; *)
  | IStruct of struct_def
  | IEnum   of enum_def
  | ITrait  of trait_def            (* trait definition *)
  | IImpl   of impl_def
  | IExtern of extern_def           (* FFI *)
  | IUse    of ident list           (* use path *)

and fn_def = {
  fn_name:     ident;
  fn_generics: (ident * kind) list;  (* <T, N: usize> — KType/KNat generic params *)
  fn_params:   (ident * ty) list;
  fn_ret:      ty;
  fn_requires: pred list;
  fn_ensures:  pred list;
  fn_decreases: pred option;        (* termination measure *)
  fn_body:     expr option;         (* None = extern *)
  fn_attrs:    attr list;
}

and type_def = {
  td_name:   ident;
  td_params: ident list;
  td_ty:     ty;
}

and struct_def = {
  sd_name:   ident;
  sd_params: (ident * kind) list;
  sd_fields: (ident * ty) list;
  sd_invars: pred list;             (* struct invariants — always hold *)
  sd_is_union: bool;                (* true = C union, false = C struct *)
  sd_is_packed: bool;               (* true = __attribute__((packed)) *)
  sd_bitwidths: (string * int) list;  (* field_name -> bit width for bitfields *)
}

and enum_def = {
  ed_name:     ident;
  ed_params:   (ident * kind) list;
  ed_variants: (ident * ty list) list;
}

and impl_def = {
  im_trait:     ident option;           (* None = inherent impl; Some name = trait impl *)
  im_ty:        ty;
  im_assoc_tys: impl_assoc_ty list;     (* type Item = u64; — associated type definitions *)
  im_items:     item list;
}

and extern_def = {
  ex_name: ident;
  ex_ty:   ty;
  ex_link: string;                  (* C symbol name *)
}

and attr = {
  attr_name: string;
  attr_args: string list;
}

and trait_def = {
  tr_name:       ident;
  tr_params:     (ident * kind) list;
  tr_assoc_tys:  ident list;                (* type Item; — associated type declarations *)
  tr_methods:    (ident * fn_ty * expr option) list; (* method name → signature, optional default body *)
}

and impl_assoc_ty = {
  iat_name: ident;
  iat_ty:   ty;
}

and kind =
  | KType                           (* type parameter *)
  | KNat                            (* natural number (dimension) *)
  | KBounded of ident list          (* T: Trait — bounded type parameter *)
  | KConst of ty                    (* const N: u64 — compile-time value parameter *)

(* ------------------------------------------------------------------ *)
(* Compilation unit                                                     *)
(* ------------------------------------------------------------------ *)

type program = {
  prog_items: item list;
  prog_file:  string;
}
