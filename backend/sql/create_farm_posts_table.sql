-- Créer la table pour les posts d'images des fermes
CREATE TABLE IF NOT EXISTS farm_image_posts (
    id SERIAL PRIMARY KEY,
    farm_id INTEGER NOT NULL REFERENCES farms(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    image_url VARCHAR(500),
    caption TEXT,
    likes_count INTEGER DEFAULT 0,
    comments_count INTEGER DEFAULT 0,
    shares_count INTEGER DEFAULT 0,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Créer la table pour les likes des farm posts
CREATE TABLE IF NOT EXISTS farm_post_likes (
    id SERIAL PRIMARY KEY,
    farm_post_id INTEGER NOT NULL REFERENCES farm_image_posts(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    UNIQUE(farm_post_id, user_id)
);

-- Créer la table pour les commentaires des farm posts
CREATE TABLE IF NOT EXISTS farm_post_comments (
    id SERIAL PRIMARY KEY,
    farm_post_id INTEGER NOT NULL REFERENCES farm_image_posts(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    comment TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Créer la table pour les shares des farm posts
CREATE TABLE IF NOT EXISTS farm_post_shares (
    id SERIAL PRIMARY KEY,
    farm_post_id INTEGER NOT NULL REFERENCES farm_image_posts(id) ON DELETE CASCADE,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Index pour performance
CREATE INDEX IF NOT EXISTS idx_farm_image_posts_farm_id ON farm_image_posts(farm_id);
CREATE INDEX IF NOT EXISTS idx_farm_image_posts_user_id ON farm_image_posts(user_id);
CREATE INDEX IF NOT EXISTS idx_farm_image_posts_created_at ON farm_image_posts(created_at DESC);
CREATE INDEX IF NOT EXISTS idx_farm_post_likes_farm_post_id ON farm_post_likes(farm_post_id);
CREATE INDEX IF NOT EXISTS idx_farm_post_likes_user_id ON farm_post_likes(user_id);
