/// 🎯 Modèle pour les interactions sociales (likes, commentaires, partages)

class PostLike {
  final int id;
  final int postId;
  final int userId;
  final DateTime createdAt;

  PostLike({
    required this.id,
    required this.postId,
    required this.userId,
    required this.createdAt,
  });

  factory PostLike.fromJson(Map<String, dynamic> json) {
    return PostLike(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      userId: json['user_id'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'post_id': postId,
    'user_id': userId,
    'created_at': createdAt.toIso8601String(),
  };
}

class PostComment {
  final int id;
  final int postId;
  final int userId;
  final String userName;
  final String userAvatar;
  final String content;
  final int likesCount;
  final DateTime createdAt;

  PostComment({
    required this.id,
    required this.postId,
    required this.userId,
    required this.userName,
    required this.userAvatar,
    required this.content,
    required this.likesCount,
    required this.createdAt,
  });

  factory PostComment.fromJson(Map<String, dynamic> json) {
    return PostComment(
      id: json['id'] as int,
      postId: json['post_id'] as int,
      userId: json['user_id'] as int,
      userName: json['user_name'] as String? ?? 'Utilisateur',
      userAvatar: json['user_avatar'] as String? ?? '',
      content: json['content'] as String,
      likesCount: json['likes_count'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'post_id': postId,
    'user_id': userId,
    'user_name': userName,
    'user_avatar': userAvatar,
    'content': content,
    'likes_count': likesCount,
    'created_at': createdAt.toIso8601String(),
  };
}

class PostEngagement {
  final int postId;
  final int likesCount;
  final int commentsCount;
  final int sharesCount;
  final bool likedByUser;
  final List<PostComment> comments;

  PostEngagement({
    required this.postId,
    required this.likesCount,
    required this.commentsCount,
    required this.sharesCount,
    required this.likedByUser,
    required this.comments,
  });

  factory PostEngagement.fromJson(Map<String, dynamic> json) {
    return PostEngagement(
      postId: json['post_id'] as int,
      likesCount: json['likes_count'] as int? ?? 0,
      commentsCount: json['comments_count'] as int? ?? 0,
      sharesCount: json['shares_count'] as int? ?? 0,
      likedByUser: json['liked_by_user'] as bool? ?? false,
      comments: (json['comments'] as List<dynamic>?)
          ?.map((e) => PostComment.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
    );
  }

  Map<String, dynamic> toJson() => {
    'post_id': postId,
    'likes_count': likesCount,
    'comments_count': commentsCount,
    'shares_count': sharesCount,
    'liked_by_user': likedByUser,
    'comments': comments.map((e) => e.toJson()).toList(),
  };
}

class FarmNetwork {
  final int userId;
  final int followersCount;
  final int followingCount;
  final List<int> followingUserIds;
  final bool followedByUser;

  FarmNetwork({
    required this.userId,
    required this.followersCount,
    required this.followingCount,
    required this.followingUserIds,
    required this.followedByUser,
  });

  factory FarmNetwork.fromJson(Map<String, dynamic> json) {
    return FarmNetwork(
      userId: json['user_id'] as int,
      followersCount: json['followers_count'] as int? ?? 0,
      followingCount: json['following_count'] as int? ?? 0,
      followingUserIds: (json['following_user_ids'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList() ?? [],
      followedByUser: json['followed_by_user'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
    'user_id': userId,
    'followers_count': followersCount,
    'following_count': followingCount,
    'following_user_ids': followingUserIds,
    'followed_by_user': followedByUser,
  };
}
