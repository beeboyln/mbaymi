-- Ajouter colonnes pour unité de mesure et photos additionnelles
ALTER TABLE IF EXISTS sales ADD COLUMN IF NOT EXISTS unit VARCHAR(50) DEFAULT 'kg';
ALTER TABLE IF EXISTS sales ADD COLUMN IF NOT EXISTS additional_images JSONB;
ALTER TABLE IF EXISTS sales ADD COLUMN IF NOT EXISTS description VARCHAR(1000);
ALTER TABLE IF EXISTS sales ADD COLUMN IF NOT EXISTS category VARCHAR(100);

-- Index pour les recherches
CREATE INDEX IF NOT EXISTS idx_sales_category ON sales(category);
CREATE INDEX IF NOT EXISTS idx_sales_user_id ON sales(user_id);
