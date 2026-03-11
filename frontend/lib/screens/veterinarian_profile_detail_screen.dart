import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/models/veterinarian_model.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/token_storage.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/widgets/skeleton_loader.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS — Organic Luxury palette
// ═══════════════════════════════════════════════════════════════════════════

const _cForest  = Color(0xFF1B3A1D);   // deep forest
const _cGreen   = Color(0xFF2E7D32);   // primary green
const _cSage    = Color(0xFF66BB6A);   // accent sage
const _cAmber   = Color(0xFFD4A029);   // warm gold
const _cClay    = Color(0xFFE05C5C);   // terracotta
const _cSky     = Color(0xFF4A7FC1);   // sky blue

const _cBg      = Color(0xFFF4F7F4);   // linen white-green
const _cSurf    = Color(0xFFFFFFFF);   // pure white
const _cSurf2   = Color(0xFFEFF4EF);   // tinted surface
const _cBorder  = Color(0x12000000);   // hairline
const _cBorder2 = Color(0x22000000);   // stronger hairline

const _cInk1    = Color(0xFF1A2B1B);   // near-black
const _cInk2    = Color(0xFF4E6850);   // mid text
const _cInk3    = Color(0xFF8AA08B);   // dim text

// ═══════════════════════════════════════════════════════════════════════════
// PAINTERS — grain + double wave
// ═══════════════════════════════════════════════════════════════════════════

class _GrainPainter extends CustomPainter {
  final double t;
  final Color color;
  _GrainPainter(this.t, this.color);
  @override
  void paint(Canvas canvas, Size size) {
    final rng   = Random((t * 1000).toInt());
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 260; i++) {
      paint.color = color.withOpacity(rng.nextDouble() * 0.028 + 0.003);
      canvas.drawCircle(
        Offset(rng.nextDouble() * size.width, rng.nextDouble() * size.height),
        rng.nextDouble() * 0.85 + 0.18,
        paint,
      );
    }
  }
  @override bool shouldRepaint(_GrainPainter o) => o.t != t;
}

class _WavePainter extends CustomPainter {
  final double phase;
  final Color color;
  final double yRatio;
  final double amplitude;
  _WavePainter({required this.phase, required this.color, this.yRatio = 0.55, this.amplitude = 14});
  @override
  void paint(Canvas canvas, Size size) {
    final p    = Paint()..color = color..style = PaintingStyle.fill;
    final path = Path();
    final baseY = size.height * yRatio;
    path.moveTo(0, size.height);
    path.lineTo(0, baseY + amplitude * sin(phase));
    for (double x = 0; x <= size.width; x += 1.5) {
      path.lineTo(x,
          baseY
        + amplitude       * sin(x / size.width * 2 * pi + phase)
        + amplitude * 0.5 * sin(x / size.width * 4 * pi - phase * 1.3)
        + amplitude * 0.3 * cos(x / size.width * 6 * pi + phase * 0.7));
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, p);
  }
  @override bool shouldRepaint(_WavePainter o) => o.phase != phase;
}

// ═══════════════════════════════════════════════════════════════════════════
// SPECIALTY → COLOUR MAP
// ═══════════════════════════════════════════════════════════════════════════

