import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/token_storage.dart';

// 🔹 ALIAS POUR ÉVITER LE CONFLIT
import 'package:mbaymi/utils/email_validator.dart' as email_validator;
import 'package:mbaymi/utils/validators.dart' as validators;
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/utils/app_spacing.dart';
import 'package:mbaymi/utils/app_typography.dart';
import 'package:mbaymi/utils/app_radius.dart';
import 'package:mbaymi/widgets/app_button.dart';
import 'package:mbaymi/widgets/app_input.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  // Controllers
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _regionController = TextEditingController();
  final _villageController = TextEditingController();

  // Focus
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _regionFocus = FocusNode();
  final _villageFocus = FocusNode();

  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  String _selectedRole = 'farmer';

  bool get isWeb => kIsWeb;

  @override
  void initState() {
    super.initState();
    _setupFocusScroll();
  }

  void _setupFocusScroll() {
    void listen(FocusNode node, double offset) {
      node.addListener(() {
        if (node.hasFocus && isWeb) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _scroll(offset);
          });
        }
      });
    }

    listen(_nameFocus, 100);
    listen(_emailFocus, 200);
    listen(_phoneFocus, 300);
    listen(_passwordFocus, 400);
    listen(_confirmPasswordFocus, 500);
    listen(_regionFocus, 600);
    listen(_villageFocus, 700);
  }

  void _scroll(double offset) {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;

    _scrollController.animateTo(
      offset > max ? max : offset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _regionController.dispose();
    _villageController.dispose();

    _nameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    _regionFocus.dispose();
    _villageFocus.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final res = await ApiService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        region: _regionController.text.trim(),
        village: _villageController.text.trim(),
      );

      if (res['access_token'] != null) {
        await TokenStorage.saveTokens(
          accessToken: res['access_token'],
          refreshToken: res['refresh_token'] ?? '',
          userId: res['id'],
          userEmail: _emailController.text.trim(),
          userRole: _selectedRole,
        );
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscription réussie')),
      );

      Navigator.pushReplacementNamed(
        context,
        _selectedRole == 'veterinarian' || _selectedRole == 'expert'
            ? '/veterinarian-setup'
            : '/login',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red.shade700,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _input(
    String label,
    bool isDark,
  ) {
    final borderColor = isDark ? Colors.white12 : Colors.black12;
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.md)),
      contentPadding: EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.md,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(AppRadius.md),
        borderSide: BorderSide(
          color: AppColors.primary,
          width: 2,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bgColor = AppColors.getBgColor(isDark);
    final textColor = AppColors.getTextColor(isDark);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text('Créer un compte', style: AppTypography.h3),
        backgroundColor: bgColor,
        foregroundColor: textColor,
      ),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          controller: _scrollController,
          padding: EdgeInsets.only(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            top: AppSpacing.lg,
            bottom: bottomInset + AppSpacing.lg,
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Icon(
                  Icons.person,
                  size: 90,
                  color: AppColors.primaryLight,
                ),
                SizedBox(height: AppSpacing.xxl),

                TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  textInputAction: TextInputAction.next,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: _input('Nom complet', isDark),
                  style: AppTypography.body.copyWith(color: textColor),
                  validator: (v) => v == null || v.isEmpty ? 'Nom requis' : null,
                ),

                SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: _input('Email', isDark),
                  style: AppTypography.body.copyWith(color: textColor),
                  validator: email_validator.Validators.email,
                ),

                SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  autocorrect: false,
                  enableSuggestions: false,
                  keyboardType: TextInputType.phone,
                  decoration: _input('Téléphone', isDark),
                  style: AppTypography.body.copyWith(color: textColor),
                  validator: validators.Validators.phone,
                ),

                SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  autocorrect: false,
                  enableSuggestions: false,
                  obscureText: true,
                  decoration: _input('Mot de passe', isDark),
                  style: AppTypography.body.copyWith(color: textColor),
                  validator: validators.Validators.password,
                ),

                SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  autocorrect: false,
                  enableSuggestions: false,
                  obscureText: true,
                  decoration: _input('Confirmer mot de passe', isDark),
                  style: AppTypography.body.copyWith(color: textColor),
                  validator: (v) =>
                      v != _passwordController.text
                          ? 'Les mots de passe ne correspondent pas'
                          : null,
                ),

                SizedBox(height: AppSpacing.md),

                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  decoration: _input('Rôle', isDark),
                  style: AppTypography.body.copyWith(color: textColor),
                  items: const [
                    DropdownMenuItem(value: 'farmer', child: Text('Agriculteur')),
                    DropdownMenuItem(value: 'livestock_breeder', child: Text('Éleveur')),
                    DropdownMenuItem(value: 'veterinarian', child: Text('Vétérinaire')),
                    DropdownMenuItem(value: 'expert', child: Text('Expert Agricole')),
                    DropdownMenuItem(value: 'buyer', child: Text('Acheteur')),
                    DropdownMenuItem(value: 'seller', child: Text('Vendeur')),
                  ],
                  onChanged: (v) => setState(() => _selectedRole = v!),
                ),

                SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _regionController,
                  focusNode: _regionFocus,
                  decoration: _input('Région', isDark),
                  style: AppTypography.body.copyWith(color: textColor),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Région requise' : null,
                ),

                SizedBox(height: AppSpacing.md),

                TextFormField(
                  controller: _villageController,
                  focusNode: _villageFocus,
                  decoration: _input('Village (optionnel)', isDark),
                  style: AppTypography.body.copyWith(color: textColor),
                ),

                SizedBox(height: AppSpacing.xl),

                AppButton(
                  label: 'CRÉER UN COMPTE',
                  onPressed: _isLoading ? null : _register,
                  isLoading: _isLoading,
                  isDarkMode: isDark,
                ),

                if (isWeb) SizedBox(height: AppSpacing.xxl),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
