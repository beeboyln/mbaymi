import 'package:flutter/foundation.dart';

/// 📋 Logger centralisé pour l'app
/// Fournit une interface cohérente pour le logging à travers l'app
class AppLogger {
  static const String _prefix = '🔵';
  
  /// ✅ Log de succès
  static void success(String message) {
    if (kDebugMode) {
      debugPrint('✅ $message');
    }
  }
  
  /// ❌ Log d'erreur
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('❌ $message');
      if (error != null) debugPrint('   Error: $error');
      if (stackTrace != null) debugPrint('   Stack: $stackTrace');
    }
  }
  
  /// ⚠️ Log d'avertissement
  static void warning(String message) {
    if (kDebugMode) {
      debugPrint('⚠️ $message');
    }
  }
  
  /// ℹ️ Log informatif
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('ℹ️ $message');
    }
  }
  
  /// 🔄 Log pour les requêtes API
  static void api(String method, String endpoint, {int? statusCode}) {
    if (kDebugMode) {
      if (statusCode != null) {
        debugPrint('🌐 $method $endpoint → $statusCode');
      } else {
        debugPrint('🌐 $method $endpoint');
      }
    }
  }
  
  /// 🔐 Log pour l'authentification
  static void auth(String message) {
    if (kDebugMode) {
      debugPrint('🔐 $message');
    }
  }
  
  /// 💾 Log pour le cache
  static void cache(String message) {
    if (kDebugMode) {
      debugPrint('💾 $message');
    }
  }
  
  /// ⏱️ Log de performance
  static void performance(String label, Duration duration) {
    if (kDebugMode) {
      debugPrint('⏱️ $label: ${duration.inMilliseconds}ms');
    }
  }
  
  /// 🐛 Log de debug
  static void debug(String message) {
    if (kDebugMode) {
      debugPrint('🐛 $message');
    }
  }
}
