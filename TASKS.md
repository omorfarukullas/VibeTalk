# 📋 VibeTalk Project Roadmap

This document tracks the progress of VibeTalk development.

## ✅ Completed Tasks

### Phase 1: Infrastructure & Authentication
- [x] **Project Scaffolding**
    - [x] Flutter app structure with Feature-driven architecture.
    - [x] Node.js backend with Express and Socket.IO.
- [x] **Database & Cache**
    - [x] PostgreSQL (Supabase) integration for persistent data.
    - [x] Redis (Upstash) for session management and real-time state.
- [x] **Authentication**
    - [x] Firebase Auth integration (Email & Google Sign-In).
    - [x] Custom JWT pipeline (Access & Refresh tokens).
    - [x] Synchronous token interceptors for reliable API calls.
- [x] **Profile Management**
    - [x] Profile setup flow (Name, Bio).
    - [x] Avatar upload to **Supabase Storage** (S3-compatible).
    - [x] Real-time profile viewing and data fetching.
- [x] **Network Layer**
    - [x] Robust Dio client with auto-refresh token logic.
    - [x] Socket.IO real-time connection established.

---

## 🚧 In Progress / Upcoming Tasks

### Phase 2: Real-time Messaging (Sprint 2)
- [ ] **End-to-End Encryption (E2EE)**
    - [ ] Integrate Signal Protocol (libsignal) for secure messaging.
    - [ ] Identity key and pre-key bundle management on backend.
- [ ] **Chat Functionality**
    - [ ] Real-time message delivery via Socket.IO.
    - [ ] Message status (Sent, Delivered, Read).
    - [ ] Typing indicators and online/offline presence.
    - [ ] Chat history pagination.

### Phase 3: Voice & Video Calling (Sprint 3)
- [ ] **WebRTC Integration**
    - [ ] 1-to-1 voice calling.
    - [ ] 1-to-1 video calling.
    - [ ] Screen sharing capabilities.
- [ ] **Infrastructure**
    - [ ] Coturn server deployment for STUN/TURN traversal.
    - [ ] Call signaling protocol implementation.

### Phase 4: Groups & Advanced Media (Sprint 4)
- [ ] **Group Chats**
    - [ ] Group creation with multiple members.
    - [ ] Admin controls (Add/Remove members, promote admins).
    - [ ] Group profiles and descriptions.
- [ ] **Media & File Sharing**
    - [ ] Upload/Download photos and videos in chats.
    - [ ] Document sharing (PDFs, Docs).
    - [ ] Voice notes implementation.
    - [ ] In-app media viewer (Gallery & Video player).

### Phase 5: Final Polish & Notifications (Sprint 5)
- [ ] **Push Notifications**
    - [ ] FCM integration for background message alerts.
    - [ ] Interactive notifications for calls.
- [ ] **Settings & Customization**
    - [ ] Dark/Light mode support.
    - [ ] Privacy settings (Block users, Last seen visibility).
    - [ ] Multi-language support (i18n).
- [ ] **Optimization**
    - [ ] Sentry error tracking and performance monitoring.
    - [ ] App size and startup time optimization.

---

## 🛠️ Maintenance
- [ ] Unit and Integration tests for core logic.
- [ ] Documentation for API endpoints (Swagger/Postman).
- [ ] CI/CD pipeline optimization for automated deployments.
