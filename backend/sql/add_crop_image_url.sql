-- Add image_url column to crops table for parcel profile photos
ALTER TABLE crops ADD COLUMN IF NOT EXISTS image_url VARCHAR(500);
