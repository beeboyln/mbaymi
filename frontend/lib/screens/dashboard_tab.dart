import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/services/weather_service.dart';
import 'package:mbaymi/models/news_model.dart';
import 'package:mbaymi/screens/news_detail_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class _GrainPainter extends CustomPainter {
  final double seed;
  final Color color;
  _GrainPainter({required this.seed, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random((seed * 1000).toInt());
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 280; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 0.9 + 0.2;
      final op = rng.nextDouble() * 0.040 + 0.006;
      paint.color = color.withOpacity(op);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter o) => o.seed != seed;
}

class _WavePainter extends CustomPainter {
  final double phase;
  final Color color;
  final double yOffset;
  _WavePainter({required this.phase, required this.color, this.yOffset = 0.6});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    final path = Path();
    final baseY = size.height * yOffset;
    path.moveTo(0, size.height);
    path.lineTo(0, baseY + 10 * sin(phase));
    for (double x = 0; x <= size.width; x += 2) {
      final y = baseY
          + 12 * sin(x / size.width * 2 * pi + phase)
          + 6  * sin(x / size.width * 4 * pi - phase * 1.3)
          + 3  * cos(x / size.width * 6 * pi + phase * 0.7);
      path.lineTo(x, y);
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_WavePainter o) => o.phase != phase;
}

