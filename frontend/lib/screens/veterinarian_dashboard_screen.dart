import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/edit_veterinarian_profile_screen.dart';
import 'package:mbaymi/models/veterinarian_model.dart';
import 'package:mbaymi/widgets/skeleton_loader.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS — grain + rings (same visual language as DashboardTab)
// ─────────────────────────────────────────────────────────────────────────────

class _VetGrainPainter extends CustomPainter {
  final double seed;
  final Color color;
  const _VetGrainPainter({required this.seed, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random((seed * 1000).toInt());
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 260; i++) {
      final x  = rng.nextDouble() * size.width;
      final y  = rng.nextDouble() * size.height;
      final r  = rng.nextDouble() * 0.85 + 0.2;
      final op = rng.nextDouble() * 0.038 + 0.005;
      paint.color = color.withOpacity(op);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_VetGrainPainter o) => o.seed != seed;
}

class _VetRingsPainter extends CustomPainter {
  final Color color;
  const _VetRingsPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;
    for (int i = 1; i <= 7; i++) {
      paint.color = color.withOpacity(0.022 + i * 0.004);
      canvas.drawCircle(Offset(cx, cy), i * 38.0, paint);
    }
  }

  @override
  bool shouldRepaint(_VetRingsPainter o) => false;
}

class _WavePainter extends CustomPainter {
  final double phase;
  final Color color;
  final double yOffset;
  const _WavePainter({required this.phase, required this.color, this.yOffset = 0.6});

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

// ─────────────────────────────────────────────────────────────────────────────
// VET ILLUSTRATION PAINTER — stethoscope + paw silhouette
// ─────────────────────────────────────────────────────────────────────────────
class _VetIllustrationPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final bool isDark;
  final double phase;

  const _VetIllustrationPainter({
    required this.primary,
    required this.accent,
    required this.isDark,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseOp   = isDark ? 0.18 : 0.13;
    final accentOp = isDark ? 0.32 : 0.24;

    final fillPrimary = Paint()
      ..color = primary.withOpacity(baseOp)
      ..style = PaintingStyle.fill;
    final fillAccent = Paint()
      ..color = accent.withOpacity(accentOp)
      ..style = PaintingStyle.fill;
    final strokePrimary = Paint()
      ..color = primary.withOpacity(baseOp * 0.75)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..strokeCap = StrokeCap.round;

    // Stethoscope tube
    final sway = 1.4 * sin(phase * 2 * pi);
    final tubePath = Path();
    tubePath.moveTo(w * 0.35, h * 0.20);
    tubePath.cubicTo(
      w * 0.18, h * 0.20,
      w * 0.12 + sway, h * 0.55,
      w * 0.30 + sway, h * 0.72,
    );
    tubePath.cubicTo(
      w * 0.45 + sway, h * 0.85,
      w * 0.62 + sway, h * 0.82,
      w * 0.72 + sway, h * 0.68,
    );
    canvas.drawPath(tubePath, strokePrimary..strokeWidth = 2.0);

    // Chest piece — circle
    canvas.drawCircle(
      Offset(w * 0.72 + sway, h * 0.64),
      w * 0.088,
      fillAccent,
    );
    canvas.drawCircle(
      Offset(w * 0.72 + sway, h * 0.64),
      w * 0.065,
      Paint()
        ..color = accent.withOpacity(accentOp * 0.45)
        ..style = PaintingStyle.fill,
    );

    // Earpiece left
    final ep1 = Path();
    ep1.moveTo(w * 0.35, h * 0.20);
    ep1.cubicTo(w * 0.34, h * 0.12, w * 0.28, h * 0.10, w * 0.26, h * 0.15);
    canvas.drawPath(ep1, strokePrimary..strokeWidth = 1.5);
    canvas.drawCircle(Offset(w * 0.26, h * 0.15), w * 0.030, fillPrimary);

    // Earpiece right
    final ep2 = Path();
    ep2.moveTo(w * 0.35, h * 0.20);
    ep2.cubicTo(w * 0.46, h * 0.14, w * 0.50, h * 0.10, w * 0.52, h * 0.16);
    canvas.drawPath(ep2, strokePrimary..strokeWidth = 1.5);
    canvas.drawCircle(Offset(w * 0.52, h * 0.16), w * 0.030, fillPrimary);

    // Paw print — 3 toe pads + main pad
    final pawX = w * 0.58;
    final pawY = h * 0.38 + sway * 0.4;
    final toes = [
      Offset(pawX - w * 0.10, pawY - h * 0.06),
      Offset(pawX,            pawY - h * 0.09),
      Offset(pawX + w * 0.10, pawY - h * 0.06),
    ];
    for (final t in toes) {
      canvas.drawOval(
        Rect.fromCenter(center: t, width: w * 0.07, height: h * 0.048),
        fillAccent..color = accent.withOpacity(accentOp * 0.80),
      );
    }
    canvas.drawOval(
      Rect.fromCenter(center: Offset(pawX, pawY + h * 0.01), width: w * 0.17, height: h * 0.12),
      fillAccent..color = accent.withOpacity(accentOp * 0.55),
    );

    // Cross / plus medical symbol
    final cx = w * 0.20;
    final cy = h * 0.78 + sway * 0.2;
    final cr = w * 0.055;
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: cr * 2.2, height: cr * 0.7), const Radius.circular(2)),
      fillPrimary..color = primary.withOpacity(baseOp * 0.70),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromCenter(center: Offset(cx, cy), width: cr * 0.7, height: cr * 2.2), const Radius.circular(2)),
      fillPrimary..color = primary.withOpacity(baseOp * 0.70),
    );
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
      Text(text, style: TextStyle(
        fontSize: 7, fontWeight: FontWeight.w600,
        letterSpacing: 1.8, color: fg,
      )),
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
    Container(width: 20, height: 1, color: primary),
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
// STAT CHIP
// ─────────────────────────────────────────────────────────────────────────────
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
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    decoration: BoxDecoration(
      color: surface,
      boxShadow: [BoxShadow(
        color: isDark ? Colors.black.withOpacity(0.22) : primary.withOpacity(0.06),
        blurRadius: 16, offset: const Offset(0, 5), spreadRadius: -2,
      )],
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.10),
          borderRadius: BorderRadius.circular(7),
        ),
        child: Icon(icon, color: accent, size: 13),
      ),
      const SizedBox(height: 10),
      Text(value, style: TextStyle(
        fontSize: 26, fontWeight: FontWeight.w700,
        color: textPri, letterSpacing: -1.5, height: 1.0,
      )),
      const SizedBox(height: 4),
      Text(label, style: TextStyle(
        fontSize: 8.5, fontWeight: FontWeight.w300,
        color: textSec.withOpacity(0.60), letterSpacing: 0.3,
      )),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// REQUEST ROW ITEM — minimaliste editorial
