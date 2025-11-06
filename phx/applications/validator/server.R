function(input, output, session) {
  table_preview_server("table-preview")
  table_validation_server("table-validation")
  field_validation_server("field-validation")

  onStop(function() {
    print("shiny onStop - closing stray db connection.")
    dbDisconnect(db_con, shutdown = TRUE)
  })
}
