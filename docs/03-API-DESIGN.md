# Phase 4 — REST API Design

**Base URL:** `/api/v1`  
**Auth:** `Authorization: Bearer <access_token>`  
**Content-Type:** `application/json` (unless multipart)

All list endpoints support: `?page=1&limit=20&search=&sortBy=&sortOrder=asc|desc`  
Branch-scoped endpoints auto-inject `branchId` except for founder with explicit filter.

---

## 1. Standard Response Formats

### Success (single resource)

```json
{
  "success": true,
  "data": { }
}
```

### Success (paginated list)

```json
{
  "success": true,
  "data": [ ],
  "meta": {
    "page": 1,
    "limit": 20,
    "total": 142,
    "totalPages": 8
  }
}
```

### Error

```json
{
  "success": false,
  "error": {
    "code": "FORBIDDEN",
    "message": "You do not have permission to perform this action",
    "details": []
  }
}
```

### HTTP status codes

| Code | Usage |
|------|-------|
| 200 | Success |
| 201 | Created |
| 400 | Validation error |
| 401 | Missing/invalid token |
| 403 | Forbidden (role, branch, inactive) |
| 404 | Not found |
| 409 | Conflict (duplicate) |
| 429 | Rate limited |
| 500 | Server error |

---

## 2. Authentication — `/api/v1/auth`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| POST | `/login` | — | Unified login (email + password); detects teacher/student |
| POST | `/teacher/login` | — | Staff-only login |
| POST | `/student/login` | — | Student-only login |
| POST | `/parent/login` | — | Parent login (future; returns 501 until enabled) |
| POST | `/refresh` | — | Exchange refresh token for new access token |
| POST | `/logout` | ✓ | Revoke refresh token |
| GET | `/me` | ✓ | Current user profile + role + permissions |
| PUT | `/me/password` | ✓ | Change own password |

### POST `/login` request

```json
{
  "email": "user@example.com",
  "password": "secret",
  "userType": "auto"
}
```

`userType`: `auto` | `teacher` | `student`

### POST `/login` response

```json
{
  "success": true,
  "data": {
    "accessToken": "eyJ...",
    "refreshToken": "eyJ...",
    "expiresIn": 900,
    "user": {
      "id": "...",
      "name": "...",
      "email": "...",
      "userType": "teacher",
      "role": "admin",
      "branchId": "...",
      "permissions": { },
      "profileImage": "..."
    }
  }
}
```

---

## 3. Branches — `/api/v1/branches`

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/` | Founder: all; Staff: own | List branches |
| POST | `/` | Founder | Create branch |
| GET | `/:id` | ✓ | Get branch |
| PUT | `/:id` | Founder | Update branch |
| PATCH | `/:id/status` | Founder | Activate/deactivate |
| GET | `/:id/stats` | Admin+ | Dashboard stats |
| DELETE | `/:id` | Founder | Soft deactivate |

---

## 4. Teachers — `/api/v1/teachers`

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/` | canViewStudents | List teachers |
| POST | `/` | canManageStudents | Create teacher |
| GET | `/:id` | ✓ | Get teacher |
| PUT | `/:id` | canManageStudents | Update teacher |
| DELETE | `/:id` | canManageStudents | Deactivate |
| POST | `/:id/photo` | canManageStudents | Upload profile photo |
| PUT | `/:id/permissions` | canManageSettings | Override permissions |

---

## 5. Students — `/api/v1/students`

| Method | Path | Permission | Description |
|--------|------|------------|-------------|
| GET | `/` | canViewStudents | List students |
| POST | `/` | canManageStudents | Create student |
| GET | `/:id` | ✓ | Get student |
| PUT | `/:id` | canManageStudents | Update student |
| PATCH | `/:id/status` | canManageStudents | Activate/deactivate |
| DELETE | `/:id` | canManageStudents | Deactivate |
| POST | `/:id/photo` | ✓ | Upload profile photo |
| POST | `/:id/fcm-token` | ✓ | Register FCM token |
| GET | `/:id/notification-settings` | Admin/Parent | Get parent notification settings |
| PUT | `/:id/notification-settings` | Admin/Parent | Update settings |
| GET | `/:id/dashboard` | ✓ | Student dashboard aggregate |

