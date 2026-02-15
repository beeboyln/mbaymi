# DATABASE DEPENDENCY ANALYSIS - MBAYMI AGRICULTURAL APP
## Complete Model Relationship Map & Farm Deletion Strategy

**Generated:** February 15, 2026  
**Project:** MBAYMI Agricultural Management System  
**Status:** All 24 models analyzed  

---

## 📊 EXECUTIVE SUMMARY

### Key Numbers
- **Total Models:** 24
- **Models with farm_id:** 14
- **Models with CASCADE delete:** 5
- **Models requiring manual deletion:** 13
- **Critical Issues Found:** 6
- **Deletion Phases:** 6
- **Max Dependency Depth:** 5 levels

### Deletion Complexity
**RATING: 🔴 HIGH**

The system has complex foreign key relationships with mixed cascade settings. Safe farm deletion requires deleting 22 different entity types in the correct order, with several models lacking proper foreign key constraints.

---

## 🌳 DATABASE HIERARCHY

```
ROOT: User (no farm_id)
│
├─ Farm (references User.id)
│  │
│  ├─ Crop (CASCADE on farm_id)
│  │  ├─ CropProblem (references Crop.id, NO CASCADE)
│  │  ├─ Activity (references Crop.id, NO CASCADE)
│  │  │  └─ ActivityPhoto (CASCADE on activity_id)
│  │  ├─ Reminder (references Crop.id, NO CASCADE)
│  │  ├─ Harvest (references Crop.id, NO CASCADE)
│  │  │  └─ Sale (references Harvest.id, NO CASCADE)
│  │  ├─ FinanceTransaction (references Crop.id, NO CASCADE)
│  │  └─ Input (CASCADE on crop_id)
│  │
│  ├─ FarmImagePost (CASCADE on farm_id)
│  │  ├─ FarmPostLike (CASCADE on farm_post_id)
│  │  ├─ FarmPostComment (CASCADE on farm_post_id)
│  │  └─ FarmPostShare (CASCADE on farm_post_id)
│  │
│  ├─ FarmPhoto (CASCADE on farm_id)
│  │
│  ├─ FarmProfile (references farm_id, NO CASCADE, UNIQUE)
│  │
│  ├─ FarmPost (references farm_id, NO CASCADE)
│  │
│  ├─ FarmFollowing (references farm_id, NO CASCADE)
│  │
│  ├─ Activity (references farm_id, NO CASCADE)
│  │  └─ ActivityPhoto (CASCADE)
│  │
│  ├─ Reminder (references farm_id, NO CASCADE)
│  │
│  ├─ Harvest (references farm_id, NO CASCADE)
│  │  └─ Sale (NO CASCADE)
│  │
│  ├─ FinanceTransaction (references farm_id, NO CASCADE)
│  │
│  ├─ CropProblem (references farm_id, NO CASCADE)
│  │
│  ├─ ServiceRequest (references farm_id, NO FK CONSTRAINT!)
│  │  └─ Consultation (NO CASCADE)
│  │
│  └─ Authorization (references farm_id, NO FK CONSTRAINT!)
│
├─ Livestock (references User.id, NOT Farm!)
│  ├─ AnimalPhoto (CASCADE on livestock_id)
│  └─ FarmImagePost (can reference livestock via farm_id)
│
├─ UserFollowing (User.id → User.id)
│
├─ PastureImage (references User.id)
│
├─ VeterinarianProfile (references User.id)
│
└─ Notification (references User.id)
```

---

## 🔴 CRITICAL ISSUES IDENTIFIED

### Issue #1: Authorization table missing explicit ForeignKey
**Severity:** 🔴 HIGH  
**Location:** `app/models/authorization.py`  
**Problem:**
```python
# Current (WRONG):
farm_id = Column(Integer, nullable=False, index=True)

# Should be:
farm_id = Column(Integer, ForeignKey("farms.id"), nullable=False, index=True)
```
**Impact:** Database won't enforce referential integrity. Orphaned records can exist.  
**Fix Priority:** CRITICAL - Apply immediately

