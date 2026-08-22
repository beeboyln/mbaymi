import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/token_storage.dart';
import '../models/project_notebook_model.dart';

class NotebookService {
  static const String _notebooksKey = 'project_notebooks';
  static const String _versionsKey = 'note_versions_';

  final SharedPreferences _prefs;

  NotebookService(this._prefs);

  String get _baseUrl => ApiService.baseUrl;

  /// Get auth token from TokenStorage (not SharedPreferences!)
  Future<String?> _getTokenFromStorage() async {
    return await TokenStorage.getAccessToken();
  }

  /// Helper to build headers with token
  Map<String, String> _getHeadersWithToken(String? token) {
    return {
      'Content-Type': 'application/json',
      if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
    };
  }

  // ========== CRUD OPERATIONS ==========

  /// Créer un nouveau cahier
  Future<ProjectNotebook> createNotebook({
    required String title,
    required String description,
    required String farmId,
    required String userId,
    String category = 'general',
    List<String>? tags,
  }) async {
    final notebook = ProjectNotebook(
      title: title,
      description: description,
      farmId: farmId,
      createdBy: userId,
      category: category,
      tags: tags ?? [],
    );

    await saveNotebook(notebook);
    return notebook;
  }

  /// Sauvegarder un cahier (local + API)
  Future<void> saveNotebook(ProjectNotebook notebook) async {
    try {
      print('[NOTEBOOK] === SAVE START ===');
      print('[NOTEBOOK] ID: ${notebook.id}');
      print('[NOTEBOOK] Title: ${notebook.title}');
      print('[NOTEBOOK] FarmID: ${notebook.farmId}');
      
      // Récupérer le token depuis TokenStorage
      final token = await _getTokenFromStorage();
      print('[NOTEBOOK] Token: ${token != null ? token.substring(0, 20) + '...' : 'NULL'}');
      print('[NOTEBOOK] BaseURL: $_baseUrl');
      
      // Sauvegarder localement d'abord (plus rapide, offline-first)
      final notebooks = await getAllNotebooks();
      final index = notebooks.indexWhere((n) => n.id == notebook.id);

      if (index != -1) {
        notebooks[index] = notebook;
      } else {
        notebooks.add(notebook);
      }

      final jsonList = notebooks.map((n) => n.toJson()).toList();
      await _prefs.setString(_notebooksKey, jsonEncode(jsonList));
      print('[NOTEBOOK] ✅ LOCAL SAVED');

      // Ensuite, synchroniser avec l'API si token disponible
      if (token != null && token.isNotEmpty) {
        print('[NOTEBOOK] 🔄 API SYNC starting...');
        _syncWithApi(notebook, token).then((_) {
          print('[NOTEBOOK] ✅ API SYNC completed');
        }).catchError((e) {
          print('[NOTEBOOK] ❌ API SYNC failed: $e');
        });
      } else {
        print('[NOTEBOOK] ⚠️ NO TOKEN - skipping API sync');
      }
    } catch (e) {
      print('[NOTEBOOK] 💥 SAVE ERROR: $e');
      throw Exception('Erreur lors de la sauvegarde: $e');
    }
  }

