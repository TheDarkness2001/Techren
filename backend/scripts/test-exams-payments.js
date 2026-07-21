require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');
const ClassSchedule = require('../src/models/ClassSchedule');
const Student = require('../src/models/Student');

async function login(base, email, password, userType = 'teacher') {
  const res = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, userType }),
  });
  return res.json();
}

async function run() {
  await connectDB();
  await initDefaults();
  await ensureDevAccounts();

  const app = createApp();
  const server = app.listen(0);
  const base = `http://127.0.0.1:${server.address().port}/api/v1`;

  const adminLogin = await login(base, process.env.TEST_ADMIN_EMAIL || 'admin@techren.uz', process.env.TEST_ADMIN_PASSWORD || 'Admin123!');
  if (!adminLogin.success) {
    console.log('skip API test: admin login failed (set TEST_ADMIN_EMAIL / TEST_ADMIN_PASSWORD for Atlas)');
    server.close();
    await disconnectDB();
    return;
  }
  const adminHeaders = { Authorization: `Bearer ${adminLogin.data.accessToken}`, 'Content-Type': 'application/json' };

  const schedule = await ClassSchedule.findOne();
  const student = await Student.findOne({ email: 'student@techren.uz' });

  const createExam = await fetch(`${base}/exams`, {
    method: 'POST',
    headers: adminHeaders,
    body: JSON.stringify({
      examName: 'English Mid-Term',
      subject: 'English',
      class: schedule.className,
      scheduleId: schedule._id,
      examDate: new Date().toISOString(),
      startTime: '10:00',
      duration: 90,
      totalMarks: 100,
      passingMarks: 40,
      examType: 'mid-term',
    }),
  });
  const exam = (await createExam.json()).data;

  const markResult = await fetch(`${base}/exams/${exam.id}/results/${student._id}`, {
    method: 'PUT',
    headers: adminHeaders,
    body: JSON.stringify({ marksObtained: 75 }),
  });

  const createPayment = await fetch(`${base}/payments`, {
    method: 'POST',
    headers: adminHeaders,
    body: JSON.stringify({
      studentId: student._id,
      amount: 500000,
      paymentType: 'tuition-fee',
      subject: 'English',
      dueDate: new Date().toISOString(),
      academicYear: '2025-2026',
      term: '1st-term',
      month: 7,
      year: 2026,
      status: 'paid',
    }),
  });

  const revenue = await fetch(`${base}/revenue/summary`, { headers: adminHeaders });
  const studentLogin = await login(base, 'student@techren.uz', 'Student123!', 'student');
  const studentExams = await fetch(`${base}/exams`, {
    headers: { Authorization: `Bearer ${studentLogin.data.accessToken}` },
  });
  const studentPayments = await fetch(`${base}/payments`, {
    headers: { Authorization: `Bearer ${studentLogin.data.accessToken}` },
  });

  console.log('create exam:', createExam.status, exam?.results?.length);
  console.log('mark result:', markResult.status);
  console.log('create payment:', createPayment.status);
  console.log('revenue summary:', revenue.status, (await revenue.json()).data?.totalRevenue);
  console.log('student exams:', studentExams.status, (await studentExams.json()).data?.length);
  console.log('student payments:', studentPayments.status, (await studentPayments.json()).data?.length);

  const examSearch = await fetch(`${base}/exams?search=English`, { headers: adminHeaders });
  const examSearchJson = await examSearch.json();
  const paymentSearch = await fetch(`${base}/payments?search=English`, { headers: adminHeaders });
  const paymentSearchJson = await paymentSearch.json();

  console.log('exam search:', examSearch.status, examSearchJson.data?.length);
  console.log('payment search:', paymentSearch.status, paymentSearchJson.data?.length);

  server.close();
  await disconnectDB();
}

run().catch((e) => { console.error(e); process.exit(1); });
