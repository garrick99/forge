(* FORGE compiler driver
   Pipeline: source -> lex -> parse -> typecheck -> prove -> erase -> emit C *)

open Typecheck
open Proof_engine
open Codegen_c

let version = "forge-0.1.0"

let usage = {|
FORGE compiler (forge-0)

Usage:
  forge build <file.fg>      compile: prove all obligations, emit C
  forge check <file.fg>      proof check only — no codegen
  forge audit <file.c>       dump assume log from generated C
  forge version              print version info
|}

(* ------------------------------------------------------------------ *)
(* Parse a source file                                                  *)
(* ------------------------------------------------------------------ *)

let parse_file path =
  let ic = open_in path in
  let lexbuf = Lexing.from_channel ic in
  Lexing.set_filename lexbuf path;
  (* Token wrapper: splits >> into > > for nested generic type args.
     Tracks angle-bracket depth; when depth >= 2 and >> (SHR) appears,
     emits two GT tokens so e.g. span<span<u32>> parses correctly. *)
  let angle_depth = ref 0 in
  let pending : Token.token option ref = ref None in
  let prev_tok  : Token.token ref = ref Token.EOF in
  let prev2_tok : Token.token ref = ref Token.EOF in
  (* Count '<' as a generic open when it follows a type-introducing position.
     Built-in type constructors (span, ref, etc.) are always type-introducing.
     An IDENT is type-introducing when preceded by ':', '->', '<', or ',' —
     the positions where a named generic type can legally appear. *)
  let is_type_lt () = match !prev_tok with
    | Token.SPAN | Token.REF | Token.REFMUT | Token.OWN | Token.RAW_TY | Token.RAW
    | Token.SHARED | Token.UNIFORM | Token.VARYING | Token.COALESCED -> true
    | Token.IDENT _ ->
        (* Allow IDENT<T> when IDENT appears in a type position.
           Type positions are introduced by ':', '->', '<', ',', '(' *)
        (match !prev2_tok with
         | Token.COLON | Token.ARROW | Token.LT | Token.COMMA | Token.LPAREN -> true
         | _ -> !angle_depth > 0)   (* inside an already-open generic: also allow *)
    | _ -> false
  in
  let tok_supplier lb =
    let tok = match !pending with
      | Some t -> pending := None; t
      | None   -> Lexer.token lb
    in
    let result = match tok with
    | Token.LT when is_type_lt () -> incr angle_depth; tok
    | Token.GT  -> if !angle_depth > 0 then decr angle_depth; tok
    | Token.SHR when !angle_depth >= 2 ->
        (* Split >> into two GTs: return first, queue second *)
        decr angle_depth;
        pending := Some Token.GT;
        Token.GT
    | other -> other
    in
    prev2_tok := !prev_tok;
    prev_tok  := result;
    result
  in
  (try
    let prog = Parser.program tok_supplier lexbuf in
    close_in ic;
    { prog with Ast.prog_file = path }
  with
  | Lexer.LexError (msg, pos) ->
      close_in ic;
      Printf.eprintf "%s:%d:%d: lex error: %s\n"
        path pos.pos_lnum (pos.pos_cnum - pos.pos_bol) msg;
      exit 1
  | Parser.Error ->
      close_in ic;
      let pos = Lexing.lexeme_start_p lexbuf in
      Printf.eprintf "%s:%d:%d: parse error near '%s'\n"
        path pos.pos_lnum (pos.pos_cnum - pos.pos_bol)
        (Lexing.lexeme lexbuf);
      exit 1)

(* ------------------------------------------------------------------ *)
(* Module resolution — IUse file inclusion                             *)
(* ------------------------------------------------------------------ *)

(* Tracks canonical paths already loaded; prevents cycles *)
let loaded_files : string list ref = ref []

(* Load a .fg file and recursively resolve its uses.
   base_dir: directory of the file that contains the 'use' directive.
   path_parts: the ident list from 'use foo::bar' — becomes "foo/bar.fg". *)
