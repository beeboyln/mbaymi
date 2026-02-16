import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/token_storage.dart';
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

  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _regionController = TextEditingController();
  final _villageController = TextEditingController();

  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _regionFocus = FocusNode();
  final _villageFocus = FocusNode();

  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
        SnackBar(
          content: const Text('Inscription réussie', style: TextStyle(letterSpacing: 0.5)),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
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
          content: Text(e.toString(), style: const TextStyle(letterSpacing: 0.5)),
          backgroundColor: const Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFFFFBF5);
    final textColor = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
    final subtleColor = isDark ? const Color(0xFF6B6B6B) : const Color(0xFF757575);

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'CRÉER UN COMPTE',
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 2.5,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 18, color: textColor),
          onPressed: () => Navigator.of(context).pop(),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 0.5,
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          ),
        ),
      ),
      body: SafeArea(
        bottom: false,
        child: Center(
          child: SingleChildScrollView(
            controller: _scrollController,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: EdgeInsets.only(
                  left: 32,
                  right: 32,
                  top: 32,
                  bottom: bottomInset + 32,
                ),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Logo de l'app
                      Center(
                        child: SizedBox(
                          width: 80,
                          height: 80,
                          child: Image.asset(
                            'assets/images/aa.png',
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 48),

                      // Nom complet
                      _buildTextField(
                        controller: _nameController,
                        focusNode: _nameFocus,
                        label: 'NOM COMPLET',
                        isDark: isDark,
                        textColor: textColor,
                        subtleColor: subtleColor,
                        validator: (v) => v == null || v.isEmpty ? 'Nom requis' : null,
                      ),

                      const SizedBox(height: 24),

                      // Email
                      _buildTextField(
                        controller: _emailController,
                        focusNode: _emailFocus,
                        label: 'ADRESSE EMAIL',
                        isDark: isDark,
                        textColor: textColor,
                        subtleColor: subtleColor,
                        keyboardType: TextInputType.emailAddress,
                        validator: email_validator.Validators.email,
                      ),

                      const SizedBox(height: 24),

                      // Téléphone
                      _buildTextField(
                        controller: _phoneController,
                        focusNode: _phoneFocus,
                        label: 'TÉLÉPHONE',
                        isDark: isDark,
                        textColor: textColor,
                        subtleColor: subtleColor,
                        keyboardType: TextInputType.phone,
                        validator: validators.Validators.phone,
                      ),

                      const SizedBox(height: 24),

                      // Mot de passe
                      _buildPasswordField(
                        controller: _passwordController,
                        focusNode: _passwordFocus,
                        label: 'MOT DE PASSE',
                        isDark: isDark,
                        textColor: textColor,
                        subtleColor: subtleColor,
                        obscureText: _obscurePassword,
                        onToggle: () => setState(() => _obscurePassword = !_obscurePassword),
                        validator: validators.Validators.password,
                      ),

                      const SizedBox(height: 24),

                      // Confirmer mot de passe
                      _buildPasswordField(
                        controller: _confirmPasswordController,
                        focusNode: _confirmPasswordFocus,
                        label: 'CONFIRMER MOT DE PASSE',
                        isDark: isDark,
                        textColor: textColor,
                        subtleColor: subtleColor,
                        obscureText: _obscureConfirmPassword,
                        onToggle: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                        validator: (v) => v != _passwordController.text
                            ? 'Les mots de passe ne correspondent pas'
                            : null,
                      ),

                      const SizedBox(height: 24),

                      // Rôle
                      _buildRoleSelector(isDark, textColor, subtleColor),

                      const SizedBox(height: 24),

                      // Région
                      _buildTextField(
                        controller: _regionController,
                        focusNode: _regionFocus,
                        label: 'RÉGION',
                        isDark: isDark,
                        textColor: textColor,
                        subtleColor: subtleColor,
                        validator: (v) => v == null || v.isEmpty ? 'Région requise' : null,
                      ),

                      const SizedBox(height: 24),

                      // Village (optionnel)
                      _buildTextField(
                        controller: _villageController,
                        focusNode: _villageFocus,
                        label: 'VILLAGE (OPTIONNEL)',
                        isDark: isDark,
                        textColor: textColor,
                        subtleColor: subtleColor,
                      ),

                      const SizedBox(height: 48),

                      // Register button
                      _buildRegisterButton(isDark, textColor),

                      const SizedBox(height: 32),

                      // Login link
                      Center(
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pushNamed('/login'),
                          child: RichText(
                            text: TextSpan(
                              style: TextStyle(
                                color: textColor,
                                fontSize: 13,
                                letterSpacing: 0.3,
                              ),
                              children: [
                                const TextSpan(text: 'Déjà un compte ? '),
                                TextSpan(
                                  text: 'Se connecter',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.w500,
                                    decoration: TextDecoration.underline,
                                    decorationColor: textColor,
                                    decorationThickness: 1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      if (isWeb) const SizedBox(height: 48),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool isDark,
    required Color textColor,
    required Color subtleColor,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: subtleColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: keyboardType,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF757575) : const Color(0xFF1A1A1A),
                width: 1.5,
              ),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD32F2F), width: 1),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD32F2F), width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 11, letterSpacing: 0.5),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required bool isDark,
    required Color textColor,
    required Color subtleColor,
    required bool obscureText,
    required VoidCallback onToggle,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            color: subtleColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          autocorrect: false,
          enableSuggestions: false,
          obscureText: obscureText,
          textInputAction: TextInputAction.next,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF757575) : const Color(0xFF1A1A1A),
                width: 1.5,
              ),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD32F2F), width: 1),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFD32F2F), width: 1.5),
            ),
            errorStyle: const TextStyle(fontSize: 11, letterSpacing: 0.5),
            suffixIcon: IconButton(
              icon: Icon(
                obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: subtleColor,
              ),
              onPressed: onToggle,
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildRoleSelector(bool isDark, Color textColor, Color subtleColor) {
    final roles = {
      'farmer': 'Agriculteur',
      'livestock_breeder': 'Éleveur',
      'veterinarian': 'Vétérinaire',
      'expert': 'Expert Agricole',
      'buyer': 'Acheteur',
      'seller': 'Vendeur',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RÔLE',
          style: TextStyle(
            color: subtleColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<String>(
          value: _selectedRole,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
          dropdownColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF757575) : const Color(0xFF1A1A1A),
                width: 1.5,
              ),
            ),
          ),
          items: roles.entries.map((entry) {
            return DropdownMenuItem<String>(
              value: entry.key,
              child: Text(entry.value),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() => _selectedRole = value);
            }
          },
        ),
      ],
    );
  }

  Widget _buildRegisterButton(bool isDark, Color textColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _register,
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark ? Colors.white : const Color(0xFF1A1A1A),
          foregroundColor: isDark ? Colors.black : Colors.white,
          disabledBackgroundColor: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
        child: _isLoading
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    isDark ? Colors.black : Colors.white,
                  ),
                ),
              )
            : Text(
                'CRÉER UN COMPTE',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 2.5,
                  color: isDark ? Colors.black : Colors.white,
                ),
              ),
      ),
    );
  }
}