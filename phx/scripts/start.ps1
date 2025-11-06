function Get-EnvironmentVariables {
  param($path)
  $content = Get-Content $path
  foreach ($line in $content) {
    $name, $value = $line -split '=', 2
    if ([string]::IsNullOrWhiteSpace($name) -or $name.Contains('#')) {
      continue
    }
    Set-Content env:\$name $value
  }
}

# Read environment variables
Get-EnvironmentVariables .env

# Get the absolute path to .env.local
$dirOfScript = $PSScriptRoot
$rootDir = Join-Path $dirOfScript '..'
$envLocalPath = "$rootDir\.env.local"
if ($IsMacOS) {
  $envLocalPath = "$rootDir/.env.local"
}

# Read secret values if defined
if ([System.IO.File]::Exists($envLocalPath)) {
  Get-EnvironmentVariables .env.local
}

# Telemetry Database
if (!(Test-Path -Path "$rootDir\data\telemetry.txt")) {
  New-Item "$rootDir\data\telemetry.txt" -type file
}
else {
  Write-Host "Using existing telemetry.txt file"
}

# Static config
$compose_stacks = @("shinyproxy", "database")
$applications_path = "applications"
$image_name_prefix = "ghcr.io/bmc-d4e/h2e"
$docker_images = @("main", "validator", "telemetry")
$github_container_registry = "ghcr.io"
$retries = 10

# .env-based config
if (!$env:DB_DRIVER) {
  $db_container = "mssql"
}
else {
  $db_container = $env:DB_DRIVER
}
if (!$env:DB_NAME_SYNTHEA) {
  $db_name = "H2E_Synthea"
}
else {
  $db_name = $env:DB_NAME_SYNTHEA
}
if (!$env:DB_USER_SYNTHEA) {
  $db_user = "sa"
}
else {
  $db_user = $env:DB_USER_SYNTHEA
}
if (!$env:DB_PASS_SYNTHEA) {
  $db_password = "Password12345!"
}
else {
  $db_password = $env:DB_PASS_SYNTHEA
}
if (!$env:DOCKER_TAG -or $env:DOCKER_TAG -eq "main" -or $env:DOCKER_TAG -eq "develop") {
  $docker_tag = "latest"
}
else {
  $docker_tag = $env:DOCKER_TAG
}
$modified_docker_tag = $docker_tag
if ($modified_docker_tag.Length -gt 128) {
  $modified_docker_tag = $docker_tag.SubString(0, 128) # Docker tag must be less than 128 characters
}

Write-Host "Using $db_container configuration"

# Stop all running containers
foreach ($stack in $compose_stacks) {
  docker compose -p "$stack-stack" down
}

# Remove Shinyproxy images if they exist
docker rmi $(docker images -q --filter=reference="h2e-shinyproxy") -f
docker rmi $(docker images -q --filter=reference="shinyproxy-stack-shinyproxy") -f

# Build or pull necessary images
foreach ($image in $docker_images) {
  if ($env:DOCKER_BUILD -eq "false" -and (Select-String -Path ~/.docker/config.json -Quiet -SimpleMatch -Pattern $github_container_registry) ) {
    Write-Host "Pulling docker images from $github_container_registry"
    docker pull --platform=linux/amd64 "${image_name_prefix}-${image}:main"
    docker pull --platform=linux/amd64 "${image_name_prefix}-${image}:develop"
    docker pull --platform=linux/amd64 "${image_name_prefix}-${image}:${modified_docker_tag}"
  }
  else {
    Write-Host "Building docker images locally"
    docker build "$applications_path/$image" -t "${image_name_prefix}-${image}:${modified_docker_tag}"
  }
}

# Create .env.modified_docker_tag
Add-Content -Path .env.modified_docker_tag -Value "DOCKER_TAG=$modified_docker_tag"

if (Test-Path -Path shinyproxy/admin_users.txt) {
  Write-Host "Using existing shinyproxy/admin_users.txt file"
}
else {
  Write-Host "Creating example shinyproxy/admin_users.txt for shinyproxy"
  Add-Content -Path shinyproxy/admin_users.txt -Value @("admin1", "admin2")
}

if (Test-Path -Path shinyproxy/regular_users.txt) {
  Write-Host "Using existing shinyproxy/regular_users.txt file"
}
else {
  Write-Host "Creating example shinyproxy/regular_users.txt for shinyproxy"
  Add-Content -Path shinyproxy/regular_users.txt -Value @("user1", "user2", "user3")
}

# Run shinyproxy stack
docker compose -f "compose.shinyproxy.yml" build --no-cache
docker compose -f "compose.shinyproxy.yml" -p "shinyproxy-stack" up --remove-orphans -d

# Delete .env.modified_docker_tag
Remove-Item .env.modified_docker_tag -Force

# Check if it necessery to create a local database
if ($env:DOCKER_CREATE_DATABASE -eq "false") {
  Write-Host "No need to start a local database."
  exit 0
}

# Run database stack only with the required database container
docker compose -f "compose.database.yml" build
docker compose -f "compose.database.yml" -p "database-stack" --profile $db_container up --remove-orphans -d $db_container

# Wait till database container is ready
while (-Not (docker inspect --format='{{.State.Health.Status}}' $db_container | Select-String -Quiet -SimpleMatch -Pattern "healthy") ) {
  Write-Host "Waiting for database container... ($retries)"
  Start-Sleep -Seconds 6
  $retries--

  if ($retries -eq 0) {
    Write-Host "Database container did not start up."
    exit 1
  }
}

Write-Host "Database container ready."

Write-Host "Restoring database..."
# Restore backup in mssql
if ($db_container -eq "mssql") {
  $database_restore_query = "RESTORE DATABASE $db_name FROM DISK='/opt/backup/$db_name.bak' WITH MOVE '$db_name' TO '/var/opt/mssql/data/$db_name.mdf', MOVE '$($db_name)_log' TO '/var/opt/mssql/data/$db_name.ldf'"
  docker exec $db_container /opt/mssql-tools/bin/sqlcmd -U $db_user -P $db_password -Q $database_restore_query
}

# Restore backup in PSQL
if ($db_container -eq "postgres") {
  docker exec $db_container createdb $db_name -U $db_user
  docker exec $db_container pg_restore -U $db_user --dbname $db_name --verbose --no-password /opt/backup/$db_name.tar
}

