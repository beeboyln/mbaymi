from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from starlette.middleware.gzip import GZipMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from app.config import settings
import os
import traceback
from datetime import datetime
import asyncio
import threading

# Default domain for fallback in error handlers
MAIN_DOMAIN = os.getenv("MAIN_DOMAIN", "https://mbaymi.vercel.app")

# Initialize app
app = FastAPI(title=settings.APP_NAME, version="0.1.0")

# Build timestamp captured at process start (UTC)
BUILD_TIME = datetime.utcnow().isoformat()

# CORS middleware - Production-ready config
# ✅ Uses environment variable ALLOWED_ORIGINS for flexible configuration
# ✅ Fallback to sensible defaults if not set
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.ALLOWED_ORIGINS,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH", "HEAD"],
    allow_headers=["Content-Type", "Authorization", "Accept", "Origin"],
    expose_headers=["Content-Type", "X-Total-Count"],
    max_age=86400,  # 24 hours
)

print("[OK] CORS middleware configured with these origins:")
for origin in settings.ALLOWED_ORIGINS:
    print(f"   ✓ {origin}")

# ✅ OPTIMIZATION 1: Add Gzip compression (80% smaller responses)
app.add_middleware(GZipMiddleware, minimum_size=1000)
print("[OK] GzipMiddleware enabled (reduces bandwidth ~80%)")

# Mount static files for uploads
uploads_dir = "uploads"
if os.path.exists(uploads_dir):
    app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")
    print("[OK] Static files mounted at /uploads")

# Lazy import routes to avoid circular imports
def include_routes():
    from app.routes import auth, farmers, livestock, market, advice, news, activities, harvests, sales, crops, pasture, animal_photos
    app.include_router(auth.router)
    # Register farmers routes with /api/farms prefix for frontend consumption
    app.include_router(farmers.router, prefix="/api/farms")
    app.include_router(livestock.router)
    app.include_router(market.router)
    app.include_router(advice.router)
    app.include_router(news.router)
    app.include_router(activities.router)
    app.include_router(harvests.router)
    app.include_router(sales.router)
    app.include_router(crops.router)
    app.include_router(pasture.router)
    app.include_router(animal_photos.router)
    
    # Agricultural features
    from app.routes import crop_problems, farm_network, user_profile, social, farm_posts, market_prices, notifications, veterinarian, authorization, service_request, media, search, admin
    # New agriculture API routes
    from app.routes import api_crops, api_inputs, api_finance, api_reminders, animals
    app.include_router(crop_problems.router)
    app.include_router(farm_network.router)
    # Also expose farm_network routes under legacy `/api` prefix to support older frontends
    app.include_router(farm_network.router, prefix="/api")
    app.include_router(user_profile.router)
    app.include_router(social.router)  # Social interactions
    app.include_router(farm_posts.router)  # Farm image posts with likes/comments/shares
    app.include_router(market_prices.router)  # Market prices & trends
    app.include_router(search.router)  # Search users, veterinarians, farms
    app.include_router(notifications.router)  # Notifications
    # Also expose legacy `/api` prefixed routes to support frontends using `/api/...`
    app.include_router(farm_posts.router, prefix="/api")
    app.include_router(market_prices.router, prefix="/api")
    app.include_router(media.router)  # Media serving (videos, images with CORS)
    
    # Veterinarian/Expert System
    app.include_router(veterinarian.router)  # Veterinarian profiles and management
    app.include_router(authorization.router)  # Farm data access authorization
    app.include_router(service_request.router)  # Service requests and consultations
    app.include_router(admin.router)  # Admin panel (verification, authorizations)
    # Agricultural management APIs (auth required)
    app.include_router(api_crops.router)
    app.include_router(api_inputs.router)
    app.include_router(api_finance.router)
    app.include_router(api_reminders.router)
    app.include_router(animals.router)  # Individual animal management system
    
    print("[DEBUG] farm_posts.router routes:")
    for route in app.routes:
        if "farm-posts" in str(route.path):
            print(f"  {route.methods} {route.path}")
    
    print("[DEBUG] api_inputs.router routes:")
    for route in app.routes:
        if "input" in str(route.path).lower():
            print(f"  {route.methods} {route.path}")

