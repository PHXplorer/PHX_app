box::use(
  shiny[
    NS, tagList, moduleServer, plotOutput, renderPlot, reactive, bindCache, tags, conditionalPanel,
    checkboxInput, req, validate, need, uiOutput, renderUI, bindEvent, observe,
    reactiveVal, observeEvent, updateCheckboxInput,
  ],
  checkmate[assert_class, assert_flag, assert_function, assert_string, assert_subset],
  dplyr[
    pull, distinct, group_by, summarize, rename, mutate, across, all_of, filter, select, collect,
    coalesce, n, arrange, left_join
  ],
  dbplyr[dbplyr_pivot_wider_spec],
  tictoc[tic, toc],
  biscale[bi_class],
  scales[label_percent],
  gridExtra[grid.arrange],
  utils[head],
  sf[st_transform],
  stats[as.formula, setNames, na.omit],
  stringr[str_extract, str_to_title, str_replace_all],
  tibble[tibble],
  leaflet[
    addLegend,
    addMapPane,
    addPolygons,
    addProviderTiles,
    colorFactor,
    colorNumeric,
    highlightOptions,
    labelOptions,
    labelFormat,
    leaflet,
    leafletOutput,
    leafletOptions,
    leafletProxy,
    pathOptions,
    renderLeaflet,
    setMaxBounds,
    setView,
  ],
  leaflet.extras2[addSidebyside],
  glue[glue],
  purrr[map, partial],
  htmltools[HTML],
  htmlwidgets[onRender, JS],
  jsonlite[toJSON],
  tidyr[separate_wider_delim],
  rlang[sym],
)

box::use(
  app / logic / get_variables_from_colnames[get_variables_from_colnames],
  app / logic / utils[bmc_spinner],
  app / logic / ColnameDetails[colname_details],
  app / logic / load_env[config],
  app / logic / variable_details_to_choices[variable_details_to_choices],
  app / logic / join_variables[join_variables],
  app / logic / DataLoader[data_loader],
  app / logic / pivot_wider_specs[count_distinct_by_status_spec],
  app / logic / relevel_factors[relevel_vector],
  app / view / input / dimension_input,
  app / logic / constants[PLACE_ATTRIBUTE_FIPS, PLACE_ATTRIBUTE_ZIP5],
)

BISCALE_DIMS <- config$geo$bivariate_dims
equity_dimension_colors <- c(config$colors$dark_teal_color, config$colors$light_teal_color)
attribute_colors <- c(config$colors$dark_purple_color, config$colors$light_purple_color)

equity_dimension_pal <- colorNumeric(
  palette = equity_dimension_colors,
  domain = NULL,
  na.color = "#ffffff"
)

numeric_attribute_pal <- partial(
  colorNumeric,
  palette = attribute_colors,
  domain = NULL,
  na.color = "#ffffff"
)

factor_attribute_pal <- partial(
  colorFactor,
  palette = attribute_colors,
  domain = NULL,
  na.color = "#ffffff"
)

#' Get a bivariate color palette
#' @param attribute_reverse A logical flag indicating whether the attribute should be reversed
#'
#' When the attribute is reversed, the x axis colors will be darker as you move from left to right.
#'
#' @return A list containing the color palette, domain, and color factor
get_biscale_pal <- function(attribute_reverse) {
  assert_flag(attribute_reverse)
  dims <- BISCALE_DIMS
  # `bi_pal_pull` is a private function in the biscale package
  # that pulls colors based on the number of dims
  # https://github.com/chris-prener/biscale/blob/4457dd13392a89a66d93050b28f9c7907e78f63f/R/bi_pal.R#L113 # nolint
  colors <- biscale:::bi_pal_pull("GrPink2", dims, FALSE, FALSE)
  domain <- names(colors)
  palette_domain <- tibble(domain = domain, palette = colors) |>
    separate_wider_delim(domain, delim = "-", names = c("col", "row"))

  if (!attribute_reverse) {
    palette_domain <- palette_domain |>
      mutate(col = (dims + 1) - as.numeric(col))
  }

  palette_domain <- palette_domain |>
    mutate(domain = paste(row, col, sep = "-")) |>
    arrange(domain)

  list(
    pal_colors = palette_domain$palette,
    pal_domain = palette_domain$domain,
    pal = colorFactor(
      palette = palette_domain$palette,
      domain = palette_domain$domain,
      na.color = "#ffffff00"
    )
  )
}

