box::use(
  bs4Dash[box],
  shiny[NS, moduleServer, tags],
)

box::use(
  app / view / independence_table[independence_table_ui, independence_table_server],
)

#' @export
LABEL <- "Fisher's Exact Test"

#' @export
ui <- function(id) {
  ns <- NS(id)

  box(
    width = 12,
    collapsible = FALSE,
    independence_table_ui(ns("independence"))
  )
}

#' @export
server <- function(id, equity_data_filtered, measure, cache_key) {
  moduleServer(id, function(input, output, session) {
    independence_table_server(
      id = "independence",
      measure_df = equity_data_filtered,
      measure = measure,
      cache_key = cache_key
    )
  })
}
