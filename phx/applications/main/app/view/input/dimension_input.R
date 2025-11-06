box::use(
  bs4Dash[actionButton],
  glue[glue],
  jsonlite[fromJSON, toJSON],
  shiny[
    div,
    getDefaultReactiveDomain,
    icon,
    isolate,
    modalButton,
    modalDialog,
    moduleServer,
    NS,
    observeEvent,
    outputOptions,
    reactiveVal,
    removeModal,
    renderUI,
    showModal,
    uiOutput,
  ],
  purrr[map, map_chr],
)
box::use(
  app / logic / DataLoader[data_loader],
  app / logic / relevel_factors[relevel_vector],
  app / view / components / input_with_button[input_with_button],
  app / view / components / nested_accordion[nested_accordion],
)

modal_header_ui <- function(title, session = getDefaultReactiveDomain()) {
  div(
    class = "bmc-dimension-input-header",
    title,
    input_with_button(session$ns("search"), session$ns("search_go")),
    div(class = "close", modalButton(icon = icon("times"), label = ""))
  )
}

modal_footer_ui <- function(
    should_have_footer = FALSE,
    ignore_apply = FALSE,
    mode = "select",
    session = getDefaultReactiveDomain()) {
  if (!should_have_footer) {
    return(NULL)
  }

  if (mode == "select") {
    handle_apply <- paste0("App.handleMultipleDimensionSelection('", session$ns("selected"), "');")
  } else if (mode == "filter") {
    handle_apply <- paste0("App.handleFilterApply('", session$ns("selected"), "');")
  }

  if (ignore_apply) {
    handle_apply <- "window.Shiny.modal.remove();"
  }

  div(
    class = "bmc-dimension-input-footer",
    actionButton(
      inputId = session$ns("reset"),
      label = "Reset",
      `data-cy` = "dimension-input-reset-button"
    ),
    actionButton(
      inputId = session$ns("apply"),
      label = "Apply",
      status = "primary",
      onclick = handle_apply,
      `data-cy` = "dimension-input-apply-button"
    )
  )
}

modal_ui <- function(title, add_footer, ignore_apply, mode, session = getDefaultReactiveDomain()) {
  modal <- modalDialog(
    class = "bmc-dimension-input",
    fade = FALSE,
    size = "l",
    title = modal_header_ui(title),
    footer = NULL,
    easyClose = TRUE,
    uiOutput(session$ns("accordion_list")),
    modal_footer_ui(add_footer, ignore_apply, mode)
  )
}

handle_select_single <- function(set_selected_value, session = getDefaultReactiveDomain()) {
  variable <- session$input$selected$variable
  category <- session$input$selected$category
  value <- session$input$selected$value

  set_selected_value(list(
    variable = tolower(variable),
    category = category,
    value = value
  ))

  removeModal()
}

handle_select_multiple <- function(set_selected_value, session = getDefaultReactiveDomain()) {
  selected <- fromJSON(session$input$selected, simplifyVector = TRUE)

  set_selected_value(list(
    variable = tolower(selected$variable),
    category = selected$category,
    value = selected$value
  ))

  removeModal()
}

handle_apply_filter <- function(set_selected_value, session = getDefaultReactiveDomain()) {
  selected <- session$input$selected |>
    fromJSON(simplifyVector = FALSE)

  set_selected_value(list(
    variable = map_chr(selected, \(x) tolower(x$variable)),
    category = map(selected, \(x) unlist(x$category)),
    value = map(selected, \(x) unlist(x$value))
  ))

  removeModal()
}

handle_deselect <- function(set_selected_value, session = getDefaultReactiveDomain()) {
  set_selected_value(list(variable = NULL, category = NULL))

  removeModal()

  return()
}

