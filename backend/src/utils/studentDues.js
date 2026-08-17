/**
 * Resolve monthly billable courses from the student's own fees.
 * Exam-group membership is only used for subject names / catalog fallback.
 *
 * Rules:
 * - Per-subject `subjectFees` with amount > 0 win (one due per subject).
 * - Else a single `coursePrice` > 0 is one due (not copied onto every group).
 * - Else group `pricePerClass` is used when the student has no personal fee.
 * - Amount 0 is omitted (no unpaid 0/0 chips).
 */
const resolveBillableCourses = (student = {}, groupSubjects = []) => {
  const coursePrice = Number(student.coursePrice || 0);
  const fees = Array.isArray(student.subjectFees) ? student.subjectFees : [];
  const groups = Array.isArray(groupSubjects) ? groupSubjects : [];

  const groupByName = new Map();
  for (const group of groups) {
    const name = String(group.subjectName || '').trim();
    if (!name) continue;
    const key = name.toLowerCase();
    if (!groupByName.has(key)) {
      groupByName.set(key, {
        subjectId: group.subjectId || null,
        subjectName: name,
        pricePerClass: Number(group.pricePerClass || 0),
      });
    }
  }

  const add = (map, { subjectId, subjectName, amountDue }) => {
    const name = String(subjectName || '').trim();
    const due = Number(amountDue) || 0;
    if (!name || due <= 0) return;
    const key = name.toLowerCase();
    if (!map.has(key)) {
      map.set(key, { subjectId: subjectId || null, subjectName: name, amountDue: due });
      return;
    }
    const existing = map.get(key);
    if (due > existing.amountDue) existing.amountDue = due;
    if (!existing.subjectId && subjectId) existing.subjectId = subjectId;
  };

  const map = new Map();
  const positiveFees = fees.filter(
    (fee) => String(fee?.subject || '').trim() && Number(fee.amount) > 0
  );

  if (positiveFees.length) {
    for (const fee of positiveFees) {
      const name = String(fee.subject).trim();
      const group = groupByName.get(name.toLowerCase());
      add(map, {
        subjectId: group?.subjectId,
        subjectName: name,
        amountDue: Number(fee.amount),
      });
    }
    return [...map.values()];
  }

  if (coursePrice > 0) {
    const names = [];
    const seen = new Set();
    const pushName = (raw) => {
      const name = String(raw || '').trim();
      if (!name) return;
      const key = name.toLowerCase();
      if (seen.has(key)) return;
      seen.add(key);
      names.push(name);
    };
    for (const fee of fees) pushName(fee?.subject);
    for (const group of groups) pushName(group?.subjectName);

    const subjectName = names.length ? names.join(' + ') : 'Course';
    const onlyGroup = names.length === 1 ? groupByName.get(names[0].toLowerCase()) : null;
    return [
      {
        subjectId: onlyGroup?.subjectId || null,
        subjectName,
        amountDue: coursePrice,
      },
    ];
  }

  for (const group of groupByName.values()) {
    add(map, {
      subjectId: group.subjectId,
      subjectName: group.subjectName,
      amountDue: group.pricePerClass,
    });
  }
  return [...map.values()];
};

const paidTowardCourse = ({ studentId, course, courseCount, paidByStudentSubject, paidByStudent }) => {
  const sid = String(studentId);
  const name = String(course.subjectName || '').trim().toLowerCase();
  const exact = Number(paidByStudentSubject.get(`${sid}::${name}`) || 0);
  const parts = String(course.subjectName || '')
    .split(/\s*\+\s*/)
    .map((part) => part.trim().toLowerCase())
    .filter(Boolean);
  let fromParts = 0;
  if (parts.length > 1) {
    fromParts = parts.reduce(
      (sum, part) => sum + Number(paidByStudentSubject.get(`${sid}::${part}`) || 0),
      0
    );
  }
  const matched = Math.max(exact, fromParts);
  if (courseCount === 1) {
    return Math.max(matched, Number(paidByStudent.get(sid) || 0));
  }
  return matched;
};

const courseStatus = (amountDue, amountPaid) => {
  const due = Number(amountDue) || 0;
  const paid = Number(amountPaid) || 0;
  if (due > 0 && paid >= due) return 'paid';
  if (paid > 0) return 'partial';
  if (due === 0 && paid > 0) return 'paid';
  return 'unpaid';
};

const summarizeCourses = (courses) => {
  const list = Array.isArray(courses) ? courses : [];
  const amountRemaining = list.reduce((sum, course) => {
    if (course.status === 'paid') return sum;
    return sum + Math.max(0, Number(course.amountDue || 0) - Number(course.amountPaid || 0));
  }, 0);
  let overallStatus = 'unpaid';
  if (list.length && list.every((course) => course.status === 'paid')) overallStatus = 'paid';
  else if (list.some((course) => Number(course.amountPaid) > 0)) overallStatus = 'partial';
  return { courses: list, overallStatus, amountRemaining };
};

module.exports = {
  resolveBillableCourses,
  paidTowardCourse,
  courseStatus,
  summarizeCourses,
};
