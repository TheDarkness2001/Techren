# Phase 6 — Backend Folder Structure

**Runtime:** Node.js 20 LTS  
**Framework:** Express 4.x  
**ODM:** Mongoose 8.x

---

## 1. Root Structure

```
backend/
├── src/
│   ├── server.js
│   ├── app.js
│   ├── config/
│   ├── routes/
│   ├── controllers/
│   ├── services/
│   ├── repositories/
│   ├── models/
│   ├── middleware/
│   ├── validators/
│   ├── utils/
│   ├── plugins/
│   └── jobs/
├── scripts/
│   ├── seed.js
│   └── ensure-indexes.js
├── tests/
│   ├── unit/
│   └── integration/
├── uploads/                   # local fallback storage
├── .env.example
├── package.json
└── README.md
```

---

## 2. `src/config/`

```
config/
├── index.js              # loads & validates all env vars
├── database.js           # MongoDB connection
├── cors.js               # CORS allowlist
├── rateLimit.js          # rate limit configs
├── storage.js            # ImageKit / local config
├── firebase.js           # FCM admin SDK
└── logger.js             # Winston logger instance
```

### Environment variables (`.env.example`)

```env
NODE_ENV=development
PORT=5002
MONGO_URI=mongodb+srv://...
JWT_SECRET=
JWT_ACCESS_EXPIRE=15m
JWT_REFRESH_EXPIRE=7d
FOUNDER_EMAIL=founder@techren.uz
FOUNDER_PASSWORD=

# Storage
STORAGE_PROVIDER=imagekit
IMAGEKIT_PRIVATE_KEY=
IMAGEKIT_PUBLIC_KEY=
IMAGEKIT_URL_ENDPOINT=

# Firebase FCM
FIREBASE_PROJECT_ID=
FIREBASE_CLIENT_EMAIL=
FIREBASE_PRIVATE_KEY=

# Feature flags
WALLET_ENABLED=false
GAMIFICATION_ENABLED=true
```

---

## 3. `src/middleware/`

```
middleware/
├── auth.js                 # protect, authorize, checkPermission
├── branchIsolation.js      # enforceBranchIsolation
├── teacherSecurity.js      # schedule/feedback/earnings ownership
├── authorizeHomework.js
├── authorizeVideoLessons.js
├── inactiveStudentGuard.js
├── validate.js             # express-validator runner
├── sanitize.js             # XSS strip
├── errorHandler.js
├── notFound.js
└── upload.js               # multer configs
```

### Auth middleware chain (preserved logic)

```javascript
// Typical protected route
router.get('/',
  protect,
  enforceBranchIsolation,
  checkPermission('canViewStudents'),
  controller.list
);
```

---

## 4. `src/models/`

```
models/
├── Branch.js
├── Teacher.js
├── Student.js
├── Parent.js
├── Subject.js
├── ExamGroup.js
├── ClassSchedule.js
├── Class.js
├── Timetable.js
├── Attendance.js
├── StudentAttendance.js
├── AttendanceAudit.js
├── Feedback.js
├── Exam.js
├── Payment.js
├── Language.js
├── Level.js
├── Lesson.js
├── Word.js
├── Sentence.js
├── ListeningExercise.js
├── VideoLesson.js
├── TopicTest.js
├── HomeworkProgress.js
├── StudentVocabProgress.js
├── StudentLessonProgress.js
├── StudentSentenceProgress.js
├── StudentListeningProgress.js
├── StudentVideoProgress.js
├── StudentTestResult.js
├── Penalty.js
├── PenaltyPeriod.js
├── PresentationScore.js
├── StaffEarning.js
├── StaffAccount.js
├── StaffPayout.js
├── Wallet.js
├── WalletTransaction.js
├── RecycleBin.js
├── Snapshot.js
├── NotificationLog.js
├── ParentNotificationSettings.js
├── Settings.js
├── SystemConfig.js
├── RefreshToken.js
├── StudentGamification.js
├── Achievement.js
├── StudentAchievement.js
└── index.js
```

### Shared plugins

```
plugins/
├── softDeletePlugin.js     # isDeleted filter on all queries
└── timestampsPlugin.js     # createdAt/updatedAt if not using built-in
```

---

## 5. `src/repositories/`

Data access only — no business logic.

```
repositories/
├── baseRepository.js
├── branchRepository.js
├── teacherRepository.js
├── studentRepository.js
├── examGroupRepository.js
├── classScheduleRepository.js
├── homeworkRepository.js
├── sentenceRepository.js
├── listeningRepository.js
├── videoRepository.js
├── progressRepository.js
├── penaltyRepository.js
├── walletRepository.js
├── recycleBinRepository.js
├── gamificationRepository.js
└── settingsRepository.js
```

---

## 6. `src/services/`

Business logic and algorithms.

```
services/
├── authService.js
├── tokenService.js           # access + refresh JWT
├── branchService.js
├── studentService.js
├── teacherService.js
├── scheduleService.js        # group ↔ schedule sync
├── attendanceService.js      # time windows, eligibility
├── feedbackService.js
├── examService.js
├── paymentService.js
├── revenueService.js
│
├── learning/
│   ├── homeworkService.js
│   ├── sentenceService.js
│   ├── listeningService.js
│   ├── videoService.js
│   ├── lessonUnlockService.js
│   ├── examGateService.js    # class hours, daily attempt, group unlock
│   └── leaderboardService.js
│
├── validators/
│   ├── textNormalizer.js     # PORT VERBATIM from legacy
│   ├── sentenceValidator.js    # PORT VERBATIM
│   └── listeningValidator.js   # PORT VERBATIM
│
├── competition/
│   ├── penaltyService.js
│   ├── presentationService.js
│   └── bonusService.js       # 40/30/30 calculation
│
├── finance/
│   ├── staffEarningService.js
│   ├── staffPayoutService.js
│   └── walletService.js
│
├── gamification/
│   ├── xpService.js
│   ├── streakService.js
│   ├── achievementService.js
│   └── recommendationService.js
│
├── recycleBinService.js
├── notificationService.js
├── uploadService.js
├── importService.js          # DOCX + OCR
└── storageService.js         # ImageKit abstraction
```

