box::use(
  shiny[NS, moduleServer, tags],
  bs4Dash[tabItem, menuItem, menuSubItem, ],
)

box::use(
  . / exploratory_analysis,
  . / statistical_inference,
  . / machine_learning,
)

#' @export
ui_sidebar <- function(title) {
  menuItem(
    text = title,
    startExpanded = TRUE,
    menuSubItem(text = "Data Exploration", tabName = "exploratory_analysis", icon = NULL),
    menuSubItem(text = "Statistical Inference", tabName = "statistical_inference", icon = NULL),
    menuSubItem(text = "Machine Learning", tabName = "machine_learning", icon = NULL)
  )
}

#' @export
ui_body <- function(id) {
  ns <- NS(id)
  list(
    tabItem(
      tabName = "exploratory_analysis",
      exploratory_analysis$ui(id = ns("exploratory_analysis")),
    ),
    tabItem(
      tabName = "statistical_inference",
      statistical_inference$ui(id = ns("statistical_inference"))
    ),
    tabItem(
      tabName = "machine_learning",
      machine_learning$ui(id = ns("machine_learning"))
    )
  )
}

#' @export
server <- function(id, equity_data_filtered, measure, cache_key) {
  moduleServer(id, function(input, output, session) {
    exploratory_analysis$server(
      id = "exploratory_analysis",
      equity_data_filtered = equity_data_filtered,
      measure = measure,
      cache_key = cache_key
    )

    statistical_inference$server(
      id = "statistical_inference",
      equity_data_filtered = equity_data_filtered,
      measure = measure,
      cache_key = cache_key
    )

    machine_learning$server(
      id = "machine_learning",
      equity_data_filtered = equity_data_filtered,
      measure = measure,
      cache_key = cache_key
    )
  })
}
