require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const examService = require('../src/services/examService');
const paymentService = require('../src/services/paymentService');
const Exam = require('../src/models/Exam');
const Payment = require('../src/models/Payment');

const mockReq = (query = {}) => ({
  query,
  userType: 'teacher',
  user: { role: 'founder', branchId: null },
  branchId: null,
});

async function run() {
  await connectDB();

  const sampleExam = await Exam.findOne().select('examName subject class');
  const samplePayment = await Payment.findOne().populate('student', 'name').select('subject student');

  if (!sampleExam) {
    console.log('skip exam search: no exams in database');
  } else {
    const term = sampleExam.subject || sampleExam.examName || sampleExam.class;
    const all = await examService.list(mockReq({ page: 1, limit: 5, includeArchived: 'true' }));
    const filtered = await examService.list(mockReq({ page: 1, limit: 5, search: term, includeArchived: 'true' }));
    console.log('exam search term:', term);
    console.log('exam list total:', all.meta.total, 'filtered:', filtered.meta.total);
    if (filtered.meta.total > all.meta.total) {
      throw new Error('exam search returned more results than unfiltered list');
    }
    if (filtered.meta.total === 0) {
      throw new Error('exam search returned zero matches for known term');
    }
  }

  if (!samplePayment) {
    console.log('skip payment search: no payments in database');
  } else {
    const term = samplePayment.subject
      || samplePayment.student?.name?.split(' ')[0]
      || 'payment';
    const all = await paymentService.list(mockReq({ page: 1, limit: 5 }));
    const filtered = await paymentService.list(mockReq({ page: 1, limit: 5, search: term }));
    console.log('payment search term:', term);
    console.log('payment list total:', all.meta.total, 'filtered:', filtered.meta.total);
    if (filtered.meta.total > all.meta.total) {
      throw new Error('payment search returned more results than unfiltered list');
    }
    if (filtered.meta.total === 0) {
      throw new Error('payment search returned zero matches for known term');
    }
  }

  console.log('finance search filters OK');
  await disconnectDB();
}

run().catch(async (error) => {
  console.error(error);
  await disconnectDB();
  process.exit(1);
});