// ─────────────────────────────────────────────────────────────────────────────
class _RequestRow extends StatelessWidget {
  final dynamic request;
  final VoidCallback onTap;
  final Color primary;
  final Color accent;
  final Color surface;
  final Color textPri;
  final Color textSec;
  final bool isDark;

  const _RequestRow({
    required this.request, required this.onTap,
    required this.primary, required this.accent, required this.surface,
    required this.textPri, required this.textSec, required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final farmer = request['farmer'] as Map<String, dynamic>?;
    final farm   = request['farm']   as Map<String, dynamic>?;
    final reason = request['authorization_reason'] as String? ?? '';
    final farmerName = farmer?['name'] as String? ?? 'Agriculteur';
    final farmName   = farm?['name']   as String? ?? 'Bétail / Ferme';

    return GestureDetector(
      onTap: () { HapticFeedback.lightImpact(); onTap(); },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        decoration: BoxDecoration(
          color: surface,
          boxShadow: [BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.18) : Colors.black.withOpacity(0.04),
            blurRadius: 12, offset: const Offset(0, 3), spreadRadius: -2,
          )],
        ),
        child: IntrinsicHeight(
          child: Row(children: [
            // Accent bar
            Container(
              width: 2.5,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [accent.withOpacity(0.9), primary.withOpacity(0.25)],
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12), bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            // Avatar
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 12, 14),
              child: Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: accent.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.person_outline_rounded, color: accent, size: 20),
              ),
            ),
            // Text
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 14),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(farmerName, style: TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w500,
                    color: textPri, letterSpacing: -0.2,
                  )),
                  const SizedBox(height: 3),
                  Text(farmName, style: TextStyle(
                    fontSize: 10.5, fontWeight: FontWeight.w300,
                    color: primary.withOpacity(0.65),
                  )),
                  if (reason.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(reason, style: TextStyle(
                      fontSize: 10, color: textSec.withOpacity(0.55),
                      fontWeight: FontWeight.w300,
                    ), maxLines: 1, overflow: TextOverflow.ellipsis),
                  ],
                ]),
              ),
            ),
            // Badge + chevron
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 14, 14, 14),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF9800).withOpacity(0.12),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text('EN ATTENTE', style: TextStyle(
                      fontSize: 6.5, fontWeight: FontWeight.w700,
                      letterSpacing: 1.4, color: const Color(0xFFFF9800),
                    )),
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.chevron_right_rounded,
                      color: primary.withOpacity(0.30), size: 16),
                ],
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTHORIZATION CARD — visuelle et élégante
// ─────────────────────────────────────────────────────────────────────────────
class _AuthCard extends StatefulWidget {
  final dynamic authorization;
  final Color primary;
  final Color accent;
  final Color surface;
  final Color textPri;
  final Color textSec;
  final bool isDark;

  const _AuthCard({
    required this.authorization, required this.primary, required this.accent,
    required this.surface, required this.textPri, required this.textSec,
    required this.isDark,
  });

