#!/bin/sh
set -eu

BACKUP_DIR="${BACKUP_DIR:-/backups}"
MINIO_ALIAS="${MINIO_ALIAS:-minio}"
MINIO_BUCKET="${MINIO_BUCKET:-mlflow}"
MINIO_URL="${MINIO_URL:-http://minio:9000}"

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
  BACKUP_FILE="$(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'minio_mlflow_*.tar.gz' | sort | tail -n 1)"

  if [ -z "$BACKUP_FILE" ]; then
    echo "No MinIO backup found in $BACKUP_DIR" >&2
    exit 1
  fi
fi

WORKDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

echo "Restoring backup: $BACKUP_FILE"

mkdir -p "$WORKDIR"
tar -xzf "$BACKUP_FILE" -C "$WORKDIR"

mc alias set "$MINIO_ALIAS" "$MINIO_URL" "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY"
mc mb --ignore-existing "$MINIO_ALIAS/$MINIO_BUCKET"
mc mirror --overwrite --remove "$WORKDIR/$MINIO_BUCKET" "$MINIO_ALIAS/$MINIO_BUCKET"

echo "Restore completed."
