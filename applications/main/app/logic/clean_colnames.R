box::use(
  stringr[str_to_lower, str_replace_all],
  checkmate[assert_character]
)

#' Clean column names
#' This function takes a character vector and converts it to lower case,
#' and replaces spaces and dashes with underscores.
#' This is necessary because dbplyr can't handle spaces and dashes in column names
#'
#' @param colnames A character vector
#'
#' @return A character vector
#'
#' @export
clean_colnames <- function(colnames) {
  assert_character(colnames, any.missing = FALSE, min.len = 1)
  colnames |>
    str_to_lower() |>
    str_replace_all("(\\s|-)+", "_")
}
