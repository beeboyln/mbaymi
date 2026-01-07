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
    raw_origins = os.getenv("ALLOWED_ORIGINS", "http://localhost:8000,http://localhost:3000,http://localhost:8080,http://10.0.2.2:8080")
    # split and strip whitespace, ignore empty entries
    ALLOWED_ORIGINS = [o.strip() for o in raw_origins.split(",") if o.strip()]

settings = Settings()

