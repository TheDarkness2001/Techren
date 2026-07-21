# Phase 3 — MongoDB Database Design

> **Implementation status (Jul 2026):** Prefer this section over older aspirational lists below when they conflict with running code.

## Implementation status vs this document

| Documented collection | Live status |
|----------------------|-------------|
| `classschedules` | **Implemented** — weekly timetable is **derived** from schedules (no separate `timetables` collection) |
| `classes` | **Not implemented** — sessions are virtual (day + schedule), not persisted rows |
| `timetables` | **Not implemented** — use `GET /timetable` against `classschedules` |
| `studentlessonprogresses` | **Not implemented** — lesson lock/progress uses module-specific progress collections |
| `systemconfigs` | **Not implemented** — use `settings` singleton + env/`featureFlags` |
| `classschedules.subject` | **ObjectId → Subject** (legacy string values may remain until migrated) |
| `words` / `sentences` | Unique `(lessonId, english)` while not soft-deleted |
| `levels.order` | Optional `order` field + index with `languageId` + `moduleType` |

Atlas DB name in this workspace has historically been `student-management-system`; local default is `techren_edu`.

---

## 1. Design Goals

- Preserve all legacy collection semantics from the analysis report
- Normalize where it reduces duplication; embed where read patterns are atomic
- Branch-scope all operational data
- Index every query used in list, filter, and leaderboard aggregations
- Soft-delete learning content via plugin (not hard delete)
- Add gamification collections as a new layer

**Database name:** `techren_edu`  
**ODM:** Mongoose 8.x on MongoDB Atlas (replica set, M10+ for production)

---

## 2. Collection Overview

| # | Collection | Purpose | Branch-scoped |
|---|------------|---------|---------------|
| 1 | `branches` | Academy locations | N/A (root) |
| 2 | `teachers` | Staff accounts | ✓ |
| 3 | `students` | Student accounts | ✓ |
| 4 | `parents` | Parent accounts (future) | via children |
| 5 | `subjects` | Course subjects | ✓ |
| 6 | `examgroups` | Student groups per subject | ✓ |
| 7 | `classschedules` | Recurring class definitions | ✓ |
| 8 | `classes` | Single session instances | ✓ |
| 9 | `timetables` | Weekly period grid | ✓ |
| 10 | `attendances` | Teacher self check-in | ✓ |
| 11 | `studentattendances` | Per-student class attendance | ✓ |
| 12 | `attendanceaudits` | Teacher attendance audit | ✓ |
| 13 | `feedbacks` | Daily class feedback | ✓ |
| 14 | `exams` | Institutional exams | ✓ |
| 15 | `payments` | Tuition payments | ✓ |
| 16 | `languages` | Learning language roots | global* |
| 17 | `levels` | Learning levels | global* |
| 18 | `lessons` | Lessons within levels | global* |
| 19 | `words` | Vocab content | global* |
| 20 | `sentences` | Sentence content | global* |
| 21 | `listeningexercises` | Listening content | global* |
| 22 | `videolessons` | Video content | global* |
| 23 | `topictests` | Video topic tests | global* |
| 24 | `homeworkprogresses` | Global word practice stats | per student |
| 25 | `studentvocabprogresses` | Per-lesson vocab exam | per student |
| 26 | `studentlessonprogresses` | Lesson lock state | per student |
| 27 | `studentsentenceprogresses` | Per-sentence attempts | per student |
| 28 | `studentlisteningprogresses` | Listening attempts | per student |
| 29 | `studentvideoprogresses` | Video watch state | per student |
| 30 | `studenttestresults` | Topic test attempts | per student |
| 31 | `penalties` | Competition penalties | ✓ |
| 32 | `penaltyperiods` | Monthly closure | ✓ |
| 33 | `presentationscores` | Presentation scores | ✓ |
| 34 | `staffearnings` | Staff payroll items | ✓ |
| 35 | `staffaccounts` | Staff account balances | ✓ |
| 36 | `staffpayouts` | Payout records | ✓ |
| 37 | `wallets` | Student wallet | ✓ |
| 38 | `wallettransactions` | Immutable ledger | ✓ |
| 39 | `recyclebins` | Soft-deleted snapshots | — |
| 40 | `snapshots` | Version history | — |
| 41 | `notificationlogs` | Push dedup log | — |
| 42 | `parentnotificationsettings` | Quiet hours, channels | per student |
| 43 | `settings` | Singleton RBAC config | global |
| 44 | `systemconfigs` | Key/value defaults | global |
| 45 | `refreshtokens` | Refresh token store | — |
| 46 | `studentgamification` | XP, level, streaks (new) | per student |
| 47 | `achievements` | Achievement definitions (new) | global |
| 48 | `studentachievements` | Unlocked achievements (new) | per student |

