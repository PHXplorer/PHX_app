box::use(
  cicerone[Cicerone],
  cookies[get_cookie, set_cookie],
  glue[glue],
  rhino[log],
  shiny[moduleServer, observeEvent]
)

# setup guided tour
guides <- list(
  time = Cicerone$new()$step(
    "app-knowledge-knowledge_center",
    "Knowledge Center",
    "Find more information here, including data definitions and documentation.",
    position = "top"
  )$step(
    "app-global_filters-measure-show_modal",
    "Health outcome - click to select feature",
    "Click to select a different option.",
    position = "bottom"
  )$step(
    "app-global_filters-dim1-show_modal",
    "Select attribute",
    "Click to add variables to the display.",
    position = "bottom"
  )$step(
    "app-global_filters-show_advanced_filters-btn",
    "Advanced filtering",
    "Filter data displayed.",
    position = "left"
  )
)

#' @export
server <- function(id, tab) {
  moduleServer(
    id,
    function(input, output, session) {
      observeEvent(
        tab(),
        {
          cookie_name <- glue("skip_intro_{tab()}")
          # {cookies} does not work with mock shiny session, i.e testServer session
          # we need to use tryCatch to avoid error in tests
          skip_intro_cookie <- tryCatch(get_cookie(cookie_name), error = function(e) NULL)
          log$debug("intro loading")
          if (is.null(skip_intro_cookie)) {
            if (tab() == "time") {
              log$debug("intro loading: no cookie detected for tab {tab()},
  and no modal in analytics:  intro will be displayed")
              guides[[tab()]]$init()$start()
              tryCatch(
                set_cookie(cookie_name, "true"),
                error = function(e) log$warn("failed to set cookie")
              )
            }
          }
        }
      )
    }
  )
}
