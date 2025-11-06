#' Collection of raw SQL queris that fetch some static information.
#' This information is usually technical, e.g. database metadata.
#' @example
#' box::use(
#'  app/logic/connection[db_con],
#'  app/logic/load_env[config],
#'  app/logic/sql_queries,
#' )
#' sql <- sql_queries[[config$data$database$db_driver]]$last_update
#' timestamp <- dbplyr::db_collect(con = db_con, sql = sql)

#' @export
mssql <- list(
  #' Get maximum timestamp value of modification date
  #' across tables ('U') and views ('V') in the database.
  last_update = paste(
    "select max(modify_date) as last_update",
    "from sys.objects",
    "where sys.objects.type in ('U', 'V')"
  )
)

#' @export
postgres <- list(
  # TODO: cache basically won't work for postgres. Needs to be implemented.
  last_update = "select now()"
)

#' @export
sqlite <- list(
  last_update = "select time('now')"
)
