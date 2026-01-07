# 🗄️ Database Documentation - Mbaymi

## Neon PostgreSQL Setup

### 1. Créer un compte Neon

Visiter [neon.tech](https://neon.tech) et créer un compte gratuit.

### 2. Créer un projet

- Dashboard → New Project
- Choisir Postgres version 15 ou 16
- Copier la connection string

### 3. Variables d'environnement

`.env` du backend :
```
DATABASE_URL=postgresql://[user]:[password]@[host]/[dbname]
```

Exemple :
```
DATABASE_URL=postgresql://mbaymi_user:mypassword123@ep-tiny-wood-123456.us-east-1.neon.tech/mbaymi_db
```

## Schema Détaillé

### Users Table
```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  phone VARCHAR(20) UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL, -- farmer, livestock_breeder, buyer, seller, institution
  region VARCHAR(100),
  village VARCHAR(100),
  is_active BOOLEAN DEFAULT true,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_role ON users(role);
CREATE INDEX idx_users_region ON users(region);
```

**Roles**:
- `farmer` : Agriculteur
- `livestock_breeder` : Éleveur
- `buyer` : Acheteur
- `seller` : Vendeur
- `institution` : Ministère/Institution

### Farms Table
```sql
CREATE TABLE farms (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  location VARCHAR(200),
  size_hectares FLOAT,
  soil_type VARCHAR(50), -- sandy, loamy, clay, rocky
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_farms_user_id ON farms(user_id);
CREATE INDEX idx_farms_location ON farms(location);
```

**Soil Types**:
- `sandy` : Sableux
- `loamy` : Limoneux
- `clay` : Argileux
- `rocky` : Rocailleux

### Crops Table
```sql
CREATE TABLE crops (
  id SERIAL PRIMARY KEY,
  farm_id INTEGER NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
  crop_name VARCHAR(100) NOT NULL, -- maïs, riz, arachide, millet, tomate, etc.
  planted_date TIMESTAMP,
  expected_harvest_date TIMESTAMP,
  quantity_planted FLOAT, -- kg
  expected_yield FLOAT, -- kg
  actual_yield FLOAT,
  status VARCHAR(50) DEFAULT 'growing', -- growing, harvested, failed, abandoned
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_crops_farm_id ON crops(farm_id);
CREATE INDEX idx_crops_status ON crops(status);
CREATE INDEX idx_crops_crop_name ON crops(crop_name);
```

**Common Crops**:
- `maïs` : Maize/Corn
- `riz` : Rice
- `arachide` : Peanut
- `millet` : Millet
- `tomate` : Tomato
- `oignon` : Onion

### Livestock Table
```sql
CREATE TABLE livestock (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  animal_type VARCHAR(50) NOT NULL, -- cattle, goat, sheep, poultry, pig, horse
  breed VARCHAR(100),
  quantity INTEGER DEFAULT 1,
  age_months INTEGER,
  weight_kg FLOAT,
  health_status VARCHAR(50) DEFAULT 'healthy', -- healthy, sick, vaccinated, recovering
  last_vaccination_date TIMESTAMP,
  vaccination_type VARCHAR(100), -- foot and mouth, anthrax, etc.
  feeding_type VARCHAR(100), -- grass, grains, mixed
  location VARCHAR(200),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_livestock_user_id ON livestock(user_id);
CREATE INDEX idx_livestock_animal_type ON livestock(animal_type);
CREATE INDEX idx_livestock_health_status ON livestock(health_status);
```

**Animal Types**:
- `cattle` : Bovins
- `goat` : Chèvres
- `sheep` : Moutons
- `poultry` : Volaille
- `pig` : Porcs
- `horse` : Chevaux

### Market Prices Table
```sql
CREATE TABLE market_prices (
  id SERIAL PRIMARY KEY,
  product_name VARCHAR(100) NOT NULL,
  region VARCHAR(100) NOT NULL,
  price_per_kg FLOAT NOT NULL,
  currency VARCHAR(10) DEFAULT 'CFA', -- CFA, XOF
  unit VARCHAR(50) DEFAULT 'kg', -- kg, liter, bunch
  price_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  source VARCHAR(100), -- ministry, market_data, user_reported
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_market_prices_product ON market_prices(product_name);
CREATE INDEX idx_market_prices_region ON market_prices(region);
CREATE INDEX idx_market_prices_price_date ON market_prices(price_date);
CREATE UNIQUE INDEX idx_market_prices_unique 
  ON market_prices(product_name, region, DATE(price_date));
```

## Migration avec Alembic (Optionnel)

Pour gérer les migrations automatiquement :

```bash
# Initialiser Alembic
alembic init alembic

# Créer une migration
alembic revision --autogenerate -m "Initial migration"

# Appliquer
alembic upgrade head

# Downgrade
alembic downgrade -1
```

## Seed Data (Données initiales)

```python
# Script pour ajouter des données de test
from app.database import SessionLocal
from app.models.market import MarketPrice
from datetime import datetime

db = SessionLocal()

prices = [
    MarketPrice(product_name="maïs", region="Dakar", price_per_kg=250, currency="CFA"),
    MarketPrice(product_name="riz", region="Dakar", price_per_kg=400, currency="CFA"),
    MarketPrice(product_name="arachide", region="Kaolack", price_per_kg=350, currency="CFA"),
    MarketPrice(product_name="millet", region="Kolda", price_per_kg=300, currency="CFA"),
]

db.add_all(prices)
db.commit()
```

## Backups

Neon offre des backups automatiques. Pour un backup manuel :

```bash
# Export
pg_dump postgresql://user:password@host/db > backup.sql

# Import
psql postgresql://user:password@host/db < backup.sql
```

## Performance Tips

1. **Indexes** : Créer des indexes sur colonnes fréquemment interrogées
2. **Pagination** : Limiter les résultats avec `LIMIT` et `OFFSET`
3. **Caching** : Implémenter Redis pour les prix du marché
4. **Archiving** : Archiver les anciennes données de prix

## Future Enhancements

- [ ] pgvector pour RAG (quand intégration IA)
- [ ] Time-series data pour historique prix
- [ ] Geo-spatial queries pour localisation
- [ ] Full-text search pour produits
- [ ] Data warehouse pour analytics ministère
