box::use(
  R6[R6Class]
)
box::use(
  checkmate[
    assert_character,
    assert_class,
    assert_list,
    assert_numeric,
    assert_r6,
    assert_string,
    assert_subset
  ],
  dplyr[
    across,
    all_of,
    arrange,
    coalesce,
    collect,
    compute,
    cur_column,
    distinct,
    everything,
    filter,
    left_join,
    group_by,
    if_else,
    inner_join,
    mutate,
    n_distinct,
    pull,
    rename_with,
    select,
    summarize,
    sym,
    ungroup,
    union_all,
  ],
  dbplyr[dbplyr_pivot_wider_spec],
  checkmate[
    assert_class,
    assert_list
  ],
  purrr[
    map,
    imap,
    reduce,
  ],
  rhino[log],
  rlang[
    expr,
    sym
  ],
  shiny[
    need,
    validate,
  ],
  stats[setNames],
  stringr[str_remove],
  tictoc[tic, toc],
)

box::use(
  app / logic / constants[
    EQUITY_DIMENSION_PREVALENCE,
    EQUITY_DIMENSION_SIMPLE,
  ],
  app / logic / load_env[config],
  app / logic / categorize_numeric[categorize_numeric, rank_numerical_variables],
  app / logic / join_variables[join_variables],
  app / logic / pivot_wider_specs[count_distinct_by_status_spec],
  app / logic / relevel_factors[relevel_factors],
  app / logic / utils[nrows_db, get_percentile_prefix, replace_na],
)

