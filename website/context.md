# SwipeHire Web — Employer Dashboard Context

> Living reference for building the **employer-side dashboard** on the web (`website/`).
> Read this before writing any code. Update it as the dashboard evolves.

## What this project is

SwipeHire is a **Tinder-for-Jobs** product for small businesses and local talent. Candidates swipe on job cards, employers review only the candidates who swiped right on their jobs, and a **mutual match** unlocks chat + interview scheduling.

The `website/` folder is a Next.js app. **Its job is the employer-side dashboard** — the management/analytics counterpart to the mobile app's employer screens. Candidates keep using the mobile app; the web dashboard is where an employer manages their hiring.

**App version in the monorepo:** `1.4.0+4` (Flutter). The web dashboard should mirror and extend the Flutter employer experience.

---

## Tech Stack (website)

| Concern | Choice | Notes |
|---|---|---|
| Framework | **Next.js `16.2.12`** | App Router |
| UI | React `19.2.4` | |
| Styling | Tailwind CSS `^4` | `@tailwindcss/postcss`, CSS-first config |
| Language | TypeScript `^5` | |
| Scripts | `npm run dev` / `build` / `start` / `lint` | |

> ⚠️ **CRITICAL — READ THIS FIRST.** This is a **newer Next.js (16.x) with breaking changes**. APIs, conventions, and file structure may differ from older versions. **Read the relevant guide in `node_modules/next/dist/docs/` before writing any code** (see `AGENTS.md`). Heed deprecation notices.

The site is currently a bare `create-next-app` scaffold (`app/page.tsx`, `app/layout.tsx`). There is **no Firebase integration in the website yet** — that's part of the work.

---

## Employer Persona

- Small business owners: shops, restaurants, salons, local startups.
- Hiring 1–5 people at a time, need fast turnaround ("cashier by Friday").
- Not tech-savvy enough for LinkedIn/Indeed complexity → **the dashboard must be simple, visual, and mobile-friendly**.

---

## Employer User Flows (from the product)

```
Login / Sign Up (email/password + Google)
  └─► Employer Dashboard
        ├─ Post a Job          ──► job goes live, appears in candidate feed
        ├─ My Jobs             ──► list, active/expired status, view stats
        ├─ Candidate Review    ──► see candidates who swiped right on a job
        │     ├─ Swipe right   ──► if candidate also swiped right → MATCH
        │     └─ Swipe left    ──► pass
        ├─ Matches             ──► all mutual matches + hiring pipeline status
        │     └─ Chat          ──► (mobile) / schedule interview (mobile)
        ├─ Interview confirmed ──► pipeline advances automatically
        └─ Offer / Hire        ──► advance match status
```

**Key design rule:** Employers only ever see candidates who already swiped right on their job. No cold browsing — every candidate in the review feed is already interested.

---

## Firestore Data Model (employer-relevant)

Firebase project: `swipehire-flutter`. **No geo-query server exists** — queries are client-side (haversine on the app). The web dashboard can use direct Firestore reads.

### `users/{uid}` — employer documents
- `name`, `displayName`, `email`, `phone`, `role` = `"employer"`, `profilePic`
- `onboardingDone` (bool), `fcmTokens` (array), `lastActive`
- Employer business info (set during signup): `businessName`, plus profile fields for business logo / location / about

### `jobs/{jobId}`
- `employerId`, `title`, `jobType`, `payMin`, `payMax`
- `location` (text like "Vasad, Anand, Gujarat"), `latitude`, `longitude` (doubles, geocoded on post)
- `requirements` (array of strings), `isUrgent`, `isActive`
- `createdAt`, `expiresAt` (Timestamps — **jobs auto-expire at 30 days**)

### `swipes/{candidateId_jobId}`
- `candidateId`, `jobId`, `employerId`, `direction` (`"left"`/`"right"`), `swipedAt`
- `employerPass` (bool — set when employer dismisses a candidate)

### `matches/{matchId}` — **this is the hiring-pipeline source of truth**
- `candidateId`, `employerId`, `jobId`, `jobTitle`, `candidateName`, `status`, `createdAt`
- **Status pipeline (single string enum):**
  - `matched` → created when employer accepts a candidate who already swiped right
  - `interview_scheduled` → auto-set by Cloud Function when candidate accepts an interview
  - `offer_sent` → set by employer
  - `hired` → set by employer
- `chatId === matchId` (one chat per match)

### `chats/{chatId}` and `chats/{chatId}/messages/{messageId}`
- Employer dashboard is **read-mostly** for chat; active messaging lives in the mobile app.
- Interview messages (`type: "interview"`) carry `interviewData.proposedTime` + `status` (`pending`/`accepted`/`declined`).

### `notifications/{uid}/items/{itemId}`
- In-app notification log (title, body, type, data, `read`, `createdAt`). Cloud Functions write these alongside FCM pushes.

### Firestore rules
Currently permissive for signed-in users (`request.auth != null`) — all reads/writes require auth but have no per-owner checks yet. **If the dashboard writes to Firestore, plan to tighten rules (owner-only) rather than rely on these.**

---

## Cloud Functions (what the backend already does for you)

