box::use(
  logger[log_threshold, FATAL],
  testthat[teardown_env],
  withr[defer],
)

env_file <- file.path(getOption("box.path"), ".Renviron")
env_bak <- file.path(getOption("box.path"), ".Renviron.bak")

environment <- Sys.getenv("ENVIRONMENT", "production")
redis_enabled <- Sys.getenv("REDIS_ENABLED", "true")
ensure_data_anonymity <- Sys.getenv("ENSURE_DATA_ANONYMITY", "true")
db_driver <- Sys.getenv("DB_DRIVER", "sqlite")
log_threshold <- log_threshold()

message("Disabling .Renviron file temporarily for e2e tests")
if (file.exists(env_file)) {
  file.rename(env_file, env_bak)
}

message("Stubbing environment variables for testing")
Sys.setenv(ENVIRONMENT = "development")
Sys.setenv(REDIS_ENABLED = "false")
Sys.setenv(ENSURE_DATA_ANONYMITY = "false")
if (Sys.getenv("CI", "false") == "false") {
  Sys.setenv(DB_DRIVER = "sqlite")
}
log_threshold(FATAL)


defer(envir = teardown_env(), {
  message("Restoring .Renviron file")
  if (file.exists(env_bak)) {
    file.rename(env_bak, env_file)
  }
  message("Restoring environment variables to its original value")
  Sys.setenv(ENVIRONMENT = environment)
  Sys.setenv(REDIS_ENABLED = redis_enabled)
  Sys.setenv(ENSURE_DATA_ANONYMITY = ensure_data_anonymity)
  if (Sys.getenv("CI", "false") == "false") {
    Sys.setenv(DB_DRIVER = db_driver)
  }
  log_threshold(log_threshold)
})
