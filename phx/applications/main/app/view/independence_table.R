box::use(
  bs4Dash[ionicon, addPopover],
  plotly[plotlyOutput, renderPlotly, plot_ly, add_heatmap, layout, config],
  shiny[
    actionLink,
    bindCache,
    debounce,
    div,
    icon,
    moduleServer,
    need,
    NS,
    observeEvent,
    reactive,
    reactiveValues,
    req,
    tagList,
    tags,
    validate,
  ],
  shinyWidgets[pickerOptions],
)

box::use(
  app / logic / DataLoader[data_loader],
  app / logic / get_variables_from_colnames[get_variables_from_colnames],
  app / logic / load_env[app_config = config],
  app / logic / matrix_utils[replace_matrix_dim_names],
  app / logic / utils[bmc_spinner, compute_fisher_matrix],
  app / logic / ColnameDetails[colname_details],
  app / view / input / dimension_input,
)

#' @export
placeholder_ui <- function(title) {
  tags$div(
    tags$p(title, style = "font-size:16px;font-weight:700"),
    tags$div(
      class = "wip-placeholder",
      style = "text-align: center;",
      tags$p("Work in progress"),
      icon("person-digging",
        style = paste0("color:", app_config$colors$chart_colors[1], ";font-size:100px;")
      )
    )
  )
}

#' @export
independence_table_ui <- function(id) {
  ns <- NS(id)

  heatmap_footnote <- app_config$strings$heatmap_footnote

  if (!app_config$numbers$fisher_pvalues_log10) {
    heatmap_footnote <- NULL
  }

  tagList(
    div(
      class = "sentence-filter-container",
      "Fisher's Exact Test of Independence",
      actionLink(
        ns("popover_fisher"),
        ionicon(
          "information-circle-outline"
        )
      ),
      "for",
      dimension_input$ui(ns("variables"))
    ),
    plotlyOutput(ns("heatmap"), height = "550px") |> bmc_spinner(),
    heatmap_footnote
  )
}

#' @export
independence_table_server <- function(id, measure_df, measure, cache_key) {
  moduleServer(
    id,
    function(input, output, session) {
      observeEvent(input$popover_fisher >= 0, {
        addPopover(
          id = "popover_fisher",
          options = list(
            title = "",
            placement = "right",
            content = app_config$strings$info_boxes$fishers_exact_test,
            trigger = "hover"
          )
        )
      })

      variables <- dimension_input$server(
        id = "variables",
        title = "Variables Selection",
        multiple = TRUE,
        multiple_limit = 10,
        allow_continuous = TRUE,
        only_categorical_variables = TRUE
      )

      fisher_data <- reactive({
        validate(
          need(variables()$variable, app_config$strings$error_messages$fisher_selection)
        )
        compute_fisher_matrix(measure_df(), variables()$variable)
      })

      output$heatmap <- renderPlotly({
        current_names <- colnames(fisher_data()$values)
        variable_names <- get_variables_from_colnames(current_names[-1], names_only = TRUE)
        equity_description <- colname_details$get_variable_description(measure())
        new_names <- c(equity_description, variable_names)
        values <- replace_matrix_dim_names(fisher_data()$values, current_names, new_names)
        labels <- replace_matrix_dim_names(fisher_data()$labels, current_names, new_names)

        plot_ly(
          x = colnames(values),
          y = rownames(values),
          z = values
        ) |>
          add_heatmap(
            colorbar = list(title = "<b>Significance of\nassociation</b>", thickness = 10),
            zmin = -10,
            text = labels,
            hovertemplate = paste(
              "(%{y}, %{x})",
              # when accessing values in JS, they are treated as numbers
              # even when we provide text. This is why we need to make rounding also here
              paste0(
                "Significance of association: %{text:.",
                app_config$numbers$decimal_accuracy,
                "f}"
              ),
              "<extra></extra>",
              sep = "<br>"
            )
          ) |>
          config(displayModeBar = FALSE) |>
          layout(
            yaxis = list(autorange = "reversed", showgrid = FALSE),
            xaxis = list(showgrid = FALSE, tickangle = 30)
          )
      }) |>
        bindCache(cache_key(), variables())
    }
  )
}
