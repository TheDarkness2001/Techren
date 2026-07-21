const { toMinutes } = require('./timeUtils');

const TZ = 'Asia/Tashkent';

const getTashkentParts = (date = new Date()) => {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: TZ,
    weekday: 'short',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).formatToParts(date);

  let day = parts.find((p) => p.type === 'weekday')?.value || 'Mon';
  day = day.replace('.', '');
  if (day.length > 3) day = day.slice(0, 3);

  const hour = parts.find((p) => p.type === 'hour')?.value || '00';
  const minute = parts.find((p) => p.type === 'minute')?.value || '00';

  return {
    day,
    time: `${hour.padStart(2, '0')}:${minute.padStart(2, '0')}`,
    dateString: new Intl.DateTimeFormat('en-CA', { timeZone: TZ }).format(date),
  };
};

const addMinutesToTime = (time, minutes) => {
  const total = toMinutes(time) + minutes;
  const h = Math.floor(total / 60) % 24;
  const m = total % 60;
  return `${String(h).padStart(2, '0')}:${String(m).padStart(2, '0')}`;
};

const isScheduleToday = (schedule, parts = getTashkentParts()) =>
  (schedule.scheduledDays || []).includes(parts.day);

const isWithinClassWindow = (schedule, graceMinutes = 30, parts = getTashkentParts()) => {
  if (!isScheduleToday(schedule, parts)) return false;
  const now = toMinutes(parts.time);
  const start = toMinutes(schedule.startTime);
  const end = toMinutes(addMinutesToTime(schedule.endTime, graceMinutes));
  return now >= start && now <= end;
};

const canBypassTimeWindow = (user) =>
  user && ['founder', 'admin', 'manager'].includes(user.role);

module.exports = {
  getTashkentParts,
  isScheduleToday,
  isWithinClassWindow,
  canBypassTimeWindow,
  addMinutesToTime,
};
