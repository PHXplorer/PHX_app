box::use(
  assertthat[assert_that],
  shiny[reactiveVal, is.reactive, showNotification, removeNotification],
  rhino[log],
  purrr[imap],
)

box::use(
  app / logic / load_env[config]
)

#' @export
add_alert <- function(session, id, msg, condition = TRUE) {
  assert_that(typeof(session) == "environment")
  assert_that(typeof(id) == "character")
  if (!is.reactive(session$userData$alerts)) {
    log$warn("add_alert used without init")
    init_alerts(session)
  }
  assert_that(id %in% names(config$misc$alert_list))
  assert_that(is.logical(condition))

  alerts <- session$userData$alerts()
  if (condition) {
    log$debug("Alert added: {id}")
    alerts[id] <- msg
    showNotification(
      msg,
      type = "warning",
      session = session,
      duration = NULL,
      id = id
    )
  } else {
    log$debug("Alert skipped or removed: {id}")
    alerts[id] <- FALSE
  }

  session$userData$alerts(alerts)
  invisible(TRUE)
}

#' @export
init_alerts <- function(session, overwrite = FALSE) {
  assert_that(typeof(session) == "environment")

  # before reseting reactive value, remove all notifications
  if (overwrite) {
    imap(
      session$userData$alerts(),
      function(x, i) {
        if (!isFALSE(x)) {
          removeNotification(id = i, session = session)
        }
      }
    )
  }

  alerts <- config$misc$alert_list
  if (!is.reactive(session$userData$alerts)) {
    log$debug("Alerts initiated for the first time")
    session$userData$alerts <- reactiveVal(alerts)
  } else if (overwrite) {
    log$debug("All alerts removed")
    session$userData$alerts(alerts)
  } else {
    log$warn("Alerts already initiated")
  }
  invisible(TRUE)
}
