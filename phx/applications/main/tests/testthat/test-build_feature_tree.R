box::use(
  data.tree[FindNode],
  testthat[...],
)

box::use(
  app / logic / build_feature_tree[build_feature_tree],
)


feature_details_fix <- data.frame(
  feature_type = rep("Demo Attribute", 6),
  level1 = c("a1", "a1", "a1", "a2", "a2", "a2"),
  level2 = c("b1", "b1", "b2", "b3", NA, NA),
  colname = c("variable1", "variable2", "variable3", "variable4", "variable5", "variable6"),
  value_type = c(rep("text", 3), rep("num", 3))
)

feature_levels_fix <- c("feature_type", "level1", "level2", "colname")

describe("build_feature_tree", {
  test_that("returns a Node object", {
    result <- build_feature_tree(feature_details_fix, feature_levels_fix)
    expect_s3_class(result, "Node")
  })

  test_that("returns a Node with correct number of levels", {
    result <- build_feature_tree(feature_details_fix, feature_levels_fix)

    # expected length is number of input levels + root
    expected_length <- length(feature_levels_fix) + 1
    expect_equal(result$height, expected_length)
  })

  test_that("collapses branches for missing levels", {
    root_node <- build_feature_tree(feature_details_fix, feature_levels_fix)
    missing_node <- FindNode(root_node, "NA")
    expect_equal(length(missing_node), 0)
  })

  test_that("replaces unknown feature_type values with a config label", {
    root_node <- build_feature_tree(feature_details_fix, feature_levels_fix)
    demo_attribute_node <- FindNode(root_node, "Demo Attribute")
    person_attribute_node <- FindNode(root_node, "Person Attribute")
    expect_null(demo_attribute_node)
    expect_gt(length(person_attribute_node), 0)
  })
})
