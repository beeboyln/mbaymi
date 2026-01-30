import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io' as io;
import 'package:mbaymi/screens/home_screen.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/screens/login_screen.dart';
import 'package:mbaymi/screens/register_screen.dart';
import 'package:mbaymi/screens/veterinarian_setup_screen.dart';
import 'package:mbaymi/screens/edit_veterinarian_profile_screen.dart';
import 'package:mbaymi/screens/veterinarian_profile_detail_screen.dart';
import 'package:mbaymi/screens/veterinarian_profile_screen.dart';
import 'package:mbaymi/screens/crop_problems_screen.dart';
import 'package:mbaymi/screens/farm_profile_screen.dart';
import 'package:mbaymi/screens/farm_detail_screen.dart';
import 'package:mbaymi/screens/user_profile_screen.dart';
import 'package:mbaymi/screens/animal_detail_screen.dart';
import 'package:mbaymi/utils/app_colors.dart';

Future<void> main() async {
  // Run all initialization inside the same zone as runApp to avoid "Zone mismatch".
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    debugPrint('═══════════════════════════════════════════════════════');
    debugPrint('🚀 MBAYMI APP STARTUP - ${DateTime.now()}');
    debugPrint('Platform: ${kIsWeb ? "web" : io.Platform.operatingSystem}');
    debugPrint('Debug Mode: $kDebugMode');
    debugPrint('═══════════════════════════════════════════════════════');
    
    // Load .env file with fallback for mobile (where .env may not exist)
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('✅ .env loaded successfully');
      debugPrint('API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
    } catch (e) {
      debugPrint('⚠️ Failed to load .env: $e');
      debugPrint('Stack: ${StackTrace.current}');
      // On mobile, .env might not be accessible as a file. That's OK - use defaults.
      // The app will work with environment variables or defaults defined in the code.
      if (kIsWeb) {
        // On web, .env should exist. Log the error but continue.
        debugPrint('⚠️ .env file not found on web. Some features may not work.');
      }
    }

    // Initialize intl locale data required for DateFormat with locales (e.g. 'fr_FR')
    try {
      await initializeDateFormatting('fr_FR');
      Intl.defaultLocale = 'fr_FR';
      debugPrint('✅ Locale initialized: fr_FR');
    } catch (e) {
      // Fallback: initialize default data
      debugPrint('⚠️ Locale init failed for fr_FR: $e');
      await initializeDateFormatting();
      // leave defaultLocale unset (will use system/default)
    }

    // Restore session from localStorage (JWT style persistence)
    debugPrint('🔄 Restoring session from localStorage...');
    try {
      await AuthService.restoreSession();
      debugPrint('✅ Session restored. User ID: ${AuthService.currentSession?.userId}');
    } catch (e) {
      debugPrint('⚠️ Session restore failed: $e');
      debugPrint('Stack: ${StackTrace.current}');
    }

    // 🏥 Wake up backend on cold start (Render free tier)
    await _wakeupBackend();

    // Initialiser le ThemeProvider
    try {
      await ThemeProvider().init();
      debugPrint('✅ ThemeProvider initialized');
    } catch (e) {
      debugPrint('⚠️ ThemeProvider init failed: $e');
      debugPrint('Stack: ${StackTrace.current}');
    }

    // Global error handling so uncaught Flutter errors are logged in console
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      debugPrint('🔥 FLUTTER ERROR: ${details.exception}');
      if (details.stack != null) debugPrint('Stack: ${details.stack.toString()}');
    };

    try {
      debugPrint('🎨 Building MbaymiApp...');
      runApp(const MbaymiApp());
      debugPrint('✅ MbaymiApp initialized successfully');
    } catch (e, stack) {
      debugPrint('💥 Failed to initialize app: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }, (error, stack) {
    // Log uncaught async/zone errors
    debugPrint('💥 ZONE ERROR (CRITICAL): $error');
    debugPrint('Stack: $stack');
  });
}

/// 🏥 Wake up backend on app launch (handles Render free tier cold start)
Future<void> _wakeupBackend() async {
  try {
    final apiUrl = dotenv.env['API_BASE_URL'] ?? 'https://burning-yetty-bigboyme-428f3176.koyeb.app/api';
    final healthUrl = Uri.parse('$apiUrl/health');
    
    debugPrint('🏥 Attempting to wake up backend at $healthUrl...');
    
    try {
      final response = await http.get(healthUrl).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        debugPrint('✅ Backend is awake and ready!');
      } else {
        debugPrint('⚠️ Backend returned status code: ${response.statusCode}');
      }
    } on TimeoutException {
      debugPrint('⚠️ Health check TIMEOUT (cold start likely), will retry on first request');
    }
  } catch (e) {
    // Silently fail - will retry on first real request
    debugPrint('⚠️ Health check error: $e');
  }
}

class MbaymiApp extends StatefulWidget {
  const MbaymiApp({super.key});

  @override
  State<MbaymiApp> createState() => _MbaymiAppState();
}

