box::use(
  car[vif],
  dplyr[mutate, filter, pull],
  forcats[fct_reorder],
  ggplot2[
    ggplot, aes, geom_segment, geom_point, geom_vline, xlab, theme_minimal, theme, element_blank,
    element_text
  ],
  glue[glue],
  plotly[renderPlotly, plotlyOutput, ggplotly],
  shiny[
    bindCache,
    bindEvent,
    moduleServer,
    need,
    NS,
    observeEvent,
    plotOutput,
    reactive,
    renderPlot,
    req,
    tagList,
    validate,
  ],
  stats[alias],
  tictoc[tic, toc],
)

box::use(
  app / logic / alerts[add_alert],
  app / logic / load_env[config],
  app / logic / utils[bmc_spinner],
  app / logic / get_variables_from_colnames[get_variables_from_colnames]
)

vif_column <- "GVIF^(1/(2*Df))"

#' @export
vif_plot_output <- function(id) {
  ns <- NS(id)
  plotlyOutput(ns("plot")) |> bmc_spinner()
}

#' @export
vif_plot_server <- function(id, glm_reg, cache_key, go) {
  moduleServer(
    id,
    function(input, output, session) {
      alert_msg <- config$strings$error_messages$vif_missing_independent_variables

      output$plot <- renderPlotly({
        tic("vif_plot_server-plot_preparation")
        alert_condition <- ncol(glm_reg()$model) > 2

        add_alert(session, "vif_not_enough_independent_variables", alert_msg, !alert_condition)

        validate(
          need(
            alert_condition,
            alert_msg
          )
        )

        glm_reg_alias <- alias(glm_reg())$Complete
        has_aliased_variable <- sum(glm_reg_alias) > 0
        # Display an informative message when the model has aliased variables
        if (has_aliased_variable) {
          alias_pairs <- as.data.frame(as.table(glm_reg_alias), responseName = "aliased") |>
            filter(aliased > 0) |>
            mutate(
              alias_pair = paste0("(", Var1, ", ", Var2, ")")
            ) |>
            pull(alias_pair)
          alias_pairs <- paste(alias_pairs, collapse = ", ")

          alert_msg <- paste0(
            config$aliased_coefficients, "\n",
            alias_pairs
          )
          alert_condition <- !has_aliased_variable
          add_alert(session, "vif_has_aliased_variable", alert_msg, !has_aliased_variable)
          validate(
            need(
              alert_condition,
              alert_msg
            )
          )
        }
        glm_vif <- vif(glm_reg())
        if (vif_column %in% colnames(glm_vif)) {
          vifs <- glm_vif[, vif_column]
        } else {
          # This occurs when the variables have no degrees of freedom
          vif_column <- "VIF"
          vifs <- glm_vif
        }

        vif_df <- data.frame(variable = names(vifs), vifs = vifs)
        # create and re-order factor levels for ggplot2
        vif_df$variable <- fct_reorder(vif_df$variable, vif_df$vifs)

        add_alert(
          session,
          "vif_exceed_threshold",
          msg = glue("Some VIFs are higher than {config$numbers$vif_threshold}."),
          condition = any(vif_df$vifs >= config$numbers$vif_threshold)
        )
        toc()
        viz <- vif_df |>
          mutate(variable = get_variables_from_colnames(variable, names_only = TRUE)) |>
          ggplot(aes(x = vifs, y = variable)) +
          geom_segment(
            aes(
              x = 0,
              xend = vifs,
              yend = variable
            ),
            size = 1.25
          ) +
          geom_point(
            color = config$colors$purple_color,
            size = 6
          ) +
          # add a vertical line for vif = 5. Vif > 5 is considered concerning
          # https://quantifyinghealth.com/vif-threshold/
          geom_vline(xintercept = config$numbers$vif_threshold, linetype = "dashed") +
          xlab(vif_column) +
          theme_minimal() +
          theme(
            axis.title.y = element_blank(),
            text = element_text(size = 18)
          )
        ggplotly(viz)
      }) |>
        bindCache(cache_key()) |>
        bindEvent(go())
    }
  )
}
