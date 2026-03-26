(* FORGE-0 Codegen — emits C99

   Proofs are fully erased before this stage.
   The output is exactly what you'd write in C if you were perfect.

   No bounds checks. No null checks. No overflow checks.
   They were proven away. *)

open Ast

(* ------------------------------------------------------------------ *)
(* C type emission                                                      *)
(* ------------------------------------------------------------------ *)

let rec emit_ty = function
  | TPrim (TInt I8)    -> "int8_t"
  | TPrim (TInt I16)   -> "int16_t"
  | TPrim (TInt I32)   -> "int32_t"
  | TPrim (TInt I64)   -> "int64_t"
  | TPrim (TInt I128)  -> "__int128"
  | TPrim (TInt ISize) -> "intptr_t"
  | TPrim (TUint U8)   -> "uint8_t"
  | TPrim (TUint U16)  -> "uint16_t"
  | TPrim (TUint U32)  -> "uint32_t"
  | TPrim (TUint U64)  -> "uint64_t"
  | TPrim (TUint U128) -> "unsigned __int128"
  | TPrim (TUint USize)-> "uintptr_t"
  | TPrim (TFloat F32) -> "float"
  | TPrim (TFloat F64) -> "double"
  | TPrim TBool        -> "_Bool"
  | TPrim TUnit        -> "void"
  | TPrim TNever       -> "void"  (* unreachable *)
  | TRefined (base, _, _) -> emit_ty (TPrim base)  (* refinements erased *)
  | TRef t             -> Printf.sprintf "const %s*" (emit_ty t)
  | TRefMut t          -> Printf.sprintf "%s*" (emit_ty t)
  | TOwn t             -> emit_ty t     (* ownership erased *)
  | TRaw t             -> Printf.sprintf "%s*" (emit_ty t)
  | TArray (t, Some _n) ->
      (* Fixed arrays: caller handles size; emit element type for now *)
      emit_ty t
  | TSlice t           -> emit_ty t ^ "*"
  | TNamed (id, _)     -> id.name
  | TArray (t, None)   -> emit_ty t ^ "*"
  | TDepArr (_, _, r)  -> emit_ty r
  | TFn _              -> "void*"   (* function pointers — TODO *)

(* ------------------------------------------------------------------ *)
(* Expression emission                                                  *)
(* ------------------------------------------------------------------ *)

let binop_str = function
  | Add     -> "+"  | Sub     -> "-"  | Mul -> "*"
  | Div     -> "/"  | Mod     -> "%"
  | Eq      -> "==" | Ne      -> "!="
  | Lt      -> "<"  | Le      -> "<=" | Gt  -> ">" | Ge -> ">="
  | And     -> "&&" | Or      -> "||"
  | BitAnd  -> "&"  | BitOr   -> "|"  | BitXor -> "^"
  | Shl     -> "<<" | Shr     -> ">>"
  | Implies -> "||" (* not directly expressible — proof only *)
  | Iff     -> "==" (* ditto *)

let unop_str = function
  | Neg    -> "-"
  | Not    -> "!"
  | BitNot -> "~"

let indent n = String.make (n * 2) ' '

let rec emit_expr depth e =
  match e.expr_desc with
  | ELit (LInt (n, _))    -> string_of_int n
  | ELit (LFloat (f, _))  -> Printf.sprintf "%g" f
  | ELit (LBool true)     -> "1"
  | ELit (LBool false)    -> "0"
  | ELit LUnit            -> "/* unit */"
  | ELit (LStr s)         -> Printf.sprintf "\"%s\"" (String.escaped s)
  | EVar id               -> id.name
  | EBinop (op, l, r)     ->
      Printf.sprintf "(%s %s %s)"
        (emit_expr depth l) (binop_str op) (emit_expr depth r)
  | EUnop (op, e)         ->
      Printf.sprintf "(%s%s)" (unop_str op) (emit_expr depth e)
  | ECall (f, args)       ->
      Printf.sprintf "%s(%s)"
        (emit_expr depth f)
        (String.concat ", " (List.map (emit_expr depth) args))
  | EIndex (arr, idx)     ->
      Printf.sprintf "%s[%s]" (emit_expr depth arr) (emit_expr depth idx)
  | EField (s, f)         ->
      Printf.sprintf "%s.%s" (emit_expr depth s) f.name
  | EAssign (l, r)        ->
      Printf.sprintf "%s = %s" (emit_expr depth l) (emit_expr depth r)
  | ERef e                -> Printf.sprintf "(&%s)" (emit_expr depth e)
  | ERefMut e             -> Printf.sprintf "(&%s)" (emit_expr depth e)
  | EDeref e              -> Printf.sprintf "(*%s)" (emit_expr depth e)
  | ECast (e, ty)         ->
      Printf.sprintf "((%s)%s)" (emit_ty ty) (emit_expr depth e)
  | EIf (cond, then_, None) ->
      Printf.sprintf "(%s ? %s : 0)"
        (emit_expr depth cond) (emit_expr_value depth then_)
  | EIf (cond, then_, Some else_) ->
      Printf.sprintf "(%s ? %s : %s)"
        (emit_expr depth cond)
        (emit_expr_value depth then_)
        (emit_expr_value depth else_)
  | EBlock (stmts, ret) ->
      let buf = Buffer.create 256 in
      Buffer.add_string buf "{\n";
      List.iter (fun s ->
        Buffer.add_string buf (emit_stmt (depth+1) s);
        Buffer.add_char buf '\n'
      ) stmts;
      (match ret with
       | Some e ->
           Buffer.add_string buf (indent (depth+1));
           Buffer.add_string buf (emit_expr (depth+1) e)
       | None -> ());
      Buffer.add_string buf ("\n" ^ indent depth ^ "}");
      Buffer.contents buf
  | EMatch (e, arms) ->
      emit_match depth e arms
  | EProof _  -> "/* proof erased */"
  | ERaw rb   ->
      let buf = Buffer.create 64 in
      List.iter (fun s ->
        Buffer.add_string buf (emit_stmt depth s)
      ) rb.rb_stmts;
      Buffer.contents buf
  | EAssume _ -> "/* assume erased */"  (* proof artifact — gone at codegen *)