\*Learning content is globally managed by founders/admins but unlock permissions are group-scoped via `practiceUnlockedFor`, `examUnlockedFor`, `watchUnlockedFor`.

---

## 3. Entity Relationship Diagram

```mermaid
erDiagram
    Branch ||--o{ Teacher : employs
    Branch ||--o{ Student : enrolls
    Branch ||--o{ Subject : offers
    Subject ||--o{ ExamGroup : groups
    ExamGroup ||--o{ ClassSchedule : links
    ClassSchedule ||--o{ Class : generates
    ClassSchedule ||--o{ Exam : hosts
    ClassSchedule ||--o{ Feedback : receives

    Language ||--o{ Level : contains
    Level ||--o{ Lesson : contains
    Lesson ||--o{ Word : words_module
    Lesson ||--o{ Sentence : sentences_module
    Lesson ||--o{ ListeningExercise : listening_module
    Language ||--o{ VideoLesson : videos
    VideoLesson ||--|| TopicTest : has

    Student ||--o{ HomeworkProgress : tracks
    Student ||--o{ StudentVocabProgress : tracks
    Student ||--o{ StudentLessonProgress : tracks
    Student ||--o{ StudentSentenceProgress : tracks
    Student ||--o{ StudentListeningProgress : tracks
    Student ||--o{ StudentVideoProgress : tracks
    Student ||--o{ StudentTestResult : tracks
    Student ||--o| StudentGamification : earns

    ExamGroup }o--o{ Level : practiceUnlockedFor
    ExamGroup }o--o{ Lesson : examUnlockedFor
    ExamGroup }o--o{ VideoLesson : watchUnlockedFor
```

---

## 4. Core Schemas (Detailed)

### 4.1 `branches`

```javascript
{
  _id: ObjectId,
  name: String,          // required, trim
  address: String,
  phone: String,
  isActive: { type: Boolean, default: true },
  createdBy: { type: ObjectId, ref: 'Teacher' },
  createdAt, updatedAt
}
// Index: { isActive: 1 }
```

### 4.2 `teachers`

```javascript
{
  teacherId: String,       // auto: TCH-YYYYMMDD-XXXX
  name: String,
  email: { type: String, unique: true, lowercase: true },
  password: String,        // bcrypt, select: false
  phone: String,
  subject: [String],
  role: {
    type: String,
    enum: ['founder','admin','teacher','sales','receptionist','manager'],
    default: 'teacher'
  },
  permissions: {
    canViewStudents: Boolean,
    canManageStudents: Boolean,
    // ... all permission keys from Settings defaults
  },
  perClassEarning: Number,
  perClassEarnings: Map,   // subjectId → Number
  branchId: { type: ObjectId, ref: 'Branch', required: true },
  status: { type: String, enum: ['active','inactive'], default: 'active' },
  profileImage: String,
  createdAt, updatedAt
}
// Indexes: { email: 1 } unique, { branchId: 1, role: 1 }, { branchId: 1, status: 1 }
```

### 4.3 `students`

```javascript
{
  studentId: String,       // auto: STU-YYYYMMDD-XXXX
  name: String,
  email: { type: String, lowercase: true },
  password: String,
  parentName: String,
  parentPhone: String,
  parentId: ObjectId,      // future link to parents collection
  status: { type: String, enum: ['active','inactive'], default: 'active' },
  examEligibility: { type: Boolean, default: true },
  examResults: [{
    examId, subject, marks, totalMarks, percentage, grade, date
  }],
  subjectPayments: [{
    subjectId, subjectName, amount, paidDate, month, year, status
  }],
  perClassPrices: Map,     // subjectId → Number (so'm)
  branchId: { type: ObjectId, ref: 'Branch' },
  profileImage: String,
  fcmTokens: [String],     // replaces web pushTokens
  enrolledGroupIds: [ObjectId], // denormalized cache from ExamGroup
  createdAt, updatedAt
}
// Indexes: { email: 1, branchId: 1 }, { branchId: 1, status: 1 }, { studentId: 1 }
// Post-save: on deactivate → remove from ClassSchedule.enrolledStudents + ExamGroup.students
```

