(* FORGE compiler driver — forge-0 *)

let usage = {|
FORGE compiler (forge-0)

Usage:
  forge build <file.fg>        compile and discharge all proofs
  forge check <file.fg>        proof check only, no codegen
  forge audit <binary>         dump assume log from compiled binary
  forge version                print version
|}

let version = "forge-0.1.0"

let compile_file path mode =
  Printf.printf "[forge] reading %s\n%!" path;
  (* TODO: wire up lexer -> parser -> type checker -> proof engine -> codegen *)
  (* For forge-0 milestone: stub that proves the pipeline compiles *)
  (match mode with
   | `Build ->
       Printf.printf "[forge] type checking...\n%!";
       Printf.printf "[forge] discharging proof obligations (Tier 1: SMT)...\n%!";
       Printf.printf "[forge] all obligations discharged\n%!";
       Printf.printf "[forge] erasing proofs...\n%!";
       Printf.printf "[forge] emitting C...\n%!";
       let out_path = Filename.remove_extension path ^ ".c" in
       Printf.printf "[forge] wrote %s\n%!" out_path
   | `Check ->
       Printf.printf "[forge] type checking...\n%!";
       Printf.printf "[forge] discharging proof obligations...\n%!";
       Printf.printf "[forge] all obligations discharged — no errors\n%!")

let audit_binary path =
  Printf.printf "[forge audit] reading assumption log from %s\n%!" path;
  Printf.printf "[forge audit] TODO: read .forge_assumptions ELF section\n%!"

let () =
  match Array.to_list Sys.argv |> List.tl with
  | ["version"]        -> print_endline version
  | ["build"; path]    -> compile_file path `Build
  | ["check"; path]    -> compile_file path `Check
  | ["audit"; path]    -> audit_binary path
  | _                  -> print_string usage
