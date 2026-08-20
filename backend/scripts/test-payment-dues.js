/**
 * Unit checks for student payment dues (no DB).
 * Run: node scripts/test-payment-dues.js
 */
const assert = require('assert');
const {
  resolveBillableCourses,
  paidTowardCourse,
  courseStatus,
  summarizeCourses,
} = require('../src/utils/studentDues');

// Fee on the student profile shows even with no exam group (Mushtariy case).
{
  const courses = resolveBillableCourses(
    { coursePrice: 200, subjectFees: [{ subject: 'English', amount: 0 }] },
    []
  );
  assert.strictEqual(courses.length, 1, 'profile fee without group');
  assert.strictEqual(courses[0].subjectName, 'English');
  assert.strictEqual(courses[0].amountDue, 200);
}

{
  const courses = resolveBillableCourses({ coursePrice: 200, subjectFees: [] }, []);
  assert.strictEqual(courses.length, 1, 'coursePrice only');
  assert.strictEqual(courses[0].subjectName, 'Course');
  assert.strictEqual(courses[0].amountDue, 200);
}

// Per-subject fees: two subjects, two dues (not one lump copied twice).
{
  const courses = resolveBillableCourses(
    {
      coursePrice: 1200,
      subjectFees: [
        { subject: 'English', amount: 600 },
        { subject: 'IT', amount: 600 },
      ],
    },
    [
      { subjectName: 'English', pricePerClass: 500 },
      { subjectName: 'IT', pricePerClass: 500 },
    ]
  );
  assert.strictEqual(courses.length, 2, 'two subject fees');
  const byName = Object.fromEntries(courses.map((c) => [c.subjectName, c.amountDue]));
  assert.strictEqual(byName.English, 600);
  assert.strictEqual(byName.IT, 600);
}

// Zero fee is omitted (Nurbek IT 0/0).
{
  const courses = resolveBillableCourses(
    {
      coursePrice: 500,
      subjectFees: [
        { subject: 'English', amount: 500 },
        { subject: 'IT', amount: 0 },
      ],
    },
    [
      { subjectName: 'English', pricePerClass: 0 },
      { subjectName: 'IT', pricePerClass: 0 },
    ]
  );
  assert.strictEqual(courses.length, 1, 'zero-fee subject omitted');
  assert.strictEqual(courses[0].subjectName, 'English');
  assert.strictEqual(courses[0].amountDue, 500);
}

// Student with 0 fee and no group price → nothing to collect.
{
  const courses = resolveBillableCourses({ coursePrice: 0, subjectFees: [] }, []);
  assert.strictEqual(courses.length, 0, 'zero fee empty');
}

// Explicit zero subject fee should not fall back to group price.
{
  const courses = resolveBillableCourses(
    {
      coursePrice: 0,
      subjectFees: [{ subject: 'English', amount: 0 }],
    },
    [{ subjectName: 'English', pricePerClass: 500 }]
  );
  assert.strictEqual(courses.length, 0, 'explicit zero fee overrides group default');
}

// Legacy: one coursePrice must not be applied to every group.
{
  const courses = resolveBillableCourses(
    { coursePrice: 200, subjectFees: [] },
    [
      { subjectName: 'English', pricePerClass: 600 },
      { subjectName: 'IT', pricePerClass: 600 },
    ]
  );
  assert.strictEqual(courses.length, 1, 'do not duplicate coursePrice per group');
  assert.strictEqual(courses[0].amountDue, 200);
  assert.strictEqual(courses[0].subjectName, 'English + IT');
}

// Combined-name payments count English + IT receipts.
{
  const paidByStudentSubject = new Map([
    ['s1::english', 100],
    ['s1::it', 50],
  ]);
  const paidByStudent = new Map([['s1', 150]]);
  const paid = paidTowardCourse({
    studentId: 's1',
    course: { subjectName: 'English + IT', amountDue: 200 },
    courseCount: 1,
    paidByStudentSubject,
    paidByStudent,
  });
  assert.strictEqual(paid, 150);
}

{
  assert.strictEqual(courseStatus(600, 0), 'unpaid');
  assert.strictEqual(courseStatus(600, 200), 'partial');
  assert.strictEqual(courseStatus(600, 600), 'paid');
}

{
  const summary = summarizeCourses([
    { status: 'paid', amountDue: 600, amountPaid: 600 },
    { status: 'unpaid', amountDue: 600, amountPaid: 0 },
  ]);
  assert.strictEqual(summary.overallStatus, 'partial');
  assert.strictEqual(summary.amountRemaining, 600);
}

{
  const summary = summarizeCourses([
    { status: 'partial', amountDue: 600, amountPaid: 200 },
    { status: 'unpaid', amountDue: 600, amountPaid: 0 },
  ]);
  assert.strictEqual(summary.overallStatus, 'partial');
  assert.strictEqual(summary.amountRemaining, 1000);
}

console.log('test-payment-dues: ok');
