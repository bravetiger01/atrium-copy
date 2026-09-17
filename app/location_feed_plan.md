# Location-based Feed — Implementation Plan

> **Status: ✅ COMPLETED — v1.2.1**
> GPS permission + haversine client-side filtering is live. `geolocator` and `geocoding` added to pubspec. Candidate lat/lng stored in `users/{uid}/profile`. Job lat/lng stored in `jobs/{jobId}`. Feed filtered by `locationRadius`.

---


## Current State

### Job Posting (`post_job_screen.dart`)
- Jobs stored in `jobs` collection in Firestore
- Fields: `title`, `jobType`, `payMin`, `payMax`, `location` (plain text string like "Vasad, Anand, Gujarat"), `requirements`, `isUrgent`, `isActive`, `employerId`, `createdAt`, `expiresAt`
- **No lat/lng stored** — only a text location field

### Candidate Profile (`profile_screen.dart` / `onboarding_screen.dart`)
- Candidate profile stored in `users/{uid}/profile` map
- Has `locationRadius` (int, km) — range 5–50km
- **No lat/lng stored** — no geo coordinates at all
- Also has: `skills`, `availability`, `payMin/payMax`, `openToNegotiation`, `bio`

### Swipe Feed (`job_screen.dart`)
- Currently loads ALL active jobs, then filters out already-swiped ones
- Shows "N jobs near you" label but doesn't actually filter by distance
- Uses `JobCardContent` widget for card UI
- Swipe recorded in `swipes` collection

### Other Context
- **Auth**: Firebase Auth with Google + phone
- **Firestore**: `users`, `jobs`, `swipes`, `matches`, `chats/{chatId}/messages/{messageId}` collections
- **Theme**: Slate + Blue (AppColors, AppTextStyles in `theme/app_theme.dart`)
- **Chat**: Fully working with text/image/document + interview messages
- **Cloud Functions**: `asia-south1` region, Node.js 22 (2nd gen)
- **Flutter SDK**: ^3.9.2

## What Needs to Change

### 1. Add lat/lng to Job Posting
- Add `latitude`/`longitude` fields (doubles) to `jobs` collection
- Employer enters text location + a map picker (or we geocode the text)
- Option A: Simple text input + approximate coordinates
- Option B: Google Maps / Map picker to select exact location
- **Recommended**: Text input + manual lat/lng fields initially (MVP), or use a map picker

### 2. Add lat/lng to Candidate Profile
- Store `latitude`/`longitude` in the candidate's profile map
- Can be obtained via:
  - Device GPS (requires `permission_handler`, `geolocator` package)
  - Onboarding step asking for location permission
  - Fallback: manual text entry

### 3. Filter Feed by Distance
- Two approaches:
  - **A. Firestore GeoQueries**: Requires storing geo data and using a geoquery library (`geoflutterfire` or manual hash approach). Firestore doesn't support native geo queries.
  - **B. Client-side Haversine**: Load all jobs within a broad area, calculate distance on client, filter. Simpler but less scalable.
- **Recommended**: Start with **client-side haversine** — load jobs, compute distance using the haversine formula, filter by candidate's `locationRadius`. Works well for MVP (<1000 jobs).

### 4. Dependencies to Add
- `geolocator` — get device GPS position
- `geocoding` — convert address to lat/lng (optional, for employer)
- `map_launcher` or `google_maps_flutter` — map picker (optional)

## Rough Implementation Order
1. Add `geolocator` dependency
2. Update candidate onboarding + profile to capture lat/lng (GPS permission)
3. Update job posting to capture lat/lng (from text geocoding or map picker)
4. Add haversine utility function
5. Update swipe feed filter to use distance calculation
6. Update "N jobs near you" label with actual count

## Files to Touch
| File | Change |
|------|--------|
| `pubspec.yaml` | Add `geolocator`, `geocoding` dependencies |
| `lib/screens/candidate/onboarding_screen.dart` | Add location permission step |
| `lib/screens/candidate/profile_screen.dart` | Add lat/lng editing |
| `lib/screens/employer/post_job_screen.dart` | Add lat/lng fields or geocode location text |
| `lib/screens/candidate/job_screen.dart` | Add distance filtering logic |
| `lib/utils/` | New: `location_utils.dart` with haversine function |
| `lib/screens/candidate/widgets/job_card_content.dart` | Show distance badge (optional) |
