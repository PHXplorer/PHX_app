clean_colnames <- function(colnames) {
  colnames |>
    str_to_lower() |>
    str_replace_all("(\\s|-)+", "_")
}

get_df_clean_colnames <- function(data) {
  data |>
    colnames() |>
    clean_colnames()
}

get_filtered_data <- function(table, fields) {
  LAZY_TABLES[[table]] |> select(all_of(fields))
}

get_feature_details_combined <- function(filter_value, keep_col) {
  LAZY_TABLES[["feature_details"]] |>
    filter(feature_type %in% filter_value, display == 1) |>
    mutate(Combined = paste(featureid, source, sep = "-")) |>
    select(all_of(keep_col), Combined)
}

get_filtered_col <- function(data, filter_col, filter_val, col_name) {
  data |>
    filter(!!rlang::sym(filter_col) == filter_val) |>
    pull(col_name) |>
    clean_colnames()
}

get_cols_validation_report <- function(filter_value, dataset, tbl_name, show_result) {
  feature_details_combined <- get_feature_details_combined(filter_value, "value_type")
  text_headers_feat <- get_filtered_col(feature_details_combined, "value_type", "text", "Combined")
  num_headers_feat <- get_filtered_col(feature_details_combined, "value_type", "num", "Combined")

  data <- LAZY_TABLES[[dataset]] |>
    head(1) |>
    collect() |>
    withProgress(value = 1, message = "Fetching data...")
  colnames(data) <- data |> get_df_clean_colnames()
  data_headers <- data |> colnames()

  text_headers <- intersect(text_headers_feat, data_headers)
  num_headers <- intersect(num_headers_feat, data_headers)

  create_agent(
    tbl = data,
    tbl_name = tbl_name,
    label = "VALID-I",
    actions = ACTION_LEVEL
  ) |>
    col_is_character(columns = all_of(text_headers)) |>
    col_is_numeric(columns = all_of(num_headers)) |>
    interrogate() |>
    get_agent_report(title = "Validation report", arrange_by = "severity", keep = show_result()) |>
    withProgress(
      value = 1,
      message = "Running validations",
      detail = "This may take a while. Please wait..."
    )
}

get_tbl_join_result <- function(data_x, data_y, fields, result_var) {
  table_x <- get_filtered_data(data_x, fields)
  table_y <- get_filtered_data(data_y, fields)
  row_count <- inner_join(table_x, table_y, fields) |>
    count() |>
    collect()
  if (row_count > 0) {
    config$validation_results[[result_var]]$pass_text
  } else {
    config$validation_results[[result_var]]$fail_text
  }
}
