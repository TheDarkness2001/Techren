const express = require('express');
const authRoutes = require('./authRoutes');
const branchRoutes = require('./branchRoutes');
const teacherRoutes = require('./teacherRoutes');
const studentRoutes = require('./studentRoutes');
const settingsRoutes = require('./settingsRoutes');
const dashboardRoutes = require('./dashboardRoutes');
const subjectRoutes = require('./subjectRoutes');
const examGroupRoutes = require('./examGroupRoutes');
const classScheduleRoutes = require('./classScheduleRoutes');
const timetableRoutes = require('./timetableRoutes');
const teacherSelfAttendanceRoutes = require('./teacherSelfAttendanceRoutes');
const studentAttendanceRoutes = require('./studentAttendanceRoutes');
const feedbackRoutes = require('./feedbackRoutes');
const examRoutes = require('./examRoutes');
const paymentRoutes = require('./paymentRoutes');
const revenueRoutes = require('./revenueRoutes');
const branchExpenseRoutes = require('./branchExpenseRoutes');
const homeworkRoutes = require('./homeworkRoutes');
const sentenceRoutes = require('./sentenceRoutes');
const listeningRoutes = require('./listeningRoutes');
const videoLessonRoutes = require('./videoLessonRoutes');
const penaltyRoutes = require('./penaltyRoutes');
const presentationRoutes = require('./presentationRoutes');
const bonusRoutes = require('./bonusRoutes');
const staffEarningRoutes = require('./staffEarningRoutes');
const staffPayoutRoutes = require('./staffPayoutRoutes');
const recycleBinRoutes = require('./recycleBinRoutes');
const notificationRoutes = require('./notificationRoutes');
const gamificationRoutes = require('./gamificationRoutes');
const parentRoutes = require('./parentRoutes');
const walletRoutes = require('./walletRoutes');
const uploadRoutes = require('./uploadRoutes');
const progressRoutes = require('./progressRoutes');
const learningRoutes = require('./learningRoutes');
const ieltsRoutes = require('./ieltsRoutes');
const learningQuizRoutes = require('./learningQuizRoutes');
const typingRoutes = require('./typingRoutes');
const communicationRoutes = require('./communicationRoutes');
const newsRoutes = require('./newsRoutes');
const pollRoutes = require('./pollRoutes');

const router = express.Router();

router.use('/auth', authRoutes);
router.use('/branches', branchRoutes);
router.use('/teachers', teacherRoutes);
router.use('/students', studentRoutes);
router.use('/settings', settingsRoutes);
router.use('/dashboard', dashboardRoutes);
router.use('/subjects', subjectRoutes);
router.use('/exam-groups', examGroupRoutes);
router.use('/class-schedules', classScheduleRoutes);
router.use('/timetable', timetableRoutes);
router.use('/attendance', teacherSelfAttendanceRoutes);
router.use('/student-attendance', studentAttendanceRoutes);
router.use('/feedback', feedbackRoutes);
router.use('/exams', examRoutes);
router.use('/payments', paymentRoutes);
router.use('/revenue', revenueRoutes);
router.use('/branch-expenses', branchExpenseRoutes);
router.use('/homework', homeworkRoutes);
router.use('/sentences', sentenceRoutes);
router.use('/listening', listeningRoutes);
router.use('/video-lessons', videoLessonRoutes);
router.use('/penalties', penaltyRoutes);
router.use('/presentations', presentationRoutes);
router.use('/bonuses', bonusRoutes);
router.use('/staff-earnings', staffEarningRoutes);
router.use('/staff-payouts', staffPayoutRoutes);
router.use('/admin/recycle-bin', recycleBinRoutes);
router.use('/notifications', notificationRoutes);
router.use('/gamification', gamificationRoutes);
router.use('/parent', parentRoutes);
router.use('/wallet', walletRoutes);
router.use('/upload', uploadRoutes);
router.use('/progress', progressRoutes);
router.use('/learning', learningRoutes);
router.use('/ielts', ieltsRoutes);
router.use('/quizzes', learningQuizRoutes);
router.use('/typing', typingRoutes);
router.use('/communications', communicationRoutes);
router.use('/news', newsRoutes);
router.use('/polls', pollRoutes);

const { getConnectionInfo } = require('../config/database');

router.get('/health', (req, res) => {
  res.json({
    success: true,
    data: {
      status: 'ok',
      version: '1.0.0',
      uptime: Math.floor(process.uptime()),
      timestamp: new Date().toISOString(),
      database: getConnectionInfo(),
    },
  });
});

module.exports = router;