class _RingsPainter extends CustomPainter {
  final Color color;
  const _RingsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6;
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;
    for (int i = 1; i <= 6; i++) {
      paint.color = color.withOpacity(0.025 + i * 0.005);
      canvas.drawCircle(Offset(cx, cy), i * 40.0, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// ILLUSTRATION HERO — silhouette agricole minimaliste
// ─────────────────────────────────────────────────────────────────────────────
class _AgriIllustrationPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final bool isDark;
  final double phase;

  const _AgriIllustrationPainter({
    required this.primary,
    required this.accent,
    required this.isDark,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseOpacity   = isDark ? 0.20 : 0.14;
    final accentOpacity = isDark ? 0.35 : 0.26;

    final fillPrimary = Paint()
      ..color = primary.withOpacity(baseOpacity)
      ..style = PaintingStyle.fill;
    final fillAccent = Paint()
      ..color = accent.withOpacity(accentOpacity)
      ..style = PaintingStyle.fill;
    final strokePrimary = Paint()
      ..color = primary.withOpacity(baseOpacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    // Sol
    final groundPath = Path();
    groundPath.moveTo(0, h * 0.72);
    for (double x = 0; x <= w; x += 2) {
      final y = h * 0.72
          + 2.2 * sin(x / w * pi * 2 + phase * 0.4)
          + 1.0 * sin(x / w * pi * 5 - phase * 0.6);
      groundPath.lineTo(x, y);
    }
    groundPath.lineTo(w, h);
    groundPath.lineTo(0, h);
    groundPath.close();
    canvas.drawPath(groundPath, fillPrimary);

    // Sillons
    for (int row = 0; row < 3; row++) {
      final yBase = h * (0.76 + row * 0.07);
      final rowPath = Path();
      rowPath.moveTo(w * 0.08, yBase);
      for (double x = w * 0.08; x <= w * 0.92; x += 2) {
        final y = yBase + 0.8 * sin((x / w * pi * 6) + phase * 0.3 + row * 0.8);
        rowPath.lineTo(x, y);
      }
      canvas.drawPath(rowPath, Paint()
        ..color = primary.withOpacity(baseOpacity * 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.7);
    }

    // Tige
    final stemSway = 1.6 * sin(phase * 2 * pi);
    final stemPath = Path();
    stemPath.moveTo(w * 0.5, h * 0.72);
    stemPath.cubicTo(
      w * 0.5 + stemSway * 0.3, h * 0.55,
      w * 0.5 + stemSway, h * 0.40,
      w * 0.5 + stemSway, h * 0.28,
    );
    canvas.drawPath(stemPath, strokePrimary..strokeWidth = 1.3);

    // Grande feuille gauche
    final leaf1 = Path();
    final lx = w * 0.5 + stemSway * 0.5;
    final ly = h * 0.46;
    leaf1.moveTo(lx, ly);
    leaf1.cubicTo(lx - w * 0.14, ly - h * 0.06, lx - w * 0.22, ly + h * 0.04, lx - w * 0.18, ly + h * 0.09);
    leaf1.cubicTo(lx - w * 0.10, ly + h * 0.06, lx - w * 0.04, ly + h * 0.02, lx, ly);
    canvas.drawPath(leaf1, fillAccent);

    // Nervure
    final vein1 = Path();
    vein1.moveTo(lx, ly);
    vein1.quadraticBezierTo(lx - w * 0.11, ly + h * 0.03, lx - w * 0.18, ly + h * 0.09);
    canvas.drawPath(vein1, Paint()
      ..color = accent.withOpacity(accentOpacity * 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.55
      ..strokeCap = StrokeCap.round);

    // Petite feuille droite
    final leaf2 = Path();
    final rx = w * 0.5 + stemSway * 0.8;
    final ry = h * 0.36;
    leaf2.moveTo(rx, ry);
    leaf2.cubicTo(rx + w * 0.10, ry - h * 0.05, rx + w * 0.16, ry + h * 0.03, rx + w * 0.13, ry + h * 0.08);
    leaf2.cubicTo(rx + w * 0.06, ry + h * 0.05, rx + w * 0.02, ry + h * 0.01, rx, ry);
    canvas.drawPath(leaf2, fillAccent..color = accent.withOpacity(accentOpacity * 0.70));

    // Épi
    final grainX = w * 0.5 + stemSway;
    final grainY = h * 0.28;
    for (int g = 0; g < 5; g++) {
      final gy = grainY - g * h * 0.028;
      final gw = (5 - g) * w * 0.014 * (1 + 0.04 * sin(phase * 2 * pi + g));
      final grainPaint = Paint()
        ..color = primary.withOpacity(baseOpacity + g * 0.016)
        ..style = PaintingStyle.fill;
      canvas.drawOval(Rect.fromCenter(center: Offset(grainX - gw * 0.6, gy), width: gw * 0.85, height: h * 0.020), grainPaint);
      canvas.drawOval(Rect.fromCenter(center: Offset(grainX + gw * 0.6, gy), width: gw * 0.85, height: h * 0.020), grainPaint);
    }
  }

  @override
  bool shouldRepaint(_AgriIllustrationPainter o) =>
      o.phase != phase || o.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// WEATHER BADGE
// ─────────────────────────────────────────────────────────────────────────────
class _WeatherBadge extends StatelessWidget {
  final int weatherCode;
  final double phase;
  final Color primary;
  final Color accent;
  final bool isDark;

  const _WeatherBadge({
    required this.weatherCode,
    required this.phase,
    required this.primary,
    required this.accent,
    required this.isDark,
  });

  IconData get _iconData {
    if (weatherCode == 0) return Icons.wb_sunny_rounded;
    if (weatherCode <= 2) return Icons.wb_cloudy_rounded;
    if (weatherCode <= 3) return Icons.cloud_rounded;
    if (weatherCode <= 49) return Icons.foggy;
    if (weatherCode <= 67) return Icons.grain_rounded;
    if (weatherCode <= 77) return Icons.ac_unit_rounded;
    if (weatherCode <= 82) return Icons.umbrella_rounded;
    return Icons.thunderstorm_rounded;
  }

  Color get _glowColor {
    if (weatherCode == 0) return const Color(0xFFFFB300);
    if (weatherCode <= 2) return const Color(0xFFFFB300);
    if (weatherCode <= 3) return const Color(0xFF90A4AE);
    if (weatherCode <= 49) return const Color(0xFFB0BEC5);
    if (weatherCode <= 82) return const Color(0xFF42A5F5);
    return const Color(0xFF7E57C2);
  }

  @override
  Widget build(BuildContext context) {
    final glowOpacity = 0.08 + 0.05 * phase;
    final iconColor = _glowColor;
    return Container(
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: iconColor.withOpacity(isDark ? glowOpacity * 1.5 : glowOpacity),
      ),
      child: Center(
        child: Icon(_iconData, size: 21, color: iconColor.withOpacity(isDark ? 0.88 : 0.78)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SHIMMER
// ─────────────────────────────────────────────────────────────────────────────
class _Shimmer extends StatefulWidget {
  final double width, height;
  final double radius;
  const _Shimmer({required this.width, required this.height, this.radius = 0});
  @override
  State<_Shimmer> createState() => _ShimmerState();
}
class _ShimmerState extends State<_Shimmer> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1500))..repeat();
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(widget.radius),
          gradient: LinearGradient(
            begin: Alignment(-2 + 4 * _c.value, 0),
            end: Alignment(-2 + 4 * _c.value + 2, 0),
            colors: isDark
                ? [const Color(0xFF1C1410), const Color(0xFF2A1F16), const Color(0xFF1C1410)]
                : [const Color(0xFFEDE8DE), const Color(0xFFF5F1E8), const Color(0xFFEDE8DE)],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PILL TAG minimal
// ─────────────────────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;
  const _Tag(this.text, {required this.bg, required this.fg, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: icon != null ? 8 : 9, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(4)),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 8, color: fg),
          const SizedBox(width: 4),
        ],
        Text(text, style: TextStyle(
          fontSize: 7.5, fontWeight: FontWeight.w600,
          letterSpacing: 1.6, color: fg,
        )),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// NEWS CATEGORY TAG
// ─────────────────────────────────────────────────────────────────────────────
class _NewsCategoryTag extends StatelessWidget {
  final String category;
  const _NewsCategoryTag(this.category);

  static _CategoryStyle _style(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('local') || c.contains('senegal')) {
      return _CategoryStyle(bg: const Color(0xFF2E7D32).withOpacity(0.13),
          fg: const Color(0xFF4CAF50), icon: Icons.location_on_rounded, label: 'LOCAL');
    }
    if (c.contains('international') || c.contains('world') || c.contains('global')) {
      return _CategoryStyle(bg: const Color(0xFF1565C0).withOpacity(0.12),
          fg: const Color(0xFF42A5F5), icon: Icons.public_rounded, label: 'INTL');
    }
    if (c.contains('national')) {
      return _CategoryStyle(bg: const Color(0xFFE65100).withOpacity(0.12),
          fg: const Color(0xFFFF7043), icon: Icons.flag_rounded, label: 'NATIONAL');
    }
    if (c.contains('marché') || c.contains('market') || c.contains('prix')) {
      return _CategoryStyle(bg: const Color(0xFF6A1B9A).withOpacity(0.12),
          fg: const Color(0xFFCE93D8), icon: Icons.trending_up_rounded, label: 'MARCHÉ');
    }
    return _CategoryStyle(bg: const Color(0xFF558B2F).withOpacity(0.12),
        fg: const Color(0xFF8BC34A), icon: Icons.eco_rounded, label: 'AGRI');
  }

  @override
  Widget build(BuildContext context) {
    final s = _style(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
      decoration: BoxDecoration(color: s.bg, borderRadius: BorderRadius.circular(3)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 7.5, color: s.fg),
          const SizedBox(width: 3),
          Text(s.label, style: TextStyle(
            fontSize: 7, fontWeight: FontWeight.w700,
            letterSpacing: 1.3, color: s.fg,
          )),
        ],
      ),
    );
  }
}

class _CategoryStyle {
  final Color bg, fg;
  final IconData icon;
  final String label;
  const _CategoryStyle({required this.bg, required this.fg, required this.icon, required this.label});
}


// ─────────────────────────────────────────────────────────────────────────────
// ✨ TAGLINE WIDGET — révélation au clic
// ─────────────────────────────────────────────────────────────────────────────
class _AgriTagline extends StatefulWidget {
  final Color primary;
  final Color accent;
  final bool isDark;
  const _AgriTagline({required this.primary, required this.accent, required this.isDark});
  @override
  State<_AgriTagline> createState() => _AgriTaglineState();
}
class _AgriTaglineState extends State<_AgriTagline> with TickerProviderStateMixin {
  late AnimationController _entryCtrl;
  late Animation<double> _entryFade;
  late Animation<Offset> _entrySlide;

  late AnimationController _revealCtrl;
  late Animation<double> _revealFade;
  late Animation<Offset> _revealSlide;
  late Animation<double> _revealScale;

  bool _revealed = false;

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _entryFade  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _entrySlide = Tween<Offset>(begin: const Offset(0, 0.10), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));

    _revealCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 520));
    _revealFade  = CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOut);
    _revealSlide = Tween<Offset>(begin: const Offset(0, 0.18), end: Offset.zero)
        .animate(CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOutCubic));
    _revealScale = Tween<double>(begin: 0.94, end: 1.0)
        .animate(CurvedAnimation(parent: _revealCtrl, curve: Curves.easeOutCubic));

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    _revealCtrl.dispose();
    super.dispose();
  }

