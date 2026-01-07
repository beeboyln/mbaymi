class Livestock {
  final int id;
  final int userId;
  final String animalType; // cattle, goat, sheep, poultry, pig
  final String? breed;
  final int quantity;
  final int? ageMonths;
  final double? weightKg;
  final String healthStatus; // healthy, sick, vaccinated
  final DateTime? lastVaccinationDate;
  final String? feedingType;
  final String? location;
  final String? notes;

  Livestock({
    required this.id,
    required this.userId,
    required this.animalType,
    this.breed,
    this.quantity = 1,
    this.ageMonths,
    this.weightKg,
    this.healthStatus = 'healthy',
    this.lastVaccinationDate,
    this.feedingType,
    this.location,
    this.notes,
  });

  factory Livestock.fromJson(Map<String, dynamic> json) {
    return Livestock(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      animalType: json['animal_type'] as String,
      breed: json['breed'] as String?,
      quantity: json['quantity'] as int? ?? 1,
      ageMonths: json['age_months'] as int?,
      weightKg: json['weight_kg'] as double?,
      healthStatus: json['health_status'] as String? ?? 'healthy',
      lastVaccinationDate: json['last_vaccination_date'] != null
          ? DateTime.parse(json['last_vaccination_date'] as String)
          : null,
      feedingType: json['feeding_type'] as String?,
      location: json['location'] as String?,
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'animal_type': animalType,
      'breed': breed,
      'quantity': quantity,
      'age_months': ageMonths,
      'weight_kg': weightKg,
      'health_status': healthStatus,
      'feeding_type': feedingType,
      'location': location,
      'notes': notes,
    };
  }
}
