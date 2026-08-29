import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🎨 Theme Provider - Gère le mode sombre/clair globalement
class ThemeProvider extends ChangeNotifier {
  static final ThemeProvider _instance = ThemeProvider._internal();
  
  bool _isDarkMode = false;
  late SharedPreferences _prefs;

  factory ThemeProvider() {
    return _instance;
  }

  ThemeProvider._internal();

  /// Initialiser le provider (à appeler au démarrage)
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    _isDarkMode = _prefs.getBool('isDarkMode') ?? false;
    notifyListeners();
  }

  /// Getter pour isDarkMode
  bool get isDarkMode => _isDarkMode;

  /// Basculer le mode sombre
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    await _prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  /// Définir le mode sombre
  Future<void> setDarkMode(bool isDark) async {
    if (_isDarkMode == isDark) return;
    _isDarkMode = isDark;
    await _prefs.setBool('isDarkMode', _isDarkMode);
    notifyListeners();
  }

  /// Obtenir le ThemeMode pour MaterialApp
  ThemeMode get themeMode {
    return _isDarkMode ? ThemeMode.dark : ThemeMode.light;
  }
}

class AppCurrencyService {
  static const String defaultCurrency = 'FCFA';
  static const String storageKey = 'app_currency';

  static Future<String> getCurrency() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getString(storageKey);
    return (value == null || value.trim().isEmpty) ? defaultCurrency : value.trim().toUpperCase();
  }

  static Future<void> setCurrency(String currency) async {
    final prefs = await SharedPreferences.getInstance();
    final normalized = currency.trim();
    await prefs.setString(storageKey, normalized.isEmpty ? defaultCurrency : normalized.toUpperCase());
  }
}