#' Dimension input UI
#'
#' See docs/nested_accordion.md for more details
#'
#' @param id The ID of the module
#' @param initial_label The initial label of the button - could be text or html component
#' @param is_label_dynamic Controls whether JS part shuold change the label. Useful to set to TRUE
#' when the label is supposed to be a constant icon, not text. E.g. advanced filters.
#' @export
ui <- function(
    id,
    initial_label = icon(
      "plus",
      class = "dimension-input-default-icon",
      title = "Click here to add a dimension",
      `data-cy` = "dimension-input-default-icon"
    ),
    is_label_dynamic = TRUE,
    ...) {
  ns <- NS(id)
  classlist <- c()

  if (is_label_dynamic) {
    classlist <- c(classlist, "btn-dimension-input")
  }

  actionButton(
    inputId = ns("show_modal"),
    label = initial_label,
    class = classlist,
    `data-initial-label` = as.character(initial_label),
    ...
  )
}

#' Dimension input server
#'
#' See docs/nested_accordion.md for more details
#'
#' @param id The ID of the module
#' @param title The title of the modal displayed to the left of search bar
#' @inheritParams @seealso {nested_accordion}
#' @export
server <- function(id,
                   title,
                   initial_variable = NULL,
                   initial_category = NULL,
                   initial_filter_value = NULL,
                   feature_type_subset = NULL,
                   multiple = FALSE,
                   multiple_limit = 3,
                   only_categorical_variables = FALSE,
                   no_categorization = FALSE,
                   allow_continuous = FALSE,
                   is_label_dynamic = TRUE,
                   mode = "select") {
  moduleServer(id, function(input, output, session) {
    session$sendCustomMessage("bmcLabelMap", data_loader$variable_label_map)

    if (mode == "filter") {
      session$sendCustomMessage(
        "bmcChoicesMap",
        data_loader$filter_options |>
          map(\(x) {
            x |>
              relevel_vector() |>
              sort() |>
              as.character()
          }) |>
          toJSON()
      )
    }

    selected_value <- reactiveVal(list(
      variable = tolower(initial_variable),
      category = initial_category,
      value = initial_filter_value
    ))

    observeEvent(input$show_modal, ignoreInit = TRUE, {
      showModal(modal_ui(
        title = title,
        add_footer = multiple || no_categorization || mode == "filter",
        ignore_apply = no_categorization && !multiple,
        mode = mode,
        session = session
      ))
    })

    output$accordion_list <- renderUI({
      nested_accordion(
        input_id = session$ns("selected"),
        selected = selected_value()$variable,
        selected_category = selected_value()$category,
        selected_filter_values = selected_value()$value,
        mode = mode,
        multiple_limit = multiple_limit,
        feature_type_subset = feature_type_subset,
        multiple = multiple,
        only_categorical_variables = only_categorical_variables,
        no_categorization = no_categorization,
        allow_continuous = allow_continuous,
        is_label_dynamic = is_label_dynamic
      )
    })
    outputOptions(output, "accordion_list", suspendWhenHidden = FALSE)

    observeEvent(input$reset, {
      session$sendCustomMessage(
        "bmcResetAccordion",
        list(id = session$ns("selected"))
      )
    })

    observeEvent(session$userData$advanced_settings_state$place_attribute_type,
      {
        session$sendCustomMessage(
          "bmcResetAccordion",
          list(id = session$ns("selected"))
        )
        # bmcResetAccordion only resets inputs when the accordion is rendered
        # since Shiny unsubscribes the inputs when the modal is closed
        # So we need to "manually" reset the selected_value
        selected_value(
          list(
            variable = tolower(initial_variable),
            category = initial_category,
            value = initial_filter_value
          )
        )
      },
      ignoreInit = TRUE
    )

    observeEvent(input$selected, ignoreNULL = TRUE, ignoreInit = TRUE, {
      if (mode == "filter") {
        handle_apply_filter(selected_value, session)
        return()
      }

      if (is.character(input$selected)) {
        handle_select_multiple(selected_value, session)
        return()
      }

      if (is.null(input$selected$variable)) {
        handle_deselect(selected_value, session)
        return()
      }

      handle_select_single(selected_value, session)
    })

    selected_value
  })
}
