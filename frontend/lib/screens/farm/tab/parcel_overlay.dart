/// ParcelOverlay — N parcelles interactives sur la vue aérienne.
/// Style : minimaliste raffiné — glassmorphic blur, géométrie précise,
///         typographie aérée, animations soignées et optimisées GPU.
library;

import 'dart:convert';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// MODÈLE
// ─────────────────────────────────────────────────────────────────────────────
class ParcelState {
  double nx, ny, nw, nh;

  ParcelState({
    this.nx = 0.1,
    this.ny = 0.1,
    this.nw = 0.28,
    this.nh = 0.28,
  });

  ParcelState.fromJson(Map<String, dynamic> j)
      : nx = ((j['nx'] as num?) ?? 0.1).toDouble(),
        ny = ((j['ny'] as num?) ?? 0.1).toDouble(),
        nw = ((j['nw'] as num?) ?? 0.28).toDouble(),
        nh = ((j['nh'] as num?) ?? 0.28).toDouble();

  Map<String, dynamic> toJson() => {'nx': nx, 'ny': ny, 'nw': nw, 'nh': nh};
}

// ─────────────────────────────────────────────────────────────────────────────
// DÉTECTION DE LA SANTÉ DE LA PARCELLE
// ─────────────────────────────────────────────────────────────────────────────

bool _hasCriticalProblem(Map<String, dynamic> parcel) {
  final problems = parcel['problems'] as List<dynamic>? ?? [];
  for (final p in problems) {
    final m = p as Map<String, dynamic>;
    final sev = (m['severity'] ?? '').toString().toLowerCase();
    if (sev == 'high') return true;
  }
  return false;
}

enum _HealthLevel { healthy, warning, critical }

_HealthLevel _healthLevel(Map<String, dynamic> parcel) {
  final hs = [
    parcel['health_status'], parcel['status'],
    parcel['disease'], parcel['notes'], parcel['health_issues'],
  ].whereType<String>().join(' ').toLowerCase();

  const redKw   = ['critical','disease','maladie','pest','ravageur','infection',
                   'blight','danger','urgent','severe','rouge','malade'];
  const amberKw = ['attention','warning','caution','risque','treated',
                   'traitement','medium','moyen','faible'];
  const greenKw = ['good','sain','healthy','normal','excellent'];

  if (redKw.any(hs.contains))   return _HealthLevel.critical;
  if (greenKw.any(hs.contains)) return _HealthLevel.healthy;
  if (amberKw.any(hs.contains)) return _HealthLevel.warning;

  final problems = parcel['problems'] as List<dynamic>? ?? [];
  if (problems.isEmpty) return _HealthLevel.healthy;

  bool hasHigh = false;
  for (final p in problems) {
    final m = p as Map<String, dynamic>;
    final sev = (m['severity'] ?? '').toString().toLowerCase();
    if (sev == 'high') hasHigh = true;
  }
  return hasHigh ? _HealthLevel.critical : _HealthLevel.warning;
}

Color _colorForLevel(_HealthLevel level) => switch (level) {
  _HealthLevel.healthy  => const Color(0xFF95C8A1),
  _HealthLevel.warning  => const Color(0xFFD4A96A),
  _HealthLevel.critical => const Color(0xFFFF5252),
};

Color _healthColor(Map<String, dynamic> parcel) =>
    _colorForLevel(_healthLevel(parcel));

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────
class ParcelOverlay extends StatefulWidget {
  final int farmId;
  final List<Map<String, dynamic>> parcels;
  final bool dark;
  final String? farmImage;
  final void Function(int parcelId)? onParcelTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;

  const ParcelOverlay({
    super.key,
    required this.farmId,
    required this.parcels,
    this.dark = true,
    this.farmImage,
    this.onParcelTap,
    this.onEdit,
    this.onDelete,
  });

  @override
  State<ParcelOverlay> createState() => _ParcelOverlayState();
}

