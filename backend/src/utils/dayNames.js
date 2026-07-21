const { DAYS } = require('../models/ClassSchedule');

const DAY_ALIASES = {
  mon: 'Mon',
  monday: 'Mon',
  tue: 'Tue',
  tues: 'Tue',
  tuesday: 'Tue',
  wed: 'Wed',
  wednesday: 'Wed',
  thu: 'Thu',
  thur: 'Thu',
  thurs: 'Thu',
  thursday: 'Thu',
  fri: 'Fri',
  friday: 'Fri',
  sat: 'Sat',
  saturday: 'Sat',
  sun: 'Sun',
  sunday: 'Sun',
};

/** Normalize full or short day names to Mon..Sun. Returns null if unknown. */
const normalizeDay = (value) => {
  if (value == null) return null;
  const raw = String(value).trim();
  if (!raw) return null;
  if (DAYS.includes(raw)) return raw;
  const alias = DAY_ALIASES[raw.toLowerCase()];
  if (alias) return alias;
  const short = raw.slice(0, 3);
  return DAYS.find((d) => d.toLowerCase() === short.toLowerCase()) || null;
};

const normalizeScheduledDays = (days) => {
  const seen = new Set();
  const out = [];
  for (const day of days || []) {
    const normalized = normalizeDay(day);
    if (normalized && !seen.has(normalized)) {
      seen.add(normalized);
      out.push(normalized);
    }
  }
  return out;
};

module.exports = { DAYS, normalizeDay, normalizeScheduledDays, DAY_ALIASES };
