box::use(
  testthat[...]
)

box::use(
  app / view / components / selectpicker[selectpicker]
)

describe("selectpicker", {
  local_edition(3)
  it("returns a select element with selectpicker class and a label with `data-variable` attribute wrapped in a div with class 'custom-selectpicker'", { # nolint
    selectpicker(
      label = "test",
      choices = c("a", "b", "c"),
      selected = "b",
      data_variable = "test"
    ) |>
      expect_snapshot()
  })
  it("sets the disabled attribute in select element to 'true' when disabled is TRUE", {
    selectpicker(
      label = "test",
      choices = c("a", "b", "c"),
      selected = "b",
      data_variable = "test",
      disabled = TRUE
    ) |>
      expect_snapshot()
  })
  it("adds additional attributes to select element passed to ...", {
    selectpicker(
      label = "test",
      choices = c("a", "b", "c"),
      selected = "b",
      data_variable = "test",
      disabled = TRUE,
      `additional-attribute-test` = "test"
    ) |>
      expect_snapshot()
  })
})
