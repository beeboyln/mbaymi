/// Animal Management Models for individual livestock tracking
library;
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────────────
// ANIMAL MODEL
// ─────────────────────────────────────────────────────────────────────────────
class Animal {
  final int id;
  final int userId;
  final int? farmId;
  
  final String name;
  final String? tagId;
  final String species;  // cattle, goat, sheep, pig, poultry
  final String? breed;
  final String gender;  // male, female
  final DateTime dateOfBirth;
  
  final double? weightKg;
  final double? heightCm;
  final String? colorMarkings;
  
  final String healthStatus;  // healthy, sick, treated, vaccinated, isolated
  final String? healthNotes;
  final DateTime? lastCheckupDate;
  
  final String reproductiveStatus;  // not_breeding, in_cycle, pregnant, lactating, weaned
  
  final DateTime? acquisitionDate;
  final double? acquisitionCost;
  final String? location;
  final bool isActive;
  
  final String? photoUrl;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  Animal({
    required this.id,
    required this.userId,
    this.farmId,
    required this.name,
    this.tagId,
    required this.species,
    this.breed,
    required this.gender,
    required this.dateOfBirth,
    this.weightKg,
    this.heightCm,
    this.colorMarkings,
    this.healthStatus = 'healthy',
    this.healthNotes,
    this.lastCheckupDate,
    this.reproductiveStatus = 'not_breeding',
    this.acquisitionDate,
    this.acquisitionCost,
    this.location,
    this.isActive = true,
    this.photoUrl,
    required this.createdAt,
    required this.updatedAt,
  });
  
  int get ageInMonths {
    final now = DateTime.now();
    return (now.year - dateOfBirth.year) * 12 + (now.month - dateOfBirth.month);
  }
  
  int get ageInYears => ageInMonths ~/ 12;
  
