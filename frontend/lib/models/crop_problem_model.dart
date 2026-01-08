class CropProblem {
  final int id;
  final int cropId;
  final int farmId;
  final int userId;
  final String problemType;
  final String? description;
  final String? photoUrl;
  final String severity;
  final String status;
  final String? treatmentNotes;
  final DateTime createdAt;
  final DateTime updatedAt;

  CropProblem({
    required this.id,
    required this.cropId,
    required this.farmId,
    required this.userId,
    required this.problemType,
    this.description,
    this.photoUrl,
    this.severity = 'medium',
    this.status = 'reported',
    this.treatmentNotes,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CropProblem.fromJson(Map<String, dynamic> json) {
    return CropProblem(
      id: json['id'] as int,
      cropId: json['crop_id'] as int,
      farmId: json['farm_id'] as int,
      userId: json['user_id'] as int,
      problemType: json['problem_type'] as String,
      description: json['description'] as String?,
      photoUrl: json['photo_url'] as String?,
      severity: json['severity'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'reported',
      treatmentNotes: json['treatment_notes'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'crop_id': cropId,
    'farm_id': farmId,
    'user_id': userId,
    'problem_type': problemType,
    'description': description,
    'photo_url': photoUrl,
    'severity': severity,
    'status': status,
    'treatment_notes': treatmentNotes,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };

  String get problemTypeLabel {
    const labels = {
      'yellowing': '🟡 Jaunissement des feuilles',
      'leaf_holes': '🕳️ Feuilles trouées',
      'poor_yield': '📉 Mauvais rendement',
      'rot': '🌀 Pourriture',
      'pest': '🐛 Ravageurs',
      'disease': '🦠 Maladie',
      'wilting': '🥀 Flétrissement',
      'spotting': '⚫ Taches sur feuilles',
    };
    return labels[problemType] ?? problemType;
  }

  String get severityLabel {
    const labels = {
      'low': 'Faible',
      'medium': 'Moyen',
      'high': 'Élevé',
    };
    return labels[severity] ?? severity;
  }

  String get statusLabel {
    const labels = {
      'reported': 'Signalé',
      'identified': 'Identifié',
      'treated': 'Traité',
      'resolved': 'Résolu',
    };
    return labels[status] ?? status;
  }
}
