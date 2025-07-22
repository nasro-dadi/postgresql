#!/bin/bash

# PostgreSQL Backup Script
# This script creates a backup of the PostgreSQL database

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
DATE=$(date +"%Y%m%d_%H%M%S")
BACKUP_FILE="${BACKUP_DIR}/backup_${POSTGRES_DB}_${DATE}.sql"
COMPRESSED_BACKUP="${BACKUP_FILE}.gz"
RETENTION_DAYS=${BACKUP_RETENTION_DAYS:-7}

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to validate BACKUP_DIR
validate_backup_dir() {
    local dir="$1"
    local real_dir
    real_dir="$(realpath "$dir")"
    local real_base
    real_base="$(realpath ./backups)"
    [[ -n "$dir" && "$dir" != "/" && "$dir" != "." && "$dir" != ".." && "$dir" != "~" && "$dir" != "$HOME" && "$real_dir" == "$real_base"* ]]
}

echo -e "${YELLOW}Starting PostgreSQL backup...${NC}"

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${RED}Error: PostgreSQL container is not running${NC}"
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create backup
echo -e "${YELLOW}Creating backup of database: ${POSTGRES_DB}${NC}"
# Create a temporary .pgpass file for secure authentication
PGPASS_CONTENT="${POSTGRES_HOST:-localhost}:5432:${POSTGRES_DB}:${POSTGRES_USER}:${POSTGRES_PASSWORD}"
docker exec "$CONTAINER_NAME" bash -c "echo '$PGPASS_CONTENT' > /tmp/.pgpass && chmod 600 /tmp/.pgpass && PGPASSFILE=/tmp/.pgpass pg_dump -U '${POSTGRES_USER}' -d '${POSTGRES_DB}' && rm /tmp/.pgpass" > "$BACKUP_FILE" 2> "${BACKUP_FILE}.err"
BACKUP_EXIT_CODE=$?

if [ $BACKUP_EXIT_CODE -ne 0 ]; then
    echo -e "${RED}Backup failed! See error log: ${BACKUP_FILE}.err${NC}"
    cat "${BACKUP_FILE}.err"
    rm -f "$BACKUP_FILE"
    exit 1
fi

echo -e "${GREEN}Backup created successfully: $BACKUP_FILE${NC}"

# Compress backup
echo -e "${YELLOW}Compressing backup...${NC}"
gzip "$BACKUP_FILE"
echo -e "${GREEN}Backup compressed: $COMPRESSED_BACKUP${NC}"

# Remove old backups (keep last 7 days by default)
echo -e "${YELLOW}Cleaning up old backups (older than ${RETENTION_DAYS} days)...${NC}"
# Validate BACKUP_DIR before deleting
if validate_backup_dir "$BACKUP_DIR"; then
    find "$BACKUP_DIR" -name "backup_*.sql.gz" -mtime "+$RETENTION_DAYS" -delete
else
    echo -e "${RED}Error: BACKUP_DIR is not set correctly or is unsafe. Skipping deletion.${NC}"
fi
echo -e "${GREEN}Backup process completed successfully!${NC}"
