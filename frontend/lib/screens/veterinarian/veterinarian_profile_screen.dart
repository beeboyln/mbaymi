import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mbaymi/models/veterinarian_model.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/widgets/skeleton_loader.dart';

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
    for (int i = 0; i < 240; i++) {
      paint.color = color.withOpacity(rng.nextDouble() * 0.036 + 0.004);
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 0.85 + 0.15, paint,
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
    for (int i = 1; i <= 6; i++) {
      paint.color = color.withOpacity(0.020 + i * 0.004);
      canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.5), i * 38.0, paint);
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

// Stethoscope + paw illustration
class _VetIllustrationPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final bool isDark;
  final double phase;
  const _VetIllustrationPainter({required this.primary, required this.accent, required this.isDark, required this.phase});

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width; final h = size.height;
    final baseOp = isDark ? 0.18 : 0.13;
    final accentOp = isDark ? 0.32 : 0.24;
    final sway = 1.4 * sin(phase * 2 * pi);

    final fillP = Paint()..color = primary.withOpacity(baseOp)..style = PaintingStyle.fill;
    final fillA = Paint()..color = accent.withOpacity(accentOp)..style = PaintingStyle.fill;
    final strokeP = Paint()..color = primary.withOpacity(baseOp * 0.75)..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round;

    // Tube
    final tube = Path();
    tube.moveTo(w * 0.35, h * 0.20);
    tube.cubicTo(w * 0.18, h * 0.20, w * 0.12 + sway, h * 0.55, w * 0.30 + sway, h * 0.72);
    tube.cubicTo(w * 0.45 + sway, h * 0.85, w * 0.62 + sway, h * 0.82, w * 0.72 + sway, h * 0.68);
    canvas.drawPath(tube, strokeP);
    canvas.drawCircle(Offset(w * 0.72 + sway, h * 0.64), w * 0.088, fillA);
    canvas.drawCircle(Offset(w * 0.72 + sway, h * 0.64), w * 0.065, Paint()..color = accent.withOpacity(accentOp * 0.40)..style = PaintingStyle.fill);

    // Earpieces
    final ep1 = Path();
    ep1.moveTo(w * 0.35, h * 0.20);
    ep1.cubicTo(w * 0.34, h * 0.12, w * 0.28, h * 0.10, w * 0.26, h * 0.15);
    canvas.drawPath(ep1, strokeP..strokeWidth = 1.5);
    canvas.drawCircle(Offset(w * 0.26, h * 0.15), w * 0.030, fillP);

    final ep2 = Path();
    ep2.moveTo(w * 0.35, h * 0.20);
    ep2.cubicTo(w * 0.46, h * 0.14, w * 0.50, h * 0.10, w * 0.52, h * 0.16);
    canvas.drawPath(ep2, strokeP);
    canvas.drawCircle(Offset(w * 0.52, h * 0.16), w * 0.030, fillP);

    // Paw
    final pawX = w * 0.58; final pawY = h * 0.38 + sway * 0.4;
    for (final t in [Offset(pawX - w * 0.10, pawY - h * 0.06), Offset(pawX, pawY - h * 0.09), Offset(pawX + w * 0.10, pawY - h * 0.06)]) {
      canvas.drawOval(Rect.fromCenter(center: t, width: w * 0.07, height: h * 0.048), fillA..color = accent.withOpacity(accentOp * 0.80));
    }
    canvas.drawOval(Rect.fromCenter(center: Offset(pawX, pawY + h * 0.01), width: w * 0.17, height: h * 0.12), fillA..color = accent.withOpacity(accentOp * 0.55));

    // Cross
    final cx = w * 0.20; final cy = h * 0.78 + sway * 0.2; final cr = w * 0.055;
    final crossPaint = Paint()..color = primary.withOpacity(baseOp * 0.65)..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: cr * 2.2, height: cr * 0.7), const Radius.circular(2)), crossPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: cr * 0.7, height: cr * 2.2), const Radius.circular(2)), crossPaint);
  }

  @override
  bool shouldRepaint(_VetIllustrationPainter o) => o.phase != phase || o.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String text;
  final Color primary;
  final Color textSec;
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

