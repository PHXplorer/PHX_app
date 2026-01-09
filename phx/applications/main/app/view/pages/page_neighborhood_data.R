box::use(
  shiny[
    moduleServer,
    NS,
    reactive,
    req,
    validate,
    need
  ],
  bs4Dash[tabItem, box],
  tictoc[tic, toc],
  dplyr[
    filter,
    summarize, n,
    pull
  ]
)

# Import shiny modules from app/view
box::use(
  app / logic / load_env[config],
  app / view / advanced_filters[filters_list_ui, filters_list_server],
  app / view / map[map_ui, map_server],
)

#' @export
ui <- function(id, tab_name) {
  ns <- NS(id)
  tabItem(
    tabName = tab_name,
    filters_list_ui(ns("selected_filters_maps")),
    box(
      width = 12,
      solidHeader = FALSE,
      collapsible = FALSE,
      map_ui(ns("map"))
    )
  )
}

#' server
#'
#' This function creates an interactive map visualization
#'
#' @param id ID string that corresponds with the ID used to call `map` and
#' `page_neighborhood_data` modules.
#' @export
server <- function(
    id,
    global_filters,
    r_equity_dimension_status) {
  moduleServer(id, function(input, output, session) {
    map_df <- reactive({
      tic("map_df")
      req(r_equity_dimension_status())

      measure_df <- r_equity_dimension_status()$get_measure_df()

      validate(
        need(
          measure_df |> summarize(n()) |> pull() > 0,
          "No data available for selected filters"
        )
      )

      incontrol_table <- r_equity_dimension_status()$get_incontrol_table(
        tolower(session$userData$advanced_settings_state$place_attribute_type)
      )

      toc()
      list(incontrol_table = incontrol_table, measure_df = measure_df)
    })

    map_server(
      id = "map",
      map_data = map_df,
      measure = reactive(global_filters$measure()),
      period = reactive(global_filters$period())
    )
    filters_list_server("selected_filters_maps")
  })
}
