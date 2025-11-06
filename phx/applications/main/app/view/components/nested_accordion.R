box::use(
  bs4Dash[accordion, accordionItem, dashboardBadge, ionicon],
  htmltools[tags, HTML, tagAppendAttributes],
  jsonlite[toJSON],
  purrr[map_chr, partial],
  rhino[react_component],
  shiny[getDefaultReactiveDomain, tagList, tags],
  shinyWidgets[pickerInput],
  stringr[str_remove_all],
)

box::use(
  app / logic / build_feature_tree[build_feature_tree, build_feature_tree_mem, LEVEL_MISSING],
  app / logic / categorize_numeric[config_unique_categories],
  app / logic / DataLoader[data_loader],
  app / logic / load_env[config],
  app / logic / relevel_factors[relevel_vector],
  app / logic / utils[safe_vector_to_json],
  app / view / components / selectpicker[selectpicker],
  app / logic / constants[PLACE_ATTRIBUTE_FIPS, PLACE_ATTRIBUTE_ZIP5]
)

Accordion <- react_component("NestedAccordionComponent")

#' UI component with nested accordions
#'
#' @param mode {string} Mode of the component: "select" or "filter"
#' @param disabled {character} Vector with disabled variable names
#' @param feature_details {data.frame} Table with feature details data
#' @param session {Session} shiny session object
#'
#' @return {shiny.tag}
#'
#' @export
nested_accordion <- function(
    input_id,
    selected = NULL,
    selected_category = NULL,
    selected_filter_values = NULL,
    choices = data_loader$filter_options,
    mode = c("select", "filter"),
    disabled = c(),
    feature_details = data_loader$variable_details,
    feature_type_subset = NULL,
    multiple = FALSE,
    multiple_limit = 3,
    only_categorical_variables = FALSE,
    no_categorization = FALSE,
    allow_continuous = FALSE,
    use_description_as_label = FALSE,
    is_label_dynamic = TRUE,
    session = getDefaultReactiveDomain()) {
  mode <- match.arg(mode)

  feature_type_exclude <- switch(session$userData$advanced_settings_state$place_attribute_type,
    FIPS = PLACE_ATTRIBUTE_ZIP5,
    ZIP5 = PLACE_ATTRIBUTE_FIPS,
  )

  tree <- build_feature_tree_mem(
    feature_details,
    feature_type_subset = feature_type_subset,
    feature_type_exclude = feature_type_exclude,
    excluded_attributes = config$global_filters$dimensions_to_skip_in_attribute_selection_modal,
    only_categorical_variables = only_categorical_variables,
    no_categorization = no_categorization
  )

  if (mode == "filter") {
    multiple <- TRUE
    initial_variables <- safe_vector_to_json(selected)
    initial_categories <- safe_vector_to_json(selected_category)
    filter_values <- safe_vector_to_json(selected_filter_values)
  } else {
    initial_variables <- map_chr(selected, identity)
    initial_categories <- map_chr(selected_category, identity)
    filter_values <- NULL
  }

  tree_json <- toJSON(as.list(tree), auto_unbox = TRUE)

  # NOTE: map_chr + identity allows to turn NULL into character(0)
  initial_values <- toJSON(list(
    is_multiple = multiple,
    variable = initial_variables,
    category = initial_categories,
    filter_values = filter_values
  ), auto_unbox = FALSE)

  tags$div(
    id = input_id,
    class = "bmc-nested-accordion",
    `data-initial_values` = initial_values,
    `data-is-label-dynamic` = toJSON(is_label_dynamic, auto_unbox = TRUE),
    Accordion(
      inputId = input_id,
      data = tree_json,
      namespace = session$ns("selected_dim"),
      multiple = multiple,
      multipleLimit = multiple_limit,
      mode = mode,
      allowContinuous = allow_continuous,
      selectedVariables = initial_variables,
      selectedCategories = initial_categories,
      selectedFilterValues = filter_values,
      useDescriptionAsLabel = use_description_as_label
    )
  )
}