---

## 6. Subjects — `/api/v1/subjects`

Standard CRUD. Fields: `name`, `code`, `pricePerClass`, `branchId`.

---

## 7. Exam Groups — `/api/v1/exam-groups`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | List groups |
| POST | `/` | Create group |
| GET | `/:id` | Get group with students |
| PUT | `/:id` | Update group |
| DELETE | `/:id` | Delete group |
| POST | `/:id/students` | Add students (syncs schedule) |
| DELETE | `/:id/students/:studentId` | Remove student (syncs schedule) |

---

## 8. Class Schedules — `/api/v1/class-schedules`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | List schedules |
| POST | `/` | Create schedule |
| GET | `/:id` | Get schedule |
| PUT | `/:id` | Update schedule |
| DELETE | `/:id` | Delete schedule |
| GET | `/unified-view` | Combined group+schedule view |
| POST | `/from-group` | Create schedule from exam group |
| POST | `/:id/sync-students` | Sync students from linked group |
| GET | `/conflicts` | Detect scheduling conflicts |

---

## 9. Classes — `/api/v1/classes`

CRUD for single class session instances.  
`PATCH /:id/attendance` — bulk update student attendance for session.

---

## 10. Timetable — `/api/v1/timetable`

| Method | Path | Role | Description |
|--------|------|------|-------------|
| GET | `/admin` | Admin+ | Full branch grid |
| GET | `/teacher` | Teacher | Own schedule grid |
| GET | `/student` | Student | Enrolled classes grid |

Query: `?weekStart=2026-07-07`

---

## 11. Attendance

### Teacher self — `/api/v1/attendance`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | List own records |
| POST | `/check-in` | Check in with photo/GPS |
| POST | `/check-out` | Check out |
| GET | `/:id` | Get record |

### Student — `/api/v1/student-attendance`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | List (filtered) |
| POST | `/` | Mark attendance |
| GET | `/student/:studentId` | Student history |
| GET | `/check-consecutive-absences` | Batch check |
| GET | `/eligibility/:studentId` | Exam eligibility status |

### Teacher admin — `/api/v1/teacher-attendance`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/mark` | Admin mark for teacher |
| GET | `/history` | History |
| GET | `/stats/my-stats` | Teacher own stats |
| GET | `/admin/pending` | Pending approvals |
| PATCH | `/admin/:id/approve` | Approve |
| PATCH | `/admin/:id/reject` | Reject |
| GET | `/admin/audit` | Audit trail |

---

## 12. Feedback — `/api/v1/feedback`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | List feedback |
| POST | `/` | Create (time-window enforced) |
| GET | `/:id` | Get feedback |
| PUT | `/:id` | Update |
| PUT | `/:id/parent-comment` | Parent adds comment |
| DELETE | `/:id` | Delete |

Fields: `homework`, `behavior`, `participation` (0–100), `isExamDay`, `examPercentage`, `parentComments`.

---

## 13. Exams — `/api/v1/exams`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | List exams |
| POST | `/` | Create exam |
| GET | `/:id` | Get with results |
| PUT | `/:id` | Update |
| DELETE | `/:id` | Delete |
| POST | `/:id/enroll` | Enroll from schedule |
| PUT | `/:id/results/:studentId` | Enter marks |
| POST | `/:id/mark-absent-failed` | Mark absent as failed |
| POST | `/:id/students` | Add student |
| DELETE | `/:id/students/:studentId` | Remove student |

---

## 14. Payments — `/api/v1/payments`

CRUD + `GET /revenue` sub-router for aggregated stats.

### Revenue — `/api/v1/revenue`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/summary` | Totals by month/year |
| GET | `/pending` | Pending payments |
| GET | `/chart` | Chart data |
| GET | `/export` | PDF export data |

---

## 15. Settings — `/api/v1/settings`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | Get settings (admin) |
| PUT | `/` | Update settings |
| GET | `/permissions` | Permission matrix |
| PUT | `/permissions` | Update matrix |
| GET | `/features/:flag` | Check feature flag |

