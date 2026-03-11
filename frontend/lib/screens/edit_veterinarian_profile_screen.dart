import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mbaymi/services/api_service.dart';

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
      paint.color = color.withOpacity(rng.nextDouble() * 0.034 + 0.004);
      canvas.drawCircle(Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
          rng.nextDouble() * 0.8 + 0.15, paint);
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

// ─────────────────────────────────────────────────────────────────────────────
// STEP DOTS
// ─────────────────────────────────────────────────────────────────────────────
class _StepDots extends StatelessWidget {
  final int current;
  final int total;
  final Color primary;
  final Color surface;
  const _StepDots({required this.current, required this.total, required this.primary, required this.surface});

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: List.generate(total, (i) {
      final done   = i < current;
      final active = i == current;
      return AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
        margin: const EdgeInsets.only(right: 6),
        width: active ? 22 : 7, height: 7,
        decoration: BoxDecoration(
          color: done || active ? primary : primary.withOpacity(0.18),
          borderRadius: BorderRadius.circular(4),
        ),
        child: done ? Center(child: Icon(Icons.check_rounded, color: surface, size: 5)) : null,
      );
    }),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// VET FIELD — animated input
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
        style: TextStyle(fontSize: 14, color: widget.textPri, fontWeight: FontWeight.w400),
        decoration: InputDecoration(
          labelText: widget.label,
          hintText: widget.hint,
          hintStyle: TextStyle(color: widget.primary.withOpacity(0.30), fontSize: 13, fontWeight: FontWeight.w300),
          labelStyle: TextStyle(
            color: _focused ? widget.primary : widget.primary.withOpacity(0.55),
            fontSize: _focused ? 11 : 13,
            fontWeight: FontWeight.w400,
            letterSpacing: _focused ? 0.5 : 0,
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14),
            child: Icon(widget.icon,
              color: _focused ? widget.primary : widget.primary.withOpacity(0.35), size: 18),
          ),
          border: InputBorder.none,
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: widget.maxLines > 1 ? 16 : 0),
          errorStyle: TextStyle(fontSize: 10, color: Colors.red.withOpacity(0.75), fontWeight: FontWeight.w300),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CONTACT OPTION CARD
// ─────────────────────────────────────────────────────────────────────────────
class _ContactOption extends StatelessWidget {
  final String value, label, subtitle;
  final IconData icon;
  final String groupValue;
  final ValueChanged<String> onChanged;
  final Color primary, surface, textPri, textSec;
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
          boxShadow: selected ? [BoxShadow(color: primary.withOpacity(0.10), blurRadius: 12, offset: const Offset(0, 3))] : null,
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
            Text(label, style: TextStyle(fontSize: 13, fontWeight: selected ? FontWeight.w500 : FontWeight.w400, color: textPri, letterSpacing: -0.2)),
            Text(subtitle, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w300, color: textSec.withOpacity(0.55))),
          ])),
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18, height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: selected ? primary : Colors.transparent,
              border: Border.all(color: selected ? primary : primary.withOpacity(0.25), width: 1.5),
            ),
            child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 11) : null,
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION LABEL
// ─────────────────────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  final Color primary, textSec;
  const _SectionLabel(this.text, {required this.primary, required this.textSec});
  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 18, height: 1, color: primary),
    const SizedBox(width: 8),
    Text(text, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w500, letterSpacing: 2.8, color: textSec.withOpacity(0.50))),
    const SizedBox(width: 8),
    Expanded(child: Container(height: 1, color: textSec.withOpacity(0.08))),
  ]);
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class EditVeterinarianProfileScreen extends StatefulWidget {
  const EditVeterinarianProfileScreen({super.key});

  @override
  State<EditVeterinarianProfileScreen> createState() => _EditVeterinarianProfileScreenState();
}

