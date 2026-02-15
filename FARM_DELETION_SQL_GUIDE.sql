-- DATABASE DELETION GUIDE FOR FARM DELETION
-- This SQL script shows the exact order to delete all farm-related data
-- 
-- CRITICAL RULES:
-- 1. Follow the exact order - DO NOT SKIP STEPS
-- 2. Test with ROLLBACK first on a backup database
-- 3. Use transactions to ensure consistency
-- 4. Replace ? with the actual farm_id

-- ============================================================================
-- PHASE 1: Delete leaf-level entities (cascade dependencies)
-- These tables are referenced only by their parents, so we delete first
-- ============================================================================

-- 1. Delete all likes on farm posts
DELETE FROM farm_post_likes 
WHERE farm_post_id IN (
    SELECT id FROM farm_image_posts WHERE farm_id = ?
);

-- 2. Delete all comments on farm posts
DELETE FROM farm_post_comments 
WHERE farm_post_id IN (
    SELECT id FROM farm_image_posts WHERE farm_id = ?
);

-- 3. Delete all shares of farm posts
DELETE FROM farm_post_shares 
WHERE farm_post_id IN (
    SELECT id FROM farm_image_posts WHERE farm_id = ?
);

-- 4. Delete all photos from activities on the farm
DELETE FROM activity_photos 
WHERE activity_id IN (
    SELECT id FROM activities WHERE farm_id = ?
);

-- 5. Delete all photos of animals (if deleting associated livestock)
-- Note: Livestock is user-based, not farm-based, so this is conditional
-- Only do this if you're deleting livestock owned by the farm's user
DELETE FROM animal_photos 
WHERE livestock_id IN (
    SELECT id FROM livestock 
    WHERE user_id = (SELECT user_id FROM farms WHERE id = ?)
);

-- ============================================================================
-- PHASE 2: Delete dependent entities that reference Phase 1 tables
-- ============================================================================

-- 6. Delete all consultations for service requests on this farm
DELETE FROM consultations 
WHERE service_request_id IN (
    SELECT id FROM service_requests WHERE farm_id = ?
);

-- 7. Delete all sales for harvests on this farm
DELETE FROM sales 
WHERE harvest_id IN (
    SELECT id FROM harvests WHERE farm_id = ?
);

-- ============================================================================
-- PHASE 3: Delete farm data with NO cascade constraints
-- ⚠️ CRITICAL: These tables reference the farm but database doesn't enforce cascade
--    They MUST be manually deleted
-- ============================================================================

-- 8. Delete crop problems
DELETE FROM crop_problems 
WHERE farm_id = ?;

-- 9. Delete reminders
DELETE FROM reminders 
WHERE farm_id = ?;

-- 10. Delete finance transactions
DELETE FROM finance_transactions 
WHERE farm_id = ?;

-- 11. Delete harvests
DELETE FROM harvests 
WHERE farm_id = ?;

-- 12. Delete activities
DELETE FROM activities 
WHERE farm_id = ?;

-- 13. Delete farm posts (from farm_posts table, not farm_image_posts)
DELETE FROM farm_posts 
WHERE farm_id = ?;

-- 14. Delete service requests
-- ⚠️ NOTE: This table has NO explicit ForeignKey constraint!
DELETE FROM service_requests 
WHERE farm_id = ?;

-- 15. Delete authorizations
-- ⚠️ NOTE: This table has NO explicit ForeignKey constraint!
DELETE FROM authorizations 
WHERE farm_id = ?;

-- 16. Delete farm following relationships
DELETE FROM farm_following 
WHERE farm_id = ?;

-- 17. Delete farm profile
-- ⚠️ NOTE: This is a 1-to-1 relationship and unique=True
DELETE FROM farm_profiles 
WHERE farm_id = ?;

-- ============================================================================
-- PHASE 4: Delete farm data WITH cascade constraints
-- These can auto-delete descendants, but we delete them explicitly here
-- ============================================================================

-- 18. Delete farm image posts (will cascade to likes, comments, shares if not deleted)
DELETE FROM farm_image_posts 
WHERE farm_id = ?;

-- 19. Delete farm photos
DELETE FROM farm_photos 
WHERE farm_id = ?;

