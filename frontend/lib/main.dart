import 'package:flutter/material.dart';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/screens/home_screen.dart';
import 'package:mbaymi/services/auth_storage.dart';
import 'package:mbaymi/screens/login_screen.dart';
import 'package:mbaymi/screens/register_screen.dart';

Future<void> main() async {
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
  };

  // Run the app inside a guarded zone to catch uncaught async errors
  runZonedGuarded(() {
    runApp(MbaymiApp(initialUserId: storedUserId));
  }, (error, stack) {
    // You can send this to analytics or remote logging if desired
    // For now, print to console so it's visible in production logs
    // ignore: avoid_print
    print('Uncaught zone error: $error');
    // ignore: avoid_print
    print(stack);
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
