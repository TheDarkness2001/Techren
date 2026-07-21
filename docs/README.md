# TechRen EDU — Mobile & Desktop Application

**Platform:** Flutter (Android, iOS, Windows, Linux)  
**Backend:** Node.js + Express + MongoDB Atlas  
**Source of truth:** `d:\system\TECHREN_SYSTEM_ANALYSIS.md`

---

## Development Phases

| Phase | Document | Status |
|-------|----------|--------|
| 1 | System analysis (source report) | ✅ Complete |
| 2 | [System Architecture](./01-SYSTEM-ARCHITECTURE.md) | ✅ Complete |
| 3 | [MongoDB Database Design](./02-DATABASE-DESIGN.md) | ✅ Complete |
| 4 | [REST API Design](./03-API-DESIGN.md) | ✅ Complete |
| 5 | [Flutter Folder Structure](./04-FLUTTER-STRUCTURE.md) | ✅ Complete |
| 6 | [Backend Folder Structure](./05-BACKEND-STRUCTURE.md) | ✅ Complete |
| 7 | [Navigation Flows](./06-NAVIGATION-FLOWS.md) | ✅ Complete |
| 8 | [UI/UX Wireframes & Screen Hierarchy](./07-UI-WIREFRAMES.md) | ✅ Complete |
| 8.1 | [Deployment Guide](./08-DEPLOYMENT.md) | ✅ Complete |
| 9 | Module implementation (one at a time) | ✅ Complete |
| 9.1 | Foundation — backend + Flutter shell | ✅ Complete |
| 9.2 | Identity & Branches — CRUD, dashboards | ✅ Complete |
| 9.3 | Scheduling — subjects, groups, schedules, timetable | ✅ Complete |
| 9.4 | Attendance & Feedback — time windows, eligibility | ✅ Complete |
| 9.5 | Exams & Payments — institutional exams, revenue | ✅ Complete |
| 9.6 | Learning: Words — practice, validators, leaderboard | ✅ Complete |
| 9.7 | Learning: Sentences — grammar analysis, leaderboard | ✅ Complete |
| 9.8 | Learning: Listening — audio exercises, signed streams | ✅ Complete |
| 9.9 | Learning: Video — watch tracking, topic tests, anti-cheat | ✅ Complete |
| 9.10 | Competition — penalties, presentations, bonuses | ✅ Complete |
| 9.11 | Staff Finance — earnings, payouts, account sync | ✅ Complete |
| 9.12 | Recycle Bin & Safety — soft delete, restore, purge | ✅ Complete |
| 9.13 | Notifications — FCM push, parent settings, inbox | ✅ Complete |
| 9.14 | Gamification — XP, levels, achievements, leaderboard | ✅ Complete |
| 9.15 | Parent Portal — child view, feedback comments | ✅ Complete |
| 9.16 | Wallet — balance, top-up, ledger, admin deduct | ✅ Complete |
| 9.17 | Upload & Import — DOCX parse, bulk import, media | ✅ Complete |

---

## Phase 10 — Platform polish

| Step | Module | Status |
|------|--------|--------|
| 10.1 | Settings & Permissions — feature flags, role matrix UI | ✅ Complete |
| 10.2 | Student Progress — overview hub, admin dashboard, group stats | ✅ Complete |
| 10.3 | Learning CMS — word editor, content tree, bulk import link | ✅ Complete |
| 10.4 | Exam Control — group practice & exam unlock matrix | ✅ Complete |
| 10.5 | Revenue Reports — monthly charts, breakdowns, clipboard export | ✅ Complete |
| 10.6 | Group Progress — exam group selector with aggregate stats | ✅ Complete |
| 10.7 | Deployment — Docker, CI, production env guide | ✅ Complete |

---

## Phase 10 — Platform polish (complete)

See [Deployment Guide](./08-DEPLOYMENT.md) for Docker Compose, CI, Atlas, and Flutter release builds.

---

## Phase 11 — Wireframe completion

| Step | Module | Status |
|------|--------|--------|
| 11.1 | Learning CMS — Sentences tab with CRUD | ✅ Complete |
| 11.2 | Learning CMS — Listening tab with audio exercise CRUD | ✅ Complete |
| 11.3 | Student Progress — bottom nav tab (wireframe alignment) | ✅ Complete |
| 11.4 | Inactive student route guard (learning + progress blocked) | ✅ Complete |
| 11.5 | Learning CMS — level & lesson creation UI | ✅ Complete |
| 11.6 | Content Import — OCR image picker + manual paste fallback | ✅ Complete |
| 11.7 | Staff shell polish — routes, branch filter, mobile drawer, teacher CMS | ✅ Complete |
| 11.8 | Revenue Reports — date-range filter UI | ✅ Complete |

---

## Phase 12 — Role-aware staff experience (complete)

| Step | Module | Status |
|------|--------|--------|
| 12.1 | Manager dashboard — permission-aware nav, route guard, demo account | ✅ Complete |
| 12.2 | People photos — profile image upload & display | ✅ Complete |
| 12.3 | Parent shell — bottom nav, child routes, switcher | ✅ Complete |
| 12.4 | Unified progress hub — staff drill-down, vocab lessons tab | ✅ Complete |

---

## Phase 13 — Limited staff roles (complete)

