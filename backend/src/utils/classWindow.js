const { toMinutes } = require('./timeUtils');

const TZ = 'Asia/Tashkent';

const getTashkentParts = (date = new Date()) => {
  const parts = new Intl.DateTimeFormat('en-US', {
    timeZone: TZ,
    weekday: 'short',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    hour12: false,
  }).formatToParts(date);

  let day = parts.find((p) => p.type === 'weekday')?.value || 'Mon';
  day = day.replace('.', '');
  if (day.length > 3) day = day.slice(0, 3);

  const hour = parts.find((p) => p.type === 'hour')?.value || '00';
  const minute = parts.find((p) => p.type === 'minute')?.value || '00';
  const year = Number(parts.find((p) => p.type === 'year')?.value || '0');
  const month = Number(parts.find((p) => p.type === 'month')?.value || '0');
  const dayOfMonth = Number(parts.find((p) => p.type === 'day')?.value || '0');

  return {
    day,
    time: `${hour.padStart(2, '0')}:${minute.padStart(2, '0')}`,
    dateString: new Intl.DateTimeFormat('en-CA', { timeZone: TZ }).format(date),
    year,
    month,
    dayOfMonth,
  };
};

/** Academy billing calendar (UTC+5, no DST) — never use host getMonth(). */
const tashkentBillingPeriod = (date = new Date()) => {
  const parts = getTashkentParts(date);
  return { month: parts.month, year: parts.year };
};

const billingPeriodFromQuery = (query = {}) => {
  const current = tashkentBillingPeriod();
  const month = Math.min(12, Math.max(1, Number(query.month) || current.month));
  const year = Number(query.year) || current.year;
  return { month, year };
};

/** Add whole calendar days to a YYYY-MM-DD string without host-TZ drift. */
const addCalendarDays = (dateString, days) => {
  const [y, m, d] = String(dateString).slice(0, 10).split('-').map(Number);
  if (!y || !m || !d) return String(dateString).slice(0, 10);
  return new Date(Date.UTC(y, m - 1, d + Number(days || 0))).toISOString().slice(0, 10);
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
  tashkentBillingPeriod,
  billingPeriodFromQuery,
  addCalendarDays,
  isScheduleToday,
  isWithinClassWindow,
  canBypassTimeWindow,
  addMinutesToTime,
};
