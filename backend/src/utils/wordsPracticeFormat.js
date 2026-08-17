const shuffle = (items) => {
  const copy = [...items];
  for (let i = copy.length - 1; i > 0; i -= 1) {
    const j = Math.floor(Math.random() * (i + 1));
    [copy[i], copy[j]] = [copy[j], copy[i]];
  }
  return copy;
};

const scrambleWord = (text) => {
  const letters = [...String(text || '')];
  if (letters.length < 2) return letters.join(' ');
  let scrambled = shuffle(letters).join('');
  let guard = 0;
  while (scrambled === text && guard < 8) {
    scrambled = shuffle(letters).join('');
    guard += 1;
  }
  return scrambled.split('').join(' ');
};

const maskWord = (text) => {
  const chars = [...String(text || '')];
  if (chars.length === 0) return '';
  const hideCount = Math.max(1, Math.floor(chars.length * 0.4));
  const indexes = shuffle(chars.map((_, i) => i).filter((i) => /[a-zA-Z']/.test(chars[i]))).slice(0, hideCount);
  return chars.map((char, i) => (indexes.includes(i) ? '_' : char)).join(' ');
};

module.exports = { shuffle, scrambleWord, maskWord };
