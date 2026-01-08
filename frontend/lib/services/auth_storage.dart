import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';

class AuthStorage {
  static const _keyUserId = 'mbaymi_user_id';

  static Future<void> saveUserId(int id) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setInt(_keyUserId, id);
    } catch (e) {
      debugPrint('⚠️ AuthStorage.saveUserId failed: $e');
      // Silently fail on web if shared_preferences is not available
    }
  }

  static Future<int?> getUserId() async {
    try {
      final sp = await SharedPreferences.getInstance();
      return sp.containsKey(_keyUserId) ? sp.getInt(_keyUserId) : null;
    } catch (e) {
      debugPrint('⚠️ AuthStorage.getUserId failed: $e');
      // Return null on web if shared_preferences is not available
      return null;
    }
  }

  static Future<void> clear() async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.remove(_keyUserId);
    } catch (e) {
      debugPrint('⚠️ AuthStorage.clear failed: $e');
      // Silently fail on web if shared_preferences is not available
    }
  }
}
