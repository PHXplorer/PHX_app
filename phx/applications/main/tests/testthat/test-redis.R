box::use(
  shiny[...],
  testthat[...],
  logger[...],
)

box::use(
  app / logic / redis[RedisCache, CLIENT_STATUS],
)

describe("RedisCache: initialization", {
  test_that("does not throw error when redis cache is disabled", {
    # redis cache is disabled by default in tests
    client <- RedisCache$new("test")
    expect_identical(client$status, CLIENT_STATUS$DISABLED)
  })

  test_that("does not throw error when redis is not available", {
    withr::with_envvar(c(REDIS_ENABLED = "true", REDIS_HOST = "abracadabra"), {
      client <- RedisCache$new("test")
      expect_identical(client$status, CLIENT_STATUS$OFFLINE)
    })
  })
})

describe("RedisCache: public methods", {
  test_that("has methods required by Shiny for bindCache", {
    client <- RedisCache$new("test")
    expect_true(all(c("get", "set") %in% names(client)))
  })

  test_that("RedisCache$keys() returns character vector of all keys cached in the store", {
    client <- RedisCache$new("test")

    keys_before <- client$keys()
    client$set("hello", "world")
    client$set("counter", 1)

    keys_after <- client$keys()

    expect_length(keys_before, 0)
    expect_identical(
      sort(keys_after),
      sort(c("main_application__test__hello", "main_application__test__counter"))
    )
  })

  test_that("RedisCache$set() creates new key-value pair in the store", {
    client <- RedisCache$new("test")
    expect_length(client$keys(), 0)
    value <- client$set("hello", "world")
    expect_length(client$keys(), 1)
  })

  test_that("RedisCache$get() returns object of class `key_missing` when cache miss", {
    client <- RedisCache$new("test")
    value <- client$get("test")
    expect_s3_class(value, "key_missing")
  })

  test_that("RedisCache$get() returns value that was set by RedisCache$set()", {
    client <- RedisCache$new("test")
    client$set("test", 12)
    value <- client$get("test")
    expect_identical(value, 12)
  })

  test_that("RedisCache$getset() will try to retrieve a value by key, if the value is missing, it will execute provided callback, save the result in cache and return it", { # nolint
    client <- RedisCache$new("test")
    log_appender(appender_stdout)

    with_log_threshold(threshold = TRACE, {
      expect_output(client$getset("hello", function() "world"), "cache miss")
      expect_output(client$getset("hello", function() "world"), "cache hit")
    })

    log_appender(appender_console)
  })

  test_that("RedisCache$flush() deletes all key-value pairs in the store", {
    client <- RedisCache$new("test")
    client$set("hello", "world")
    client$set("counter", 1)
    expect_length(client$keys(), 2)
    client$flush()
    expect_length(client$keys(), 0)
  })
})

describe("RedisCache: cache invalidation", {
  test_that("all keys are deleted when database is modidfied", {
    client <- RedisCache$new("test")
    client$set("hello", "world")
    client$set("counter", 13)
    expect_length(client$keys(), 2)

    # Inside unit tests we use SQLite, with which cache is always invalidated
    client$validate_cache_keys()

    # one key - date of datetime of database modification
    expect_length(client$keys(), 1)
  })
})

describe("RedisCache: Shiny context", {
  test_that("caches shiny outputs", {
    client <- RedisCache$new("test")
    mock_server <- function(input, output, session) {
      output$text <- renderText(mtcars[input$row, "qsec"]) |>
        bindCache(input$row, cache = client)
    }

    testServer(mock_server, {
      expect_length(client$keys(), 0)
      session$setInputs(row = 1)
      expect_length(client$keys(), 1)
      session$setInputs(row = 2)
      expect_length(client$keys(), 2)
      session$setInputs(row = 3)
      expect_length(client$keys(), 3)
    })
  })

  test_that("does not cache when runtime error is thrown", {
    client <- RedisCache$new("test")
    mock_server <- function(input, output, session) {
      output$text <- renderText({
        stop("something went wrong")
      }) |>
        bindCache(input$row, cache = client)
    }
    testServer(mock_server, {
      expect_length(client$keys(), 0)
      session$setInputs(row = 1)
      expect_length(client$keys(), 0)
    })
  })

  test_that("does not cache when 'handled' error is thrown", {
    client <- RedisCache$new("test")
    mock_server <- function(input, output, session) {
      output$text <- renderText({
        validate(need(is.character(input$row)))
        mtcars[input$row, "qsec"]
      }) |>
        bindCache(input$row, cache = client)
    }
    testServer(mock_server, {
      expect_length(client$keys(), 0)
      session$setInputs(row = 1)
      expect_length(client$keys(), 0)
    })
  })
})