Color _specColor(String spec) {
  final map = {
    'bovin':    const Color(0xFF3E6B3F),
    'ovin':     const Color(0xFF5E5024),
    'caprin':   const Color(0xFF3B5E6A),
    'avicole':  const Color(0xFF7A4A1E),
    'équin':    const Color(0xFF4A3A6A),
    'porcin':   const Color(0xFF7A3A3A),
    'généraliste': const Color(0xFF2E5E30),
  };
  for (final entry in map.entries) {
    if (spec.toLowerCase().contains(entry.key)) return entry.value;
  }
  return _cGreen;
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class VeterinarianProfileDetailScreen extends StatefulWidget {
  final String veterinarianId;
  const VeterinarianProfileDetailScreen({super.key, required this.veterinarianId});

  @override
  State<VeterinarianProfileDetailScreen> createState() =>
      _VeterinarianProfileDetailScreenState();
}

class _VeterinarianProfileDetailScreenState
    extends State<VeterinarianProfileDetailScreen>
    with TickerProviderStateMixin {

  late Future<VeterinarianProfile?> _profileFuture;
  bool _isAuthorized = false;
  final _scroll = ScrollController();

  // Controllers
  late AnimationController _waveCtrl;
  late AnimationController _grainCtrl;
  late AnimationController _entryCtrl;

  // Staggered entry animations (6 layers)
  late List<Animation<double>>  _fades;
  late List<Animation<Offset>>  _slides;

  @override
  void initState() {
    super.initState();

    _waveCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);
    _grainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 110))
      ..repeat();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));

    _fades  = List.generate(6, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl,
        curve: Interval(i * 0.09, min(i * 0.09 + 0.55, 1.0), curve: Curves.easeOut)),
    ));
    _slides = List.generate(6, (i) =>
      Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero).animate(
        CurvedAnimation(parent: _entryCtrl,
          curve: Interval(i * 0.09, min(i * 0.09 + 0.55, 1.0), curve: Curves.easeOutCubic)),
      ));

    _profileFuture = ApiService.getVeterinarianProfileById(
        int.tryParse(widget.veterinarianId) ?? 0);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _scroll.dispose();
    _waveCtrl.dispose();
    _grainCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _anim(int i, Widget child) => FadeTransition(
    opacity: _fades[i],
    child: SlideTransition(position: _slides[i], child: child),
  );

  void _requestAuthorization() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _AuthorizationSheet(
        veterinarianId: widget.veterinarianId,
        onSuccess: () {
          setState(() => _isAuthorized = true);
          _toast('Demande envoyée avec succès ✓', color: _cSage);
        },
      ),
    );
  }

  void _contactVeterinarian(VeterinarianProfile profile) {
    HapticFeedback.lightImpact();
    _toast('Contact via ${_contactLabel(profile.contactPreference)}', color: _cSky);
  }

  void _toast(String msg, {Color color = _cSage}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500, fontSize: 13.5)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));

  String _contactLabel(String m) => switch (m) {
    'whatsapp' => 'WhatsApp',
    'call'     => 'Appel',
    'email'    => 'Email',
    _          => m,
  };

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cBg,
      body: FutureBuilder<VeterinarianProfile?>(
        future: _profileFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return SkeletonPageLoader(isDarkMode: false, includeAppBar: true, cardCount: 5);
          }
          if (snap.hasError) {
            return _ErrorPage(error: snap.error.toString(), onRetry: () => setState(() {
              _entryCtrl.forward(from: 0);
              _profileFuture = ApiService.getVeterinarianProfileById(
                  int.tryParse(widget.veterinarianId) ?? 0);
            }));
          }
          if (!snap.hasData || snap.data == null) return const _EmptyPage();

          final p = snap.data!;
          final hue = _specColor(p.specialty);

          return CustomScrollView(
            controller: _scroll,
            physics: const BouncingScrollPhysics(),
            slivers: [

              // ── Immersive hero ─────────────────────────────────────────
              SliverAppBar(
                expandedHeight: 320,
                pinned: true,
                stretch: true,
                elevation: 0,
                backgroundColor: hue,
                surfaceTintColor: Colors.transparent,
                leading: Padding(
                  padding: const EdgeInsets.all(8),
                  child: _GlassBtn(icon: Icons.arrow_back_rounded, onTap: () => Navigator.pop(context)),
                ),
                actions: [
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: _GlassBtn(icon: Icons.ios_share_rounded, onTap: () {}),
                  ),
                ],
                flexibleSpace: FlexibleSpaceBar(
                  stretchModes: const [StretchMode.zoomBackground],
                  background: _HeroBanner(
                    profile: p, hue: hue,
                    waveCtrl: _waveCtrl, grainCtrl: _grainCtrl,
                  ),
                ),
              ),

              // ── Floating stat ribbon ───────────────────────────────────
              SliverToBoxAdapter(
                child: _anim(0, Transform.translate(
                  offset: const Offset(0, -20),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: _StatRibbon(profile: p),
                  ),
                )),
              ),

              // ── Body ───────────────────────────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      // Bio
                      if (p.bio.isNotEmpty) ...[
                        _anim(1, _ContentCard(
                          label: 'À propos',
                          icon: Icons.format_quote_rounded,
                          iconColor: hue,
                          child: Text(p.bio, style: const TextStyle(
                            fontSize: 14.5, height: 1.70,
                            color: _cInk2, fontWeight: FontWeight.w300,
                          )),
                        )),
                        const SizedBox(height: 16),
                      ],

                      // Zone
                      _anim(2, _ContentCard(
                        label: 'Zone d\'intervention',
                        icon: Icons.map_outlined,
                        iconColor: _cSky,
                        child: _ZoneRows(profile: p),
                      )),
                      const SizedBox(height: 16),

                      // Contact
                      _anim(3, _ContentCard(
                        label: 'Contact préféré',
                        icon: Icons.contact_phone_outlined,
                        iconColor: _cAmber,
                        child: _ContactRow(
                          profile: p,
                          onTap: () => _contactVeterinarian(p),
                        ),
                      )),
                      const SizedBox(height: 32),

                      // CTA
                      _anim(4, _CTASection(
                        isAuthorized: _isAuthorized,
                        hue: hue,
                        onTap: _requestAuthorization,
                      )),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// HERO BANNER
// ═══════════════════════════════════════════════════════════════════════════

class _HeroBanner extends StatelessWidget {
  final VeterinarianProfile profile;
  final Color hue;
  final AnimationController waveCtrl;
  final AnimationController grainCtrl;

