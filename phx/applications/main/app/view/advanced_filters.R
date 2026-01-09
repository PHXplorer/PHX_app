box::use(
  bs4Dash[actionButton],
  dplyr[filter, pull],
  shiny[
    bindCache,
    bindEvent,
    div,
    h5,
    HTML,
    icon,
    isolate,
    modalButton,
    modalDialog,
    moduleServer,
    NS,
    observeEvent,
    removeModal,
    renderUI,
    showModal,
    tagAppendChild,
    tagList,
    tags,
    textInput,
    uiOutput,
  ],
  R6[R6Class],
  purrr[imap, map, discard],
  shinyWidgets[pickerInput],
  stats[setNames],
  stringr[str_c]
)

box::use(
  app / logic / DataLoader[data_loader],
  app / logic / get_variables_from_colnames[get_variables_from_colnames],
  app / logic / utils[bmc_spinner],
  app / view / components / input_with_button[input_with_button],
  app / view / components / nested_accordion[nested_accordion],
)

#' @export
filters_list_ui <- function(id) {
  ns <- NS(id)
  uiOutput(ns("selected_filters"), class = "selected-filters-output")
}

#' @export
filters_list_server <- function(id) {
  moduleServer(
    id,
    function(input, output, session) {
      output$selected_filters <- renderUI({
        selected <- session$userData$advanced_filters_state()$selected
        results <- tags$span(
          "Filters applied:",
          {
            if (length(selected) == 0) {
              tags$span("No filters selected")
            } else {
              tags$ul(
                class = "filter-list",
                imap(selected, function(x, i) {
                  variable_name <- names(get_variables_from_colnames(i))
                  tags$li(
                    HTML(paste0(
                      tags$span(variable_name, class = "text-bold"),
                      ": ",
                      str_c(x, collapse = ", ")
                    ))
                  )
                })
              )
            }
          }
        )
        return(tags$div(class = "advanced-filters-list", results))
      })
    }
  )
}
