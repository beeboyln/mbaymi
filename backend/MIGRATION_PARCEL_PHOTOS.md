# 🌾 Mbaymi - Parcel Photo Migration Guide

## Problem Fixed
- ✅ Added `image_url` column to `crops` table  
- ✅ Farm detail screen now displays parcel profile photos
- ✅ Network pages show parcel photos in read-only mode
- ✅ Fixed CORS issues with Flask Web origin

## Database Migration

### Option 1: Auto-Apply (Recommended)
Call the migration endpoint after deploying:

```bash
# Development
curl -X POST "http://localhost:8000/admin/migrate?key=dev-key-change-in-prod"

# Production (use actual key)
curl -X POST "https://cuddly-lil-bigboyllmnd-9965fc8f.koyeb.app/admin/migrate?key=YOUR_MIGRATION_KEY"
```

### Option 2: Manual SQL
Connect to your database and run:

```sql
ALTER TABLE crops ADD COLUMN IF NOT EXISTS image_url VARCHAR(500);
```

## Changes Made

### Backend (`app/main.py`)
- ✅ Added `/admin/migrate` endpoint to apply migrations
- ✅ Fixed CORS handler to respect request origin

### Backend (`app/routes/farm_network.py`)
- ✅ Added `image_url` to crops response data
- ✅ Safe handling if column doesn't exist yet

### Backend (`app/models/farm.py`)
- ✅ Added `image_url` column to Crop model

### Frontend (`farm_detail_screen.dart`)
- ✅ Display parcel photos with premium image banner
- ✅ Show 160px image with gradient overlay
- ✅ Display crop name and status over image
- ✅ Read-only mode for other users

### Frontend (`parcel_screen.dart`)
- ✅ Add background `b.png`
- ✅ 180px parcel profile photo banner
- ✅ Edit button for own parcels only
- ✅ Mode `readOnly=true` for others

## Features Now Available

✅ Users can add/change parcel profile photos
✅ Photos display beautifully on parcel screen
✅ Photos visible on network farm detail page
✅ Cloudinary integration for photo uploads
✅ Proper CORS headers for all origins
✅ Graceful fallback if image_url not yet in database
