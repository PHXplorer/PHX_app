field_validation_ui <- function(id) {
  ns <- NS(id)
  tabItem(
    tabName = "field_valid",
    div(
      class = "controls-container",
      checkboxInput(ns("check_all_results"), "Show all validation check results", FALSE),
      actionButton(
        class = "bmc-btn",
        inputId = ns("gen_report_btn"),
        label = "Get report",
        icon = icon("file")
      )
    ),
    box(
      title = "Equity_dimensions validation",
      width = 12,
      withSpinner(uiOutput(ns("validate_equity_dimensions")), color = config$bmc_spinner_color)
    ),
    box(
      title = "Demo_attributes validation",
      width = 12,
      withSpinner(uiOutput(ns("validate_demo_attributes")), color = config$bmc_spinner_color)
    ),
    box(
      title = "Fips_data validation",
      width = 12,
      withSpinner(uiOutput(ns("validate_fips_data")), color = config$bmc_spinner_color)
    ),
    box(
      title = "Zip5_data validation",
      width = 12,
      withSpinner(uiOutput(ns("validate_zip5_data")), color = config$bmc_spinner_color)
    )
  )
}

field_validation_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    show_result <- reactiveVal("fail_states")

    observeEvent(input$check_all_results, {
      if (input$check_all_results) {
        show_result("all")
      } else {
        show_result("fail_states")
      }
    })

    output$validate_equity_dimensions <- renderUI({
      req(input$gen_report_btn)
      dataset <- get_filtered_data(table = "equity_dimensions", fields = "status") |>
        collect() |>
        withProgress(value = 1, message = "Fetching data...")
      create_agent(
        tbl = dataset,
        tbl_name = "equity_dimensions",
        label = "VALID-I",
        actions = ACTION_LEVEL
      ) |>
        col_is_integer(status) |>
        col_vals_in_set(status, set = STATUS_VALUES_SET) |>
        interrogate() |>
        get_agent_report(
          title = "Validation report",
          arrange_by = "severity",
          keep = isolate(show_result())
        ) |>
        withProgress(value = 1, message = "Running validations")
    })

    output$validate_demo_attributes <- renderUI({
      req(input$gen_report_btn)
      demo_attr_data <- LAZY_TABLES[["demo_attributes"]] |>
        head(1) |>
        collect() |>
        withProgress(value = 1, message = "Fetching data...")
      demo_attr_headers <- demo_attr_data |> get_df_clean_colnames()

      feature_details <- get_filtered_data(
        table = "feature_details",
        fields = c("feature_type", "value_type", "featureid", "display")
      ) |>
        filter(feature_type == "Demo Attribute", display == 1)

      text_headers_feat_details <- get_filtered_col(
        data = feature_details,
        filter_col = "value_type",
        filter_val = "text",
        col_name = "featureid"
      )

      text_headers_demo <- intersect(text_headers_feat_details, demo_attr_headers)

      validate(
        need(
          length(text_headers_demo) > 0,
          "No headers in demo_attributes match the values of featureid in feature_details"
        )
      )

      create_agent(
        tbl = demo_attr_data,
        tbl_name = "demo_attributes",
        label = "VALID-I",
        actions = ACTION_LEVEL
      ) |>
        col_is_character(columns = all_of(text_headers_demo)) |>
        interrogate() |>
        get_agent_report(
          title = "Validation report",
          arrange_by = "severity",
          keep = isolate(show_result())
        ) |>
        withProgress(value = 1, message = "Running validations")
    })

    output$validate_fips_data <- renderUI({
      req(input$gen_report_btn)
      get_cols_validation_report(
        filter_value = "Place Attribute (FIPS)",
        dataset = "fips_data",
        tbl_name = "fips_data",
        show_result = reactive(isolate(show_result()))
      )
    })

    output$validate_zip5_data <- renderUI({
      req(input$gen_report_btn)
      get_cols_validation_report(
        filter_value = "Place Attribute (ZIP5)",
        dataset = "zip5_data",
        tbl_name = "zip5_data",
        show_result = reactive(isolate(show_result()))
      )
    })
  })
}
