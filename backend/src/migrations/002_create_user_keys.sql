-- ============================================================
-- Migration 002: Create user_keys table (Signal Protocol)
-- VibeTalk — Sprint 0
-- ============================================================

CREATE TABLE user_keys (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    identity_key    TEXT NOT NULL,
    signed_prekey   TEXT NOT NULL,
    prekey_bundle   JSONB,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Each user should have exactly one active key set
CREATE UNIQUE INDEX idx_user_keys_user_id ON user_keys (user_id);

-- Index for fast key lookup during session establishment
CREATE INDEX idx_user_keys_created_at ON user_keys (created_at DESC);
