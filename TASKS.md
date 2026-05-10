# 📋 VibeTalk Project Checklist

This document tracks the granular progress of VibeTalk.

## ✅ Completed Tasks

### Phase 1: Infrastructure & Authentication
- [x] Flutter app structure with Feature-driven architecture.
- [x] Node.js backend with Express and Socket.IO.
- [x] PostgreSQL (Supabase) integration.
- [x] Redis (Upstash) for presence and state.
- [x] Firebase Auth + Custom JWT pipeline.
- [x] Robust Dio client with auto-refresh token logic.

### Phase 2: Core Messaging & Friends
- [x] Real-time message delivery via Socket.IO.
- [x] Message status (Sent, Delivered, Read).
- [x] Typing indicators and Online/Offline presence.
- [x] Friend requests flow (Backend + Frontend).
- [x] Image and Document uploading to Cloudflare R2.
- [x] **Bugfix:** Resolved AES empty string crash.
- [x] **Bugfix:** Resolved Dio multipart boundary headers.

---

## 🚧 Current Technical Debt (Fix Immediately)
- [ ] **Socket Authorization:** Verify room participation on join/send.
- [ ] **Signaling Fix:** Join user-specific socket rooms for WebRTC.
- [ ] **Security:** Add Multer file type filtering.
- [ ] **Security:** Add API Rate Limiting.
- [ ] **Cleanup:** Remove redundant Hive storage for Auth tokens.

---

## 📅 Remaining Features

### Phase 3: WebRTC & Groups
- [ ] **WebRTC 1-to-1 Calls** (Signaling works, but connection logic missing).
- [ ] **Group Chat Creation** (UI exists, Backend missing).
- [ ] **Group Member Management** (Admin roles, adding/removing).

### Phase 4: Encryption & Advanced Chat
- [ ] **Signal Protocol Integration** (Currently using AES mock).
- [ ] **Pre-key Bundle Management**.
- [ ] **Voice Notes**.
- [ ] **Message Search**.

### Phase 5: Notifications & Polish
- [ ] **Push Notifications (FCM)**.
- [ ] **User Blocking / Privacy Settings**.
- [ ] **Sentry Error Tracking**.
