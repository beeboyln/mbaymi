from sqlalchemy import create_engine
from sqlalchemy.orm import sessionmaker
from sqlalchemy.pool import StaticPool
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
from sqlalchemy import text

# Create engine
engine = create_engine(
    settings.DATABASE_URL,
    poolclass=StaticPool,
    echo=settings.DEBUG
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
            # You can add more ALTER statements here for future model changes
    except Exception as e:
        print(f"Warning: could not run ALTER TABLE statements: {e}")

SessionLocal = sessionmaker(autocommit=False, autoflush=False, bind=engine)

def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()