  const _HeroBanner({
    required this.profile, required this.hue,
    required this.waveCtrl, required this.grainCtrl,
  });

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final topPad = MediaQuery.of(context).padding.top;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: [
            Color.lerp(hue, Colors.black, 0.18)!,
            Color.lerp(hue, const Color(0xFF0A1A0A), 0.35)!,
          ],
        ),
      ),
      child: Stack(fit: StackFit.expand, children: [

        // ── Grain texture ─────────────────────────────────────────────
        Positioned.fill(
          child: AnimatedBuilder(
            animation: grainCtrl,
            builder: (_, __) => CustomPaint(
              painter: _GrainPainter(grainCtrl.value, Colors.white),
            ),
          ),
        ),

        // ── Radial glow ───────────────────────────────────────────────
        Positioned(top: -100, right: -100,
          child: Container(width: 320, height: 320,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                Colors.white.withOpacity(0.10), Colors.transparent,
              ]),
            ),
          ),
        ),

        // ── Second glow bottom-left ───────────────────────────────────
        Positioned(bottom: -60, left: -60,
          child: Container(width: 220, height: 220,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _cSage.withOpacity(0.12), Colors.transparent,
              ]),
            ),
          ),
        ),

        // ── Dual waves ────────────────────────────────────────────────
        Positioned(bottom: 0, left: 0, right: 0,
          child: AnimatedBuilder(
            animation: waveCtrl,
            builder: (_, __) {
              final phi = waveCtrl.value * 2 * pi;
              return SizedBox(height: 90,
                child: Stack(children: [
                  CustomPaint(
                    size: Size(w, 90),
                    painter: _WavePainter(
                      phase: phi, amplitude: 16,
                      color: _cBg.withOpacity(0.22), yRatio: 0.50,
                    ),
                  ),
                  CustomPaint(
                    size: Size(w, 90),
                    painter: _WavePainter(
                      phase: phi + 2.1, amplitude: 12,
                      color: _cBg.withOpacity(0.12), yRatio: 0.58,
                    ),
                  ),
                  CustomPaint(
                    size: Size(w, 90),
                    painter: _WavePainter(
                      phase: phi + 0.9, amplitude: 8,
                      color: _cBg.withOpacity(0.40), yRatio: 0.70,
                    ),
                  ),
                ]),
              );
            },
          ),
        ),

        // ── Content ───────────────────────────────────────────────────
        Padding(
          padding: EdgeInsets.fromLTRB(24, topPad + 64, 24, 52),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.end,
            children: [

              // Avatar ring
              Container(
                width: 68, height: 68,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.14),
                  border: Border.all(color: Colors.white.withOpacity(0.30), width: 1.5),
                ),
                child: Center(
                  child: Text(
                    profile.specialty.isNotEmpty
                        ? profile.specialty[0].toUpperCase() : 'V',
                    style: const TextStyle(
                      fontSize: 28, fontWeight: FontWeight.w200,
                      color: Colors.white, letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),

              // Specialty name — ultra-thin display
              Text(
                profile.specialty,
                style: const TextStyle(
                  fontSize: 34, fontWeight: FontWeight.w200,
                  color: Colors.white, letterSpacing: -1.5, height: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Vétérinaire',
                style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w300,
                  color: Colors.white.withOpacity(0.55), letterSpacing: 2.0,
                ),
              ),
              const SizedBox(height: 14),

              // Pills row
              Wrap(spacing: 8, runSpacing: 8, children: [
                if (profile.isVerified) _HeroPill(
                  icon: Icons.verified_rounded, label: 'Vérifié',
                  color: _cSage,
                ),
                _HeroPill(
                  icon: Icons.location_on_rounded, label: profile.zone,
                  color: Colors.white, bgOpacity: 0.14,
                ),
                if (profile.experienceYears > 0) _HeroPill(
                  icon: Icons.workspace_premium_rounded,
                  label: '${profile.experienceYears} ans',
                  color: _cAmber,
                ),
              ]),
            ],
          ),
        ),
      ]),
    );
  }
}

class _HeroPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final double bgOpacity;

  const _HeroPill({
    required this.icon, required this.label, required this.color,
    this.bgOpacity = 0.0,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
    decoration: BoxDecoration(
      color: bgOpacity > 0
          ? Colors.white.withOpacity(bgOpacity)
          : color.withOpacity(0.17),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: color.withOpacity(0.35), width: 1),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 11, color: color),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(
        fontSize: 11.5, color: color,
        fontWeight: FontWeight.w500, letterSpacing: 0.2,
      )),
    ]),
  );
}

class _GlassBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  const _GlassBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 38, height: 38,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.white.withOpacity(0.16),
        border: Border.all(color: Colors.white.withOpacity(0.28), width: 1),
      ),
      child: Icon(icon, color: Colors.white, size: 18),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// STAT RIBBON — floating card with shadow
// ═══════════════════════════════════════════════════════════════════════════

class _StatRibbon extends StatelessWidget {
  final VeterinarianProfile profile;
  const _StatRibbon({required this.profile});