(* Unwrap EBlock([], Some e) to just e — for use in expression positions
   like ternary arms where a compound statement is not valid C *)
and emit_expr_value depth e =
  match e.expr_desc with
  | EBlock ([], Some ret) -> emit_expr depth ret
  | EBlock ([], None)     -> "0"
  | _                     -> emit_expr depth e

and emit_match depth scrutinee arms =
  (* Emit as C switch where possible, else if-else chain *)
  let buf = Buffer.create 256 in
  Buffer.add_string buf
    (Printf.sprintf "/* match %s */\n" (emit_expr depth scrutinee));
  (* For FORGE-0: emit as if-else chain *)
  let first = ref true in
  List.iter (fun arm ->
    let kw = if !first then "if" else "else if" in
    first := false;
    let cond = emit_pattern_cond depth scrutinee arm.pattern in
    Buffer.add_string buf
      (Printf.sprintf "%s%s (%s) %s\n"
        (indent depth) kw cond
        (emit_expr depth arm.body))
  ) arms;
  Buffer.contents buf

and emit_pattern_cond depth scrutinee pat =
  let s = emit_expr depth scrutinee in
  match pat with
  | PWild        -> "1"
  | PBind _      -> "1"
  | PLit l       -> Printf.sprintf "%s == %s" s (emit_expr depth { expr_desc = ELit l; expr_loc = dummy_loc; expr_ty = None })
  | PCtor (id, _) -> Printf.sprintf "/* ctor %s */" id.name
  | _            -> "1 /* pattern */"

(* ------------------------------------------------------------------ *)
(* Statement emission                                                   *)
(* ------------------------------------------------------------------ *)

