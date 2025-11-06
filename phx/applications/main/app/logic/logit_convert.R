#' Convert between logit, odds and probabilities.
#'
#' This function provides a method for converting input values in the logit scale
#' to either odds or probabilities, or for just returning the input if the desired
#' output is also the logit scale. The conversion between these scales is common in
#' statistics, particularly in the field of logistic regression.
#'
#' @param logit A numeric vector representing values on the logit scale.
#' @param to A character string representing the desired output scale.
#' Must be one of "logit", "prob", or "odd".
#' "logit" will simply return the input logit values.
#' "prob" will convert the logit values to probabilities.
#' "odd" will convert the logit values to odds.
#'
#' @return A numeric vector with the input logit values converted to the
#' desired output scale ("prob", "odd", or "logit").
#'
#' @source https://sebastiansauer.github.io/convert_logit2prob/
#'
#' @examples
#' # converting logit to odds
#' logit_convert(0.5, to = "odd")
#'
#' # converting logit to probability
#' logit_convert(0.5, to = "prob")
#'
#' # returning the same logit input
#' logit_convert(0.5, to = "logit")
#' @export
logit_convert <- function(logit, to = "prob") {
  stopifnot(is.numeric(logit))
  stopifnot(length(to) == 1)
  stopifnot(to %in% c("logit", "prob", "odd"))
  if (to == "logit") {
    return(logit)
  }
  odd <- exp(logit)
  switch(
    to,
    odd = odd,
    prob = odd / (1 + odd)
  )
}
