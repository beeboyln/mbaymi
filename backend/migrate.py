"""
Script to run database migrations
Run with: python migrate.py
"""
import os
import sys
from dotenv import load_dotenv
import psycopg2

load_dotenv()

def run_migration(migration_file: str):
    """Execute a SQL migration file"""
    db_url = os.getenv("DATABASE_URL")
    if not db_url:
        print("❌ DATABASE_URL not set in environment variables")
        sys.exit(1)
    
    try:
        conn = psycopg2.connect(db_url)
        cursor = conn.cursor()
        
        # Read and execute SQL file
        with open(migration_file, 'r') as f:
            sql_content = f.read()
        
        print(f"📝 Running migration: {migration_file}")
        cursor.execute(sql_content)
        conn.commit()
        print(f"✅ Migration executed successfully")
        
        cursor.close()
        conn.close()
    except Exception as e:
        print(f"❌ Migration failed: {e}")
        sys.exit(1)

if __name__ == "__main__":
    migration_file = sys.argv[1] if len(sys.argv) > 1 else "sql/add_crop_image_url.sql"
    run_migration(migration_file)
