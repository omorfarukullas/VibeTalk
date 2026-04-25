/**
 * Media Controller — Sprint 3 implementation.
 */

const upload = async (req, res, next) => {
  res.json({ success: true, data: { message: 'File uploaded — Sprint 3' } });
};

const getMedia = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Get media — Sprint 3' } });
};

const deleteMedia = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Media deleted — Sprint 3' } });
};

const download = async (req, res, next) => {
  res.json({ success: true, data: { message: 'Download media — Sprint 3' } });
};

module.exports = { upload, getMedia, deleteMedia, download };
