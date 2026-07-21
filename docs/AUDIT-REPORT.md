# TechRen EDU — Complete Project Audit Report

**Date:** 14 July 2026  
**Scope:** Full stack (`techren_edu` Flutter client, `backend` Node/Express API, MongoDB Atlas, docs)  
**Mode:** Analysis only — no code was modified  
**Approx. source files reviewed:** ~396 (`.dart` / `.js` under app + API)

---

# Executive Summary

TechRen EDU is a **multi-role education SaaS** covering branch ops, scheduling/timetable, attendance & feedback, exams, payments/revenue, learning CMS (words / sentences / listening / video), competition, staff finance, wallet, gamification, notifications, and parent portal.

The product is **feature-dense and architecturally coherent** for a mid-stage build: Express layered as routes → controllers → services → models; Flutter organized as core / domain / data / presentation with Riverpod + GoRouter. A Material 3 design system exists. Soft-delete + recycle bin for much of the learning CMS is a strength.

However, the project is **not production-ready**. Active secrets/defaults, refresh-token misuse, and several **IDOR / authorization gaps** are blockers. Frontend routing and auth session handling have known race conditions. Docs diverge from the live schema/API in material ways.

| Scorecard | Score (0–100) |
|-----------|---------------|
| **Overall Project Score** | **58** |
| Production Readiness | **38** |
| Architecture | **72** |
| Frontend | **68** |
| Backend | **65** |
| Security | **42** |
| Performance | **70** |
| Database | **68** |
| Maintainability | **62** |
| Accessibility | **55** |
| Responsive Design | **72** |
| Code Quality | **65** |

**Final verdict: NO — do not deploy to production** until Critical/High security and secret-management items are remediated.

---

## Architecture Overview

### What it does
Staff (founder / admin / manager / teacher / sales / receptionist) run an academy across branches: groups & schedules, attendance, feedback, exams, payments, CMS for vocabulary/sentences/listening/video, competition scoring, staff payouts. Students practice modules and see progress/leaderboards. Parents (optional flag) view children. Founders manage branches and elevated settings.

### Tech stack

| Layer | Stack |
|-------|--------|
| Client | Flutter **3.29** / Dart **3.7**, Riverpod **2.6**, GoRouter **14**, Dio **5**, flutter_secure_storage, Google Fonts |
| API | Node **≥20**, Express **4.21**, Mongoose **8**, JWT, bcryptjs, multer, express-validator, winston |
| DB | MongoDB Atlas (`student-management-system`) |
| API base | `/api/v1` (default client: `http://127.0.0.1:5002/api/v1`) |

### High-level data / auth flow
1. Client → `POST /auth/login` → access + refresh JWT → secure storage  
2. Dio attaches Bearer → `protect` loads Teacher/Student/Parent  
3. `checkPermission` + Settings role matrix (founder/admin/manager bypass)  
4. Branch isolation middleware (partial) + `getBranchFilter` / `canAccessBranch` in services  
5. Domain collections are mostly branch-scoped; timetable is **derived** from `classschedules`, not a separate collection  

### Folder map
```
Techren app/
  docs/                 # architecture & API design (partly outdated)
  backend/src/          # config, routes, controllers, services, models, middleware
  techren_edu/lib/src/  # core, domain/entities, data/datasources|repositories, presentation
```

---

## Critical Issues (High Priority)

### C1 — Secrets and credentials in workspace / weak JWT default
| | |
|--|--|
| **Location** | `backend/.env`, `backend/src/config/index.js`, seed/bootstrap scripts |
| **Description** | Live `MONGO_URI` with embedded Atlas credentials; `JWT_SECRET=change-this-to-a-long-random-secret`; `FOUNDER_PASSWORD=Founder123!`; demo passwords printed by seed scripts. **No project-level `.gitignore` found** (root/backend). |
| **Why dangerous** | Token forgery, DB takeover, founder account compromise; high risk if repo is shared or published. |
| **Fix** | Rotate Atlas password + JWT immediately; generate strong secrets; add `.gitignore` for `.env`; refuse startup in production if defaults remain; never log passwords. |

