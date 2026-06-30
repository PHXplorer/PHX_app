box::use(
  app / view / pages / page_advanced_analytics / module_factory,
)

box::use(. / modules)

machiner_learning <- module_factory$factory(modules, "machine_learning")

#' @export
ui <- machiner_learning$ui

#' @export
server <- machiner_learning$server
