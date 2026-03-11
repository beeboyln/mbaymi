import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:mbaymi/models/veterinarian_model.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/token_storage.dart';
import 'package:mbaymi/utils/app_colors.dart';
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
      paint.color = color.withOpacity(rng.nextDouble() * 0.035 + 0.004);
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
    final strokeP = Paint()..color = primary.withOpacity(baseOp * 0.75)..style = PaintingStyle.stroke..strokeWidth = 2.0..strokeCap = StrokeCap.round;
    final fillA = Paint()..color = accent.withOpacity(accentOp)..style = PaintingStyle.fill;
    final fillP = Paint()..color = primary.withOpacity(baseOp)..style = PaintingStyle.fill;
    // tube
    final tube = Path();
    tube.moveTo(w * 0.35, h * 0.20);
    tube.cubicTo(w * 0.18, h * 0.20, w * 0.12 + sway, h * 0.55, w * 0.30 + sway, h * 0.72);
    tube.cubicTo(w * 0.45 + sway, h * 0.85, w * 0.62 + sway, h * 0.82, w * 0.72 + sway, h * 0.68);
    canvas.drawPath(tube, strokeP);
    canvas.drawCircle(Offset(w * 0.72 + sway, h * 0.64), w * 0.088, fillA);
    canvas.drawCircle(Offset(w * 0.72 + sway, h * 0.64), w * 0.065, Paint()..color = accent.withOpacity(accentOp * 0.40)..style = PaintingStyle.fill);
    // earpieces
    final ep1 = Path()..moveTo(w*0.35,h*0.20)..cubicTo(w*0.34,h*0.12,w*0.28,h*0.10,w*0.26,h*0.15);
    canvas.drawPath(ep1, strokeP..strokeWidth = 1.5);
    canvas.drawCircle(Offset(w*0.26,h*0.15), w*0.030, fillP);
    final ep2 = Path()..moveTo(w*0.35,h*0.20)..cubicTo(w*0.46,h*0.14,w*0.50,h*0.10,w*0.52,h*0.16);
    canvas.drawPath(ep2, strokeP);
    canvas.drawCircle(Offset(w*0.52,h*0.16), w*0.030, fillP);
    // paw
    final pawX = w * 0.58; final pawY = h * 0.38 + sway * 0.4;
    for (final t in [Offset(pawX-w*0.10,pawY-h*0.06),Offset(pawX,pawY-h*0.09),Offset(pawX+w*0.10,pawY-h*0.06)]) {
      canvas.drawOval(Rect.fromCenter(center: t, width: w*0.07, height: h*0.048), fillA..color = accent.withOpacity(accentOp*0.80));
    }
    canvas.drawOval(Rect.fromCenter(center: Offset(pawX,pawY+h*0.01), width: w*0.17, height: h*0.12), fillA..color = accent.withOpacity(accentOp*0.55));
    // cross
    final cx = w*0.20; final cy = h*0.78+sway*0.2; final cr = w*0.055;
    final crossP = Paint()..color = primary.withOpacity(baseOp*0.65)..style = PaintingStyle.fill;
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx,cy), width: cr*2.2, height: cr*0.7), const Radius.circular(2)), crossP);
    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx,cy), width: cr*0.7, height: cr*2.2), const Radius.circular(2)), crossP);
  }
  @override
  bool shouldRepaint(_VetIllustrationPainter o) => o.phase != phase || o.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
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

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class VeterinarianProfileDetailScreen extends StatefulWidget {
  final String veterinarianId;
  const VeterinarianProfileDetailScreen({super.key, required this.veterinarianId});

  @override
  State<VeterinarianProfileDetailScreen> createState() => _VeterinarianProfileDetailScreenState();
}

