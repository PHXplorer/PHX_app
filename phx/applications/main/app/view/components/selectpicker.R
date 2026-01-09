box::use(
  checkmate[assert_string, assert_character, assert_flag],
  htmltools[tags],
  shiny[tagAppendAttributes],
)

#' Picker input without shiny bindings and extra functionalities
#'
#' @param label String label for the selectpicker
#' @param choices Character vector of choices for the selectpicker
#' @param ... additional attributes for the select element
#' @param selected Selected choice(s)
#' @param data_variable `data-variable` attribute for the label (string)
#' @param disable Set TRUE to disable the selectpicker, FALSE to enable
#'
#' @details Notice that this function does not have an inputId argument.
#' This is because the resulting HTML element is not meant to be used with Shiny's reactive
#' programming but rather used in Javascript. This is useful if you are rendering hundreds of
#' selectpickers because Shiny's input bindings is a bottleneck.
#'
#' @export
selectpicker <- function(
    label,
    choices,
    ...,
    selected = "",
    data_variable = NULL,
    disabled = FALSE) {
  assert_character(choices, null.ok = TRUE)
  assert_character(selected, null.ok = TRUE)
  assert_flag(disabled)
  assert_string(data_variable, null.ok = TRUE)

  select <- tags$select(
    class = "selectpicker",
    ...,
    lapply(choices, function(choice) {
      option <- tags$option(choice)
      if (choice %in% selected) {
        option <- tagAppendAttributes(option, selected = "")
      }
      option
    })
  )
  if (disabled) {
    select <- tagAppendAttributes(select, disabled = "true")
  }
  element <- tags$div(
    class = "custom-selectpicker",
    tags$label(
      label,
      class = "control-label",
      `data-variable` = data_variable
    ),
    select
  )
  shinyWidgets:::attachShinyWidgetsDep(element, "picker")
}
