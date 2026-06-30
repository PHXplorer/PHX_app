box::use(
  shiny[
    NS, tagList, moduleServer, reactive, checkboxInput, tags, downloadButton, downloadHandler,
    textOutput, renderText, req, icon
  ],
  reactable[reactableOutput, renderReactable, reactable, colDef],
  glue[glue],
  dplyr[mutate, select, all_of, across, everything],
  openxlsx[writeDataTable, createWorkbook, saveWorkbook, addWorksheet]
)

#' @export
download_btn_ui <- function(id) {
  ns <- NS(id)
  downloadButton(
    ns("xlsx_download"),
    label = NULL,
    icon = icon("download-alt", lib = "glyphicon")
  )
}

#' @export
download_btn_server <- function(id, status_by_year) {
  moduleServer(
    id,
    function(input, output, session) {
      output$xlsx_download <- downloadHandler(
        filename = function() {
          paste("meeting_metric_table-", Sys.time(), ".xlsx", sep = "")
        },
        content = function(file) {
          data <- status_by_year()
          class(data$incontrol) <- "percentage"
          class(data$missing_rate) <- "percentage"
          wb <- createWorkbook()
          addWorksheet(wb, "data")
          writeDataTable(wb, sheet = "data", x = data)
          saveWorkbook(wb, file = file)
        }
      )
    }
  )
}
