import 'package:flutter/foundation.dart';
import 'dart:html' as html;

/// TokenStorage uses browser localStorage for web persistence.
/// Tokens survive page refresh and are shared across tabs.
class TokenStorage {
  static const _keyAccessToken = 'mbaymi_access_token';
  static const _keyRefreshToken = 'mbaymi_refresh_token';
  static const _keyUserId = 'mbaymi_user_id';
  static const _keyUserEmail = 'mbaymi_user_email';

  /// Save tokens to localStorage (web) or fallback in-memory.
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String userEmail,
  }) async {
    try {
      final storage = html.window.localStorage;
      storage[_keyAccessToken] = accessToken;
      storage[_keyRefreshToken] = refreshToken;
      storage[_keyUserId] = userId.toString();
      storage[_keyUserEmail] = userEmail;
      debugPrint('✅ Tokens saved to localStorage');
    } catch (e) {
      debugPrint('⚠️ TokenStorage.saveTokens failed: $e');
    }
  }

  /// Retrieve access token from localStorage.
  static Future<String?> getAccessToken() async {
    try {
      final storage = html.window.localStorage;
      return storage[_keyAccessToken];
    } catch (e) {
      debugPrint('⚠️ TokenStorage.getAccessToken failed: $e');
      return null;
    }
  }

  /// Retrieve refresh token from localStorage.
  static Future<String?> getRefreshToken() async {
    try {
      final storage = html.window.localStorage;
      return storage[_keyRefreshToken];
    } catch (e) {
      debugPrint('⚠️ TokenStorage.getRefreshToken failed: $e');
      return null;
    }
  }

  /// Retrieve userId from localStorage.
  static Future<int?> getUserId() async {
    try {
      final storage = html.window.localStorage;
      final raw = storage[_keyUserId];
      if (raw == null) return null;
      return int.tryParse(raw);
    } catch (e) {
      debugPrint('⚠️ TokenStorage.getUserId failed: $e');
      return null;
    }
  }

  /// Retrieve userEmail from localStorage.
  static Future<String?> getUserEmail() async {
    try {
      final storage = html.window.localStorage;
      return storage[_keyUserEmail];
    } catch (e) {
      debugPrint('⚠️ TokenStorage.getUserEmail failed: $e');
      return null;
    }
  }

  /// Clear all tokens (logout).
  static Future<void> clear() async {
    try {
      final storage = html.window.localStorage;
      storage.remove(_keyAccessToken);
      storage.remove(_keyRefreshToken);
      storage.remove(_keyUserId);
      storage.remove(_keyUserEmail);
      debugPrint('✅ Tokens cleared from localStorage');
    } catch (e) {
      debugPrint('⚠️ TokenStorage.clear failed: $e');
    }
  }
}
