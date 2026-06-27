box::use(
  bs4Dash[box],
  shiny[NS, moduleServer],
)

box::use(
  app / view / eda[eda_ui, eda_server],
)

#' @export
LABEL <- "Data Distribution"

#' @export
ui <- function(id) {
  ns <- NS(id)

  box(
    width = 12,
    collapsible = FALSE,
    eda_ui(ns("eda"))
  )
}

#' @export
server <- function(id, equity_data_filtered, measure, cache_key) {
  moduleServer(id, function(input, output, session) {
    eda_server(
      id = "eda",
      equity_data_filtered = equity_data_filtered,
      cache_key = cache_key
    )
  })
}