### C2 — Refresh JWT can be used as access token
| | |
|--|--|
| **Location** | `backend/src/services/tokenService.js`, `backend/src/middleware/auth.js` |
| **Description** | Access and refresh share one secret. Refresh payload includes `type: 'refresh'`, but `protect` never rejects refresh tokens. |
| **Why dangerous** | Long-lived refresh JWT becomes a usable API credential. |
| **Fix** | Separate secrets; reject `type === 'refresh'` in `protect`; rotate refresh tokens on use. |

### C3 — Student IDOR on payments / feedback list filters
| | |
|--|--|
| **Location** | `backend/src/services/paymentService.js`, `backend/src/services/feedbackService.js` |
| **Description** | Student filter is set from `req.user`, then overwritten by `req.query.studentId`. |
| **Why dangerous** | Authenticated student can request another student’s payments/feedback. |
| **Fix** | For `userType === 'student'`, force `studentId = req.user._id` and ignore query overrides. |

### C4 — Unscoped attendance history / eligibility by studentId
| | |
|--|--|
| **Location** | `backend/src/routes/studentAttendanceRoutes.js` (`GET /student/:studentId`, `GET /eligibility/:studentId`) |
| **Description** | Routes use `protect` only; no ownership or `canViewAttendance` gate. |
| **Why dangerous** | Any authenticated principal with a known ID can read attendance/eligibility. |
| **Fix** | Require self **or** staff with permission + branch access. |

### C5 — Flutter GoRouter recreated on every auth/settings change
| | |
|--|--|
| **Location** | `techren_edu/lib/src/core/routing/app_router.dart` |
| **Description** | `routerProvider` `watch`es `authProvider` and `platformSettingsProvider`, constructing a **new** `GoRouter` each time. |
| **Why dangerous** | Navigation state loss, splash/login races, flaky first login / redirect loops under load. |
| **Fix** | Single long-lived `GoRouter`; refresh via listenable only; read auth inside `redirect`. |

### C6 — Failed token refresh does not log out the session
| | |
|--|--|
| **Location** | `techren_edu/lib/src/core/network/dio_client.dart`, `auth_provider.dart` |
| **Description** | Concurrent 401s aren’t queued; refresh failure clears tokens but leaves `AuthStatus.authenticated`. |
| **Why dangerous** | Broken session state, confusing failures, possible privilege confusion until restart. |
| **Fix** | Refresh queue; on failure call `logout()` / set `unauthenticated` + clear all. |

---

## Medium Priority Issues

| ID | Area | Location | Summary | Recommendation |
|----|------|----------|---------|----------------|
| M1 | Security | `app.js` | No Helmet; permissive CORS (`origin: true`) in development | Add Helmet; never reflect arbitrary origins with credentials remotely |
| M2 | Security | `app.js`, upload routes | Public static `/api/v1/uploads` | Auth or signed URLs; magic-byte validation |
| M3 | Security | Query filters across services | NoSQL operator injection via Express nested query (`status[$ne]`) | Allowlist scalars / `express-mongo-sanitize` |
| M4 | Security | `walletService.js` | Self-service top-up credits balance (feature-flagged) | Payment webhook / staff credit only |
| M5 | AuthZ | `auth.js` | Manager (and admin) bypass all `checkPermission` | Narrow bypass; enforce matrix for manager |
| M6 | AuthZ | recycle-bin routes | No branch scoping | Filter by branch |
| M7 | AuthZ | payment/feedback/exam `GET :id` | Missing view permission → same-branch IDOR risk | Ownership + permission checks |
| M8 | Frontend | `api_constants.dart` | Default `http://127.0.0.1:5002` | Fail release without `API_BASE_URL` HTTPS |
| M9 | Frontend | secure storage web | Not OS-level secure | Cookie/session for web; document threat model |
| M10 | Frontend | logout | Riverpod caches not invalidated | Invalidate auth-scoped providers on logout |
| M11 | API | various controllers | Inconsistent list shapes (`data[]`+meta vs nested `items`/`notifications`) | Standardize `{ success, data, meta }` |
| M12 | DB | Word/Sentence/Level | Missing uniqueness / order indexes promised by docs | Add compound unique indexes |
| M13 | DB | ClassSchedule.subject | `Mixed` type | Store ObjectId only |
| M14 | Docs | 02/03/05 design docs | Collections/routes not implemented (`classes`, `timetables`, …) | Align docs or implement deferred modules |
| M15 | UX | Many screens | `Text(e.toString())` instead of shared `ErrorState` | Shared AsyncValue UI helper |
| M16 | A11y | login / icon buttons | Missing tooltips/semantics/autofill | Complete labels + autofill |
| M17 | Maintainability | `app_router.dart` | Duplicated admin/founder route trees | Shared route factory with prefix |