  @override
  Widget build(BuildContext context) {
    final rating = profile.rating?.toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      decoration: BoxDecoration(
        color: _cSurf,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _cBorder),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.07), blurRadius: 24, offset: const Offset(0, 8), spreadRadius: -4),
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6,  offset: const Offset(0, 2)),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(children: [
          _RibbonStat(
            value: '${profile.consultationCount ?? 0}',
            label: 'Consultations',
            icon: Icons.medical_services_rounded,
            color: _cSky,
          ),
          _RibbonDivider(),
          _RibbonStat(
            value: rating != null ? '$rating ★' : '—',
            label: 'Évaluation',
            icon: Icons.star_rounded,
            color: _cAmber,
          ),
          _RibbonDivider(),
          _RibbonStat(
            value: '${profile.experienceYears}',
            label: 'Ans d\'exp.',
            icon: Icons.workspace_premium_rounded,
            color: _cGreen,
          ),
        ]),
      ),
    );
  }
}

class _RibbonStat extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  const _RibbonStat({required this.value, required this.label, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        width: 32, height: 32,
        decoration: BoxDecoration(
          color: color.withOpacity(0.10),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: color, size: 15),
      ),
      const SizedBox(height: 7),
      Text(value, style: const TextStyle(
        fontSize: 16, fontWeight: FontWeight.w700,
        color: _cInk1, letterSpacing: -0.5,
      )),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(
        fontSize: 9.5, color: _cInk3,
        fontWeight: FontWeight.w400, letterSpacing: 0.4,
      )),
    ]),
  );
}

class _RibbonDivider extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
    width: 1, margin: const EdgeInsets.symmetric(vertical: 6),
    decoration: const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topCenter, end: Alignment.bottomCenter,
        colors: [Colors.transparent, _cBorder2, Colors.transparent],
      ),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTENT CARD — reusable section wrapper
// ═══════════════════════════════════════════════════════════════════════════

class _ContentCard extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconColor;
  final Widget child;

  const _ContentCard({
    required this.label, required this.icon,
    required this.iconColor, required this.child,
  });

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: _cSurf,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: _cBorder),
      boxShadow: [
        BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 4), spreadRadius: -2),
      ],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
        child: Row(children: [
          Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.10),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(width: 10),
          Text(label.toUpperCase(), style: const TextStyle(
            fontSize: 9, fontWeight: FontWeight.w600,
            letterSpacing: 2.2, color: _cInk3,
          )),
        ]),
      ),
      // Hairline
      Padding(
        padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
        child: Container(height: 1, color: _cBorder),
      ),
      // Content
      Padding(
        padding: const EdgeInsets.all(18),
        child: child,
      ),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ZONE ROWS
// ═══════════════════════════════════════════════════════════════════════════

class _ZoneRows extends StatelessWidget {
  final VeterinarianProfile profile;
  const _ZoneRows({required this.profile});

  @override
  Widget build(BuildContext context) => Column(children: [
    _ZoneItem(icon: Icons.location_on_rounded, label: profile.zone, color: _cSky),
    const SizedBox(height: 14),
    _ZoneItem(
      icon: Icons.radar_rounded,
      label: 'Rayon d\'intervention : ${profile.distanceMax} km',
      color: _cGreen,
    ),
  ]);
}

class _ZoneItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ZoneItem({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(
      width: 36, height: 36,
      decoration: BoxDecoration(
        color: color.withOpacity(0.09),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 16),
    ),
    const SizedBox(width: 13),
    Expanded(child: Text(label, style: const TextStyle(
      fontSize: 14, color: _cInk2,
      fontWeight: FontWeight.w300, height: 1.45,
    ))),
  ]);
}

// ═══════════════════════════════════════════════════════════════════════════
// CONTACT ROW
// ═══════════════════════════════════════════════════════════════════════════

class _ContactRow extends StatelessWidget {
  final VeterinarianProfile profile;
  final VoidCallback onTap;
  const _ContactRow({required this.profile, required this.onTap});

  IconData _icon(String m) {
    switch (m) {
      case 'whatsapp': return Icons.chat_bubble_rounded;
      case 'call':     return Icons.phone_rounded;
      case 'email':    return Icons.mail_rounded;
      default:         return Icons.message_rounded;
    }
  }

  Color _color(String m) {
    switch (m) {
      case 'whatsapp': return const Color(0xFF25D366);
      case 'call':     return _cSky;
      case 'email':    return _cAmber;
      default:         return _cGreen;
    }
  }

  String _label(String m) {
    switch (m) {
      case 'whatsapp': return 'WhatsApp';
      case 'call':     return 'Appel téléphonique';
      case 'email':    return 'Email';
      default:         return m;
    }
  }

