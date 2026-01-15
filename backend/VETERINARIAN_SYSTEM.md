# 👨‍⚕️ Veterinarian/Expert System - Complete Implementation Guide

## Overview

The platform now supports a 3-role system:
1. **Agriculteur/Éleveur** (Farmer/Livestock Breeder) - Requests help
2. **Vétérinaire/Expert Agricole** (Veterinarian/Agricultural Expert) - Provides consultations
3. **Admin** (Future) - Manages platform

## Architecture

### Database Schema

#### 1. `veterinarian_profiles` Table
Stores professional information for veterinarians/experts.

**Fields:**
- `id` - Primary key
- `user_id` - Reference to users table (unique, one profile per user)
- `specialty` - e.g., "Veterinaire", "Agronome", "Élevage de ruminants"
- `zone` - Geographic zone where they operate
- `distance_max` - Maximum distance willing to travel (km)
- `bio` - Professional biography
- `experience_years` - Years of professional experience
- `certificate_url` - URL to uploaded professional certificate
- `contact_preference` - Preferred contact method (whatsapp, call, email)
- `verification_status` - "pending", "verified", "rejected"
- `availability_status` - "available", "busy", "offline"
- `total_consultations` - Count of completed consultations
- `average_rating` - Rating from farmers (1-5 stars)

#### 2. `authorizations` Table
Tracks farm data access permissions (farmers grant, veterinarians accept).

**Fields:**
- `id` - Primary key
- `farm_id` - Farm being authorized
- `veterinarian_id` - Professional user
- `authorized_by` - Farmer user_id
- `can_view_data` - Can see farm data
- `can_give_advice` - Can provide consultations
- `can_visit` - Can visit farm (on-site consultations)
- `status` - "pending" (waiting for vet), "accepted", "rejected", "revoked"
- `authorization_reason` - Why farmer is requesting this professional
- `expires_at` - Authorization expiration date (1 year default)
- `revoked_at` - When farmer revoked access
- `UNIQUE(farm_id, veterinarian_id)` - One per professional per farm

#### 3. `service_requests` Table
Farmers request help for animal/crop problems.

**Fields:**
- `id` - Primary key
- `farm_id` - Which farm has the problem
- `created_by` - Farmer who created request
- `service_type` - "animal_problem", "crop_problem", "general_advice"
- `title` - Short description
- `description` - Full problem description
- `symptoms` - Observed symptoms
- `animal_id` - Associated livestock (if animal problem)
- `crop_id` - Associated crop (if crop problem)
- `priority` - "low", "medium", "high", "urgent"
- `status` - "open", "in_progress", "assigned", "completed", "closed", "cancelled"
- `photos` - JSON array of Cloudinary URLs
- `assigned_to` - Veterinarian currently handling it
- `created_at`, `updated_at` - Timestamps

#### 4. `consultations` Table
Professional responses to service requests (one per service request).

**Fields:**
- `id` - Primary key
- `service_request_id` - Reference to service request (unique - one consultation per request)
- `veterinarian_id` - Professional providing consultation
- `consultation_type` - "written_advice", "whatsapp_call", "video_call", "on_site_visit"
- `advice` - Professional advice/diagnosis
- `recommendations` - Recommended treatments/actions
- `scheduling` - Proposed schedule for visit/call
- `cost` - Amount to charge farmer
- `payment_status` - "pending", "paid", "free"
- `farmer_rating` - 1-5 star rating from farmer
- `farmer_feedback` - Farmer's review comments

## API Endpoints

### 👨‍⚕️ Veterinarian Profiles

```
POST   /api/veterinarians/profile
       Create new veterinarian profile
       ✅ Requires: specialty, zone, experience_years
       Returns: VeterinarianProfileResponse

GET    /api/veterinarians/my-profile
       Get current user's veterinarian profile
       ✅ Auth required

GET    /api/veterinarians/profile/{veterinarian_id}
       Get specific veterinarian's public profile
       No auth required

PATCH  /api/veterinarians/profile
       Update veterinarian's own profile
       ✅ Auth required

POST   /api/veterinarians/upload-certificate
       Upload professional certificate (to Cloudinary)
       ✅ Auth required (multipart form)

PATCH  /api/veterinarians/availability/{status}
       Update availability: "available", "busy", "offline"
       ✅ Auth required

GET    /api/veterinarians/verified
       Get all verified veterinarians
       No auth required

GET    /api/veterinarians/by-zone/{zone}
       Get veterinarians in specific zone
       No auth required

GET    /api/veterinarians/by-specialty/{specialty}
       Get veterinarians with specific specialty
       No auth required
```

### 🔐 Authorizations

