class AppCacheEntry<T> {
  final T value;
  final DateTime expiresAt;

  const AppCacheEntry({
    required this.value,
    required this.expiresAt,
  });

  bool get isExpired => DateTime.now().isAfter(expiresAt);
}

class AppCacheManager {
  static final AppCacheManager _instance = AppCacheManager._internal();

  factory AppCacheManager() => _instance;

  AppCacheManager._internal();

  final Map<String, AppCacheEntry<dynamic>> _entries = {};

  Future<T> load<T>(
    String key,
    Future<T> Function() loader, {
    Duration ttl = const Duration(minutes: 2),
  }) async {
    final current = _entries[key];
    if (current != null && !current.isExpired) {
      return current.value as T;
    }

    final value = await loader();
    _entries[key] = AppCacheEntry<T>(
      value: value,
      expiresAt: DateTime.now().add(ttl),
    );
    return value;
  }

  T? peek<T>(String key) {
    final entry = _entries[key];
    if (entry == null || entry.isExpired) {
      _entries.remove(key);
      return null;
    }
    return entry.value as T?;
  }

  void invalidate(String key) {
    _entries.remove(key);
  }

  void invalidatePrefix(String prefix) {
    final matches = _entries.keys.where((key) => key.startsWith(prefix)).toList();
    for (final key in matches) {
      _entries.remove(key);
    }
  }

  void clear() {
    _entries.clear();
  }
}
