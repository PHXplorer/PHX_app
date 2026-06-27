box::use(
  DBI[dbWriteTable, dbSendQuery, dbExistsTable],
  dplyr[across, all_of, mutate, where],
  rhino[log],
  stringr[str_trunc],
  vroom[vroom],
)

box::use(
  app / logic / load_env[config],
)

#' Load test data
#' Read local CSV files that contain test data for all
#' tables in the database that are used by this application.
#' @return list of data.frames
#' @export
load_test_data <- function() {
  na <- c("", "NA", "NULL")

  demo_attributes <- vroom(config$data$files$demo_attributes, show_col_types = FALSE, na = na) |>
    mutate(across(any_of(c("zip5", "fips")), as.character))
  health_dimensions <- vroom(config$data$files$health_dimensions, show_col_types = FALSE, na = na)
  feature_details <- vroom(config$data$files$feature_details, show_col_types = FALSE, na = na)
  fips_data <- vroom(config$data$files$fips_data, show_col_types = FALSE, na = na) |>
    mutate(fips = as.character(fips))
  zip5_data <- vroom(config$data$files$zip5_data, show_col_types = FALSE, na = na) |>
    mutate(zip5 = as.character(zip5))

  list(
    demo_attributes = demo_attributes,
    health_dimensions = health_dimensions,
    feature_details = feature_details,
    fips_data = fips_data,
    zip5_data = zip5_data
  )
}

#' Upload test data
#' Takes connection object and a list of data.frames, and writes
#' each data.frame to the database as a table.
#'
#' If a table already exists, it will not be overwritten.
#'
#' For postgres connections, it will create a schema called dbo if it does not exist.
#' This is required for testing in CI, where a completely fresh databse is scaffolded.
#'
#' Another fix is truncating character columns to 70 characters,
#' which is necessary for MS SQL Server.
#'
#' @param connection DBI connection object
#' @param datalist list of data.frames
#' @export
upload_test_data <- function(connection, datalist) {
  if (inherits(connection, "PqConnection")) {
    dbSendQuery(connection, "CREATE SCHEMA IF NOT EXISTS dbo")
  }

  for (table_name in names(datalist)) {
    if (dbExistsTable(connection, table_name)) {
      next
    }

    table <- datalist[[table_name]] |>
      mutate(across(
        where(is.character),
        # This is a necessary fix for MS SQL Server
        ~ str_trunc(.x, width = 70)
      ))

    log$warn("Writing test data to database: {table_name}")
    dbWriteTable(connection, table_name, table, overwrite = FALSE, append = FALSE)
  }
}
