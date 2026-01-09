/// <reference types="../.rhino/node_modules/cypress/" />

const path = require('path');

const screenshotsFolder = path.resolve(__dirname, '..', 'tests', 'cypress', 'screenshots');

console.log(screenshotsFolder);

/** @type {Cypress.Config} */
module.exports = {
  e2e: {
    setupNodeEvents(on, config) {},
    baseUrl: 'http://localhost:3333',
    supportFile: false,
  },
  env: {
    BENCHMARK_IGNORE: '__benchmark_ignore',
  },
  reporter: 'teamcity',
  viewportWidth: 1680,
  viewportHeight: 1050,
  defaultCommandTimeout: 10000,
  screenshotOnRunFailure: true,
  screenshotsFolder,
};