  @override
  State<_AuthCard> createState() => _AuthCardState();
}

class _AuthCardState extends State<_AuthCard> {
  List<dynamic> _livestocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final farmId   = widget.authorization['farm_id'] as int?;
    final farmer   = widget.authorization['farmer'] as Map<String, dynamic>?;
    final farmerId = farmer?['id'] as int?;
    if ((farmId == null || farmId == 0) && farmerId != null) {
      try {
        final ls = await ApiService.getUserLivestock(farmerId);
        if (mounted) setState(() { _livestocks = ls; _isLoading = false; });
      } catch (_) { if (mounted) setState(() => _isLoading = false); }
    } else {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final farm  = widget.authorization['farm'] as Map<String, dynamic>?;
    final farmId = widget.authorization['farm_id'] as int?;
    final isFarm = farmId != null && farmId > 0;

    final photos = isFarm ? ((farm?['photos'] as List?) ?? []) : [];
    final String? photoUrl = isFarm && photos.isNotEmpty
        ? photos[0]['image_url'] as String?
        : (!isFarm && _livestocks.isNotEmpty ? _livestocks[0]['image_url'] as String? : null);

    final String title = isFarm
        ? (farm?['name'] ?? 'Ferme sans nom')
        : (!isFarm && _livestocks.isNotEmpty
            ? '${_livestocks[0]['animal_type']} — ${_livestocks[0]['breed'] ?? 'Race'}'
            : 'Autorisation');
    final dynamic detailId = isFarm ? farmId : (!isFarm && _livestocks.isNotEmpty ? _livestocks[0]['id'] : null);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.surface,
        boxShadow: [BoxShadow(
          color: widget.isDark ? Colors.black.withOpacity(0.22) : Colors.black.withOpacity(0.04),
          blurRadius: 18, offset: const Offset(0, 5), spreadRadius: -3,
        )],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // Top accent line
        Container(
          height: 2,
          decoration: BoxDecoration(gradient: LinearGradient(colors: [
            Colors.green.withOpacity(0.7),
            widget.accent.withOpacity(0.30),
            Colors.transparent,
          ])),
        ),
        // Image
        SizedBox(
          height: 160,
          width: double.infinity,
          child: _isLoading
              ? Container(
                  color: widget.primary.withOpacity(0.04),
                  child: Center(child: SizedBox(
                    width: 24, height: 24,
                    child: CircularProgressIndicator(strokeWidth: 1.5,
                        valueColor: AlwaysStoppedAnimation(widget.accent)),
                  )),
                )
              : photoUrl != null
                  ? Image.network(photoUrl, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder(isFarm))
                  : _placeholder(isFarm),
        ),
        // Info row
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: TextStyle(
                fontSize: 14, fontWeight: FontWeight.w600,
                color: widget.textPri, letterSpacing: -0.3,
              ), maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text(isFarm ? 'Ferme' : 'Bétail', style: TextStyle(
                fontSize: 9, fontWeight: FontWeight.w300,
                color: widget.textSec.withOpacity(0.50), letterSpacing: 0.5,
              )),
            ])),
            // Accepted badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green.withOpacity(0.20)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 10),
                const SizedBox(width: 4),
                Text('ACCEPTÉE', style: TextStyle(
                  fontSize: 6.5, fontWeight: FontWeight.w700,
                  letterSpacing: 1.4, color: Colors.green.withOpacity(0.85),
                )),
              ]),
            ),
          ]),
        ),
        // View button
        if (detailId != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                if (isFarm) {
                  Navigator.pushNamed(context, '/farm-detail', arguments: detailId);
                } else {
                  Navigator.pushNamed(context, '/livestock-detail', arguments: detailId);
                }
              },
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 11),
                decoration: BoxDecoration(
                  color: widget.primary.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Voir le détail', style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w400,
                    color: widget.primary, letterSpacing: 0.8,
                  )),
                  const SizedBox(width: 6),
                  Icon(Icons.arrow_forward_rounded, size: 13, color: widget.primary.withOpacity(0.60)),
                ]),
              ),
            ),
          ),
      ]),
    );
  }

  Widget _placeholder(bool isFarm) => Container(
    color: widget.primary.withOpacity(0.05),
    child: Icon(
      isFarm ? Icons.agriculture_rounded : Icons.pets_rounded,
      color: widget.primary.withOpacity(0.22),
      size: 48,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// EMPTY STATE
// ─────────────────────────────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color primary;
  final Color accent;
  final Color textPri;
  final Color textSec;

  const _EmptyState({
    required this.icon, required this.title, required this.subtitle,
    required this.primary, required this.accent, required this.textPri, required this.textSec,
  });

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: accent.withOpacity(0.07),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: accent.withOpacity(0.45), size: 28),
      ),
      const SizedBox(height: 14),
      Text(title, style: TextStyle(
        fontSize: 14, fontWeight: FontWeight.w500,
        color: textPri.withOpacity(0.70), letterSpacing: -0.3,
      )),
      const SizedBox(height: 5),
      Text(subtitle, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w300,
        color: textSec.withOpacity(0.45),
      ), textAlign: TextAlign.center),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class VeterinarianDashboardScreen extends StatefulWidget {
  const VeterinarianDashboardScreen({super.key});

  @override
  State<VeterinarianDashboardScreen> createState() =>
      _VeterinarianDashboardScreenState();
}