class _VeterinarianProfileDetailScreenState extends State<VeterinarianProfileDetailScreen>
    with TickerProviderStateMixin {

  late Future<VeterinarianProfile?> _profileFuture;
  bool _isAuthorized = false;

  static const Color _primary = Color(0xFF00695C);
  static const Color _accent  = Color(0xFF80CBC4);

  late AnimationController _grainCtrl;
  late AnimationController _waveCtrl;
  late AnimationController _entryCtrl;
  List<Animation<double>>? _fade;
  List<Animation<Offset>>?  _slide;

  @override
  void initState() {
    super.initState();
    _profileFuture = ApiService.getVeterinarianProfileById(int.tryParse(widget.veterinarianId) ?? 0);

    _grainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120))..repeat();
    _waveCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

    _fade  = List.generate(6, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Interval(i * 0.09, min(i * 0.09 + 0.50, 1.0), curve: Curves.easeOut))));
    _slide = List.generate(6, (i) => Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Interval(i * 0.09, min(i * 0.09 + 0.50, 1.0), curve: Curves.easeOutCubic))));
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

  void _requestAuthorization() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AuthorizationSheet(
        veterinarianId: widget.veterinarianId,
        primary: _primary, accent: _accent,
        onSuccess: () {
          setState(() => _isAuthorized = true);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: const Text('Demande envoyée avec succès'),
            backgroundColor: _primary,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ));
        },
      ),
    );
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
              _buildHero(null, isDark, textPri, textSec),
              Expanded(child: SkeletonPageLoader(isDarkMode: isDark, includeAppBar: false, cardCount: 4)),
            ]);
          }
          if (snapshot.hasError) {
            return _buildErrorState(snapshot.error.toString(), isDark, bg, textPri, textSec);
          }
          if (!snapshot.hasData || snapshot.data == null) {
            return _buildEmptyState(isDark, bg, textPri, textSec);
          }

          final profile = snapshot.data!;
          _entryCtrl.forward(from: 0);

          return CustomScrollView(
            physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
            slivers: [
              SliverToBoxAdapter(child: _buildHero(profile, isDark, textPri, textSec)),

              // Stats
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                sliver: SliverToBoxAdapter(child: _s(0, _buildStats(profile, isDark, surface, textPri, textSec))),
              ),

              // Verification badge
              if (profile.isVerified)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                  sliver: SliverToBoxAdapter(child: _s(1, _buildVerifiedBadge(isDark, surface, textPri, textSec))),
                ),

              // Bio
              if (profile.bio.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                  sliver: SliverToBoxAdapter(child: _s(2, _buildBio(profile, isDark, surface, textPri, textSec))),
                ),

              // Coverage
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                sliver: SliverToBoxAdapter(child: _s(3, _buildCoverage(profile, isDark, surface, textPri, textSec))),
              ),

              // Contact
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
                sliver: SliverToBoxAdapter(child: _s(4, _buildContact(profile, isDark, surface, textPri, textSec))),
              ),

              // CTA
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 32, 16, 0),
                sliver: SliverToBoxAdapter(child: _s(5, _buildCTA(isDark))),
              ),

              const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
            ],
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildHero(VeterinarianProfile? profile, bool isDark, Color textPri, Color textSec) {
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
          decoration: BoxDecoration(shape: BoxShape.circle,
              gradient: RadialGradient(colors: [_accent.withOpacity(isDark ? 0.14 : 0.09), Colors.transparent])),
        )),
        Positioned(right: 10, bottom: 14, top: 14, child: SizedBox(
          width: 130,
          child: AnimatedBuilder(
            animation: _waveCtrl,
            builder: (_, __) => CustomPaint(painter: _VetIllustrationPainter(
              primary: _primary, accent: _accent, isDark: isDark, phase: _waveCtrl.value)),
          ),
        )),
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
                onTap: () {},
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(color: _primary.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
                  child: Icon(Icons.share_outlined, color: _primary, size: 17),
                ),
              ),
            ]),
            const Spacer(),
            _Tag('VÉTÉRINAIRE', bg: _primary.withOpacity(0.12), fg: _primary.withOpacity(0.80), icon: Icons.medical_services_outlined),
            const SizedBox(height: 6),
            Text(
              profile?.specialty ?? '—',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.w300, color: textPri, letterSpacing: -1.4, height: 1.1),
            ),
            if (profile?.zone != null) ...[
              const SizedBox(height: 5),
              Row(children: [
                Icon(Icons.location_on_outlined, color: _accent.withOpacity(0.70), size: 12),
                const SizedBox(width: 4),
                Text(profile!.zone, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300, color: _accent.withOpacity(0.75))),
              ]),
            ],
          ]),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS ROW — 3 chips sans bordure
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildStats(VeterinarianProfile profile, bool isDark, Color surface, Color textPri, Color textSec) {
    return Row(children: [
      _StatChip(label: 'Consultations', value: '${profile.consultationCount ?? 0}',
          icon: Icons.video_call_outlined, accent: _accent,
          surface: surface, textPri: textPri, textSec: textSec, isDark: isDark),
      const SizedBox(width: 10),
      _StatChip(label: 'Note', value: profile.rating?.toStringAsFixed(1) ?? 'N/A',
          icon: Icons.star_outline_rounded, accent: const Color(0xFFFFB300),
          surface: surface, textPri: textPri, textSec: textSec, isDark: isDark),
      const SizedBox(width: 10),
      _StatChip(label: 'Expérience', value: '${profile.experienceYears}a',
          icon: Icons.timeline_rounded, accent: _primary,
          surface: surface, textPri: textPri, textSec: textSec, isDark: isDark),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VERIFIED
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildVerifiedBadge(bool isDark, Color surface, Color textPri, Color textSec) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.20)),
      ),
      child: Row(children: [
        Icon(Icons.verified_rounded, color: Colors.green.withOpacity(0.80), size: 16),
        const SizedBox(width: 10),
        Text('Vétérinaire certifié et vérifié', style: TextStyle(
          fontSize: 12, fontWeight: FontWeight.w400,
          color: Colors.green.withOpacity(0.85),
        )),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BIO
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildBio(VeterinarianProfile profile, bool isDark, Color surface, Color textPri, Color textSec) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionLabel('À PROPOS', primary: _primary, textSec: textSec),
      const SizedBox(height: 14),
      Container(
        width: double.infinity, padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: surface,
          boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.18) : Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 3), spreadRadius: -2)],
        ),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
            margin: const EdgeInsets.only(top: 2),
            width: 2.5, height: 60,
            decoration: BoxDecoration(
              gradient: LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [_accent.withOpacity(0.9), _accent.withOpacity(0.10)]),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(child: Text(profile.bio, style: TextStyle(
            fontSize: 13, fontWeight: FontWeight.w300,
            color: textPri.withOpacity(0.80), height: 1.65, letterSpacing: 0.1,
          ))),
        ]),
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COVERAGE
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCoverage(VeterinarianProfile profile, bool isDark, Color surface, Color textPri, Color textSec) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionLabel('ZONE DE COUVERTURE', primary: _primary, textSec: textSec),
      const SizedBox(height: 14),
      _InfoTile(icon: Icons.location_on_outlined, label: 'Zone', value: profile.zone,
          accent: _accent, surface: surface, textPri: textPri, textSec: textSec, isDark: isDark),
      const SizedBox(height: 10),
      _InfoTile(icon: Icons.radar_rounded, label: "Rayon d'intervention", value: '${profile.distanceMax} km',
          accent: _accent, surface: surface, textPri: textPri, textSec: textSec, isDark: isDark),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTACT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildContact(VeterinarianProfile profile, bool isDark, Color surface, Color textPri, Color textSec) {
    final Map<String, ({IconData icon, String label, String sub})> contacts = {
      'whatsapp': (icon: Icons.chat_bubble_outline_rounded, label: 'WhatsApp', sub: 'Messages et appels via WhatsApp'),
      'call':     (icon: Icons.phone_outlined,              label: 'Appel téléphonique', sub: 'Contact direct par téléphone'),
      'email':    (icon: Icons.mail_outline_rounded,        label: 'Email', sub: 'Échanges par messagerie'),
    };
    final ct = contacts[profile.contactPreference] ??
        (icon: Icons.contact_phone_outlined, label: profile.contactPreference.toUpperCase(), sub: '');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _SectionLabel('CONTACT', primary: _primary, textSec: textSec),
      const SizedBox(height: 14),
      Container(
        decoration: BoxDecoration(
          color: surface,
          boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.18) : Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 3), spreadRadius: -2)],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: () { HapticFeedback.lightImpact(); },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: _accent.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
                  child: Icon(ct.icon, color: _accent, size: 18),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(ct.label, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: textPri)),
                  Text(ct.sub,   style: TextStyle(fontSize: 10, fontWeight: FontWeight.w300, color: textSec.withOpacity(0.55))),
                ])),
                Icon(Icons.chevron_right_rounded, color: _primary.withOpacity(0.30), size: 18),
              ]),
            ),
          ),
        ),
      ),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CTA
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildCTA(bool isDark) {
    if (_isAuthorized) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.green.withOpacity(0.20)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_outline_rounded, color: Colors.green.withOpacity(0.80), size: 18),
          const SizedBox(width: 10),
          Text('Accès autorisé', style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500,
            color: Colors.green.withOpacity(0.85), letterSpacing: 0.2,
          )),
        ]),
      );
    }

    return GestureDetector(
      onTap: _requestAuthorization,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: _primary,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: _primary.withOpacity(0.28), blurRadius: 20, offset: const Offset(0, 8))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.lock_open_rounded, color: Colors.white, size: 15),
          const SizedBox(width: 9),
          const Text("Demander l'accès", style: TextStyle(
            fontSize: 14, fontWeight: FontWeight.w500, color: Colors.white, letterSpacing: 0.3,
          )),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ERROR / EMPTY
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildErrorState(String err, bool isDark, Color bg, Color textPri, Color textSec) {
    return Scaffold(backgroundColor: bg, body: Center(child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(color: Colors.red.withOpacity(0.08), shape: BoxShape.circle),
          child: Icon(Icons.error_outline_rounded, color: Colors.red.withOpacity(0.60), size: 36)),
        const SizedBox(height: 20),
        Text('Erreur de chargement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: textPri, letterSpacing: -0.3)),
        const SizedBox(height: 8),
        Text(err, style: TextStyle(fontSize: 11, color: textSec.withOpacity(0.55), fontWeight: FontWeight.w300), textAlign: TextAlign.center),
        const SizedBox(height: 28),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: _primary.withOpacity(0.06), borderRadius: BorderRadius.circular(10)),
              child: Text('Retour', style: TextStyle(fontSize: 13, color: _primary, fontWeight: FontWeight.w400)),
            ),
          ),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => setState(() => _profileFuture = ApiService.getVeterinarianProfileById(int.tryParse(widget.veterinarianId) ?? 0)),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(color: _primary, borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: _primary.withOpacity(0.25), blurRadius: 12, offset: const Offset(0, 4))]),
              child: const Text('Réessayer', style: TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.w500)),
            ),
          ),
        ]),
      ]),
    )));
  }

  Widget _buildEmptyState(bool isDark, Color bg, Color textPri, Color textSec) {
    return Scaffold(backgroundColor: bg, body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(color: _primary.withOpacity(0.07), shape: BoxShape.circle),
          child: Icon(Icons.person_off_outlined, color: _primary.withOpacity(0.35), size: 36)),
      const SizedBox(height: 18),
      Text('Profil introuvable', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: textPri.withOpacity(0.70))),
    ])));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _StatChip extends StatelessWidget {
  final String label, value;
  final IconData icon;
  final Color accent, surface, textPri, textSec;
  final bool isDark;
  const _StatChip({required this.label, required this.value, required this.icon,
      required this.accent, required this.surface, required this.textPri, required this.textSec, required this.isDark});
  @override
  Widget build(BuildContext context) => Expanded(child: Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    decoration: BoxDecoration(
      color: surface,
      boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.18) : Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 3), spreadRadius: -2)],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: accent.withOpacity(0.10), borderRadius: BorderRadius.circular(6)),
          child: Icon(icon, color: accent, size: 12)),
      const SizedBox(height: 8),
      Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: textPri, letterSpacing: -1.2, height: 1.0)),
      const SizedBox(height: 3),
      Text(label, style: TextStyle(fontSize: 8, fontWeight: FontWeight.w300, color: textSec.withOpacity(0.55), letterSpacing: 0.3)),
    ]),
  ));
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO TILE
// ─────────────────────────────────────────────────────────────────────────────
class _InfoTile extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color accent, surface, textPri, textSec;
  final bool isDark;
  const _InfoTile({required this.icon, required this.label, required this.value,
      required this.accent, required this.surface, required this.textPri, required this.textSec, required this.isDark});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: surface,
      boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.18) : Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 3), spreadRadius: -2)],
    ),
    child: Row(children: [
      Container(padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(color: accent.withOpacity(0.10), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: accent, size: 15)),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label.toUpperCase(), style: TextStyle(fontSize: 7, fontWeight: FontWeight.w500, letterSpacing: 1.8, color: textSec.withOpacity(0.50))),
        const SizedBox(height: 3),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: textPri)),
      ]),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTHORIZATION BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────
