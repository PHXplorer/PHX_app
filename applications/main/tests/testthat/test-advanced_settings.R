box::use(
  purrr[partial],
  shiny[...],
  testthat[...],
)

box::use(
  app / view / advanced_settings
)

describe("advanced_settings$server", {
  advanced_settings_tester <- partial(
    testServer,
    app = advanced_settings$server,
    args = list(default_settings = list(test_setting = "default value"))
  )
  it("initially returns default settings", {
    advanced_settings_tester({
      expect_true(is.reactivevalues(session$userData$advanced_settings_state))
      expect_equal(
        reactiveValuesToList(session$userData$advanced_settings_state),
        list(test_setting = "default value")
      )
    })
  })
  it("returns new settings only when input$apply is updated", {
    advanced_settings_tester({
      session$setInputs(test_setting = "new value")
      expect_equal(
        reactiveValuesToList(session$userData$advanced_settings_state),
        list(test_setting = "default value")
      )
      session$setInputs(apply = 1)
      expect_equal(
        reactiveValuesToList(session$userData$advanced_settings_state),
        list(test_setting = "new value")
      )
    })
  })
  it("resets changed settings to the default_settings when input$reset is updated", {
    advanced_settings_tester({
      session$setInputs(test_setting = "new value")
      session$setInputs(apply = 1)
      session$setInputs(reset = 1)
      expect_equal(
        reactiveValuesToList(session$userData$advanced_settings_state),
        list(test_setting = "default value")
      )
    })
  })
})
