open Batteries

type t = float array array
(** AF: a float array m, where m.(i).(j) repreeents the element at row i + 1 and
    column j + 1 of the matrix representes a matrix M. The matrix has dimensions
    Array.length m by Array.length m.(0).

    RI: Array.length m and Array.length m.(0) >= 1. All elements are valid float
    values. The length of each row and each column is the same. *)

exception NotNumMat

(** [matr_string_header mat] is the string representation of the header which
    shows the number of columns for the matrix in the string representation of
    the matrix. Requires: [mat] is not empty. *)
let matr_string_header mat =
  let string_header = ref "" in
  Array.iteri
    (fun index _ ->
      if index <> 0 then
        string_header := Printf.sprintf "%s [,%i]" !string_header (index + 1)
      else string_header := Printf.sprintf "    [,%i]" (index + 1))
    mat.(0);
  !string_header

let to_float_arr_arr (mat : t) : float array array = mat

let string_of_t (mat : t) : string =
  let row_counter = ref 0 in
  matr_string_header mat
  ^ (Array.map
       (fun row ->
         incr row_counter;
         Printf.sprintf "%s"
           (Array.mapi
              (fun i col ->
                if i = Array.length row - 1 then string_of_float col ^ ""
                else string_of_float col ^ "  ")
              row
           |> Array.fold_left ( ^ ) (Printf.sprintf "\n[%i,] " !row_counter)))
       mat
    |> Array.fold_left ( ^ ) "")

let process_csv (fileName : string) dir : t =
  let string_mat =
    BatFile.lines_of (dir ^ fileName)
    |> BatEnum.map (fun line ->
           line |> String.split_on_char ','
           |> List.filter (fun word -> word <> "")
           |> Array.of_list)
    |> BatList.of_enum |> Array.of_list
  in
  try Array.map (Array.map float_of_string) string_mat
  with _ -> raise NotNumMat

let set_element (arr : t) (row : int) (col : int) new_element : unit =
  try arr.(row - 1).(col - 1) <- new_element
  with Invalid_argument _ -> failwith "Index out of bounds"

let get_element (arr : t) (row : int) (col : int) : float =
  try arr.(row - 1).(col - 1)
  with Invalid_argument _ -> failwith "Index out of bounds"

let matrix (vec : float array) nrow ncol : t =
  if Array.length vec <> nrow * ncol then failwith "Invalid dimensions"
  else Array.init_matrix nrow ncol (fun i j -> vec.((i * ncol) + j))

let nrow (mat : t) = Array.length mat
let ncol (mat : t) = Array.length mat.(0)

let transpose mat : t =
  Array.init_matrix (ncol mat) (nrow mat) (fun i j -> mat.(j).(i))

let get_row (mat : t) nrow = mat.(nrow - 1)

let get_col (mat : t) ncol =
  Array.init (Array.length mat) (fun n -> mat.(n).(ncol - 1))

let dot_product vec1 vec2 =
  let n = Array.length vec1 in
  if n <> Array.length vec2 then failwith "The lengths of vectors don't match!"
  else Array.fold_right ( +. ) (Array.init n (fun i -> vec1.(i) *. vec2.(i))) 0.

let add (lmat : t) (rmat : t) : t =
  Array.mapi
    (fun i row -> Array.mapi (fun j item -> lmat.(i).(j) +. rmat.(i).(j)) row)
    lmat

let subtract lmat rmat =
  Array.mapi
    (fun i row -> Array.mapi (fun j item -> lmat.(i).(j) -. rmat.(i).(j)) row)
    lmat

let multiply lmat rmat =
  if Array.length lmat.(0) <> Array.length rmat then
    failwith "Multiplication cannot be performed on these matrices"
  else
    Array.init_matrix (Array.length lmat)
      (Array.length rmat.(0))
      (fun i j -> dot_product (get_row lmat (i + 1)) (get_col rmat (j + 1)))

let inverse (mat : t) =
  let n = Array.length mat in
  if n <> Array.length mat.(0) then
    failwith "Matrix must be square to compute its inverse"
  else
    let augmented =
      Array.init n (fun i ->
          Array.append mat.(i)
            (Array.init n (fun j -> if i = j then 1. else 0.)))
    in
    for i = 0 to n - 1 do
      let max_row = ref i in
      for k = i + 1 to n - 1 do
        if abs_float augmented.(k).(i) > abs_float augmented.(!max_row).(i) then
          max_row := k
      done;
      let temp = augmented.(i) in
      augmented.(i) <- augmented.(!max_row);
      augmented.(!max_row) <- temp;
      if augmented.(i).(i) >= -1. *. 1e-6 && augmented.(i).(i) <= 1e-6 then
        failwith "Matrix is singular and cannot be inverted";
      let pivot = augmented.(i).(i) in
      for j = 0 to (2 * n) - 1 do
        augmented.(i).(j) <- augmented.(i).(j) /. pivot
      done;
      for k = 0 to n - 1 do
        if k <> i then
          let factor = augmented.(k).(i) in
          for j = 0 to (2 * n) - 1 do
            augmented.(k).(j) <-
              augmented.(k).(j) -. (factor *. augmented.(i).(j))
          done
      done
    done;
    Array.init n (fun i -> Array.sub augmented.(i) n n)

let linear_regression obs response =
  let add_one_col mat =
    Array.init_matrix (Array.length mat)
      (Array.length mat.(0) + 1)
      (fun x y -> if y = 0 then 1. else mat.(x).(y - 1))
  in
  let proj_mat mat =
    multiply (inverse (multiply (transpose mat) mat)) (transpose mat)
  in
  multiply (proj_mat (add_one_col obs)) response

let predict obs response new_vals =
  let betas = linear_regression obs response in
  (multiply
     (matrix
        (Array.append (Array.of_list [ 1. ]) new_vals)
        1
        (Array.length new_vals + 1))
     betas).(0).(0)

let to_expr (mat : t) : Interp.Ast.expr list list =
  Array.to_list
    (Array.map
       (fun row -> Array.to_list (Array.map (fun x -> Interp.Ast.Float x) row))
       mat)

let of_expr (exprs : Interp.Ast.expr list list) : t =
  Array.of_list
    (List.map
       (fun row ->
         Array.of_list
           (List.map
              (function
                | Interp.Ast.Float f -> f
                | _ -> failwith "Invalid expression type in matrix")
              row))
       exprs)
