#!/usr/bin/env python3
import sys
sys.path.insert(0, 'c:\\Users\\bmd-tech\\Desktop\\mbaymi\\backend')

from app.database import SessionLocal
from app.models.authorization import Authorization

db = SessionLocal()

# Get the pending authorization
auth = db.query(Authorization).filter(
    Authorization.status == 'PENDING'
).first()

if auth:
    print(f"Authorization ID: {auth.id}")
    print(f"Farm ID: {auth.farm_id}")
    print(f"Veterinarian ID: {auth.veterinarian_id}")
    print(f"Status: {auth.status}")
    print(f"Reason: {auth.authorization_reason}")
    
    # Get farm
    from app.models.farm import Farm
    farm = db.query(Farm).filter(Farm.id == auth.farm_id).first()
    if farm:
        print(f"\nFarm found:")
        print(f"  ID: {farm.id}")
        print(f"  Name: {farm.name}")
        print(f"  Location: {farm.location}")
        print(f"  User ID: {farm.user_id}")
    else:
        print(f"Farm not found for ID {auth.farm_id}")
else:
    print("No pending authorizations found")

db.close()
