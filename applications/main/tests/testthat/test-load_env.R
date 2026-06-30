box::use(
  testthat[...],
  shiny[testServer],
  withr[local_envvar],
)

box::use(
  app / logic / load_env[set_environment, debug_info, config]
)


test_that("env var is not set properly", {
  local_envvar(list(ENVIRONMENT = "test"))
  expect_error(
    set_environment(),
    msg = "Must be a subset of {'production','development'}"
  )
  local_envvar(list(ENVIRONMENT = ""))
  expect_error(
    set_environment(),
    msg = "Must be a subset of {'production','development'}"
  )
})

test_that("returns config when env set properly", {
  local_envvar(list(ENVIRONMENT = "production"))
  value <- expect_invisible(
    set_environment()
  )
  expect_type(value, "list")
})

test_that("Config will be added to session object", {
  server <- function(id) {
    moduleServer(
      id,
      function(input, output, session) {
        set_environment(session)
      }
    )
  }
  testServer(
    server,
    {
      expect_type(session$userData$config, "list")
      expect_type(session$userData$config$rhino_log_level, "character")
    }
  )

  server <- function(id) {
    moduleServer(
      id,
      function(input, output, session) {
        set_environment()
      }
    )
  }
  testServer(
    server,
    {
      expect_equal(session$userData$config, NULL)
    }
  )
})
