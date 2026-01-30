import requests
import json
from app.services.token_service import create_jwt_token
from app.database import SessionLocal
from app.models.user import User

db = SessionLocal()
# Get vet user (ID 27)
vet = db.query(User).filter(User.id == 27).first()
if vet:
    # Create a token for this vet
    token = create_jwt_token(user_id=vet.id, email=vet.email)
    print(f"Token: {token}")
    
    # Make request
    headers = {"Authorization": f"Bearer {token}"}
    response = requests.get("http://127.0.0.1:8000/api/authorizations/pending", headers=headers)
    print(f"Status: {response.status_code}")
    data = response.json()
    print(json.dumps(data, indent=2, ensure_ascii=False))
else:
    print("Vet not found")

db.close()
