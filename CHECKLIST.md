# ✅ Mbaymi - Complete Setup Checklist

## 🚀 Phase 1: Database Setup

- [ ] Go to https://neon.tech
- [ ] Create free account
- [ ] Create new PostgreSQL project
- [ ] Copy CONNECTION STRING (DATABASE_URL)
- [ ] Open SQL Editor on Neon Dashboard
- [ ] Copy entire `database.sql` content
- [ ] Paste in SQL Editor
- [ ] Click "Run"
- [ ] ✅ Verify database created by running verification query
- [ ] Save CONNECTION_STRING for later

**Example CONNECTION_STRING:**
```
postgresql://user:password@ep-xxxx.us-east-1.neon.tech/mbaymi_db
```

---

## 🔧 Phase 2: Backend Setup

### Windows Users

- [ ] Open PowerShell/Command Prompt
- [ ] Navigate to `mbaymi/backend` folder
- [ ] Check Python installed: `python --version`
- [ ] Create venv: `python -m venv venv`
- [ ] Activate venv: `venv\Scripts\activate`
- [ ] Install deps: `pip install -r requirements.txt`
- [ ] Copy `.env.example` to `.env`: `copy .env.example .env`
- [ ] Edit `.env` - Add your DATABASE_URL from Neon
- [ ] Edit `.env` - Add SECRET_KEY (random string)
- [ ] Test with: `python -m uvicorn app.main:app --reload`
- [ ] ✅ Visit http://localhost:8000/docs to see API docs

**Expected output:**
```
INFO:     Started server process
INFO:     Application startup complete
INFO:     Uvicorn running on http://0.0.0.0:8000
```

### Mac/Linux Users

- [ ] Open Terminal
- [ ] Navigate to `mbaymi/backend`
- [ ] Check Python: `python3 --version`
- [ ] Create venv: `python3 -m venv venv`
- [ ] Activate venv: `source venv/bin/activate`
- [ ] Install deps: `pip install -r requirements.txt`
- [ ] Copy .env: `cp .env.example .env`
- [ ] Edit `.env` with DATABASE_URL
- [ ] Edit `.env` with SECRET_KEY
- [ ] Test: `uvicorn app.main:app --reload`
- [ ] ✅ Visit http://localhost:8000/docs

---

## 📱 Phase 3: Frontend Setup

### All Platforms

- [ ] Open new Terminal
- [ ] Navigate to `mbaymi/frontend`
- [ ] Check Flutter: `flutter --version`
- [ ] Get dependencies: `flutter pub get`
- [ ] **IMPORTANT:** Edit `lib/services/api_service.dart`
  - [ ] Find: `static const String baseUrl = ...`
  - [ ] Change to: `http://localhost:8000/api` (for local dev)
  - [ ] Or: `http://10.0.2.2:8000/api` (for Android Emulator)
- [ ] List devices: `flutter devices`
- [ ] Run app:
  - [ ] On Android Emulator: `flutter run`
  - [ ] On Chrome: `flutter run -d chrome`
  - [ ] On iOS Simulator: `flutter run`
- [ ] ✅ Should see Mbaymi login screen

**Check if API connection works:**
- [ ] Try to register new user
- [ ] Check backend console for request logs
- [ ] If successful, user was created in database

---

## 🧪 Phase 4: Testing Integration

### Test 1: Database

- [ ] SSH into Neon or use SQL Editor
- [ ] Run: `SELECT COUNT(*) FROM users;`
- [ ] ✅ Should return: `5` (4 sample + 1 registered)

### Test 2: Backend API

- [ ] Go to http://localhost:8000/docs
- [ ] Try endpoint: **POST /api/auth/register**
  - [ ] Fill form with test user data
  - [ ] Click "Try it out"
  - [ ] ✅ Should return user data with id

### Test 3: Frontend Connection

- [ ] Open Flutter app
- [ ] Try to register with different email
- [ ] ✅ Should show success message

### Test 4: Get List of Farms

