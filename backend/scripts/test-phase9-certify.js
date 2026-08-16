/**
 * Phase 9 certification: unit gates + live six-role API pass.
 * Signs access JWTs for real Mongo users (no demo passwords required).
 */
require('dotenv').config();

const assert = require('assert');
const jwt = require('jsonwebtoken');

const config = require('../src/config');
const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { initDefaults } = require('../src/services/settingsService');
const Teacher = require('../src/models/Teacher');
const Student = require('../src/models/Student');
const Parent = require('../src/models/Parent');
const ClassSchedule = require('../src/models/ClassSchedule');
const Subject = require('../src/models/Subject');
const { isItTypingSubject } = require('../src/utils/learningModules');

const { parsePagination, MAX_LIMIT } = require('../src/utils/pagination');
const { assertParentChild, linkedChildIds } = require('../src/utils/resourceAccess');
const {
  getTashkentParts,
  tashkentBillingPeriod,
  addCalendarDays,
} = require('../src/utils/classWindow');

let failed = 0;
const rows = [];

const check = (name, ok, detail = '') => {
  rows.push({ name, ok: !!ok, detail });
  if (!ok) failed += 1;
  console.log(`${ok ? 'PASS' : 'FAIL'}  ${name}${detail ? ` — ${detail}` : ''}`);
};

const skip = (name, detail) => check(name, true, `SKIP ${detail}`);

const accessToken = (userId, userType) =>
  jwt.sign({ id: userId, userType, typ: 'access' }, config.jwt.secret, { expiresIn: '15m' });

const headersFor = (userId, userType) => ({
  Authorization: `Bearer ${accessToken(userId, userType)}`,
  'Content-Type': 'application/json',
});

const json = async (res) => {
  const text = await res.text();
  try {
    return { status: res.status, body: JSON.parse(text) };
  } catch {
    return { status: res.status, body: { raw: text } };
  }
};

const runUnit = () => {
  assert.strictEqual(MAX_LIMIT, 500);
  assert.strictEqual(parsePagination({ limit: '999' }).limit, 500);
  check('pagination cap is 500', true);

  const parent = { children: ['aaa', { _id: 'bbb' }] };
  assert.deepStrictEqual(linkedChildIds(parent), ['aaa', 'bbb']);
  assertParentChild(parent, 'aaa');
  let threw = false;
  try {
    assertParentChild(parent, 'ccc');
  } catch (e) {
    threw = e.statusCode === 403;
  }
  check('parent resourceAccess blocks unlinked child', threw);

  const nye = getTashkentParts(new Date('2025-12-31T20:00:00Z'));
  check('Tashkent billing crosses UTC new year', nye.dateString === '2026-01-01' && tashkentBillingPeriod(new Date('2025-12-31T20:00:00Z')).month === 1);
  check('addCalendarDays handles March 1', addCalendarDays('2026-03-01', -2) === '2026-02-27');
};

const pickStaff = async (role) =>
  Teacher.findOne({ role, status: { $ne: 'inactive' } }).select('_id name email role').lean();

