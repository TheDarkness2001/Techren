/**
 * Roll student dues up to branch totals (need vs collected).
 */
const aggregateBranchCollections = ({ branches = [], students = [], duesMap = new Map() } = {}) => {
  const rows = new Map();
  const ensure = (id, name) => {
    const key = String(id || 'unassigned');
    if (!rows.has(key)) {
      rows.set(key, {
        branchId: key,
        branchName: name || 'Unassigned',
        expected: 0,
        collected: 0,
        remaining: 0,
        studentCount: 0,
        unpaidCount: 0,
      });
    }
    return rows.get(key);
  };

  for (const branch of branches) {
    ensure(branch._id || branch.id, branch.name);
  }

  for (const student of students) {
    const branchId = student.branchId ? String(student.branchId) : 'unassigned';
    const branch = branches.find((b) => String(b._id || b.id) === branchId);
    const row = ensure(branchId, branch?.name || 'Unassigned');
    const dues = duesMap.get(String(student._id || student.id)) || { courses: [], amountRemaining: 0 };
    const expected = (dues.courses || []).reduce((sum, course) => sum + Number(course.amountDue || 0), 0);
    const collected = (dues.courses || []).reduce((sum, course) => sum + Number(course.amountPaid || 0), 0);
    const remaining = Number(dues.amountRemaining || Math.max(0, expected - collected));
    row.studentCount += 1;
    row.expected += expected;
    row.collected += collected;
    row.remaining += remaining;
    if (remaining > 0) row.unpaidCount += 1;
  }

  if (rows.get('unassigned')?.studentCount === 0) rows.delete('unassigned');

  const items = [...rows.values()].sort((a, b) => a.branchName.localeCompare(b.branchName));
  const totals = items.reduce(
    (acc, row) => ({
      expected: acc.expected + row.expected,
      collected: acc.collected + row.collected,
      remaining: acc.remaining + row.remaining,
      studentCount: acc.studentCount + row.studentCount,
      unpaidCount: acc.unpaidCount + row.unpaidCount,
    }),
    { expected: 0, collected: 0, remaining: 0, studentCount: 0, unpaidCount: 0 }
  );

  return { items, totals };
};

module.exports = { aggregateBranchCollections };
