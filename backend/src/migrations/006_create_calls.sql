-- ============================================================
-- Migration 006: Create calls table
-- VibeTalk — Sprint 0
-- ============================================================

-- Call type enum
CREATE TYPE call_type AS ENUM ('voice', 'video');

-- Call status enum
CREATE TYPE call_status AS ENUM ('initiated', 'ongoing', 'ended', 'missed', 'rejected');

CREATE TABLE calls (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id         UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    caller_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    call_type       call_type NOT NULL,
    status          call_status NOT NULL DEFAULT 'initiated',
    started_at      TIMESTAMPTZ,
    ended_at        TIMESTAMPTZ
);

-- Index for fetching calls by chat
CREATE INDEX idx_calls_chat_id ON calls (chat_id);

-- Index for fetching calls by caller
CREATE INDEX idx_calls_caller_id ON calls (caller_id);

-- Index for active calls lookup
CREATE INDEX idx_calls_active ON calls (status)
    WHERE status IN ('initiated', 'ongoing');

-- Index for call history (most recent first)
CREATE INDEX idx_calls_started_at ON calls (started_at DESC NULLS LAST);
