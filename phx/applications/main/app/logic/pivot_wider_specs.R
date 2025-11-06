box::use(
  checkmate[assert_character, assert_string],
  tibble[tibble],
)

box::use(
  app / logic / load_env[config],
)

#' This spec pivots the data by `status` column where the values comes from the
#' `count_distinct` column
#' @export
count_distinct_by_status_spec <- tibble(
  .name = names(config$global_filters$health_dimension$status_dict),
  .value = "count_distinct",
  status = unname(unlist(config$global_filters$health_dimension$status_dict))
)

#' This function returns a spec that pivots the given featureids as columns using the values from
#' as the values
#'
#' @param featureids A character vector of featureids to pivot as columns
#' @param values_from A string specifying the column name to use as values. Default is "value"
#' @export
names_from_featureid_spec <- function(featureids, values_from = "value") {
  assert_character(featureids)
  assert_string(values_from)
  tibble(
    .name = featureids,
    .value = values_from,
    featureid = featureids
  )
}
