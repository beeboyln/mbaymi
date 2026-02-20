import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import 'package:mbaymi/utils/app_colors.dart';
import 'farm_tab_components.dart';

// Cache des statuts de santé (à déplacer dans un service dédié plus tard)
final _statusCache = <int, Color>{};

// ─────────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────────
Color _statusColor(Map<String, dynamic> crop) {
  final id = crop['id'] as int?;
  if (id != null && _statusCache.containsKey(id)) return _statusCache[id]!;

  Color result;
  try {
    final problems = crop['problems'] as List<dynamic>? ?? [];
    if (problems.isNotEmpty) {
      for (final p in problems) {
        final sev = p['severity']?.toString().toLowerCase() ?? '';
        final type = p['problem_type']?.toString().toLowerCase() ?? '';
        if (sev == 'high' || type.contains('disease') || type.contains('pest')) {
          result = Colors.red;
          if (id != null) _statusCache[id] = result;
          return result;
        }
        if (sev == 'medium') {
          result = Colors.amber;
          if (id != null) _statusCache[id] = result;
          return result;
        }
      }
    }

    final text = [
      crop['health_status'], crop['status'], crop['notes'],
      crop['description'], crop['disease'], crop['health_issues'],
    ].where((v) => v != null).join(' ').toLowerCase();

    const critical = ['maladie', 'disease', 'ravageur', 'pest', 'urgent',
      'critique', 'critical', 'severe', 'danger', 'infection', 'blight'];
    const alert = ['attention', 'surveiller', 'risque', 'caution', 'warning',
      'anormal', 'faible rendement'];

    if (critical.any((k) => text.contains(k))) {
      result = Colors.red;
    } else if (alert.any((k) => text.contains(k))) {
      result = Colors.amber;
    } else {
      result = Colors.green;
    }
  } catch (_) {
    result = AppColors.accent;
  }

  if (id != null) _statusCache[id] = result;
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// FARM CARD PRINCIPALE
// ─────────────────────────────────────────────────────────────────────────────
class FarmCard extends StatefulWidget {
  final Map<String, dynamic> farm;
  final int farmId;
  final String name;
  final String location;
  final String? image;
  final bool isOwner;
  final bool dark;
  final Future<List<dynamic>> cropsFuture;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onParcelles;
  final void Function(int parcelId) onParcelTap;
  final void Function(BuildContext, String, String) onPhotoTap;

  const FarmCard({
    super.key,
    required this.farm,
    required this.farmId,
    required this.name,
    required this.location,
    required this.image,
    required this.isOwner,
    required this.dark,
    required this.cropsFuture,
    required this.onEdit,
    required this.onDelete,
    required this.onParcelles,
    required this.onParcelTap,
    required this.onPhotoTap,
  });

  @override
  State<FarmCard> createState() => _FarmCardState();
}

class _FarmCardState extends State<FarmCard> {
  final Map<int, Offset> _pinOffsets = {};
  int? _draggingPin;
  int _maxVisible = 6;

  static const _zones = [
    (dx: 0.22, dy: 0.28),
    (dx: 0.58, dy: 0.20),
    (dx: 0.78, dy: 0.40),
    (dx: 0.16, dy: 0.55),
    (dx: 0.62, dy: 0.54),
    (dx: 0.40, dy: 0.38),
  ];

  @override
  void initState() {
    super.initState();
    _loadPinOffsets();
  }

  @override
  void dispose() {
    _savePinOffsets();
    super.dispose();
  }

  Future<void> _loadPinOffsets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('pins_${widget.farmId}');
      if (raw != null) {
        final data = jsonDecode(raw) as Map<String, dynamic>;
        if (mounted) {
          setState(() {
            data.forEach((k, v) {
              _pinOffsets[int.parse(k)] = Offset(v['dx'] as double, v['dy'] as double);
            });
          });
        }
      }
    } catch (_) {}
  }

  Future<void> _savePinOffsets() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = <String, dynamic>{};
      _pinOffsets.forEach((k, v) {
        data[k.toString()] = {'dx': v.dx, 'dy': v.dy};
      });
      await prefs.setString('pins_${widget.farmId}', jsonEncode(data));
    } catch (_) {}
  }

  Offset _defaultOffset(int i, double dx, double dy, double w, double h, bool hasPhoto) {
    final px = dx * w;
    final py = dy * h;
    final alignRight = dx > 0.5;
    final alignTop = dy < 0.5;
    const tw = 92.0;
    const th = 80.0;
    const ttW = 100.0;
    const ttH = 26.0;
    const gap = 14.0;
    const line = 28.0;
    
    if (hasPhoto) {
      return Offset(
        (alignRight ? px - gap - tw : px + gap).clamp(2.0, w - tw - 2),
        (alignTop ? py - line - th : py + line).clamp(2.0, h - th - 36),
      );
    }
    return Offset(
      (alignRight ? px - gap - ttW : px + gap).clamp(2.0, w - ttW - 2),
      (alignTop ? py - line - ttH : py + line).clamp(2.0, h - ttH - 36),
    );
  }

  Widget _placeholder() => Container(
        color: widget.dark ? AppColors.darkCardBg : AppColors.lightCardBg,
        child: Center(
          child: Icon(
            Icons.landscape_outlined,
            size: 36,
            color: (widget.dark ? Colors.white : Colors.black).withOpacity(0.08),
          ),
        ),
      );

  Widget _buildPin(Map<String, dynamic> crop, double dx, double dy,
      double w, double h, BuildContext ctx, int idx) {
    final name = (crop['crop_name'] ?? '').toString();
    final photo = (crop['image_url'] ?? crop['photo_url'] ?? crop['photo'] ?? '') as String;
    final hasPhoto = photo.isNotEmpty;
    final sc = _statusColor(crop);
    final px = dx * w;
    final py = dy * h;
    const tw = 92.0;
    const th = 80.0;
    const ttW = 100.0;
    const ttH = 26.0;

    _pinOffsets.putIfAbsent(
        idx, () => _defaultOffset(idx, dx, dy, w, h, hasPhoto));
    final offset = _pinOffsets[idx]!;
    final isDragging = _draggingPin == idx;
    final tipCenter = Offset(
        offset.dx + (hasPhoto ? tw : ttW) / 2,
        offset.dy + (hasPhoto ? th : ttH) / 2);

    return Stack(clipBehavior: Clip.none, children: [
      // Connecteur
      Positioned.fill(
        child: IgnorePointer(
          child: CustomPaint(
            painter: _DynamicLinePainter(
                from: Offset(px, py),
                to: tipCenter,
                dragging: isDragging,
                color: sc),
          ),
        ),
      ),
      // Dot pulsant
      Positioned(
        left: px - 5,
        top: py - 5,
        child: _PulsingDot(color: isDragging ? sc : sc.withOpacity(0.85)),
      ),
      // Tooltip draggable
      Positioned(
        left: offset.dx,
        top: offset.dy,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: hasPhoto && !isDragging
              ? () => widget.onPhotoTap(ctx, name, photo)
              : null,
          onPanStart: (_) => setState(() => _draggingPin = idx),
          onPanUpdate: (d) {
            setState(() {
              final next = _pinOffsets[idx]! + d.delta;
              _pinOffsets[idx] = Offset(
                next.dx.clamp(2.0, w - (hasPhoto ? tw : ttW) - 2),
                next.dy.clamp(2.0, h - (hasPhoto ? th : ttH) - 2),
              );
            });
          },
          onPanEnd: (_) {
            setState(() => _draggingPin = null);
            _savePinOffsets();
          },
          child: AnimatedScale(
            scale: isDragging ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: hasPhoto
                ? _PhotoPin(
                    name: name,
                    photo: photo,
                    accent: sc,
                    isDragging: isDragging)
                : Container(
                    width: ttW,
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(isDragging ? 0.88 : 0.70),
                      border: Border.all(
                        color: isDragging
                            ? sc.withOpacity(0.8)
                            : Colors.white.withOpacity(0.18),
                        width: isDragging ? 1 : 0.5,
                      ),
                    ),
                    child: Text(
                        name.length > 13 ? name.substring(0, 13) : name,
                        style: const TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.8,
                            color: Colors.white),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ),
          ),
        ),
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 3 / 2,
      child: ClipRect(
        child: Stack(children: [
          // Image + pins
          Positioned.fill(
            child: Stack(fit: StackFit.expand, children: [
              widget.image != null && widget.image!.isNotEmpty
                  ? Image.network(widget.image!,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _placeholder())
                  : _placeholder(),

              // Gradients
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.30, 0.62, 1.0],
                      colors: [
                        Colors.black.withOpacity(0.40),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.82),
                      ],
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: Alignment.center,
                        radius: 1.0,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.22)
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // Pins
              FutureBuilder<List<dynamic>>(
                future: widget.cropsFuture,
                builder: (ctx, snap) {
                  if ((snap.data ?? []).isEmpty) {
                    return const SizedBox.shrink();
                  }
                  final all = snap.data!;
                  final crops = all.take(_maxVisible).toList();
                  final hasMore = all.length > _maxVisible;

                  return LayoutBuilder(builder: (_, box) {
                    final w = box.maxWidth;
                    final h = box.maxHeight;
                    return Stack(children: [
                      for (var i = 0;
                          i < crops.length && i < _zones.length;
                          i++)
                        if (i != _draggingPin)
                          KeyedSubtree(
                            key: ValueKey('p$i'),
                            child: _buildPin(
                                crops[i] as Map<String, dynamic>,
                                _zones[i].dx,
                                _zones[i].dy,
                                w,
                                h,
                                ctx,
                                i),
                          ),
                      if (_draggingPin != null &&
                          _draggingPin! < crops.length)
                        KeyedSubtree(
                          key: ValueKey('pd$_draggingPin'),
                          child: _buildPin(
                              crops[_draggingPin!] as Map<String, dynamic>,
                              _zones[_draggingPin!].dx,
                              _zones[_draggingPin!].dy,
                              w,
                              h,
                              ctx,
                              _draggingPin!),
                        ),
                      if (hasMore)
                        Positioned(
                          bottom: 8,
                          right: 8,
                          child: GestureDetector(
                            onTap: () => setState(() => _maxVisible += 6),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.65),
                                  border: Border.all(
                                      color: AppColors.accent.withOpacity(0.5),
                                      width: 0.8)),
                              child: Text(
                                  'VOIR +${all.length - _maxVisible}',
                                  style: const TextStyle(
                                      fontSize: 8,
                                      letterSpacing: 1.2,
                                      color: Colors.white70)),
                            ),
                          ),
                        ),
                    ]);
                  });
                },
              ),
            ]),
          ),

          // Overlays fixes
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 80,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.90)
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Nom + lieu + bouton
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: IgnorePointer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.name.toUpperCase(),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 2.5,
                                color: Colors.white),
                          ),
                          if (widget.location.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(children: [
                              const Icon(Icons.place_outlined,
                                  size: 10, color: Colors.white54),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  widget.location,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 0.4,
                                      color: Colors.white54),
                                ),
                              ),
                            ]),
                          ],
                        ],
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: widget.onParcelles,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.50),
                          border: Border.all(
                              color: Colors.white.withOpacity(0.25),
                              width: 0.5)),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: const [
                            Text('PARCELLES',
                                style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.4,
                                    color: Colors.white70)),
                            SizedBox(width: 5),
                            Icon(Icons.arrow_forward_ios,
                                size: 8, color: Colors.white54),
                          ]),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Boutons owner
          if (widget.isOwner)
            Positioned(
              top: 10,
              right: 10,
              child: Row(children: [
                OwnerButton(
                    icon: Icons.edit_outlined,
                    onTap: widget.onEdit),
                const SizedBox(width: 6),
                OwnerButton(
                    icon: Icons.delete_outlined,
                    onTap: widget.onDelete,
                    danger: true),
              ]),
            ),

          // Badge satellite
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black.withOpacity(0.42),
              child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: const [
                    Icon(Icons.satellite_alt_outlined,
                        size: 9, color: Colors.white38),
                    SizedBox(width: 4),
                    Text('VUE AÉRIENNE',
                        style: TextStyle(
                            fontSize: 7,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.2,
                            color: Colors.white38)),
                  ]),
            ),
          ),
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS & ANIMATIONS
// ─────────────────────────────────────────────────────────────────────────────
class _DynamicLinePainter extends CustomPainter {
  final Offset from;
  final Offset to;
  final bool dragging;
  final Color color;

