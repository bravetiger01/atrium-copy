# Atrium — Project Context

> Living reference for the codebase. Update after each feature sprint.

## Overview

Flutter + Firebase job-matching and portfolio showcase app (swipe-based local hiring and talent discovery). Candidates showcase project portfolios and swipe jobs, employers swipe candidates, mutual match unlocks chat and interview scheduling.

**Version:** `1.4.0+4`  
**Last updated:** September 2026

---

## Tech Stack

| Layer | Tech |
|-------|------|
| Frontend | Flutter `^3.9.2`, Dart, Material 3 |
| Auth | Firebase Auth (email/password + Google Sign-In) |
| DB | Cloud Firestore |
| Storage | Firebase Storage (profile pics, chat files, project media, resumes) |
| Push | FCM + Cloud Functions (2nd gen, Node.js 22, `asia-south1`) |
| State | `setState` + `StreamBuilder` (no provider/riverpod) |
| PDF | `flutter_pdfview ^1.3.2` (native Android/iOS rendering) |
| Location | `geolocator ^14.0.2`, `geocoding ^5.0.0` |

---

## Project Structure

```
atrium/
├── lib/
│   ├── main.dart                        # App entry, FCM handlers, routing, AuthGate
│   ├── firebase_options.dart
│   ├── theme/
│   │   ├── app_theme.dart               # AppColors, AppTextStyles, AppTheme (slate+blue)
│   │   ├── light_mode_token.dart        # Design tokens & color system
│   │   └── app_typography_tokens.dart   # Bricolage Grotesque & typography tokens
│   ├── models/
│   │   ├── chat_model.dart              # ChatModel, MessageModel, InterviewData, ContactModel
│   │   └── candidate/models/project_model.dart # ProjectModel with copyWith & serialization
│   ├── services/
│   │   ├── auth_service.dart            # Firebase Auth wrapper
│   │   ├── project_service.dart         # Portfolio projects CRUD & streams
│   │   ├── file_download.dart           # Download chat files locally
│   │   ├── message_cache.dart           # Offline message cache
│   │   └── notification_service.dart    # Local notification display
│   ├── utils/                           # location_utils.dart (haversine), shared helpers
│   └── screens/
│       ├── splash_screen.dart
│       ├── login_screen.dart
│       ├── signup_screen.dart
│       ├── role_selection.dart          # "I'm a Candidate" / "I'm an Employer"
│       ├── notification_screen.dart
│       ├── home_screen.dart             # (unused placeholder)
│       ├── candidate/
│       │   ├── candidate_shell.dart     # Bottom nav: Discover | Projects | Matches | Profile
│       │   ├── job_screen.dart          # Swipe feed (distance-filtered via haversine)
│       │   ├── projects_screen.dart     # Candidate project showcase feed & empty state
│       │   ├── candidate_project_upload_screen.dart  # Media adjustment & reordering
│       │   ├── candidate_project_details_screen.dart # Project details, rich text, publish
│       │   ├── candidate_project_view_screen.dart    # Project view with 3-dots edit & delete
│       │   ├── project_search_screen.dart            # Search bar & 380x124 result cards
│       │   ├── inbox_screen.dart        # Matches list (candidate view)
│       │   ├── chat_screen.dart         # Full chat (text/image/document/interview)
│       │   ├── match_screen.dart        # "It's a Match!" celebration overlay
│       │   ├── onboarding_screen.dart   # 4-step wizard (skills, availability, pay, bio, location)
│       │   ├── profile_screen.dart      # View/edit profile, skills, pay, radius
│       │   ├── company_profile_screen.dart  # View employer company details
│       │   ├── interview_detail_screen.dart # (empty — future use)
│       │   └── widgets/
│       │       ├── job_card_content.dart    # Job card UI (title, pay, loc, reqs, distance)
│       │       └── swipe_card.dart          # Drag gesture card with overlays
│       └── employer/
│           ├── employer_home_screen.dart       # Dashboard: active jobs, match counts, pipeline
│           ├── post_job_screen.dart            # Create job card (title, type, pay, loc, reqs)
│           ├── candidates_screen.dart          # Review interested candidates per job
│           ├── candidate_swipe_screen.dart     # (empty)
│           ├── matched_candidates_screen.dart  # Matches list (employer view)
│           ├── candidate_details_screen.dart   # Full candidate profile + resume options
│           ├── pdf_viewer_screen.dart          # Native PDF viewer (flutter_pdfview)
│           ├── schedule_interview_screen.dart  # Date/time picker → sends interview msg
│           └── employer_profile_screen.dart
├── functions/
│   └── index.js                         # sendChatNotification, sendMatchNotification,
│                                        # sendInterviewResponseNotification
├── pubspec.yaml
├── firebase.json
└── .firebaserc
```

---

## Firestore Collections

