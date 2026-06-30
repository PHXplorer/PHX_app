box::use(
  testthat[...],
  DBI[dbConnect, dbWriteTable, dbDisconnect],
  dplyr[...]
)
box::use(
  app / logic / join_variables[join_variables],
)

describe("join_variables", {
  # Arrange
  sqlite_con <- DBI::dbConnect(
    drv = RSQLite::SQLite(),
    dbdir = ":memory:"
  )
  health_dimensions <- data.frame(
    person_id = c(1, 2, 3, 4),
    fips = c(1001, 1002, 1003, 1004),
    year = c(2020, 2021, 2022, 2022),
    featureid = c("CVR_04", "CVR_03", "BH_03", "CVR_04"),
    value = c("Diabetes", "Cancer", "Depression", "Diabetes")
  )
  fips_data <- data.frame(
    fips = c(1001, 1002, 1003),
    coi = c("Low", "High", "Unknown"),
    svi = c(0.1, 0.2, 0.3)
  )
  demo_attributes <- data.frame(
    person_id = c(1, 2, 3),
    fips = c(1001, 1002, 1003),
    year = c(2020, 2021, 2022),
    age = c(20, 30, 40),
    sex = c("M", "F", "M")
  )
  dbWriteTable(sqlite_con, "health_dimensions", health_dimensions)
  dbWriteTable(sqlite_con, "demo_attributes", demo_attributes)
  dbWriteTable(sqlite_con, "fips_data", fips_data)

  health_dimensions <- tbl(sqlite_con, "health_dimensions")

  tbl_list_fixture <- list(
    health_dimensions = tbl(sqlite_con, "health_dimensions"),
    demo_attributes = tbl(sqlite_con, "demo_attributes"),
    fips_data = tbl(sqlite_con, "fips_data")
  )

  variable_details_fixture <- data.frame(
    colname = c("coi", "svi", "age", "sex", "cvr_04", "bh_03"),
    label = c(
      "Child Opportunity Index", "Social Vulnerability Index", "Age", "Sex",
      "Diabetes", "Depression"
    ),
    table = c(
      "fips_data", "fips_data", "demo_attributes",
      "demo_attributes", "health_dimensions", "health_dimensions"
    )
  )

  data_loader_fixture <- list(
    variable_details = variable_details_fixture,
    tbl_list = tbl_list_fixture,
    prevelance_equity_dimensions = c("bh_03")
  )

  it("only joins the colnames_to_join", {
    # Act
    result <- join_variables(
      base_table = health_dimensions,
      colnames_to_join = c("coi"),
      data_loader = data_loader_fixture
    ) |>
      collect()

    # Assert
    expect_equal(
      sort(colnames(result)),
      sort(c("person_id", "fips", "year", "featureid", "value", "coi"))
    )
  })

  it("pivots the health_dimensions table before joining and only joins the relevant health dimensions", { # nolint
    # Act
    result <- join_variables(
      base_table = health_dimensions,
      colnames_to_join = c("cvr_04"),
      data_loader = data_loader_fixture
    ) |>
      collect()

    # Assert
    expect_equal(
      sort(colnames(result)),
      sort(c("person_id", "fips", "year", "featureid", "value", "cvr_04"))
    )
  })

  it("can join colnames from different tables", {
    # Act
    result <- join_variables(
      base_table = health_dimensions,
      colnames_to_join = c("coi", "sex", "bh_03"),
      data_loader = data_loader_fixture
    ) |>
      collect()

    # Assert
    expect_equal(
      sort(colnames(result)),
      sort(c("person_id", "fips", "year", "featureid", "value", "coi", "sex", "bh_03"))
    )
  })

  it("performs a left_join to base_table", {
    # Act
    result <- join_variables(
      base_table = health_dimensions,
      colnames_to_join = c("coi"),
      data_loader = data_loader_fixture
    ) |>
      collect()
    expect_equal(result$coi, c("Low", "High", "Unknown", NA))
  })

  it("returns base_table if colnames_to_join is NULL", {
    # Act
    result <- join_variables(
      base_table = health_dimensions,
      colnames_to_join = NULL,
      data_loader = data_loader_fixture
    )

    # Assert
    expect_equal(result, health_dimensions)
  })

  it("only joins colnames that are not in the base_table", {
    # Arrange
    first_join <- join_variables(
      base_table = health_dimensions,
      colnames_to_join = c("coi", "svi", "age"),
      data_loader = data_loader_fixture
    )

    # Act
    result <- join_variables(
      base_table = first_join,
      colnames_to_join = c("coi", "svi", "age", "sex"),
      data_loader = data_loader_fixture
    )

    # Assert
    expect_equal(
      sort(colnames(result)),
      sort(c("person_id", "fips", "year", "featureid", "value", "age", "coi", "svi", "sex"))
    )
  })

  it("replaces NULL values with 'No + Label' when joining prevalence dimension", {
    join_variables(
      base_table = health_dimensions |>
        mutate(is_active = "TRUE"),
      colnames_to_join = "bh_03",
      data_loader = data_loader_fixture
    ) |>
      pull(bh_03) |>
      expect_equal(c("No Depression", "No Depression", "Depression", "No Depression"))
  })

  dbDisconnect(sqlite_con)
})