  const _DynamicLinePainter({
    required this.from,
    required this.to,
    required this.dragging,
    this.color = Colors.white,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withOpacity(dragging ? 0.7 : 0.45)
      ..strokeWidth = dragging ? 1.2 : 0.7
      ..style = PaintingStyle.stroke;

    final mid = Offset(from.dx, (from.dy + to.dy) / 2);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(mid.dx, mid.dy)
      ..lineTo(to.dx, mid.dy)
      ..lineTo(to.dx, to.dy);
    canvas.drawPath(path, paint);
    canvas.drawCircle(
        to, 2, Paint()..color = color.withOpacity(dragging ? 0.7 : 0.3));
  }

  @override
  bool shouldRepaint(_DynamicLinePainter old) =>
      old.from != from ||
      old.to != to ||
      old.dragging != dragging ||
      old.color != color;
}

class _PhotoPin extends StatelessWidget {
  final String name;
  final String photo;
  final Color accent;
  final bool isDragging;

  const _PhotoPin({
    required this.name,
    required this.photo,
    required this.accent,
    this.isDragging = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      decoration: BoxDecoration(
        border: Border.all(
            color: accent.withOpacity(isDragging ? 0.85 : 0.6),
            width: isDragging ? 1.5 : 1),
        boxShadow: [
          BoxShadow(
              color: accent.withOpacity(isDragging ? 0.35 : 0.25),
              blurRadius: isDragging ? 14 : 8)
        ],
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        SizedBox(
          height: 56,
          child: Stack(fit: StackFit.expand, children: [
            Image.network(photo,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                    color: Colors.black54,
                    child: const Icon(Icons.grass_outlined,
                        size: 18, color: Colors.white24))),
            Positioned(
              top: 3,
              right: 3,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accent,
                    boxShadow: [
                      BoxShadow(color: accent, blurRadius: 4)
                    ]),
              ),
            ),
          ]),
        ),
        Container(
          color: Colors.black.withOpacity(0.75),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
          child: Row(children: [
            Expanded(
              child: Text(
                  name.length > 10 ? name.substring(0, 10) : name,
                  style: const TextStyle(
                      fontSize: 7,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.8,
                      color: Colors.white),
                  maxLines: 1),
            ),
            Icon(Icons.open_in_full,
                size: 7, color: Colors.white.withOpacity(0.4)),
          ]),
        ),
      ]),
    );
  }
}

class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 1600))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = Curves.easeOut.transform(_ctrl.value);
        return SizedBox(
          width: 20,
          height: 20,
          child: Stack(alignment: Alignment.center, children: [
            Container(
              width: 8 + t * 14,
              height: 8 + t * 14,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: widget.color.withOpacity((1 - t) * 0.7),
                      width: 1)),
            ),
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  border: Border.all(color: widget.color, width: 1.5)),
            ),
          ]),
        );
      },
    );
  }
}