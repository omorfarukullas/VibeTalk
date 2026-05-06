'use strict';

const express = require('express');
const { authenticate } = require('../middleware/auth');
const groupsController = require('../controllers/groupsController');

const router = express.Router();

router.post('/', authenticate, groupsController.createGroup);
router.get('/:id/members', authenticate, groupsController.getGroupMembers);
router.post('/:id/members', authenticate, groupsController.addGroupMember);

module.exports = router;
