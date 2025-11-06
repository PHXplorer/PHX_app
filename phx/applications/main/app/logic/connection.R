tictoc::tic("[module] connection")
box::use(
  DBI[dbConnect, dbDisconnect],
  rhino[log],
  shiny[onStop],
)

box::use(
  app / logic / load_env[config],
  app / logic / connection_utils[load_test_data, upload_test_data],
)

get_db_con <- function() {
  con <- switch(config$data$database$db_driver,
    sqlite = dbConnect(
      drv = RSQLite::SQLite(),
      dbdir = ":memory:"
    ),
    postgres = dbConnect(
      drv = RPostgres::Postgres(),
      dbname = config$data$database$db_name,
      host = config$data$database$db_host,
      port = config$data$database$db_port,
      user = config$data$database$db_user,
      password = config$data$database$db_pass,
      options = "-c search_path=dbo"
    ),
    mssql = dbConnect(
      drv = odbc::odbc(),
      Driver = "ODBC Driver 17 for SQL Server",
      Server = paste(config$data$database$db_host, config$data$database$db_port, sep = ","),
      Database = config$data$database$db_name,
      UID = config$data$database$db_user,
      PWD = config$data$database$db_pass,
      TrustServerCertificate = "yes"
    ),
    stop("Unsupported database driver")
  )

  is_sqlite <- config$data$database$db_driver == "sqlite"
  should_use_mock_data <- Sys.getenv("USE_MOCK_DB_DATA", "false") == "true"

  if (is_sqlite || should_use_mock_data) {
    config$numbers$minimum_sample_size <- 0
    datalist <- load_test_data()
    upload_test_data(con, datalist)
  }

  onStop(function() {
    print("shiny onStop - closing stray db connection.")
    dbDisconnect(con, shutdown = TRUE)
  })

  con
}

#' @export
db_con <- get_db_con()
tictoc::toc()
