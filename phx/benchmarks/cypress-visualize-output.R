library(readr)
library(dplyr)
library(ggplot2)
library(stringr)
library(purrr)

full_filenames <- list.files("../../benchmarks/cypress-benchmarks/", full.names = TRUE, pattern = "\\.csv$") # nolint
short_filenames <- list.files("../../benchmarks/cypress-benchmarks/", full.names = FALSE, pattern = "\\.csv$") # nolint

datalist <- map(full_filenames, read_csv)

data <- imap(short_filenames, function(filename, index) {
  file_info <- filename |>
    str_remove("\\.csv$") |>
    str_split("__") |>
    unlist()
  branch <- file_info[1]
  location <- file_info[2]
  db_driver <- file_info[3]

  datalist[[index]] |>
    mutate(branch = branch, location = location, db_driver = db_driver)
}) |>
  bind_rows() |>
  mutate(branch = str_trunc(branch, 30))

data_total <- data |> filter(name == "TOTAL")
data <- data |> filter(name != "TOTAL")

png(
  filename = "../../benchmarks/cypress-benchmark-total.png",
  width = 900,
  height = 600
)

data_total |>
  ggplot(aes(x = branch, y = duration, fill = db_driver)) +
  geom_bar(position = "dodge", stat = "identity") +
  labs(
    title = "Cypress test: total duration",
    x = NULL,
    y = "Time, seconds"
  ) +
  theme_classic() +
  theme(axis.text.x = element_text(angle = -90, hjust = 1))

dev.off()