#' Creates a JavaScript onrender callback function for a Leaflet map.
#'
#' This function generates a JavaScript onrender callback function
#' that can be used with a Leaflet map. The callback function sets
#' the measure and comparison values in the session storage and
#' invoke a special function `initializeLeafletMap` that creates
#' bivariate legend and adds it as a Leaflet Control to the map.
#'
#' @param measure_label The label for the measure
#' @param comparison_label The label for the comparison
#' @param colors A vector of colors for the bivariate map
#' @param groups A vector of groups (domain) values corresponding to the colors
#'
#' @return A JavaScript onrender callback function.
make_js_onrender_callback <- function(
    measure_label,
    comparison_label,
    colors,
    groups) {
  js_text <- glue(
    "function(el, x) {
      window.sessionStorage.setItem('measure', '{{measure_label}}');
      window.sessionStorage.setItem('comparison', '{{comparison_label}}');
      window.BivariateLegend ??= {};
      window.BivariateLegend.colors = {{toJSON(colors)}}
      window.BivariateLegend.groups = {{toJSON(groups)}}
      window.initializeLeafletMap(el.id, this);
    }",
    .open = "{{",
    .close = "}}"
  )

  JS(js_text)
}

#' Function to create bivariate labels
#'
#' This function takes in data, numeric comparison flag, measure label, and comparison label
#' and creates bivariate labels for each data point.
#'
#' @param data The input data frame
#' @param title The title for the hovertext (glue string)
#' @param numeric_comparison A logical flag indicating whether the comparison is numeric or not
#' @param measure_label The label for the measure
#' @param comparison_label The label for the comparison
#'
#' @return A character vector of bivariate labels
make_bivariate_labels <- function(
    data,
    title,
    numeric_comparison,
    measure_label,
    comparison_label) {
  assert_flag(numeric_comparison)
  comparison_var_label_col <- ifelse(numeric_comparison, "comparison_var", "comparison_var_text")
  data |>
    mutate(
      labels = paste0(
        glue(title),
        glue("{measure_label}: {percent_formatter(incontrol)}<br>"),
        glue(paste0("{comparison_label}: {", comparison_var_label_col, "}<br>")),
        glue("Group: {bi_class}")
      )
    ) |>
    pull(labels) |>
    map(HTML)
}

make_biscale_classification <- function(data) {
  data |>
    # We do this in order to make low incontrol values darker on the map
    mutate(uncontrol = -incontrol) |>
    bi_class(
      x = uncontrol,
      y = comparison_var,
      style = "fisher",
      dim = BISCALE_DIMS
    )
}

percent_formatter <- label_percent(accuracy = 0.01)

#' Generate labels for the leaflet polygons
#'
#' @param sf_df A data frame with geometrical data
#' @param title The title for the hovertext (glue string)
#' @param label_for The variable to check if it's NA
#' @param glue_string A string to use inside the glue function for generating the label. The glue
#' function will be called inside the mutate statement for the `sf_df`
#' @param na_string A string to use if the variable is NA
#'
#' @return A list of HTML labels
polygon_labels <- function(sf_df, title, label_for, glue_string, na_string = "No data available") {
  sf_df |>
    mutate(
      labels = paste0(
        glue(title),
        ifelse(is.na({{ label_for }}), na_string, glue(glue_string))
      )
    ) |>
    pull(labels) |>
    map(HTML)
}

