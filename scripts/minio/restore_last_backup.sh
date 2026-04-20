#!/bin/sh
set -eu

BACKUP_DIR="${BACKUP_DIR:-/backups}"
MINIO_ALIAS="${MINIO_ALIAS:-minio}"
MINIO_BUCKET="${MINIO_BUCKET:-mlflow}"
MINIO_URL="${MINIO_URL:-http://minio:9000}"

LAST_BACKUP="$(find "$BACKUP_DIR" -maxdepth 1 -type f -name 'minio_mlflow_*.tar.gz' | sort | tail -n 1)"

if [ -z "$LAST_BACKUP" ]; then
  echo "No MinIO backup found in $BACKUP_DIR" >&2
  exit 1
fi

WORKDIR="$(mktemp -d)"
cleanup() {
  rm -rf "$WORKDIR"
}
trap cleanup EXIT

echo "Restoring backup: $LAST_BACKUP"

mkdir -p "$WORKDIR"
tar -xzf "$LAST_BACKUP" -C "$WORKDIR"

mc alias set "$MINIO_ALIAS" "$MINIO_URL" "$AWS_ACCESS_KEY_ID" "$AWS_SECRET_ACCESS_KEY"
mc mb --ignore-existing "$MINIO_ALIAS/$MINIO_BUCKET"
mc mirror --overwrite --remove "$WORKDIR/$MINIO_BUCKET" "$MINIO_ALIAS/$MINIO_BUCKET"

echo "Restore completed."