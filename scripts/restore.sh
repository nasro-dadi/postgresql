#!/bin/bash

# PostgreSQL Restore Script
# This script restores a PostgreSQL database from a backup file

set -e
set -o pipefail

# Load environment variables safely
if [ -f .env ]; then
    set -a
    source .env
    set +a
fi

# Configuration
CONTAINER_NAME="postgres_db"
BACKUP_DIR="./backups"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to show usage
show_usage() {
    echo "Usage: $0 <backup_file>"
    echo "Example: $0 backup_myapp_20231122_143000.sql.gz"
    echo ""
    echo "Available backups:"
    ls -la "$BACKUP_DIR"/*.sql.gz 2>/dev/null || echo "No backup files found"
}

# Check if backup file is provided
if [ $# -eq 0 ]; then
    echo -e "${RED}Error: No backup file specified${NC}"
    show_usage
    exit 1
fi

BACKUP_FILE="$1"

# Check if backup file exists
if [ ! -f "$BACKUP_DIR/$BACKUP_FILE" ]; then
    echo -e "${RED}Error: Backup file not found: $BACKUP_DIR/$BACKUP_FILE${NC}"
    show_usage
    exit 1
fi

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}Error: PostgreSQL container is not running${NC}"
    exit 1
fi

echo -e "${YELLOW}Starting PostgreSQL restore...${NC}"
echo -e "${YELLOW}Backup file: $BACKUP_DIR/$BACKUP_FILE${NC}"
echo -e "${YELLOW}Target database: ${POSTGRES_DB}${NC}"

# Confirm restoration
read -p "Are you sure you want to restore? This will overwrite the current database. (y/N): " -n 1 -r
echo
if [[ ! $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}Restore cancelled${NC}"
    exit 0
fi

echo -e "${YELLOW}Dropping and recreating database...${NC}"
# Drop the database and recreate it
docker exec -i "$CONTAINER_NAME" env PGPASSWORD="$POSTGRES_PASSWORD" psql -U "$POSTGRES_USER" -d postgres -c "DROP DATABASE IF EXISTS \"$POSTGRES_DB\";"
docker exec -i "$CONTAINER_NAME" env PGPASSWORD="$POSTGRES_PASSWORD" psql -U "$POSTGRES_USER" -d postgres -c "CREATE DATABASE \"$POSTGRES_DB\";"

# Decompress if needed and restore
if [[ $BACKUP_FILE == *.gz ]]; then
    echo -e "${YELLOW}Decompressing and restoring backup...${NC}"
    # Use a subshell to isolate the pipeline and ensure we capture the exit code of docker exec (not gunzip),
    # since in a pipeline only the exit code of the last command is returned by default.
    (
        gunzip -c "$BACKUP_DIR/$BACKUP_FILE" | docker exec -i "$CONTAINER_NAME" env PGPASSWORD="$POSTGRES_PASSWORD" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
    )
    RESTORE_EXIT_CODE=$?
else
    echo -e "${YELLOW}Restoring backup...${NC}"
    # Use environment variable for secure authentication instead of .pgpass file
    docker exec -i "$CONTAINER_NAME" env PGPASSWORD="$POSTGRES_PASSWORD" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB" < "$BACKUP_DIR/$BACKUP_FILE"
    RESTORE_EXIT_CODE=$?
fi

if [ $RESTORE_EXIT_CODE -eq 0 ]; then
    echo -e "${GREEN}Database restored successfully!${NC}"
else
    echo -e "${RED}Restore failed!${NC}"
    exit 1
fi
