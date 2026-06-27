box::use(
  testthat[...],
)

box::use(
  app / logic / feature_importance[
    get_feature_importance,
    plot_feature_importance,
    get_modelling_data,
  ],
  app / logic / DataLoader[data_loader],
)

equity_with_filters <- data_loader$equity_dimensions_tbl |>
  dplyr::filter(health_dimension == "BMI")

describe("get_feature_importance", {
  data <- subset(datasets::mtcars, select = -am)

  it("throws error when target is not a factor", {
    target_fail_factor <- mtcars[["am"]]
    expect_error(get_feature_importance(target_fail_factor, data))
  })

  it("throws error when target length and data row length mismatch", {
    target_fail_length <- mtcars[["am"]][1:31]
    expect_error(get_feature_importance(target_fail_length, data))
  })

  it("provides variable importance data when target and data is correct", {
    target_pass <- mtcars[["am"]] |> as.factor()
    variable_importance_output <- get_feature_importance(target_pass, data)
    expect_true(is.data.frame(variable_importance_output))
    expect_true(ncol(variable_importance_output) > 0)
  })
})

describe("plot_feature_importance", {
  it("throws error when data does not have required fields", {
    expect_error(plot_feature_importance(datasets::mtcars))
  })
})

describe("get_modelling_data", {
  it("takes in a lazy tbl and returns a list with specific names", {
    result <- get_modelling_data(equity_with_filters, 100, "complete")
    expect_type(result, "list")
    expect_named(result, c("target", "predictors", "missing"))
    expect_type(result$target, "integer")
    expect_s3_class(result$predictors, "tbl_df")
    expect_type(result$missing, "character")
  })

  it("returns complete fips data for modelling", {
    result <- get_modelling_data(equity_with_filters, 100, "complete", remove_missing = FALSE)
    expect_identical(levels(result$target), c("0", "1"))
    expect_contains(names(result$predictors), c("sex", "race", "bh_01", "spl_svm_eji_2022"))
  })

  it("returns complete zip5 data for modelling", {
    result <- get_modelling_data(
      equity_with_filters = equity_with_filters,
      sample_size = 100,
      mode = "complete",
      remove_missing = FALSE,
      place_attribute_type = "ZIP5"
    )
    expect_identical(levels(result$target), c("0", "1"))
    expect_contains(names(result$predictors), c("sex", "race", "bh_01", "pop_zc_coi_zip5_2020"))
  })

  it("throws when mode is subset, but included variables is not provided", {
    expect_error(get_modelling_data(equity_with_filters, 100, "subset"))
  })

  it("returns subset data for modelling", {
    variables <- c("age_group", "race", "bh_01", "spl_svm_eji_2022")
    result <- get_modelling_data(
      equity_with_filters = equity_with_filters,
      sample_size = 100,
      mode = "subset",
      remove_missing = FALSE,
      included_variables = variables
    )
    expect_named(result$predictors, variables)
  })
})