---

## Low Priority Issues

- bcrypt cost 12 is fine; password **min length 6** is weak for staff.
- `mongodb-memory-server` in runtime dependencies → move to `devDependencies`.
- Global API rate limit (1000/15m) is loose; `/auth/refresh` not specially limited.
- Hardcoded feature colors outside design tokens (sentence heatmaps, feedback chips).
- Staff mobile nav thinner than desktop sidebar destinations.
- Teacher/admin nav labels not localized (students use l10n).
- Almost no automated tests beyond a smoke widget test.
- Health endpoint exposes DB host/mode metadata.
- Pagination: validator max **200** vs service hard-cap **100**.
- Residual `print` in secure storage debug path.
- Dead/unused `connectivity_plus` usage clarity.

---

## Frontend Findings

**Strengths**
- Feature-oriented presentation folders; AdaptiveScaffold + staff chrome.
- Design system (`AppTheme`, semantic colors, spacing/radius/shadows) recently upgraded.
- Pagination helper / EmptyState / LoadingState exist when used.
- Multi-role shells and route guards for inactive students and staff permissions.

**Gaps**
- Incomplete clean architecture (only `auth_repository`; providers call APIs directly).
- Error UX inconsistent (raw DioException text on hubs — observed on Timetable historically).
- Design token leakage in features.
- Accessibility incomplete vs Material / WCAG AA goals.
- Web token storage and GoRouter lifecycle remain high risk.

---

## Backend Findings

**Strengths**
- Clear mounting at `/api/v1`; service layer for most domains.
- Login rate limiting (stricter in production).
- Soft-delete + recycle bin for learning CMS.
- Branch helpers and permission middleware pattern.

**Gaps**
- Uneven application of branch isolation and permissions on GET-by-id / student-scoped routes.
- Token design flaws (C2).
- Upload + static serving under-hardened.
- No Helmet / mongo sanitize.
- Docs ↔ code drift on modules and verbs.

---

## Database Findings

**Strengths**
- Soft-delete plugin with default find filtering.
- Canonical day names `Mon..Sun` with normalizer.
- Reasonable indexes on many high-traffic collections.

**Gaps**
- Documented but missing collections (`classes`, `timetables`, `systemconfigs`, `studentlessonprogresses`).
- Optional `branchId` on Teacher/Student vs “required” in design doc.
- Missing unique `{ lessonId, english }` for words/sentences; Level missing `order` index/field alignment.
- Denormalized group↔schedule student lists can drift.
- `ClassSchedule.subject` as Mixed.

---

## Security Findings

| Theme | Status |
|-------|--------|
| Password hashing (bcrypt) | Acceptable |
| Secret management | **Fail** |
| JWT design | **Fail** (refresh-as-access) |
| IDOR / AuthZ | **Fail** (several routes) |
| Rate limiting | Partial |
| Input validation | Writes often good; list filters weak |
| Upload / static files | Weak |
| XSS sanitize | Partial body/query scrub; not anti-NoSQL |
| Helmet / CSP / HSTS | Missing |
| CORS | Dangerous if public in “dev” |

---

## Performance Findings

- Pagination exists for core lists; some Flutter hubs build large non-builder trees.
- Timetable is O(schedules × days) in memory — fine for current scale; watch growth.
- Auto login may try Teacher → Student → Parent (multiple bcrypt) — usually OK after first match.
- No CDN/compression strategy documented for Flutter web assets.
- No evidence of aggressive caching layer (Redis) — acceptable for current size.
- Atlas + cold start can inflate first-request latency (contributes to “first click login” perception).

---

## Accessibility Findings

- Some Semantics on shared widgets.
- Login password visibility toggle lacks semantic label/tooltip.
- No consistent autofill.
- Color-only heatmaps/status chips without text alternatives.
- Raw exception text is hostile to screen readers.
- Focus/keyboard paths for complex staff tables not verified systematically.

**Score driver:** ~55 — foundation present, not systematically applied.

---

## UI/UX Findings

