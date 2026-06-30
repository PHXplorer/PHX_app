box::use(
  checkmate[
    assert_character,
    assert_class,
    assert_data_frame,
    assert_list,
    assert_subset
  ],
  purrr[map, walk, reduce],
  dplyr[
    all_of,
    coalesce,
    filter,
    group_by,
    group_map,
    left_join,
    mutate,
    rename_with,
    select,
    summarise,
  ],
  rlang[expr, sym],
  stats[setNames],
  stringr[str_to_lower],
  dbplyr[dbplyr_pivot_wider_spec]
)

box::use(
  app / logic / constants[UNKNOWN_VALUE],
  app / logic / DataLoader,
  app / logic / clean_colnames[clean_colnames],
  app / logic / pivot_wider_specs[names_from_featureid_spec],
)


#' Join variables to a base table dynamically
#'
#' This function joins variables to a base table dynamically.
#'
#' The variables that are already in the base table, will not joined.
#'
#' If the table is health_dimensions, it will pivot the table to wide format and join the relevant
#' health dimensions to the base table as columns.
#'
#' @param base_table A lazy table to which the variables will be joined. It must have common columns
#' with the tables in tbl_list
#' @param colnames_to_join A character vector of column names to join to base_table. If NULL, the
#' function will return base_table without joining any variables
#' @param data_loader data_loader object containing the variable details and tbl_list
#'
#' @export
join_variables <- function(
    base_table,
    colnames_to_join,
    data_loader = DataLoader$data_loader) {
  assert_class(base_table, "tbl_lazy")
  assert_character(colnames_to_join, null.ok = TRUE, unique = TRUE)

  # Only join the colnames that are not already in base_table
  colnames_to_join <- setdiff(colnames_to_join, colnames(base_table))
  if (length(colnames_to_join) == 0) {
    return(base_table)
  }

  assert_data_frame(data_loader$variable_details)
  assert_subset(
    x = c("colname", "table"),
    choices = colnames(data_loader$variable_details)
  )
  assert_subset(colnames_to_join, data_loader$variable_details$colname)
  assert_list(data_loader$tbl_list)
  data_loader$tbl_list |>
    walk(\(x) {
      assert_class(x, "tbl_lazy")
      # Make sure all tables can be joined automatically with base_table
      assert_character(intersect(colnames(x), colnames(base_table)), min.chars = 1)
    })

  data_loader$variable_details |>
    filter(colname %in% colnames_to_join) |>
    group_by(table) |>
    group_map(\(details, table) {
      table <- table$table
      colnames <- details$colname
      # Make sure the tables are in tbl_list
      assert_subset(table, names(data_loader$tbl_list))
      table_to_join <- data_loader$tbl_list[[table]]

      # Write a custom expresion to replace NULLs in prevalence dimension
      # by prepending the variable label with "No". E.g: "No Anxiety"
      prevalence_colnames_no_expr <- NULL
      if (table == "health_dimensions") {
        prevalence_colnames <- colnames[colnames %in% data_loader$prevelance_equity_dimensions]
        if (length(prevalence_colnames) > 0) {
          prevalence_colnames_details <- data_loader$variable_details |>
            filter(colname %in% prevalence_colnames)
          prevalence_colnames_no <- setNames(
            paste("No", prevalence_colnames_details$label),
            prevalence_colnames
          )
          prevalence_colnames_no_expr <- names(prevalence_colnames_no) |>
            map(\(x) {
              expr(
                ifelse(
                  is_active == "TRUE",
                  coalesce(!!sym(x), !!prevalence_colnames_no[[x]]),
                  !!UNKNOWN_VALUE
                )
              )
            }) |>
            setNames(names(prevalence_colnames_no))
        }

        table_to_join <- table_to_join |>
          mutate(featureid = str_to_lower(featureid)) |>
          filter(featureid %in% colnames) |>
          dbplyr_pivot_wider_spec(names_from_featureid_spec(colnames)) |>
          rename_with(clean_colnames)

        if (length(colnames) > 1) {
          table_to_join <- table_to_join |>
            group_by(person_id, year, fips, zip5) |>
            summarise(across(all_of(colnames), max))
        }
      }

      id_columns <- c("person_id", "year")

      if (table == "fips_data") {
        id_columns <- c(id_columns, "fips")
      }

      if (table == "zip5_data") {
        id_columns <- c(id_columns, "zip5")
      }

      list(
        table_to_join = table_to_join |>
          select(any_of(id_columns), all_of(colnames)),
        prevalence_colnames_no_expr = prevalence_colnames_no_expr
      )
    }) |>
    reduce(
      \(base_table, nxt) {
        prevalence_colnames_no_expr <- nxt$prevalence_colnames_no_expr
        table_to_join <- nxt$table_to_join
        joined <- base_table |>
          left_join(table_to_join)
        if ("is_active" %in% colnames(joined) && !is.null(prevalence_colnames_no_expr)) {
          joined <- joined |>
            mutate(prevalence_colnames_no_expr)
        }
        joined
      },
      .init = base_table
    )
}