- [ ] Go to http://localhost:8000/docs
- [ ] Try endpoint: **GET /api/farms/user/{user_id}**
  - [ ] Use user_id = 1 (Moussa Sow)
  - [ ] ✅ Should return 2 farms (Ferme Sow, Champ Nord)

### Test 5: Get Advice

- [ ] Go to http://localhost:8000/docs
- [ ] Try endpoint: **POST /api/advice/**
  - [ ] type: `crop`
  - [ ] topic: `maïs`
  - [ ] ✅ Should return advice with tips and warnings

---

## 📊 Phase 5: Verify Data in Database

Run these in Neon SQL Editor:

### Check Users
```sql
SELECT id, name, email, role FROM users;
```
Expected: 4-5 rows

### Check Farms
```sql
SELECT f.id, f.name, u.name as owner FROM farms f 
JOIN users u ON f.user_id = u.id;
```
Expected: 3 rows

### Check Crops
```sql
SELECT c.crop_name, c.status, f.name as farm 
FROM crops c JOIN farms f ON c.farm_id = f.id;
```
Expected: 4 rows

### Check Livestock
```sql
SELECT animal_type, quantity, u.name as owner 
FROM livestock l JOIN users u ON l.user_id = u.id;
```
Expected: 4 rows

### Check Market Prices
```sql
SELECT product_name, region, price_per_kg FROM market_prices;
```
Expected: 7 rows

---

## 🐛 If Something Fails

### Backend won't start?
- [ ] Check Python is installed
- [ ] Check venv is activated
- [ ] Check requirements installed: `pip list`
- [ ] Check .env exists
- [ ] Check DATABASE_URL is correct
- [ ] See [TROUBLESHOOTING_WINDOWS.md](TROUBLESHOOTING_WINDOWS.md)

### Flutter won't run?
- [ ] Check Flutter installed: `flutter doctor`
- [ ] Check device/emulator available
- [ ] Check API baseUrl is correct
- [ ] Check backend is running
- [ ] Run: `flutter clean && flutter pub get`

### Database errors?
- [ ] Check CONNECTION_STRING is correct
- [ ] Check Neon project exists
- [ ] Check tables created: `\dt` (in psql)
- [ ] See [TROUBLESHOOTING_WINDOWS.md](TROUBLESHOOTING_WINDOWS.md)

### Still stuck?
- [ ] Check [SETUP_WINDOWS.md](SETUP_WINDOWS.md)
- [ ] Check [DATABASE.md](DATABASE.md)
- [ ] Check backend README.md
- [ ] Check frontend README.md

---

## 🎯 Success Criteria

You're ready when:

- ✅ Backend running: http://localhost:8000/docs works
- ✅ Database connected: Tables exist with sample data
- ✅ Flutter app runs: Login screen appears
- ✅ Integration works: Can register and see data in database
- ✅ Advice API works: Returns agricultural tips
- ✅ Market prices visible: Can fetch prices by region

---

## 📝 File Locations

| File | Purpose | Location |
|------|---------|----------|
| `database.sql` | SQL for database creation | `mbaymi/` |
| `requirements.txt` | Python dependencies | `mbaymi/backend/` |
| `.env` | Backend configuration | `mbaymi/backend/` |
| `pubspec.yaml` | Flutter dependencies | `mbaymi/frontend/` |
| `api_service.dart` | API client | `mbaymi/frontend/lib/services/` |

---

## 🚀 Next Steps (After Checklist)

1. **Add more features:**
   - Chat between users
   - Photo uploads
   - Push notifications

2. **Test with real data:**
   - Add your own farms/livestock
   - Update market prices
   - Test advice for your crops

3. **Deploy to production:**
   - Use [DEPLOYMENT.md](DEPLOYMENT.md)
   - Deploy backend to Koyeb
   - Publish app to Google Play Store

---

## 🎉 Congratulations!

You have a fully functional agricultural platform!

**Questions?** Check the documentation files or run `flutter doctor` for diagnostics.

**Ready to scale?** See [DEPLOYMENT.md](DEPLOYMENT.md) for production setup.
