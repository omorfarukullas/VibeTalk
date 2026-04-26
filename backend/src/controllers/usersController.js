'use strict';

const { query } = require('../config/db');
const { AppError } = require('../middleware/errorHandler');
const UserModel = require('../models/User');
const UserKeyModel = require('../models/UserKey');
const { upload, uploadAvatarMiddleware } = require('../services/uploadService');
const logger = require('../utils/logger');

/**
 * PUT /api/users/profile
 * Update authenticated user's name, bio, and avatar_url.
 */
const updateProfile = async (req, res, next) => {
  try {
    const { name, bio, avatar_url } = req.body;

    if (name !== undefined && (typeof name !== 'string' || name.trim().length < 2)) {
      return next(new AppError('Name must be at least 2 characters.', 400, 'VALIDATION_ERROR'));
    }
    if (bio !== undefined && typeof bio === 'string' && bio.length > 500) {
      return next(new AppError('Bio must not exceed 500 characters.', 400, 'VALIDATION_ERROR'));
    }

    const updates = {};
    if (name !== undefined) updates.name = name.trim();
    if (bio !== undefined) updates.bio = bio;
    if (avatar_url !== undefined) updates.avatar_url = avatar_url;

    if (Object.keys(updates).length === 0) {
      return next(new AppError('No fields provided to update.', 400, 'NO_UPDATES'));
    }

    const user = await UserModel.update(req.user.id, updates);
    if (!user) {
      return next(new AppError('User not found.', 404, 'USER_NOT_FOUND'));
    }

    const { id, phone_number, name: userName, avatar_url: avatarUrl, bio: userBio, status, updated_at } = user;

    return res.json({
      success: true,
      data: { user: { id, phone_number, name: userName, avatar_url: avatarUrl, bio: userBio, status, updated_at } },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/users/avatar
 * Upload avatar image to Cloudflare R2, update user record.
 */
const uploadAvatar = async (req, res, next) => {
  try {
    if (!req.file) {
      return next(new AppError('No image file provided.', 400, 'FILE_MISSING'));
    }

    const { uploadFile } = require('../services/uploadService');
    const fileName = `${req.user.id}_${Date.now()}`;
    const publicUrl = await uploadFile(
      req.file.buffer,
      fileName,
      req.file.mimetype,
      'avatars',
    );

    const user = await UserModel.update(req.user.id, { avatar_url: publicUrl });

    logger.info('Avatar uploaded', { userId: req.user.id, url: publicUrl });

    return res.json({
      success: true,
      data: { avatar_url: publicUrl, user },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/users/keys
 * Store or update Signal Protocol public keys for the authenticated user.
 */
const uploadKeys = async (req, res, next) => {
  try {
    const { identity_key, signed_prekey, prekey_bundle } = req.body;

    if (!identity_key || !signed_prekey) {
      return next(
        new AppError('identity_key and signed_prekey are required.', 400, 'VALIDATION_ERROR'),
      );
    }

    await UserKeyModel.upsert({
      user_id: req.user.id,
      identity_key,
      signed_prekey,
      prekey_bundle: prekey_bundle || null,
    });

    logger.info('User keys uploaded', { userId: req.user.id });

    return res.status(201).json({
      success: true,
      data: { message: 'Key bundle stored successfully.' },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * GET /api/users/keys/:userId
 * Retrieve public key bundle for a specific user (Signal Protocol handshake).
 */
const getKeys = async (req, res, next) => {
  try {
    const { userId } = req.params;

    const keys = await UserKeyModel.findByUserId(userId);
    if (!keys) {
      return next(new AppError('Key bundle not found for this user.', 404, 'KEYS_NOT_FOUND'));
    }

    return res.json({
      success: true,
      data: {
        user_id: keys.user_id,
        identity_key: keys.identity_key,
        signed_prekey: keys.signed_prekey,
        prekey_bundle: keys.prekey_bundle,
        created_at: keys.created_at,
      },
    });
  } catch (error) {
    next(error);
  }
};

/**
 * POST /api/users/contacts
 * Given an array of phone numbers, return which ones are registered on VibeTalk.
 */
const findContacts = async (req, res, next) => {
  try {
    const { phone_numbers } = req.body;

    if (!Array.isArray(phone_numbers) || phone_numbers.length === 0) {
      return next(new AppError('phone_numbers must be a non-empty array.', 400, 'VALIDATION_ERROR'));
    }

    if (phone_numbers.length > 500) {
      return next(new AppError('Maximum 500 phone numbers per request.', 400, 'LIMIT_EXCEEDED'));
    }

    // Sanitize
    const sanitized = phone_numbers
      .filter((p) => typeof p === 'string')
      .map((p) => p.trim())
      .filter(Boolean);

    // Parameterised query
    const placeholders = sanitized.map((_, i) => `$${i + 1}`).join(', ');
    const result = await query(
      `SELECT id, phone_number, name, avatar_url
       FROM users
       WHERE phone_number IN (${placeholders})
         AND status = 'active'`,
      sanitized,
    );

    return res.json({
      success: true,
      data: { contacts: result.rows },
    });
  } catch (error) {
    next(error);
  }
};

module.exports = { updateProfile, uploadAvatar, uploadKeys, getKeys, findContacts };
