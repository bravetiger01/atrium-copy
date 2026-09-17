# Atrium

> **Tinder for Jobs & Portfolio Showcase.** Swipe-based hiring and project showcase for talent and businesses.

A Flutter + Firebase app that makes local hiring and talent discovery frictionless. Candidates showcase project portfolios and swipe on jobs, employers swipe on interested candidates — mutual match unlocks chat and interview scheduling.

---

## Version

**Current:** `1.4.0+4`  
**Flutter SDK:** `^3.9.2` · **Dart SDK:** `^3.9.2`

---

## Quick Start

```bash
# Install dependencies
flutter pub get

# Run on connected device / emulator
flutter run

# Build release APK
flutter build apk --release
```

> **Note:** Requires a valid `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) placed in the respective platform directories.

---

## Tech Stack

| Layer | Technology |
|-------|-----------|
| Frontend | Flutter `^3.9.2`, Dart, Material 3 |
| Auth | Firebase Auth (email/password + Google Sign-In) |
| Database | Cloud Firestore |
| Storage | Firebase Storage (profile pics, chat files, project media, resumes) |
| Push | FCM + Cloud Functions (2nd gen, Node.js 22, `asia-south1`) |
| State | `setState` + `StreamBuilder` |
| PDF Viewer | `flutter_pdfview ^1.3.2` |
| Location | `geolocator ^14.0.2` · `geocoding ^5.0.0` |

---

## Key Dependencies

| Package | Version | Purpose |
|---------|---------|---------|
| `firebase_core` | `^4.11.0` | Firebase initialisation |
| `firebase_auth` | `^6.5.4` | Authentication |
| `cloud_firestore` | `^6.6.0` | Primary database |
| `firebase_storage` | `^13.4.3` | File/media storage |
| `firebase_messaging` | `^16.4.1` | Push notifications |
| `google_sign_in` | `^7.2.0` | Google OAuth |
| `cached_network_image` | `^3.4.1` | Image caching |
| `image_picker` | `^1.1.2` | Gallery/camera access |
| `file_picker` | `^11.0.3` | Document selection |
| `dio` | `^5.8.0` | HTTP client / file downloads |
| `path_provider` | `^2.1.5` | Local file paths |
| `permission_handler` | `^12.0.3` | Runtime permissions |
| `flutter_local_notifications` | `^19.4.2` | In-app notification display |
| `url_launcher` | `^6.3.1` | Open URLs in browser |
| `open_filex` | `^4.5.0` | Open downloaded files |
| `flutter_pdfview` | `^1.3.2` | Native PDF rendering |
| `geolocator` | `^14.0.2` | Device GPS |
| `geocoding` | `^5.0.0` | Address ↔ lat/lng |

---

## Project Structure

```
atrium/
├── lib/
│   ├── main.dart                        # Entry point, FCM, routing, AuthGate
│   ├── firebase_options.dart
│   ├── theme/
│   │   ├── app_theme.dart               # AppColors, AppTextStyles, AppTheme
│   │   ├── light_mode_token.dart        # Color and typography tokens
│   │   └── app_typography_tokens.dart   # Display and body font tokens
│   ├── models/
│   │   └── chat_model.dart
│   ├── services/
│   │   ├── auth_service.dart            # Firebase Auth wrapper
│   │   ├── project_service.dart         # Portfolio projects CRUD & streams
│   │   ├── file_download.dart           # Download chat files locally
│   │   ├── message_cache.dart           # Offline message cache
│   │   └── notification_service.dart    # Local notification display
│   ├── utils/                           # Haversine + shared utilities
│   └── screens/
│       ├── splash_screen.dart
│       ├── login_screen.dart
│       ├── signup_screen.dart
│       ├── role_selection.dart
│       ├── candidate/
│       │   ├── candidate_shell.dart     # Bottom nav (Discover, Projects, Matches, Profile)
│       │   ├── job_screen.dart          # Swipe feed (distance-filtered)
│       │   ├── projects_screen.dart     # Project portfolio feed & empty state
│       │   ├── candidate_project_upload_screen.dart  # Media adjustment & reordering
│       │   ├── candidate_project_details_screen.dart # Project details & publishing
│       │   ├── candidate_project_view_screen.dart    # Full view, edit & delete flows
│       │   ├── project_search_screen.dart            # Live search & filtering (380x124 cards)
│       │   ├── models/
│       │   │   └── project_model.dart   # Project data model
│       │   ├── inbox_screen.dart
│       │   ├── chat_screen.dart
│       │   ├── match_screen.dart
│       │   ├── onboarding_screen.dart
│       │   ├── profile_screen.dart
│       │   ├── company_profile_screen.dart
│       │   └── widgets/
│       │       ├── job_card_content.dart
│       │       └── swipe_card.dart
│       └── employer/
│           ├── employer_home_screen.dart
│           ├── post_job_screen.dart
│           ├── candidates_screen.dart
│           ├── matched_candidates_screen.dart
│           ├── candidate_details_screen.dart
│           ├── pdf_viewer_screen.dart
│           ├── schedule_interview_screen.dart
│           └── employer_profile_screen.dart
├── functions/
│   └── index.js                         # Cloud Functions (FCM triggers)
├── pubspec.yaml
├── firebase.json
└── .firebaserc
```

---

## Features

### Implemented (MVP)
| # | Feature | Status |
|---|---------|--------|
| 1 | Dual role accounts (Candidate / Employer) | ✅ |
| 2 | Job card format (title, pay, location, requirements) | ✅ |
| 3 | Swipe feed for candidates | ✅ |
| 4 | Candidate review for employers | ✅ |
| 5 | Mutual match logic | ✅ |
| 6 | In-app chat (text, image, document) | ✅ |
| 7 | Interview slot booking (propose + accept/decline) | ✅ |
| 8 | Push notifications (match, message, interview) | ✅ |
| 9 | Basic employer verification (phone + business name) | ✅ |
| 10 | Location-based feed (GPS + haversine distance filter) | ✅ |
| 11 | Resume upload & PDF viewer | ✅ |
| 12 | Candidate Project Showcase (portfolio, upload, edit, delete, search) | ✅ |

### Upcoming (V2)
- Smart match score (skills × location × availability)
- Video intro (30-second candidate clip)
- Job expiry + boost credits
- Calendly integration
- Skill filters & undo last swipe

---

## Firestore Collections

| Collection | Key Fields |
|-----------|-----------|
| `users/{uid}` | `name`, `email`, `role`, `profilePic`, `fcmTokens`, `profile` (map) |
| `users/{uid}/projects/{projectId}` | `title`, `client`, `companyDescription`, `projectDescription`, `category`, `mediaUrls`, `thumbnailUrl`, `createdAt`, `updatedAt` |
| `jobs/{jobId}` | `employerId`, `title`, `jobType`, `payMin/Max`, `location`, `latitude`, `longitude`, `requirements`, `isActive`, `expiresAt` |
| `swipes/{candidateId_jobId}` | `direction`, `candidateId`, `jobId`, `employerPass` |
| `matches/{matchId}` | `candidateId`, `employerId`, `jobId`, `createdAt` |
| `chats/{chatId}` | `members`, `lastMessage`, `lastTime`, `unreadCount_{uid}` |
| `chats/{chatId}/messages/{msgId}` | `senderId`, `text`, `type`, `fileUrl`, `interviewData` |

---

## Cloud Functions (`functions/index.js`)

| Function | Trigger | Purpose |
|----------|---------|---------|
| `sendChatNotification` | Firestore write on `messages` | Notify recipient of new chat message |
| `sendMatchNotification` | Firestore write on `matches` | Notify both parties of a new match |
| `sendInterviewResponseNotification` | Firestore update on interview message | Notify employer when candidate responds |

---

*Last updated: September 2026 · v1.4.0*