class _ParcelOverlayState extends State<ParcelOverlay>
    with TickerProviderStateMixin {
  final Map<int, ParcelState> _states = {};
  final Map<int, AnimationController> _entryCtrl = {};
  final Map<int, AnimationController> _pulseCtrl = {};
  bool _loaded = false;
  int _activeId = -1;
  bool _resizing = false;

  bool _editMode = false;
  late AnimationController _modeToggleCtrl;
  late Animation<double> _modeToggleAnim;

  bool _menuExpanded = false;
  late AnimationController _menuCtrl;
  late Animation<double> _menuAnim;

  bool _legendExpanded = false;
  late AnimationController _legendCtrl;
  late Animation<double> _legendAnim;

  @override
  void initState() {
    super.initState();
    _modeToggleCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 340),
    );
    _modeToggleAnim = CurvedAnimation(
      parent: _modeToggleCtrl,
      curve: Curves.easeInOutCubic,
    );
    _menuCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _menuAnim = CurvedAnimation(
      parent: _menuCtrl,
      curve: Curves.easeOutCubic,
    );
    _legendCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _legendAnim = CurvedAnimation(
      parent: _legendCtrl,
      curve: Curves.easeOutCubic,
    );
    _loadStates();
  }

  @override
  void dispose() {
    _modeToggleCtrl.dispose();
    _menuCtrl.dispose();
    _legendCtrl.dispose();
    for (final c in _entryCtrl.values) {
      c.dispose();
    }
    for (final c in _pulseCtrl.values) {
      c.dispose();
    }
    super.dispose();
  }

  void _toggleLegend() {
    HapticFeedback.selectionClick();
    setState(() => _legendExpanded = !_legendExpanded);
    if (_legendExpanded) {
      _legendCtrl.forward();
    } else {
      _legendCtrl.reverse();
    }
  }

  void _toggleMode() {
    HapticFeedback.mediumImpact();
    setState(() => _editMode = !_editMode);
    if (_editMode) {
      _modeToggleCtrl.forward();
      if (_legendExpanded) {
        _legendExpanded = false;
        _legendCtrl.reverse();
      }
    } else {
      _modeToggleCtrl.reverse();
      _activeId = -1;
      _resizing = false;
    }
  }

  void _toggleMenu() {
    HapticFeedback.lightImpact();
    setState(() => _menuExpanded = !_menuExpanded);
    if (_menuExpanded) {
      _menuCtrl.forward();
    } else {
      _menuCtrl.reverse();
    }
  }

  String _prefKey() => 'parcels_layout_v2_${widget.farmId}';

  Future<void> _loadStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_prefKey());
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        data.forEach((k, v) {
          _states[int.parse(k)] =
              ParcelState.fromJson(v as Map<String, dynamic>);
        });
      }
    } catch (_) {}

    for (var i = 0; i < widget.parcels.length; i++) {
      final id = widget.parcels[i]['id'] as int;
      if (!_states.containsKey(id)) {
        final col = i % 2;
        final row = i ~/ 2;
        _states[id] = ParcelState(
          nx: 0.04 + col * 0.50,
          ny: 0.04 + row * 0.32,
          nw: 0.42,
          nh: 0.26,
        );
      }

      final ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 500),
      );
      _entryCtrl[id] = ctrl;
      Future.delayed(Duration(milliseconds: 60 * i), () {
        if (mounted) ctrl.forward();
      });

      if (_hasCriticalProblem(widget.parcels[i])) {
        final pulse = AnimationController(
          vsync: this,
          duration: const Duration(milliseconds: 600),
        )..repeat(reverse: true);
        _pulseCtrl[id] = pulse;
      }
    }

    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _saveStates() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{};
      _states.forEach((k, v) => data[k.toString()] = v.toJson());
      await prefs.setString(_prefKey(), jsonEncode(data));
    } catch (_) {}
  }

  ({int healthy, int warning, int critical}) get _densityStats {
    int h = 0, w = 0, c = 0;
    for (final p in widget.parcels) {
      switch (_healthLevel(p)) {
        case _HealthLevel.healthy:  h++; break;
        case _HealthLevel.warning:  w++; break;
        case _HealthLevel.critical: c++; break;
      }
    }
    return (healthy: h, warning: w, critical: c);
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded) return const SizedBox.shrink();
    final total = widget.parcels.length;

    return LayoutBuilder(builder: (_, box) {
      final W = box.maxWidth;
      final H = box.maxHeight;
      return Stack(
        children: [
          for (var i = 0; i < widget.parcels.length; i++)
            _buildParcel(widget.parcels[i], i, W, H),

          Positioned(
            right: 12,
            top: 10,
            child: _ModeToggle(
              editMode: _editMode,
              modeAnim: _modeToggleAnim,
              onToggle: _toggleMode,
            ),
          ),

          Positioned(
            left: 12,
            top: 10,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                GestureDetector(
                  onTap: _toggleMenu,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        width: 42,
                        height: 42,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.30),
                            width: 0.8,
                          ),
                        ),
                        child: const Icon(
                          Icons.menu_outlined,
                          size: 21,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
                SizeTransition(
                  sizeFactor: _menuAnim,
                  axisAlignment: -1,
                  child: Container(
                    margin: const EdgeInsets.only(top: 4),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
                        child: Container(
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.60),
                            border: Border.all(
                              color: Colors.white.withOpacity(0.15),
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  _toggleMenu();
                                  widget.onEdit?.call();
                                },
                                child: Container(
                                  width: 132,
                                  height: 46,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.edit_note_outlined, size: 19, color: Colors.white),
                                      SizedBox(width: 10),
                                      Text('MODIFIER', style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: Colors.white, fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                              Container(
                                height: 0.5,
                                color: Colors.white.withOpacity(0.1),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _toggleMenu();
                                  widget.onDelete?.call();
                                },
                                child: Container(
                                  width: 132,
                                  height: 46,
                                  padding: const EdgeInsets.symmetric(horizontal: 14),
                                  child: const Row(
                                    children: [
                                      Icon(Icons.delete_outline, size: 19, color: Color(0xFFFF5252)),
                                      SizedBox(width: 10),
                                      Text('SUPPRIMER', style: TextStyle(fontSize: 10, letterSpacing: 1.2, color: Color(0xFFFF5252), fontWeight: FontWeight.w600)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Positioned(
            left: 12,
            bottom: 50,
            child: _HealthIndicator(
              stats: _densityStats,
              total: total,
              expanded: _legendExpanded,
              expandAnim: _legendAnim,
              onToggle: _toggleLegend,
            ),
          ),
        ],
      );
    });
  }

  Widget _buildParcel(
      Map<String, dynamic> parcel, int idx, double W, double H) {
    final id = parcel['id'] as int;
    final name =
        (parcel['name'] ?? parcel['parcel_name'] ?? 'P${idx + 1}').toString();
    final photo =
        (parcel['image_url'] ?? parcel['photo_url'] ?? parcel['photo'] ?? '')
            as String;
    final st = _states[id]!;
    final color = _healthColor(parcel);
    final isActive = _activeId == id;

    final left = st.nx * W;
    final top = st.ny * H;
    final width = (st.nw * W).clamp(56.0, W * 0.92);
    final height = (st.nh * H).clamp(40.0, H * 0.92);

    final entryAnim = CurvedAnimation(
      parent: _entryCtrl[id]!,
      curve: Curves.easeOutCubic,
    );

    return Positioned(
      left: left,
      top: top,
      child: AnimatedBuilder(
        animation: entryAnim,
        builder: (_, child) => FadeTransition(
          opacity: entryAnim,
          child: ScaleTransition(
            scale: Tween(begin: 0.88, end: 1.0).animate(entryAnim),
            alignment: Alignment.topLeft,
            child: child,
          ),
        ),
        child: GestureDetector(
          onPanStart: _editMode ? (_) {
            if (_resizing) return;
            HapticFeedback.lightImpact();
            setState(() => _activeId = id);
          } : null,
          onPanUpdate: _editMode ? (d) {
            if (_resizing) return;
            setState(() {
              st.nx = (st.nx + d.delta.dx / W).clamp(0.0, 1.0 - st.nw);
              st.ny = (st.ny + d.delta.dy / H).clamp(0.0, 1.0 - st.nh);
            });
          } : null,
          onPanEnd: _editMode ? (_) {
            setState(() => _activeId = -1);
            _saveStates();
          } : null,
          onTap: () => widget.onParcelTap?.call(id),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            curve: Curves.easeOut,
            width: width,
            height: height,
            child: Stack(clipBehavior: Clip.none, children: [
              Positioned.fill(
                child: _ParcelBody(
                  photo: photo,
                  color: color,
                  isActive: isActive,
                  lockedMode: !_editMode,
                  width: width,
                  height: height,
                ),
              ),

              Positioned.fill(
                child: IgnorePointer(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      painter: _CornerBorderPainter(
                        color: color,
                        active: isActive,
                      ),
                    ),
                  ),
                ),
              ),

              AnimatedBuilder(
                animation: _modeToggleAnim,
                builder: (_, __) {
                  final t = 1.0 - _modeToggleAnim.value;
                  if (t < 0.01) return const SizedBox.shrink();
                  return Positioned(
                    top: 0,
                    right: 0,
                    child: Opacity(
                      opacity: t * 0.55,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        child: Icon(
                          Icons.lock_outline_rounded,
                          size: 8,
                          color: color,
                        ),
                      ),
                    ),
                  );
                },
              ),

              Positioned(
                top: 0,
                left: 0,
                child: _ParcelLabel(
                  name: name,
                  color: color,
                  isActive: isActive,
                  idx: idx,
                  maxW: width,
                ),
              ),

              if (_pulseCtrl.containsKey(id))
                Positioned(
                  top: 4,
                  right: 4,
                  child: ScaleTransition(
                    scale: Tween(begin: 0.6, end: 1.0)
                        .animate(_pulseCtrl[id]!),
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFFF5252),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFFFF5252).withOpacity(0.6),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

              if (isActive && _editMode)
                Center(
                  child: _DimBadge(
                    text: '${width.toInt()} × ${height.toInt()}',
                    color: color,
                  ),
                ),

              if (_editMode) _DraggableOriginDot(color: color),

              if (_editMode)
                Positioned(
                  right: 0,
                  bottom: 0,
                  child: _ResizeHandle(
                    color: color,
                    onPanStart: () {
                      HapticFeedback.lightImpact();
                      setState(() {
                        _activeId = id;
                        _resizing = true;
                      });
                    },
                    onPanUpdate: (d) {
                      setState(() {
                        st.nw = (st.nw + d.delta.dx / W)
                            .clamp(0.10, 1.0 - st.nx);
                        st.nh = (st.nh + d.delta.dy / H)
                            .clamp(0.10, 1.0 - st.ny);
                      });
                    },
                    onPanEnd: () {
                      setState(() {
                        _activeId = -1;
                        _resizing = false;
                      });
                      _saveStates();
                    },
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// INDICATEUR DE SANTÉ — GLASSMORPHIC PILL REPLIABLE
// ─────────────────────────────────────────────────────────────────────────────
class _HealthIndicator extends StatelessWidget {
  final ({int healthy, int warning, int critical}) stats;
  final int total;
  final bool expanded;
  final Animation<double> expandAnim;
  final VoidCallback onToggle;

  const _HealthIndicator({
    required this.stats,
    required this.total,
    required this.expanded,
    required this.expandAnim,
    required this.onToggle,
  });

  Color get _dominantColor {
    if (stats.critical > 0) return const Color(0xFFFF5252);
    if (stats.warning > 0)  return const Color(0xFFD4A96A);
    return const Color(0xFF95C8A1);
  }

  @override
  Widget build(BuildContext context) {
    final color = _dominantColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: expandAnim,
          builder: (_, child) {
            final t = expandAnim.value;
            return ClipRect(
              child: Align(
                alignment: Alignment.bottomLeft,
                heightFactor: t,
                child: Opacity(
                  opacity: t,
                  child: Transform.translate(
                    offset: Offset(0, (1 - t) * 10),
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: _DensityLegend(stats: stats, total: total),
          ),
        ),

        GestureDetector(
          onTap: onToggle,
          child: AnimatedBuilder(
            animation: expandAnim,
            builder: (_, __) {
              final t = expandAnim.value;
              final bgColor = Color.lerp(
                const Color(0xFF1A1A1A),
                color.withOpacity(0.12),
                t,
              )!;
              return ClipRRect(
                borderRadius: BorderRadius.circular(13),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    height: 26,
                    padding: const EdgeInsets.symmetric(horizontal: 10),
                    decoration: BoxDecoration(
                      color: bgColor.withOpacity(0.70),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: color.withOpacity(0.25 + 0.25 * t),
                        width: 0.6,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                        if (stats.critical > 0)
                          BoxShadow(
                            color: const Color(0xFFFF5252).withOpacity(0.12),
                            blurRadius: 10,
                          ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: color,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.5),
                                blurRadius: 4,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          'SANTÉ',
                          style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.4,
                            color: Colors.white.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(width: 7),
                        _MiniBar(stats: stats, total: total),
                        const SizedBox(width: 8),
                        AnimatedRotation(
                          turns: expanded ? 0.5 : 0.0,
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOutCubic,
                          child: Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 12,
                            color: Colors.white.withOpacity(0.4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MiniBar extends StatelessWidget {
  final ({int healthy, int warning, int critical}) stats;
  final int total;

  const _MiniBar({required this.stats, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();
    final ratioH = stats.healthy / total;
    final ratioW = stats.warning / total;
    final ratioC = stats.critical / total;

    return ClipRRect(
      borderRadius: BorderRadius.circular(1.5),
      child: SizedBox(
        width: 36,
        height: 3,
        child: Row(
          children: [
            if (ratioH > 0)
              Expanded(
                flex: (ratioH * 100).round(),
                child: Container(color: const Color(0xFF95C8A1).withOpacity(0.75)),
              ),
            if (ratioW > 0) ...[
              const SizedBox(width: 1),
              Expanded(
                flex: (ratioW * 100).round(),
                child: Container(color: const Color(0xFFD4A96A).withOpacity(0.75)),
              ),
            ],
            if (ratioC > 0) ...[
              const SizedBox(width: 1),
              Expanded(
                flex: (ratioC * 100).round(),
                child: Container(color: const Color(0xFFFF5252).withOpacity(0.75)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PANNEAU DE DENSITÉ GLASSMORPHIC
// ─────────────────────────────────────────────────────────────────────────────
class _DensityLegend extends StatelessWidget {
  final ({int healthy, int warning, int critical}) stats;
  final int total;

  const _DensityLegend({required this.stats, required this.total});

  @override
  Widget build(BuildContext context) {
    if (total == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(4),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          width: 148,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0D0D0D).withOpacity(0.68),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: Colors.white.withOpacity(0.12),
              width: 0.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 4,
                    height: 4,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: Color(0xFF505055),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'ÉTAT DES PARCELLES',
                    style: TextStyle(
                      fontSize: 6.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.4,
                      color: Colors.white.withOpacity(0.35),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              _CompositeDensityBar(stats: stats, total: total),
              const SizedBox(height: 10),

              _LegendRow(
                color: const Color(0xFF95C8A1),
                label: 'SAIN',
                count: stats.healthy,
                total: total,
              ),
              const SizedBox(height: 5),
              _LegendRow(
                color: const Color(0xFFD4A96A),
                label: 'ATTENTION',
                count: stats.warning,
                total: total,
              ),
              const SizedBox(height: 5),
              _LegendRow(
                color: const Color(0xFFFF5252),
                label: 'CRITIQUE',
                count: stats.critical,
                total: total,
              ),
              const SizedBox(height: 8),

              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  '$total parcelle${total > 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 6.5,
                    letterSpacing: 0.8,
                    color: Colors.white.withOpacity(0.25),
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CompositeDensityBar extends StatefulWidget {
  final ({int healthy, int warning, int critical}) stats;
  final int total;

  const _CompositeDensityBar({required this.stats, required this.total});

  @override
  State<_CompositeDensityBar> createState() => _CompositeDensityBarState();
}

class _CompositeDensityBarState extends State<_CompositeDensityBar>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _anim = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic);
    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.total;
    final ratioH = widget.stats.healthy / t;
    final ratioW = widget.stats.warning / t;
    final ratioC = widget.stats.critical / t;

    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) {
        final progress = _anim.value;
        return ClipRRect(
          borderRadius: BorderRadius.circular(2),
          child: SizedBox(
            height: 5,
            child: Row(
              children: [
                if (ratioH > 0)
                  Expanded(
                    flex: (ratioH * 1000).round(),
                    child: Container(
                      color: const Color(0xFF95C8A1)
                          .withOpacity(0.4 + 0.6 * progress),
                    ),
                  ),
                if (ratioW > 0) ...[
                  const SizedBox(width: 1),
                  Expanded(
                    flex: (ratioW * 1000).round(),
                    child: Container(
                      color: const Color(0xFFD4A96A)
                          .withOpacity(0.4 + 0.6 * progress),
                    ),
                  ),
                ],
                if (ratioC > 0) ...[
                  const SizedBox(width: 1),
                  Expanded(
                    flex: (ratioC * 1000).round(),
                    child: Container(
                      color: const Color(0xFFFF5252)
                          .withOpacity(0.4 + 0.6 * progress),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final int count;
  final int total;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.count,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final ratio = total > 0 ? count / total : 0.0;
    return Row(
      children: [
        Container(
          width: 5,
          height: 5,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withOpacity(count > 0 ? 0.85 : 0.22),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 6.5,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w500,
            color: Colors.white.withOpacity(count > 0 ? 0.65 : 0.22),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 40,
          height: 3,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(1.5),
            child: Stack(
              children: [
                Container(color: Colors.white.withOpacity(0.06)),
                FractionallySizedBox(
                  widthFactor: ratio,
                  child: Container(color: color.withOpacity(count > 0 ? 0.7 : 0)),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 5),
        SizedBox(
          width: 12,
          child: Text(
            '$count',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 6.5,
              letterSpacing: 0.5,
              fontWeight: FontWeight.w600,
              color: color.withOpacity(count > 0 ? 0.85 : 0.22),
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CORPS DE LA PARCELLE
// ─────────────────────────────────────────────────────────────────────────────
class _ParcelBody extends StatelessWidget {
  final String photo;
  final Color color;
  final bool isActive;
  final bool lockedMode;
  final double width, height;

  const _ParcelBody({
    required this.photo,
    required this.color,
    required this.isActive,
    required this.lockedMode,
    required this.width,
    required this.height,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: Stack(fit: StackFit.expand, children: [
        photo.isNotEmpty
            ? Image.network(photo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _hatchBackground())
            : _hatchBackground(),

        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            color: isActive
                ? Colors.black.withOpacity(0.18)
                : Colors.black.withOpacity(lockedMode ? 0.30 : 0.38),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(isActive ? 0.18 : 0.10),
                Colors.black.withOpacity(isActive ? 0.10 : 0.25),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _hatchBackground() {
    return RepaintBoundary(
      child: CustomPaint(painter: _HatchPainter(color: color)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// LABEL DE PARCELLE GLASSMORPHIC
// ─────────────────────────────────────────────────────────────────────────────
class _ParcelLabel extends StatelessWidget {
  final String name;
  final Color color;
  final bool isActive;
  final int idx;
  final double maxW;

  const _ParcelLabel({
    required this.name,
    required this.color,
    required this.isActive,
    required this.idx,
    required this.maxW,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          constraints: BoxConstraints(maxWidth: maxW),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: isActive
                ? color.withOpacity(0.92)
                : Colors.black.withOpacity(0.55),
            border: Border(
              right: BorderSide(color: color.withOpacity(0.35), width: 0.5),
              bottom: BorderSide(color: color.withOpacity(0.35), width: 0.5),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'P${idx + 1}',
                style: TextStyle(
                  fontSize: 7,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.4,
                  color: color.withOpacity(isActive ? 1.0 : 0.85),
                ),
              ),
              const SizedBox(width: 4),
              Container(width: 0.5, height: 8, color: Colors.white.withOpacity(0.22)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  name.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 7,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 1.1,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BADGE DIMENSIONS
// ─────────────────────────────────────────────────────────────────────────────
class _DimBadge extends StatelessWidget {
  final String text;
  final Color color;

  const _DimBadge({required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.55),
            border: Border.all(color: color.withOpacity(0.4), width: 0.5),
          ),
          child: Text(
            text,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.0,
              color: color.withOpacity(0.9),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POIGNÉE DE REDIMENSIONNEMENT INTERACTIVE
// ─────────────────────────────────────────────────────────────────────────────
class _ResizeHandle extends StatefulWidget {
  final Color color;
  final VoidCallback onPanStart;
  final void Function(DragUpdateDetails) onPanUpdate;
  final VoidCallback onPanEnd;

  const _ResizeHandle({
    required this.color,
    required this.onPanStart,
    required this.onPanUpdate,
    required this.onPanEnd,
  });

  @override
  State<_ResizeHandle> createState() => _ResizeHandleState();
}

class _ResizeHandleState extends State<_ResizeHandle> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onPanStart: (_) {
        setState(() => _hovered = true);
        widget.onPanStart();
      },
      onPanUpdate: widget.onPanUpdate,
      onPanEnd: (_) {
        setState(() => _hovered = false);
        widget.onPanEnd();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: _hovered
              ? widget.color.withOpacity(0.28)
              : widget.color.withOpacity(0.12),
          border: Border.all(
            color: _hovered
                ? widget.color.withOpacity(0.70)
                : widget.color.withOpacity(0.35),
            width: 0.8,
          ),
        ),
        child: RepaintBoundary(
          child: CustomPaint(painter: _ResizeIconPainter(color: widget.color)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POINT D'ORIGINE DRAGGABLE
// ─────────────────────────────────────────────────────────────────────────────
class _DraggableOriginDot extends StatefulWidget {
  final Color color;
  const _DraggableOriginDot({required this.color});

  @override
  State<_DraggableOriginDot> createState() => _DraggableOriginDotState();
}

class _DraggableOriginDotState extends State<_DraggableOriginDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  Offset _local = Offset.zero;
  bool _init = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 2200))
      ..repeat();
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (_, box) {
      if (!_init) {
        _local = Offset(box.maxWidth / 2 - 12, box.maxHeight / 2 - 12);
        _init = true;
      }
      return Stack(children: [
        Positioned(
          left: _local.dx,
          top: _local.dy,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onPanUpdate: (d) {
              setState(() {
                final maxX = (box.maxWidth - 28).clamp(4, double.infinity) as double;
                final maxY = (box.maxHeight - 28).clamp(20, double.infinity) as double;
                _local = Offset(
                  ((_local.dx + d.delta.dx).clamp(4, maxX)) as double,
                  ((_local.dy + d.delta.dy).clamp(20, maxY)) as double,
                );
              });
            },
            child: AnimatedBuilder(
              animation: _pulse,
              builder: (_, __) {
                final t = Curves.easeInOut.transform(_pulse.value);
                return SizedBox(
                  width: 24,
                  height: 24,
                  child: Stack(alignment: Alignment.center, children: [
                    Container(
                      width: 10 + t * 14,
                      height: 10 + t * 14,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.color.withOpacity((1 - t) * 0.5),
                          width: 0.8,
                        ),
                      ),
                    ),
                    Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: widget.color.withOpacity(0.4),
                          width: 0.5,
                        ),
                      ),
                    ),
                    Container(
                      width: 5,
                      height: 5,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white,
                        boxShadow: [
                          BoxShadow(
                            color: widget.color.withOpacity(0.6),
                            blurRadius: 4,
                          ),
                        ],
                      ),
                    ),
                    RepaintBoundary(
                      child: CustomPaint(
                        size: const Size(24, 24),
                        painter: _CrosshairPainter(color: widget.color),
                      ),
                    ),
                  ]),
                );
              },
            ),
          ),
        ),
      ]);
    });
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS
// ─────────────────────────────────────────────────────────────────────────────

class _CornerBorderPainter extends CustomPainter {
  final Color color;
  final bool active;

  const _CornerBorderPainter({required this.color, required this.active});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(active ? 0.85 : 0.45)
      ..strokeWidth = active ? 1.2 : 0.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.square;

    const len = 10.0;
    final w = size.width;
    final h = size.height;

    canvas.drawLine(const Offset(0, len), const Offset(0, 0), paint);
    canvas.drawLine(const Offset(0, 0), const Offset(len, 0), paint);
    canvas.drawLine(Offset(w - len, 0), Offset(w, 0), paint);
    canvas.drawLine(Offset(w, 0), Offset(w, len), paint);
    canvas.drawLine(Offset(0, h - len), Offset(0, h), paint);
    canvas.drawLine(Offset(0, h), Offset(len, h), paint);
    canvas.drawLine(Offset(w - len, h), Offset(w, h), paint);
    canvas.drawLine(Offset(w, h - len), Offset(w, h), paint);

    final faintPaint = Paint()
      ..color = color.withOpacity(active ? 0.30 : 0.15)
      ..strokeWidth = 0.4
      ..style = PaintingStyle.stroke;
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), faintPaint);
  }

  @override
  bool shouldRepaint(_CornerBorderPainter old) =>
      old.color != color || old.active != active;
}

class _HatchPainter extends CustomPainter {
  final Color color;
  const _HatchPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = const Color(0xFF0D0D0D),
    );

    final paint = Paint()
      ..color = color.withOpacity(0.07)
      ..strokeWidth = 0.6
      ..style = PaintingStyle.stroke;

    const step = 10.0;
    for (double i = -size.height; i < size.width; i += step) {
      canvas.drawLine(
        Offset(i, 0),
        Offset(i + size.height, size.height),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(_HatchPainter old) => old.color != color;
}

class _ResizeIconPainter extends CustomPainter {
  final Color color;
  const _ResizeIconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.90)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final w = size.width;
    final h = size.height;

    for (var i = 0; i < 4; i++) {
      final o = 4.5 + i * 4.5;
      canvas.drawLine(Offset(w - o, h), Offset(w, h - o), paint);
    }
  }

  @override
  bool shouldRepaint(_ResizeIconPainter old) => old.color != color;
}

class _CrosshairPainter extends CustomPainter {
  final Color color;
  const _CrosshairPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(0.35)
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round;

    final cx = size.width / 2;
    final cy = size.height / 2;
    const gap = 4.0;
    const arm = 5.0;

    canvas.drawLine(Offset(cx - gap - arm, cy), Offset(cx - gap, cy), paint);
    canvas.drawLine(Offset(cx + gap, cy), Offset(cx + gap + arm, cy), paint);
    canvas.drawLine(Offset(cx, cy - gap - arm), Offset(cx, cy - gap), paint);
    canvas.drawLine(Offset(cx, cy + gap), Offset(cx, cy + gap + arm), paint);
  }

  @override
  bool shouldRepaint(_CrosshairPainter old) => old.color != color;
}

// ─────────────────────────────────────────────────────────────────────────────
// TOGGLE MODE LECTURE/ÉDITION
// ─────────────────────────────────────────────────────────────────────────────
class _ModeToggle extends StatelessWidget {
  final bool editMode;
  final Animation<double> modeAnim;
  final VoidCallback onToggle;

  const _ModeToggle({
    required this.editMode,
    required this.modeAnim,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onToggle();
      },
      child: AnimatedBuilder(
        animation: modeAnim,
        builder: (_, __) {
          final t = modeAnim.value;

          final trackColor = Color.lerp(
            Colors.white.withOpacity(0.10),
            const Color(0xFF34D399).withOpacity(0.18),
            t,
          )!;

          final borderColor = Color.lerp(
            Colors.white.withOpacity(0.14),
            const Color(0xFF34D399).withOpacity(0.45),
            t,
          )!;

          final thumbColor = Color.lerp(
            Colors.white,
            const Color(0xFF34D399),
            t,
          )!;

          final thumbGlow = Color.lerp(
            Colors.transparent,
            const Color(0xFF34D399).withOpacity(0.50),
            t,
          )!;

          final iconOpacityRead = (1 - t).clamp(0.0, 1.0);
          final iconOpacityEdit = t.clamp(0.0, 1.0);

          return ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
              child: Container(
                width: 44,
                height: 26,
                decoration: BoxDecoration(
                  color: trackColor,
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Stack(
                  alignment: Alignment.centerLeft,
                  children: [
                    Positioned(
                      left: 3 + t * 18,
                      child: Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: thumbColor,
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.12),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                            BoxShadow(
                              color: thumbGlow,
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Opacity(
                                opacity: iconOpacityRead,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 1.2,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.35),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                    const SizedBox(height: 2.5),
                                    Container(
                                      width: 5,
                                      height: 1.2,
                                      decoration: BoxDecoration(
                                        color: Colors.black.withOpacity(0.25),
                                        borderRadius: BorderRadius.circular(1),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Opacity(
                                opacity: iconOpacityEdit,
                                child: Transform.rotate(
                                  angle: -0.785,
                                  child: Column(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 1.5,
                                        height: 7,
                                        decoration: BoxDecoration(
                                          color: Colors.white.withOpacity(0.85),
                                          borderRadius: BorderRadius.circular(1),
                                        ),
                                      ),
                                      ClipPath(
                                        clipper: _TriangleTipClipper(),
                                        child: Container(
                                          width: 1.5,
                                          height: 3,
                                          color: Colors.white.withOpacity(0.85),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _TriangleTipClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    return Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
  }

  @override
  bool shouldReclip(_TriangleTipClipper old) => false;
}