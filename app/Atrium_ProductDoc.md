# Atrium — Product Documentation

> Tinder for Jobs & Portfolio Showcase. Swipe-based hiring for small businesses, talent, and project discovery.

**Version:** `1.4.0+4` · **Last updated:** September 2026

---

## Table of Contents

1. [Idea & Vision](#1-idea--vision)
2. [Target Users](#2-target-users)
3. [App Architecture](#3-app-architecture)
4. [Screen Inventory](#4-screen-inventory)
5. [User Flows](#5-user-flows)
6. [Feature Roadmap](#6-feature-roadmap)
7. [Styling & Theme](#7-styling--theme)
8. [Tech Stack](#8-tech-stack)
9. [Key Design Rules](#9-key-design-rules)
10. [Monetisation](#10-monetisation)

---

## 1. Idea & Vision

Atrium borrows the swipe mechanic from Tinder and applies it to local job hiring and creative portfolio showcases. The core problem it solves: traditional hiring is broken for small businesses and talent. Uploading a resume, filling 40-field forms, waiting weeks — none of that works for a local business owner or creative who needs fast, visual matching.

**The core loop:**
1. Employer posts a job card (concise, structured, swipeable).
2. Candidate swipes right (interested) or left (skip).
3. Employer then reviews interested candidates and swipes right or left.
4. On **mutual match** → chat unlocks instantly.
5. Employer proposes an interview slot → candidate confirms → done.

**Why it works:**
- Friction reduction: near-zero effort to apply or post.
- Mutual match before contact: no spam, no cold ghosting.
- Local-first: built for the SMB owner hiring within 20 km, not multinational corporations.
- Dopamine loop: the swipe mechanic keeps both sides engaged.

---

## 2. Target Users

### Candidates
- Local job seekers (18–35), blue-collar to entry-level white-collar.
- Looking for part-time, full-time, or gig work nearby.
- May not have a polished resume — just skills and availability.

### Employers
- Small business owners: shops, restaurants, salons, local startups.
- Hiring 1–5 people at a time, need quick turnaround.
- Not tech-savvy enough for LinkedIn/Indeed-level complexity.

---

## 3. App Architecture

```
┌──────────────────────────────────────────────────┐
│             Flutter App (iOS + Android)          │
│   Auth screens · Swipe UI · Matches · Chat       │
└────────────────────┬─────────────────────────────┘
                     │
              REST API Gateway
          Auth · Rate limiting · JWT
                     │
    ┌────────────┬───┴────────┬─────────────┐
    │            │            │             │
Auth Service  Job Service  Swipe Engine  Notify Service
Google/OTP   Post/edit    Match logic    Push/FCM
                expire       feed
                     │
    ┌────────────┬───┴────────┬─────────────┐
    │            │            │             │
PostgreSQL     Redis      Firebase      Algolia
users/jobs   swipes/     Storage       job search
             sessions    (media)
                     │
         Third-party Integrations
  Firebase Auth · Razorpay · Google Maps
  FCM · Calendly API · WhatsApp (v3)
```

### Real-time Layer
WebSocket (Socket.IO) handles:
- Match events (fires instantly when both sides swipe right)
- In-app chat messages
- Interview booking confirmations

---

## 4. Screen Inventory

### Shared / Onboarding
| Screen | File | Status | Purpose |
|---|---|---|---|
| Splash | `splash_screen.dart` | ✅ | Branded cover during Firebase init |
| Login | `login_screen.dart` | ✅ | Email/password + Google Sign-In |
| Sign Up | `signup_screen.dart` | ✅ | Name, email, password, phone, business name |
| Role Selection | `role_selection.dart` | ✅ | Pick: Candidate or Employer (saved to Firestore) |

### Candidate Screens
| Screen | File | Status | Purpose |
|---|---|---|---|
| Onboarding | `candidate/onboarding_screen.dart` | ✅ | Skills, pay, location (GPS), radius, availability — shown once |
| Job Swipe Feed | `candidate/job_screen.dart` | ✅ | Swipeable job cards, distance-filtered |
| Match Celebration | `candidate/match_screen.dart` | ✅ | "It's a Match!" overlay on mutual match |
| Matches Inbox | `candidate/inbox_screen.dart` | ✅ | List of all mutual matches |
| Chat | `candidate/chat_screen.dart` | ✅ | Post-match messaging (text/image/document/interview) |
| Profile | `candidate/profile_screen.dart` | ✅ | Skills, bio, photo, availability, pay, location edit |
| Company Profile | `candidate/company_profile_screen.dart` | ✅ | View employer company details from job card |
| Interview Detail | `candidate/interview_detail_screen.dart` | 🔲 | Empty — planned for calendar integration |
| Notifications | `notification_screen.dart` | 🔲 | Planned: in-app log of matches, messages, alerts |

### Employer Screens
| Screen | File | Status | Purpose |
|---|---|---|---|
| Employer Home | `employer/employer_home_screen.dart` | ✅ | Dashboard: active jobs, match counts, interview pipeline |
| Post a Job | `employer/post_job_screen.dart` | ✅ | Title, pay range, location (geocoded), requirements |
| Candidate Review | `employer/candidates_screen.dart` | ✅ | Swipe through interested candidates per job |
| Matched Candidates | `employer/matched_candidates_screen.dart` | ✅ | All mutual matches, chat entry point |
| Candidate Details | `employer/candidate_details_screen.dart` | ✅ | Full candidate profile, resume view/download |
| PDF Viewer | `employer/pdf_viewer_screen.dart` | ✅ | Native PDF rendering via `flutter_pdfview` |
| Schedule Interview | `employer/schedule_interview_screen.dart` | ✅ | Date/time picker → sends interview card in chat |
| Employer Profile | `employer/employer_profile_screen.dart` | ✅ | Business name, logo, location, about |

---

## 5. User Flows

### Candidate Flow

```
Splash
  └─► AuthGate
        ├─ (no user) ──► Login / Sign Up
        │                    └─► Role Selection ──► Candidate Onboarding
        └─ (signed in)
              └─► Job Swipe Feed
                    ├─ Swipe Left ──► next card
                    ├─ Swipe Right ──► (waiting for employer)
                    │     └─ Employer also swipes right
                    │           └─► Match Screen ("It's a Match!")
                    │                 └─► Chat unlocks
                    │                       └─► Interview Detail (on confirmation)
                    └─ Tap card ──► Job Detail Screen
```

### Employer Flow

```
Splash
  └─► AuthGate
        ├─ (no user) ──► Login / Sign Up
        │                    └─► Role Selection ──► Post a Job
        └─ (signed in)
              └─► Employer Home Dashboard
                    ├─ Post a Job ──► Job goes live
                    ├─ Candidate Swipe Feed (per job)
                    │     ├─ Swipe Left ──► pass
                    │     └─ Swipe Right ──► (if candidate already swiped right)
                    │           └─► Match fires ──► Matched Candidates list
                    │                 └─► Chat ──► Schedule Interview
                    └─ Interview confirmed ──► Calendar invite sent to candidate
```

### Match Event (real-time)
```
Candidate swipes right on Job A
  └─► Stored in Redis as "candidate_interested: {jobId, candidateId}"

Employer swipes right on same Candidate
  └─► Backend detects mutual interest
        └─► WebSocket fires match event to BOTH devices simultaneously
              ├─ Candidate sees "It's a Match!" overlay
              └─ Employer sees candidate added to Matched list
                    └─ Chat thread created in DB
```

---

## 6. Feature Roadmap

### MVP — v1 ✅ Shipped

| Feature | Status | Notes |
|---|---|---|
| Dual role accounts | ✅ | Candidate or Employer chosen at signup, stored in Firestore |
| Job card format | ✅ | Title, pay range, location, 3-bullet requirements |
| Swipe feed (candidates) | ✅ | Card stack UI with haversine distance filtering |
| Candidate review (employers) | ✅ | Employer sees only right-swiped candidates |
| Mutual match logic | ✅ | Chat unlocks on mutual right-swipe |
| In-app chat | ✅ | Text, images, documents, interview cards |
| Interview slot booking | ✅ | Propose slot → candidate accepts/declines → push notification |
| Location-based feed | ✅ | GPS + haversine filter by candidate's radius preference |
| Push notifications | ✅ | Match, message, interview response via FCM |
| Basic employer verification | ✅ | Phone + business name on signup |
| Resume upload & PDF viewer | ✅ | Candidate uploads resume; employer views natively via `flutter_pdfview` |

### V2 — Growth Features

| Feature | Description |
|---|---|
| Smart match score | Rank candidates by skill overlap, location, availability fit |
| Video intro (30 sec) | Candidate records a quick intro — replaces cover letters |
| Employer dashboard | Active jobs, match counts, interview pipeline in one view |
| Job expiry & boost | Jobs auto-expire in 30 days; pay to boost to top of feed |
| Saved / revisit | Undo last swipe; save a job to decide later |
| Skill tags & filters | Filter by industry, pay range, job type |
| Calendly integration | Employer connects calendar; candidate picks slot automatically |
| Referral system | Candidates refer friends, earn perks |
| Post-hire rating | Both sides rate the experience; builds trust scores |
| Multi-job posting | Employer manages multiple openings from one dashboard |

### V3 — Scale & Monetisation

| Feature | Description |
|---|---|
| AI-assisted job cards | Employer types rough description → AI formats the card |
| Background check (optional) | Digilocker or third-party ID + background verification |
| Employer subscription | Free: 2 active jobs. Pro ₹999/mo: unlimited + analytics |
| Candidate premium | See who saved your profile; priority in employer feed |
| WhatsApp notifications | Match + interview alerts for low-smartphone users |
| Regional language support | Gujarati + Hindi UI — critical for SMB owners |
| Analytics for employers | Views, match rate, time-to-hire per job |
| Agency / recruiter mode | Recruiters manage multiple employers; commission per placement |

---

## 7. Styling & Theme

### Theme: Slate + Blue (Recommended)

Chosen for trust, clarity, and professionalism. Hiring apps require users to make real decisions — the palette projects confidence without feeling corporate.

### Color Palette

| Token | Hex | Usage |
|---|---|---|
| `primary` | `#1E293B` | Nav bars, headers, dark surfaces |
| `accent` | `#3B82F6` | CTAs, active states, links |
| `accentLight` | `#DBEAFE` | Chip backgrounds, tag fills |
| `accentDark` | `#1D4ED8` | Pressed accent states |
| `background` | `#F8FAFC` | Page canvas (scaffold bg) |
| `surface` | `#FFFFFF` | Cards, sheets, inputs |
| `surfaceVariant` | `#F1F5F9` | Secondary surface |
| `textPrimary` | `#1E293B` | Headings, body text |
| `textSecondary` | `#64748B` | Subtitles, meta info |
| `textHint` | `#94A3B8` | Placeholder text |
| `border` | `#E2E8F0` | Card borders, dividers |
| `swipeRight` | `#16A34A` | ✓ Swipe right indicator |
| `swipeLeft` | `#DC2626` | ✕ Swipe left indicator |
| `error` | `#DC2626` | Form errors |
| `success` | `#16A34A` | Success states |
| `warning` | `#F59E0B` | "Urgent" badges, alerts |

### Typography — Inter Font Family

| Style | Size | Weight | Usage |
|---|---|---|---|
| `displayLarge` | 32px | 700 | Hero headers |
| `headlineMedium` | 18px | 600 | Section headings |
| `headlineSmall` | 16px | 600 | AppBar title |
| `jobTitle` | 22px | 700 | Job card title |
| `jobCompany` | 15px | 500 | Company name on card |
| `salaryLabel` | 18px | 700 | Pay range (accent color) |
| `bodyMedium` | 14px | 400 | General body text |
| `bodySmall` | 13px | 400 | Meta info, timestamps |
| `buttonLabel` | 15px | 600 | Button text |
| `navLabel` | 11px | 500 | Bottom nav labels |
| `matchBanner` | 28px | 800 | "It's a Match!" text |

### Spacing Scale

| Token | Value | Usage |
|---|---|---|
| `xs` | 4px | Icon gaps, tight padding |
| `sm` | 8px | Between inline elements |
| `md` | 12px | Inner card padding |
| `lg` | 16px | Standard section gap |
| `xl` | 20px | Page horizontal padding |
| `xxl` | 24px | Between major sections |
| `xxxl` | 32px | Large screen breathing room |

### Border Radius

| Token | Value | Usage |
|---|---|---|
| `sm` | 6px | Badges, small pills |
| `md` | 10px | Buttons, input fields |
| `lg` | 14px | Standard cards |
| `xl` | 20px | Bottom sheets, modals |
| `xxl` | 28px | Large feature cards |
| `cardRadius` | 24px | Swipe job cards |
| `full` | 999px | Chip tags, avatar rings |

### Key Shadows

```dart
// Card shadow — subtle depth
BoxShadow(color: slate900 @ 6%, blurRadius: 16, offset: Offset(0, 4))

// Job swipe card — more prominent
BoxShadow(color: slate900 @ 10%, blurRadius: 32, offset: Offset(0, 8))

// Button shadow — accent glow
BoxShadow(color: accent @ 28%, blurRadius: 12, offset: Offset(0, 4))
```

### Swipe Overlays

- **Swipe Right (Yes):** Green border `#16A34A`, light green bg `#DCFCE7` at 90% opacity
- **Swipe Left (No):** Red border `#DC2626`, light red bg `#FEE2E2` at 90% opacity
- Overlay animates opacity based on drag distance (0 → 1 as card reaches edge)

### Component Decisions

- **Buttons:** Full-width (52px height), rounded `10px`, no elevation — flat modern look
- **Cards:** 0.5px border over shadow — cleaner than pure shadow cards on light backgrounds
- **Inputs:** Filled + outlined hybrid — fill on idle, accent border on focus
- **Bottom nav:** M3 `NavigationBar` with accent indicator pill behind selected icon
- **Chips:** Stadium shape, no border, slate-100 bg (accent-light when selected)
- **Bottom sheets:** Drag handle always visible, `20px` top radius

---

## 8. Tech Stack

### Flutter App (Actual packages in use)
| Concern | Package | Version |
|---|---|---|
| State management | `setState` + `StreamBuilder` | (built-in) |
| Navigation | Named routes + `RouteSettings` | (built-in) |
| HTTP client | `dio` | `^5.8.0` |
| Image handling | `cached_network_image` | `^3.4.1` |
| Image picker | `image_picker` | `^1.1.2` |
| File picker | `file_picker` | `^11.0.2` |
| PDF viewer | `flutter_pdfview` | `^1.3.2` |
| File opener | `open_filex` | `^4.5.0` |
| Auth | `firebase_auth` + `google_sign_in` | `^6.5.4` / `^7.2.0` |
| Push notifs | `firebase_messaging` + `flutter_local_notifications` | `^16.4.1` / `^18.0.1` |
| Location | `geolocator` + `geocoding` | `^13.0.2` / `^3.0.0` |
| Permissions | `permission_handler` | `^12.0.3` |
| URL opening | `url_launcher` | `^6.3.1` |

### Backend
| Layer | Choice |
|---|---|
| Runtime | Node.js (Express) |
| Primary DB | PostgreSQL |
| Cache / sessions | Redis |
| Media storage | Firebase Storage |
| Search | Algolia |
| Real-time | Socket.IO |
| Auth | Firebase Auth (JWT verification) |

### Third-party
| Service | Purpose |
|---|---|
| Firebase Auth | Google + Phone OTP login |
| FCM | Push notifications |
| Google Maps API | Location picker, radius filter |
| Razorpay | Indian payment gateway (employer subscriptions) |
| Calendly API | V2 interview scheduling |
| Digilocker | V3 background verification |

---

## 9. Key Design Rules

1. **Job card = max 5 data points.** Role, company name, pay, location, one key requirement. Nothing else on the card face.

2. **Employers see candidates only after the candidate swiped right.** This cuts spam — employers only browse people who are already interested, making every swipe meaningful.

3. **Chat unlocks only on mutual match.** No cold messages. Both sides opted in before any communication starts.

4. **No resume uploads in MVP.** Candidate profile = skills tags + 2-line bio + location + availability toggle. Keep it frictionless.

5. **Swipe overlay is feedback, not decoration.** Animate the green/red overlay as a direct function of drag distance — users should feel the decision before they make it.

6. **Employer posts expire in 30 days.** Prevents stale listings polluting the candidate feed. Employers get a push reminder at day 25.

7. **Local radius is a first-class filter.** Default 15 km. Candidates can expand to 50 km. Never show jobs with no commute path.

8. **Match celebration is a moment.** The "It's a Match!" screen should feel rewarding — use Lottie animation + haptic feedback. Don't skip this; it's the dopamine hit that drives retention.

---

## 10. Monetisation

### Philosophy
- **Free for candidates, always.** Candidates are the supply side — charging them kills the network.
- **Charge employers.** They derive direct business value from a hire.

### Pricing Tiers (from V2 onward)

| Plan | Price | Includes |
|---|---|---|
| Free | ₹0 | 2 active job posts, basic matching, chat |
| Pro | ₹999/mo | Unlimited posts, boost credits, analytics, priority support |
| Boost (à la carte) | ₹199/boost | Push one job to top of local feed for 7 days |

### V3 Revenue Streams
- Candidate premium: ₹99/mo — see who saved your profile, appear higher in employer feed
- Recruiter accounts: commission-based per successful placement
- WhatsApp notification service: ₹49/job post add-on for broader reach

---

*Document reflects implementation state as of July 2026 · v1.2.1. Update after each sprint.*
