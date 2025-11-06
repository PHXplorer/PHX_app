tictoc::tic("[module] main (libraries)")
box::use(
  bs4Dash[
    dashboardBody,
    dashboardHeader,
    dashboardPage,
    dashboardSidebar,
    menuItem,
    sidebarMenu,
    tabItem,
    tabItems,
  ],
  dplyr[case_when, filter, mutate],
  purrr[map],
  rhino[log],
  rlang[list2],
  shiny[
    actionButton,
    incProgress,
    modalDialog,
    moduleServer,
    NS,
    observeEvent,
    reactive,
    reactiveVal,
    removeModal,
    req,
    shinyOptions,
    showModal,
    tags,
    withMathJax,
    withProgress,
  ],
  shiny.info[toggle_info],
  shiny.telemetry[DataStorageLogFile, use_telemetry, Telemetry],
  tictoc[tic, toc]
)
tictoc::toc()

# Import shiny modules from app/view
tictoc::tic("[module] main (modules)")
box::use(
  app / logic / alerts[init_alerts],
  app / logic / categorize_numeric[config_unique_categories],
  app / logic / DataLoader[data_loader],
  app / logic / EquityDimensionStatus[EquityDimensionStatus],
  app / logic / load_env[config, debug_info, initial_advanced_filters_state],
  app / logic / redis[redis_client],
  app / logic / relevel_factors[relevel_vector],
  app / logic / utils[get_app_name],
  app / view / global_filters,
  app / view / knowledge_center,
  app / view / pages[
    page_advanced_analytics,
    page_health_outcomes,
    page_home,
    page_neighborhood_data
  ],
  app / view / web_dependency[use_react_bootstrap],
)
tictoc::toc()

shinyOptions(cache = redis_client)

# Initialize telemetry with default options
telemetry <- Telemetry$new(
  app_name = get_app_name(),
  data_storage = DataStorageLogFile$new(log_file_path = "telemetry.txt")
)

#' @export
ui <- function(id) {
  ns <- NS(id)

  dashboardPage(
    dark = NULL,
    dashboardHeader(
      title = tags$a(
        class = "brand-link bg-white",
        href = "#",
        tags$img(src = "static/h2e_logo.png")
      ),
      status = "white",
      border = FALSE
    ),
    dashboardSidebar(
      skin = "light",
      width = 250,
      status = "white",
      sidebarMenu(
        id = ns("tabs"),
        menuItem("Home", tabName = "home"),
        menuItem("Health Outcomes", tabName = "time"),
        page_advanced_analytics$ui_sidebar("Advanced Analytics"),
        menuItem("Neighborhood Data", tabName = "neighbor"),
        knowledge_center$ui(ns("knowledge"))
      )
    ),
    dashboardBody(
      withMathJax(),
      debug_info(),
      use_react_bootstrap(),
      use_telemetry(),
      global_filters$ui(ns("global_filters")),
      tabItems(.list = list2(
        page_home$ui(id = ns("home"), tab_name = "home"),
        page_health_outcomes$ui(id = ns("health_outcome"), tab_name = "time"),
        !!!page_advanced_analytics$ui_body(id = ns("adv_analytics")),
        page_neighborhood_data$ui(id = ns("neighbor_data"), tab_name = "neighbor")
      ))
    )
  )
}

#' @export
server <- function(id) {
  moduleServer(id, function(input, output, session) {
    # Minimal setup to track events
    telemetry$start_session(
      track_inputs = config$telemetry$track_inputs,
      track_values = config$telemetry$track_values,
      username = Sys.getenv("SHINYPROXY_USERNAME")
    )
    telemetry$log_navigation("tabs")


    # Send categorize_numeric_breaks to the JavaScript side
    session$sendCustomMessage(
      "config-unique-categories",
      config_unique_categories |>
        map(\(x) {
          x |>
            relevel_vector() |>
            sort() |>
            as.character()
        })
    )
    # initialize advanced filters state
    # default filters are selected when you start
    session$userData$advanced_filters_state <- reactiveVal(initial_advanced_filters_state(session))
    global_filters <- global_filters$server("global_filters", reactive(input$tabs))

    r_equity_dimension_status <- reactive({
      tic("r_equity_dimension_status")
      result <- withProgress(message = "Applying advanced filters...", value = 0.5, {
        EquityDimensionStatus$new(data_loader, session$userData$advanced_filters_state())
      })
      toc()
      result
    })

    # we are creating a separete reactive only for triggering reactivity
    # results of r_equity_dimension_status_filtered() and r_equity_dimension_status()
    # points to the same address in memory
    r_equity_dimension_status_filtered <- reactive({ # nolint
      req(r_equity_dimension_status())
      tic("r_equity_dimension_status_filtered")
      result <- withProgress(message = "Applying global filters...", value = 1, {
        r_equity_dimension_status()$set_global_filters(
          global_filters$measure(),
          global_filters$period(),
          global_filters$selected_dims()
        )
      })
      toc()
      result
    })

    status_by_year <- reactive(r_equity_dimension_status_filtered()$get_incontrol_table())
    session$userData$status_by_year <- status_by_year

    # advanced analytics elements
    init_alerts(session)

    equity_data_filtered <- reactive({
      r_equity_dimension_status_filtered()$get_measure_df() |>
        mutate(
          status = case_when(
            status == 1 ~ 1,
            status == 0 ~ 0,
            TRUE ~ NA_real_
          )
        )
    })

    # combinations of input values used to cache shiny outputs
    common_cache_key <- reactive(c(
      global_filters$measure(),
      global_filters$period(),
      session$userData$advanced_filters_state()$selected
    ))

    page_home$server("home", parent_session = session)

    page_health_outcomes$server(
      id = "health_outcome",
      selected_dims = global_filters$selected_dims,
      status_by_year = status_by_year,
      measure = reactive(global_filters$measure()),
      cache_key = common_cache_key
    )

    page_advanced_analytics$server(
      id = "adv_analytics",
      equity_data_filtered = equity_data_filtered,
      measure = reactive(global_filters$measure()),
      cache_key = common_cache_key
    )

    page_neighborhood_data$server(
      id = "neighbor_data",
      global_filters = global_filters,
      r_equity_dimension_status = r_equity_dimension_status_filtered
    )

    knowledge_center$server("knowledge")
  })
}