#' Add a mapPane, providerTiles, polygons, and a legend to a leaflet map
#'
#' @param leaflet A leaflet object
#' @param variable The variable to use for the fill color (string)
#' @param layer_id The layer ID for the tiles (string)
#' @param pal The color palette to use for the fill color
#' @param polygon_labels The labels to use for the polygons. Typically list of HTML generated by
#' `polygon_labels`
#' @param legend_title The title for the legend
#' @param position The position of the map pane. Either "left" or "right"
#'
#' @return A leaflet object with the polygons and legend added
add_polygon_map <- function(
    leaflet,
    variable,
    layer_id,
    pal,
    polygon_labels,
    legend_title,
    position = c("left", "right")) {
  assert_class(leaflet, "leaflet")
  assert_string(variable)
  assert_string(layer_id)
  assert_function(pal)
  assert_string(legend_title)
  match.arg(position)

  legend_values <- attributes(leaflet$x)$leafletData[[variable]] |>
    na.omit()
  unique_legend_values <- unique(legend_values)
  if (is.numeric(unique_legend_values) && length(unique_legend_values) == 1) {
    pal <- colorFactor(
      palette = switch(variable,
        incontrol = equity_dimension_colors,
        attribute_colors
      ),
      domain = NULL,
      na.color = "#ffffff"
    )
  }
  label_formatter <- switch(variable,
    incontrol = labelFormat(
      transform = \(x) x * 100,
      suffix = "%"
    ),
    labelFormat()
  )

  leaflet |>
    addMapPane(position, zIndex = 0) |>
    addProviderTiles(
      config$geo$provider_tile,
      layerId = layer_id,
      options = pathOptions(pane = position),
      group = paste0(layer_id, "_tile")
    ) |>
    addPolygons(
      options = pathOptions(pane = position),
      group = paste0(layer_id, "_polygons"),
      fillColor = as.formula(glue("~ pal({variable})")),
      weight = 1,
      opacity = 1,
      color = config$geo$polygon_border_color,
      dashArray = "3",
      fillOpacity = as.formula(glue("~ ifelse(is.na({variable}), 0, 0.7)")),
      highlightOptions = ~ highlightOptions(
        weight = 5,
        stroke = TRUE,
        bringToFront = TRUE
      ),
      label = polygon_labels,
      labelOptions = labelOptions(
        textsize = "14px",
        direction = "auto"
      )
    ) |>
    addLegend(
      layerId = layer_id,
      group = paste0(layer_id, "_legend"),
      pal = pal,
      values = legend_values,
      opacity = 0.7,
      title = legend_title,
      position = paste0("bottom", position),
      labFormat = label_formatter
    )
}

#' Add a bivariate map to a leaflet object
#'
#' On the surface, this is just a single choropleth map with a special color palette. However, the
#' legend added via `make_js_onrender_callback` is what makes this special.
#'
#' @param leaflet A leaflet object
#' @param data A data frame with geometrical data and `bi_class` column
#' @param labels A list of HTML labels for the polygons.
#' Typically generated by `make_bivariate_labels`
#' @param pal The color palette to use for the fill color. Typically generated by `get_biscale_pal`
#'
#' @return A leaflet object with the bivariate map added
add_bivariate_map <- function(leaflet, data, labels, pal) {
  assert_class(leaflet, "leaflet")
  assert_subset("bi_class", colnames(data))
  assert_function(pal)

  leaflet |>
    addProviderTiles(config$geo$provider_tile) |>
    addPolygons(
      group = data$bi_class,
      fillColor = ~ pal(bi_class),
      weight = 1,
      opacity = 1,
      color = config$geo$polygon_border_color,
      dashArray = "3",
      fillOpacity = 0.7,
      highlightOptions = ~ highlightOptions(
        weight = 5,
        stroke = TRUE,
        bringToFront = TRUE
      ),
      label = labels,
      labelOptions = labelOptions(
        textsize = "14px",
        direction = "auto"
      )
    )
}

