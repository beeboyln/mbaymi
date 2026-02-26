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

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

/// Grain/noise texture — chaleur organique
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

/// Soft wave — ondulation terrain naturel
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

/// Cercles concentriques — anneaux de croissance
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

  // ── controllers (nullable — safe dispose) ─────────────────────────────────
  AnimationController? _waveCtrl;
  AnimationController? _entryCtrl;
  AnimationController? _pulseCtrl;
  AnimationController? _grainCtrl;

  // ── state ─────────────────────────────────────────────────────────────────
  bool _filterOpen   = false;
  bool _initialized  = false;

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

  final _rng = Random();

  // ─────────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();

    _waveCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 8))..repeat(reverse: true);
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1800))..repeat(reverse: true);
    _grainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120))..repeat();

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

  /// Navigate to Farms Tab using callback from HomeScreen
  void _navigateToFarmsTab() {
    HapticFeedback.mediumImpact();
    if (widget.onNavigateToFarmTab != null) {
      widget.onNavigateToFarmTab!();
    }
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
  // HERO
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
                const SizedBox(height: 2),
                Text('Mon Espace', style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w100,
                  color: isDark ? const Color(0xFFF2E8DC) : AppColors.textLight,
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
  // WEATHER CARD
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
                    // Température
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('MÉTÉO DU JOUR', style: TextStyle(
                          fontSize: 7.5, fontWeight: FontWeight.w500,
                          letterSpacing: 2.8, color: textSec.withOpacity(0.7),
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
                    const SizedBox(width: 20),
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
                    const SizedBox(width: 20),
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
                              fontFamily: 'Roboto',
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
                              fontFamily: 'Roboto',
                            ), maxLines: 3, overflow: TextOverflow.ellipsis),
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
  // FARM BANNER
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
          // Rings
          Positioned(
            top: -50, right: -50,
            child: SizedBox(
              width: 240, height: 240,
              child: CustomPaint(painter: _RingsPainter(color: Colors.white)),
            ),
          ),
          // Contenu
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
                      fontFamily: 'Roboto',
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
                    fontFamily: 'Roboto', letterSpacing: 1.5,
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
                              fontWeight: sel ? FontWeight.w500 : FontWeight.w400,
                              color: sel ? Colors.white : primary.withOpacity(0.65),
                              fontFamily: 'Roboto', letterSpacing: 1.2,
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

        // News List
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
            return Column(
              children: articles.map((article) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _newsCard(article, isDark, surface, border,
                    primary, accent, textPri, textSec),
              )).toList(),
            );
          },
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // NEWS CARD
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
              Expanded(
                flex: 0,
                child: Container(
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
              ),
              // Content
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(article.title,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: textPri,
                          height: 1.4,
                          letterSpacing: 0.1,
                          fontFamily: 'Roboto',
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
                                fontFamily: 'Roboto',
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(article.timeAgo,
                            style: TextStyle(
                              fontSize: 8.5,
                              color: textSec.withOpacity(0.6),
                              fontFamily: 'Roboto',
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