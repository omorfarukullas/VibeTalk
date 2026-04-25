-- ============================================================
-- Migration 004: Create messages table
-- VibeTalk — Sprint 0
-- ============================================================

-- Message type enum
CREATE TYPE message_type AS ENUM ('text', 'image', 'video', 'audio', 'document', 'emoji');

-- Message delivery status enum
CREATE TYPE message_status AS ENUM ('sent', 'delivered', 'read');

CREATE TABLE messages (
    id              UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    chat_id         UUID NOT NULL REFERENCES chats(id) ON DELETE CASCADE,
    sender_id       UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    content         TEXT NOT NULL,  -- stores ciphertext only, NEVER plaintext
    message_type    message_type NOT NULL DEFAULT 'text',
    status          message_status NOT NULL DEFAULT 'sent',
    reply_to_id     UUID REFERENCES messages(id) ON DELETE SET NULL,
    created_at      TIMESTAMPTZ NOT NULL DEFAULT NOW(),
    deleted_at      TIMESTAMPTZ  -- nullable, for soft delete
);

-- Index for fetching messages in a chat (paginated, newest first)
CREATE INDEX idx_messages_chat_id_created_at ON messages (chat_id, created_at DESC);

-- Index for sender lookup
CREATE INDEX idx_messages_sender_id ON messages (sender_id);

-- Index for reply threading
CREATE INDEX idx_messages_reply_to_id ON messages (reply_to_id)
    WHERE reply_to_id IS NOT NULL;

-- Partial index for active (non-deleted) messages
CREATE INDEX idx_messages_active ON messages (chat_id, created_at DESC)
    WHERE deleted_at IS NULL;

-- Index for message status updates
CREATE INDEX idx_messages_status ON messages (status)
    WHERE status != 'read';
