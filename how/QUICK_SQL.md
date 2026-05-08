# 🚀 Quick Copy-Paste SQL Commands

Voici les commandes SQL à copier-coller directement dans Neon SQL Editor.

## ✂️ Copy-Paste Complètement

Copie le contenu du fichier **`database.sql`** (tout le fichier) et colle-le dans:

1. Neon Dashboard → SQL Editor
2. Click "Run"
3. Done! ✅

---

## Ou exécute les commandes individuellement ci-dessous:

### 1️⃣ CREATE USERS TABLE

```sql
CREATE TABLE users (
  id SERIAL PRIMARY KEY,
  name VARCHAR(100) NOT NULL,
  email VARCHAR(100) UNIQUE NOT NULL,
  phone VARCHAR(20) UNIQUE,
  password_hash VARCHAR(255) NOT NULL,
  role VARCHAR(50) NOT NULL,
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

---

### 2️⃣ CREATE FARMS TABLE

```sql
CREATE TABLE farms (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  name VARCHAR(100) NOT NULL,
  location VARCHAR(200),
  size_hectares FLOAT,
  soil_type VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_farms_user_id ON farms(user_id);
CREATE INDEX idx_farms_location ON farms(location);
```

---

### 3️⃣ CREATE CROPS TABLE

```sql
CREATE TABLE crops (
  id SERIAL PRIMARY KEY,
  farm_id INTEGER NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
  crop_name VARCHAR(100) NOT NULL,
  planted_date TIMESTAMP,
  expected_harvest_date TIMESTAMP,
  quantity_planted FLOAT,
  expected_yield FLOAT,
  actual_yield FLOAT,
  status VARCHAR(50) DEFAULT 'growing',
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_crops_farm_id ON crops(farm_id);
CREATE INDEX idx_crops_status ON crops(status);
CREATE INDEX idx_crops_crop_name ON crops(crop_name);
```

---

### 4️⃣ CREATE LIVESTOCK TABLE

```sql
CREATE TABLE livestock (
  id SERIAL PRIMARY KEY,
  user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  animal_type VARCHAR(50) NOT NULL,
  breed VARCHAR(100),
  quantity INTEGER DEFAULT 1,
  age_months INTEGER,
  weight_kg FLOAT,
  health_status VARCHAR(50) DEFAULT 'healthy',
  last_vaccination_date TIMESTAMP,
  vaccination_type VARCHAR(100),
  feeding_type VARCHAR(100),
  location VARCHAR(200),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_livestock_user_id ON livestock(user_id);
CREATE INDEX idx_livestock_animal_type ON livestock(animal_type);
CREATE INDEX idx_livestock_health_status ON livestock(health_status);
```

---

### 5️⃣ CREATE MARKET_PRICES TABLE

```sql
CREATE TABLE market_prices (
  id SERIAL PRIMARY KEY,
  product_name VARCHAR(100) NOT NULL,
  region VARCHAR(100) NOT NULL,
  price_per_kg FLOAT NOT NULL,
  currency VARCHAR(10) DEFAULT 'CFA',
  unit VARCHAR(50) DEFAULT 'kg',
  price_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  source VARCHAR(100),
  notes TEXT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

CREATE INDEX idx_market_prices_product ON market_prices(product_name);
CREATE INDEX idx_market_prices_region ON market_prices(region);
CREATE INDEX idx_market_prices_price_date ON market_prices(price_date);
CREATE UNIQUE INDEX idx_market_prices_unique 
  ON market_prices(product_name, region, DATE(price_date));
```

---

### 6️⃣ INSERT SAMPLE DATA (OPTIONAL)

```sql
-- Sample users
INSERT INTO users (name, email, phone, password_hash, role, region, village)
VALUES 
  ('Moussa Sow', 'moussa@example.com', '221701234567', '$2b$12$abcdefghijk', 'farmer', 'Dakar', 'Parcelles Assainies'),
  ('Aïssatou Diallo', 'aissatou@example.com', '221702345678', '$2b$12$lmnopqrstuv', 'livestock_breeder', 'Kaolack', 'Kaolack-ville'),
  ('Ibrahima Ba', 'ibrahima@example.com', '221703456789', '$2b$12$wxyzabcdefg', 'buyer', 'Tambacounda', 'Tambacounda-centre'),
  ('Fatou Ndiaye', 'fatou@example.com', '221704567890', '$2b$12$hijklmnopqr', 'farmer', 'Kolda', 'Kolda-ville');

-- Sample farms
INSERT INTO farms (user_id, name, location, size_hectares, soil_type)
VALUES 
  (1, 'Ferme Sow', 'Parcelles Assainies, Dakar', 2.5, 'sandy'),
  (1, 'Champ Nord', 'Pikine, Dakar', 1.5, 'loamy'),
  (4, 'Ferme Kolda', 'Kolda-ville', 3.0, 'clay');

-- Sample crops
INSERT INTO crops (farm_id, crop_name, planted_date, expected_harvest_date, quantity_planted, expected_yield, status)
VALUES 
  (1, 'maïs', '2025-06-01', '2025-09-15', 100, 450, 'growing'),
  (1, 'arachide', '2025-06-15', '2025-10-01', 80, 320, 'growing'),
  (2, 'riz', '2025-05-20', '2025-09-01', 150, 750, 'growing'),
  (3, 'millet', '2025-07-01', '2025-10-15', 120, 480, 'growing');

-- Sample livestock
INSERT INTO livestock (user_id, animal_type, breed, quantity, age_months, health_status, feeding_type, location)
VALUES 
  (2, 'cattle', 'N\'Dama', 5, 36, 'healthy', 'grass', 'Kaolack-ville'),
  (2, 'goat', 'Local', 15, 18, 'healthy', 'mixed', 'Kaolack-ville'),
  (4, 'sheep', 'Peul', 8, 24, 'healthy', 'grass', 'Kolda-ville'),
  (4, 'poultry', 'Local', 50, 4, 'vaccinated', 'grains', 'Kolda-ville');

-- Sample market prices
INSERT INTO market_prices (product_name, region, price_per_kg, currency, source)
VALUES 
  ('maïs', 'Dakar', 250, 'CFA', 'ministry'),
  ('maïs', 'Kaolack', 220, 'CFA', 'ministry'),
  ('riz', 'Dakar', 400, 'CFA', 'ministry'),
  ('arachide', 'Kaolack', 350, 'CFA', 'ministry'),
  ('millet', 'Kolda', 300, 'CFA', 'ministry'),
  ('tomate', 'Dakar', 500, 'CFA', 'market_data'),
  ('oignon', 'Tambacounda', 180, 'CFA', 'market_data');
```

---

### 7️⃣ VERIFY EVERYTHING WORKS

```sql
-- Count records in each table
SELECT 'users' as table_name, COUNT(*) as count FROM users
UNION ALL
SELECT 'farms', COUNT(*) FROM farms
UNION ALL
SELECT 'crops', COUNT(*) FROM crops
UNION ALL
SELECT 'livestock', COUNT(*) FROM livestock
UNION ALL
SELECT 'market_prices', COUNT(*) FROM market_prices;
```

Expected result:
```
table_name      | count
----------------+-------
crops           | 4
farm            | 3
livestock       | 4
market_prices   | 7
users           | 4
```

---

## 📍 Steps to Use

### On Neon Dashboard

1. Go to **SQL Editor**
2. Copy the entire `database.sql` file content
3. Paste in editor
4. Click **"Run"** button
5. Wait for ✅ "Success"

### Or Use Command Line

```powershell
# Windows PowerShell
$url = "postgresql://user:password@host/dbname"
psql $url -f database.sql
```

### Or Python

```python
import psycopg2

url = "postgresql://user:password@host/dbname"
conn = psycopg2.connect(url)
cursor = conn.cursor()

with open('database.sql', 'r') as f:
    cursor.execute(f.read())
conn.commit()
```

---

## ✅ You're Done!

Your database is ready to use with the Mbaymi backend! 🎉

Next:
1. Copy DATABASE_URL from Neon
2. Add to backend `.env`
3. Run backend with `uvicorn app.main:app --reload`
4. Test at http://localhost:8000/docs
