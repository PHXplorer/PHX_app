box::use(
  shiny[textInput, actionButton, icon, div],
)

#' @export
input_with_button <- function(text_id, btn_id) {
  div(
    class = "input-with-button",
    textInput(
      inputId = text_id,
      label = NULL,
      placeholder = "Search..."
    ),
    actionButton(
      inputId = btn_id,
      label = NULL,
      icon = icon("search")
    )
  )
}
