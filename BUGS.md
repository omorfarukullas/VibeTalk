# 🐛 VibeTalk Known Bugs & Security Issues

### 🔴 Critical Security Vulnerabilities
1.  **Unauthorized Room Access (`backend/src/socket/index.js`):** The `join_room` event allows any user to join any room ID without checking the `chat_participants` table.
2.  **Unprotected Messaging:** `send_message` doesn't verify if the sender is actually a member of the room they are sending to.
3.  **Arbitrary File Upload:** `multer` in `uploadService.js` has a `fileFilter` that returns `true` for all types. Users could upload malicious `.exe` or `.js` files.
4.  **Stateless JWT Refresh:** Refresh tokens are verified by signature only. There is no way to revoke a compromised refresh token (Needs Redis blacklisting).

### 🟠 High Priority Logic Errors
1.  **Broken WebRTC Signaling:** `io.to(targetUserId)` is used in `socket/index.js`, but users never actually `socket.join(userId)` upon connection. Signaling messages are lost.
2.  **Redundant Token Storage:** Tokens are stored in both `Hive` and `FlutterSecureStorage`. This increases the risk of desync where the app thinks it is logged in but the API fails.
3.  **Startup DB Creation:** `FriendModel.createTable()` is called on server startup in `server.js`. This should be a proper migration.

### 🟡 Medium/Low Priority
1.  **Last Seen Sync:** When a user logs in, they don't receive the "Online" status of their existing chat partners until those partners perform an action.
2.  **No Rate Limiting:** API endpoints (especially upload) have no protection against flood attacks.
3.  **Empty Encryption (Fixed):** AES encryption used to crash on empty strings (Fixed by padding with space).

---

### 🛠️ Resolved Bugs
*   [x] Fixed `RangeError` when encrypting empty text for documents.
*   [x] Fixed `Dio` Multipart boundary error by using `Options(contentType: 'multipart/form-data')`.
*   [x] Fixed Message misalignment by adding `.enableForceNew()` to socket connection.
