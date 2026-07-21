const Attendance = require('../models/Attendance');
const Teacher = require('../models/Teacher');
const { getBranchFilter } = require('../utils/branchFilter');
const { getTashkentParts } = require('../utils/classWindow');

const format = (doc) => ({
  id: doc._id,
  teacher: doc.teacher,
  date: doc.date,
  checkInAt: doc.checkInAt,
  checkOutAt: doc.checkOutAt,
  checkInPhoto: doc.checkInPhoto,
  checkOutPhoto: doc.checkOutPhoto,
  gps: doc.gps,
  status: doc.status,
  dailyStatus: doc.dailyStatus,
  notes: doc.notes,
});

const resolveDailyStatus = (record) => {
  if (!record) return null;
  if (record.dailyStatus) return record.dailyStatus;
  if (record.checkInAt) return 'present';
  return null;
};

const formatRosterAttendance = (record) => {
  if (!record) return null;
  return {
    id: record._id,
    dailyStatus: resolveDailyStatus(record),
    notes: record.notes,
    checkInAt: record.checkInAt,
    checkOutAt: record.checkOutAt,
  };
};

const listOwn = async (teacherId, query = {}) => {
  const filter = { teacher: teacherId };
  if (query.date) filter.date = query.date;
  const items = await Attendance.find(filter).sort({ date: -1 }).limit(30);
  return items.map(format);
};

const checkIn = async (teacher, data = {}) => {
  const { dateString } = getTashkentParts();
  const existing = await Attendance.findOne({ teacher: teacher._id, date: dateString });
  if (existing?.checkInAt) {
    throw Object.assign(new Error('Already checked in today'), { statusCode: 409, code: 'DUPLICATE' });
  }

  const record = existing || new Attendance({ teacher: teacher._id, date: dateString, branchId: teacher.branchId });
  record.checkInAt = new Date();
  record.checkInPhoto = data.photo;
  record.gps = data.gps;
  record.status = 'checked_in';
  await record.save();
  return format(record);
};

const checkOut = async (teacher, data = {}) => {
  const { dateString } = getTashkentParts();
  const record = await Attendance.findOne({ teacher: teacher._id, date: dateString });
  if (!record?.checkInAt) {
    throw Object.assign(new Error('Check in first'), { statusCode: 400, code: 'VALIDATION_ERROR' });
  }
  if (record.checkOutAt) {
    throw Object.assign(new Error('Already checked out today'), { statusCode: 409, code: 'DUPLICATE' });
  }

  record.checkOutAt = new Date();
  record.checkOutPhoto = data.photo;
  record.status = 'checked_out';
  await record.save();
  return format(record);
};

const getTodayStatus = async (teacherId) => {
  const { dateString } = getTashkentParts();
  const record = await Attendance.findOne({ teacher: teacherId, date: dateString });
  return record ? format(record) : null;
};

const listRoster = async (req, query = {}) => {
  const { dateString } = getTashkentParts();
  const date = query.date || dateString;
  // Founders are not tracked for staff attendance.
  if (query.role === 'founder') return [];

  const filter = { status: 'active', role: { $ne: 'founder' }, ...getBranchFilter(req) };
  if (query.role && query.role !== 'all') filter.role = query.role;

  const teachers = await Teacher.find(filter).sort({ name: 1 });
  const records = await Attendance.find({
    teacher: { $in: teachers.map((t) => t._id) },
    date,
  });
  const recordByTeacher = new Map(records.map((r) => [String(r.teacher), r]));

  return teachers.map((teacher) => {
    const publicTeacher = teacher.toPublicJSON();
    const record = recordByTeacher.get(String(teacher._id));
    return {
      teacher: {
        id: publicTeacher.id,
        name: publicTeacher.name,
        email: publicTeacher.email,
        phone: publicTeacher.phone,
        role: publicTeacher.role,
        teacherId: publicTeacher.teacherId,
        profileImage: publicTeacher.profileImage,
        subjects: publicTeacher.subject || [],
      },
      attendance: formatRosterAttendance(record),
    };
  });
};

const markRoster = async (req, { teacherId, date, dailyStatus, notes }) => {
  const teacher = await Teacher.findOne({ _id: teacherId, ...getBranchFilter(req) });
  if (!teacher) {
    throw Object.assign(new Error('Teacher not found'), { statusCode: 404, code: 'NOT_FOUND' });
  }
  if (teacher.role === 'founder') {
    throw Object.assign(new Error('Founders do not require attendance'), {
      statusCode: 400,
      code: 'VALIDATION_ERROR',
    });
  }

  const { dateString } = getTashkentParts();
  const targetDate = date || dateString;
  const record = await Attendance.findOneAndUpdate(
    { teacher: teacher._id, date: targetDate },
    {
      $set: {
        dailyStatus,
        notes: notes || undefined,
        branchId: teacher.branchId,
      },
      $setOnInsert: {
        teacher: teacher._id,
        date: targetDate,
        status: 'pending',
      },
    },
    { upsert: true, new: true, runValidators: true }
  );

  return {
    teacher: teacher.toPublicJSON(),
    attendance: formatRosterAttendance(record),
  };
};

module.exports = {
  listOwn,
  checkIn,
  checkOut,
  getTodayStatus,
  listRoster,
  markRoster,
  format,
};
