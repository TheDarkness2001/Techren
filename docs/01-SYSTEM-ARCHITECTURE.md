# Phase 2 — System Architecture

## 1. Vision

TechRen EDU is a **native cross-platform education operations and language-learning application**. It replaces the React web client with a single Flutter codebase while introducing a **new** Node.js backend that preserves every business rule from the legacy platform and improves security, maintainability, and mobile UX.

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                         FLUTTER CLIENT (All Platforms)                       │
│  Android │ iOS │ Windows │ Linux                                            │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────────────────────────┐ │
│  │ Presentation │  │   Domain    │  │  Data (API, cache, secure storage)  │ │
│  └─────────────┘  └─────────────┘  └──────────────────────────────────────┘ │
│  Adaptive UI: Bottom Nav (phone) │ Navigation Rail (tablet/desktop)         │
└───────────────────────────────────┬─────────────────────────────────────────┘
                                    │ HTTPS REST + JWT (access + refresh)
                                    ▼
┌─────────────────────────────────────────────────────────────────────────────┐
│                         API GATEWAY LAYER (Express)                          │
│  Rate limit │ CORS │ Sanitize │ Auth │ RBAC │ Branch isolation │ Validate   │
└───────────────────────────────────┬─────────────────────────────────────────┘
                                    │
        ┌───────────────────────────┼───────────────────────────┐
        ▼                           ▼                           ▼
┌───────────────┐         ┌───────────────┐         ┌───────────────────┐
│  Controllers  │────────▶│   Services    │────────▶│   Repositories    │
└───────────────┘         └───────────────┘         └─────────┬─────────┘
                                                            ▼
                                                  ┌───────────────────┐
                                                  │   MongoDB Atlas   │
                                                  └───────────────────┘
        ┌───────────────────────────┬───────────────────────────┐
        ▼                           ▼                           ▼
   Cloud Storage              FCM Push                   (Future: Cron)
   ImageKit / S3              Notifications              Auto-penalties
```

---

## 2. Architectural Principles

### Clean Architecture (Flutter)

| Layer | Responsibility | Depends on |
|-------|----------------|------------|
| **Presentation** | Widgets, screens, state (Riverpod), routing | Domain |
| **Domain** | Entities, use cases, repository contracts | Nothing external |
| **Data** | API clients, DTOs, repository implementations, cache | Domain contracts |

### Layered Backend

| Layer | Responsibility |
|-------|----------------|
| **Routes** | HTTP mapping, middleware chain |
| **Controllers** | Request/response orchestration |
| **Services** | Business logic, algorithms, transactions |
| **Repositories** | MongoDB queries, aggregation |
| **Models** | Mongoose schemas |
| **Middleware** | Cross-cutting concerns |
| **Validators** | express-validator schemas |

**Rule:** Controllers never contain business algorithms. Validators live in `sentenceValidator`, `listeningValidator`, `textNormalizer` services — ported verbatim from legacy logic.

---

## 3. Multi-Tenancy & Security Model

### Branch isolation (preserved)

| Actor | Scope |
|-------|-------|
| Founder | All branches; optional `branchId` filter |
| Manager / Admin / Staff | Own `branchId` enforced on read/write |
| Student | Scoped by own ID + enrolled exam groups |
| Parent (future) | Scoped to linked child IDs |

### Authentication (improved over legacy)

| Concern | Legacy | New design |
|---------|--------|------------|
| Token storage | sessionStorage | `flutter_secure_storage` |
| Token type | Single JWT | Access (15m) + Refresh (7d) |
| Login | Separate teacher/student endpoints | Unified `/auth/login` + role in response; dedicated endpoints retained for compatibility |
| Inactive student | Route whitelist | Same whitelist + UI guard |
| Media streams | Unauthenticated listening audio | Signed URL or auth-required stream |

### Authorization resolution (preserved order)

1. Founder / Admin / Manager → allow all (founder: all branches)
2. `Settings.rolePermissions[role][permission]`
3. Per-teacher `permissions` override
4. Default deny

---

## 4. Module Map

### Operations modules

| Module | Primary roles | Key integrations |
|--------|---------------|------------------|
| Dashboard | All | Aggregations per role |
| Branches | Founder | Multi-tenant root |
| People | Founder, Admin, Manager | Teachers, students |
| Scheduler | Admin, Manager | Groups, schedules, sync |
| Attendance | Teacher, Admin | Time windows, GPS/photos |
| Feedback | Teacher, Parent | Notifications |
| Exams | Teacher, Admin | Eligibility, archiving |
| Payments & Revenue | Admin, Sales | Branch-scoped |
| Timetable | All staff, Student | Role-filtered views |

### Learning modules (isolated by `moduleType`)

| Module | Content tree | Progress models |
|--------|--------------|-----------------|
| Words | Language → Level → Lesson → Word | HomeworkProgress, StudentVocabProgress, StudentLessonProgress |
| Sentences | Language → Level → Lesson → Sentence | StudentSentenceProgress |
| Listening | Language → Level → Exercise | StudentListeningProgress |
| Video | VideoLesson → TopicTest | StudentVideoProgress, StudentTestResult |

### Competition & finance

| Module | Notes |
|--------|-------|
| Penalties / Presentations / Bonuses | Monthly pool: 40% / 30% / 30% center |
| Staff earnings & payouts | Teacher fraud prevention preserved |
| Wallet | Feature-flagged; amounts in tyiyn |

### Platform services

| Service | Purpose |
|---------|---------|
| Recycle bin | Soft delete with cascade restore |
| Notifications | FCM (mobile) replacing web-push |
| Upload pipeline | ImageKit with local fallback |
| Gamification (new) | XP, levels, achievements on top of progress |

---

## 5. Cross-Cutting Concerns

### API response envelope

```json
{
  "success": true,
  "data": { },
  "meta": { "page": 1, "limit": 20, "total": 150 },
  "message": "Optional human message"
}
```

```json
{
  "success": false,
  "error": {
    "code": "VALIDATION_ERROR",
    "message": "Human-readable message",
    "details": []
  }
}
```

### Caching strategy (Flutter)

| Data | Strategy |
|------|----------|
| User profile, settings | Secure storage + memory |
| Timetable, schedules | Hive/SQLite with TTL |
| Learning content lists | Cache per lesson; invalidate on pull-to-refresh |
| Leaderboards | Short TTL (5 min) |
| Offline practice queue | Local queue sync when online |

### Responsive breakpoints

| Breakpoint | Width | Navigation |
|------------|-------|------------|
| Compact | < 600dp | Bottom navigation |
| Medium | 600–1024dp | Navigation rail |
| Expanded | > 1024dp | Permanent rail + content + optional detail pane |

### Timezone

All class-hour gates use **UTC+5** (legacy `isWithinClassHours` behavior preserved).

---

## 6. Gamification Layer (New — Not in Legacy)

The analysis report confirms XP, streaks, and achievements are **not implemented** in the existing system. The new app adds them as an **additive layer** without changing core scoring:

| Event | XP example | Source |
|-------|------------|--------|
| Correct word practice | +5 | HomeworkProgress submit |
| Sentence pass | +10 | StudentSentenceProgress |
| Listening tier passed | +15–25 | Tier-based |
| Video completed | +20 | StudentVideoProgress |
| Daily streak | Multiplier | Consecutive practice days |

Achievements are derived from aggregated progress (e.g., "100 sentences correct", "7-day streak"). Leaderboards remain accuracy-based per legacy rules; a separate "XP leaderboard" is optional.

---

## 7. Deployment Topology

```
┌─────────────┐     ┌─────────────────┐     ┌──────────────┐
│ App Stores  │     │  Backend (Node)  │     │ MongoDB Atlas│
│ Play/App/   │────▶│  Railway/Fly/    │────▶│  Replica Set │
│ MS Store    │     │  VPS + PM2       │     └──────────────┘
└─────────────┘     └────────┬────────┘
                             │
                    ┌────────┴────────┐
                    ▼                 ▼
              ImageKit CDN      Firebase FCM
