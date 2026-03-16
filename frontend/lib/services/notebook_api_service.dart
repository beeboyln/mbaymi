import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_notebook_model.dart';

class NotebookApiService {
  final String baseUrl;
  late String _token;

  NotebookApiService({
    required this.baseUrl,
  });

  /// Initialize with auth token
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('auth_token') ?? '';
  }

  /// Helper to build headers
  Map<String, String> _getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $_token',
    };
  }

  /// Helper to handle errors
  void _handleResponse(http.Response response) {
    if (response.statusCode >= 400) {
      final error = jsonDecode(response.body);
      throw Exception(error['detail'] ?? 'API error: ${response.statusCode}');
    }
  }

  // ========== CRUD OPERATIONS ==========

  /// Créer un cahier
  Future<ProjectNotebook> createNotebook({
    required String title,
    required String description,
    required int farmId,
    String category = 'general',
    List<String>? tags,
    bool isPublic = false,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/notebooks'),
      headers: _getHeaders(),
      body: jsonEncode({
        'title': title,
        'description': description,
        'farm_id': farmId,
        'category': category,
        'tags': tags ?? [],
        'is_public': isPublic,
        'sections': [],
      }),
    );

    _handleResponse(response);
    final data = jsonDecode(response.body);
    return ProjectNotebook.fromJson(data);
  }

  /// Récupérer tous les cahiers
  Future<List<ProjectNotebook>> getAllNotebooks({
    int? farmId,
    String? category,
    bool? isPublic,
  }) async {
    String url = '$baseUrl/api/notebooks';
    final params = <String, String>{};
    
    if (farmId != null) params['farm_id'] = farmId.toString();
    if (category != null) params['category'] = category;
    if (isPublic != null) params['is_public'] = isPublic.toString();

    if (params.isNotEmpty) {
      url += '?' + params.entries.map((e) => '${e.key}=${e.value}').join('&');
    }

    final response = await http.get(
      Uri.parse(url),
      headers: _getHeaders(),
    );

    _handleResponse(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ProjectNotebook.fromJson(json)).toList();
  }

  /// Récupérer les cahiers d'une ferme
  Future<List<ProjectNotebook>> getNotebooksByFarm(int farmId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notebooks/farm/$farmId'),
      headers: _getHeaders(),
    );

    _handleResponse(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ProjectNotebook.fromJson(json)).toList();
  }

  /// Récupérer un cahier
  Future<ProjectNotebook> getNotebook(int id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notebooks/$id'),
      headers: _getHeaders(),
    );

    _handleResponse(response);
    final data = jsonDecode(response.body);
    return ProjectNotebook.fromJson(data);
  }

  /// Mettre à jour un cahier
  Future<ProjectNotebook> updateNotebook(
    int id,
    ProjectNotebook notebook,
  ) async {
    final response = await http.put(
      Uri.parse('$baseUrl/api/notebooks/$id'),
      headers: _getHeaders(),
      body: jsonEncode({
        'title': notebook.title,
        'description': notebook.description,
        'category': notebook.category,
        'tags': notebook.tags,
        'sections': notebook.sections.map((s) => s.toJson()).toList(),
        'is_public': notebook.isPublic,
      }),
    );

    _handleResponse(response);
    final data = jsonDecode(response.body);
    return ProjectNotebook.fromJson(data);
  }

  /// Supprimer un cahier
  Future<void> deleteNotebook(int id) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/notebooks/$id'),
      headers: _getHeaders(),
    );

    _handleResponse(response);
  }

  // ========== COMMENTAIRES ==========

  /// Ajouter un commentaire
  Future<NoteComment> addComment(
    int notebookId,
    String text,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/notebooks/$notebookId/comments'),
      headers: _getHeaders(),
      body: jsonEncode({'text': text}),
    );

    _handleResponse(response);
    final data = jsonDecode(response.body);
    return NoteComment(
      id: data['id'],
      userId: data['user_id'],
      userName: data['user_name'] ?? 'User',
      text: data['text'],
      createdAt: DateTime.parse(data['created_at']),
    );
  }

  /// Supprimer un commentaire
  Future<void> deleteComment(int notebookId, int commentId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/notebooks/$notebookId/comments/$commentId'),
      headers: _getHeaders(),
    );

    _handleResponse(response);
  }

  // ========== PARTAGE ==========

  /// Partager un cahier
  Future<void> shareNotebook(int notebookId, List<int> userIds) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/notebooks/$notebookId/share'),
      headers: _getHeaders(),
      body: jsonEncode({'user_ids': userIds}),
    );

    _handleResponse(response);
  }

  /// Arrêter le partage
  Future<void> unshareNotebook(int notebookId, int userId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/api/notebooks/$notebookId/share/$userId'),
      headers: _getHeaders(),
    );

    _handleResponse(response);
  }

  // ========== VERSIONING ==========

  /// Créer une version
  Future<NoteVersion> createVersion(
    int notebookId,
    String changeDescription,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/api/notebooks/$notebookId/versions'),
      headers: _getHeaders(),
      body: jsonEncode({'change_description': changeDescription}),
    );

    _handleResponse(response);
    final data = jsonDecode(response.body);
    return NoteVersion(
      id: data['id'],
      notebookId: data['notebook_id'],
      title: data['title'],
      sections: [],
      createdBy: data['created_by'].toString(),
      changeDescription: data['change_description'],
    );
  }

  /// Récupérer l'historique
  Future<List<NoteVersion>> getVersionHistory(int notebookId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notebooks/$notebookId/versions'),
      headers: _getHeaders(),
    );

    _handleResponse(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data
        .map((json) => NoteVersion(
          id: json['id'],
          notebookId: json['notebook_id'],
          title: json['title'],
          sections: [],
          createdBy: json['created_by'].toString(),
          changeDescription: json['change_description'],
          createdAt: DateTime.parse(json['created_at']),
        ))
        .toList();
  }

  /// Restaurer une version
  Future<void> restoreVersion(int notebookId, int versionId) async {
    final response = await http.post(
      Uri.parse(
          '$baseUrl/api/notebooks/$notebookId/versions/$versionId/restore'),
      headers: _getHeaders(),
    );

    _handleResponse(response);
  }

  // ========== RECHERCHE ==========

  /// Rechercher des cahiers
  Future<List<ProjectNotebook>> search(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/notebooks/search?query=$query'),
      headers: _getHeaders(),
    );

    _handleResponse(response);
    final List<dynamic> data = jsonDecode(response.body);
    return data.map((json) => ProjectNotebook.fromJson(json)).toList();
  }
}
