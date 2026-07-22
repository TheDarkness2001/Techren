const fs = require('fs');
const path = require('path');

/**
 * Upload root for local disk and Railway volumes.
 * Set UPLOADS_DIR=/data/uploads (or similar) when a Railway volume is mounted.
 */
const getUploadsRoot = () => {
  if (process.env.UPLOADS_DIR) {
    return path.resolve(process.env.UPLOADS_DIR);
  }
  return path.join(__dirname, '../../uploads');
};

const ensureUploadDirs = () => {
  const root = getUploadsRoot();
  for (const dir of [
    root,
    path.join(root, 'imports'),
    path.join(root, 'images'),
    path.join(root, 'audio'),
    path.join(root, 'listening'),
  ]) {
    if (!fs.existsSync(dir)) fs.mkdirSync(dir, { recursive: true });
  }
  return root;
};

/**
 * Download landing page (`website/`) lives at the monorepo root.
 * Prefer repo-root website; fall back to backend/website if copied in.
 */
const getWebsiteRoot = () => {
  const candidates = [
    path.resolve(__dirname, '../../../website'),
    path.resolve(__dirname, '../../website'),
    path.join(process.cwd(), 'website'),
    path.join(process.cwd(), '../website'),
  ];
  for (const dir of candidates) {
    if (fs.existsSync(path.join(dir, 'index.html'))) return dir;
  }
  return candidates[0];
};

module.exports = { getUploadsRoot, ensureUploadDirs, getWebsiteRoot };
