box::use(
  htmltools[tags],
)

#' @export
use_react_bootstrap <- function() {
  tags$script(
    src = "https://unpkg.com/react-bootstrap@1.6.8/dist/react-bootstrap.min.js",
    crossorigin = ""
  )
}