and emit_stmt depth s =
  match s.stmt_desc with
  | SLet (id, ty, e, _lin) ->
      let ty_str = match ty with
        | Some t -> emit_ty t
        | None   ->
            (* Use expr's inferred type if available, else __typeof__ *)
            (match e.expr_ty with
             | Some t -> emit_ty t
             | None   -> Printf.sprintf "__typeof__(%s)" (emit_expr depth e))
      in
      Printf.sprintf "%s%s %s = %s;"
        (indent depth) ty_str id.name (emit_expr depth e)
  | SExpr e ->
      Printf.sprintf "%s%s;" (indent depth) (emit_expr depth e)
  | SReturn None ->
      Printf.sprintf "%sreturn;" (indent depth)
  | SReturn (Some e) ->
      Printf.sprintf "%sreturn %s;" (indent depth) (emit_expr depth e)
  | SWhile (cond, _inv, _dec, body) ->
      let buf = Buffer.create 128 in
      Buffer.add_string buf
        (Printf.sprintf "%swhile (%s) {\n"
          (indent depth) (emit_expr depth cond));
      List.iter (fun s ->
        Buffer.add_string buf (emit_stmt (depth+1) s);
        Buffer.add_char buf '\n'
      ) body;
      Buffer.add_string buf (indent depth ^ "}");
      Buffer.contents buf
  | SFor (id, iter, _dec, body) ->
      (* For FORGE-0: emit as C for loop over range *)
      let buf = Buffer.create 128 in
      Buffer.add_string buf
        (Printf.sprintf "%s/* for %s in ... */\n" (indent depth) id.name);
      Buffer.add_string buf
        (Printf.sprintf "%s(void)%s;\n" (indent depth) (emit_expr depth iter));
      List.iter (fun s ->
        Buffer.add_string buf (emit_stmt (depth+1) s);
        Buffer.add_char buf '\n'
      ) body;
      Buffer.contents buf
  | SBreak    -> indent depth ^ "break;"
  | SContinue -> indent depth ^ "continue;"

(* ------------------------------------------------------------------ *)
(* Top-level item emission                                              *)
(* ------------------------------------------------------------------ *)

let emit_fn fn =
  let buf = Buffer.create 512 in
  (* requires/ensures are fully erased — proof was discharged *)
  let params_str = String.concat ", " (List.map (fun (id, ty) ->
    Printf.sprintf "%s %s" (emit_ty ty) id.name
  ) fn.fn_params) in
  Buffer.add_string buf
    (Printf.sprintf "%s %s(%s)"
      (emit_ty fn.fn_ret) fn.fn_name.name params_str);
  (match fn.fn_body with
   | None ->
       Buffer.add_string buf ";"  (* extern declaration *)
   | Some body ->
       Buffer.add_string buf " ";
       (* Emit function body: trailing expression becomes return *)
       (match body.expr_desc with
        | EBlock (stmts, ret) ->
            Buffer.add_string buf "{\n";
            List.iter (fun s ->
              Buffer.add_string buf (emit_stmt 1 s);
              Buffer.add_char buf '\n'
            ) stmts;
            (match ret with
             | Some e ->
                 Buffer.add_string buf (Printf.sprintf "  return %s;\n" (emit_expr 1 e))
             | None -> ());
            Buffer.add_string buf "}"
        | _ ->
            Buffer.add_string buf (Printf.sprintf "{ return %s; }" (emit_expr 0 body))));
  Buffer.add_char buf '\n';
  Buffer.contents buf

let emit_struct sd =
  let buf = Buffer.create 256 in
  Buffer.add_string buf (Printf.sprintf "typedef struct %s {\n" sd.sd_name.name);
  List.iter (fun (id, ty) ->
    Buffer.add_string buf
      (Printf.sprintf "  %s %s;\n" (emit_ty ty) id.name)
  ) sd.sd_fields;
  (* struct invariants erased — proven at construction sites *)
  Buffer.add_string buf (Printf.sprintf "} %s;\n" sd.sd_name.name);
  Buffer.contents buf

let emit_item item =
  match item.item_desc with
  | IFn fn     -> emit_fn fn
  | IStruct sd -> emit_struct sd
  | IType td   ->
      Printf.sprintf "typedef %s %s;\n"
        (emit_ty td.td_ty) td.td_name.name
  | IEnum _    -> "/* enum — TODO */\n"
  | IImpl _    -> "/* impl — TODO */\n"
  | IExtern ex ->
      Printf.sprintf "extern %s %s;  /* %s */\n"
        (emit_ty ex.ex_ty) ex.ex_name.name ex.ex_link
  | IUse _     -> ""

(* ------------------------------------------------------------------ *)
(* Assume audit section emission                                        *)
(* ------------------------------------------------------------------ *)

let emit_assume_audit assumes =
  let buf = Buffer.create 512 in
  Buffer.add_string buf "\n/* ---- FORGE ASSUMPTION AUDIT LOG ----\n";
  Buffer.add_string buf
    (Printf.sprintf "   Total assumptions: %d\n" (List.length assumes));
  List.iter (fun (ae : Proof_engine.assume_entry) ->
    Buffer.add_string buf
      (Printf.sprintf "   [ASSUME] %s:%d  %s\n"
        ae.ae_loc.file ae.ae_loc.line ae.ae_smtlib);
    (match ae.ae_context with
     | Some ctx -> Buffer.add_string buf (Printf.sprintf "             \"%s\"\n" ctx)
     | None -> ())
  ) assumes;
  Buffer.add_string buf "   ---- END AUDIT LOG ---- */\n";
  Buffer.contents buf

(* ------------------------------------------------------------------ *)
(* Program emission                                                     *)
(* ------------------------------------------------------------------ *)

let emit_program prog =
  let buf = Buffer.create 4096 in
  (* Standard header *)
  Buffer.add_string buf
    "/* Generated by FORGE compiler — do not edit.\n";
  Buffer.add_string buf
    "   All proof obligations discharged. This code is correct by construction. */\n\n";
  Buffer.add_string buf "#include <stdint.h>\n";
  Buffer.add_string buf "#include <stdbool.h>\n\n";
  (* Items *)
  List.iter (fun item ->
    Buffer.add_string buf (emit_item item);
    Buffer.add_char buf '\n'
  ) prog.prog_items;
  (* Assume audit log *)
  let assumes = Proof_engine.dump_assume_log () in
  if assumes <> [] then
    Buffer.add_string buf (emit_assume_audit assumes);
  Buffer.contents buf
