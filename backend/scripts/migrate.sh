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
-- Migration: 20260715_add_firebase_auth_fields
-- Adds email and firebaseUid columns to User table
-- ============================================================
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "email" TEXT;
ALTER TABLE "User" ADD COLUMN IF NOT EXISTS "firebaseUid" TEXT;

CREATE UNIQUE INDEX IF NOT EXISTS "User_email_key" ON "User"("email");
CREATE UNIQUE INDEX IF NOT EXISTS "User_firebaseUid_key" ON "User"("firebaseUid");

SQL

echo ""
echo "✅ All migrations applied successfully!"
echo ""
echo "Verifying schema..."
psql "$DB_URL" -c "\d \"User\"" 2>/dev/null | grep -E "email|firebaseUid|username" || echo "(columns listed above)"
