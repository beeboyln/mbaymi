"""
Database indexes for performance optimization.
Run this script once to create all necessary indexes.

Usage:
  python add_db_indexes.py
"""

from app.database import engine, SessionLocal
from app.models.sale import Sale
from app.models.farm import Farm
from app.models.livestock import Livestock
from app.models.farm_post import FarmImagePost
from sqlalchemy import Index, text

def add_indexes():
    """Add performance indexes to database"""
    
    with engine.connect() as connection:
        # Sales table indexes
        print("Creating indexes on sales table...")
        try:
            connection.execute(text(
                "CREATE INDEX IF NOT EXISTS idx_sales_user_id_created_at "
                "ON sale (user_id DESC, created_at DESC)"
            ))
            print("  ✓ idx_sales_user_id_created_at created")
        except Exception as e:
            print(f"  ⚠ idx_sales_user_id_created_at: {e}")
        
        try:
            connection.execute(text(
                "CREATE INDEX IF NOT EXISTS idx_sales_category "
                "ON sale (category)"
            ))
            print("  ✓ idx_sales_category created")
        except Exception as e:
            print(f"  ⚠ idx_sales_category: {e}")
        
        try:
            connection.execute(text(
                "CREATE INDEX IF NOT EXISTS idx_sales_created_at "
                "ON sale (created_at DESC)"
            ))
            print("  ✓ idx_sales_created_at created")
        except Exception as e:
            print(f"  ⚠ idx_sales_created_at: {e}")
        
        # Farm table indexes
        print("\nCreating indexes on farm table...")
        try:
            connection.execute(text(
                "CREATE INDEX IF NOT EXISTS idx_farm_user_id_created_at "
                "ON farm (user_id DESC, created_at DESC)"
            ))
            print("  ✓ idx_farm_user_id_created_at created")
        except Exception as e:
            print(f"  ⚠ idx_farm_user_id_created_at: {e}")
        
        try:
            connection.execute(text(
                "CREATE INDEX IF NOT EXISTS idx_farm_location "
                "ON farm (location)"
            ))
            print("  ✓ idx_farm_location created")
        except Exception as e:
            print(f"  ⚠ idx_farm_location: {e}")
        
        # Livestock table indexes
        print("\nCreating indexes on livestock table...")
        try:
            connection.execute(text(
                "CREATE INDEX IF NOT EXISTS idx_livestock_user_id_created_at "
                "ON livestock (user_id DESC, created_at DESC)"
            ))
            print("  ✓ idx_livestock_user_id_created_at created")
        except Exception as e:
            print(f"  ⚠ idx_livestock_user_id_created_at: {e}")
        
        try:
            connection.execute(text(
                "CREATE INDEX IF NOT EXISTS idx_livestock_animal_type "
                "ON livestock (animal_type)"
            ))
            print("  ✓ idx_livestock_animal_type created")
        except Exception as e:
            print(f"  ⚠ idx_livestock_animal_type: {e}")
        
        try:
            connection.execute(text(
                "CREATE INDEX IF NOT EXISTS idx_livestock_visibility "
                "ON livestock (visibility)"
            ))
            print("  ✓ idx_livestock_visibility created")
        except Exception as e:
            print(f"  ⚠ idx_livestock_visibility: {e}")
        
        # Farm Post (FarmImagePost) indexes
        print("\nCreating indexes on farm_image_post table...")
        try:
            connection.execute(text(
                "CREATE INDEX IF NOT EXISTS idx_farm_post_user_id_created_at "
                "ON farm_image_post (user_id DESC, created_at DESC)"
            ))
            print("  ✓ idx_farm_post_user_id_created_at created")
        except Exception as e:
            print(f"  ⚠ idx_farm_post_user_id_created_at: {e}")
        
        try:
            connection.execute(text(
                "CREATE INDEX IF NOT EXISTS idx_farm_post_farm_id "
                "ON farm_image_post (farm_id)"
            ))
            print("  ✓ idx_farm_post_farm_id created")
        except Exception as e:
            print(f"  ⚠ idx_farm_post_farm_id: {e}")
        
        connection.commit()
    
    print("\n✅ All indexes created successfully!")

if __name__ == "__main__":
    add_indexes()
