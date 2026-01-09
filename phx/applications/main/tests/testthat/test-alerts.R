box::use(
  testthat[...],
  shiny[testServer],
  app / logic / alerts[init_alerts, add_alert],
  app / logic / load_env[config]
)

sample_id <- names(config$misc$alert_list)[[1]]
msg <- "test msg"

test_that("init_alerts creates reactive object", {
  server <- function(id) {
    moduleServer(
      id,
      function(input, output, session) {
        init_alerts(session)
      }
    )
  }
  testServer(
    server,
    {
      expect_type(session$userData$alerts(), "list")
      expect_identical(session$userData$alerts(), config$misc$alert_list)
    }
  )
})

test_that("init_alerts fails when config missing or session object missing", {
  expect_error(init_alerts("test"))
  expect_error(init_alerts(NULL))
})

test_that("initialized second time keep existing object without complains", {
  server <- function(id) {
    moduleServer(
      id,
      function(input, output, session) {
        init_alerts(session)
        add_alert(session, sample_id, msg)
      }
    )
  }
  testServer(
    server,
    {
      expect_no_error(init_alerts(session))
      expect_no_warning(init_alerts(session))
    }
  )
  testServer(
    server,
    {
      init_alerts(session)
      expect_identical(session$userData$alerts()[[sample_id]], msg)
    }
  )
})

test_that("init_alerts overwrite object", {
  server <- function(id) {
    moduleServer(
      id,
      function(input, output, session) {
        init_alerts(session)
        add_alert(session, sample_id, msg)
        init_alerts(session, overwrite = TRUE)
      }
    )
  }
  testServer(
    server,
    {
      expect_type(session$userData$alerts(), "list")
      expect_identical(session$userData$alerts(), config$misc$alert_list)
    }
  )
})

test_that("add_alert create reactive when missing and adds alert", {
  server <- function(id) {
    moduleServer(
      id,
      function(input, output, session) {
        add_alert(session, sample_id, msg)
      }
    )
  }
  testServer(
    server,
    {
      expect_type(session$userData$alerts(), "list")
      expect_identical(names(session$userData$alerts()), names(config$misc$alert_list))
      expect_identical(session$userData$alerts()[[sample_id]], msg)
    }
  )
})

test_that("add_alert fails when id not in the list", {
  server <- function(id) {
    moduleServer(
      id,
      function(input, output, session) {
      }
    )
  }
  testServer(
    server,
    {
      expect_error(add_alert(session, "test", msg))
    }
  )
})

test_that("add_alert fails when session object missing", {
  expect_error(add_alert("test", sample_id, msg))
})

test_that("add_alert adds alert when condition met", {
  server <- function(id) {
    moduleServer(
      id,
      function(input, output, session) {
        add_alert(session, sample_id, msg, 1 > 0)
      }
    )
  }
  testServer(
    server,
    {
      expect_identical(session$userData$alerts()[[sample_id]], msg)
    }
  )
})

test_that("add_alert doesn't add alert when condition not met", {
  server <- function(id) {
    moduleServer(
      id,
      function(input, output, session) {
        add_alert(session, sample_id, msg, 1 > 2)
      }
    )
  }
  testServer(
    server,
    {
      expect_identical(session$userData$alerts()[[sample_id]], FALSE)
    }
  )
})
