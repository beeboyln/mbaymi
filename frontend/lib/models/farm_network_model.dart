class FarmProfile {
  final int id;
  final int farmId;
  final String farmName;
  final String? farmLocation;
  final String? ownerName;
  final String? description;
  final List<String> specialties;
  final bool isPublic;
  final int totalFollowers;
  final DateTime createdAt;

  FarmProfile({
    required this.id,
    required this.farmId,
    required this.farmName,
    this.farmLocation,
    this.ownerName,
    this.description,
    this.specialties = const [],
    this.isPublic = true,
    this.totalFollowers = 0,
    required this.createdAt,
  });

  factory FarmProfile.fromJson(Map<String, dynamic> json) {
    return FarmProfile(
      id: json['id'] as int,
      farmId: json['farm_id'] as int,
      farmName: json['farm_name'] as String,
      farmLocation: json['farm_location'] as String?,
      ownerName: json['owner_name'] as String?,
      description: json['description'] as String?,
      specialties: _parseSpecialties(json['specialties']),
      isPublic: json['is_public'] as bool? ?? true,
      totalFollowers: json['total_followers'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  static List<String> _parseSpecialties(dynamic spec) {
    if (spec is List) {
      return List<String>.from(spec);
    } else if (spec is String) {
      return spec.split(',').map((s) => s.trim()).toList();
    }
    return [];
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'farm_id': farmId,
    'farm_name': farmName,
    'farm_location': farmLocation,
    'owner_name': ownerName,
    'description': description,
    'specialties': specialties,
    'is_public': isPublic,
    'total_followers': totalFollowers,
    'created_at': createdAt.toIso8601String(),
  };
}

class FarmPost {
  final int id;
  final int farmId;
  final String? farmName;
  final String? ownerName;
  final String title;
  final String? description;
  final String? photoUrl;
  final String postType;
  final DateTime createdAt;

  FarmPost({
    required this.id,
    required this.farmId,
    this.farmName,
    this.ownerName,
    required this.title,
    this.description,
    this.photoUrl,
    this.postType = 'crop_update',
    required this.createdAt,
  });

  factory FarmPost.fromJson(Map<String, dynamic> json) {
    return FarmPost(
      id: json['id'] as int,
      farmId: json['farm_id'] as int,
      farmName: json['farm_name'] as String?,
      ownerName: json['owner_name'] as String?,
      title: json['title'] as String,
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      postType: json['post_type'] as String? ?? 'crop_update',
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  String get postTypeLabel {
    const labels = {
      'crop_update': '🌱 Mise à jour de culture',
      'harvest_result': '🌾 Résultat de récolte',
      'problem_report': '🚨 Signalement de problème',
      'tip': '💡 Conseil/Astuce',
    };
    return labels[postType] ?? postType;
  }
}

class FarmFollowing {
  final int id;
  final int farmId;
  final String farmName;
  final String? farmLocation;
  final DateTime createdAt;

  FarmFollowing({
    required this.id,
    required this.farmId,
    required this.farmName,
    this.farmLocation,
    required this.createdAt,
  });

  factory FarmFollowing.fromJson(Map<String, dynamic> json) {
    return FarmFollowing(
      id: json['id'] as int? ?? 0,
      farmId: json['farm_id'] as int,
      farmName: json['farm_name'] as String,
      farmLocation: json['location'] as String?,
      createdAt: DateTime.now(),
    );
  }
}
