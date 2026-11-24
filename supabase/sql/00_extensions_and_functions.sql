-- ============================================================================
-- 00_extensions_and_functions.sql
-- Extensions & helper functions for Supabase PostgreSQL
-- ============================================================================

-- Ensure pgcrypto is available for gen_random_uuid()
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

-- Trigger function to automatically update "updatedAt" on row modification
-- (Replaces Prisma's @updatedAt behavior at the database level)
CREATE OR REPLACE FUNCTION public.handle_updated_at()
RETURNS TRIGGER AS $$
BEGIN
    NEW."updatedAt" = CURRENT_TIMESTAMP;
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;
