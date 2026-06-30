box::use(
  shiny[
    actionLink,
    column,
    fluidRow,
    moduleServer,
    NS,
    observe,
    observeEvent,
    reactiveVal,
    tagList,
    tags,
  ],
  bs4Dash[tabItem, updateTabItems],
)

box::use(app / logic / load_env[config])

#' @export
ui <- function(id, tab_name) {
  ns <- NS(id)
  tabItem(
    tabName = tab_name,
    tagList(
      fluidRow(
        column(
          12,
          tags$h2("About the Population Health Explorer"),
          tags$p(
            "The health care we receive often has only a small impact on our overall health. Combining electronic health record (EHR) data with place-based data about the neighborhoods where we live, learn, and work can help us better understand the many factors that drive human health and well-being." # nolint
          ),
          tags$ul(
            tags$li(
              actionLink(
                ns("health_outcomes_link"),
                label = "Health Outcomes: explore trends in health outcomes over time by different patient populations" # nolint
              )
            ),
            tags$li(
              actionLink(
                ns("advanced_analytics_link"),
                label = "Advanced Analytics: build a multivariate logistic regression model to explore relationships between variables and outcomes" # nolint
              )
            ),
            tags$li(
              actionLink(
                ns("neighborhood_data_link"),
                label = "Neighborhood Data: visualize how health outcomes and drivers of health differ by neighborhood" # nolint
              )
            )
          ),
          tags$h3("Limitations"),
          tags$p(
            "Results from this tool are not to be used for patient care or for research purposes. To request access to this data for research purposes, please contact Bill Adams." # nolint
          ),
          tags$h3("Documentation"),
          tags$p(
            "You can find more information in",
            tags$a(
              "official documentation",
              href = config$external_links$h2e_docs,
              target = "_blank",
              .noWS = "after"
            ),
            "."
          ),
          tags$h3("Licensing and Acknowledgements"),
          tags$p(
            "Please review licensing details in the",
            tags$a(
              "licensing and acknowledgement document",
              href = config$external_links$h2e_license,
              target = "_blank",
              .noWS = "after"
            ),
            "."
          )
        )
      )
    )
  )
}

#' @export
server <- function(id, parent_session) {
  moduleServer(id, function(input, output, session) {
    selected_tab <- reactiveVal()

    observeEvent(input$health_outcomes_link, selected_tab("time"))
    observeEvent(input$advanced_analytics_link, selected_tab("analytics"))
    observeEvent(input$neighborhood_data_link, selected_tab("neighbor"))

    observe({
      updateTabItems(
        inputId = "tabs",
        selected = selected_tab(),
        session = parent_session
      )
      # reset the selected_tab to trigger observe if the same bullet point is clicked again
      selected_tab(NULL)
    })
  })
}
