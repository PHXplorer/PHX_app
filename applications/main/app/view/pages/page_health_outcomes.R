box::use(
  shiny[
    NS,
    tabPanel,
    moduleServer
  ],
  bs4Dash[box],
  bs4Dash[
    tabItem,
    tabsetPanel
  ]
)

# Import shiny modules from app/view
box::use(
  app / view / incontrol_plot[incontrol_plot_ui, incontrol_plot_server],
  app / view / incontrol_table[incontrol_table_ui, incontrol_table_server],
  app / view / advanced_filters[filters_list_ui, filters_list_server],
)

#' ui
#'
#' This function creates a tabset layout for the plot and data table.
#'
#' @param id ID string that corresponds with the ID used to call
#' `incontrol_plot`, `incontrol_table`, `advanced_filters` and `page_health_outcomes` modules.
#' @param tab_name A string value for the tabset item name.
#' @export
ui <- function(id, tab_name) {
  ns <- NS(id)
  tabItem(
    tabName = tab_name,
    filters_list_ui(ns("selected_filters_health_outcomes")),
    tabsetPanel(
      id = ns("time_tabs"),
      tabPanel(
        title = "Plot",
        box(
          incontrol_plot_ui(ns("plot")),
          width = 12
        )
      ),
      tabPanel(
        title = "Table",
        box(
          incontrol_table_ui(ns("incontrol_rate")),
          width = 12
        )
      )
    )
  )
}

#' server
#'
#' This function invokes the `incontrol_plot`, `incontrol_table`, and `advanced_filters` modules to
#' create the Health Outcomes page.
#'
#' @param id ID string that corresponds with the ID used to call
#' `incontrol_plot`, `incontrol_table`, `advanced_filters` and `page_health_outcomes` modules.
#' @param selected_dims A reactive value returning a character vector of selected dimensions
#' to group patients by. If empty, a single line plot for all
#' patients is generated.
#' @param status_by_year A reactive value returning a data frame that contains
#' columns: 'year', 'incontrol' and ,if selected, dimensions.
#' @export
server <- function(
    id,
    selected_dims,
    status_by_year,
    measure,
    cache_key) {
  moduleServer(
    id,
    function(input, output, session) {
      filters_list_server("selected_filters_health_outcomes")
      incontrol_plot_server(
        id = "plot",
        selected_dims = selected_dims,
        status_by_year = status_by_year,
        measure = measure,
        cache_key = cache_key
      )

      incontrol_table_server(
        id = "incontrol_rate",
        selected_dims = selected_dims,
        status_by_year = status_by_year,
        cache_key = cache_key
      )
    }
  )
}
