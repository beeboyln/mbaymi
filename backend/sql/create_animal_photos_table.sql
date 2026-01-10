-- Create animal_photos table for multiple photos per animal
CREATE TABLE animal_photos (
    id SERIAL PRIMARY KEY,
    livestock_id INTEGER NOT NULL REFERENCES livestock(id) ON DELETE CASCADE,
    image_url VARCHAR(500) NOT NULL,
    caption TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);

-- Create indexes for faster queries
CREATE INDEX idx_animal_photos_livestock_id ON animal_photos(livestock_id);
CREATE INDEX idx_animal_photos_created_at ON animal_photos(created_at DESC);
