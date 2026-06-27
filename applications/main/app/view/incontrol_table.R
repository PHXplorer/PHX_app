box::use(
  bs4Dash[ionicon, addPopover],
  dplyr[mutate, select, all_of, across, everything, rowwise],
  glue[glue],
  reactable[reactableOutput, renderReactable, reactable, colDef],
  scales[label_percent],
  shiny[
    actionLink,
    bindCache,
    checkboxInput,
    moduleServer,
    need,
    NS,
    reactive,
    renderText,
    req,
    tagList,
    tags,
    textOutput,
    validate,
  ],
  tictoc[tic, toc],
  tidyr[pivot_wider],
)

box::use(
  app / logic / get_variables_from_colnames[get_variables_from_colnames],
  app / logic / load_env[config],
  app / logic / utils[bmc_spinner]
)

#' @export
incontrol_table_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$div(
      class = "incontrol-table-container",
      reactableOutput(ns("table")) |>
        bmc_spinner(proxy.height = "200px")
    ),
    tags$div(
      class = "missing-data-toggle-container",
      checkboxInput(
        ns("missing_data_toggle"),
        label = "Show Missing Data"
      ),
      actionLink(
        ns("popover-missingdata"),
        ionicon(
          "information-circle-outline"
        )
      ),
      tags$span(
        id = "legend",
        "% meeting metric / Screened patients",
        textOutput(ns("missing_data_legend"), inline = TRUE)
      )
    )
  )
}

#' @export
incontrol_table_server <- function(
    id,
    selected_dims,
    status_by_year,
    cache_key) {
  moduleServer(
    id,
    function(input, output, session) {
      addPopover(
        id = "popover-missingdata",
        options = list(
          title = "",
          placement = "right",
          content = config$strings$info_boxes$missing_data,
          trigger = "hover"
        )
      )

      table_data <- reactive({
        tic("incontrol_table_server")
        validate(need(nrow(status_by_year()) > 0, "No data available for selected filters"))
        missing_data_display <- ifelse(input$missing_data_toggle, "inline", "none")
        data <- status_by_year() |>
          mutate(
            across(
              c(incontrol, missing_rate), label_percent(accuracy = .1)
            ),
            across(
              c(denominator, all_observations), function(x) {
                formatC(round(as.numeric(x), 0), format = "d", big.mark = ",")
              }
            ),
            across(everything(), function(x) ifelse(is.na(x) | x == "NA", "", as.character(x)))
          ) |>
          rowwise() |>
          mutate(
            reactable_payload = as.character(
              tags$div(
                class = "meeting-metric-row",
                style = "display: flex",
                tags$div(
                  class = "meeting-metric",
                  incontrol,
                  tags$hr(),
                  denominator
                ),
                tags$div(
                  class = "missing-data",
                  missing_rate,
                  tags$hr(),
                  all_observations,
                  style = glue("display: {missing_data_display}")
                )
              )
            )
          ) |>
          select(year, all_of(c(selected_dims()$dimensions, "reactable_payload"))) |>
          pivot_wider(names_from = year, values_from = reactable_payload)
        toc()
        return(data)
      })

      output$table <- renderReactable({
        selected_dims <- selected_dims()$dimensions
        data_colnames <- names(table_data())
        coldefs <- lapply(data_colnames, FUN = colDef, html = TRUE)
        names(coldefs) <- data_colnames
        # replace column name for selected dims with variables
        for (selected_dim in selected_dims) {
          coldefs[[selected_dim]]$name <- get_variables_from_colnames(
            selected_dim,
            names_only = TRUE
          )
        }
        reactable(table_data(), columns = coldefs)
      }) |>
        bindCache(cache_key(), selected_dims(), input$missing_data_toggle)

      output$missing_data_legend <- renderText({
        req(input$missing_data_toggle)
        "% missing patients / Total patients"
      })
    }
  )
}
