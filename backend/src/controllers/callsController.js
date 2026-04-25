/**
 * Calls Controller — Sprint 3 implementation.
 */

const getCalls = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Get call history — Sprint 3' } });
};

const createCall = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Call initiated — Sprint 3' } });
};

const updateCallStatus = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Call status updated — Sprint 3' } });
};

const getCall = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Get call — Sprint 3' } });
};

module.exports = { getCalls, createCall, updateCallStatus, getCall };