let rec load_module base_dir (path_parts : Ast.ident list) =
  let rel = (String.concat "/" (List.map (fun id -> id.Ast.name) path_parts)) ^ ".fg" in
  let canonical =
    if Filename.is_relative rel then Filename.concat base_dir rel
    else rel
  in
  if List.mem canonical !loaded_files then begin
    []   (* already loaded — skip to break cycles *)
  end else begin
    loaded_files := canonical :: !loaded_files;
    if not (Sys.file_exists canonical) then begin
      Printf.eprintf "[forge] use: file not found: %s\n" canonical;
      exit 1
    end;
    let prog = parse_file canonical in
    let dir  = Filename.dirname canonical in
    resolve_uses dir prog.Ast.prog_items
  end

(* Expand IUse items by splicing in the referred file's items. *)
and resolve_uses base_dir items =
  List.concat_map (fun (item : Ast.item) ->
    match item.Ast.item_desc with
    | Ast.IUse path_parts ->
        (* Replace the IUse node with the included file's items *)
        load_module base_dir path_parts
    | _ -> [item]
  ) items

(* ------------------------------------------------------------------ *)
(* Compile pipeline                                                     *)
(* ------------------------------------------------------------------ *)

let compile path emit_code =
  Printf.printf "[forge] %s\n%!" path;
  loaded_files := [];            (* reset module cycle tracker *)
  Codegen_c.reset_codegen_state (); (* reset enum registries (may be stale from check-only mode) *)

  (* 1. Parse *)
  Printf.printf "[forge] parsing...\n%!";
  let raw = parse_file path in
  let base_dir = Filename.dirname path in
  let resolved_items = resolve_uses base_dir raw.Ast.prog_items in
  let prog = { raw with Ast.prog_items = resolved_items } in
  Printf.printf "[forge] parsed %d top-level items\n%!"
    (List.length prog.Ast.prog_items);

  (* 2. Type check + generate proof obligations *)
  Printf.printf "[forge] type checking...\n%!";
  let (tc_errors, obligations, extra_items) = typecheck_program prog in
  let prog = { prog with Ast.prog_items = prog.Ast.prog_items @ extra_items } in

  if tc_errors <> [] then begin
    Printf.eprintf "[forge] type errors:\n";
    List.iter (fun e ->
      match e with
      | TypeError (loc, msg) ->
          Printf.eprintf "  %s:%d:%d: %s\n" loc.file loc.line loc.col msg
      | LinearityError (loc, msg) ->
          Printf.eprintf "  %s:%d:%d: linearity: %s\n" loc.file loc.line loc.col msg
      | UnboundVar (loc, name) ->
          Printf.eprintf "  %s:%d:%d: unbound variable '%s'\n"
            loc.file loc.line loc.col name
      | UnboundFn (loc, name) ->
          Printf.eprintf "  %s:%d:%d: unbound function '%s'\n"
            loc.file loc.line loc.col name
      | ArityMismatch (loc, fn, exp, got) ->
          Printf.eprintf "  %s:%d:%d: '%s' expects %d args, got %d\n"
            loc.file loc.line loc.col fn exp got
      | ProofError pe ->
          Printf.eprintf "  %s\n" (format_error pe)
    ) tc_errors;
    exit 1
  end;

  Printf.printf "[forge] %d proof obligations generated\n%!"
    (List.length obligations);

  (* 3. Discharge proof obligations *)
  Printf.printf "[forge] discharging proof obligations...\n%!";
  let env = empty_env in
  let summary = discharge_all obligations env in

  (if summary.ds_vacuous > 0 then
    Printf.printf "[forge] proof summary: %d total, %d SMT, %d guided, %d manual, %d failed, %d vacuous\n%!"
      summary.ds_total summary.ds_tier1 summary.ds_tier2 summary.ds_tier3
      summary.ds_failed summary.ds_vacuous
  else
    Printf.printf "[forge] proof summary: %d total, %d SMT, %d guided, %d manual, %d failed\n%!"
      summary.ds_total summary.ds_tier1 summary.ds_tier2 summary.ds_tier3 summary.ds_failed);

  if summary.ds_failed > 0 || summary.ds_vacuous > 0 then begin
    let n = summary.ds_failed + summary.ds_vacuous in
    Printf.eprintf "[forge] %d proof obligation(s) could not be discharged\n" n;
    Printf.eprintf "[forge] compilation stopped — fix proof failures before proceeding\n";
    exit 1
  end;

  Printf.printf "[forge] all obligations discharged\n%!";

  if not emit_code then begin
    Printf.printf "[forge] check complete — no errors\n%!";
    ()
  end else begin
    (* 4. Erase proofs and emit C / CUDA C *)
    Printf.printf "[forge] erasing proofs...\n%!";
    let (code, is_cuda) = emit_program prog in
    let ext = if is_cuda then ".cu" else ".c" in
    Printf.printf "[forge] emitting %s...\n%!" (if is_cuda then "CUDA C" else "C99");
    let out_path = Filename.remove_extension path ^ ext in
    let oc = open_out out_path in
    output_string oc code;
    close_out oc;
    Printf.printf "[forge] wrote %s\n%!" out_path;
    if is_cuda then begin
      Printf.printf "[forge] compile with: nvcc -arch=sm_120 %s\n%!" out_path;
      (* Also emit PTX for #[kernel] functions *)
      let ptx = Codegen_ptx.emit_ptx_program prog.prog_items 120 in
      if ptx <> "" then begin
        let ptx_path = Filename.remove_extension path ^ ".ptx" in
        let ocp = open_out ptx_path in
        output_string ocp ptx;
        close_out ocp;
        Printf.printf "[forge] wrote %s\n%!" ptx_path;
        Printf.printf "[forge] validate: ptxas --gpu-name sm_120 --compile-only %s\n%!" ptx_path
      end
    end;

    (* 5. Report assume audit *)
    let assumes = dump_assume_log () in
    if assumes = [] then
      Printf.printf "[forge] assume audit: 0 assumptions (clean)\n%!"
    else begin
      Printf.printf "[forge] assume audit: %d assumption(s) — run 'forge audit %s' for details\n%!"
        (List.length assumes) out_path
    end
  end

(* ------------------------------------------------------------------ *)
(* Audit subcommand                                                     *)
(* ------------------------------------------------------------------ *)

let audit path =
  (* Read the .forge_assumptions section from the generated C file
     (embedded as a comment block by the codegen) *)
  Printf.printf "[forge audit] %s\n%!" path;
  let ic = open_in path in
  let found = ref false in
  (try
    while true do
      let line = input_line ic in
      if String.length line >= 22 &&
         String.sub line 0 22 = "/* ---- FORGE ASSUMPTI" then begin
        found := true;
        print_endline line;
        (try
          while true do
            let l = input_line ic in
            print_endline l;
            if String.length l >= 19 &&
               String.sub l 0 19 = "   ---- END AUDIT L" then
              raise Exit
          done
        with Exit | End_of_file -> ())
      end
    done
  with End_of_file -> ());
  close_in ic;
  if not !found then
    Printf.printf "[forge audit] no assumption log found in %s\n\
                   (file may not be FORGE-generated or has 0 assumptions)\n%!" path

(* ------------------------------------------------------------------ *)
(* Entry point                                                          *)
(* ------------------------------------------------------------------ *)

let () =
  match Array.to_list Sys.argv |> List.tl with
  | ["version"]      ->
      Printf.printf "forge %s\n" version;
      Printf.printf "  Calculus of Constructions proof kernel\n";
      Printf.printf "  Z3 SMT backend (Tier 1 automatic)\n";
      Printf.printf "  Target: C99\n"
  | ["build"; path]  -> compile path true
  | ["check"; path]  -> compile path false
  | ["audit"; path]  -> audit path
  | []               -> print_string usage
  | args             ->
      Printf.eprintf "unknown command: %s\n" (String.concat " " args);
      print_string usage;
      exit 1
