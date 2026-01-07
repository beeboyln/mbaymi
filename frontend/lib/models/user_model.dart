class User {
  final int id;
  final String name;
  final String email;
  final String phone;
  final String role; // farmer, livestock_breeder, buyer, seller
  final String region;
  final String? village;
  final DateTime createdAt;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.region,
    this.village,
    required this.createdAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      role: json['role'] as String,
      region: json['region'] as String,
      village: json['village'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phone': phone,
      'role': role,
      'region': region,
      'village': village,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
