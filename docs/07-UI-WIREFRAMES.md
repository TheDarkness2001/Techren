# Phase 8 — UI/UX Wireframes & Screen Hierarchy

**Design system:** Material 3, Google Fonts (Inter + optional display font), 8dp grid, 16dp card radius.

**Color philosophy:** Professional education brand — deep indigo primary, teal accent for learning, warm amber for achievements, semantic red/green for errors/success.

---

## 1. Design Tokens

### Colors (Light mode — dark mode architecture ready)

| Token | Hex | Usage |
|-------|-----|-------|
| `primary` | `#3949AB` | App bar, FAB, key actions |
| `primaryContainer` | `#E8EAF6` | Selected nav, chips |
| `secondary` | `#00897B` | Learning module accent |
| `tertiary` | `#FF8F00` | XP, achievements, streaks |
| `surface` | `#FAFAFA` | Background |
| `surfaceContainer` | `#FFFFFF` | Cards |
| `error` | `#D32F2F` | Errors, penalties |
| `success` | `#388E3C` | Correct answers |
| `onSurfaceVariant` | `#616161` | Secondary text |

### Typography (Google Fonts: Inter)

| Style | Size | Weight | Usage |
|-------|------|--------|-------|
| Display | 32sp | Bold | Dashboard greeting |
| Headline | 24sp | SemiBold | Screen titles |
| Title | 18sp | SemiBold | Card titles |
| Body | 16sp | Regular | Content |
| Label | 14sp | Medium | Buttons, chips |
| Caption | 12sp | Regular | Hints, timestamps |

### Spacing

`4 | 8 | 12 | 16 | 24 | 32 | 48` dp scale. Card padding: 16dp. Screen horizontal: 16dp (mobile), 24dp (tablet), 32dp (desktop).

---

## 2. Screen Hierarchy Tree

```
App
├── Auth
│   ├── Splash
│   └── Login
├── Student Shell
│   ├── Dashboard
│   ├── Learning Hub
│   │   ├── Words
│   │   │   ├── Language Picker
│   │   │   ├── Level Picker
│   │   │   ├── Lesson Picker
│   │   │   ├── Practice
│   │   │   ├── Exam
│   │   │   └── Leaderboard
│   │   ├── Sentences (parallel)
│   │   ├── Listening (parallel)
│   │   └── Videos
│   │       ├── Video Player
│   │       └── Topic Test
│   ├── Timetable
│   ├── Progress Hub
│   │   ├── XP Profile
│   │   ├── Achievements
│   │   └── Module Stats
│   └── Profile
│       ├── Settings
│       ├── Payments
│       ├── Results
│       └── Feedback
├── Teacher Shell
│   ├── Dashboard
│   ├── My Classes
│   ├── Attendance
│   ├── Feedback
│   ├── Learning CMS (conditional)
│   ├── Earnings
│   └── Profile
├── Staff Shell (Admin/Manager)
│   ├── Dashboard
│   ├── People
│   │   ├── Students
│   │   └── Teachers
│   ├── Schedule
│   │   ├── Groups
│   │   ├── Scheduler
│   │   └── Timetable
│   ├── Learning CMS
│   ├── Exams
│   ├── Finance
│   │   ├── Payments
│   │   └── Revenue
│   └── More
│       ├── Competition
│       ├── Recycle Bin
│       └── Settings
├── Founder Shell
│   ├── Dashboard (multi-branch)
│   ├── Branches
│   ├── People (all branches)
│   ├── Learning CMS
│   └── More (full access)
└── Parent Shell (future)
    ├── Child Selector
    └── Child Profile
```

**Total screens (estimated):** ~85 unique screens + ~40 sheets/dialogs.

---

## 3. Wireframe — Splash & Login

### Splash (1s min)

```
┌─────────────────────────────┐
│                             │
│                             │
│         [TechRen Logo]      │
│         EDU Platform        │
│                             │
│         ◠ loading ◠          │
│                             │
└─────────────────────────────┘
```