  @override
  Widget build(BuildContext context) {
    final pref  = profile.contactPreference;
    final ico   = _icon(pref);
    final color = _color(pref);
    final label = _label(pref);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.18)),
        ),
        child: Row(children: [
          Container(
            width: 42, height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(ico, color: color, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.w500, color: _cInk1,
            )),
            const SizedBox(height: 2),
            Text('Appuyer pour contacter', style: TextStyle(
              fontSize: 11.5, color: color.withOpacity(0.75), fontWeight: FontWeight.w300,
            )),
          ])),
          Icon(Icons.arrow_forward_ios_rounded, size: 13, color: _cInk3),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CTA SECTION
// ═══════════════════════════════════════════════════════════════════════════

class _CTASection extends StatelessWidget {
  final bool isAuthorized;
  final Color hue;
  final VoidCallback onTap;
  const _CTASection({required this.isAuthorized, required this.hue, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isAuthorized) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _cSage.withOpacity(0.08),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _cSage.withOpacity(0.25)),
        ),
        child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_rounded, color: _cSage, size: 22),
          SizedBox(width: 10),
          Text('Accès autorisé', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500, color: _cSage,
          )),
        ]),
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 58,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [hue, Color.lerp(hue, _cSage, 0.40)!],
            begin: Alignment.centerLeft, end: Alignment.centerRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: hue.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 8)),
            BoxShadow(color: hue.withOpacity(0.15), blurRadius: 6, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock_open_rounded, color: Colors.white.withOpacity(0.9), size: 19),
          const SizedBox(width: 10),
          const Text('Demander l\'accès', style: TextStyle(
            fontSize: 16, fontWeight: FontWeight.w500,
            color: Colors.white, letterSpacing: 0.2,
          )),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ERROR / EMPTY STATES
// ═══════════════════════════════════════════════════════════════════════════

class _ErrorPage extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorPage({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _cBg,
    appBar: AppBar(backgroundColor: _cBg, elevation: 0, leading: const BackButton(color: _cInk1)),
    body: Center(child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          width: 64, height: 64,
          decoration: BoxDecoration(
            color: _cClay.withOpacity(0.09), shape: BoxShape.circle,
            border: Border.all(color: _cClay.withOpacity(0.18)),
          ),
          child: const Icon(Icons.error_outline_rounded, color: _cClay, size: 28),
        ),
        const SizedBox(height: 20),
        const Text('Erreur de chargement', style: TextStyle(
          fontSize: 18, fontWeight: FontWeight.w500, color: _cInk1,
        )),
        const SizedBox(height: 8),
        Text(error, textAlign: TextAlign.center, style: const TextStyle(
          fontSize: 13, color: _cInk3, fontWeight: FontWeight.w300,
        )),
        const SizedBox(height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _OutBtn(label: 'Retour', onTap: () => Navigator.pop(context)),
          const SizedBox(width: 12),
          _FillBtn(label: 'Réessayer', onTap: onRetry, color: _cGreen),
        ]),
      ]),
    )),
  );
}

class _EmptyPage extends StatelessWidget {
  const _EmptyPage();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _cBg,
    appBar: AppBar(backgroundColor: _cBg, elevation: 0, leading: const BackButton(color: _cInk1)),
    body: Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 64, height: 64,
        decoration: BoxDecoration(
          color: _cBorder, shape: BoxShape.circle,
          border: Border.all(color: _cBorder2),
        ),
        child: const Icon(Icons.person_off_outlined, color: _cInk3, size: 26),
      ),
      const SizedBox(height: 18),
      const Text('Profil non trouvé', style: TextStyle(
        fontSize: 16, color: _cInk3, fontWeight: FontWeight.w300,
      )),
    ])),
  );
}

class _OutBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutBtn({required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _cBorder2),
      ),
      child: Text(label, style: const TextStyle(
        fontSize: 13.5, color: _cInk2, fontWeight: FontWeight.w400,
      )),
    ),
  );
}

class _FillBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _FillBtn({required this.label, required this.onTap, required this.color});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 13),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: color.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Text(label, style: const TextStyle(
        fontSize: 13.5, color: Colors.white, fontWeight: FontWeight.w500,
      )),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// AUTHORIZATION BOTTOM SHEET
// ═══════════════════════════════════════════════════════════════════════════

class _AuthorizationSheet extends StatefulWidget {
  final String veterinarianId;
  final VoidCallback onSuccess;
  const _AuthorizationSheet({required this.veterinarianId, required this.onSuccess});

  @override
  State<_AuthorizationSheet> createState() => _AuthorizationSheetState();
}