-- 20. Delete inputs
-- ⚠️ NOTE: This has cascade on BOTH farm_id AND crop_id
DELETE FROM inputs 
WHERE farm_id = ?;

-- ============================================================================
-- PHASE 5: Delete Crops
-- Crops have CASCADE delete on farm_id, so they auto-delete remaining Inputs
-- ============================================================================

-- 21. Delete all crops for this farm
DELETE FROM crops 
WHERE farm_id = ?;

-- ============================================================================
-- PHASE 6: Delete the Farm itself
-- Final step - the farm record and the Farm is the root of this hierarchy
-- ============================================================================

-- 22. Delete the farm
DELETE FROM farms 
WHERE id = ?;


-- ============================================================================
-- VERIFICATION QUERIES (Run these AFTER deletion to confirm success)
-- ============================================================================

-- Check if farm still exists
SELECT COUNT(*) as farms_remaining FROM farms WHERE id = ?;

-- Check remaining related data (should all be 0)
SELECT 
    (SELECT COUNT(*) FROM crops WHERE farm_id = ?) as crops,
    (SELECT COUNT(*) FROM farm_image_posts WHERE farm_id = ?) as farm_image_posts,
    (SELECT COUNT(*) FROM farm_photo FROM farm WHERE farm_id = ?) as farm_photos,
    (SELECT COUNT(*) FROM activities WHERE farm_id = ?) as activities,
    (SELECT COUNT(*) FROM service_requests WHERE farm_id = ?) as service_requests,
    (SELECT COUNT(*) FROM crop_problems WHERE farm_id = ?) as crop_problems,
    (SELECT COUNT(*) FROM reminders WHERE farm_id = ?) as reminders,
    (SELECT COUNT(*) FROM inputs WHERE farm_id = ?) as inputs,
    (SELECT COUNT(*) FROM farm_posts WHERE farm_id = ?) as farm_posts,
    (SELECT COUNT(*) FROM farm_profiles WHERE farm_id = ?) as farm_profiles,
    (SELECT COUNT(*) FROM farm_following WHERE farm_id = ?) as farm_following,
    (SELECT COUNT(*) FROM authorizations WHERE farm_id = ?) as authorizations,
    (SELECT COUNT(*) FROM harvests WHERE farm_id = ?) as harvests,
    (SELECT COUNT(*) FROM finance_transactions WHERE farm_id = ?) as finance,
    (SELECT COUNT(*) FROM sales WHERE harvest_id IN 
        (SELECT id FROM harvests WHERE farm_id = ?)) as orphaned_sales;

-- ============================================================================
-- COMPLETE TRANSACTION TEMPLATE (Use this for safety)
-- ============================================================================

/*
BEGIN TRANSACTION;

-- Run all deletion queries above here

COMMIT;  -- or ROLLBACK if something goes wrong

-- Then run verification queries
*/


-- ============================================================================
-- NOTES ON CASCADE DELETE IN DATABASE VS APPLICATION
-- ============================================================================

/*
Some tables have "CASCADE" defined in the ForeignKey constraint:
- farm_image_posts.farm_id -> farms.id (CASCADE)
- farm_photos.farm_id -> farms.id (CASCADE)  
- farm_photo_likes.farm_post_id -> farm_image_posts.id (CASCADE)
- farm_post_comments.farm_post_id -> farm_image_posts.id (CASCADE)
- farm_post_shares.farm_post_id -> farm_image_posts.id (CASCADE)
- activity_photos.activity_id -> activities.id (CASCADE)
- animal_photos.livestock_id -> livestock.id (CASCADE)
- inputs.farm_id -> farms.id (CASCADE)
- inputs.crop_id -> crops.id (CASCADE)
- crops.farm_id -> farms.id (CASCADE)

If database cascade is properly configured, deleting the parent SHOULD 
automatically delete these children. However, for safety and clarity, 
we delete them explicitly in the correct order.

Tables WITHOUT cascade that reference the farm:
- farm_posts
- farm_profiles
- farm_following
- activities
- reminders
- harvests
- finance_transactions
- crop_problems
- service_requests
- consultations
- authorizations

These MUST be manually deleted before the farm, or the deletion will fail
with foreign key constraint violations.
*/
