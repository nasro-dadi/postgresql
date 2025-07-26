#!/bin/bash

# Scheduler script for automated backups using a simple loop
# This script runs inside a Docker container and executes backups based on BACKUP_SCHEDULE

set -e

# Load environment variables
if [ -f /app/.env ]; then
    set -a
    source /app/.env
    set +a
fi

# Default schedule if not set (format: "minute hour * * *")
BACKUP_SCHEDULE=${BACKUP_SCHEDULE:-"0 2 * * *"}

echo "Starting backup scheduler with schedule: $BACKUP_SCHEDULE"

# Parse the cron schedule to get minute and hour
MINUTE=$(echo $BACKUP_SCHEDULE | cut -d' ' -f1)
HOUR=$(echo $BACKUP_SCHEDULE | cut -d' ' -f2)

echo "Scheduled backup time: ${HOUR}:$(printf '%02d' $MINUTE)"

# Function to run backup
run_backup() {
    echo "$(date): Running scheduled backup..."
    /app/scripts/backup-docker.sh
    echo "$(date): Backup completed"
}

# Main scheduler loop
while true; do
    current_hour=$(date +'%H')
    current_minute=$(date +'%M')
    
    # Remove leading zeros for comparison
    current_hour=$((10#$current_hour))
    current_minute=$((10#$current_minute))
    target_hour=$((10#$HOUR))
    target_minute=$((10#$MINUTE))
    
    if [ $current_hour -eq $target_hour ] && [ $current_minute -eq $target_minute ]; then
        run_backup
        # Sleep for 61 seconds to avoid running multiple times in the same minute
        sleep 61
    else
        # Check every 30 seconds
        sleep 30
    fi
done