---

## 16. Homework / Words — `/api/v1/homework`

### Student practice & exam

| Method | Path | Description |
|--------|------|-------------|
| GET | `/words/random` | Random word `?lessonId&direction` |
| POST | `/check-answer` | Validate answer |
| POST | `/submit-result` | Update HomeworkProgress |
| GET | `/progress` | Student global progress |
| GET | `/leaderboard` | Top 10 + current rank |
| GET | `/lessons/:id/exam` | Get exam questions (gated) |
| POST | `/lessons/:id/exam` | Submit exam |

### Admin CMS

| Method | Path | Description |
|--------|------|-------------|
| GET/POST | `/words` | Word CRUD |
| PUT/DELETE | `/words/:id` | Word update/delete |
| GET | `/students/progress` | Admin progress dashboard |
| GET | `/students/group-progress` | Group analytics |

### Languages — `/api/v1/homework/languages`

CRUD with `?moduleType=words`

### Levels — `/api/v1/homework/levels`

| Method | Path | Description |
|--------|------|-------------|
| CRUD | `/` | Level management |
| PATCH | `/:id/toggle-practice-lock` | Toggle group practice unlock |

### Lessons — `/api/v1/homework/lessons`

| Method | Path | Description |
|--------|------|-------------|
| CRUD | `/` | Lesson management |
| GET | `/:id/student-progress` | Per-lesson student progress |
| GET | `/:id/practice-stats` | Practice statistics |
| PATCH | `/:id/toggle-exam-lock` | Toggle exam unlock per group |
| POST | `/:id/auto-generate` | Auto-generate lesson structure |

---

## 17. Sentences — `/api/v1/sentences`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/random` | Random sentence `?lessonId&direction` |
| POST | `/check` | Analyze answer (full grammar breakdown) |
| POST | `/submit-result` | Update progress |
| GET | `/progress` | Student progress |
| GET | `/leaderboard` | Top 10 + rank |
| CRUD | `/` | Sentence management |
| CRUD | `/languages`, `/levels`, `/lessons` | Parallel hierarchy (moduleType=sentences) |

### POST `/check` response (preserved algorithm)

```json
{
  "success": true,
  "data": {
    "isCorrect": false,
    "similarityScore": 85,
    "errors": [
      { "type": "wrongWord", "expected": "the", "actual": "a", "position": 2 }
    ],
    "analysis": {
      "grammar": { "articles": 1, "wordOrder": 0, "punctuation": 0 },
      "vocabulary": { "correctWords": 8, "totalWords": 10 }
    }
  }
}
```

---

## 18. Listening — `/api/v1/listening`

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/random` | ✓ | Random exercise |
| POST | `/check` | ✓ | Check answer (tier result) |
| GET | `/progress` | ✓ | Student progress |
| GET | `/leaderboard` | ✓ | Leaderboard |
| GET | `/group-progress` | Admin | Group stats |
| GET | `/student-stats/:studentId` | Teacher | Student stats |
| CRUD | `/exercises` | Admin | Exercise management |
| GET | `/exercises/:id/audio` | ✓ | **Authenticated** audio stream |
| GET | `/exercises/:id/signed-url` | ✓ | Short-lived signed URL (preferred) |

### POST `/check` response

```json
{
  "success": true,
  "data": {
    "isCorrect": false,
    "accuracyPercent": 78,
    "tier": "partial",
    "correctWords": 14,
    "totalWords": 18,
    "missingWords": ["remember", "always"]
  }
}
```

Note: `missingWords` only returned for `partial` and `passed` tiers.

---

## 19. Video Lessons — `/api/v1/video-lessons`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | List (filtered by group unlock) |
| POST | `/` | Create |
| GET | `/:id` | Get (no script) |
| PUT | `/:id` | Update |
| DELETE | `/:id` | Soft delete |
| POST | `/:id/track` | Update watch percent |
| POST | `/:id/complete` | Mark completed |
| PATCH | `/:id/toggle-watch-unlock` | Group watch unlock |
| GET | `/:id/test` | Get topic test |
| POST | `/:id/test/attempt` | Submit test attempt |
| POST | `/:id/test/warning` | Anti-cheat warning |
| GET | `/:id/test/leaderboard` | Test leaderboard (top 50) |
| CRUD | `/:id/test/questions` | Manage questions |

---

## 20. Competition

### Penalties — `/api/v1/penalties`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/` | Create penalty |
| GET | `/student/:studentId` | By student |
| GET | `/group/:groupId` | By group |
| GET | `/monthly` | Monthly aggregate `?month&year` |
| POST | `/:id/revert` | Revert penalty |