  void _onTap() {
    HapticFeedback.lightImpact();
    setState(() => _revealed = true);
    _revealCtrl.forward();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primary;
    final accent  = widget.accent;
    final isDark  = widget.isDark;

    return FadeTransition(
      opacity: _entryFade,
      child: SlideTransition(
        position: _entrySlide,
        child: GestureDetector(
          onTap: _revealed ? null : _onTap,
          child: Container(
            width: double.infinity,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0D1A0A) : const Color(0xFFF0F7EC),
            ),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 460),
              curve: Curves.easeOutCubic,
              child: _revealed
                  ? _revealedContent(accent, isDark)
                  : _teaser(primary, accent, isDark),
            ),
          ),
        ),
      ),
    );
  }

  Widget _teaser(Color primary, Color accent, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.chat_bubble_outline_rounded, color: accent, size: 16),
              ),
              Positioned(
                top: -1, right: -1,
                child: Container(
                  width: 8, height: 8,
                  decoration: BoxDecoration(
                    color: accent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF0D1A0A) : const Color(0xFFF0F7EC),
                      width: 1.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Un message pour vous', style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  color: isDark ? Colors.white.withOpacity(0.75) : Colors.black.withOpacity(0.60),
                  letterSpacing: 0.1,
                )),
                const SizedBox(height: 2),
                Text('Appuyez pour découvrir', style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w300,
                  color: accent.withOpacity(0.70),
                  letterSpacing: 0.3,
                )),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: primary.withOpacity(0.30), size: 16),
        ],
      ),
    );
  }

  Widget _revealedContent(Color accent, bool isDark) {
    return FadeTransition(
      opacity: _revealFade,
      child: SlideTransition(
        position: _revealSlide,
        child: ScaleTransition(
          scale: _revealScale,
          alignment: Alignment.topCenter,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 22),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(Icons.spa_rounded, color: accent, size: 17),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LA TERRE NOURRIT. LA TECH GUIDEE.',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.0,
                          color: accent,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'De Dakar au Sahel, chaque agriculteur mérite les meilleures informations au bon moment.',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w300,
                          color: isDark
                              ? Colors.white.withOpacity(0.65)
                              : Colors.black.withOpacity(0.52),
                          height: 1.55,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD TAB
// ─────────────────────────────────────────────────────────────────────────────
class DashboardTab extends StatefulWidget {
  final bool isDarkMode;
  final int? userId;
  final VoidCallback? onNavigateToFarmTab;
  const DashboardTab({super.key, this.isDarkMode = false, this.userId, this.onNavigateToFarmTab});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab>
    with TickerProviderStateMixin {
  String _selectedFilter = 'Local';
  late Future<Map<String, dynamic>> _weatherFuture;
  late Future<List<NewsArticle>>    _newsFuture;

  static final _gcWeather = <String, Future<Map<String, dynamic>>>{};
  static final _gcNews    = <String, Future<List<NewsArticle>>>{};

  AnimationController? _waveCtrl;
  AnimationController? _entryCtrl;
  AnimationController? _grainCtrl;
  AnimationController? _weatherIconCtrl;
  AnimationController? _filterSlideCtrl;

  bool _filterOpen      = false;
  bool _initialized     = false;
  int  _filterDirection = 1;

  List<Animation<double>>? _fade;
  List<Animation<Offset>>?  _slide;

  int _tipIdx = 0;
  final _tips = [
    'Arrosez tôt le matin pour réduire l\'évaporation et économiser l\'eau.',
    'Le compost améliore la rétention d\'humidité du sol en profondeur.',
    'Diversifiez les cultures pour réduire les risques de ravageurs.',
    'Surveillez les feuilles pour détecter les maladies tôt.',
    'Plantez des haies coupe-vent pour protéger vos parcelles.',
    'Récupérez l\'eau de pluie pour une irrigation durable.',
  ];

  String _newsKey = 'Local';
  final _rng = Random();

  @override
  void initState() {
    super.initState();

    _waveCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _grainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120))..repeat();
    _weatherIconCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 4))..repeat();
    _filterSlideCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 340));

    final ec = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _entryCtrl = ec;

    _fade = List.generate(7, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: ec, curve: Interval(i * 0.08, min(i * 0.08 + 0.45, 1.0), curve: Curves.easeOut)),
    ));
    _slide = List.generate(7, (i) =>
      Tween<Offset>(begin: const Offset(0, 0.14), end: Offset.zero).animate(
        CurvedAnimation(parent: ec, curve: Interval(i * 0.08, min(i * 0.08 + 0.45, 1.0), curve: Curves.easeOutCubic)),
      ));

    _weatherFuture = _getOrCreateWeather();
    _newsFuture    = _getOrCreateNews();
    _tipIdx        = _rng.nextInt(_tips.length);
    _initialized   = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryCtrl?.forward();
    });
  }

  @override
  void dispose() {
    _waveCtrl?.dispose();
    _entryCtrl?.dispose();
    _grainCtrl?.dispose();
    _weatherIconCtrl?.dispose();
    _filterSlideCtrl?.dispose();
    super.dispose();
  }

  Widget _s(int i, Widget child) {
    final f = _fade; final s = _slide;
    if (f == null || s == null) return child;
    return FadeTransition(opacity: f[i],
      child: SlideTransition(position: s[i], child: child));
  }

  Future<Map<String, dynamic>> _getOrCreateWeather() =>
      _gcWeather['w'] ??= WeatherService.getWeather();

  Future<List<NewsArticle>> _getOrCreateNews() =>
      _gcNews['n_$_selectedFilter'] ??= ApiService.getAgriculturalNews();

  Future<void> _refresh() async {
    _gcWeather.clear(); _gcNews.clear();
    _entryCtrl?.forward(from: 0);
    setState(() {
      _weatherFuture = _getOrCreateWeather();
      _newsFuture    = _getOrCreateNews();
      _filterOpen    = false;
    });
    await Future.delayed(const Duration(milliseconds: 600));
  }

  List<NewsArticle> _filter(List<NewsArticle> a) => a.where((art) {
    final cat = (art.category ?? '').toLowerCase();
    final src = (art.source   ?? '').toLowerCase();
    switch (_selectedFilter) {
      case 'Local':         return cat.contains('local') || cat.contains('senegal') || src.contains('local') || src.contains('senegal');
      case 'International': return cat.contains('international') || cat.contains('world') || cat.contains('global');
      default:              return true;
    }
  }).toList();

  String _date() {
    final n = DateTime.now();
    const days   = ['Lundi','Mardi','Mercredi','Jeudi','Vendredi','Samedi','Dimanche'];
    const months = ['janvier','février','mars','avril','mai','juin','juillet','août','septembre','octobre','novembre','décembre'];
    return '${days[n.weekday - 1]} ${n.day} ${months[n.month - 1]} ${n.year}';
  }

  void _navigateToFarmsTab() {
    HapticFeedback.mediumImpact();
    widget.onNavigateToFarmTab?.call();
  }

  void _changeFilter(String newFilter) {
    final filters = ['Local', 'National', 'International', 'Liens utiles'];
    final oldIdx = filters.indexOf(_selectedFilter);
    final newIdx = filters.indexOf(newFilter);
    _filterDirection = newIdx > oldIdx ? 1 : -1;
    _filterSlideCtrl?.forward(from: 0);
    HapticFeedback.selectionClick();
    setState(() {
      _selectedFilter = newFilter;
      _filterOpen     = false;
      _newsKey        = newFilter;
      _gcNews.clear();
      _newsFuture     = _getOrCreateNews();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    if (!_initialized) return const SizedBox.shrink();
    final tp     = Provider.of<ThemeProvider>(context);
    final isDark = tp.isDarkMode;

    final bg      = isDark ? AppColors.darkBg      : AppColors.lightBg;
    final surface = isDark ? AppColors.darkCardBg   : const Color(0xFFFAF8F4);
    final border  = isDark ? AppColors.borderDark   : AppColors.borderLight;
    const primary = AppColors.primary;
    const accent  = AppColors.accent;
    final textPri = isDark ? AppColors.textDark     : AppColors.textLight;
    final textSec = isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: primary,
        backgroundColor: surface,
        displacement: 36,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Hero
            SliverToBoxAdapter(
              child: _s(0, _hero(isDark, bg, primary, accent, textPri, textSec)),
            ),

            // ✨ Tagline agricole
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(0, 20, 0, 0),
              sliver: SliverToBoxAdapter(
                child: _s(1, _AgriTagline(primary: primary, accent: accent, isDark: isDark)),
              ),
            ),

            // Weather
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _s(2, _weatherCard(isDark, surface, border, primary, accent, textPri, textSec)),
              ),
            ),

            // Farm banner
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _s(3, _farmBanner(isDark, primary, accent)),
              ),
            ),

            // Tip card
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _s(4, _tipCard(isDark, surface, border, primary, accent, textPri, textSec)),
              ),
            ),

            // News
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 32, 16, 14),
              sliver: SliverToBoxAdapter(
                child: _s(5, _newsSection(isDark, surface, border, primary, accent, textPri, textSec)),
              ),
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 90)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _hero(bool isDark, Color bg, Color primary, Color accent,
      Color textPri, Color textSec) {
    return SizedBox(
      height: 220,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Fond
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF18100A), const Color(0xFF0C0804)]
                      : [const Color(0xFFFFF8EE), const Color(0xFFEEE2CC)],
                ),
              ),
            ),
          ),

          // Grain subtil
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _grainCtrl ?? const AlwaysStoppedAnimation(0),
              builder: (_, __) => CustomPaint(
                painter: _GrainPainter(seed: _grainCtrl?.value ?? 0, color: primary),
              ),
            ),
          ),

          // Rings
          Positioned(
            top: -30, right: -60,
            child: SizedBox(
              width: 260, height: 260,
              child: CustomPaint(painter: _RingsPainter(color: primary)),
            ),
          ),

          // Glow
          Positioned(
            top: -80, right: -80,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  accent.withOpacity(isDark ? 0.18 : 0.12),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // Illustration
          Positioned(
            right: 12, bottom: 16, top: 16,
            child: SizedBox(
              width: 124,
              child: AnimatedBuilder(
                animation: _waveCtrl ?? const AlwaysStoppedAnimation(0),
                builder: (_, __) => CustomPaint(
                  painter: _AgriIllustrationPainter(
                    primary: primary,
                    accent: accent,
                    isDark: isDark,
                    phase: _waveCtrl?.value ?? 0,
                  ),
                ),
              ),
            ),
          ),

          // Vague 1
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _waveCtrl ?? const AlwaysStoppedAnimation(0),
              builder: (_, __) => SizedBox(
                height: 80,
                child: CustomPaint(
                  painter: _WavePainter(
                    phase: (_waveCtrl?.value ?? 0) * 2 * pi,
                    color: primary.withOpacity(isDark ? 0.22 : 0.12),
                    yOffset: 0.50,
                  ),
                  size: Size(MediaQuery.of(context).size.width, 80),
                ),
              ),
            ),
          ),

          // Vague 2
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _waveCtrl ?? const AlwaysStoppedAnimation(0),
              builder: (_, __) => SizedBox(
                height: 80,
                child: CustomPaint(
                  painter: _WavePainter(
                    phase: (_waveCtrl?.value ?? 0) * 2 * pi + 1.4,
                    color: primary.withOpacity(isDark ? 0.11 : 0.07),
                    yOffset: 0.68,
                  ),
                  size: Size(MediaQuery.of(context).size.width, 80),
                ),
              ),
            ),
          ),

          // Contenu texte
          Padding(
            padding: EdgeInsets.fromLTRB(22, MediaQuery.of(context).padding.top + 12, 22, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_date(), style: TextStyle(
                      fontSize: 10.5, fontWeight: FontWeight.w300,
                      color: primary.withOpacity(0.60), letterSpacing: 0.2,
                    )),
                    const Spacer(),
                    _Tag('SAISON SÈCHE',
                      bg: primary.withOpacity(0.10),
                      fg: primary.withOpacity(0.80),
                      icon: Icons.wb_sunny_outlined),
                  ],
                ),
                const Spacer(),
                Text('Bonjour,', style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w300,
                  color: accent.withOpacity(0.85), letterSpacing: 0.5,
                )),
                const SizedBox(height: 4),
                if (AuthService.isAuthenticated && AuthService.currentSession?.name != null) ...[
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        AuthService.currentSession!.name.split(' ').first,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w200,
                          color: accent.withOpacity(0.80),
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(width: 7),
                      if (AuthService.currentSession!.name.split(' ').length > 1)
                        Flexible(
                          child: Text(
                            AuthService.currentSession!.name.split(' ').skip(1).join(' '),
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w500,
                              color: isDark ? const Color(0xFFF0E8D8) : AppColors.textLight,
                              letterSpacing: -1.0,
                              height: 1.1,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ] else ...[
                  Text('Agriculteur', style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFF0E8D8) : AppColors.textLight,
                    letterSpacing: -1.0,
                  )),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WEATHER CARD — épuré, sans bordure, ombre douce
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _weatherCard(bool isDark, Color surface, Color border, Color primary,
      Color accent, Color textPri, Color textSec) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _weatherFuture,
      builder: (_, snap) {
        final loading   = snap.connectionState == ConnectionState.waiting;
        final w         = snap.data ?? {};
        final maxT      = (w['max_temp'] as num?)?.toDouble()     ?? 29;
        final minT      = (w['min_temp'] as num?)?.toDouble()     ?? 21;
        final code      = (w['daily_weather_code'] as int?)       ?? 1;
        final advice    = WeatherService.getWeatherAdvice(code, maxT);
        final windSpeed = (w['wind_speed'] as num?)?.toDouble()
            ?? (w['wind_speed_10m_max'] as num?)?.toDouble()     ?? 14.0;

        return Container(
          decoration: BoxDecoration(
            color: surface,
            // ✨ Pas de Border, juste une ombre propre
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.30)
                    : primary.withOpacity(0.07),
                blurRadius: 24,
                offset: const Offset(0, 8),
                spreadRadius: -2,
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // Bande top — dégradé discret
              Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    accent.withOpacity(0.6),
                    primary.withOpacity(0.30),
                    Colors.transparent,
                  ]),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 20, 22, 22),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Gauche — temp
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MÉTÉO', style: TextStyle(
                          fontSize: 7, fontWeight: FontWeight.w500,
                          letterSpacing: 3.0, color: textSec.withOpacity(0.5),
                        )),
                        const SizedBox(height: 12),
                        if (loading)
                          const _Shimmer(width: 100, height: 76, radius: 6)
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              AnimatedBuilder(
                                animation: _weatherIconCtrl ?? const AlwaysStoppedAnimation(0),
                                builder: (_, __) => _WeatherBadge(
                                  weatherCode: code,
                                  phase: _weatherIconCtrl?.value ?? 0,
                                  primary: primary,
                                  accent: accent,
                                  isDark: isDark,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${maxT.round()}', style: TextStyle(
                                        fontSize: 54, fontWeight: FontWeight.w800,
                                        color: textPri, height: 0.88, letterSpacing: -3.5,
                                      )),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 6),
                                        child: Text('°C', style: TextStyle(
                                          fontSize: 15, fontWeight: FontWeight.w200, color: accent,
                                        )),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  // Min / max pill
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: primary.withOpacity(0.06),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Text(
                                      '↓${minT.round()}°  ↑${maxT.round()}°',
                                      style: TextStyle(fontSize: 9, color: textSec, fontWeight: FontWeight.w400),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                      ],
                    ),

                    const SizedBox(width: 20),

                    // Séparateur fin
                    Container(
                      width: 1,
                      height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, textSec.withOpacity(0.12), Colors.transparent],
                        ),
                      ),
                    ),

                    const SizedBox(width: 20),

                    // Droite — conseil
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: Icon(Icons.eco_rounded, color: accent, size: 12),
                            ),
                            const SizedBox(width: 7),
                            Text('CONSEIL', style: TextStyle(
                              fontSize: 7, fontWeight: FontWeight.w500,
                              letterSpacing: 2.5, color: textSec.withOpacity(0.5),
                            )),
                          ]),
                          const SizedBox(height: 10),
                          if (loading)
                            const Column(children: [
                              _Shimmer(width: double.infinity, height: 10, radius: 3),
                              SizedBox(height: 5),
                              _Shimmer(width: 90, height: 10, radius: 3),
                            ])
                          else
                            Text(advice, style: TextStyle(
                              fontSize: 11.5, color: textPri,
                              fontWeight: FontWeight.w300, height: 1.55,
                            ), maxLines: 3, overflow: TextOverflow.ellipsis),

                          const SizedBox(height: 14),

                          // Vent — sans bordure, fond léger
                          if (!loading)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: const Color(0xFF78909C).withOpacity(isDark ? 0.12 : 0.08),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.air_rounded,
                                      size: 10, color: const Color(0xFF78909C).withOpacity(0.80)),
                                  const SizedBox(width: 5),
                                  Text('${windSpeed.round()} km/h', style: TextStyle(
                                    fontSize: 10, fontWeight: FontWeight.w500,
                                    color: isDark ? Colors.white.withOpacity(0.75) : Colors.black.withOpacity(0.60),
                                    height: 1.0,
                                  )),
                                  const SizedBox(width: 3),
                                  Text('vent', style: TextStyle(
                                    fontSize: 8, fontWeight: FontWeight.w300,
                                    color: const Color(0xFF78909C).withOpacity(0.70),
                                    letterSpacing: 0.4,
                                  )),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FARM BANNER — élégant, sans bordure
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _farmBanner(bool isDark, Color primary, Color accent) {
    return GestureDetector(
      onTap: _navigateToFarmsTab,
      child: Container(
        height: 180,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF251608), const Color(0xFF160C04)]
                : [const Color(0xFF7A3514), const Color(0xFF3E1C08)],
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.24),
              blurRadius: 28, offset: const Offset(0, 12), spreadRadius: -6,
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(children: [
          // Grain
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _grainCtrl ?? const AlwaysStoppedAnimation(0),
              builder: (_, __) => CustomPaint(
                painter: _GrainPainter(
                  seed: (_grainCtrl?.value ?? 0) * 0.3,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          // Vague
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _waveCtrl ?? const AlwaysStoppedAnimation(0),
              builder: (_, __) => SizedBox(
                height: 80,
                child: CustomPaint(
                  painter: _WavePainter(
                    phase: (_waveCtrl?.value ?? 0) * 2 * pi + 2.5,
                    color: Colors.white.withOpacity(0.05),
                    yOffset: 0.38,
                  ),
                  size: Size(MediaQuery.of(context).size.width, 80),
                ),
              ),
            ),
          ),
          // Rings
          const Positioned(
            top: -60, right: -60,
            child: SizedBox(
              width: 220, height: 220,
              child: CustomPaint(painter: _RingsPainter(color: Colors.white)),
            ),
          ),
          // Contenu
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Tag('GESTION', bg: Colors.white.withOpacity(0.12), fg: Colors.white.withOpacity(0.85)),
                const Spacer(),

                // ✨ Micro-texte descriptif
                Text('VOS TERRES', style: TextStyle(
                  fontSize: 8, fontWeight: FontWeight.w400,
                  letterSpacing: 2.5, color: Colors.white.withOpacity(0.45),
                )),
                const SizedBox(height: 4),
                const Text('Mes Fermes', style: TextStyle(
                  fontSize: 26, fontWeight: FontWeight.w200,
                  color: Colors.white, height: 1.0, letterSpacing: -1.8,
                )),

                const SizedBox(height: 16),
                Row(children: [
                  // CTA principal
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.18),
                            blurRadius: 12, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Explorer', style: TextStyle(
                        fontSize: 12, fontWeight: FontWeight.w600,
                        color: AppColors.primary, letterSpacing: 0.2,
                      )),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 13, color: AppColors.primary),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  // Secondaire ghost
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text('Parcelles', style: TextStyle(
                      fontSize: 12, fontWeight: FontWeight.w300, color: Colors.white,
                    )),
                  ),
                ]),
              ],
            ),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TIP CARD — sans bordure, respiration maximale
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _tipCard(bool isDark, Color surface, Color border, Color primary,
      Color accent, Color textPri, Color textSec) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 360),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.05, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(_tipIdx),
        decoration: BoxDecoration(
          color: surface,
          // ✨ Ombre sans bordure
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withOpacity(0.22) : primary.withOpacity(0.05),
              blurRadius: 20, offset: const Offset(0, 6), spreadRadius: -2,
            ),
          ],
        ),
        child: Row(children: [
          // Bande accent gauche
          Container(
            width: 3, height: 70,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter, end: Alignment.bottomCenter,
                colors: [accent.withOpacity(0.25), accent, accent.withOpacity(0.25)],
              ),
              borderRadius: const BorderRadius.horizontal(left: Radius.circular(18)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 16, 0, 16),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.09),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.tips_and_updates_rounded, color: accent, size: 14),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 16, 8, 16),
              child: Text(_tips[_tipIdx], style: TextStyle(
                fontSize: 12, color: textPri,
                fontWeight: FontWeight.w300, height: 1.6,
              )),
            ),
          ),
          GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _tipIdx = (_tipIdx + 1) % _tips.length);
            },
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: primary.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(Icons.refresh_rounded, color: primary, size: 14),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEWS SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _newsSection(bool isDark, Color surface, Color border, Color primary,
      Color accent, Color textPri, Color textSec) {
    const filters = ['Local', 'National', 'International', 'Liens utiles'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(width: 24, height: 1, color: primary),
            const SizedBox(width: 8),
            Text('ACTUALITÉS', style: TextStyle(
              fontSize: 7.5, fontWeight: FontWeight.w500,
              letterSpacing: 2.8, color: textSec.withOpacity(0.5),
            )),
            const SizedBox(width: 8),
            Expanded(child: Container(height: 1, color: textSec.withOpacity(0.08))),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _filterOpen = !_filterOpen);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _filterOpen
                      ? primary.withOpacity(0.08)
                      : primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: [
                  Text(_selectedFilter, style: TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w400,
                    color: primary, letterSpacing: 1.2,
                  )),
                  const SizedBox(width: 3),
                  AnimatedRotation(
                    turns: _filterOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 240),
                    curve: Curves.easeOutCubic,
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: primary.withOpacity(0.6), size: 15),
                  ),
                ]),
              ),
            ),
          ],
        ),

        // Filter chips
        AnimatedSize(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          child: _filterOpen
              ? Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    child: Row(
                      children: filters.map((f) {
                        final sel = f == _selectedFilter;
                        return GestureDetector(
                          onTap: () => _changeFilter(f),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 180),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: sel ? primary : primary.withOpacity(0.05),
                              borderRadius: BorderRadius.circular(7),
                              boxShadow: sel ? [
                                BoxShadow(color: primary.withOpacity(0.18),
                                    blurRadius: 10, offset: const Offset(0, 3)),
                              ] : null,
                            ),
                            child: Text(f, style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: sel ? FontWeight.w500 : FontWeight.w300,
                              color: sel ? Colors.white : primary.withOpacity(0.60),
                              letterSpacing: 1.0,
                            )),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 18),

        // News list
        FutureBuilder<List<NewsArticle>>(
          future: _newsFuture,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Column(
                children: List.generate(3, (_) => const Padding(
                  padding: EdgeInsets.only(bottom: 14),
                  child: _Shimmer(width: double.infinity, height: 90, radius: 10),
                )),
              );
            }
            final articles = _filter(snap.data ?? []);
            if (articles.isEmpty) {
              return Container(
                height: 90,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: surface,
                ),
                child: Text('Aucune actualité disponible',
                    style: TextStyle(color: textSec, fontSize: 12, fontWeight: FontWeight.w300)),
              );
            }

            final double capturedDir = _filterDirection == 1 ? 1.0 : -1.0;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 360),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(capturedDir * 0.15, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Column(
                key: ValueKey(_newsKey),
                children: articles.map((article) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _newsCard(article, isDark, surface, border, primary, accent, textPri, textSec),
                )).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEWS CARD — sans bordure, shadow douce, respiration Zara
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _newsCard(NewsArticle article, bool isDark, Color surface, Color border,
      Color primary, Color accent, Color textPri, Color textSec) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => NewsDetailScreen(article: article)));
        },
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            // ✨ Ombre sans bordure — style Zara
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.20)
                    : Colors.black.withOpacity(0.04),
                blurRadius: 14,
                offset: const Offset(0, 3),
                spreadRadius: -2,
              ),
            ],
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
              // Accent bar gauche — fine et élégante
              Container(
                width: 2.5,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [accent.withOpacity(0.8), primary.withOpacity(0.2)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(14),
                    bottomLeft: Radius.circular(14),
                  ),
                ),
              ),
              // Contenu
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 14, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (article.category != null && article.category!.isNotEmpty) ...[
                        _NewsCategoryTag(article.category!),
                        const SizedBox(height: 7),
                      ],
                      Text(article.title,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w400,
                          color: textPri,
                          height: 1.45,
                          letterSpacing: 0.05,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 7),
                      Row(children: [
                        Expanded(
                          child: Text(article.source ?? 'Source',
                            style: TextStyle(
                              fontSize: 8.5, fontWeight: FontWeight.w300,
                              color: primary.withOpacity(0.65), letterSpacing: 0.2,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(article.timeAgo, style: TextStyle(
                          fontSize: 8.5, fontWeight: FontWeight.w300,
                          color: textSec.withOpacity(0.50),
                        )),
                      ]),
                    ],
                  ),
                ),
              ),
              // Chevron discret
              Padding(
                padding: const EdgeInsets.only(right: 14),
                child: Icon(Icons.chevron_right_rounded,
                    color: primary.withOpacity(0.35), size: 16),
              ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}