import 'package:flutter/material.dart';

/// 🎨 Palette de couleurs centralisée
/// Utilise ces couleurs partout dans l'app pour garantir la cohérence
class AppColors {
  // ========== COULEURS PRIMAIRES ==========
  // Palette brune/caramel (primaire)
  static const Color primary = Color.fromARGB(181, 156, 78, 47); // Espresso (marron foncé principal)
  static const Color primaryLight = Color.fromARGB(228, 126, 67, 24); // Coffee (marron moyen)
  static const Color accent = Color(0xFFAB7743); // Caramel (doré accent)
  
  // Couleurs neutres - Light Mode
  static const Color lightBg = Color(0xFFF5F1E8); // Beige clair
  static const Color lightBgAlt = Color(0xFFFFFFFF); // Blanc pur
  static const Color lightCardBg = Color(0xFFFAFAFA); // Gris très clair
  
  // Couleurs neutres - Dark Mode
  static const Color darkBg = Color(0xFF0A0A0A); // Noir très foncé
  static const Color darkBgAlt = Color(0xFF121212); // Noir
  static const Color darkCardBg = Color(0xFF1A1A1A); // Gris très foncé
  
  // ========== TEXTE ==========
  static const Color textLight = Color(0xFF1A1A1A); // Texte sur fond clair
  static const Color textDark = Color(0xFFFFFFFF); // Texte sur fond sombre
  static const Color textSecondaryLight = Color(0xFF6B6B6B); // Texte secondaire clair
  static const Color textSecondaryDark = Color(0xFFB0B0B0); // Texte secondaire sombre
  
  // ========== STATUTS & FEEDBACK ==========
  static const Color success = Color(0xFF27AE60); // Vert succès
  static const Color error = Color(0xFFE74C3C); // Rouge erreur
  static const Color warning = Color(0xFFF39C12); // Orange avertissement
  static const Color info = Color(0xFF3498DB); // Bleu info
  
  // ========== BORDURES & DIVIDERS ==========
  static const Color borderLight = Color(0xFFE8E2D8); // Bordure sur fond clair
  static const Color borderDark = Color(0xFF2C2C2C); // Bordure sur fond sombre
  
  // ========== MÉTHODES UTILITAIRES ==========
  
  /// Retourne la couleur de fond adaptée au thème
  static Color getBgColor(bool isDarkMode) {
    return isDarkMode ? darkBgAlt : lightBg;
  }
  
  /// Retourne la couleur de carte adaptée au thème
  static Color getCardBgColor(bool isDarkMode) {
    return isDarkMode ? darkCardBg : lightCardBg;
  }
  
  /// Retourne la couleur de texte adaptée au thème
  static Color getTextColor(bool isDarkMode) {
    return isDarkMode ? textDark : textLight;
  }
  
  /// Retourne la couleur de texte secondaire adaptée au thème
  static Color getSecondaryTextColor(bool isDarkMode) {
    return isDarkMode ? textSecondaryDark : textSecondaryLight;
  }
  
  /// Retourne la couleur de bordure adaptée au thème
  static Color getBorderColor(bool isDarkMode) {
    return isDarkMode ? borderDark : borderLight;
  }
  
  /// Retourne une couleur avec opacité adaptée au thème
  static Color withOpacityByTheme(Color color, double opacity, bool isDarkMode) {
    return color.withOpacity(opacity);
  }
}
