-- ============================================================================
-- 🔧 MIGRATION NEON DB - Farm Network Tables & Columns Update
-- ============================================================================
-- Exécute ces requêtes pour mettre à jour ta base de données Neon

-- 1. Créer la table farm_profiles si elle n'existe pas
CREATE TABLE IF NOT EXISTS farm_profiles (
    id SERIAL PRIMARY KEY,
    farm_id INTEGER NOT NULL UNIQUE REFERENCES farms(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    is_public BOOLEAN DEFAULT TRUE,
    description TEXT,
    specialties VARCHAR(500),
    total_followers INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 2. Créer la table farm_posts si elle n'existe pas
CREATE TABLE IF NOT EXISTS farm_posts (
    id SERIAL PRIMARY KEY,
    farm_id INTEGER NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    crop_id INTEGER REFERENCES crops(id) ON DELETE SET NULL,
    title VARCHAR(200) NOT NULL,
    description TEXT,
    photo_url VARCHAR(500),
    post_type VARCHAR(50) DEFAULT 'crop_update',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- 3. Créer la table farm_following si elle n'existe pas
CREATE TABLE IF NOT EXISTS farm_following (
    id SERIAL PRIMARY KEY,
    follower_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    farm_id INTEGER NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(follower_id, farm_id)
);

-- 4. Ajouter les colonnes manquantes à farm_profiles si nécessaire
ALTER TABLE farm_profiles 
ADD COLUMN IF NOT EXISTS is_public BOOLEAN DEFAULT TRUE;

ALTER TABLE farm_profiles 
ADD COLUMN IF NOT EXISTS total_followers INTEGER DEFAULT 0;

ALTER TABLE farm_profiles 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- 5. Ajouter les colonnes manquantes à farm_posts si nécessaire
ALTER TABLE farm_posts 
ADD COLUMN IF NOT EXISTS post_type VARCHAR(50) DEFAULT 'crop_update';

ALTER TABLE farm_posts 
ADD COLUMN IF NOT EXISTS updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP;

-- 6. Créer les indices pour optimiser les performances
CREATE INDEX IF NOT EXISTS idx_farm_profiles_farm_id ON farm_profiles(farm_id);
CREATE INDEX IF NOT EXISTS idx_farm_profiles_user_id ON farm_profiles(user_id);
CREATE INDEX IF NOT EXISTS idx_farm_profiles_is_public ON farm_profiles(is_public);
CREATE INDEX IF NOT EXISTS idx_farm_posts_farm_id ON farm_posts(farm_id);
CREATE INDEX IF NOT EXISTS idx_farm_posts_user_id ON farm_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_farm_posts_created_at ON farm_posts(created_at);
CREATE INDEX IF NOT EXISTS idx_farm_following_follower_id ON farm_following(follower_id);
CREATE INDEX IF NOT EXISTS idx_farm_following_farm_id ON farm_following(farm_id);

-- 7. Mettre à jour le count des followers basé sur la table farm_following
UPDATE farm_profiles 
SET total_followers = (
    SELECT COUNT(*) FROM farm_following 
    WHERE farm_following.farm_id = farm_profiles.farm_id
);

-- ✅ Migration complétée!
-- Les tables et colonnes nécessaires pour le réseau agricole sont maintenant en place.
