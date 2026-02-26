import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:provider/provider.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/services/weather_service.dart';
import 'package:mbaymi/models/news_model.dart';
import 'package:mbaymi/screens/news_detail_screen.dart';
import 'package:mbaymi/screens/farm_tab/farm_tab.dart';

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

/// NEW: Micro dot grid painter for card backgrounds
class _DotGridPainter extends CustomPainter {
  final Color color;
  final double spacing;
  const _DotGridPainter({required this.color, this.spacing = 18});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;
    for (double x = 0; x <= size.width; x += spacing) {
      for (double y = 0; y <= size.height; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.9, paint);
      }
    }
  }

  @override
  bool shouldRepaint(_DotGridPainter o) => false;
}

/// NEW: Diagonal lines texture
class _DiagonalPainter extends CustomPainter {
  final Color color;
  const _DiagonalPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;
    const step = 14.0;
    for (double i = -size.height; i <= size.width + size.height; i += step) {
      canvas.drawLine(Offset(i, 0), Offset(i + size.height, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(_DiagonalPainter o) => false;
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
// NEW: MINI SPARK CHART PAINTER
// ─────────────────────────────────────────────────────────────────────────────
class _SparkLinePainter extends CustomPainter {
  final List<double> data;
  final Color color;
  final Color fillColor;
  _SparkLinePainter({required this.data, required this.color, required this.fillColor});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final maxV = data.reduce(max);
    final minV = data.reduce(min);
    final range = maxV - minV == 0 ? 1 : maxV - minV;

    List<Offset> pts = [];
    for (int i = 0; i < data.length; i++) {
      final x = i / (data.length - 1) * size.width;
      final y = size.height - ((data[i] - minV) / range) * size.height;
      pts.add(Offset(x, y));
    }

    // Fill
    final fillPath = Path();
    fillPath.moveTo(pts.first.dx, size.height);
    for (final p in pts) fillPath.lineTo(p.dx, p.dy);
    fillPath.lineTo(pts.last.dx, size.height);
    fillPath.close();
    canvas.drawPath(fillPath, Paint()..color = fillColor..style = PaintingStyle.fill);

    // Line
    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final linePath = Path();
    linePath.moveTo(pts.first.dx, pts.first.dy);
    for (int i = 1; i < pts.length; i++) {
      final prev = pts[i - 1];
      final curr = pts[i];
      final cp1 = Offset((prev.dx + curr.dx) / 2, prev.dy);
      final cp2 = Offset((prev.dx + curr.dx) / 2, curr.dy);
      linePath.cubicTo(cp1.dx, cp1.dy, cp2.dx, cp2.dy, curr.dx, curr.dy);
    }
    canvas.drawPath(linePath, linePaint);

    // Dot at last point
    canvas.drawCircle(pts.last, 3.5, Paint()..color = color);
    canvas.drawCircle(pts.last, 2, Paint()..color = Colors.white);
  }

  @override
  bool shouldRepaint(_SparkLinePainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// NEW: FLOATING ACTION BUTTON custom
// ─────────────────────────────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});
  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}
class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))
      ..repeat(reverse: true);
  }
  @override
  void dispose() { _c.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: _c,
    builder: (_, __) => Container(
      width: 8, height: 8,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.color,
        boxShadow: [BoxShadow(
          color: widget.color.withOpacity(0.5 * _c.value),
          blurRadius: 6 * _c.value,
          spreadRadius: 2 * _c.value,
        )],
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// DASHBOARD TAB
// ─────────────────────────────────────────────────────────────────────────────
class DashboardTab extends StatefulWidget {
  final bool isDarkMode;
  final int? userId;
  const DashboardTab({super.key, this.isDarkMode = false, this.userId});
  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab>
    with TickerProviderStateMixin {
  // ── data ──────────────────────────────────────────────────────────────────
  String _selectedFilter = 'Local';
  late Future<Map<String, dynamic>> _countsFuture;
  late Future<Map<String, dynamic>> _weatherFuture;
  late Future<List<NewsArticle>>    _newsFuture;

  static final _gcCounts  = <String, Future<Map<String, dynamic>>>{};
  static final _gcWeather = <String, Future<Map<String, dynamic>>>{};
  static final _gcNews    = <String, Future<List<NewsArticle>>>{};

  // ── controllers ───────────────────────────────────────────────────────────
  AnimationController? _waveCtrl;
  AnimationController? _entryCtrl;
  AnimationController? _statsCtrl;
  AnimationController? _pulseCtrl;
  AnimationController? _grainCtrl;
  AnimationController? _quickActCtrl; // NEW

  // ── state ─────────────────────────────────────────────────────────────────
  bool _statsOpen        = false;
  bool _filterOpen       = false;
  bool _initialized      = false;
  bool _quickActOpen     = false; // NEW
  int  _selectedWeekDay  = DateTime.now().weekday - 1; // NEW — forecast selector

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
    'Faites tourner vos cultures chaque saison pour enrichir le sol.',
    'Testez le pH de votre sol avant chaque plantation.',
  ];

  // NEW: Mock weekly revenue sparkline data
  final _sparkData = <double>[42000.0, 38000.0, 56000.0, 61000.0, 48000.0, 72000.0, 65000.0];
  final _weekLabels = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

  final _rng        = Random();
  final _newsScroll = ScrollController();

  // NEW: Quick actions data
  late List<Map<String, dynamic>> _quickActions;

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _quickActions = [
      {'icon': Icons.add_circle_outline_rounded,  'label': 'Nouvelle\nFerme',   'color': AppColors.primary},
      {'icon': Icons.grass_rounded,               'label': 'Ajouter\nParcelle', 'color': AppColors.accent},
      {'icon': Icons.pets_rounded,                'label': 'Enregistrer\nAnimal','color': const Color(0xFF8B6914)},
      {'icon': Icons.bar_chart_rounded,           'label': 'Saisir\nRécolte',   'color': const Color(0xFF2A6B4A)},
    ];

    _waveCtrl      = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat();
    _pulseCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _grainCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 120))..repeat();
    _statsCtrl     = AnimationController(vsync: this, duration: const Duration(milliseconds: 420));
    _quickActCtrl  = AnimationController(vsync: this, duration: const Duration(milliseconds: 380));

    final ec = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800));
    _entryCtrl = ec;

    _fade = List.generate(9, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: ec,
        curve: Interval(i * 0.08, min(i * 0.08 + 0.50, 1.0), curve: Curves.easeOut)),
    ));
    _slide = List.generate(9, (i) =>
      Tween<Offset>(begin: const Offset(0, 0.16), end: Offset.zero).animate(
        CurvedAnimation(parent: ec,
          curve: Interval(i * 0.08, min(i * 0.08 + 0.50, 1.0), curve: Curves.easeOutCubic)),
      ));

    _countsFuture  = _getOrCreateCounts();
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
    _statsCtrl?.dispose();
    _pulseCtrl?.dispose();
    _grainCtrl?.dispose();
    _quickActCtrl?.dispose();
    _newsScroll.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────────────────
  Widget _s(int i, Widget child) {
    final f = _fade; final s = _slide;
    if (f == null || s == null || i >= f.length) return child;
    return FadeTransition(opacity: f[i],
      child: SlideTransition(position: s[i], child: child));
  }

  Future<Map<String, dynamic>> _loadWeather() => WeatherService.getWeather();

  Future<Map<String, dynamic>> _loadCounts() async {
    final r = <String, dynamic>{
      'farms': 0, 'livestock': 0, 'parcels': 0, 'harvests': 0, 'revenue': 0.0,
    };
    if (widget.userId == null) return r;
    try {
      final farms     = await ApiService.getUserFarms();
      final livestock = await ApiService.getUserLivestock(widget.userId!);
      r['farms']      = farms.length;
      r['livestock']  = livestock.length;
      final pl = await Future.wait(farms.map((f) => ApiService.getFarmCrops(f['id'] as int)));
      r['parcels'] = pl.fold<int>(0, (s, l) => s + l.length);
      final hl = await Future.wait(farms.map((f) => ApiService.getHarvestsForFarm(f['id'] as int)));
      r['harvests'] = hl.fold<int>(0, (s, l) => s + l.length);
      final sales = await ApiService.getSalesByUser(widget.userId!);
      double rev = 0;
      for (final s in sales) {
        final q = (s['quantity']       ?? 0) is int ? (s['quantity']       as int).toDouble() : (s['quantity']       ?? 0.0) as double;
        final p = (s['price_per_unit'] ?? 0) is int ? (s['price_per_unit'] as int).toDouble() : (s['price_per_unit'] ?? 0.0) as double;
        rev += q * p;
      }
      r['revenue'] = rev;
    } catch (_) {}
    return r;
  }

  Future<Map<String, dynamic>> _getOrCreateCounts() => _gcCounts['c'] ??= _loadCounts();
  Future<Map<String, dynamic>> _getOrCreateWeather() => _gcWeather['w'] ??= _loadWeather();
  Future<List<NewsArticle>>    _getOrCreateNews()    =>
      _gcNews['n_$_selectedFilter'] ??= ApiService.getAgriculturalNews();

  Future<void> _refresh() async {
    _gcCounts.clear(); _gcWeather.clear(); _gcNews.clear();
    _entryCtrl?.forward(from: 0);
    setState(() {
      _countsFuture  = _getOrCreateCounts();
      _weatherFuture = _getOrCreateWeather();
      _newsFuture    = _getOrCreateNews();
      _statsOpen     = false;
      _filterOpen    = false;
      _quickActOpen  = false;
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
    final warmBg  = isDark ? const Color(0xFF1A120A) : const Color(0xFFFFF8EE);

    return Scaffold(
      backgroundColor: bg,
      // ─── NEW: Floating Quick-Add Button ───────────────────────────────────
      floatingActionButton: _buildFAB(isDark, primary, accent, surface, border, textPri, textSec),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: primary,
        backgroundColor: surface,
        displacement: 36,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            SliverToBoxAdapter(child: _s(0, _hero(isDark, bg, primary, accent, textPri, textSec))),
            // NEW: Forecast strip
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _s(1, _forecastStrip(isDark, surface, border, primary, accent, textPri, textSec))),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _s(2, _weatherCard(isDark, surface, border, primary, accent, textPri, textSec))),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _s(3, _statsCard(isDark, surface, cardBg, border, primary, accent, textPri, textSec))),
            ),
            // NEW: Revenue + sparkline combined
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _s(4, _revenueCard(isDark, warmBg, border, primary, accent, textPri, textSec))),
            ),
            // NEW: Quick actions row
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _s(5, _quickActionsRow(isDark, surface, border, primary, accent, textPri, textSec))),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _s(6, _farmBanner(isDark, primary, accent))),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _s(7, _tipCard(isDark, surface, border, primary, accent, textPri, textSec))),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 14),
              sliver: SliverToBoxAdapter(
                child: _s(8, _newsSection(isDark, surface, cardBg, border, primary, accent, textPri, textSec))),
            ),
            const SliverPadding(padding: EdgeInsets.only(bottom: 100)),
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
      height: 238,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
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
          // NEW: Dot grid texture
          Positioned.fill(
            child: CustomPaint(
              painter: _DotGridPainter(
                color: primary.withOpacity(isDark ? 0.06 : 0.045),
              ),
            ),
          ),
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
          Positioned(
            top: -20, right: -50,
            child: SizedBox(
              width: 270, height: 270,
              child: CustomPaint(painter: _RingsPainter(color: primary)),
            ),
          ),
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
          // NEW: Secondary glow bottom-left
          Positioned(
            bottom: -60, left: -40,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  primary.withOpacity(isDark ? 0.12 : 0.08),
                  Colors.transparent,
                ]),
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
                    phase: (_waveCtrl?.value ?? 0) * 2 * pi,
                    color: primary.withOpacity(isDark ? 0.26 : 0.15),
                    yOffset: 0.50,
                  ),
                  size: Size(MediaQuery.of(context).size.width, 90),
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
                    phase: (_waveCtrl?.value ?? 0) * 2 * pi + 1.4,
                    color: primary.withOpacity(isDark ? 0.14 : 0.09),
                    yOffset: 0.68,
                  ),
                  size: Size(MediaQuery.of(context).size.width, 90),
                ),
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.fromLTRB(22, MediaQuery.of(context).padding.top + 14, 22, 32),
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
                    // NEW: Theme toggle pill
                    GestureDetector(
                      onTap: () {
                        HapticFeedback.selectionClick();
                        Provider.of<ThemeProvider>(context, listen: false).setDarkMode(!isDark);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: primary.withOpacity(0.10),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: primary.withOpacity(0.18)),
                        ),
                        child: Row(children: [
                          Icon(isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                              size: 11, color: primary.withOpacity(0.75)),
                          const SizedBox(width: 5),
                          Text(isDark ? 'Clair' : 'Sombre', style: TextStyle(
                            fontSize: 9, fontWeight: FontWeight.w600,
                            color: primary.withOpacity(0.75),
                          )),
                        ]),
                      ),
                    ),
                    const SizedBox(width: 8),
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
                  letterSpacing: 0.3,
                )),
                const SizedBox(height: 2),
                Text('Mon Espace', style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFFF2E8DC) : AppColors.textLight,
                  height: 1.0,
                  letterSpacing: -1.4,
                )),
                const SizedBox(height: 0),
                Text('Agricole', style: TextStyle(
                  fontSize: 38,
                  fontWeight: FontWeight.w200,
                  color: (isDark ? const Color(0xFFF2E8DC) : AppColors.textLight).withOpacity(0.38),
                  height: 1.0,
                  letterSpacing: -1.4,
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEW: FORECAST STRIP — 7-day horizontal scroll
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _forecastStrip(bool isDark, Color surface, Color border, Color primary,
      Color accent, Color textPri, Color textSec) {
    // Mock 7-day forecast — replace with real API data
    final forecasts = [
      {'day': 'Lun', 'icon': Icons.wb_sunny_rounded,        'high': 31, 'low': 22, 'rain': 0},
      {'day': 'Mar', 'icon': Icons.wb_cloudy_rounded,        'high': 28, 'low': 20, 'rain': 20},
      {'day': 'Mer', 'icon': Icons.grain_rounded,            'high': 25, 'low': 19, 'rain': 70},
      {'day': 'Jeu', 'icon': Icons.wb_sunny_rounded,        'high': 29, 'low': 21, 'rain': 5},
      {'day': 'Ven', 'icon': Icons.wb_sunny_rounded,        'high': 33, 'low': 23, 'rain': 0},
      {'day': 'Sam', 'icon': Icons.cloud_rounded,           'high': 27, 'low': 20, 'rain': 30},
      {'day': 'Dim', 'icon': Icons.wb_sunny_rounded,        'high': 32, 'low': 22, 'rain': 0},
    ];

    return SizedBox(
      height: 88,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: forecasts.length,
        itemBuilder: (_, i) {
          final f   = forecasts[i];
          final sel = i == _selectedWeekDay;
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() => _selectedWeekDay = i);
            },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 240),
              curve: Curves.easeOutCubic,
              margin: EdgeInsets.only(right: 8, top: sel ? 0 : 4, bottom: sel ? 0 : 4),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: sel ? primary : surface,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: sel ? primary : border,
                  width: sel ? 0 : 1,
                ),
                boxShadow: sel ? [
                  BoxShadow(color: primary.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4)),
                ] : null,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(f['day'] as String, style: TextStyle(
                    fontSize: 9, fontWeight: FontWeight.w600,
                    color: sel ? Colors.white.withOpacity(0.75) : textSec,
                    letterSpacing: 0.5,
                  )),
                  const SizedBox(height: 6),
                  Icon(f['icon'] as IconData, size: 18,
                    color: sel ? Colors.white : (f['rain'] as int) > 50 ? accent : primary,
                  ),
                  const SizedBox(height: 6),
                  Text('${f['high']}°', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w700,
                    color: sel ? Colors.white : textPri,
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // WEATHER CARD (enhanced with rain indicator)
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
        final rain   = (w['precipitation_sum'] as num?)?.toDouble() ?? 0.0; // NEW
        final advice = WeatherService.getWeatherAdvice(code, maxT);

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
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MÉTÉO DU JOUR', style: TextStyle(
                          fontSize: 7.5, fontWeight: FontWeight.w700,
                          letterSpacing: 2.0, color: textSec.withOpacity(0.7),
                        )),
                        const SizedBox(height: 8),
                        if (loading)
                          _Shimmer(width: 80, height: 52, radius: 8)
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('${maxT.round()}', style: TextStyle(
                                fontSize: 62, fontWeight: FontWeight.w800,
                                color: textPri, height: 0.9, letterSpacing: -3,
                              )),
                              Padding(
                                padding: const EdgeInsets.only(top: 6),
                                child: Text('°C', style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w300, color: accent,
                                )),
                              ),
                            ],
                          ),
                        const SizedBox(height: 6),
                        if (!loading) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: primary.withOpacity(0.07),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text('↓${minT.round()}°  ↑${maxT.round()}°',
                              style: TextStyle(fontSize: 9.5, color: textSec, fontWeight: FontWeight.w500)),
                          ),
                          const SizedBox(height: 6),
                          // NEW: Rain indicator
                          if (rain > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.10),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(children: [
                                Icon(Icons.water_drop_rounded, size: 10, color: Colors.blue.shade400),
                                const SizedBox(width: 4),
                                Text('${rain.toStringAsFixed(1)} mm', style: TextStyle(
                                  fontSize: 9.5, color: Colors.blue.shade400,
                                  fontWeight: FontWeight.w500,
                                )),
                              ]),
                            ),
                        ],
                      ],
                    ),
                    const SizedBox(width: 20),
                    Container(
                      width: 1, height: 80,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter, end: Alignment.bottomCenter,
                          colors: [Colors.transparent, border, Colors.transparent],
                        ),
                      ),
                    ),
                    const SizedBox(width: 20),
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
                              fontSize: 7.5, fontWeight: FontWeight.w700,
                              letterSpacing: 2.0, color: textSec.withOpacity(0.7),
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
                          const SizedBox(height: 12),
                          // NEW: Condition mini badges
                          if (!loading)
                            Wrap(spacing: 4, runSpacing: 4, children: [
                              _miniConditionBadge('Humidité 62%', Icons.water_outlined, primary),
                              _miniConditionBadge('Vent 12 km/h', Icons.air_rounded, primary),
                            ]),
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

  Widget _miniConditionBadge(String text, IconData icon, Color primary) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
    decoration: BoxDecoration(
      color: primary.withOpacity(0.06),
      borderRadius: BorderRadius.circular(5),
      border: Border.all(color: primary.withOpacity(0.10)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 9, color: primary.withOpacity(0.65)),
      const SizedBox(width: 3),
      Text(text, style: TextStyle(
        fontSize: 8.5, color: primary.withOpacity(0.65), fontWeight: FontWeight.w500,
      )),
    ]),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS CARD
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _statsCard(bool isDark, Color surface, Color cardBg, Color border,
      Color primary, Color accent, Color textPri, Color textSec) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _countsFuture,
      builder: (_, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final d = snap.data ?? {};

        return Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: border, width: 1),
            boxShadow: [
              BoxShadow(color: primary.withOpacity(isDark ? 0.06 : 0.04),
                  blurRadius: 16, offset: const Offset(0, 4)),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() => _statsOpen = !_statsOpen);
                if (_statsOpen) _statsCtrl?.forward(from: 0);
                else _statsCtrl?.reverse();
              },
              splashColor: primary.withOpacity(0.05),
              highlightColor: Colors.transparent,
              borderRadius: BorderRadius.circular(16),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(9),
                          decoration: BoxDecoration(
                            color: primary.withOpacity(0.10),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(Icons.bar_chart_rounded, color: primary, size: 16),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Statistiques', style: TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w600,
                              color: textPri, letterSpacing: -0.3,
                            )),
                            Text('Vue d\'ensemble de votre exploitation',
                              style: TextStyle(fontSize: 10, color: textSec)),
                          ],
                        ),
                        const Spacer(),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeOutCubic,
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _statsOpen
                                ? primary.withOpacity(0.12)
                                : primary.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: AnimatedRotation(
                            turns: _statsOpen ? 0.25 : 0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: Icon(Icons.chevron_right_rounded,
                                color: primary.withOpacity(0.7), size: 18),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 420),
                    curve: Curves.easeOutCubic,
                    child: _statsOpen
                        ? Container(
                            decoration: BoxDecoration(
                              color: cardBg,
                              border: Border(top: BorderSide(color: border, width: 1)),
                              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(16)),
                            ),
                            padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
                            child: loading
                                ? Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                                    children: List.generate(4, (_) =>
                                      _Shimmer(width: 56, height: 52, radius: 10)),
                                  )
                                : FadeTransition(
                                    opacity: CurvedAnimation(
                                      parent: _statsCtrl ?? const AlwaysStoppedAnimation(1),
                                      curve: Curves.easeOut,
                                    ),
                                    child: Row(children: [
                                      _statItem(Icons.agriculture_rounded, 'Fermes',    d['farms']     ?? 0, primary, accent, textPri, textSec),
                                      _statItem(Icons.pets_rounded,        'Animaux',   d['livestock'] ?? 0, primary, accent, textPri, textSec),
                                      _statItem(Icons.grass_rounded,       'Parcelles', d['parcels']   ?? 0, primary, accent, textPri, textSec),
                                      _statItem(Icons.grain_rounded,       'Récoltes',  d['harvests']  ?? 0, primary, accent, textPri, textSec),
                                    ]),
                                  ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _statItem(IconData icon, String label, int value,
      Color primary, Color accent, Color textPri, Color textSec) {
    return Expanded(
      child: Column(children: [
        Container(
          padding: const EdgeInsets.all(9),
          decoration: BoxDecoration(
            color: accent.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: accent, size: 16),
        ),
        const SizedBox(height: 8),
        _AnimCounter(
          value: value,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800,
              color: textPri, letterSpacing: -1.2, height: 1),
        ),
        const SizedBox(height: 3),
        Text(label, style: TextStyle(fontSize: 9.5, color: textSec, fontWeight: FontWeight.w500)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // REVENUE CARD — NEW: with sparkline chart + weekly total
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _revenueCard(bool isDark, Color warmBg, Color border, Color primary,
      Color accent, Color textPri, Color textSec) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _countsFuture,
      builder: (_, snap) {
        final loading = snap.connectionState == ConnectionState.waiting;
        final rev = (snap.data?['revenue'] as double?) ?? 0.0;
        final fmt = rev >= 1000000
            ? '${(rev / 1000000).toStringAsFixed(1)} M'
            : rev >= 1000
                ? '${(rev / 1000).toStringAsFixed(0)} K'
                : rev.toStringAsFixed(0);

        // Determine trend
        final lastTwo = _sparkData.length >= 2
            ? _sparkData[_sparkData.length - 1] - _sparkData[_sparkData.length - 2]
            : 0.0;
        final isUp = lastTwo >= 0;

        return Container(
          decoration: BoxDecoration(
            color: warmBg,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: primary.withOpacity(isDark ? 0.20 : 0.12), width: 1),
            boxShadow: [
              BoxShadow(color: primary.withOpacity(isDark ? 0.12 : 0.06),
                  blurRadius: 20, offset: const Offset(0, 6)),
            ],
          ),
          clipBehavior: Clip.hardEdge,
          child: Stack(children: [
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _grainCtrl ?? const AlwaysStoppedAnimation(0),
                builder: (_, __) => CustomPaint(
                  painter: _GrainPainter(
                    seed: (_grainCtrl?.value ?? 0) * 0.5,
                    color: primary,
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -40, right: -30,
              child: SizedBox(
                width: 200, height: 200,
                child: CustomPaint(painter: _RingsPainter(color: primary)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: accent.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.trending_up_rounded, color: accent, size: 14),
                    ),
                    const SizedBox(width: 8),
                    Text('REVENUS TOTAUX', style: TextStyle(
                      fontSize: 7.5, fontWeight: FontWeight.w700,
                      letterSpacing: 1.8,
                      color: isDark ? primary.withOpacity(0.60) : primary.withOpacity(0.65),
                    )),
                    const Spacer(),
                    // NEW: Trend badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: (isUp ? Colors.green : Colors.red).withOpacity(0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        Icon(
                          isUp ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded,
                          size: 10, color: isUp ? Colors.green.shade400 : Colors.red.shade400,
                        ),
                        const SizedBox(width: 3),
                        Text(isUp ? '+8.4%' : '-3.2%', style: TextStyle(
                          fontSize: 9, fontWeight: FontWeight.w700,
                          color: isUp ? Colors.green.shade400 : Colors.red.shade400,
                        )),
                      ]),
                    ),
                  ]),
                  const SizedBox(height: 12),
                  if (loading)
                    _Shimmer(width: 160, height: 44, radius: 8)
                  else
                    RichText(
                      text: TextSpan(children: [
                        TextSpan(
                          text: fmt,
                          style: TextStyle(
                            fontSize: 48, fontWeight: FontWeight.w800,
                            color: textPri, letterSpacing: -2.5, height: 1,
                          ),
                        ),
                        TextSpan(
                          text: '  FCFA',
                          style: TextStyle(
                            fontSize: 13, fontWeight: FontWeight.w400,
                            color: textSec, letterSpacing: 0.5,
                          ),
                        ),
                      ]),
                    ),
                  const SizedBox(height: 16),
                  // NEW: Sparkline with day labels
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('7 derniers jours', style: TextStyle(
                        fontSize: 8.5, color: textSec.withOpacity(0.6),
                        fontWeight: FontWeight.w500, letterSpacing: 0.5,
                      )),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 50,
                        child: CustomPaint(
                          painter: _SparkLinePainter(
                            data: _sparkData,
                            color: accent,
                            fillColor: accent.withOpacity(0.12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: _weekLabels.map((l) => Text(l, style: TextStyle(
                          fontSize: 8, color: textSec.withOpacity(0.55), fontWeight: FontWeight.w500,
                        ))).toList(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ]),
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEW: QUICK ACTIONS ROW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _quickActionsRow(bool isDark, Color surface, Color border, Color primary,
      Color accent, Color textPri, Color textSec) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Actions rapides', style: TextStyle(
          fontSize: 13, fontWeight: FontWeight.w600,
          color: textSec, letterSpacing: -0.2,
        )),
        const SizedBox(height: 10),
        Row(
          children: _quickActions.asMap().entries.map((e) {
            final i    = e.key;
            final item = e.value;
            return Expanded(
              child: GestureDetector(
                onTap: () => HapticFeedback.lightImpact(),
                child: AnimatedContainer(
                  duration: Duration(milliseconds: 200 + i * 50),
                  curve: Curves.easeOutCubic,
                  margin: EdgeInsets.only(right: i < _quickActions.length - 1 ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: border, width: 1),
                  ),
                  child: Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: (item['color'] as Color).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(item['icon'] as IconData,
                          color: item['color'] as Color, size: 16),
                      ),
                      const SizedBox(height: 7),
                      Text(item['label'] as String, style: TextStyle(
                        fontSize: 9, fontWeight: FontWeight.w600,
                        color: textSec, height: 1.3,
                      ), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // FARM BANNER
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _farmBanner(bool isDark, Color primary, Color accent) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(context, PageRouteBuilder(
          pageBuilder: (_, a, __) => FarmTab(userId: widget.userId, initialSection: 0),
          transitionsBuilder: (_, a, __, child) => FadeTransition(opacity: a, child: child),
        ));
      },
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
          // NEW: diagonal lines texture on banner
          Positioned.fill(
            child: CustomPaint(
              painter: _DiagonalPainter(color: Colors.white.withOpacity(0.035)),
            ),
          ),
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
                Row(children: [
                  _Tag('GESTION',
                    bg: Colors.white.withOpacity(0.14),
                    fg: Colors.white.withOpacity(0.90)),
                  const Spacer(),
                  // NEW: live indicator
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.white.withOpacity(0.20)),
                    ),
                    child: Row(children: [
                      _PulsingDot(color: Colors.greenAccent.shade200),
                      const SizedBox(width: 5),
                      Text('EN LIGNE', style: TextStyle(
                        fontSize: 8, fontWeight: FontWeight.w700,
                        color: Colors.white.withOpacity(0.80), letterSpacing: 1.2,
                      )),
                    ]),
                  ),
                ]),
                const Spacer(),
                const Text('Mes Fermes', style: TextStyle(
                  fontSize: 34, fontWeight: FontWeight.w800,
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
  // TIP CARD
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
        child: Row(children: [
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // NEW: tip counter
                  Text('CONSEIL DU JOUR — ${_tipIdx + 1}/${_tips.length}', style: TextStyle(
                    fontSize: 7.5, fontWeight: FontWeight.w700,
                    letterSpacing: 1.5, color: accent.withOpacity(0.7),
                  )),
                  const SizedBox(height: 5),
                  Text(_tips[_tipIdx], style: TextStyle(
                    fontSize: 12.5, color: textPri,
                    fontWeight: FontWeight.w400, height: 1.55,
                  )),
                ],
              ),
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
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEWS SECTION
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _newsSection(bool isDark, Color surface, Color cardBg, Color border,
      Color primary, Color accent, Color textPri, Color textSec) {
    const filters = ['Local', 'National', 'International', 'Liens utiles'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('ACTUALITÉSS', style: TextStyle(
                fontSize: 8, fontWeight: FontWeight.w700,
                letterSpacing: 2.5, color: textSec.withOpacity(0.6),
              )),
              const SizedBox(height: 4),
              Text('Dernières nouvelles', style: TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700,
                color: textPri, letterSpacing: -0.7, height: 1,
              )),
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
                    fontSize: 11, fontWeight: FontWeight.w600, color: primary,
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
                          onTap: () {
                            HapticFeedback.selectionClick();
                            setState(() {
                              _selectedFilter = f;
                              _filterOpen     = false;
                              _gcNews.clear();
                              _newsFuture = _getOrCreateNews();
                            });
                          },
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
                              fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                              color: sel ? Colors.white : primary.withOpacity(0.65),
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
        FutureBuilder<List<NewsArticle>>(
          future: _newsFuture,
          builder: (_, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 296,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.zero,
                  itemCount: 3,
                  itemBuilder: (_, __) => Padding(
                    padding: const EdgeInsets.only(right: 12),
                    child: _Shimmer(width: 210, height: 296, radius: 14),
                  ),
                ),
              );
            }
            final articles = _filter(snap.data ?? []);
            if (articles.isEmpty) {
              return Container(
                height: 100,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: border),
                ),
                child: Text('Aucune actualité disponible',
                    style: TextStyle(color: textSec, fontSize: 13)),
              );
            }
            return SizedBox(
              height: 296,
              child: ListView.builder(
                controller: _newsScroll,
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.zero,
                physics: const BouncingScrollPhysics(),
                itemCount: articles.length,
                itemBuilder: (_, i) => Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: _newsCard(articles[i], isDark, surface, border,
                      primary, accent, textPri, textSec),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEWS CARD — enhanced with category badge & reading time
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _newsCard(NewsArticle article, bool isDark, Color surface, Color border,
      Color primary, Color accent, Color textPri, Color textSec) {
    // NEW: Estimate reading time (mock)
    final readMin = 2 + (article.title.length ~/ 40);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(context,
            MaterialPageRoute(builder: (_) => NewsDetailScreen(article: article)));
      },
      child: Container(
        width: 210, height: 296,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: border, width: 1),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(isDark ? 0.22 : 0.06),
                blurRadius: 16, offset: const Offset(0, 6)),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 150, width: double.infinity,
              child: Stack(fit: StackFit.expand, children: [
                const Image(
                  image: AssetImage('assets/images/d.jpg'),
                  fit: BoxFit.cover,
                ),
                // NEW: Category badge on image
                Positioned(
                  top: 10, left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: primary.withOpacity(0.85),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      (article.category ?? 'Agri').toUpperCase(),
                      style: const TextStyle(
                        fontSize: 7.5, fontWeight: FontWeight.w800,
                        color: Colors.white, letterSpacing: 1.2,
                      ),
                    ),
                  ),
                ),
                // NEW: Reading time badge
                Positioned(
                  top: 10, right: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.50),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.access_time_rounded, size: 8, color: Colors.white70),
                      const SizedBox(width: 3),
                      Text('${readMin} min', style: const TextStyle(
                        fontSize: 8, color: Colors.white70, fontWeight: FontWeight.w500,
                      )),
                    ]),
                  ),
                ),
                Positioned(
                  bottom: 0, left: 0, right: 0, height: 60,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter, end: Alignment.topCenter,
                        colors: [surface, Colors.transparent],
                      ),
                    ),
                  ),
                ),
              ]),
            ),
            Container(
              height: 2.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [accent, primary.withOpacity(0)],
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(article.title, style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600,
                        color: textPri, height: 1.35, letterSpacing: -0.2,
                      ), maxLines: 3, overflow: TextOverflow.ellipsis),
                    ),
                    const SizedBox(height: 8),
                    Row(children: [
                      Container(
                        width: 5, height: 5,
                        decoration: BoxDecoration(color: accent, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(article.source ?? '', style: TextStyle(
                          fontSize: 9, color: primary.withOpacity(0.75),
                          fontWeight: FontWeight.w600, letterSpacing: 0.3,
                        ), overflow: TextOverflow.ellipsis),
                      ),
                      Text(article.timeAgo, style: TextStyle(
                        fontSize: 9, color: textSec.withOpacity(0.7),
                      )),
                    ]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEW: FLOATING ACTION BUTTON (speed dial style)
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _buildFAB(bool isDark, Color primary, Color accent,
      Color surface, Color border, Color textPri, Color textSec) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        // Mini actions
        AnimatedSize(
          duration: const Duration(milliseconds: 320),
          curve: Curves.easeOutCubic,
          child: _quickActOpen
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    _fabMiniAction('Nouvelle ferme',  Icons.agriculture_rounded, primary, isDark),
                    const SizedBox(height: 8),
                    _fabMiniAction('Ajouter animal',   Icons.pets_rounded,       accent,  isDark),
                    const SizedBox(height: 8),
                    _fabMiniAction('Saisir récolte',   Icons.grain_rounded,      const Color(0xFF2A6B4A), isDark),
                    const SizedBox(height: 12),
                  ],
                )
              : const SizedBox.shrink(),
        ),
        // Main FAB
        GestureDetector(
          onTap: () {
            HapticFeedback.mediumImpact();
            setState(() => _quickActOpen = !_quickActOpen);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _quickActOpen ? accent : primary,
              borderRadius: BorderRadius.circular(15),
              boxShadow: [
                BoxShadow(
                  color: (_quickActOpen ? accent : primary).withOpacity(0.38),
                  blurRadius: 16, offset: const Offset(0, 6),
                ),
              ],
            ),
            child: AnimatedRotation(
              turns: _quickActOpen ? 0.125 : 0,
              duration: const Duration(milliseconds: 280),
              curve: Curves.easeOutCubic,
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 26),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fabMiniAction(String label, IconData icon, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1C1410) : Colors.white,
            borderRadius: BorderRadius.circular(10),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 10, offset: const Offset(0, 3)),
            ],
          ),
          child: Text(label, style: TextStyle(
            fontSize: 12, fontWeight: FontWeight.w600, color: color,
          )),
        ),
        const SizedBox(width: 8),
        Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.withOpacity(0.20)),
          ),
          child: Icon(icon, color: color, size: 17),
        ),
      ],
    );
  }
}