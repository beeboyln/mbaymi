from app.database import engine
from sqlalchemy import text

# Check livestock with id 6
with engine.connect() as conn:
    result = conn.execute(text("SELECT * FROM livestock WHERE id = 6"))
    row = result.fetchone()
    if row:
        print("Livestock ID 6:")
        for col, val in zip(result.keys(), row):
            print(f"  {col}: {val}")
    else:
        print("No livestock found with id 6")

print("\n--- All sheep (moutons) ---")
result = conn.execute(text("SELECT id, animal_type, breed, quantity, created_at FROM livestock WHERE LOWER(animal_type) LIKE '%mouton%' OR LOWER(breed) LIKE '%mouton%'"))
for row in result:
    print(row)
