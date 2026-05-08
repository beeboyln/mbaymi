#!/usr/bin/env python3
"""
Quick fix: Make farm_id nullable in project_notebooks table
Run this once to fix the schema mismatch
"""

from app.database import engine
import sys

try:
    with engine.connect() as connection:
        # Make farm_id nullable
        connection.execute("ALTER TABLE project_notebooks ALTER COLUMN farm_id DROP NOT NULL;")
        connection.commit()
        print("✅ Successfully made farm_id nullable in project_notebooks table")
except Exception as e:
    print(f"❌ Error: {e}")
    sys.exit(1)
