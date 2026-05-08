# 🚀 Quick Start - Backend & Frontend Connected

## ✅ Backend Status

**Your backend is RUNNING!** 🎉

```
✅ Uvicorn running on http://0.0.0.0:8000
📚 API Docs at http://localhost:8000/docs
```

Server is ready to accept requests.

## 📱 Flutter Configuration

### Step 1: Update API Base URL

Edit **`lib/services/api_service.dart`** on line 2:

For **Android Emulator** (currently best):
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

For **Local Development** (Windows):
```dart
static const String baseUrl = 'http://localhost:8000/api';
```

For **iOS Simulator**:
```dart
static const String baseUrl = 'http://localhost:8000/api';
```

### Step 2: Start Android Emulator

```powershell
# List available emulators
flutter emulators

# Start an emulator (example)
flutter emulators launch Pixel_5_API_33

# Verify it's running
flutter devices
```

### Step 3: Run Flutter App

```powershell
cd frontend

# Clean and rebuild
flutter clean
flutter pub get

# Run on emulator
flutter run
```

## 🧪 Test the Connection

1. **Open the app** in Flutter
2. **Go to Register** screen
3. **Fill in a test account**:
   - Name: John Doe
   - Email: test@example.com
   - Phone: +221770000000
   - Password: Test123!
   - Role: farmer
   - Region: Dakar
4. **Click "S'inscrire"**

If registration works → **Backend & Frontend are connected!** ✅

## 📊 Backend API Documentation

Visit: **http://localhost:8000/docs**

You can test all endpoints here:
- POST `/api/auth/register`
- POST `/api/auth/login`
- POST `/api/farms/`
- GET `/api/farms/{farm_id}`
- And more...

## 🔗 How It Works

```
Flutter App (localhost)
     ↓ HTTP Request
     ↓ POST /api/auth/register
     ↓
FastAPI Backend (0.0.0.0:8000)
     ↓ Validate
     ↓ Create User
     ↓
PostgreSQL Database
     ↓ Save
     ↓
Backend → Flutter (JSON Response)
     ↓
App updates UI
```

## ⚡ Multiple Terminals Setup

Keep **3 terminals open**:

**Terminal 1 - Backend (KEEP RUNNING):**
```powershell
cd backend
venv\Scripts\activate
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

**Terminal 2 - Flutter:**
```powershell
cd frontend
flutter run
```

**Terminal 3 - Testing/Debugging:**
```powershell
# Open browser to http://localhost:8000/docs
# Monitor logs from both terminals
```

## 🐛 Troubleshooting

### Flutter can't connect to backend

**Issue:** Connection refused error

**Solution:** Make sure:
1. ✅ Backend is running (Terminal 1)
2. ✅ API URL is correct (check `api_service.dart`)
3. ✅ Emulator is running (run `flutter devices`)

### Change API URL

Edit `lib/services/api_service.dart` line 2:

**Before:**
```dart
static const String baseUrl = 'http://localhost:8000/api';
```

**After (Android):**
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

Then rebuild:
```powershell
flutter clean
flutter pub get
flutter run
```

## 📈 Next Steps

1. ✅ Backend running
2. ✅ Flutter configured
3. 🔄 Test registration/login
4. 📊 Explore API endpoints
5. 🎨 Customize UI
6. 🚀 Deploy!

---

**Everything is set up and ready!** 🌾✨
