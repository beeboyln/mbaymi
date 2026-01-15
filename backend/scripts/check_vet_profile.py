import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env'))

DATABASE_URL = os.getenv('DATABASE_URL')
if not DATABASE_URL:
    print('DATABASE_URL not set')
    raise SystemExit(1)

engine = create_engine(DATABASE_URL)

user_id = 22

with engine.connect() as conn:
    result = conn.execute(text("SELECT id, user_id, specialty, zone, verification_status FROM veterinarian_profiles WHERE user_id = :uid"), {'uid': user_id}).fetchone()
    if not result:
        print(f'No veterinarian profile found for user_id={user_id}')
    else:
        pid, uid, specialty, zone, vstatus = result
        print(f'Found veterinarian profile: id={pid}, user_id={uid}, specialty={specialty}, zone={zone}, verification_status={vstatus}')
