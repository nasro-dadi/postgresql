# PostgreSQL Docker Compose Setup

A product| Variable               | Description              | Default                |
| ---------------------- | ------------------------ | ---------------------- |
| `POSTGRES_DB`          | Database name            | `myapp`                |
| `POSTGRES_USER`        | Database user            | `postgres`             |
| `POSTGRES_PASSWORD`    | Database password        | **Required**           |
| `POSTGRES_PORT`        | Database port            | `5432`                 |
| `PGADMIN_EMAIL`        | PgAdmin login email      | `admin@example.com`    |
| `PGADMIN_PASSWORD`     | PgAdmin password         | **Required**           |
| `PGADMIN_PORT`         | PgAdmin web port         | `8080`                 |
| `BACKUP_RETENTION_DAYS`| Backup retention period  | `7`                    |
| `BACKUP_SCHEDULE`      | Cron schedule for backups| `"35 10 * * *"` (10:35 AM)| PostgreSQL setup with Docker Compose, featuring security best practices, automated backups, and PgAdmin for database management.

## Features

- **PostgreSQL 16 Alpine** - Latest stable version with minimal footprint
- **PgAdmin 4** - Web-based administration tool
- **Automated Backups** - Scheduled backup scripts with compression
- **Health Checks** - Container health monitoring
- **Security** - Environment-based configuration
- **Performance Tuning** - Optimized PostgreSQL configuration
- **Volume Persistence** - Data persists across container restarts

## Quick Start

1. **Initial Setup**

   ```bash
   ./manage.sh setup
   ```

2. **Edit Environment Variables**

   ```bash
   nano .env
   ```

   Update the passwords and configuration as needed.

3. **Start Services**

   ```bash
   ./manage.sh start
   ```

4. **Access Services**
   - PostgreSQL: `localhost:5432`
   - PgAdmin: `http://localhost:8080`

## Environment Variables

Copy `.env.example` to `.env` and configure:

| Variable            | Description         | Default             |
| ------------------- | ------------------- | ------------------- |
| `POSTGRES_DB`       | Database name       | `myapp`             |
| `POSTGRES_USER`     | Database user       | `postgres`          |
| `POSTGRES_PASSWORD` | Database password   | **Required**        |
| `POSTGRES_PORT`     | Database port       | `5432`              |
| `PGADMIN_EMAIL`     | PgAdmin login email | `admin@example.com` |
| `PGADMIN_PASSWORD`  | PgAdmin password    | **Required**        |
| `PGADMIN_PORT`      | PgAdmin web port    | `8080`              |

## Management Commands

Use the `manage.sh` script for easy management:

```bash
./manage.sh start      # Start all services
./manage.sh stop       # Stop all services
./manage.sh restart    # Restart all services
./manage.sh status     # Show service status
./manage.sh logs       # Show PostgreSQL logs
./manage.sh backup     # Create database backup
./manage.sh scheduler  # Show backup scheduler logs
./manage.sh restore    # Restore from backup
./manage.sh psql       # Connect to PostgreSQL CLI
./manage.sh reset      # Reset all data (DANGEROUS!)
./manage.sh setup      # Initial setup
```

## Database Initialization

The `init/` directory contains SQL scripts that run when the database is first created:

- `01-init.sql` - Creates extensions, sample tables, and initial data

Add your own initialization scripts here (they'll run in alphabetical order).

## Backup and Restore

### Automated Backup Scheduler

The setup includes an automated backup scheduler that runs inside a Docker container:

```bash
# The backup scheduler runs automatically based on BACKUP_SCHEDULE in .env
# Default: "35 10 * * *" (Daily at 10:35 AM)

# View scheduler logs
./manage.sh scheduler

# Check backup logs
cat backups/backup.log
```

### Manual Backups

```bash
# Create a manual backup
./manage.sh backup

# The backup script creates compressed backups in ./backups/
# Old backups are automatically cleaned up (7 days retention by default)
```

### Restore from Backup

```bash
# List available backups
ls -la backups/

# Restore from a specific backup
./manage.sh restore backup_myapp_20231122_143000.sql.gz
```

## Performance Configuration

The PostgreSQL container includes optimized settings:

- **Connections**: Up to 200 concurrent connections
- **Memory**: Optimized buffer and cache settings
- **WAL**: Configured for better write performance
- **Statistics**: Enhanced query planning with pg_stat_statements

## Security Best Practices

- ✅ Environment-based secrets management
- ✅ No hardcoded passwords in configuration
- ✅ Isolated Docker network
- ✅ Non-root user execution
- ✅ Health checks for reliability
- ✅ Minimal Alpine-based images

## Directory Structure

```
postgresql/
├── docker-compose.yml      # Main Docker Compose configuration
├── .env.example           # Environment variables template
├── .env                   # Your environment variables (create from .env.example)
├── manage.sh              # Management script
├── init/                  # Database initialization scripts
│   └── 01-init.sql
├── scripts/               # Backup and restore scripts
│   ├── backup.sh
│   └── restore.sh
├── pgadmin/               # PgAdmin configuration
│   └── servers.json
├── backups/               # Database backups (auto-created)
└── README.md              # This file
```

## Troubleshooting

### Container Won't Start

```bash
# Check logs
./manage.sh logs

# Check if ports are available
sudo netstat -tlnp | grep :5432
sudo netstat -tlnp | grep :8080
```

### Permission Issues

```bash
# Make scripts executable
chmod +x manage.sh scripts/*.sh
```

### Database Connection Issues

```bash
# Test connection
./manage.sh psql

# Check if container is healthy
docker ps
./manage.sh status
```

### PgAdmin Access Issues

1. Ensure the container is healthy: `./manage.sh status`
2. Check if port 8080 is available
3. Verify PGADMIN_EMAIL and PGADMIN_PASSWORD in `.env`

## Production Deployment

For production use:

1. **Change default passwords** in `.env`
2. **Configure SSL/TLS** for encrypted connections
3. **Set up regular backups** with cron jobs
4. **Monitor disk space** for data volume
5. **Configure firewall** to restrict access
6. **Use secrets management** instead of .env files
7. **Enable logging** and monitoring

## Contributing

Feel free to submit issues and enhancement requests!

## License

This project is licensed under the MIT License.
