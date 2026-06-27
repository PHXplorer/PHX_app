box::use(
  testthat[...],
)

box::use(
  app / logic / get_filter_options[
    get_filter_options,
    get_filter_options_raw,
    prepare_filter_options_sql,
  ],
  app / logic / connection[db_con],
  app / logic / redis[redis_client],
)

redis_client$flush()

details_fix <- data.frame(
  value_type = c("text", "text", "num"),
  original_colname = c("c5_ED_nat-COI_2015", "Sex", "Year"),
  colname = c("c5_ed_nat_coi_2015", "sex", "year"),
  table = c("fips_data", "demo_attributes", "demo_attributes")
)

describe("prepare_filter_options_sql", {
  test_that("creates a character sql query", {
    sql <- prepare_filter_options_sql(details_fix, db_con)
    expect_type(sql, "character")
  })

  test_that("sql query contains all and only required features", {
    sql <- prepare_filter_options_sql(details_fix, db_con)
    expect_match(sql, "c5_ed_nat.+sex")
  })

  test_that("features from fips_data have composite name", {
    sql <- prepare_filter_options_sql(details_fix, db_con)
    expect_match(sql, "c5_ed_nat_coi_2015")
  })
})

describe("get_filter_options_raw", {
  test_that("returns a named list", {
    options <- get_filter_options_raw(details_fix, db_con)
    expect_type(options, "list")
    expect_named(options)
  })

  test_that("each element in the list has a unique character vector value", {
    options <- get_filter_options_raw(details_fix, db_con)
    lapply(options, function(x) {
      expect_equal(length(x), length(unique(x)))
      expect_type(x, "character")
    })
  })
})

describe("get_filter_options", {
  test_that("returns same thing as get_filter_options_raw", {
    raw <- get_filter_options_raw(details_fix, db_con)
    cache <- get_filter_options(details_fix, db_con)
    expect_identical(raw, cache)
  })
})
