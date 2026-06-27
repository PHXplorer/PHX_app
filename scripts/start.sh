#!/usr/bin/env bash

function load_env() {
  while IFS='=' read -r key value; do
    # Skip comments and empty lines
    [[ $key = \#* ]] || [[ -z $key ]] && continue

    # Remove leading and trailing spaces from key and value
    key=$(echo $key | xargs)
    value=$(echo $value | xargs)

    # Remove single quotes from value
    value=${value//\'/}

    # Export the variable
    export "$key"="$value"
  done <$1
}

# Read environment variables
# export $(grep -v '^#' .env | xargs)
load_env .env

# Read secret values if defined
if test -f .env.local; then
  load_env .env.local
fi

# Telemetry Database
if test -f data/telemetry.txt; then
  echo "Telemetry database already exists."
else
  echo "Creating telemetry database."
  touch data/telemetry.txt
fi

# Static config
compose_stacks=("shinyproxy" "database")
applications_path="applications"
image_name_prefix="ghcr.io/bmc-d4e/h2e"
docker_images=("main" "validator" "telemetry")
github_container_registry="ghcr.io"
retries=10

# .env-based config
db_container=${DB_DRIVER:-mssql}
db_name=${DB_NAME_SYNTHEA:-H2E_Synthea}
db_user=${DB_USER_SYNTHEA:-sa}
db_password=${DB_PASS_SYNTHEA:-Password12345!}
docker_tag=${DOCKER_TAG:-latest}
if [[ $docker_tag == "main" || $docker_tag == "develop" ]]; then
  docker_tag="latest"
fi
modified_docker_tag=${docker_tag:0:128} # Docker tag can't be longer than 128 characters
ready_msg=""

echo "Using $db_container configuration"
if [[ $db_container == "mssql" ]]; then
  ready_msg="SQL Server is now ready for client connections"
fi

if [[ $db_container == "postgres" ]]; then
  ready_msg="database system is ready to accept connections"
fi

# Stop all running containers
for stack in "${compose_stacks[@]}"; do
  docker compose -p "$stack-stack" down
done

# Remove Shinyproxy images if they exist
docker rmi $(docker images -q --filter=reference="h2e-shinyproxy") -f
docker rmi $(docker images -q --filter=reference="shinyproxy-stack-shinyproxy") -f

# Build or pull necessary images
for image in "${docker_images[@]}"; do
  if [[ $(grep -ic "$github_container_registry" ~/.docker/config.json) -eq 1 && "$DOCKER_BUILD" == "false" ]]; then
    echo "Pulling docker images from $github_container_registry"
    docker pull --platform=linux/amd64 "$image_name_prefix-$image:main"
    docker pull --platform=linux/amd64 "$image_name_prefix-$image:develop"
    docker pull --platform=linux/amd64 "$image_name_prefix-$image:$modified_docker_tag"
  else
    echo "Building docker images locally"
    docker build "$applications_path/$image" -t "$image_name_prefix-$image:$modified_docker_tag"
  fi
done

# Create .env.modified_docker_tag
echo "DOCKER_TAG=$modified_docker_tag" >.env.modified_docker_tag

if [[ -e shinyproxy/admin_users.txt ]]; then
  echo "Using existing shinyproxy/admin_users.txt file"
else
  echo "Creating example shinyproxy/admin_users.txt for shinyproxy"
  echo -e "admin1\nadmin2" >shinyproxy/admin_users.txt
fi

if [[ -e shinyproxy/regular_users.txt ]]; then
  echo "Using existing shinyproxy/regular_users.txt file"
else
  echo "Creating example shinyproxy/regular_users.txt for shinyproxy"
  echo -e "user1\nuser2\nuser3" >shinyproxy/regular_users.txt
fi

# Run shinyproxy stack
docker compose -f "compose.shinyproxy.yml" build --no-cache
docker compose -f "compose.shinyproxy.yml" -p "shinyproxy-stack" up --remove-orphans -d

# Delete .env.modified_docker_tag
rm .env.modified_docker_tag

# Check if it necessery to create a local database
if [[ $DOCKER_CREATE_DATABASE == "false" ]]; then
  echo "No need to start a local database."
  exit 0
fi

# Run database stack only with the required database container
docker compose -f "compose.database.yml" build
docker compose -f "compose.database.yml" -p "database-stack" --profile $db_container up --remove-orphans -d $db_container

# Wait till database container is ready
while [[ $(docker inspect --format='{{.State.Health.Status}}' $db_container 2>&1 | grep -ic "healthy") -eq 0 ]]; do
  echo "Waiting for database container... ($retries)"
  sleep 6
  retries=$(($retries - 1))

  if [[ $retries == 0 ]]; then
    echo "Database container did not start up."
    exit 1
  fi
done

echo "Database container ready."

echo "Restoring database"
# Restore backup in MSSQL
if [[ $db_container == "mssql" ]]; then
  database_restore_query="RESTORE DATABASE $db_name FROM DISK='/opt/backup/$db_name.bak' WITH MOVE '$db_name' TO '/var/opt/mssql/data/$db_name.mdf', MOVE '"$db_name"_log' TO '/var/opt/mssql/data/$db_name.ldf'"
  docker exec $db_container /opt/mssql-tools/bin/sqlcmd -U $db_user -P $db_password -Q "$database_restore_query"
fi

# Restore backup in PSQL
if [[ $db_container == "postgres" ]]; then
  docker exec $db_container createdb $db_name -U $db_user
  docker exec $db_container pg_restore \
    -U $db_user \
    --dbname $db_name \
    --verbose \
    --no-password \
    /opt/backup/$db_name.tar
fi

exit 0