class _MbaymiAppState extends State<MbaymiApp> {
  late StreamSubscription _authSubscription;
  int? _lastUserId;

  @override
  void initState() {
    super.initState();
    _lastUserId = AuthService.currentSession?.userId;
    
    // 🔍 Écouter les changements d'authentification de manière plus efficace
    // Vérifier toutes les 2 secondes au lieu de 500ms (moins consommateur d'énergie)
    _authSubscription = Stream.periodic(const Duration(seconds: 2)).listen((_) {
      if (mounted) {
        final currentUserId = AuthService.currentSession?.userId;
        // Ne rebuild que si l'userId a changé
        if (_lastUserId != currentUserId) {
          _lastUserId = currentUserId;
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ThemeProvider>(
      create: (_) => ThemeProvider(),
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Always show HomeScreen (read-only mode for guests, full access for authenticated users)
          final userId = AuthService.currentSession?.userId;

          return MaterialApp(
            title: 'Mbaymi',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              primarySwatch: Colors.green,
              useMaterial3: true,
              brightness: Brightness.light,
              scaffoldBackgroundColor: const Color(0xFFF8F9FA),
              appBarTheme: const AppBarTheme(
                backgroundColor: AppColors.lightBg,
                foregroundColor: Colors.black87,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
            ),
            darkTheme: ThemeData(
              primarySwatch: Colors.green,
              useMaterial3: true,
              brightness: Brightness.dark,
              scaffoldBackgroundColor: const Color(0xFF0A0A0A),
              appBarTheme: const AppBarTheme(
                backgroundColor: Color(0xFF1A1A1A),
                foregroundColor: Colors.white,
                elevation: 0,
                surfaceTintColor: Colors.transparent,
              ),
            ),
            themeMode: themeProvider.themeMode,
            home: HomeScreen(key: ValueKey('home_${userId ?? 0}'), userId: userId),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/veterinarian-setup': (context) => const VeterinarianSetupScreen(),
              '/edit-veterinarian-profile': (context) => const EditVeterinarianProfileScreen(),
              '/veterinarian-profile': (context) => const VeterinarianProfileScreen(),
            },
            onGenerateRoute: (settings) {
              // Veterinarian Profile Detail
              if (settings.name?.startsWith('/veterinarian-profile/') == true) {
                final vetId = settings.name!.replaceFirst('/veterinarian-profile/', '');
                return MaterialPageRoute(
                  builder: (context) => VeterinarianProfileDetailScreen(
                    veterinarianId: vetId,
                  ),
                );
              }
              // 🌾 Farm Detail (from authorization request)
              if (settings.name == '/farm-detail') {
                final farmId = settings.arguments as int?;
                if (farmId != null) {
                  return MaterialPageRoute(
                    builder: (context) => FarmDetailScreen(
                      farmId: farmId,
                      farmData: {'id': farmId},
                      isDarkMode: Theme.of(context).brightness == Brightness.dark,
                      readOnly: true, // Visiteur ne peut pas éditer
                    ),
                  );
                }
              }
              // 🐑 Livestock Detail (from authorization request)
              if (settings.name == '/livestock-detail') {
                final livestockId = settings.arguments as int?;
                if (livestockId != null) {
                  return MaterialPageRoute(
                    builder: (context) => AnimalDetailScreen(
                      livestockId: livestockId,
                      animal: {},
                      isDarkMode: Theme.of(context).brightness == Brightness.dark,
                    ),
                  );
                }
              }
              // 🌾 Crop Problems Screen
              if (settings.name?.startsWith('/crop-problems/') == true) {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => CropProblemsScreen(
                    farmId: args['farmId'] as int,
                    cropId: args['cropId'] as int,
                    userId: args['userId'] as int,
                    cropName: args['cropName'] as String,
                    isDarkMode: args['isDarkMode'] as bool? ?? false,
                  ),
                );
              }
              // 🌾 Farm Profile Screen
              if (settings.name?.startsWith('/farm-profile/') == true) {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => FarmProfileScreen(
                    farmId: args['farmId'] as int,
                    userId: args['userId'] as int,
                    isDarkMode: args['isDarkMode'] as bool? ?? false,
                  ),
                );
              }
              // 👤 User Profile Screen
              if (settings.name?.startsWith('/user-profile/') == true) {
                final args = settings.arguments as Map<String, dynamic>;
                return MaterialPageRoute(
                  builder: (context) => UserProfileScreen(
                    userId: args['userId'] as int,
                    isDarkMode: args['isDarkMode'] as bool? ?? false,
                  ),
                );
              }
              return null;
            },
          );
        },
      ),
    );
  }
}

class SplashScreen extends StatefulWidget {
  final int? userId;
  const SplashScreen({super.key, this.userId});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Afficher le splash pendant 2 secondes, puis passer à HomeScreen
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/', arguments: widget.userId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.lightBg,
      body: Center(
        child: Image.asset(
          'assets/images/aa.png',
          height: 200,
          width: 200,
          fit: BoxFit.contain,
        ),
      ),
    );
  }
}