# DATABASE DEPENDENCY GRAPH - VISUAL REPRESENTATION

## 🟢 GREEN Models (Safe CASCADE Delete)
These will auto-delete descendants properly:
- ✅ Crop (CASCADE on farm_id)
- ✅ FarmImagePost (CASCADE on farm_id) 
- ✅ FarmPhoto (CASCADE on farm_id)
- ✅ Input (CASCADE on farm_id + crop_id)
- ✅ FarmPostLike (CASCADE on farm_post_id)
- ✅ FarmPostComment (CASCADE on farm_post_id)
- ✅ FarmPostShare (CASCADE on farm_post_id)
- ✅ ActivityPhoto (CASCADE on activity_id)
- ✅ AnimalPhoto (CASCADE on livestock_id)

## 🟡 YELLOW Models (Weak CASCADE or No CASCADE)
These have farm_id but NO cascade - MANUAL DELETION REQUIRED:
- ⚠️ FarmProfile (farm_id, unique, NO CASCADE)
- ⚠️ FarmPost (farm_id, NO CASCADE)
- ⚠️ FarmFollowing (farm_id, NO CASCADE)
- ⚠️ Activity (farm_id, NO CASCADE)
- ⚠️ CropProblem (farm_id + crop_id, NO CASCADE)
- ⚠️ Reminder (farm_id, NO CASCADE)
- ⚠️ Harvest (farm_id, NO CASCADE)
- ⚠️ FinanceTransaction (farm_id, NO CASCADE)

## 🔴 RED Models (Critical Issues)
These are DANGEROUS - missing FK constraints or cascades:
- 🚨 ServiceRequest (farm_id field, NO FK CONSTRAINT!)
- 🚨 Authorization (farm_id field, NO FK CONSTRAINT!)
- ❌ Consultation (NO CASCADE on service_request_id)
- ❌ Sale (NO CASCADE on harvest_id)

======================================================================
COMPLETE DELETION DEPENDENCY GRAPH
======================================================================

PHASE 1 (Leaf-level entities - delete these FIRST):
┌─────────────────────────────────────────────┐
│                                             │
│  DELETE: FarmPostLike                       │
│  DELETE: FarmPostComment                    │
│  DELETE: FarmPostShare                      │
│  DELETE: ActivityPhoto                      │
│  DELETE: AnimalPhoto                        │
│                                             │
│  Status: 🟢 Cascade from parents            │
│  Order: Can parallelize (no dependencies)   │
│                                             │
└─────────────────────────────────────────────┘
           ↓↓↓ DEPENDS ON ↓↓↓

PHASE 2 (Delete dependencies of deleted items):
┌─────────────────────────────────────────────┐
│                                             │
│  DELETE: Consultation                       │
│  DELETE: Sale                               │
│                                             │
│  Status: ❌ No automatic cascade            │
│  Action: MANUAL deletion required           │
│  Order: Can parallelize after Phase 1       │
│                                             │
└─────────────────────────────────────────────┘
           ↓↓↓ DEPENDS ON ↓↓↓

PHASE 3 (Farm data with NO cascade - CRITICAL):
┌──────────────────────────────────────────────────┐
│                                                  │
│  DELETE: CropProblem      (farm_id, crop_id)     │
│  DELETE: Reminder         (farm_id, crop_id)     │
│  DELETE: FinanceTransaction (farm_id, crop_id)   │
│  DELETE: Harvest          (farm_id, crop_id)     │
│  DELETE: Activity         (farm_id, crop_id)     │
│  DELETE: FarmPost         (farm_id, crop_id)     │
│  DELETE: ServiceRequest   (NO FK - CRITICAL!)    │
│  DELETE: Authorization    (NO FK - CRITICAL!)    │
│  DELETE: FarmFollowing    (farm_id)              │
│  DELETE: FarmProfile      (farm_id, unique)      │
│                                                  │
│  Status: ⚠️⚠️ DANGEROUS - Manual required!      │
│  ⚠️ ServiceRequest & Authorization have NO      │
│     explicit ForeignKey constraints!             │
│  Order: Can parallelize after Phase 2            │
│  Action: 🚨 FIX FK CONSTRAINTS FIRST             │
│                                                  │
└──────────────────────────────────────────────────┘
           ↓↓↓ DEPENDS ON ↓↓↓

