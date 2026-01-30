from app.database import SessionLocal
from app.models.authorization import Authorization
from app.models.user import User

db = SessionLocal()

# Get all authorizations
auths = db.query(Authorization).all()
print(f"\n=== All Authorizations ===")
print(f"Total: {len(auths)}")
for auth in auths:
    vet = db.query(User).filter(User.id == auth.veterinarian_id).first()
    farmer = db.query(User).filter(User.id == auth.authorized_by).first()
    print(f"ID: {auth.id}")
    print(f"  Farm: {auth.farm_id}")
    print(f"  Veterinarian: {auth.veterinarian_id} ({vet.name if vet else 'NOT FOUND'})")
    print(f"  Created by (farmer): {auth.authorized_by} ({farmer.name if farmer else 'NOT FOUND'})")
    print(f"  Status: {auth.status}")
    print()

# List all users
users = db.query(User).all()
print(f"\n=== All Users ===")
for user in users:
    print(f"ID: {user.id}, Name: {user.name}, Email: {user.email}, Role: {user.role}")

db.close()
