-- Add image_url column to livestock table
ALTER TABLE livestock ADD COLUMN image_url VARCHAR(500) NULL;

-- Create index for user_id for faster queries
CREATE INDEX idx_livestock_user_id ON livestock(user_id);