### 4.4 `parents` (future-ready)

```javascript
{
  name: String,
  email: { type: String, unique: true },
  password: String,
  phone: String,
  children: [{ type: ObjectId, ref: 'Student' }],
  fcmTokens: [String],
  status: { type: String, enum: ['active','inactive'] },
  createdAt, updatedAt
}
```

### 4.5 `examgroups`

```javascript
{
  groupName: String,
  subject: { type: ObjectId, ref: 'Subject' },
  students: [{ type: ObjectId, ref: 'Student' }],
  teachers: [{ type: ObjectId, ref: 'Teacher' }],
  branchId: { type: ObjectId, ref: 'Branch' },
  linkedScheduleId: ObjectId,  // bidirectional sync helper
  createdAt, updatedAt
}
// Indexes: { branchId: 1 }, { subject: 1, branchId: 1 }, { students: 1 }
```

### 4.6 `classschedules`

```javascript
{
  className: String,
  subject: Mixed,          // name string or ObjectId ref
  subjectGroup: { type: ObjectId, ref: 'ExamGroup' },
  enrolledStudents: [{ type: ObjectId, ref: 'Student' }],
  teacher: { type: ObjectId, ref: 'Teacher' },
  scheduledDays: [{ type: String, enum: ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'] }],
  startTime: String,       // HH:mm
  endTime: String,
  branchId: ObjectId,
  createdAt, updatedAt
}
// Indexes: { branchId: 1, teacher: 1 }, { enrolledStudents: 1 }, { subjectGroup: 1 }
```

### 4.7 Learning content (shared plugin fields)

All learning content models include soft-delete plugin:

```javascript
{
  isDeleted: { type: Boolean, default: false },
  deletedAt: Date,
  deletedBy: String
}
```

#### `languages`

```javascript
{
  name: String,
  moduleType: { type: String, enum: ['words','sentences','listening'], required: true },
  description: String,
  createdAt, updatedAt
}
// Unique compound: { name: 1, moduleType: 1 }
```

#### `levels`

```javascript
{
  languageId: { type: ObjectId, ref: 'Language' },
  name: String,
  order: Number,
  classesCount: Number,
  wordsPerClass: Number,
  examTimeLimit: Number,    // minutes
  minPassScore: { type: Number, default: 70 },
  practiceUnlockedFor: [{ type: ObjectId, ref: 'ExamGroup' }],
  moduleType: String,       // denormalized for query speed
  createdAt, updatedAt
}
// Indexes: { languageId: 1, order: 1 }, { practiceUnlockedFor: 1 }
```

#### `lessons`

```javascript
{
  levelId: { type: ObjectId, ref: 'Level' },
  type: { type: String, enum: ['words','sentences','listening'] },
  order: Number,
  title: String,
  wordIds: [ObjectId],      // words module
  maxWords: Number,
  examUnlockedFor: [{ type: ObjectId, ref: 'ExamGroup' }],
  directionMode: { type: String, enum: ['en-to-uz','uz-to-en','both'], default: 'both' },
  minPassScore: Number,     // override level default
  createdAt, updatedAt
}
// Indexes: { levelId: 1, order: 1 }, { examUnlockedFor: 1 }
```

#### `words` / `sentences`

```javascript
// words
{ english: String, uzbek: String, lessonId: ObjectId, order: Number }
// sentences
{ english: String, uzbek: String, lessonId: ObjectId, order: Number }
// Unique: { lessonId: 1, english: 1 } per collection
```

#### `listeningexercises`

```javascript
{
  title: String,
  script: String,           // never exposed to students
  audioFile: String,
  audioDuration: Number,
  lessonId: ObjectId,
  levelId: ObjectId,
  order: Number,
  createdAt, updatedAt
}
```

#### `videolessons`

```javascript
{
  title: String,
  youtubeUrl: String,
  youtubeId: String,
  languageId: ObjectId,
  levelId: ObjectId,
  requireWatchPercent: { type: Number, default: 70 },
  watchUnlockedFor: [ObjectId],
  examUnlockedFor: [ObjectId],
  thumbnailUrl: String,
  createdAt, updatedAt
}
// Business rule index helper: enforce one video per group per level at service layer
```

