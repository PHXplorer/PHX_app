#' This script generates fixture data for testing.
#' Whenever the structure of the database changes, this script should be run in development
#' environment connected to a non-sqlite database to update the test data.
#' You can configure the number of persons to sample by setting the `n_person` variable.
#'
db_driver <- Sys.getenv("DB_DRIVER")
if (Sys.getenv("ENVIRONMENT", "production") == "development" && db_driver != "sqlite") {
  box::use(
    readr[...],
    dplyr[...],
    tidyr[...]
  )


  box::use(
    app / logic / load_env[config],
    app / logic / connection[db_con]
  )

  message("Generating test data from ", db_driver)

  n_person <- 30

  tbl(db_con, "health_dimensions") |>
    filter(person_id <= !!n_person) |>
    collect() |>
    write_csv(file = config$data$files$health_dimensions)

  tbl(db_con, "feature_details") |>
    collect() |>
    write_csv(file = config$data$files$feature_details)

  sample_demo_attributes <- tbl(db_con, "demo_attributes") |>
    filter(person_id <= !!n_person) |>
    collect()

  sample_demo_attributes |>
    write_csv(file = config$data$files$demo_attributes)

  tbl(db_con, "fips_data") |>
    filter(fips %in% !!sample_demo_attributes$fips) |>
    collect() |>
    write_csv(file = config$data$files$fips_data)

  tbl(db_con, "zip5_data") |>
    filter(`zip5` %in% !!sample_demo_attributes$zip5) |>
    collect() |>
    write_csv(file = config$data$files$zip5_data)
} else {
  stop("You can only run this script in development environment with a non-sqlite database.")
}
