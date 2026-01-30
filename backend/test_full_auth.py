#!/usr/bin/env python3
import sys
sys.path.insert(0, 'c:\\Users\\bmd-tech\\Desktop\\mbaymi\\backend')

from app.database import SessionLocal
from app.models.authorization import Authorization
from app.models.farm import Farm, Crop
from app.models.user import User
from app.models.livestock import Livestock
from app.models.photo import FarmPhoto
import json

db = SessionLocal()

# Simulate what the endpoint returns for vet_id=27
vet_id = 27

authorizations = db.query(Authorization).filter(
    Authorization.veterinarian_id == vet_id,
    Authorization.status == 'PENDING'
).all()

print(f"Found {len(authorizations)} pending authorizations for vet {vet_id}\n")

result = []
for auth in authorizations:
    # Get farm and farmer data
    farm = db.query(Farm).filter(Farm.id == auth.farm_id).first()
    farmer = db.query(User).filter(User.id == farm.user_id).first() if farm else None
    
    # Get farm photos and livestocks and crops
    photos = db.query(FarmPhoto).filter(FarmPhoto.farm_id == auth.farm_id).all() if farm else []
    livestocks = db.query(Livestock).filter(Livestock.user_id == farm.user_id).all() if farm else []
    crops = db.query(Crop).filter(Crop.farm_id == auth.farm_id).all() if farm else []
    
    auth_dict = {
        'id': auth.id,
        'farm_id': auth.farm_id,
        'veterinarian_id': auth.veterinarian_id,
        'status': str(auth.status),
        'authorization_reason': auth.authorization_reason,
        'created_at': auth.created_at.isoformat() if auth.created_at else None,
        'farm': {
            'id': farm.id if farm else None,
            'name': farm.name if farm else None,
            'location': farm.location if farm else None,
            'image_url': getattr(farm, 'image_url', None) if farm else None,
            'photos': [
                {'id': p.id, 'image_url': getattr(p, 'image_url', None)}
                for p in photos
            ],
            'livestocks': [
                {
                    'id': l.id,
                    'animal_type': getattr(l, 'animal_type', None),
                    'breed': getattr(l, 'breed', None),
                    'quantity': getattr(l, 'quantity', None),
                    'age_months': getattr(l, 'age_months', None),
                    'health_status': getattr(l, 'health_status', None),
                    'image_url': getattr(l, 'image_url', None),
                }
                for l in livestocks
            ],
            'crops': [
                {
                    'id': c.id,
                    'crop_name': getattr(c, 'crop_name', None),
                    'variety': getattr(c, 'variety', None),
                    'status': getattr(c, 'status', None),
                    'image_url': getattr(c, 'image_url', None),
                }
                for c in crops
            ],
        },
        'farmer': {
            'id': farmer.id if farmer else None,
            'name': farmer.name if farmer else None,
        }
    }
    result.append(auth_dict)

print("JSON Response that backend would return:")
print("=" * 80)
print(json.dumps(result, indent=2, ensure_ascii=False))
print("=" * 80)

db.close()
