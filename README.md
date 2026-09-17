# Atrium

> **Tinder for Jobs & Portfolio Showcase.** Swipe-based hiring and project showcase for talent and businesses.

Atrium makes local hiring and talent discovery frictionless. Candidates showcase creative project portfolios and swipe on jobs, employers swipe on interested candidates, and a **mutual match** unlocks chat + interview scheduling. Built local-first for the SMB owner hiring within 20 km, not multinational corporations.

The core loop:
1. Employer posts a job card (concise, structured, swipeable).
2. Candidate swipes right (interested) or left (skip).
3. Employer reviews interested candidates and swipes right or left.
4. On **mutual match** → chat unlocks instantly.
5. Employer proposes an interview slot → candidate confirms → done.

---

## Monorepo Layout

| Folder | What it is | Status |
|--------|-----------|--------|
| [`app/`](./app) | Flutter mobile app (iOS + Android) — the core product | ✅ Active · `1.4.0+4` |
| [`functions/`](./functions) | Firebase Cloud Functions (2nd gen, Node.js 22) — FCM notifications | ✅ Active |
| [`website/`](./website) | Next.js website — **employer-side dashboard** | 🚧 Under development |
| [`docs/`](./docs) | Documentation (empty) | 📁 |

---

## Components

### Mobile App (`app/`)

Flutter + Firebase app with dual-role accounts (Candidate / Employer).

- **Candidate side:** swipe feed (distance-filtered via haversine), project portfolio showcase (media adjustment, details editing, deletion modal, 380x124 live search), match celebration, matches inbox, chat (text/image/document/interview cards), onboarding wizard, profile, resume upload + native PDF viewer.
- **Employer side:** dashboard, post a job (geocoded), review interested candidates, matched candidates, candidate details, schedule interview, company profile.

Key packages: `firebase_core`, `firebase_auth`, `cloud_firestore`, `firebase_storage`, `firebase_messaging`, `google_sign_in`, `flutter_pdfview`, `geolocator`, `geocoding`.

Full details: [`app/README.md`](./app/README.md), [`app/Atrium_ProductDoc.md`](./app/Atrium_ProductDoc.md)

### Cloud Functions (`functions/`)

Firebase Cloud Functions (2nd gen, `asia-south1`) that drive FCM push notifications:

| Function | Trigger | Purpose |
|----------|---------|---------|
| `sendChatNotification` | write on `messages` | Notify recipient of new chat message |
| `sendMatchNotification` | write on `matches` | Notify candidate of a new match |
| `sendInterviewResponseNotification` | update on interview message | Notify employer of accept/decline |
| `sendStatusChangeNotification` | update on `matches.status` | Notify candidate of `offer_sent` / `hired` |

Also persists in-app notifications to `notifications/{uid}/items` and auto-advances match status to `interview_scheduled` on interview acceptance.

### Website — Employer Dashboard (`website/`)

Next.js 16.2.12 + React 19.2.4 + Tailwind CSS v4 site. Intended to be the **employer-side web dashboard** (post jobs, review candidates, manage matches & hiring pipeline, analytics).

See [`website/context.md`](./website/context.md) for the full product context before starting.

---

## Data Model (Firestore)

| Collection | Key Fields |
|-----------|-----------|
| `users/{uid}` | `name`, `email`, `phone`, `role` (`candidate`/`employer`), `profilePic`, `fcmTokens`, `onboardingDone`, `profile` (map — candidates only) |
| `users/{uid}/projects/{projectId}` | `id`, `userId`, `title`, `client`, `companyDescription`, `projectDescription`, `category`, `mediaUrls`, `thumbnailUrl`, `createdAt`, `updatedAt` |
| `jobs/{jobId}` | `employerId`, `title`, `jobType`, `payMin/Max`, `location`, `latitude`, `longitude`, `requirements`, `isUrgent`, `isActive`, `createdAt`, `expiresAt` |
| `swipes/{candidateId_jobId}` | `direction` (`left`/`right`), `candidateId`, `jobId`, `employerPass` |
| `matches/{matchId}` | `candidateId`, `employerId`, `jobId`, `jobTitle`, `status`, `createdAt` |
| `chats/{chatId}` | `matchId` (== `chatId`), `jobId`, `jobTitle`, `members`, `lastMessage`, `lastTime`, `unreadCount_{uid}` |
| `chats/{chatId}/messages/{msgId}` | `senderId`, `text`, `type`, `fileUrl`, `interviewData` (with `status`) |
| `notifications/{uid}/items/{id}` | `title`, `body`, `type`, `data`, `read`, `createdAt` |

**Match status pipeline:** `matched` → `interview_scheduled` → `offer_sent` → `hired`

---

## Getting Started

### Flutter app

```bash
cd app
flutter pub get
flutter run
```

Requires `google-services.json` (Android) / `GoogleService-Info.plist` (iOS) and a configured Firebase project.

### Website

```bash
cd website
npm install
npm run dev        # http://localhost:3000
npm run build      # production build
npm run lint
```

### Functions

```bash
cd functions
npm install
npm run serve      # emulator
firebase deploy --only functions
```

> ⚠️ The website runs a **newer Next.js (16.x)** with breaking changes vs older versions. Always read the docs in `node_modules/next/dist/docs/` before writing code (see `website/AGENTS.md`).

---

## Roadmap Highlights

**V1 ✅** — dual roles, swipe feed, project portfolio showcase, mutual match, chat, interview booking, push notifications, location-based feed, resume upload & PDF viewer.

**V2** — smart match score, video intros, employer dashboard analytics, job expiry + boost credits, Calendly integration, skill filters, undo swipe.

**V3** — AI-assisted job cards, background checks, employer subscription (Free 2 jobs / Pro ₹1,999/mo), regional language (Gujarati/Hindi) support, recruiter mode.

Monetisation philosophy: **free for candidates always, charge employers** (₹0 Free / ₹1,999 Pro / ₹199 boost).

---

## Documentation

| File | Purpose |
|------|---------|
| [`app/README.md`](./app/README.md) | App quick-start, structure, features |
| [`app/Atrium_ProductDoc.md`](./app/Atrium_ProductDoc.md) | Full product doc: vision, flows, screens, design system, monetisation |
| [`app/project_context.md`](./app/project_context.md) | Living codebase reference (update per sprint) |
| [`app/location_feed_plan.md`](./app/location_feed_plan.md) | Implementation plan for the location-based feed |
| [`website/context.md`](./website/context.md) | Employer-dashboard build context for the web team |

---

*Atrium monorepo · App `v1.4.0+4` · Last updated: September 2026*
