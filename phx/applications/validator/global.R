library(bs4Dash)
library(config)
library(DBI)
library(dplyr)
library(DT)
library(odbc)
library(plotly)
library(pointblank)
library(purrr)
library(RSQLite)
library(shiny)
library(shinycssloaders)
library(stringr)
library(testthat)
library(tidyr)

env <- Sys.getenv("ENVIRONMENT", "production")
config <- get(config = env)

STATUS_VALUES_SET <- c(-2, -1, 0, 1)
ACTION_LEVEL <- action_levels(stop_at = config$action_level$stop_threshold_value)

db_con <- switch(config$database$db_driver,
  sqlite = dbConnect(drv = SQLite(), dbdir = ":memory:"),
  postgres = dbConnect(
    drv = RPostgreSQL::PostgreSQL(),
    dbname = config$database$db_name,
    host = config$database$db_host,
    port = config$database$db_port,
    user = config$database$db_user,
    password = config$database$db_pass
  ),
  mssql = dbConnect(
    drv = odbc::odbc(),
    Driver = "ODBC Driver 18 for SQL Server",
    Server = paste(config$database$db_host, config$database$db_port, sep = ","),
    Database = config$database$db_name,
    UID = config$database$db_user,
    PWD = config$database$db_pass,
    TrustServerCertificate = "yes"
  ),
  stop("Unsupported database driver")
)

LAZY_TABLES <- config$all_tables |>
  map(\(x) tbl(db_con, x)) |>
  map(\(x) rename_with(x, tolower)) |>
  set_names(config$all_tables)
