dashboardPage(
  dashboardHeader(title = "Validator"),
  dashboardSidebar(
    skin = "light",
    width = 250,
    status = "white",
    sidebarMenu(
      id = "tabs",
      menuItem("Table previews", tabName = "preview"),
      menuItem("Table validations", tabName = "data_valid"),
      menuItem("Field validations", tabName = "field_valid")
    )
  ),
  dashboardBody(
    tags$head(
      tags$link(rel = "stylesheet", type = "text/css", href = "styles.css")
    ),
    tabItems(
      table_preview_ui("table-preview"),
      table_validation_ui("table-validation"),
      field_validation_ui("field-validation")
    )
  )
)
