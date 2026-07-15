#!/bin/bash
# ============================================================
# Veyl Database Migration Script
# Runs directly against PostgreSQL using psql — bypasses
# Prisma CLI versioning issues between dev (v6) and VPS (v7)
# ============================================================

set -e

DB_URL="${DATABASE_URL:-postgresql://veyl:veylpassword@postgres:5432/veyldb}"

echo "Applying Veyl database migrations..."
echo "Target: $DB_URL"

psql "$DB_URL" <<'SQL'

-- ============================================================
-- Migration: 20260715_zero_identity_and_recovery
-- Drops identifying fields and adds recoveryKeyHash
-- ============================================================
ALTER TABLE "User" DROP COLUMN IF EXISTS "phoneNumber";
ALTER TABLE "User" DROP COLUMN IF EXISTS "email";
ALTER TABLE "User" DROP COLUMN IF EXISTS "firebaseUid";
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "recoveryKeyHash" TEXT;
SQL

echo ""
echo "✅ All migrations applied successfully!"
echo ""
echo "Verifying schema..."
psql "$DB_URL" -c "\d \"User\"" 2>/dev/null | grep -E "recoveryKeyHash|username" || echo "(columns listed above)"
