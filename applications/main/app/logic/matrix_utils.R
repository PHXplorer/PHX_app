#' Create an empty square matrix
#'
#' This function creates an empty square matrix of a given order with specific row and column names
#'
#' @param names A character vector specifying the row and column names of the matrix.
#' @param vector vector to fill the matrix with
#'
#' @return A square matrix with dimensions `n`x`n` with row and column names specified by `names`.
#'
#' @examples
#' \dontrun{
#'   create_matrix(c("a", "b", "c"))
#' }
#'
#' @export
create_matrix <- function(names, vector = NA) {
  mat <- matrix(data = vector, nrow = length(names), ncol = length(names))
  rownames(mat) <- names
  colnames(mat) <- names
  mat
}

#' Set matrix value from pair
#'
#' This function sets the value for a pair of positions in a matrix.
#' It fills both the lower and upper triangle.
#'
#' @param mat A matrix where the value is to be set.
#' @param pair A character vector of length 2 specifying the row and column names
#' where the value should be set.
#' @param value The value to be set in the specified positions in the matrix.
#'
#' @return The input matrix `mat` with the value `value` set in the positions specified by `pair`.
#'
#' @examples
#' \dontrun{
#'   mat <- matrix(1:9, nrow=3)
#'   rownames(mat) <- colnames(mat) <- c("a", "b", "c")
#'   set_matrix_value_from_pair(mat, c("a", "b"), 10)
#' }
#'
#' @export
set_matrix_value_from_pair <- function(mat, pair, value) {
  stopifnot(length(pair) == 2)
  stopifnot(
    "pair must be present in the matrix" =
      all(pair %in% rownames(mat)) && all(pair %in% colnames(mat))
  )
  mat[pair[2], pair[1]] <- value # lower triangle
  mat
}

box::use(shiny[validate, need])

#' Replace Dimension Names in a Matrix
#'
#' Replaces specified row and column names in a matrix with new names.
#'
#' @param matrix A matrix with named rows and columns.
#' @param current_names A character vector of current names to be replaced.
#' @param new_names A character vector of new names to replace the current names. Must be the same
#' length as current_names.
#' @return A matrix with the replaced dimension names.
#' @export
replace_matrix_dim_names <- function(matrix, current_names, new_names) {
  validate(
    need(
      length(current_names) == length(new_names),
      "Please recalculate Fisher's results, as we don't have it in cache."
    )
  )

  non_existing_colnames <- setdiff(current_names, colnames(matrix))
  non_existing_rownames <- setdiff(current_names, rownames(matrix))
  if (length(non_existing_colnames) > 0) {
    stop(
      paste(non_existing_colnames, collapse = ", "), "are missing from column names of the matrix"
    )
  }
  if (length(non_existing_rownames) > 0) {
    stop(paste(non_existing_rownames, collapse = ", "), "are missing from row names of the matrix")
  }
  names_in_col <- which(colnames(matrix) %in% current_names)
  names_in_row <- which(rownames(matrix) %in% current_names)
  if (length(names_in_col) > 0) {
    colnames(matrix)[names_in_row] <- new_names
  }
  if (length(names_in_row) > 0) {
    rownames(matrix)[names_in_col] <- new_names
  }
  matrix
}