class _AuthorizationSheetState extends State<_AuthorizationSheet>
    with SingleTickerProviderStateMixin {

  final _reasonCtrl = TextEditingController();
  bool _loading     = false;
  bool _loadingData = true;
  int  _tab         = 0;

  List<dynamic> _farms      = [];
  List<dynamic> _livestocks = [];
  dynamic _farm;
  dynamic _livestock;
  dynamic _pendingCrop;
  final Set<int> _crops   = {};
  final Set<int> _animals = {};

  late AnimationController _tabAnim;

  @override
  void initState() {
    super.initState();
    _tabAnim = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _loadData();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _tabAnim.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final farms = await ApiService.getUserFarms();
      final uid   = await TokenStorage.getUserId();
      final lives = uid != null ? await ApiService.getUserLivestock(uid) : <dynamic>[];
      if (mounted) setState(() { _farms = farms; _livestocks = lives; _loadingData = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  void _switchTab(int t) {
    HapticFeedback.selectionClick();
    setState(() {
      _tab = t; _farm = null; _livestock = null;
      _pendingCrop = null; _crops.clear(); _animals.clear();
    });
    _tabAnim.forward(from: 0);
  }

  String get _summary {
    if (_tab == 0 && _crops.isNotEmpty)   return '${_crops.length} parcelle(s)';
    if (_tab == 1 && _animals.isNotEmpty) return '${_animals.length} animal(aux)';
    return 'Aucun élément';
  }

  bool get _canSend {
    if (_loadingData || _loading) return false;
    return _tab == 0
        ? (_farm != null && _crops.isNotEmpty)
        : (_livestock != null && _animals.isNotEmpty);
  }

  Future<void> _submit() async {
    if (_reasonCtrl.text.trim().isEmpty) {
      _toast('Veuillez décrire le problème', color: _cAmber);
      return;
    }
    setState(() => _loading = true);
    try {
      final reason = '${_reasonCtrl.text}\n\n[À diagnostiquer: $_summary]';
      final farmId = _tab == 0 ? (_farm['id'] as int) : 0;
      final cropIds  = _tab == 0 ? _crops.map((e) => e.toString()).join(',') : null;
      final animIds  = _tab == 1 ? (_livestock['id'] as int).toString() : null;

      await ApiService.createAuthorization(
        farmId: farmId,
        veterinarianId: int.tryParse(widget.veterinarianId) ?? 0,
        authorizationReason: reason,
        selectedLivestockIds: animIds,
        selectedCropIds: cropIds,
      );
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) _toast('Erreur: $e', color: _cClay);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _toast(String msg, {Color color = _cSage}) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500)),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 2),
      ));

  // ── BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);

    return Container(
      height: mq.size.height * 0.90,
      decoration: const BoxDecoration(
        color: _cBg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(children: [

        // Handle bar
        Container(
          width: 40, height: 4,
          margin: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: _cBorder2,
            borderRadius: BorderRadius.circular(2),
          ),
        ),

        // Sheet header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Demander l\'accès', style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w200,
                color: _cInk1, letterSpacing: -1.0,
              )),
              const SizedBox(height: 4),
              const Text('Sélectionnez ce que vous souhaitez diagnostiquer', style: TextStyle(
                fontSize: 12.5, color: _cInk3, fontWeight: FontWeight.w300,
              )),
            ])),
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: 34, height: 34,
                decoration: BoxDecoration(
                  color: _cSurf2, borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: _cBorder),
                ),
                child: const Icon(Icons.close_rounded, size: 16, color: _cInk2),
              ),
            ),
          ]),
        ),

        const SizedBox(height: 20),

        // Tab switcher pill
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            height: 46,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: _cSurf,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: _cBorder),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
            ),
            child: Row(children: [
              _SheetTab(label: '🌾  Cultures', active: _tab == 0, onTap: () => _switchTab(0)),
              _SheetTab(label: '🐄  Animaux',  active: _tab == 1, onTap: () => _switchTab(1)),
            ]),
          ),
        ),

        const SizedBox(height: 16),

        // Scrollable body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            physics: const BouncingScrollPhysics(),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

              if (_loadingData)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 48),
                  child: Center(child: CircularProgressIndicator(color: _cGreen, strokeWidth: 2)),
                )
              else if (_tab == 0)
                _CulturesBody(
                  farms: _farms,
                  farm: _farm, crop: _pendingCrop, crops: _crops,
                  onFarm: (f) => setState(() { _farm = f; _crops.clear(); _pendingCrop = null; }),
                  onAddCrop: (c) => setState(() { _crops.add(c['id'] as int); _pendingCrop = null; }),
                  onRemoveCrop: (id) => setState(() => _crops.remove(id)),
                  onSelectCrop: (c) => setState(() => _pendingCrop = c),
                )
              else
                _AnimalsBody(
                  livestocks: _livestocks,
                  livestock: _livestock,
                  animals: _animals,
                  onLivestock: (l) => setState(() { _livestock = l; _animals.clear(); }),
                  onCount: (n) => setState(() { _animals.clear(); for (int i = 0; i < n; i++) _animals.add(i); }),
                ),

              const SizedBox(height: 20),

              // Summary
              _SummaryBanner(text: 'À diagnostiquer : $_summary'),

              const SizedBox(height: 20),

              // Reason label + field
              const _FieldLabel(text: 'Raison de la demande'),
              const SizedBox(height: 8),
              _ReasonTextField(ctrl: _reasonCtrl),
              const SizedBox(height: 28),
            ]),
          ),
        ),

        // Footer buttons
        Container(
          padding: EdgeInsets.fromLTRB(24, 14, 24, mq.padding.bottom + 16),
          decoration: const BoxDecoration(
            color: _cBg,
            border: Border(top: BorderSide(color: _cBorder)),
          ),
          child: Row(children: [
            _OutBtn(label: 'Annuler', onTap: () => Navigator.pop(context)),
            const SizedBox(width: 12),
            Expanded(child: _SendBtn(canSend: _canSend, loading: _loading, onTap: _submit)),
          ]),
        ),
      ]),
    );
  }
}

