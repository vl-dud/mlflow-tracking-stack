#!/bin/sh
set -eu

BACKUP_DIR="${BACKUP_DIR:-/backups}"
DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${POSTGRES_USER:?POSTGRES_USER is not set}"
DB_NAME="${POSTGRES_DB:?POSTGRES_DB is not set}"

LAST_BACKUP="$(find "$BACKUP_DIR" -maxdepth 1 -type f -name '*.dump' | sort | tail -n 1)"

if [ -z "$LAST_BACKUP" ]; then
  echo "No .dump backup found in $BACKUP_DIR" >&2
  exit 1
fi

echo "Restoring backup: $LAST_BACKUP"
pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
  --clean --if-exists "$LAST_BACKUP"

echo "Restore completed."