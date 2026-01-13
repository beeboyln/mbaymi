import 'package:flutter/material.dart';

/// 🎨 App Theme - Centralized styling
class AppTheme {
  // Couleurs principales
  static const Color primaryColor = Color(0xFF6B8E23);
  static const Color primaryLight = Color(0xFF8BA63D);
  static const Color primaryDark = Color(0xFF4A5A1A);
  static const Color accentColor = Color(0xFFFFA726);
  
  // Couleurs de fond
  static const Color bgLight = Color(0xFFF8F9FA);
  static const Color bgDark = Color(0xFF0A0A0A);
  
  // Couleurs de carte
  static const Color cardLight = Color(0xFFFFFFFF);
  static const Color cardDark = Color(0xFF1A1A1A);
  
  // Couleurs de texte
  static const Color textLight = Color(0xFF1A1A1A);
  static const Color textDark = Colors.white;
  static const Color textSecondaryLight = Color(0xFF6B6B6B);
  static const Color textSecondaryDark = Color(0xFF8E8E93);
  
  // Couleurs de statut
  static const Color statusPending = Color(0xFFFFA726);
  static const Color statusActive = Color(0xFF66BB6A);
  static const Color statusInProgress = Color(0xFF42A5F5);
  static const Color statusCompleted = Color(0xFFAB47BC);
  
  static const Color errorColor = Color(0xFFEF5350);
  static const Color successColor = Color(0xFF66BB6A);
  static const Color warningColor = Color(0xFFFFA726);

  // Fonctions utilitaires pour mode sombre/clair
  static Color getBackground(bool isDark) => isDark ? bgDark : bgLight;
  static Color getCardColor(bool isDark) => isDark ? cardDark : cardLight;
  static Color getTextColor(bool isDark) => isDark ? textDark : textLight;
  static Color getSecondaryTextColor(bool isDark) => 
      isDark ? textSecondaryDark : textSecondaryLight;

  // Border colors
  static Color getBorderColor(bool isDark) =>
      isDark ? Colors.white12 : Colors.black12;
}
