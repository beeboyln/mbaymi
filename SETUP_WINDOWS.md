# 🪟 Setup Guide - Mbaymi on Windows

## Prerequisites

### ✅ Check if you have these installed

```powershell
python --version
flutter --version
```

If either is missing, install them first.

## 🔧 Backend Setup (FastAPI)

### Option 1: Automated Setup (Recommended)

Double-click **`setup_windows.bat`** in the `backend` folder.

This script will:
- ✅ Create Python virtual environment
- ✅ Activate it
- ✅ Install all dependencies
- ✅ Create `.env` file from template

### Option 2: Manual Setup

```powershell
cd backend

# Create virtual environment
python -m venv venv

# Activate it
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Copy environment file
copy .env.example .env
```

### ⚙️ Configure Backend

Edit **`.env`** file and add your Neon PostgreSQL URL:

```
DATABASE_URL=postgresql://[user]:[password]@[host]/[dbname]
SECRET_KEY=your-secret-key-here
DEBUG=False
```

**Where to get DATABASE_URL**:
1. Go to [neon.tech](https://neon.tech)
2. Create free account
3. Create new project
4. Copy connection string

### 🚀 Run Backend

**Option 1: Automated (Recommended)**

Double-click **`run.bat`** in the `backend` folder.

**Option 2: Manual**

```powershell
# Make sure venv is activated
venv\Scripts\activate

# Run FastAPI server
uvicorn app.main:app --reload
```

✅ Server should start at: **http://localhost:8000**

📚 API Docs: **http://localhost:8000/docs**

## 📱 Frontend Setup (Flutter)

### Option 1: Automated Setup (Recommended)

Double-click **`setup_windows.bat`** in the `frontend` folder.

This will:
- ✅ Check Flutter installation
- ✅ Get all dependencies
- ✅ List available devices

### Option 2: Manual Setup

```powershell
cd frontend

# Get dependencies
flutter pub get
```

### ⚙️ Configure API Endpoint

Edit **`lib/services/api_service.dart`** and update the base URL:

```dart
// For local development
static const String baseUrl = 'http://localhost:8000/api';

// For Android Emulator (special IP)
static const String baseUrl = 'http://10.0.2.2:8000/api';

// For actual backend deployed
static const String baseUrl = 'https://your-api-domain.com/api';
```

### 🚀 Run Frontend

**Option 1: Automated (Recommended)**

Double-click **`run.bat`** in the `frontend` folder.

**Option 2: Manual - List available devices**

```powershell
flutter devices
```

Choose your device:

```powershell
# Run on Android Emulator
flutter run -d emulator-5554

# Run on Chrome (Web)
flutter run -d chrome

# Run on connected phone
flutter run -d <device-id>
```

## 🐛 Troubleshooting

### Error: "Python is not installed"

**Solution**: Install Python from https://www.python.org/
- Make sure to check "Add Python to PATH" during installation
- Restart Windows after installation

### Error: "pip install" fails with Rust/Cargo errors

**Solution**: This was fixed in the new `requirements.txt`

Delete everything and restart:
```powershell
rmdir /s venv
python -m venv venv
venv\Scripts\activate
pip install -r requirements.txt
```

### Error: "uvicorn command not found"

**Solution**: Virtual environment not activated

```powershell
venv\Scripts\activate
# Then run:
pip install -r requirements.txt
```

### Error: "flutter not found"

**Solution**: Install Flutter from https://flutter.dev/docs/get-started/install/windows

### Error: "No devices found" for Flutter

**Solution**: Start Android Emulator or connect a physical device

```powershell
# List available emulators
flutter emulators

# Start emulator
flutter emulators launch <emulator-name>

# Then run
flutter run
```

### Backend won't connect from Flutter

**Solution**: Check API base URL in `lib/services/api_service.dart`

- Local development: `http://localhost:8000/api`
- Android Emulator: `http://10.0.2.2:8000/api` ← Special IP for emulator
- iOS Simulator: `http://localhost:8000/api`

## 📋 Quick Start Summary

### For Backend Developers

```powershell
# One time setup
cd backend
.\setup_windows.bat

# Every time you want to run
.\run.bat
```

### For Mobile Developers

```powershell
# One time setup
cd frontend
.\setup_windows.bat

# Every time you want to run
.\run.bat
```

### For Full Stack Development

**Terminal 1 - Backend:**
```powershell
cd backend
.\run.bat
# Listens on localhost:8000
```

**Terminal 2 - Frontend:**
```powershell
cd frontend
.\run.bat
# Listens on your device/emulator
```

## ✅ Verify Everything Works

### Backend Check

Visit: http://localhost:8000/docs

You should see Swagger API documentation with all endpoints.

### Frontend Check

When app starts, you should see:
- ✅ Mbaymi login screen
- ✅ Icons and green theme
- ✅ Input fields for email/password

### Full Integration Check

1. Register a new account in Flutter app
2. Check backend console for request logs
3. Login should work and redirect to home screen

## 📚 File Structure on Windows

```
mbaymi/
├── backend/
│   ├── venv/                 ← Virtual environment (created by setup_windows.bat)
│   ├── app/
│   ├── requirements.txt
│   ├── .env                  ← Created by setup_windows.bat
│   ├── setup_windows.bat     ← Run this first!
│   └── run.bat              ← Run this to start server
│
└── frontend/
    ├── lib/
    ├── pubspec.yaml
    ├── setup_windows.bat     ← Run this first!
    └── run.bat              ← Run this to start app
```

## 🚀 Next Steps

1. ✅ Setup backend with `setup_windows.bat`
2. ✅ Setup frontend with `setup_windows.bat`
3. ✅ Run backend with `run.bat` (Terminal 1)
4. ✅ Run frontend with `run.bat` (Terminal 2)
5. 🎉 Start developing!

---

**Need help?** Check the main [README.md](../README.md) or [DATABASE.md](../DATABASE.md)
