const sendSuccess = (res, data, statusCode = 200, meta = null) => {
  const body = { success: true, data };
  if (meta) body.meta = meta;
  return res.status(statusCode).json(body);
};

/**
 * Canonical list envelope: `{ success, data: items[], meta }`.
 * Prefer this for new list endpoints. Legacy nested wrappers
 * (e.g. `{ data: { penalties: [] } }`) should migrate here + clients together.
 */
const sendList = (res, items, meta = null, statusCode = 200) =>
  sendSuccess(res, Array.isArray(items) ? items : [], statusCode, meta);

const sendError = (res, statusCode, code, message, details = []) => {
  return res.status(statusCode).json({
    success: false,
    error: { code, message, details },
  });
};

module.exports = { sendSuccess, sendList, sendError };
