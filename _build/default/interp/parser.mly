%{
    [@@@coverage exclude_file]
    open Ast
%}

%token <float> FLOAT
%token <string> VAR
%token <string> STRINGLIT
%token PLUS
%token MINUS
%token MULT
%token DIVIDE
%token ASSIGNMENT
%token LPAREN
%token RPAREN
%token COMMA
%token C
%token EOF
%token TRUE
%token FALSE
%token AND
%token OR
%token NOT
%token READCSV
%token PLOT
%token LBRACKET
%token RBRACKET
%token MATRIX
%token EQUAL
%token NROW
%token NCOL
%token INV
%token T
%token LM
%token PREDICT

%nonassoc ASSIGNMENT
// nonassoc, no defined behavior for multiple assignments in the same expression
%left PLUS
%left MINUS
%left MULT
%left DIVIDE
%left OR
%left AND
%right NOT

%start <Ast.expr> prog
%%

prog:
    | e = line; EOF { e };

line:
    | e = value { e }
    | e = binop { e }
    | e = unop { e } 
    | LPAREN; e = line; RPAREN { e }
    // figure out how to get rid of the shift reduce conflict here
    | C; LPAREN; v = vector_values; RPAREN { Vector (v)}
    | READCSV; LPAREN; e = line; RPAREN { Readcsv (e) }
    | PLOT; LPAREN; v1 = line; COMMA; v2 = line; COMMA; name = line; RPAREN { Plot (v1, v2, name)}
    | MATRIX; LPAREN; vec = line; COMMA; NROW; EQUAL; rown = line; COMMA; NCOL; EQUAL; coln = line; RPAREN { FlatMatrix (vec, rown, coln) }
    | INV; LPAREN; matrix = line; RPAREN { Unop (MatrixInverse, matrix ) }
    | T; LPAREN; matrix = line; RPAREN { Unop (MatrixTranspose, matrix)}
    | LM; LPAREN; obs = line; COMMA; responses = line; RPAREN { LinearModel (obs, responses) }
    | PREDICT; LPAREN; obs = line; COMMA; responses = line; COMMA; values = line; RPAREN { Predict (obs, responses, values) }

binop:
    | e1 = line; MULT; e2 = line { Binop (Mult, e1, e2) }
    | e1 = line; PLUS; e2 = line { Binop (Add, e1, e2) }
    | e1 = line; DIVIDE; e2 = line { Binop (Div, e1, e2) }
    | e1 = line; MINUS; e2 = line { Binop (Minus, e1, e2) }
    | e1 = line; ASSIGNMENT; e2 = line { Assignment (e1, e2) }
    | e1 = line; AND; e2 = line { Binop (And, e1, e2) }
    | e1 = line; OR; e2 = line { Binop (Or, e1, e2) }

unop:
    | NOT; e1 = line { Unop (Not, e1) }
    | e = value; LBRACKET; row_index = value; COMMA; col_index = value; RBRACKET { Unop (MatrixIndex (row_index, col_index), e)}

value:
    | f = FLOAT { Float f }
    | v = VAR { Var v }
    | C { Var "c" }
    | FALSE { Bool (false)}
    | TRUE { Bool (true) }
    | e = STRINGLIT { String e }

vector_values:
    | { [] }
    | v = line { v :: [] }
    | v1 = line; COMMA; v2 = vector_values {v1 :: v2}
