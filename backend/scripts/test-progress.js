require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');
const Student = require('../src/models/Student');
const ExamGroup = require('../src/models/ExamGroup');
const Lesson = require('../src/models/Lesson');

async function login(base, email, password, userType = 'student') {
  const res = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, userType }),
  });
  return { status: res.status, json: await res.json() };
}

async function run() {
  await connectDB();
  await initDefaults();
  await ensureDevAccounts();

  const app = createApp();
  const server = app.listen(0);
  const base = `http://127.0.0.1:${server.address().port}/api/v1`;

  const studentLogin = await login(base, 'student@techren.uz', 'Student123!');
  const adminLogin = await login(base, 'admin@techren.uz', 'Admin123!', 'teacher');
  const studentHeaders = { Authorization: `Bearer ${studentLogin.json.data.accessToken}` };
  const adminHeaders = { Authorization: `Bearer ${adminLogin.json.data.accessToken}` };

  const overview = await fetch(`${base}/progress/overview`, { headers: studentHeaders });
  const overviewJson = await overview.json();

  const students = await fetch(`${base}/progress/students`, { headers: adminHeaders });
  const studentsJson = await students.json();

  const group = await ExamGroup.findOne();
  const groupRes = group
    ? await fetch(`${base}/progress/groups/${group._id}`, { headers: adminHeaders })
    : null;
  const groupJson = groupRes ? await groupRes.json() : null;

  const lesson = await Lesson.findOne({ type: 'words' });
  const lessonRes = lesson
    ? await fetch(`${base}/homework/lessons/${lesson._id}/student-progress`, { headers: adminHeaders })
    : null;
  const lessonJson = lessonRes ? await lessonRes.json() : null;

  console.log('student login:', studentLogin.status);
  console.log('overview:', overview.status, overviewJson.data?.student?.name);
  console.log('words accuracy:', overviewJson.data?.modules?.words?.accuracy);
  console.log('gamification xp:', overviewJson.data?.gamification?.totalXp);
  console.log('admin students:', students.status, studentsJson.data?.items?.length);
  console.log('group progress:', groupRes?.status, groupJson?.data?.aggregate?.studentCount);
  console.log('lesson progress:', lessonRes?.status, lessonJson?.data?.students?.length);

  const student = await Student.findOne();
  const vocabLessonsRes = student
    ? await fetch(`${base}/progress/students/${student._id}/vocab-lessons`, { headers: adminHeaders })
    : null;
  const vocabLessonsJson = vocabLessonsRes ? await vocabLessonsRes.json() : null;
  console.log('student vocab lessons:', vocabLessonsRes?.status, vocabLessonsJson?.data?.lessons?.length);

  server.close();
  await disconnectDB();
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
