box::use(
  shiny[
    actionButton,
    actionLink,
    div,
    HTML,
    icon,
    modalDialog,
    moduleServer,
    NS,
    observeEvent,
    removeModal,
    showModal,
    tabPanel,
  ],
  purrr[map],
  bs4Dash[tabsetPanel]
)

box::use(
  app / logic / load_env[config]
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  actionLink(ns("knowledge_center"), class = "knowledge-center", label = "Knowledge Center")
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    observeEvent(input$knowledge_center, {
      showModal(
        modalDialog(
          class = "kc-content",
          footer = NULL,
          fade = FALSE,
          title = div(
            div(class = "kc-header", "Knowledge Center"),
            actionButton(
              session$ns("close"),
              icon("x"),
              class = "close-button"
            )
          ),
          tabsetPanel(
            id = session$ns("kc_tabs"),
            .list = config$strings$knowledge_center |> map(~ tabPanel(.$title, HTML(.$content)))
          ),
          size = "xl",
          easyClose = TRUE
        )
      )
    })

    observeEvent(input$close, {
      removeModal()
    })
  })
}
