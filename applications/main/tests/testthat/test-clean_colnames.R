box::use(
  testthat[...]
)
box::use(
  app / logic / clean_colnames[clean_colnames]
)


describe("clean_colnames", {
  it("converts a character vector to lowercase, replaces spaces and dashes with underscores", {
    expect_equal(clean_colnames(c("A B", "C-D")), c("a_b", "c_d"))
  })
})
