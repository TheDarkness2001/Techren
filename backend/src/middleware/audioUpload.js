const path = require('path');
const multer = require('multer');
const { ensureUploadDirs } = require('../config/paths');

const UPLOAD_DIR = path.join(ensureUploadDirs(), 'listening');

const storage = multer.diskStorage({
  destination: (_req, _file, cb) => cb(null, UPLOAD_DIR),
  filename: (_req, file, cb) => {
    const ext = path.extname(file.originalname) || '.mp3';
    cb(null, `listening-${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`);
  },
});

const upload = multer({
  storage,
  limits: { fileSize: 25 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = /\.(mp3|wav|ogg|m4a|aac|webm|mpeg)$/i;
    if (allowed.test(file.originalname) || file.mimetype.startsWith('audio/')) {
      cb(null, true);
    } else {
      cb(new Error('Only audio files are allowed'));
    }
  },
});

module.exports = { upload, UPLOAD_DIR };
