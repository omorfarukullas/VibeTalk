-- ============================================================
-- Migration 001: Create users table
-- VibeTalk — Sprint 0
-- ============================================================

-- Custom enum for user status
CREATE TYPE user_status AS ENUM ('active', 'inactive', 'banned');

-- Enable UUID extension if not already enabled
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

CREATE TABLE users (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    email           VARCHAR(255) UNIQUE NOT NULL,
    firebase_uid    VARCHAR(128) UNIQUE NOT NULL,
    name            VARCHAR(100),
    avatar_url      TEXT,
    bio             TEXT,
    status          user_status NOT NULL DEFAULT 'active',
    last_seen       TIMESTAMPTZ,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    updated_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for email lookup (login flow)
CREATE INDEX idx_users_email ON users (email);
CREATE INDEX idx_users_firebase_uid ON users (firebase_uid);

-- Index for status filtering (admin panel)
CREATE INDEX idx_users_status ON users (status);

-- Auto-update updated_at on row modification
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER trigger_users_updated_at
    BEFORE UPDATE ON users
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();
