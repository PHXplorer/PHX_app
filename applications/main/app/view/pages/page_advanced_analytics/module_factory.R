box::use(
  bs4Dash[bs4Card],
  htmltools[tagAppendAttributes],
  shiny[NS, moduleServer, tags, uiOutput, renderUI, req, observeEvent],
  shinyWidgets[pickerInput],
)

box::use(
  app / logic / load_env[config],
  app / logic / utils[bmc_spinner],
  app / logic / constants[AAF_ABOUT_MODULE],
  app / view / advanced_filters[filters_list_ui, filters_list_server],
)

SECTIONS <- names(config$advanced_analytics_framework$active_modules)

get_module_names <- function(box_mod) {
  namespace <- names(attr(box_mod, "namespace"))
  namespace <- namespace[!startsWith(namespace, ".")]

  labels <- unname(vapply(namespace, function(x) {
    if (!"LABEL" %in% names(box_mod[[x]])) {
      return(x)
    }
    box_mod[[x]]$LABEL
  }, character(1)))

  labels[labels == AAF_ABOUT_MODULE] <- "About"

  names(namespace) <- labels

  # Always put "About" first, let others go in alphabetical order
  c(
    namespace[namespace == AAF_ABOUT_MODULE],
    namespace[namespace != AAF_ABOUT_MODULE]
  )
}


#' @param modules Box module
#' @export
factory <- function(box_mod, section = SECTIONS) {
  section <- match.arg(section)

  exported_modules <- get_module_names(box_mod)
  modules_to_include <- config$advanced_analytics_framework$active_modules[[section]]

  if (!is.null(modules_to_include)) {
    exported_modules <- exported_modules[order(match(exported_modules, modules_to_include))]
    exported_modules <- exported_modules[exported_modules %in% modules_to_include]
  }

  ui <- function(id) {
    ns <- NS(id)

    tags$main(
      filters_list_ui(ns("active_advanced_filters")),
      bs4Card(
        width = 4,
        pickerInput(
          inputId = ns("module_select"),
          choices = exported_modules
        ) |>
          tagAppendAttributes(style = "margin-bottom: 0")
      ),
      bmc_spinner(uiOutput(ns("module_output")))
    )
  }

  server <- function(id, ...) {
    moduleServer(id, function(input, output, session) {
      filters_list_server("active_advanced_filters")

      output$module_output <- renderUI({
        mod <- input$module_select
        if (mod == "") mod <- AAF_ABOUT_MODULE
        box_mod[[mod]]$ui(
          id = session$ns(paste0("mod_", mod))
        )
      })

      observeEvent(input$module_select, {
        mod <- input$module_select
        if (mod == "") mod <- AAF_ABOUT_MODULE
        box_mod[[mod]]$server(
          id = paste0("mod_", mod),
          ...
        )
      })
    })
  }

  list(ui = ui, server = server)
}
