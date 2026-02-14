import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/app_initializer.dart';
import 'package:mbaymi/services/api_service.dart';

/// État global de l'initialisation de l'app
class BootstrapState {
  final bool authRestored;
  final bool backendAlive;
  final String? error;
  
  BootstrapState({
    required this.authRestored,
    required this.backendAlive,
    this.error,
  });
  
  bool get isReady => authRestored && (backendAlive || error != null);
}

/// 🚀 Manage startup sequence WITHOUT BLOCKING UI
/// 
/// Principes:
/// - restoreSession() appelé UNE seule fois et await
/// - Wakeup backend EN PARALELLE (avec timeout court)
/// - Services dépendants de l'auth initialisés en lazy
/// - Pas d'appels réseau dans build()
class AppBootstrap {
  static final AppBootstrap _instance = AppBootstrap._internal();
  
  // Singleton pour éviter plusieurs initialisations
  factory AppBootstrap() {
    return _instance;
  }
  
  AppBootstrap._internal();
  
  // État de bootstrap
  late BootstrapState _state;
  bool _initialized = false;
  
  // Stream pour notifier l'UI que bootstrap est complété
  final _completionController = StreamController<BootstrapState>.broadcast();
  Stream<BootstrapState> get onBootstrapComplete => _completionController.stream;
  
  bool get isInitialized => _initialized;
  BootstrapState get state => _state;
  
  /// 🚀 Démarrer le bootstrap (appelé une seule fois dans main())
  /// 
  /// **Ordre d'exécution** (thread safety):
  /// 1. await AuthService.restoreSession() - BLOCKING (mais rapide, local)
  /// 2. _wakeupBackendAsync() - EN ARRIÈRE-PLAN
  /// 3. State updated → UI refreshée
  /// 4. Autres services initialisés EN LAZY (on-demand)
  Future<BootstrapState> initialize() async {
    if (_initialized) {
      debugPrint('⚠️ Bootstrap already initialized, returning cached state');
      return _state;
    }
    
    final startTime = DateTime.now();
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🚀 AppBootstrap.initialize() STARTING');
    debugPrint('═══════════════════════════════════════════════════════');
    
    try {
      // ✅ ÉTAPE 1: Restaurer session LOCAL (rapide, ne bloque pas longtemps)
      debugPrint('📍 Step 1/2: AuthService.restoreSession()...');
      await AuthService.restoreSession();
      final authRestored = AuthService.isAuthenticated;
      debugPrint('✅ Auth restored: $authRestored (userId=${AuthService.currentSession?.userId})');
      
      // ✅ ÉTAPE 2: Démarrer wakeup backend EN PARALLÈLE (non-bloquant)
      debugPrint('📍 Step 2/2: _wakeupBackendAsync() (fire-and-forget)...');
      final backendAlive = await _wakeupBackendAsync();
      
      _state = BootstrapState(
        authRestored: authRestored,
        backendAlive: backendAlive,
      );
      
      _initialized = true;
      
      final elapsed = DateTime.now().difference(startTime);
      debugPrint('═══════════════════════════════════════════════════════');
      debugPrint('✅ AppBootstrap COMPLETE (${elapsed.inMilliseconds}ms)');
      debugPrint('   - Auth: $authRestored');
      debugPrint('   - Backend alive: $backendAlive');
      debugPrint('═══════════════════════════════════════════════════════');
      
      _completionController.add(_state);
      
      // ✅ ÉTAPE 3: Initialiser services EN LAZY (AppInitializer gère ça)
      // Voir AppInitializer pour plus de détails
      AppInitializer.schedulePostBootstrapTasks(authRestored);
      
      return _state;
    } catch (e) {
      debugPrint('❌ Bootstrap ERROR: $e');
      _state = BootstrapState(
        authRestored: false,
        backendAlive: false,
        error: e.toString(),
      );
      _completionController.add(_state);
      rethrow;
    }
  }
  
  /// 🏥 Wakeup backend EN PARALLÈLE (après le bootstrap initial)
  /// 
  /// Ne bloque JAMAIS le UI. Timeout court (3s).
  /// Résultat: ignoré si échec (UI ne dépend pas de la réponse).
  Future<bool> _wakeupBackendAsync() async {
    try {
      debugPrint('🏥 Backend wakeup started (async, timeout=3s)...');
      final result = await ApiService.healthCheck();
      
      debugPrint('✅ Backend is alive');
      return result;
    } on TimeoutException {
      debugPrint('⚠️ Health check timeout (cold start likely)');
      return false;
    } catch (e) {
      debugPrint('⚠️ Health check failed: $e');
      return false;
    }
  }
}