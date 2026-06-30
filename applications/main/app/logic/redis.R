tictoc::tic("[module] redis")
box::use(
  checkmate[assert, assert_function, assert_string, check_raw, check_null],
  dbplyr[db_collect],
  redux[hiredis, object_to_bin, bin_to_object],
  rhino[log],
)

box::use(
  app / logic / connection[db_con],
  app / logic / load_env[config],
  app / logic / sql_queries,
)

REDIS_STATUS <- list(
  ONLINE = "PONG",
  OFFLINE = "OFFLINE"
)

#' @export
CLIENT_STATUS <- list(
  ONLINE = 1,
  OFFLINE = 2,
  DISABLED = 3
)

MockRedisEngine <- R6::R6Class(
  classname = "MockRedisEngine",
  public = list(
    initialize = function() {
      private$engine <- cachem::cache_mem()
    },
    PING = function() REDIS_STATUS$OFFLINE,
    GET = function(key) private$engine$get(key),
    SET = function(key, value) private$engine$set(key, value),
    CONFIG_SET = function(key, value) NULL,
    FLUSHALL = function() private$engine$reset(),
    KEYS = function(pattern) private$engine$keys()
  ),
  private = list(
    engine = NULL
  )
)

#' Connect to Redis and create a client
#'
#' You can control whether you want to turn off the redis cache by setting the environment variable
#' `REDIS_ENABLED`. If it is set to `false`, the function will return a dummy client that will
#' always return `OFFLINE` when calling `PING()`.
#'
#' This same dummy client will also be returned if the connection to the redis server fails and
#' `REDIS_ENABLED` is not `false`.
#'
#' @return a hiredis client
#' @export
RedisCache <- R6::R6Class(
  classname = "RedisCache",
  public = list(
    status = NULL,
    initialize = function(app_id = NULL) {
      private$app_id <- app_id

      if (Sys.getenv("REDIS_ENABLED") == "false") {
        log$info("[REDIS] cache is disabled via environment variable REDIS_ENABLED=false")
        private$client <- MockRedisEngine$new()
        self$status <- CLIENT_STATUS$DISABLED
        return(self)
      }

      redis_client <- tryCatch(
        expr = {
          hiredis(
            host = Sys.getenv("REDIS_HOST"),
            port = Sys.getenv("REDIS_PORT")
          )
        },
        error = function(e) MockRedisEngine$new()
      )

      if (redis_client$PING() == REDIS_STATUS$OFFLINE) {
        log$info("[REDIS] did not connect to redis instance")
        private$client <- redis_client
        self$status <- CLIENT_STATUS$OFFLINE
        return(self)
      }

      private$client <- redis_client
      self$status <- CLIENT_STATUS$ONLINE

      self$validate_cache_keys()

      # Apply memory policy configuration settings
      private$client$CONFIG_SET(
        "maxmemory",
        Sys.getenv("REDIS_MAXMEMORY", "100mb")
      )
      private$client$CONFIG_SET(
        "maxmemory-policy",
        Sys.getenv("REDIS_MAXMEMORY_POLICY", "allkeys-lru")
      )
    },

    #' special method used by shiny::bindCache
    get = function(key) {
      key <- private$add_namespace(key)
      serialized_value <- private$client$GET(key)
      if (is.null(serialized_value) || inherits(serialized_value, "key_missing")) {
        log$info("[REDIS] {key} - cache miss")
        structure(list(), class = "key_missing")
      } else {
        log$info("[REDIS] {key} - cache hit")
        unserialize(serialized_value, NULL)
      }
    },

    #' special method used by shiny::bindCache
    set = function(key, value) {
      if ("error" %in% names(value) && isTRUE(value$error)) {
        log$info("[REDIS] {key} - not caching error")
        return()
      }
      key <- private$add_namespace(key)
      serialized_value <- serialize(value, NULL)
      private$client$SET(key, serialized_value)
    },

    #' our own method used in DataLoader
    getset = function(key, on_miss) {
      assert_string(key)
      assert_function(on_miss, args = character(0))

      value_in_cache <- self$get(key)
      cache_hit <- !inherits(value_in_cache, "key_missing")

      if (cache_hit) {
        return(value_in_cache)
      }

      object <- on_miss()
      self$set(key, object)
      object
    },

    #' remove all key-value pairs from the cache
    flush = function() {
      private$client$FLUSHALL()
    },

    #' get list of all keys in the cache
    keys = function() {
      private$client$KEYS("*")
    },

    #' check if cached keys should be invalidated
    validate_cache_keys = function() {
      last_update_key <- "database_last_update"
      last_update_query <- sql_queries[[config$data$database$db_driver]]$last_update

      actual_db_last_update <- db_collect(con = db_con, sql = last_update_query)[[1]]
      registered_db_last_update <- self$get(last_update_key)

      if (!identical(actual_db_last_update, registered_db_last_update)) {
        log$info("[REDIS] DB modification detected. All Redis cache will be invalidated.")
        log$info("[REDIS] Actual change on: {actual_db_last_update}; Last registered change on: {registered_db_last_update}") # nolint
        self$flush()
        self$set(last_update_key, actual_db_last_update)
      }
    }
  ),
  private = list(
    client = NULL,
    app_id = NULL,
    add_namespace = function(key) {
      paste("main_application", private$app_id, key, sep = "__")
    }
  )
)

APP_ID <- paste(
  Sys.getenv("APP_ID", "prod"),
  Sys.getenv("GIT_BRANCH", "main"),
  Sys.getenv("DATABASE_ENV", "prod"),
  sep = "__"
)

#' @export
redis_client <- RedisCache$new(APP_ID)
tictoc::toc()
