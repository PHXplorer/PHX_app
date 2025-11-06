box::use(
  checkmate[
    assert,
    assert_character,
    assert_list,
    assert_numeric,
    assert_subset,
    check_class,
    check_data_frame
  ],
  dplyr[
    across,
    all_of,
    any_of,
    collect,
    distinct,
    filter,
    group_by,
    group_split,
    inner_join,
    left_join,
    mutate,
    percent_rank,
    pull,
    rename,
    select,
    summarise,
    ungroup,
    union_all,
    where,
  ],
  purrr[flatten_dbl, keep, map, partial, walk, reduce, map_chr],
  rlang[expr, sym],
  stats[setNames],
  stringr[str_remove],
  tibble[as_tibble],
  tictoc[tic, toc],
  utils[head],
)

box::use(
  app / logic / connection[db_con],
  app / logic / DataLoader[data_loader],
  app / logic / load_env,
  app / logic / utils[get_percentile_prefix, get_percentile_group_index],
)

#' Calculate min, mean and max values for a given column in a lazy tibble
#'
#' @param tbl_lazy A lazy tibble
#' @param columns A character vector of column names to calculate min, mean and max values
#'
#' @details
#' This function will throw an error if min, mean and max values are not unique and sorted.
#'
#' @return A list of min, mean and max values for each column
calculate_average_breaks <- function(tbl_lazy, columns) {
  average_breaks_df <- tbl_lazy |>
    mutate(across(all_of(columns), as.numeric)) |>
    summarise(
      across(
        all_of(columns),
        list(
          min = ~ min(.x, na.rm = TRUE),
          mean = ~ mean(.x, na.rm = TRUE),
          max = ~ max(.x, na.rm = TRUE)
        )
      )
    ) |>
    collect()

  columns |>
    map(\(column) {
      breaks <- c(
        average_breaks_df[[paste0(column, "_min")]],
        average_breaks_df[[paste0(column, "_mean")]],
        average_breaks_df[[paste0(column, "_max")]]
      )
      assert_numeric(breaks, unique = TRUE, len = 3, sorted = TRUE, any.missing = FALSE)
      breaks
    }) |>
    setNames(columns)
}

