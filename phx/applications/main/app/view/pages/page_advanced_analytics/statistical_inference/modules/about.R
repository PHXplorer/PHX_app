box::use(
  bs4Dash[bs4Card],
  shiny[NS, moduleServer, tags],
)

#' @export
ui <- function(id) {
  ns <- NS(id)

  bs4Card(
    width = 12,
    tags$h2("Statistical Inference"),
    tags$p("To get started, choose a module from the dropdown above.")
  )
}

#' @export
server <- function(id, ...) {
  moduleServer(id, function(input, output, session) {
  })
}
