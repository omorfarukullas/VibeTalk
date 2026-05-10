# 🗺️ VibeTalk Development Roadmap

**Current Completion State: ~65%**

### Phase 1: Security Hardening (Current Priority)
1.  **Socket Security:** Add database checks to `join_room` and `send_message`.
2.  **WebRTC Fix:** Fix signaling by implementing user-specific socket rooms.
3.  **Upload Validation:** Restrict file types and implement size limits in `multer`.
4.  **Rate Limiting:** Add `express-rate-limit` to prevent API abuse.

### Phase 2: Missing Core Logic (Sprint 3)
1.  **Group Management:**
    *   Backend: `POST /api/groups`, `POST /api/groups/:id/members`.
    *   Frontend: Integrate `CreateGroupScreen` with actual API calls.
2.  **WebRTC Implementation:**
    *   Integrate `flutter_webrtc`.
    *   Handle `RTCPeerConnection` and ICE candidate exchange.
3.  **Presence Improvements:**
    *   Fetch partner status on chat open.

### Phase 3: Advanced Encryption & Features (Sprint 4)
1.  **Signal Protocol:**
    *   Replace AES mock with `libsignal` (Double Ratchet Algorithm).
    *   Implement Pre-key bundle management.
2.  **Push Notifications:**
    *   Firebase Cloud Messaging (FCM) integration for background alerts.

### Phase 4: Polish & Deployment (Sprint 5)
1.  **Code Cleanup:** Remove redundant Hive storage for tokens.
2.  **Unit Testing:** Add tests for BLoC logic and Backend services.
3.  **DevOps:** Setup CI/CD and Dockerize the backend.
