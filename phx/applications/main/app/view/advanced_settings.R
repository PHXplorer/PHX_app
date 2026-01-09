box::use(
  bs4Dash[actionButton],
  purrr[map, walk],
  shiny[
    getDefaultReactiveDomain,
    modalDialog,
    modalButton,
    moduleServer,
    NS,
    observeEvent,
    icon,
    reactiveValues,
    removeModal,
    showModal,
    tags,
  ],
  shinyWidgets[radioGroupButtons],
  stats[setNames],
)

box::use(app / logic / load_env[config])

#' This function sets the `settings` reactive values according to the `new_settings`
#' @param settings A reactiveValues object
#' @param new_settings A list where each item is a setting with a value
#' @return Nothing
set_settings <- function(settings, new_settings, session = getDefaultReactiveDomain()) {
  walk(names(new_settings), function(setting_id) {
    settings[[setting_id]] <- new_settings[[setting_id]]
  })
  session$userData$advanced_settings_state <- settings
}

#' @export
ui <- function(id) {
  ns <- NS(id)
  actionButton(
    ns("btn"),
    label = NULL,
    icon = icon("cog", lib = "glyphicon"),
    `data-cy` = "advanced-settings-button"
  )
}

#' @export
server <- function(id, default_settings = config$global_filters$default_settings) {
  moduleServer(id, function(input, output, session) {
    # Initialize with the default settings
    settings <- reactiveValues()
    set_settings(settings, default_settings)

    observeEvent(input$btn, {
      showModal(
        modalDialog(
          class = "advanced-settings-modal",
          fade = FALSE,
          size = "l",
          title = tags$div(
            "Advanced Settings",
            tags$div(class = "close", modalButton(icon = icon("times"), label = ""))
          ),
          footer = NULL,
          easyClose = TRUE,
          tags$div(
            class = "advanced-settings-inputs",
            radioGroupButtons(
              inputId = session$ns("place_attribute_type"),
              label = "Spatial Analysis Format",
              choices = c("FIPS", "ZIP5"),
              selected = settings$place_attribute_type,
              justified = TRUE
            )
          ),
          tags$div(
            class = "bmc-dimension-input-footer", # apply the same styles as the dimension input
            actionButton(
              inputId = session$ns("reset"),
              label = "Reset"
            ),
            actionButton(
              inputId = session$ns("apply"),
              label = "Apply Settings",
              status = "primary"
            )
          )
        )
      )
    })

    observeEvent(input$reset, {
      set_settings(settings, default_settings)
      removeModal()
    })

    observeEvent(input$apply, {
      new_settings <- names(default_settings) |>
        map(\(setting_id) input[[setting_id]]) |>
        setNames(names(default_settings))
      set_settings(settings, new_settings)
      removeModal()
    })
  })
}
