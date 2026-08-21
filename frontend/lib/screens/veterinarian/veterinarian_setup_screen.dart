import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:math';

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class _GrainPainter extends CustomPainter {
  final double seed;
  final Color color;
  const _GrainPainter({required this.seed, required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random((seed * 1000).toInt());
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 220; i++) {
      paint.color = color.withOpacity(rng.nextDouble() * 0.035 + 0.004);
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 0.8 + 0.15, paint,
      );
    }
  }
  @override
  bool shouldRepaint(_GrainPainter o) => o.seed != seed;
}

class _RingsPainter extends CustomPainter {
  final Color color;
  const _RingsPainter({required this.color});
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.5;
    for (int i = 1; i <= 5; i++) {
      paint.color = color.withOpacity(0.020 + i * 0.004);
      canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), i * 36.0, paint);
    }
  }
  @override
  bool shouldRepaint(_RingsPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// STEP DOT INDICATOR
// ─────────────────────────────────────────────────────────────────────────────
class _StepDots extends StatelessWidget {
  final int current;
  final int total;
  final Color primary;
  final Color surface;
  const _StepDots({required this.current, required this.total, required this.primary, required this.surface});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final done = i < current;
        final active = i == current;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.only(right: 6),
          width: active ? 22 : 7,
          height: 7,
          decoration: BoxDecoration(
            color: done || active
                ? primary
                : primary.withOpacity(0.18),
            borderRadius: BorderRadius.circular(4),
          ),
          child: done
              ? Center(child: Icon(Icons.check_rounded, color: surface, size: 5))
              : null,
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ELEGANT INPUT FIELD
// ─────────────────────────────────────────────────────────────────────────────
class _VetField extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String label;
  final String? hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final int maxLines;
  final String? Function(String?)? validator;
  final Color primary;
  final Color textPri;
  final bool isDark;

  const _VetField({
    required this.controller, this.focusNode,
    required this.label, this.hint, required this.icon,
    this.keyboardType, this.maxLines = 1, this.validator,
    required this.primary, required this.textPri, required this.isDark,
  });

  @override
  State<_VetField> createState() => _VetFieldState();
}

class _VetFieldState extends State<_VetField> {
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    widget.focusNode?.addListener(() {
      if (mounted) setState(() => _focused = widget.focusNode!.hasFocus);
    });
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = _focused
        ? widget.primary
        : widget.primary.withOpacity(widget.isDark ? 0.18 : 0.14);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: widget.isDark
            ? widget.primary.withOpacity(_focused ? 0.08 : 0.04)
            : widget.primary.withOpacity(_focused ? 0.04 : 0.02),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: _focused ? 1.5 : 1.0),
      ),
      child: TextFormField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        keyboardType: widget.keyboardType,
        maxLines: widget.maxLines,
        validator: widget.validator,
        style: TextStyle(
          fontSize: 14, color: widget.textPri,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          hintStyle: TextStyle(
            color: widget.primary.withOpacity(0.30),
            fontSize: 13, fontWeight: FontWeight.w300,
          ),
          labelStyle: TextStyle(
            color: _focused ? widget.primary : widget.primary.withOpacity(0.55),
            fontSize: _focused ? 11 : 13,
            fontWeight: FontWeight.w400,
            letterSpacing: _focused ? 0.5 : 0,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(widget.icon,
              color: _focused ? widget.primary : widget.primary.withOpacity(0.35),
              size: 18,
            ),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 16,
            vertical: widget.maxLines > 1 ? 16 : 0,
          ),
          errorStyle: TextStyle(
            fontSize: 10, color: Colors.red.withOpacity(0.75),
            fontWeight: FontWeight.w300,
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTACT OPTION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ContactOption extends StatelessWidget {
  final String value;
  final String label;
  final String subtitle;
  final IconData icon;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final Color primary;
  final Color surface;
  final Color textPri;
  final Color textSec;
  final bool isDark;

  const _ContactOption({
    required this.value, required this.label, required this.subtitle,
    required this.icon, required this.groupValue, required this.onChanged,
    required this.primary, required this.surface, required this.textPri,
    required this.textSec, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return GestureDetector(
      onTap: () { HapticFeedback.selectionClick(); onChanged(value); },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: selected ? primary.withOpacity(0.07) : surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? primary.withOpacity(0.40) : primary.withOpacity(isDark ? 0.12 : 0.10),
            width: selected ? 1.5 : 1.0,
          ),
          boxShadow: selected ? [BoxShadow(
            color: primary.withOpacity(0.10),
            blurRadius: 12, offset: const Offset(0, 3),
          )] : null,
        ),
        child: Row(children: [
          Container(
            padding: const EdgeInsets.all(9),
            decoration: BoxDecoration(
              color: selected ? primary.withOpacity(0.12) : primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: selected ? primary : primary.withOpacity(0.40), size: 16),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(
              fontSize: 13, fontWeight: selected ? FontWeight.w500 : FontWeight.w400,
              color: textPri, letterSpacing: -0.2,
            )),
            Text(subtitle, style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w300,
              color: textSec.withOpacity(0.55),
            )),
          ])),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? primary : Colors.transparent,
              border: Border.all(
                color: selected ? primary : primary.withOpacity(0.25),
                width: 1.5,
              ),
            ),
            child: selected
                ? const Icon(Icons.check_rounded, color: Colors.white, size: 11)
                : null,
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class VeterinarianSetupScreen extends StatefulWidget {
  const VeterinarianSetupScreen({super.key});

  @override
  State<VeterinarianSetupScreen> createState() => _VeterinarianSetupScreenState();
}

class _VeterinarianSetupScreenState extends State<VeterinarianSetupScreen>
    with TickerProviderStateMixin {

  final _formKey    = GlobalKey<FormState>();
  bool _isLoading   = false;
  int  _currentStep = 0;

  // Controllers
  final _specialtyController  = TextEditingController();
  final _zoneController       = TextEditingController();
  final _distanceController   = TextEditingController();
  final _bioController        = TextEditingController();
  final _experienceController = TextEditingController();

  // Focus nodes
  final _specialtyFocus  = FocusNode();
  final _zoneFocus       = FocusNode();
  final _distanceFocus   = FocusNode();
  final _experienceFocus = FocusNode();
  final _bioFocus        = FocusNode();

  String _contactPreference = 'whatsapp';
  XFile? _certificateFile;
  final  _imagePicker = ImagePicker();
  final  _scrollController = ScrollController();

  // Animations
  late AnimationController _grainCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _stepCtrl;
  late Animation<double>   _stepFade;
  late Animation<Offset>   _stepSlide;

  static const Color _primary = Color(0xFF00695C);
  static const Color _accent  = Color(0xFF80CBC4);

  bool get isWeb => kIsWeb;

  @override
  void initState() {
    super.initState();
    _grainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120))..repeat();
    _waveCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);

    _stepCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _stepFade  = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOut);
    _stepSlide = Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOutCubic));
    _stepCtrl.forward();

    _setupFocusScrolling();
    _restoreSession();
  }

  @override
  void dispose() {
    _grainCtrl.dispose();
    _waveCtrl.dispose();
    _stepCtrl.dispose();
    for (final c in [_specialtyController, _zoneController, _distanceController,
        _bioController, _experienceController]) c.dispose();
    for (final f in [_specialtyFocus, _zoneFocus, _distanceFocus,
        _experienceFocus, _bioFocus]) f.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupFocusScrolling() {
    final pairs = [
      (_specialtyFocus, 80.0), (_zoneFocus, 180.0), (_distanceFocus, 260.0),
      (_experienceFocus, 340.0), (_bioFocus, 100.0),
    ];
    for (final p in pairs) {
      p.$1.addListener(() {
        if (p.$1.hasFocus && isWeb) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!_scrollController.hasClients) return;
            final target = p.$2.clamp(0.0, _scrollController.position.maxScrollExtent);
            _scrollController.animateTo(target,
                duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
          });
        }
      });
    }
    
    // Force UI update when text changes
    for (final c in [_specialtyController, _zoneController, _distanceController,
        _bioController, _experienceController]) {
      c.addListener(() { if (mounted) setState(() {}); });
    }
  }

  Future<void> _restoreSession() async {
    try { await AuthService.restoreSession(); } catch (_) {}
  }

  void _goToStep(int step) {
    _stepCtrl.forward(from: 0);
    setState(() => _currentStep = step);
    HapticFeedback.lightImpact();
    _scrollController.animateTo(0,
        duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic);
  }

  bool _validateCurrentStep() {
    if (_currentStep == 0) {
      return _specialtyController.text.trim().isNotEmpty &&
             _zoneController.text.trim().isNotEmpty &&
             _distanceController.text.trim().isNotEmpty &&
             _experienceController.text.trim().isNotEmpty;
    }
    if (_currentStep == 1) return _bioController.text.trim().isNotEmpty;
    return true;
  }

  Future<void> _pickCertificate() async {
    try {
      final f = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (f != null && mounted) setState(() => _certificateFile = f);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')));
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      // Upload certificate to Cloudinary FIRST if provided
      String? certificateUrl;
      String? certificateFilename;
      if (_certificateFile != null) {
        try {
          debugPrint('📤 Uploading certificate to Cloudinary...');
          debugPrint('   File name: ${_certificateFile!.name}');
          
          // Upload using uploadImageToCloudinary with XFile
          certificateUrl = await ApiService.uploadImageToCloudinary(
            _certificateFile!,
          );
          certificateFilename = _certificateFile!.name;
          debugPrint('✅ Certificate uploaded to Cloudinary: $certificateUrl');
        } catch (e) {
          debugPrint('⚠️ Certificate upload error: $e');
          if (mounted) ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Certificat non uploadé: $e'), 
              backgroundColor: Colors.orange.withOpacity(0.7),
              behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          );
          // Continue anyway - certificate is optional
        }
      }
      
      if (!mounted) return;
      
      // Create veterinarian profile with certificate URL
      await ApiService.createVeterinarianProfile(
        specialty: _specialtyController.text.trim(),
        zone: _zoneController.text.trim(),
        distanceMax: int.tryParse(_distanceController.text) ?? 50,
        bio: _bioController.text.trim(),
        experienceYears: int.tryParse(_experienceController.text) ?? 0,
        contactPreference: _contactPreference,
        certificateUrl: certificateUrl,
        certificateFilename: certificateFilename,
      );
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final bg      = isDark ? const Color(0xFF060E0D) : const Color(0xFFF4FAF9);
    final surface = isDark ? const Color(0xFF0D1A18) : Colors.white;
    final textPri = isDark ? const Color(0xFFE0F2F1) : const Color(0xFF0D2420);
    final textSec = isDark ? const Color(0xFF80CBC4) : const Color(0xFF4A7A73);

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [
        _buildHeader(isDark, surface, textPri),
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              controller: _scrollController,
              physics: const BouncingScrollPhysics(),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
              padding: EdgeInsets.fromLTRB(20, 0, 20, isWeb ? 80 : 40),
              child: FadeTransition(
                opacity: _stepFade,
                child: SlideTransition(
                  position: _stepSlide,
                  child: _buildStepContent(isDark, surface, textPri, textSec),
                ),
              ),
            ),
          ),
        ),
        _buildFooter(isDark, surface, textPri, textSec),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HEADER — hero compact avec illustration
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(bool isDark, Color surface, Color textPri) {
    final steps = ['Profil', 'Bio & Contact', 'Certificat'];

    return SizedBox(
      height: 190,
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        // Fond gradient
        Positioned.fill(child: Container(decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0A1A18), const Color(0xFF051210)]
                : [const Color(0xFFE0F2F0), const Color(0xFFCCEAE7)],
          ),
        ))),
        // Grain
        Positioned.fill(child: AnimatedBuilder(
          animation: _grainCtrl,
          builder: (_, __) => CustomPaint(
            painter: _GrainPainter(seed: _grainCtrl.value, color: _primary),
          ),
        )),
        // Rings
        const Positioned(top: -50, right: -50, child: SizedBox(
          width: 240, height: 240,
          child: CustomPaint(painter: _RingsPainter(color: _primary)),
        )),
        // Glow
        Positioned(top: -60, right: -60, child: Container(
          width: 200, height: 200,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              _accent.withOpacity(isDark ? 0.14 : 0.09),
              Colors.transparent,
            ]),
          ),
        )),
        // Wave bottom
        Positioned(bottom: 0, left: 0, right: 0, child: AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, __) => SizedBox(height: 60, child: CustomPaint(
            painter: _WavePainter(
              phase: _waveCtrl.value * 2 * pi,
              color: _primary.withOpacity(isDark ? 0.18 : 0.09),
              yOffset: 0.42,
            ),
            size: Size(MediaQuery.of(context).size.width, 60),
          )),
        )),
        // Back button + content
        Padding(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 28),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (Navigator.of(context).canPop())
                GestureDetector(
                  onTap: () { HapticFeedback.lightImpact(); Navigator.of(context).pop(); },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.arrow_back_rounded, color: _primary, size: 17),
                  ),
                ),
              const Spacer(),
              _StepDots(current: _currentStep, total: 3, primary: _primary, surface: isDark ? const Color(0xFF0A1A18) : Colors.white),
            ]),
            const Spacer(),
            // Step micro label
            Text(
              'ÉTAPE ${_currentStep + 1} / 3',
              style: TextStyle(
                fontSize: 7, fontWeight: FontWeight.w500,
                letterSpacing: 2.5, color: _accent.withOpacity(0.75),
              ),
            ),
            const SizedBox(height: 4),
            Text(steps[_currentStep], style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w300,
              color: textPri, letterSpacing: -1.2, height: 1.1,
            )),
          ]),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP CONTENT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStepContent(bool isDark, Color surface, Color textPri, Color textSec) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const SizedBox(height: 28),
      if (_currentStep == 0) _step1(isDark, surface, textPri, textSec)
      else if (_currentStep == 1) _step2(isDark, surface, textPri, textSec)
      else _step3(isDark, surface, textPri, textSec),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 1 — Informations professionnelles
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _step1(bool isDark, Color surface, Color textPri, Color textSec) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('INFORMATIONS PROFESSIONNELLES', textSec),
      const SizedBox(height: 16),
      _VetField(
        controller: _specialtyController, focusNode: _specialtyFocus,
        label: 'Spécialité', hint: 'ex. Médecine bovine, Petits animaux…',
        icon: Icons.medical_services_outlined,
        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        primary: _primary, textPri: textPri, isDark: isDark,
      ),
      const SizedBox(height: 14),
      _VetField(
        controller: _zoneController, focusNode: _zoneFocus,
        label: 'Zone de couverture', hint: 'ex. Dakar, Thiès…',
        icon: Icons.location_on_outlined,
        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        primary: _primary, textPri: textPri, isDark: isDark,
      ),
      const SizedBox(height: 14),
      Row(children: [
        Expanded(child: _VetField(
          controller: _distanceController, focusNode: _distanceFocus,
          label: 'Distance max (km)', hint: '50',
          icon: Icons.radar_rounded,
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Requis';
            if (int.tryParse(v) == null) return 'Nombre';
            return null;
          },
          primary: _primary, textPri: textPri, isDark: isDark,
        )),
        const SizedBox(width: 12),
        Expanded(child: _VetField(
          controller: _experienceController, focusNode: _experienceFocus,
          label: 'Années d\'expérience', hint: '5',
          icon: Icons.timeline_rounded,
          keyboardType: TextInputType.number,
          validator: (v) {
            if (v == null || v.isEmpty) return 'Requis';
            if (int.tryParse(v) == null) return 'Nombre';
            return null;
          },
          primary: _primary, textPri: textPri, isDark: isDark,
        )),
      ]),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 2 — Bio & Contact
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _step2(bool isDark, Color surface, Color textPri, Color textSec) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('BIOGRAPHIE', textSec),
      const SizedBox(height: 16),
      _VetField(
        controller: _bioController, focusNode: _bioFocus,
        label: 'Parlez de vous', hint: 'Formation, spécialisations, approche…',
        icon: Icons.edit_note_rounded,
        maxLines: 5,
        validator: (v) => v == null || v.isEmpty ? 'Requis' : null,
        primary: _primary, textPri: textPri, isDark: isDark,
      ),
      const SizedBox(height: 28),
      _sectionLabel('PRÉFÉRENCE DE CONTACT', textSec),
      const SizedBox(height: 14),
      _ContactOption(
        value: 'whatsapp', label: 'WhatsApp',
        subtitle: 'Messages et appels via WhatsApp',
        icon: Icons.chat_bubble_outline_rounded,
        groupValue: _contactPreference, onChanged: (v) => setState(() => _contactPreference = v),
        primary: _primary, surface: surface, textPri: textPri, textSec: textSec, isDark: isDark,
      ),
      _ContactOption(
        value: 'call', label: 'Appel téléphonique',
        subtitle: 'Contact direct par téléphone',
        icon: Icons.phone_outlined,
        groupValue: _contactPreference, onChanged: (v) => setState(() => _contactPreference = v),
        primary: _primary, surface: surface, textPri: textPri, textSec: textSec, isDark: isDark,
      ),
      _ContactOption(
        value: 'email', label: 'Email',
        subtitle: 'Échanges par messagerie électronique',
        icon: Icons.mail_outline_rounded,
        groupValue: _contactPreference, onChanged: (v) => setState(() => _contactPreference = v),
        primary: _primary, surface: surface, textPri: textPri, textSec: textSec, isDark: isDark,
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 3 — Certificat
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _step3(bool isDark, Color surface, Color textPri, Color textSec) {
    final hasFile = _certificateFile != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _sectionLabel('CERTIFICAT PROFESSIONNEL', textSec),
      const SizedBox(height: 16),

      // Upload zone
      GestureDetector(
        onTap: _pickCertificate,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 36),
          decoration: BoxDecoration(
            color: hasFile
                ? Colors.green.withOpacity(isDark ? 0.08 : 0.05)
                : _primary.withOpacity(isDark ? 0.05 : 0.03),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: hasFile
                  ? Colors.green.withOpacity(0.35)
                  : _primary.withOpacity(0.18),
              width: 1.5,
            ),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hasFile
                    ? Colors.green.withOpacity(0.10)
                    : _primary.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasFile ? Icons.check_circle_outline_rounded : Icons.upload_file_rounded,
                size: 32,
                color: hasFile ? Colors.green : _primary.withOpacity(0.55),
              ),
            ),
            const SizedBox(height: 14),
            Text(
              hasFile ? 'Certificat ajouté' : 'Appuyer pour sélectionner',
              style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w400,
                color: hasFile ? Colors.green.withOpacity(0.85) : textPri.withOpacity(0.70),
              ),
            ),
            const SizedBox(height: 5),
            if (hasFile)
              Text(
                _certificateFile!.name,
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w300,
                  color: textSec.withOpacity(0.55),
                ),
                textAlign: TextAlign.center,
                maxLines: 1, overflow: TextOverflow.ellipsis,
              )
            else
              Text(
                'JPG, PNG — Photo du certificat vétérinaire',
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w300,
                  color: _primary.withOpacity(0.40),
                ),
              ),
            if (!hasFile) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 9),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('Choisir une image', style: TextStyle(
                  fontSize: 12, fontWeight: FontWeight.w500,
                  color: _primary, letterSpacing: 0.3,
                )),
              ),
            ],
          ]),
        ),
      ),

      const SizedBox(height: 20),

      // Info notice
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFFF9800).withOpacity(isDark ? 0.08 : 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFF9800).withOpacity(0.20)),
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(Icons.info_outline_rounded,
              color: const Color(0xFFFF9800).withOpacity(0.70), size: 16),
          const SizedBox(width: 10),
          Expanded(child: Text(
            'Votre profil sera en attente de vérification. Un administrateur examinera votre certificat sous 24 à 48 heures.',
            style: TextStyle(
              fontSize: 12, fontWeight: FontWeight.w300,
              color: textPri.withOpacity(0.75), height: 1.55,
            ),
          )),
        ]),
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FOOTER — navigation buttons
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFooter(bool isDark, Color surface, Color textPri, Color textSec) {
    final canNext = _validateCurrentStep();

    return Container(
      padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(context).padding.bottom + 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0D1A18) : Colors.white,
        boxShadow: [BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.25) : _primary.withOpacity(0.06),
          blurRadius: 20, offset: const Offset(0, -5),
        )],
      ),
      child: Row(children: [
        // Back button
        if (_currentStep > 0)
          GestureDetector(
            onTap: () => _goToStep(_currentStep - 1),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.arrow_back_rounded, color: _primary, size: 15),
                const SizedBox(width: 7),
                Text('Retour', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w400,
                  color: _primary, letterSpacing: 0.2,
                )),
              ]),
            ),
          )
        else
          const SizedBox(width: 1),

        const Spacer(),

        // Next / Submit button
        GestureDetector(
          onTap: (!canNext || _isLoading) ? null : () {
            if (_currentStep < 2) {
              if (_formKey.currentState!.validate()) _goToStep(_currentStep + 1);
            } else {
              _submitProfile();
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
            decoration: BoxDecoration(
              color: canNext ? _primary : _primary.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              boxShadow: canNext ? [BoxShadow(
                color: _primary.withOpacity(0.28),
                blurRadius: 16, offset: const Offset(0, 6),
              )] : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (_isLoading)
                const SizedBox(width: 18, height: 18,
                    child: CircularProgressIndicator(strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation(Colors.white)))
              else ...[
                Text(
                  _currentStep < 2 ? 'Suivant' : 'Créer mon profil',
                  style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: Colors.white, letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(width: 8),
                Icon(
                  _currentStep < 2 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                  color: Colors.white, size: 15,
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String text, Color textSec) => Row(children: [
    Container(width: 18, height: 1, color: _primary),
    const SizedBox(width: 8),
    Text(text, style: TextStyle(
      fontSize: 7, fontWeight: FontWeight.w500,
      letterSpacing: 2.8, color: textSec.withOpacity(0.50),
    )),
    const SizedBox(width: 8),
    Expanded(child: Container(height: 1, color: textSec.withOpacity(0.08))),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// Wave painter (shared)
// ─────────────────────────────────────────────────────────────────────────────
class _WavePainter extends CustomPainter {
  final double phase;
  final Color color;
  final double yOffset;
  const _WavePainter({required this.phase, required this.color, this.yOffset = 0.6});

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final baseY = size.height * yOffset;
    path.moveTo(0, size.height);
    path.lineTo(0, baseY + 10 * sin(phase));
    for (double x = 0; x <= size.width; x += 2) {
      path.lineTo(x, baseY
          + 12 * sin(x / size.width * 2 * pi + phase)
          + 6  * sin(x / size.width * 4 * pi - phase * 1.3)
          + 3  * cos(x / size.width * 6 * pi + phase * 0.7));
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_WavePainter o) => o.phase != phase;
}