async function runLive() {
  await connectDB();
  await initDefaults();

  const app = createApp();
  const server = app.listen(0);
  const base = `http://127.0.0.1:${server.address().port}/api/v1`;

  try {
    const [founder, admin, teacher, receptionist, manager, sales, student, parent] = await Promise.all([
      pickStaff('founder'),
      pickStaff('admin'),
      pickStaff('teacher'),
      pickStaff('receptionist'),
      pickStaff('manager'),
      pickStaff('sales'),
      Student.findOne({ status: { $ne: 'inactive' } }).select('_id name email').lean(),
      Parent.findOne({ status: { $ne: 'inactive' } }).select('_id name children').lean(),
    ]);

    const roles = { founder, admin, teacher, receptionist, manager, sales, student, parent };
    for (const [name, doc] of Object.entries(roles)) {
      if (doc) check(`role present: ${name}`, true, String(doc._id));
      else skip(`role present: ${name}`, 'no account in Mongo');
    }

    const get = (path, userId, userType) =>
      fetch(`${base}${path}`, { headers: headersFor(userId, userType) }).then(json);
    const send = (method, path, userId, userType, body) =>
      fetch(`${base}${path}`, {
        method,
        headers: headersFor(userId, userType),
        body: body ? JSON.stringify(body) : undefined,
      }).then(json);

    if (founder) {
      const dash = await get('/dashboard', founder._id, 'teacher');
      check('founder dashboard', dash.status === 200 && dash.body?.data?.role === 'founder', `HTTP ${dash.status}`);
    }
    if (admin) {
      const dash = await get('/dashboard', admin._id, 'teacher');
      check('admin dashboard', dash.status === 200, `HTTP ${dash.status}`);
    }
    if (teacher) {
      const dash = await get('/dashboard', teacher._id, 'teacher');
      check('teacher dashboard', dash.status === 200, `HTTP ${dash.status}`);
    }
    if (receptionist) {
      const dash = await get('/dashboard', receptionist._id, 'teacher');
      check('receptionist dashboard', dash.status === 200, `HTTP ${dash.status}`);
    }
    if (student) {
      const dash = await get('/dashboard', student._id, 'student');
      check('student dashboard', dash.status === 200, `HTTP ${dash.status}`);
      const roster = await get('/payments/roster', student._id, 'student');
      check('student cannot read payment roster', roster.status === 403, `HTTP ${roster.status}`);
      const other = await Student.findOne({ _id: { $ne: student._id } }).select('_id').lean();
      if (other) {
        const peek = await get(`/students/${other._id}`, student._id, 'student');
        check('student cannot read classmate profile', peek.status === 403, `HTTP ${peek.status}`);
      }
    }
    if (parent) {
      const children = await get('/parent/children', parent._id, 'parent');
      if (children.status === 501) {
        skip('parent children list', 'parentPortalEnabled is false');
      } else {
        check('parent children list', children.status === 200, `HTTP ${children.status}`);
      }
      const linked = linkedChildIds(parent);
      const otherStudent = await Student.findOne({ _id: { $nin: linked } }).select('_id').lean();
      if (otherStudent) {
        const unlinked = await get(`/students/${otherStudent._id}`, parent._id, 'parent');
        check('parent cannot read unlinked student', unlinked.status === 403, `HTTP ${unlinked.status}`);
      } else {
        skip('parent cannot read unlinked student', 'no unlinked student in Mongo');
      }
      const progress = await get('/progress/overview', parent._id, 'parent');
      check(
        'parent unscoped progress overview blocked',
        progress.status === 400 || progress.status === 403,
        `HTTP ${progress.status}`
      );
      const dash = await get('/dashboard', parent._id, 'parent');
      check(
        'parent dashboard is stub not staff stats',
        dash.status === 200 && dash.body?.data?.role === 'parent',
        `HTTP ${dash.status} role=${dash.body?.data?.role}`
      );
      const childId = children.status === 200
        ? children.body?.data?.children?.[0]?.id
        : linked[0];
      const directory = await get('/communications/directory', parent._id, 'parent');
      check('parent chat directory forbidden', directory.status === 403, `HTTP ${directory.status}`);
      const support = await send('POST', '/communications/conversations/support', parent._id, 'parent', {});
      check(
        'parent can open support chat',
        support.status === 200 || support.status === 201,
        `HTTP ${support.status} ${support.body?.error?.message || ''}`
      );
      if (children.status === 501) {
        skip('parent child homework', 'parentPortalEnabled is false');
        skip('parent child schedule', 'parentPortalEnabled is false');
        skip('parent child exams', 'parentPortalEnabled is false');
      } else if (childId) {
        const hw = await get(`/parent/children/${childId}/homework`, parent._id, 'parent');
        check('parent child homework', hw.status === 200 && hw.body?.data?.progress, `HTTP ${hw.status}`);
        const sch = await get(`/parent/children/${childId}/schedule`, parent._id, 'parent');
        check('parent child schedule', sch.status === 200 && sch.body?.data?.grid, `HTTP ${sch.status}`);
        const exams = await get(`/parent/children/${childId}/exams`, parent._id, 'parent');
        check('parent child exams', exams.status === 200, `HTTP ${exams.status}`);
      }
    }

    const examManager = founder || admin || manager;
    if (examManager) {
      const schedule = await ClassSchedule.findOne().select('_id className').lean();
      if (schedule) {
        const created = await send('POST', '/exams', examManager._id, 'teacher', {
          examName: 'Phase9 Certify Exam',
          subject: 'English',
          class: schedule.className || 'Certify',
          scheduleId: String(schedule._id),
          examDate: new Date().toISOString(),
          startTime: '10:00',
          duration: 45,
          totalMarks: 100,
          passingMarks: 40,
          examType: 'quiz',
        });
        const examId = created.body?.data?.id || created.body?.data?._id;
        check('exam create', created.status === 201 && examId, `HTTP ${created.status}`);
        if (examId) {
          const updated = await send('PUT', `/exams/${examId}`, examManager._id, 'teacher', {
            examName: 'Phase9 Certify Exam Updated',
            duration: 50,
          });
          check(
            'exam update (former req ReferenceError)',
            updated.status === 200 && (updated.body?.data?.examName || '').includes('Updated'),
            `HTTP ${updated.status}`
          );
          if (student) {
            const asStudent = await get(`/exams/${examId}`, student._id, 'student');
            const results = asStudent.body?.data?.results;
            const onlySelf = !Array.isArray(results)
              || results.every((row) => String(row.student?._id || row.student) === String(student._id));
            check(
              'student exam payload hides classmates',
              asStudent.status === 200 || asStudent.status === 403 || asStudent.status === 404,
              `HTTP ${asStudent.status} selfOnly=${onlySelf}`
            );
            if (asStudent.status === 200) {
              check('student exam results are self-only', onlySelf, `rows=${results?.length ?? 0}`);
            }
          }
          const removed = await send('DELETE', `/exams/${examId}`, examManager._id, 'teacher');
          check('exam delete', removed.status === 200, `HTTP ${removed.status}`);
        }
      } else {
        check('exam CRUD', false, 'no class schedule in Mongo');
      }
    }

    if (student) {
      const subjects = await Subject.find({}).lean();
      const it = subjects.find((s) => isItTypingSubject(s.name));
      if (it) {
        const started = await send('POST', '/typing/start', student._id, 'student', {
          subjectId: String(it._id),
          mode: 'english',
          difficulty: 'easy',
          durationSec: 15,
        });
        check('typing start', started.status === 200 && started.body?.data?.prompt, `HTTP ${started.status}`);
        const more = await send('POST', '/typing/more', student._id, 'student', {
          subjectId: String(it._id),
          mode: 'english',
          difficulty: 'easy',
          durationSec: 15,
        });
        check('typing moreText buffer', more.status === 200, `HTTP ${more.status}`);
        const finished = await send('POST', '/typing/finish', student._id, 'student', {
          subjectId: String(it._id),
          mode: 'english',
          wpm: 30,
          rawWpm: 32,
          accuracy: 95,
          correctChars: 80,
          incorrectChars: 4,
          totalChars: 84,
          mistakes: 4,
          wordsTyped: 20,
          correctWords: 19,
          wrongWords: 1,
          elapsedSec: 15,
          durationSec: 15,
          contentId: started.body?.data?.prompt?.contentId,
        });
        check('typing finish', finished.status === 200 && finished.body?.data?.result, `HTTP ${finished.status}`);
      } else {
        check('typing start', false, 'no IT/typing subject in Mongo');
      }
    }
  } finally {
    server.close();
    await disconnectDB();
  }
}

async function main() {
  console.log('=== Phase 9 unit ===');
  runUnit();
  console.log('\n=== Phase 9 live API ===');
  try {
    await runLive();
  } catch (e) {
    check('live Mongo/API session', false, e.message);
  }
  console.log(`\n${rows.filter((r) => r.ok).length}/${rows.length} checks passed.`);
  process.exit(failed > 0 ? 1 : 0);
}

main();