### Login

```
┌─────────────────────────────┐
│                             │
│    [Logo]  TechRen EDU      │
│    Learn smarter, anywhere  │
│                             │
│  ┌───────────────────────┐  │
│  │ 📧 Email              │  │
│  └───────────────────────┘  │
│  ┌───────────────────────┐  │
│  │ 🔒 Password       👁  │  │
│  └───────────────────────┘  │
│                             │
│  ┌───────────────────────┐  │
│  │      Sign In          │  │
│  └───────────────────────┘  │
│                             │
│  ─── Staff · Student ───    │  ← segmented toggle
│                             │
│         v1.0.0              │
└─────────────────────────────┘
```

---

## 4. Wireframe — Student Dashboard (Mobile)

```
┌─────────────────────────────┐
│ ☰  Good morning, Aziz    🔔 │
├─────────────────────────────┤
│ ┌─────────────────────────┐ │
│ │ 🔥 5 day streak  ⭐ Lv.12│ │
│ │ ████████░░ 2,450 XP     │ │
│ └─────────────────────────┘ │
│                             │
│ Today's Classes             │
│ ┌──────┐ ┌──────┐ ┌──────┐ │
│ │English│ │Math │ │ — │  │ → horizontal scroll
│ │10:00 │ │14:00│ │    │  │
│ └──────┘ └──────┘ └──────┘ │
│                             │
│ Continue Learning           │
│ ┌───────────┐ ┌───────────┐ │
│ │ 📝 Words  │ │ 📖 Sent.  │ │
│ │ Level 3   │ │ Level 2   │ │
│ │ ▶ Resume  │ │ ▶ Resume  │ │
│ └───────────┘ └───────────┘ │
│ ┌───────────┐ ┌───────────┐ │
│ │ 🎧 Listen │ │ 🎬 Video  │ │
│ └───────────┘ └───────────┘ │
│                             │
│ Quick Stats                 │
│ ┌────┐ ┌────┐ ┌────┐       │
│ │87% │ │#4  │ │12  │       │
│ │Acc.│ │Rank│ │Ach.│       │
│ └────┘ └────┘ └────┘       │
├─────────────────────────────┤
│ 🏠   📚   📅   📊   👤    │
│ Home Learn Sched Prog Prof  │
└─────────────────────────────┘
```

---

## 5. Wireframe — Word Practice (Mobile)

```
┌─────────────────────────────┐
│ ←  Practice        EN → UZ  │ ← direction chip toggle
├─────────────────────────────┤
│                             │
│     Lesson 3 · Word 7/20    │
│     ████████░░░░░░ 35%      │
│                             │
│  ┌─────────────────────────┐│
│  │                         ││
│  │                         ││
│  │      beautiful          ││  ← large display word
│  │                         ││
│  │                         ││
│  └─────────────────────────┘│
│                             │
│  ┌─────────────────────────┐│
│  │ Type translation...   ││
│  └─────────────────────────┘│
│                             │
│  ┌─────────────────────────┐│
│  │       Check Answer      ││
│  └─────────────────────────┘│
│                             │
│  Accuracy: 84%  ✓ 42  ✗ 8  │
└─────────────────────────────┘

[After correct answer — bottom sheet peek]
┌─────────────────────────────┐
│  ✓ Correct!  +5 XP          │
│  chiroyli, go'zal           │  ← revealed meanings
│  ┌─────────┐ ┌───────────┐ │
│  │ Next →  │ │ Leaderboard│ │
│  └─────────┘ └───────────┘ │
└─────────────────────────────┘
```

---

## 6. Wireframe — Sentence Practice with Analysis

