import 'package:flutter/foundation.dart';
import 'package:mbaymi/services/token_storage.dart';

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
  static Future<void> login({
    required int userId,
    required String email,
    required String name,
    required String role,
  }) async {
    // For now, use userId as a simple access token.
    // In production, this would come from backend JWT.
    final accessToken = 'token_$userId';
    final refreshToken = 'refresh_$userId';

    _currentSession = Session(
      userId: userId,
      email: email,
      name: name,
      role: role,
      accessToken: accessToken,
      refreshToken: refreshToken,
    );

    // Persist to localStorage
    await TokenStorage.saveTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      userEmail: email,
    );

    debugPrint('✅ AuthService.login: Session created for userId=$userId');
  }

  /// Restore session from localStorage (called on app startup).
  static Future<void> restoreSession() async {
    try {
      final userId = await TokenStorage.getUserId();
      final accessToken = await TokenStorage.getAccessToken();
      final refreshToken = await TokenStorage.getRefreshToken();
      final email = await TokenStorage.getUserEmail();

      if (userId != null && accessToken != null && refreshToken != null && email != null) {
        _currentSession = Session(
          userId: userId,
          email: email,
          name: email.split('@').first, // Extract name from email
          role: 'farmer', // Default role
          accessToken: accessToken,
          refreshToken: refreshToken,
        );
        debugPrint('✅ AuthService.restoreSession: Session restored for userId=$userId');
      } else {
        debugPrint('⚠️ AuthService.restoreSession: No valid tokens found');
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
