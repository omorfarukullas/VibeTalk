-- ============================================================
-- Migration 007: Create groups table
-- VibeTalk — Sprint 0
-- ============================================================

CREATE TABLE groups (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id         UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    name            VARCHAR(100) NOT NULL,
    avatar_url      TEXT,
    invite_link     TEXT UNIQUE,
    created_by      UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

-- Index for looking up group by chat
CREATE UNIQUE INDEX idx_groups_chat_id ON groups (chat_id);

-- Index for invite link lookup
CREATE UNIQUE INDEX idx_groups_invite_link ON groups (invite_link)
    WHERE invite_link IS NOT NULL;

-- Index for finding groups created by a specific user
CREATE INDEX idx_groups_created_by ON groups (created_by);
