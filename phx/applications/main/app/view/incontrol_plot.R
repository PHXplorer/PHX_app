box::use(
  app / logic / DataLoader[data_loader],
  app / logic / load_env[config],
  app / logic / utils[bmc_spinner],
  app / logic / ColnameDetails[colname_details],
  app / logic / get_variables_from_colnames[get_variables_from_colnames],
  app / logic / constants[UNKNOWN_VALUE],
)

# do not move this line below the plotly[config] import.
chart_colors <- config$colors$chart_colors

box::use(
  shiny[NS, tagList, moduleServer, reactive, bindCache],
  plotly[add_trace, plotlyOutput, renderPlotly, plot_ly, layout, config],
  dplyr[ungroup, all_of, cur_column, select, mutate, filter, sym],
  tidyr[unite],
  tictoc[tic, toc],
  forcats[fct_cross],
  purrr[partial],
  rlang[syms],
  scales[percent],
  stats[setNames]
)

set_plotly_config <- partial(
  config,
  displaylogo = FALSE,
  modeBarButtonsToRemove = c("select2d", "lasso2d")
)

hovertemplate <- function(
    year,
    incontrol,
    truthy,
    denominator,
    selected_dims_hovertemplate = NULL) {
  paste(
    year,
    paste0(percent(incontrol, accuracy = 0.01), "% ", "(", truthy, "/", denominator, ")"),
    selected_dims_hovertemplate,
    "<extra></extra>", # to remove the secondary tooltip
    sep = "<br>"
  )
}

#' @export
incontrol_plot_ui <- function(id) {
  ns <- NS(id)
  plotlyOutput(ns("plot"), height = "70vh") |> bmc_spinner()
}

#' incontrol_plot_server
#'
#' This function generates an interactive scatter plot using the plotly package
#' to visualize the proportion of patients meeting a certain metric over years.
#' The patients can be grouped by selected dimensions. If no
#' dimensions are selected, a single line plot representing all patients is displayed.
#'
#' @param id ID string that corresponds with the ID used to call `incontrol_plot_server`
#' @param selected_dims A reactive value returning a character vector of selected dimensions
#' to group patients by. If empty, a single line plot for all
#' patients is generated.
#' @param status_by_year A reactive value returning a data frame that contains
#' columns: 'year', 'incontrol' and ,if selected, dimensions.
#' @export
incontrol_plot_server <- function(
    id,
    selected_dims,
    status_by_year,
    measure,
    cache_key) {
  moduleServer(
    id,
    function(input, output, session) {
      output$plot <- renderPlotly({
        tic("incontrol_plot")
        selected_dims <- selected_dims()$dimensions
        status_by_year <- status_by_year() |>
          # for avoiding decimals on the x-axis of the plot
          mutate(year = as.character(year))
        health_outcome <- colname_details$get_variable_description(measure())
        plot_title <- paste("Percentage of", health_outcome)
        if (length(selected_dims) == 0) {
          plot <- status_by_year |>
            plot_ly(
              x = ~year,
              y = ~incontrol,
              type = "scatter",
              mode = "lines+markers",
              colors = chart_colors,
              hovertemplate = ~ hovertemplate(year, incontrol, truthy, denominator)
            ) |>
            layout(
              title = plot_title,
              xaxis = list(title = "Year"),
              yaxis = list(
                title = "",
                tickformatstops = list(
                  list(dtickrange = list(0, 0.01), value = ".1%"),
                  list(dtickrange = list(0.01, 0.1), value = ".1%"),
                  list(dtickrange = list(0.1, 1), value = ".0%")
                ),
                range = list(0, 1)
              )
            ) |>
            set_plotly_config()
          toc()
          return(plot)
        }
        selected_dims_labels <- get_variables_from_colnames(selected_dims, names_only = TRUE) |>
          setNames(selected_dims)

        plot_data <- status_by_year |>
          ungroup() |>
          mutate(
            patientgroup = fct_cross(!!!syms(selected_dims), sep = ", ")
          ) |>
          mutate(
            across(
              all_of(selected_dims),
              \(x) paste(selected_dims_labels[cur_column()], x, sep = ": "),
              .names = "{col}_hovertemplate"
            )
          ) |>
          unite(
            "selected_dims_hovertemplate",
            all_of(paste0(selected_dims, "_hovertemplate")),
            sep = "<br>"
          )

        plot_data_known <- plot_data |>
          filter(!!sym(selected_dims[1]) != UNKNOWN_VALUE)

        plot_data_unknown <- plot_data |>
          filter(!!sym(selected_dims[1]) == UNKNOWN_VALUE)

        plot <- plot_ly(
          plot_data_known,
          x = ~year, y = ~incontrol,
          color = ~patientgroup,
          type = "scatter",
          mode = "lines+markers",
          legendgroup = plot_data_known[[selected_dims[1]]],
          colors = chart_colors,
          hovertemplate = ~ hovertemplate(
            year, incontrol, truthy, denominator, selected_dims_hovertemplate
          )
        ) |>
          add_trace(
            data = plot_data_unknown,
            x = ~year,
            y = ~incontrol,
            visible = "legendonly",
            legendgroup = plot_data_unknown[[selected_dims[1]]]
          ) |>
          layout(
            title = plot_title,
            xaxis = list(title = "Year"),
            yaxis = list(
              title = "",
              tickformatstops = list(
                list(dtickrange = list(0, 0.01), value = ".1%"),
                list(dtickrange = list(0.01, 0.1), value = ".1%"),
                list(dtickrange = list(0.1, 1), value = ".0%")
              ),
              range = list(0, 1)
            ),
            legend = list(
              title = list(text = paste(selected_dims_labels, collapse = ", "))
            )
          ) |>
          set_plotly_config()
        toc()
        return(plot)
      }) |>
        bindCache(selected_dims(), cache_key())
    }
  )
}