#' @export
EquityDimensionStatus <- R6Class(
  classname = "EquityDimensionStatus",
  private = list(
    data_loader = NULL,
    measure = NULL,
    measure_df = NULL,
    measure_is_prevalence = NULL,
    active_lookback_patients = NULL,
    selected_dims = list(),
    period = NULL,
    is_global_filters_set = FALSE,
    assert_global_filters_set = function() {
      if (!private$is_global_filters_set) {
        stop("Global filters are not set. Use set_global_filters method to set the global filters.")
      }
    }
  ),
  public = list(
    #' Initialize the EquityDimensionStatus object
    #' @param data_loader A DataLoader object
    #' @param advanced_filters_state A list
    #'
    #' @details
    #' The initialize method sets the data_loader and the active_lookback_patients table
    #' which is the base table for all calculations.
    #' Active lookback patients is the health_dimensions table filtered by the
    #' advanced_filters_state where featureid is equal to
    #' `config$global_filters$health_dimension$prevalence_default_denominator`.
    #' All tables will be joined to the active_lookback_patients table.
    # nolint end
    initialize = function(data_loader, advanced_filters_state = list()) {
      assert_r6(data_loader, "DataLoader")
      assert_list(advanced_filters_state)

      private$data_loader <- data_loader

      selected <- advanced_filters_state$selected
      if (length(selected) == 0) {
        joined_dataset <- data_loader$equity_dimensions_tbl
      } else {
        percentile_breaks <- advanced_filters_state$percentile_breaks

        init_dataset <- data_loader$equity_dimensions_tbl

        joined_dataset <- data_loader$equity_dimensions_tbl |>
          join_variables(names(selected)) |>
          compute()

        # We use custom expression to avoid using multiple `filter` calls because dbplyr creates
        # a subquery for each filter call which slows down the query
        categorical_filter_expr <- map(
          names(selected)[names(selected) %in% unlist(data_loader$categorical_variables)],
          \(x) expr(!!sym(x) %in% !!selected[[x]])
        )

        joined_dataset <- joined_dataset |>
          filter(categorical_filter_expr)

        if (length(percentile_breaks) > 0) {
          # We must flag numerical variables that are filtered by percentile
          # Because we categorize them to numeric again in downstream
          # TODO: Clarify the expected behavior with the client, also find a robust way
          # to handle this
          new_percentile_break_cols <- setdiff(names(percentile_breaks), colnames(init_dataset))
          existing_percentile_break_cols <- intersect(
            names(percentile_breaks), colnames(init_dataset)
          )
          joined_dataset <- joined_dataset |>
            mutate(
              across(all_of(existing_percentile_break_cols), \(x) x, .names = "{.col}_filtered")
            ) |>
            rename_with(\(x) paste0(x, "_filtered"), all_of(new_percentile_break_cols))

          percentile_selected <- which(names(selected) %in% names(percentile_breaks))

          names(selected)[percentile_selected] <- paste0(
            names(selected)[percentile_selected], "_filtered"
          )

          names(percentile_breaks) <- paste0(names(percentile_breaks), "_filtered")

          numeric_cols <- names(advanced_filters_state$percentile_breaks)
          numerical_filter_expressions <- map(numeric_cols, \(col) {
            categorization_prefix <- get_percentile_prefix(
              unname(unlist(advanced_filters_state$percentile_breaks[col]))
            )

            indices <- advanced_filters_state$selected[col] |>
              map(\(x) as.numeric(str_remove(x, categorization_prefix))) |>
              unlist() |>
              unname()

            map(indices, \(idx) {
              expr(
                between(
                  !!sym(paste0(col, "_rank")),
                  !!advanced_filters_state$percentile_breaks[[col]][idx],
                  !!advanced_filters_state$percentile_breaks[[col]][idx + 1]
                )
              )
            })
          })

          numerical_filter_expr <- unname(map(numerical_filter_expressions, \(exprs) {
            reduce(exprs, \(acc, nxt) {
              expr((!!acc) | (!!nxt))
            })
          }))

          filtered_join_keys <- rank_numerical_variables(
            joined_dataset |>
              rename_with(
                \(x) str_remove(x, "_filtered"),
                .cols = all_of(paste0(numeric_cols, "_filtered"))
              ),
            numeric_cols
          ) |>
            map(\(x) {
              join_keys <- setdiff(colnames(x), c(numeric_cols, paste0(numeric_cols, "_rank")))
              x |>
                filter(numerical_filter_expr) |>
                distinct(across(all_of(join_keys)), .keep_all = FALSE)
            }) |>
            reduce(\(acc, nxt) union_all(acc, nxt))

          joined_dataset <- joined_dataset |>
            inner_join(filtered_join_keys)
        }
      }

      denominator_dimension <- config$global_filters$health_dimension$prevalence_default_denominator
      private$active_lookback_patients <- joined_dataset |>
        filter(featureid == !!denominator_dimension) |>
        mutate(person_id, year, is_active = status == 1, .keep = "none") |>
        compute()
    },
    #' Set the global filters
    #'
    #' @param measure A string representing the measure to join to the active_lookback_patients
    #' @param period A numeric vector representing the period to filter the data
    #' @param selected_dims A list containing the additional dimensions and percentile columns
    #'
    #' @details
    #' Setting the global filters is a prerequisite for all other methods.
    #'
    #' @return self
    set_global_filters = function(measure,
                                  period,
                                  selected_dims = list(
                                    dimensions = NULL,
                                    percentile_columns = NULL
                                  )) {
      assert_string(measure)
      assert_numeric(period, len = 2, sorted = TRUE, null.ok = TRUE)
      assert_list(selected_dims)
      assert_subset(names(selected_dims), c("dimensions", "percentile_columns"))

      selected_dims$is_prevalence <- selected_dims$dimensions %in%
        private$data_loader$prevelance_equity_dimensions
      private$selected_dims <- selected_dims

      private$measure <- measure
      private$measure_is_prevalence <- measure %in%
        private$data_loader$prevelance_equity_dimensions

      private$period <- period
      min_period <- private$period[1]
      max_period <- private$period[2]

      private$measure_df <- private$active_lookback_patients |>
        filter(between(year, !!min_period, !!max_period)) |>
        left_join(
          # We dont need to join the filtered_equity_dimensions since active_lookback_patients
          # is already filtered and we are doing a left join.
          # Plus, filtered_eqıity_dimensions is slow
          private$data_loader$equity_dimensions_tbl |>
            filter(tolower(featureid) == !!private$measure)
        )

      # Here, we are replacing null status values with 0 for prevalence measures
      # Because we assume that the all active patients are in the denominator
      if (private$measure_is_prevalence) {
        private$measure_df <- private$measure_df |>
          mutate(status = coalesce(
            status,
            !!config$global_filters$health_dimension$status_dict$falsy
          ))
      }

      private$measure_df <- private$measure_df |>
        compute()

      private$is_global_filters_set <- TRUE

      return(self)
    },
    get_measure_df = function() {
      private$assert_global_filters_set()
      return(private$measure_df)
    },
    #' Get the incontrol table
    #'
    #' @param by A string representing the columns to add to the group by clause. Can be NULL
    #' @param minimum_sample_size A numeric representing the minimum sample size to include
    #' in the incontrol table. Defaults to the minimum_sample_size entry in the config file.
    #'
    #' @details This function calculates the incontrol rate, grouped by
    #' `private$selected_dims$dimensions` and the `by` argument.
    #' The groups that has no observations are filtered out.
    #' The resulting data frame is collected and `private$selected_dims$dimensions`
    #' are converted to factor.
    #' Finally, the data frame is sorted by `by` and `private$selected_dims$dimensions`.
    #' @return collected data frame
    get_incontrol_table = function(by = "year",
                                   minimum_sample_size = config$numbers$minimum_sample_size) {
      private$assert_global_filters_set()
      assert_character(by, null.ok = TRUE)
      assert_subset(by, colnames(private$measure_df))
      if (length(intersect(by, private$selected_dims$dimensions)) > 0) {
        stop("`by` argument cannot contain any of the selected dimensions")
      }
      private$measure_df |>
        join_variables(private$selected_dims$dimensions, private$data_loader) |>
        categorize_numeric(private$selected_dims$percentile_columns) |>
        replace_na(private$selected_dims$dimensions) |>
        group_by(across(all_of(by)), across(any_of(private$selected_dims$dimensions)), status) |>
        summarize(count_distinct = n_distinct(person_id), .groups = "drop") |>
        dbplyr_pivot_wider_spec(count_distinct_by_status_spec) |>
        collect() |>
        mutate(
          across(
            all_of(names(config$global_filters$health_dimension$status_dict)),
            \(x) coalesce(as.numeric(x), 0)
          ),
          denominator = truthy + falsy,
          all_observations = denominator + not_measured
        ) |>
        filter(
          denominator > 0 &
            all_observations > 0 &
            truthy >= !!minimum_sample_size
        ) |>
        mutate(
          incontrol = truthy / denominator,
          missing_rate = not_measured / all_observations
        ) |>
        relevel_factors(private$selected_dims$dimensions) |>
        arrange(across(all_of(by)), across(any_of(private$selected_dims$dimensions))) |>
        ungroup()
    }
  )
)