| Step | Module | Status |
|------|--------|--------|
| 13.1 | Sales & receptionist — demo accounts, role dashboards | ✅ Complete |
| 13.2 | Practice recommendations — Learn & Progress hub surfacing | ✅ Complete |
| 13.3 | People edit — student/teacher profile updates from detail sheet | ✅ Complete |
| 13.4 | Feature-flag UX — wallet gating, notification unread badges | ✅ Complete |
| 13.5 | People lifecycle — teacher status, create form fields, unified actions | ✅ Complete |
| 13.6 | Role dashboards — quick links for limited staff, finance toolbar permissions | ✅ Complete |

**Demo accounts**

| Role | Email | Password |
|------|-------|----------|
| Manager | `manager@techren.uz` | `Manager123!` |
| Sales | `sales@techren.uz` | `Sales123!` |
| Receptionist | `receptionist@techren.uz` | `Reception123!` |
| Parent | `parent@techren.uz` | `Parent123!` |

---

## Phase 14 — Data UX polish

| Step | Module | Status |
|------|--------|--------|
| 14.1 | People pagination — page controls, range label, tab/branch reset | ✅ Complete |
| 14.2 | Branches pagination — founder branch list page controls | ✅ Complete |
| 14.3 | Finance pagination — exams & payments tabs page controls | ✅ Complete |
| 14.4 | Progress pagination — admin all-students tab page controls | ✅ Complete |
| 14.5 | Notifications pagination — inbox API paging + UI controls | ✅ Complete |
| 14.6 | Recycle bin pagination — API paging + module filter reset | ✅ Complete |
| 14.7 | Scheduling pagination — class schedules tab page controls | ✅ Complete |

---

## Phase 14 — Data UX polish (complete)

---

## Phase 15 — Data UX polish (continued)

| Step | Module | Status |
|------|--------|--------|
| 15.1 | Feedback pagination — staff & student feedback screens page controls | ✅ Complete |
| 15.2 | Wallet transactions pagination — student & admin wallet screens page controls | ✅ Complete |
| 15.3 | Parent portal feedback pagination — child feedback tab page controls | ✅ Complete |
| 15.4 | Parent portal attendance pagination — child attendance tab page controls | ✅ Complete |
| 15.5 | Parent portal exams pagination — child exams tab page controls | ✅ Complete |
| 15.6 | Competition hub student picker pagination — record sheet page controls | ✅ Complete |
| 15.7 | Staff finance pagination — earnings & payouts tab page controls | ✅ Complete |
| 15.8 | Scheduling groups pagination — unified groups tab page controls | ✅ Complete |
| 15.9 | Admin wallet student picker pagination — student dropdown page controls | ✅ Complete |
| 15.10 | Staff finance teacher picker pagination — staff dropdown page controls | ✅ Complete |
| 15.11 | Competition penalties pagination — monthly penalties tab page controls | ✅ Complete |

---

## Phase 15 — Data UX polish (continued) (complete)

---

## Phase 16 — Search & filter UX

| Step | Module | Status |
|------|--------|--------|
| 16.1 | Scheduling schedules search — class name filter with page reset | ✅ Complete |
| 16.2 | Finance hub exams/payments search — name, subject, student filter with page reset | ✅ Complete |
| 16.3 | Scheduling groups search — group name or subject filter with page reset | ✅ Complete |
| 16.4 | Branches search — branch name filter with page reset | ✅ Complete |
| 16.5 | Notifications inbox search — title, body, or event type filter with page reset | ✅ Complete |
| 16.6 | Recycle bin search — label, collection, or module filter with page reset | ✅ Complete |
| 16.7 | Feedback search — student, class, teacher, or date filter with page reset | ✅ Complete |
| 16.8 | Staff finance search — earnings & payouts filter with page reset | ✅ Complete |
| 16.9 | Wallet transactions search — type, description, or reference filter with page reset | ✅ Complete |

---

Modules are implemented sequentially. Each module must be stable before the next begins.

1. **Foundation** — Backend bootstrap, MongoDB, JWT auth, Flutter shell, theme, routing
2. **Identity & Branches** — Login, roles, branch isolation, settings
3. **People** — Teachers, students, profiles, photos
4. **Scheduling** — Subjects, exam groups, class schedules, timetable
5. **Attendance & Feedback** — All three attendance systems, time windows
6. **Exams & Payments** — Institutional exams, payments, revenue
7. **Learning: Words** — Full vocab module with validators and leaderboards
8. **Learning: Sentences** — Sentence practice with grammar analysis
9. **Learning: Listening** — Audio exercises and streaming
10. **Learning: Video** — Watch tracking, topic tests, anti-cheat
11. **Competition** — Penalties, presentations, bonuses
12. **Staff Finance** — Earnings, payouts
13. **Recycle Bin & Safety** — Soft delete, restore, purge
14. **Notifications** — FCM push, parent settings
15. **Gamification** — XP, levels, achievements (new layer on progress)
16. **Parent Portal** — Child view, feedback comments
17. **Wallet** — Feature-flagged financial module
18. **Upload & Import** — DOCX/OCR parse, bulk content, media files

---

## Key Design Decisions

- **Not a web port.** Mobile-first UX with adaptive layouts for desktop (navigation rail, multi-pane).
- **Preserve all business logic** from the analysis report (validators, scoring, gates, branch isolation).
- **Improve security:** refresh tokens, authenticated media streams, no debug routes in production.
- **Gamification is new.** XP/achievements/streaks do not exist in the legacy system; they are designed as an additive layer on existing progress data.
- **Parent role** is architected but implemented after core student/staff flows.
