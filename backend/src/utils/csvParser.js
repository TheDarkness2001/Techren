/**
 * RFC 4180-style CSV parser.
 * Does not split on commas that sit inside quoted fields.
 */
const parseCsv = (rawText) => {
  const text = String(rawText || '').replace(/^\uFEFF/, '');
  const rows = [];
  let row = [];
  let field = '';
  let inQuotes = false;

  for (let i = 0; i < text.length; i += 1) {
    const char = text[i];
    const next = text[i + 1];

    if (inQuotes) {
      if (char === '"') {
        if (next === '"') {
          field += '"';
          i += 1;
        } else {
          inQuotes = false;
        }
      } else {
        field += char;
      }
      continue;
    }

    if (char === '"') {
      inQuotes = true;
      continue;
    }
    if (char === ',') {
      row.push(field);
      field = '';
      continue;
    }
    if (char === '\n') {
      row.push(field);
      rows.push(row);
      row = [];
      field = '';
      continue;
    }
    if (char === '\r') {
      if (next === '\n') continue;
      row.push(field);
      rows.push(row);
      row = [];
      field = '';
      continue;
    }
    field += char;
  }

  if (inQuotes) {
    const error = new Error('Malformed CSV: unclosed quoted field');
    error.code = 'MALFORMED_CSV';
    throw error;
  }

  if (field.length > 0 || row.length > 0) {
    row.push(field);
    rows.push(row);
  }

  return rows;
};

const looksLikeCsv = (rawText) => {
  const text = String(rawText || '').replace(/^\uFEFF/, '').trim();
  if (!text) return false;
  const firstLine = text.split(/\r?\n/).find((line) => line.trim()) || '';
  if (/^"?english"?\s*,\s*"?uzbek"?\s*$/i.test(firstLine.trim())) return true;
  if (/^"?en"?\s*,\s*"?uz"?\s*$/i.test(firstLine.trim())) return true;
  if (/^"?word"?\s*,\s*"?(?:translation|meaning)"?\s*$/i.test(firstLine.trim())) return true;
  if (/"[^"]*","[^"]*"/.test(text)) return true;
  return false;
};

module.exports = { parseCsv, looksLikeCsv };
