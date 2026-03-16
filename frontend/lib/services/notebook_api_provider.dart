import 'package:flutter/foundation.dart';
import '../models/project_notebook_model.dart';
import 'notebook_api_service.dart';
import 'notebook_service.dart';

class NotebookApiProvider extends ChangeNotifier {
  final NotebookApiService apiService;
  final NotebookService localService;

  List<ProjectNotebook> _notebooks = [];
  ProjectNotebook? _selectedNotebook;
  bool _isLoading = false;
  String? _errorMessage;
  String? _selectedFarmId;
  String? _selectedCategory;

  NotebookApiProvider({
    required this.apiService,
    required this.localService,
  });

  // ========== GETTERS ==========

  List<ProjectNotebook> get notebooks => _notebooks;
  ProjectNotebook? get selectedNotebook => _selectedNotebook;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  List<ProjectNotebook> get filteredNotebooks {
    return _notebooks.where((notebook) {
      if (_selectedCategory != null && notebook.category != _selectedCategory) {
        return false;
      }
      if (_selectedFarmId != null && notebook.farmId != _selectedFarmId) {
        return false;
      }
      return true;
    }).toList();
  }

  // ========== INITIALIZATION & SYNC ==========

  /// Initialiser le provider
  Future<void> initialize() async {
    try {
      await apiService.initialize();
      await loadNotebooks();
    } catch (e) {
      _errorMessage = 'Erreur d\'initialisation: $e';
      notifyListeners();
    }
  }

