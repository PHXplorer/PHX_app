box::use(
  testthat[...],
  app / logic / connection_utils[...],
)

describe("load_test_data", {
  it("loads data from files", {
    expect_type(load_test_data(), "list")
  })

  it("outputs list with certain names", {
    output <- load_test_data()
    expect_named(output, c(
      "demo_attributes",
      "health_dimensions",
      "feature_details",
      "fips_data",
      "zip5_data"
    ))
  })

  it("outputs a list of data.frames", {
    output <- load_test_data()
    for (table in output) {
      expect_s3_class(table, "data.frame")
    }
  })

  it("contains only non-empty data.frames", {
    output <- load_test_data()
    for (table in output) {
      expect_gt(nrow(table), 0)
    }
  })
})

describe("upload_test_data", {
  it("uploads tables to the database", {
    con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
    datalist <- list("test_table" = data.frame(a = 1:3, b = c("a", "b", "c")))
    upload_test_data(con, datalist)
    tables <- DBI::dbListTables(con)
    DBI::dbDisconnect(con)
    expect_equal(tables, names(datalist))
  })

  it("does not overwrite existing tables", {
    con <- DBI::dbConnect(RSQLite::SQLite(), ":memory:")
    datalist <- list(test_table = data.frame(a = 1:3, b = c("a", "b", "c")))

    # 1st attempt
    upload_test_data(con, datalist)

    # 2nd attempt
    upload_test_data(con, list(test_table = data.frame(c = 4:6, d = c("d", "e", "f"))))

    table_from_db <- DBI::dbReadTable(con, "test_table")
    DBI::dbDisconnect(con)
    expect_equal(table_from_db, datalist$test_table)
  })
})
