import 'dart:async';

/// Service simple de détection de connectivité
/// Utilise des heuristiques simples pour détecter si on est offline
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._();

  final _connectivityController = StreamController<bool>.broadcast();

  /// Stream qui émet true si connecté, false sinon
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  bool _isOnline = true;

  /// État actuel de la connectivité
  bool get isOnline => _isOnline;

  /// Simule un changement de connectivité (appelé après erreurs réseau)
  void _notifyConnectivityChange(bool isOnline) {
    if (_isOnline != isOnline) {
      _isOnline = isOnline;
      _connectivityController.add(isOnline);
    }
  }

  /// Enregistre une erreur de connectivité
  void recordConnectionError() {
    _notifyConnectivityChange(false);
  }

  /// Enregistre une connexion réussie
  void recordConnectionSuccess() {
    _notifyConnectivityChange(true);
  }

  /// Nettoie les ressources
  void dispose() {
    _connectivityController.close();
  }
}

/// Extension helper pour les messages d'erreur connectivité
extension ConnectivityMessages on ConnectivityService {
  String getOfflineMessage() {
    return '📡 Mode hors ligne. Certaines fonctionnalités sont limitées.';
  }

  String getOnlineMessage() {
    return '✅ Connexion rétablie.';
  }
}
