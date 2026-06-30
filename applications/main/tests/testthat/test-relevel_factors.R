box::use(
  app / logic / relevel_factors[relevel_factors, get_numeric_levels]
)
box::use(
  testthat[...],
  dplyr[group_by, group_vars],
  withr[with_seed]
)


describe("relevel_factors", {
  ordinal_categories <- list(
    c("First", "Second", "Third", "Fourth", "Fifth"),
    c("Very High", "High", "Moderate", "Low", "Very Low"),
    c("Extremely High", "Very High", "High", "Moderate", "Low", "Very Low", "Extremely Low"),
    c("High", "Low"),
    c("High", "Medium", "Low"),
    c("Small", "Medium", "Large")
  )
  it("Sorts levels alphabetically", {
    test_data <- data.frame(
      a = c("a", "z", "Unknown", "d")
    )
    result <- test_data |> relevel_factors("a", ordinal_categories)
    result$a |>
      expect_equal(factor(
        c("a", "z", "Unknown", "d"),
        levels = c("a", "d", "z", "Unknown")
      ))
  })
  it("relevels very-high to very-low variables", {
    test_data <- data.frame(
      a = c("Moderate", "High", "Low", "Very High", "Very Low", "Unknown")
    )
    result <- test_data |> relevel_factors("a", ordinal_categories)
    result$a |>
      expect_equal(factor(
        c("Moderate", "High", "Low", "Very High", "Very Low", "Unknown"),
        levels = c("Very Low", "Low", "Moderate", "High", "Very High", "Unknown")
      ))
  })
  it("relevels very high to very low and sorts other levels alphabetically and sets Unknown as the last level", { # nolint
    test_data <- data.frame(
      a = c("Z", "Moderate", "Low", "B", "123", "High", "Very High", "Unknown", "A", "Very Low")
    )
    result <- test_data |> relevel_factors("a", ordinal_categories)
    result$a |>
      expect_equal(factor(
        c("Z", "Moderate", "Low", "B", "123", "High", "Very High", "Unknown", "A", "Very Low"),
        levels = c("Very Low", "Low", "Moderate", "High", "Very High", "123", "A", "B", "Z", "Unknown") # nolint
      ))
  })
  it("throws an error if the colnames_to_relevel is numeric", {
    test_data <- data.frame(
      a = c(1, 2, 3, 4, 5, NA)
    )
    expect_error(test_data |> relevel_factors("a"))
  })
  it("returns data back if colnames_to_relevel is NULL", {
    test_data <- data.frame(
      a = c("a", "z", NA, "d")
    )
    result <- test_data |> relevel_factors(NULL, ordinal_categories)
    result |>
      expect_equal(test_data)
  })

  it("relevels categorized numeric data based on weak matching order", {
    test_data <- data.frame(
      a = with_seed(
        45,
        sample(
          c("[0,0.25)", "(0.25,0.5]", "(0.5,0.75]", "(0.75,1]"),
          size = 24,
          replace = TRUE
        )
      )
    )
    numeric_levels <- get_numeric_levels(c(0, 0.25, 0.5, 0.75, 1))
    result <- test_data |> relevel_factors(c("a"), list(numeric_levels))
    expect_identical(
      attr(result$a, "levels"),
      c("[0,0.25)", "(0.25,0.5]", "(0.5,0.75]", "(0.75,1]")
    )
  })
})

describe("get_numeric_levels", {
  it("returns correct level permutations", {
    breaks <- c(0, 0.25, 0.5, 0.75, 1)
    expected_levels <- c(
      "[0,0.25]", "(0,0.25]", "[0,0.25)", "(0,0.25)",
      "[0.25,0.5]", "(0.25,0.5]", "[0.25,0.5)", "(0.25,0.5)",
      "[0.5,0.75]", "(0.5,0.75]", "[0.5,0.75)", "(0.5,0.75)",
      "[0.75,1]", "(0.75,1]", "[0.75,1)", "(0.75,1)"
    )

    levels <- get_numeric_levels(breaks)

    expect_equal(levels, expected_levels)
  })
})
