box::use(
  bs4Dash[addPopover, ionicon, removePopover],
  checkmate[assert, assert_data_frame, assert_string],
  dplyr[filter, pull],
  shiny[actionLink, is.reactive, moduleServer, NS, observeEvent, req],
)

box::use(
  app / logic / DataLoader[data_loader]
)

#' @export
ui <- function(id) {
  ns <- NS(id)
  actionLink(inputId = ns("info_icon"), label = ionicon("information-circle-outline"))
}

#' Add a popover to the UI that displays information about a variable
#' @param id The module id
#' @param info_for A reactive expression that returns either the colname or featureid of a variable
#' @param ... Additional options to pass to `addPopover`
#' @param variable_details A dataframe structured as data_loader$variable_details
#'
#' This server function will observe the `info_for` and change the content of the popover
#' according to the value returned from this reactive.
#'
#' @export
server <- function(id, info_for, ..., variable_details = data_loader$variable_details) {
  assert(is.reactive(info_for))
  assert(!any(names(list(...)) %in% c("content", "trigger")))
  assert_data_frame(variable_details)

  moduleServer(id, function(input, output, session) {
    observeEvent(info_for(), {
      req(info_for())
      assert_string(info_for())
      removePopover(id = "info_icon", session = session)
      info <- variable_details |>
        # attributes match to colname,
        # equity dimensions match to featureid.
        # TODO: this should be standardized, gh issue: #124
        filter(colname == info_for() | featureid == info_for())
      addPopover(
        session = session,
        id = "info_icon",
        options = list(
          content = shiny::HTML(info$info_content),
          trigger = "click",
          placement = "bottom",
          html = TRUE
        )
      )
    })
  })
}
