# 📱 Frontend Integration Guide - Veterinarian System

## Quick Start for Frontend Developers

### Base URL
```
http://localhost:8000  # Development
https://api.mbaymi.com  # Production (update as needed)
```

### Authentication
All endpoints except `/get` endpoints require Bearer token in header:
```
Authorization: Bearer {jwt_token}
```

## 1️⃣ FARMER - Service Request Flow

### Create Service Request
```dart
// Create service request for animal problem
POST /api/service-requests/
{
  "service_type": "animal_problem",  // or "crop_problem", "general_advice"
  "title": "Cow with fever",
  "description": "My cow has high fever and won't eat",
  "symptoms": "Temperature 39.5°C, loss of appetite",
  "animal_id": 123,  // optional
  "priority": "high",  // or "low", "medium", "urgent"
  "photos": [
    "https://cloudinary.com/image1.jpg",
    "https://cloudinary.com/image2.jpg"
  ]
}
Response: ServiceRequestResponse
```

### View My Requests
```dart
GET /api/service-requests/my-requests
Response: List<ServiceRequestResponse>
```

### Find Veterinarians (Before Requesting Help)
```dart
// By location
GET /api/veterinarians/by-zone/Douala
Response: List<VeterinarianProfileResponse>

// By specialty
GET /api/veterinarians/by-specialty/Veterinaire
Response: List<VeterinarianProfileResponse>

// Get specific profile
GET /api/veterinarians/profile/{veterinarian_id}
Response: VeterinarianProfileResponse
```

### Request Authorization from Veterinarian
```dart
POST /api/authorizations/
{
  "farm_id": 789,
  "veterinarian_id": 101,
  "can_view_data": true,
  "can_give_advice": true,
  "can_visit": true,
  "authorization_reason": "Need help with sick cow"
}
Response: AuthorizationResponse (status: "pending")
```

### View Consultations
```dart
GET /api/service-requests/{request_id}/consultations
Response: List<ConsultationResponse>
```

### Rate Consultation
```dart
POST /api/service-requests/{request_id}/rate
{
  "rating": 5,  // 1-5
  "feedback": "Very helpful, cow is better now"
}
Response: ConsultationResponse (updated with rating)
```

### Manage Authorizations (for own farm)
```dart
// View all authorizations for farm
GET /api/authorizations/farm/{farm_id}
Response: List<AuthorizationResponse>

// Revoke authorization
POST /api/authorizations/{authorization_id}/revoke
Response: AuthorizationResponse (status: "revoked")
```

---

## 2️⃣ VETERINARIAN - Service Provider Flow

### Create Veterinarian Profile
```dart
POST /api/veterinarians/profile
{
  "specialty": "Veterinaire",  // or "Agronome", "Éleveur", etc
  "zone": "Douala",
  "distance_max": 50,  // km
  "bio": "20 years experience with cattle and poultry",
  "experience_years": 20,
  "contact_preference": "whatsapp"  // or "call", "email"
}
Response: VeterinarianProfileResponse (status: "pending")
```

### Upload Professional Certificate
```dart
POST /api/veterinarians/upload-certificate
Content-Type: multipart/form-data
[file data]

Response: {"message": "Certificate uploaded successfully"}
Note: Admin will verify certificate before verification_status → "verified"
```

### Check Pending Authorizations
```dart
GET /api/veterinarians/pending
Response: List<AuthorizationResponse>
// Shows authorizations waiting for veterinarian acceptance
```

### Accept Authorization
```dart
POST /api/authorizations/{authorization_id}/accept
Response: AuthorizationResponse (status: "accepted")
```

### Reject Authorization
```dart
POST /api/authorizations/{authorization_id}/reject
Response: AuthorizationResponse (status: "rejected")
```

### Find Available Service Requests
```dart
// Returns requests in your zone that don't have assigned veterinarian
GET /api/service-requests/available-for-me
Response: List<ServiceRequestResponse>
```

