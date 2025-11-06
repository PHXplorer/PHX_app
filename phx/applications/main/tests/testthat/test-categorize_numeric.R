box::use(
  DBI[...],
  dplyr[...],
  purrr[map_chr],
  testthat[...],
  dbplyr[sql_render],
  stringr[str_count],
)

box::use(
  app / logic / DataLoader[data_loader],
  app / logic / categorize_numeric[
    categorize_numeric,
    config_unique_categories_fun
  ]
)

table_fixture <- data_loader$get_lazy_table("demo_attributes") |>
  left_join(data_loader$get_lazy_table("health_dimensions")) |>
  left_join({
    data_loader$get_lazy_table("fips_data") |>
      select(fips, spl_svm_eji_2022, spl_svm_dom1_eji_2022, spl_svm_dom2_eji_2022)
  }) |>
  compute()

# Arrange
describe("categorize_numeric", {
  it("returns the original table back if there are no columns to transform", {
    result <- categorize_numeric(table_fixture)
    expect_equal(result, table_fixture)

    result <- categorize_numeric(table_fixture, percentile_columns = list(), average_columns = NULL)
    expect_equal(result, table_fixture)
  })
  it("always returns a lazy table", {
    # Act
    result <- categorize_numeric(table_fixture)

    # Assert
    expect_true("tbl_lazy" %in% class(result))

    # Act
    result <- categorize_numeric(
      table_fixture,
      percentile_columns = list(spl_svm_eji_2022 = c(0, 0.25, 0.5, 0.75, 1)),
      average_columns = NULL
    )
    # Assert
    expect_true("tbl_lazy" %in% class(result))
  })

  it("cuts percentile_columns list by percentiles given", {
    percentiles <- c(0, 0.25, 0.5, 0.75, 1)
    # Act
    result <- categorize_numeric(
      table_fixture,
      percentile_columns = list(
        spl_svm_eji_2022 = percentiles,
        spl_svm_dom1_eji_2022 = percentiles,
        spl_svm_dom2_eji_2022 = percentiles
      )
    )

    result |>
      pull(spl_svm_eji_2022) |>
      as.factor() |>
      levels() |>
      sort() |>
      expect_equal(c(
        "Q1 [2.75,5.73]",
        "Q2 [6.92,7.73]",
        "Q3 [8.96,9.02]",
        "Q4 [9.16,9.5]"
      ))

    result |>
      pull(spl_svm_dom1_eji_2022) |>
      as.factor() |>
      levels() |>
      sort() |>
      expect_equal(c(
        "Q1 [0,0.06]",
        "Q2 [0.27,0.65]",
        "Q3 [0.67,0.81]",
        "Q4 [0.93,0.96]"
      ))

    result |>
      pull(spl_svm_dom2_eji_2022) |>
      as.factor() |>
      levels() |>
      sort() |>
      expect_equal(c(
        "Q1 [1.54,2.22]",
        "Q2 [3.82,4.54]",
        "Q3 [4.77,5.1]",
        "Q4 [5.28,5.42]"
      ))
  })
})

describe("config_unique_categories", {
  it("returns unique categories resulting from applying categorize_numeric using config breaks", {
    config_fixture <- list(
      categorization = list(
        numeric_breaks = list(
          `50 - 50` = list(prefix = "H", values = list(0, 0.5, 1)),
          Tertiles = list(prefix = "T", values = list(0, 0.33, 0.66, 1)),
          Quartiles = list(prefix = "Q", values = list(0, 0.25, 0.5, 0.7, 1))
        )
      )
    )
    config_unique_categories_fun(config_fixture) |>
      purrr::map(as.character) |>
      expect_equal(
        list(
          `50 - 50` = c("H1", "H2"),
          Tertiles = c("T1", "T2", "T3"),
          Quartiles = c("Q1", "Q2", "Q3", "Q4")
        )
      )
  })
})
