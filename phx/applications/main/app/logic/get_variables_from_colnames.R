box::use(
  dplyr[select, left_join, mutate, coalesce],
  stats[setNames],
  purrr[map_chr],
)

box::use(
  app / logic / DataLoader[data_loader],
)

#' Helper function to look up interaction variable constituents' labels
get_interaction_label <- function(colnames, labels, sep = ":") {
  map_chr(colnames, function(x) {
    split <- unlist(strsplit(x, sep))
    if (length(split) == 1) {
      return(NA)
    }
    paste(
      labels[which(colnames == split[1])],
      labels[which(colnames == split[2])],
      sep = sep
    )
  })
}


#' Get Variables from Column Names
#'
#' This function retrieves variable names from a given set of column names.
#'
#' @param colnames A character vector containing the column names to be matched.
#' @param names_only A logical value. If TRUE, the function returns only the variable names.
#'                   If FALSE (default), the function returns a named vector where the names
#'                   are the variable names and the values are the original column names.
#' @return If `names_only` is TRUE, a character vector containing the variable names.
#'         If `names_only` is FALSE, a named vector where the names are the variable names
#'         and the values are the original column names.
#' @export
get_variables_from_colnames <- function(colnames, names_only = FALSE) {
  selected_variables <- data.frame(colname = colnames) |>
    left_join(data_loader$variable_details, by = "colname") |>
    mutate(interaction_label = get_interaction_label(colname, label)) |>
    mutate(label = coalesce(label, interaction_label, colname)) |>
    select(colname, label)

  if (names_only) {
    selected_variables$label
  } else {
    setNames(selected_variables$colname, selected_variables$label)
  }
}
