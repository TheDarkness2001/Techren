require('dotenv').config();

const connectDB = require('../src/config/database');
const { disconnectDB } = require('../src/config/database');
const createApp = require('../src/app');
const { ensureDevAccounts } = require('../src/services/bootstrapService');
const { initDefaults } = require('../src/services/settingsService');
const Lesson = require('../src/models/Lesson');

async function login(base, email, password) {
  const res = await fetch(`${base}/auth/login`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ email, password, userType: 'teacher' }),
  });
  return { status: res.status, json: await res.json() };
}

async function run() {
  await connectDB();
  await initDefaults();
  await ensureDevAccounts();

  const app = createApp();
  const server = app.listen(0);
  const base = `http://127.0.0.1:${server.address().port}/api/v1`;

  const adminLogin = await login(base, 'admin@techren.uz', 'Admin123!');
  const headers = {
    Authorization: `Bearer ${adminLogin.json.data.accessToken}`,
    'Content-Type': 'application/json',
  };

  const languages = await fetch(`${base}/homework/languages?moduleType=words`, { headers });
  const languagesJson = await languages.json();
  const languageId = languagesJson.data?.[0]?.id;

  const levels = languageId
    ? await fetch(`${base}/homework/levels?languageId=${languageId}&moduleType=words`, { headers })
    : null;
  const levelsJson = levels ? await levels.json() : null;
  const levelId = levelsJson?.data?.[0]?.id;

  const lessons = levelId
    ? await fetch(`${base}/homework/lessons?levelId=${levelId}&type=words`, { headers })
    : null;
  const lessonsJson = lessons ? await lessons.json() : null;
  const lessonId = lessonsJson?.data?.[0]?.id ?? (await Lesson.findOne({ type: 'words' }))?._id?.toString();

  const listWords = lessonId
    ? await fetch(`${base}/homework/words?lessonId=${lessonId}`, { headers })
    : null;
  const listJson = listWords ? await listWords.json() : null;

  const addWord = lessonId
    ? await fetch(`${base}/homework/words`, {
        method: 'POST',
        headers,
        body: JSON.stringify({ lessonId, english: 'cms-test', uzbek: 'sinov' }),
      })
    : null;
  const addJson = addWord ? await addWord.json() : null;
  const wordId = addJson?.data?.id;

  const deleteWord = wordId
    ? await fetch(`${base}/homework/words/${wordId}`, { method: 'DELETE', headers })
    : null;

  console.log('admin login:', adminLogin.status);
  console.log('languages:', languages.status, languagesJson.data?.length);
  console.log('levels:', levels?.status, levelsJson?.data?.length);
  console.log('lessons:', lessons?.status, lessonsJson?.data?.length);
  console.log('list words:', listWords?.status, listJson?.data?.length);
  console.log('add word:', addWord?.status, addJson?.data?.english);
  console.log('delete word:', deleteWord?.status);

  const sentenceLanguages = await fetch(`${base}/sentences/languages`, { headers });
  const sentenceLanguagesJson = await sentenceLanguages.json();
  const sentenceLanguageId = sentenceLanguagesJson.data?.[0]?.id;

  const sentenceLevels = sentenceLanguageId
    ? await fetch(`${base}/sentences/levels?languageId=${sentenceLanguageId}&moduleType=sentences`, { headers })
    : null;
  const sentenceLevelsJson = sentenceLevels ? await sentenceLevels.json() : null;
  const sentenceLevelId = sentenceLevelsJson?.data?.[0]?.id;

  const sentenceLessons = sentenceLevelId
    ? await fetch(`${base}/sentences/lessons?levelId=${sentenceLevelId}`, { headers })
    : null;
  const sentenceLessonsJson = sentenceLessons ? await sentenceLessons.json() : null;
  const sentenceLessonId = sentenceLessonsJson?.data?.[0]?.id;

  const listSentences = sentenceLessonId
    ? await fetch(`${base}/sentences?lessonId=${sentenceLessonId}`, { headers })
    : null;
  const listSentencesJson = listSentences ? await listSentences.json() : null;

  const addSentence = sentenceLessonId
    ? await fetch(`${base}/sentences`, {
        method: 'POST',
        headers,
        body: JSON.stringify({ lessonId: sentenceLessonId, english: 'CMS test sentence.', uzbek: 'Sinov gap.' }),
      })
    : null;
  const addSentenceJson = addSentence ? await addSentence.json() : null;
  const sentenceId = addSentenceJson?.data?.id;

  const deleteSentence = sentenceId
    ? await fetch(`${base}/sentences/${sentenceId}`, { method: 'DELETE', headers })
    : null;

  console.log('sentence languages:', sentenceLanguages.status, sentenceLanguagesJson.data?.length);
  console.log('sentence levels:', sentenceLevels?.status, sentenceLevelsJson?.data?.length);
  console.log('sentence lessons:', sentenceLessons?.status, sentenceLessonsJson?.data?.length);
  console.log('list sentences:', listSentences?.status, listSentencesJson?.data?.length);
  console.log('add sentence:', addSentence?.status, addSentenceJson?.data?.english);
  console.log('delete sentence:', deleteSentence?.status);

  const ok =
    adminLogin.status === 200 &&
    languages.status === 200 &&
    addWord?.status === 201 &&
    sentenceLanguages.status === 200 &&
    addSentence?.status === 201;

  const listeningLanguages = await fetch(`${base}/listening/languages`, { headers });
  const listeningLanguagesJson = await listeningLanguages.json();
  const listeningLanguageId = listeningLanguagesJson.data?.[0]?.id;

  const listeningLevels = listeningLanguageId
    ? await fetch(`${base}/homework/levels?languageId=${listeningLanguageId}&moduleType=listening`, { headers })
    : null;
  const listeningLevelsJson = listeningLevels ? await listeningLevels.json() : null;
  const listeningLevelId = listeningLevelsJson?.data?.[0]?.id;

  const listListening = listeningLevelId
    ? await fetch(`${base}/listening/exercises?levelId=${listeningLevelId}`, { headers })
    : null;
  const listListeningJson = listListening ? await listListening.json() : null;

  const addListening = listeningLevelId
    ? await fetch(`${base}/listening/exercises`, {
        method: 'POST',
        headers,
        body: JSON.stringify({
          levelId: listeningLevelId,
          title: 'CMS Listening Test',
          script: 'This is a cms listening test script.',
          audioFile: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
        }),
      })
    : null;
  const addListeningJson = addListening ? await addListening.json() : null;
  const listeningExerciseId = addListeningJson?.data?.id;

  const deleteListening = listeningExerciseId
    ? await fetch(`${base}/listening/exercises/${listeningExerciseId}`, { method: 'DELETE', headers })
    : null;

  console.log('listening languages:', listeningLanguages.status, listeningLanguagesJson.data?.length);
  console.log('listening levels:', listeningLevels?.status, listeningLevelsJson?.data?.length);
  console.log('list listening:', listListening?.status, listListeningJson?.data?.length);
  console.log('add listening:', addListening?.status, addListeningJson?.data?.title);
  console.log('delete listening:', deleteListening?.status);

  const allOk =
    ok &&
    listeningLanguages.status === 200 &&
    addListening?.status === 201;

  server.close();
  await disconnectDB();
  process.exit(allOk ? 0 : 1);
}

run().catch((e) => {
  console.error(e);
  process.exit(1);
});
