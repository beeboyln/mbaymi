import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/screens/home_screen.dart';
import 'package:mbaymi/services/auth_storage.dart';
import 'package:mbaymi/screens/login_screen.dart';
import 'package:mbaymi/screens/register_screen.dart';

Future<void> main() async {
  // Run all initialization inside the same zone as runApp to avoid "Zone mismatch".
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    await dotenv.load(fileName: '.env');

    // Initialize intl locale data required for DateFormat with locales (e.g. 'fr_FR')
    try {
      await initializeDateFormatting('fr_FR');
      Intl.defaultLocale = 'fr_FR';
    } catch (_) {
      // Fallback: initialize default data
      await initializeDateFormatting();
      // leave defaultLocale unset (will use system/default)
    }

    // Try to restore stored user id to keep user logged in after reloads
    final storedUserId = await AuthStorage.getUserId();

    // Global error handling so uncaught Flutter errors are logged in console
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      debugPrint('🔥 FlutterError: ${details.exception}');
      if (details.stack != null) debugPrint(details.stack.toString());
    };

    runApp(MbaymiApp(initialUserId: storedUserId));
  }, (error, stack) {
    // Log uncaught async/zone errors
    debugPrint('💥 ZONE ERROR: $error');
    debugPrint(stack.toString());
  });
}

class MbaymiApp extends StatelessWidget {
  final int? initialUserId;

  const MbaymiApp({Key? key, this.initialUserId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mbaymi',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: HomeScreen(userId: initialUserId),
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final arg = settings.arguments;
          int? userId;
          if (arg is int) userId = arg;
          if (arg is Map && arg['id'] != null) {
            final raw = arg['id'];
            if (raw is int) {
              userId = raw;
            } else {
              userId = int.tryParse(raw.toString());
            }
          }
          return MaterialPageRoute(
            builder: (context) => HomeScreen(userId: userId ?? initialUserId),
          );
        }
        return null;
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
      },
    );
  }
}