### View Service Request Details
```dart
GET /api/service-requests/{request_id}
Response: ServiceRequestResponse
Note: Can only view if:
  1. You have accepted authorization for that farm
  2. Authorization has can_view_data: true
```

### Provide Consultation
```dart
POST /api/service-requests/{request_id}/consultations
{
  "consultation_type": "written_advice",  // or "whatsapp_call", "video_call", "on_site_visit"
  "advice": "Cow has bacterial infection. Diagnosis: Mastitis",
  "recommendations": "Administer Amoxicillin 500mg 2x daily for 5 days. Clean udder with antiseptic",
  "scheduling": "Tomorrow at 10 AM",  // optional
  "cost": 50000,  // optional, in local currency
  "payment_status": "pending"  // or "paid", "free"
}
Response: ConsultationResponse
Note: Service request status automatically changes to "completed"
```

### View Your Authorizations
```dart
GET /api/veterinarians/veterinarian/{your_user_id}
Response: List<AuthorizationResponse>
// Shows all farms you have accepted authorization for
```

### Update Availability
```dart
PATCH /api/veterinarians/availability/busy
// Options: "available", "busy", "offline"

Response: {"message": "Availability status updated to busy"}
```

### Update Profile
```dart
PATCH /api/veterinarians/profile
{
  "specialty": "Veterinaire",  // optional
  "zone": "Douala",  // optional
  "distance_max": 75,  // optional
  "bio": "Updated bio...",  // optional
  "experience_years": 21,  // optional
  "contact_preference": "call",  // optional
  "availability_status": "available"  // optional
}
Response: VeterinarianProfileResponse (updated)
```

---

## 3️⃣ Response Models Reference

### VeterinarianProfileResponse
```dart
{
  "id": 1,
  "user_id": 101,
  "specialty": "Veterinaire",
  "zone": "Douala",
  "distance_max": 50,
  "bio": "20 years experience",
  "experience_years": 20,
  "certificate_url": "https://cloudinary.com/cert.pdf",
  "contact_preference": "whatsapp",
  "verification_status": "verified",  // "pending", "verified", "rejected"
  "availability_status": "available",  // "available", "busy", "offline"
  "total_consultations": 15,
  "average_rating": 4.8
}
```

### AuthorizationResponse
```dart
{
  "id": 1,
  "farm_id": 123,
  "veterinarian_id": 101,
  "authorized_by": 456,  // farmer user_id
  "can_view_data": true,
  "can_give_advice": true,
  "can_visit": true,
  "status": "accepted",  // "pending", "accepted", "rejected", "revoked"
  "authorization_reason": "Need help with sick cow",
  "expires_at": "2026-01-15T10:00:00",
  "is_active": true,
  "created_at": "2025-01-15T10:00:00",
  "updated_at": "2025-01-15T10:30:00"
}
```

### ServiceRequestResponse
```dart
{
  "id": 1,
  "farm_id": 123,
  "created_by": 456,
  "service_type": "animal_problem",
  "title": "Cow with fever",
  "description": "My cow has high fever and won't eat",
  "symptoms": "Temperature 39.5°C, loss of appetite",
  "animal_id": 789,
  "crop_id": null,
  "priority": "high",  // "low", "medium", "high", "urgent"
  "status": "completed",  // "open", "in_progress", "assigned", "completed", "closed", "cancelled"
  "photos": [
    "https://cloudinary.com/image1.jpg"
  ],
  "assigned_to": 101,  // veterinarian user_id
  "created_at": "2025-01-15T09:00:00",
  "updated_at": "2025-01-15T11:00:00"
}
```

### ConsultationResponse
```dart
{
  "id": 1,
  "service_request_id": 1,
  "veterinarian_id": 101,
  "consultation_type": "on_site_visit",  // "written_advice", "whatsapp_call", "video_call", "on_site_visit"
  "advice": "Cow has bacterial infection. Diagnosis: Mastitis",
  "recommendations": "Administer Amoxicillin 500mg 2x daily for 5 days",
  "scheduling": "Tomorrow at 10 AM",
  "cost": 50000,
  "payment_status": "pending",  // "pending", "paid", "free"
  "farmer_rating": 5,  // 1-5 stars
  "farmer_feedback": "Very helpful, cow recovered well",
  "created_at": "2025-01-15T11:00:00",
  "updated_at": "2025-01-15T11:30:00"
}
```

