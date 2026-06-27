box::use(
  broom[tidy, glance],
  bs4Dash[box, addPopover, ionicon],
  dplyr[
    across,
    all_of,
    bind_rows,
    coalesce,
    collect,
    everything,
    filter,
    group_by_at,
    mutate,
    n,
    pull,
    select,
    summarize,
    where,
  ],
  emmeans[get_emm_option],
  equatiomatic[eqOutput, renderEq, extract_eq],
  glue[glue],
  performance[model_performance],
  shiny[
    actionButton,
    actionLink,
    bindCache,
    bindEvent,
    column,
    conditionalPanel,
    eventReactive,
    fluidRow,
    htmlOutput,
    isolate,
    moduleServer,
    need,
    NS,
    observeEvent,
    reactive,
    renderTable,
    renderText,
    renderUI,
    req,
    tableOutput,
    tagList,
    tags,
    textOutput,
    uiOutput,
    validate,
  ],
  shinyWidgets[pickerInput, updatePickerInput],
  stats[glm, binomial, formula],
  tibble[as_tibble],
  tidyr[pivot_wider, pivot_longer],
)

box::use(
  app / logic / create_formula[create_formula],
  app / logic / alerts[init_alerts, add_alert],
  app / logic / relevel_factors[relevel_factors],
  app / logic / join_variables[join_variables],
  app / logic / utils[
    bmc_spinner,
    format_pvalues,
    get_percentile_breaks,
    replace_na,
  ],
  app / logic / ColnameDetails[colname_details],
  app / logic / load_env[config],
  app / logic / get_variables_from_colnames[get_variables_from_colnames],
  app / logic / DataLoader[data_loader],
  app / logic / categorize_numeric[categorize_numeric],
  app / view / vif_plot[vif_plot_output, vif_plot_server],
  app / view / glm_emm[glm_emm_ui, glm_emm_server],
  app / view / advanced_filters[
    filters_list_ui,
    filters_list_server
  ],
  app / view / input / dimension_input,
)

#' @export
LABEL <- "Multivariate Regression"

#' @export
ui <- function(id) {
  ns <- NS(id)

  tags$div(
    box(
      collapsible = FALSE,
      solidHeader = FALSE,
      width = 12,
      title = "Model the relationship between selected variables and outcome of interest", #   nolint
      tags$ul(
        class = "logistic-regression-filters-container",
        tags$li(
          class = "sentence",
          tags$div(
            class = "sentence-filter-container",
            "Model ",
            tags$span(
              class = "highlighted-text",
              textOutput(ns("measure_variable"))
            ),
            "using",
            dimension_input$ui(
              ns("independent_variable"),
              initial_label = "Race and Sex"
            ),
            "where the primary variable of interest is",
            pickerInput(
              ns("primary"),
              "Select primary variable of interest:",
              choices = c()
            )
          )
        ),
        tags$li(
          class = "sentence",
          tags$div(
            class = "sentence-filter-container",
            "Group the output by",
            tags$span(
              class = "optional-tag",
              "Optional"
            ),
            pickerInput(
              ns("group"),
              "Select variables to group output by (optional):",
              choices = c()
            )
          )
        ),
        uiOutput(ns("interaction_variable"))
      ),
      actionButton(ns("go"), "Go"),
      conditionalPanel(
        condition = "input.go",
        ns = ns,
        eqOutput(ns("logistic_regresion_equation")) |>
          bmc_spinner(proxy.height = "80px")
      )
    ),
    conditionalPanel(
      condition = "input.go",
      ns = ns,
      box(
        collapsible = FALSE,
        width = 12,
        title = "Estimated Marginal Means (EMM)",
        glm_emm_ui(ns("glm_emm"))
      ),
      box(
        collapsible = FALSE,
        width = 12,
        fluidRow(
          column(
            width = 6,
            tags$h3(
              class = "with-icon",
              "Variance Inflation Factor"
            ),
            actionLink(
              ns("popover-vif"),
              ionicon(
                "information-circle-outline"
              )
            )
          ),
          column(
            width = 6,
            tags$h3("Model Coefficients")
          )
        ),
        fluidRow(
          column(
            width = 6,
            vif_plot_output(ns("vif_plot"))
          ),
          column(
            width = 6,
            tags$div(
              class = "box-scroll",
              tableOutput(ns("model_metrics_tidy")) |> bmc_spinner()
            )
          )
        ),
        tags$h3(
          class = "with-icon",
          "Model Performance"
        ),
        actionLink(
          ns("popover-model-performance"),
          ionicon(
            "information-circle-outline"
          )
        ),
        htmlOutput(ns("model_metrics_performance")) |> bmc_spinner()
      )
    )
  )
}