### Presentations — `/api/v1/presentations`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/` | Record score (1–10) |
| GET | `/student/:studentId` | By student |
| GET | `/monthly` | Monthly scores |
| GET | `/top` | Top presenters |

### Bonuses — `/api/v1/bonuses`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/calculate` | Preview 40/30/30 split |
| POST | `/distribute` | Create bonus penalty records |
| GET | `/history` | Distribution history |

---

## 21. Staff Finance

### Staff Earnings — `/api/v1/staff-earnings`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | List earnings |
| POST | `/` | Create |
| PATCH | `/:id/approve` | Approve |
| POST | `/:id/bonus` | Add bonus |
| POST | `/:id/penalty` | Add penalty |
| POST | `/:id/adjustment` | Manual adjustment |
| POST | `/recalculate` | Recalculate |

### Staff Payouts — `/api/v1/staff-payouts`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/preview` | Preview payout |
| POST | `/` | Create payout |
| PATCH | `/:id/complete` | Complete |
| PATCH | `/:id/cancel` | Cancel |

---

## 22. Wallet — `/api/v1/wallet` (feature-flagged)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/balance` | Student balance |
| POST | `/topup` | Top up (min 10,000 so'm) |
| GET | `/transactions` | Transaction history |
| POST | `/deduct` | Deduct (admin) |

---

## 23. Gamification — `/api/v1/gamification` (new)

| Method | Path | Description |
|--------|------|-------------|
| GET | `/profile` | XP, level, streak |
| GET | `/achievements` | All achievements + unlock status |
| GET | `/leaderboard` | XP leaderboard (optional) |
| GET | `/recommendations` | Suggested practice based on weak areas |

---

## 24. Recycle Bin — `/api/v1/admin/recycle-bin`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | List deleted items |
| GET | `/:id/snapshots` | Version history |
| POST | `/:id/restore` | Restore item + cascade |
| POST | `/:id/purge` | Permanent purge |
| POST | `/purge-all` | Bulk purge |
| PATCH | `/:id/toggle-important` | Mark important |

---

## 25. Upload — `/api/v1/upload`

| Method | Path | Description |
|--------|------|-------------|
| POST | `/parse-docx` | Parse DOCX for word/sentence pairs |
| POST | `/parse-ocr` | OCR image parsing |
| POST | `/bulk-import/words` | Bulk create words |
| POST | `/bulk-import/sentences` | Bulk create sentences |
| POST | `/audio` | Upload listening audio |
| POST | `/image` | Upload image |

---

## 26. Notifications — `/api/v1/notifications`

| Method | Path | Description |
|--------|------|-------------|
| GET | `/` | List notifications for user |
| PATCH | `/:id/read` | Mark read |
| PATCH | `/read-all` | Mark all read |

---

## 27. Health

| Method | Path | Auth | Description |
|--------|------|------|-------------|
| GET | `/api/v1/health` | — | `{ status: "ok", version, uptime }` |

**No debug routes in production.**

---

## 28. Rate Limits

| Endpoint group | Limit |
|----------------|-------|
| `/auth/login` | 5 / 15 min per IP |
| `/auth/refresh` | 20 / 15 min per IP |
| All other `/api/v1/*` | 1000 / 15 min per IP |

---

## 29. Inactive Student Whitelist (middleware)

Allowed paths when `student.status === 'inactive'`:

- `/api/v1/auth/*`
- `/api/v1/payments/*`
- `/api/v1/exams/*` (results only)
- `/api/v1/feedback/*`
- `/api/v1/students/:ownId`

---

*Next: [Flutter Structure](./04-FLUTTER-STRUCTURE.md)*
