/**
 * Chat Model — database queries for chats and chat_participants.
 */
const { query } = require('../config/db');

const ChatModel = {
  findById: async (id) => {
    const result = await query('SELECT * FROM chats WHERE id = $1', [id]);
    return result.rows[0] || null;
  },

  create: async (type) => {
    const result = await query(
      'INSERT INTO chats (type) VALUES ($1) RETURNING *',
      [type]
    );
    return result.rows[0];
  },

  getDirectChat: async (userId1, userId2) => {
    // Find a direct chat where BOTH users are members
    const result = await query(
      `SELECT c.* FROM chats c
       JOIN chat_participants cp1 ON c.id = cp1.chat_id
       JOIN chat_participants cp2 ON c.id = cp2.chat_id
       WHERE c.type = 'direct'
       AND cp1.user_id = $1 AND cp2.user_id = $2`,
      [userId1, userId2]
    );
    return result.rows[0] || null;
  },

  createDirectChat: async (userId1, userId2) => {
    // Check if it already exists
    const existingChat = await ChatModel.getDirectChat(userId1, userId2);
    if (existingChat) return existingChat;

    // We should technically use a transaction here, but for simplicity we'll just run queries sequentially.
    // In production, use client.query('BEGIN') ... client.query('COMMIT').
    try {
      const chatResult = await query(
        "INSERT INTO chats (type) VALUES ('direct') RETURNING *"
      );
      const chat = chatResult.rows[0];

      await query(
        `INSERT INTO chat_participants (chat_id, user_id, role) VALUES ($1, $2, 'member'), ($1, $3, 'member')`,
        [chat.id, userId1, userId2]
      );

      return chat;
    } catch (e) {
      console.error('Error creating direct chat:', e);
      throw e;
    }
  },

  createGroupChat: async (creatorId, name, participantIds) => {
    try {
      const chatResult = await query(
        "INSERT INTO chats (type, name) VALUES ('group', $1) RETURNING *",
        [name]
      );
      const chat = chatResult.rows[0];

      // Add creator as admin
      let values = `('${chat.id}', '${creatorId}', 'admin')`;
      
      // Add other participants
      const otherIds = participantIds.filter(id => id !== creatorId);
      if (otherIds.length > 0) {
         const participantValues = otherIds.map(id => `('${chat.id}', '${id}', 'member')`).join(', ');
         values += `, ${participantValues}`;
      }

      await query(`INSERT INTO chat_participants (chat_id, user_id, role) VALUES ${values}`);

      return chat;
    } catch (e) {
      console.error('Error creating group chat:', e);
      throw e;
    }
  },



  addParticipant: async (chatId, userId, role = 'member') => {
    const result = await query(
      `INSERT INTO chat_participants (chat_id, user_id, role)
       VALUES ($1, $2, $3) RETURNING *`,
      [chatId, userId, role]
    );
    return result.rows[0];
  },

  getParticipants: async (chatId) => {
    const result = await query(
      `SELECT u.* FROM users u
       JOIN chat_participants cp ON u.id = cp.user_id
       WHERE cp.chat_id = $1`,
      [chatId]
    );
    return result.rows;
  },

  getUserChats: async (userId) => {
    // Fetch all chats for the user, along with the latest message and participant details
    const result = await query(
      `SELECT 
         c.id, 
         c.type,
         c.name as group_name,
         c.avatar_url as group_avatar,
         c.created_at,
         -- Get the other participant's details (for direct chats)
         (
           SELECT json_build_object('id', u.id, 'name', u.name, 'email', u.email, 'avatar_url', u.avatar_url, 'last_seen', u.last_seen)
           FROM chat_participants cp2
           JOIN users u ON cp2.user_id = u.id
           WHERE cp2.chat_id = c.id AND cp2.user_id != $1
           LIMIT 1
         ) as other_participant,
         -- Get all participant IDs for socket broadcasting
         (
           SELECT json_agg(cp3.user_id)
           FROM chat_participants cp3
           WHERE cp3.chat_id = c.id
         ) as participant_ids,
         -- Get the latest message
         (
           SELECT json_build_object('id', m.id, 'content', m.content, 'created_at', m.created_at, 'sender_id', m.sender_id, 'status', m.status)
           FROM messages m
           WHERE m.chat_id = c.id
           ORDER BY m.created_at DESC
           LIMIT 1
         ) as last_message,
         -- Get unread count for this user
         (
           SELECT COUNT(*)
           FROM messages m
           WHERE m.chat_id = c.id AND m.sender_id != $1 AND m.status != 'read'
         ) as unread_count
       FROM chats c
       JOIN chat_participants cp ON c.id = cp.chat_id
       WHERE cp.user_id = $1
       ORDER BY (
         SELECT COALESCE(MAX(m.created_at), c.created_at)
         FROM messages m WHERE m.chat_id = c.id
       ) DESC`,
      [userId]
    );
    return result.rows;
  },

};

module.exports = ChatModel;
