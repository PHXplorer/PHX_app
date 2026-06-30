box::use(
  testthat[...],
  app / logic / create_formula[create_formula]
)

test_that(
  "create_formula returns a formula object",
  {
    result <- create_formula(
      independent_vars = c("x1", "x2"),
      dependent_var = "y",
      interaction_vars = c("a", "b")
    )
    expect_s3_class(result, "formula")
  }
)

test_that(
  "create_formula creates the correct formula",
  {
    base_formula <- formula(y ~ x1 + x2)
    interacted_formula <- formula(y ~ x1 + x2 + a * b)

    base_result <- create_formula(
      independent_vars = c("x1", "x2"),
      dependent_var = "y",
      interaction_vars = NULL
    )
    expect_equal(base_formula, base_result)

    interacted_result <- create_formula(
      independent_vars = c("x1", "x2"),
      dependent_var = "y",
      interaction_vars = c("a", "b")
    )
    expect_equal(interacted_result, interacted_formula)
  }
)


test_that(
  "create_formula does not include any interaction term when interaction_vars is NULL",
  {
    independent_vars <- c("a", "b", "c")
    result <- create_formula(
      independent_vars = independent_vars,
      interaction_vars = NULL
    )

    # the right handside of the formula must only the independent vars concatanated by " + "
    character_result <- as.character(result)
    rhs <- character_result[length(character_result)]
    expect_equal(rhs, paste0(independent_vars, collapse = " + "))
  }
)

test_that(
  "create_formula generates an error when interaction_vars is not a NULL or a character vector with length == 2", # nolint
  { # nolint
    expect_error(
      create_formula(
        independent_vars = "a",
        interaction_vars = c("a", "b", "c")
      ),
      "interaction_vars"
    )
    expect_error(
      create_formula(independent_vars = "a", interaction_vars = "a"), "interaction_vars"
    )
  }
)
