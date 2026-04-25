/**
 * Users Controller — Sprint 1 implementation.
 * Handles user CRUD operations.
 */

const getUser = async (req, res, next) => {
  // TODO: Sprint 1 — Fetch user by ID from PostgreSQL
  res.json({ success: true, data: { message: 'Get user — Sprint 1' } });
};

const updateUser = async (req, res, next) => {
  // TODO: Sprint 1 — Update user profile (name, bio, avatar)
  res.json({ success: true, data: { message: 'User updated — Sprint 1' } });
};

const searchUsers = async (req, res, next) => {
  // TODO: Sprint 1 — Search users by phone number
  res.json({ success: true, data: { message: 'Search users — Sprint 1' } });
};

const deleteUser = async (req, res, next) => {
  // TODO: Sprint 5 — Soft delete user account
  res.json({ success: true, data: { message: 'User deleted — Sprint 5' } });
};

module.exports = { getUser, updateUser, searchUsers, deleteUser };