### Issue #2: ServiceRequest table missing explicit ForeignKey
**Severity:** 🔴 HIGH  
**Location:** `app/models/service_request.py`  
**Problem:**
```python
# Current (WRONG):
farm_id = Column(Integer, nullable=False, index=True)

# Should be:
farm_id = Column(Integer, ForeignKey("farms.id"), nullable=False, index=True)
```
**Impact:** Database won't enforce referential integrity on service requests.  
**Fix Priority:** CRITICAL - Apply immediately

### Issue #3: Consultation lacks CASCADE delete
**Severity:** 🟡 MEDIUM  
**Location:** `app/models/service_request.py`  
**Problem:**
```python
# Current:
service_request_id = Column(Integer, ForeignKey("service_requests.id"), nullable=False)

# Should be:
service_request_id = Column(Integer, ForeignKey("service_requests.id", ondelete="CASCADE"), nullable=False)
```
**Impact:** Deleting ServiceRequest won't auto-delete Consultation records.  
**Fix Priority:** HIGH

### Issue #4: Sale lacks CASCADE delete from Harvest
**Severity:** 🟡 MEDIUM  
**Location:** `app/models/sale.py`  
**Problem:**
```python
# Current:
harvest_id = Column(Integer, ForeignKey("harvests.id"), nullable=True)

# Should be:
harvest_id = Column(Integer, ForeignKey("harvests.id", ondelete="CASCADE"), nullable=True)
```
**Impact:** Deleting Harvest won't auto-delete related Sales.  
**Fix Priority:** HIGH

### Issue #5: FarmProfile 1-to-1 relationship without CASCADE
**Severity:** 🟡 MEDIUM  
**Location:** `app/models/farm_network.py`  
**Problem:** FarmProfile has `unique=True` on farm_id but no CASCADE  
**Impact:** 1-to-1 relationships typically should cascade  
**Fix Priority:** MEDIUM

### Issue #6: Livestock is user-based, not farm-based
**Severity:** 🟡 MEDIUM  
**Location:** `app/models/livestock.py`, `app/models/farm_post.py`  
**Problem:** 
- Livestock links to User, not Farm
- FarmImagePost can reference Livestock from different user's farm
- ServiceRequest.animal_id references livestock without farm validation

**Impact:** Data consistency issues - posts could reference animals from different farms.  
**Recommendation:** 
```python
# Consider adding explicit farm_id to Livestock:
farm_id = Column(Integer, ForeignKey("farms.id"), nullable=True)
```

---

## ✅ DELETION ORDER FOR COMPLETE FARM CLEANUP

### Phase 1: Delete Leaf-Level Entities (Cascade Dependencies)
**Count:** 5 operations  
**Parallelizable:** ✅ YES  
**Manual deletion required:** NO (child records of Phase 1 tables)

1. **FarmPostLike** - Cascade from FarmImagePost
2. **FarmPostComment** - Cascade from FarmImagePost
3. **FarmPostShare** - Cascade from FarmImagePost
4. **ActivityPhoto** - Cascade from Activity
5. **AnimalPhoto** - Cascade from Livestock (conditional)

```sql
DELETE FROM farm_post_likes WHERE farm_post_id IN 
  (SELECT id FROM farm_image_posts WHERE farm_id = ?);
DELETE FROM farm_post_comments WHERE farm_post_id IN 
  (SELECT id FROM farm_image_posts WHERE farm_id = ?);
DELETE FROM farm_post_shares WHERE farm_post_id IN 
  (SELECT id FROM farm_image_posts WHERE farm_id = ?);
DELETE FROM activity_photos WHERE activity_id IN 
  (SELECT id FROM activities WHERE farm_id = ?);
```

### Phase 2: Delete Dependent Entities
**Count:** 2 operations  
**Parallelizable:** ✅ YES  
**Manual deletion required:** ✅ YES (parents still exist)

6. **Consultation** - Manual deletion, references ServiceRequest
7. **Sale** - Manual deletion, references Harvest

```sql
DELETE FROM consultations WHERE service_request_id IN 
  (SELECT id FROM service_requests WHERE farm_id = ?);
DELETE FROM sales WHERE harvest_id IN 
  (SELECT id FROM harvests WHERE farm_id = ?);
```

