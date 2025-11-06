options(
  # Allow absolute module imports (relative to the app root).
  box.path = getwd(),
  tigris_use_cache = TRUE,

  # shiny configuration
  shiny.host = "0.0.0.0",
  shiny.port = 3838L,

  # renv configuration
  repos = c(CRAN = "https://p3m.dev/cran/__linux__/jammy/latest"),
  pkgType = "binary",
  renv.config.ppm.enabled = TRUE,
  renv.config.pak.enabled = FALSE,
  renv.config.sandbox.enabled = FALSE,
  renv.config.cache.enabled = TRUE,
  renv.config.cache.symlinks = FALSE,
  renv.config.install.verbose = FALSE,
  renv.config.locking.enabled = TRUE,
  renv.config.synchronized.check = FALSE,

  # language server configuration to support box::use
  languageserver.parser_hooks = list(
    "box::use" = function(expr, action) {
      call <- match.call(box::use, expr)
      packages <- unlist(lapply(call[-1], function(x) {
        #' box::use(something, )
        if (x == "") {
          return()
        }

        #' box::use(dplyr)
        if (typeof(x) == "symbol") {
          return(as.character(x))
        }

        #' box::use(app/logic/utils)
        if (as.character(x[[1]]) == "/") {
          y <- x[[length(x)]]

          # this case is for app/logic/module_one
          if (length(y) == 1) {
            action$assign(symbol = as.character(y), value = NULL)
          }

          # this case is for app/logic/module_two[...]
          if (length(y) == 3 && y[[3]] == "...") {
            # import box module, iterate over its namespace and assign
          }

          # this case is for app/logic/module_three[a, b, c]
          lapply(y[-c(1, 2)], function(z) {
            action$assign(symbol = as.character(z), value = NULL)
          })

          return()
        }

        #' box::use(dplyr[filter, ...])
        as.character(x[[2]])
      }))
      action$update(packages = c("base", packages))
    }
  )
)

source("renv/activate.R")
