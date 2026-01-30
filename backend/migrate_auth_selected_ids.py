#!/usr/bin/env python3
"""
Migration: Add selected_livestock_ids and selected_crop_ids to authorizations table
"""
import sys
sys.path.insert(0, 'c:\\Users\\bmd-tech\\Desktop\\mbaymi\\backend')

from sqlalchemy import text
from app.database import engine

if __name__ == '__main__':
    print("Applying migration: Add selected IDs columns to authorizations...")
    
    try:
        with engine.connect() as conn:
            # Check if columns already exist
            result = conn.execute(text('''
                SELECT column_name FROM information_schema.columns 
                WHERE table_name='authorizations' AND column_name='selected_livestock_ids'
            '''))
            
            if result.fetchone() is None:
                print("Adding columns...")
                conn.execute(text('''
                    ALTER TABLE authorizations 
                    ADD COLUMN selected_livestock_ids VARCHAR(500) NULL
                '''))
                conn.execute(text('''
                    ALTER TABLE authorizations 
                    ADD COLUMN selected_crop_ids VARCHAR(500) NULL
                '''))
                conn.commit()
                print("✓ Columns added successfully!")
            else:
                print("✓ Columns already exist!")
    except Exception as e:
        print(f"Error: {e}")
        print("Trying alternative approach...")
        try:
            with engine.connect() as conn:
                conn.execute(text('''
                    ALTER TABLE authorizations 
                    ADD COLUMN selected_livestock_ids VARCHAR(500)
                '''))
                conn.commit()
        except:
            pass
        try:
            with engine.connect() as conn:
                conn.execute(text('''
                    ALTER TABLE authorizations 
                    ADD COLUMN selected_crop_ids VARCHAR(500)
                '''))
                conn.commit()
        except:
            pass
        print("Migration completed with partial results")