| Function | Effect the dashboard cares about |
|---|---|
| `sendMatchNotification` | Candidate gets a push when you match |
| `sendInterviewResponseNotification` | Auto-advances match → `interview_scheduled` on accept; notifies you on decline |
| `sendStatusChangeNotification` | Fires when you set `offer_sent` / `hired` — candidate gets notified |

So the dashboard's job for the pipeline is: **update `matches/{id}.status`** (offer_sent, hired) and the rest happens automatically.

---

## Dashboard Feature Scope

### Must-have (v1 of the web dashboard)
| Feature | Source of truth | Notes |
|---|---|---|
| Auth (login/signup) | Firebase Auth (email/password + Google) | Reuse app conventions; `role: employer` gate |
| Dashboard overview | `jobs`, `matches` | Active job count, total matches, candidates in pipeline, recent activity |
| Post / edit a job | `jobs` | Title, type, pay range, location text + lat/lng, requirements, urgent flag |
| My Jobs list | `jobs` (by `employerId`) | Active vs expired, per-job candidate count, live status |
| Candidate review feed | `swipes` + `users` | Candidates who swiped right on a job (direction right, `employerPass` false); accept (create `match`) / pass (set `employerPass`) |
| Matches list | `matches` | Show pipeline status pill per match, candidate summary |
| Candidate details | `users/{uid}/profile` | Skills, bio, availability, pay expectation, resume URL |
| Hiring pipeline control | `matches.status` | Advance to `offer_sent` / `hired` |
| Job expiry | `expiresAt` | Mark/expire stale listings (30-day default) |

### Nice-to-have (V2+ from product roadmap)
- Dashboard analytics: views, match rate, time-to-hire per job
- Boost credits & Pro subscription (Razorpay) — ₹199 boost, ₹999/mo Pro
- Calendly integration for interview scheduling
- Gujarati/Hindi language support

### Out of scope for the web dashboard
- Candidate swipe feed / chat (mobile-first, lives in the Flutter app)

---

## Design System (match the app — slate + blue)

Consistency with the mobile app is important. Tokens from `app/theme/app_theme.dart` / the product doc:

### Colors
| Token | Hex | Usage |
|---|---|---|
| primary | `#1E293B` | Nav, headers, dark surfaces |
| accent | `#3B82F6` | CTAs, active states, links |
| accentLight | `#DBEAFE` | Chip backgrounds, tag fills |
| accentDark | `#1D4ED8` | Pressed accent |
| background | `#F8FAFC` | Page canvas |
| surface | `#FFFFFF` | Cards, sheets, inputs |
| surfaceVariant | `#F1F5F9` | Secondary surface |
| textPrimary | `#1E293B` | Headings, body |
| textSecondary | `#64748B` | Subtitles, meta |
| textHint | `#94A3B8` | Placeholders |
| border | `#E2E8F0` | Borders, dividers |
| error | `#DC2626` | Errors |
| success | `#16A34A` | Success states |
| warning | `#F59E0B` | "Urgent" badges |

### Typography (Inter)
| Style | Size | Weight | Usage |
|---|---|---|---|
| display | 32px | 700 | Hero headers |
| headline | 18–22px | 600–700 | Section / card titles |
| body | 14px | 400 | Body text |
| label | 13–15px | 500–600 | Meta, buttons |

### Spacing / Radius / Shadows
- Spacing scale: 4 / 8 / 12 / 16 / 20 / 24 / 32 (px)
- Radius: 6 (pills) · 10 (buttons/inputs) · 14 (cards) · 20 (sheets) · 24 (feature cards) · 999 (chips)
- Card shadow: `#1E293B` @ 6%, blur 16, y-offset 4. Button shadow: accent @ 28%, blur 12.

### Style rules
- Full-width flat buttons, 52px height, rounded 10px, no elevation
- 0.5px border over shadow on cards
- Stadium chips, no border, `#F1F5F9` bg (accent-light when selected)
- Pipeline status pills (color-coded): `matched` → slate, `interview_scheduled` → blue, `offer_sent` → amber, `hired` → green

---

## Suggested Page / Route Structure

```
/                        # Marketing/landing → redirect to dashboard
/auth/login              # Employer login (Firebase)
/auth/signup             # Employer signup (role gate)
/dashboard               # Overview: active jobs, matches, pipeline
/dashboard/jobs          # My Jobs list
/dashboard/jobs/new      # Post a job
/dashboard/jobs/[jobId]  # Job detail + candidates + stats
/dashboard/jobs/[jobId]/candidates   # Review feed (swipe-style or list)
/dashboard/matches       # All matches + pipeline status
/dashboard/matches/[matchId]         # Match detail → candidate + actions
/dashboard/candidates/[candidateId]  # Candidate profile + resume
/dashboard/settings      # Business profile, subscription, boosts
```

---

## Getting Started Checklist

1. Read `AGENTS.md` and the Next.js 16 docs in `node_modules/next/dist/docs/` **before writing code**.
2. Wire up Firebase: `firebase_core` / `firebase_auth` / `firestore` (config for project `swipehire-flutter` lives in `app/firebase_options.dart` — replicate for web).
3. Gate the app by `role === "employer"`.
4. Build the dashboard shell (sidebar + slate/blue theme, Inter font) first.
5. Implement pages against the Firestore model above; reuse the status pipeline constants.

---

*Part of the SwipeHire monorepo. App v1.4.0+4 · Last updated: August 2026.*