PHASE 4 (Farm data WITH cascade - safer):
┌──────────────────────────────────────────────┐
│                                              │
│  DELETE: FarmImagePost    (CASCADE on farm)  │
│  DELETE: FarmPhoto        (CASCADE on farm)  │
│  DELETE: Input            (CASCADE on farm)  │
│                                              │
│  Status: 🟢 Should auto-cascade              │
│  Note: We delete explicitly for clarity      │
│  Order: Can parallelize after Phase 3        │
│                                              │
└──────────────────────────────────────────────┘
           ↓↓↓ DEPENDS ON ↓↓↓

PHASE 5 (Root crop entities):
┌──────────────────────────────────────────────┐
│                                              │
│  DELETE: Crop            (CASCADE on farm)   │
│                                              │
│  Status: 🟢 Cascade delete enabled           │
│  Note: Deletes remaining Inputs if any       │
│  Order: MUST be after Phase 4                │
│                                              │
└──────────────────────────────────────────────┘
           ↓↓↓ DEPENDS ON ↓↓↓

PHASE 6 (Final - the farm itself):
┌──────────────────────────────────────────────┐
│                                              │
│  DELETE: Farm                                │
│                                              │
│  Status: 🟢 Root entity                      │
│  Note: User record is NOT deleted            │
│  Order: MUST be last (depends on all above)  │
│                                              │
└──────────────────────────────────────────────┘


======================================================================
REFERENCE TABLE: CASCADE STATUS BY TABLE
======================================================================

TABLE NAME              │ farm_id│ CASCADE│ Status │ Action
────────────────────────┼────────┼────────┼────────┼────────────
Crop                    │   YES  │ YES    │ 🟢     │ Safe
FarmImagePost           │   YES  │ YES    │ 🟢     │ Safe
FarmPhoto               │   YES  │ YES    │ 🟢     │ Safe
Input                   │   YES  │ YES    │ 🟢     │ Safe
FarmProfile             │   YES  │ NO     │ ⚠️     │ MANUAL
FarmPost                │   YES  │ NO     │ ⚠️     │ MANUAL
FarmFollowing           │   YES  │ NO     │ ⚠️     │ MANUAL
Activity                │   YES  │ NO     │ ⚠️     │ MANUAL
CropProblem             │   YES  │ NO     │ ⚠️     │ MANUAL
Reminder                │   YES  │ NO     │ ⚠️     │ MANUAL
Harvest                 │   YES  │ NO     │ ⚠️     │ MANUAL
FinanceTransaction      │   YES  │ NO     │ ⚠️     │ MANUAL
ServiceRequest          │   NO ForeignKey │ 🔴    │ FIX+MANUAL
Authorization           │   NO ForeignKey │ 🔴    │ FIX+MANUAL
────────────────────────┴────────┴────────┴────────┴────────────
FarmPostLike            │   NO   │ YES    │ 🟢     │ Safe
FarmPostComment         │   NO   │ YES    │ 🟢     │ Safe
FarmPostShare           │   NO   │ YES    │ 🟢     │ Safe
ActivityPhoto           │   NO   │ YES    │ 🟢     │ Safe
AnimalPhoto             │   NO   │ YES    │ 🟢     │ Safe
Consultation            │   NO   │ NO     │ ⚠️     │ MANUAL
Sale                    │   NO   │ NO     │ ⚠️     │ MANUAL


======================================================================
TOTAL RECORD DELETION REQUIREMENTS
======================================================================

For a typical farm with:
  - 5 crops
  - 20 farm posts
  - 100 farm images with likes/comments
  - 50 activities with photos
  - 10 livestock with photos
  - Various records in other tables

