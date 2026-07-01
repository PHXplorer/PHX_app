box::use(
  testthat[...],
  shiny[testServer, reactive]
)
withr::local_dir(test_path("../../"))

box::use(
  app / view / global_filters,
)

test_that("global_filters_server returns the correct values", {
  skip("Functionality is delivered with JS and other modules")
})


test_that("global_filters_server plus buttons dont affect selected dimensions", {
  testServer(global_filters$server,
             args = list(
               current_tab = reactive("main")
             ),
             {
    session$setInputs(
      minus_button = 0,
      plus_button = 3
    )
    expect_equal(length(unlist(selected_dims())), 0)
  })
})
