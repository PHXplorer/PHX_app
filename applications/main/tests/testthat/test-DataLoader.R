box::use(
  testthat[...],
  DBI[...],
  purrr[...],
  dplyr[...],
)

box::use(
  app / logic / DataLoader[DataLoader],
  app / logic / connection[db_con],
  app / logic / load_env[config]
)

describe("data_loader", {
  test_that("is an r6 class", {
    data_loader <- DataLoader$new(db_con)
    expect_s3_class(data_loader, "R6")
  })
})

describe("data_loader public methods", {
  test_that("get_lazy_table", {
    data_loader <- DataLoader$new(db_con)
    walk(data_loader$db_tables, function(x) {
      res <- data_loader$get_lazy_table(x)
      expected_class <- ifelse(x == "feature_details", "tbl", "tbl_lazy")
      expect_s3_class(res, expected_class)
    })
  })

  test_that("get_origin_colnames", {
    data_loader <- DataLoader$new(db_con)
    walk(data_loader$db_tables, function(x) {
      res <- data_loader$get_origin_colnames(x)
      expect_type(res, "character")
    })
  })
})

describe("data loader active bindings", {
  describe("equity_years", {
    test_that("returns a numeric vector", {
      data_loader <- DataLoader$new(db_con)
      equity_years <- data_loader$equity_years
      expect_true("numeric" %in% class(equity_years))
    })

    test_that("returns values from health_dimensions, sorted", {
      data_loader <- DataLoader$new(db_con)
      raw_years <- data_loader$get_lazy_table("health_dimensions") |>
        pull(year) |>
        unique() |>
        sort()
      equity_years <- data_loader$equity_years
      expect_identical(raw_years, equity_years)
    })
  })

  describe("tbl_list", {
    test_that("returns a list of lazy tables", {
      data_loader <- DataLoader$new(db_con)
      tbl_list <- data_loader$tbl_list
      expect_type(tbl_list, "list")
      walk(tbl_list, \(x) expect_s3_class(x, "tbl_lazy"))
    })

    test_that("has specific tables", {
      data_loader <- DataLoader$new(db_con)
      tbl_list <- data_loader$tbl_list
      expect_true(all(c("health_dimensions", "demo_attributes", "fips_data") %in% names(tbl_list)))
    })
  })

  describe("equity_dimensions_tbl", {
    test_that("returns a lazy table", {
      data_loader <- DataLoader$new(db_con)
      equity_dimensions_tbl <- data_loader$equity_dimensions_tbl
      expect_s3_class(equity_dimensions_tbl, "tbl_lazy")
    })

    test_that("has required columns", {
      data_loader <- DataLoader$new(db_con)
      equity_dimensions_tbl <- data_loader$equity_dimensions_tbl
      expected_colnames <- c(
        "person_id", "year", "measurement_date", "health_dimension",
        "value", "status", "value_as_number", "featureid", "fips"
      )
      expect_true(all(expected_colnames %in% colnames(equity_dimensions_tbl)))
    })
  })

  describe("equity_dimensions_details", {
    test_that("returns a table", {
      data_loader <- DataLoader$new(db_con)
      equity_dimensions_details <- data_loader$equity_dimensions_details
      expect_s3_class(equity_dimensions_details, "tbl")
    })

    test_that("has required columns", {
      data_loader <- DataLoader$new(db_con)
      equity_dimensions_details <- data_loader$equity_dimensions_details
      expected_colnames <- c(
        "displayorder", "display", "feature_type", "domainorder", "domain", "sd_order",
        "subdomain", "ssd_order", "subsubdomain", "item_order", "label", "source",
        "featureid", "description", "full_description", "value_type", "category",
        "colname", "table"
      )
      expect_true(all(expected_colnames %in% colnames(equity_dimensions_details)))
    })

    test_that("only has equity dimensions & prevelance", {
      data_loader <- DataLoader$new(db_con)
      equity_dimensions_details <- data_loader$equity_dimensions_details
      feature_types <- equity_dimensions_details |>
        distinct(feature_type) |>
        collect() |>
        pull()
      expect_identical(feature_types, c("Equity Dimension", "Prevalence Equity Dimension"))
    })
  })

  describe("variable_details", {
    test_that("returns a real data.frame", {
      data_loader <- DataLoader$new(db_con)
      variable_details <- data_loader$variable_details
      expect_s3_class(variable_details, "tbl_df")
    })

    test_that("has required columns", {
      data_loader <- DataLoader$new(db_con)
      variable_details <- data_loader$variable_details
      expected_columns <- c(
        "featureid",
        "source",
        "category",
        "colname",
        "label",
        "description",
        "full_description",
        "value_type",
        "table",
        "feature_type",
        "domain",
        "subdomain",
        "subsubdomain",
        "reverse",
        "info_content",
        "info_title",
        "reverse"
      )
      expect_true(all(expected_columns %in% colnames(variable_details)))
    })

    test_that("only has displayed variables", {
      data_loader <- DataLoader$new(db_con)
      variable_details <- data_loader$variable_details
      expected <- data_loader$get_lazy_table("feature_details") |>
        filter(display == "1") |>
        pull(featureid)
      actual <- pull(variable_details, featureid)
      expect_true(all(actual %in% expected))
    })
  })


  describe("categorical_colnames", {
    test_that("returns a character vector", {
      data_loader <- DataLoader$new(db_con)
      categorical_colnames <- data_loader$categorical_colnames
      expect_type(categorical_colnames, "character")
    })

    test_that("only has text variables", {
      data_loader <- DataLoader$new(db_con)
      actual <- data_loader$categorical_colnames
      expected <- data_loader$variable_details |>
        filter(value_type == "text") |>
        pull(colname)
      expect_true(all(actual %in% expected))
    })
  })

  test_that("variables", {
    data_loader <- DataLoader$new(db_con)
    variables <- data_loader$variables
    expect_type(variables, "list")
    walk(variables, \(x) {
      expect_type(x, "character")
      expect_named(x)
    })
  })

  test_that("categorical_variables", {
    data_loader <- DataLoader$new(db_con)
    categorical_variables <- data_loader$categorical_variables
    expect_type(categorical_variables, "list")
    walk(categorical_variables, \(x) {
      expect_type(x, "character")
      expect_named(x)
    })
  })

  test_that("filter_options", {
    data_loader <- DataLoader$new(db_con)
    filter_options <- data_loader$filter_options
    expect_type(filter_options, "list")
    walk(filter_options, \(x) expect_type(x, "character"))
  })
})
