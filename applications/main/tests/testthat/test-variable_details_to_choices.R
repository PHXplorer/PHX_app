box::use(
  app / logic / variable_details_to_choices[variable_details_to_choices]
)

box::use(
  testthat[...]
)


test_variable_details <- data.frame(
  category = c("Time", "Place", "Demographics", "Demographics"),
  colname = c("year", "FIPS", "Birth Year", "Death Date"),
  label = c("Year", "FIPS", "Birth Year", "Death Date")
)

describe("variable_details_to_choices", {
  it(
    "converts variable_details dataframe into list of choices where each list item is a category",
    {
      test_variable_details |>
        variable_details_to_choices() |>
        expect_equal(list(
          Demographics = c("Birth Year" = "Birth Year", "Death Date" = "Death Date"),
          Place = c("FIPS" = "FIPS"),
          Time = c("Year" = "year")
        ))
    }
  )
})