  /// Synchroniser avec l'API (fire-and-forget, async)
  Future<void> _syncWithApi(ProjectNotebook notebook, String token) async {
    try {
      print('[SYNC] ═══════ API SYNC START ═══════');
      print('[SYNC] Notebook ID: ${notebook.id}');
      print('[SYNC] Notebook Title: ${notebook.title}');
      print('[SYNC] Notebook FarmID: ${notebook.farmId}');
      print('[SYNC] Token valid: ${token.isNotEmpty}');
      
      final headers = _getHeadersWithToken(token);
      print('[SYNC] Headers ready: ${headers.keys.toList()}');

      // Check if notebook exists on server (has integer ID)
      if (notebook.id.isEmpty || notebook.id.startsWith('local_')) {
        print('[SYNC] 📝 CREATE mode (new notebook)');
        final url = '$_baseUrl/notebooks';
        print('[SYNC] POST to: $url');
        print('[SYNC] Headers: $headers');
        
        // Create new notebook on API
        final response = await http.post(
          Uri.parse(url),
          headers: headers,
          body: jsonEncode({
            'title': notebook.title,
            'description': notebook.description,
            'category': notebook.category,
            'tags': notebook.tags,
            'is_public': notebook.isPublic,
            'sections': notebook.sections.map((s) => s.toJson()).toList(),
          }),
        ).timeout(const Duration(seconds: 10));

        print('[SYNC] Response: ${response.statusCode}');
        print('[SYNC] Body: ${response.body}');
        
        if (response.statusCode == 201 || response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final serverId = data['id'].toString();
          print('[SYNC] ✅ Created with ID: $serverId');
          
          // Update local notebook with server ID
          final updated = ProjectNotebook(
            id: serverId,
            title: notebook.title,
            description: notebook.description,
            farmId: notebook.farmId,
            createdBy: notebook.createdBy,
            sections: notebook.sections,
            tags: notebook.tags,
            category: notebook.category,
            isPublic: notebook.isPublic,
            comments: notebook.comments,
            versions: notebook.versions,
          );
          final notebooks = await getAllNotebooks();
          final idx = notebooks.indexWhere((n) => n.id == notebook.id);
          if (idx != -1) {
            notebooks[idx] = updated;
            await _prefs.setString(_notebooksKey, jsonEncode(notebooks.map((n) => n.toJson()).toList()));
            print('[SYNC] ✅ Updated local ID to: $serverId');
          }
        } else {
          print('[SYNC] ❌ Error: ${response.statusCode}');
        }
      } else {
        print('[SYNC] 📝 UPDATE mode');
        final notebookId = int.tryParse(notebook.id);
        if (notebookId != null) {
          final url = '$_baseUrl/notebooks/$notebookId';
          print('[SYNC] PUT to: $url');
          
          final response = await http.put(
            Uri.parse(url),
            headers: headers,
            body: jsonEncode({
              'title': notebook.title,
              'description': notebook.description,
              'category': notebook.category,
              'tags': notebook.tags,
              'is_public': notebook.isPublic,
              'sections': notebook.sections.map((s) => s.toJson()).toList(),
            }),
          ).timeout(const Duration(seconds: 10));
          
          print('[SYNC] Response: ${response.statusCode}');
          if (response.statusCode == 200) {
            print('[SYNC] ✅ Update sent');
          } else {
            print('[SYNC] ❌ Error: ${response.statusCode}');
          }
        }
      }
      print('[SYNC] ═══════ API SYNC END ═══════');
    } catch (e, stack) {
      print('[SYNC] 💥 Exception: $e');
      print('[SYNC] Stack: $stack');
    }
  }

  /// Récupérer tous les cahiers
  Future<List<ProjectNotebook>> getAllNotebooks() async {
    try {
      final jsonString = _prefs.getString(_notebooksKey) ?? '[]';
      final jsonList = jsonDecode(jsonString) as List;
      return jsonList
          .map((json) => ProjectNotebook.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erreur lors de la récupération des cahiers: $e');
    }
  }

  /// Charger les cahiers depuis le serveur et les synchroniser localement
  /// Appelé au login pour restaurer tous les cahiers du user
  Future<List<ProjectNotebook>> syncNotebooksFromServer() async {
    try {
      print('[NOTEBOOK-SYNC] Syncing notebooks from server...');
      final token = await _getTokenFromStorage();
      
      if (token == null || token.isEmpty) {
        print('[NOTEBOOK-SYNC] ⚠️ No token available');
        return [];
      }

      final headers = _getHeadersWithToken(token);
      final url = '$_baseUrl/notebooks';
      
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        final notebooks = data
            .map((n) => ProjectNotebook.fromJson(n as Map<String, dynamic>))
            .toList();

        // Sauvegarder localement
        final jsonList = notebooks.map((n) => n.toJson()).toList();
        await _prefs.setString(_notebooksKey, jsonEncode(jsonList));

        print('[NOTEBOOK-SYNC] ✅ Synced ${notebooks.length} notebooks from server');
        return notebooks;
      } else {
        print('[NOTEBOOK-SYNC] ❌ Failed: ${response.statusCode}');
        return [];
      }
    } catch (e, stack) {
      print('[NOTEBOOK-SYNC] 💥 Exception: $e');
      print('[NOTEBOOK-SYNC] Stack: $stack');
      return [];
    }
  }

