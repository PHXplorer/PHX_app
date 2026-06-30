box::use(
  bs4Dash[bs4Card],
  shiny[NS, moduleServer, tags, markdown],
)

about_feature_importance <- readLines(
  "./app/view/pages/page_advanced_analytics/machine_learning/modules/feature_importance.md"
)

#' @export
ui <- function(id) {
  ns <- NS(id)

  bs4Card(
    width = 12,
    tags$h2("Machine Learning"),
    tags$p("To get started, choose a module from the dropdown above."),
    tags$hr(),
    tags$em("Learn more about available modules by expanding sections below."),
    tags$details(
      open = "",
      tags$summary(style = "font-weight: bold", "About Feature Importance Module"),
      markdown(about_feature_importance)
    )
  )
}

#' @export
server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
  })
}