class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color primary;
  final Color accent;
  final Color surface;
  final Color textPri;
  final Color textSec;
  final bool isDark;

  const _InfoTile({
    required this.icon, required this.label, required this.value,
    required this.primary, required this.accent, required this.surface,
    required this.textPri, required this.textSec, required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: surface,
      boxShadow: [BoxShadow(
        color: isDark ? Colors.black.withOpacity(0.18) : Colors.black.withOpacity(0.04),
        blurRadius: 14, offset: const Offset(0, 3), spreadRadius: -2,
      )],
    ),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(color: accent.withOpacity(0.10), borderRadius: BorderRadius.circular(9)),
        child: Icon(icon, color: accent, size: 15),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: TextStyle(
          fontSize: 7, fontWeight: FontWeight.w500, letterSpacing: 1.8, color: textSec.withOpacity(0.50),
        )),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: textPri)),
      ]),
    ]),
  );
}

class _StatChip extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color primary;
  final Color accent;
  final Color surface;
  final Color textPri;
  final Color textSec;
  final bool isDark;

  const _StatChip({
    required this.label, required this.value, required this.icon,
    required this.primary, required this.accent, required this.surface,
    required this.textPri, required this.textSec, required this.isDark,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    decoration: BoxDecoration(
      color: surface,
      boxShadow: [BoxShadow(
        color: isDark ? Colors.black.withOpacity(0.20) : primary.withOpacity(0.06),
        blurRadius: 16, offset: const Offset(0, 5), spreadRadius: -2,
      )],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(color: accent.withOpacity(0.10), borderRadius: BorderRadius.circular(7)),
        child: Icon(icon, color: accent, size: 13),
      ),
      const SizedBox(height: 10),
      Text(value, style: TextStyle(
        fontSize: 28, fontWeight: FontWeight.w700,
        color: textPri, letterSpacing: -1.8, height: 1.0,
      )),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(
        fontSize: 8.5, fontWeight: FontWeight.w300, color: textSec.withOpacity(0.55), letterSpacing: 0.3,
      )),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class VeterinarianProfileScreen extends StatefulWidget {
  const VeterinarianProfileScreen({super.key});

  @override
  State<VeterinarianProfileScreen> createState() => _VeterinarianProfileScreenState();
}

class _VeterinarianProfileScreenState extends State<VeterinarianProfileScreen>
    with TickerProviderStateMixin {

  late Future<VeterinarianProfile?> _profileFuture;

  late AnimationController _grainCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _entryCtrl;
  List<Animation<double>>? _fade;
  List<Animation<Offset>>?  _slide;

  final _imagePicker = ImagePicker();
  bool _certificateUploading = false;

  static const Color _primary = Color(0xFF00695C);
  static const Color _accent  = Color(0xFF80CBC4);

  @override
  void initState() {
    super.initState();
    _profileFuture = ApiService.getVeterinarianProfile();

    _grainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120))..repeat();
    _waveCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

    _fade  = List.generate(7, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Interval(i * 0.08, min(i * 0.08 + 0.50, 1.0), curve: Curves.easeOut)),
    ));
    _slide = List.generate(7, (i) => Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Interval(i * 0.08, min(i * 0.08 + 0.50, 1.0), curve: Curves.easeOutCubic)),
    ));
  }

  @override
  void dispose() {
    _grainCtrl.dispose();
    _waveCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _s(int i, Widget child) {
    final f = _fade; final s = _slide;
    if (f == null || s == null) return child;
    return FadeTransition(opacity: f[i], child: SlideTransition(position: s[i], child: child));
  }

  void _startEntry() => _entryCtrl.forward(from: 0);

  Future<void> _logout() async {
    HapticFeedback.mediumImpact();
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final surface = isDark ? const Color(0xFF0D1A18) : Colors.white;
        final textPri = isDark ? const Color(0xFFE0F2F1) : const Color(0xFF0D2420);
        return Dialog(
          backgroundColor: surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.08), shape: BoxShape.circle,
                ),
                child: Icon(Icons.logout_rounded, color: Colors.red.withOpacity(0.70), size: 24),
              ),
              const SizedBox(height: 18),
              Text('Déconnexion', style: TextStyle(
                fontSize: 17, fontWeight: FontWeight.w500, color: textPri, letterSpacing: -0.3,
              )),
              const SizedBox(height: 8),
              Text('Voulez-vous vraiment vous déconnecter ?', style: TextStyle(
                fontSize: 12, fontWeight: FontWeight.w300,
                color: textPri.withOpacity(0.55), height: 1.5,
              ), textAlign: TextAlign.center),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, false),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: _primary.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text('Annuler', textAlign: TextAlign.center, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w400, color: _primary,
                    )),
                  ),
                )),
                const SizedBox(width: 10),
                Expanded(child: GestureDetector(
                  onTap: () => Navigator.pop(ctx, true),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.red.withOpacity(0.20)),
                    ),
                    child: Text('Déconnecter', textAlign: TextAlign.center, style: TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w500,
                      color: Colors.red.withOpacity(0.80),
                    )),
                  ),
                )),
              ]),
            ]),
          ),
        );
      },
    );
    if (confirm == true && mounted) {
      await AuthService.logout();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
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
      body: FutureBuilder<VeterinarianProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Column(children: [
              _buildHeader(null, isDark, surface, textPri, textSec),
              Expanded(child: SkeletonPageLoader(isDarkMode: isDark, includeAppBar: false, cardCount: 4, backgroundColor: bg)),
            ]);
          }

          if (snapshot.hasError) {
            return _errorState(snapshot.error.toString(), isDark, surface, textPri, textSec);
          }

          final profile = snapshot.data;
          if (profile == null) return _nullState(isDark, textPri, textSec);

          _startEntry();
          return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _buildHeader(profile, isDark, surface, textPri, textSec)),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                sliver: SliverToBoxAdapter(
                  child: _s(0, _verificationBanner(profile, isDark, surface, textPri, textSec)),
                ),
              ),

              if (profile.bio.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  sliver: SliverToBoxAdapter(child: _s(1, _bioSection(profile, isDark, surface, textPri, textSec))),
                ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                sliver: SliverToBoxAdapter(child: _s(2, _infoSection(profile, isDark, surface, textPri, textSec))),
              ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                sliver: SliverToBoxAdapter(child: _s(3, _certificateSection(profile, isDark, surface, textPri, textSec))),
              ),

              if (profile.consultationCount != null || profile.rating != null)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  sliver: SliverToBoxAdapter(child: _s(4, _statsSection(profile, isDark, surface, textPri, textSec))),
                ),

              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                sliver: SliverToBoxAdapter(child: _s(5, _actionButtons(isDark, textPri))),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO HEADER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHeader(VeterinarianProfile? profile, bool isDark, Color surface, Color textPri, Color textSec) {
    return SizedBox(
      height: 230,
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
        const Positioned(top: -40, right: -50, child: SizedBox(
          width: 260, height: 260,
          child: CustomPaint(painter: _RingsPainter(color: _primary)),
        )),
        Positioned(top: -70, right: -70, child: Container(
          width: 220, height: 220,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              _accent.withOpacity(isDark ? 0.14 : 0.09), Colors.transparent,
            ]),
          ),
        )),
        // Illustration
        Positioned(right: 10, bottom: 14, top: 14, child: SizedBox(
          width: 130,
          child: AnimatedBuilder(
            animation: _waveCtrl,
            builder: (_, __) => CustomPaint(painter: _VetIllustrationPainter(
              primary: _primary, accent: _accent, isDark: isDark, phase: _waveCtrl.value,
            )),
          ),
        )),
        // Waves
        Positioned(bottom: 0, left: 0, right: 0, child: AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, __) => SizedBox(height: 80, child: CustomPaint(
            painter: _WavePainter(phase: _waveCtrl.value * 2 * pi, color: _primary.withOpacity(isDark ? 0.20 : 0.10), yOffset: 0.48),
            size: Size(MediaQuery.of(context).size.width, 80),
          )),
        )),
        Positioned(bottom: 0, left: 0, right: 0, child: AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, __) => SizedBox(height: 80, child: CustomPaint(
            painter: _WavePainter(phase: _waveCtrl.value * 2 * pi + 1.6, color: _primary.withOpacity(isDark ? 0.09 : 0.06), yOffset: 0.66),
            size: Size(MediaQuery.of(context).size.width, 80),
          )),
        )),
        // Content
        Padding(
          padding: EdgeInsets.fromLTRB(22, MediaQuery.of(context).padding.top + 12, 22, 36),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              if (Navigator.of(context).canPop())
                GestureDetector(
                  onTap: () { HapticFeedback.lightImpact(); Navigator.of(context).pop(); },
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(color: _primary.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.arrow_back_rounded, color: _primary, size: 17),
                  ),
                ),
              const Spacer(),
              GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); Navigator.pushNamed(context, '/edit-veterinarian-profile'); },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _primary.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.edit_outlined, color: _primary, size: 17),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _logout,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.logout_rounded, color: Colors.red.withOpacity(0.65), size: 17),
                ),
              ),
            ]),
            const Spacer(),
            _Tag('MON PROFIL', bg: _primary.withOpacity(0.12), fg: _primary.withOpacity(0.80), icon: Icons.medical_services_outlined),
            const SizedBox(height: 6),
            Text(
              profile?.specialty ?? 'Vétérinaire',
              style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w300,
                color: textPri, letterSpacing: -1.4, height: 1.1,
              ),
            ),
            if (profile?.zone != null) ...[
              const SizedBox(height: 5),
              Row(children: [
                Icon(Icons.location_on_outlined, color: _accent.withOpacity(0.70), size: 12),
                const SizedBox(width: 4),
                Text(profile!.zone, style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w300,
                  color: _accent.withOpacity(0.75),
                )),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VERIFICATION BANNER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _verificationBanner(VeterinarianProfile profile, bool isDark, Color surface, Color textPri, Color textSec) {
    final verified = profile.verificationStatus == 'verified';
    final bannerColor = verified ? Colors.green : const Color(0xFFFF9800);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bannerColor.withOpacity(isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: bannerColor.withOpacity(0.22)),
        boxShadow: [BoxShadow(
          color: bannerColor.withOpacity(0.08),
          blurRadius: 16, offset: const Offset(0, 4), spreadRadius: -2,
        )],
      ),
      child: Row(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: bannerColor.withOpacity(0.12), shape: BoxShape.circle),
          child: Icon(
            verified ? Icons.verified_rounded : Icons.hourglass_top_rounded,
            color: bannerColor, size: 18,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(
            verified ? 'Profil vérifié' : 'Vérification en cours',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPri, letterSpacing: -0.2),
          ),
          const SizedBox(height: 2),
          Text(
            verified
                ? 'Votre profil est certifié et visible par les agriculteurs.'
                : 'Un administrateur examinera votre certificat sous 24–48h.',
            style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w300, color: textSec.withOpacity(0.65), height: 1.4),
          ),
        ])),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(
            color: bannerColor.withOpacity(0.12),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            verified ? 'VÉRIFIÉ' : 'EN ATTENTE',
            style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w700, letterSpacing: 1.4, color: bannerColor),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BIO SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _bioSection(VeterinarianProfile profile, bool isDark, Color surface, Color textPri, Color textSec) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionLabel('À PROPOS', primary: _primary, textSec: textSec),
      const SizedBox(height: 14),
      Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surface,
          boxShadow: [BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.18) : Colors.black.withOpacity(0.04),
            blurRadius: 14, offset: const Offset(0, 3), spreadRadius: -2,
          )],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 2.5, height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [_accent.withOpacity(0.9), _accent.withOpacity(0.10)],
              ),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(
            profile.bio,
            style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w300,
              color: textPri.withOpacity(0.80), height: 1.65, letterSpacing: 0.1,
            ),
          )),
        ]),
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // INFO SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _infoSection(VeterinarianProfile profile, bool isDark, Color surface, Color textPri, Color textSec) {
    String contactLabel;
    IconData contactIcon;
    switch (profile.contactPreference) {
      case 'whatsapp': contactLabel = 'WhatsApp'; contactIcon = Icons.chat_bubble_outline_rounded; break;
      case 'call': contactLabel = 'Appel téléphonique'; contactIcon = Icons.phone_outlined; break;
      case 'email': contactLabel = 'Email'; contactIcon = Icons.mail_outline_rounded; break;
      default: contactLabel = profile.contactPreference.toUpperCase(); contactIcon = Icons.contact_phone_outlined;
    }

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionLabel('INFORMATIONS', primary: _primary, textSec: textSec),
      const SizedBox(height: 14),
      _InfoTile(
        icon: Icons.timeline_rounded, label: 'Expérience',
        value: '${profile.experienceYears} ans',
        primary: _primary, accent: _accent, surface: surface,
        textPri: textPri, textSec: textSec, isDark: isDark,
      ),
      const SizedBox(height: 10),
      _InfoTile(
        icon: Icons.radar_rounded, label: 'Distance maximale',
        value: 'Jusqu\'à ${profile.distanceMax} km',
        primary: _primary, accent: _accent, surface: surface,
        textPri: textPri, textSec: textSec, isDark: isDark,
      ),
      const SizedBox(height: 10),
      _InfoTile(
        icon: contactIcon, label: 'Préférence de contact',
        value: contactLabel,
        primary: _primary, accent: _accent, surface: surface,
        textPri: textPri, textSec: textSec, isDark: isDark,
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _statsSection(VeterinarianProfile profile, bool isDark, Color surface, Color textPri, Color textSec) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionLabel('STATISTIQUES', primary: _primary, textSec: textSec),
      const SizedBox(height: 14),
      Row(children: [
        if (profile.consultationCount != null) ...[
          Expanded(child: _StatChip(
            label: 'Consultations', value: '${profile.consultationCount}',
            icon: Icons.video_call_outlined,
            primary: _primary, accent: _accent, surface: surface,
            textPri: textPri, textSec: textSec, isDark: isDark,
          )),
          if (profile.rating != null) const SizedBox(width: 12),
        ],
        if (profile.rating != null)
          Expanded(child: _StatChip(
            label: 'Note moyenne',
            value: profile.rating?.toStringAsFixed(1) ?? 'N/A',
            icon: Icons.star_outline_rounded,
            primary: _primary, accent: const Color(0xFFFFB300), surface: surface,
            textPri: textPri, textSec: textSec, isDark: isDark,
          )),
      ]),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CERTIFICATE SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _certificateSection(VeterinarianProfile profile, bool isDark, Color surface, Color textPri, Color textSec) {
    final hasCert = profile.certificateUrl != null && profile.certificateUrl!.isNotEmpty;
    
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionLabel('CERTIFICAT PROFESSIONNEL', primary: _primary, textSec: textSec),
      const SizedBox(height: 14),
      
      if (hasCert) ...[
        // Show existing certificate
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(isDark ? 0.08 : 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.25)),
          ),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Row(children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 18),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Certificat enregistré', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500, color: Colors.green,
                )),
                Text('Statut: ${profile.verificationStatus}', style: TextStyle(
                  fontSize: 11, fontWeight: FontWeight.w300, color: textSec.withOpacity(0.7),
                )),
              ])),
            ]),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () async {
                  if (profile.certificateUrl != null && profile.certificateUrl!.isNotEmpty) {
                    if (await canLaunchUrl(Uri.parse(profile.certificateUrl!))) {
                      await launchUrl(Uri.parse(profile.certificateUrl!));
                    }
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.download_outlined, color: Colors.green, size: 14),
                    const SizedBox(width: 6),
                    Text('Voir le certificat', style: TextStyle(
                      fontSize: 11, fontWeight: FontWeight.w500, color: Colors.green,
                    )),
                  ]),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: _certificateUploading ? null : () => _uploadCertificate(profile),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  decoration: BoxDecoration(
                    color: _primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: _certificateUploading
                    ? const SizedBox(width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 1.5))
                    : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(Icons.edit_outlined, color: _primary, size: 14),
                        const SizedBox(width: 6),
                        Text('Modifier', style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w500, color: _primary,
                        )),
                      ]),
                ),
              )),
            ]),
          ]),
        ),
      ] else ...[
        // Show upload prompt
        GestureDetector(
          onTap: _certificateUploading ? null : () => _uploadCertificate(profile),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: _primary.withOpacity(isDark ? 0.05 : 0.03),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _primary.withOpacity(0.18), width: 1.5),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _primary.withOpacity(0.07),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  _certificateUploading ? Icons.hourglass_empty_rounded : Icons.upload_file_rounded,
                  size: 32,
                  color: _primary.withOpacity(0.55),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                _certificateUploading ? 'Envoi en cours...' : 'Ajouter mon certificat',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w400,
                  color: textPri.withOpacity(0.70),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                'JPG, PNG — Diplôme ou certificat vétérinaire',
                style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w300,
                  color: _primary.withOpacity(0.40),
                ),
              ),
            ]),
          ),
        ),
      ],
    ]);
  }

  Future<void> _uploadCertificate(VeterinarianProfile profile) async {
    try {
      final file = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 85);
      if (file == null || !mounted) return;

      setState(() => _certificateUploading = true);

      // Upload to Cloudinary
      debugPrint('📤 Uploading certificate to Cloudinary...');
      final certificateUrl = await ApiService.uploadImageToCloudinary(
        file,
      );

      if (!mounted) return;

      // Update profile with new certificate
      await ApiService.createVeterinarianProfile(
        specialty: profile.specialty,
        zone: profile.zone,
        distanceMax: profile.distanceMax,
        bio: profile.bio,
        experienceYears: profile.experienceYears,
        contactPreference: profile.contactPreference,
        certificateUrl: certificateUrl,
        certificateFilename: file.name,
      );

      if (!mounted) return;

      // Refresh the profile
      setState(() {
        _profileFuture = ApiService.getVeterinarianProfile();
        _certificateUploading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: const Text('✅ Certificat mis à jour avec succès'),
          backgroundColor: Colors.green.withOpacity(0.8),
          behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _certificateUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'),
            backgroundColor: Colors.red.withOpacity(0.8),
            behavior: SnackBarBehavior.floating, margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        );
      }
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTION BUTTONS
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _actionButtons(bool isDark, Color textPri) {
    return Column(children: [
      // Edit CTA
      GestureDetector(
        onTap: () { HapticFeedback.lightImpact(); Navigator.pushNamed(context, '/edit-veterinarian-profile'); },
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: _primary,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [BoxShadow(color: _primary.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 7))],
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            const Icon(Icons.edit_outlined, color: Colors.white, size: 15),
            const SizedBox(width: 8),
            const Text('Modifier mon profil', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.3,
            )),
          ]),
        ),
      ),
      const SizedBox(height: 12),
      // Logout
      GestureDetector(
        onTap: _logout,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(isDark ? 0.08 : 0.05),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.red.withOpacity(0.15)),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            Icon(Icons.logout_rounded, color: Colors.red.withOpacity(0.70), size: 15),
            const SizedBox(width: 8),
            Text('Se déconnecter', style: TextStyle(
              fontSize: 13, fontWeight: FontWeight.w400,
              color: Colors.red.withOpacity(0.75),
            )),
          ]),
        ),
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR / NULL STATES
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _errorState(String err, bool isDark, Color surface, Color textPri, Color textSec) {
    final bg = isDark ? const Color(0xFF060E0D) : const Color(0xFFF4FAF9);
    return Scaffold(
      backgroundColor: bg,
      body: Center(child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle),
            child: Icon(Icons.error_outline_rounded, color: Colors.red.withOpacity(0.60), size: 36),
          ),
          const SizedBox(height: 20),
          Text('Une erreur est survenue', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: textPri, letterSpacing: -0.3,
          )),
          const SizedBox(height: 8),
          Text(err, style: TextStyle(fontSize: 11, color: textSec.withOpacity(0.55), fontWeight: FontWeight.w300)),
          const SizedBox(height: 28),
          GestureDetector(
            onTap: () => setState(() => _profileFuture = ApiService.getVeterinarianProfile()),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
              decoration: BoxDecoration(
                color: _primary, borderRadius: BorderRadius.circular(10),
                boxShadow: [BoxShadow(color: _primary.withOpacity(0.25), blurRadius: 14, offset: const Offset(0, 5))],
              ),
              child: const Text('Réessayer', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ),
        ]),
      )),
    );
  }

  Widget _nullState(bool isDark, Color textPri, Color textSec) {
    final bg = isDark ? const Color(0xFF060E0D) : const Color(0xFFF4FAF9);
    return Scaffold(
      backgroundColor: bg,
      body: Center(child: Padding(
        padding: const EdgeInsets.all(36),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(color: _primary.withOpacity(0.07), shape: BoxShape.circle),
            child: Icon(Icons.medical_services_outlined, color: _primary.withOpacity(0.45), size: 40),
          ),
          const SizedBox(height: 24),
          Text('PROFIL INTROUVABLE', style: TextStyle(
            fontSize: 7.5, fontWeight: FontWeight.w600, letterSpacing: 2.8, color: _primary.withOpacity(0.45),
          )),
          const SizedBox(height: 10),
          Text('Profil vétérinaire\nnon configuré', style: TextStyle(
            fontSize: 22, fontWeight: FontWeight.w300, color: textPri, letterSpacing: -1.2, height: 1.2,
          ), textAlign: TextAlign.center),
          const SizedBox(height: 14),
          Text('Créez votre profil pour commencer\nà recevoir des demandes.',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w300, color: textSec.withOpacity(0.60), height: 1.55),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 32),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/veterinarian-setup'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 15),
              decoration: BoxDecoration(
                color: _primary, borderRadius: BorderRadius.circular(12),
                boxShadow: [BoxShadow(color: _primary.withOpacity(0.28), blurRadius: 18, offset: const Offset(0, 7))],
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Text('Créer mon profil', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.3)),
                const SizedBox(width: 8),
                const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 15),
              ]),
            ),
          ),
        ]),
      )),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// TAG helper
// ─────────────────────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
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