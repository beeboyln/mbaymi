import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/utils/email_validator.dart';
import 'package:mbaymi/utils/validators.dart';

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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (_emailController.text.isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs')),
      );
      return;
    }

    // Validate email format
    final email = _emailController.text.trim();
    if (!Validators.isValidEmail(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez entrer une adresse email valide.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final result = await ApiService.login(
        email: email,
        password: _passwordController.text,
      );

      if (!mounted) return;

      final userId = result['id'] ?? result['user_id'];
      if (userId == null) throw Exception('ID utilisateur manquant');

      final accessToken = result['access_token'] as String?;
      final refreshToken = result['refresh_token'] as String?;
      if (accessToken == null || refreshToken == null) {
        throw Exception('Tokens JWT manquants du serveur');
      }

      await AuthService.login(
        userId: userId is int ? userId : int.parse(userId.toString()),
        email: email,
        name: result['name'] ?? 'User',
        role: result['role'] ?? 'farmer',
        accessToken: accessToken,
        refreshToken: refreshToken,
      );

      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      if (!mounted) return;
      final errorMessage = ErrorMessages.getHumanReadableError(e);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.red.shade700,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  InputDecoration _inputDecoration(
      String label, Color borderColor, Color hintColor,
      {Widget? suffix}) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: hintColor),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
      ),
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Palette dynamique
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final appBarColor = bgColor;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = isDark ? Colors.grey.shade500 : Colors.grey.shade600;
    final borderColor = isDark ? Colors.grey.shade700 : Colors.grey.shade300;
    final buttonColor = isDark ? Colors.brown.shade700 : Colors.brown;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0,
        centerTitle: true,
        foregroundColor: textColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: textColor),
          onPressed: () => Navigator.of(context).pushReplacementNamed('/'),
          splashRadius: 1,
        ),
        title: Text(
          'Connexion',
          style: TextStyle(fontWeight: FontWeight.w600, color: textColor),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),

              // LOGO CENTRÉ
              Center(
                child: Image.asset(
                  'assets/images/aa.png',
                  height: 100,
                  width: 100,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 40),

              // EMAIL
              TextField(
                controller: _emailController,
                focusNode: _emailFocus,
                autofocus: false,
                textInputAction: TextInputAction.next,
                keyboardType: TextInputType.emailAddress,
                onSubmitted: (_) =>
                    FocusScope.of(context).requestFocus(_passwordFocus),
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                style: TextStyle(color: textColor, fontSize: 16),
                decoration:
                    _inputDecoration('Email', borderColor, hintColor),
              ),
              const SizedBox(height: 24),

              // MOT DE PASSE
              TextField(
                controller: _passwordController,
                focusNode: _passwordFocus,
                autofocus: false,
                textInputAction: TextInputAction.done,
                obscureText: _obscurePassword,
                onSubmitted: (_) => _handleLogin(),
                onTapOutside: (_) => FocusManager.instance.primaryFocus?.unfocus(),
                style: TextStyle(color: textColor, fontSize: 16),
                decoration: _inputDecoration(
                  'Mot de passe',
                  borderColor,
                  hintColor,
                  suffix: IconButton(
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: hintColor,
                    ),
                    onPressed: () {
                      setState(() => _obscurePassword = !_obscurePassword);
                    },
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // BOUTON SE CONNECTER
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: buttonColor,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'SE CONNECTER',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.1,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // LIEN INSCRIPTION
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Pas encore de compte ?', style: TextStyle(color: textColor)),
                  TextButton(
                    onPressed: () =>
                        Navigator.of(context).pushNamed('/register'),
                    child: Text(
                      'Créer un compte',
                      style: TextStyle(
                        color: buttonColor,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
