import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../src/visual_viewport_listener_stub.dart'
  if (dart.library.html) '../src/visual_viewport_listener_web.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/utils/validators.dart' as validators;
import 'package:mbaymi/utils/app_colors.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _isLoading = false;
  bool _obscurePassword = true;

  bool get isWeb => kIsWeb;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus && isWeb) {
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

    // If running on web, listen to visualViewport messages from index.html and ensure focused field is visible
    if (isWeb) {
      try {
        // Platform-specific function is defined in lib/src/visual_viewport_listener_web.dart or stub.
        // ignore: undefined_function
        addVisualViewportListener((height, offsetTop) {
          // Callback for visual viewport changes
        });
      } catch (e) {
        // ignore if the function isn't available (non-web builds)
      }
    }
  }

  Future<void> _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    final emailError = validators.Validators.email(email);
    final passwordError = validators.Validators.password(password);

    if (emailError != null || passwordError != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(emailError ?? passwordError ?? 'Champs invalides'),
          backgroundColor: Colors.red.shade700,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.login(email: email, password: password);

      await AuthService.login(
        userId: int.parse(result['id'].toString()),
        email: result['email'],
        name: result['name'] ?? 'User',
        role: result['role'] ?? 'farmer',
        accessToken: result['access_token'],
        refreshToken: result['refresh_token'],
      );

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _decoration(
    String label,
    Color border,
    Color hint, {
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: hint),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgColor = AppColors.getBgColor(isDark);
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = Colors.grey;
    final borderColor = Colors.grey.shade400;
    final buttonColor = Colors.brown;

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,

      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        title: const Text('Connexion'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),

      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Padding(
            padding: EdgeInsets.fromLTRB(24, 32, 24, 32 + MediaQuery.of(context).viewInsets.bottom),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(
                  Icons.person,
                  size: 90,
                  color: Colors.brown.shade100,
                ),
                const SizedBox(height: 40),

                    TextField(
                      controller: _emailController,
                      focusNode: _emailFocus,
                      autocorrect: false,
                      enableSuggestions: false,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      onSubmitted: (_) =>
                          FocusScope.of(context).requestFocus(_passwordFocus),
                      style: TextStyle(color: textColor, fontSize: 16),
                      decoration: _decoration('Email', borderColor, hintColor),
                    ),

                    const SizedBox(height: 24),

                    TextField(
                      controller: _passwordController,
                      focusNode: _passwordFocus,
                      autocorrect: false,
                      enableSuggestions: false,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _handleLogin(),
                      style: TextStyle(color: textColor, fontSize: 16),
                      decoration: _decoration(
                        'Mot de passe',
                        borderColor,
                        hintColor,
                        suffix: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                          ),
                          onPressed: () =>
                              setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      height: 52,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleLogin,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: buttonColor,
                        ),
                        child: _isLoading
                            ? const CircularProgressIndicator(color: Colors.white)
                            : const Text(
                                'SE CONNECTER',
                                style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Pas encore de compte ? "),
                        GestureDetector(
                          onTap: () =>
                              Navigator.of(context).pushNamed('/register'),
                          child: Text(
                            "S'inscrire",
                            style: TextStyle(
                              color: Colors.brown.shade700,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),

                if (isWeb) const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
