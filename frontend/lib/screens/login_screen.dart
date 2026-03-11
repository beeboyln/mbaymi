import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../src/visual_viewport_listener_stub.dart'
  if (dart.library.html) '../src/visual_viewport_listener_web.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/utils/validators.dart' as validators;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _identifierController = TextEditingController(); // Email ou téléphone
  final _passwordController = TextEditingController();

  final _identifierFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _isPhoneMode = false; // Toggle entre email et téléphone

  bool get isWeb => kIsWeb;

  @override
  void dispose() {
    _identifierController.dispose();
    _passwordController.dispose();
    _identifierFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _identifierFocus.addListener(() {
      if (_identifierFocus.hasFocus && isWeb) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 250),
        );
      }
    });

    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus && isWeb) {
        Scrollable.ensureVisible(
          context,
          duration: const Duration(milliseconds: 250),
        );
      }
    });

    if (isWeb) {
      try {
        // ignore: undefined_function
        addVisualViewportListener((height, offsetTop) {});
      } catch (e) {
        // ignore if the function isn't available
      }
    }
  }

  Future<void> _handleLogin() async {
    final identifier = _identifierController.text.trim();
    final password = _passwordController.text;

    // Validation
    if (identifier.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez entrer votre email ou numéro de téléphone',
            style: TextStyle(letterSpacing: 0.5),
          ),
          backgroundColor: Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
      return;
    }

    if (password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Veuillez entrer votre mot de passe',
            style: TextStyle(letterSpacing: 0.5),
          ),
          backgroundColor: Color(0xFFD32F2F),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      // Déterminer si c'est un email ou un téléphone
      final isEmail = identifier.contains('@');
      
      late Map<String, dynamic> result;
      if (isEmail) {
        result = await ApiService.login(email: identifier, password: password);
      } else {
        // Connexion par téléphone
        result = await ApiService.login(phone: identifier, password: password);
      }

      final userRole = result['role'] ?? 'farmer';
      
      await AuthService.login(
        userId: int.parse(result['id'].toString()),
        email: result['email'] ?? identifier,  // Use phone if email is null
        name: result['name'] ?? 'User',
        role: userRole,
        accessToken: result['access_token'],
        refreshToken: result['refresh_token'],
      );

      if (!mounted) return;
      
      // Rediriger vers l'interface appropriée selon le rôle
      if (userRole == 'admin') {
        Navigator.of(context).pushReplacementNamed('/admin-dashboard');
      } else {
        Navigator.of(context).pushReplacementNamed('/');
      }
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
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFFFFBF5);
    final textColor = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
    final subtleColor = isDark ? const Color(0xFF6B6B6B) : const Color(0xFF757575);

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: Text(
          'CONNEXION',
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
        child: Center(
          child: SingleChildScrollView(
            physics: const ClampingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 480),
              child: Padding(
                padding: EdgeInsets.fromLTRB(
                  32,
                  48,
                  32,
                  32 + MediaQuery.of(context).viewInsets.bottom,
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
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
                    
                    const SizedBox(height: 24),
                    
                    // Slogan
                    Center(
                      child: Column(
                        children: [
                          Text(
                            'CONNECTEZ-VOUS À MBAYMI',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Votre plateforme agricole intelligente\nConnectant agriculteurs et marchés',
                            style: TextStyle(
                              color: subtleColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 0.3,
                              height: 1.4,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 48),

                    // Email/Phone toggle
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        GestureDetector(
                          onTap: () => setState(() => _isPhoneMode = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: !_isPhoneMode ? Colors.green : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'EMAIL',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: !_isPhoneMode ? FontWeight.w600 : FontWeight.w400,
                                letterSpacing: 1.5,
                                color: !_isPhoneMode ? Colors.green : subtleColor,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 32),
                        GestureDetector(
                          onTap: () => setState(() => _isPhoneMode = true),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              border: Border(
                                bottom: BorderSide(
                                  color: _isPhoneMode ? Colors.green : Colors.transparent,
                                  width: 2,
                                ),
                              ),
                            ),
                            child: Text(
                              'TÉLÉPHONE',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: _isPhoneMode ? FontWeight.w600 : FontWeight.w400,
                                letterSpacing: 1.5,
                                color: _isPhoneMode ? Colors.green : subtleColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 32),

                    // Identifier field (Email or Phone)
                    _buildTextField(
                      controller: _identifierController,
                      focusNode: _identifierFocus,
                      label: _isPhoneMode ? 'NUMÉRO DE TÉLÉPHONE' : 'ADRESSE EMAIL',
                      isDark: isDark,
                      textColor: textColor,
                      subtleColor: subtleColor,
                      keyboardType: _isPhoneMode ? TextInputType.phone : TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      hint: _isPhoneMode ? 'Ex: +221 XX XX XX XX' : 'Ex: vous@exemple.com',
                      onSubmitted: (_) => FocusScope.of(context).requestFocus(_passwordFocus),
                    ),

                    const SizedBox(height: 28),

                    // Password field
                    _buildPasswordField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      label: 'MOT DE PASSE',
                      isDark: isDark,
                      textColor: textColor,
                      subtleColor: subtleColor,
                      onSubmitted: (_) => _handleLogin(),
                    ),

                    const SizedBox(height: 48),

                    // Login button
                    _buildLoginButton(isDark, textColor),

                    const SizedBox(height: 32),
                    
                    // Message de sécurité
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green.withOpacity(0.08),
                        border: Border.all(
                          color: Colors.green.withOpacity(0.3),
                          width: 1,
                        ),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.lock_outline,
                            size: 18,
                            color: Colors.green,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Vos données sont sécurisées et protégées.',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 0.3,
                                color: Colors.green,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Divider
                    Row(
                      children: [
                        Expanded(
                          child: Container(
                            height: 0.5,
                            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'OU',
                            style: TextStyle(
                              color: subtleColor,
                              fontSize: 11,
                              letterSpacing: 2,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Container(
                            height: 0.5,
                            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    // Register link
                    Center(
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pushNamed('/register'),
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              color: textColor,
                              fontSize: 13,
                              letterSpacing: 0.3,
                            ),
                            children: [
                              const TextSpan(text: 'Pas de compte ? '),
                              TextSpan(
                                text: 'Créer un compte',
                                style: TextStyle(
                                  color: textColor,
                                  fontWeight: FontWeight.w500,
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
    TextInputAction? textInputAction,
    String? hint,
    void Function(String)? onSubmitted,
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
        TextField(
          controller: controller,
          focusNode: focusNode,
          autocorrect: false,
          enableSuggestions: false,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          onSubmitted: onSubmitted,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: subtleColor.withOpacity(0.5),
              fontSize: 13,
            ),
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
    void Function(String)? onSubmitted,
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
        TextField(
          controller: controller,
          focusNode: focusNode,
          autocorrect: false,
          enableSuggestions: false,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onSubmitted: onSubmitted,
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
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                size: 20,
                color: subtleColor,
              ),
              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoginButton(bool isDark, Color textColor) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isLoading ? null : _handleLogin,
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
                'SE CONNECTER',
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