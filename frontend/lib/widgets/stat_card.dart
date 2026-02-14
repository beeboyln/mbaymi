import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class StatCard extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;
  final dynamic value;
  final String? subtitle;
  final Color? subtitleColor;
  final VoidCallback? onTap;
  final bool isDarkMode;

  const StatCard({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.value,
    this.subtitle,
    this.subtitleColor,
    this.onTap,
    required this.isDarkMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: isDarkMode 
                ? Colors.black.withAlpha((0.25 * 255).toInt())
                : Colors.black.withAlpha((0.08 * 255).toInt()),
              blurRadius: 12,
              offset: const Offset(0, 4),
              spreadRadius: 1,
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icône en haut
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: iconColor.withAlpha((0.12 * 255).toInt()),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor.withAlpha((0.75 * 255).toInt()), size: 16),
            ),
            const SizedBox(height: 16),
            // Valeur du nombre - centrée
            Text(
              '$value',
              style: TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.w300,
                color: isDarkMode 
                  ? Colors.white.withAlpha((0.95 * 255).toInt())
                  : const Color(0xFF0A0A0A).withAlpha((0.85 * 255).toInt()),
                letterSpacing: -0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            // Libellé - centré
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: isDarkMode 
                  ? Colors.white.withAlpha((0.65 * 255).toInt())
                  : Colors.black.withAlpha((0.55 * 255).toInt()),
                letterSpacing: 0.2,
              ),
              textAlign: TextAlign.center,
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 10),
              Text(
                subtitle!,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w300,
                  color: (subtitleColor ?? iconColor).withAlpha((0.65 * 255).toInt()),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
