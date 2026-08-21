import 'package:flutter/material.dart';
import 'package:mbaymi/utils/app_colors.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A0A0A) : AppColors.lightBg,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Logo avec animation
            ScaleTransition(
              scale: Tween(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
              ),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B8E23).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  '🌾',
                  style: TextStyle(fontSize: 60),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Savana',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w200,
                letterSpacing: -0.6,
                color: isDark ? Colors.white : const Color(0xFF0A0A0A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Chargement...',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: isDark ? Colors.white60 : Colors.black54,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 40),
            // Minimal progress indicator
            SizedBox(
              width: 200,
              height: 3,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(2),
                child: LinearProgressIndicator(
                  backgroundColor: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.05),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    const Color(0xFF6B8E23).withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
