const fs = require('fs');

const MAGIC = {
  jpeg: [[0xff, 0xd8, 0xff]],
  png: [[0x89, 0x50, 0x4e, 0x47]],
  gif: [[0x47, 0x49, 0x46, 0x38]],
  webp: [[0x52, 0x49, 0x46, 0x46]], // RIFF....WEBP checked separately
  wav: [[0x52, 0x49, 0x46, 0x46]],
  mp3: [[0xff, 0xfb], [0xff, 0xf3], [0xff, 0xf2], [0x49, 0x44, 0x33]], // frame or ID3
  ogg: [[0x4f, 0x67, 0x67, 0x53]],
  docx: [[0x50, 0x4b, 0x03, 0x04]], // zip/docx
};

const startsWith = (buf, signature) => {
  if (buf.length < signature.length) return false;
  return signature.every((byte, i) => buf[i] === byte);
};

const matchesAny = (buf, signatures) => signatures.some((sig) => startsWith(buf, sig));

const assertMagicBytes = (filePath, kind) => {
  const fd = fs.openSync(filePath, 'r');
  try {
    const buf = Buffer.alloc(16);
    fs.readSync(fd, buf, 0, 16, 0);

    if (kind === 'image') {
      const ok =
        matchesAny(buf, MAGIC.jpeg)
        || matchesAny(buf, MAGIC.png)
        || matchesAny(buf, MAGIC.gif)
        || (matchesAny(buf, MAGIC.webp) && buf.slice(8, 12).toString('ascii') === 'WEBP');
      if (!ok) {
        throw Object.assign(new Error('File content is not a valid image'), {
          statusCode: 400,
          code: 'VALIDATION_ERROR',
        });
      }
      return;
    }

    if (kind === 'audio') {
      const ok =
        matchesAny(buf, MAGIC.mp3)
        || matchesAny(buf, MAGIC.ogg)
        || matchesAny(buf, MAGIC.wav)
        || buf.slice(4, 8).toString('ascii') === 'ftyp'; // m4a/mp4
      if (!ok) {
        throw Object.assign(new Error('File content is not a valid audio file'), {
          statusCode: 400,
          code: 'VALIDATION_ERROR',
        });
      }
      return;
    }

    if (kind === 'docx') {
      if (!matchesAny(buf, MAGIC.docx)) {
        // Plain .txt imports have no magic — allow UTF-8 text heuristically
        const sample = buf.toString('utf8');
        if (!/^[\x09\x0A\x0D\x20-\x7E\u0080-\uFFFF]*$/.test(sample)) {
          throw Object.assign(new Error('File content is not a valid document'), {
            statusCode: 400,
            code: 'VALIDATION_ERROR',
          });
        }
      }
    }
  } finally {
    fs.closeSync(fd);
  }
};

module.exports = { assertMagicBytes };
