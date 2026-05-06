-- ============================================================
-- Migration 005: Add name and avatar_url to chats
-- VibeTalk — Sprint 3
-- ============================================================

ALTER TABLE chats 
ADD COLUMN name VARCHAR(100),
ADD COLUMN avatar_url TEXT;