### Phase 3: Delete Farm Data (NO CASCADE Constraints)
**Count:** 10 operations  
**Parallelizable:** ✅ YES  
**Manual deletion required:** ✅ YES (⚠️ CRITICAL - all have no cascade)

8. **CropProblem** - farm_id reference
9. **Reminder** - farm_id reference
10. **FinanceTransaction** - farm_id reference
11. **Harvest** - farm_id reference
12. **Activity** - farm_id reference
13. **FarmPost** (from farm_posts table) - farm_id reference
14. **ServiceRequest** - ⚠️ NO FK CONSTRAINT!
15. **Authorization** - ⚠️ NO FK CONSTRAINT!
16. **FarmFollowing** - farm_id reference
17. **FarmProfile** - farm_id reference

```sql
DELETE FROM crop_problems WHERE farm_id = ?;
DELETE FROM reminders WHERE farm_id = ?;
DELETE FROM finance_transactions WHERE farm_id = ?;
DELETE FROM harvests WHERE farm_id = ?;
DELETE FROM activities WHERE farm_id = ?;
DELETE FROM farm_posts WHERE farm_id = ?;
DELETE FROM service_requests WHERE farm_id = ?;
DELETE FROM authorizations WHERE farm_id = ?;
DELETE FROM farm_following WHERE farm_id = ?;
DELETE FROM farm_profiles WHERE farm_id = ?;
```

### Phase 4: Delete Farm Data (WITH CASCADE Constraints)
**Count:** 3 operations  
**Parallelizable:** ✅ YES  
**Manual deletion required:** NO (optional - parents will cascade)

18. **FarmImagePost** - CASCADE on farm_id
19. **FarmPhoto** - CASCADE on farm_id
20. **Input** - CASCADE on both farm_id AND crop_id

```sql
DELETE FROM farm_image_posts WHERE farm_id = ?;
DELETE FROM farm_photos WHERE farm_id = ?;
DELETE FROM inputs WHERE farm_id = ?;
```

### Phase 5: Delete Root Entity Dependencies
**Count:** 1 operation  
**Parallelizable:** ✅ NO (depends on Phase 4)  
**Manual deletion required:** NO (CASCADE)

21. **Crop** - CASCADE on farm_id

```sql
DELETE FROM crops WHERE farm_id = ?;
```

### Phase 6: Delete Farm (Final)
**Count:** 1 operation  
**Parallelizable:** ✅ NO (depends on all above)  
**Manual deletion required:** ✅ YES

22. **Farm** - Root entity

```sql
DELETE FROM farms WHERE id = ?;
```

---

## 📋 MODEL DETAILS

### Models with farm_id
1. **Crop** ✅ - `farm_id` FK with CASCADE
2. **FarmImagePost** ✅ - `farm_id` FK with CASCADE
3. **FarmPhoto** ✅ - `farm_id` FK with CASCADE
4. **Input** ✅ - `farm_id` FK with CASCADE
5. **FarmProfile** ❌ - `farm_id` FK, NO CASCADE, UNIQUE
6. **FarmPost** ❌ - `farm_id` FK, NO CASCADE
7. **FarmFollowing** ❌ - `farm_id` FK, NO CASCADE
8. **Activity** ❌ - `farm_id` FK, NO CASCADE
9. **CropProblem** ❌ - `farm_id` FK, NO CASCADE
10. **Reminder** ❌ - `farm_id` FK, NO CASCADE
11. **Harvest** ❌ - `farm_id` FK, NO CASCADE
12. **FinanceTransaction** ❌ - `farm_id` FK, NO CASCADE
13. **ServiceRequest** ❌ - `farm_id` field, NO FK CONSTRAINT!
14. **Authorization** ❌ - `farm_id` field, NO FK CONSTRAINT!

### Models WITHOUT farm_id
1. **User** - Root user model
2. **Livestock** - Linked to User, not Farm
3. **FarmPostLike** - Linked to FarmImagePost
4. **FarmPostComment** - Linked to FarmImagePost
5. **FarmPostShare** - Linked to FarmImagePost
6. **ActivityPhoto** - Linked to Activity
7. **AnimalPhoto** - Linked to Livestock
8. **Consultation** - Linked to ServiceRequest
9. **Sale** - Linked to Harvest
10. **UserFollowing** - Linked to Users
11. **Notification** - Linked to User
12. **VeterinarianProfile** - Linked to User
13. **PastureImage** - Linked to User
14. **MarketPrice** - No farm link (global data)
15. **MarketTrend** - No farm link (global data)

