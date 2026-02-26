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
    for (int i = 0; i < 320; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 1.1 + 0.2;
      final op = rng.nextDouble() * 0.055 + 0.008;
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
    path.lineTo(0, baseY + 12 * sin(phase));
    for (double x = 0; x <= size.width; x += 2) {
      final y = baseY
          + 14 * sin(x / size.width * 2 * pi + phase)
          + 7  * sin(x / size.width * 4 * pi - phase * 1.3)
          + 4  * cos(x / size.width * 6 * pi + phase * 0.7);
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
      ..strokeWidth = 0.8;
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;
    for (int i = 1; i <= 7; i++) {
      paint.color = color.withOpacity(0.03 + i * 0.007);
      canvas.drawCircle(Offset(cx, cy), i * 36.0, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// CONDITION PILL — humidité, vent, UV
// ─────────────────────────────────────────────────────────────────────────────
class _CondPill extends StatelessWidget {
  final IconData icon;
  final String label;
  final String sublabel;
  final Color color;
  final bool isDark;

  const _CondPill({
    required this.icon,
    required this.label,
    required this.sublabel,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.10 : 0.07),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.18), width: 0.8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color.withOpacity(0.85)),
          const SizedBox(width: 5),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label, style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white.withOpacity(0.82) : Colors.black.withOpacity(0.72),
                height: 1.1,
              )),
              Text(sublabel, style: TextStyle(
                fontSize: 7.5,
                fontWeight: FontWeight.w400,
                color: color.withOpacity(0.75),
                letterSpacing: 0.3,
                height: 1.2,
              )),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ✨ MINIMAL WEATHER BADGE — discret, juste un symbole + glow subtil
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
    final glowOpacity = 0.08 + 0.06 * phase;
    final iconColor = _glowColor;
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: iconColor.withOpacity(isDark ? glowOpacity * 1.6 : glowOpacity * 1.1),
        border: Border.all(color: iconColor.withOpacity(0.20), width: 1),
      ),
      child: Center(
        child: Icon(
          _iconData,
          size: 22,
          color: iconColor.withOpacity(isDark ? 0.90 : 0.80),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMATED COUNTER
// ─────────────────────────────────────────────────────────────────────────────
class _AnimCounter extends StatefulWidget {
  final int value;
  final TextStyle style;
  const _AnimCounter({required this.value, required this.style});
  @override
  State<_AnimCounter> createState() => _AnimCounterState();
}
class _AnimCounterState extends State<_AnimCounter>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _a;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200));
    _a = CurvedAnimation(parent: _c, curve: Curves.easeOutExpo);
    _c.forward();
  }
  @override
  void didUpdateWidget(_AnimCounter old) {
    super.didUpdateWidget(old);
    if (old.value != widget.value) _c.forward(from: 0);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _a,
    builder: (_, __) => Text(
      '${(_a.value * widget.value).round()}',
      style: widget.style,
    ),
  );
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
class _ShimmerState extends State<_Shimmer>
    with SingleTickerProviderStateMixin {
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
// PILL TAG
// ─────────────────────────────────────────────────────────────────────────────
class _Tag extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;
  const _Tag(this.text, {required this.bg, required this.fg, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(
      horizontal: icon != null ? 8 : 10,
      vertical: 5,
    ),
    decoration: BoxDecoration(
      color: bg,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 9, color: fg),
          const SizedBox(width: 4),
        ],
        Text(text, style: TextStyle(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.4,
          color: fg,
        )),
      ],
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// ✨ NOUVEAU: NEWS CATEGORY TAG avec couleur par type
// ─────────────────────────────────────────────────────────────────────────────
class _NewsCategoryTag extends StatelessWidget {
  final String category;
  const _NewsCategoryTag(this.category);

  // Couleur + icône selon catégorie
  static _CategoryStyle _style(String cat) {
    final c = cat.toLowerCase();
    if (c.contains('local') || c.contains('senegal'))
      return _CategoryStyle(
        bg: const Color(0xFF2E7D32).withOpacity(0.15),
        fg: const Color(0xFF4CAF50),
        icon: Icons.location_on_rounded,
        label: 'LOCAL',
      );
    if (c.contains('international') || c.contains('world') || c.contains('global'))
      return _CategoryStyle(
        bg: const Color(0xFF1565C0).withOpacity(0.15),
        fg: const Color(0xFF42A5F5),
        icon: Icons.public_rounded,
        label: 'INTL',
      );
    if (c.contains('national'))
      return _CategoryStyle(
        bg: const Color(0xFFE65100).withOpacity(0.15),
        fg: const Color(0xFFFF7043),
        icon: Icons.flag_rounded,
        label: 'NATIONAL',
      );
    if (c.contains('marché') || c.contains('market') || c.contains('prix'))
      return _CategoryStyle(
        bg: const Color(0xFF6A1B9A).withOpacity(0.15),
        fg: const Color(0xFFCE93D8),
        icon: Icons.trending_up_rounded,
        label: 'MARCHÉ',
      );
    if (c.contains('meteo') || c.contains('climat'))
      return _CategoryStyle(
        bg: const Color(0xFF0277BD).withOpacity(0.15),
        fg: const Color(0xFF4FC3F7),
        icon: Icons.cloud_rounded,
        label: 'MÉTÉO',
      );
    // Défaut : Agri vert
    return _CategoryStyle(
      bg: const Color(0xFF558B2F).withOpacity(0.15),
      fg: const Color(0xFF8BC34A),
      icon: Icons.eco_rounded,
      label: 'AGRI',
    );
  }

  @override
  Widget build(BuildContext context) {
    final s = _style(category);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: s.bg,
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(s.icon, size: 8, color: s.fg),
          const SizedBox(width: 3),
          Text(s.label, style: TextStyle(
            fontSize: 7.5,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: s.fg,
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
// ✨ NOUVEAU: SCROLL INDICATOR (chevrons animés)
// ─────────────────────────────────────────────────────────────────────────────
class _ScrollIndicator extends StatefulWidget {
  final Color color;
  const _ScrollIndicator({required this.color});
  @override
  State<_ScrollIndicator> createState() => _ScrollIndicatorState();
}
class _ScrollIndicatorState extends State<_ScrollIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1000))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (_, __) => Column(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          final delay = i * 0.25;
          final t = (_c.value - delay).clamp(0.0, 1.0);
          return Opacity(
            opacity: 0.2 + 0.6 * t,
            child: Transform.translate(
              offset: Offset(0, -2 + 4 * t),
              child: Icon(
                Icons.keyboard_arrow_down_rounded,
                color: widget.color,
                size: 14,
              ),
            ),
          );
        }),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ILLUSTRATION HERO — silhouette agricole minimaliste (champ + feuille)
// ─────────────────────────────────────────────────────────────────────────────
class _AgriIllustrationPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final bool isDark;
  final double phase; // 0..1 pour la respiration subtile

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
    final baseOpacity = isDark ? 0.22 : 0.16;
    final accentOpacity = isDark ? 0.38 : 0.28;

    final fillPrimary = Paint()
      ..color = primary.withOpacity(baseOpacity)
      ..style = PaintingStyle.fill;
    final fillAccent = Paint()
      ..color = accent.withOpacity(accentOpacity)
      ..style = PaintingStyle.fill;
    final strokePrimary = Paint()
      ..color = primary.withOpacity(baseOpacity * 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // ── Sol / horizon ──────────────────────────────────────────────────────
    final groundPath = Path();
    groundPath.moveTo(0, h * 0.72);
    for (double x = 0; x <= w; x += 2) {
      final y = h * 0.72
          + 2.5 * sin(x / w * pi * 2 + phase * 0.4)
          + 1.2 * sin(x / w * pi * 5 - phase * 0.6);
      groundPath.lineTo(x, y);
    }
    groundPath.lineTo(w, h);
    groundPath.lineTo(0, h);
    groundPath.close();
    canvas.drawPath(groundPath, fillPrimary);

    // ── Sillons (rangées de culture) ───────────────────────────────────────
    for (int row = 0; row < 3; row++) {
      final yBase = h * (0.76 + row * 0.07);
      final rowPath = Path();
      rowPath.moveTo(w * 0.08, yBase);
      for (double x = w * 0.08; x <= w * 0.92; x += 2) {
        final y = yBase + 1.0 * sin((x / w * pi * 6) + phase * 0.3 + row * 0.8);
        rowPath.lineTo(x, y);
      }
      final rowPaint = Paint()
        ..color = primary.withOpacity(baseOpacity * 0.5)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 0.8;
      canvas.drawPath(rowPath, rowPaint);
    }

    // ── Tige centrale ──────────────────────────────────────────────────────
    final stemSway = 1.8 * sin(phase * 2 * pi);
    final stemPath = Path();
    stemPath.moveTo(w * 0.5, h * 0.72);
    stemPath.cubicTo(
      w * 0.5 + stemSway * 0.3, h * 0.55,
      w * 0.5 + stemSway, h * 0.40,
      w * 0.5 + stemSway, h * 0.28,
    );
    canvas.drawPath(stemPath, strokePrimary..strokeWidth = 1.4);

    // ── Grande feuille gauche ──────────────────────────────────────────────
    final leaf1 = Path();
    final lx = w * 0.5 + stemSway * 0.5;
    final ly = h * 0.46;
    leaf1.moveTo(lx, ly);
    leaf1.cubicTo(lx - w * 0.14, ly - h * 0.06, lx - w * 0.22, ly + h * 0.04, lx - w * 0.18, ly + h * 0.09);
    leaf1.cubicTo(lx - w * 0.10, ly + h * 0.06, lx - w * 0.04, ly + h * 0.02, lx, ly);
    canvas.drawPath(leaf1, fillAccent);
    // nervure
    final vein1 = Path();
    vein1.moveTo(lx, ly);
    vein1.quadraticBezierTo(lx - w * 0.11, ly + h * 0.03, lx - w * 0.18, ly + h * 0.09);
    canvas.drawPath(vein1, strokePrimary..strokeWidth = 0.6..color = accent.withOpacity(accentOpacity * 0.5));

    // ── Petite feuille droite ──────────────────────────────────────────────
    final leaf2 = Path();
    final rx = w * 0.5 + stemSway * 0.8;
    final ry = h * 0.36;
    leaf2.moveTo(rx, ry);
    leaf2.cubicTo(rx + w * 0.10, ry - h * 0.05, rx + w * 0.16, ry + h * 0.03, rx + w * 0.13, ry + h * 0.08);
    leaf2.cubicTo(rx + w * 0.06, ry + h * 0.05, rx + w * 0.02, ry + h * 0.01, rx, ry);
    canvas.drawPath(leaf2, fillAccent..color = accent.withOpacity(accentOpacity * 0.75));

    // ── Épi de céréale au sommet ───────────────────────────────────────────
    final grainX = w * 0.5 + stemSway;
    final grainY = h * 0.28;
    for (int g = 0; g < 5; g++) {
      final gy = grainY - g * h * 0.028;
      final gw = (5 - g) * w * 0.014 * (1 + 0.04 * sin(phase * 2 * pi + g));
      final grainPaint = Paint()
        ..color = primary.withOpacity(baseOpacity + g * 0.018)
        ..style = PaintingStyle.fill;
      // grain gauche
      canvas.drawOval(
        Rect.fromCenter(center: Offset(grainX - gw * 0.6, gy), width: gw * 0.9, height: h * 0.022),
        grainPaint,
      );
      // grain droit
      canvas.drawOval(
        Rect.fromCenter(center: Offset(grainX + gw * 0.6, gy), width: gw * 0.9, height: h * 0.022),
        grainPaint,
      );
    }
  }

  @override
  bool shouldRepaint(_AgriIllustrationPainter o) =>
      o.phase != phase || o.isDark != isDark;
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
  // ── data ──────────────────────────────────────────────────────────────────
  String _selectedFilter = 'Local';
  late Future<Map<String, dynamic>> _weatherFuture;
  late Future<List<NewsArticle>>    _newsFuture;

  static final _gcCounts  = <String, Future<Map<String, dynamic>>>{};
  static final _gcWeather = <String, Future<Map<String, dynamic>>>{};
  static final _gcNews    = <String, Future<List<NewsArticle>>>{};

  // ── controllers ───────────────────────────────────────────────────────────
  AnimationController? _waveCtrl;
  AnimationController? _entryCtrl;
  AnimationController? _pulseCtrl;
  AnimationController? _grainCtrl;
  // ✨ Nouveau: animation icône météo
  AnimationController? _weatherIconCtrl;
  // ✨ Nouveau: animation transition filtre news
  AnimationController? _filterSlideCtrl;

  // ── state ─────────────────────────────────────────────────────────────────
  bool _filterOpen   = false;
  bool _initialized  = false;
  // ✨ Direction du slide filtre news (-1 gauche, 1 droite)
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

  // ✨ Clé pour forcer le rebuild du contenu news avec slide
  String _newsKey = 'Local';

  final _rng = Random();

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _waveCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _grainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120))..repeat();

    // ✨ Icône météo — rotation lente continue
    _weatherIconCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // ✨ Slide transition filtre news
    _filterSlideCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );

    final ec = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600));
    _entryCtrl = ec;

    _fade = List.generate(5, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: ec,
        curve: Interval(i * 0.10, min(i * 0.10 + 0.50, 1.0), curve: Curves.easeOut)),
    ));
    _slide = List.generate(5, (i) =>
      Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero).animate(
        CurvedAnimation(parent: ec,
          curve: Interval(i * 0.10, min(i * 0.10 + 0.50, 1.0), curve: Curves.easeOutCubic)),
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
    _pulseCtrl?.dispose();
    _grainCtrl?.dispose();
    _weatherIconCtrl?.dispose();
    _filterSlideCtrl?.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  Widget _s(int i, Widget child) {
    final f = _fade; final s = _slide;
    if (f == null || s == null) return child;
    return FadeTransition(opacity: f[i],
      child: SlideTransition(position: s[i], child: child));
  }

  Future<Map<String, dynamic>> _loadWeather() => WeatherService.getWeather();

  Future<Map<String, dynamic>> _getOrCreateWeather() => _gcWeather['w'] ??= _loadWeather();
  Future<List<NewsArticle>>    _getOrCreateNews()    =>
      _gcNews['n_$_selectedFilter'] ??= ApiService.getAgriculturalNews();

  Future<void> _refresh() async {
    _gcCounts.clear(); _gcWeather.clear(); _gcNews.clear();
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
    if (widget.onNavigateToFarmTab != null) {
      widget.onNavigateToFarmTab!();
    }
  }

  // ✨ Changer le filtre avec slide horizontal animé
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
      _newsFuture = _getOrCreateNews();
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
    final surface = isDark ? AppColors.darkCardBg   : AppColors.lightBgAlt;
    final cardBg  = isDark ? AppColors.darkBgAlt    : const Color(0xFFFAF7F2);
    final border  = isDark ? AppColors.borderDark   : AppColors.borderLight;
    final primary = AppColors.primary;
    final accent  = AppColors.accent;
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
            SliverToBoxAdapter(child: _s(0, _hero(isDark, bg, primary, accent, textPri, textSec))),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _s(1, _weatherCard(isDark, surface, border, primary, accent, textPri, textSec))),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _s(2, _farmBanner(isDark, primary, accent))),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _s(3, _tipCard(isDark, surface, border, primary, accent, textPri, textSec))),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
              sliver: SliverToBoxAdapter(
                child: _s(4, _newsSection(isDark, surface, cardBg, border, primary, accent, textPri, textSec))),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // HERO  (+ scroll indicator en bas)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _hero(bool isDark, Color bg, Color primary, Color accent,
      Color textPri, Color textSec) {
    return SizedBox(
      height: 230,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Fond dégradé chaud
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: isDark
                      ? [const Color(0xFF1A100A), const Color(0xFF0F0A06)]
                      : [const Color(0xFFFFF3E0), const Color(0xFFEDE0C8)],
                ),
              ),
            ),
          ),

          // Grain organique
          Positioned.fill(
            child: AnimatedBuilder(
              animation: _grainCtrl ?? const AlwaysStoppedAnimation(0),
              builder: (_, __) => CustomPaint(
                painter: _GrainPainter(
                  seed: _grainCtrl?.value ?? 0,
                  color: primary,
                ),
              ),
            ),
          ),

          // Rings décoratifs
          Positioned(
            top: -20, right: -50,
            child: SizedBox(
              width: 270, height: 270,
              child: CustomPaint(painter: _RingsPainter(color: primary)),
            ),
          ),

          // Glow accent
          Positioned(
            top: -70, right: -70,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  accent.withOpacity(isDark ? 0.20 : 0.14),
                  Colors.transparent,
                ]),
              ),
            ),
          ),

          // ✨ Illustration agricole — silhouette champ + épi, focal point droit
          Positioned(
            right: 16, bottom: 20, top: 20,
            child: SizedBox(
              width: 130,
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
                height: 90,
                child: CustomPaint(
                  painter: _WavePainter(
                    phase: (_waveCtrl?.value ?? 0) * 2 * pi,
                    color: primary.withOpacity(isDark ? 0.26 : 0.15),
                    yOffset: 0.50,
                  ),
                  size: Size(MediaQuery.of(context).size.width, 90),
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
                height: 90,
                child: CustomPaint(
                  painter: _WavePainter(
                    phase: (_waveCtrl?.value ?? 0) * 2 * pi + 1.4,
                    color: primary.withOpacity(isDark ? 0.14 : 0.09),
                    yOffset: 0.68,
                  ),
                  size: Size(MediaQuery.of(context).size.width, 90),
                ),
              ),
            ),
          ),

          // Texte
          Padding(
            padding: EdgeInsets.fromLTRB(22, MediaQuery.of(context).padding.top + 14, 22, 36),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(_date(), style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                      color: primary.withOpacity(0.70),
                      letterSpacing: 0.2,
                    )),
                    const Spacer(),
                    _Tag('SAISON SÈCHE',
                      bg: primary.withOpacity(0.12),
                      fg: primary.withOpacity(0.85),
                      icon: Icons.wb_sunny_outlined,
                    ),
                  ],
                ),
                const Spacer(),
                Text('Bonjour,', style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: accent,
                  letterSpacing: 0.4,
                  fontFamily: 'Roboto',
                )),
                if (AuthService.isAuthenticated && AuthService.currentSession?.name != null) ...[
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          primary.withOpacity(0.15),
                          primary.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          AuthService.currentSession!.name.split(' ').first,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w300,
                            color: accent,
                            height: 1.0,
                            letterSpacing: -1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        if (AuthService.currentSession!.name.split(' ').length > 1)
                          Expanded(
                            child: Text(
                              AuthService.currentSession!.name.split(' ').skip(1).join(' '),
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                                color: isDark ? const Color(0xFFF2E8DC) : AppColors.textLight,
                                height: 1.2,
                                letterSpacing: -0.5,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),

        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WEATHER CARD  (+ icône météo animée)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _weatherCard(bool isDark, Color surface, Color border, Color primary,
      Color accent, Color textPri, Color textSec) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _weatherFuture,
      builder: (_, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final w      = snap.data ?? {};
        final maxT   = (w['max_temp'] as num?)?.toDouble() ?? 29;
        final minT   = (w['min_temp'] as num?)?.toDouble() ?? 21;
        final code   = (w['daily_weather_code'] as int?)   ?? 1;
        final advice = WeatherService.getWeatherAdvice(code, maxT);
        // Conditions du jour
        final humidity  = (w['humidity'] as num?)?.toInt()
            ?? (w['relative_humidity_2m'] as num?)?.toInt() ?? 45;
        final windSpeed = (w['wind_speed'] as num?)?.toDouble()
            ?? (w['wind_speed_10m_max'] as num?)?.toDouble() ?? 14.0;
        final uvIndex   = (w['uv_index'] as num?)?.toInt()
            ?? (w['uv_index_max'] as num?)?.toInt() ?? 7;

        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(
                color: primary.withOpacity(isDark ? 0.08 : 0.05),
                blurRadius: 20, offset: const Offset(0, 6),
              ),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Column(
            children: [
              // Bande colorée top
              Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    accent.withOpacity(0.75),
                    primary.withOpacity(0.45),
                    Colors.transparent,
                  ]),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ✨ NOUVEAU: Colonne gauche — icône météo animée + température
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MÉTÉO DU JOUR', style: TextStyle(
                          fontSize: 7.5, fontWeight: FontWeight.w500,
                          letterSpacing: 2.8, color: textSec.withOpacity(0.7),
                        )),
                        const SizedBox(height: 10),
                        if (loading)
                          _Shimmer(width: 100, height: 80, radius: 8)
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              // ✨ Badge météo minimal — discret, pas d'app météo !
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
                              const SizedBox(width: 12),
                              // Température
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text('${maxT.round()}', style: TextStyle(
                                        fontSize: 52, fontWeight: FontWeight.w800,
                                        color: textPri, height: 0.9, letterSpacing: -3,
                                      )),
                                      Padding(
                                        padding: const EdgeInsets.only(top: 5),
                                        child: Text('°C', style: TextStyle(
                                          fontSize: 16, fontWeight: FontWeight.w300, color: accent,
                                        )),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        const SizedBox(height: 6),
                        if (!loading)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('↓${minT.round()}°  ↑${maxT.round()}°',
                              style: TextStyle(fontSize: 9.5, color: textSec, fontWeight: FontWeight.w500)),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Séparateur
                    Container(
                      width: 1, height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, border, Colors.transparent],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    // Conseil
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: accent.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(Icons.eco_rounded, color: accent, size: 13),
                            ),
                            const SizedBox(width: 8),
                            Text('CONSEIL', style: TextStyle(
                              fontSize: 7.5, fontWeight: FontWeight.w500,
                              letterSpacing: 2.5, color: textSec.withOpacity(0.7),
                            )),
                          ]),
                          const SizedBox(height: 10),
                          if (loading)
                            Column(children: [
                              _Shimmer(width: double.infinity, height: 11, radius: 4),
                              const SizedBox(height: 6),
                              _Shimmer(width: 100, height: 11, radius: 4),
                            ])
                          else
                            Text(advice, style: TextStyle(
                              fontSize: 11, color: textPri,
                              fontWeight: FontWeight.w400, height: 1.5,
                            ), maxLines: 3, overflow: TextOverflow.ellipsis),

                          const SizedBox(height: 14),

                          // ─── Séparateur fin ───────────────────────────────
                          Container(
                            height: 1,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                border.withOpacity(0.0),
                                border,
                                border.withOpacity(0.0),
                              ]),
                            ),
                          ),

                          const SizedBox(height: 12),

                          // ─── Vent — donnée clé pour l'agriculteur ────────
                          if (!loading)
                            _CondPill(
                              icon: Icons.air_rounded,
                              label: '${windSpeed.round()} km/h',
                              sublabel: 'Vent',
                              color: const Color(0xFF78909C),
                              isDark: isDark,
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
  // FARM BANNER  (inchangé)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _farmBanner(bool isDark, Color primary, Color accent) {
    return GestureDetector(
      onTap: _navigateToFarmsTab,
      child: Container(
        height: 190,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF2A1A0A), const Color(0xFF1A0F06)]
                : [const Color(0xFF7B3A16), const Color(0xFF4A2008)],
          ),
          boxShadow: [
            BoxShadow(
              color: primary.withOpacity(0.28),
              blurRadius: 24, offset: const Offset(0, 10), spreadRadius: -4,
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Stack(children: [
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
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: _waveCtrl ?? const AlwaysStoppedAnimation(0),
              builder: (_, __) => SizedBox(
                height: 90,
                child: CustomPaint(
                  painter: _WavePainter(
                    phase: (_waveCtrl?.value ?? 0) * 2 * pi + 2.5,
                    color: Colors.white.withOpacity(0.06),
                    yOffset: 0.40,
                  ),
                  size: Size(MediaQuery.of(context).size.width, 90),
                ),
              ),
            ),
          ),
          Positioned(
            top: -50, right: -50,
            child: SizedBox(
              width: 240, height: 240,
              child: CustomPaint(painter: _RingsPainter(color: Colors.white)),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 20, 22, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Tag('GESTION',
                  bg: Colors.white.withOpacity(0.14),
                  fg: Colors.white.withOpacity(0.90)),
                const Spacer(),
                const Text('Mes Fermes', style: TextStyle(
                  fontSize: 24, fontWeight: FontWeight.w200,
                  color: Colors.white, height: 1.0, letterSpacing: -1.5,
                )),
                const SizedBox(height: 14),
                Row(children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.15),
                            blurRadius: 10, offset: const Offset(0, 4)),
                      ],
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Explorer', style: TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w700, color: primary,
                      )),
                      const SizedBox(width: 6),
                      Icon(Icons.arrow_forward_rounded, size: 14, color: primary),
                    ]),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.white.withOpacity(0.25), width: 1),
                    ),
                    child: const Text('Parcelles', style: TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w400, color: Colors.white,
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
  // TIP CARD  (+ compteur progression ✨)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _tipCard(bool isDark, Color surface, Color border, Color primary,
      Color accent, Color textPri, Color textSec) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 380),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.06, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: Container(
        key: ValueKey(_tipIdx),
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1),
        ),
        child: Column(
          children: [
            // Corps principal
            Row(children: [
              // Bande gauche
              Container(
                width: 4, height: 72,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter, end: Alignment.bottomCenter,
                    colors: [accent.withOpacity(0.3), accent, accent.withOpacity(0.3)],
                  ),
                  borderRadius: const BorderRadius.horizontal(left: Radius.circular(16)),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 16, 0, 16),
                child: Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: accent.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.tips_and_updates_rounded, color: accent, size: 16),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 16, 8, 16),
                  child: Text(_tips[_tipIdx], style: TextStyle(
                    fontSize: 12.5, color: textPri,
                    fontWeight: FontWeight.w400, height: 1.55,
                    fontFamily: 'Roboto',
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
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.07),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.refresh_rounded, color: primary, size: 15),
                  ),
                ),
              ),
            ]),

          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEWS SECTION  (+ slide horizontal + category tags ✨)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _newsSection(bool isDark, Color surface, Color cardBg, Color border,
      Color primary, Color accent, Color textPri, Color textSec) {
    const filters = ['Local', 'National', 'International', 'Liens utiles'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ACTUALITÉS', style: TextStyle(
                fontSize: 8, fontWeight: FontWeight.w500,
                letterSpacing: 2.5, color: textSec.withOpacity(0.6),
              )),
              const SizedBox(height: 4),
            ]),
            const Spacer(),
            GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _filterOpen = !_filterOpen);
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: _filterOpen ? primary.withOpacity(0.10) : Colors.transparent,
                  border: Border.all(color: primary.withOpacity(0.20), width: 1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(children: [
                  Text(_selectedFilter, style: TextStyle(
                    fontSize: 11, fontWeight: FontWeight.w400, color: primary,
                    letterSpacing: 1.5,
                  )),
                  const SizedBox(width: 4),
                  AnimatedRotation(
                    turns: _filterOpen ? 0.5 : 0,
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutCubic,
                    child: Icon(Icons.keyboard_arrow_down_rounded,
                        color: primary.withOpacity(0.7), size: 16),
                  ),
                ]),
              ),
            ),
          ],
        ),

        // Filter chips
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
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
                          onTap: () => _changeFilter(f),  // ✨ utilise la nouvelle méthode
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            margin: const EdgeInsets.only(right: 8),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
                            decoration: BoxDecoration(
                              color: sel ? primary : Colors.transparent,
                              border: Border.all(
                                color: sel ? primary : primary.withOpacity(0.20), width: 1),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: sel ? [
                                BoxShadow(color: primary.withOpacity(0.20),
                                    blurRadius: 10, offset: const Offset(0, 3)),
                              ] : null,
                            ),
                            child: Text(f, style: TextStyle(
                              fontSize: 12,
                              fontWeight: sel ? FontWeight.w500 : FontWeight.w400,
                              color: sel ? Colors.white : primary.withOpacity(0.65),
                              letterSpacing: 1.2,
                            )),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),

        const SizedBox(height: 16),

        // ✨ NOUVEAU: News list avec slide horizontal animé au changement de filtre
        FutureBuilder<List<NewsArticle>>(
          future: _newsFuture,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return Column(
                children: List.generate(3, (_) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _Shimmer(width: double.infinity, height: 96, radius: 8),
                )),
              );
            }
            final articles = _filter(snap.data ?? []);
            if (articles.isEmpty) {
              return Container(
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border),
                ),
                child: Text('Aucune actualité disponible',
                    style: TextStyle(color: textSec, fontSize: 13)),
              );
            }

            // ✨ AnimatedSwitcher avec slide horizontal selon direction filtre
            // On capture dir AVANT le builder pour éviter le crash Flutter Web DDC
            final double capturedDir = _filterDirection == 1 ? 1.0 : -1.0;
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 380),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              transitionBuilder: (child, anim) => SlideTransition(
                position: Tween<Offset>(
                  begin: Offset(capturedDir * 0.18, 0.0),
                  end: Offset.zero,
                ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Column(
                key: ValueKey(_newsKey),
                children: articles.map((article) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _newsCard(article, isDark, surface, border,
                      primary, accent, textPri, textSec),
                )).toList(),
              ),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEWS CARD  (+ category tag coloré ✨)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _newsCard(NewsArticle article, bool isDark, Color surface, Color border,
      Color primary, Color accent, Color textPri, Color textSec) {
    return Material(
      color: surface,
      child: InkWell(
        onTap: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (_) => NewsDetailScreen(article: article)));
        },
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: border, width: 0.8),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(isDark ? 0.12 : 0.04),
                  blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              // Accent bar
              Container(
                width: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [accent, primary.withOpacity(0.3)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(8),
                    bottomLeft: Radius.circular(8),
                  ),
                ),
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ✨ NOUVEAU: Category tag coloré en haut
                      if (article.category != null && article.category!.isNotEmpty) ...[
                        _NewsCategoryTag(article.category!),
                        const SizedBox(height: 6),
                      ],
                      Text(article.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: textPri,
                          height: 1.4,
                          letterSpacing: 0.1,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(
                            child: Text(article.source ?? 'Source',
                              style: TextStyle(
                                fontSize: 8.5,
                                fontWeight: FontWeight.w400,
                                color: primary.withOpacity(0.7),
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(article.timeAgo,
                            style: TextStyle(
                              fontSize: 8.5,
                              color: textSec.withOpacity(0.6),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              // Chevron
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: Icon(Icons.chevron_right_rounded,
                  color: primary.withOpacity(0.5), size: 18),
              ),
            ],
          ),
        ),
      ),
    );
  }
}