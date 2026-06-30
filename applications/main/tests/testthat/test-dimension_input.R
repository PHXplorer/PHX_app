box::use(
  testthat[...],
  shiny[testServer],
  app / view / input / dimension_input,
)

describe("dimension_input server", {
  test_that(
    "is initialized with 'empty' selected value",
    testServer(dimension_input$server, args = list(id = "test", title = "Test"), {
      expect_equal(
        selected_value(),
        list(variable = character(), category = NULL, value = NULL)
      )
    })
  )

  test_that(
    "can be initialized with initial variable and/or category",
    testServer(
      dimension_input$server,
      args = list(
        id = "test",
        title = "Test",
        initial_variable = "temp",
        initial_category = "category",
        initial_filter_value = "Q1"
      ),
      {
        expect_equal(
          selected_value(),
          list(variable = "temp", category = "category", value = "Q1")
        )
      }
    )
  )

  test_that(
    "handles single selection",
    testServer(dimension_input$server, args = list(id = "test", title = "Test"), {
      session$flushReact()
      session$setInputs(selected = list(variable = "temp", category = "category"))
      expect_equal(
        selected_value(),
        list(variable = "temp", category = "category", value = NULL)
      )
    })
  )

  test_that(
    "handles multiple selection",
    testServer(dimension_input$server, args = list(id = "test", title = "Test"), {
      session$flushReact()
      session$setInputs(
        selected = '{"variable": ["temp1", "temp2"], "category": [null, "category"]}'
      )
      expect_equal(
        selected_value(),
        list(variable = c("temp1", "temp2"), category = c(NA, "category"), value = c(NULL, NULL))
      )
    })
  )

  test_that(
    "handles variable deselection",
    testServer(dimension_input$server, args = list(id = "test", title = "Test"), {
      session$flushReact()
      session$setInputs(selected = list(variable = "temp1", category = NULL))
      session$setInputs(selected = list(variable = "hello", category = "world"))
      session$setInputs(selected = list(variable = NULL))
      expect_equal(
        selected_value(),
        list(variable = NULL, category = NULL)
      )
    })
  )

  test_that(
    "handles reset",
    skip("Functionality is delivered with JS, cannot be tested with testServer")
  )
})
