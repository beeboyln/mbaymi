import 'package:shared_preferences/shared_preferences.dart';

class AuthStorage {
  static const _keyUserId = 'mbaymi_user_id';

  static Future<void> saveUserId(int id) async {
    final sp = await SharedPreferences.getInstance();
    await sp.setInt(_keyUserId, id);
  }

  static Future<int?> getUserId() async {
    final sp = await SharedPreferences.getInstance();
    return sp.containsKey(_keyUserId) ? sp.getInt(_keyUserId) : null;
  }

  static Future<void> clear() async {
    final sp = await SharedPreferences.getInstance();
    await sp.remove(_keyUserId);
  }
}
