#!/usr/bin/env bash
# scripts/run_migrations.sh
# Runs PostgreSQL migrations using the official golang-migrate Docker container.
#
# Usage:
#   ./scripts/run_migrations.sh [up|down|version]
#
# Environment variables:
#   DB_HOST         PostgreSQL host (default: localhost)
#   DB_PORT         PostgreSQL port (default: 5432)
#   DB_USER         PostgreSQL user (default: lokalaku)
#   DB_PASSWORD     PostgreSQL password (default: lokalaku_dev_pass)
#   DB_NAME         PostgreSQL database (default: lokalaku)
#   DB_SSLMODE      SSL mode (default: disable)
#   MIGRATIONS_DIR  Path to migrations directory (default: ./apps/api/migrations)

set -euo pipefail

ACTION="${1:-up}"
DB_HOST="${DB_HOST:-localhost}"
DB_PORT="${DB_PORT:-5432}"
DB_USER="${DB_USER:-lokalaku}"
DB_PASSWORD="${DB_PASSWORD:-lokalaku_dev_pass}"
DB_NAME="${DB_NAME:-lokalaku}"
DB_SSLMODE="${DB_SSLMODE:-disable}"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MIGRATIONS_DIR="${MIGRATIONS_DIR:-${REPO_ROOT}/apps/api/migrations}"

if [ ! -d "${MIGRATIONS_DIR}" ]; then
  echo "❌ Error: Migrations directory not found at ${MIGRATIONS_DIR}" >&2
  exit 1
fi

DATABASE_URL="postgres://${DB_USER}:${DB_PASSWORD}@${DB_HOST}:${DB_PORT}/${DB_NAME}?sslmode=${DB_SSLMODE}"

echo "🔄 Running migrations [${ACTION}] against ${DB_HOST}:${DB_PORT}/${DB_NAME}..."

# If running against localhost from host machine, use host network mode
NETWORK_ARG="--net=host"
if [ "${DB_HOST}" != "localhost" ] && [ "${DB_HOST}" != "127.0.0.1" ]; then
  NETWORK_ARG=""
fi

docker run --rm \
  ${NETWORK_ARG} \
  -v "${MIGRATIONS_DIR}:/migrations:ro" \
  migrate/migrate:v4.17.0 \
  -path=/migrations \
  -database "${DATABASE_URL}" \
  "${ACTION}"

echo "✅ Migrations completed successfully."
