box::use(
  bs4Dash[box],
  dplyr[arrange, rename, collect, mutate, select, all_of],
  emmeans[emmeans, as.emm_list],
  ggplot2[theme, element_text, ggtitle, theme_minimal, scale_x_continuous, scale_y_discrete],
  plotly[plotlyOutput, renderPlotly, ggplotly],
  scales[label_percent],
  shiny[
    bindCache,
    column,
    fluidRow,
    moduleServer,
    need,
    NS,
    reactive,
    renderTable,
    renderUI,
    req,
    tableOutput,
    tagList,
    tags,
    uiOutput,
    validate,
  ],
  stats[glm, binomial, formula],
)

box::use(
  app / logic / relevel_factors[relevel_factors],
  app / logic / join_variables[join_variables],
  app / logic / utils[
    bmc_spinner,
    get_percentile_breaks,
    replace_na,
  ],
  app / logic / load_env[config],
  app / logic / categorize_numeric[categorize_numeric],
  app / view / input / dimension_input,
)

#' @export
LABEL <- "Univariate Regression"

#' @export
ui <- function(id) {
  ns <- NS(id)

  box(
    title = "Univariate Regression - Predicted Probabilities",
    width = 12,
    solidHeader = FALSE,
    collapsible = FALSE,
    tags$div(
      class = "sentence-filter-container",
      "Univariate Regression - Predicted Probabilities by",
      dimension_input$ui(ns("uv_predictor"))
    ),
    tags$h5("glm(status~variable)"),
    tags$div(
      tableOutput(ns("uv_regression_table")),
      uiOutput(ns("uv_regression_notes")),
      plotlyOutput(ns("uv_plot")) |>
        bmc_spinner(proxy.height = "550px")
    )
  )
}

#' @export
server <- function(id, equity_data_filtered, measure, cache_key) {
  moduleServer(id, function(input, output, session) {
    # TODO: probably need to allow for continuous variables,
    # but have to update further data processing
    uv_predictor <- dimension_input$server(
      "uv_predictor",
      title = "UV Predictor",
      allow_continuous = FALSE
    )

    uv <- reactive({
      uv_predictor <- uv_predictor()$variable
      percentile_breaks <- get_percentile_breaks(uv_predictor()$variable, uv_predictor()$category)
      uv_data <- equity_data_filtered() |>
        join_variables(uv_predictor) |>
        categorize_numeric(percentile_breaks) |>
        select(all_of(uv_predictor), "status") |>
        replace_na(uv_predictor) |>
        collect() |>
        relevel_factors(uv_predictor)

      # NOTE: explicit namespace calls are on purpose:
      # it takes ~1s to load recipies namespace via box on start,
      # so we want to offload it to after the app has started
      uv_formula <- uv_data |>
        recipes::recipe() |>
        recipes::update_role(status, new_role = "outcome") |>
        recipes::update_role(uv_predictor, new_role = "predictor") |>
        recipes::prep() |>
        formula()

      uvr <- glm(
        uv_formula,
        data = collect(uv_data),
        family = binomial(link = "logit")
      )

      emmeans(
        uvr,
        uv_predictor,
        type = "response",
        infer = c(TRUE, FALSE)
      )
    })

    uv_df <- reactive({
      uv() |>
        as.emm_list() |>
        as.data.frame()
    })

    uv_cache_key <- reactive(c(
      cache_key(),
      uv_predictor()
    ))

    output$uv_regression_notes <- renderUI({
      req(uv_predictor()$variable)
      tags$ul(
        attributes(
          uv_df()
        )$mesg |> lapply(tags$li)
      )
    }) |>
      bindCache(uv_cache_key())

    output$uv_regression_table <- renderTable({
      req(uv_predictor()$variable)
      table <- uv_df() |>
        mutate(
          across(
            where(is.numeric),
            ~ round(.x, 2)
          )
        ) |>
        rename(LCL = asymp.LCL, UCL = asymp.UCL) |>
        relevel_factors(uv_predictor()$variable) |>
        arrange(all_of(uv_predictor()$variable))
      return(table)
    }) |>
      bindCache(uv_cache_key())

    output$uv_plot <- renderPlotly({
      validate(need(
        uv_predictor()$variable,
        config$strings$error_messages$missing_independent_variables
      ))

      viz <- plot(uv()) + theme(text = element_text(size = 15)) +
        ggtitle("Predicted Probabilities") +
        theme_minimal() +
        theme(axis.text = element_text(size = 12)) +
        theme(axis.text.y = element_text(angle = 45)) +
        scale_x_continuous(labels = label_percent(accuracy = 1)) +
        scale_y_discrete(limits = rev)
      ggplotly(viz)
    }) |> bindCache(uv_cache_key())
  })
}