// ── Sheet tab pill ────────────────────────────────────────────────────────

class _SheetTab extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _SheetTab({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) => Expanded(
    child: GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: double.infinity,
        decoration: BoxDecoration(
          color: active ? _cGreen : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: active
              ? [BoxShadow(color: _cGreen.withOpacity(0.25), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Center(child: Text(label, style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w400,
          color: active ? Colors.white : _cInk3,
        ))),
      ),
    ),
  );
}

// ── Cultures body ─────────────────────────────────────────────────────────

class _CulturesBody extends StatelessWidget {
  final List<dynamic> farms;
  final dynamic farm, crop;
  final Set<int> crops;
  final ValueChanged<dynamic> onFarm, onAddCrop, onSelectCrop;
  final ValueChanged<int> onRemoveCrop;

  const _CulturesBody({
    required this.farms, required this.farm, required this.crop,
    required this.crops, required this.onFarm, required this.onAddCrop,
    required this.onRemoveCrop, required this.onSelectCrop,
  });

  @override
  Widget build(BuildContext context) {
    if (farms.isEmpty) return const _EmptyHint(icon: Icons.agriculture_rounded, msg: 'Aucune ferme — créez-en une d\'abord');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _FieldLabel(text: 'Ferme'),
      const SizedBox(height: 8),
      _StyledDrop<dynamic>(
        hint: 'Sélectionner une ferme',
        value: farm,
        items: farms.map((f) => DropdownMenuItem(value: f,
          child: Text(f['name'] ?? 'Ferme', overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onFarm,
      ),

      if (farm != null && (farm['crops']?.isNotEmpty ?? false)) ...[
        const SizedBox(height: 18),
        const _FieldLabel(text: 'Parcelles à examiner'),
        const SizedBox(height: 8),
        _StyledDrop<dynamic>(
          hint: '+ Ajouter une parcelle',
          value: crop,
          items: (farm['crops'] as List)
              .where((c) => !crops.contains(c['id']))
              .map((c) => DropdownMenuItem(value: c, child: Text(c['crop_name'] ?? 'Culture')))
              .toList(),
          onChanged: onAddCrop,
        ),
        if (crops.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8, children: crops.map((id) {
            final c = (farm['crops'] as List).firstWhere((x) => x['id'] == id, orElse: () => null);
            if (c == null) return const SizedBox.shrink();
            return _Chip(label: c['crop_name'] ?? 'Culture', color: _cAmber,
                onRemove: () => onRemoveCrop(id));
          }).toList()),
        ],
      ],
    ]);
  }
}

// ── Animals body ──────────────────────────────────────────────────────────

class _AnimalsBody extends StatelessWidget {
  final List<dynamic> livestocks;
  final dynamic livestock;
  final Set<int> animals;
  final ValueChanged<dynamic> onLivestock;
  final ValueChanged<int> onCount;

  const _AnimalsBody({
    required this.livestocks, required this.livestock,
    required this.animals, required this.onLivestock, required this.onCount,
  });

  @override
  Widget build(BuildContext context) {
    if (livestocks.isEmpty) return const _EmptyHint(icon: Icons.pets_rounded, msg: 'Aucun bétail — créez-en un d\'abord');

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const _FieldLabel(text: 'Bétail'),
      const SizedBox(height: 8),
      _StyledDrop<dynamic>(
        hint: 'Sélectionner un bétail',
        value: livestock,
        items: livestocks.map((l) => DropdownMenuItem(value: l,
          child: Text('${l['animal_type']} — ${l['breed'] ?? 'Race'} (×${l['quantity'] ?? 1})',
              overflow: TextOverflow.ellipsis))).toList(),
        onChanged: onLivestock,
      ),

      if (livestock != null) ...[
        const SizedBox(height: 18),
        const _FieldLabel(text: 'Nombre d\'animaux à examiner'),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: _cSurf,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _cBorder),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
          ),
          child: Row(children: [
            Expanded(child: TextField(
              keyboardType: TextInputType.number,
              style: const TextStyle(fontSize: 14, color: _cInk1),
              decoration: InputDecoration(
                hintText: 'ex: 3',
                hintStyle: const TextStyle(color: _cInk3),
                filled: true, fillColor: _cBg,
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                border:        OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _cBorder)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _cBorder)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: _cGreen, width: 1.5)),
              ),
              onChanged: (v) {
                final q = int.tryParse(v) ?? 0;
                if (q > 0 && q <= (livestock['quantity'] ?? 1)) onCount(q);
              },
            )),
            const SizedBox(width: 12),
            Text('sur ${livestock['quantity'] ?? 1} total',
                style: const TextStyle(fontSize: 12, color: _cInk3, fontWeight: FontWeight.w300)),
          ]),
        ),
        if (animals.isNotEmpty) ...[
          const SizedBox(height: 10),
          _Chip(
            label: '${animals.length} animal(aux) sélectionné(s)',
            color: _cSky,
          ),
        ],
      ],
    ]);
  }
}