class _VeterinarianDashboardScreenState
    extends State<VeterinarianDashboardScreen> with TickerProviderStateMixin {

  bool _isLoading = true;
  VeterinarianProfile? _profile;
  List<dynamic> _availableRequests     = [];
  List<dynamic> _acceptedAuthorizations = [];

  // Vet color palette — teal/emerald — distinct from agri orange
  static const Color _vetPrimary = Color(0xFF00695C);
  static const Color _vetAccent  = Color(0xFF80CBC4);

  late AnimationController _waveCtrl;
  late AnimationController _grainCtrl;
  late AnimationController _entryCtrl;
  List<Animation<double>>? _fade;
  List<Animation<Offset>>?  _slide;

  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _waveCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _grainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120))..repeat();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));

    _fade  = List.generate(6, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Interval(i * 0.08, min(i * 0.08 + 0.45, 1.0), curve: Curves.easeOut)),
    ));
    _slide = List.generate(6, (i) => Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryCtrl, curve: Interval(i * 0.08, min(i * 0.08 + 0.45, 1.0), curve: Curves.easeOutCubic)),
    ));

    _loadDashboard();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _grainCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _s(int i, Widget child) {
    final f = _fade; final s = _slide;
    if (f == null || s == null) return child;
    return FadeTransition(opacity: f[i], child: SlideTransition(position: s[i], child: child));
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);
    try {
      final profile = await ApiService.getVeterinarianProfile();
      if (profile == null) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/veterinarian-setup');
        return;
      }
      setState(() => _profile = profile);
      try {
        final req = await ApiService.getPendingAuthorizations();
        if (mounted) setState(() => _availableRequests = req);
      } catch (_) { if (mounted) setState(() => _availableRequests = []); }

      try {
        final acc = await ApiService.getAcceptedAuthorizations();
        if (mounted) setState(() => _acceptedAuthorizations = acc);
      } catch (_) { if (mounted) setState(() => _acceptedAuthorizations = []); }

    } catch (e) {
      if (e.toString().contains('404')) {
        if (mounted) Navigator.of(context).pushReplacementNamed('/veterinarian-setup');
        return;
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Erreur: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.all(16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
        _entryCtrl.forward(from: 0);
      }
    }
  }

  void _openRequestDetails(dynamic request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RequestDetailsSheet(
        request: request,
        onAuthorizationUpdated: _loadDashboard,
        primary: _vetPrimary,
        accent: _vetAccent,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Inspire des couleurs de edit_veterinarian_profile_screen
    final bg      = isDark ? const Color(0xFF060E0D) : const Color(0xFFF4FAF9);
    final surface = isDark ? const Color(0xFF0D1A18) : Colors.white;
    final textPri = isDark ? const Color(0xFFE0F2F1) : const Color(0xFF0D2420);
    final textSec = isDark ? const Color(0xFF80CBC4) : const Color(0xFF4A7A73);

    if (_isLoading) {
      return Scaffold(
        backgroundColor: bg,
        body: SkeletonPageLoader(isDarkMode: isDark, includeAppBar: true, cardCount: 4, backgroundColor: bg),
      );
    }

    if (_profile == null) {
      return _SetupProfileView(
        onCreateProfile: () => Navigator.of(context).pushNamed('/veterinarian-setup'),
        primary: _vetPrimary, accent: _vetAccent, isDark: isDark,
        textPri: textPri, textSec: textSec,
      );
    }

    return Scaffold(
      backgroundColor: bg,
      body: RefreshIndicator(
        onRefresh: _loadDashboard,
        color: _vetPrimary,
        backgroundColor: surface,
        displacement: 36,
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
          slivers: [
            // Hero Header
            SliverToBoxAdapter(
              child: _s(0, _hero(isDark, bg, textPri, textSec)),
            ),

            // Stats row
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _s(1, _statsRow(isDark, surface, textPri, textSec)),
              ),
            ),

            // Tab selector
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 28, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _s(2, _tabSelector(isDark, surface, textSec)),
              ),
            ),

            // Tab content
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
              sliver: SliverToBoxAdapter(
                child: _s(3, _tabContent(isDark, surface, textPri, textSec)),
              ),
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
  Widget _hero(bool isDark, Color bg, Color textPri, Color textSec) {
    return SizedBox(
      height: 230,
      child: Stack(clipBehavior: Clip.hardEdge, children: [
        // Background gradient
        Positioned.fill(
          child: Container(decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF0A1A18), const Color(0xFF051210)]
                  : [const Color(0xFFE8F5F3), const Color(0xFFD0EDEA)],
            ),
          )),
        ),
        // Grain
        Positioned.fill(child: AnimatedBuilder(
          animation: _grainCtrl,
          builder: (_, __) => CustomPaint(
            painter: _VetGrainPainter(seed: _grainCtrl.value, color: _vetPrimary),
          ),
        )),
        // Rings
        const Positioned(top: -40, right: -50, child: SizedBox(
          width: 280, height: 280,
          child: CustomPaint(painter: _VetRingsPainter(color: _vetPrimary)),
        )),
        // Glow
        Positioned(top: -70, right: -70, child: Container(
          width: 230, height: 230,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              _vetAccent.withOpacity(isDark ? 0.16 : 0.11),
              Colors.transparent,
            ]),
          ),
        )),
        // Illustration
        Positioned(right: 10, bottom: 10, top: 10, child: SizedBox(
          width: 130,
          child: AnimatedBuilder(
            animation: _waveCtrl,
            builder: (_, __) => CustomPaint(painter: _VetIllustrationPainter(
              primary: _vetPrimary, accent: _vetAccent,
              isDark: isDark, phase: _waveCtrl.value,
            )),
          ),
        )),
        // Waves
        Positioned(bottom: 0, left: 0, right: 0, child: AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, __) => SizedBox(height: 80, child: CustomPaint(
            painter: _WavePainter(
              phase: _waveCtrl.value * 2 * pi,
              color: _vetPrimary.withOpacity(isDark ? 0.20 : 0.11),
              yOffset: 0.48,
            ),
            size: Size(MediaQuery.of(context).size.width, 80),
          )),
        )),
        Positioned(bottom: 0, left: 0, right: 0, child: AnimatedBuilder(
          animation: _waveCtrl,
          builder: (_, __) => SizedBox(height: 80, child: CustomPaint(
            painter: _WavePainter(
              phase: _waveCtrl.value * 2 * pi + 1.6,
              color: _vetPrimary.withOpacity(isDark ? 0.10 : 0.06),
              yOffset: 0.66,
            ),
            size: Size(MediaQuery.of(context).size.width, 80),
          )),
        )),
        // Content
        Padding(
          padding: EdgeInsets.fromLTRB(22, MediaQuery.of(context).padding.top + 14, 22, 36),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              _Tag('VÉTÉRINAIRE',
                bg: _vetPrimary.withOpacity(0.12),
                fg: _vetPrimary.withOpacity(0.85),
                icon: Icons.medical_services_outlined,
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => const EditVeterinarianProfileScreen(),
                  )).then((_) => _loadDashboard());
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _vetPrimary.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.edit_outlined, color: _vetPrimary, size: 16),
                ),
              ),
            ]),
            const Spacer(),
            Text('Tableau de bord', style: TextStyle(
              fontSize: 10, fontWeight: FontWeight.w300,
              color: _vetAccent.withOpacity(0.80), letterSpacing: 1.5,
            )),
            const SizedBox(height: 4),
            Text(
              _profile?.name ?? 'Dr. Vétérinaire',
              style: TextStyle(
                fontSize: 24, fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFE0F2F1) : const Color(0xFF0D2420),
                letterSpacing: -1.2, height: 1.1,
              ),
            ),
            if (_profile!.specialty.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(_profile!.specialty, style: TextStyle(
                fontSize: 11, fontWeight: FontWeight.w300,
                color: _vetPrimary.withOpacity(0.70),
              )),
            ],
          ]),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS ROW
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _statsRow(bool isDark, Color surface, Color textPri, Color textSec) {
    return Row(children: [
      Expanded(child: _StatChip(
        label: 'Demandes',
        value: '${_availableRequests.length}',
        icon: Icons.inbox_outlined,
        primary: _vetPrimary, accent: _vetAccent,
        surface: surface, textPri: textPri, textSec: textSec, isDark: isDark,
      )),
      const SizedBox(width: 12),
      Expanded(child: _StatChip(
        label: 'Autorisations',
        value: '${_acceptedAuthorizations.length}',
        icon: Icons.verified_outlined,
        primary: _vetPrimary, accent: Colors.green,
        surface: surface, textPri: textPri, textSec: textSec, isDark: isDark,
      )),
      const SizedBox(width: 12),
      Expanded(child: _StatChip(
        label: 'Consultations',
        value: '0',
        icon: Icons.video_call_outlined,
        primary: _vetPrimary, accent: const Color(0xFF42A5F5),
        surface: surface, textPri: textPri, textSec: textSec, isDark: isDark,
      )),
    ]);
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB SELECTOR — custom pill style
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _tabSelector(bool isDark, Color surface, Color textSec) {
    final tabs = [
      (label: 'Demandes',    icon: Icons.inbox_outlined),
      (label: 'Autorisations', icon: Icons.verified_outlined),
      (label: 'Consultations', icon: Icons.video_call_outlined),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: _vetPrimary.withOpacity(isDark ? 0.08 : 0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: tabs.asMap().entries.map((e) {
          final sel = e.key == _selectedTab;
          return Expanded(child: GestureDetector(
            onTap: () { HapticFeedback.selectionClick(); setState(() => _selectedTab = e.key); },
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: sel ? _vetPrimary : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                boxShadow: sel ? [BoxShadow(
                  color: _vetPrimary.withOpacity(0.22),
                  blurRadius: 12, offset: const Offset(0, 3),
                )] : null,
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(e.value.icon, size: 14,
                    color: sel ? Colors.white : _vetPrimary.withOpacity(0.45)),
                const SizedBox(height: 3),
                Text(e.value.label, style: TextStyle(
                  fontSize: 9, fontWeight: sel ? FontWeight.w600 : FontWeight.w300,
                  color: sel ? Colors.white : _vetPrimary.withOpacity(0.55),
                  letterSpacing: 0.3,
                )),
              ]),
            ),
          ));
        }).toList(),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // TAB CONTENT
  // ═══════════════════════════════════════════════════════════════════════════
  Widget _tabContent(bool isDark, Color surface, Color textPri, Color textSec) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 300),
      transitionBuilder: (child, anim) => FadeTransition(
        opacity: anim,
        child: SlideTransition(
          position: Tween<Offset>(begin: const Offset(0.04, 0), end: Offset.zero)
              .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
          child: child,
        ),
      ),
      child: KeyedSubtree(
        key: ValueKey(_selectedTab),
        child: _selectedTab == 0
            ? _requestsContent(isDark, surface, textPri, textSec)
            : _selectedTab == 1
                ? _authorizationsContent(isDark, surface, textPri, textSec)
                : _consultationsContent(textPri, textSec),
      ),
    );
  }

  Widget _requestsContent(bool isDark, Color surface, Color textPri, Color textSec) {
    if (_availableRequests.isEmpty) {
      return SizedBox(height: 200, child: _EmptyState(
        icon: Icons.inbox_outlined, title: 'Aucune demande',
        subtitle: 'Les nouvelles demandes apparaîtront ici',
        primary: _vetPrimary, accent: _vetAccent, textPri: textPri, textSec: textSec,
      ));
    }
    return Column(children: [
      _SectionLabel('DEMANDES EN ATTENTE', primary: _vetPrimary, textSec: textSec),
      const SizedBox(height: 14),
      ..._availableRequests.map((r) => _RequestRow(
        request: r, onTap: () => _openRequestDetails(r),
        primary: _vetPrimary, accent: _vetAccent, surface: surface,
        textPri: textPri, textSec: textSec, isDark: isDark,
      )),
    ]);
  }

  Widget _authorizationsContent(bool isDark, Color surface, Color textPri, Color textSec) {
    if (_acceptedAuthorizations.isEmpty) {
      return SizedBox(height: 200, child: _EmptyState(
        icon: Icons.verified_outlined, title: 'Aucune autorisation',
        subtitle: 'Les accès accordés apparaîtront ici',
        primary: _vetPrimary, accent: _vetAccent, textPri: textPri, textSec: textSec,
      ));
    }
    return Column(children: [
      _SectionLabel('ACCÈS ACCORDÉS', primary: _vetPrimary, textSec: textSec),
      const SizedBox(height: 14),
      ..._acceptedAuthorizations.map((a) => _AuthCard(
        authorization: a, primary: _vetPrimary, accent: _vetAccent,
        surface: surface, textPri: textPri, textSec: textSec, isDark: isDark,
      )),
    ]);
  }

  Widget _consultationsContent(Color textPri, Color textSec) {
    return SizedBox(height: 200, child: _EmptyState(
      icon: Icons.video_call_outlined, title: 'Aucune consultation',
      subtitle: 'Vos consultations actives apparaîtront ici',
      primary: _vetPrimary, accent: _vetAccent, textPri: textPri, textSec: textSec,
    ));
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// SETUP PROFILE VIEW — style Zara
// ─────────────────────────────────────────────────────────────────────────────
class _SetupProfileView extends StatelessWidget {
  final VoidCallback onCreateProfile;
  final Color primary;
  final Color accent;
  final bool isDark;
  final Color textPri;
  final Color textSec;

  const _SetupProfileView({
    required this.onCreateProfile, required this.primary, required this.accent,
    required this.isDark, required this.textPri, required this.textSec,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF060E0D) : const Color(0xFFF4FAF9);
    return Scaffold(
      backgroundColor: bg,
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(36),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: primary.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.medical_services_outlined, size: 44, color: primary.withOpacity(0.45)),
            ),
            const SizedBox(height: 32),
            Text('PROFIL VÉTÉRINAIRE', style: TextStyle(
              fontSize: 8, fontWeight: FontWeight.w600,
              letterSpacing: 3.0, color: primary.withOpacity(0.50),
            )),
            const SizedBox(height: 12),
            Text('Créez votre profil', style: TextStyle(
              fontSize: 26, fontWeight: FontWeight.w300,
              color: textPri, letterSpacing: -1.5, height: 1.1,
            ), textAlign: TextAlign.center),
            const SizedBox(height: 14),
            Text(
              'Configurez votre profil pour commencer à recevoir des demandes de consultation.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13, color: textSec.withOpacity(0.70),
                fontWeight: FontWeight.w300, height: 1.6,
              ),
            ),
            const SizedBox(height: 36),
            GestureDetector(
              onTap: onCreateProfile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 16),
                decoration: BoxDecoration(
                  color: primary,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(
                    color: primary.withOpacity(0.28),
                    blurRadius: 20, offset: const Offset(0, 8),
                  )],
                ),
                child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text('Créer mon profil', style: const TextStyle(
                    fontSize: 14, fontWeight: FontWeight.w500,
                    color: Colors.white, letterSpacing: 0.3,
                  )),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 16),
                ]),
              ),
            ),
          ]),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// REQUEST DETAILS BOTTOM SHEET — élégant