#### `topictests`

```javascript
{
  videoLessonId: { type: ObjectId, ref: 'VideoLesson', unique: true },
  passingScore: { type: Number, default: 70 },
  timerSeconds: Number,
  questions: [{
    type: { type: String, enum: ['multiple-choice','true-false','fill-blank','translation','short-answer'] },
    question: String,
    options: [String],
    correctAnswer: Mixed,
    acceptableAnswers: [String],
    points: { type: Number, default: 1 }
  }],
  createdAt, updatedAt
}
```

---

## 5. Progress Collections

### `homeworkprogresses` (one per student)

```javascript
{
  studentId: { type: ObjectId, ref: 'Student', unique: true },
  totalAttempts: Number,
  correctAnswers: Number,
  accuracy: Number,
  enToUzTotal: Number,
  enToUzCorrect: Number,
  enToUzAccuracy: Number,
  uzToEnTotal: Number,
  uzToEnCorrect: Number,
  uzToEnAccuracy: Number,
  lastPracticeAt: Date,
  updatedAt
}
```

### `studentvocabprogresses`

```javascript
{
  studentId: ObjectId,
  lessonId: ObjectId,
  status: { type: String, enum: ['locked','available','in_progress','passed','failed'] },
  bestScore: Number,
  attempts: Number,
  lastExamDate: Date,      // one attempt per calendar day gate
  lastExamScore: Number,
  updatedAt
}
// Unique: { studentId: 1, lessonId: 1 }
```

### `studentlessonprogresses`

```javascript
{
  studentId: ObjectId,
  lessonId: ObjectId,
  levelId: ObjectId,
  status: { type: String, enum: ['locked','available','passed'] },
  updatedAt
}
// Unique: { studentId: 1, lessonId: 1 }
```

### `studentsentenceprogresses`

```javascript
{
  studentId: ObjectId,
  sentenceId: ObjectId,
  lessonId: ObjectId,
  totalAttempts: Number,
  correctCount: Number,
  accuracy: Number,
  lastAttemptAt: Date,
  mistakeTypes: [String],  // aggregated error categories for analytics
  updatedAt
}
// Unique: { studentId: 1, sentenceId: 1 }
// Index: { studentId: 1, lessonId: 1 }
```

### `studentlisteningprogresses`

```javascript
{
  studentId: ObjectId,
  exerciseId: ObjectId,
  totalAttempts: Number,
  bestAccuracy: Number,
  lastTier: { type: String, enum: ['failed','partial','passed'] },
  lastAttemptAt: Date,
  updatedAt
}
// Unique: { studentId: 1, exerciseId: 1 }
```

### `studentvideoprogresses`

```javascript
{
  studentId: ObjectId,
  videoLessonId: ObjectId,
  watchPercent: Number,    // monotonic, max 100
  completed: Boolean,
  rewatchCount: Number,
  lastWatchedAt: Date,
  updatedAt
}
// Unique: { studentId: 1, videoLessonId: 1 }
```

### `studenttestresults`

```javascript
{
  studentId: ObjectId,
  topicTestId: ObjectId,
  videoLessonId: ObjectId,
  mode: { type: String, enum: ['practice','exam'] },
  score: Number,
  bestScore: Number,
  passed: Boolean,
  answers: [Mixed],
  warnings: Number,
  terminated: Boolean,     // warnings >= 3
  attemptDate: Date,
  durationSeconds: Number
}
// Index: { studentId: 1, topicTestId: 1, attemptDate: -1 }
```

---

## 6. Gamification Collections (New)

### `studentgamification`

```javascript
{
  studentId: { type: ObjectId, ref: 'Student', unique: true },
  totalXp: { type: Number, default: 0 },
  level: { type: Number, default: 1 },
  currentStreak: { type: Number, default: 0 },
  longestStreak: { type: Number, default: 0 },
  lastActivityDate: Date,  // calendar date UTC+5
  moduleXp: {
    words: Number,
    sentences: Number,
    listening: Number,
    video: Number
  },
  updatedAt
}
```

### `achievements`

