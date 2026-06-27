[Back to main README](../../README.md#development)

# Testing suite

[`applications/main/tests`](applications/main/tests) folder contains all tests for the main application.

## Testing process

In CI (Github Actions) we test our code against three database engines: SQLite, MS SQL Server, and Postgres.
To facilitate this, new databse is created and populated with the same set of testing data.

When running tests locally, you need to keep in mind which database driver is being used (`DB_DRIVER` environment variable).
It makes sense to run e2e tests against different database engines locally,
but for unit tests please set it to `DB_DRIVER=sqlite` to ensure test data is used.

## Test Data

The test data are stored in [applications/main/tests/testthat/data](applications/main/tests/testthat/data) folder.
In this folder, there is also an [RScript](applications/main/tests/testthat/data/generate_test_data.R) to generate csv files from the database.
Make sure to run this script and push the updated files whenever you make changes to the database schema.
If you need add a test data for a new table, also add this table to the sqlite backend for [`connection.R`](applications/main/app/logic/connection.R)

> [!WARNING]
> Do not push real data to the repository. Make sure you are connected to the development database with fake data such as Synthea before running the script.

## Unit tests

Unit tests are defined in [`applications/main/tests/testthat`](applications/main/tests/testthat).

These tests are written using `testthat` package. We utilize [`setup.R`](applications/main/tests/testthat/setup.R) file for setting up and tearing down the environment for each test run. To make sure these takes into effect, run the tests only using the `{testthat}` package.

Here are the recommended ways to run the unit tests in the R console:

Run a single test file:

```R
# Make sure box imports the latest version of the files
box::purge_cache()
testthat::test_file("PATH_TO_THE_TEST_FILE")
```

Run all tests:

```R
rhino::test_r()
```

Since `setup.R` handles the environment setup and teardown, these steps makes sure that you can reproduce the test results in the CI locally.

## E2E tests

End to end test cases are defined in special Cypress files in [`applications/main/tests/cypress`](applications/main/tests/cypress). These test cases are writte in JavaScript.

We utilize `cypress` for e2e testing which comes out of the box with `rhino`. You can run the e2e tests in the R console using [`rhino::test_e2e`](https://appsilon.github.io/rhino/reference/test_e2e.html) function that supports both interactive and headless modes.
