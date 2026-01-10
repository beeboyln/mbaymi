-- Create pasture_images table
CREATE TABLE pasture_images (
    id SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    title VARCHAR(200),
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for faster queries
CREATE INDEX idx_pasture_images_user_id ON pasture_images(user_id);
CREATE INDEX idx_pasture_images_created_at ON pasture_images(created_at DESC);
