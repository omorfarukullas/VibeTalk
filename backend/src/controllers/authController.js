/**
 * Auth Controller — Sprint 1 implementation.
 * Handles phone OTP authentication via Firebase.
 */

const sendOtp = async (req, res, next) => {
  // TODO: Sprint 1 — Firebase phone auth OTP send
  res.json({ success: true, data: { message: 'OTP sent — Sprint 1' } });
};

const verifyOtp = async (req, res, next) => {
  // TODO: Sprint 1 — Verify Firebase OTP token, create/find user, issue JWT
  res.json({ success: true, data: { message: 'OTP verified — Sprint 1' } });
};

const refreshToken = async (req, res, next) => {
  // TODO: Sprint 1 — Validate refresh token, issue new access token
  res.json({ success: true, data: { message: 'Token refreshed — Sprint 1' } });
};

const logout = async (req, res, next) => {
  // TODO: Sprint 1 — Invalidate refresh token in Redis
  res.json({ success: true, data: { message: 'Logged out — Sprint 1' } });
};

module.exports = { sendOtp, verifyOtp, refreshToken, logout };
