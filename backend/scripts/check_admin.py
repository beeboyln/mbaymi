import os
from sqlalchemy import create_engine, text
from dotenv import load_dotenv

load_dotenv(dotenv_path=os.path.join(os.path.dirname(__file__), '..', '.env'))

DATABASE_URL = os.getenv('DATABASE_URL')
engine = create_engine(DATABASE_URL)

with engine.connect() as conn:
    result = conn.execute(text("SELECT id, name, email, role, is_active FROM users WHERE email = 'admin@gmail.com'")).fetchone()
    if result:
        print(f'✅ Admin found:')
        print(f'   ID: {result[0]}')
        print(f'   Name: {result[1]}')
        print(f'   Email: {result[2]}')
        print(f'   Role: {result[3]}')
        print(f'   Is Active: {result[4]}')
    else:
        print('❌ Admin not found')