```
POST   /api/authorizations/
       Create authorization request
       ✅ Requires: farm_id, veterinarian_id, can_view_data, can_give_advice, can_visit
       Body includes: authorization_reason
       Only farm owner can create

GET    /api/authorizations/pending
       Get pending authorizations for current veterinarian
       ✅ Auth required

POST   /api/authorizations/{authorization_id}/accept
       Veterinarian accepts authorization
       ✅ Auth required

POST   /api/authorizations/{authorization_id}/reject
       Veterinarian rejects authorization
       ✅ Auth required

POST   /api/authorizations/{authorization_id}/revoke
       Farmer revokes authorization
       ✅ Auth required

GET    /api/authorizations/farm/{farm_id}
       Get all authorizations for a farm
       ✅ Auth required (farm owner only)

GET    /api/authorizations/veterinarian/{veterinarian_id}
       Get active authorizations for a veterinarian
       ✅ Auth required (veterinarian only)
```

### 🆘 Service Requests

```
POST   /api/service-requests/
       Create new service request
       ✅ Requires: service_type, title, description
       Optional: symptoms, animal_id, crop_id, priority, photos

GET    /api/service-requests/my-requests
       Get all requests created by current farmer
       ✅ Auth required

GET    /api/service-requests/{request_id}
       Get specific service request
       ✅ Auth required (owner or authorized veterinarian)

PATCH  /api/service-requests/{request_id}
       Update service request (farmer only)
       ✅ Auth required

GET    /api/service-requests/available-for-me
       Get available requests in veterinarian's zone
       ✅ Auth required

POST   /api/service-requests/{request_id}/assign
       Assign request to veterinarian
       ✅ Auth required (farm owner only)

POST   /api/service-requests/{request_id}/consultations
       Create consultation (provide advice)
       ✅ Auth required (authorized veterinarian)
       Updates service_request status to "completed"

GET    /api/service-requests/{request_id}/consultations
       Get all consultations for a request
       ✅ Auth required

POST   /api/service-requests/{request_id}/rate
       Farmer rates the consultation (1-5 stars)
       ✅ Auth required (farmer only)
```

## Workflow Examples

### Example 1: Farmer Requests Help

```
1. Farmer creates SERVICE_REQUEST
   POST /api/service-requests/
   {
     "service_type": "animal_problem",
     "title": "Cow with fever",
     "description": "Our cow has high temperature and won't eat",
     "symptoms": "Fever 39.5°C, loss of appetite",
     "animal_id": 123,
     "priority": "high",
     "photos": ["https://cloudinary.../photo1.jpg"]
   }
   → Returns: service_request_id = 456

2. Veterinarian searches available requests
   GET /api/service-requests/available-for-me
   → Returns list of open requests in their zone

3. Farmer finds veterinarian and sends authorization
   POST /api/authorizations/
   {
     "farm_id": 789,
     "veterinarian_id": 101,
     "can_view_data": true,
     "can_give_advice": true,
     "can_visit": true,
     "authorization_reason": "Need help with sick cow"
   }
   → authorization_id = 234 (status: "pending")

4. Veterinarian accepts authorization
   POST /api/authorizations/234/accept
   → authorization now active

5. Veterinarian provides consultation
   POST /api/service-requests/456/consultations
   {
     "consultation_type": "on_site_visit",
     "advice": "Cow has bacterial infection, needs antibiotics",
     "recommendations": "Administer Amoxicillin 500mg twice daily for 5 days",
     "scheduling": "Tomorrow at 10 AM",
     "cost": 50000,
     "payment_status": "pending"
   }
   → service_request status → "completed"
   → consultation_id = 567

6. Farmer rates consultation
   POST /api/service-requests/456/rate
   {
     "rating": 5,
     "feedback": "Very helpful, the cow is recovering well"
   }
   → Updates veterinarian's average_rating
```

### Example 2: Veterinarian Setup

```
1. User registers as Veterinarian
   Needs to set role = "veterinarian" in signup

2. Creates veterinarian profile
   POST /api/veterinarians/profile
   {
     "specialty": "Veterinaire",
     "zone": "Douala",
     "distance_max": 50,
     "bio": "20 years experience with cattle and poultry",
     "experience_years": 20,
     "contact_preference": "whatsapp"
   }
   → verification_status = "pending"

3. Uploads certificate
   POST /api/veterinarians/upload-certificate
   [uploads file to Cloudinary]
   → Admin reviews and verifies

4. Admin verifies profile
   [Manual verification - future automation]
   verification_status → "verified"

5. Farmer finds and requests authorization
   GET /api/veterinarians/by-zone/Douala
   GET /api/veterinarians/by-specialty/Veterinaire
   → Finds veterinarian, initiates authorization

6. Veterinarian manages availability
   PATCH /api/veterinarians/availability/busy
   [When overloaded]
   
   PATCH /api/veterinarians/availability/available
   [When ready for more requests]
```

## Role-Based Access Control

### Farmer (role = "farmer")
- ✅ Create service requests
- ✅ Send authorization requests to veterinarians
- ✅ View consultations for own requests
- ✅ Rate and review consultations
- ✅ Revoke veterinarian authorizations
- ❌ Cannot view other farms' requests

### Veterinarian (role = "veterinarian")
- ✅ Create veterinarian profile
- ✅ View pending authorizations
- ✅ Accept/reject authorizations
- ✅ View authorized farms' data
- ✅ Provide consultations
- ✅ Update availability status
- ✅ See own consultation history
- ❌ Cannot access unauthorized farms
- ❌ Cannot view other veterinarians' authorizations

