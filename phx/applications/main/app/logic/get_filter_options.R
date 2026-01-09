box::use(
  dbplyr[db_collect],
  dplyr[
    coalesce,
    filter,
    group_by,
    group_map,
    if_else,
    mutate,
    pull,
    select,
    rowwise,
    ungroup
  ],
  glue[glue_sql],
  purrr[set_names],
  tictoc[tic, toc]
)

box::use(
  app / logic / redis[redis_client],
  app / logic / clean_colnames[clean_colnames],
)

#' Create a raw SQL query that fetches unique values for every text variable
#' @param details data.frame
#' @param con DBI connection or dbPool
#' @return Character vector of length 1 that represents a SQL query
#' @export
prepare_filter_options_sql <- function(details, con) {
  details |>
    filter(value_type == "text") |>
    select(colname, table) |>
    rowwise() |>
    mutate(
      query_template = ifelse(
        table == "health_dimensions",
        "
        SELECT
            DISTINCT CAST(Value as VARCHAR(150)) AS value,
            FeatureID AS name
        FROM
            {`table`}
        WHERE
            FeatureID = UPPER({
              colname
            })
        ",
        "
        SELECT
          DISTINCT CAST({`colname`} as VARCHAR(150)) as value,
          {colname} as name
        FROM {`table`}
        "
      ),
      query = glue_sql(query_template, .con = con)
    ) |>
    ungroup() |>
    pull(query) |>
    paste(collapse = " union all ")
}

#' Get filter options for text variables
#' Each filter option is considered to be a key-value pair,
#' where key is a variable name and value is unique values of given variable.
#' @param details data.frame
#' @param con DBI connection or dbPool
#' @return named list
#' @export
get_filter_options_raw <- function(details, con) {
  tic("get_filter_options_raw")
  sql <- prepare_filter_options_sql(details, con)
  data <- db_collect(con, sql)
  result <- data |>
    mutate(
      name = clean_colnames(name),
      value = coalesce(trimws(value), "Unkown")
    ) |>
    group_by(name) |>
    group_map(function(data, group) {
      list(group = pull(data, value)) |> set_names(group[[1]])
    }) |>
    unlist(recursive = FALSE)
  toc()
  result
}

#' get filter options with cache
#' @seealso get_filter_options_raw
#' @export
get_filter_options <- function(details, con) {
  key <- "filter_options"
  redis_client$getset(key, function() {
    get_filter_options_raw(details, con)
  })
}
