[Back to main README](../../README.md#quick-start)

# Deployment on a Linux machine

## Requirements

- Docker Engine
- Docker Compose
  - You can install Docker Desktop, it comes with the engine and the compose

## Authorize docker access

See [remote_docker_images](./remote_docker_images.md) tutorial.

## Obtain the latest code

Download the latest application code from the [Github Releases](https://github.com/BMC-D4E/h2e/releases/latest) page in a zip archive and unpack it on your computer.

You can also clone the repositoty using `git`. Please use `main` branch for production code.

## Obtain the data

See [how to get the data](./data.md) tutorial.

## Configure environment variables

See [environment variables](./env_variables.md) tutorial.

> [!IMPORTANT]  
> Applications will not start unless the following variables are defined:
> - WORKING_DIRECTORY
> - DB_HOST_PROD
> - DB_PORT_PROD
> - DB_NAME_PROD
> - DB_USER_PROD
> - DB_PASS_PROD

To learn more about these variables please refer to the environment variables section.

## Run the `start` script

Everything is ready to run the `start` script now. Make sure to run the `start` script from the root directory of the project:

```shell
./scripts/start.sh
```

The script will:
1. Read environment variables from _.env_
2. Read environment variables from _.env.local_ if it was created by the user
3. Pull docker images if ghcr is authorized and `DOCKER_BUILD=false`, otherwise it will build them locally
4. Create and run required docker containers: ShinyProxy, Redis and MS SQL (if necessary)

### Open the application

Once the script is finished, you can access the web application at http://localhost:8080.

### Update the application

Every once in a while, developers/maintainers of the application will release new versions.
To use the new application code, first of all, delete all docker containers and images.
You can do that in the Docker Desktop application.

Next, if you don't use git, you need to go through all steps once again - obtain the latest code, etc.

If you use git, it is enough (after removing docker images of course) to pull the latest changes and run the `start` script again:

```shell
git fetch
git checkout develop
git pull
./scripts/start.ps1
```

> [!WARNING]
> If you're using git and you made changes to the app,
> it might be necessary to reset your changes before pulling
> latest code. This will remove all changes that were
> introduced locally:

```
git reset --hard origin/main
```
