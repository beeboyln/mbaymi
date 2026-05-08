# CORS Configuration Analysis - Backend & Frontend

**Date:** March 12, 2026  
**Status:** Production Configuration Review  
**Issue:** CORS policy errors when Flutter web app tries to fetch from backend

---

## 📋 Summary

The backend uses **FastAPI** with **CORSMiddleware** configured to allow specific origins. The Flutter web app may be failing due to:
1. **Port mismatch** - Flask dev server typically runs on a different port than what's configured
2. **Missing localhost:5500-5900 range** - Common Flutter web development ports
3. **Browser origin ** - The exact origin the browser sends might not be whitelisted
4. **Credentials & preflight** - REQUEST HEADERS might not be properly configured

---

## 🔧 BACKEND CORS CONFIGURATION

### **Main Framework**
- **Framework:** FastAPI (NOT Flask, despite config.py reference)
- **CORS Library:** `fastapi.middleware.cors.CORSMiddleware`
- **Location:** [backend/app/main.py](backend/app/main.py#L18-L47)

### **Primary CORS Configuration (main.py)**

```python
# Lines 18-47 in main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:3001",
        "http://localhost:3002",
        "http://localhost:5000",
        "http://localhost:8000",
        "http://localhost:62436",  # Flutter Web (hardcoded)
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5000",
        "http://127.0.0.1:8000",
        "https://mbaymi.vercel.app",
        "https://mbaymi-staging.vercel.app",
        "https://mbaymi.com",
        "https://www.mbaymi.com",
        "https://cuddly-lil-bigboyllmnd-9965fc8f.koyeb.app",
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH", "HEAD"],
    allow_headers=["Content-Type", "Authorization", "Accept", "Origin"],
    expose_headers=["Content-Type", "X-Total-Count"],
    max_age=86400,  # 24 hours
)
```

### **Fallback Configuration (config.py)**

**Location:** [backend/app/config.py](backend/app/config.py#L19-L45)

```python
# Lines 19-45 in config.py
class Settings:
    # Allow configuring allowed origins via environment variable ALLOWED_ORIGINS
    # as a comma-separated list. If not set, default to a conservative list.
    raw_origins = os.getenv("ALLOWED_ORIGINS")
    if raw_origins is None:
        # Default fallback origins
        raw_origins = "http://localhost:8000,http://localhost:3000,http://localhost:8080,http://10.0.2.2:8080"
        used_env = False
    else:
        used_env = True

    ALLOWED_ORIGINS = [o.strip() for o in raw_origins.split(",") if o.strip()]

    # Production fallback - adds Vercel if not using env config
    if not DEBUG and not used_env:
        vercel_origin = "https://mbaymi.vercel.app"
        if vercel_origin not in ALLOWED_ORIGINS:
            ALLOWED_ORIGINS.append(vercel_origin)
```

### **Environment Variable Configuration**

**Location:** [backend/.env](backend/.env#L17-L18)

```
ALLOWED_ORIGINS=https://mbaymi.vercel.app,http://localhost:8000,http://localhost:3000,http://localhost:8080,http://10.0.2.2:8080
```

### **Global Exception Handler with CORS**

**Location:** [backend/app/main.py](backend/app/main.py#L216-L245)

The app includes a **global exception handler** that ensures CORS headers are present even during errors:

```python
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catch all exceptions and return with proper CORS headers"""
    allowed_origins = [
        "http://localhost:3000",
        "http://localhost:3001",
        "http://localhost:3002",
        "http://localhost:5000",
        "http://localhost:8000",
        "http://localhost:62436",
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5000",
        "http://127.0.0.1:8000",
        "https://mbaymi.vercel.app",
        "https://mbaymi-staging.vercel.app",
        "https://mbaymi.com",
        "https://www.mbaymi.com",
        "https://cuddly-lil-bigboyllmnd-9965fc8f.koyeb.app",
    ]
```

### **Media Route CORS (Explicit Headers)**

**Location:** [backend/app/routes/media.py](backend/app/routes/media.py#L26-L75)

This route serves videos/images with explicit CORS headers:

```python
@router.get('/video/farm-hero')
async def get_farm_hero_video():
    """
    Sert la vidéo de la ferme avec les bons headers CORS
    Bypass les problèmes de Tracking Prevention en servant depuis notre domaine
    """
    response = Response(video_data, media_type='video/mp4')
    
    # Explicit CORS headers
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    response.headers['Cache-Control'] = 'public, max-age=86400'

@router.options('/video/farm-hero')
async def video_options():
    """Handle CORS preflight requests"""
    response = Response()
    response.headers['Access-Control-Allow-Origin'] = '*'
    response.headers['Access-Control-Allow-Methods'] = 'GET, OPTIONS'
    response.headers['Access-Control-Allow-Headers'] = 'Content-Type'
    return response
```

---

## 🌐 FRONTEND CONFIGURATION

### **API Service Base URL**

**Location:** [frontend/lib/services/api_service.dart](frontend/lib/services/api_service.dart#L138)

```dart
static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 
    'https://cuddly-lil-bigboyllmnd-9965fc8f.koyeb.app/api';
```

### **.env Configuration (Frontend)**

**Location:** [frontend/.env](frontend/.env)

**Current Production Setting:**
```
API_BASE_URL=https://burning-yetty-bigboyme-428f3176.koyeb.app/api
```

**Local Development (commented):**
```
#API_BASE_URL=http://localhost:8000/api
```

⚠️ **Note:** Different Koyeb URLs in config.py vs frontend .env!

---

## 🚨 POTENTIAL CORS ISSUES

### **Issue 1: Missing Flutter Web Development Ports**
The hardcoded port `62436` is specific, but Flutter web typically runs on:
- `http://localhost:5500-5900` (range varies)
- `http://localhost:8080` or higher

**Currently Whitelisted LocalHost Ports:**
- ✅ 3000, 3001, 3002 (React/Next.js)
- ✅ 5000 (Flask)
- ✅ 8000 (FastAPI)
- ✅ 62436 (Flutter Web - hardcoded)
- ❌ Dynamic ports (5500-5900 range)

### **Issue 2: Inconsistent Koyeb URLs**
- **Backend config:** `https://cuddly-lil-bigboyllmnd-9965fc8f.koyeb.app`
- **Frontend .env:** `https://burning-yetty-bigboyme-428f3176.koyeb.app/api`

These are **different URLs** - frontend won't work against backend!

### **Issue 3: Missing 127.0.0.1 Ports**
Main middleware only allows `127.0.0.1:3000, :5000, :8000` but not the full range

### **Issue 4: Credentials & Preflight**
- ✅ `allow_credentials=True` is set
- ✅ `allow_methods` includes OPTIONS (for preflight)
- ✅ `allow_headers` includes `Authorization`
- ❌ `expose_headers` only exposes `Content-Type, X-Total-Count` (may need more)

---

## 📁 ALL CORS-RELATED FILES

| File | Purpose | CORS Details |
|------|---------|--------------|
| [backend/app/main.py](backend/app/main.py) | **Main FastAPI app** | Primary CORSMiddleware config + global exception handler |
| [backend/app/config.py](backend/app/config.py) | **Settings class** | Fallback CORS config from env variables |
| [backend/.env](backend/.env) | **Environment vars** | `ALLOWED_ORIGINS` comma-separated list |
| [backend/.env.example](backend/.env.example) | **Example config** | Template for CORS setup |
| [backend/app/routes/media.py](backend/app/routes/media.py) | **Media serving** | Explicit CORS headers for video/image routes |
| [frontend/.env](frontend/.env) | **React/Flutter .env** | `API_BASE_URL` for backend connection |
| [frontend/lib/services/api_service.dart](frontend/lib/services/api_service.dart) | **Flutter API service** | Reads API_BASE_URL env var |

---

## ✅ QUICK FIXES TO TRY

### **1. Update allowed_origins in main.py**

Add the current Flutter web port to the whitelist in `backend/app/main.py` (lines 23-39):

```python
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        # ... existing origins ...
        "http://localhost:5500",  # ADD THIS
        "http://localhost:5501",  # ADD THIS
        "http://localhost:5502",  # ADD THIS if using dynamic port
        "http://localhost:8080",  # ADD THIS
        # ... rest of origins
    ],
```

### **2. Switch to environment-based CORS (Recommended)**

Modify `backend/app/main.py` to use the `ALLOWED_ORIGINS` from config:

**Current (hardcoded):**
```python
app.add_middleware(CORSMiddleware, allow_origins=[...hardcoded list...])
```

**After change:**
```python
from app.config import settings

app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    # ... rest stays same
)
```

Then manage CORS via `.env` file (more flexible).

### **3. Fix Koyeb URL Mismatch**

- **Choose ONE Koyeb URL** across all configs
- Update [frontend/.env](frontend/.env) to match backend
- OR update [backend/app/main.py](backend/app/main.py#L39) to match frontend

### **4. Enable Flexible Port Range (Development)**

For development, use regex wildcard:

```python
allow_origins=[
    "http://localhost:*",  # Allows any port on localhost (development only!)
    # ... production origins
]
```

⚠️ **WARNING:** This is unsafe for production!

### **5. Check Browser Console**

When you get CORS error, the browser console should show:
```
Access to XMLHttpRequest at 'https://backend-url.com/api/...' 
from origin 'http://localhost:5500' has been blocked by CORS policy
```

The origin in the error message must be added to `allow_origins`.

---

## 🔍 DEBUGGING STEPS

1. **Check exact origin the browser sends:**
   - Open DevTools → Network tab → inspect request headers
   - Look for **Origin** header (e.g., `Origin: http://localhost:5500`)

2. **Test backend CORS directly:**
   ```bash
   curl -H "Origin: http://localhost:5500" \
        -H "Access-Control-Request-Method: GET" \
        -H "Access-Control-Request-Headers: Content-Type" \
        -X OPTIONS https://backend-url.com/api/auth/login -v
   ```

3. **Check backend logs:**
   ```
   [OK] CORS configured with regex (production-ready)
   ```
   If this line appears, CORS middleware is active

4. **Verify .env is loaded:**
   Check that `DEBUG=False` is not preventing config from loading

---

## 📊 CORS Health Checklist

- [ ] Flutter web development port added to `allowed_origins`
- [ ] `http://localhost:8080` added (common Flutter web port)
- [ ] Koyeb URLs consistent across all files
- [ ] `allow_methods` includes GET, POST, PUT, DELETE, OPTIONS, PATCH
- [ ] `allow_headers` includes `Authorization, Content-Type, Origin`
- [ ] `allow_credentials=True` is set
- [ ] Browser DevTools shows successful preflight (HTTP 200 for OPTIONS)
- [ ] No differences between main.py hardcoded list and config.py env list
