#!/usr/bin/env bash

set -e

function read_users() {
  local file=$1
  local variable_name=$2
  
  # Read the file into an array
  mapfile -t users < $file

  # Collapse the array into a comma-separated string
  IFS=',' eval 'users_joined="${users[*]}"'

  # Export the string as an environment variable
  export $variable_name="$users_joined"
}

read_users admin_users.txt ADMIN_USERS
read_users regular_users.txt REGULAR_USERS

echo "ADMIN_USERS: $ADMIN_USERS"
echo "REGULAR_USERS: $REGULAR_USERS"

java -jar /opt/shinyproxy/shinyproxy.jar