```

### Environments

| Env | Purpose |
|-----|---------|
| `development` | Local API + Atlas dev cluster |
| `staging` | Pre-production QA |
| `production` | Live academies |

---

## 8. Technology Choices

### Flutter

| Package | Purpose |
|---------|---------|
| `flutter_riverpod` | State management |
| `go_router` | Declarative routing |
| `dio` | HTTP client |
| `flutter_secure_storage` | Tokens |
| `hive` / `drift` | Local cache |
| `google_fonts` | Typography |
| `cached_network_image` | Image loading |
| `just_audio` | Listening module |
| `youtube_player_iframe` | Video lessons |
| `firebase_messaging` | Push notifications |
| `connectivity_plus` | Offline detection |
| `shimmer` | Skeleton loading |

### Backend

| Package | Purpose |
|---------|---------|
| `express` | HTTP |
| `mongoose` | ODM |
| `jsonwebtoken` | JWT |
| `bcryptjs` | Passwords |
| `express-validator` | Validation |
| `express-rate-limit` | Rate limiting |
| `multer` | Uploads |
| `mammoth` | DOCX import |
| `xss` | Sanitization |
| `winston` | Logging |
| `firebase-admin` | FCM |

---

## 9. Data Flow — Practice Session (Words)

```
Student taps Practice
  → Flutter: Select lesson + direction
  → GET /api/v1/homework/words/random
  → Display card UI (not web flashcard layout)
  → Student submits answer
  → POST /api/v1/homework/check-answer (server-side normalize)
  → POST /api/v1/homework/submit-result
  → HomeworkProgress updated
  → Optional: GamificationService.awardXp()
  → UI: success animation + updated accuracy
  → Pull leaderboard: GET /api/v1/homework/leaderboard
```

All validation runs **server-side**. Client shows optimistic UI only for UX; server is authoritative.

---

## 10. Risk Mitigation

| Risk | Mitigation |
|------|------------|
| Scope creep | Phase 9 one-module-at-a-time |
| Legacy behavior drift | Port validators as unit-tested modules |
| Large document size | Pagination on all list endpoints |
| Audio URL guessing | Auth + short-lived signed URLs |
| Inactive student bypass | Middleware whitelist + Flutter route guard |
| Desktop Linux (Kali) | Standard Flutter Linux build; no special deps |

---

*Next: [Database Design](./02-DATABASE-DESIGN.md)*