class _EditVeterinarianProfileScreenState extends State<EditVeterinarianProfileScreen>
    with TickerProviderStateMixin {

  late PageController _pageController;
  int _currentStep = 0;
  bool _isLoading = false;
  bool _profileLoading = true;

  // Controllers
  final _specialtyCtrl    = TextEditingController();
  final _zoneCtrl         = TextEditingController();
  final _distanceCtrl     = TextEditingController();
  final _experienceCtrl   = TextEditingController();
  final _bioCtrl          = TextEditingController();

  // Focus nodes
  final _specialtyFocus  = FocusNode();
  final _zoneFocus       = FocusNode();
  final _distanceFocus   = FocusNode();
  final _experienceFocus = FocusNode();
  final _bioFocus        = FocusNode();

  String _contactPreference = 'whatsapp';
  File?  _certificateFile;

  // Animations
  late AnimationController _grainCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _stepCtrl;
  late Animation<double>   _stepFade;
  late Animation<Offset>   _stepSlide;

  static const Color _primary = Color(0xFF00695C);
  static const Color _accent  = Color(0xFF80CBC4);

  @override
  void initState() {
    super.initState();
    _pageController = PageController();

    _grainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120))..repeat();
    _waveCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _stepCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _stepFade  = CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOut);
    _stepSlide = Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _stepCtrl, curve: Curves.easeOutCubic));
    _stepCtrl.forward();

    _loadProfile();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _grainCtrl.dispose();
    _waveCtrl.dispose();
    _stepCtrl.dispose();
    for (final c in [_specialtyCtrl, _zoneCtrl, _distanceCtrl, _experienceCtrl, _bioCtrl]) c.dispose();
    for (final f in [_specialtyFocus, _zoneFocus, _distanceFocus, _experienceFocus, _bioFocus]) f.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final profile = await ApiService.getVeterinarianProfile();
      if (profile != null && mounted) {
        setState(() {
          _specialtyCtrl.text  = profile.specialty;
          _zoneCtrl.text       = profile.zone;
          _distanceCtrl.text   = profile.distanceMax.toString();
          _experienceCtrl.text = profile.experienceYears.toString();
          _bioCtrl.text        = profile.bio ?? '';
          _contactPreference   = profile.contactPreference;
          _profileLoading      = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _profileLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))));
      }
    }
  }

  Future<void> _pickCertificate() async {
    try {
      final f = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (f != null && mounted) setState(() => _certificateFile = File(f.path));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  bool _validateStep1() {
    if (_specialtyCtrl.text.trim().isEmpty || _zoneCtrl.text.trim().isEmpty ||
        _distanceCtrl.text.trim().isEmpty || _experienceCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Tous les champs sont requis'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return false;
    }
    return true;
  }

  void _goToStep(int step) {
    HapticFeedback.lightImpact();
    _stepCtrl.forward(from: 0);
    _pageController.animateToPage(step, duration: const Duration(milliseconds: 340), curve: Curves.easeOutCubic);
  }

  void _next() {
    if (_currentStep == 0 && !_validateStep1()) return;
    if (_currentStep < 2) {
      _goToStep(_currentStep + 1);
    } else {
      _saveProfile();
    }
  }

  void _prev() {
    if (_currentStep > 0) _goToStep(_currentStep - 1);
  }

  bool get _canNext {
    if (_currentStep == 0) {
      return _specialtyCtrl.text.trim().isNotEmpty && _zoneCtrl.text.trim().isNotEmpty &&
             _distanceCtrl.text.trim().isNotEmpty && _experienceCtrl.text.trim().isNotEmpty;
    }
    return true;
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);
    try {
      // TODO: implement updateVeterinarianProfile API call
      await Future.delayed(const Duration(milliseconds: 800)); // simulate
      if (!mounted) return;
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Profil mis à jour avec succès'),
        backgroundColor: _primary,
        behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'), backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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
        // HERO HEADER
        _buildHeader(isDark, surface, textPri, textSec),

        // PAGE CONTENT
        Expanded(
          child: _profileLoading
              ? Center(child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(_accent)))
              : PageView(
                  controller: _pageController,
                  physics: const NeverScrollableScrollPhysics(),
                  onPageChanged: (i) => setState(() => _currentStep = i),
                  children: [
                    _step1(isDark, textPri, textSec),
                    _step2(isDark, surface, textPri, textSec),
                    _step3(isDark, surface, textPri, textSec),
                  ],
                ),
        ),

        // FOOTER
        _buildFooter(isDark, surface),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(bool isDark, Color surface, Color textPri, Color textSec) {
    final steps = ['Informations', 'Contact', 'Certificat'];

    return SizedBox(
      height: 185,
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        Positioned.fill(child: Container(decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0A1A18), const Color(0xFF051210)]
                : [const Color(0xFFE0F2F0), const Color(0xFFCCEAE7)],
          ),
        ))),
        Positioned.fill(child: AnimatedBuilder(
          animation: _grainCtrl,
          builder: (_, __) => CustomPaint(painter: _GrainPainter(seed: _grainCtrl.value, color: _primary)),
        )),
        const Positioned(top: -50, right: -50, child: SizedBox(
          width: 240, height: 240,
          child: CustomPaint(painter: _RingsPainter(color: _primary)),
        )),
        Positioned(top: -65, right: -65, child: Container(
          width: 200, height: 200,
          decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [_accent.withOpacity(isDark ? 0.13 : 0.08), Colors.transparent])),
        )),
        // Wave
        Positioned(bottom: 0, left: 0, right: 0, child: AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, __) => SizedBox(height: 60, child: CustomPaint(
            painter: _WavePainter(phase: _waveCtrl.value * 2 * pi, color: _primary.withOpacity(isDark ? 0.18 : 0.09), yOffset: 0.40),
            size: Size(MediaQuery.of(context).size.width, 60),
          )),
        )),
        // Content
        Padding(
          padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 10, 20, 26),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Top row: back + dots
            Row(children: [
              GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); Navigator.of(context).pop(); },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _primary.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.arrow_back_rounded, color: _primary, size: 17),
                ),
              ),
              const Spacer(),
              _StepDots(current: _currentStep, total: 3, primary: _primary,
                  surface: isDark ? const Color(0xFF0A1A18) : Colors.white),
            ]),
            const Spacer(),
            // Tag + title
            _Tag('MODIFIER', bg: _primary.withOpacity(0.12), fg: _primary.withOpacity(0.80), icon: Icons.edit_outlined),
            const SizedBox(height: 5),
            Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
              Text('ÉTAPE ${_currentStep + 1} / 3 — ', style: TextStyle(
                fontSize: 7, fontWeight: FontWeight.w400, letterSpacing: 1.8, color: _accent.withOpacity(0.70),
              )),
              Text(steps[_currentStep], style: TextStyle(
                fontSize: 7, fontWeight: FontWeight.w500, letterSpacing: 1.8, color: _accent.withOpacity(0.70),
              )),
            ]),
            const SizedBox(height: 3),
            Text('Éditer mon profil', style: TextStyle(
              fontSize: 22, fontWeight: FontWeight.w300,
              color: textPri, letterSpacing: -1.3, height: 1.1,
            )),
          ]),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 1 — Pro info
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _step1(bool isDark, Color textPri, Color textSec) {
    return FadeTransition(
      opacity: _stepFade,
      child: SlideTransition(
        position: _stepSlide,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          physics: const BouncingScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SectionLabel('INFORMATIONS PROFESSIONNELLES', primary: _primary, textSec: textSec),
            const SizedBox(height: 16),
            _VetField(controller: _specialtyCtrl, focusNode: _specialtyFocus,
              label: 'Spécialité', hint: 'ex. Médecine bovine…',
              icon: Icons.medical_services_outlined,
              primary: _primary, textPri: textPri, isDark: isDark),
            const SizedBox(height: 14),
            _VetField(controller: _zoneCtrl, focusNode: _zoneFocus,
              label: 'Zone de couverture', hint: 'ex. Dakar, Thiès…',
              icon: Icons.location_on_outlined,
              primary: _primary, textPri: textPri, isDark: isDark),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _VetField(controller: _distanceCtrl, focusNode: _distanceFocus,
                label: 'Distance max (km)', hint: '50',
                icon: Icons.radar_rounded, keyboardType: TextInputType.number,
                primary: _primary, textPri: textPri, isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(child: _VetField(controller: _experienceCtrl, focusNode: _experienceFocus,
                label: 'Expérience (ans)', hint: '5',
                icon: Icons.timeline_rounded, keyboardType: TextInputType.number,
                primary: _primary, textPri: textPri, isDark: isDark)),
            ]),
            const SizedBox(height: 24),
            _SectionLabel('BIOGRAPHIE', primary: _primary, textSec: textSec),
            const SizedBox(height: 16),
            _VetField(controller: _bioCtrl, focusNode: _bioFocus,
              label: 'Décrivez-vous', hint: 'Formation, spécialisations, approche…',
              icon: Icons.edit_note_rounded, maxLines: 5,
              primary: _primary, textPri: textPri, isDark: isDark),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 2 — Contact
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _step2(bool isDark, Color surface, Color textPri, Color textSec) {
    return FadeTransition(
      opacity: _stepFade,
      child: SlideTransition(
        position: _stepSlide,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          physics: const BouncingScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SectionLabel('PRÉFÉRENCE DE CONTACT', primary: _primary, textSec: textSec),
            const SizedBox(height: 6),
            Text('Comment les agriculteurs peuvent-ils vous contacter ?',
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300, color: textSec.withOpacity(0.65), height: 1.5)),
            const SizedBox(height: 18),
            _ContactOption(value: 'whatsapp', label: 'WhatsApp', subtitle: 'Messages et appels via WhatsApp',
              icon: Icons.chat_bubble_outline_rounded,
              groupValue: _contactPreference, onChanged: (v) => setState(() => _contactPreference = v),
              primary: _primary, surface: surface, textPri: textPri, textSec: textSec, isDark: isDark),
            _ContactOption(value: 'call', label: 'Appel téléphonique', subtitle: 'Contact direct par téléphone',
              icon: Icons.phone_outlined,
              groupValue: _contactPreference, onChanged: (v) => setState(() => _contactPreference = v),
              primary: _primary, surface: surface, textPri: textPri, textSec: textSec, isDark: isDark),
            _ContactOption(value: 'email', label: 'Email', subtitle: 'Échanges par messagerie électronique',
              icon: Icons.mail_outline_rounded,
              groupValue: _contactPreference, onChanged: (v) => setState(() => _contactPreference = v),
              primary: _primary, surface: surface, textPri: textPri, textSec: textSec, isDark: isDark),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STEP 3 — Certificat
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _step3(bool isDark, Color surface, Color textPri, Color textSec) {
    final hasFile = _certificateFile != null;

    return FadeTransition(
      opacity: _stepFade,
      child: SlideTransition(
        position: _stepSlide,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
          physics: const BouncingScrollPhysics(),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            _SectionLabel('CERTIFICAT PROFESSIONNEL', primary: _primary, textSec: textSec),
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
                    color: hasFile ? Colors.green.withOpacity(0.35) : _primary.withOpacity(0.18),
                    width: 1.5,
                  ),
                ),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: hasFile ? Colors.green.withOpacity(0.10) : _primary.withOpacity(0.07),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasFile ? Icons.check_circle_outline_rounded : Icons.upload_file_rounded,
                      size: 30, color: hasFile ? Colors.green : _primary.withOpacity(0.55),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    hasFile ? 'Certificat sélectionné' : 'Appuyer pour sélectionner',
                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400,
                        color: hasFile ? Colors.green.withOpacity(0.85) : textPri.withOpacity(0.70)),
                  ),
                  const SizedBox(height: 5),
                  if (hasFile)
                    Text(_certificateFile!.path.split('/').last,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w300, color: textSec.withOpacity(0.55)),
                      textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis)
                  else
                    Text('JPG, PNG — Photo du certificat vétérinaire',
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w300, color: _primary.withOpacity(0.38))),
                  if (hasFile) ...[
                    const SizedBox(height: 12),
                    GestureDetector(
                      onTap: () { HapticFeedback.lightImpact(); setState(() => _certificateFile = null); },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.07),
                          borderRadius: BorderRadius.circular(7),
                          border: Border.all(color: Colors.red.withOpacity(0.18)),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.close_rounded, color: Colors.red.withOpacity(0.65), size: 12),
                          const SizedBox(width: 6),
                          Text('Supprimer', style: TextStyle(fontSize: 11, color: Colors.red.withOpacity(0.75), fontWeight: FontWeight.w400)),
                        ]),
                      ),
                    ),
                  ] else ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
                      decoration: BoxDecoration(
                        color: _primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text('Choisir une image', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w500, color: _primary, letterSpacing: 0.3,
                      )),
                    ),
                  ],
                ]),
              ),
            ),

            const SizedBox(height: 18),

            // Info notice
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _accent.withOpacity(isDark ? 0.08 : 0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: _accent.withOpacity(0.20)),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.info_outline_rounded, color: _accent.withOpacity(0.70), size: 15),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Votre certificat doit être clair et lisible. La mise à jour sera soumise à vérification.',
                  style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w300, color: textPri.withOpacity(0.70), height: 1.55),
                )),
              ]),
            ),
          ]),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FOOTER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFooter(bool isDark, Color surface) {
    return Container(
      padding: EdgeInsets.fromLTRB(20, 14, 20, MediaQuery.of(context).padding.bottom + 18),
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
            onTap: _prev,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                color: _primary.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.arrow_back_rounded, color: _primary, size: 14),
                const SizedBox(width: 7),
                Text('Retour', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: _primary)),
              ]),
            ),
          )
        else
          const SizedBox(width: 1),

        const Spacer(),

        // Next / Save button
        GestureDetector(
          onTap: (!_canNext || _isLoading) ? null : _next,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 14),
            decoration: BoxDecoration(
              color: _canNext ? _primary : _primary.withOpacity(0.25),
              borderRadius: BorderRadius.circular(12),
              boxShadow: _canNext ? [BoxShadow(color: _primary.withOpacity(0.28), blurRadius: 16, offset: const Offset(0, 6))] : null,
            ),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              if (_isLoading)
                const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
              else ...[
                Text(
                  _currentStep < 2 ? 'Suivant' : 'Enregistrer',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.3),
                ),
                const SizedBox(width: 8),
                Icon(
                  _currentStep < 2 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                  color: Colors.white, size: 14,
                ),
              ],
            ]),
          ),
        ),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAG helper
// ─────────────────────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String text;
  final Color bg, fg;
  final IconData? icon;
  const _Tag(this.text, {required this.bg, required this.fg, this.icon});
  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: icon != null ? 7 : 9, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[Icon(icon, size: 7.5, color: fg), const SizedBox(width: 4)],
      Text(text, style: TextStyle(fontSize: 7, fontWeight: FontWeight.w600, letterSpacing: 1.8, color: fg)),
    ]),
  );
}