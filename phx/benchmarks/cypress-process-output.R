library(dplyr)
library(readr)

BENCHMARK_IGNORE <- "__benchmark_ignore" # nolint
MS_IN_SECOND <- 1000 # nolint

logs <- readLines("cypress.log")
unlink("cypress.log")

# Extract name and duration using regular expressions
result <- regmatches(
  logs,
  regexec("##teamcity\\[testSuiteFinished name='(.*?)' duration='(\\d+)'", logs)
)

values <- lapply(result, function(x) {
  list(name = x[2], duration = x[3])
})

table <- bind_rows(values) |>
  filter(!startsWith(name, BENCHMARK_IGNORE)) |>
  mutate(duration = as.numeric(duration) / MS_IN_SECOND)

total_duration <- sum(table$duration)

table <- bind_rows(table, tibble(name = "TOTAL", duration = total_duration))

current_branch <- system2(c("git", "rev-parse", "--abbrev-ref", "HEAD"), stdout = TRUE) # nolint
current_branch <- gsub("/", "_", current_branch)
db_driver <- Sys.getenv("DB_DRIVER", "unknown")
current_location <- Sys.getenv("TEST_LOCATION", "local")

file_name <- paste(
  current_branch,
  current_location,
  db_driver,
  sep = "__"
)

full_file_name <- paste0("../../benchmarks/cypress-benchmarks/", file_name, ".csv") # nolint

if (file.exists(full_file_name)) {
  unlink(full_file_name)
}

write_csv(table, full_file_name)
