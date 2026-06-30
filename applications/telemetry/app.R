library(DT)
library(plotly)
library(semantic.dashboard)
library(shiny.telemetry)
library(shinyjs)
library(timevis)

db_path <- "/application/telemetry.txt"

# path is the same as in Shiny Apps for consistency
data_storage <- shiny.telemetry::DataStorageLogFile$new(log_file_path = db_path)

analytics_app(data_storage = data_storage)
