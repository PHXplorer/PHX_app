box::use(
  dplyr[group_by, group_map, collect],
  purrr[list_c],
  checkmate[assert_data_frame, assert, check_string],
  stats[setNames]
)

#' Create choices from variable details
#'
#' This function takes a data frame of variable details and returns a list of choices
#' to be used in pickerInput.
#'
#' @param variable_details A data frame with columns colname, Label, and category
#' @param colname_col The name of the column containing the variable names
#' @param label_col The name of the column containing the variable labels
#' @param category_col The name of the column containing the variable categories
#'
#' @return A list where each element is a category containing a named character vector
#'
#' @export
variable_details_to_choices <- function(
    variable_details,
    colname_col = "colname",
    label_col = "label",
    category_col = "category") {
  assert_data_frame(variable_details)
  assert(
    check_string(colname_col),
    check_string(label_col),
    check_string(category_col),
    combine = "and"
  )
  required_columns <- c(colname_col, label_col, category_col)
  missing_columns <- setdiff(required_columns, colnames(variable_details))
  if (length(missing_columns) > 0) {
    stop(
      "The variable_details data frame is missing the following columns: ",
      paste(missing_columns, collapse = ", ")
    )
  }
  variable_details |>
    group_by(category) |>
    group_map(\(x, y) {
      setNames(x[[colname_col]], x[[label_col]]) |>
        list() |>
        setNames(y[[category_col]])
    }) |>
    list_c()
}
