box::use(
  testthat[...]
)

box::use(
  app / logic / ColnameDetails[ColnameDetails]
)

describe("ColnameDetails", {
  data_loader_fix <- list(
    variable_label_map = data.frame(
      colname = c("test_col1", "test_col2"),
      label = c("test_label1", "test_label2")
    ),
    variable_details = data.frame(
      colname = c("test_col1", "test_col2"),
      description = c("test_description1", "test_description2"),
      reverse = c(0, 1)
    )
  )
  colname_details_fix <- ColnameDetails$new(data_loader_fix)

  it("gets a variable's label from variable_label_map", {
    expect_equal(colname_details_fix$get_variable_label("test_col1"), "test_label1")
  })

  it("gets a variable's description from variable_details", {
    expect_equal(colname_details_fix$get_variable_description("test_col2"), "test_description2")
  })

  it("checks if a variable is reverse from variable_details", {
    expect_false(colname_details_fix$is_variable_reverse("test_col1"))
    expect_true(colname_details_fix$is_variable_reverse("test_col2"))
  })
})
