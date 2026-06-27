box::use(
  dplyr[mutate, across, where, rename, arrange, all_of],
  emmeans[emmeans, as.emm_list],
  ggplot2[theme, theme_minimal, element_text, ylab, scale_y_discrete],
  graphics[plot],
  plotly[renderPlotly, plotlyOutput, ggplotly],
  shiny[
    bindCache,
    bindEvent,
    column,
    div,
    fluidRow,
    htmlOutput,
    moduleServer,
    NS,
    plotOutput,
    reactive,
    renderPlot,
    renderTable,
    renderUI,
    req,
    tableOutput,
    tagList,
    tags,
  ],
  shinyWidgets[pickerInput],
  stringr[str_replace],
)

box::use(app / logic / utils[bmc_spinner])

box::use(
  app / logic / logit_convert[logit_convert],
  app / logic / get_variables_from_colnames[get_variables_from_colnames],
)

#' @export
glm_emm_ui <- function(id) {
  spinner_proxy_height <- "200px"
  ns <- NS(id)
  tagList(
    fluidRow(
      column(
        width = 6,
        plotlyOutput(ns("glm_emmeans_plot")) |>
          bmc_spinner(proxy.height = spinner_proxy_height)
      ),
      column(
        width = 6,
        div(
          class = "box-scroll",
          tableOutput(ns("glm_emmeans_table")) |>
            bmc_spinner(proxy.height = spinner_proxy_height),
          htmlOutput(ns("glm_emmeans_table_footnote")) |>
            bmc_spinner(size = 0, proxy.height = spinner_proxy_height)
        )
      )
    ),
    div(
      class = "sentence-filter-container",
      "Show EMM as",
      pickerInput(
        ns("emm_type"),
        label = "",
        choices = c(
          "logit" = "logit",
          "probabilities" = "prob",
          "odds" = "odd"
        )
      )
    )
  )
}

#' @export
glm_emm_server <- function(id, glm_reg, group, primary, recalculate, cache_key) {
  moduleServer(
    id,
    function(input, output, session) {
      glm_emmeans <- reactive({
        # to avoid reactivity without "go" pressed
        primary_value <- primary()
        group_value <- group()
        if (group_value == "") {
          emmeans(glm_reg(), primary_value, infer = c(TRUE, FALSE))
        } else {
          emmeans(
            glm_reg(),
            primary_value,
            by = group_value,
            infer = c(TRUE, FALSE)
          )
        }
      })

      glm_emmeans_scaled <- reactive({
        emm <- as.emm_list(glm_emmeans()) |>
          as.data.frame()
        for (var in c("emmean", "SE", "asymp.LCL", "asymp.UCL")) {
          emm[[var]] <- logit_convert(emm[[var]], input$emm_type)
        }
        emm
      })

      output$glm_emmeans_table <- renderTable({
        glm_emmeans_scaled() |>
          mutate(
            across(
              where(is.numeric),
              ~ round(.x, 2)
            )
          ) |>
          rename("Lower CI" = asymp.LCL, "Upper CI" = asymp.UCL) |>
          arrange(all_of(primary()))
      }) |>
        bindCache(cache_key(), input$emm_type) |>
        bindEvent(recalculate())

      output$glm_emmeans_table_footnote <- renderUI({
        req(glm_emmeans_scaled())
        scale <- input$emm_type
        if (scale == "prob") {
          scale <- "probability"
        }
        clean_attributes <- str_replace(
          attributes(glm_emmeans_scaled())$mesg,
          "(?<=on the ).*?(?= scale)", scale
        )
        tags$ul(
          clean_attributes |> lapply(tags$li)
        )
      }) |>
        bindCache(cache_key(), input$emm_type) |>
        bindEvent(recalculate())

      output$glm_emmeans_plot <- renderPlotly({
        viz <- plot(glm_emmeans_scaled()) +
          ylab(get_variables_from_colnames(primary(), names_only = TRUE)) +
          scale_y_discrete(limits = rev) +
          theme_minimal() +
          theme(
            text = element_text(size = 15),
            axis.text = element_text(size = 12),
            axis.text.y = element_text(angle = 45),
            strip.text.y = element_text(size = 12)
          )
        ggplotly(viz)
      }) |>
        bindCache(cache_key(), input$emm_type) |>
        bindEvent(recalculate())
    }
  )
}
