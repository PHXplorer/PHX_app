box::use(
  tibble[tibble],
  testthat[...],
  tidyr[pivot_wider, pivot_wider_spec, build_wider_spec]
)


box::use(
  app / logic / pivot_wider_specs
)

describe("count_distinct_by_status_spec", {
  it("pivots the data by status column where the values are the count of distinct values", {
    fixture <- tibble(
      id = 1:8,
      status = rep(c(1, 0, -1, -2), 2),
      count_distinct = 1:8
    )

    result <- fixture |>
      pivot_wider_spec(pivot_wider_specs$count_distinct_by_status_spec)
    expected <- fixture |>
      pivot_wider(names_from = status, values_from = count_distinct)
    names(expected) <- c("id", "truthy", "falsy", "not_measured", "excluded")
    expect_equal(result, expected)
  })
})

describe("names_from_featureid_spec", {
  it("pivots the featureid specified as a column", {
    fixture <- tibble(
      id = 1:6,
      featureid = rep(c("featureid1", "featureid2", "featureid3"), 2),
      value = 1:6
    )

    build_wider_spec(fixture, names_from = featureid) |>
      expect_equal(
        pivot_wider_specs$names_from_featureid_spec(c("featureid1", "featureid2", "featureid3"))
      )

    result <- fixture |>
      pivot_wider_spec(
        pivot_wider_specs$names_from_featureid_spec(c("featureid1", "featureid2", "featureid3"))
      )
    expected <- fixture |>
      pivot_wider(names_from = featureid)
    expect_equal(result, expected)
  })
})
