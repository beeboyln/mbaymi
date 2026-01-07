# 🎯 Complete Startup Guide - Mbaymi Project

## 📋 Prerequisites Checklist

Before starting, make sure you have:

- [x] Python 3.10+ installed
- [x] Flutter installed
- [x] Git installed
- [x] PostgreSQL (Neon) account set up
- [x] Android Emulator or physical device

## 🚀 Startup Steps (In Order)

### Phase 1: Backend Setup (First Time Only)

#### Step 1.1: Navigate to backend

```powershell
cd backend
```

#### Step 1.2: Create virtual environment

```powershell
python -m venv venv
venv\Scripts\activate
```

#### Step 1.3: Install dependencies

```powershell
pip install -r requirements.txt
```

#### Step 1.4: Configure database

```powershell
# Copy example to actual config
copy .env.example .env
```

Edit `.env` file and add your Neon PostgreSQL URL:
```
DATABASE_URL=postgresql://username:password@host/dbname
SECRET_KEY=your-secret-key-here
DEBUG=False
```

#### Step 1.5: Verify installation

```powershell
# Test that everything is installed
python -c "import fastapi; import sqlalchemy; print('✅ Dependencies OK')"
```

### Phase 2: Start Backend Server

```powershell
# Make sure you're in backend directory with venv activated
cd backend
venv\Scripts\activate

# Start the server
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

**Expected output:**
```
INFO:     Started server process
INFO:     Application startup complete.
✅ Routes loaded
📚 API Docs at http://localhost:8000/docs
INFO:     Uvicorn running on http://0.0.0.0:8000
```

**Keep this terminal OPEN!** ← IMPORTANT

### Phase 3: Frontend Setup (In New Terminal)

```powershell
cd frontend

# Get dependencies
flutter pub get

# Check devices available
flutter devices
```

### Phase 4: Start Frontend App (In New Terminal)

```powershell
cd frontend

# Start on Android emulator (recommended)
flutter run

# Or specify device:
flutter run -d emulator-5554
```

**Expected output:**
```
Launching lib\main.dart on Android...
✓ Built build/app/outputs/flutter-app.apk
```

## ✅ Full Startup Checklist

### Required Running Processes:

- [ ] **Terminal 1**: Backend running on `http://0.0.0.0:8000`
  ```
  python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
  ```

- [ ] **Terminal 2**: Flutter app running on emulator
  ```
  flutter run
  ```

### Verify Everything Works:

1. **Open Flutter app** → Should see login screen ✅
2. **Visit http://localhost:8000/docs** → Should see API docs ✅
3. **Try registering** in the app → Check backend console for logs ✅

## 🔧 Configuration Options

### Change API Base URL (in lib/services/api_service.dart)

**For Android Emulator** (Recommended):
```dart
static const String baseUrl = 'http://10.0.2.2:8000/api';
```

**For Local Windows Development:**
```dart
static const String baseUrl = 'http://localhost:8000/api';
```

**For iOS Simulator:**
```dart
static const String baseUrl = 'http://localhost:8000/api';
```

**For Deployed Backend:**
```dart
static const String baseUrl = 'https://your-api-domain.com/api';
```

Then rebuild: `flutter clean && flutter pub get && flutter run`

## 📊 Project Structure

```
mbaymi/
├── backend/                 ← FastAPI server
│   ├── venv/               ← Virtual environment (created)
│   ├── app/
│   │   ├── models/         ← Database models
│   │   ├── routes/         ← API endpoints
│   │   ├── services/       ← Business logic
│   │   └── main.py         ← FastAPI app
│   ├── requirements.txt    ← Python packages
│   ├── .env                ← Your config (KEEP SECRET!)
│   └── run.bat             ← Quick start script
│
├── frontend/               ← Flutter app
│   ├── lib/
│   │   ├── models/         ← Data models
│   │   ├── screens/        ← UI screens
│   │   ├── services/       ← API client
│   │   └── main.dart       ← App entry
│   ├── pubspec.yaml        ← Dependencies
│   └── run.bat             ← Quick start script
│
├── README.md               ← Main documentation
├── SETUP_WINDOWS.md        ← Windows setup guide
├── DATABASE.md             ← Database documentation
├── DEPLOYMENT.md           ← Deployment guide
├── QUICKSTART.md           ← Quick reference
└── TROUBLESHOOTING_WINDOWS.md ← Common issues
```

## 🐛 Quick Troubleshooting

### Backend won't start

**Problem:** `'uvicorn' is not recognized`

**Solution:**
```powershell
cd backend
venv\Scripts\activate
pip install -r requirements.txt
```

### Flask can't find database

**Problem:** `Database connection error`

**Solution:**
1. Check `.env` file has DATABASE_URL
2. Verify Neon PostgreSQL URL is correct
3. Test connection separately

### Flutter can't connect to API

**Problem:** `Connection refused in Flutter`

**Solution:**
1. Ensure backend is running (Terminal 1)
2. Check `lib/services/api_service.dart` has correct base URL
3. For Android: Use `http://10.0.2.2:8000/api`
4. Rebuild: `flutter clean && flutter pub get && flutter run`

### No Flutter devices found

**Problem:** `No devices found`

**Solution:**
```powershell
# Start Android emulator first
flutter emulators

# Then run
flutter run
```

## 📖 Documentation Files

- **[README.md](README.md)** - Project overview
- **[SETUP_WINDOWS.md](SETUP_WINDOWS.md)** - Detailed Windows setup
- **[DATABASE.md](DATABASE.md)** - Database schema & Neon setup
- **[DEPLOYMENT.md](DEPLOYMENT.md)** - Production deployment
- **[TROUBLESHOOTING_WINDOWS.md](TROUBLESHOOTING_WINDOWS.md)** - Common issues
- **[QUICKSTART.md](QUICKSTART.md)** - Quick reference

## 🚀 After Everything is Running

Now you can:

1. **Test the API** at http://localhost:8000/docs
2. **Register** a new account from Flutter app
3. **Add farms** and livestock
4. **Get advice** for crops and animals
5. **View market prices**

## 🎉 Success Indicators

✅ Backend starting with no errors
✅ Flutter app launching on emulator
✅ Login/Register screen visible
✅ No connection errors in logs
✅ API responding at localhost:8000

## 📝 Next Development Steps

1. Implement User State Management (Provider)
2. Add Local Storage (Hive/SQLite)
3. Implement Chat Functionality
4. Add Photo Upload
5. Integrate Push Notifications
6. Deploy to Koyeb + Neon

## 💾 Saving Your Work

When you're done developing:

```powershell
# Backend
git add backend/
git commit -m "Backend improvements"

# Frontend
git add frontend/
git commit -m "Frontend improvements"

# Push
git push origin main
```

---

**Everything is ready!** You can now start developing Mbaymi! 🌾✨