#' @export
map_ui <- function(id) {
  ns <- NS(id)
  tagList(
    tags$div(
      class = "sentence-filter-container",
      "Compare with",
      dimension_input$ui(ns("compare_with")),
      tags$span(
        class = "optional-tag",
        "Optional"
      )
    ),
    tags$div(
      class = "leaflet-map-container",
      leafletOutput(ns("map_plot"), height = "70vh") |> bmc_spinner()
    ),
    conditionalPanel(
      ns = NS(paste(id, "compare_with", sep = "-")),
      condition = "!!input.selected?.variable",
      tags$div(
        class = "bivariate-checkbox-container",
        checkboxInput(ns("bivariate"), "Bivariate")
      )
    )
  )
}

#' @export
map_server <- function(id, map_data, measure, period) {
  moduleServer(
    id,
    function(input, output, session) {
      shape_file <- reactive(
        switch(session$userData$advanced_settings_state$place_attribute_type,
          # we import explicitly because importing tigris is expensive
          FIPS = tigris::tracts(
            state = config$geo$state,
            county = config$geo$county,
            cb = TRUE
          ),
          ZIP5 = tigris::zctas(
            cb = FALSE,
            state = config$geo$state,
            starts_with = config$geo$zip5_starts_with,
            year = 2010
          )
        )
      )

      join_by <- reactive(
        switch(session$userData$advanced_settings_state$place_attribute_type,
          FIPS = c("GEOID" = "fips"),
          ZIP5 = c("ZCTA5CE10" = "zip5")
        )
      )

      hovertext_title <- reactive(
        switch(session$userData$advanced_settings_state$place_attribute_type,
          FIPS = "<strong>{NAMELSAD}, {NAMELSADCO}, {STUSPS}</strong><br>",
          ZIP5 = "<strong>Zip5: {ZCTA5CE10}</strong><br>"
        )
      )

      compare_with <- dimension_input$server(
        id = "compare_with",
        title = "Comparison Variable",
        initial_variable = "",
        feature_type_subset = c(PLACE_ATTRIBUTE_FIPS, PLACE_ATTRIBUTE_ZIP5),
        no_categorization = TRUE
      )
      comparison_selected <- reactive(compare_with()$variable != "")
      reverse_comparison <- reactive({
        req(comparison_selected())
        colname_details$is_variable_reverse(compare_with()$variable)
      })


      observeEvent(comparison_selected(), {
        if (!comparison_selected()) {
          updateCheckboxInput(inputId = "bivariate", value = FALSE)
        }
      })

      numeric_comparison <- reactive({
        req(comparison_selected())
        data_loader$variable_details |>
          filter(colname == compare_with()$variable) |>
          pull(value_type) == "num"
      })

      equity_description <- reactive({
        colname_details$get_variable_description(measure())
      })

      spatial_data <- reactive({
        tic("incontrol_map_server-spatial_data")
        # NOTE: need to load `sf` so that geometrical data is processed correctly,
        # but also don't want to load sf at startup :)
        loadNamespace("sf")
        incontrol_table <- map_data()$incontrol_table
        measure_df <- map_data()$measure_df
        join_by <- join_by()
        joined <- shape_file() |>
          left_join(incontrol_table, by = join_by)
        if (comparison_selected()) {
          comparison_var_df <- measure_df |>
            join_variables(compare_with()$variable) |>
            rename(all_of(c(comparison_var = compare_with()$variable)))
          if (numeric_comparison()) {
            comparison_var_df <- comparison_var_df |>
              filter(!is.na(comparison_var)) |>
              group_by(
                across(!!tolower(session$userData$advanced_settings_state$place_attribute_type))
              ) |>
              summarize(comparison_var = mean(as.numeric(comparison_var), na.rm = TRUE))
          } else {
            comparison_var_df <- comparison_var_df |>
              distinct(
                !!sym(tolower(session$userData$advanced_settings_state$place_attribute_type)),
                comparison_var
              )
          }
          joined <- joined |>
            left_join(collect(comparison_var_df), by = join_by)
          if (!numeric_comparison()) {
            joined <- joined |>
              mutate(
                comparison_var = relevel_vector(comparison_var)
              )
          }
        }
        # SF warns about the projection unless we do this
        joined <- joined |>
          st_transform("+proj=longlat +datum=WGS84")
        if (input$bivariate) {
          validate(
            need(
              length(unique(na.omit(joined$comparison_var))) >= BISCALE_DIMS,
              "Not enough unique values in comparison variable to create bivariate map."
            ),
            need(
              length(unique(na.omit(joined$incontrol))) >= BISCALE_DIMS,
              "Not enough unique values in equity dimension to create bivariate map."
            )
          )
          if (!numeric_comparison()) {
            joined <- joined |>
              mutate(
                comparison_var_text = as.character(comparison_var),
                comparison_var = as.numeric(comparison_var)
              )
          }
          joined <- make_biscale_classification(joined)
        }
        toc()
        joined
      })

      output$map_plot <- renderLeaflet({
        map_data <- spatial_data()
        equtiy_dimension_labels <- map_data |>
          polygon_labels(
            hovertext_title(),
            incontrol,
            "{percent_formatter(incontrol)} ({truthy}/{denominator})"
          )

        measure_label <- colname_details$get_variable_label(measure())
        if (comparison_selected()) {
          comparison_label <- colname_details$get_variable_label(compare_with()$variable)
        }

        map <- map_data |>
          leaflet(options = leafletOptions(minZoom = config$geo$min_zoom)) |>
          setView(config$geo$view_long, config$geo$view_lat, zoom = config$geo$view_zoom) |>
          setMaxBounds(
            config$geo$view_long - config$geo$max_bound_interval,
            config$geo$view_lat - config$geo$max_bound_interval,
            config$geo$view_long + config$geo$max_bound_interval,
            config$geo$view_lat + config$geo$max_bound_interval
          )

        if (input$bivariate) {
          biscale_pal <- get_biscale_pal(reverse_comparison())
          map <- add_bivariate_map(
            leaflet = map,
            data = map_data,
            labels = make_bivariate_labels(
              data = map_data,
              title = hovertext_title(),
              numeric_comparison = numeric_comparison(),
              measure_label = measure_label,
              comparison_label = comparison_label
            ),
            pal = biscale_pal$pal
          ) |>
            onRender(
              make_js_onrender_callback(
                measure_label,
                comparison_label,
                biscale_pal$pal_colors,
                biscale_pal$pal_domain
              )
            )
          return(map)
        }

        map <- map |>
          add_polygon_map(
            variable = "incontrol",
            layer_id = "health_dimension",
            pal = equity_dimension_pal,
            polygon_labels = equtiy_dimension_labels,
            legend_title = paste("% of", equity_description()),
            position = "left"
          )

        if (comparison_selected()) {
          attribute_labels <- map_data |>
            polygon_labels(hovertext_title(), comparison_var, "{comparison_var}")
          pal_fun <- if (numeric_comparison()) numeric_attribute_pal else factor_attribute_pal
          attribute_pal <- pal_fun(reverse = reverse_comparison())
          map <- map |>
            add_polygon_map(
              variable = "comparison_var",
              layer_id = "attribute",
              pal = attribute_pal,
              polygon_labels = attribute_labels,
              legend_title = colname_details$get_variable_label(compare_with()$variable),
              position = "right"
            ) |>
            addSidebyside(
              layerId = "sidecontrols",
              rightId = "attribute",
              leftId = "health_dimension"
            )
        }
        return(map)
      }) |>
        bindCache(
          input$bivariate,
          compare_with()$variable,
          measure(),
          period(),
          session$userData$advanced_filters_state()$selected,
          session$userData$advanced_settings_state$place_attribute_type
        )
    }
  )
}
