import 'package:flutter/material.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/utils/app_radius.dart';
import 'package:mbaymi/utils/app_spacing.dart';
import 'package:mbaymi/utils/app_typography.dart';

/// 🔤 Input field réutilisable avec validation intégrée
class AppInput extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final FocusNode? focusNode;
  final Function(String)? onChanged;
  final Function(String)? onSubmitted;
  final String? Function(String?)? validator;
  final bool obscureText;
  final IconData? prefixIcon;
  final IconData? suffixIcon;
  final VoidCallback? onSuffixTap;
  final int? maxLines;
  final int? minLines;
  final bool isDarkMode;
  final Color? backgroundColor;
  final Color? borderColor;
  final bool autocorrect;
  final bool enableSuggestions;

  const AppInput({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.focusNode,
    this.onChanged,
    this.onSubmitted,
    this.validator,
    this.obscureText = false,
    this.prefixIcon,
    this.suffixIcon,
    this.onSuffixTap,
    this.maxLines = 1,
    this.minLines,
    this.isDarkMode = false,
    this.backgroundColor,
    this.borderColor,
    this.autocorrect = false,
    this.enableSuggestions = false,
  });

  @override
  State<AppInput> createState() => _AppInputState();
}

class _AppInputState extends State<AppInput> {
  late bool _obscurePassword;

  @override
  void initState() {
    super.initState();
    _obscurePassword = widget.obscureText;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = widget.backgroundColor ??
        AppColors.getCardBgColor(widget.isDarkMode);
    final borderColor = widget.borderColor ??
        AppColors.getBorderColor(widget.isDarkMode);
    final textColor = AppColors.getTextColor(widget.isDarkMode);
    final labelColor = AppColors.getSecondaryTextColor(widget.isDarkMode);

    return TextFormField(
      controller: widget.controller,
      focusNode: widget.focusNode,
      keyboardType: widget.keyboardType,
      textInputAction: widget.textInputAction,
      onChanged: widget.onChanged,
      onFieldSubmitted: widget.onSubmitted,
      validator: widget.validator,
      obscureText: _obscurePassword,
      maxLines: _obscurePassword ? 1 : widget.maxLines,
      minLines: widget.minLines,
      autocorrect: widget.autocorrect,
      enableSuggestions: widget.enableSuggestions,
      style: AppTypography.body.copyWith(color: textColor),
      decoration: InputDecoration(
        labelText: widget.label,
        labelStyle: AppTypography.body.copyWith(color: labelColor),
        hintText: widget.hint,
        hintStyle: AppTypography.body.copyWith(color: labelColor.withOpacity(0.6)),
        filled: true,
        fillColor: bgColor,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.md,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 1.5,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.md),
          borderSide: const BorderSide(
            color: AppColors.error,
            width: 2,
          ),
        ),
        prefixIcon: widget.prefixIcon != null
            ? Icon(widget.prefixIcon, color: labelColor)
            : null,
        suffixIcon: widget.suffixIcon != null
            ? IconButton(
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_off
                      : Icons.visibility,
                  color: labelColor,
                ),
                onPressed: widget.onSuffixTap ??
                    () {
                      if (widget.obscureText) {
                        setState(() {
                          _obscurePassword = !_obscurePassword;
                        });
                      }
                    },
              )
            : null,
      ),
    );
  }
}

/// 🔤 Search input (cas spécifique)
class AppSearchInput extends StatelessWidget {
  final TextEditingController? controller;
  final String? hint;
  final Function(String)? onChanged;
  final VoidCallback? onClear;
  final bool isDarkMode;

  const AppSearchInput({
    super.key,
    this.controller,
    this.hint,
    this.onChanged,
    this.onClear,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return AppInput(
      controller: controller,
      label: 'Rechercher',
      hint: hint,
      keyboardType: TextInputType.text,
      prefixIcon: Icons.search,
      suffixIcon: controller?.text.isNotEmpty == true ? Icons.close : null,
      onChanged: onChanged,
      onSuffixTap: onClear,
      isDarkMode: isDarkMode,
    );
  }
}
