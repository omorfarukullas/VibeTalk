-- ============================================================
-- Migration 003: Create chats and chat_participants tables
-- VibeTalk — Sprint 0
-- ============================================================

-- Chat type enum
CREATE TYPE chat_type AS ENUM ('direct', 'group');

-- Participant role enum
CREATE TYPE participant_role AS ENUM ('member', 'admin');

CREATE TABLE chats (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    type            chat_type NOT NULL DEFAULT 'direct',
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW()
);

CREATE TABLE chat_participants (
    chat_id         UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    user_id         UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    joined_at       TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    role            participant_role NOT NULL DEFAULT 'member',
    PRIMARY KEY (chat_id, user_id)
);

-- Index for fetching a user's chats
CREATE INDEX idx_chat_participants_user_id ON chat_participants (user_id);

-- Index for fetching chat members
CREATE INDEX idx_chat_participants_chat_id ON chat_participants (chat_id);

-- Index for chat type filtering
CREATE INDEX idx_chats_type ON chats (type);