---

## 4️⃣ Error Handling

### Common Error Responses

```dart
// 401 Unauthorized - Not authenticated
{
  "detail": "Not authenticated"
}

// 403 Forbidden - Authenticated but no permission
{
  "detail": "You don't have permission to view this request"
}

// 404 Not Found
{
  "detail": "Service request not found"
}

// 400 Bad Request - Invalid data
{
  "detail": "Rating must be between 1 and 5"
}
```

---

## 5️⃣ Flutter Implementation Examples

### Using Dio HTTP Client

```dart
// Create service request
Future<ServiceRequest> createServiceRequest(ServiceRequestCreate data) async {
  final response = await dio.post(
    '/api/service-requests/',
    data: data.toJson(),
  );
  return ServiceRequest.fromJson(response.data);
}

// Request authorization
Future<Authorization> requestAuthorization(AuthorizationCreate data) async {
  final response = await dio.post(
    '/api/authorizations/',
    data: data.toJson(),
  );
  return Authorization.fromJson(response.data);
}

// Create consultation
Future<Consultation> provideConsultation(
  int requestId,
  ConsultationCreate data
) async {
  final response = await dio.post(
    '/api/service-requests/$requestId/consultations',
    data: data.toJson(),
  );
  return Consultation.fromJson(response.data);
}

// Rate consultation
Future<Consultation> rateConsultation(
  int requestId,
  int rating,
  String? feedback
) async {
  final response = await dio.post(
    '/api/service-requests/$requestId/rate',
    queryParameters: {
      'rating': rating,
      if (feedback != null) 'feedback': feedback,
    },
  );
  return Consultation.fromJson(response.data);
}
```

---

## 6️⃣ Testing API with cURL

```bash
# Create service request
curl -X POST http://localhost:8000/api/service-requests/ \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "service_type": "animal_problem",
    "title": "Cow with fever",
    "description": "High fever and loss of appetite",
    "priority": "high"
  }'

# Find veterinarians
curl http://localhost:8000/api/veterinarians/by-zone/Douala

# Request authorization
curl -X POST http://localhost:8000/api/authorizations/ \
  -H "Authorization: Bearer {token}" \
  -H "Content-Type: application/json" \
  -d '{
    "farm_id": 1,
    "veterinarian_id": 2,
    "can_view_data": true,
    "can_give_advice": true,
    "can_visit": true
  }'
```

---

## 7️⃣ Database Transaction Example

### Complete Farmer Workflow
```
1. Farmer Creates ServiceRequest
   POST /api/service-requests/
   → Gets service_request_id = 1

2. Farmer Finds Veterinarian
   GET /api/veterinarians/by-zone/Douala
   → Gets veterinarian_id = 2

3. Farmer Sends Authorization
   POST /api/authorizations/
   farm_id: 1, veterinarian_id: 2
   → Gets authorization_id = 1 (status: "pending")

4. Veterinarian Accepts
   POST /api/authorizations/1/accept
   → authorization status → "accepted"

5. Veterinarian Views Request
   GET /api/service-requests/1
   → Can now see all details (due to authorization)

6. Veterinarian Provides Consultation
   POST /api/service-requests/1/consultations
   → Service request status → "completed"

7. Farmer Rates
   POST /api/service-requests/1/rate
   → Updates veterinarian's average_rating
```

---

## 📚 Additional Resources

- Full API Documentation: `/backend/VETERINARIAN_SYSTEM.md`
- Database Schema: Check migration SQL file
- Status Enums: See model definitions for valid values

---

**Created:** 2025-01-XX  
**For:** Frontend Development Team  
**Status:** Ready for Integration ✅