// ── Shared sheet components ───────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel({required this.text});
  @override
  Widget build(BuildContext context) => Text(text.toUpperCase(), style: const TextStyle(
    fontSize: 9.5, fontWeight: FontWeight.w600,
    letterSpacing: 2.0, color: _cInk3,
  ));
}

class _StyledDrop<T> extends StatelessWidget {
  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;
  const _StyledDrop({required this.hint, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
    decoration: BoxDecoration(
      color: _cSurf,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _cBorder),
      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 3))],
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<T>(
        value: value, isExpanded: true,
        hint: Text(hint, style: const TextStyle(color: _cInk3, fontSize: 13.5)),
        icon: const Icon(Icons.keyboard_arrow_down_rounded, color: _cInk3, size: 18),
        style: const TextStyle(color: _cInk1, fontSize: 13.5),
        dropdownColor: _cSurf,
        borderRadius: BorderRadius.circular(14),
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onRemove;
  const _Chip({required this.label, required this.color, this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.fromLTRB(10, 6, onRemove != null ? 6 : 10, 6),
    decoration: BoxDecoration(
      color: color.withOpacity(0.09),
      borderRadius: BorderRadius.circular(30),
      border: Border.all(color: color.withOpacity(0.22)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Text(label, style: TextStyle(fontSize: 12.5, color: color, fontWeight: FontWeight.w400)),
      if (onRemove != null) ...[
        const SizedBox(width: 6),
        GestureDetector(onTap: onRemove,
          child: Icon(Icons.close_rounded, size: 14, color: color.withOpacity(0.65))),
      ],
    ]),
  );
}

class _SummaryBanner extends StatelessWidget {
  final String text;
  const _SummaryBanner({required this.text});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
    decoration: BoxDecoration(
      color: _cGreen.withOpacity(0.06),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _cGreen.withOpacity(0.18)),
    ),
    child: Row(children: [
      const Icon(Icons.info_outline_rounded, color: _cGreen, size: 16),
      const SizedBox(width: 10),
      Expanded(child: Text(text, style: const TextStyle(
        fontSize: 13, color: _cGreen, fontWeight: FontWeight.w400,
      ))),
    ]),
  );
}

class _ReasonTextField extends StatelessWidget {
  final TextEditingController ctrl;
  const _ReasonTextField({required this.ctrl});

  @override
  Widget build(BuildContext context) => TextField(
    controller: ctrl,
    maxLines: 4,
    style: const TextStyle(fontSize: 14, color: _cInk1, height: 1.55),
    decoration: InputDecoration(
      hintText: 'Décrivez les symptômes ou problèmes observés…',
      hintStyle: const TextStyle(color: _cInk3, fontSize: 13.5, fontWeight: FontWeight.w300),
      filled: true, fillColor: _cSurf,
      contentPadding: const EdgeInsets.all(16),
      border:        OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _cBorder)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _cBorder)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: const BorderSide(color: _cGreen, width: 1.5)),
    ),
  );
}

class _SendBtn extends StatelessWidget {
  final bool canSend, loading;
  final VoidCallback onTap;
  const _SendBtn({required this.canSend, required this.loading, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: canSend ? onTap : null,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      height: 50,
      decoration: BoxDecoration(
        gradient: canSend
            ? const LinearGradient(colors: [_cGreen, Color(0xFF43A047)],
                begin: Alignment.centerLeft, end: Alignment.centerRight)
            : null,
        color: canSend ? null : _cBorder,
        borderRadius: BorderRadius.circular(14),
        boxShadow: canSend
            ? [BoxShadow(color: _cGreen.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 5))]
            : null,
      ),
      child: Center(
        child: loading
            ? const SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text('Envoyer la demande', style: TextStyle(
                fontSize: 14.5, fontWeight: FontWeight.w500,
                color: canSend ? Colors.white : _cInk3,
              )),
      ),
    ),
  );
}

class _EmptyHint extends StatelessWidget {
  final IconData icon;
  final String msg;
  const _EmptyHint({required this.icon, required this.msg});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: _cSurf,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: _cBorder),
    ),
    child: Row(children: [
      Icon(icon, color: _cInk3, size: 22),
      const SizedBox(width: 14),
      Expanded(child: Text(msg, style: const TextStyle(
        fontSize: 13.5, color: _cInk2, fontWeight: FontWeight.w300,
      ))),
    ]),
  );
}