#' @export
server <- function(id, equity_data_filtered, measure, cache_key) {
  moduleServer(id, function(input, output, session) {
    filters_list_server("selected_filters_advanced_analytics")

    observeEvent(input$go, {
      addPopover(
        id = "popover-vif",
        options = list(
          title = "",
          placement = "right",
          content = config$strings$info_boxes$vif_plot,
          trigger = "hover"
        )
      )

      addPopover(
        id = "popover-model-performance",
        options = list(
          title = "",
          placement = "right",
          content = config$strings$info_boxes$model_performance,
          trigger = "hover"
        )
      )
    })

    output$measure_variable <- renderText(
      colname_details$get_variable_description(measure())
    )

    independent_variable <- dimension_input$server(
      "independent_variable",
      title = "Independent Variables",
      initial_variable = c("race", "sex"),
      multiple = TRUE,
      allow_continuous = TRUE,
      multiple_limit = 10
    )

    observeEvent(independent_variable(), {
      updatePickerInput(
        session,
        "primary",
        choices = get_variables_from_colnames(independent_variable()$variable)
      )
    })

    observeEvent(c(independent_variable(), input$primary), {
      req(independent_variable())
      updatePickerInput(
        session,
        "group",
        choices = c(
          "nothing" = "",
          get_variables_from_colnames(
            independent_variable()$variable[independent_variable()$variable != input$primary]
          )
        )
      )
    })

    output$interaction_variable <- renderUI({
      req(length(independent_variable()$variable) >= 2)
      tags$li(
        class = "sentence",
        tags$div(
          class = "sentence-filter-container",
          "Create an interaction variable between",
          tags$span(
            class = "optional-tag",
            "Optional"
          ),
          pickerInput(
            session$ns("interaction_1"),
            label = "",
            choices = c(
              "nothing" = "",
              get_variables_from_colnames(independent_variable()$variable)
            ),
            selected = ""
          ),
          uiOutput(session$ns("interaction_2"), style = "display: inherit; gap: inherit;")
        )
      )
    })

    output$interaction_2 <- renderUI({
      req(input$interaction_1)
      tagList(
        "and",
        pickerInput(
          session$ns("interaction_2"),
          label = "",
          choices = get_variables_from_colnames(
            independent_variable()$variable[
              independent_variable()$variable != input$interaction_1
            ]
          )
        )
      )
    })

    interaction_variables <- reactive({
      # in some situtations (fast clicking) this input might be NULL
      if (is.null(input$interaction_1) || input$interaction_1 == "") {
        NULL
      } else {
        c(input$interaction_1, input$interaction_2)
      }
    })

    recipe_formula <- reactive({
      validate(
        need(
          length(independent_variable()$variable) > 0 &&
            all(independent_variable()$variable != ""),
          config$strings$error_messages$missing_independent_variables
        ),
        need(
          length(interaction_variables()) %in% c(0, 2),
          config$strings$error_messages$needed_two_interact_vars
        )
      )
      create_formula(
        independent_vars = independent_variable()$variable,
        dependent_var = "status",
        interaction_vars = interaction_variables()
      )
    })

    observeEvent(
      input$go,
      priority = 1,
      {
        init_alerts(session, overwrite = TRUE)
      }
    )

    model_cache_key <- reactive(c(
      cache_key(),
      independent_variable(),
      input$group,
      input$primary,
      input$interaction_1,
      input$interaction_2
    ))

    glm_reg <- eventReactive(input$go, {
      validate(
        need(
          independent_variable()$variable,
          "Select at least 1 independent variable to create a model"
        ),
        need(
          equity_data_filtered() |>
            summarize(n()) |>
            collect() |>
            pull() > 0,
          "No data available for selected filters"
        )
      )
      variable_name <- "status"
      count <- equity_data_filtered() |>
        group_by_at(variable_name) |>
        summarize(count = n()) |>
        filter(count == min(count, na.rm = TRUE)) |>
        collect()

      independent_count <- length(independent_variable()$variable)

      add_alert(
        session,
        "one_in_ten_rule",
        msg = glue("For {variable_name} = {count$status} there is {count$count} observations. With {independent_count} independent variable the one in ten rule is violated."), # nolint
        condition = (count$count / independent_count) < 10
      )

      percentile_breaks <- get_percentile_breaks(
        independent_variable()$variable,
        independent_variable()$category
      )

      glm_reg_data <- equity_data_filtered() |>
        join_variables(independent_variable()$variable) |>
        categorize_numeric(percentile_breaks)
      reference_grid_size <- glm_reg_data |>
        select(all_of(independent_variable()$variable)) |>
        collect() |>
        select(
          where(function(x) is.character(x) | is.factor(x))
        ) |>
        mutate(across(everything(), as.factor)) |>
        lapply(function(x) levels(as.factor(x))) |>
        expand.grid() |>
        nrow()
      reference_grid_size_is_big <- reference_grid_size > get_emm_option("rg.limit")
      alert_message <- config$strings$error_messages$reference_grid_size_too_big
      add_alert(
        session,
        "reference_grid_size",
        msg = alert_message,
        condition = reference_grid_size_is_big
      )
      validate(need(!reference_grid_size_is_big, alert_message))

      # validate if there is enough categories in the independent variables
      selected_vars <- isolate(independent_variable()$variable)

      categorical_predictors <- intersect(
        independent_variable()$variable,
        data_loader$categorical_colnames
      )

      numerical_predictors <- setdiff(
        independent_variable()$variable[
          unlist(lapply(independent_variable()$category, \(x) isTRUE(x == "Continuous")))
        ],
        categorical_predictors
      )

      glm_reg_data <- glm_reg_data |>
        select(all_of(selected_vars), "status") |>
        replace_na(categorical_predictors) |>
        mutate(across(all_of(numerical_predictors), as.numeric)) |>
        collect() |>
        relevel_factors(categorical_predictors)

      glm(
        recipe_formula(),
        data = glm_reg_data,
        family = binomial(link = "logit")
      )
    })

    output$logistic_regresion_equation <- renderEq({
      req(glm_reg())
      extract_eq(glm_reg(), wrap = TRUE)
    }) |>
      bindCache(model_cache_key()) |>
      bindEvent(input$go)

    glm_emm_server(
      id = "glm_emm",
      glm_reg = glm_reg,
      group = reactive(input$group),
      primary = reactive(input$primary),
      recalculate = reactive(input$go),
      cache_key = model_cache_key
    )

    # I pass input$go to trigger recalculation on press of Go button
    # It is done for purpose of displaying alert immediately, not when plot is rendered
    vif_plot_server("vif_plot", glm_reg, model_cache_key, reactive(input$go))

    output$model_metrics_tidy <- renderTable(
      {
        req(glm_reg())
        table <- glm_reg() |> tidy(exp = TRUE)
        table <- table |>
          mutate(`p.value` = format_pvalues(`p.value`))
        return(table)
      },
      digits = config$numbers$decimal_accuracy,
      align = "????r"
    ) |>
      bindCache(model_cache_key()) |>
      bindEvent(input$go)

    output$model_metrics_performance <- renderUI({
      req(input$go)
      glm_glance <- glm_reg() |>
        glance() |>
        pivot_longer(everything())
      glm_performance <- glm_reg() |>
        model_performance() |>
        as_tibble() |>
        pivot_longer(everything())
      metrics <- glm_glance |>
        bind_rows(glm_performance) |>
        mutate(value = round(value, 2)) |>
        unique() |>
        pivot_wider() |>
        as.list()
      tags$div(
        class = "model-metrics-container",
        lapply(
          names(metrics),
          function(x) {
            tags$div(
              class = "model-metric",
              tags$p(x, class = "model-metric-name"),
              tags$p(metrics[[x]], class = "model-metric-value")
            )
          }
        )
      )
    }) |>
      bindCache(model_cache_key()) |>
      bindEvent(input$go)
  })
}
