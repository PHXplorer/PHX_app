box::use(
  checkmate[
    assert_true,
    assert_factor,
    assert_names
  ],
  dplyr[
    any_of,
    arrange,
    coalesce,
    collect,
    desc,
    distinct,
    filter,
    inner_join,
    left_join,
    mutate,
    pull,
    select,
    slice_sample,
  ],
  glue[glue],
  parsnip[rand_forest, fit, set_engine, set_mode],
  plotly[plot_ly, layout],
  purrr[keep, map, reduce],
  reactable[colDef, reactable],
  reactablefmtr[data_bars],
  vip[vi],
)

box::use(
  app / logic / DataLoader[data_loader],
  app / logic / join_variables[join_variables],
)

#' get_feature_importance()
#'
#' This function ranks the variables based on their importance in the machine learning model.
#' It returns a tibble with 2 fields, `Variable` and `Importance`, that contains the variable names
#' and their corresponding importance values respectively.
#'
#' @param target A vector of categorical values. It must be of type `factor`
#' and should have length equal to the data row length.
#' @param data A dataframe containing all the predictor fields.
#' @param ntrees (optional) An integer, specifying number of decision trees to
#' build the random forest model. Note: Higher value takes more computational time
#' @export
get_feature_importance <- function(target, data, ntrees = 501) {
  assert_true(length(target) == nrow(data))
  assert_factor(target)

  data <- cbind(data, target = target)
  rand_forest(mtry = floor(sqrt(ncol(data))), trees = ntrees) |>
    set_engine("ranger", importance = "impurity") |>
    set_mode("classification") |>
    fit(target ~ ., data) |>
    vi() |>
    mutate(Importance = round(Importance, 2))
}

#' plot_feature_importance()
#'
#' This function plots an interactive bar graph highlighting the variables in
#' order of their importance values.
#'
#' @param variable_importance_datalist A list of dataframes with 2 fields, `Variable`
#' and `Importance`, that contains the variable names and their
#' corresponding importance values respectively.
#' @export
plot_feature_importance <- function(variable_importance_datalist) {
  combined <- variable_importance_datalist |>
    reduce(\(acc, nxt) inner_join(acc, nxt, by = "Variable"))

  average_importance <- combined |>
    mutate(
      Variable,
      Importance = rowMeans(select(combined, -Variable)),
      .keep = "none"
    ) |>
    arrange(desc(Importance))

  reactable(
    data = average_importance,
    searchable = TRUE,
    columns = list(
      Variable = colDef(name = "Variable", sortable = FALSE, searchable = TRUE),
      Importance = colDef(
        name = "Importance",
        sortable = TRUE,
        searchable = FALSE,
        filterable = FALSE,
        cell = average_importance |>
          data_bars(
            text_position = "outside-end",
            number_fmt = \(x) glue("{round(x, 2)}"),
            fill_color = "black",
            background = "white"
          )
      )
    )
  )
}

#' @export
#' get_modelling_data
#'
#' This function retrieves the data used to train the machine learning model.
#'
#' @param equity_with_filters The equity data with filters applied.
#' @param sample_size The desired sample size for the modelling data.
#' @param mode The mode for retrieving the modelling data.
#'             Possible values are "complete" and "subset".
#' @param remove_missing A boolean value to remove missing values from the modelling data.
#'                       It was observed that `ranger` fails to run the model with >= 0.5
#'                       missing values in a particular predictor.
#' @param excluded_variables A vector of variables to exclude from the modelling data.
#' @param included_variables A vector of variables to include in the modelling data.
#' @param place_attribute_type The type of place attribute to use. Default is "FIPS".
#'
#' @return The modelling data based on the specified parameters.
#'
#' @examples
#' get_modelling_data(equity_with_filters, 100, mode = "complete")
#' get_modelling_data(equity_with_filters, 100, mode = "subset", included_variables = c("var1", "var2")) # nolint
#'
#' @export
get_modelling_data <- function(
    equity_with_filters,
    sample_size,
    mode = c("complete", "subset"),
    remove_missing = TRUE,
    excluded_variables = NULL,
    included_variables = NULL,
    place_attribute_type = "FIPS") {
  mode <- match.arg(mode)

  if (mode == "subset" && is.null(included_variables)) {
    stop("included_variables must be provided when mode is 'subset'")
  }

  full_data <- NULL

  if (mode == "complete") {
    full_data <- get_complete_modelling_data(
      equity_with_filters,
      sample_size,
      excluded_variables,
      place_attribute_type
    )
  }

  if (mode == "subset") {
    full_data <- get_subset_modelling_data(
      equity_with_filters,
      sample_size,
      included_variables
    )
  }

  if (NROW(full_data) == 0) {
    return(simpleError("No data available for the selected filters"))
  }

  missing_variables <- map(full_data, \(x) {
    missing_rate <- length(x[is.na(x)]) / length(x)
    if (is.na(missing_rate)) missing_rate <- 1
    if (missing_rate >= 0.5) TRUE else FALSE
  }) |>
    keep(\(x) isTRUE(x)) |>
    names()

  if (remove_missing) {
    full_data <- full_data |>
      select(-any_of(missing_variables))
  }

  predictors_data <- full_data |>
    select(-status)

  target_data <- full_data |>
    pull(status) |>
    as.factor()

  list(target = target_data, predictors = predictors_data, missing = missing_variables)
}

#' Add labels to importance data
#'
#' This function adds labels to the importance data based on the variable details.
#' It will try to take an existing Variable column and replace it with the label
#' where possible.
#'
#' @param importance_data The importance data to which labels will be added.
#' @param variable_details The variable details data frame containing the column names and labels.
#'
#' @return data.frame with Variable and Importance columns.
#' @export
add_labels_to_importance <- function(importance_data, variable_details) {
  importance_data |>
    left_join(
      select(variable_details, colname, label),
      by = c(Variable = "colname")
    ) |>
    mutate(Variable = coalesce(label, Variable), Importance, .keep = "none")
}

#' get_complete_modelling_data()
#' Private module function
get_complete_modelling_data <- function(
    equity_with_filters,
    sample_size,
    excluded_variables,
    place_attribute_type) {
  all_variables <- if (place_attribute_type == "FIPS") {
    data_loader$get_lazy_table("fips_data")
  } else if (place_attribute_type == "ZIP5") {
    data_loader$get_lazy_table("zip5_data")
  }

  health_dimensions <- data_loader$equity_dimensions_tbl |>
    distinct(featureid) |>
    pull(featureid) |>
    tolower()

  health_dimensions <- intersect(health_dimensions, data_loader$variable_details$colname)

  equity_with_filters |>
    left_join(data_loader$tbl_list$demo_attributes) |>
    join_variables(health_dimensions) |>
    left_join(all_variables) |>
    # TODO: verify which columns should be removed
    select(-any_of(c(
      "uniqueid",
      "year",
      "status_as_string",
      "statusasstring",
      "value",
      "value_as_number",
      "person_id",
      "measurement_date",
      "fips",
      "zip5",
      "is_active",
      "health_dimension",
      "featureid"
    ))) |>
    select(-all_of(excluded_variables)) |>
    filter(!is.na(status)) |>
    slice_sample(n = sample_size) |>
    collect()
}

#' get_subset_modelling_data()
#' Private module function
get_subset_modelling_data <- function(equity_with_filters, sample_size, included_variables) {
  equity_with_filters |>
    join_variables(included_variables) |>
    select(all_of(included_variables), "status") |>
    filter(!is.na(status)) |>
    slice_sample(n = sample_size) |>
    collect()
}
