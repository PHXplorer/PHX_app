box::use(
  shinytest2[...],
  testthat[...],
  tictoc[tic, toc],
)

test_that("application startup", {
  skip_if(Sys.getenv("SKIP_E2E", "true") == "true", "Skipping end-to-end tests")
  tic("application startup")
  app <- AppDriver$new(
    app_dir = getOption("box.path"),
    name = "main-app",
    width = 1920,
    height = 1080,
    load_timeout = 15 * 1000,
    timeout = 30 * 1000
  )
  toc()
  app$stop(signal_timeout = 15 * 1000)
})
