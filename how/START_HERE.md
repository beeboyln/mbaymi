# 🎯 START HERE - Mbaymi Setup Quick Guide

## ⚡ 5-Minute Quick Start

### Step 1: Create Database (2 min)

1. Go to https://neon.tech
2. Create free account
3. Create new PostgreSQL project
4. Copy CONNECTION STRING
5. Open **SQL Editor** in Neon
6. Copy ALL content from **`database.sql`** file in this project
7. Paste in SQL Editor
8. Click **"Run"**
9. ✅ Done! Save your CONNECTION_STRING

**Example:**
```
postgresql://username:password@ep-random.us-east-1.neon.tech/mbaymi
```

---

### Step 2: Setup Backend (2 min)

On Windows (if you're on Mac/Linux, adjust paths):

```powershell
cd c:\Users\bmd-tech\Desktop\mbaymi\backend

# Activate virtual environment
venv\Scripts\activate

# Install dependencies
pip install -r requirements.txt

# Create .env file
copy .env.example .env
```

**Edit `.env` file:**
```
DATABASE_URL=postgresql://username:password@host/mbaymi
SECRET_KEY=your-secret-key-here
DEBUG=False
```

**Run backend:**
```powershell
python -m uvicorn app.main:app --reload
```

✅ Backend should be running at http://localhost:8000/docs

---

### Step 3: Setup Frontend (1 min)

```powershell
cd c:\Users\bmd-tech\Desktop\mbaymi\frontend

# Get dependencies
flutter pub get

# IMPORTANT: Update API URL
# Edit: lib/services/api_service.dart
# Find: static const String baseUrl = ...
# Change to: http://localhost:8000/api
```

**Run Flutter:**
```powershell
flutter run
```

✅ You should see the Mbaymi login screen!

---

## 📖 Documentation Files

### For Setup
- **[SETUP_WINDOWS.md](SETUP_WINDOWS.md)** ← Detailed Windows setup
- **[CHECKLIST.md](CHECKLIST.md)** ← Complete step-by-step checklist
- **[FILE_STRUCTURE.md](FILE_STRUCTURE.md)** ← Where all files are

### For Using Database
- **[QUICK_SQL.md](QUICK_SQL.md)** ← Copy-paste SQL commands
- **[SQL_SETUP.md](SQL_SETUP.md)** ← How to use database.sql
- **[DATABASE.md](DATABASE.md)** ← Database schema details

### For Problems
- **[TROUBLESHOOTING_WINDOWS.md](TROUBLESHOOTING_WINDOWS.md)** ← Common issues

### For Deployment
- **[DEPLOYMENT.md](DEPLOYMENT.md)** ← Deploy to production

### Project Overview
- **[README.md](README.md)** ← Main project overview
- **backend/README.md** ← Backend API docs
- **frontend/README.md** ← Flutter app docs

---

## 🔍 Key Files Location

| What | Where |
|------|-------|
| SQL Commands to paste in Neon | `database.sql` |
| Backend Python code | `backend/app/` |
| Frontend Flutter code | `frontend/lib/` |
| Configuration template | `backend/.env.example` |
| Your configuration | `backend/.env` (you create) |
| Flutter API client | `frontend/lib/services/api_service.dart` |

---

## ✅ After Setup, You Should Have:

1. ✅ PostgreSQL database on Neon with 5 tables
2. ✅ Backend running at http://localhost:8000
3. ✅ API docs visible at http://localhost:8000/docs
4. ✅ Flutter app running on device/emulator
5. ✅ Login screen visible in app

---

## 🐛 Something Broken?

1. Check [TROUBLESHOOTING_WINDOWS.md](TROUBLESHOOTING_WINDOWS.md)
2. Run `flutter doctor` to diagnose
3. Check if backend is running
4. Check if DATABASE_URL is correct

---

## 🚀 Next Steps (After It Works)

### Test Everything
- [ ] Try to register in app
- [ ] Visit http://localhost:8000/docs and test endpoints
- [ ] Check data appears in Neon database

### Add Your Own Data
- [ ] Add your farms/crops
- [ ] Add your animals
- [ ] Update market prices

### Deploy to Production
- Follow [DEPLOYMENT.md](DEPLOYMENT.md)
- Deploy backend to Koyeb (free!)
- Publish app to Google Play Store

---

## 💡 Pro Tips

1. **Keep backend running** in one terminal
2. **Run flutter in another** terminal
3. **For Android Emulator**, use URL: `http://10.0.2.2:8000/api`
4. **For web development**, use: `http://localhost:8000/api`
5. **Check logs** in backend terminal for request debugging

---

## 📞 Quick Reference

```bash
# Start backend
cd backend && python -m uvicorn app.main:app --reload

# Start flutter
cd frontend && flutter run

# Check if database is working
# Visit Neon dashboard and run verification query

# Test API
# Visit http://localhost:8000/docs
```

---

## 🎉 You're All Set!

Everything is ready to go. Just follow the 3 steps above and you're done!

**Questions?** Check the documentation files listed above.

**Want to deploy?** See [DEPLOYMENT.md](DEPLOYMENT.md) for Koyeb & production setup.

---

**Made with ❤️ for African Farmers 🌾**
