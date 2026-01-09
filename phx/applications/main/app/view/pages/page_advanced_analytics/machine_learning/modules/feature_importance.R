box::use(
  bs4Dash[box],
  htmltools[HTML],
  shiny[
    actionButton,
    conditionalPanel,
    htmlOutput,
    moduleServer,
    need,
    NS,
    numericInput,
    observeEvent,
    Progress,
    reactive,
    reactiveVal,
    renderUI,
    req,
    showNotification,
    tags,
    updateActionButton,
    validate,
  ],
  shinyWidgets[switchInput],
  reactable[renderReactable, reactableOutput],
  reactablefmtr[data_bars],
)

box::use(
  app / logic / categorize_numeric[categorize_numeric],
  app / logic / feature_importance[
    get_feature_importance,
    get_modelling_data,
    add_labels_to_importance,
    plot_feature_importance,
  ],
  app / logic / DataLoader[data_loader],
  app / logic / join_variables[join_variables],
  app / logic / load_env[config],
  app / logic / relevel_factors[relevel_factors],
  app / logic / utils[bmc_spinner, nrows_db],
  app / view / input / dimension_input,
)

#' @export
LABEL <- "Feature Importance"

DEFAULT_NUMBER_OF_TREES <- 501
DEFAULT_SAMPLE_SIZE <- 2500

#' @export
ui <- function(id) {
  ns <- NS(id)

  tags$div(
    box(
      width = 12,
      collapsible = FALSE,
      tags$div(
        style = "display:flex;gap:1rem",
        numericInput(ns("ntrees"), "Number of trees", value = DEFAULT_NUMBER_OF_TREES),
        numericInput(ns("sample_size"), "Sample size", value = DEFAULT_SAMPLE_SIZE),
      ),
      tags$details(
        tags$summary(
          style = "font-weight: bold",
          "Show Variable Selection Options"
        ),
        tags$div(
          style = "padding-top: 1rem",
          tags$text("Use specific variables for model training?"),
          switchInput(
            inputId = ns("variable_subset"),
            onLabel = "Yes",
            offLabel = "No",
            value = FALSE,
            size = "mini"
          ),
          conditionalPanel(
            condition = "input.variable_subset === true",
            ns = ns,
            tags$div(
              style = "display: flex; flex-direction:column;gap: 0.5rem",
              tags$div(
                class = "sentence-filter-container",
                "Include variables",
                dimension_input$ui(ns("select_predictors"))
              )
            )
          ),
          conditionalPanel(
            condition = "input.variable_subset === false",
            ns = ns,
            tags$div(
              class = "sentence-filter-container",
              "Exclude variables",
              dimension_input$ui(ns("remove_predictors"))
            )
          )
        )
      ),
      tags$div(
        style = "margin-top: 1rem",
        actionButton(ns("run_model"), label = "Run model")
      )
    ),
    box(
      width = 12,
      tags$h3("Variable Importance"),
      htmlOutput(ns("number_of_samples")),
      reactableOutput(ns("vi_table")) |>
        bmc_spinner(proxy.height = "200px"),
      htmlOutput(ns("missing_variables"))
    )
  )
}

#' @export
server <- function(id, equity_data_filtered, measure, cache_key) {
  moduleServer(id, function(input, output, session) {
    importance_values <- reactiveVal()
    missing_variables <- reactiveVal()

    predictors <- dimension_input$server(
      "select_predictors",
      title = "Select predictors",
      multiple = TRUE,
      multiple_limit = 100,
      no_categorization = TRUE
    )

    predictors_removed <- dimension_input$server(
      "remove_predictors",
      title = "Remove predictors",
      initial_variable = measure(),
      multiple = TRUE,
      multiple_limit = 100,
      no_categorization = TRUE
    )

    # Make sure to reset the importance list when these values change
    observeEvent(
      eventExpr = list(
        measure(),
        equity_data_filtered(),
        input$variable_subset,
        input$sample_size,
        input$ntrees,
        predictors(),
        predictors_removed(),
        session$userData$advanced_settings_state$place_attribute_type
      ),
      ignoreInit = TRUE,
      {
        importance_values(NULL)
        missing_variables(NULL)
        updateActionButton(
          session = session,
          inputId = "run_model",
          label = "Run model"
        )
      }
    )

    observeEvent(input$run_model, {
      updateActionButton(
        session = session,
        inputId = "run_model",
        label = "Re-run model"
      )

      filtered_data_nrows <- nrows_db(equity_data_filtered())

      if (filtered_data_nrows == 0) {
        showNotification(
          "No data available with the selected filters",
          duration = 5,
          type = "error"
        )
        return()
      }

      if (input$variable_subset && length(predictors()$variable) == 0) {
        showNotification(
          config$strings$error_messages$ml_missing_predictors,
          duration = 5,
          type = "error"
        )
        return()
      }

      progress <- Progress$new()
      on.exit(progress$close())

      data_mode <- if (input$variable_subset) "subset" else "complete"

      progress$set(message = "Fetching data", value = 0.25)

      modelling_data <- get_modelling_data(
        equity_data_filtered(),
        sample_size = input$sample_size,
        mode = data_mode,
        excluded_variables = predictors_removed()$variable,
        included_variables = predictors()$variable,
        place_attribute_type = session$userData$advanced_settings_state$place_attribute_type
      )

      if (inherits(modelling_data, "simpleError")) {
        showNotification(
          modelling_data$message,
          duration = 5,
          type = "error"
        )
        return()
      }

      missing_variables(modelling_data$missing_variables)

      progress$set(message = "Creating model", value = 0.5)
      result <- get_feature_importance(
        modelling_data$target,
        modelling_data$predictors,
        ntrees = input$ntrees
      ) |>
        add_labels_to_importance(data_loader$variable_details)

      progress$set(message = "Preparing result", value = 0.75)
      importance_values(c(importance_values(), list(result)))
    })

    output$number_of_samples <- renderUI({
      input$run_model
      req(importance_values())

      tags$em(
        style = "margin: 0 0 1rem 0",
        HTML(
          paste(
            "Results based on running the model",
            length(importance_values()),
            "time(s)"
          )
        )
      )
    })

    output$vi_table <- renderReactable({
      input$run_model
      req(importance_values())

      plot_feature_importance(importance_values())
    })

    output$missing_variables <- renderUI({
      input$run_model
      req(missing_variables())

      variables_with_labels <- data.frame(colname = missing_variables()) |>
        add_labels_to_importance(data_loader$variable_details)

      tags$p(
        style = "margin: 1rem 0 0 0",
        HTML("The following variables were removed due to missing rate &ge; 50%:\n"),
        tags$pre(
          style = "padding:0",
          paste(c(variables_with_labels), collapse = "\n")
        )
      )
    })
  })
}
