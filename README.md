# 📱 VibeTalk

> **End-to-end encrypted messaging, voice calling, video calling, screen sharing, file sharing, group chats, and emoji — for Android & iOS.**

[![CI/CD](https://github.com/omorfarukullas/VibeTalk/actions/workflows/ci.yml/badge.svg)](https://github.com/omorfarukullas/VibeTalk/actions/workflows/ci.yml)

---

## 🏗️ Tech Stack

| Layer | Technology |
|-------|-----------|
| **Frontend** | Flutter (Dart) |
| **Backend** | Node.js + Express + Socket.IO |
| **Database** | PostgreSQL (Supabase) |
| **Cache** | Redis (Upstash) |
| **File Storage** | Cloudflare R2 |
| **Authentication** | Firebase Auth (Phone OTP) |
| **Push Notifications** | Firebase Cloud Messaging (FCM) |
| **Voice/Video/Screen Share** | WebRTC + Coturn (Google Cloud) |
| **Encryption** | Signal Protocol (libsignal) |
| **Backend Hosting** | Railway |
| **CI/CD** | GitHub Actions |
| **Error Tracking** | Sentry |

---

## 📂 Project Structure

```
VibeTalk/
├── app/                          # Flutter mobile app
│   ├── lib/
│   │   ├── config/               # Environment, theme, DI
│   │   ├── core/                 # Network, storage, encryption, notifications, errors
│   │   ├── features/             # Feature modules (auth, chat, calls, groups, media, profile)
│   │   ├── routes/               # GoRouter navigation
│   │   ├── shared/               # Widgets, themes, utils, constants
│   │   └── main.dart             # App entry point
│   └── pubspec.yaml
│
├── backend/                      # Node.js API server
│   ├── src/
│   │   ├── config/               # Database, Redis, environment
│   │   ├── controllers/          # Request handlers
│   │   ├── middleware/           # Auth, error handling
│   │   ├── migrations/           # PostgreSQL schema migrations
│   │   ├── models/               # Data access layer
│   │   ├── routes/               # Express route definitions
│   │   ├── services/             # Business logic
│   │   ├── socket/               # Socket.IO real-time events
│   │   ├── utils/                # Logger, helpers
│   │   ├── app.js                # Express app setup
│   │   └── server.js             # HTTP server entry point
│   └── package.json
│
├── .github/workflows/ci.yml     # CI/CD pipeline
├── .gitignore
└── README.md
```

---

## 🚀 Getting Started

### Prerequisites

- **Flutter SDK** ≥ 3.41.0
- **Node.js** ≥ 18.0.0
- **npm** ≥ 9.0.0
- **PostgreSQL** (or Supabase account)
- **Redis** (or Upstash account)

### Flutter App Setup

```bash
cd app
cp .env.example .env          # Fill in your credentials
flutter pub get
dart run build_runner build    # Generate env.g.dart
flutter run
```

### Backend Setup

```bash
cd backend
cp .env.example .env           # Fill in your credentials
npm install
npm run dev                    # Starts with nodemon
```

### Database Setup

Run migration files in order against your PostgreSQL database:

```bash
# Using psql
psql $DATABASE_URL -f backend/src/migrations/001_create_users.sql
psql $DATABASE_URL -f backend/src/migrations/002_create_user_keys.sql
psql $DATABASE_URL -f backend/src/migrations/003_create_chats.sql
psql $DATABASE_URL -f backend/src/migrations/004_create_messages.sql
psql $DATABASE_URL -f backend/src/migrations/005_create_media.sql
psql $DATABASE_URL -f backend/src/migrations/006_create_calls.sql
psql $DATABASE_URL -f backend/src/migrations/007_create_groups.sql
```

---

## 🔐 Environment Variables

### Flutter App (`app/.env`)

| Variable | Description |
|----------|-------------|
| `FIREBASE_API_KEY` | Firebase Web API key |
| `FIREBASE_APP_ID` | Firebase app ID |
| `FIREBASE_MESSAGING_SENDER_ID` | FCM sender ID |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `API_BASE_URL` | Backend API URL |
| `CLOUDFLARE_R2_BUCKET` | R2 bucket name |
| `CLOUDFLARE_R2_ACCESS_KEY` | R2 access key |
| `CLOUDFLARE_R2_SECRET_KEY` | R2 secret key |
| `CLOUDFLARE_R2_ENDPOINT` | R2 endpoint URL |
| `SENTRY_DSN` | Sentry error tracking DSN |

### Backend (`backend/.env`)

| Variable | Description |
|----------|-------------|
| `PORT` | Server port (default: 3000) |
| `DATABASE_URL` | PostgreSQL connection string |
| `REDIS_URL` | Redis connection string |
| `JWT_SECRET` | JWT signing secret |
| `JWT_REFRESH_SECRET` | JWT refresh token secret |
| `FIREBASE_PROJECT_ID` | Firebase project ID |
| `FIREBASE_PRIVATE_KEY` | Firebase admin private key |
| `FIREBASE_CLIENT_EMAIL` | Firebase admin client email |
| `CLOUDFLARE_R2_*` | R2 storage credentials |
| `SENTRY_DSN` | Sentry error tracking DSN |

---

## 🌿 Branching Strategy

| Branch | Purpose | Rules |
|--------|---------|-------|
| `main` | Production releases | Requires PR + approval, no direct push |
| `develop` | Active development | All feature branches merge here |
| `feature/*` | Feature work | Named as `feature/sprint1-auth`, `feature/sprint2-chat`, etc. |
| `hotfix/*` | Critical bug fixes | Branched from `main`, merged to both `main` and `develop` |

### Branch Protection Rules

- **`main`**: Requires pull request review, status checks must pass, no force push
- **`develop`**: Requires status checks to pass before merging

---

## 📋 Sprint Plan

| Sprint | Duration | Focus |
|--------|----------|-------|
| Sprint 0 | Week 0 | Project scaffolding & infrastructure setup |
| Sprint 1 | Weeks 1-2 | Authentication (Firebase Phone OTP) |
| Sprint 2 | Weeks 3-4 | Real-time messaging (E2EE) |
| Sprint 3 | Weeks 5-6 | Voice/video calling (WebRTC) |
| Sprint 4 | Weeks 7-8 | Groups & file sharing |
| Sprint 5 | Weeks 9-10 | Polish, settings, notifications |

---

## 🧪 Testing

```bash
# Flutter
cd app && flutter test

# Backend
cd backend && npm test
```

---

## 📄 License

This project is proprietary and unlicensed for public use.
