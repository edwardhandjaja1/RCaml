
(* The type of tokens. *)

type token = 
  | VAR of (string)
  | TRUE
  | T
  | STRINGLIT of (string)
  | RPAREN
  | READCSV
  | RBRACKET
  | PREDICT
  | PLUS
  | PLOT
  | OR
  | NROW
  | NOT
  | NCOL
  | MULT
  | MINUS
  | MATRIX
  | LPAREN
  | LM
  | LBRACKET
  | INV
  | FLOAT of (float)
  | FALSE
  | EQUAL
  | EOF
  | DIVIDE
  | COMMA
  | C
  | ASSIGNMENT
  | AND

(* This exception is raised by the monolithic API functions. *)

exception Error

(* The monolithic API. *)

val prog: (Lexing.lexbuf -> token) -> Lexing.lexbuf -> (Ast.expr)
