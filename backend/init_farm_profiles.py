"""
Script to initialize farm_profiles table in the database.
Run with: python init_farm_profiles.py
"""
import os
import sys
from dotenv import load_dotenv
from sqlalchemy import create_engine, text
from sqlalchemy.orm import sessionmaker

load_dotenv()

def init_farm_profiles():
    """Initialize the farm_profiles table"""
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        print("❌ DATABASE_URL not set in environment variables")
        sys.exit(1)
    
    try:
        # Create engine and session
        engine = create_engine(db_url, pool_pre_ping=True)
        SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)
        db = SessionLocal()
        
        # Import models to register them with SQLAlchemy
        from app.models.farm_network import FarmProfile
        from app.models.base import Base
        
        print("📝 Initializing farm_profiles table...")
        
        # Create all tables (safe - only creates if not exists)
        Base.metadata.create_all(bind=engine)
        
        # Verify the table was created
        result = db.execute(text("""
            SELECT EXISTS (
                SELECT 1 FROM information_schema.tables 
                WHERE table_name = 'farm_profiles'
            );
        """))
        
        table_exists = result.scalar()
        
        if table_exists:
            print("✅ farm_profiles table created successfully!")
            
            # Count existing profiles
            count_result = db.execute(text("SELECT COUNT(*) FROM farm_profiles;"))
            count = count_result.scalar()
            print(f"   Current profiles: {count}")
        else:
            print("❌ Failed to create farm_profiles table")
            sys.exit(1)
        
        db.close()
        
    except Exception as e:
        print(f"❌ Error: {str(e)}")
        sys.exit(1)

if __name__ == "__main__":
    init_farm_profiles()
