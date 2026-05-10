-- ============================================================
-- Migration 009: Add username to users table
-- ============================================================

-- Enable pg_trgm for fast ILIKE searches
CREATE EXTENSION IF NOT EXISTS pg_trgm;

ALTER TABLE users
  ADD COLUMN username VARCHAR(30) UNIQUE;

-- Index for exact lookups
CREATE UNIQUE INDEX idx_users_username ON users (username);

-- Trigram index for partial/fuzzy search by username
CREATE INDEX idx_users_username_trgm ON users USING gin (username gin_trgm_ops);

-- Also add trigram index for name to speed up general search
CREATE INDEX idx_users_name_trgm ON users USING gin (name gin_trgm_ops);
