box::use(
  checkmate[assert, assert_character, assert_data_frame, check_character, check_factor],
  dplyr[
    across,
    all_of,
    coalesce,
    cur_column,
    filter,
    group_by,
    group_vars,
    mutate,
    pull,
    transmute,
    ungroup,
  ],
  forcats[fct_relevel],
  purrr[keep, map_int, imap_chr],
  rhino[log],
  stringr[str_sort],
  stats[na.omit],
)

box::use(
  app / logic / constants[UNKNOWN_VALUE],
  app / logic / load_env[config],
)

#' Relevel a character or a factor vector
#' @param x {character|factor} A character or a factor vector
#' @param ordinal_categories {list} A list of ordered categories, uses config.yml by default
#'
#' This functions converts a vector to a factor and relevels it.
#'
#' It will first try to find a matching category order in the ordinal_categories list.
#' Then use the most specific order for relevelling.
#'
#' If the column contains the category "Unknown", it will be relevelled to the last position.
#'
#' If the column has some categories that are not in the ordinal_categories list, it will be
#' relevelled alphabetically.
#'
#' @return {factor} A relevelled factor
#' @export
relevel_vector <- function(x, ordinal_categories = config$categorization$ordinal_categories) {
  assert(
    check_character(x),
    check_factor(x)
  )
  unique_categories <- unique(x)
  clean_unique_categories <- unique_categories[unique_categories != UNKNOWN_VALUE]
  factor_x <- factor(x, levels = unique(str_sort(x, numeric = TRUE)))

  weak_matching_orders <- ordinal_categories |>
    keep(\(category_order) {
      all(clean_unique_categories %in% category_order)
    })

  if (length(weak_matching_orders) > 0) {
    most_specific_order <- weak_matching_orders |>
      map_int(\(category_order) {
        length(setdiff(clean_unique_categories, category_order))
      }) |>
      which.min()

    new_levels <- weak_matching_orders[[most_specific_order]]
    new_levels <- new_levels[new_levels %in% clean_unique_categories]

    factor_x <- fct_relevel(factor_x, new_levels)
  }
  strong_matching_orders <- ordinal_categories |>
    keep(\(category_order) {
      all(na.omit(unique_categories) %in% category_order) ||
        all(category_order %in% unique_categories)
    })

  if (length(strong_matching_orders) > 0) {
    most_specific_order <- strong_matching_orders |>
      map_int(\(category_order) {
        length(setdiff(clean_unique_categories, category_order))
      }) |>
      which.min()

    factor_x <- fct_relevel(factor_x, strong_matching_orders[[most_specific_order]])
  }

  if (UNKNOWN_VALUE %in% unique_categories) {
    factor_x <- fct_relevel(factor_x, UNKNOWN_VALUE, after = Inf)
  }

  factor_x
}

#' Relevel columns of a data frame
#'
#' @param data A data frame
#' @param colnames_to_relevel A character vector of column names to relevel
#' @param ordinal_categories A list of ordered categories, uses config.yml by default
#'
#' @return A data frame with the specified columns relevelled
#'
#' @export
relevel_factors <- function(
    data,
    colnames_to_relevel,
    ordinal_categories = config$categorization$ordinal_categories) {
  assert_data_frame(data)
  if (is.null(colnames_to_relevel)) {
    return(data)
  }
  assert_character(colnames_to_relevel)

  data |>
    mutate(across(all_of(colnames_to_relevel), relevel_vector))
}

#' Get all possible numeric levels based on given breaks
#'
#' This function creates a permutation of all possible bins based on the given breaks.
#' We need to create permutations, because we do not know in advance which section is
#' "closed" and which is "open". Essentially, four options for each bin, see example
#'
#' @example
#' breaks <- c(0, 0.25, 0.5, 0.75, 1)
#' levels <- get_numeric_levels(breaks)
#' print(levels)
#' # [1]  "[0,0.25]"   "(0,0.25]"   "[0,0.25)"   "(0,0.25)"   "[0.25,0.5]"
#' # [6]  "(0.25,0.5]" "[0.25,0.5)" "(0.25,0.5)" "[0.5,0.75]" "(0.5,0.75]"
#' # [11] "[0.5,0.75)" "(0.5,0.75)" "[0.75,1]"   "(0.75,1]"   "[0.75,1)"   "(0.75,1)"
#'
#' @param breaks A vector of breaks.
#' @return A character vector of numeric levels.
#' @export
get_numeric_levels <- function(breaks) {
  expand.grid(
    open_bracket = c("[", "("),
    close_bracket = c("]", ")"),
    bin = imap_chr(breaks, function(x, i) {
      if (i == length(breaks)) {
        return("")
      }
      paste0(x, ",", breaks[i + 1])
    })
  ) |>
    filter(bin != "") |>
    transmute(level = paste(open_bracket, bin, close_bracket, sep = "")) |>
    pull(level)
}
