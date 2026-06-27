[Back to main README](../../README.md#quick-start)

# Quick start with RStudio

Despite the name of this tutorial, you can run the app in VSCode, RStudio, Vim,
or any other development environment. Essentially, this tutorial is dedicated to
those users who will run it **without** docker.

Before you proceed, please make sure that you have the data required for the application to work.
Please refer to the [how to get the data](./data.md) tutorial.

> [!WARNING]  
> This tutorial is for those who want to check out the app quickly and
> test some ad-hoc changes. We cannot guarantee that the app will run
> successfully due to many variable factors: one's environment, available
> available computing power and machine resources (CPU and RAM),
> access to web resources, etc. Thus application's performance should not
> be assessed when launching it from RStudio. Please be informed,
> that the development team recommends to use Docker (local deployment).

## Requirements
- Access to web resources
  - Intenet is required when installing R packages
  - Active internet connection is required when running the app to load external resources (e.g. React, Bootstrap, etc)
- Latest version of R
- ODBC drivers for MS SQL Server
  - If you are facing problems with the driver, check out the [FAQ](./faq.md)
- Tools for building R packages from source (#TODO add links to cran)

## Obtain the latest code

Download the latest application code from the [Github Releases](https://github.com/BMC-D4E/h2e/releases/latest) page in a zip archive and unpack it on your computer.

If you have `git` configured and you have access to the repository, you can clone it using the following command:

```
git clone git@github.com:BMC-D4E/h2e.git
```

The project has much more code than just the application - infrastructure code, scripts, benchmakrs, etc.
If you want to play around with the application code, you need to open _applications/main_ in RStudio.
You can do it by double clicking **applications/main/bmc-h2e.Rproj** file.

## Configure environment variables

Create a _.Renviron_ file, copy contents of _.env_ file into _.Renviron_ and update the values as needed (particularly all DB_* variables). Learn more in the [environment variables tutorial](./env_variables.md).

> [!IMPORTANT]
> You must restart R session to make use of the new environment variables!

You can check what other variables are used in the project by looking at _.env_ file in the root of the project (it is not the folder that is open in RStudio).

## Restore R dependencies

When the RStudio has opened the project, first thing to do is to restore the dependencies. In the R Console:

```r
# follow instructions in the console, if any
renv::restore()
```

### Start the app

Everything should be ready to go.
To start the app, either open _app.R_ file and click on the "Run" button in RStudio,
or run the following command in the R Console:

```r
rhino::app()
```