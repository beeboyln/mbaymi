import 'package:flutter/material.dart';

/// 🔄 Global Loading Service
/// Gère un loader global pour l'application
class LoadingService {
  static final LoadingService _instance = LoadingService._internal();
  
  late BuildContext? _context;
  late OverlayEntry? _overlayEntry;
  bool _isLoading = false;

  factory LoadingService() {
    return _instance;
  }

  LoadingService._internal();

  /// Initialiser avec le contexte global
  void init(BuildContext context) {
    _context = context;
  }

  /// Afficher le loader global
  void show({String message = 'Chargement...'}) {
    if (_isLoading || _context == null) return;
    
    _isLoading = true;
    _overlayEntry = OverlayEntry(
      builder: (context) => _buildLoadingOverlay(message),
    );
    
    Overlay.of(_context!).insert(_overlayEntry!);
  }

  /// Masquer le loader global
  void hide() {
    if (!_isLoading || _overlayEntry == null) return;
    
    _isLoading = false;
    _overlayEntry!.remove();
    _overlayEntry = null;
  }

  /// Wrapper pour les requêtes avec loading automatique
  Future<T> wrap<T>(
    Future<T> Function() fn, {
    String message = 'Chargement...',
  }) async {
    show(message: message);
    try {
      return await fn();
    } finally {
      hide();
    }
  }

  Widget _buildLoadingOverlay(String message) {
    return Material(
      color: Colors.black.withOpacity(0.3),
      child: Center(
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF6B8E23),
              ),
              const SizedBox(height: 16),
              Text(
                message,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
