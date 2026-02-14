class VeterinarianProfile {
  final int id;
  final int userId;
  final String specialty;
  final String zone;
  final int distanceMax;
  final String bio;
  final int experienceYears;
  final String contactPreference;
  final String verificationStatus;
  final bool isVerified;
  final double? rating;
  final int? consultationCount;
  final DateTime createdAt;
  final DateTime updatedAt;

  var email;

  VeterinarianProfile({
    required this.id,
    required this.userId,
    required this.specialty,
    required this.zone,
    required this.distanceMax,
    required this.bio,
    required this.experienceYears,
    required this.contactPreference,
    required this.verificationStatus,
    required this.isVerified,
    this.rating,
    this.consultationCount,
    required this.createdAt,
    required this.updatedAt,
  });

  factory VeterinarianProfile.fromJson(Map<String, dynamic> json) {
    return VeterinarianProfile(
      id: json['id'] ?? 0,
      userId: json['user_id'] ?? 0,
      specialty: json['specialty'] ?? '',
      zone: json['zone'] ?? '',
      distanceMax: json['distance_max'] ?? 0,
      bio: json['bio'] ?? '',
      experienceYears: json['experience_years'] ?? 0,
      contactPreference: json['contact_preference'] ?? 'whatsapp',
      verificationStatus: json['verification_status'] ?? 'pending',
      isVerified: json['is_verified'] ?? false,
      rating: (json['average_rating'] as num?)?.toDouble(),
      consultationCount: json['total_consultations'],
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'])
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'])
          : DateTime.now(),
    );
  }

  get name => null;

  get phone => null;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'specialty': specialty,
      'zone': zone,
      'distance_max': distanceMax,
      'bio': bio,
      'experience_years': experienceYears,
      'contact_preference': contactPreference,
      'verification_status': verificationStatus,
      'is_verified': isVerified,
      'average_rating': rating,
      'total_consultations': consultationCount,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }
}
