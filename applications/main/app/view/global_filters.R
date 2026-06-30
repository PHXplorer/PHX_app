box::use(
  glue[glue],
  dplyr[as_tibble, mutate, coalesce, select],
  shiny[
    actionButton,
    actionLink,
    checkboxInput,
    conditionalPanel,
    debounce,
    div,
    icon,
    moduleServer,
    NS,
    observe,
    observeEvent,
    reactive,
    reactiveVal,
    renderUI,
    tags,
    uiOutput,
    updateActionButton,
    updateCheckboxInput,
  ],
  shinyWidgets[pickerInput, sliderTextInput, updatePickerInput],
  bs4Dash[ionicon, removePopover, addPopover],
  purrr[discard, map],
  stats[setNames],
)

box::use(
  app / logic / load_env[config, initial_advanced_filters_state],
  app / logic / DataLoader[data_loader],
  app / logic / ColnameDetails[colname_details],
  app / view / advanced_filters[
    filters_list_ui,
    filters_list_server
  ],
  app / view / advanced_settings,
  app / logic / utils[get_percentile_breaks],
  app / view / download_btn[download_btn_ui, download_btn_server],
  app / view / variable_info,
  app / view / input / dimension_input,
)

MAX_GROUPINGS <- 2

YEARS_SEPERATOR <- " to "

START_YEAR <- max(config$global_filters$start_year, min(data_loader$equity_years))
END_YEAR <- max(data_loader$equity_years) - 1

initial_measure_label <- colname_details$get_variable_label(config$global_filters$default_measure)


#' @export
ui <- function(id) {
  ns <- NS(id)

  initial_range_label <- paste(
    c(START_YEAR, END_YEAR),
    collapse = YEARS_SEPERATOR
  )

  conditionalPanel(
    condition = "input.tabs !== 'home'",
    ns = NS("app"),
    class = "global-filters-container",
    `data-cy` = "global-filters-container",
    div(
      class = "global-filters-sentence-container",
      div(
        class = "sentence-filter-container",
        "Show me the percentage of",
        dimension_input$ui(ns("measure"), initial_measure_label, `data-cy` = "measure-input-button")
      ),
      variable_info$ui(ns("measure_info")),
      div(
        class = "global-filters-dimensions",
        "by",
        dimension_input$ui(ns("dim1"), `data-cy` = "dimensions-input-button")
      ),
      div(
        class = "sentence-filter-container year-slider",
        "for",
        div(
          class = "year-slider-container",
          `data-cy` = "year-input-slider",
          div(
            class = "text-container",
            conditionalPanel(
              condition = "input.tabs !== 'neighbor'",
              ns = NS("app"),
              checkboxInput(
                ns("show_slider_years"),
                label = initial_range_label
              )
            ),
            conditionalPanel(
              condition = "input.tabs === 'neighbor'",
              ns = NS("app"),
              checkboxInput(
                ns("show_slider_years_neighbor"),
                label = END_YEAR
              )
            )
          ),
          conditionalPanel(
            condition = "input.show_slider_years || input.show_slider_years_neighbor",
            ns = ns,
            class = "slider-container",
            conditionalPanel(
              condition = "input.show_slider_years",
              ns = ns,
              sliderTextInput(
                inputId = ns("years"),
                label = "",
                choices = data_loader$equity_years,
                selected = c(START_YEAR, END_YEAR),
                grid = TRUE,
                width = "472px"
              )
            ),
            conditionalPanel(
              condition = "input.show_slider_years_neighbor",
              ns = ns,
              sliderTextInput(
                inputId = ns("years_neighbor"),
                label = "",
                choices = data_loader$equity_years,
                selected = END_YEAR,
                grid = TRUE,
                width = "472px"
              )
            )
          )
        )
      ),
    ),
    div(
      class = "global-filters-extra-controls",
      dimension_input$ui(
        id = ns("advanced_filters"),
        initial_label = icon("filter", lib = "glyphicon"),
        is_label_dynamic = FALSE,
        `data-cy` = "advanced-filters-button"
      ),
      advanced_settings$ui(ns("advanced_settings")),
      conditionalPanel(
        condition = "input.tabs === 'time'",
        ns = NS("app"),
        download_btn_ui(ns("health_outcomes_download"))
      )
    )
  )
}

