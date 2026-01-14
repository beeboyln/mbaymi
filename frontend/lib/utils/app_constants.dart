/// 🎨 Configuration centralisée des couleurs de l'app
class AppColors {
  // 🟢 Verts primaires
  static const int primaryGreen = 0xFF6B8E23;
  static const int darkGreen = 0xFF3D6B1F;
  static const int lightGreen = 0xFF2D5016;
  
  // 🟤 Marrons/Earth tones
  static const int brown = 0xFF8B6B4D;
  static const int darkBrown = 0xFFD2691E;
  
  // ⬛ Grays
  static const int darkGray = 0xFF0D0D0D;
  static const int cardDark = 0xFF1A1A1A;
  static const int cardLight = 0xFFFFFFFF;
  static const int bgLight = 0xFFFAFAFA;
  static const int bgDark = 0xFF121212;
  static const int bgCard = 0xFF0D0D0D;
  
  // ❌ Status
  static const int errorRed = 0xFFE74C3C;
  static const int successGreen = 0xFF27AE60;
  static const int warningOrange = 0xFFF39C12;
  static const int infoBlue = 0xFF3498DB;
}

/// 📏 Configuration des dimensions
class AppDimensions {
  // Padding/Spacing
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;
  
  // Border radius
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;
  
  // Icon sizes
  static const double iconSmall = 16.0;
  static const double iconMedium = 20.0;
  static const double iconLarge = 24.0;
  static const double iconXL = 32.0;
}

/// 🕐 Durations
class AppDurations {
  static const Duration animationFast = Duration(milliseconds: 200);
  static const Duration animationNormal = Duration(milliseconds: 300);
  static const Duration animationSlow = Duration(milliseconds: 500);
  
  static const Duration debounce = Duration(milliseconds: 500);
  static const Duration authPoll = Duration(seconds: 2);
  
  static const Duration requestTimeout = Duration(seconds: 15);
}

/// 🌐 API & Network
class AppAPI {
  static const String baseUrl = String.fromEnvironment('API_BASE_URL', defaultValue: 'http://localhost:8000');
  static const int maxRetries = 3;
  static const Duration initialRetryDelay = Duration(milliseconds: 500);
}

/// 🎯 App-wide strings & constraints
class AppConstants {
  // App version
  static const String appVersion = '1.0.0';
  
  // Cache TTL
  static const Duration cacheTTL = Duration(minutes: 5);
  
  // Pagination
  static const int itemsPerPage = 20;
  
  // Image constraints
  static const int maxImageSize = 5242880; // 5MB
  
  // Validation
  static const int minPasswordLength = 8;
  static const int maxNameLength = 100;
  
  // Features
  static const bool enableDebugLogs = true;
  static const bool enableAnalytics = false;
}
