tictoc::tic("[module] load_env")
box::use(
  dplyr[glimpse],
  config[get],
  glue[glue, glue_collapse],
  checkmate[assert_subset],
  rhino[log],
)

box::use(
  app / logic / relevel_factors[get_numeric_levels],
)

#' Set environment
#'
#' This function should be executed at the start of the app
#' It reads environmental variable ENVIRONMENT, validate it and get proper config.
#' You can run it for side effects (saving to session object)
#' or to validate ENVIRONMENT variable or to get config
#'
#' @param session Shiny session object, if set, config will be saved to session$userData$config
#'
#' @export
set_environment <- function(session = NULL) {
  env <- Sys.getenv("ENVIRONMENT", "production")
  # this list is hardcoded to avoid typos and misconfigurations
  # app will not run, if it is not defined properly
  # production is used for deployed app
  # development is used for dev's local environment
  possible_envs <- c("production", "development")
  assert_subset(env, possible_envs)

  config <- get(config = env)

  # config validation
  assert_subset(config$geo$bivariate_dims, c(2, 3, 4))
  assert_subset(config$global_filters$default_settings$place_attribute_type, c("FIPS", "ZIP5"))

  if (env == "production") {
    options(shiny.sanitize.errors = TRUE)
  } else if (env == "development") {
    log$debug("[CONFIG] values retrieved from config.yml:")
    glimpse(config)
    log$debug("[CONFIG] environment variables:")
    print(Sys.getenv())
  }

  config$categorization$ordinal_categories <- c(
    config$categorization$ordinal_categories,
    unname(lapply(config$categorization$numeric_breaks, function(category) {
      get_numeric_levels(unlist(category$values))
    }))
  )

  if (!is.null(session)) {
    session$userData$config <- config
  }

  # Set minimum_sample_size to 0 in CI to pass tests
  if (Sys.getenv("ENSURE_DATA_ANONYMITY", "true") == "false") {
    log$warn("ENSURE_DATA_ANONYMITY is false, setting minimum_sample_size to 0")
    config$numbers$minimum_sample_size <- 0
  }

  if (config$data$database$db_driver == "sqlite") {
    log$warn("DB_DRIVER is sqlite, setting minimum_sample_size to 0")
    config$numbers$minimum_sample_size <- 0
  }

  invisible(config)
}

#' @export
config <- set_environment()

#' @export
initial_advanced_filters_state <- function(session) {
  default_selected <- config$global_filters$health_dimension$default_filter$value
  names(default_selected) <- config$global_filters$health_dimension$default_filter$key

  default_inputs <- list(list(
    value = config$global_filters$health_dimension$default_filter$value,
    category = config$global_filters$health_dimension$default_filter$category
  ))
  names(default_inputs) <- config$global_filters$health_dimension$default_filter$key

  list(
    selected = default_selected,
    percentile_breaks = NULL,
    inputs = default_inputs
  )
}

box::use(
  shiny[tagList, tags],
  shiny.info[toggle_info, display]
)

#' @export
debug_info <- function() {
  if (Sys.getenv("ENVIRONMENT", "production") == "production") {
    return()
  }

  tagList(
    toggle_info(hidden_on_start = TRUE, shortcut = "Ctrl+Shift+L"),
    display(
      tags$ul(
        tags$em("Database connection:"),
        tags$li(glue("DB_HOST: {Sys.getenv('DB_HOST')}")),
        tags$li(glue("DB_PORT: {Sys.getenv('DB_PORT')}")),
        tags$li(glue("DB_NAME: {Sys.getenv('DB_NAME')}"))
      ),
    )
  )
}
tictoc::toc()
