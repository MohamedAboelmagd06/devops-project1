#!/bin/bash
set -e

if [ -z "$1" ]; then
  echo "Usage: ./restore.sh <db_backup_file.sql.gz>"
  echo "Available backups:"
  ls -lh /home/ubuntu/devops-project1/backups/*.sql.gz 2>/dev/null
  exit 1
fi

BACKUP_FILE="$1"
DB_CONTAINER="postgresql-dev"
APP_CONTAINER="nestjs-app"
DB_NAME="db-dev"
DB_USER="postgres"

if [ ! -f "$BACKUP_FILE" ]; then
  echo "Error: backup file not found: $BACKUP_FILE"
  exit 1
fi

echo "[$(date)] Stopping app container to release database connections..."
docker stop "$APP_CONTAINER"

echo "[$(date)] Restoring $BACKUP_FILE into $DB_NAME..."
docker exec "$DB_CONTAINER" dropdb -U "$DB_USER" --if-exists "$DB_NAME"
docker exec "$DB_CONTAINER" createdb -U "$DB_USER" "$DB_NAME"
gunzip -c "$BACKUP_FILE" | docker exec -i "$DB_CONTAINER" psql -U "$DB_USER" "$DB_NAME"

echo "[$(date)] Restore completed. Restarting app container..."
docker start "$APP_CONTAINER"

echo "[$(date)] Restore completed successfully. App is back online."