class _AuthorizationSheet extends StatefulWidget {
  final String veterinarianId;
  final VoidCallback onSuccess;
  final Color primary;
  final Color accent;
  const _AuthorizationSheet({required this.veterinarianId, required this.onSuccess, required this.primary, required this.accent});

  @override
  State<_AuthorizationSheet> createState() => _AuthorizationSheetState();
}

class _AuthorizationSheetState extends State<_AuthorizationSheet> with SingleTickerProviderStateMixin {
  final _reasonController = TextEditingController();
  bool _isLoading = false;
  bool _loadingData = true;
  List<dynamic> _farms = [];
  List<dynamic> _livestocks = [];
  dynamic _selectedFarm;
  dynamic _selectedLivestock;
  dynamic _selectedCrop;
  dynamic _selectedAnimal;
  final Set<int> _selectedCrops = {};
  final Set<int> _selectedAnimals = {};
  int _tab = 0;

  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _tabCtrl.addListener(() { if (!_tabCtrl.indexIsChanging) setState(() { _tab = _tabCtrl.index; _clearSelections(); }); });
    _loadData();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _clearSelections() {
    _selectedFarm = null; _selectedLivestock = null;
    _selectedCrop = null; _selectedAnimal = null;
    _selectedCrops.clear(); _selectedAnimals.clear();
  }

