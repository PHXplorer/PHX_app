print(sprintf("This script was launched from %s", getwd()))

library(dplyr)
library(ggplot2)
library(shiny.benchmark)

app_startup_max <- as.numeric(Sys.getenv("APP_STARTUP_MAX", "15"))

current_branch <- system2(
  c("git", "rev-parse", "--abbrev-ref", "HEAD"),
  stdout = TRUE
)
current_location <- Sys.getenv("TEST_LOCATION", "local")
current_driver <- Sys.getenv("DB_DRIVER")

result <- benchmark(
  commit_list = current_branch,
  shinytest2_dir = "tests",
  tests_pattern = "e2e-application_startup",
  n_rep = 5,
  renv_prompt = FALSE,
  debug = TRUE
)

output <- summary(result)
output$location <- current_location
output$db_driver <- current_driver
output$comment <- "no comment"
output$datetime <- format(Sys.time(), "%Y-%m-%d %H:%M:%S")

result <- output$median[output$test_name == "application startup"][1]

if (result > app_startup_max) {
  stop("App takes too long to start.")
}

old_results <- read.csv("../../benchmarks/shiny-benchmark.csv")

old_condition <- old_results$commit == current_branch &
  old_results$location == current_location &
  old_results$db_driver == current_driver

new_results <- rbind(old_results[!old_condition, ], output)
new_results <- new_results[order(new_results$datetime), ]

write.csv(
  x = new_results,
  file = "../../benchmarks/shiny-benchmark.csv",
  row.names = FALSE
)

png(
  filename = "../../benchmarks/shiny-benchmark.png",
  width = 600,
  height = 900
)

plot_data <- new_results |>
  arrange(datetime) |>
  mutate(commit = substring(commit, 1, 15)) |>
  mutate(commit = factor(commit, levels = unique(commit))) |>
  mutate(show_label_lag = if_else(
    median > lag(median) * 1.1, TRUE, FALSE, FALSE
  )) |>
  mutate(show_label_lead = if_else(
    median < lead(median) * 0.9, TRUE, FALSE, FALSE
  )) |>
  mutate(show_label = show_label_lag | show_label_lead)

plot_data |>
  ggplot(
    aes(
      x = commit,
      color = interaction(location, db_driver)
    )
  ) +
  coord_flip() +
  geom_line(
    aes(y = median, group = interaction(location, db_driver))
  ) +
  geom_line(
    aes(y = max, group = interaction(location, db_driver)),
    linetype = "dotted"
  ) +
  geom_point(aes(y = median)) +
  geom_label(
    data = plot_data[plot_data$show_label, ],
    aes(y = median, label = round(median, 2), hjust = -0.2),
    show.legend = FALSE
  ) +
  labs(
    title = "Application startup time",
    subtitle = paste(
      "Y axis shows branch names sorted by commit time,",
      "most recent at the top"
    ),
    x = NULL,
    y = "Time, seconds",
    color = "Environment\nand DB driver"
  ) +
  theme_classic() +
  theme(
    axis.text.x = element_text(angle = 30, vjust = 1, hjust = 1),
    legend.position = "right"
  ) +
  scale_color_manual(values = c("#999999", "#E69F00")) +
  scale_x_discrete(expand = c(0.02, 0.02))

dev.off()