  factory Animal.fromJson(Map<String, dynamic> json) {
    return Animal(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      farmId: json['farm_id'] as int?,
      name: json['name'] as String,
      tagId: json['tag_id'] as String?,
      species: json['species'] as String,
      breed: json['breed'] as String?,
      gender: json['gender'] as String,
      dateOfBirth: DateTime.parse(json['date_of_birth'] as String),
      weightKg: (json['weight_kg'] as num?)?.toDouble(),
      heightCm: (json['height_cm'] as num?)?.toDouble(),
      colorMarkings: json['color_markings'] as String?,
      healthStatus: json['health_status'] as String? ?? 'healthy',
      healthNotes: json['health_notes'] as String?,
      lastCheckupDate: json['last_checkup_date'] != null
          ? DateTime.parse(json['last_checkup_date'] as String)
          : null,
      reproductiveStatus: json['reproductive_status'] as String? ?? 'not_breeding',
      acquisitionDate: json['acquisition_date'] != null
          ? DateTime.parse(json['acquisition_date'] as String)
          : null,
      acquisitionCost: (json['acquisition_cost'] as num?)?.toDouble(),
      location: json['location'] as String?,
      isActive: json['is_active'] as bool? ?? true,
      photoUrl: json['photo_url'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'tag_id': tagId,
      'species': species,
      'breed': breed,
      'gender': gender,
      'date_of_birth': dateOfBirth.toIso8601String().split('T')[0],
      'weight_kg': weightKg,
      'height_cm': heightCm,
      'color_markings': colorMarkings,
      'health_status': healthStatus,
      'health_notes': healthNotes,
      'reproductive_status': reproductiveStatus,
      'acquisition_date': acquisitionDate?.toIso8601String().split('T')[0],
      'acquisition_cost': acquisitionCost,
      'location': location,
      'photo_url': photoUrl,
      'farm_id': farmId,
    };
  }
  
  Animal copyWith({
    String? name,
    String? breed,
    double? weightKg,
    String? healthStatus,
    String? location,
    String? photoUrl,
  }) {
    return Animal(
      id: id,
      userId: userId,
      farmId: farmId,
      name: name ?? this.name,
      tagId: tagId,
      species: species,
      breed: breed ?? this.breed,
      gender: gender,
      dateOfBirth: dateOfBirth,
      weightKg: weightKg ?? this.weightKg,
      heightCm: heightCm,
      colorMarkings: colorMarkings,
      healthStatus: healthStatus ?? this.healthStatus,
      healthNotes: healthNotes,
      lastCheckupDate: lastCheckupDate,
      reproductiveStatus: reproductiveStatus,
      acquisitionDate: acquisitionDate,
      acquisitionCost: acquisitionCost,
      location: location ?? this.location,
      isActive: isActive,
      photoUrl: photoUrl ?? this.photoUrl,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// HEALTH RECORD MODEL
// ─────────────────────────────────────────────────────────────────────────────
class AnimalHealthRecord {
  final int id;
  final int animalId;
  final int userId;
  
  final String recordType;  // vaccination, deworming, treatment, checkup, surgery
  final DateTime date;
  
  final String medicalName;
  final String? description;
  final String? dosage;
  final String? administeredBy;
  final double? cost;
  
  final DateTime? nextDueDate;
  final String? notes;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  AnimalHealthRecord({
    required this.id,
    required this.animalId,
    required this.userId,
    required this.recordType,
    required this.date,
    required this.medicalName,
    this.description,
    this.dosage,
    this.administeredBy,
    this.cost,
    this.nextDueDate,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory AnimalHealthRecord.fromJson(Map<String, dynamic> json) {
    return AnimalHealthRecord(
      id: json['id'] as int,
      animalId: json['animal_id'] as int,
      userId: json['user_id'] as int,
      recordType: json['record_type'] as String,
      date: DateTime.parse(json['date'] as String),
      medicalName: json['medical_name'] as String,
      description: json['description'] as String?,
      dosage: json['dosage'] as String?,
      administeredBy: json['administered_by'] as String?,
      cost: (json['cost'] as num?)?.toDouble(),
      nextDueDate: json['next_due_date'] != null
          ? DateTime.parse(json['next_due_date'] as String)
          : null,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'record_type': recordType,
      'date': date.toIso8601String().split('T')[0],
      'medical_name': medicalName,
      'description': description,
      'dosage': dosage,
      'administered_by': administeredBy,
      'cost': cost,
      'next_due_date': nextDueDate?.toIso8601String().split('T')[0],
      'notes': notes,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PRODUCTION RECORD MODEL
// ─────────────────────────────────────────────────────────────────────────────
class AnimalProductionRecord {
  final int id;
  final int animalId;
  final int userId;
  
  final DateTime date;
  
  final String metricType;  // milk, eggs, wool, meat
  final double quantity;
  final String unit;  // liters, number, kg
  
  final String? qualityGrade;
  final String? notes;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  AnimalProductionRecord({
    required this.id,
    required this.animalId,
    required this.userId,
    required this.date,
    required this.metricType,
    required this.quantity,
    required this.unit,
    this.qualityGrade,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory AnimalProductionRecord.fromJson(Map<String, dynamic> json) {
    return AnimalProductionRecord(
      id: json['id'] as int,
      animalId: json['animal_id'] as int,
      userId: json['user_id'] as int,
      date: DateTime.parse(json['date'] as String),
      metricType: json['metric_type'] as String,
      quantity: (json['quantity'] as num).toDouble(),
      unit: json['unit'] as String,
      qualityGrade: json['quality_grade'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T')[0],
      'metric_type': metricType,
      'quantity': quantity,
      'unit': unit,
      'quality_grade': qualityGrade,
      'notes': notes,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REPRODUCTION RECORD MODEL
// ─────────────────────────────────────────────────────────────────────────────
class AnimalReproductionRecord {
  final int id;
  final int animalId;
  final int userId;
  
  final String eventType;  // heat, mating, pregnancy, birth
  final DateTime eventDate;
  
  final int? partnerAnimalId;
  final String? partnerName;
  
  final DateTime? expectedDeliveryDate;
  final DateTime? actualDeliveryDate;
  final int? numberOfOffspring;
  final String? offspringGender;
  final String? offspringHealth;
  
  final String? notes;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  AnimalReproductionRecord({
    required this.id,
    required this.animalId,
    required this.userId,
    required this.eventType,
    required this.eventDate,
    this.partnerAnimalId,
    this.partnerName,
    this.expectedDeliveryDate,
    this.actualDeliveryDate,
    this.numberOfOffspring,
    this.offspringGender,
    this.offspringHealth,
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  
  factory AnimalReproductionRecord.fromJson(Map<String, dynamic> json) {
    return AnimalReproductionRecord(
      id: json['id'] as int,
      animalId: json['animal_id'] as int,
      userId: json['user_id'] as int,
      eventType: json['event_type'] as String,
      eventDate: DateTime.parse(json['event_date'] as String),
      partnerAnimalId: json['partner_animal_id'] as int?,
      partnerName: json['partner_name'] as String?,
      expectedDeliveryDate: json['expected_delivery_date'] != null
          ? DateTime.parse(json['expected_delivery_date'] as String)
          : null,
      actualDeliveryDate: json['actual_delivery_date'] != null
          ? DateTime.parse(json['actual_delivery_date'] as String)
          : null,
      numberOfOffspring: json['number_of_offspring'] as int?,
      offspringGender: json['offspring_gender'] as String?,
      offspringHealth: json['offspring_health'] as String?,
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'event_type': eventType,
      'event_date': eventDate.toIso8601String().split('T')[0],
      'partner_animal_id': partnerAnimalId,
      'partner_name': partnerName,
      'expected_delivery_date':
          expectedDeliveryDate?.toIso8601String().split('T')[0],
      'actual_delivery_date':
          actualDeliveryDate?.toIso8601String().split('T')[0],
      'number_of_offspring': numberOfOffspring,
      'offspring_gender': offspringGender,
      'offspring_health': offspringHealth,
      'notes': notes,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CARE REMINDER MODEL
// ─────────────────────────────────────────────────────────────────────────────
class AnimalCareReminder {
  final int id;
  final int animalId;
  final int userId;
  
  final String title;
  final String? description;
  final String? tag;  // health, reproduction, maintenance, nutrition
  
  final DateTime dueDate;
  final DateTime? completedDate;
  final bool isCompleted;
  
  final bool isRecurring;
  final String? recurrenceInterval;  // daily, weekly, monthly, yearly
  
  final String priority;  // low, normal, high, critical
  
  final String? notes;
  
  final DateTime createdAt;
  final DateTime updatedAt;
  
  AnimalCareReminder({
    required this.id,
    required this.animalId,
    required this.userId,
    required this.title,
    this.description,
    this.tag,
    required this.dueDate,
    this.completedDate,
    this.isCompleted = false,
    this.isRecurring = false,
    this.recurrenceInterval,
    this.priority = 'normal',
    this.notes,
    required this.createdAt,
    required this.updatedAt,
  });
  
  bool get isOverdue =>
      !isCompleted && dueDate.isBefore(DateTime.now()) &&
      dueDate.difference(DateTime.now()).inDays < 0;
  
  bool get isDueToday =>
      !isCompleted &&
      dueDate.year == DateTime.now().year &&
      dueDate.month == DateTime.now().month &&
      dueDate.day == DateTime.now().day;
  
  int get daysUntilDue =>
      dueDate.difference(DateTime.now()).inDays;
  
  factory AnimalCareReminder.fromJson(Map<String, dynamic> json) {
    return AnimalCareReminder(
      id: json['id'] as int,
      animalId: json['animal_id'] as int,
      userId: json['user_id'] as int,
      title: json['title'] as String,
      description: json['description'] as String?,
      tag: json['tag'] as String?,
      dueDate: DateTime.parse(json['due_date'] as String),
      completedDate: json['completed_date'] != null
          ? DateTime.parse(json['completed_date'] as String)
          : null,
      isCompleted: json['is_completed'] as bool? ?? false,
      isRecurring: json['is_recurring'] as bool? ?? false,
      recurrenceInterval: json['recurrence_interval'] as String?,
      priority: json['priority'] as String? ?? 'normal',
      notes: json['notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }
  
  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'description': description,
      'tag': tag,
      'due_date': dueDate.toIso8601String().split('T')[0],
      'is_recurring': isRecurring,
      'recurrence_interval': recurrenceInterval,
      'priority': priority,
      'notes': notes,
    };
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SUMMARY MODELS
// ─────────────────────────────────────────────────────────────────────────────
class AnimalHealthSummary {
  final int animalId;
  final String animalName;
  final String currentHealthStatus;
  final int totalHealthRecords;
  final DateTime? lastCheckupDate;
  final int? daysSinceCheckup;
  final int upcomingCareCount;
  final int overdueCareCount;
  final int recentVaccinations;
  
  AnimalHealthSummary({
    required this.animalId,
    required this.animalName,
    required this.currentHealthStatus,
    required this.totalHealthRecords,
    this.lastCheckupDate,
    this.daysSinceCheckup,
    required this.upcomingCareCount,
    required this.overdueCareCount,
    required this.recentVaccinations,
  });
  
  factory AnimalHealthSummary.fromJson(Map<String, dynamic> json) {
    return AnimalHealthSummary(
      animalId: json['animal_id'] as int,
      animalName: json['animal_name'] as String,
      currentHealthStatus: json['current_health_status'] as String,
      totalHealthRecords: json['total_health_records'] as int,
      lastCheckupDate: json['last_checkup_date'] != null
          ? DateTime.parse(json['last_checkup_date'] as String)
          : null,
      daysSinceCheckup: json['days_since_checkup'] as int?,
      upcomingCareCount: json['upcoming_care_count'] as int,
      overdueCareCount: json['overdue_care_count'] as int,
      recentVaccinations: json['recent_vaccinations'] as int,
    );
  }
}
