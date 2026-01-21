import 'package:flutter/material.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/utils/app_radius.dart';
import 'package:mbaymi/utils/app_spacing.dart';
import 'package:mbaymi/utils/app_typography.dart';

/// 🔘 Bouton réutilisable avec états cohérents
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final Color? backgroundColor;
  final Color? textColor;
  final IconData? icon;
  final double? height;
  final bool isDarkMode;

  const AppButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.backgroundColor,
    this.textColor,
    this.icon,
    this.height,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final bgColor = backgroundColor ?? AppColors.primary;
    final txtColor = textColor ?? Colors.white;

    Widget child = isLoading
        ? SizedBox(
            height: 24,
            width: 24,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(txtColor),
              strokeWidth: 2,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: txtColor, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTypography.button.copyWith(color: txtColor),
              ),
            ],
          );

    final button = ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: bgColor,
        disabledBackgroundColor: bgColor.withOpacity(0.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      child: child,
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        height: height ?? AppSpacing.buttonHeight,
        child: button,
      );
    }

    return button;
  }
}

/// 🔘 Bouton secondaire / outline
class AppSecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final Color? borderColor;
  final Color? textColor;
  final IconData? icon;
  final bool isDarkMode;

  const AppSecondaryButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.isFullWidth = true,
    this.borderColor,
    this.textColor,
    this.icon,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final border = borderColor ?? AppColors.primary;
    final txtColor = textColor ?? AppColors.primary;

    Widget child = isLoading
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(txtColor),
              strokeWidth: 2,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, color: txtColor, size: 18),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTypography.button.copyWith(color: txtColor),
              ),
            ],
          );

    final button = OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: border, width: 1.5),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
        ),
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.lg,
          vertical: AppSpacing.md,
        ),
      ),
      child: child,
    );

    if (isFullWidth) {
      return SizedBox(
        width: double.infinity,
        height: AppSpacing.buttonHeight,
        child: button,
      );
    }

    return button;
  }
}

/// 🔘 Bouton texte / ghost button
class AppTextButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final Color? textColor;
  final IconData? icon;
  final double? fontSize;

  const AppTextButton({
    Key? key,
    required this.label,
    this.onPressed,
    this.textColor,
    this.icon,
    this.fontSize,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final txtColor = textColor ?? AppColors.primary;

    return TextButton(
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, color: txtColor, size: 18),
            const SizedBox(width: 8),
          ],
          Text(
            label,
            style: TextStyle(
              color: txtColor,
              fontSize: fontSize ?? 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
