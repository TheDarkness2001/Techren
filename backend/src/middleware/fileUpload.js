const fs = require('fs');
const path = require('path');
const multer = require('multer');

const UPLOAD_ROOT = path.join(__dirname, '../../uploads');
const DOCX_DIR = path.join(UPLOAD_ROOT, 'imports');
const IMAGE_DIR = path.join(UPLOAD_ROOT, 'images');
const AUDIO_DIR = path.join(UPLOAD_ROOT, 'audio');

for (const dir of [UPLOAD_ROOT, DOCX_DIR, IMAGE_DIR, AUDIO_DIR]) {
  if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
}

const makeStorage = (folder, prefix) =>
  multer.diskStorage({
    destination: (_req, _file, cb) => cb(null, folder),
    filename: (_req, file, cb) => {
      const ext = path.extname(file.originalname) || '';
      cb(null, `${prefix}-${Date.now()}-${Math.round(Math.random() * 1e9)}${ext}`);
    },
  });

const docxUpload = multer({
  storage: makeStorage(DOCX_DIR, 'import'),
  limits: { fileSize: 10 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = /\.(docx|txt)$/i;
    if (allowed.test(file.originalname)) cb(null, true);
    else cb(new Error('Only .docx or .txt files are allowed'));
  },
});

const imageUpload = multer({
  storage: makeStorage(IMAGE_DIR, 'image'),
  limits: { fileSize: 5 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = /\.(jpe?g|png|webp|gif)$/i;
    if (allowed.test(file.originalname) || file.mimetype.startsWith('image/')) cb(null, true);
    else cb(new Error('Only image files are allowed'));
  },
});

const audioUpload = multer({
  storage: makeStorage(AUDIO_DIR, 'audio'),
  limits: { fileSize: 25 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = /\.(mp3|wav|ogg|m4a|aac|webm|mpeg)$/i;
    if (allowed.test(file.originalname) || file.mimetype.startsWith('audio/')) cb(null, true);
    else cb(new Error('Only audio files are allowed'));
  },
});

const ocrUpload = multer({
  storage: makeStorage(IMAGE_DIR, 'ocr'),
  limits: { fileSize: 8 * 1024 * 1024 },
  fileFilter: (_req, file, cb) => {
    const allowed = /\.(jpe?g|png|webp|gif|bmp|tiff?)$/i;
    if (allowed.test(file.originalname) || file.mimetype.startsWith('image/')) cb(null, true);
    else cb(new Error('Only image files are allowed for OCR'));
  },
});

module.exports = {
  UPLOAD_ROOT,
  DOCX_DIR,
  IMAGE_DIR,
  AUDIO_DIR,
  docxUpload,
  imageUpload,
  audioUpload,
  ocrUpload,
};
