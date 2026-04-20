#!/bin/sh
set -eu

BACKUP_DIR="${BACKUP_DIR:-/backups}"
DB_HOST="${DB_HOST:-db}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${POSTGRES_USER:?POSTGRES_USER is not set}"
DB_NAME="${POSTGRES_DB:?POSTGRES_DB is not set}"

if [ "$#" -gt 0 ] && [ -n "${1:-}" ]; then
  BACKUP_FILE="$1"
  case "$BACKUP_FILE" in
    /*) ;;
    *) BACKUP_FILE="$BACKUP_DIR/$BACKUP_FILE" ;;
  esac

  if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup file not found: $BACKUP_FILE" >&2
    exit 1
  fi
else
  BACKUP_FILE="$(find "$BACKUP_DIR" -maxdepth 1 -type f -name '*.dump' | sort | tail -n 1)"

  if [ -z "$BACKUP_FILE" ]; then
    echo "No .dump backup found in $BACKUP_DIR" >&2
    exit 1
  fi
fi

echo "Restoring backup: $BACKUP_FILE"
pg_restore -h "$DB_HOST" -p "$DB_PORT" -U "$DB_USER" -d "$DB_NAME" \
  --clean --if-exists "$BACKUP_FILE"

echo "Restore completed."
