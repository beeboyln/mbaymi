from fastapi import FastAPI
from fastapi.middleware.cors import CORSMiddleware
from app.config import settings

# Initialize app
app = FastAPI(title=settings.APP_NAME, version="0.1.0")

# CORS middleware - Stable regex-based config (no intermittent failures)
# ✅ Handles Vercel, Koyeb, localhost, custom domains
app.add_middleware(
    CORSMiddleware,
    allow_origin_regex=r"https://.*\.vercel\.app|https://.*\.koyeb\.app|http://localhost:\d+|https://mbaymi\.com|https://.*\.mbaymi\.com",
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

print("✅ CORS configured with regex (production-ready)")
print("   Allows: *.vercel.app, *.koyeb.app, localhost:*, mbaymi.com")

# Lazy import routes to avoid circular imports
def include_routes():
    from app.routes import auth, farmers, livestock, market, advice, news, activities, harvests, sales
    app.include_router(auth.router)
    app.include_router(farmers.router)
    app.include_router(livestock.router)
    app.include_router(market.router)
    app.include_router(advice.router)
    app.include_router(news.router)
    app.include_router(activities.router)
    app.include_router(harvests.router)
    app.include_router(sales.router)

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

if __name__ == "__main__":
    import uvicorn
    uvicorn.run(app, host="0.0.0.0", port=8000)