### `users/{uid}`
- `name`, `email`, `phone`, `role` (`"candidate"` / `"employer"`), `profilePic`, `displayName`
- `onboardingDone` (bool)
- `fcmTokens` (array of strings)
- `lastActive` (Timestamp)
- `profile` (map — candidates only):
  - `skills`, `availability`, `locationRadius`, `payMin`, `payMax`, `openToNegotiation`, `bio`
  - `latitude`, `longitude` (double — device GPS, set during onboarding & profile save)
  - `resumeUrl` (String — Firebase Storage URL, optional)
  - `projects` (array of maps — project metadata summary)

### `users/{uid}/projects/{projectId}`
- `id`, `userId`, `title`, `client`, `companyDescription`, `projectDescription`, `category`
- `mediaUrls` (array of string URLs)
- `thumbnailUrl` (string URL)
- `createdAt`, `updatedAt` (Timestamp)

### `jobs/{jobId}`
- `employerId`, `title`, `jobType`, `payMin`, `payMax`
- `location` (text), `latitude`, `longitude` (double — geocoded on post)
- `requirements` (array), `isUrgent`, `isActive`
- `createdAt`, `expiresAt` (Timestamp)

### `swipes/{candidateId_jobId}`
- `candidateId`, `jobId`, `employerId`, `direction` (`"left"` / `"right"`), `swipedAt`
- `employerPass` (bool — set when employer dismisses)

### `matches/{matchId}`
- `candidateId`, `employerId`, `jobId`, `jobTitle`, `createdAt`, `candidateName`

### `chats/{chatId}`
- `matchId`, `jobId`, `jobTitle`, `members`, `candidateId`, `employerId`
- `lastMessage`, `lastTime`, `unreadCount_{uid}`

### `chats/{chatId}/messages/{messageId}`
- `senderId`, `text`, `timestamp`, `type` (`"text"` / `"interview"`), `isEdited`, `editedAt`
- `fileUrl`, `fileType`, `fileName` (for images/documents)
- `interviewData` (map — for `type=interview`):
  - `proposedTime` (Timestamp), `status` (`"pending"` / `"accepted"` / `"declined"`), `employerNote`

---

## Features Implemented

| # | Feature | Status | Key Files |
|---|---------|--------|-----------|
| 1 | Dual role accounts | ✅ | `role_selection.dart`, `main.dart` (AuthGate) |
| 2 | Job card format | ✅ | `job_card_content.dart`, `post_job_screen.dart` |
| 3 | Swipe feed (candidates) | ✅ | `job_screen.dart`, `swipe_card.dart` |
| 4 | Candidate review (employers) | ✅ | `candidates_screen.dart` |
| 5 | Mutual match logic | ✅ | `candidates_screen.dart` → creates `matches` doc |
| 6 | In-app chat (text/image/doc) | ✅ | `chat_screen.dart`, `inbox_screen.dart`, `matched_candidates_screen.dart` |
| 7 | Interview slot booking | ✅ | `schedule_interview_screen.dart`, `message_bubble.dart` |
| 8 | Push notifications | ✅ | `functions/index.js`, `notification_service.dart`, `main.dart` |
| 9 | Basic employer verification | ✅ | `signup_screen.dart` (phone + business name) |
| 10 | Location-based feed | ✅ | `job_screen.dart` + haversine filter, `geolocator` |
| 11 | Resume upload & PDF viewer | ✅ | `candidate_details_screen.dart`, `pdf_viewer_screen.dart` |
| 12 | Candidate Project Showcase | ✅ | `projects_screen.dart`, `candidate_project_upload_screen.dart`, `candidate_project_details_screen.dart`, `candidate_project_view_screen.dart`, `project_search_screen.dart`, `project_service.dart` |

### Upcoming (V2)
| Feature | Notes |
|---------|-------|
| Smart match score | Rank by skill overlap, location, availability |
| Video intro (30 sec) | Candidate records quick intro |
| Employer dashboard analytics | Views, match rate, time-to-hire |
| Job expiry + boost credits | Auto-expire 30 days, pay to boost |
| Calendly integration | Calendar-linked interview scheduling |
| Undo last swipe | Save / revisit cards |
| Skill tag filters | Industry, pay range, job type |

---

## Key Conventions

- **All screen files** use `AppColors` / `AppTextStyles` from `app_theme.dart` and tokens from `light_mode_token.dart` & `app_typography_tokens.dart`
- **No state management library** — plain `setState` + `StreamBuilder`
- **Bottom nav** uses `IndexedStack` to preserve tab state across Discover, Projects, Matches, and Profile
- **Chat** uses `matchId` as the `chatId` (one chat per match)
- **Routing** via named routes + `RouteSettings.arguments` for passing data
- **Text styles**: `AppTextStyles.jobTitle`, `.bodyMedium`, `.labelSmall`, etc.
- **Spacing**: `AppSpacing.pagePadding`, `cardPadding`, etc.
- **Radius**: `AppRadius.cardRadius` (24), `lgRadius` (14), `fullRadius`
- **Shadows**: `AppShadows.cardShadow`, `jobCardShadow`, `buttonShadow`
- **PDF viewing**: always download to temp file first, then render with `flutter_pdfview`; never try to render remote URLs directly
- **Platform view plugins** (e.g., `flutter_pdfview`) require a **full cold restart** after adding — hot reload is not sufficient