#' @export
server <- function(id, current_tab) {
  moduleServer(id, function(input, output, session) {
    advanced_settings$server("advanced_settings")

    measure <- dimension_input$server(
      id = "measure",
      title = "Dimension Selection",
      initial_variable = config$global_filters$default_measure,
      feature_type_subset = "Health Dimension"
    )

    selected_dims <- dimension_input$server(
      id = "dim1",
      title = "Attribute Selection",
      multiple = TRUE
    )

    advanced_filters <- dimension_input$server(
      id = "advanced_filters",
      title = "Advanced Filters",
      multiple = TRUE,
      mode = "filter",
      is_label_dynamic = FALSE,
      initial_variable = names(initial_advanced_filters_state(session)$inputs),
      initial_category = map(
        initial_advanced_filters_state(session)$inputs,
        \(x) x$category
      ) |> unlist(),
      initial_filter_value = map(
        initial_advanced_filters_state(session)$inputs,
        \(x) x$value
      ) |>
        unlist() |>
        unname(),
    )

    download_btn_server("health_outcomes_download", session$userData$status_by_year)

    variable_info$server(
      id = "measure_info",
      info_for = reactive(measure()$variable),
      placement = "bottom"
    )

    years_debounced <- reactive(input$years) |> debounce(500)
    years_neighbor_debounced <- reactive(input$years_neighbor) |> debounce(500)

    observeEvent(years_debounced(), {
      updateCheckboxInput(
        session = session,
        inputId = "show_slider_years",
        label = paste(years_debounced(), collapse = YEARS_SEPERATOR),
        value = input$show_slider_years
      )
    })

    observeEvent(years_neighbor_debounced(), {
      updateCheckboxInput(
        session = session,
        inputId = "show_slider_years_neighbor",
        label = years_neighbor_debounced(),
        value = input$show_slider_years_neighbor
      )
    })

    observeEvent(advanced_filters(), {
      filters <- advanced_filters() |>
        map(\(x) {
          if (is.null(x)) {
            x <- NA_character_
          }
          x
        }) |>
        as_tibble()

      selected_state <- filters |>
        mutate(filter_value = coalesce(value, category)) |>
        select(variable, filter_value)
      selected_state <- selected_state$filter_value |>
        setNames(selected_state$variable) |>
        as.list()

      percentile_breaks <- get_percentile_breaks(filters$variable, filters$category)

      input_state <- apply(filters, 1, function(row) {
        row <- as.list(row)
        list(list(value = row$value, category = row$category)) |>
          setNames(row$variable)
      }) |>
        unlist(recursive = FALSE)

      session$userData$advanced_filters_state(
        list(
          selected = selected_state,
          percentile_breaks = percentile_breaks,
          inputs = input_state
        )
      )
    })

    r_current_tab <- reactiveVal("home")
    observeEvent(current_tab(), {
      if (current_tab() %in% names(config$advanced_analytics_framework$active_modules)) {
        r_current_tab("advanced_analytics")
      } else {
        r_current_tab(current_tab())
      }
    })

    r_period <- reactiveVal(NULL)
    observe({
      if (r_current_tab() == "neighbor") {
        r_period(rep(years_neighbor_debounced(), 2))
      } else {
        r_period(years_debounced())
      }
    })

    r_selected_dims <- reactiveVal(list())
    observe({
      if (r_current_tab() == "time" && length(selected_dims()$variable) > 0) {
        r_selected_dims(
          list(
            dimensions = selected_dims()$variable,
            percentile_columns = get_percentile_breaks(
              selected_dims()$variable,
              selected_dims()$category
            )
          )
        )
      } else {
        r_selected_dims(list())
      }
    })

    list(
      measure = reactive(measure()$variable),
      period = r_period,
      selected_dims = r_selected_dims
    )
  })
}
