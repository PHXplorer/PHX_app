box::use(
  checkmate[assert_string, assert_subset],
  dplyr[first, filter, pull],
  R6[R6Class]
)

box::use(
  app / logic / DataLoader[data_loader],
  app / logic / redis[redis_client]
)

#' This class provides methods to access variable details of a column
#' @export
ColnameDetails <- R6Class(
  classname = "ColnameDetails",
  private = list(
    data_loader = NULL,
    assert_colname = function(colname) {
      assert_string(colname)
      assert_subset(colname, private$data_loader$variable_details$colname)
    }
  ),
  public = list(
    initialize = function(data_loader) {
      private$data_loader <- data_loader
    },
    get_variable_label = function(colname) {
      private$assert_colname(colname)
      private$data_loader$variable_label_map |>
        filter(colname == !!colname) |>
        pull(label) |>
        first()
    },
    get_variable_description = function(colname) {
      private$assert_colname(colname)
      private$data_loader$variable_details |>
        filter(colname == !!colname) |>
        pull(description) |>
        first()
    },
    is_variable_reverse = function(colname) {
      private$assert_colname(colname)
      private$data_loader$variable_details |>
        filter(colname == !!colname) |>
        pull(reverse) |>
        first() == 1
    }
  )
)

#' @export
colname_details <- ColnameDetails$new(data_loader)
