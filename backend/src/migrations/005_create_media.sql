-- ============================================================
-- Migration 005: Create media table
-- VibeTalk — Sprint 0
-- ============================================================

CREATE TABLE media (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    message_id      UUID NOT NULL REFERENCES messages(id) ON DELETE CASCADE,
    uploader_id     UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    file_url        TEXT NOT NULL,
    file_type       VARCHAR(50) NOT NULL,
    file_size       BIGINT NOT NULL,
    encrypted_key   TEXT NOT NULL,  -- encryption key for the file (E2EE)
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for fetching media by message
CREATE INDEX idx_media_message_id ON media (message_id);

-- Index for fetching uploads by user
CREATE INDEX idx_media_uploader_id ON media (uploader_id);

-- Index for file type filtering
CREATE INDEX idx_media_file_type ON media (file_type);
