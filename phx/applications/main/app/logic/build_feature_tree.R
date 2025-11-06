box::use(
  data.tree[as.Node],
  checkmate[assert_data_frame],
  dplyr[coalesce, mutate, rowwise, ungroup, distinct, pull, filter],
  purrr[map_chr, reduce],
)

box::use(
  app / logic / constants[
    EQUITY_DIMENSION_PREVALENCE,
    EQUITY_DIMENSION_SIMPLE,
    LEVEL_MISSING,
    ROOT_NAME,
  ],
  app / logic / load_env[config],
)

#' @export
LEVEL_MISSING <- "MISSING"

# "root" is a reserved word in data.tree objects, so we can't use it
ROOT_NAME <- "root2"

FEATURE_LEVELS <- c(
  "feature_type",
  "domain",
  "subdomain",
  "subsubdomain",
  "colname"
)

get_feature_type_label <- function(feature_type) {
  label <- config$global_filters$feature_type_label_mapping[[feature_type]]$label
  if (is.null(label)) {
    return(feature_type)
  }
  label
}

#' Create a tree structure out of a data.frame
#' @param df {data.frame} with feature details data
#' @param levels_from {character} vector of column names to use as levels in the tree
#' @param feature_type_subset {character} vector of feature types to include in the tree
#' @return The root {Node} of the {data.tree} structure
#' @export
build_feature_tree <- function(
    df,
    levels_from = FEATURE_LEVELS,
    feature_type_subset = NULL,
    feature_type_exclude = NULL,
    excluded_attributes = c(),
    only_categorical_variables = FALSE,
    no_categorization = FALSE) {
  assert_data_frame(df)

  df <- df |>
    mutate(feature_type = ifelse(
      feature_type == EQUITY_DIMENSION_PREVALENCE,
      EQUITY_DIMENSION_SIMPLE,
      feature_type
    ))

  if (is.null(feature_type_subset)) {
    feature_type_subset <- unique(df$feature_type)
  }

  if (only_categorical_variables) {
    df <- filter(df, value_type == "text")
  }

  if (no_categorization) {
    df <- mutate(df, value_type = "text")
  }

  df <- df |>
    filter(!colname %in% excluded_attributes) |>
    filter(
      feature_type %in% feature_type_subset &
        !feature_type %in% feature_type_exclude
    ) |>
    mutate(across(levels_from, \(x) coalesce(x, LEVEL_MISSING))) |>
    mutate(feature_type = map_chr(feature_type, get_feature_type_label)) |>
    rowwise() |>
    mutate(pathString = reduce(
      levels_from,
      \(acc, nxt) {
        nxt <- get(nxt)
        if (length(nxt) == 0 || nxt == LEVEL_MISSING) {
          acc
        } else {
          paste(acc, nxt, sep = "/")
        }
      },
      .init = ROOT_NAME
    )) |>
    ungroup()
  if (nrow(df) > 0) {
    return(as.Node(df))
  }
}


#' @export
build_feature_tree_mem <- memoise::memoise(build_feature_tree)
