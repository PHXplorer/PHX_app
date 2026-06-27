[Back to main README](../../README.md#data-and-environment-variables)

# Getting the data

There are three possible scenarios:

1. Database is running on some server that is _different_ from the machine that runs ShinyProxy.
In this case `DB_HOST_PROD`, `DB_HOST_DEV`, and `DB_HOST_SYNTHEA` must be set to the IP address of the said server.
Example: `DB_HOST_PROD=38.123.92.154` (this is a random ip address!).

2. Database is running on the same machine that runs ShinyProxy, but outside of Docker, or in a separate network. In this case, DB_HOST has to be mapped to the internal machine address.
Example: `DB_HOST_PROD=host.docker.internal`.

3. There is no database running, it was created during the `start` script execution (this can be configured with `DOCKER_CREATE_DATABASE=true` in .env.local file).
In this case database and ShinyProxy are running in the same virtual docker network, so the `DB_HOST_PROD` should be set to the name of the appropriate container.
Example: `DB_HOST_PROD=mssql`.

> [!NOTE]
> The following sections are for those who follow scenario #3,
> i.e. when `start` script spins up a fresh database container.

## Download backup file(s)

`start` script will create a completely fresh and empty database.
To populate it with some data, you need to provide it with a data backup file.

Download database backup file and put it into `data` at the root of the project.

### MS SQL Server
1. Make sure that the file name of the backup is `H2E_Synthea.bak`.
2. Set the environment variables in `.env.local` file:

```
DB_DRIVER=mssql

DB_HOST_SYNTHEA=mssql
DB_PORT_SYNTHEA=1433
DB_NAME_SYNTHEA=H2E_Synthea
DB_USER_SYNTHEA=sa
DB_PASS_SYNTHEA=Password12345!

DB_HOST_DEV=mssql
DB_PORT_DEV=1433
DB_NAME_DEV=H2E_Synthea
DB_USER_DEV=sa
DB_PASS_DEV=Password12345!

DB_HOST_PROD=mssql
DB_PORT_PROD=1433
DB_NAME_PROD=H2E_Synthea
DB_USER_PROD=sa
DB_PASS_PROD=Password12345!
```

### Postgres Server

1. Make sure that the file name of the backup is `H2E_Synthea.tar`.
2. Set the environment variables in `.env.local` file:

```
DB_DRIVER=postgres

DB_HOST_SYNTHEA=postgres
DB_PORT_SYNTHEA=5432
DB_NAME_SYNTHEA=H2E_Synthea
DB_USER_SYNTHEA=postgres
DB_PASS_SYNTHEA=Password12345!

DB_HOST_DEV=postgres
DB_PORT_DEV=5432
DB_NAME_DEV=H2E_Synthea
DB_USER_DEV=postgres
DB_PASS_DEV=Password12345!

DB_HOST_PROD=postgres
DB_PORT_PROD=5432
DB_NAME_PROD=H2E_Synthea
DB_USER_PROD=postgres
DB_PASS_PROD=Password12345!
```

## Database restore

Database backup should be restored automatically via running:


### Shell (Unix)
[`start.sh`](../../scripts/start.sh) at the root of the project.

```sh
./scripts/start.sh
```

### Powershell (Windows or Unix)
[`start.ps1`](../../scripts/start.ps1) at the root of the project.

```powershell
./scripts/start.ps1
```


If it didn't happen, or for any other reasons, you can restore the backup manually.

For MS SQL Server:

- open Docker Desktop
- click on the `mssql` container
- go to Exec tab and paste the following command:

```
/opt/mssql-tools/bin/sqlcmd -U SA -P Password12345! -Q "RESTORE DATABASE H2E_Synthea FROM DISK='/opt/backup/H2E_Synthea.bak' WITH MOVE 'H2E_Synthea' TO '/var/opt/mssql/data/H2E_Synthea.mdf', MOVE 'H2E_Synthea_log' TO '/var/opt/mssql/data/H2E_Synthea.ldf'"
```

- make sure that the new database appears in the list

```
/opt/mssql-tools/bin/sqlcmd -U SA -P Password12345! -Q "SELECT name, database_id, create_date FROM sys.databases;"
```

### Database backup

- To backup the database (in case you made crucial changes to Views, Tables, etc):

```
/opt/mssql-tools/bin/sqlcmd -U SA -P Password12345! -Q "BACKUP DATABASE H2E_Synthea TO DISK = '/opt/backup/H2E_Synthea_new.bak' WITH INIT;"
```

- When the command finishes, you will see `H2E_Synthea_new.bak` in the `data` folder at the root of the project.

## SQL IDE

For working with the database it is recommended to use DBeaver. To connect, no need to change default host/port settings. User is "sa", and password is defined in `.env.local` file. Also make sure to check "Trust server certificate". 

While developing the application, you will probably only need a devcontainer and database container running - feel free to stop all other containers.
