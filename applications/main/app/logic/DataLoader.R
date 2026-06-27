tictoc::tic("[module] DataLoader")
box::use(
  dplyr[
    arrange,
    case_when,
    coalesce,
    collect,
    distinct,
    filter,
    left_join,
    mutate,
    pull,
    rename,
    rename_with,
    select,
    tbl,
    union,
  ],
  purrr[
    keep,
    map,
    walk,
  ],
  rlang[expr, sym],
  rhino[log],
)

box::use(
  app / logic / clean_colnames[clean_colnames],
  app / logic / connection[db_con],
  app / logic / constants[
    EQUITY_DIMENSION_PREVALENCE,
    EQUITY_DIMENSION_SIMPLE,
    DEMO_ATTRIBUTE,
    PLACE_ATTRIBUTE_FIPS,
    PLACE_ATTRIBUTE_ZIP5,
  ],
  app / logic / get_filter_options[get_filter_options_raw],
  app / logic / load_env[config],
  app / logic / redis[redis_client],
  app / logic / variable_details_to_choices[variable_details_to_choices],
  app / logic / categorize_numeric[categorize_numeric],
)

#' @export
DataLoader <- R6::R6Class(
  classname = "DataLoader",
  #' PUBLIC
  public = list(
    #' properties
    db_tables = c(
      "demo_attributes",
      "health_dimensions",
      "fips_data",
      "zip5_data",
      "feature_details"
    ),

    #' initializer
    initialize = function(db_con, cache_engine = redis_client) {
      private$db_con <- db_con
      private$cache_engine <- cache_engine

      walk(self$db_tables, \(x) {
        lazy_table <- tbl(private$db_con, x)
        private$lazy_tables[[x]] <- rename_with(lazy_table, clean_colnames)
        private$origin_colnames[[x]] <- colnames(lazy_table)

        if (x == "feature_details") {
          private$lazy_tables[[x]] <- private$lazy_tables[[x]] |>
            mutate(category = coalesce(subdomain, domain, feature_type, "Other")) |>
            collect()
        }
      })
    },

    #' methods
    get_lazy_table = function(table_name) {
      private$lazy_tables[[table_name]]
    },
    get_origin_colnames = function(table_name) {
      private$origin_colnames[[table_name]]
    }
  ),
  #' PRIVATE
  private = list(
    #' properties
    db_con = NULL,
    cache_engine = NULL,
    lazy_tables = list(),
    origin_colnames = list(),

    #' methods
    make_active_binding = function(key, callback, with_cache = TRUE) {
      if (with_cache) {
        private$cache_engine$getset(key, callback)
      } else {
        callback()
      }
    },

    #' active binding placeholders
    equity_years_ = NULL,
    tbl_list_ = NULL,
    equity_dimensions_tbl_ = NULL,
    equity_dimensions_details_ = NULL,
    variable_details_ = NULL,
    categorical_colnames_ = NULL,
    variables_ = NULL,
    categorical_variables_ = NULL,
    filter_options_ = NULL,
    variable_label_map_ = NULL,
    prevelance_equity_dimensions_ = NULL
  ),
  #' ACTIVE BINDINGS
  active = list(
    equity_years = function() {
      private$make_active_binding("equity_years_", function() {
        private$lazy_tables$health_dimensions |>
          distinct(year) |>
          arrange(year) |>
          collect() |>
          pull()
      })
    },
    tbl_list = function() {
      private$make_active_binding("tbl_list_", function() {
        list(
          health_dimensions = self$equity_dimensions_tbl,
          demo_attributes = private$lazy_tables$demo_attributes,
          fips_data = private$lazy_tables$fips_data,
          zip5_data = private$lazy_tables$zip5_data
        )
      }, with_cache = FALSE)
    },
    equity_dimensions_tbl = function() {
      private$make_active_binding("equity_dimensions_tbl_", function() {
        private$lazy_tables$health_dimensions |>
          left_join(select(private$lazy_tables$demo_attributes, person_id, fips, zip5, year))
      }, with_cache = FALSE)
    },
    equity_dimensions_details = function() {
      private$make_active_binding(
        "equity_dimensions_details_", function() {
          existing_equity_dimensions <- private$lazy_tables$health_dimensions |>
            distinct(featureid) |>
            collect() |>
            pull()
          private$lazy_tables$feature_details |>
            filter(
              feature_type %in% c(EQUITY_DIMENSION_SIMPLE, EQUITY_DIMENSION_PREVALENCE) &
                featureid %in% existing_equity_dimensions
            ) |>
            mutate(colname = featureid, table = "health_dimensions")
        },
        with_cache = FALSE
      )
    },
    variable_details = function() {
      private$make_active_binding("variable_details_", function() {
        fips_data_colnames <- colnames(tbl(private$db_con, "fips_data"))
        zip5_data_colnames <- colnames(tbl(private$db_con, "zip5_data"))
        place_attribute_colnames <- clean_colnames(c(fips_data_colnames, zip5_data_colnames))
        place_variable_details <- private$lazy_tables$feature_details |>
          mutate(
            colname = paste(featureid, source, sep = "-"),
            table = case_when(
              feature_type == !!PLACE_ATTRIBUTE_FIPS ~ "fips_data",
              feature_type == !!PLACE_ATTRIBUTE_ZIP5 ~ "zip5_data"
            )
          ) |>
          filter(clean_colnames(colname) %in% place_attribute_colnames & !is.na(table))

        demo_colnames <- clean_colnames(private$origin_colnames$demo_attributes)
        demo_variable_details <- private$lazy_tables$feature_details |>
          filter(feature_type == !!DEMO_ATTRIBUTE) |>
          mutate(colname = featureid, table = "demo_attributes") |>
          filter(clean_colnames(colname) %in% demo_colnames)

        private$variable_details_ <- demo_variable_details |>
          union(place_variable_details) |>
          union(self$equity_dimensions_details) |>
          filter(display == "1") |>
          arrange(displayorder) |>
          select(
            featureid,
            source,
            category,
            colname,
            label,
            description,
            full_description,
            value_type,
            table,
            feature_type,
            domain,
            subdomain,
            subsubdomain,
            reverse
          ) |>
          mutate(
            colname = clean_colnames(colname),
            info_content = coalesce(full_description, description, "No information"),
            info_title = ifelse(!is.na(full_description), description, NA_character_),
            reverse = coalesce(reverse, 0)
          )
      })
    },
    categorical_colnames = function() {
      private$make_active_binding("categorical_colnames_", function() {
        self$variable_details |>
          filter(value_type == "text") |>
          pull(colname)
      })
    },
    variables = function() {
      private$make_active_binding("variables_", function() {
        variable_details_to_choices(self$variable_details)
      })
    },
    categorical_variables = function() {
      private$make_active_binding("categorical_variables_", function() {
        self$variables |>
          map(\(x) x[x %in% self$categorical_colnames]) |>
          keep(\(x) length(x) > 0)
      })
    },
    filter_options = function() {
      private$make_active_binding("filter_options_", function() {
        get_filter_options_raw(self$variable_details, db_con)
      })
    },
    variable_label_map = function() {
      private$make_active_binding("variable_label_map_", function() {
        eq_dimension_labels <- self$equity_dimensions_details |>
          select(featureid, description) |>
          collect()

        self$variable_details |>
          select(featureid, colname, label, value_type) |>
          left_join(eq_dimension_labels, by = "featureid") |>
          mutate(colname, value_type, label = coalesce(description, label), .keep = "none")
      })
    },
    prevelance_equity_dimensions = function() {
      private$make_active_binding("prevelance_equity_dimensions_", function() {
        self$equity_dimensions_details |>
          filter(feature_type == EQUITY_DIMENSION_PREVALENCE) |>
          pull(colname) |>
          tolower()
      })
    }
  ),
  cloneable = FALSE
)

#' @export
data_loader <- DataLoader$new(db_con, redis_client)
tictoc::toc()
