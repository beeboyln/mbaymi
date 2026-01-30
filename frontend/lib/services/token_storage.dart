import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// TokenStorage uses shared_preferences for persistence.
/// On web, it uses browser localStorage (via shared_preferences web impl).
/// On mobile (Android/iOS), uses shared_preferences.
/// Tokens survive app restart and are unique per device.
class TokenStorage {
  static const _keyAccessToken = 'mbaymi_access_token';
  static const _keyRefreshToken = 'mbaymi_refresh_token';
  static const _keyUserId = 'mbaymi_user_id';
  static const _keyUserEmail = 'mbaymi_user_email';
  static const _keyUserRole = 'mbaymi_user_role';

  /// Save tokens to shared_preferences.
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
    required int userId,
    required String userEmail,
    String? userRole,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyAccessToken, accessToken);
      await prefs.setString(_keyRefreshToken, refreshToken);
      await prefs.setInt(_keyUserId, userId);
      await prefs.setString(_keyUserEmail, userEmail);
      if (userRole != null) {
        await prefs.setString(_keyUserRole, userRole);
      }
      debugPrint('✅ Tokens saved');
    } catch (e) {
      debugPrint('⚠️ TokenStorage.saveTokens failed: $e');
    }
  }

  /// Retrieve access token from shared_preferences.
  static Future<String?> getAccessToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyAccessToken);
    } catch (e) {
      debugPrint('⚠️ TokenStorage.getAccessToken failed: $e');
      return null;
    }
  }

  /// Retrieve refresh token from shared_preferences.
  static Future<String?> getRefreshToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyRefreshToken);
    } catch (e) {
      debugPrint('⚠️ TokenStorage.getRefreshToken failed: $e');
      return null;
    }
  }

  /// Retrieve userId from shared_preferences.
  static Future<int?> getUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(_keyUserId);
    } catch (e) {
      debugPrint('⚠️ TokenStorage.getUserId failed: $e');
      return null;
    }
  }

  /// Retrieve userEmail from shared_preferences.
  static Future<String?> getUserEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserEmail);
    } catch (e) {
      debugPrint('⚠️ TokenStorage.getUserEmail failed: $e');
      return null;
    }
  }

  /// Retrieve userRole from shared_preferences.
  static Future<String?> getUserRole() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_keyUserRole);
    } catch (e) {
      debugPrint('⚠️ TokenStorage.getUserRole failed: $e');
      return null;
    }
  }

  /// Clear all tokens (logout).
  static Future<void> clear() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyAccessToken);
      await prefs.remove(_keyRefreshToken);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyUserEmail);
      await prefs.remove(_keyUserRole);
      debugPrint('✅ Tokens cleared');
    } catch (e) {
      debugPrint('⚠️ TokenStorage.clear failed: $e');
    }
  }
}
