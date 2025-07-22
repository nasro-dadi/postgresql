#!/bin/bash

# SSL Certificate Generation Script for PostgreSQL
# This script generates self-signed SSL certificates for PostgreSQL

set -e

CERT_DIR="./ssl"
CONTAINER_NAME="postgres_db"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Generating SSL certificates for PostgreSQL...${NC}"

# Create SSL directory
mkdir -p "$CERT_DIR"

# Generate private key
openssl genrsa -out "$CERT_DIR/server.key" 2048

# Generate certificate
openssl req -new -x509 -key "$CERT_DIR/server.key" -out "$CERT_DIR/server.crt" -days 365 \
  -subj "/C=US/ST=State/L=City/O=Organization/CN=postgres"

# Set proper permissions
chmod 600 "$CERT_DIR/server.key"
chmod 644 "$CERT_DIR/server.crt"

# Copy certificates to running container if it exists
if docker ps | grep -q "$CONTAINER_NAME"; then
    echo -e "${YELLOW}Copying certificates to running container...${NC}"
    docker cp "$CERT_DIR/server.key" "$CONTAINER_NAME:/var/lib/postgresql/server.key"
    docker cp "$CERT_DIR/server.crt" "$CONTAINER_NAME:/var/lib/postgresql/server.crt"
    docker exec "$CONTAINER_NAME" chown postgres:postgres /var/lib/postgresql/server.key /var/lib/postgresql/server.crt
    docker exec "$CONTAINER_NAME" chmod 600 /var/lib/postgresql/server.key
    docker exec "$CONTAINER_NAME" chmod 644 /var/lib/postgresql/server.crt
    
    echo -e "${GREEN}SSL certificates generated and installed successfully!${NC}"
    echo -e "${YELLOW}Note: You may need to restart PostgreSQL to use SSL.${NC}"
else
    echo -e "${GREEN}SSL certificates generated successfully!${NC}"
    echo -e "${YELLOW}Certificates will be copied to container on next startup.${NC}"
fi
