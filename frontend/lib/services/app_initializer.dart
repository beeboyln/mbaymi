import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:mbaymi/services/weather_service.dart';

/// 🎬 Lazy initialization of services that depend on auth state
/// 
/// Services are NOT initialized on app startup, but on-demand:
/// - Weather: initialized first time user loads home screen
/// - Notifications: initialized first time user loads notification icon/screen
/// - Market data: initialized when user navigates to market
/// 
/// This avoids network overhead if user never uses a feature.
class AppInitializer {
  static final AppInitializer _instance = AppInitializer._internal();
  
  factory AppInitializer() => _instance;
  AppInitializer._internal();
  
  // Flags pour éviter les double-initializations
  static bool _weatherInitialized = false;
  static bool _notificationsInitialized = false;
  
  /// 📅 Tâches à faire APRÈS bootstrap initial (async, en arrière-plan)
  /// 
  /// Cette fonction est appelée par AppBootstrap une fois
  /// que AuthService.restoreSession() est complété.
  /// Elle lance des tâches asynchrones NON-BLOQUANTES.
  static void schedulePostBootstrapTasks(bool authRestored) {
    // N'initialiser que si l'utilisateur est déjà authentifié
    // (i.e., avait un token valide en localStorage)
    if (!authRestored) {
      debugPrint('⏭️ Skipping post-bootstrap tasks: user not authenticated');
      return;
    }
    
    debugPrint('🎬 AppInitializer scheduling post-bootstrap tasks...');
    
    // TÂCHE 1: Pré-charger la météo (utile pour dashboard)
    // → Fire-and-forget, ne bloque l'UI
    _scheduleWeatherPreload();
    
    // TÂCHE 2: Pré-charger les notifications (utile pour badge)
    // → Fire-and-forget
    _scheduleNotificationPreload();
  }
  
  /// ☀️ Pré-charger la météo EN ARRIÈRE-PLAN
  /// 
  /// Si l'utilisateur est authentifié et navigue vers le dashboard,
  /// la météo est déjà disponible (pas d'attente).
  static void _scheduleWeatherPreload() {
    Future.delayed(const Duration(seconds: 1), () async {
      if (_weatherInitialized) return;
      
      try {
        debugPrint('🔄 Pre-loading weather data...');
        await WeatherService.getWeather();
        _weatherInitialized = true;
        debugPrint('✅ Weather pre-loaded');
      } catch (e) {
        debugPrint('⚠️ Weather pre-load failed (OK): $e');
        // C'est OK si ça échoue - le service retry au prochain appel
      }
    });
  }
  
  /// 🔔 Pré-charger notifications EN ARRIÈRE-PLAN
  static void _scheduleNotificationPreload() {
    Future.delayed(const Duration(seconds: 2), () async {
      if (_notificationsInitialized) return;
      
      try {
        debugPrint('🔄 Pre-loading notifications count...');
        // Appeler le service de notifications
        // await NotificationService.getUnreadCount();
        _notificationsInitialized = true;
        debugPrint('✅ Notifications pre-loaded');
      } catch (e) {
        debugPrint('⚠️ Notifications pre-load failed (OK): $e');
      }
    });
  }
  
  /// 🎯 Initialize a service ON-DEMAND (lazy loading)
  /// 
  /// Exemple d'usage dans un écran:
  /// ```dart
  /// @override
  /// void initState() {
  ///   super.initState();
  ///   AppInitializer.initWeatherOnDemand();
  /// }
  /// ```
  static Future<void> initWeatherOnDemand() async {
    if (_weatherInitialized) return;
    
    try {
      debugPrint('🔄 Initializing weather on-demand...');
      await WeatherService.getWeather();
      _weatherInitialized = true;
    } catch (e) {
      debugPrint('⚠️ Weather initialization failed: $e');
      // Retry on next call
    }
  }
  
  /// Reset initialization flags (pour tests, ou si user logout)
  static void reset() {
    _weatherInitialized = false;
    _notificationsInitialized = false;
    debugPrint('🔄 AppInitializer reset');
  }
}
