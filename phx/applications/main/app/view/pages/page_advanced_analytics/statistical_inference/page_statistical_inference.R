box::use(
  app / view / pages / page_advanced_analytics / module_factory,
)

box::use(. / modules)

statistical_inference <- module_factory$factory(modules, "statistical_inference")

#' @export
ui <- statistical_inference$ui

#' @export
server <- statistical_inference$server
