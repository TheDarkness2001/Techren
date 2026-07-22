# TechRen EDU

Cross-platform education platform (Flutter + Node.js).

## Project structure

```
Techren app/
├── backend/          # Node.js REST API
├── techren_edu/      # Flutter app (Android, iOS, Windows, Linux)
└── docs/             # Architecture & design documents
```

## Quick start

### Backend

```bash
cd backend
cp .env.example .env
npm install
npm start              # http://localhost:5002
```

Development uses an **in-memory MongoDB** fallback when local MongoDB is unavailable. Create real users from the admin/founder account (or `npm run seed` for founder only).

### Flutter

```bash
cd techren_edu
flutter pub get
flutter run -d windows
```

For Android emulator:

```bash
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5002/api/v1
```

### Docker (staging stack)

```bash
cp .env.docker.example .env.docker
# Edit JWT_SECRET and FOUNDER_PASSWORD

docker compose --env-file .env.docker up -d --build
docker compose exec api node scripts/seed.js   # first deploy only
```

API: `http://localhost:5002/api/v1`

See [docs/08-DEPLOYMENT.md](docs/08-DEPLOYMENT.md) for Atlas, PM2, CI, and production builds.

### CI

```bash
cd backend
JWT_SECRET=local-test-secret-minimum-32-characters npm test
```

GitHub Actions runs backend tests + `flutter analyze` on push/PR (`.github/workflows/ci.yml`).

## Phase 9 status

| Module | Status |
|--------|--------|
| Foundation | ✅ |
| Identity & Branches | ✅ |
| Scheduling | ✅ |
| Attendance & Feedback | ✅ |
| Exams & Payments | ✅ |
| Learning: Words | ✅ |
| Learning: Sentences | ✅ |
| Learning: Listening | ✅ |
| Learning: Video | ✅ |
| Competition | ✅ |
| Staff Finance | ✅ |
| Recycle Bin & Safety | ✅ |
| Notifications | ✅ |
| Gamification | ✅ |
| Parent Portal | ✅ |
| Wallet | ✅ |
| Upload & Import | ✅ |
| Settings & Permissions | ✅ |
| Student Progress | ✅ |
| Learning CMS | ✅ |
| Exam Control | ✅ |

**Competition highlights:** penalty ledger (spoken Uzbek, missed homework, etc.), presentation scores 1–10, monthly 40/30/30 bonus split, top presenters leaderboard, period closure history.

**Staff Finance highlights:** teacher earnings ledger (salary, bonus, penalty, adjustment), account sync (pending/approved/paid), payout preview and creation, complete/cancel payout workflow, teacher self-service view.

**Recycle Bin highlights:** soft-delete plugin on learning content, snapshot history, cascade restore by group, mark important, purge single or bulk old items.

**Notifications highlights:** in-app inbox with read/unread, FCM stub (logs when Firebase not configured), parent alert settings per student (quiet hours, event toggles), feedback-submit trigger with push dedup.

**Gamification highlights:** XP on practice (words +5, sentences +10, listening +15–25, video +20), daily streaks, 10 achievements, XP leaderboard, weak-module recommendations — additive layer on existing progress.

**Parent Portal highlights:** parent login with child linking, child overview (feedback/attendance/exams), parent comments on teacher feedback, feature-flagged via `parentPortalEnabled`.

**Wallet highlights:** student balance in tyiyn (100 tyiyn = 1 so'm), top-up (min 10,000 so'm), immutable transaction ledger, admin deduct/penalty/adjustment — feature-flagged via `walletEnabled`.

**Upload highlights:** DOCX/TXT pair parsing, bulk word/sentence import, image and audio file upload with static URLs — staff `canManageHomework` or privileged roles.

**Settings highlights:** founder/admin UI for feature flags (wallet, gamification, parent portal) and editable role permission matrix (teacher, sales, receptionist).

**Progress highlights:** unified student progress hub (words, sentences, listening, video, XP), admin student list with search, **By Group** tab with aggregate stats per exam group, per-lesson vocab progress for staff.

**Learning CMS highlights:** staff tree browser (language → level → lesson), **Words**, **Sentences**, and **Listening** tabs with CRUD (audio upload for listening), link to bulk DOCX import.

**Exam Control highlights:** per-level practice unlock and per-lesson exam unlock matrix by exam group — toggles `practiceUnlockedFor` / `examUnlockedFor` on levels and lessons.

**Video highlights:** YouTube lessons with per-group watch unlock (one per level), watch-percent gating for exams, topic tests (practice + exam), anti-cheat warnings, test leaderboard.

**Listening highlights:** audio transcription with legacy `listeningValidator` (tier scoring: failed under 70%, partial 70–89%, passed 90%+), signed audio URLs, script never exposed to students, leaderboard.

**Sentences highlights:** translation practice with legacy `sentenceValidator` (word diff, pronoun equivalence, article/period rules), per-sentence progress, leaderboard.

**Words highlights:** language/level/lesson hierarchy, flashcard practice with legacy text normalizer, answer validation (en-to-uz / uz-to-en), global progress + leaderboard, exam gates (class hours, group unlock, one per day).

**Finance highlights:** institutional exams (schedule-linked, auto-enroll, marks entry, auto-archive), tuition payments with receipt IDs, revenue summary and pending reports, dedicated revenue reports screen with charts and clipboard export (`/admin/revenue-reports`, `/founder/revenue-reports`).

**Attendance highlights:** teacher check-in/out, student attendance marking with UTC+5 class-hour windows (+30 min grace), admin override, 3-absence exam eligibility block, homework/behavior/participation feedback, student feedback view.

**Scheduling highlights:** subjects, exam groups, class schedules, unified create, group↔schedule sync, conflict detection, timetable views (admin/teacher/student).
