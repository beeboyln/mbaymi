import 'package:flutter/foundation.dart';
import 'package:mbaymi/services/token_storage.dart';
import 'package:mbaymi/services/api_service.dart';

/// Session model for the current authenticated user.
class Session {
  final int userId;
  final String email;
  final String name;
  final String role;
  final String accessToken;
  final String refreshToken;

  Session({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.accessToken,
    required this.refreshToken,
  });
}

/// AuthService manages the user session (login, logout, restore).
class AuthService {
  static Session? _currentSession;

  /// Get the current active session (if any).
  static Session? get currentSession => _currentSession;

  /// Check if user is authenticated.
  static bool get isAuthenticated => _currentSession != null;

  /// Login and create a session.
  /// 
  /// ⚠️ IMPORTANT:
  /// - Clears cache ONLY when switching users (userId changed)
  /// - This prevents stale data from previous user
  /// - Cache invalidation is explicit and targeted
  static Future<void> login({
    required int userId,
    required String email,
    required String name,
    required String role,
    required String accessToken,
    required String refreshToken,
  }) async {
    // Guard: if same user already logged in, don't clear cache
    final isUserSwitch = _currentSession?.userId != userId;
    
    if (isUserSwitch) {
      debugPrint('🔄 User switch detected (old=${ _currentSession?.userId} → new=$userId), clearing cache');
      ApiService.clearCache();
    } else {
      debugPrint('ℹ️ User re-login (same user), NOT clearing cache');
    }

    _currentSession = Session(
      userId: userId,
      email: email,
      name: name,
      role: role,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    // Persist to localStorage (including role)
    await TokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      userEmail: email,
      userRole: role,
    );

    debugPrint('✅ AuthService.login: Session created for userId=$userId with JWT token');
  }

  /// Restore session from localStorage (called on app startup ONLY).
  /// 
  /// ⚠️ IMPORTANT:
  /// - Called ONCE by AppBootstrap.initialize()
  /// - Do NOT call this multiple times (use _currentSession instead)
  /// - Do NOT call this from NotificationService or other dependent services
  /// - Cache is NOT invalidated here (perf optimization)
  static Future<void> restoreSession() async {
    // Guard: if already restored, return immediately
    if (_currentSession != null) {
      debugPrint('⚠️ AuthService.restoreSession: Already restored, skipping');
      return;
    }
    
    try {
      final userId = await TokenStorage.getUserId();
      final accessToken = await TokenStorage.getAccessToken();
      final refreshToken = await TokenStorage.getRefreshToken();
      final email = await TokenStorage.getUserEmail();
      final role = await TokenStorage.getUserRole();

      if (userId != null && accessToken != null && refreshToken != null && email != null) {
        // ⚠️ NO clearCache() here - it's expensive and called too often
        // Cache invalidation should be explicit (invalidateCache(key)) or on logout only
        
        _currentSession = Session(
          userId: userId,
          email: email,
          name: email.split('@').first, // Extract name from email
          role: role ?? 'farmer', // Use stored role or default to 'farmer'
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        debugPrint('✅ AuthService.restoreSession: Session restored for userId=$userId with role=$role');
      } else {
        debugPrint('⚠️ AuthService.restoreSession: No valid tokens found (user will see login screen)');
      }
    } catch (e) {
      debugPrint('❌ AuthService.restoreSession failed: $e');
    }
  }

  /// Logout and clear session.
  static Future<void> logout() async {
    _currentSession = null;
    await TokenStorage.clear();
    debugPrint('✅ AuthService.logout: Session cleared');
  }
}
