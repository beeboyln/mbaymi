"""
Migration: Add animal_id column to livestock table and create linked Animal records
Run this with: python migrate_add_animal_id_to_livestock.py
"""
from sqlalchemy import text, create_engine
from sqlalchemy.orm import Session
from app.config import settings
from app.database import get_db, engine
from app.models.livestock import Livestock
from app.models.animal import Animal, AnimalSpecies, AnimalGender, HealthStatus, ReproductiveStatus
from datetime import datetime, date

def run_migration():
    """Add animal_id column to livestock table and link existing livestock to Animal records"""
    
    with Session(engine) as db:
        try:
            # 1. Check if column already exists
            result = db.execute(text("""
                SELECT column_name FROM information_schema.columns 
                WHERE table_name='livestock' AND column_name='animal_id'
            """))
            
            column_exists = result.fetchone() is not None
            
            if not column_exists:
                print("Adding 'animal_id' column to livestock table...")
                db.execute(text("""
                    ALTER TABLE livestock 
                    ADD COLUMN animal_id INTEGER,
                    ADD CONSTRAINT fk_livestock_animal 
                    FOREIGN KEY (animal_id) REFERENCES animals(id) ON DELETE SET NULL
                """))
                db.commit()
                print("✅ Column 'animal_id' added successfully")
            else:
                print("✅ Column 'animal_id' already exists")
            
            # 2. Now create Animal records for Livestock that don't have them yet
            print("\nLinking livestock to Animal records...")
            
            livestock_records = db.query(Livestock).filter(Livestock.animal_id == None).all()
            print(f"Found {len(livestock_records)} livestock without Animal links")
            
            # Map livestock animal types to Animal species
            species_map = {
                'cattle': AnimalSpecies.CATTLE,
                'cattle_beef': AnimalSpecies.CATTLE,
                'cattle_dairy': AnimalSpecies.CATTLE,
                'goat': AnimalSpecies.GOAT,
                'sheep': AnimalSpecies.SHEEP,
                'pig': AnimalSpecies.PIG,
                'poultry': AnimalSpecies.POULTRY,
                'chicken': AnimalSpecies.POULTRY,
                'horse': AnimalSpecies.HORSE,
                'donkey': AnimalSpecies.DONKEY,
            }
            
            created_count = 0
            for livestock in livestock_records:
                try:
                    # Determine species from animal_type
                    species = species_map.get(livestock.animal_type.lower(), AnimalSpecies.CATTLE)
                    
                    # Create Animal record
                    animal = Animal(
                        user_id=livestock.user_id,
                        farm_id=None,  # Will be linked later if needed
                        name=f"{livestock.breed or livestock.animal_type} #{livestock.id}",
                        tag_id=None,
                        species=species,
                        breed=livestock.breed,
                        gender=AnimalGender.MALE,  # Default to male since livestock doesn't track gender
                        date_of_birth=datetime.utcnow().date() if not livestock.age_months else (datetime.utcnow().date().replace(year=datetime.utcnow().year - (livestock.age_months // 12))),
                        weight_kg=livestock.weight_kg,
                        health_status=HealthStatus.HEALTHY,
                        health_notes=livestock.notes,
                        last_checkup_date=livestock.last_vaccination_date,
                        reproductive_status=ReproductiveStatus.NOT_BREEDING,
                        location=livestock.location,
                        photo_url=livestock.image_url,
                        created_at=livestock.created_at,
                        updated_at=livestock.updated_at,
                    )
                    
                    db.add(animal)
                    db.flush()  # Get the ID
                    
                    # Link the livestock to this animal
                    livestock.animal_id = animal.id
                    db.add(livestock)
                    
                    created_count += 1
                    print(f"  ✅ Created Animal #{animal.id} for Livestock #{livestock.id}")
                    
                except Exception as e:
                    print(f"  ❌ Error linking livestock {livestock.id}: {str(e)}")
                    db.rollback()
                    continue
            
            db.commit()
            print(f"\n✅ Successfully created and linked {created_count} Animal records")
            print("✅ Migration complete! Livestock are now linked to detailed Animal records")
            
        except Exception as e:
            print(f"❌ Migration failed: {str(e)}")
            import traceback
            traceback.print_exc()
            db.rollback()
            raise

if __name__ == "__main__":
    print("Running migration: Link livestock to Animal records...")
    run_migration()
