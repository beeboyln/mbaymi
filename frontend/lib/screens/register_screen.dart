import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

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

  // FocusNodes (Next / Done fluide)
  final _nameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();
  final _regionFocus = FocusNode();
  final _villageFocus = FocusNode();

  String _selectedRole = 'farmer';
  bool _isLoading = false;

  // Palette de couleurs
  static const Color _bgLight = Colors.white;
  static const Color _bgDark = Color(0xFF121212);
  static const Color _textLight = Color(0xFF1A1A1A);
  static const Color _textDark = Colors.white;
  static const Color _borderLight = Color(0xFFE8E2D8);
  static const Color _borderDark = Color(0xFF2C2C2C);
  static const Color _buttonDark = Color(0xFF2C2C2C);
  static const Color _hintLight = Color(0xFF999999);
  static const Color _hintDark = Color(0xFF666666);

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

    super.dispose();
  }

  void _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      await ApiService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        password: _passwordController.text,
        role: _selectedRole,
        region: _regionController.text.trim(),
        village: _villageController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inscription réussie')),
      );

      Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: ${e.toString()}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(String label, Color borderColor, Color hintColor, bool isDark) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: hintColor),
      border: const UnderlineInputBorder(),
      enabledBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: UnderlineInputBorder(
        borderSide: BorderSide(color: isDark ? Colors.white70 : Colors.black),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _bgDark : _bgLight;
    final textColor = isDark ? _textDark : _textLight;
    final borderColor = isDark ? _borderDark : _borderLight;
    final buttonColor = isDark ? _buttonDark : Colors.black;
    final appBarColor = isDark ? Color(0xFF1E1E1E) : Colors.white;
    final hintColor = isDark ? _hintDark : _hintLight;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        foregroundColor: textColor,
        title: Text(
          'Créer un compte',
          style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),

                // NOM
                TextFormField(
                  controller: _nameController,
                  focusNode: _nameFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_emailFocus),
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration('Nom complet', borderColor, hintColor, isDark),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Nom requis' : null,
                ),

                const SizedBox(height: 24),

                // EMAIL
                TextFormField(
                  controller: _emailController,
                  focusNode: _emailFocus,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.emailAddress,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_phoneFocus),
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration('Email', borderColor, hintColor, isDark),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Email requis' : null,
                ),

                const SizedBox(height: 24),

                // TELEPHONE
                TextFormField(
                  controller: _phoneController,
                  focusNode: _phoneFocus,
                  textInputAction: TextInputAction.next,
                  keyboardType: TextInputType.phone,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_passwordFocus),
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration('Téléphone', borderColor, hintColor, isDark),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Téléphone requis' : null,
                ),

                const SizedBox(height: 24),

                // MOT DE PASSE
                TextFormField(
                  controller: _passwordController,
                  focusNode: _passwordFocus,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_confirmPasswordFocus),
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration('Mot de passe', borderColor, hintColor, isDark),
                  validator: (v) =>
                      v != null && v.length < 6 ? '6 caractères minimum' : null,
                ),

                const SizedBox(height: 24),

                // CONFIRMATION
                TextFormField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  obscureText: true,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_regionFocus),
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration('Confirmer le mot de passe', borderColor, hintColor, isDark),
                  validator: (v) =>
                      v != _passwordController.text
                          ? 'Les mots de passe ne correspondent pas'
                          : null,
                ),

                const SizedBox(height: 24),

                // ROLE
                DropdownButtonFormField<String>(
                  value: _selectedRole,
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration('Rôle', borderColor, hintColor, isDark),
                  items: const [
                    DropdownMenuItem(value: 'farmer', child: Text('Agriculteur')),
                    DropdownMenuItem(
                        value: 'livestock_breeder', child: Text('Éleveur')),
                    DropdownMenuItem(value: 'buyer', child: Text('Acheteur')),
                    DropdownMenuItem(value: 'seller', child: Text('Vendeur')),
                  ],
                  onChanged: (v) =>
                      setState(() => _selectedRole = v ?? 'farmer'),
                ),

                const SizedBox(height: 24),

                // REGION
                TextFormField(
                  controller: _regionController,
                  focusNode: _regionFocus,
                  textInputAction: TextInputAction.next,
                  onFieldSubmitted: (_) =>
                      FocusScope.of(context).requestFocus(_villageFocus),
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration('Région', borderColor, hintColor, isDark),
                  validator: (v) =>
                      v == null || v.isEmpty ? 'Région requise' : null,
                ),

                const SizedBox(height: 24),

                // VILLAGE
                TextFormField(
                  controller: _villageController,
                  focusNode: _villageFocus,
                  textInputAction: TextInputAction.done,
                  style: TextStyle(color: textColor),
                  decoration: _inputDecoration('Village (optionnel)', borderColor, hintColor, isDark),
                ),

                const SizedBox(height: 40),

                // BOUTON
                SizedBox(
                  height: 50,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'CRÉER UN COMPTE',
                            style: TextStyle(
                              letterSpacing: 1.2,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