  Future<void> _loadData() async {
    try {
      final farms = await ApiService.getUserFarms();
      final userId = await TokenStorage.getUserId();
      final ls = userId != null ? await ApiService.getUserLivestock(userId) : [];
      if (mounted) setState(() { _farms = farms; _livestocks = ls; _loadingData = false; });
    } catch (e) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  String _diagnosisSummary() {
    if (_tab == 0 && _selectedCrops.isNotEmpty) return '${_selectedCrops.length} culture(s)';
    if (_tab == 1 && _selectedAnimals.isNotEmpty) return '${_selectedAnimals.length} animal(aux)';
    return 'Aucune sélection';
  }

  bool get _canSubmit {
    if (_loadingData || _isLoading) return false;
    if (_tab == 0) return _selectedFarm != null && _selectedCrops.isNotEmpty;
    return _selectedLivestock != null && _selectedAnimals.isNotEmpty;
  }

  Future<void> _submit() async {
    if (_reasonController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Décrivez le problème'), backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final reason = '${_reasonController.text.trim()}\n\n[À diagnostiquer: ${_diagnosisSummary()}]';
      await ApiService.createAuthorization(
        farmId: _tab == 0 ? (_selectedFarm['id'] as int) : 0,
        veterinarianId: int.tryParse(widget.veterinarianId) ?? 0,
        authorizationReason: reason,
        selectedLivestockIds: _tab == 1 ? (_selectedLivestock['id'].toString()) : null,
        selectedCropIds: _tab == 0 ? _selectedCrops.join(',') : null,
      );
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating,
      ));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final isDark  = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF0D1A18) : Colors.white;
    final textPri = isDark ? const Color(0xFFE0F2F1) : const Color(0xFF0D2420);
    final textSec = isDark ? const Color(0xFF80CBC4) : const Color(0xFF4A7A73);
    final bg      = isDark ? const Color(0xFF060E0D) : const Color(0xFFF4FAF9);

    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(children: [
          // Handle
          Padding(
            padding: const EdgeInsets.only(top: 18),
            child: Center(child: Container(
              width: 32, height: 3,
              decoration: BoxDecoration(color: widget.primary.withOpacity(0.20), borderRadius: BorderRadius.circular(2)),
            )),
          ),
          const SizedBox(height: 20),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(color: widget.accent.withOpacity(0.10), borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.lock_open_rounded, color: widget.accent, size: 16),
              ),
              const SizedBox(width: 12),
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('DEMANDE D\'ACCÈS', style: TextStyle(
                  fontSize: 7, fontWeight: FontWeight.w600, letterSpacing: 2.2, color: widget.primary.withOpacity(0.50),
                )),
                Text('Accès vétérinaire', style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w500, color: textPri, letterSpacing: -0.5,
                )),
              ]),
            ]),
          ),
          const SizedBox(height: 20),

          // Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: widget.primary.withOpacity(isDark ? 0.08 : 0.05),
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabCtrl,
                indicator: BoxDecoration(
                  color: widget.primary,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: [BoxShadow(color: widget.primary.withOpacity(0.22), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                labelColor: Colors.white,
                unselectedLabelColor: widget.primary.withOpacity(0.50),
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
                dividerColor: Colors.transparent,
                tabs: const [
                  Tab(text: '🌾  Cultures'),
                  Tab(text: '🐄  Animaux'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Scrollable body
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
              physics: const BouncingScrollPhysics(),
              child: _loadingData
                  ? SizedBox(height: 120, child: Center(child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(widget.accent))))
                  : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      if (_tab == 0) _culturesTab(isDark, surface, textPri, textSec, bg)
                      else _animalsTab(isDark, surface, textPri, textSec),

                      const SizedBox(height: 20),

                      // Summary chip
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: widget.primary.withOpacity(isDark ? 0.08 : 0.05),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: widget.primary.withOpacity(0.15)),
                        ),
                        child: Row(children: [
                          Icon(Icons.assignment_outlined, color: widget.accent, size: 15),
                          const SizedBox(width: 10),
                          Expanded(child: Text('Diagnostic : ${_diagnosisSummary()}', style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w400, color: widget.primary,
                          ))),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      // Reason
                      Text('RAISON DE LA DEMANDE', style: TextStyle(
                        fontSize: 7, fontWeight: FontWeight.w500, letterSpacing: 2.5, color: textSec.withOpacity(0.50),
                      )),
                      const SizedBox(height: 10),
                      Container(
                        decoration: BoxDecoration(
                          color: widget.primary.withOpacity(isDark ? 0.05 : 0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: widget.primary.withOpacity(0.14)),
                        ),
                        child: TextField(
                          controller: _reasonController,
                          maxLines: 5,
                          style: TextStyle(fontSize: 13, color: textPri, fontWeight: FontWeight.w300),
                          decoration: InputDecoration(
                            hintText: 'Décrivez les symptômes ou problèmes observés…',
                            hintStyle: TextStyle(color: widget.primary.withOpacity(0.30), fontSize: 12, fontWeight: FontWeight.w300),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.all(16),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ]),
            ),
          ),

          // Footer buttons
          Container(
            padding: EdgeInsets.fromLTRB(24, 16, 24, MediaQuery.of(context).padding.bottom + 16),
            decoration: BoxDecoration(
              color: surface,
              boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.22) : widget.primary.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, -4))],
            ),
            child: Row(children: [
              GestureDetector(
                onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  decoration: BoxDecoration(
                    color: widget.primary.withOpacity(0.06), borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text('Annuler', style: TextStyle(fontSize: 13, color: widget.primary, fontWeight: FontWeight.w400)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(child: GestureDetector(
                onTap: _canSubmit ? _submit : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: _canSubmit ? widget.primary : widget.primary.withOpacity(0.25),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: _canSubmit ? [BoxShadow(color: widget.primary.withOpacity(0.26), blurRadius: 14, offset: const Offset(0, 5))] : null,
                  ),
                  child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                    if (_isLoading)
                      const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(Colors.white)))
                    else ...[
                      const Icon(Icons.send_rounded, color: Colors.white, size: 14),
                      const SizedBox(width: 8),
                      const Text('Envoyer la demande', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white)),
                    ],
                  ]),
                ),
              )),
            ]),
          ),
        ]),
      ),
    );
  }

  // ─── CULTURES TAB ───────────────────────────────────────────────────────────
  Widget _culturesTab(bool isDark, Color surface, Color textPri, Color textSec, Color bg) {
    if (_farms.isEmpty) {
      return _emptyTabState("Vous n'avez pas de fermes enregistrées.", textSec);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('FERME', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w500, letterSpacing: 2.5, color: textSec.withOpacity(0.50))),
      const SizedBox(height: 10),
      _StyledDropdown(
        value: _selectedFarm,
        hint: 'Sélectionner une ferme',
        icon: Icons.agriculture_rounded,
        items: _farms.map((f) => DropdownMenuItem(value: f, child: Text(f['name'] ?? 'Ferme sans nom',
            style: TextStyle(fontSize: 13, color: textPri, fontWeight: FontWeight.w400)))).toList(),
        onChanged: (v) => setState(() { _selectedFarm = v; _selectedCrops.clear(); _selectedCrop = null; }),
        primary: widget.primary, surface: surface, textPri: textPri, isDark: isDark,
      ),

      if (_selectedFarm != null && (_selectedFarm['crops']?.isNotEmpty ?? false)) ...[
        const SizedBox(height: 20),
        Text('CULTURES À EXAMINER', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w500, letterSpacing: 2.5, color: textSec.withOpacity(0.50))),
        const SizedBox(height: 10),
        _StyledDropdown(
          value: _selectedCrop,
          hint: '+ Ajouter une culture',
          icon: Icons.grass_rounded,
          items: (_selectedFarm['crops'] as List)
              .where((c) => !_selectedCrops.contains(c['id']))
              .map((c) => DropdownMenuItem(value: c, child: Text(c['crop_name'] ?? 'Culture',
                  style: TextStyle(fontSize: 13, color: textPri, fontWeight: FontWeight.w400)))).toList(),
          onChanged: (c) { if (c != null) setState(() { _selectedCrops.add(c['id'] as int); _selectedCrop = null; }); },
          primary: widget.primary, surface: surface, textPri: textPri, isDark: isDark,
        ),
        if (_selectedCrops.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8,
            children: _selectedCrops.map((id) {
              final c = (_selectedFarm['crops'] as List).firstWhere((x) => x['id'] == id, orElse: () => null);
              if (c == null) return const SizedBox.shrink();
              return _CropChip(
                label: c['crop_name'] ?? 'Culture',
                primary: widget.primary, accent: widget.accent,
                onRemove: () => setState(() => _selectedCrops.remove(id)),
              );
            }).toList(),
          ),
        ],
      ],
    ]);
  }

  // ─── ANIMALS TAB ────────────────────────────────────────────────────────────
  Widget _animalsTab(bool isDark, Color surface, Color textPri, Color textSec) {
    if (_livestocks.isEmpty) {
      return _emptyTabState("Vous n'avez pas de bétail enregistré.", textSec);
    }
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('BÉTAIL', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w500, letterSpacing: 2.5, color: textSec.withOpacity(0.50))),
      const SizedBox(height: 10),
      _StyledDropdown(
        value: _selectedLivestock,
        hint: 'Sélectionner un bétail',
        icon: Icons.pets_rounded,
        items: _livestocks.map((l) => DropdownMenuItem(value: l, child: Text(
          '${l['animal_type']} — ${l['breed'] ?? 'Race'} (×${l['quantity'] ?? 1})',
          style: TextStyle(fontSize: 13, color: textPri, fontWeight: FontWeight.w400),
          overflow: TextOverflow.ellipsis,
        ))).toList(),
        onChanged: (v) => setState(() { _selectedLivestock = v; _selectedAnimals.clear(); }),
        primary: widget.primary, surface: surface, textPri: textPri, isDark: isDark,
      ),

      if (_selectedLivestock != null) ...[
        const SizedBox(height: 20),
        Text('NOMBRE D\'ANIMAUX', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w500, letterSpacing: 2.5, color: textSec.withOpacity(0.50))),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: widget.primary.withOpacity(isDark ? 0.05 : 0.03),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.primary.withOpacity(0.14)),
          ),
          child: Row(children: [
            Icon(Icons.pets_rounded, color: widget.accent, size: 16),
            const SizedBox(width: 12),
            Expanded(child: TextField(
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 14, color: textPri, fontWeight: FontWeight.w400),
              decoration: InputDecoration(
                hintText: 'Nombre d\'animaux à examiner',
                hintStyle: TextStyle(color: widget.primary.withOpacity(0.30), fontSize: 12),
                border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) {
                final q = int.tryParse(v) ?? 0;
                final max = _selectedLivestock['quantity'] as int? ?? 1;
                setState(() {
                  _selectedAnimals.clear();
                  for (int i = 0; i < q.clamp(0, max); i++) _selectedAnimals.add(i);
                });
              },
            )),
            Text('sur ${_selectedLivestock['quantity'] ?? 1}', style: TextStyle(
              fontSize: 11, color: textSec.withOpacity(0.55), fontWeight: FontWeight.w300,
            )),
          ]),
        ),
        if (_selectedAnimals.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.green.withOpacity(0.80), size: 13),
              const SizedBox(width: 8),
              Text('${_selectedAnimals.length} animal(aux) sélectionné(s)', style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w400, color: Colors.green.withOpacity(0.85),
              )),
            ]),
          ),
        ],
      ],
    ]);
  }

  Widget _emptyTabState(String msg, Color textSec) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 24),
    child: Row(children: [
      Icon(Icons.info_outline_rounded, color: textSec.withOpacity(0.40), size: 15),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: TextStyle(fontSize: 12, color: textSec.withOpacity(0.55), fontWeight: FontWeight.w300))),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STYLED DROPDOWN
