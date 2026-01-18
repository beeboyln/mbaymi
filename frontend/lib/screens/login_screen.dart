import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../src/visual_viewport_listener_stub.dart'
  if (dart.library.html) '../src/visual_viewport_listener_web.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/utils/validators.dart' as validators;

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

  final ScrollController _scrollController = ScrollController();
  final GlobalKey _emailKey = GlobalKey();
  final GlobalKey _passwordKey = GlobalKey();

  bool _isLoading = false;
  bool _obscurePassword = true;

  bool get isWeb => kIsWeb;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();

    _emailFocus.addListener(() {
      if (_emailFocus.hasFocus && isWeb) {
        final ctx = _emailKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 250),
            alignment: 0.3,
          );
        }
      }
    });

    _passwordFocus.addListener(() {
      if (_passwordFocus.hasFocus && isWeb) {
        final ctx = _passwordKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 250),
            alignment: 0.3,
          );
        }
      }
    });

    if (isWeb) {
      try {
        addVisualViewportListener((height, offsetTop) {
          if (_emailFocus.hasFocus) {
            final ctx = _emailKey.currentContext;
            if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), alignment: 0.3);
          } else if (_passwordFocus.hasFocus) {
            final ctx = _passwordKey.currentContext;
            if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 250), alignment: 0.3);
          }
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
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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
    IconData? prefixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(color: hint),
      prefixIcon: prefixIcon != null ? Icon(prefixIcon, color: hint) : null,
      filled: true,
      fillColor: Colors.grey[50],
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: Colors.brown.shade700, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
      suffixIcon: suffix,
    );
  }

  Widget _buildLoginForm(double maxWidth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final hintColor = Colors.grey;
    final borderColor = Colors.grey.shade300;

    // Responsive sizing
    final isLargeScreen = maxWidth > 600;
    final formWidth = isLargeScreen ? 480.0 : maxWidth;
    final logoSize = isLargeScreen ? 120.0 : 90.0;
    final fontSize = isLargeScreen ? 18.0 : 16.0;

    return Container(
      width: formWidth,
      padding: EdgeInsets.all(isLargeScreen ? 48 : 24),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isLargeScreen ? [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ] : null,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Center(
            child: Image.asset('assets/images/aa.png', height: logoSize),
          ),
          SizedBox(height: isLargeScreen ? 48 : 32),
          Text(
            'Bienvenue',
            style: TextStyle(
              fontSize: isLargeScreen ? 32 : 28,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Connectez-vous pour continuer',
            style: TextStyle(
              fontSize: isLargeScreen ? 16 : 14,
              color: hintColor,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: isLargeScreen ? 40 : 32),
          Container(
            key: _emailKey,
            child: TextField(
              controller: _emailController,
              focusNode: _emailFocus,
              autocorrect: false,
              enableSuggestions: false,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              onTap: () {
                if (isWeb) {
                  final ctx = _emailKey.currentContext;
                  if (ctx != null) {
                    Scrollable.ensureVisible(
                      ctx,
                      duration: const Duration(milliseconds: 250),
                      alignment: 0.3,
                    );
                  }
                }
              },
              onSubmitted: (_) =>
                  FocusScope.of(context).requestFocus(_passwordFocus),
              style: TextStyle(color: textColor, fontSize: fontSize),
              decoration: _decoration(
                'Email',
                borderColor,
                hintColor,
                prefixIcon: Icons.email_outlined,
              ),
            ),
          ),
          SizedBox(height: isLargeScreen ? 24 : 20),
          Container(
            key: _passwordKey,
            child: TextField(
              controller: _passwordController,
              focusNode: _passwordFocus,
              autocorrect: false,
              enableSuggestions: false,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onTap: () {
                if (isWeb) {
                  final ctx = _passwordKey.currentContext;
                  if (ctx != null) {
                    Scrollable.ensureVisible(
                      ctx,
                      duration: const Duration(milliseconds: 250),
                      alignment: 0.3,
                    );
                  }
                }
              },
              onSubmitted: (_) => _handleLogin(),
              style: TextStyle(color: textColor, fontSize: fontSize),
              decoration: _decoration(
                'Mot de passe',
                borderColor,
                hintColor,
                prefixIcon: Icons.lock_outline,
                suffix: IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: hintColor,
                  ),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
            ),
          ),
          SizedBox(height: isLargeScreen ? 32 : 24),
          SizedBox(
            height: isLargeScreen ? 56 : 52,
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isLoading ? null : _handleLogin,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.brown.shade700,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Text(
                      'SE CONNECTER',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                        fontSize: isLargeScreen ? 16 : 15,
                        letterSpacing: 0.5,
                      ),
                    ),
            ),
          ),
          SizedBox(height: isLargeScreen ? 32 : 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Pas encore de compte ? ",
                style: TextStyle(
                  fontSize: isLargeScreen ? 15 : 14,
                  color: hintColor,
                ),
              ),
              GestureDetector(
                onTap: () => Navigator.of(context).pushNamed('/register'),
                child: Text(
                  "S'inscrire",
                  style: TextStyle(
                    color: Colors.brown.shade700,
                    fontWeight: FontWeight.bold,
                    fontSize: isLargeScreen ? 15 : 14,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.grey[50];

    return Scaffold(
      backgroundColor: bgColor,
      resizeToAvoidBottomInset: true,
      appBar: MediaQuery.of(context).size.width <= 600
          ? AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.of(context).pop(),
              ),
            )
          : null,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final bottomInset = MediaQuery.of(context).viewInsets.bottom;
            final isLargeScreen = constraints.maxWidth > 600;

            if (isLargeScreen) {
              // Layout pour grand écran - Centré avec design épuré
              return Center(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  physics: const ClampingScrollPhysics(),
                  keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                  child: AnimatedPadding(
                    padding: EdgeInsets.fromLTRB(
                      32,
                      32,
                      32,
                      32 + (bottomInset > 8 ? bottomInset : 0),
                    ),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        if (constraints.maxWidth > 900) ...[
                          // Section décorative pour très grands écrans
                          Expanded(
                            child: Container(
                              constraints: const BoxConstraints(maxWidth: 500),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(16),
                                    decoration: BoxDecoration(
                                      color: Colors.brown.shade700,
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: const Icon(
                                      Icons.agriculture,
                                      size: 48,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 32),
                                  Text(
                                    'Gérez votre ferme\navec simplicité',
                                    style: TextStyle(
                                      fontSize: 42,
                                      fontWeight: FontWeight.bold,
                                      height: 1.2,
                                      color: isDark ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Suivez vos cultures, gérez vos finances et optimisez vos rendements avec notre plateforme complète.',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[600],
                                      height: 1.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 80),
                        ],
                        _buildLoginForm(constraints.maxWidth),
                      ],
                    ),
                  ),
                ),
              );
            } else {
              // Layout pour mobile - Disposition verticale classique
              return SingleChildScrollView(
                controller: _scrollController,
                physics: const ClampingScrollPhysics(),
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: AnimatedPadding(
                    padding: EdgeInsets.fromLTRB(
                      0,
                      16,
                      0,
                      16 + (bottomInset > 8 ? bottomInset : 0),
                    ),
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOut,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildLoginForm(constraints.maxWidth),
                      ],
                    ),
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }
}