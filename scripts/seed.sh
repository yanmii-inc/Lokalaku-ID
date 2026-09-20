#!/usr/bin/env bash
set -euo pipefail

# =============================================================================
# Lokalaku Database Migration & Seed Runner
# Usage:
#   ./scripts/seed.sh           # runs via docker compose or local psql
#   DATABASE_URL=postgres://... ./scripts/seed.sh
# =============================================================================

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
MIGRATION_FILE="${REPO_ROOT}/apps/api/migrations/000001_create_auth_tables.up.sql"
SEED_FILE="${REPO_ROOT}/scripts/seed_dev.sql"

echo "==> Lokalaku Database Seeder"

if [[ ! -f "${MIGRATION_FILE}" ]]; then
    echo "ERROR: Migration file not found at ${MIGRATION_FILE}" >&2
    exit 1
fi

if [[ ! -f "${SEED_FILE}" ]]; then
    echo "ERROR: Seed file not found at ${SEED_FILE}" >&2
    exit 1
fi

# Strategy 1: Explicit DATABASE_URL via local psql
if [[ -n "${DATABASE_URL:-}" ]] && command -v psql >/dev/null 2>&1; then
    echo "==> Running migrations via psql (DATABASE_URL)..."
    psql "${DATABASE_URL}" -f "${MIGRATION_FILE}"
    echo "==> Seeding development data via psql..."
    psql "${DATABASE_URL}" -f "${SEED_FILE}"
    echo "==> Database seeded successfully!"
    exit 0
fi

# Strategy 2: Local Docker Compose container
if command -v docker >/dev/null 2>&1; then
    COMPOSE_FILE="${REPO_ROOT}/docker-compose.dev.yml"
    if docker compose -f "${COMPOSE_FILE}" ps postgres --status running -q 2>/dev/null | grep -q .; then
        echo "==> Applying migrations to running Docker postgres container..."
        docker compose -f "${COMPOSE_FILE}" exec -T postgres psql -U "${POSTGRES_USER:-lokalaku}" -d "${POSTGRES_DB:-lokalaku}" < "${MIGRATION_FILE}"
        echo "==> Applying seed data to running Docker postgres container..."
        docker compose -f "${COMPOSE_FILE}" exec -T postgres psql -U "${POSTGRES_USER:-lokalaku}" -d "${POSTGRES_DB:-lokalaku}" < "${SEED_FILE}"
        echo "==> Database seeded successfully!"
        exit 0
    fi
fi

# Strategy 3: Standard localhost psql fallback
if command -v psql >/dev/null 2>&1; then
    export PGPASSWORD="${POSTGRES_PASSWORD:-lokalaku_dev_pass}"
    DB_HOST="${POSTGRES_HOST:-localhost}"
    DB_PORT="${POSTGRES_PORT:-5432}"
    DB_USER="${POSTGRES_USER:-lokalaku}"
    DB_NAME="${POSTGRES_DB:-lokalaku}"

    echo "==> Applying migrations to local PostgreSQL (${DB_HOST}:${DB_PORT}/${DB_NAME})..."
    psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${MIGRATION_FILE}"
    echo "==> Applying seed data..."
    psql -h "${DB_HOST}" -p "${DB_PORT}" -U "${DB_USER}" -d "${DB_NAME}" -f "${SEED_FILE}"
    echo "==> Database seeded successfully!"
    exit 0
fi

echo "ERROR: Neither running Docker postgres container nor local psql found." >&2
echo "Start the dev stack with: docker compose -f docker-compose.dev.yml up -d" >&2
exit 1
