#!/bin/bash

# Docker-optimized PostgreSQL Backup Script
# This script runs inside the scheduler container and creates backups

set -e
set -o pipefail

# Load environment variables
if [ -f /app/.env ]; then
    set -a
    source /app/.env
    set +a
fi

# Configuration
CONTAINER_NAME="postgres_db"
BACKUP_DIR="/app/backups"
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
    real_base="$(realpath /app/backups)"
    [[ -n "$dir" && "$dir" != "/" && "$dir" != "." && "$dir" != ".." && "$dir" != "~" && "$dir" != "$HOME" && "$real_dir" == "$real_base"* ]]
}

echo "$(date): Starting PostgreSQL backup..." >> /app/backups/backup.log

# Check if container is running
if ! docker ps | grep -q "$CONTAINER_NAME"; then
    echo "$(date): Error: PostgreSQL container is not running" >> /app/backups/backup.log
    exit 1
fi

# Create backup directory if it doesn't exist
mkdir -p "$BACKUP_DIR"

# Create backup
echo "$(date): Creating backup of database: ${POSTGRES_DB}" >> /app/backups/backup.log

# Create a temporary .pgpass file for secure authentication
PGPASS_CONTENT="${POSTGRES_HOST:-localhost}:5432:${POSTGRES_DB}:${POSTGRES_USER}:${POSTGRES_PASSWORD}"
docker exec "$CONTAINER_NAME" bash -c "echo '$PGPASS_CONTENT' > /tmp/.pgpass && chmod 600 /tmp/.pgpass && PGPASSFILE=/tmp/.pgpass pg_dump -U '${POSTGRES_USER}' -d '${POSTGRES_DB}' && rm /tmp/.pgpass" > "$BACKUP_FILE" 2> "${BACKUP_FILE}.err"
BACKUP_EXIT_CODE=$?

if [ $BACKUP_EXIT_CODE -ne 0 ]; then
    echo "$(date): Backup failed! See error log: ${BACKUP_FILE}.err" >> /app/backups/backup.log
    exit 1
fi

echo "$(date): Backup created successfully: $BACKUP_FILE" >> /app/backups/backup.log

# Compress backup
gzip "$BACKUP_FILE"
echo "$(date): Backup compressed: $COMPRESSED_BACKUP" >> /app/backups/backup.log

# Remove old backups (keep last 7 days by default)
echo "$(date): Cleaning up old backups (older than ${RETENTION_DAYS} days)..." >> /app/backups/backup.log

# Validate BACKUP_DIR before deleting
if validate_backup_dir "$BACKUP_DIR"; then
    find "$BACKUP_DIR" -name "backup_*.sql.gz" -mtime "+$RETENTION_DAYS" -delete
    echo "$(date): Old backups cleaned up successfully" >> /app/backups/backup.log
else
    echo "$(date): Error: BACKUP_DIR is not set correctly or is unsafe. Skipping deletion." >> /app/backups/backup.log
fi

echo "$(date): Backup process completed successfully!" >> /app/backups/backup.log
