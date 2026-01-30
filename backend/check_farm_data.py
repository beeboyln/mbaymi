from app.database import SessionLocal
from app.models.farm import Farm, Crop
from app.models.livestock import Livestock
from app.models.photo import FarmPhoto

db = SessionLocal()

# Get farm 7
farm = db.query(Farm).filter(Farm.id == 7).first()
print(f"\n=== Farm 7 ===")
if farm:
    print(f"Name: {farm.name}")
    print(f"Location: {farm.location}")
    print(f"User ID: {farm.user_id}")
    print(f"Image URL: {farm.image_url}")
else:
    print("Farm not found!")

# Get photos for farm 7
photos = db.query(FarmPhoto).filter(FarmPhoto.farm_id == 7).all()
print(f"\n=== Photos for Farm 7: {len(photos)} ===")
for p in photos:
    print(f"  ID: {p.id}, URL: {p.image_url}")

# Get livestocks for farm 7
livestocks = db.query(Livestock).filter(Livestock.farm_id == 7).all()
print(f"\n=== Livestocks for Farm 7: {len(livestocks)} ===")
for l in livestocks:
    print(f"  ID: {l.id}, Type: {l.animal_type}, Breed: {l.breed}, Qty: {l.quantity}")

# Get crops for farm 7
crops = db.query(Crop).filter(Crop.farm_id == 7).all()
print(f"\n=== Crops for Farm 7: {len(crops)} ===")
for c in crops:
    print(f"  ID: {c.id}, Name: {c.crop_name}, Variety: {c.variety}")

db.close()
