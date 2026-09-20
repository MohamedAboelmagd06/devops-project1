#!/bin/bash
set -e

BACKUP_ROOT="/home/ubuntu/devops-project1/backups"
TIMESTAMP=$(date +%Y%m%d_%H%M%S)
DB_CONTAINER="postgresql-dev"
DB_NAME="db-dev"
DB_USER="postgres"
VOLUME_DIR="/home/ubuntu/devops-project1/postgresql_volume"
RETENTION_DAYS=7

mkdir -p "$BACKUP_ROOT"

echo "[$(date)] Starting backup..."

# 1. PostgreSQL logical backup (pg_dump) - safe to run while DB is live
DB_BACKUP_FILE="$BACKUP_ROOT/db_${TIMESTAMP}.sql.gz"
docker exec "$DB_CONTAINER" pg_dump -U "$DB_USER" "$DB_NAME" | gzip > "$DB_BACKUP_FILE"
echo "[$(date)] Database backup saved: $DB_BACKUP_FILE"

# 2. Data directory (volume) backup - filesystem-level snapshot
VOLUME_BACKUP_FILE="$BACKUP_ROOT/volume_${TIMESTAMP}.tar.gz"
sudo tar -czf "$VOLUME_BACKUP_FILE" -C "$(dirname "$VOLUME_DIR")" "$(basename "$VOLUME_DIR")"
echo "[$(date)] Volume backup saved: $VOLUME_BACKUP_FILE"

# 3. Retention: delete backups older than N days
find "$BACKUP_ROOT" -name "*.sql.gz" -mtime +$RETENTION_DAYS -delete
find "$BACKUP_ROOT" -name "*.tar.gz" -mtime +$RETENTION_DAYS -delete
echo "[$(date)] Old backups older than $RETENTION_DAYS days removed."

echo "[$(date)] Backup completed successfully."
