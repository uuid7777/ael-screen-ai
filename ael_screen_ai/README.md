# AEL Screen AI

AI-powered screen translation app built with Flutter. Translate text from images and screenshots in real-time.

## Architecture

```
ael_screen_ai/          # Flutter app (Android + iOS)
backend/                # FastAPI backend server
  app/                  # Python application
    models/             # Pydantic data models
    routes/             # API endpoints
    services/           # Business logic
    supabase/           # Database migrations
```

## Quick Start

### 1. Backend Setup

```bash
cd backend
cp .env.example .env
# Edit .env with your credentials:
#   SUPABASE_URL, SUPABASE_ANON_KEY
#   DASHSCOPE_API_KEY (for Tongyi Qianwen translation)

pip install -r requirements.txt
python run.py
```

The API server starts at `http://localhost:8000`.
Swagger docs: `http://localhost:8000/docs`

### 2. Database Setup

Open Supabase SQL Editor and run:
```
backend/app/supabase/migration.sql
```

This creates all tables: profiles, translations, favorites, subscriptions, user_settings, logs.

### 3. Flutter App Setup

```bash
# Install Flutter SDK first: https://flutter.dev/docs/get-started/install
cd ael_screen_ai

# Edit config in lib/config/app_config.dart
#   baseUrl: your backend URL
#   supabaseUrl: your Supabase URL
#   supabaseAnonKey: your Supabase anon key

flutter pub get
flutter run           # Run on connected device
# OR
flutter build apk    # Build Android APK
flutter build ios    # Build iOS (requires macOS + Xcode)
```

## Android Features

### Floating Bubble Overlay
- Drag anywhere on screen
- Tap to capture screenshot
- Auto OCR + translate
- Shows result in mini overlay window

### Required Android Permissions
- `SYSTEM_ALERT_WINDOW` - For floating bubble
- `FOREGROUND_SERVICE` + `FOREGROUND_SERVICE_MEDIA_PROJECTION` - For screen capture
- `CAMERA` - For photo mode
- `POST_NOTIFICATIONS` - For service notification

## API Endpoints

| Endpoint | Method | Description |
|---|---|---|
| `/auth/register` | POST | Register new user |
| `/auth/login` | POST | Login |
| `/auth/apple` | POST | Apple Sign-In |
| `/auth/me` | GET | Get user profile |
| `/translate/` | POST | Translate text |
| `/translate/ocr` | POST | OCR image |
| `/translate/screen` | POST | OCR + Translate |
| `/history/` | GET/DELETE | Translation history |
| `/favorites/` | GET/POST/DELETE | Favorites |
| `/subscriptions/status` | GET | Subscription status |

## Tech Stack

- **Frontend**: Flutter, Riverpod, Google ML Kit OCR
- **Backend**: FastAPI, Supabase
- **AI**: Alibaba Cloud Tongyi Qianwen
- **Android**: Foreground Service, MediaProjection, Overlay Bubble

## Required Parameters (fill in .env / app_config.dart)

- [ ] `SUPABASE_URL` - Your Supabase project URL
- [ ] `SUPABASE_ANON_KEY` - Your Supabase anonymous key
- [ ] `DASHSCOPE_API_KEY` - Alibaba Cloud DashScope API key for translation
- [ ] `JWT_SECRET` - Secret for token generation (change in production)
- [ ] `Package name` - Currently `com.ael.screenai`, change if needed
- [ ] `Apple Developer Team` - For iOS build and Sign in with Apple
