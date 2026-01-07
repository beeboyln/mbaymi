-- Add new columns to farms if missing
ALTER TABLE IF EXISTS farms ADD COLUMN IF NOT EXISTS image_url VARCHAR(500);
ALTER TABLE IF EXISTS farms ADD COLUMN IF NOT EXISTS latitude DOUBLE PRECISION;
ALTER TABLE IF EXISTS farms ADD COLUMN IF NOT EXISTS longitude DOUBLE PRECISION;

-- Create activities table if not exists
CREATE TABLE IF NOT EXISTS activities (
  id serial PRIMARY KEY,
  farm_id integer REFERENCES farms(id) ON DELETE CASCADE,
  crop_id integer REFERENCES crops(id) ON DELETE SET NULL,
  user_id integer REFERENCES users(id) ON DELETE SET NULL,
  activity_type varchar(100) NOT NULL,
  activity_date timestamp without time zone DEFAULT now(),
  notes text,
  created_at timestamp without time zone DEFAULT now(),
  updated_at timestamp without time zone DEFAULT now()
);

-- Create harvests table if not exists
CREATE TABLE IF NOT EXISTS harvests (
  id serial PRIMARY KEY,
  farm_id integer REFERENCES farms(id) ON DELETE CASCADE,
  crop_id integer REFERENCES crops(id) ON DELETE SET NULL,
  estimated_quantity double precision,
  actual_quantity double precision,
  harvest_date timestamp without time zone DEFAULT now(),
  notes text,
  created_at timestamp without time zone DEFAULT now()
);

-- Create sales table if not exists
CREATE TABLE IF NOT EXISTS sales (
  id serial PRIMARY KEY,
  harvest_id integer REFERENCES harvests(id) ON DELETE SET NULL,
  product_name varchar(200) NOT NULL,
  quantity double precision NOT NULL,
  price_per_unit double precision NOT NULL,
  currency varchar(10) DEFAULT 'CFA',
  delivery_location varchar(200),
  contact varchar(100),
  user_id integer REFERENCES users(id) ON DELETE SET NULL,
  created_at timestamp without time zone DEFAULT now()
);

-- Indexes to help lookups
CREATE INDEX IF NOT EXISTS idx_farms_user_id ON farms(user_id);
CREATE INDEX IF NOT EXISTS idx_activities_farm_id ON activities(farm_id);
CREATE INDEX IF NOT EXISTS idx_harvests_farm_id ON harvests(farm_id);
CREATE INDEX IF NOT EXISTS idx_sales_user_id ON sales(user_id);
