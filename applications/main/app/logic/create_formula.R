box::use(
  stats[as.formula]
)
#' Create a formula for model
#'
#' This function creates a formula object from the given independent, dependent and interaction
#' variables.
#'
#' @param independent_vars A character vector specifying the independent variables.
#' The length of this vector should be greater than zero.
#' @param dependent_var A character string specifying the dependent variable.
#' This should have length 1. Default is "status".
#' @param interaction_vars A character vector specifying the interaction variables.
#' This should either be NULL or have length 2. Default is NULL.
#'
#' @return A formula object for use in model functions (like lm() or glm()).
#' The structure of the formula is "dependent_var ~ independent_vars". If interaction_vars is
#' provided, the formula includes the interaction term, structured as
#' "dependent_var ~ independent_vars + interaction_term".
#'
#' @examples
#' create_formula(c("var1", "var2"), "outcome")
#' create_formula(c("var1", "var2"), "outcome", c("var1", "var2"))
#'
#' @export
create_formula <- function(
    independent_vars,
    dependent_var = "status",
    interaction_vars = NULL) {
  stopifnot(
    "independent_vars must be a character vector" =
      is.character(independent_vars) && length(independent_vars) > 0
  )
  stopifnot(
    "dependent_var must be a character string (e.g with length 1)" =
      is.character(dependent_var) && length(dependent_var) == 1
  )
  stopifnot(
    "interaction_vars must be NULL or a character vector with length 2" =
      is.null(interaction_vars) || (
        is.character(interaction_vars) && length(interaction_vars) == 2
      )
  )
  interactions_selected <- !is.null(interaction_vars)
  rhs <- paste(independent_vars, collapse = " + ")
  if (interactions_selected) {
    interaction_term <- paste(interaction_vars, collapse = "*")
    rhs <- paste(
      rhs,
      interaction_term,
      sep = " + "
    )
  }
  lhs <- paste(dependent_var, "~")
  as.formula(
    paste(lhs, rhs)
  )
}
