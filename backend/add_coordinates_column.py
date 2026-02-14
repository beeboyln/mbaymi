#!/usr/bin/env python
"""Add missing coordinates column to crops table"""

from app.database import engine
from sqlalchemy import text

try:
    with engine.connect() as connection:
        # Add coordinates column to crops table if it doesn't exist
        migration_sql = """
        ALTER TABLE crops 
        ADD COLUMN IF NOT EXISTS coordinates VARCHAR(2000) NULL;
        """
        connection.execute(text(migration_sql))
        connection.commit()
        print("[OK] coordinates column added to crops table")
except Exception as e:
    print(f"[ERROR] {str(e)}")
