from app.database import SessionLocal
from app.models.authorization import Authorization

db = SessionLocal()
auths = db.query(Authorization).all()
print(f"Total authorizations: {len(auths)}")
for auth in auths:
    print(f"ID: {auth.id}, Farm: {auth.farm_id}, Vet: {auth.veterinarian_id}, Status: {auth.status}")

# Delete all
for auth in auths:
    db.delete(auth)
db.commit()
print("All authorizations deleted")
db.close()
