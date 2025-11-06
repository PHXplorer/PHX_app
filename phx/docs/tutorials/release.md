[Back to main README](../../README.md#development)

# Release and Deployment Flow

When we work on features, we create "feature branches".
When the feature is complete, we merge it into "develop" branch.
At the end of every sprint, we merge "develop" into "main" and create a release.

The application images are built automatically in the cloud for each branch.

ShinyProxy interface has three applications: main, dev and test.
Main application corresponds to the docker image that is built on main branch, dev - on develop, and test allows you to run an arbitrary image that is defined in environment variable `DOCKER_TAG`.

During the deployment, you can manually specify environment variables in `shinyproxy/application.yml` configuration file for each application.
For example, `dev` and `test` application can connect to different databases.
