# 🔧 Common Issues & Solutions - Windows

## Backend Issues

### Issue 1: Rust/Cargo compilation errors

**Symptom:**
```
error: metadata-generation-failed
Cargo, the Rust package manager, is not installed or is not on PATH
```

**Cause:** Old dependencies tried to compile from source on Windows

**Solution:** 
- ✅ Already fixed in new `requirements.txt`
- Delete everything and reinstall:
  ```powershell
  rmdir /s venv
  python -m venv venv
  venv\Scripts\activate
  pip install -r requirements.txt
  ```

---

### Issue 2: "cp" command not found

**Symptom:**
```
'cp' n'est pas reconnu en tant que commande
```

**Cause:** `cp` is a Unix command, doesn't exist on Windows

**Solution:** Use one of these:

```powershell
# Option 1: PowerShell (Recommended)
Copy-Item .env.example .env

# Option 2: Command Prompt
copy .env.example .env

# Option 3: Use setup_windows.bat (Automatic)
.\setup_windows.bat
```

---

### Issue 3: Virtual environment not activating

**Symptom:**
```
'venv' is not recognized as an internal or external command
```

**Cause:** Virtual environment path is wrong

**Solution:**

```powershell
# Make sure you're in the backend directory
cd backend

# Activate with correct path
venv\Scripts\activate

# You should see (venv) in your command prompt
```

---

### Issue 4: uvicorn/pip commands not found

**Symptom:**
```
'uvicorn' n'est pas reconnu
'pip' n'est pas reconnu
```

**Cause:** Virtual environment not activated

**Solution:**

```powershell
# Always activate first!
venv\Scripts\activate

# Then use pip/uvicorn
pip install -r requirements.txt
uvicorn app.main:app --reload
```

---

### Issue 5: Database connection fails

**Symptom:**
```
ERROR: Could not connect to database
Database URL is invalid
```

**Cause:** Missing or wrong `DATABASE_URL` in `.env`

**Solution:**

1. Get PostgreSQL URL from Neon:
   - Go to https://neon.tech
   - Create account (free)
   - Create project
   - Copy connection string

2. Edit `.env`:
   ```
   DATABASE_URL=postgresql://username:password@host/dbname
   ```

3. Test connection:
   ```powershell
   python
   from app.database import engine
   engine.connect()  # Should not error
   ```

---

### Issue 6: Port 8000 already in use

**Symptom:**
```
Address already in use: ('0.0.0.0', 8000)
```

**Cause:** Another process using port 8000

**Solution:**

```powershell
# Kill process on port 8000
netstat -ano | findstr :8000
taskkill /PID <PID> /F

# Or use different port
uvicorn app.main:app --reload --port 8001
```

---

### Issue 7: Long error message about bcrypt/passlib

**Symptom:**
```
error in passlib setup command: use_scm_version=True
```

**Cause:** Outdated dependencies

**Solution:**
```powershell
pip install --upgrade passlib bcrypt
# Or reinstall everything
```

---

## Frontend Issues

### Issue 1: Flutter not found

**Symptom:**
```
'flutter' n'est pas reconnu
```

**Cause:** Flutter not installed or not in PATH

**Solution:**

1. Install Flutter: https://flutter.dev/docs/get-started/install/windows
2. Add to PATH:
   - Control Panel → Environment Variables
   - Add: `C:\path\to\flutter\bin`
3. Restart PowerShell/Command Prompt
4. Verify:
   ```powershell
   flutter --version
   ```

---

### Issue 2: No connected devices

**Symptom:**
```
No devices found
```

**Cause:** No emulator running or phone connected

**Solution:**

**Option A: Start Android Emulator**
```powershell
# List available emulators
flutter emulators

# Start one
flutter emulators launch <emulator-name>

# Then run app
flutter run
```

**Option B: Connect physical phone**
- Enable Developer Mode on phone
- Connect via USB cable
- Run: `flutter run`

**Option C: Run on Web (requires Chrome)**
```powershell
flutter run -d chrome
```

---

### Issue 3: API connection error from Flutter app

**Symptom:**
```
Failed to connect to backend API
Connection refused
```

**Cause:** Wrong API base URL or backend not running

**Solution:**

1. Check backend is running:
   ```powershell
   # In backend folder
   .\run.bat
   # Should see: "Uvicorn running on http://localhost:8000"
   ```

2. Update API URL in `lib/services/api_service.dart`:
   
   **For local development:**
   ```dart
   static const String baseUrl = 'http://localhost:8000/api';
   ```

   **For Android Emulator:**
   ```dart
   static const String baseUrl = 'http://10.0.2.2:8000/api';
   // 10.0.2.2 is special IP in Android emulator for localhost
   ```

   **For actual backend deployed:**
   ```dart
   static const String baseUrl = 'https://your-backend-domain.com/api';
   ```

3. Rebuild and run:
   ```powershell
   flutter clean
   flutter pub get
   flutter run
   ```

---

### Issue 4: Gradle build fails

**Symptom:**
```
FAILURE: Build failed with an exception
```

**Cause:** JDK or Gradle issues

**Solution:**

```powershell
# Clean and rebuild
flutter clean
flutter pub get
flutter run

# If still fails, upgrade Flutter
flutter upgrade
```

---

### Issue 5: Package version conflicts

**Symptom:**
```
pub.dev: version conflict
```

**Cause:** Dependencies in `pubspec.yaml` conflict

**Solution:**

```powershell
# Get latest compatible versions
flutter pub upgrade

# Or reset
flutter clean
flutter pub get
```

---

## Database Issues

### Issue 1: Cannot connect to PostgreSQL

**Symptom:**
```
Error: could not translate host name "host" to address
```

**Cause:** Wrong database URL

**Solution:**

1. Get correct URL from Neon PostgreSQL
2. Format: `postgresql://user:password@host:5432/dbname`
3. Make sure it's in `.env`:
   ```
   DATABASE_URL=postgresql://...
   ```

---

### Issue 2: Database locked

**Symptom:**
```
database is locked
```

**Cause:** Multiple connections trying to write

**Solution:**

```powershell
# Restart the backend server
# This closes all connections
```

---

## General Windows Tips

### Running Multiple Terminals

For full development (backend + frontend), use **Windows Terminal**:

```powershell
# Terminal 1 - Backend
cd mbaymi\backend
.\run.bat

# Terminal 2 - Frontend (use split view)
cd mbaymi\frontend
.\run.bat
```

### Environment Variables

To set environment variables permanently:

**PowerShell (Recommended):**
```powershell
$env:DATABASE_URL = "postgresql://..."
$env:SECRET_KEY = "your-secret"
```

**Command Prompt:**
```cmd
set DATABASE_URL=postgresql://...
set SECRET_KEY=your-secret
```

**Permanent (System):**
- Settings → Environment Variables → New User Variable

### Useful Commands

```powershell
# Check Python version
python --version

# Check Flutter version
flutter --version

# List environment variables
$env:DATABASE_URL

# Clear terminal
Clear-Host

# Kill process on port
netstat -ano | findstr :8000
```

---

## Getting Help

1. **Check API Docs**: http://localhost:8000/docs (when backend running)
2. **Flutter Doctor**: `flutter doctor` (checks setup)
3. **Check Logs**: Look for error messages in terminal
4. **Database**: Test connection with `psql` or Neon dashboard

---

**Still stuck?** Check the main [SETUP_WINDOWS.md](SETUP_WINDOWS.md) guide!
