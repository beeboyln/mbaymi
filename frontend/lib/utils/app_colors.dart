import 'package:flutter/material.dart';

class AppColors {
  // Light mode background colors
  static const Color lightBg = Color(0xFFF5F1E8);
  static const Color lightBgAlt = Color(0xFFFFFFFF);
  
  // Dark mode background colors
  static const Color darkBg = Color(0xFF121212);
  static const Color darkBgAlt = Color(0xFF1E1E1E);
  
  // Text colors
  static const Color darkText = Color(0xFF000000);
  static const Color lightText = Color(0xFFFFFFFF);
  
  // Primary colors
  static const Color primary = Color(0xFF8B4513); // Brown
  static const Color primaryDark = Color(0xFF5C2E0F);
  
  // Status colors
  static const Color success = Color(0xFF4CAF50);
  static const Color error = Color(0xFFE53935);
  static const Color warning = Color(0xFFFB8C00);
  static const Color info = Color(0xFF1976D2);
  
  // Helper method to get background color based on theme
  static Color getBgColor(bool isDarkMode) {
    return isDarkMode ? darkBg : lightBg;
  }
  
  // Helper method to get text color based on theme
  static Color getTextColor(bool isDarkMode) {
    return isDarkMode ? lightText : darkText;
  }
}
