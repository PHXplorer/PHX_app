# Shiny entrypoint for RDebugger
shiny::devmode(TRUE)
options(shiny.autoreload = FALSE)
shiny::runApp()
