import 'dart:async';

/// Cache simple en mémoire pour les requêtes GET
/// Chaque entrée expire après une durée configurable
class SimpleCache<T> {
  final Duration _ttl; // Time To Live
  final Map<String, _CacheEntry<T>> _cache = {};

  SimpleCache({Duration ttl = const Duration(minutes: 5)}) : _ttl = ttl;

  /// Récupère une valeur du cache si elle existe et n'a pas expiré
  T? get(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    if (DateTime.now().isBefore(entry.expiresAt)) {
      return entry.value;
    } else {
      // Entrée expirée, la supprimer
      _cache.remove(key);
      return null;
    }
  }

  /// Ajoute ou met à jour une valeur dans le cache
  void set(String key, T value) {
    _cache[key] = _CacheEntry(
      value: value,
      expiresAt: DateTime.now().add(_ttl),
    );
  }

  /// Vérifie si une clé existe et n'a pas expiré
  bool contains(String key) {
    return get(key) != null;
  }

  /// Supprime une entrée spécifique
  void remove(String key) {
    _cache.remove(key);
  }

  /// Vide tout le cache
  void clear() {
    _cache.clear();
  }

  /// Vide les entrées expirées
  void cleanup() {
    final now = DateTime.now();
    _cache.removeWhere((_, entry) => now.isAfter(entry.expiresAt));
  }

  /// Nombre d'entrées en cache
  int get size => _cache.length;
}

/// Classe interne pour stocker les valeurs en cache avec leur date d'expiration
class _CacheEntry<T> {
  final T value;
  final DateTime expiresAt;

  _CacheEntry({required this.value, required this.expiresAt});
}
