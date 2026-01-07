class Farm {
  final int id;
  final int userId;
  final String name;
  final String location;
  final double? sizeHectares;
  final String? soilType;
  final DateTime createdAt;

  Farm({
    required this.id,
    required this.userId,
    required this.name,
    required this.location,
    this.sizeHectares,
    this.soilType,
    required this.createdAt,
  });

  factory Farm.fromJson(Map<String, dynamic> json) {
    return Farm(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      name: json['name'] as String,
      location: json['location'] as String,
      sizeHectares: json['size_hectares'] as double?,
      soilType: json['soil_type'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'location': location,
      'size_hectares': sizeHectares,
      'soil_type': soilType,
    };
  }
}

class Crop {
  final int id;
  final int farmId;
  final String cropName;
  final DateTime? plantedDate;
  final DateTime? expectedHarvestDate;
  final double? quantityPlanted;
  final double? expectedYield;
  final String status; // growing, harvested, failed
  final String? notes;

  Crop({
    required this.id,
    required this.farmId,
    required this.cropName,
    this.plantedDate,
    this.expectedHarvestDate,
    this.quantityPlanted,
    this.expectedYield,
    this.status = 'growing',
    this.notes,
  });

  factory Crop.fromJson(Map<String, dynamic> json) {
    return Crop(
      id: json['id'] as int,
      farmId: json['farm_id'] as int,
      cropName: json['crop_name'] as String,
      plantedDate: json['planted_date'] != null 
          ? DateTime.parse(json['planted_date'] as String)
          : null,
      expectedHarvestDate: json['expected_harvest_date'] != null
          ? DateTime.parse(json['expected_harvest_date'] as String)
          : null,
      quantityPlanted: json['quantity_planted'] as double?,
      expectedYield: json['expected_yield'] as double?,
      status: json['status'] as String? ?? 'growing',
      notes: json['notes'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'crop_name': cropName,
      'planted_date': plantedDate?.toIso8601String(),
      'expected_harvest_date': expectedHarvestDate?.toIso8601String(),
      'quantity_planted': quantityPlanted,
      'expected_yield': expectedYield,
      'status': status,
      'notes': notes,
    };
  }
}
