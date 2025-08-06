#!/bin/bash

# Script to generate secret files from environment variables

set -e

# Source the .env file
if [ -f "/tmp/.env" ]; then
    source /tmp/.env
elif [ -f "./srcs/.env" ]; then
    source ./srcs/.env
elif [ -f ".env" ]; then
    source .env
else
    echo "Error: .env file not found"
    exit 1
fi

# Create secrets directory
mkdir -p ./secrets

# Generate secret files from environment variables
echo "$MYSQL_ROOT_PASSWORD" > ./secrets/db_root_password.txt
echo "$MYSQL_PASSWORD" > ./secrets/db_password.txt

echo "Secret files generated from .env variables"