  /// Récupérer un cahier par ID
  Future<ProjectNotebook?> getNotebookById(String id) async {
    final notebooks = await getAllNotebooks();
    try {
      return notebooks.firstWhere((n) => n.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Récupérer les cahiers d'une ferme
  Future<List<ProjectNotebook>> getNotebooksByFarm(String farmId) async {
    final notebooks = await getAllNotebooks();
    return notebooks.where((n) => n.farmId == farmId).toList();
  }

  /// Récupérer les cahiers créés par un utilisateur
  Future<List<ProjectNotebook>> getNotebooksByUser(String userId) async {
    final notebooks = await getAllNotebooks();
    return notebooks.where((n) => n.createdBy == userId).toList();
  }

  /// Supprimer un cahier
  Future<void> deleteNotebook(String id) async {
    try {
      final notebooks = await getAllNotebooks();
      notebooks.removeWhere((n) => n.id == id);
      final jsonList = notebooks.map((n) => n.toJson()).toList();
      await _prefs.setString(_notebooksKey, jsonEncode(jsonList));
      
      // Supprimer aussi les versions
      await _prefs.remove('$_versionsKey$id');
    } catch (e) {
      throw Exception('Erreur lors de la suppression: $e');
    }
  }

  // ========== SECTIONS ==========

  /// Ajouter une section
  Future<ProjectNotebook> addSection(
    String notebookId,
    String sectionTitle,
  ) async {
    final notebook = await getNotebookById(notebookId);
    if (notebook == null) throw Exception('Cahier non trouvé');

    final newSection = NotebookSection(title: sectionTitle);
    final updatedSections = [...notebook.sections, newSection];

    final updated = notebook.copyWith(sections: updatedSections);
    await saveNotebook(updated);
    return updated;
  }

  /// Mettre à jour une section
  Future<ProjectNotebook> updateSection(
    String notebookId,
    String sectionId,
    String newTitle,
  ) async {
    final notebook = await getNotebookById(notebookId);
    if (notebook == null) throw Exception('Cahier non trouvé');

    final updatedSections = notebook.sections.map((s) {
      if (s.id == sectionId) {
        return s.copyWith(title: newTitle);
      }
      return s;
    }).toList();

    final updated = notebook.copyWith(sections: updatedSections);
    await saveNotebook(updated);
    return updated;
  }

  /// Supprimer une section
  Future<ProjectNotebook> deleteSection(
    String notebookId,
    String sectionId,
  ) async {
    final notebook = await getNotebookById(notebookId);
    if (notebook == null) throw Exception('Cahier non trouvé');

    final updatedSections =
        notebook.sections.where((s) => s.id != sectionId).toList();
    final updated = notebook.copyWith(sections: updatedSections);
    await saveNotebook(updated);
    return updated;
  }

  // ========== CONTENU ==========

  /// Ajouter du contenu à une section
  Future<ProjectNotebook> addContent(
    String notebookId,
    String sectionId,
    String type,
    String content, {
    Map<String, dynamic> metadata = const {},
  }) async {
    final notebook = await getNotebookById(notebookId);
    if (notebook == null) throw Exception('Cahier non trouvé');

    final newNoteContent = NoteContent(
      type: type,
      content: content,
      metadata: metadata,
    );

    final updatedSections = notebook.sections.map((s) {
      if (s.id == sectionId) {
        return s.copyWith(contents: [...s.contents, newNoteContent]);
      }
      return s;
    }).toList();

    final updated = notebook.copyWith(sections: updatedSections);
    await saveNotebook(updated);
    return updated;
  }

  /// Mettre à jour le contenu
  Future<ProjectNotebook> updateContent(
    String notebookId,
    String sectionId,
    String contentId,
    String newContent,
    Map<String, dynamic>? metadata,
  ) async {
    final notebook = await getNotebookById(notebookId);
    if (notebook == null) throw Exception('Cahier non trouvé');

    final updatedSections = notebook.sections.map((s) {
      if (s.id == sectionId) {
        final updatedContents = s.contents.map((c) {
          if (c.id == contentId) {
            return c.copyWith(
              content: newContent,
              metadata: metadata ?? c.metadata,
            );
          }
          return c;
        }).toList();
        return s.copyWith(contents: updatedContents);
      }
      return s;
    }).toList();

    final updated = notebook.copyWith(sections: updatedSections);
    await saveNotebook(updated);
    return updated;
  }

  // ========== COMMENTAIRES ==========

  /// Ajouter un commentaire
  Future<ProjectNotebook> addComment(
    String notebookId,
    String userId,
    String userName,
    String text,
  ) async {
    final notebook = await getNotebookById(notebookId);
    if (notebook == null) throw Exception('Cahier non trouvé');

    final newComment = NoteComment(
      userId: userId,
      userName: userName,
      text: text,
    );

    final updated = notebook.copyWith(
      comments: [...notebook.comments, newComment],
    );
    await saveNotebook(updated);
    return updated;
  }

  /// Supprimer un commentaire
  Future<ProjectNotebook> deleteComment(
    String notebookId,
    String commentId,
  ) async {
    final notebook = await getNotebookById(notebookId);
    if (notebook == null) throw Exception('Cahier non trouvé');

    final updated = notebook.copyWith(
      comments: notebook.comments.where((c) => c.id != commentId).toList(),
    );
    await saveNotebook(updated);
    return updated;
  }

  // ========== PARTAGE ==========

  /// Partager avec d'autres utilisateurs
  Future<ProjectNotebook> shareWith(
    String notebookId,
    List<String> userIds,
  ) async {
    final notebook = await getNotebookById(notebookId);
    if (notebook == null) throw Exception('Cahier non trouvé');

    final currentShared = Set<String>.from(notebook.sharedWith);
    currentShared.addAll(userIds);

    final updated = notebook.copyWith(
      sharedWith: currentShared.toList(),
    );
    await saveNotebook(updated);
    return updated;
  }

  /// Arrêter le partage avec un utilisateur
  Future<ProjectNotebook> unshareWith(
    String notebookId,
    String userId,
  ) async {
    final notebook = await getNotebookById(notebookId);
    if (notebook == null) throw Exception('Cahier non trouvé');

    final updated = notebook.copyWith(
      sharedWith:
          notebook.sharedWith.where((u) => u != userId).toList(),
    );
    await saveNotebook(updated);
    return updated;
  }

  /// Rendre public/privé
  Future<ProjectNotebook> setPublic(
    String notebookId,
    bool isPublic,
  ) async {
    final notebook = await getNotebookById(notebookId);
    if (notebook == null) throw Exception('Cahier non trouvé');

    final updated = notebook.copyWith(isPublic: isPublic);
    await saveNotebook(updated);
    return updated;
  }

  // ========== VERSIONING ==========

  /// Créer une version/sauvegarde
  Future<void> createVersion(
    String notebookId,
    String createdBy,
    String changeDescription,
  ) async {
    final notebook = await getNotebookById(notebookId);
    if (notebook == null) throw Exception('Cahier non trouvé');

    final version = NoteVersion(
      notebookId: notebookId,
      title: notebook.title,
      sections: notebook.sections,
      createdBy: createdBy,
      changeDescription: changeDescription,
    );

    final versions =
        [...notebook.versions, version];
    final updated = notebook.copyWith(versions: versions);
    await saveNotebook(updated);
  }

  /// Récupérer l'historique des versions
  Future<List<NoteVersion>> getVersionHistory(String notebookId) async {
    final notebook = await getNotebookById(notebookId);
    return notebook?.versions ?? [];
  }

  /// Restaurer une version précédente
  Future<ProjectNotebook> restoreVersion(
    String notebookId,
    String versionId,
  ) async {
    final notebook = await getNotebookById(notebookId);
    if (notebook == null) throw Exception('Cahier non trouvé');

    final version = notebook.versions.firstWhere(
      (v) => v.id == versionId,
      orElse: () => throw Exception('Version non trouvée'),
    );

    final updated = notebook.copyWith(sections: version.sections);
    await saveNotebook(updated);
    return updated;
  }

  // ========== TAGS ==========

  /// Ajouter des tags
  Future<ProjectNotebook> addTags(
    String notebookId,
    List<String> newTags,
  ) async {
    final notebook = await getNotebookById(notebookId);
    if (notebook == null) throw Exception('Cahier non trouvé');

    final currentTags = Set<String>.from(notebook.tags);
    currentTags.addAll(newTags);

    final updated = notebook.copyWith(tags: currentTags.toList());
    await saveNotebook(updated);
    return updated;
  }

  /// Supprimer un tag
  Future<ProjectNotebook> removeTag(
    String notebookId,
    String tag,
  ) async {
    final notebook = await getNotebookById(notebookId);
    if (notebook == null) throw Exception('Cahier non trouvé');

    final updated = notebook.copyWith(
      tags: notebook.tags.where((t) => t != tag).toList(),
    );
    await saveNotebook(updated);
    return updated;
  }

  /// Rechercher par tags
  Future<List<ProjectNotebook>> searchByTags(List<String> tags) async {
    final notebooks = await getAllNotebooks();
    return notebooks
        .where((n) => tags.any((tag) => n.tags.contains(tag)))
        .toList();
  }

  // ========== RECHERCHE ==========

  /// Rechercher les cahiers par titre ou description
  Future<List<ProjectNotebook>> search(String query) async {
    final notebooks = await getAllNotebooks();
    final lowerQuery = query.toLowerCase();

    return notebooks
        .where((n) =>
            n.title.toLowerCase().contains(lowerQuery) ||
            n.description.toLowerCase().contains(lowerQuery) ||
            n.tags.any((t) => t.toLowerCase().contains(lowerQuery)))
        .toList();
  }

  // ========== EXPORT ==========

  /// Générer le contenu texte pour export
  String generatePlainText(ProjectNotebook notebook) {
    final buffer = StringBuffer();

    buffer.writeln('═' * 60);
    buffer.writeln('CAHIER: ${notebook.title}');
    buffer.writeln('═' * 60);
    buffer.writeln('\nDescription: ${notebook.description}');
    buffer.writeln('Catégorie: ${notebook.category}');
    buffer.writeln('Créé: ${notebook.createdAt}');
    buffer.writeln('Tags: ${notebook.tags.join(", ")}');

    for (final section in notebook.sections) {
      buffer.writeln('\n\n─' * 30);
      buffer.writeln('SECTION: ${section.title}');
      buffer.writeln('─' * 30);

      for (final content in section.contents) {
        buffer.writeln('\n[${content.type.toUpperCase()}]');
        buffer.writeln(content.content);
      }
    }

    buffer.writeln('\n\n═' * 60);
    if (notebook.comments.isNotEmpty) {
      buffer.writeln('COMMENTAIRES');
      buffer.writeln('═' * 60);
      for (final comment in notebook.comments) {
        buffer.writeln(
            '\n${comment.userName}: ${comment.text}');
        buffer.writeln('(${comment.createdAt})');
      }
    }

    return buffer.toString();
  }

  /// Genérer le contenu JSON pour export
  String generateJson(ProjectNotebook notebook) {
    return jsonEncode(notebook.toJson());
  }
}
