import 'package:flutter/material.dart';

Widget buildEmptyState({
  required IconData icon,
  required String title,
  required String description,
  required String buttonLabel,
  required Color color,
  bool isDarkMode = false,
  VoidCallback? onPressed,
}) {
  final bgColor = isDarkMode ? const Color(0xFF1a1a1a) : const Color(0xFFFAFAFA);
  final titleColor = isDarkMode ? Colors.white : const Color(0xFF2C2416);
  final descColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600;
  const btnColor = Color(0xFF8B7355);
  
  return Container(
    color: bgColor,
    child: Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56, color: color),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: titleColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: descColor,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: btnColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                elevation: 0,
              ),
              child: Text(
                buttonLabel,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
