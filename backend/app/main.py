from fastapi import FastAPI, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.staticfiles import StaticFiles
from fastapi.responses import JSONResponse
from app.config import settings
import os
import traceback

# Initialize app
app = FastAPI(title=settings.APP_NAME, version="0.1.0")

# CORS middleware - Production-ready config
# ✅ Handles Vercel, Koyeb, localhost, custom domains
app.add_middleware(
    CORSMiddleware,
    allow_origins=[
        "http://localhost:3000",
        "http://localhost:3001",
        "http://localhost:3002",
        "http://localhost:5000",
        "http://localhost:8000",
        "http://localhost:62436",  # Flutter Web
        "http://127.0.0.1:3000",
        "http://127.0.0.1:5000",
        "http://127.0.0.1:8000",
        "https://mbaymi.vercel.app",  # Main Vercel domain
        "https://mbaymi-staging.vercel.app",
        "https://mbaymi.com",
        "https://www.mbaymi.com",
        "https://cuddly-lil-bigboyllmnd-9965fc8f.koyeb.app",  # Self origin for internal calls
    ],
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE", "OPTIONS", "PATCH", "HEAD"],
    allow_headers=["Content-Type", "Authorization", "Accept", "Origin"],
    expose_headers=["Content-Type", "X-Total-Count"],
    max_age=86400,  # 24 hours
)

print("✅ CORS configured with regex (production-ready)")
print("   Allows: *.vercel.app, *.koyeb.app, localhost:*, mbaymi.com")

# Mount static files for uploads
uploads_dir = "uploads"
if os.path.exists(uploads_dir):
    app.mount("/uploads", StaticFiles(directory=uploads_dir), name="uploads")
    print("✅ Static files mounted at /uploads")

# Lazy import routes to avoid circular imports
def include_routes():
    from app.routes import auth, farmers, livestock, market, advice, news, activities, harvests, sales, crops
    app.include_router(auth.router)
    app.include_router(farmers.router)
    app.include_router(livestock.router)
    app.include_router(market.router)
    app.include_router(advice.router)
    app.include_router(news.router)
    app.include_router(activities.router)
    app.include_router(harvests.router)
    app.include_router(sales.router)
    app.include_router(crops.router)
    
    # 🌾 Agricultural features
    from app.routes import crop_problems, farm_network, user_profile
    app.include_router(crop_problems.router)
    app.include_router(farm_network.router)
    app.include_router(user_profile.router)

@app.on_event("startup")
def startup():
    include_routes()
    print("✅ Routes loaded")
    print("📚 API Docs at http://localhost:8000/docs")
    # Initialize DB (creates tables if missing)
    try:
        from app.database import init_db
        init_db()
        print("🗄️ Database initialized")
    except Exception as e:
        print(f"⚠️ Database init failed: {e}")

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

@app.get("/health")
def health_check():
    return {"status": "healthy", "message": "Mbaymi API is running"}

@app.post("/admin/migrate")
def run_migration(key: str = None):
    """
    🔧 Apply database migrations (admin only)
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

# ✅ Global exception handler to ensure CORS headers are always present
@app.exception_handler(Exception)
async def global_exception_handler(request: Request, exc: Exception):
    """Catch all exceptions and return with proper CORS headers"""
    print(f"❌ Unhandled exception: {exc}")
    traceback.print_exc()
    
    # Get origin from request
    origin = request.headers.get("origin", "https://mbaymi.vercel.app")
    
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
    
    response_origin = origin if origin in allowed_origins else "https://mbaymi.vercel.app"
    
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