```
┌─────────────────────────────┐
│ ←  Sentences     EN → UZ    │
├─────────────────────────────┤
│  Translate this sentence:   │
│  ┌─────────────────────────┐│
│  │ She goes to school      ││
│  │ every day.              ││
│  └─────────────────────────┘│
│                             │
│  ┌─────────────────────────┐│
│  │ U u kunduz maktabga    ││
│  │ boradi.                 ││
│  │                         ││
│  └─────────────────────────┘│
│  ┌─────────────────────────┐│
│  │       Submit            ││
│  └─────────────────────────┘│
└─────────────────────────────┘

[Analysis bottom sheet — draggable]
┌─────────────────────────────┐
│ ────                        │
│  Similarity    85%          │
│  ◉──────────────○           │
│                             │
│  Grammar Issues             │
│  [wrongArticle] the → a     │
│                             │
│  Vocabulary    8/10 ✓       │
│                             │
│  [ Try Again ]  [ Next → ]  │
└─────────────────────────────┘
```

---

## 7. Wireframe — Listening Practice

```
┌─────────────────────────────┐
│ ←  Listening    Exercise 3  │
├─────────────────────────────┤
│                             │
│  ┌─────────────────────────┐│
│  │  ▶  ━━━━━●━━━━  1:24   ││
│  │  ⏪5s        5s⏩      ││
│  └─────────────────────────┘│
│                             │
│  What did you hear?         │
│  ┌─────────────────────────┐│
│  │ Type what you heard...  ││
│  │                         ││
│  └─────────────────────────┘│
│  ┌─────────────────────────┐│
│  │       Submit            ││
│  └─────────────────────────┘│
│                             │
│  Best: 92%  Attempts: 4     │
└─────────────────────────────┘

[Partial tier result]
┌─────────────────────────────┐
│  ⚠ Partial — 78%            │
│  Missing words:             │
│  [remember] [always]        │
│  [ Try Again ]              │
└─────────────────────────────┘
```

---

## 8. Wireframe — Video Player + Test

```
┌─────────────────────────────┐
│ ←  Present Simple Lesson    │
├─────────────────────────────┤
│  ┌─────────────────────────┐│
│  │                         ││
│  │    [YouTube Player]     ││
│  │                         ││
│  └─────────────────────────┘│
│  Watch progress ██████░░ 65%│
│                             │
│  ┌──────────┐ ┌──────────┐ │
│  │ Practice │ │ Exam 🔒  │ │  ← exam locked until 70%
│  │  Test    │ │ (need 70%)│ │
│  └──────────┘ └──────────┘ │
└─────────────────────────────┘

[Topic Test — Exam mode]
┌─────────────────────────────┐
│ ⏱ 12:34    Q 3/10    ⚠ 0   │  ← timer, progress, warnings
├─────────────────────────────┤
│  Choose the correct form:   │
│                             │
│  She ___ to school.         │
│                             │
│  ○ go                       │
│  ● goes                     │
│  ○ going                    │
│  ○ gone                     │
│                             │
│  ┌─────────────────────────┐│
│  │       Next Question     ││
│  └─────────────────────────┘│
└─────────────────────────────┘
```

---

## 9. Wireframe — Teacher Attendance (Mobile)

```
┌─────────────────────────────┐
│ ←  Attendance   English 10AM│
├─────────────────────────────┤
│  ⏰ Window closes in 18 min  │
│                             │
│  ┌─────────────────────────┐│
│  │ Mark all present        ││
│  └─────────────────────────┘│
│                             │
│  ┌─────────────────────────┐│
│  │ 👤 Aziz Karimov         ││
│  │    [Present] [Absent]   ││
│  ├─────────────────────────┤│
│  │ 👤 Malika Tosheva       ││
│  │    [Present] [Absent]   ││
│  ├─────────────────────────┤│
│  │ 👤 Jasur Rakhimov       ││
│  │    [Present] [Absent]   ││
│  └─────────────────────────┘│
│                             │
│  ┌─────────────────────────┐│
│  │     Save Attendance     ││
│  └─────────────────────────┘│
└─────────────────────────────┘
```

---