- Premium indigo design system in place for light/dark.
- Staff sidebar theme-aware after redesign.
- Empty/loading patterns exist but inconsistently applied.
- Error screens sometimes dump DioException (recent Timetable/teachers limit bug was UX + API validation).
- Founder excluded from teachers list broke timetable filter (product bug, fixed in session before this audit audit-trail).
- Mobile staff nav omits many desktop destinations → discoverability gap.

---

## Code Smells

- Duplicate admin/founder route definitions.
- Controllers wrapping `asyncHandler` with redundant try/catch.
- Permission naming quirks (`canViewStudents` guarding teacher list).
- Domain entities owning `fromJson` (DTOs bleed into domain).
- Large hub screens as god-widgets.
- Hardcoded English in staff navigation.

---

## Unused / Thin Surfaces

- `test/widget_test.dart` minimal.
- Docs claim Class/Timetable models; not in `models/index.js`.
- Possible underuse of `connectivity_plus` in auth recovery paths.
- Password-change endpoint documented, not implemented (`PUT /auth/me/password`).

---

## Duplicate Code

- Admin vs founder route trees (~parallel path lists).
- Repeated `AsyncValue.when` loading/error boilerplate across hubs.
- Multiple CMS/module managers with similar CRUD dialogs (partially improved via `ModuleContentManager`).

---

## Recommended Folder Structure

```
backend/src/
  modules/{domain}/   # optional future: routes+controller+service colocated
  middleware/          # keep global cross-cutting
  shared/              # pagination, errors, branchFilter

techren_edu/lib/src/
  domain/
    entities/
    repositories/      # interfaces
  data/
    dto/ + mappers/
    repositories/      # implementations
    datasources/remote/
  presentation/
    features/{feature}/
    providers/         # thin; depend on repositories
  core/routing/        # single router factory
```

---

## Refactoring Recommendations (priority order)

1. Rotate secrets; add `.gitignore`; production boot guards.  
2. Fix JWT refresh-as-access + student IDOR + attendance IDOR.  
3. Freeze GoRouter; auth logout/refresh queue; invalidate caches.  
4. Uniform AuthZ on all GET-by-id + student-scoped routes.  
5. Helmet + mongo sanitize + signed media.  
6. Align docs with schema; add missing indexes.  
7. Deduplicate routers; repository layer; shared AsyncValue UI.  
8. Expand automated tests (auth, permissions, IDOR regressions).

---

## Production Checklist

| Item | Status |
|------|--------|
| Strong unique secrets in env (not defaults) | ❌ Missing |
| `.gitignore` excluding `.env` | ❌ Missing |
| HTTPS API + release dart-define | ❌ Missing |
| Helmet / security headers | ❌ Missing |
| Refresh token hardening | ❌ Missing |
| IDOR-free student/staff data access | ❌ Missing / ⚠️ Partial |
| Branch isolation on all ID reads | ⚠️ Needs Improvement |
| Rate limits on auth + API | ⚠️ Needs Improvement |
| File upload content validation + private media | ❌ Missing |
| Monitoring / alerting | ❌ Missing |
| CI (analyze, test, npm audit) | ❌ Missing |
| Layered client architecture | ⚠️ Needs Improvement |
| Design system adoption completeness | ⚠️ Needs Improvement |
| Accessibility WCAG AA pass | ⚠️ Needs Improvement |
| Docs match implementation | ⚠️ Needs Improvement |
| Soft-delete / recycle for learning CMS | ✅ Completed |
| Multi-role navigation & shells | ✅ Completed |
| bcrypt password hashing | ✅ Completed |
| Paginated list endpoints (core) | ✅ Completed |
| Material 3 light/dark theme foundation | ✅ Completed |

---

## Final Verdict

### Should this project be deployed? **NO**

**Why:**  
The feature surface is impressive for an education platform, and the backbone architecture is understandable and extendable. But **production deployment would expose real accounts and data** via weak/default secrets, refresh-token design flaws, and multiple authorization/IDOR gaps — compounded by incomplete CORS/Helmet/upload hardening and client session races.

Treat the current build as a **strong internal beta / staging candidate**. Close all Critical items and the High AuthZ cluster, add CI + secret hygiene, then re-audit before any public or campus-wide rollout.

---

*End of report. Analysis-only; no source files were intentionally modified as part of this audit.*