APPROXIMATE RECORDS TO DELETE:

├─ FarmPostLike:          ~500  (likes on 100 posts)
├─ FarmPostComment:       ~500  (comments on 100 posts)
├─ FarmPostShare:         ~200  (shares of 100 posts)
├─ ActivityPhoto:         ~50   (photos of activities)
├─ AnimalPhoto:           ~30   (photos of animals)
├─ Consultation:          ~10   (consultations)
├─ Sale:                  ~10   (sales from harvests)
├─ CropProblem:           ~20   (crop issues)
├─ Reminder:              ~30   (reminders)
├─ FinanceTransaction:    ~100  (financial records)
├─ Harvest:               ~15   (harvests)
├─ Activity:              ~50   (farm activities)
├─ FarmPost:              ~20   (farm posts)
├─ ServiceRequest:        ~5    (service requests)
├─ Authorization:         ~5    (veterinarian authorizations)
├─ FarmFollowing:         ~2    (followers)
├─ FarmProfile:           ~1    (farm profile)
├─ FarmImagePost:         ~100  (farm image posts)
├─ FarmPhoto:             ~50   (farm photos)
├─ Input:                 ~50   (fertilizers, seeds, etc)
├─ Crop:                  ~5    (crops)
└─ Farm:                  ~1    (the farm itself)

TOTAL: ~1,600+ records potentially deleted


======================================================================
DELETION CHECKLIST
======================================================================

Before Deletion:
  ☐ Backup database
  ☐ Test on backup copy first
  ☐ Verify farm_id to be deleted
  ☐ Check for related data in other systems
  ☐ Set up proper transaction handling
  ☐ Enable audit logging
  ☐ Close any open connections to deleted farm

Phase 1:
  ☐ Delete FarmPostLike
  ☐ Delete FarmPostComment
  ☐ Delete FarmPostShare
  ☐ Delete ActivityPhoto
  ☐ Delete AnimalPhoto

Phase 2:
  ☐ Delete Consultation
  ☐ Delete Sale

Phase 3 (CRITICAL - Manual Deletions):
  ☐ Delete CropProblem
  ☐ Delete Reminder
  ☐ Delete FinanceTransaction
  ☐ Delete Harvest
  ☐ Delete Activity
  ☐ Delete FarmPost
  ☐ Delete ServiceRequest (⚠️ check FK constraint first)
  ☐ Delete Authorization (⚠️ check FK constraint first)
  ☐ Delete FarmFollowing
  ☐ Delete FarmProfile

Phase 4:
  ☐ Delete FarmImagePost
  ☐ Delete FarmPhoto
  ☐ Delete Input

Phase 5:
  ☐ Delete Crop

Phase 6:
  ☐ Delete Farm

Verification:
  ☐ Run cleanup queries to verify all records deleted
  ☐ Check application logs for errors
  ☐ Verify user account still exists (not deleted)
  ☐ Confirm no orphaned records remain
  ☐ Document deletion in audit log


======================================================================
ROLLBACK PLAN (If Something Goes Wrong)
======================================================================

If deletion fails at any point:

1. STOP immediately (don't continue to next step)
2. Check the error message
3. ROLLBACK the entire transaction
4. Restore from backup if necessary
5. Fix the issue:
   - If FK constraint error: Fix the constraint in the model
   - If cascade not working: Check database constraint definitions
   - If unexpected data: Check for application bugs
6. Test on backup again
7. Retry with corrected approach


======================================================================
CRITICAL FIX REQUIRED
======================================================================

Before running the deletion service in production, you MUST fix:

1. Authorization.farm_id - Add ForeignKey constraint
2. ServiceRequest.farm_id - Add ForeignKey constraint
3. Consultation.service_request_id - Add CASCADE
4. Sale.harvest_id - Add CASCADE

See: FARM_DELETION_COMPLETE_GUIDE.md for details

Without these fixes, your deletion may fail with referential integrity errors!
