import 'dart:math';
import 'package:flutter/material.dart';
import 'package:mbaymi/utils/app_colors.dart';

/// Un point d'intérêt flottant sur la vue aérienne
class _AerialPin {
  final String title;
  final String subtitle;
  final double dx; // 0.0 → 1.0 relatif à la largeur
  final double dy; // 0.0 → 1.0 relatif à la hauteur
  final IconData icon;

  const _AerialPin({
    required this.title,
    required this.subtitle,
    required this.dx,
    required this.dy,
    required this.icon,
  });
}

class FarmAerialView extends StatefulWidget {
  final Map<String, dynamic> farm;
  final List<dynamic> crops;
  final bool isDarkMode;
  final VoidCallback? onTapParcelles;

  const FarmAerialView({
    super.key,
    required this.farm,
    required this.crops,
    required this.isDarkMode,
    this.onTapParcelles,
  });

  @override
  State<FarmAerialView> createState() => _FarmAerialViewState();
}

class _FarmAerialViewState extends State<FarmAerialView>
    with TickerProviderStateMixin {
  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;
  int? _activePin;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 600));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  List<_AerialPin> _buildPins() {
    final crops = widget.crops;
    final farm  = widget.farm;
    final livestock = farm['livestock_count'] as int? ?? 0;

    final List<_AerialPin> pins = [];

    // Ferme principale — toujours présente
    pins.add(_AerialPin(
      title: (farm['name'] ?? 'Ferme').toString().toUpperCase(),
      subtitle: farm['location'] ?? '',
      dx: 0.25, dy: 0.22,
      icon: Icons.home_outlined,
    ));

    // Parcelles / cultures — distribués dynamiquement
    final positions = [
      (dx: 0.68, dy: 0.18),
      (dx: 0.12, dy: 0.62),
      (dx: 0.72, dy: 0.70),
      (dx: 0.45, dy: 0.82),
    ];

    for (var i = 0; i < min(crops.length, positions.length); i++) {
      final c = crops[i] as Map<String, dynamic>;
      final name = (c['crop_name'] ?? 'Culture').toString();
      final area = c['area_hectares'] != null ? '${c['area_hectares']} ha' : '';
      pins.add(_AerialPin(
        title: name.length > 14 ? '${name.substring(0, 14)}…' : name,
        subtitle: area,
        dx: positions[i].dx,
        dy: positions[i].dy,
        icon: Icons.grass_outlined,
      ));
    }

    // Bétail si présent
    if (livestock > 0) {
      pins.add(_AerialPin(
        title: 'BÉTAIL',
        subtitle: '$livestock têtes',
        dx: 0.55, dy: 0.35,
        icon: Icons.pets_outlined,
      ));
    }

    return pins;
  }

  @override
  Widget build(BuildContext context) {
    final dark  = widget.isDarkMode;
    final image = widget.farm['image_url'] as String?;
    final pins  = _buildPins();

    return FadeTransition(
      opacity: _fadeAnim,
      child: ClipRect(
        child: LayoutBuilder(
          builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            final h = w * 0.62; // ratio paysage

            return SizedBox(
              width: w,
              height: h,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // ── Image de fond ──────────────────────────────────────
                  Positioned.fill(
                    child: image != null && image.isNotEmpty
                        ? Image.network(image, fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _noImage(dark))
                        : _noImage(dark),
                  ),

                  // ── Vignette sombre sur les bords ─────────────────────
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment.center,
                          radius: 1.1,
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.45),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── Léger grain / texture overlay ─────────────────────
                  Positioned.fill(
                    child: CustomPaint(painter: _GridPainter()),
                  ),

                  // ── Pins avec connecteurs ──────────────────────────────
                  ...pins.asMap().entries.map((entry) {
                    final i   = entry.key;
                    final pin = entry.value;
                    final px  = pin.dx * w;
                    final py  = pin.dy * h;

                    // Décalage tooltip selon position pour éviter bords
                    final tooltipLeft = pin.dx > 0.6 ? null : px + 10;
                    final tooltipRight = pin.dx > 0.6 ? (w - px + 10) : null;
                    final tooltipTop  = pin.dy > 0.65 ? null : py - 8;
                    final tooltipBottom = pin.dy > 0.65 ? (h - py + 8) : null;

                    return Stack(
                      children: [
                        // Connecteur (ligne) du point → tooltip
                        Positioned(
                          left: px - 1,
                          top: py,
                          child: _Connector(
                            goRight: pin.dx <= 0.6,
                            goUp: pin.dy <= 0.65,
                            length: 28,
                          ),
                        ),

                        // Point de localisation (dot)
                        Positioned(
                          left: px - 5,
                          top: py - 5,
                          child: _Dot(
                            active: _activePin == i,
                            onTap: () => setState(() => _activePin = _activePin == i ? null : i),
                          ),
                        ),

                        // Tooltip
                        Positioned(
                          left: tooltipLeft,
                          right: tooltipRight,
                          top: tooltipTop,
                          bottom: tooltipBottom,
                          child: GestureDetector(
                            onTap: () {
                              setState(() => _activePin = _activePin == i ? null : i);
                              if (i > 0) widget.onTapParcelles?.call();
                            },
                            child: _Tooltip(
                              title: pin.title,
                              subtitle: pin.subtitle,
                              icon: pin.icon,
                              active: _activePin == i,
                              dark: dark,
                            ),
                          ),
                        ),
                      ],
                    );
                  }),

                  // ── Badge "VUE AÉRIENNE" en haut à droite ─────────────
                  Positioned(
                    top: 12, right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      color: Colors.black.withOpacity(0.5),
                      child: Row(mainAxisSize: MainAxisSize.min, children: const [
                        Icon(Icons.satellite_alt_outlined, size: 11, color: Colors.white54),
                        SizedBox(width: 5),
                        Text('VUE AÉRIENNE', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w300, letterSpacing: 1.5, color: Colors.white54)),
                      ]),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _noImage(bool dark) => Container(
    color: dark ? const Color(0xFF1A2318) : const Color(0xFFE8EDE5),
    child: Center(child: Icon(Icons.landscape_outlined, size: 48, color: (dark ? Colors.white : Colors.black).withOpacity(0.06))),
  );
}

// ─── Dot pulsant ──────────────────────────────────────────────────────────────
class _Dot extends StatefulWidget {
  final bool active;
  final VoidCallback onTap;
  const _Dot({required this.active, required this.onTap});

  @override
  State<_Dot> createState() => _DotState();
}

class _DotState extends State<_Dot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))
      ..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (_, __) {
          final pulse = Curves.easeOut.transform(_ctrl.value);
          return SizedBox(
            width: 22, height: 22,
            child: Stack(alignment: Alignment.center, children: [
              // Anneau pulsant
              Container(
                width: 10 + pulse * 14,
                height: 10 + pulse * 14,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.accent.withOpacity((1 - pulse) * 0.6),
                    width: 1,
                  ),
                ),
              ),
              // Point central
              Container(
                width: widget.active ? 10 : 8,
                height: widget.active ? 10 : 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.active ? AppColors.accent : Colors.white,
                  border: Border.all(color: AppColors.accent, width: 1.5),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}

// ─── Connecteur ligne ────────────────────────────────────────────────────────
class _Connector extends StatelessWidget {
  final bool goRight;
  final bool goUp;
  final double length;
  const _Connector({required this.goRight, required this.goUp, required this.length});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(length, length),
      painter: _ConnectorPainter(goRight: goRight, goUp: goUp, length: length),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final bool goRight, goUp;
  final double length;
  _ConnectorPainter({required this.goRight, required this.goUp, required this.length});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.55)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(0, 0);
    // Ligne coudée : d'abord verticale, puis horizontale
    final mid = length * 0.45;
    path.lineTo(0, goUp ? -mid : mid);
    path.lineTo(goRight ? length : -length, goUp ? -mid : mid);
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Tooltip flottant ─────────────────────────────────────────────────────────
class _Tooltip extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool active;
  final bool dark;
  const _Tooltip({
    required this.title, required this.subtitle,
    required this.icon, required this.active, required this.dark,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      constraints: const BoxConstraints(minWidth: 90, maxWidth: 140),
      decoration: BoxDecoration(
        color: active
            ? Colors.black.withOpacity(0.88)
            : Colors.black.withOpacity(0.62),
        border: Border.all(
          color: active ? AppColors.accent.withOpacity(0.7) : Colors.white.withOpacity(0.18),
          width: active ? 1 : 0.5,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: active ? AppColors.accent : Colors.white54),
          const SizedBox(width: 6),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(title,
                    style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w400, letterSpacing: 1.2, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w300, letterSpacing: 0.5, color: Colors.white.withOpacity(0.5)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Grid overlay subtil ─────────────────────────────────────────────────────
class _GridPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(0.04)
      ..strokeWidth = 0.5
      ..style = PaintingStyle.stroke;

    const step = 40.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(_) => false;
}