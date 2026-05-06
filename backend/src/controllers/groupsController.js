'use strict';

const ChatModel = require('../models/Chat');
const { AppError } = require('../middleware/errorHandler');

/**
 * POST /api/groups
 * Create a new group chat.
 */
const createGroup = async (req, res, next) => {
  try {
    const { name, participantIds } = req.body;

    if (!name || name.trim().length === 0) {
      return next(new AppError('Group name is required.', 400));
    }
    if (!Array.isArray(participantIds) || participantIds.length === 0) {
      return next(new AppError('At least one participant is required.', 400));
    }

    const chat = await ChatModel.createGroupChat(req.user.id, name.trim(), participantIds);

    return res.status(201).json({
      success: true,
      data: { chat },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/groups/:id/members
 * Get all members of a group chat.
 */
const getGroupMembers = async (req, res, next) => {
  try {
    const { id } = req.params;

    const chat = await ChatModel.findById(id);
    if (!chat || chat.type !== 'group') {
      return next(new AppError('Group not found.', 404));
    }

    const participants = await ChatModel.getParticipants(id);
    
    // Check if the requester is a participant
    const isMember = participants.some(p => p.id === req.user.id);
    if (!isMember) {
      return next(new AppError('Forbidden: Not a member of this group.', 403));
    }

    return res.json({
      success: true,
      data: { members: participants },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/groups/:id/members
 * Add a new member to the group.
 */
const addGroupMember = async (req, res, next) => {
  try {
    const { id } = req.params;
    const { userId } = req.body;

    if (!userId) {
      return next(new AppError('User ID is required.', 400));
    }

    const chat = await ChatModel.findById(id);
    if (!chat || chat.type !== 'group') {
      return next(new AppError('Group not found.', 404));
    }

    const participants = await ChatModel.getParticipants(id);
    
    // Check if the requester is an admin (or just a member if any member can add)
    // For now, any member can add another member
    const isMember = participants.some(p => p.id === req.user.id);
    if (!isMember) {
      return next(new AppError('Forbidden: Only members can add new participants.', 403));
    }

    // Check if already a member
    if (participants.some(p => p.id === userId)) {
      return res.json({
        success: true,
        data: { message: 'User is already a member.' },
      });
    }

    await ChatModel.addParticipant(id, userId, 'member');

    return res.json({
      success: true,
      data: { message: 'Member added successfully.' },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { createGroup, getGroupMembers, addGroupMember };