  /// Charger les cahiers depuis l'API (avec fallback local)
  Future<void> loadNotebooks({String? farmId, String? category}) async {
    _isLoading = true;
    _selectedFarmId = farmId;
    _selectedCategory = category;
    notifyListeners();

    try {
      if (farmId != null) {
        _notebooks = await apiService.getNotebooksByFarm(int.parse(farmId));
      } else {
        _notebooks = await apiService.getAllNotebooks();
      }
      _errorMessage = null;
    } catch (e) {
      // Fallback: charger depuis le stockage local
      if (farmId != null) {
        _notebooks = await localService.getNotebooksByFarm(farmId);
      } else {
        _notebooks = await localService.getAllNotebooks();
      }
      // Filtrer par catégorie si nécessaire
      if (category != null) {
        _notebooks = _notebooks.where((n) => n.category == category).toList();
      }
      _errorMessage = 'Mode hors ligne: données locales affichées';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger les cahiers d'une ferme
  Future<void> loadNotebooksByFarm(String farmId) async {
    _isLoading = true;
    _selectedFarmId = farmId;
    notifyListeners();

    try {
      _notebooks = await apiService.getNotebooksByFarm(int.parse(farmId));
      _errorMessage = null;
    } catch (e) {
      _notebooks = await localService.getNotebooksByFarm(farmId);
      _errorMessage = 'Mode hors ligne';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Synchroniser avec le serveur
  Future<void> syncWithServer() async {
    try {
      await loadNotebooks(
        farmId: _selectedFarmId,
        category: _selectedCategory,
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur de synchronisation: $e';
    }
    notifyListeners();
  }

  // ========== CRUD OPERATIONS ==========

  /// Créer un cahier
  Future<void> createNotebook({
    required String title,
    required String description,
    required String farmId,
    required String userId,
    String category = 'general',
    List<String>? tags,
    bool isPublic = false,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final notebook = await apiService.createNotebook(
        title: title,
        description: description,
        farmId: int.parse(farmId),
        category: category,
        tags: tags,
        isPublic: isPublic,
      );

      // Sauvegarder aussi localement
      await localService.createNotebook(
        title: title,
        description: description,
        farmId: farmId,
        userId: userId,
        category: category,
        tags: tags ?? [],
      );

      _notebooks.add(notebook);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur création: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Récupérer un cahier
  Future<void> getNotebook(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      _selectedNotebook = await apiService.getNotebook(int.parse(id));
      _errorMessage = null;
    } catch (e) {
      _selectedNotebook = await localService.getNotebookById(id);
      _errorMessage = 'Mode hors ligne';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Mettre à jour un cahier
  Future<void> updateNotebook(ProjectNotebook notebook) async {
    try {
      _isLoading = true;
      notifyListeners();

      final updated = await apiService.updateNotebook(int.parse(notebook.id), notebook);

      // Mettre à jour localement
      await localService.saveNotebook(notebook);

      final index = _notebooks.indexWhere((n) => n.id == notebook.id);
      if (index >= 0) {
        _notebooks[index] = updated;
      }

      if (_selectedNotebook?.id == notebook.id) {
        _selectedNotebook = updated;
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur mise à jour: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Supprimer un cahier
  Future<void> deleteNotebook(String id) async {
    try {
      _isLoading = true;
      notifyListeners();

      await apiService.deleteNotebook(int.parse(id));

      // Supprimer localement
      await localService.deleteNotebook(id);

      _notebooks.removeWhere((n) => n.id == id);

      if (_selectedNotebook?.id == id) {
        _selectedNotebook = null;
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur suppression: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== COMMENTAIRES ==========

  /// Ajouter un commentaire
  Future<void> addComment(String notebookId, String text) async {
    try {
      final comment = await apiService.addComment(int.parse(notebookId), text);

      if (_selectedNotebook?.id == notebookId) {
        _selectedNotebook!.comments.add(comment);
        notifyListeners();
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur comment: $e';
      notifyListeners();
    }
  }

  /// Supprimer un commentaire
  Future<void> deleteComment(String notebookId, String commentId) async {
    try {
      await apiService.deleteComment(int.parse(notebookId), int.parse(commentId));

      if (_selectedNotebook?.id == notebookId) {
        _selectedNotebook!.comments.removeWhere((c) => c.id == commentId);
        notifyListeners();
      }

      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur suppression comment: $e';
      notifyListeners();
    }
  }

  // ========== PARTAGE ==========

  /// Partager un cahier
  Future<void> shareNotebook(String notebookId, List<String> userIds) async {
    try {
      await apiService.shareNotebook(int.parse(notebookId), userIds.map(int.parse).toList());
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur partage: $e';
    }
    notifyListeners();
  }

  /// Arrêter le partage
  Future<void> unshareNotebook(String notebookId, String userId) async {
    try {
      await apiService.unshareNotebook(int.parse(notebookId), int.parse(userId));
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur partage: $e';
    }
    notifyListeners();
  }

  // ========== VERSIONING ==========

  /// Créer une version
  Future<void> createVersion(String notebookId, String description) async {
    try {
      await apiService.createVersion(int.parse(notebookId), description);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur version: $e';
    }
    notifyListeners();
  }

  /// Récupérer l'historique
  Future<List<NoteVersion>> getVersionHistory(int notebookId) async {
    try {
      return await apiService.getVersionHistory(notebookId);
    } catch (e) {
      _errorMessage = 'Erreur historique: $e';
      notifyListeners();
      return [];
    }
  }

  /// Restaurer une version
  Future<void> restoreVersion(String notebookId, String versionId) async {
    try {
      await apiService.restoreVersion(int.parse(notebookId), int.parse(versionId));
      await getNotebook(notebookId);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Erreur restauration: $e';
    }
    notifyListeners();
  }

  // ========== RECHERCHE ==========

  /// Rechercher des cahiers
  Future<void> search(String query) async {
    if (query.isEmpty) {
      await loadNotebooks();
      return;
    }

    try {
      _isLoading = true;
      notifyListeners();

      _notebooks = await apiService.search(query);
      _errorMessage = null;
    } catch (e) {
      // Chercher localement
      _notebooks = await localService.search(query);
      _errorMessage = 'Mode hors ligne';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ========== UTILITAIRES ==========

  /// Effacer l'erreur
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  /// Réinitialiser la sélection
  void clearSelection() {
    _selectedNotebook = null;
    notifyListeners();
  }

  /// Définir la catégorie filtrée
  void setCategory(String? category) {
    _selectedCategory = category;
    notifyListeners();
  }

  /// Définir la ferme filtrée
  void setFarm(String? farmId) {
    _selectedFarmId = farmId;
    notifyListeners();
  }
}