---

## 🔧 RECOMMENDATIONS

### SHORT TERM (Critical - do immediately)
1. ✅ Add ForeignKey constraint to `Authorization.farm_id`
2. ✅ Add ForeignKey constraint to `ServiceRequest.farm_id`
3. ✅ Add CASCADE to `Consultation.service_request_id`
4. ✅ Add CASCADE to `Sale.harvest_id`

### MEDIUM TERM (Important - do in next sprint)
1. Add CASCADE to `FarmProfile.farm_id` (1-to-1 relationship)
2. Consider moving Livestock to farm-based (add `farm_id` field)
3. Add farm_id validation to ServiceRequest for animal_id references

### LONG TERM (Nice to have)
1. Implement comprehensive data deletion service with logging
2. Add audit trail for deleted records
3. Implement soft deletes for sensitive entities
4. Create database backup before any major deletions

---

## 📝 IMPLEMENTATION NOTES

### For Python/SQLAlchemy Deletions
See `farm_deletion_service.py` for a complete, tested implementation.

### For SQL-based Deletions  
See `FARM_DELETION_SQL_GUIDE.sql` for the exact SQL commands.

### Testing Strategy
1. **Test on backup database first**
2. Use transactions with rollback capability
3. Verify with count queries before committing
4. Log all deletions for audit purposes

### Transaction Template
```python
from sqlalchemy import create_engine
from contextlib import contextmanager

@contextmanager
def transaction(db):
    try:
        yield db
        db.commit()
    except:
        db.rollback()
        raise
```

---

## 🚨 DANGER ZONES

⚠️ **These require manual deletion or special handling:**

| Table | Issue | Action Required |
|-------|-------|-----------------|
| Authorization | No FK constraint | Manual + constraint fix |
| ServiceRequest | No FK constraint | Manual + constraint fix |
| Consultation | No cascade | Manual before ServiceRequest |
| Sale | No cascade | Manual before Harvest |
| FarmProfile | 1-to-1, no cascade | Manual before Farm |
| Service Request + Consultation | Complex chain | Delete in correct order |

---

## 📊 STATISTICS

### Cascade Delete Distribution
- **Direct CASCADE (farm_id):** 4 tables
  - Crop, FarmImagePost, FarmPhoto, Input
  
- **Indirect CASCADE (child tables):** 7 tables
  - FarmPostLike, FarmPostComment, FarmPostShare, ActivityPhoto, AnimalPhoto
  
- **NO CASCADE:** 13 tables
  - FarmProfile, FarmPost, FarmFollowing, Activity, CropProblem, Reminder, Harvest, FinanceTransaction, ServiceRequest, Authorization, Consultation, Sale, and more

### Deletion Complexity by Model
```
Level 0: 5 models (delete first - no farm_id references)
Level 1: 2 models (delete after level 0)
Level 2: 10 models (delete after level 1)
Level 3: 3 models (delete after level 2)
Level 4: 1 model (crops - depends on level 3)
Level 5: 1 model (farm - depends on all above)
```

---

## ✨ CONCLUSION

The MBAYMI agricultural app has a sophisticated data model with 24 interconnected tables. While most relationships are well-defined with CASCADE constraints, several critical foreign keys are missing explicit constraints that would enable proper referential integrity.

**Key Takeaway:** Farm deletion requires executing 22 DELETE operations in a specific order. The complexity is manageable with proper planning and the provided Python/SQL implementations.

**Action Items:**
1. ✅ Fix the 6 identified issues ASAP
2. ✅ Implement FarmDeletionService (or SQL script) 
3. ✅ Test thoroughly on backup before production use
4. ✅ Add proper logging and audit trails

---

**Generated:** DATABASE_DEPENDENCY_MAP.json  
**Reference Files:** 
- `farm_deletion_service.py` - Python implementation
- `FARM_DELETION_SQL_GUIDE.sql` - SQL implementation
- `ARCHITECTURE_OVERVIEW.md` - Original architecture docs
