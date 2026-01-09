box::use(
  testthat[...],
  dplyr[collect, pull, tbl],
  purrr[walk],
  app / logic / utils[...],
  app / logic / load_env[config],
  app / logic / connection[db_con]
)

describe("format_pvalues", {
  it("rounds pvalues properly", {
    expect_equal(
      format_pvalues(c(0.0011, 0.00011, 0.000011, 0.0000011)),
      c("0.0011", "2e-04", "1.1000e-05", "1.1000e-06")
    )
  })
})

describe("get_percentile_breaks", {
  it("returns a named list where each item is a variable and values are breaks", {
    result <- get_percentile_breaks(c("variable", "variable2"), c("Tertiles", "50 - 50"))
    expect_equal(names(result), c("variable", "variable2"))
    expect_equal(result$variable, unlist(config$categorization$numeric_breaks$Tertiles$values))
    expect_equal(result$variable2, unlist(config$categorization$numeric_breaks$`50 - 50`$values))
  })
  it("returns an empty list if category is NULL", {
    expect_equal(get_percentile_breaks(c("variable"), NULL), list())
  })
})

describe("get_percentile_prefix", {
  it("returns the prefix of the given percentile values", {
    numeric_breaks <- config$categorization$numeric_breaks
    walk(numeric_breaks, \(x) {
      percentile_values <- unlist(x$values)
      expect_equal(get_percentile_prefix(percentile_values), x$prefix)
    })
  })
})

describe("get_percentile_group_index", {
  it("returns the index of a percentile", {
    get_percentile_group_index(c(0, 0.33, 0.66, 1)) |>
      expect_equal(c("1", "2", "3"))

    get_percentile_group_index(list(percentiles = c(0, 0.33, 0.66, 1))) |>
      expect_equal(c("1", "2", "3"))
  })
})

describe("nrows_db", {
  it("returns the number of rows of a table", {
    tbl_fix <- data.frame(a = 1:10)
    expect_equal(nrows_db(tbl_fix), 10)
  })
  it("returns the number of rows of a lazy table", {
    con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
    tbl_lazy_fix <- data.frame(a = 1:10)
    DBI::dbWriteTable(con, "tbl_lazy_fix", tbl_lazy_fix)
    tbl_lazy <- dplyr::tbl(con, "tbl_lazy_fix")
    expect_equal(nrows_db(tbl_lazy), 10)
  })
})

describe("safe_vector_to_json", {
  it("returns an empty character vector if vec is NULL", {
    expect_equal(safe_vector_to_json(NULL), character(0))
  })
  it("returns the input vec if it is NOT NULL", {
    expect_equal(safe_vector_to_json(c("a", "b")), c("a", "b"))
  })
})

describe("get_app_name", {
  it("returns the app name based on the APP_ID environment variable", {
    withr::with_envvar(list("APP_ID" = "test_app"), {
      expect_equal(get_app_name(), "H2E Equity Dashboard (test_app)")
    })
  })
  it("uses production as default app name", {
    withr::with_envvar(list("APP_ID" = NULL), {
      expect_equal(get_app_name(), "H2E Equity Dashboard (prod)")
    })
  })
})

describe("replace_na", {
  table_fix <- data.frame(text = c("a", NA, "", "b"), num = c(1, 2, NA, ""))
  DBI::dbWriteTable(db_con, "replace_na_table_fix", table_fix)
  table_fix <- tbl(db_con, "replace_na_table_fix")

  it("replaces NAs and empty strings with replace_with", {
    expect_equal(
      replace_na(table_fix, "text", "replace_na_affected") |>
        collect() |>
        pull(text),
      c("a", "replace_na_affected", "replace_na_affected", "b")
    )
  })

  it("does nothing if cols_to_replace is NULL", {
    expect_equal(
      replace_na(table_fix, NULL, "replace_na_affected") |>
        collect() |>
        pull(text),
      c("a", NA, "", "b")
    )
  })

  it("replaces NAs with the replace_with even if the cols_to_replace is numeric col", {
    result <- replace_na(table_fix, "num", "replace_na_affected") |>
      collect() |>
      pull(num)
    expect_true(is.character(result))
    expect_true(all(result[c(3, 4)] == rep("replace_na_affected", 2)))
  })
  DBI::dbRemoveTable(db_con, "replace_na_table_fix")
})