// ─────────────────────────────────────────────────────────────────────────────
class _StyledDropdown extends StatelessWidget {
  final dynamic value;
  final String hint;
  final IconData icon;
  final List<DropdownMenuItem<dynamic>> items;
  final ValueChanged<dynamic> onChanged;
  final Color primary, surface, textPri;
  final bool isDark;

  const _StyledDropdown({required this.value, required this.hint, required this.icon,
      required this.items, required this.onChanged, required this.primary,
      required this.surface, required this.textPri, required this.isDark});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      color: primary.withOpacity(isDark ? 0.05 : 0.03),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: primary.withOpacity(0.14)),
    ),
    child: Row(children: [
      Icon(icon, color: primary.withOpacity(0.40), size: 16),
      const SizedBox(width: 10),
      Expanded(child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: value,
          isExpanded: true,
          dropdownColor: isDark ? const Color(0xFF0D1A18) : Colors.white,
          style: TextStyle(fontSize: 13, color: textPri, fontWeight: FontWeight.w400),
          hint: Text(hint, style: TextStyle(fontSize: 12, color: primary.withOpacity(0.35), fontWeight: FontWeight.w300)),
          icon: Icon(Icons.keyboard_arrow_down_rounded, color: primary.withOpacity(0.40), size: 18),
          items: items, onChanged: onChanged,
        ),
      )),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CROP CHIP
// ─────────────────────────────────────────────────────────────────────────────
class _CropChip extends StatelessWidget {
  final String label;
  final Color primary, accent;
  final VoidCallback onRemove;
  const _CropChip({required this.label, required this.primary, required this.accent, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
    decoration: BoxDecoration(
      color: accent.withOpacity(0.10),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: accent.withOpacity(0.25)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.grass_rounded, size: 12, color: accent),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: primary)),
      const SizedBox(width: 6),
      GestureDetector(
        onTap: onRemove,
        child: Icon(Icons.close_rounded, size: 13, color: primary.withOpacity(0.50)),
      ),
    ]),
  );
}