```javascript
{
  code: String,            // unique: FIRST_WORD, STREAK_7, etc.
  title: String,
  description: String,
  icon: String,
  category: String,
  criteria: Mixed,         // { type: 'streak', value: 7 }
  xpReward: Number,
  isActive: Boolean
}
```

### `studentachievements`

```javascript
{
  studentId: ObjectId,
  achievementId: ObjectId,
  unlockedAt: Date,
  notified: Boolean
}
// Unique: { studentId: 1, achievementId: 1 }
```

---

## 7. Financial & Competition

### `penalties`

```javascript
{
  studentId: ObjectId,
  groupId: ObjectId,
  branchId: ObjectId,
  type: {
    type: String,
    enum: ['spoken_uzbek','missed_presentation','missed_writing_homework',
           'missed_word_memorization','bonus','other']
  },
  points: Number,
  quantity: { type: Number, default: 1 },
  reason: String,
  month: Number,
  year: Number,
  isReverted: { type: Boolean, default: false },
  revertedAt: Date,
  createdBy: ObjectId,
  createdAt
}
// Indexes: { branchId: 1, month: 1, year: 1 }, { studentId: 1, isReverted: 1 }
```

### `wallets`

```javascript
{
  studentId: { type: ObjectId, unique: true },
  branchId: ObjectId,
  balanceTyiyn: { type: Number, default: 0 },  // 100 tyiyn = 1 so'm
  isLocked: { type: Boolean, default: false },
  graceBalanceTyiyn: Number,
  updatedAt
}
```

### `wallettransactions` (immutable)

```javascript
{
  walletId: ObjectId,
  studentId: ObjectId,
  type: { type: String, enum: ['topup','deduction','penalty','refund','adjustment'] },
  amountTyiyn: Number,
  balanceAfterTyiyn: Number,
  description: String,
  referenceId: String,
  createdBy: ObjectId,
  createdAt: Date
}
// Index: { walletId: 1, createdAt: -1 }
```

---

## 8. Platform Collections

### `settings` (singleton)

```javascript
{
  _id: 'global',
  rolePermissions: {
    teacher: { canViewStudents: true, ... },
    sales: { ... },
    receptionist: { ... }
  },
  featureFlags: {
    walletEnabled: false,
    gamificationEnabled: true,
    parentPortalEnabled: false
  },
  updatedAt
}
```

### `refreshtokens`

```javascript
{
  token: String,           // hashed
  userId: ObjectId,
  userType: String,
  expiresAt: Date,
  createdAt: Date,
  revokedAt: Date
}
// TTL index: { expiresAt: 1 }, expireAfterSeconds: 0
// Index: { userId: 1, userType: 1 }
```

### `recyclebins`

```javascript
{
  collectionName: String,
  documentId: ObjectId,
  snapshot: Mixed,
  cascadeGroupId: String,
  deletedBy: String,
  deletedAt: Date,
  isImportant: Boolean,
  restoredAt: Date,
  purgedAt: Date,
  moduleType: String
}
// Indexes: { collectionName: 1, deletedAt: -1 }, { cascadeGroupId: 1 }
```

---

## 9. Index Strategy Summary

| Query pattern | Index |
|---------------|-------|
| Branch staff lists | `{ branchId: 1, status: 1 }` |
| Student by group | `{ students: 1 }` on examgroups |
| Attendance uniqueness | `{ student: 1, class: 1, date: 1 }` unique |
| Leaderboard aggregation | `{ studentId: 1 }` + computed fields |
| Soft-delete filter | `{ isDeleted: 1 }` on all learning content |
| Notification dedup | `{ studentId: 1, eventType: 1, date: 1 }` unique |
| Refresh token cleanup | TTL on `expiresAt` |

---

## 10. Migration & Seeding

### Initial seed (`scripts/seed.js`)

1. Create default `settings` document with full permission matrix
2. Create founder account (env `FOUNDER_EMAIL`, `FOUNDER_PASSWORD`)
3. Create demo branch (optional, dev only)
4. Seed `achievements` catalog
5. `systemconfigs` homework defaults

### Data integrity hooks

| Hook | Behavior |
|------|----------|
| Student deactivate | Remove from schedules + exam groups |
| ExamGroup student add/remove | Sync ClassSchedule bidirectionally |
| Lesson pass | Unlock next lesson (`order + 1`) |
| All exam marks entered | Archive exam |

---

*Next: [API Design](./03-API-DESIGN.md)*
