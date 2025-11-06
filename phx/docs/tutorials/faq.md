[Back to main README](../../README.md)

## FAQ

**Q:** I made changes, ran start script, but nothing changed.\
**A:** Make sure images are not cached: remove containers, images and (if necessary) volumes. Do not remove cached build, unless you absolutely have to.

---

**Q:** I want to build a docker image locally and push it to Github, how do I do that?\
**A:** Please note, that the image is supposed to be built inside Github Actions, and this instruction is for manual emergency situations. Also note, that the Docker CLI has to be authorized to push images to ghcr (see development workflow section). The process itself is simple:
```
docker build applications/main -t ghcr.io/bmc-d4e/h2e-main
docker push ghcr.io/bmc-d4e/h2e-main
```

---

**Q:** I want to develop PowerShell script for Windows automation, but I'm using mac. What should I do?\
**A:** You can install PowerShell on mac ([instructions](https://learn.microsoft.com/en-gb/powershell/scripting/install/installing-powershell-on-macos?view=powershell-7.4)) and install a PowerShell VS Code extension. Use these tools to write & debug your script.

---

**Q:** When I run a rhino function that require node in devcontainer, I get `[EACCES]` error. What should I do?\
**A:** Exit the devcontainer, delete if `applications/main/.rhino` folder exists, and run the function in your local R console at `applications/main/` directory. This will install the node modules to your `applications/main/.rhino` folder, and you will be able to run those functions in devcontainer.

---

**Q:** I am making changes to the code, but my shiny outputs (plot, table, etc) still look the same, what's the problem?\
**A:** There is a chance that you are using cached shiny outputs. Please refer to [How to reset the cache](#how-to-reset-the-cache) section of this document.

---

**Q:** I am getting deadlock errors in SQL. \
**A:** Check if you are using the recommended Docker Desktop version ([4.27.2](https://docs.docker.com/desktop/release-notes/#4272)). If not, consider downgrading your Docker Desktop to this version by:

1. Uninstall the current version of Docker Desktop.
2. Download the recommended version from the link above.
3. Install the recommended version.

If you don't want to change your Docker version, try disabling query parallelism as described [in this article](https://learn.microsoft.com/en-us/sql/database-engine/configure-windows/configure-the-max-degree-of-parallelism-server-configuration-option?view=sql-server-ver16). TL;DR: run this SQL query:

```SQL
EXEC sp_configure 'show advanced options', 1;
RECONFIGURE WITH OVERRIDE;
EXEC sp_configure 'max degree of parallelism', 1;
RECONFIGURE WITH OVERRIDE;
```
---

**Q** My application can't connect to MS SQL Server \
**A** There are two known reasons when the app cannot connect to SQL Server:
1. You have the wrong version of ODBC driver installed. Application is using `ODBC Driver 18 for SQL Server`. Maybe you have version 17?
2. R process is not able to locate the ODBC driver.
In this case, you can define a special `ODBCSYSINI` environment variable (in _.env.local_ or in _.Renviron_)
with the path to the folder that contains _odbcinst.ini_ and _odbc.ini_.

---

**Q**: I am getting the following segfault error when I try to run the application with `shiny::runApp()`.
```R
*** caught segfault ***
address 0xfffffffbbf2ef03a, cause 'invalid permissions'

Traceback:
 1: timechange:::C_valid_tz(tzone)
 2: with_tz.default(Sys.time(), tzone)
 3: with_tz(Sys.time(), tzone)
 4: lubridate::now(tzone = "UTC")
 5: list2(...)
 6: dplyr::coalesce(time, lubridate::now(tzone = "UTC"))
 7: private$insert_checks(app_name, type, session, details, time)
 8: self$data_storage$insert(app_name = self$app_name, type = type,     session = session$token, details = details)
```

**A**: This is a very rare error, but there is a hacky solution. Before running the application, run the following command in the R console:
```R
timechange:::C_valid_tz
```
After that, you will be able to run the application with `shiny::runApp()`.
