box::use(
  dplyr[filter, group_by, summarize, collect, arrange, desc, coalesce, mutate, ungroup],
  reactable[reactableOutput, renderReactable, reactable, colDef],
  reactablefmtr[data_bars],
  shiny[
    bindCache,
    div,
    moduleServer,
    need,
    NS,
    reactive,
    req,
    tagList,
    validate,
  ],
  shinyWidgets[pickerOptions],
  tidyr[unite],
)

box::use(
  app / logic / DataLoader[data_loader],
  app / logic / load_env[config],
  app / logic / join_variables[join_variables],
  app / logic / utils[bmc_spinner, get_percentile_breaks, replace_na],
  app / logic / categorize_numeric[categorize_numeric],
  app / view / input / dimension_input,
)

#' @export
eda_ui <- function(id) {
  ns <- NS(id)
  div(
    style = "min-height: 100px;",
    div(
      class = "sentence-filter-container",
      "Exploratory Data Analysis by",
      dimension_input$ui(ns("eda")),
    ),
    reactableOutput(ns("eda_table")) |>
      bmc_spinner(proxy.height = "200px")
  )
}

#' @export
eda_server <- function(id, equity_data_filtered, cache_key) {
  moduleServer(
    id,
    function(input, output, session) {
      eda_vars <- dimension_input$server(
        "eda",
        title = "EDA Variables",
        multiple = TRUE
      )

      eda_data <- reactive({
        validate(
          need(length(eda_vars()$variable) > 0, config$strings$error_messages$eda_missing_var)
        )
        eda_vars <- eda_vars()$variable
        percentile_breaks <- get_percentile_breaks(eda_vars()$variable, eda_vars()$category)
        categorical_vars <- intersect(
          eda_vars,
          c(data_loader$categorical_colnames, names(percentile_breaks))
        )

        equity_data_filtered() |>
          filter(status == 1) |>
          join_variables(eda_vars) |>
          categorize_numeric(percentile_breaks) |>
          replace_na(eda_vars) |>
          group_by(across(c(eda_vars))) |>
          summarize(count_distinct = n_distinct(person_id)) |>
          filter(count_distinct >= !!config$numbers$minimum_sample_size) |>
          arrange(desc(count_distinct)) |>
          collect() |>
          ungroup() |>
          unite("margin_name", all_of(eda_vars), sep = ", ")
      })

      output$eda_table <- renderReactable({
        total <- sum(eda_data()$count_distinct)
        reactable(
          data = eda_data(),
          columns = list(
            margin_name = colDef(name = "", sortable = FALSE, searchable = TRUE),
            count_distinct = colDef(
              name = "Number of Patients",
              sortable = TRUE,
              searchable = FALSE,
              filterable = FALSE,
              cell = eda_data() |>
                data_bars(
                  text_position = "outside-end",
                  number_fmt = \(x) glue::glue("{x}\U00A0({round(x / total * 100, 1)}%)"),
                  fill_color = "black",
                  background = "white"
                )
            )
          )
        )
      }) |>
        bindCache(eda_vars(), cache_key())
    }
  )
}
