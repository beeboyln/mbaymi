import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_notebook_model.dart';
import '../services/notebook_service.dart';

/// Provider pour gérer l'état des cahiers de projet
class NotebookProvider extends ChangeNotifier {
  late NotebookService _notebookService;
  
  List<ProjectNotebook> _notebooks = [];
  List<ProjectNotebook> _filteredNotebooks = [];
  ProjectNotebook? _selectedNotebook;
  
  bool _isLoading = false;
  String? _errorMessage;

  // Getters
  List<ProjectNotebook> get notebooks => _notebooks;
  List<ProjectNotebook> get filteredNotebooks => _filteredNotebooks;
  ProjectNotebook? get selectedNotebook => _selectedNotebook;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Initialiser le service
  Future<void> initialize(SharedPreferences prefs) async {
    _notebookService = NotebookService(prefs);
  }

  // ========== OPERATIONS CRUD ==========

  /// Créer un nouveau cahier
  Future<ProjectNotebook> createNotebook({
    required String title,
    required String description,
    required String farmId,
    required String userId,
    String category = 'general',
    List<String>? tags,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final notebook = await _notebookService.createNotebook(
        title: title,
        description: description,
        farmId: farmId,
        userId: userId,
        category: category,
        tags: tags,
      );
      
      _notebooks.add(notebook);
      _isLoading = false;
      notifyListeners();
      
      return notebook;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Charger tous les cahiers
  Future<void> loadNotebooks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notebooks = await _notebookService.getAllNotebooks();
      _filteredNotebooks = List.from(_notebooks);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Charger les cahiers d'une ferme
  Future<void> loadNotebooksByFarm(String farmId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _notebooks =
          await _notebookService.getNotebooksByFarm(farmId);
      _filteredNotebooks = List.from(_notebooks);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Sélectionner un cahier
  Future<void> selectNotebook(String id) async {
    try {
      _selectedNotebook = await _notebookService.getNotebookById(id);
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Sauvegarder un cahier
  Future<void> saveNotebook(ProjectNotebook notebook) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _notebookService.saveNotebook(notebook);
      
      final index = _notebooks.indexWhere((n) => n.id == notebook.id);
      if (index != -1) {
        _notebooks[index] = notebook;
      } else {
        _notebooks.add(notebook);
      }
      
      _selectedNotebook = notebook;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// Supprimer un cahier
  Future<void> deleteNotebook(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _notebookService.deleteNotebook(id);
      _notebooks.removeWhere((n) => n.id == id);
      
      if (_selectedNotebook?.id == id) {
        _selectedNotebook = null;
      }
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // ========== RECHERCHE ET FILTRAGE ==========

  /// Rechercher les cahiers
  Future<void> search(String query) async {
    if (query.isEmpty) {
      _filteredNotebooks = List.from(_notebooks);
    } else {
      _filteredNotebooks =
          await _notebookService.search(query);
    }
    notifyListeners();
  }

  /// Filtrer par catégorie
  void filterByCategory(String category) {
    if (category == 'all') {
      _filteredNotebooks = List.from(_notebooks);
    } else {
      _filteredNotebooks = _notebooks
          .where((n) => n.category == category)
          .toList();
    }
    notifyListeners();
  }

  /// Filtrer par tags
  Future<void> filterByTags(List<String> tags) async {
    _filteredNotebooks =
        await _notebookService.searchByTags(tags);
    notifyListeners();
  }

  // ========== SECTIONS ==========

  /// Ajouter une section
  Future<void> addSection(String notebookId, String title) async {
    try {
      final updated = await _notebookService.addSection(notebookId, title);
      
      final index = _notebooks.indexWhere((n) => n.id == notebookId);
      if (index != -1) {
        _notebooks[index] = updated;
      }
      
      if (_selectedNotebook?.id == notebookId) {
        _selectedNotebook = updated;
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Supprimer une section
  Future<void> deleteSection(String notebookId, String sectionId) async {
    try {
      final updated =
          await _notebookService.deleteSection(notebookId, sectionId);
      
      final index = _notebooks.indexWhere((n) => n.id == notebookId);
      if (index != -1) {
        _notebooks[index] = updated;
      }
      
      if (_selectedNotebook?.id == notebookId) {
        _selectedNotebook = updated;
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ========== COMMENTAIRES ==========

  /// Ajouter un commentaire
  Future<void> addComment(
    String notebookId,
    String userId,
    String userName,
    String text,
  ) async {
    try {
      final updated = await _notebookService.addComment(
        notebookId,
        userId,
        userName,
        text,
      );
      
      final index = _notebooks.indexWhere((n) => n.id == notebookId);
      if (index != -1) {
        _notebooks[index] = updated;
      }
      
      if (_selectedNotebook?.id == notebookId) {
        _selectedNotebook = updated;
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ========== PARTAGE ==========

  /// Partager avec d'autres utilisateurs
  Future<void> shareWith(String notebookId, List<String> userIds) async {
    try {
      final updated = await _notebookService.shareWith(notebookId, userIds);
      
      final index = _notebooks.indexWhere((n) => n.id == notebookId);
      if (index != -1) {
        _notebooks[index] = updated;
      }
      
      if (_selectedNotebook?.id == notebookId) {
        _selectedNotebook = updated;
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Rendre public/privé
  Future<void> setPublic(String notebookId, bool isPublic) async {
    try {
      final updated =
          await _notebookService.setPublic(notebookId, isPublic);
      
      final index = _notebooks.indexWhere((n) => n.id == notebookId);
      if (index != -1) {
        _notebooks[index] = updated;
      }
      
      if (_selectedNotebook?.id == notebookId) {
        _selectedNotebook = updated;
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  // ========== VERSIONING ==========

  /// Créer une version
  Future<void> createVersion(
    String notebookId,
    String userId,
    String changeDescription,
  ) async {
    try {
      await _notebookService.createVersion(
        notebookId,
        userId,
        changeDescription,
      );
      
      // Recharger le cahier
      final updated = await _notebookService.getNotebookById(notebookId);
      if (updated != null) {
        final index = _notebooks.indexWhere((n) => n.id == notebookId);
        if (index != -1) {
          _notebooks[index] = updated;
        }
        
        if (_selectedNotebook?.id == notebookId) {
          _selectedNotebook = updated;
        }
      }
      
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// Récupérer l'historique
  Future<List<NoteVersion>> getVersionHistory(String notebookId) async {
    return await _notebookService.getVersionHistory(notebookId);
  }
}
