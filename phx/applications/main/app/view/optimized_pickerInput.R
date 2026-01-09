box::use(
  shiny[moduleServer, observeEvent, NS, reactiveVal],
  shinyWidgets[pickerInput]
)
#' Simple pickerInput UI
#'
#' @param id The module namespace
#' @param ... Additional arguments to pass to pickerInput
#'
#' @export
ui <- function(id, ...) {
  ns <- NS(id)
  pickerInput(
    inputId = ns("pickerInput"),
    ...
  )
}

#' Optimized pickerInput server that only updates the returned value when the input is closed
#'
#' @param id The module namespace
#'
#' @export
server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {
      selected <- reactiveVal()
      observeEvent(
        input$pickerInput_open,
        {
          if (!isTRUE(input$pickerInput_open)) {
            selected(input$pickerInput)
          }
        },
        ignoreNULL = FALSE
      )
      selected
    }
  )
}
