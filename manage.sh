#!/bin/bash

# PostgreSQL Docker Management Script
# This script provides easy commands to manage your PostgreSQL Docker setup

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Function to show usage
show_usage() {
    echo -e "${BLUE}PostgreSQL Docker Management Script${NC}"
    echo ""
    echo "Usage: $0 [command]"
    echo ""
    echo "Commands:"
    echo "  start      - Start PostgreSQL services"
    echo "  stop       - Stop PostgreSQL services"
    echo "  restart    - Restart PostgreSQL services"
    echo "  status     - Show status of services"
    echo "  logs       - Show logs for PostgreSQL"
    echo "  backup     - Create a database backup"
    echo "  restore    - Restore from a backup file"
    echo "  psql       - Connect to PostgreSQL CLI"
    echo "  ssl        - Generate SSL certificates"
    echo "  reset      - Reset all data (DANGEROUS!)"
    echo "  setup      - Initial setup with environment file"
    echo ""
}

# Function to check if .env file exists
check_env() {
    if [ ! -f .env ]; then
        echo -e "${YELLOW}Warning: .env file not found. Creating from .env.example...${NC}"
        if [ -f .env.example ]; then
            cp .env.example .env
            chmod 600 .env
            echo -e "${YELLOW}Please edit .env file with your actual passwords before starting services.${NC}"
            return 1
        else
            echo -e "${RED}Error: .env.example file not found${NC}"
            exit 1
        fi
    fi
    return 0
}

# Function to make scripts executable
make_scripts_executable() {
    for script in scripts/*.sh; do
        [ -f "$script" ] && chmod +x "$script"
    done
}

case "$1" in
    "start")
        echo -e "${YELLOW}Starting PostgreSQL services...${NC}"
        check_env || exit 1
        make_scripts_executable
        docker compose up -d
        echo -e "${GREEN}Services started successfully!${NC}"
        echo -e "${BLUE}PostgreSQL is available on port 5432${NC}"
        echo -e "${BLUE}PgAdmin is available on http://localhost:8080${NC}"
        ;;
    "stop")
        echo -e "${YELLOW}Stopping PostgreSQL services...${NC}"
        docker compose down
        echo -e "${GREEN}Services stopped successfully!${NC}"
        ;;
    "restart")
        echo -e "${YELLOW}Restarting PostgreSQL services...${NC}"
        docker compose down
        docker compose up -d
        echo -e "${GREEN}Services restarted successfully!${NC}"
        ;;
    "status")
        echo -e "${BLUE}Service Status:${NC}"
        docker compose ps
        ;;
    "logs")
        echo -e "${BLUE}PostgreSQL Logs:${NC}"
        docker compose logs -f postgres
        ;;
    "backup")
        echo -e "${YELLOW}Creating backup...${NC}"
        ./scripts/backup.sh
        ;;
    "restore")
        echo -e "${YELLOW}Restoring from backup...${NC}"
        ./scripts/restore.sh "$2"
        ;;
    "ssl")
        echo -e "${YELLOW}Generating SSL certificates...${NC}"
        ./scripts/generate-ssl.sh
        ;;
    "psql")
        check_env || exit 1
        set -a
        source .env
        set +a
        echo -e "${BLUE}Connecting to PostgreSQL...${NC}"
        docker exec -it postgres_db env PGPASSWORD="$POSTGRES_PASSWORD" psql -U "$POSTGRES_USER" -d "$POSTGRES_DB"
        ;;
    "reset")
        echo -e "${RED}WARNING: This will delete all data!${NC}"
        read -p "Are you sure you want to reset all data? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo -e "${YELLOW}Resetting all data...${NC}"
            docker compose down -v --remove-orphans
            echo -e "${GREEN}All data has been reset!${NC}"
        else
            echo -e "${YELLOW}Reset cancelled${NC}"
        fi
        ;;
    "setup")
        echo -e "${BLUE}Setting up PostgreSQL environment...${NC}"
        if [ ! -f .env ]; then
            cp .env.example .env
            chmod 600 .env
            echo -e "${GREEN}.env file created from .env.example${NC}"
        fi
        make_scripts_executable
        echo -e "${YELLOW}Please edit .env file with your actual passwords:${NC}"
        echo -e "${BLUE}  - POSTGRES_PASSWORD${NC}"
        echo -e "${BLUE}  - PGADMIN_PASSWORD${NC}"
        echo ""
        echo -e "${YELLOW}Then run: $0 start${NC}"
        ;;
    *)
        show_usage
        ;;
esac