## 10. Wireframe — Admin Dashboard (Desktop Expanded)

```
┌──────┬──────────────────────────────────────────────────────┐
│      │  Dashboard — TechRen Chilonzor          🔔  👤    │
│  🏠  ├──────────────────────────────────────────────────────┤
│  👥  │  ┌─────────┐ ┌─────────┐ ┌─────────┐ ┌─────────┐  │
│  📅  │  │ 142     │ │ 18      │ │ 94%     │ │ 12.4M   │  │
│  📚  │  │Students │ │Teachers │ │Attend.  │ │Revenue  │  │
│  📝  │  └─────────┘ └─────────┘ └─────────┘ └─────────┘  │
│  💰  │                                                      │
│  ⚙️  │  ┌──────────────────────┐ ┌──────────────────────┐ │
│      │  │ Revenue Chart        │ │ Today's Classes      │ │
│      │  │ [chart area]         │ │ • English 10:00      │ │
│      │  │                      │ │ • Math 14:00         │ │
│      │  └──────────────────────┘ └──────────────────────┘ │
│      │                                                      │
│      │  ┌──────────────────────┐ ┌──────────────────────┐ │
│      │  │ Pending Payments (5) │ │ Recent Feedback      │ │
│      │  │ [list]               │ │ [list]               │ │
│      │  └──────────────────────┘ └──────────────────────┘ │
└──────┴──────────────────────────────────────────────────────┘
```

---

## 11. Wireframe — Learning CMS (Staff, Tablet)

```
┌──────┬─────────────────┬────────────────────────────────┐
│ Rail │  Content Tree   │  Word Editor                   │
│      ├─────────────────┼────────────────────────────────┤
│      │ ▼ English       │  Lesson 3 — 15 words           │
│      │   ▼ Level 1     │                                │
│      │     Lesson 1    │  ┌──────────────────────────┐  │
│      │     Lesson 2    │  │ English: beautiful       │  │
│      │   ● Lesson 3    │  │ Uzbek: chiroyli, go'zal  │  │
│      │   ▼ Level 2     │  └──────────────────────────┘  │
│      │     Lesson 1    │                                │
│      │  + Add Level    │  [Save] [Delete] [+ Add Word]  │
│      │                 │                                │
│      │ [Import DOCX]   │  ┌──────────────────────────┐  │
│      │ [Import OCR]    │  │ Words in lesson:         │  │
│      │                 │  │ 1. beautiful             │  │
│      │                 │  │ 2. important             │  │
│      │                 │  │ 3. ...                   │  │
│      │                 │  └──────────────────────────┘  │
└──────┴─────────────────┴────────────────────────────────┘
```

---

## 12. Wireframe — Exam Control (Group Unlock Matrix)

```
┌─────────────────────────────┐
│ ←  Exam Control    Words    │
├─────────────────────────────┤
│  Level 2 — Intermediate     │
│                             │
│  Practice Unlock (Level)    │
│  ┌─────────────────────────┐│
│  │ Group A    [████ ON ]   ││
│  │ Group B    [░░░░ OFF]   ││
│  │ Group C    [████ ON ]   ││
│  └─────────────────────────┘│
│                             │
│  Exam Unlock (per Lesson)   │
│  Lesson 1                   │
│  ┌─────────────────────────┐│
│  │ Group A ✅  B ❌  C ✅  ││
│  └─────────────────────────┘│
│  Lesson 2                   │
│  ┌─────────────────────────┐│
│  │ Group A ❌  B ❌  C ❌  ││
│  └─────────────────────────┘│
└─────────────────────────────┘
```

---

## 13. Wireframe — Leaderboard (Shared Component)

```
┌─────────────────────────────┐
│ ←  Leaderboard    Words     │
├─────────────────────────────┤
│  🥇 1. Malika T.    96%    │
│  🥈 2. Jasur R.     94%    │
│  🥉 3. Aziz K.      91%    │
│     4. ...                  │
│     ...                     │
│    10. Sanjar M.    82%    │
├─────────────────────────────┤
│  ▶ Your rank: #14 — 79%    │  ← sticky if outside top 10
└─────────────────────────────┘
```

