tictoc::tic("[module] utils")
box::use(
  checkmate[check_true, assert_character, assert_string],
  dplyr[
    across,
    collect,
    distinct,
    everything,
    filter,
    first,
    left_join,
    mutate,
    n,
    pull,
    select,
    setdiff,
    summarise,
    sym,
  ],
  glue[glue],
  purrr[discard, map_lgl, map, partial, flatten, keep],
  rhino[log],
  rlang[syms],
  stats[setNames],
  shiny[validate, need],
  shinycssloaders[withSpinner],
  stringr[str_c],
  tictoc[tic, toc],
  tidyr[expand, unite],
  utils[combn],
)


box::use(
  app / logic / connection[db_con],
  app / logic / constants[UNKNOWN_VALUE],
  app / logic / DataLoader[data_loader],
  app / logic / independence_matrix[independence_matrix],
  app / logic / join_variables[join_variables],
  app / logic / load_env[config],
)

#' Format p-values for display
#' @details This function formats p-values for display. It gets the accuracy from the config file
#' and rounds up to the nearest accuracy. If the p-value is smaller than the accuracy, it displays
#' the p-value in scientific notation.
#' @param pvalues numeric vector of p-values
#' @return character vector of formatted p-values
#' @export
format_pvalues <- function(pvalues) {
  # format display of p-values. If smaller than accuracy, display in scientific notation
  # in other cases display rounded up to accuracy
  accuracy <- config$numbers$decimal_accuracy
  accuracy_as_fraction <- 10^(-accuracy)
  log$debug("accuracy_as_fraction: {accuracy_as_fraction}")

  pvalues <- ifelse(
    pvalues >= accuracy_as_fraction,
    ceiling(
      pvalues / accuracy_as_fraction
    ) * accuracy_as_fraction,
    formatC(pvalues, format = "e")
  )
  return(pvalues)
}

#' @export
bmc_spinner <- partial(withSpinner, color = config$colors$chart_colors[1])

#' To compute fisher matrix, we need to take
#' equity dimensions, join categorical variables,
#' filter by the target feature, subset selected variables
#' then create combinations
#' for status & all other columns in the table
#' @export
compute_fisher_matrix <- function(measure_df, test_variables) {
  log$debug("Computing Fisher's exact test for {paste(test_variables, collapse=',')}") # nolint
  data <- measure_df |>
    join_variables(test_variables) |>
    select(status, all_of(test_variables)) |>
    collect()
  col_pairs <- combn(c("status", test_variables), 2, simplify = FALSE)
  independence_matrix(data, col_pairs)
}

tictoc::toc()

#' This function returns a named list where each item is a variable and values are breaks
#' according to the given category
#' @param variable character vector of variable names
#' @param category character vector of category names
#' @return named list of breaks
#' @example
#' get_percentile_breaks(c("variable", "variable2"), c("Tertiles", "50 - 50"))
#' # list(variable = c(0, 0.33, 0.66, 1), variable2 = c(0, 0.5, 1))
#' @export
get_percentile_breaks <- function(variable, category) {
  if (is.null(category)) {
    return(list())
  }

  check_true(length(variable) == length(category))

  category <- map(category, \(x) {
    if (length(x) != 1) {
      return(NULL)
    }

    if (!x %in% names(config$categorization$numeric_breaks)) {
      return(NULL)
    }
    x
  })

  variable <- unlist(variable[map_lgl(category, ~ !is.null(.x))])
  category <- unlist(category[map_lgl(category, ~ !is.null(.x))])

  breaks <- map(category, \(x) unname(unlist(config$categorization$numeric_breaks[[x]]$values))) |>
    setNames(variable)

  breaks[unlist(lapply(category != "Continuous", isTRUE))]
}

#' This function returns the prefix of the given percentile values from the config file
#' @param percentile_values numeric vector of percentile values
#' @return character prefix
#' @example
#' get_percentile_prefix(c(0, 0.33, 0.66, 1))
#' # "T"
#' @export
get_percentile_prefix <- function(percentile_values) {
  res <- keep(config$categorization$numeric_breaks, \(x) {
    identical(unlist(x$values), percentile_values)
  }) |>
    unname() |>
    unlist() |>
    as.list()
  res$prefix
}

#' This function returns a sequence of integers from 1 to the length-1 of a list item
#' @param percentiles vector or a list containing only one vector
#' @return character vector of integers
#' @export
get_percentile_group_index <- function(percentiles) {
  len <- length(unlist(unname(percentiles))) - 1
  as.character(seq_len(len))
}

#' This function returns the number of rows in a table, it is designed to be used for lazy tables
#' since nrows() is not supported for them
#' @param tbl a table
#' @return number of rows
#' @export
nrows_db <- function(tbl) {
  tbl |>
    summarise(nrows = n()) |>
    pull(nrows) |>
    first()
}

#' This is a simple function that returns an empty character vector if the input vec is NULL
#' @param vec a vector
#' @export
safe_vector_to_json <- function(vec) {
  if (is.null(vec)) character(0) else vec
}

#' This function returns the app name based on the APP_ID environment variable
#' @return character app name
#' @export
get_app_name <- function() {
  app_id <- Sys.getenv("APP_ID", "prod")
  glue("H2E Equity Dashboard ({ app_id })")
}

#' This function replaces the NA and empty strings with the UNKNOWN_VALUE constant
#' @param tbl a table
#' @param cols_to_replace character vector of column names, can be NULL
#' @param replace_with String to replace NA and empty strings with
#' @export
replace_na <- function(tbl, cols_to_replace, replace_with = UNKNOWN_VALUE) {
  assert_character(cols_to_replace, null.ok = TRUE)
  assert_string(replace_with)
  tbl |>
    mutate(across(all_of(cols_to_replace), \(x) {
      coalesce(
        ifelse(as.character(x) == "", NA, as.character(x)),
        !!replace_with
      )
    }))
}
