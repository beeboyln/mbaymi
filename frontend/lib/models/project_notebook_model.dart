import 'package:intl/intl.dart';
import 'package:uuid/uuid.dart';

/// Modèle pour un cahier de projet agricole
class ProjectNotebook {
  final String id;
  final String title;
  final String description;
  final String farmId; // Lien avec la ferme
  final String createdBy; // ID de l'utilisateur
  
  // Contenu et métadonnées
  final List<NotebookSection> sections;
  final List<String> tags;
  final String category; // 'culture', 'elevage', 'general', etc.
  
  // Dates
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Partage et accès
  final List<String> sharedWith; // IDs des utilisateurs avec accès
  final bool isPublic;
  final List<NoteComment> comments;
  
  // Versioning
  final List<NoteVersion> versions;

  ProjectNotebook({
    String? id,
    required this.title,
    required this.description,
    required this.farmId,
    required this.createdBy,
    this.sections = const [],
    this.tags = const [],
    this.category = 'general',
    DateTime? createdAt,
    DateTime? updatedAt,
    this.sharedWith = const [],
    this.isPublic = false,
    this.comments = const [],
    this.versions = const [],
  })  : id = id ?? 'local_${const Uuid().v4()}',
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  // Copier et modifier
  ProjectNotebook copyWith({
    String? title,
    String? description,
    List<NotebookSection>? sections,
    List<String>? tags,
    String? category,
    List<String>? sharedWith,
    bool? isPublic,
    List<NoteComment>? comments,
    List<NoteVersion>? versions,
  }) {
    return ProjectNotebook(
      id: id,
      title: title ?? this.title,
      description: description ?? this.description,
      farmId: farmId,
      createdBy: createdBy,
      sections: sections ?? this.sections,
      tags: tags ?? this.tags,
      category: category ?? this.category,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
      sharedWith: sharedWith ?? this.sharedWith,
      isPublic: isPublic ?? this.isPublic,
      comments: comments ?? this.comments,
      versions: versions ?? this.versions,
    );
  }

  // Convertir en JSON
  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'description': description,
    'farmId': farmId,
    'createdBy': createdBy,
    'sections': sections.map((s) => s.toJson()).toList(),
    'tags': tags,
    'category': category,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
    'sharedWith': sharedWith,
    'isPublic': isPublic,
    'comments': comments.map((c) => c.toJson()).toList(),
    'versions': versions.map((v) => v.toJson()).toList(),
  };

  // Créer depuis JSON
  factory ProjectNotebook.fromJson(Map<String, dynamic> json) {
    return ProjectNotebook(
      id: json['id'],
      title: json['title'],
      description: json['description'],
      farmId: json['farmId'],
      createdBy: json['createdBy'],
      sections: List<NotebookSection>.from(
        (json['sections'] as List? ?? []).map((x) => NotebookSection.fromJson(x)),
      ),
      tags: List<String>.from(json['tags'] ?? []),
      category: json['category'] ?? 'general',
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      sharedWith: List<String>.from(json['sharedWith'] ?? []),
      isPublic: json['isPublic'] ?? false,
      comments: List<NoteComment>.from(
        (json['comments'] as List? ?? []).map((x) => NoteComment.fromJson(x)),
      ),
      versions: List<NoteVersion>.from(
        (json['versions'] as List? ?? []).map((x) => NoteVersion.fromJson(x)),
      ),
    );
  }
}

/// Sections du cahier (pour organiser le contenu)
class NotebookSection {
  final String id;
  final String title;
  final List<NoteContent> contents;
  final int order;

  NotebookSection({
    String? id,
    required this.title,
    this.contents = const [],
    this.order = 0,
  }) : id = id ?? const Uuid().v4();

  NotebookSection copyWith({
    String? title,
    List<NoteContent>? contents,
    int? order,
  }) {
    return NotebookSection(
      id: id,
      title: title ?? this.title,
      contents: contents ?? this.contents,
      order: order ?? this.order,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'title': title,
    'contents': contents.map((c) => c.toJson()).toList(),
    'order': order,
  };

  factory NotebookSection.fromJson(Map<String, dynamic> json) {
    return NotebookSection(
      id: json['id'],
      title: json['title'],
      contents: List<NoteContent>.from(
        (json['contents'] as List? ?? []).map((x) => NoteContent.fromJson(x)),
      ),
      order: json['order'] ?? 0,
    );
  }
}

/// Contenu d'une note (texte riche, images, listes, etc.)
class NoteContent {
  final String id;
  final String type; // 'text', 'image', 'list', 'checklist', 'code', 'quote'
  final String content;
  final Map<String, dynamic> metadata; // Styles, couleurs, etc.
  final DateTime createdAt;
  final DateTime updatedAt;

  NoteContent({
    String? id,
    required this.type,
    required this.content,
    this.metadata = const {},
    DateTime? createdAt,
    DateTime? updatedAt,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now(),
        updatedAt = updatedAt ?? DateTime.now();

  NoteContent copyWith({
    String? content,
    Map<String, dynamic>? metadata,
  }) {
    return NoteContent(
      id: id,
      type: type,
      content: content ?? this.content,
      metadata: metadata ?? this.metadata,
      createdAt: createdAt,
      updatedAt: DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'content': content,
    'metadata': metadata,
    'createdAt': createdAt.toIso8601String(),
    'updatedAt': updatedAt.toIso8601String(),
  };

  factory NoteContent.fromJson(Map<String, dynamic> json) {
    return NoteContent(
      id: json['id'],
      type: json['type'],
      content: json['content'],
      metadata: json['metadata'] ?? {},
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
    );
  }
}

/// Commentaires sur le cahier
class NoteComment {
  final String id;
  final String userId;
  final String userName;
  final String text;
  final DateTime createdAt;
  final List<String> mentions; // @mentions

  NoteComment({
    String? id,
    required this.userId,
    required this.userName,
    required this.text,
    DateTime? createdAt,
    this.mentions = const [],
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'userId': userId,
    'userName': userName,
    'text': text,
    'createdAt': createdAt.toIso8601String(),
    'mentions': mentions,
  };

  factory NoteComment.fromJson(Map<String, dynamic> json) {
    return NoteComment(
      id: json['id'],
      userId: json['userId'],
      userName: json['userName'],
      text: json['text'],
      createdAt: DateTime.parse(json['createdAt']),
      mentions: List<String>.from(json['mentions'] ?? []),
    );
  }
}

/// Versioning - Garder l'historique des modifications
class NoteVersion {
  final String id;
  final String notebookId;
  final String title;
  final List<NotebookSection> sections;
  final DateTime createdAt;
  final String createdBy;
  final String changeDescription;

  NoteVersion({
    String? id,
    required this.notebookId,
    required this.title,
    required this.sections,
    DateTime? createdAt,
    required this.createdBy,
    required this.changeDescription,
  })  : id = id ?? const Uuid().v4(),
        createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toJson() => {
    'id': id,
    'notebookId': notebookId,
    'title': title,
    'sections': sections.map((s) => s.toJson()).toList(),
    'createdAt': createdAt.toIso8601String(),
    'createdBy': createdBy,
    'changeDescription': changeDescription,
  };

  factory NoteVersion.fromJson(Map<String, dynamic> json) {
    return NoteVersion(
      id: json['id'],
      notebookId: json['notebookId'],
      title: json['title'],
      sections: List<NotebookSection>.from(
        (json['sections'] as List? ?? []).map((x) => NotebookSection.fromJson(x)),
      ),
      createdAt: DateTime.parse(json['createdAt']),
      createdBy: json['createdBy'],
      changeDescription: json['changeDescription'],
    );
  }
}
