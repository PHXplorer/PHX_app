box::use(
  shiny[testServer, reactiveVal],
  testthat[...],
  dplyr[mutate, across]
)

box::use(
  app/view/vif_plot[vif_plot_output, vif_plot_server]
)


glm_data <- mtcars |>
  mutate(
    across(c(am, gear), as.character),
    gear_alias = gear
  )

glm_reg_univariate <- reactiveVal(glm(vs ~ am, data = glm_data, family = binomial(link = "logit")))
glm_reg_multivariate <- reactiveVal(
  glm(vs ~ am + gear, data = glm_data, family = binomial(link = "logit"))
)
glm_reg_aliased <- reactiveVal(
  glm(vs ~ am + gear + gear_alias, data = glm_data, family = binomial(link = "logit"))
)
