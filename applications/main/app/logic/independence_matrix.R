box::use(
  stats[fisher.test, p.adjust]
)

box::use(
  app / logic / matrix_utils[create_matrix, set_matrix_value_from_pair],
  app / logic / utils[format_pvalues],
  app / logic / load_env[config]
)

#' Fisher's exact test for multiple column pairs
#'
#' This function performs a Fisher's exact test
#' for independence for multiple column pairs of a dataset.
#' It then returns a list containing matrices of p-values and corresponding labels.
#'
#' @param df A dataframe containing the columns to be tested.
#' @param col_pairs A list of character vectors, each vector should contain two column names
#'     from `df` for which the Fisher's exact test should be performed.
#' @return A list containing two elements:
#'     - 'labels': A matrix where each element represents the formatted p-value
#'     - 'values': A matrix where each element represents the p-value from the Fisher's exact test
#'        for the corresponding column pair.
#'
#' @examples
#' \dontrun{
#' col_pairs <- list(c("cyl", "gear"), c("vs", "carb"))
#' independence_matrix(mtcars, col_pairs)
#' }
#'
#' @note
#' Fisher's exact test is performed only when both the row and column sums of the contingency table
#' are non-zero. Otherwise, the p-value is not calculated.
#' There is also issue with dataset. Sometimes one of variables has only one variable and crosstable
#' doesn't have two dimensions. In this case p-value is not calculated.
#'
#' @seealso \code{\link[stats]{fisher.test}}
#'
#' @export
independence_matrix <- function(df, col_pairs) {
  stopifnot(length(col_pairs) > 0)
  stopifnot(
    "col_pairs must be a list that contains vectors with 2 elements" =
      all(sapply(col_pairs, function(x) length(x) == 2))
  )
  stopifnot(
    "col_pairs must be a list of character column names" = all(sapply(col_pairs, is.character))
  )

  # get unique col_pairs to avoid redundant calculation
  col_pairs <- unique(col_pairs)

  # get cols contained in the col_pairs
  cols <- unique(unlist(col_pairs))

  stopifnot(
    "all columns in col_pairs must be present in the dataset" = all(cols %in% names(df))
  )

  # Initialize an empty matrix to store p-values
  p_value_matrix <- create_matrix(cols)

  for (pair in col_pairs) {
    # calculate contingency table for the test
    crosstable <- as.matrix(table(df[[pair[1]]], df[[pair[2]]]))

    row_sums <- rowSums(crosstable)
    col_sums <- colSums(crosstable)
    is_valid_fisher_input <- all(dim(crosstable[row_sums > 0, col_sums > 0, drop = FALSE]) > 1)

    if (!is_valid_fisher_input) {
      p_value <- NA
    } else {
      # Perform the Fisher's exact test
      indp_test <- fisher.test(
        crosstable,
        simulate.p.value = TRUE
      )
      p_value <- indp_test$p.value
    }

    # Store the p-value in the matrix
    p_value_matrix <- set_matrix_value_from_pair(p_value_matrix, pair, p_value)
  }

  # p-values are adjusted according to followed statistical procedure
  if (config$numbers$fisher_pvalues_log10) {
    vector <- -log10(p.adjust(p_value_matrix, method = "BH"))
    vector[vector == Inf] <- 0
    p_value_matrix <- create_matrix(
      cols,
      vector = vector
    )
  }

  return(
    list(
      labels = format_pvalues(p_value_matrix),
      values = p_value_matrix
    )
  )
}
