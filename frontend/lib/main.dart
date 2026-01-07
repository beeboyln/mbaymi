import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mbaymi/screens/home_screen.dart';
import 'package:mbaymi/screens/login_screen.dart';
import 'package:mbaymi/screens/register_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env');
  runApp(const MbaymiApp());
}

class MbaymiApp extends StatelessWidget {
  const MbaymiApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mbaymi',
      theme: ThemeData(
        primarySwatch: Colors.green,
        useMaterial3: true,
        brightness: Brightness.light,
      ),
      home: const HomeScreen(userId: null),
      onGenerateRoute: (settings) {
        if (settings.name == '/home') {
          final arg = settings.arguments;
          int? userId;
          if (arg is int) userId = arg;
          if (arg is Map && arg['id'] != null) userId = arg['id'] as int;
          return MaterialPageRoute(
            builder: (context) => HomeScreen(userId: userId),
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
