/// 🔔 Modèle de notification
class NotificationModel {
  final int id;
  final int userId;
  final String type; // 'follow', 'comment', 'like', etc.
  final String title;
  final String description;
  final String? actionUrl;
  final String? actorName;
  final String? actorImage;
  final int? actorId; // ID de l'utilisateur qui a déclenché la notification
  final bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    this.actionUrl,
    this.actorName,
    this.actorImage,
    this.actorId,
    required this.isRead,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      actionUrl: json['action_url'] as String?,
      actorName: json['actor_name'] as String?,
      actorImage: json['actor_image'] as String?,
      actorId: json['actor_id'] as int?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'description': description,
      'action_url': actionUrl,
      'actor_name': actorName,
      'actor_image': actorImage,
      'actor_id': actorId,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }

  // Copier avec modifications
  NotificationModel copyWith({
    int? id,
    int? userId,
    String? type,
    String? title,
    String? description,
    String? actionUrl,
    String? actorName,
    String? actorImage,
    int? actorId,
    bool? isRead,
    DateTime? createdAt,
  }) {
    return NotificationModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      actionUrl: actionUrl ?? this.actionUrl,
      actorName: actorName ?? this.actorName,
      actorImage: actorImage ?? this.actorImage,
      actorId: actorId ?? this.actorId,
      isRead: isRead ?? this.isRead,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
