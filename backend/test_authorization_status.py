"""Test accept/reject authorization workflow directly with DB"""
import sys
sys.path.insert(0, '/mnt/c/Users/bmd-tech/Desktop/mbaymi/backend')

from app.database import SessionLocal
from app.models.authorization import Authorization, AuthorizationStatus
from app.models.user import User
from app.models.farm import Farm

db = SessionLocal()

print("=== Authorization Status Test ===\n")

# Get authorizations
print("1. Current authorizations:")
auths = db.query(Authorization).limit(5).all()
for auth in auths:
    farm = db.query(Farm).filter(Farm.id == auth.farm_id).first()
    print(f"   ID={auth.id}, Farm={farm.name if farm else 'Unknown'}, Status={auth.status}")

if not auths:
    print("   No authorizations found!")
else:
    # Test status update
    first_auth = auths[0]
    print(f"\n2. Updating authorization {first_auth.id} to ACCEPTED...")
    first_auth.status = AuthorizationStatus.ACCEPTED
    db.commit()
    db.refresh(first_auth)
    print(f"   ✓ Status updated to: {first_auth.status}")
    
    # Get accepted authorizations
    print(f"\n3. Querying for accepted authorizations by vet {first_auth.veterinarian_id}...")
    accepted = db.query(Authorization).filter(
        Authorization.veterinarian_id == first_auth.veterinarian_id,
        Authorization.status == AuthorizationStatus.ACCEPTED,
    ).all()
    print(f"   Found {len(accepted)} accepted authorizations")
    for auth in accepted:
        farm = db.query(Farm).filter(Farm.id == auth.farm_id).first()
        print(f"      ID={auth.id}, Farm={farm.name if farm else 'Unknown'}")
    
    # Reset status
    print(f"\n4. Resetting authorization {first_auth.id} to PENDING...")
    first_auth.status = AuthorizationStatus.PENDING
    db.commit()
    print(f"   ✓ Status reset to: {first_auth.status}")

# Test rejection
if len(auths) > 1:
    second_auth = auths[1]
    print(f"\n5. Updating authorization {second_auth.id} to REJECTED...")
    second_auth.status = AuthorizationStatus.REJECTED
    db.commit()
    db.refresh(second_auth)
    print(f"   ✓ Status updated to: {second_auth.status}")
    
    # Reset
    print(f"\n6. Resetting authorization {second_auth.id} to PENDING...")
    second_auth.status = AuthorizationStatus.PENDING
    db.commit()
    print(f"   ✓ Status reset to: {second_auth.status}")

print("\n=== Test Complete ===")
