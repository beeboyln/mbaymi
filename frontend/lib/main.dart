import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'dart:io' as io;
import 'package:mbaymi/screens/home_screen.dart';
import 'package:mbaymi/screens/auth/splash_screen.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/app_bootstrap.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/services/cart_provider.dart';
import 'package:mbaymi/screens/auth/login_screen.dart';
import 'package:mbaymi/screens/auth/register_screen.dart';
import 'package:mbaymi/screens/veterinarian/veterinarian_setup_screen.dart';
import 'package:mbaymi/screens/veterinarian/edit_veterinarian_profile_screen.dart';
import 'package:mbaymi/screens/veterinarian/veterinarian_profile_detail_screen.dart';
import 'package:mbaymi/screens/veterinarian/veterinarian_profile_screen.dart';
import 'package:mbaymi/screens/admin/admin_dashboard_screen.dart';
import 'package:mbaymi/screens/farm/crop_problems_screen.dart';
import 'package:mbaymi/screens/farm/farm_profile_screen.dart';
import 'package:mbaymi/screens/farm/farm_detail_screen.dart';
import 'package:mbaymi/screens/social/user_profile_screen.dart';
import 'package:mbaymi/screens/settings_screen.dart';
import 'package:mbaymi/screens/livestock/animal_detail_screen.dart';
import 'package:mbaymi/models/animal.dart';
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
    
    // 1️⃣ Load .env file (NON-BLOCKING)
    try {
      await dotenv.load(fileName: '.env');
      debugPrint('✅ .env loaded successfully');
      debugPrint('API_BASE_URL: ${dotenv.env['API_BASE_URL']}');
    } catch (e) {
      debugPrint('⚠️ Failed to load .env: $e');
      if (kIsWeb) {
        debugPrint('⚠️ .env file not found on web.');
      }
    }

    // 2️⃣ Initialize locale data (REQUIRED for date formatting)
    try {
      await initializeDateFormatting('fr_FR');
      Intl.defaultLocale = 'fr_FR';
      debugPrint('✅ Locale initialized: fr_FR');
    } catch (e) {
      debugPrint('⚠️ Locale init failed: $e');
      await initializeDateFormatting();
    }

    // 3️⃣ Initialize ThemeProvider (FAST, local)
    try {
      await ThemeProvider().init();
      debugPrint('✅ ThemeProvider initialized');
    } catch (e) {
      debugPrint('⚠️ ThemeProvider init failed: $e');
    }

    // 4️⃣ Setup global error handlers
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      debugPrint('🔥 FLUTTER ERROR: ${details.exception}');
    };

    // 5️⃣ Limit image cache to prevent memory issues (IMPORTANT for web)
    PaintingBinding.instance.imageCache.maximumSize = 50;
    PaintingBinding.instance.imageCache.maximumSizeBytes = 50 << 20; // 50 MB

    // 6️⃣ BUILD APP with AppBootstrap (async initialization)
    try {
      debugPrint('🎨 Building MbaymiApp with AppBootstrap...');
      runApp(const MbaymiApp());
      debugPrint('✅ MbaymiApp initialized successfully');
    } catch (e, stack) {
      debugPrint('💥 Failed to initialize app: $e');
      debugPrint('Stack: $stack');
      rethrow;
    }
  }, (error, stack) {
    debugPrint('💥 ZONE ERROR (CRITICAL): $error');
    debugPrint('Stack: $stack');
  });
}

class MbaymiApp extends StatefulWidget {
  const MbaymiApp({super.key});

  @override
  State<MbaymiApp> createState() => _MbaymiAppState();
}

class _MbaymiAppState extends State<MbaymiApp> {
  late StreamSubscription _authSubscription;
  int? _lastUserId;
  late StreamSubscription _bootstrapSubscription;
  bool _bootstrapComplete = false;

  @override
  void initState() {
    super.initState();
    _lastUserId = AuthService.currentSession?.userId;
    // Initialize bootstrap immediately with high priority
    _initializeApp();
    
    // 🔍 Listen to auth state changes (every 2 seconds, less energy consuming)
    _authSubscription = Stream.periodic(const Duration(seconds: 2)).listen((_) {
      if (mounted) {
        final currentUserId = AuthService.currentSession?.userId;
        if (_lastUserId != currentUserId) {
          _lastUserId = currentUserId;
          setState(() {});
        }
      }
    });
  }

  /// Initialize app asynchronously WITHOUT BLOCKING UI
  void _initializeApp() {
    // Listen to bootstrap completion
    _bootstrapSubscription = AppBootstrap().onBootstrapComplete.listen((state) {
      if (mounted) {
        debugPrint('✅ Bootstrap complete: auth=${state.authRestored}');
        setState(() {
          _bootstrapComplete = true;
        });
      }
    });

    // START bootstrap asynchronously (fire-and-forget)
    AppBootstrap().initialize().then((state) {
      debugPrint('✅ AppBootstrap.initialize() completed');
    }).catchError((e) {
      debugPrint('⚠️ AppBootstrap.initialize() error: $e');
    });
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _bootstrapSubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<ThemeProvider>(
          create: (_) => ThemeProvider(),
        ),
        ChangeNotifierProvider<CartProvider>(
          create: (_) => CartProvider(),
        ),
      ],
      child: Consumer<ThemeProvider>(
        builder: (context, themeProvider, _) {
          // Read auth state from AuthService (stateless read)
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
            // Always show splash first, then home when bootstrap is complete
            home: _bootstrapComplete 
              ? HomeScreen(key: ValueKey('home_${userId ?? 0}'), userId: userId)
              : const SplashScreen(),
            routes: {
              '/login': (context) => const LoginScreen(),
              '/register': (context) => const RegisterScreen(),
              '/veterinarian-setup': (context) => const VeterinarianSetupScreen(),
              '/edit-veterinarian-profile': (context) => const EditVeterinarianProfileScreen(),
              '/veterinarian-profile': (context) => const VeterinarianProfileScreen(),
              '/admin-dashboard': (context) => const AdminDashboardScreen(),
              '/settings': (context) => const SettingsScreen(),
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
              // Farm Detail
              if (settings.name == '/farm-detail') {
                final farmId = settings.arguments as int?;
                if (farmId != null) {
                  return MaterialPageRoute(
                    builder: (context) => FarmDetailScreen(
                      farmId: farmId,
                      farmData: {'id': farmId},
                      isDarkMode: Theme.of(context).brightness == Brightness.dark,
                      readOnly: true,
                    ),
                  );
                }
              }
              // Livestock Detail
              if (settings.name == '/livestock-detail') {
                final livestockId = settings.arguments as int?;
                final currentUserId = AuthService.currentSession?.userId;
                if (livestockId != null && currentUserId != null) {
                  return MaterialPageRoute(
                    builder: (context) => AnimalDetailScreen(
                      animal: Animal(
                        id: livestockId,
                        userId: currentUserId,
                        name: 'Animal',
                        species: 'unknown',
                        gender: 'unknown',
                        dateOfBirth: DateTime.now(),
                        healthStatus: 'unknown',
                        reproductiveStatus: 'unknown',
                        createdAt: DateTime.now(),
                        updatedAt: DateTime.now(),
                      ),
                    ),
                  );
                }
              }
              // Crop Problems
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
              // Farm Profile
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
              // User Profile
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