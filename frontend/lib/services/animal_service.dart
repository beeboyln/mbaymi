/// Animal Management Service for API calls
library;
import 'package:mbaymi/models/animal.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/token_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class AnimalService {
  static const String _baseUrl = 'https://cuddly-lil-bigboyllmnd-9965fc8f.koyeb.app/api/animals';
  
  /// Get authorization headers with JWT token
  static Future<Map<String, String>> _getAuthHeaders() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }
  
  /// Get all animals for the user
  static Future<List<Animal>> getAnimals({
    int? farmId,
    String? species,
    bool? isActive,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (farmId != null) queryParams['farm_id'] = farmId.toString();
      if (species != null) queryParams['species'] = species;
      if (isActive != null) queryParams['is_active'] = isActive.toString();
      
      final uri = Uri.parse(_baseUrl).replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final animals = (data['animals'] as List?)
            ?.map((json) => Animal.fromJson(json as Map<String, dynamic>))
            .toList() ?? [];
        return animals;
      } else {
        throw Exception('Failed to load animals: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading animals: $e');
    }
  }
  
  /// Get a single animal by ID
  static Future<Animal> getAnimal(int animalId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(Uri.parse('$_baseUrl/$animalId'), headers: headers);
      
      if (response.statusCode == 200) {
        return Animal.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load animal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading animal: $e');
    }
  }
  
  /// Create a new animal
  static Future<Animal> createAnimal({
    required String name,
    required String species,
    required String gender,
    required DateTime dateOfBirth,
    String? tagId,
    String? breed,
    double? weightKg,
    double? heightCm,
    String? colorMarkings,
    String? healthNotes,
    String? location,
    String? photoUrl,
    int? farmId,
    DateTime? acquisitionDate,
    double? acquisitionCost,
  }) async {
    try {
      final body = {
        'name': name,
        'species': species,
        'gender': gender,
        'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
        if (tagId != null) 'tag_id': tagId,
        if (breed != null) 'breed': breed,
        if (weightKg != null) 'weight_kg': weightKg,
        if (heightCm != null) 'height_cm': heightCm,
        if (colorMarkings != null) 'color_markings': colorMarkings,
        if (healthNotes != null) 'health_notes': healthNotes,
        if (location != null) 'location': location,
        if (photoUrl != null) 'photo_url': photoUrl,
        if (farmId != null) 'farm_id': farmId,
        if (acquisitionDate != null) 
          'acquisition_date': acquisitionDate.toIso8601String().split('T')[0],
        if (acquisitionCost != null) 'acquisition_cost': acquisitionCost,
      };
      
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 201) {
        return Animal.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to create animal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating animal: $e');
    }
  }
  
  /// Update an animal
  static Future<Animal> updateAnimal(
    int animalId, {
    String? name,
    String? breed,
    double? weightKg,
    String? healthStatus,
    String? location,
    String? photoUrl,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (name != null) body['name'] = name;
      if (breed != null) body['breed'] = breed;
      if (weightKg != null) body['weight_kg'] = weightKg;
      if (healthStatus != null) body['health_status'] = healthStatus;
      if (location != null) body['location'] = location;
      if (photoUrl != null) body['photo_url'] = photoUrl;
      
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/$animalId'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 200) {
        return Animal.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to update animal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error updating animal: $e');
    }
  }
  
  /// Delete an animal (soft delete)
  static Future<void> deleteAnimal(int animalId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(Uri.parse('$_baseUrl/$animalId'), headers: headers);
      
      if (response.statusCode != 204) {
        throw Exception('Failed to delete animal: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting animal: $e');
    }
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // HEALTH RECORDS
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get health records for an animal
  static Future<List<AnimalHealthRecord>> getHealthRecords(
    int animalId, {
    String? recordType,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (recordType != null) queryParams['record_type'] = recordType;
      
      final uri = Uri.parse('$_baseUrl/$animalId/health-records').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final records = (data['health_records'] as List?)
            ?.map((json) => AnimalHealthRecord.fromJson(json as Map<String, dynamic>))
            .toList() ?? [];
        return records;
      } else {
        throw Exception('Failed to load health records: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading health records: $e');
    }
  }
  
  /// Add a health record to an animal
  static Future<AnimalHealthRecord> addHealthRecord(
    int animalId, {
    required String recordType,
    required DateTime date,
    required String medicalName,
    String? description,
    String? dosage,
    String? administeredBy,
    double? cost,
    DateTime? nextDueDate,
    String? notes,
  }) async {
    try {
      final body = {
        'record_type': recordType,
        'date': date.toIso8601String().split('T')[0],
        'medical_name': medicalName,
        if (description != null) 'description': description,
        if (dosage != null) 'dosage': dosage,
        if (administeredBy != null) 'administered_by': administeredBy,
        if (cost != null) 'cost': cost,
        if (nextDueDate != null) 
          'next_due_date': nextDueDate.toIso8601String().split('T')[0],
        if (notes != null) 'notes': notes,
      };
      
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/$animalId/health-records'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 201) {
        return AnimalHealthRecord.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to add health record: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding health record: $e');
    }
  }
  
  /// Get health summary for an animal
  static Future<AnimalHealthSummary> getHealthSummary(int animalId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.get(Uri.parse('$_baseUrl/$animalId/health-summary'), headers: headers);
      
      if (response.statusCode == 200) {
        return AnimalHealthSummary.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to load health summary: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading health summary: $e');
    }
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // PRODUCTION RECORDS
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get production records for an animal
  static Future<List<AnimalProductionRecord>> getProductionRecords(
    int animalId, {
    String? metricType,
    DateTime? dateFrom,
    DateTime? dateTo,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (metricType != null) queryParams['metric_type'] = metricType;
      if (dateFrom != null) queryParams['date_from'] = dateFrom.toIso8601String();
      if (dateTo != null) queryParams['date_to'] = dateTo.toIso8601String();
      
      final uri = Uri.parse('$_baseUrl/$animalId/production').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final records = (data['production_records'] as List?)
            ?.map((json) => AnimalProductionRecord.fromJson(json as Map<String, dynamic>))
            .toList() ?? [];
        return records;
      } else {
        throw Exception('Failed to load production records: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading production records: $e');
    }
  }
  
  /// Record production for an animal
  static Future<AnimalProductionRecord> addProductionRecord(
    int animalId, {
    required DateTime date,
    required String metricType,
    required double quantity,
    required String unit,
    String? qualityGrade,
    String? notes,
  }) async {
    try {
      final body = {
        'date': date.toIso8601String().split('T')[0],
        'metric_type': metricType,
        'quantity': quantity,
        'unit': unit,
        if (qualityGrade != null) 'quality_grade': qualityGrade,
        if (notes != null) 'notes': notes,
      };
      
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/$animalId/production'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 201) {
        return AnimalProductionRecord.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to add production record: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding production record: $e');
    }
  }
  
  /// Get production statistics for an animal
  static Future<Map<String, dynamic>> getProductionStats(
    int animalId, {
    int period = 30,  // 30, 60, 90 days
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/$animalId/production/stats').replace(queryParameters: {'period': period.toString()});
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load production stats: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading production stats: $e');
    }
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // REPRODUCTION RECORDS
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get reproduction records for an animal
  static Future<List<AnimalReproductionRecord>> getReproductionRecords(
    int animalId,
  ) async {
    try {
      final uri = Uri.parse('$_baseUrl/$animalId/reproduction');
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final records = (data['reproduction_records'] as List?)
            ?.map((json) => AnimalReproductionRecord.fromJson(json as Map<String, dynamic>))
            .toList() ?? [];
        return records;
      } else {
        throw Exception('Failed to load reproduction records: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading reproduction records: $e');
    }
  }
  
  /// Log a reproduction event
  static Future<AnimalReproductionRecord> addReproductionRecord(
    int animalId, {
    required String eventType,
    required DateTime eventDate,
    int? partnerAnimalId,
    String? partnerName,
    DateTime? expectedDeliveryDate,
    DateTime? actualDeliveryDate,
    int? numberOfOffspring,
    String? offspringGender,
    String? offspringHealth,
    String? notes,
  }) async {
    try {
      final body = {
        'event_type': eventType,
        'event_date': eventDate.toIso8601String().split('T')[0],
        if (partnerAnimalId != null) 'partner_animal_id': partnerAnimalId,
        if (partnerName != null) 'partner_name': partnerName,
        if (expectedDeliveryDate != null)
          'expected_delivery_date': expectedDeliveryDate.toIso8601String().split('T')[0],
        if (actualDeliveryDate != null)
          'actual_delivery_date': actualDeliveryDate.toIso8601String().split('T')[0],
        if (numberOfOffspring != null) 'number_of_offspring': numberOfOffspring,
        if (offspringGender != null) 'offspring_gender': offspringGender,
        if (offspringHealth != null) 'offspring_health': offspringHealth,
        if (notes != null) 'notes': notes,
      };
      
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/$animalId/reproduction'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 201) {
        return AnimalReproductionRecord.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to add reproduction record: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error adding reproduction record: $e');
    }
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // CARE REMINDERS
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get care reminders for an animal
  static Future<List<AnimalCareReminder>> getCareReminders(
    int animalId, {
    bool? isCompleted,
    String? tag,
    String? priority,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (isCompleted != null) queryParams['is_completed'] = isCompleted.toString();
      if (tag != null) queryParams['tag'] = tag;
      if (priority != null) queryParams['priority'] = priority;
      
      final uri = Uri.parse('$_baseUrl/$animalId/reminders').replace(queryParameters: queryParams.isNotEmpty ? queryParams : null);
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reminders = (data['reminders'] as List?)
            ?.map((json) => AnimalCareReminder.fromJson(json as Map<String, dynamic>))
            .toList() ?? [];
        return reminders;
      } else {
        throw Exception('Failed to load care reminders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading care reminders: $e');
    }
  }
  
  /// Get all upcoming care reminders across all animals
  static Future<List<AnimalCareReminder>> getUpcomingReminders({
    int limit = 50,
  }) async {
    try {
      final uri = Uri.parse('$_baseUrl/reminders/upcoming').replace(queryParameters: {'limit': limit.toString()});
      final headers = await _getAuthHeaders();
      final response = await http.get(uri, headers: headers);
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final reminders = (data['reminders'] as List?)
            ?.map((json) => AnimalCareReminder.fromJson(json as Map<String, dynamic>))
            .toList() ?? [];
        return reminders;
      } else {
        throw Exception('Failed to load upcoming reminders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error loading upcoming reminders: $e');
    }
  }
  
  /// Create a care reminder
  static Future<AnimalCareReminder> createReminder(
    int animalId, {
    required String title,
    required DateTime dueDate,
    String? description,
    String? tag,
    bool isRecurring = false,
    String? recurrenceInterval,
    String priority = 'normal',
    String? notes,
  }) async {
    try {
      final body = {
        'title': title,
        'due_date': dueDate.toIso8601String().split('T')[0],
        if (description != null) 'description': description,
        if (tag != null) 'tag': tag,
        'is_recurring': isRecurring,
        if (recurrenceInterval != null) 'recurrence_interval': recurrenceInterval,
        'priority': priority,
        if (notes != null) 'notes': notes,
      };
      
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$_baseUrl/$animalId/reminders'),
        headers: headers,
        body: jsonEncode(body),
      );
      
      if (response.statusCode == 201) {
        return AnimalCareReminder.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to create reminder: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error creating reminder: $e');
    }
  }
  
  /// Mark a reminder as complete
  static Future<AnimalCareReminder> completeReminder(int reminderId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$_baseUrl/reminders/$reminderId'),
        headers: headers,
        body: jsonEncode({'is_completed': true}),
      );
      
      if (response.statusCode == 200) {
        return AnimalCareReminder.fromJson(jsonDecode(response.body) as Map<String, dynamic>);
      } else {
        throw Exception('Failed to complete reminder: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error completing reminder: $e');
    }
  }
  
  /// Delete a reminder
  static Future<void> deleteReminder(int reminderId) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(Uri.parse('$_baseUrl/reminders/$reminderId'), headers: headers);
      
      if (response.statusCode != 204) {
        throw Exception('Failed to delete reminder: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error deleting reminder: $e');
    }
  }
}
