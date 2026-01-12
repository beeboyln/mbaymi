-- Add livestock_id column to farm_image_posts table
-- This allows posts to be associated with animals (livestock) in addition to farms

ALTER TABLE farm_image_posts
ADD COLUMN livestock_id INTEGER;

-- Add foreign key constraint
ALTER TABLE farm_image_posts
ADD CONSTRAINT fk_livestock_id
FOREIGN KEY (livestock_id) REFERENCES livestock(id) ON DELETE CASCADE;

-- Make farm_id nullable since posts can now be for either farms or livestock
ALTER TABLE farm_image_posts
ALTER COLUMN farm_id DROP NOT NULL;

-- Create index for faster queries
CREATE INDEX idx_farm_image_posts_livestock_id ON farm_image_posts(livestock_id);