#' Categorize columns based on list of breaks
#'
#' @param tbl_lazy A lazy tibble
#' @param percentile_columns A named list of percentiles for each column.
#' The names of the list should match the column names in the lazy tibble and the values
#' should be either a numeric vector of percentiles
#'
#' Supplying `percentile_columns` with the following list
#' ````
#' list(
#'  a = c(0, 0.33, 0.66, 1),
#' )
#' ````
#' will result in column `a` being categorized into [0%<a<33%, 33%<a<66%, 66%<a<100%]
#'
#' @param average_columns A character vector of column names to categorize based on the column's
#' average.
#'
#' Supplying `c("a")` to `average_columns` will result in column `a` being categorized into
#' [a<mean(a), a>mean(a)]
#'
#' @details
#' `percentile_columns` and `average_columns` can be both NULL but they can not have intersecting
#' column names. When NULL, the function will not categorize based on that argument.
#'
#' Provided columns will be coerced into FLOAT. We do not check if the columns are numeric and
#' non-scalar to avoid unnecessary queries to the database.
#' It is assumed that the data validation has been already done.
#'
#' @return A lazy tibble where the provided columns are categorized
#'
#' @export
categorize_numeric <- function(tbl_lazy,
                               percentile_columns = NULL,
                               average_columns = NULL) {
  if (!is.null(average_columns)) {
    stop("Usage of average columns is not supported yet")
  }
  assert(
    check_data_frame(tbl_lazy),
    check_class(tbl_lazy, "tbl_lazy")
  )
  assert_list(percentile_columns, null.ok = TRUE)
  if (length(percentile_columns) > 0) {
    percentile_columns |>
      walk(
        partial(
          assert_numeric,
          lower = 0,
          upper = 1,
          unique = TRUE,
          any.missing = FALSE,
          min.len = 2,
          sorted = TRUE
        )
      )
  }
  assert_character(average_columns, null.ok = TRUE)
  columns_to_percentile <- names(percentile_columns)
  columns_to_transform <- c(columns_to_percentile, average_columns)
  assert_character(columns_to_transform, unique = TRUE, null.ok = TRUE)
  if (length(columns_to_transform) == 0) {
    return(tbl_lazy)
  }
  assert_subset(c(columns_to_transform), colnames(tbl_lazy))
  if (length(columns_to_percentile) > 0) {
    ranked_variables <- rank_numerical_variables(tbl_lazy, columns_to_percentile)

    tbl_lazy <- tbl_lazy |>
      select(-all_of(columns_to_percentile))
    tbl_lazy <- reduce(ranked_variables, \(acc, nxt) left_join(acc, nxt), .init = tbl_lazy)
  }

  average_breaks <- NULL
  if (length(average_columns) > 0) {
    average_breaks <- calculate_average_breaks(tbl_lazy, average_columns) |>
      map(unique) |>
      setNames(average_columns)
  }

  names(percentile_columns) <- paste0(names(percentile_columns), "_rank")
  columns_to_cut <- c(percentile_columns, average_breaks)

  # Think about this step as generating an SQL query string
  # We have to generate expressions programmatically because for some reason you can not use
  # `cur_column()` inside dbplyr across to get the value of a list.
  # E.g `!!columns_to_cut[[cur_column()]]` does not work inside dbplyr `across`

  mutate_expression <- names(columns_to_cut) |>
    map(\(column) {
      cut_labels <- paste0(
        get_percentile_prefix(columns_to_cut[[column]]),
        get_percentile_group_index(columns_to_cut[[column]])
      )
      expr(cut(
        x = !!sym(column),
        breaks = !!columns_to_cut[[column]],
        labels = !!cut_labels,
        include.lowest = TRUE
      ))
    }) |>
    setNames(names(columns_to_cut))

  df <- tbl_lazy |>
    mutate(!!!mutate_expression)

  rounding_decimals <- load_env$config$categorization$numeric_precision

  value_ranges_query <- map(names(columns_to_cut), \(column) {
    df |>
      group_by(!!sym(column)) |>
      summarise(
        variable = column,
        categorization = !!sym(column),
        min = round(min(!!sym(str_remove(column, "_rank$")), na.rm = TRUE), rounding_decimals),
        max = round(max(!!sym(str_remove(column, "_rank$")), na.rm = TRUE), rounding_decimals)
      ) |>
      select(-all_of(column))
  }) |>
    reduce(\(acc, nxt) union_all(acc, nxt))

  value_ranges <- collect(value_ranges_query) |>
    group_by(variable) |>
    group_split() |>
    map(\(data) {
      variable <- data$variable[[1]]
      data |>
        mutate(
          !!sym(variable) := categorization,
          label = ifelse(
            is.na(categorization),
            NA,
            paste(categorization, paste0("[", min, ",", max, "]"))
          ),
          .keep = "none"
        )
    })

  reduce(value_ranges, \(accumulated, ranges_df) {
    column <- names(ranges_df)[1]
    columns_to_drop <- c(
      column,
      str_remove(column, "_rank$")
    )
    rename_mapping <- setNames("label", str_remove(column, "_rank$"))
    left_join(accumulated, ranges_df, copy = TRUE) |>
      select(-all_of(columns_to_drop)) |>
      rename(any_of(rename_mapping))
  }, .init = df)
}

#' Generate a list of unique categories resulting from running `categorize_numeric` for each break
#' in config file.
#'
#'
#' This is useful for displaying filtering options in the UI.
#'
#' @export
config_unique_categories_fun <- function(config = load_env$config) {
  tic("config_unique_categories")
  categorization_labels <- map(config$categorization$numeric_breaks, \(x) {
    indices <- get_percentile_group_index(x$values)
    paste0(x$prefix, indices)
  })
  toc()
  categorization_labels
}

#' TODO: Cache it
#' @export
config_unique_categories <- config_unique_categories_fun()


#' Rank numerical variables
#'
#' @param lazy_tbl A lazy tibble to calculate the ranks for
#' @param variables A character vector of column names for which to calculate the ranks
#'
#' @details
#' This function calculates the percent rank for each variable provided in the `variables` argument.
#' The rank is calculated on the source table of the variable but only for the rows that will
#' be joined with the `lazy_tbl` argument.
#'
#' @return list of lazy tibbles where each element of the list corresponds to a source table
#' @export
rank_numerical_variables <- function(lazy_tbl, variables) {
  variable_details <- data_loader$variable_details |>
    filter(colname %in% variables)

  tables <- unique(variable_details$table)

  variable_details |>
    group_split(table) |>
    map(\(variable_details) {
      source_table <- data_loader$get_lazy_table(unique(variable_details$table))
      mutual_columns <- intersect(colnames(source_table), colnames(lazy_tbl))
      join_keys <- setdiff(mutual_columns, variable_details$colname)
      relevant_keys <- lazy_tbl |>
        select(!!join_keys) |>
        distinct()
      source_table |>
        select(mutual_columns) |>
        inner_join(relevant_keys) |>
        mutate(across(
          .cols = variable_details$colname,
          .fns = \(x) percent_rank(x),
          .names = "{.col}_rank"
        ))
    }) |>
    setNames(tables)
}
