table_preview_ui <- function(id) {
  ns <- NS(id)
  tabItem(
    tabName = "preview",
    div(
      class = "controls-container",
      selectInput(
        inputId = ns("select_datatable"),
        label = "Choose dataset",
        choices = config$all_tables
      ),
      actionButton(
        class = "bmc-btn",
        inputId = ns("preview_btn"),
        label = "See preview",
        icon = icon("magnifying-glass")
      )
    ),
    box(
      title = "Data preview",
      width = 12,
      withSpinner(DTOutput(ns("data_preview")), color = config$bmc_spinner_color)
    ),
    box(
      title = "Data distribution",
      width = 12,
      collapsed = TRUE,
      selectizeInput(
        inputId = ns("fields"),
        label = "Choose field",
        choices = NULL,
        multiple = FALSE
      ),
      withSpinner(plotlyOutput(ns("data_dist")), color = config$bmc_spinner_color)
    )
  )
}

table_preview_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    get_data <- reactive({
      req(input$preview_btn)
      tryCatch(
        data <- tbl(db_con, isolate(input$select_datatable)) |>
          slice_sample(n = 6) |>
          collect(),
        error = function(e) {
          showModal(
            modalDialog(title = "Error!", "Could not fetch data. Please try again")
          )
        }
      )
      validate(need(nrow(data) > 0, "Something went wrong! Please try again."))
      data
    })

    observeEvent(input$preview_btn, {
      numeric_data <- select_if(get_data(), is.numeric)
      updateSelectizeInput(inputId = "fields", choices = names(numeric_data))
    })

    output$data_preview <- renderDT(
      {
        get_data()
      },
      options = list(scrollX = TRUE, scrollY = 300)
    )

    output$data_dist <- renderPlotly({
      req(input$fields)
      data_table <- tbl(db_con, isolate(input$select_datatable)) |>
        select(input$fields) |>
        collect()
      plot_ly(
        type = "box",
        y = data_table[[input$fields]],
        name = input$fields
      )
    })
  })
}
