box::use(
  testthat[...],
  shiny[reactiveVal, testServer]
)

box::use(
  app / view / optimized_pickerInput
)

describe("optimized_pickerInput", {
  it("Only updates the returned value when the input is not open", {
    testServer(optimized_pickerInput$server, {
      session$setInputs(pickerInput = "a")
      returned_reactive <- session$getReturned()
      expect_equal(returned_reactive(), "a")

      # Open the input
      session$setInputs(pickerInput_open = TRUE)
      session$setInputs(pickerInput = c("a", "b", "c"))
      returned_reactive <- session$getReturned()
      expect_equal(returned_reactive(), "a")

      # Close the input
      session$setInputs(pickerInput_open = FALSE)
      returned_reactive <- session$getReturned()
      expect_equal(returned_reactive(), c("a", "b", "c"))
    })
  })
})
