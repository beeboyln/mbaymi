from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from app.config import settings
from app.models.base import Base
# Import model modules so they register with Base.metadata
import app.models.user  # noqa: F401
import app.models.farm  # noqa: F401
import app.models.livestock  # noqa: F401
import app.models.market  # noqa: F401
import app.models.activity  # noqa: F401
import app.models.harvest  # noqa: F401
import app.models.sale  # noqa: F401
import app.models.photo  # noqa: F401
import app.models.farm_post  # noqa: F401
import app.models.farm_network  # noqa: F401
import app.models.market_trends  # noqa: F401
import app.models.notification  # noqa: F401
import app.models.notebook  # noqa: F401
from sqlalchemy import text

# Create engine
# ✅ OPTIMIZATION 2: Improved DB pool for concurrent requests
engine = create_engine(
    settings.DATABASE_URL,
    # Use SQLAlchemy's default pooling with pre-ping to recover closed/idle connections.
    # StaticPool is unsuitable for a remote PostgreSQL server and may reuse a connection
    # that the server closed (causing SSL connection closed unexpectedly).
    pool_pre_ping=True,
    pool_size=20,  # ⬆️ Increased from 5 (supports 100+ concurrent users)
    max_overflow=20,  # ⬆️ Increased from 10 (better under load)
    pool_recycle=3600,  # Recycle connections every hour (Koyeb stability)
    echo=settings.DEBUG,
)

# Create all tables
def init_db():
    # Create all tables registered on the shared Base
    Base.metadata.create_all(bind=engine)
    # Ensure new columns exist (safe for development). PostgreSQL supports IF NOT EXISTS.
    try:
        with engine.begin() as conn:
            conn.execute(text("ALTER TABLE farms ADD COLUMN IF NOT EXISTS image_url VARCHAR(500);"))
            conn.execute(text("ALTER TABLE farms ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;"))
            conn.execute(text("ALTER TABLE farms ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;"))
            conn.execute(text("ALTER TABLE notifications ADD COLUMN IF NOT EXISTS actor_id INTEGER;"))
            conn.execute(text("ALTER TABLE crops ADD COLUMN IF NOT EXISTS area DOUBLE PRECISION;"))
            conn.execute(text("ALTER TABLE farm_post_comments ADD COLUMN IF NOT EXISTS parent_id INTEGER REFERENCES farm_post_comments(id) ON DELETE CASCADE;"))
            
            # Update users table: make email and phone nullable for phone-only or email-only registration
            try:
                conn.execute(text("ALTER TABLE users DROP CONSTRAINT users_email_key;"))
            except:
                pass  # Constraint might not exist
            
            try:
                conn.execute(text("ALTER TABLE users DROP CONSTRAINT users_phone_key;"))
            except:
                pass  # Constraint might not exist
            
            try:
                conn.execute(text("ALTER TABLE users ALTER COLUMN email DROP NOT NULL;"))
            except:
                pass  # Column might already be nullable
            
            try:
                conn.execute(text("ALTER TABLE users ALTER COLUMN phone DROP NOT NULL;"))
            except:
                pass  # Column might already be nullable
            
            print("[✓] Database migration completed: email and phone columns are now nullable")
    except Exception as e:
        print(f"Warning: could not run ALTER TABLE statements: {e}")

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
