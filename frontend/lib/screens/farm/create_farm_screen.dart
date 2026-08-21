import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/screens/farm/map_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:flutter/foundation.dart';
import 'dart:math';

// ─────────────────────────────────────────────────────────────────────────────
// GRAIN PAINTER — même style que le dashboard
// ─────────────────────────────────────────────────────────────────────────────
class _GrainPainter extends CustomPainter {
  final double seed;
  final Color color;
  _GrainPainter({required this.seed, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random((seed * 1000).toInt());
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 200; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 0.9 + 0.2;
      final op = rng.nextDouble() * 0.035 + 0.005;
      paint.color = color.withOpacity(op);
      canvas.drawCircle(Offset(x, y), r, paint);
    }
  }

  @override
  bool shouldRepaint(_GrainPainter o) => o.seed != seed;
}

// ─────────────────────────────────────────────────────────────────────────────
// FIELD SILHOUETTE PAINTER — silhouette de champ avec épis
// ─────────────────────────────────────────────────────────────────────────────
class _FieldPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final double phase;
  final bool isDark;

  _FieldPainter({
    required this.primary,
    required this.accent,
    required this.phase,
    required this.isDark,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseOp = isDark ? 0.22 : 0.14;

    // Sol / ground layer 1
    final ground1 = Path();
    ground1.moveTo(0, h);
    ground1.lineTo(0, h * 0.58);
    for (double x = 0; x <= w; x += 2) {
      final y = h * 0.58
          + 3 * sin(x / w * pi * 2 + phase * 2 * pi * 0.4)
          + 1.5 * sin(x / w * pi * 5 - phase * 2 * pi * 0.6);
      ground1.lineTo(x, y);
    }
    ground1.lineTo(w, h);
    ground1.close();
    canvas.drawPath(
      ground1,
      Paint()..color = primary.withOpacity(baseOp),
    );

    // Sol / ground layer 2
    final ground2 = Path();
    ground2.moveTo(0, h);
    ground2.lineTo(0, h * 0.72);
    for (double x = 0; x <= w; x += 2) {
      final y = h * 0.72
          + 2 * sin(x / w * pi * 3 + phase * 2 * pi * 0.5 + 1.0);
      ground2.lineTo(x, y);
    }
    ground2.lineTo(w, h);
    ground2.close();
    canvas.drawPath(
      ground2,
      Paint()..color = primary.withOpacity(baseOp * 0.55),
    );

    // Sillons
    for (int row = 0; row < 3; row++) {
      final yBase = h * (0.75 + row * 0.07);
      final rowPath = Path();
      rowPath.moveTo(w * 0.05, yBase);
      for (double x = w * 0.05; x <= w * 0.95; x += 2) {
        final y = yBase + 0.7 * sin(x / w * pi * 6 + phase * 2 * pi * 0.3 + row * 0.9);
        rowPath.lineTo(x, y);
      }
      canvas.drawPath(
        rowPath,
        Paint()
          ..color = primary.withOpacity(baseOp * 0.38)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.6,
      );
    }

    // Épis de blé
    final stemPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1
      ..strokeCap = StrokeCap.round;
    final grainFill = Paint()..style = PaintingStyle.fill;

    final List<double> stalks = [0.10, 0.22, 0.40, 0.58, 0.72, 0.88];
    for (int i = 0; i < stalks.length; i++) {
      final sx = w * stalks[i];
      final sway = 1.4 * sin(phase * 2 * pi + i * 1.1);
      final stemTop = h * 0.18 + (i % 2) * h * 0.05;

      // Tige
      final stem = Path();
      stem.moveTo(sx, h * 0.60);
      stem.cubicTo(
        sx + sway * 0.3, h * 0.45,
        sx + sway, h * 0.32,
        sx + sway, stemTop,
      );
      stemPaint.color = primary.withOpacity(baseOp * 0.8);
      canvas.drawPath(stem, stemPaint);

      // Feuilles
      final lx = sx + sway * 0.5;
      final ly = h * 0.42 + (i % 2) * h * 0.04;
      final leaf = Path();
      leaf.moveTo(lx, ly);
      leaf.cubicTo(
        lx - w * 0.06, ly - h * 0.03,
        lx - w * 0.10, ly + h * 0.02,
        lx - w * 0.08, ly + h * 0.05,
      );
      leaf.cubicTo(
        lx - w * 0.04, ly + h * 0.03,
        lx - w * 0.01, ly + h * 0.01,
        lx, ly,
      );
      grainFill.color = accent.withOpacity(isDark ? 0.30 : 0.22);
      canvas.drawPath(leaf, grainFill);

      // Épis
      final gx = sx + sway;
      for (int g = 0; g < 5; g++) {
        final gy = stemTop - g * h * 0.024;
        final gw = (5 - g) * w * 0.012 * (1 + 0.04 * sin(phase * 2 * pi + g));
        grainFill.color = primary.withOpacity(baseOp + g * 0.014);
        canvas.drawOval(
          Rect.fromCenter(center: Offset(gx - gw * 0.55, gy), width: gw * 0.8, height: h * 0.018),
          grainFill,
        );
        canvas.drawOval(
          Rect.fromCenter(center: Offset(gx + gw * 0.55, gy), width: gw * 0.8, height: h * 0.018),
          grainFill,
        );
      }
    }
  }

  @override
  bool shouldRepaint(_FieldPainter o) => o.phase != phase || o.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION TITLE WIDGET — cohérent avec le dashboard
// ─────────────────────────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 20, height: 1, color: AppColors.primary),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            letterSpacing: 2.8,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Container(height: 1, color: AppColors.primary.withOpacity(0.12)),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// FARM TYPE BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _TypeButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _TypeButton({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? AppColors.darkCardBg : AppColors.primary)
              : (isDark ? const Color(0xFF1C1410) : const Color(0xFFFAF8F4)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 20,
              color: selected
                  ? AppColors.accent
                  : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w400 : FontWeight.w300,
                color: selected
                    ? Colors.white
                    : (isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class CreateFarmScreen extends StatefulWidget {
  final int? userId;
  const CreateFarmScreen({super.key, this.userId});

  @override
  State<CreateFarmScreen> createState() => _CreateFarmScreenState();
}

class _CreateFarmScreenState extends State<CreateFarmScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _regionCtrl = TextEditingController();
  final _departmentCtrl = TextEditingController();
  final _communeCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _sizeCtrl = TextEditingController();

  final _nameFocus = FocusNode();
  final _regionFocus = FocusNode();
  final _departmentFocus = FocusNode();
  final _communeFocus = FocusNode();
  final _descFocus = FocusNode();
  final _sizeFocus = FocusNode();

  String _type = 'Agricole';
  String? _location;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  bool _loading = false;
  bool _isPublic = true;

  // Animations
  late AnimationController _waveCtrl;
  late AnimationController _grainCtrl;
  late AnimationController _entryCtrl;
  late List<Animation<double>> _fade;
  late List<Animation<Offset>> _slide;

  @override
  void initState() {
    super.initState();
    _waveCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 9),
    )..repeat(reverse: true);

    _grainCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
    )..repeat();

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fade = List.generate(
      8,
      (i) => Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(
            i * 0.07,
            (i * 0.07 + 0.50).clamp(0.0, 1.0),
            curve: Curves.easeOut,
          ),
        ),
      ),
    );

    _slide = List.generate(
      8,
      (i) => Tween<Offset>(
        begin: const Offset(0, 0.12),
        end: Offset.zero,
      ).animate(
        CurvedAnimation(
          parent: _entryCtrl,
          curve: Interval(
            i * 0.07,
            (i * 0.07 + 0.50).clamp(0.0, 1.0),
            curve: Curves.easeOutCubic,
          ),
        ),
      ),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryCtrl.forward();
    });
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _grainCtrl.dispose();
    _entryCtrl.dispose();
    _nameCtrl.dispose();
    _regionCtrl.dispose();
    _departmentCtrl.dispose();
    _communeCtrl.dispose();
    _descCtrl.dispose();
    _sizeCtrl.dispose();
    _nameFocus.dispose();
    _regionFocus.dispose();
    _departmentFocus.dispose();
    _communeFocus.dispose();
    _descFocus.dispose();
    _sizeFocus.dispose();
    super.dispose();
  }

  Widget _s(int i, Widget child) => FadeTransition(
        opacity: _fade[i],
        child: SlideTransition(position: _slide[i], child: child),
      );

  Future<void> _pickLocation() async {
    HapticFeedback.mediumImpact();
    final result = await Navigator.push<String?>(
      context,
      MaterialPageRoute(builder: (_) => const MapPickerScreen()),
    );
    if (result != null && result.isNotEmpty) {
      setState(() => _location = result);
    }
  }

  Future<void> _pickImage() async {
    HapticFeedback.mediumImpact();
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600,
      imageQuality: 85,
    );
    if (picked != null) {
      final bytes = await picked.readAsBytes();
      setState(() {
        _imageFile = picked;
        _imageBytes = bytes;
      });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    final userId = widget.userId ?? AuthService.currentSession?.userId;
    if (userId == null || userId <= 0) {
      _showError('Utilisateur non connecté');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      String? uploadedUrl;
      double? lat;
      double? lng;
      if (_imageFile != null) {
        _imageBytes = await _imageFile!.readAsBytes();
        final url = await ApiService.uploadImageToCloudinary(_imageFile!);
        if (url == null) throw Exception('Échec de l\'upload de l\'image');
        uploadedUrl = url;
      }
      if (_location != null && _location!.contains(',')) {
        final parts = _location!.split(',');
        lat = double.tryParse(parts[0]);
        lng = double.tryParse(parts[1]);
      }
      final res = await ApiService.createFarm(
        userId: userId,
        name: _nameCtrl.text.trim(),
        location: _location ?? '${_regionCtrl.text} / ${_communeCtrl.text}',
        sizeHectares: _sizeCtrl.text.isNotEmpty ? double.tryParse(_sizeCtrl.text) : null,
        soilType: _type,
        imageUrl: uploadedUrl,
        latitude: lat,
        longitude: lng,
      );
      if (!_isPublic && res['id'] != null) {
        try {
          await ApiService.toggleFarmVisibility(
            userId: userId,
            farmId: res['id'] as int,
            isPublic: _isPublic,
          );
        } catch (e) {
          debugPrint('Warning: $e');
        }
      }
      _showSuccess('Ferme créée avec succès !');
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) Navigator.pop(context, res);
    } catch (e) {
      _showError('Erreur : ${e.toString()}');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppColors.createSnackBar(message: msg, isError: false, durationMs: 800),
    );
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppColors.createSnackBar(message: msg, isError: true),
    );
  }

  // ─── COLORS — palette douce, cohérente avec le dashboard original ─────────
  Color _bg(bool isDark) => isDark ? AppColors.darkBg : AppColors.lightBg;
  Color _card(bool isDark) => isDark ? AppColors.darkCardBg : const Color(0xFFFAF8F4);
  Color _border(bool isDark) => isDark ? AppColors.borderDark : AppColors.borderLight;
  Color _text(bool isDark) => isDark ? AppColors.textDark : AppColors.textLight;
  Color _textSec(bool isDark) => isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  // ─── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: _bg(isDark),
      resizeToAvoidBottomInset: true,
      body: Column(
        children: [
          _buildHeroHeader(isDark),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.only(
                left: 20,
                right: 20,
                top: 24,
                bottom: MediaQuery.of(context).viewInsets.bottom + 32,
              ),
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: GestureDetector(
                onTap: () => FocusScope.of(context).unfocus(),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _s(0, _buildImagePicker(isDark)),
                      const SizedBox(height: 28),
                      _s(1, _SectionTitle('Informations de base')),
                      const SizedBox(height: 14),
                      _s(1, _buildInfoSection(isDark)),
                      const SizedBox(height: 28),
                      _s(2, _SectionTitle('Localisation')),
                      const SizedBox(height: 14),
                      _s(2, _buildLocationSection(isDark)),
                      const SizedBox(height: 28),
                      _s(3, _SectionTitle('Paramètres')),
                      const SizedBox(height: 14),
                      _s(3, _buildVisibilityToggle(isDark)),
                      const SizedBox(height: 28),
                      _s(4, _SectionTitle('Description')),
                      const SizedBox(height: 14),
                      _s(4, _buildDescField(isDark)),
                      const SizedBox(height: 36),
                      _s(5, _buildSubmitButton()),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── HERO HEADER — dark soil, grain, field silhouette, animated ──────────
  Widget _buildHeroHeader(bool isDark) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 160,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Dark soil gradient
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isDark
                        ? [Color(0xFF18100A), Color(0xFF0C0804)]
                        : [Color(0xFFFFF8EE), Color(0xFFEEE2CC)],
                  ),
                ),
              ),
            ),

            // Grain texture
            Positioned.fill(
              child: AnimatedBuilder(
                animation: _grainCtrl,
                builder: (_, __) => CustomPaint(
                  painter: _GrainPainter(
                    seed: _grainCtrl.value,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),

            // Rings
            Positioned(
              top: -50,
              right: -50,
              child: SizedBox(
                width: 200,
                height: 200,
                child: CustomPaint(
                  painter: _RingsPainter(color: AppColors.primary),
                ),
              ),
            ),

            // Glow
            Positioned(
              top: -60,
              right: -60,
              child: Container(
                width: 180,
                height: 180,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      AppColors.accent.withOpacity(0.18),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Field silhouette
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 90,
                child: AnimatedBuilder(
                  animation: _waveCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _FieldPainter(
                      primary: AppColors.primary,
                      accent: AppColors.accent,
                      phase: _waveCtrl.value,
                      isDark: true,
                    ),
                  ),
                ),
              ),
            ),

            // Content
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Back + tag row
                  Row(
                    children: [
                      GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          FocusScope.of(context).unfocus();
                          Navigator.pop(context);
                        },
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.accent,
                            size: 17,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.eco_outlined,
                              size: 10,
                              color: AppColors.accent.withOpacity(0.85),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'NOUVELLE FERME',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.8,
                                color: AppColors.accent.withOpacity(0.85),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Title
                  Text(
                    'Créer',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: AppColors.accent.withOpacity(0.70),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'une ferme',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w200,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                      letterSpacing: -1.5,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── IMAGE PICKER ─────────────────────────────────────────────────────────
  Widget _buildImagePicker(bool isDark) {
    return GestureDetector(
      onTap: _pickImage,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        height: 180,
        width: double.infinity,
        decoration: BoxDecoration(
          color: _imageBytes == null
              ? (AppColors.primaryLight.withOpacity(isDark ? 0.08 : 0.06))
              : null,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _imageBytes == null
                ? AppColors.primary.withOpacity(0.25)
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: _imageBytes == null
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_photo_alternate_outlined,
                      size: 22,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ajouter une photo',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    'Touchez pour sélectionner · max 5 Mo',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w300,
                      color: _textSec(isDark),
                    ),
                  ),
                ],
              )
            : ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.memory(_imageBytes!, fit: BoxFit.cover, cacheWidth: 800),
                    Positioned(
                      top: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.edit_outlined, color: Colors.white, size: 13),
                            SizedBox(width: 4),
                            Text(
                              'Modifier',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white,
                                fontWeight: FontWeight.w300,
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
    );
  }

  // ─── INFO SECTION ─────────────────────────────────────────────────────────
  Widget _buildInfoSection(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: _buildField(
                controller: _nameCtrl,
                focusNode: _nameFocus,
                label: 'NOM DE LA FERME',
                hint: 'Ex: Ferme Keur Moussa',
                icon: Icons.agriculture_outlined,
                isDark: isDark,
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                textInputAction: TextInputAction.next,
                onSubmitted: () => FocusScope.of(context).requestFocus(_sizeFocus),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 2,
              child: _buildField(
                controller: _sizeCtrl,
                focusNode: _sizeFocus,
                label: 'SUPERFICIE (HA)',
                hint: 'Ex: 18.5',
                icon: Icons.square_foot_outlined,
                isDark: isDark,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                textInputAction: TextInputAction.next,
                onSubmitted: () =>
                    FocusScope.of(context).requestFocus(_regionFocus),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildTypeSelector(isDark),
      ],
    );
  }

  // ─── LOCATION SECTION ────────────────────────────────────────────────────
  Widget _buildLocationSection(bool isDark) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildField(
                controller: _regionCtrl,
                focusNode: _regionFocus,
                label: 'RÉGION',
                hint: 'Ex: Thiès',
                icon: Icons.location_on_outlined,
                isDark: isDark,
                textInputAction: TextInputAction.next,
                onSubmitted: () =>
                    FocusScope.of(context).requestFocus(_departmentFocus),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _buildField(
                controller: _departmentCtrl,
                focusNode: _departmentFocus,
                label: 'DÉPARTEMENT',
                hint: 'Ex: Mbour',
                icon: Icons.map_outlined,
                isDark: isDark,
                textInputAction: TextInputAction.next,
                onSubmitted: () =>
                    FocusScope.of(context).requestFocus(_communeFocus),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        _buildField(
          controller: _communeCtrl,
          focusNode: _communeFocus,
          label: 'COMMUNE / VILLAGE',
          hint: 'Ex: Saly',
          icon: Icons.home_outlined,
          isDark: isDark,
          textInputAction: TextInputAction.next,
          onSubmitted: () => FocusScope.of(context).requestFocus(_descFocus),
        ),
        const SizedBox(height: 10),
        _buildMapPicker(isDark),
      ],
    );
  }

  // ─── FIELD WIDGET ─────────────────────────────────────────────────────────
  Widget _buildField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    int maxLines = 1,
    TextInputAction textInputAction = TextInputAction.next,
    VoidCallback? onSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.8,
            color: _textSec(isDark),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _card(isDark),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border(isDark), width: 1),
          ),
          child: TextFormField(
            controller: controller,
            focusNode: focusNode,
            validator: validator,
            keyboardType: keyboardType,
            maxLines: maxLines,
            minLines: maxLines == 1 ? 1 : 3,
            textInputAction: textInputAction,
            onFieldSubmitted: (_) => onSubmitted?.call(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: _text(isDark),
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: _textSec(isDark),
                fontWeight: FontWeight.w300,
                fontSize: 13,
              ),
              prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 13,
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─── TYPE SELECTOR ────────────────────────────────────────────────────────
  Widget _buildTypeSelector(bool isDark) {
    const types = [
      {'value': 'Agricole', 'icon': Icons.grass_outlined, 'label': 'Agricole'},
      {'value': 'Élevage', 'icon': Icons.agriculture_outlined, 'label': 'Élevage'},
      {'value': 'Mixte', 'icon': Icons.forest_outlined, 'label': 'Mixte'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TYPE DE FERME',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.8,
            color: _textSec(isDark),
          ),
        ),
        const SizedBox(height: 8),
        Row(
          children: types.map((t) {
            final isSelected = _type == t['value'] as String;
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.only(right: 8),
                child: _TypeButton(
                  icon: t['icon'] as IconData,
                  label: t['label'] as String,
                  selected: isSelected,
                  isDark: isDark,
                  onTap: () => setState(() => _type = t['value'] as String),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── MAP PICKER ───────────────────────────────────────────────────────────
  Widget _buildMapPicker(bool isDark) {
    final hasLocation = _location != null;
    return GestureDetector(
      onTap: _pickLocation,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: hasLocation
              ? AppColors.primary.withOpacity(isDark ? 0.18 : 0.06)
              : _card(isDark),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: hasLocation ? AppColors.primary.withOpacity(0.40) : _border(isDark),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: hasLocation
                    ? AppColors.primary
                    : AppColors.primary.withOpacity(0.10),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                Icons.map_outlined,
                color: hasLocation ? Colors.white : AppColors.primary,
                size: 17,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    hasLocation ? 'Localisation définie' : 'Définir sur la carte',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: _text(isDark),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    _location ?? 'Sélectionner un emplacement GPS précis',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w300,
                      color: _textSec(isDark),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: _textSec(isDark),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  // ─── VISIBILITY TOGGLE ────────────────────────────────────────────────────
  Widget _buildVisibilityToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: _card(isDark),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _border(isDark), width: 1),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: (_isPublic
                      ? AppColors.primary
                      : AppColors.textSecondaryLight)
                  .withOpacity(0.12),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              _isPublic ? Icons.public_outlined : Icons.lock_outlined,
              color: _isPublic
                  ? AppColors.primary
                  : AppColors.textSecondaryLight,
              size: 17,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isPublic ? 'Ferme publique' : 'Ferme privée',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    color: _text(isDark),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  _isPublic
                      ? 'Visible par les autres agriculteurs'
                      : 'Visible pour vous uniquement',
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w300,
                    color: _textSec(isDark),
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _isPublic,
            onChanged: (v) {
              HapticFeedback.lightImpact();
              setState(() => _isPublic = v);
            },
            activeColor: AppColors.primary,
            activeTrackColor: AppColors.primary.withOpacity(0.25),
            inactiveTrackColor: _border(isDark),
            inactiveThumbColor: _textSec(isDark),
          ),
        ],
      ),
    );
  }

  // ─── DESC FIELD ───────────────────────────────────────────────────────────
  Widget _buildDescField(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DESCRIPTION (OPTIONNEL)',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.8,
            color: _textSec(isDark),
          ),
        ),
        const SizedBox(height: 6),
        Container(
          decoration: BoxDecoration(
            color: _card(isDark),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: _border(isDark), width: 1),
          ),
          child: TextFormField(
            controller: _descCtrl,
            focusNode: _descFocus,
            maxLines: 4,
            minLines: 3,
            textInputAction: TextInputAction.done,
            onFieldSubmitted: (_) => FocusScope.of(context).unfocus(),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: _text(isDark),
              height: 1.55,
            ),
            decoration: InputDecoration(
              hintText:
                  'Décrivez votre ferme, ses spécificités, les cultures pratiquées…',
              hintStyle: TextStyle(
                color: _textSec(isDark),
                fontWeight: FontWeight.w300,
                fontSize: 13,
                height: 1.55,
              ),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Icon(Icons.text_snippet_outlined,
                    color: AppColors.primary, size: 18),
              ),
              prefixIconConstraints:
                  const BoxConstraints(minWidth: 46, minHeight: 48),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
            ),
          ),
        ),
      ],
    );
  }

  // ─── SUBMIT BUTTON ────────────────────────────────────────────────────────
  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: AppColors.primary,
        child: InkWell(
          onTap: _loading ? null : _submit,
          borderRadius: BorderRadius.circular(12),
          splashColor: AppColors.primaryLight.withOpacity(0.12),
          child: Center(
            child: _loading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.8,
                      color: AppColors.accent,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_circle_outline,
                        color: AppColors.accent,
                        size: 18,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Créer la ferme',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                          letterSpacing: 0.2,
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
// RINGS PAINTER (same as dashboard)
// ─────────────────────────────────────────────────────────────────────────────
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
    for (int i = 1; i <= 5; i++) {
      paint.color = color.withOpacity(0.025 + i * 0.008);
      canvas.drawCircle(Offset(cx, cy), i * 36.0, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter o) => false;
}