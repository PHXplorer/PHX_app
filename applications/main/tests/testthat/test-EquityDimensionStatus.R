box::use(
  app / logic / EquityDimensionStatus[EquityDimensionStatus],
  app / logic / DataLoader[DataLoader],
  app / logic / connection[db_con],
  app / logic / load_env[config],
)

box::use(
  checkmate[expect_class],
  testthat[...],
  dplyr[...],
  purrr[walk],
)

describe("equity_dimension_status", {
  data_loader_fixture <- DataLoader$new(db_con)

  describe("initialize", {
    it("filters the active_lookback_patients based on advanced_filters_state", {
      result <- EquityDimensionStatus$new(
        data_loader_fixture,
        list(selected = list(age_group = "70 to 85 years old"))
      )
      result$set_global_filters(
        "bh_01",
        c(0, 9999),
        list(
          dimensions = "age_group"
        )
      )
      result$get_incontrol_table() |>
        distinct(age_group) |>
        pull() |>
        as.character() |>
        expect_equal("70 to 85 years old")

      trythy_sum_without_filters <- EquityDimensionStatus$new(
        data_loader_fixture
      )$set_global_filters(
        "bh_01",
        c(0, 9999)
      )$get_incontrol_table() |>
        pull(truthy) |>
        sum()

      expect_equal(trythy_sum_without_filters, 21)

      # Filter a numerical column, for example, spl_svm_eji_2022
      truthy_sum_filtered <- EquityDimensionStatus$new(
        data_loader_fixture,
        list(
          selected = list(spl_svm_eji_2022 = "Q1"),
          percentile_breaks = list(spl_svm_eji_2022 = c(0, 0.25, 0.5, 0.75, 1))
        )
      )$set_global_filters(
        "bh_01",
        c(0, 9999)
      )$get_incontrol_table() |>
        pull(truthy) |>
        sum()

      expect_gt(trythy_sum_without_filters, truthy_sum_filtered)
      expect_equal(truthy_sum_filtered, 4)

      # Filter both age_group and spl_svm_eji_2022
      EquityDimensionStatus$new(
        data_loader_fixture,
        list(
          selected = list(age_group = "40 to 55 years old", spl_svm_eji_2022 = "Q1"),
          percentile_breaks = list(spl_svm_eji_2022 = c(0, 0.25, 0.5, 0.75, 1))
        )
      )$set_global_filters(
        "bh_01",
        c(0, 9999),
        list(
          dimensions = c("age_group")
        )
      )$get_incontrol_table() |>
        pull(truthy) |>
        sum() |>
        expect_equal(2)
    })
  })


  public_methods_fixture <- EquityDimensionStatus$new(data_loader_fixture, list()) # nolint

  describe("set_global_filters", {
    it("sets measure_df to active_lookback_patients joined by selected measure in the period", {
      # Arrange
      public_methods_fixture$set_global_filters(
        "ptype_09",
        c(2019, 2021)
      )

      # Assert
      public_methods_fixture$get_measure_df() |>
        distinct(featureid) |>
        filter(!is.null(featureid)) |>
        pull() |>
        expect_equal(c("PTYPE_09"))

      # Assert
      public_methods_fixture$get_measure_df() |>
        summarise(max_year = max(year), min_year = min(year)) |>
        collect() |>
        expect_equal(
          tibble(
            max_year = 2021,
            min_year = 2019
          )
        )
    })
    it("replaces NULL values with falsy value if the measure is prevalence", {
      public_methods_fixture$set_global_filters(
        "bh_01",
        c(0, 9999)
      )

      public_methods_fixture$get_measure_df() |>
        distinct(status) |>
        pull() |>
        sort() |>
        expect_equal(c(0, 1))
    })
    it("sets is_global_filters_set to TRUE", {
      unset_fixture <- EquityDimensionStatus$new(data_loader_fixture, list())
      unset_fixture$get_measure_df() |>
        expect_error("set_global_filters")
      unset_fixture$set_global_filters(
        "bh_01",
        c(0, 9999)
      )
      unset_fixture$get_measure_df() |>
        expect_class("tbl_lazy")
    })
    it("returns self which points to the adress of the instance in memory", {
      result <- public_methods_fixture$set_global_filters(
        "bh_01",
        c(0, 9999)
      )
      expect_identical(result, public_methods_fixture)
      expect_true(identical(result, public_methods_fixture, extptr.as.ref = TRUE))
    })
  })

  describe("get_incontrol_table", {
    public_methods_fixture$set_global_filters(
      "bh_01",
      c(0, 9999),
      list(
        dimensions = c("age_group", "race", "sex")
      )
    )
    result <- public_methods_fixture$get_incontrol_table("year")
    it("returns incontrol table grouped by the `by` argument + selected_dims + status", {
      colnames(result) |>
        expect_equal(c(
          "year",
          "age_group",
          "race",
          "sex",
          "truthy",
          "falsy",
          "not_measured",
          "excluded",
          "denominator",
          "all_observations",
          "incontrol",
          "missing_rate"
        ))
    })
    it("filters groups that dont have any observations", {
      result |>
        filter(all_observations == 0 & denominator == 0) |>
        nrow() |>
        expect_equal(0)
    })
    it("contains columns from `config$global_filters$health_dimension$status_dict` and incontrol, denominator, all_observations and missing rate", { # nolint
      result_checks <- result |>
        mutate(
          denominator_check = denominator == (truthy + falsy),
          incontrol_check = round(incontrol, 2) == round(truthy / denominator, 2),
          all_observations_check = all_observations == (denominator + not_measured),
          missing_rate_check = missing_rate == (not_measured / all_observations)
        )
      c("denominator_check", "incontrol_check", "all_observations_check", "missing_rate_check") |>
        walk(\(x) expect_true(all(result_checks[[x]])))
    })
    it("only returns rows that has more denominator than minimum_sample_size", {
      public_methods_fixture$get_incontrol_table("year", minimum_sample_size = 11) |>
        pull(denominator) >= 11 |>
        all() |>
        expect_true()
    })
  })
})
