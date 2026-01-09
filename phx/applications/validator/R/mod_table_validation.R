table_validation_ui <- function(id) {
  ns <- NS(id)
  tabItem(
    tabName = "data_valid",
    div(
      class = "controls-container",
      actionButton(
        class = "bmc-btn",
        inputId = ns("run_tests_btn"),
        label = "Run tests",
        icon = icon("microscope")
      )
    ),
    box(
      title = "Tables/Views validation",
      width = 12,
      withSpinner(verbatimTextOutput(ns("check_dataset")), color = config$bmc_spinner_color)
    ),
    box(
      title = "Fields existance validation",
      width = 12,
      withSpinner(verbatimTextOutput(ns("check_fields")), color = config$bmc_spinner_color)
    ),
    box(
      title = "Tables join validation",
      width = 12,
      withSpinner(verbatimTextOutput(ns("check_joins")), color = config$bmc_spinner_color)
    ),
    box(
      title = "Fips_data headers validation",
      width = 12,
      withSpinner(verbatimTextOutput(ns("check_joined_fields_fips")), color = config$bmc_spinner_color)
    ),
    box(
      title = "Zip5_data headers validation",
      width = 12,
      withSpinner(verbatimTextOutput(ns("check_joined_fields_zip5")), color = config$bmc_spinner_color)
    )
  )
}

table_validation_server <- function(id) {
  moduleServer(id, function(input, output, session) {
    output$check_dataset <- renderPrint({
      req(input$run_tests_btn)
      tables <- config$all_tables
      for (table in tables) {
        tryCatch(
          {
            print(table)
            test_that("table exists", expect_true(dbExistsTable(db_con, table)))
          },
          error = function(e) e
        )
      }
    })

    output$check_fields <- renderPrint({
      req(input$run_tests_btn)
      tables <- config$all_tables[1:3]
      check_fields_result <- list()
      for (table in tables) {
        dataset <- LAZY_TABLES[[table]] |>
          head(1) |>
          collect()
        field_exist_result <- setdiff(config$table_headers[[table]], names(dataset))
        ifelse(
          length(field_exist_result) > 0,
          {
            paste0("❌ Missing fields in ", table, " 👇") |> print()
            field_exist_result |> print()
          },
          {
            list_size <- length(check_fields_result)
            check_fields_result[list_size + 1] <-
              paste0("✅ All necessary fields available in ", table)
          }
        )
      }
      check_fields_result |> unlist()
    })

    output$check_joins <- renderPrint({
      req(input$run_tests_btn)
      table_join_result <- list()
      table_join_result[1] <- get_tbl_join_result(
        data_x = "demo_attributes",
        data_y = "fips_data",
        fields = "fips",
        result_var = "check_joins_fips"
      )
      table_join_result[2] <- get_tbl_join_result(
        data_x = "demo_attributes",
        data_y = "zip5_data",
        fields = "zip5",
        result_var = "check_joins_zip5"
      )
      table_join_result[3] <- get_tbl_join_result(
        data_x = "demo_attributes",
        data_y = "equity_dimensions",
        fields = c("person_id", "year"),
        result_var = "check_joins_person_id_year"
      )
      table_join_result |> unlist()
    })

    output$check_joined_fields_fips <- renderPrint({
      req(input$run_tests_btn)
      feature_details_combined <- get_feature_details_combined(
        filter_value = "Place Attribute (FIPS)",
        keep_col = "feature_type"
      )

      ref_fips_headers <- get_filtered_col(
        data = feature_details_combined,
        filter_col = "feature_type",
        filter_val = "Place Attribute (FIPS)",
        col_name = "Combined"
      )
      fips_data_headers <- LAZY_TABLES[["fips_data"]] |> get_df_clean_colnames()
      fips_ref_not_present <- setdiff(ref_fips_headers, fips_data_headers)
      fips_act_not_present <- setdiff(fips_data_headers, ref_fips_headers)

      if (length(fips_ref_not_present) > 0) {
        config$validation_results$check_joined_fields_fips$fail_text |> print()
        fips_ref_not_present |> print()
      } else {
        config$validation_results$check_joined_fields_fips$pass_text |> print()
      }
      cat("\n\n")
      if (length(fips_act_not_present) > 0) {
        config$validation_results$check_joined_fields_fips_act$fail_text |> print()
        fips_act_not_present |> print()
      } else {
        config$validation_results$check_joined_fields_fips_act$pass_text |> print()
      }
    })

    output$check_joined_fields_zip5 <- renderPrint({
      req(input$run_tests_btn)
      feature_details_combined <- get_feature_details_combined(
        filter_value = "Place Attribute (ZIP5)",
        keep_col = "feature_type"
      )

      ref_zip5_headers <- get_filtered_col(
        data = feature_details_combined,
        filter_col = "feature_type",
        filter_val = "Place Attribute (ZIP5)",
        col_name = "Combined"
      )
      zip5_data_headers <- LAZY_TABLES[["zip5_data"]] |> get_df_clean_colnames()
      zip5_ref_not_present <- setdiff(ref_zip5_headers, zip5_data_headers)
      zip5_act_not_present <- setdiff(zip5_data_headers, ref_zip5_headers)

      if (length(zip5_ref_not_present) > 0) {
        config$validation_results$check_joined_fields_zip5$fail_text |> print()
        zip5_ref_not_present |> print()
      } else {
        config$validation_results$check_joined_fields_zip5$pass_text |> print()
      }
      cat("\n\n")
      if (length(zip5_act_not_present) > 0) {
        config$validation_results$check_joined_fields_zip5_act$fail_text |> print()
        zip5_act_not_present |> print()
      } else {
        config$validation_results$check_joined_fields_zip5_act$pass_text |> print()
      }
    })
  })
}
