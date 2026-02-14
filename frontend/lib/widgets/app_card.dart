import 'package:flutter/material.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/utils/app_radius.dart';
import 'package:mbaymi/utils/app_shadows.dart';
import 'package:mbaymi/utils/app_spacing.dart';

/// 📦 Carte réutilisable avec style cohérent
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;
  final BoxBorder? border;
  final List<BoxShadow>? shadow;
  final bool isDarkMode;

  const AppCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.borderRadius,
    this.border,
    this.shadow,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ??
        AppColors.getCardBgColor(isDarkMode);
    final radius = borderRadius ??
        BorderRadius.circular(AppRadius.lg);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: radius,
          border: border,
          boxShadow: shadow ?? AppShadows.elevationSmall,
        ),
        padding: padding ?? const EdgeInsets.all(AppSpacing.md),
        child: child,
      ),
    );
  }
}

/// 📦 Compact card (petit format)
class AppCompactCard extends StatelessWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool isDarkMode;

  const AppCompactCard({
    super.key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      backgroundColor: backgroundColor,
      isDarkMode: isDarkMode,
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: child,
    );
  }
}

/// 📦 Elevated card (avec ombre plus prononcée)
class AppElevatedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets? padding;
  final Color? backgroundColor;
  final VoidCallback? onTap;
  final bool isDarkMode;

  const AppElevatedCard({
    super.key,
    required this.child,
    this.padding,
    this.backgroundColor,
    this.onTap,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      padding: padding,
      backgroundColor: backgroundColor,
      onTap: onTap,
      shadow: AppShadows.elevationMedium,
      isDarkMode: isDarkMode,
      child: child,
    );
  }
}
