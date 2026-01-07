import os
from dotenv import load_dotenv

load_dotenv()

class Settings:
    # Database
    DATABASE_URL = os.getenv("DATABASE_URL", "postgresql://user:password@localhost:5432/mbaymi")
    
    # JWT
    SECRET_KEY = os.getenv("SECRET_KEY", "your-secret-key-change-in-production")
    ALGORITHM = "HS256"
    ACCESS_TOKEN_EXPIRE_MINUTES = 30
    
    # App
    APP_NAME = "Mbaymi API"
    DEBUG = os.getenv("DEBUG", "False") == "True"
    
    # CORS
    # Allow configuring allowed origins via environment variable ALLOWED_ORIGINS
    # as a comma-separated list. If not set, default to a conservative list.
    raw_origins = os.getenv("ALLOWED_ORIGINS")
    if raw_origins is None:
        # No ALLOWED_ORIGINS provided in env; default to localhosts.
        raw_origins = "http://localhost:8000,http://localhost:3000,http://localhost:8080,http://10.0.2.2:8080"
        used_env = False
    else:
        used_env = True

    # split and strip whitespace, ignore empty entries
    ALLOWED_ORIGINS = [o.strip() for o in raw_origins.split(",") if o.strip()]

    # If running in production (DEBUG=False) and the user didn't provide ALLOWED_ORIGINS,
    # make a sensible allowance for the Vercel frontend used in this project so web builds
    # hosted there won't be blocked by CORS. This is a convenience fallback — set
    # ALLOWED_ORIGINS explicitly in Koyeb to lock down origins.
    if not DEBUG and not used_env:
        vercel_origin = "https://mbaymi.vercel.app"
        if vercel_origin not in ALLOWED_ORIGINS:
            ALLOWED_ORIGINS.append(vercel_origin)

    # Support special wildcard token '*' to allow all origins when explicitly requested
    if any(o == "*" for o in ALLOWED_ORIGINS):
        ALLOWED_ORIGINS = ["*"]

settings = Settings()