---

## 7. `src/controllers/`

Thin — delegate to services, format responses.

```
controllers/
├── authController.js
├── branchController.js
├── teacherController.js
├── studentController.js
├── subjectController.js
├── examGroupController.js
├── classScheduleController.js
├── classController.js
├── timetableController.js
├── attendanceController.js
├── studentAttendanceController.js
├── teacherAttendanceController.js
├── feedbackController.js
├── examController.js
├── paymentController.js
├── revenueController.js
├── settingsController.js
├── homeworkController.js
├── sentenceController.js
├── listeningController.js
├── videoLessonController.js
├── topicTestController.js
├── penaltyController.js
├── presentationController.js
├── bonusController.js
├── staffEarningController.js
├── staffPayoutController.js
├── walletController.js
├── gamificationController.js
├── recycleBinController.js
├── uploadController.js
├── notificationController.js
└── healthController.js
```

### Controller pattern

```javascript
exports.checkSentence = asyncHandler(async (req, res) => {
  const result = await sentenceService.checkAnswer(
    req.body.sentenceId,
    req.body.userAnswer,
    req.user
  );
  sendSuccess(res, result);
});
```

---

## 8. `src/routes/`

```
routes/
├── index.js                  # mounts all under /api/v1
├── authRoutes.js
├── branchRoutes.js
├── teacherRoutes.js
├── studentRoutes.js
├── subjectRoutes.js
├── examGroupRoutes.js
├── classScheduleRoutes.js
├── classRoutes.js
├── timetableRoutes.js
├── attendanceRoutes.js
├── studentAttendanceRoutes.js
├── teacherAttendanceRoutes.js
├── feedbackRoutes.js
├── examRoutes.js
├── paymentRoutes.js
├── revenueRoutes.js
├── settingsRoutes.js
├── homeworkRoutes.js
├── sentenceRoutes.js
├── listeningRoutes.js
├── videoLessonRoutes.js
├── penaltyRoutes.js
├── presentationRoutes.js
├── bonusRoutes.js
├── staffEarningRoutes.js
├── staffPayoutRoutes.js
├── walletRoutes.js
├── gamificationRoutes.js
├── recycleBinRoutes.js
├── uploadRoutes.js
└── notificationRoutes.js
```

### `src/routes/index.js`

```javascript
router.use('/auth', authRoutes);
router.use('/branches', branchRoutes);
router.use('/homework', homeworkRoutes);
// ... all modules
router.use('/health', healthController);
```

---

## 9. `src/validators/`

express-validator schemas per route.

```
validators/
├── authValidators.js
├── branchValidators.js
├── studentValidators.js
├── teacherValidators.js
├── homeworkValidators.js
├── sentenceValidators.js
├── listeningValidators.js
├── examValidators.js
├── paymentValidators.js
└── commonValidators.js       # pagination, objectId
```

---

## 10. `src/utils/`

```
utils/
├── asyncHandler.js
├── apiResponse.js            # sendSuccess, sendError
├── pagination.js
├── dateUtils.js              # UTC+5 class hour checks
├── idGenerator.js            # TCH-/STU- prefixes
├── massDeleteGuard.js        # confirmText / force thresholds
└── notificationWorker.js     # event listeners
```

---

## 11. `src/jobs/` (future)

```
jobs/
└── autoPenaltyJob.js         # wire when ready; currently optional
```

No cron in Phase 1 — event-driven notifications only (matching legacy).

---

## 12. `src/app.js` Boot Sequence

```javascript
1. Load config (validate required env)
2. connectDB()
3. ensureContentIndexes()
4. initDefaults() — settings singleton
5. Mount middleware: cors, rateLimit, sanitize, json, static uploads
6. Mount /api/v1 routes
7. errorHandler, notFound
8. notificationWorker.register()
9. listen(PORT)
```

---

## 13. Testing Structure

```
tests/
├── unit/
│   ├── textNormalizer.test.js
│   ├── sentenceValidator.test.js
│   ├── listeningValidator.test.js
│   ├── bonusCalculation.test.js
│   └── examGateService.test.js
└── integration/
    ├── auth.test.js
    ├── homework.test.js
    ├── sentences.test.js
    └── branchIsolation.test.js
```

**Critical:** Validator unit tests must match legacy behavior exactly — use test vectors from the analysis report.

---

## 14. Security Checklist (built-in)

- [x] bcrypt password hashing (pre-save hooks)
- [x] JWT access + refresh with revocation store
- [x] Rate limiting on auth endpoints
- [x] XSS sanitization middleware
- [x] Branch isolation on all operational routes
- [x] Teacher ownership middleware
- [x] Inactive student route whitelist
- [x] Authenticated audio streams
- [x] No debug routes
- [x] Mass delete confirmation guards
- [x] File type/size validation on uploads
- [x] Consistent error responses (no stack in production)

---

*Next: [Navigation Flows](./06-NAVIGATION-FLOWS.md)*
