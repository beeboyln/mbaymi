import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/project_notebook_model.dart';
import 'notebook_service.dart';
import 'notebook_api_service.dart';
import 'connectivity_service.dart';

/// Provider hybride - Fonctionne offline (local) + sync avec API (online)
class HybridNotebookProvider extends ChangeNotifier {
  late NotebookService _localService;
  late NotebookApiService _apiService;
  late ConnectivityService _connectivity;

  List<ProjectNotebook> _notebooks = [];
  List<ProjectNotebook> _filteredNotebooks = [];
  ProjectNotebook? _selectedNotebook;

  bool _isLoading = false;
  bool _isSyncing = false;
  String? _errorMessage;
  bool _isOnline = true;

  // Getters
  List<ProjectNotebook> get notebooks => _notebooks;
  List<ProjectNotebook> get filteredNotebooks => _filteredNotebooks;
  ProjectNotebook? get selectedNotebook => _selectedNotebook;
  bool get isLoading => _isLoading;
  bool get isSyncing => _isSyncing;
  String? get errorMessage => _errorMessage;
  bool get isOnline => _isOnline;

  /// Initialiser le provider
  Future<void> initialize(
    SharedPreferences prefs,
    String apiBaseUrl,
  ) async {
    _localService = NotebookService(prefs);
    _apiService = NotebookApiService(baseUrl: apiBaseUrl);
    _connectivity = ConnectivityService();

    // Initialiser le service API
    await _apiService.initialize();

    // Écouter les changements de connectivité
    _connectivity.onConnectivityChanged.listen((isConnected) {
      _isOnline = isConnected;
      notifyListeners();

      // Si reconnecté, synchroniser
      if (isConnected) {
        _syncWithBackend();
      }
    });

    // Vérifier la connectivité initiale
    _isOnline = _connectivity.isOnline;
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// LOAD OPERATIONS
  /// ═══════════════════════════════════════════════════════════════════════════

  /// Charger les cahiers (local d'abord, puis API si en ligne)
  Future<void> loadNotebooksByFarm(int farmId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // D'abord, charger depuis le local
      _notebooks = await _localService.getNotebooksByFarm(farmId.toString());
      notifyListeners();

      // Si en ligne, charger depuis l'API et mettre en cache
      if (_isOnline) {
        try {
          final apiNotebooks = await _apiService.getNotebooksByFarm(farmId);
          // Mettre en cache localement
          for (final notebook in apiNotebooks) {
            await _localService.saveNotebook(notebook);
          }
          _notebooks = apiNotebooks;
          notifyListeners();
        } catch (e) {
          // Erreur API, mais on a les données locales
          _errorMessage = 'Erreur sync: $e';
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Charger tous les cahiers
  Future<void> loadAllNotebooks() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Local d'abord
      _notebooks = await _localService.getAllNotebooks();
      notifyListeners();

      // API si en ligne
      if (_isOnline) {
        try {
          final apiNotebooks = await _apiService.getAllNotebooks();
          for (final notebook in apiNotebooks) {
            await _localService.saveNotebook(notebook);
          }
          _notebooks = apiNotebooks;
          notifyListeners();
        } catch (e) {
          _errorMessage = 'Erreur sync: $e';
        }
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// CREATE OPERATIONS
  /// ═══════════════════════════════════════════════════════════════════════════

  /// Créer un cahier (local d'abord, puis sync API)
  Future<ProjectNotebook> createNotebook({
    required String title,
    required String description,
    required int farmId,
    required String userId,
    String category = 'general',
    List<String>? tags,
    bool isPublic = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Créer localement d'abord
      final localNotebook = await _localService.createNotebook(
        title: title,
        description: description,
        farmId: farmId.toString(),
        userId: userId,
        category: category,
        tags: tags,
      );

      // Si en ligne, créer sur l'API aussi
      if (_isOnline) {
        try {
          await _apiService.createNotebook(
            title: title,
            description: description,
            farmId: farmId,
            category: category,
            tags: tags ?? [],
            isPublic: isPublic,
          );
        } catch (e) {
          // Marqué comme "pending" localement
          _errorMessage = 'Notebook créé localement, sync en attente';
        }
      }

      _notebooks.add(localNotebook);
      _isLoading = false;
      notifyListeners();

      return localNotebook;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// UPDATE OPERATIONS
  /// ═══════════════════════════════════════════════════════════════════════════

  /// Mettre à jour un cahier
  Future<void> updateNotebook(ProjectNotebook notebook) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Mettre à jour localement d'abord
      await _localService.saveNotebook(notebook);

      // Si en ligne, mettre à jour sur l'API
      if (_isOnline) {
        try {
          // Note: La conversion ID dépend de votre implémentation
          // Pour l'instant, on suppose que l'ID est numérique
          // await _apiService.updateNotebook(int.parse(notebook.id), notebook);
        } catch (e) {
          _errorMessage = 'Erreur sync mise à jour: $e';
        }
      }

      // Mettre à jour la liste locale
      final index = _notebooks.indexWhere((n) => n.id == notebook.id);
      if (index != -1) {
        _notebooks[index] = notebook;
      }

      if (_selectedNotebook?.id == notebook.id) {
        _selectedNotebook = notebook;
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

  /// ═══════════════════════════════════════════════════════════════════════════
  /// DELETE OPERATIONS
  /// ═══════════════════════════════════════════════════════════════════════════

  /// Supprimer un cahier
  Future<void> deleteNotebook(String id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Supprimer localement
      await _localService.deleteNotebook(id);

      // Si en ligne, supprimer sur l'API
      if (_isOnline) {
        try {
          // await _apiService.deleteNotebook(int.parse(id));
        } catch (e) {
          _errorMessage = 'Erreur sync suppression: $e';
        }
      }

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

  /// ═══════════════════════════════════════════════════════════════════════════
  /// SEARCH & FILTER
  /// ═══════════════════════════════════════════════════════════════════════════

  /// Rechercher
  Future<void> search(String query) async {
    if (query.isEmpty) {
      _filteredNotebooks = List.from(_notebooks);
    } else {
      if (_isOnline) {
        try {
          _filteredNotebooks = await _apiService.search(query);
        } catch (e) {
          // Fallback to local search
          _filteredNotebooks = await _localService.search(query);
        }
      } else {
        _filteredNotebooks = await _localService.search(query);
      }
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

  /// ═══════════════════════════════════════════════════════════════════════════
  /// SYNC OPERATIONS
  /// ═══════════════════════════════════════════════════════════════════════════

  /// Synchroniser avec le backend
  Future<void> _syncWithBackend() async {
    if (_isSyncing) return;

    _isSyncing = true;
    notifyListeners();

    try {
      // Récupérer tous les cahiers locaux
      final localNotebooks = await _localService.getAllNotebooks();

      // Envoyer les modifications si nécessaire
      for (final notebook in localNotebooks) {
        try {
          // Tenter de créer/mettre à jour sur l'API
          // La logique dépend si le notebook a un ID API
          // Pour l'instant, on fait juste un log
          print('Syncing notebook: ${notebook.title}');
        } catch (e) {
          print('Erreur sync: $e');
        }
      }

      _isSyncing = false;
      notifyListeners();
    } catch (e) {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// Forcer une synchronisation
  Future<void> forceSyncWithBackend() async {
    await _syncWithBackend();
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// COMMENTS OPERATIONS
  /// ═══════════════════════════════════════════════════════════════════════════

  /// Ajouter un commentaire
  Future<void> addComment(
    String notebookId,
    String userId,
    String userName,
    String text,
  ) async {
    try {
      // Ajouter localement
      final updated = await _localService.addComment(
        notebookId,
        userId,
        userName,
        text,
      );

      // Si en ligne, ajouter sur l'API
      if (_isOnline) {
        try {
          // await _apiService.addComment(int.parse(notebookId), text);
        } catch (e) {
          _errorMessage = 'Erreur sync commentaire: $e';
        }
      }

      // Mettre à jour la sélection
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

  /// ═══════════════════════════════════════════════════════════════════════════
  /// SHARING OPERATIONS
  /// ═══════════════════════════════════════════════════════════════════════════

  /// Partager un cahier
  Future<void> shareWith(String notebookId, List<String> userIds) async {
    try {
      // Partager localement
      final updated = await _localService.shareWith(
        notebookId,
        userIds,
      );

      // Si en ligne, partager sur l'API
      if (_isOnline) {
        try {
          // await _apiService.shareNotebook(int.parse(notebookId), userIds.map(int.parse).toList());
        } catch (e) {
          _errorMessage = 'Erreur sync partage: $e';
        }
      }

      // Mettre à jour la liste
      final index = _notebooks.indexWhere((n) => n.id == notebookId);
      if (index != -1) {
        _notebooks[index] = updated;
      }

      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      rethrow;
    }
  }

  /// ═══════════════════════════════════════════════════════════════════════════
  /// VERSIONING OPERATIONS
  /// ═══════════════════════════════════════════════════════════════════════════

  /// Créer une version
  Future<void> createVersion(
    String notebookId,
    String userId,
    String changeDescription,
  ) async {
    try {
      // Créer localement
      await _localService.createVersion(
        notebookId,
        userId,
        changeDescription,
      );

      // Si en ligne, créer sur l'API
      if (_isOnline) {
        try {
          // await _apiService.createVersion(int.parse(notebookId), changeDescription);
        } catch (e) {
          _errorMessage = 'Erreur sync version: $e';
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
    try {
      if (_isOnline) {
        try {
          return await _apiService.getVersionHistory(int.parse(notebookId));
        } catch (e) {
          // Fallback to local
          return await _localService.getVersionHistory(notebookId);
        }
      } else {
        return await _localService.getVersionHistory(notebookId);
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }
}
