import 'dart:convert';

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
  final String? imageUrl;
  // Géométrie : liste de coordonnées [lat, lon]
  final List<List<double>>? coordinates;

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
    this.imageUrl,
    this.coordinates,
  });

  factory Crop.fromJson(Map<String, dynamic> json) {
    List<List<double>>? coords;
    if (json['coordinates'] != null) {
      if (json['coordinates'] is String) {
        // Si c'est un string JSON, parser
        try {
          final parsed = json['coordinates'] as String;
          final List<dynamic> decoded = jsonDecode(parsed);
          coords = decoded
              .map((point) => [point[0] as double, point[1] as double])
              .toList()
              .cast<List<double>>();
        } catch (_) {
          coords = null;
        }
      } else if (json['coordinates'] is List) {
        // Si c'est déjà une liste
        coords = (json['coordinates'] as List)
            .map((point) {
              if (point is List && point.length >= 2) {
                return [point[0] as double, point[1] as double];
              }
              return <double>[];
            })
            .where((p) => p.isNotEmpty)
            .toList()
            .cast<List<double>>();
      }
    }

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
      imageUrl: json['image_url'] as String?,
      coordinates: coords,
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
      'image_url': imageUrl,
      'coordinates': coordinates,
    };
  }

  // Helper : obtenir le centre du polygone (centroïde simple)
  List<double>? getCenter() {
    if (coordinates == null || coordinates!.isEmpty) return null;
    
    double sumLat = 0, sumLon = 0;
    for (final point in coordinates!) {
      sumLat += point[0];
      sumLon += point[1];
    }
    return [sumLat / coordinates!.length, sumLon / coordinates!.length];
  }

  // Générer un polygone fictif si pas de coordonnées (pour démo)
  List<List<double>> getOrGenerateCoordinates() {
    if (coordinates != null && coordinates!.isNotEmpty) {
      return coordinates!;
    }
    // Générer un carré fictif pour la démo (centre aléatoire)
    final seed = id.toString().hashCode;
    final baseLat = 14.0 + (seed % 5) / 100;
    final baseLon = -16.0 + (seed % 5) / 100;
    
    return [
      [baseLat, baseLon],
      [baseLat + 0.01, baseLon],
      [baseLat + 0.01, baseLon + 0.01],
      [baseLat, baseLon + 0.01],
    ];
  }
}