// ─────────────────────────────────────────────────────────────────────────────
class _RequestDetailsSheet extends StatefulWidget {
  final dynamic request;
  final VoidCallback? onAuthorizationUpdated;
  final Color primary;
  final Color accent;

  const _RequestDetailsSheet({
    required this.request, this.onAuthorizationUpdated,
    required this.primary, required this.accent,
  });

  @override
  State<_RequestDetailsSheet> createState() => _RequestDetailsSheetState();
}

class _RequestDetailsSheetState extends State<_RequestDetailsSheet> {
  bool _isLoading = false;
  List<dynamic> _livestocks = [];

  @override
  void initState() {
    super.initState();
    _loadLivestocks();
  }

  Future<void> _loadLivestocks() async {
    final farmId   = widget.request['farm_id'] as int?;
    final farmer   = widget.request['farmer'] as Map<String, dynamic>?;
    final farmerId = farmer?['id'] as int?;
    if ((farmId == null || farmId == 0) && farmerId != null) {
      try {
        final ls = await ApiService.getUserLivestock(farmerId);
        if (mounted) setState(() => _livestocks = ls);
      } catch (_) {}
    }
  }

  Future<void> _accept() async {
    setState(() => _isLoading = true);
    try {
      final id = widget.request['id'] as int?;
      if (id == null) throw Exception('ID manquant');
      await ApiService.acceptAuthorization(id);
      if (mounted) {
        HapticFeedback.mediumImpact();
        widget.onAuthorizationUpdated?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  Future<void> _reject() async {
    setState(() => _isLoading = true);
    try {
      final id = widget.request['id'] as int?;
      if (id == null) throw Exception('ID manquant');
      await ApiService.rejectAuthorization(id);
      if (mounted) {
        HapticFeedback.lightImpact();
        widget.onAuthorizationUpdated?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    } finally { if (mounted) setState(() => _isLoading = false); }
  }

  @override
  Widget build(BuildContext context) {
    final theme  = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final surface = isDark ? const Color(0xFF0D1A18) : Colors.white;
    final textPri = isDark ? const Color(0xFFE0F2F1) : const Color(0xFF0D2420);
    final textSec = isDark ? const Color(0xFF80CBC4) : const Color(0xFF4A7A73);

    final farm    = widget.request['farm']   as Map<String, dynamic>?;
    final farmer  = widget.request['farmer'] as Map<String, dynamic>?;
    final farmId  = widget.request['farm_id'] as int?;
    final isFarm  = farmId != null && farmId > 0;
    final photos  = (farm?['photos'] as List?) ?? [];
    final crops   = (farm?['crops']  as List?) ?? [];
    final reason  = widget.request['authorization_reason'] ?? 'Non spécifiée';
    final farmerName = farmer?['name'] ?? 'Agriculteur';
    final farmName   = farm?['name']   ?? 'Ferme sans nom';

    return Container(
      decoration: BoxDecoration(
        color: surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24, right: 24, top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Handle
              Center(child: Container(
                width: 36, height: 3,
                decoration: BoxDecoration(
                  color: widget.primary.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(2),
                ),
              )),
              const SizedBox(height: 22),

              // Title
              Row(children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: widget.accent.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.assignment_outlined, color: widget.accent, size: 18),
                ),
                const SizedBox(width: 12),
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('DEMANDE D\'AUTORISATION', style: TextStyle(
                    fontSize: 7, fontWeight: FontWeight.w600,
                    letterSpacing: 2.2, color: widget.primary.withOpacity(0.50),
                  )),
                  const SizedBox(height: 3),
                  Text('Accès médical', style: TextStyle(
                    fontSize: 17, fontWeight: FontWeight.w500,
                    color: textPri, letterSpacing: -0.5,
                  )),
                ]),
              ]),
              const SizedBox(height: 24),

              // Info card
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: widget.primary.withOpacity(0.04),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: widget.primary.withOpacity(0.10)),
                ),
                child: Column(children: [
                  _InfoRow(label: 'Agriculteur', value: farmerName,
                      icon: Icons.person_outline, primary: widget.primary, textSec: textSec, textPri: textPri),
                  if (isFarm) ...[
                    Divider(height: 20, color: widget.primary.withOpacity(0.08)),
                    _InfoRow(label: 'Ferme', value: farmName,
                        icon: Icons.agriculture_outlined, primary: widget.primary, textSec: textSec, textPri: textPri),
                  ] else if (_livestocks.isNotEmpty) ...[
                    Divider(height: 20, color: widget.primary.withOpacity(0.08)),
                    _InfoRow(
                      label: 'Bétail',
                      value: '${_livestocks[0]['animal_type']} — ${_livestocks[0]['breed'] ?? 'Race'}',
                      icon: Icons.pets_outlined,
                      primary: widget.primary, textSec: textSec, textPri: textPri,
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 20),

              // Reason
              Text('RAISON', style: TextStyle(
                fontSize: 7, fontWeight: FontWeight.w600,
                letterSpacing: 2.2, color: textSec.withOpacity(0.50),
              )),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.accent.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(reason, style: TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w300,
                  color: textPri, height: 1.6,
                )),
              ),

              // Crops
              if (crops.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('CULTURES (${crops.length})', style: TextStyle(
                  fontSize: 7, fontWeight: FontWeight.w600,
                  letterSpacing: 2.2, color: textSec.withOpacity(0.50),
                )),
                const SizedBox(height: 10),
                ...crops.map((crop) => Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: widget.primary.withOpacity(0.04),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(children: [
                    Icon(Icons.grass_rounded, color: widget.accent, size: 14),
                    const SizedBox(width: 10),
                    Text(
                      '${crop['crop_name'] ?? 'Culture'} — ${crop['variety'] ?? 'Variété'}',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w400, color: textPri),
                    ),
                  ]),
                )),
              ],

              // Photos
              if (photos.isNotEmpty) ...[
                const SizedBox(height: 20),
                Text('PHOTOS (${photos.length})', style: TextStyle(
                  fontSize: 7, fontWeight: FontWeight.w600,
                  letterSpacing: 2.2, color: textSec.withOpacity(0.50),
                )),
                const SizedBox(height: 10),
                SizedBox(
                  height: 110,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    itemCount: photos.length,
                    itemBuilder: (context, i) => Container(
                      width: 110, margin: const EdgeInsets.only(right: 8),
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8)),
                      child: Image.network(photos[i]['image_url'] ?? '',
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: Colors.grey[200],
                            child: const Icon(Icons.image_not_supported, size: 28),
                          )),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Action buttons
              Row(children: [
                Expanded(child: GestureDetector(
                  onTap: _isLoading ? null : _reject,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: Colors.red.withOpacity(0.06),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.withOpacity(0.15)),
                    ),
                    child: _isLoading
                        ? Center(child: SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation(Colors.red.withOpacity(0.70)))))
                        : Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.close_rounded, color: Colors.red.withOpacity(0.75), size: 15),
                            const SizedBox(width: 7),
                            Text('Refuser', style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500,
                              color: Colors.red.withOpacity(0.80),
                            )),
                          ]),
                  ),
                )),
                const SizedBox(width: 12),
                Expanded(child: GestureDetector(
                  onTap: _isLoading ? null : _accept,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    decoration: BoxDecoration(
                      color: widget.primary,
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [BoxShadow(
                        color: widget.primary.withOpacity(0.28),
                        blurRadius: 16, offset: const Offset(0, 6),
                      )],
                    ),
                    child: _isLoading
                        ? const Center(child: SizedBox(width: 18, height: 18,
                            child: CircularProgressIndicator(strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation(Colors.white))))
                        : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.check_rounded, color: Colors.white, size: 15),
                            SizedBox(width: 7),
                            Text('Accepter', style: TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w500,
                              color: Colors.white,
                            )),
                          ]),
                  ),
                )),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO ROW helper
// ─────────────────────────────────────────────────────────────────────────────
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color primary;
  final Color textSec;
  final Color textPri;

  const _InfoRow({
    required this.label, required this.value, required this.icon,
    required this.primary, required this.textSec, required this.textPri,
  });

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, color: primary.withOpacity(0.55), size: 15),
    const SizedBox(width: 10),
    Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label.toUpperCase(), style: TextStyle(
        fontSize: 7, fontWeight: FontWeight.w500,
        letterSpacing: 1.8, color: textSec.withOpacity(0.50),
      )),
      const SizedBox(height: 2),
      Text(value, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w400, color: textPri,
      )),
    ]),
  ]);
}