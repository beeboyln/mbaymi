# 🧪 FARM POSTS - QUICK TEST GUIDE

## API Endpoints Reference

### Create Farm Post
```bash
POST /farm-posts/{farm_id}/create
Authorization: Bearer {token}
Content-Type: application/json

{
  "image_url": "https://cloudinary.com/...",
  "caption": "Ma récolte du mois"
}
```

### Get Feed
```bash
GET /farm-posts/feed?user_id=5
Content-Type: application/json

# Response:
[
  {
    "id": 1,
    "farm_id": 5,
    "farm_name": "Ferme Dupont",
    "owner_name": "Jean",
    "image_url": "...",
    "caption": "Récolte",
    "likes_count": 3,
    "comments_count": 0,
    "shares_count": 1,
    "created_at": "2026-01-11T18:30:00",
    "is_liked": false
  }
]
```

### Like/Unlike
```bash
# Like
POST /farm-posts/{post_id}/like
Authorization: Bearer {token}

# Unlike
DELETE /farm-posts/{post_id}/like
Authorization: Bearer {token}
```

### Share
```bash
POST /farm-posts/{post_id}/share
Authorization: Bearer {token}
```

### Get Farm Posts
```bash
GET /farm-posts/{farm_id}?user_id=5
# Gets all posts for a specific farm
```

---

## Frontend Testing Scenarios

### Scenario 1: Create First Farm Post
1. Login as farm owner (must own a farm)
2. Navigate to farm detail screen
3. Click + button in "Posts de la ferme" section
4. Select image from gallery
5. Add caption (optional)
6. Click "Publier"
7. ✅ Should see post appear in list

### Scenario 2: Like From Social Feed
1. Go to Social Feed tab
2. Find a farm post in the feed
3. Click ❤️ icon
4. ✅ Like count increases immediately
5. Heart becomes filled red
6. ✅ Persists after refresh (API synced)

### Scenario 3: Unlike and Revert
1. Like a farm post
2. Click ❤️ again to unlike
3. ✅ Like count decreases
4. ❤️ becomes outline
5. Disconnect network and try to like
6. ✅ UI updates but reverts on error

### Scenario 4: Share Post
1. Find farm post
2. Click 📤 share button
3. ✅ Share count increases
4. ✅ Persists after refresh

### Scenario 5: Mixed Feed
1. Create multiple farm posts
2. Add new animal photos
3. Go to Social Feed
4. ✅ Should see alternating farm posts and animals
5. ✅ Sorted by most recent first
6. Both should have like buttons

### Scenario 6: Non-Owner Cannot Create
1. Login as farmer WITHOUT owning a farm
2. Try to create post through API
3. ✅ Get 403 Forbidden error
4. UI should not show + button if not owner

---

## Database Verification

### Check Tables Exist
```sql
SELECT table_name FROM information_schema.tables 
WHERE table_schema='public' 
AND table_name LIKE 'farm_post%';

-- Should return:
-- farm_image_posts
-- farm_post_likes
-- farm_post_comments
-- farm_post_shares
```

### Check Sample Data
```sql
SELECT id, farm_id, caption, likes_count, created_at 
FROM farm_image_posts 
ORDER BY created_at DESC 
LIMIT 5;
```

### Check Likes
```sql
SELECT farm_post_id, COUNT(*) as like_count 
FROM farm_post_likes 
GROUP BY farm_post_id;
```

### Check Indexes
```sql
SELECT indexname FROM pg_indexes 
WHERE tablename LIKE 'farm_post%';

-- Should have indexes on:
-- farm_post_id, user_id, created_at
```

---

## Network Debug

### Check API Responses

**Create Post:**
```
Status: 200 OK
Body: {
  "id": 123,
  "farm_id": 5,
  "image_url": "...",
  "caption": "...",
  "likes_count": 0,
  "comments_count": 0,
  "shares_count": 0,
  "created_at": "...",
  "is_liked": false
}
```

**Get Feed:**
```
Status: 200 OK
Body: [
  { post data... },
  { post data... }
]
```

**Like:**
```
Status: 200 OK
Body: {}
```

**Errors:**
```
401 Unauthorized - Bad/expired token
403 Forbidden - Not farm owner
404 Not Found - Post doesn't exist
500 Server Error - Database issue
```

---

## Common Issues & Fixes

### Posts Not Appearing
1. ✅ Check SQL migration was run
2. ✅ Verify `farm_posts.py` in main.py routes
3. ✅ Clear browser cache
4. ✅ Check network tab for failed requests

### Like Button Not Working
1. ✅ Check token is valid
2. ✅ Verify user is logged in
3. ✅ Check network request succeeds
4. ✅ See error message in snackbar

### Image Not Uploading
1. ✅ Check Cloudinary credentials
2. ✅ Verify image size < 5MB
3. ✅ Check browser console errors
4. ✅ Verify file format (JPG/PNG/GIF)

### Post Not Saving
1. ✅ Check database connection
2. ✅ Verify farm_id exists
3. ✅ Check user_id matches owner
4. ✅ See backend logs for SQL errors

---

## Performance Checks

### Query Speed
```sql
-- Should be < 100ms
SELECT * FROM farm_image_posts 
ORDER BY created_at DESC LIMIT 20;

-- With join (should be < 200ms)
SELECT f.*, u.name 
FROM farm_image_posts f
JOIN users u ON f.user_id = u.id
ORDER BY f.created_at DESC LIMIT 20;
```

### Memory Usage
- Each post in feed: ~2KB
- 1000 posts: ~2MB
- Should load smoothly with pagination

---

## Monitoring

### Log for Errors
```bash
# Backend
tail -f logs/app.log | grep farm

# Frontend
Chrome DevTools > Console > Filter by "farm"
```

### Check Counters
```dart
// Verify counter update in logs
print('Like count before: $likesCount');
// After API call
print('Like count after: ${post["likes_count"]}');
```

### Monitor Database
```sql
-- Active connections
SELECT count(*) FROM pg_stat_activity 
WHERE datname = 'mbaymi';

-- Last N posts
SELECT created_at, farm_id, likes_count 
FROM farm_image_posts 
ORDER BY created_at DESC LIMIT 10;
```

---

## Success Criteria ✅

- [x] User can create farm post with image and caption
- [x] Posts appear in farm detail screen
- [x] Posts appear in social feed mixed with animals
- [x] Like button updates counter immediately
- [x] Like persists after app restart
- [x] Unlike removes like
- [x] Share increments counter
- [x] Only farm owner can create posts
- [x] Error handling shows user-friendly messages
- [x] Images load from Cloudinary
- [x] Feed sorted by most recent first
- [x] Performance is smooth (< 200ms load)

---

All green? You're ready to deploy! 🚀
