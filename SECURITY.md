# Security Configuration Guide

## 🔐 Security Best Practices Implemented

### 1. Password Security

- **CRITICAL**: Change default passwords in `.env` file
- Use strong, unique passwords (minimum 16 characters)
- Consider using password managers or secret management tools

### 2. Network Security

- PostgreSQL and PgAdmin bound to localhost only (`127.0.0.1`)
- Prevents external network access by default
- Uses isolated Docker network for inter-service communication

### 3. SSL/TLS Encryption

- SSL certificates generated for encrypted connections
- Run `./manage.sh ssl` to generate certificates
- PostgreSQL configured to use SSL by default

### 4. Container Security

- PostgreSQL runs as non-root user (postgres:postgres)
- Read-only mounts for initialization scripts
- Minimal Alpine-based images for reduced attack surface

### 5. Logging & Monitoring

- Comprehensive PostgreSQL logging enabled
- Connection, disconnection, and query logging
- Lock waits and checkpoint logging for monitoring

### 6. Data Protection

- Environment files excluded from version control
- SSL certificates excluded from git repository
- Backup validation and secure cleanup

## 🚨 Production Security Checklist

### Before Production Deployment:

1. **Change ALL default passwords**

   ```bash
   # Generate strong passwords
   openssl rand -base64 32  # For PostgreSQL
   openssl rand -base64 32  # For PgAdmin
   ```

2. **Review and update `.env` file**

   - Use strong, unique passwords
   - Consider using Docker secrets or external secret management

3. **SSL Certificate Management**

   ```bash
   # Generate production SSL certificates
   ./manage.sh ssl
   ```

4. **Network Security**

   - Review port bindings for production
   - Consider using reverse proxy (nginx/traefik)
   - Implement firewall rules

5. **Remove demo data**

   - Delete sample users table from `init/01-init.sql`
   - Remove test data

6. **Backup Strategy**

   - Set up automated backups
   - Test restore procedures
   - Configure off-site backup storage

7. **Monitoring**
   - Set up log aggregation
   - Configure alerting for failed connections
   - Monitor disk usage and performance

### Production Environment Variables

```bash
# Example production .env (customize for your environment)
POSTGRES_DB=production_db
POSTGRES_USER=app_user
POSTGRES_PASSWORD=your_very_strong_password_here
POSTGRES_PORT=5432

PGADMIN_EMAIL=admin@yourdomain.com
PGADMIN_PASSWORD=another_strong_password_here
PGADMIN_PORT=8080

BACKUP_RETENTION_DAYS=30
```

### Security Considerations

1. **Database User Privileges**

   - Create application-specific database users
   - Grant minimal required privileges
   - Avoid using superuser for applications

2. **Connection Security**

   - Use SSL for all connections
   - Consider connection pooling (PgBouncer)
   - Implement connection rate limiting

3. **Regular Updates**

   - Keep PostgreSQL image updated
   - Monitor security advisories
   - Test updates in staging environment

4. **Backup Security**
   - Encrypt backup files
   - Secure backup storage location
   - Test backup restoration regularly

## 🛡️ Security Commands

```bash
# Generate SSL certificates
./manage.sh ssl

# Check container security
docker run --rm -v /var/run/docker.sock:/var/run/docker.sock aquasec/trivy image postgres:16-alpine

# Backup with verification
./manage.sh backup

# Monitor connections
./manage.sh logs | grep "connection"
```
