box::use(
  app / view / pages / page_advanced_analytics / module_factory,
)

box::use(. / modules)

exploratory_analysis <- module_factory$factory(modules, "exploratory_analysis")

#' @export
ui <- exploratory_analysis$ui

#' @export
server <- exploratory_analysis$server
