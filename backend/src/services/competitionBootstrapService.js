const Student = require('../models/Student');
const Teacher = require('../models/Teacher');
const ExamGroup = require('../models/ExamGroup');
const Penalty = require('../models/Penalty');
const PresentationScore = require('../models/PresentationScore');

const ensureCompetitionDemoContent = async () => {
  const exists = await Penalty.exists({});
  if (exists) return;

  const group = await ExamGroup.findOne({ groupName: 'English Morning A' });
  const student = group?.students?.[0] ? await Student.findById(group.students[0]) : null;
  if (!student?.branchId) return;

  const teacher = await Teacher.findOne({ email: 'teacher@techren.uz' });
  if (!teacher) return;

  await Penalty.create({
    studentId: student._id,
    type: 'spoken_uzbek',
    points: -5,
    quantity: 1,
    date: new Date(),
    notes: 'Demo penalty',
    source: 'manual',
    recordedBy: teacher._id,
    branchId: student.branchId,
  });

  await PresentationScore.create({
    studentId: student._id,
    score: 8,
    date: new Date(),
    notes: 'Demo presentation',
    evaluatedBy: teacher._id,
    branchId: student.branchId,
  });
};

module.exports = { ensureCompetitionDemoContent };