### Admin (future)
- ✅ Verify/reject veterinarian profiles
- ✅ Manage platform content
- ✅ View analytics and reports
- ✅ Handle disputes

## Data Security & Authorization

### Permission Hierarchy

1. **Farmer owns their farm data**
   - Only farm owner can create authorizations
   - Only farm owner can revoke access

2. **Veterinarian needs explicit permission**
   - Cannot see farm data without accepted authorization
   - Authorization specifies exact permissions:
     - `can_view_data`: See farm details
     - `can_give_advice`: Provide consultations
     - `can_visit`: Schedule on-site visits

3. **Expiration & Revocation**
   - Authorizations expire after 1 year
   - Farmer can revoke at any time
   - System checks authorization before allowing access

### Security Checks in API

```python
# Before veterinarian views farm data:
1. Check authorization exists
2. Check status == "accepted"
3. Check can_view_data == true
4. Check expiration > now
5. Check status != "revoked"

# Before veterinarian provides consultation:
1. Same checks as above
2. Also check can_give_advice == true
3. Verify veterinarian verified status

# Before accessing service request:
1. Check if farmer (creator)
2. OR check if veterinarian with valid authorization
```

## Migration & Deployment

### Step 1: Run Migration
```bash
# Apply SQL migration to database
psql -d mbaymi_db -f backend/sql/add_veterinarian_system.sql

# Or via API:
POST http://localhost:8000/admin/migrate
?key=MIGRATION_KEY
```

### Step 2: Verify Models & Routes
- ✅ Models created: `veterinarian.py`, `authorization.py`, `service_request.py`
- ✅ Schemas created: `veterinarian.py`, `authorization.py`, `service_request.py`
- ✅ Routes created: `veterinarian.py`, `authorization.py`, `service_request.py`
- ✅ Routes registered in `main.py`

### Step 3: Frontend Implementation (Next)
- Modify registration to select role
- Create veterinarian profile setup screen
- Create service request creation UI
- Create authorization request UI
- Create consultation display UI

## Testing Checklist

### API Tests
- [ ] POST `/api/veterinarians/profile` - Create profile
- [ ] GET `/api/veterinarians/my-profile` - Get profile
- [ ] PATCH `/api/veterinarians/profile` - Update profile
- [ ] POST `/api/veterinarians/upload-certificate` - Upload cert
- [ ] PATCH `/api/veterinarians/availability/{status}` - Set status
- [ ] GET `/api/veterinarians/by-zone/{zone}` - Find by zone
- [ ] POST `/api/authorizations/` - Request authorization
- [ ] GET `/api/authorizations/pending` - View pending
- [ ] POST `/api/authorizations/{id}/accept` - Accept
- [ ] POST `/api/service-requests/` - Create request
- [ ] GET `/api/service-requests/my-requests` - View own
- [ ] POST `/api/service-requests/{id}/consultations` - Provide advice
- [ ] GET `/api/service-requests/{id}/consultations` - View advice
- [ ] POST `/api/service-requests/{id}/rate` - Rate consultation

### Security Tests
- [ ] Farmer cannot see other farms' requests
- [ ] Veterinarian without authorization cannot see farm data
- [ ] Revoked authorizations block access
- [ ] Expired authorizations block access
- [ ] Non-verified veterinarians cannot provide consultations
- [ ] Cost/payment fields readonly after consultation created

## Next Steps

### Frontend Phase
1. Modify `RegisterScreen` to show role selection
2. Create `VeterinarianProfileSetupScreen`
3. Create `ServiceRequestCreationScreen`
4. Create `AuthorizationRequestScreen`
5. Create `ConsultationViewScreen`
6. Create `VeterinarianDashboardScreen`

### Backend Enhancements (Optional)
1. Add payment integration for consultations
2. Add notification system for requests/authorizations
3. Add search/filtering for veterinarians
4. Add ratings/reviews system
5. Add admin verification workflow

## Database Relationships

```
User (user_id)
├── VeterinarianProfile (1-to-1)
├── ServiceRequest (1-to-many as creator)
├── Authorization (1-to-many as authorized_by)
├── Consultation (1-to-many as provider)
└── Farm (1-to-many as owner)

Farm (farm_id)
├── Authorization (1-to-many)
├── ServiceRequest (1-to-many)
└── User (owner)

Authorization
├── Farm (many-to-1)
├── User/Veterinarian (many-to-1)
└── User/Farmer (authorized_by)

ServiceRequest
├── Farm (many-to-1)
├── User/Farmer (created_by)
├── Consultation (1-to-1)
├── Livestock (optional)
└── Crop (optional)

Consultation
├── ServiceRequest (1-to-1)
└── User/Veterinarian (many-to-1)
```

---

**Created:** 2025-01-XX  
**Status:** ✅ Backend Implementation Complete  
**Next:** Frontend Implementation
