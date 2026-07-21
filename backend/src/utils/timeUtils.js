const toMinutes = (time) => {
  const [h, m] = time.split(':').map(Number);
  return h * 60 + m;
};

const timesOverlap = (startA, endA, startB, endB) =>
  toMinutes(startA) < toMinutes(endB) && toMinutes(endA) > toMinutes(startB);

const daysOverlap = (daysA, daysB) => daysA.some((d) => daysB.includes(d));

module.exports = { toMinutes, timesOverlap, daysOverlap };
