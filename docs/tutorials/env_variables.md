[Back to main README](../../README.md#data-and-environment-variables)

# Environment variables

## Full list used environment variables

> [!NOTE]
> You can find the complete list of used environment variables in [.env file](../../.env)

> [!IMPORTANT]  
> Variables that don't have default value (-) must be defined manually.
> If these variables are not defined, applications will not work.

### General configuration

| Variable | Default value | Description |
| --- | --- | --- |
| WORKING_DIRECTORY | - | [Absolute path](https://www.redhat.com/sysadmin/linux-path-absolute-relative) to the directory where compose files are located. This path is required to correctly mount docker volumes. It can't be set automatically, because on Windows`pwd` does not work.
| ENVIRONMENT | production | Which environment are you going to use? Implemented environments: **production** (sanitizes errors and logs only the high severity events to avoid leaking sensitive information), **development** (does not sanitize errors and logs, useful for debugging).
| DOCKER_TAG | latest | Tag for the Docker image to be pulled or built. If a github branch name is provided, the branch's image will be pulled from the ghcr.io. If set to develop or main, it will fall back to the `latest` tag, since develop and main are always pulled. If is longer than 128 characters, it will be truncated.
| DOCKER_BUILD | false | If `true`, docker images will be built locally. Useful in situation where you don't have access to ghcr.io to pull images.
| DOCKER_CREATE_DATABASE | false | If you already have a database running somewhere, keep this option set to `false`. However, it is possible to create a docker container with a database. This database will be populated with a backup data - useful for development or testing purposes.
| ENSURE_DATA_ANONYMITY | true | In the application there are places where the data cells contain small number of patients which could lead to their identification. To avoid this, we do not show data (rows in tables, polygons on the map, etc) with number of `patients < config$numbers$minimum_sample_size`. However, for testing purposes it is useful to disable this feature.
| USE_MOCK_DB_DATA | false | Should the application upload mock data to the database? Only use this in testing.

### Authentication

| Variable | Default value | Description |
| --- | --- | --- |
| SHINYPROXY_AUTH_METHOD | none | Do you want to enable authentication? Implemented methods: (1) none, (2) simple, (3) ldap. See [Authentication Configuration](https://www.shinyproxy.io/documentation/configuration/#authentication) for more info.
| SHINYPROXY_ADMIN_GROUP | admins | User group that will have access to Shinyproxy admin panel.
| AUTH_ADMIN_GROUP | admins | User group that will have access to proceted (ADMIN) applications, i.e. development version, data validator, telemetry.
| AUTH_REGULAR_GROUP | shiny_users | User group that has access to production application.
| LDAP_URI_SHINYPROXY | ldap://ldap_server/dc=ldapusermanager,dc=org | Address of the LDAP or AD server.
| LDAP_ADMIN_DN | cn=admin,dc=ldapusermanager,dc=org | Master login to establish initial bind with the LDAP.
| LDAP_ADMIN_PASSWORD | admin | Master password to establish initial bind with the LDAP.
| AD_USER_SEARCH_FILTER | (sAMAccountName={0}) | Criterion to find the user in the LDAP/AD.
| AD_USER_SEARCH_BASE | ou=Users | Criterion to find the user in the LDAP/AD.
| AD_GROUP_SEARCH_FILTER | (member={0}) | Criterion to find the user in the LDAP/AD.
| AD_GROUP_SEARCH_BASE | ou=Groups | Criterion to find the user in the LDAP/AD.

### Database connection

| Variable | Default value | Description |
| --- | --- | --- |
| DB_DRIVER | mssql | What database will the app connect to? Implemented drivers: (1) mssql, (2) postgres, (3) sqlite
| DB_HOST_PROD | - | Productiond database host. Can be (1) docker container name, e.g. `mssql`, if database was created by the docker composer, (2) `host.docker.internal` if the database is running on the same machine as ShinyProxy, (3) any external IP address, e.g. `12.345.67.89`
| DB_PORT_PROD | - | Production DB port. For MS SQL Server the default value is 1433, for Postgres - 5432.
| DB_NAME_PROD | - | Name of the "database" inside the running database instance.
| DB_USER_PROD | - | User name to connect to production DB.
| DB_PASS_PROD | - | User password to connect to production DB.
| DB_HOST_DEV | - | Development DB host
| DB_PORT_DEV | - | Development DB port
| DB_NAME_DEV | - | Development DB database name
| DB_USER_DEV | - | Development DB user
| DB_PASS_DEV | - | Development DB password
| DB_HOST_SYNTHEA | - | Synthea DB host
| DB_PORT_SYNTHEA | - | Synthea DB port
| DB_NAME_SYNTHEA | - | Synthea DB database name
| DB_USER_SYNTHEA | - | Synthea DB user
| DB_PASS_SYNTHEA | - | Synthea DB password

### Redis configuration

| Variable | Default value | Description |
| --- | --- | --- |
| REDIS_ENABLED | true | Should cache be enabled using Redis?
| REDIS_HOST | redis | Address of the machine where Redis is running. By default Redis runs in a docker container on the same docker-network as ShinyProxy (and other docker containers spawned by ShinyProxy), thus the network name is the same as the name of the docker container. No need to change to `localhost`
| REDIS_PORT | 6379 | Port on which Redis is running
| REDIS_MAXMEMORY | 1gb | Maximum amount of memory (RAM) available to Redis. When memory limit is reached, Redis will start to remove cached items based on `REDIS_MAXMEMORY_POLICY`
| REDIS_MAXMEMORY_POLICY | allkeys-lru | Which keys to delete to free up memory. By default, least recently used keys are deleted. [Learn more on key eviction](https://redis.io/docs/latest/develop/reference/eviction/).

## .env files

This project relies on both public and private environment variables.

Public variables are defined in `.env` file.
They contain only non-sensitive information: general configuration and credentials for local resources.
This file is published on Github and can be seen by every person who has access to the project.

Private variables are defined in `.env.local` file.
They contain sensitive information: database connection credentials, passwords, tokens, etc.
This file is not published on Github.

> [!NOTE]
> Depending in the environment where the app runs, it is possible
> to define environment variables in a different way. For example,
> those who run the app through RStudio should define environment variables
> in `.Renviron` file. It is also possible to define variable on the system
> level, e.g. by defining a variable in `.bashrc` file or using secret
> management tool provided by the deployment platform.

Because private variables are not published to Github,
one needs to create `.env.local` file every time project code is copied over.

> [!NOTE]
> start script and docker-compose use both _.env_ and _.env.local_ files by first reading values
> from _.env_ and then reading values from _.env.local_ - which means that values from the former
> overriden from the latter.

Remember: every time `.env.local` or `.env` file is changed, `start` script must be run again:

Windows: `.\scripts\start.ps1`\
Linux: `./scripts/start.sh`

## .Renviron file

If you run the app outside of docker and docker-compose (most likely you are running it with RStudio),
you will need to create _.Renviron_ file and copy the contents of _.env_ into it.
Make sure to remove suffixes from the `DB_*` variables.
For example, all database connection variables should be defined as `DB_HOST=...`, `DB_PORT=...`, etc.

## docker-compose files

Although docker-compose stacks use `.env` and `.env.local` files, database-related variables are defined inline.
This is needed for two reasons:
- docker-compose will try to "read" those values from `.env.local` but if they are not defined, it will use "fallback" values assuming that there is a MS SQL docker container running with default parameters.
- Shinyproxy is run from docker-compose and it requires access to these environment variables. There might be propagation issues with values sourced from `.env.` and `.env.local` so they have to be referenced explicitly.