---

## 14. Wireframe — Gamification Profile

```
┌─────────────────────────────┐
│ ←  My Progress              │
├─────────────────────────────┤
│        [Avatar]             │
│        Aziz K.  Level 12    │
│   ████████░░ 2,450 / 3,000 XP│
│                             │
│  🔥 5 day streak  Best: 14  │
│                             │
│  Module Breakdown           │
│  ┌─────────────────────────┐│
│  │ Words      ████░  840 XP││
│  │ Sentences  ███░░  620 XP││
│  │ Listening  ██░░░  410 XP││
│  │ Video      █░░░░  280 XP││
│  └─────────────────────────┘│
│                             │
│  Recent Achievements        │
│  [🏆7-Day] [⭐100Words] [🎯90%]│
│                             │
│  [ View All Achievements ]  │
└─────────────────────────────┘
```

---

## 15. Empty, Error & Loading States

### Empty state template

```
┌─────────────────────────────┐
│                             │
│        [Illustration]       │
│                             │
│     No lessons yet          │
│  Your teacher will unlock   │
│  content soon.              │
│                             │
│  [ Contact Teacher ]        │
└─────────────────────────────┘
```

### Error state template

```
┌─────────────────────────────┐
│        ⚠ Connection lost    │
│   Couldn't load lessons.    │
│   [ Retry ]  [ Go Offline ] │
└─────────────────────────────┘
```

### Skeleton loading

Shimmer placeholders matching card layout — never spinners for list content.

---

## 16. Component Library (Reusable Widgets)

| Component | Used in |
|-----------|---------|
| `AdaptiveScaffold` | All shells |
| `StatCard` | Dashboards |
| `ModuleCard` | Learning hub |
| `LevelProgressTile` | Level pickers |
| `WordFlashCard` | Word practice |
| `GrammarErrorChip` | Sentence analysis |
| `AudioPlayerControls` | Listening |
| `WatchProgressBar` | Video |
| `LeaderboardTable` | All modules |
| `UnlockBadge` | Locked content |
| `XpBar` | Dashboard, profile |
| `StreakFlame` | Dashboard |
| `FilterChipBar` | Lists |
| `ConfirmationDialog` | Deletes |
| `OfflineBanner` | Global |

---

## 17. Motion & Interaction Guidelines

| Interaction | Animation |
|-------------|-----------|
| Tab switch | Fade + slide (200ms) |
| Correct answer | Scale bounce + green flash (300ms) |
| Wrong answer | Horizontal shake (150ms) |
| Lesson unlock | Confetti Lottie (1s) |
| Pull to refresh | Material stretch |
| Bottom sheet | Draggable with snap points |
| Page transition | Shared axis (horizontal) |
| XP gain | Number counter roll-up |

---

## 18. Accessibility

- Minimum touch target: 48×48dp
- Contrast ratio ≥ 4.5:1 for body text
- Semantic labels on all icons
- Screen reader announcements for answer feedback
- Support dynamic text scaling (up to 1.3× without layout break)
- Reduce motion option respects system setting

---

## 19. UX Principles vs Legacy Web

| Legacy web pattern | New mobile pattern |
|--------------------|--------------------|
| Sidebar with 20+ links | Bottom nav (5 tabs) + More hub |
| Data tables | Card lists with swipe actions |
| Multi-tab admin pages | Bottom sheets + drill-down |
| Desktop flashcard clone | Full-screen immersive practice |
| Modal forms | Full-screen forms with sticky CTA |
| Chart.js dashboards | Native charts + summary cards |
| Branch dropdown in navbar | Branch chip in app bar (founder) |

---

*Phases 1–8 complete. Ready for Phase 9: Foundation module implementation.*