# Health check endpoint (wakes up Render free tier)
@app.get("/health")
@app.get("/api/health")
def health():
    """Health check endpoint - used by UptimeRobot/cron-job to keep server awake"""
    return {"status": "ok", "service": "mbaymi-api"}

@app.on_event("startup")
def startup():
    include_routes()
    print("[OK] Routes loaded")
    print("[INFO] API Docs at http://localhost:8000/docs")
    # Initialize DB (creates tables if missing)
    try:
        from app.database import init_db
        init_db()
        print("[OK] Database initialized")
    except Exception as e:
        print(f"[WARN] Database init failed: {e}")
    
    # Start background task to check reminders every 5 minutes
    def check_reminders_periodically():
        import time
        from app.workers.reminder_worker import check_due_reminders
        while True:
            try:
                check_due_reminders()
            except Exception as e:
                print(f"[WARN] Reminder worker error: {e}")
            time.sleep(300)  # Check every 5 minutes
    
    reminder_thread = threading.Thread(target=check_reminders_periodically, daemon=True)
    reminder_thread.start()
    print("[OK] Reminder worker started (checks every 5 minutes)")


@app.options("/{full_path:path}")
def options_handler():
    """Handle preflight OPTIONS requests"""
    return {"message": "OK"}

@app.get("/")
def read_root():
    return {
        "name": "Mbaymi API",
        "version": "0.1.0",
        "description": "Agricultural platform for farmers and livestock breeders",
        "status": "running",
        "docs": "http://localhost:8000/docs"
    }


@app.get("/version")
def version():
    """Return application name, version, build timestamp and optional git commit."""
    return {
        "name": settings.APP_NAME,
        "version": app.version,
        "build_time": BUILD_TIME,
        "git_commit": os.getenv("GIT_COMMIT", None),
    }

@app.get("/health")
def health_check():
    return {"status": "healthy", "message": "Mbaymi API is running"}

@app.post("/admin/migrate")
def run_migration(key: str = None):
    """
    Apply database migrations (admin only)
    Requires: key=migration_key from environment
    """
    from app.config import settings
    from app.database import get_db
    from sqlalchemy import text
    
    # Check admin key
    admin_key = os.getenv("MIGRATION_KEY", "dev-key-change-in-prod")
    if key != admin_key:
        return {"status": "error", "message": "Unauthorized"}
    
    try:
        # Execute migration for crops image_url
        migration_sql = """
        ALTER TABLE crops ADD COLUMN IF NOT EXISTS image_url VARCHAR(500);
        """
        
        # Get a db session
        db = next(get_db())
        db.execute(text(migration_sql))
        db.commit()
        
        return {
            "status": "success",
            "message": "Migration applied: Added image_url column to crops table"
        }
    except Exception as e:
        return {
            "status": "error",
            "message": f"Migration failed: {str(e)}"
        }

# Global exception handler to ensure CORS headers are always present
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catch all exceptions and return with proper CORS headers"""
    print(f"[ERROR] Unhandled exception: {exc}")
    traceback.print_exc()
    
    # Get origin from request
    origin = request.headers.get("origin", MAIN_DOMAIN)
    
    # Check if origin is allowed
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
    
    response_origin = origin if origin in allowed_origins else MAIN_DOMAIN
    
    return JSONResponse(
        status_code=500,
        content={
            "detail": str(exc),
            "type": "InternalServerError"
        },
        headers={
            "Access-Control-Allow-Origin": response_origin,
            "Access-Control-Allow-Credentials": "true",
            "Access-Control-Allow-Methods": "GET, POST, PUT, DELETE, OPTIONS, PATCH",
            "Access-Control-Allow-Headers": "Content-Type, Authorization, Accept, Origin",
        }
    )

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

