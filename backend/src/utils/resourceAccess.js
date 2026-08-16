const forbidden = (message = 'Forbidden') =>
  Object.assign(new Error(message), { statusCode: 403, code: 'FORBIDDEN' });

const linkedChildIds = (parent) =>
  (parent?.children || []).map((child) => String(child._id || child));

const assertParentChild = (parent, studentId) => {
  if (!linkedChildIds(parent).includes(String(studentId))) {
    throw forbidden('Child not linked to this parent account');
  }
};

/** Mongo filter value: one child id, or `{ $in: children }`. */
const parentStudentScope = (parent, requestedStudentId) => {
  const ids = linkedChildIds(parent);
  if (requestedStudentId) {
    assertParentChild(parent, requestedStudentId);
    return requestedStudentId;
  }
  return { $in: ids };
};

module.exports = {
  forbidden,
  linkedChildIds,
  assertParentChild,
  parentStudentScope,
};
