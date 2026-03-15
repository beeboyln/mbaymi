import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'dart:math';

// ─────────────────────────────────────────────────────────────────────────────
// GRAIN PAINTER
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
// RINGS PAINTER
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

// ─────────────────────────────────────────────────────────────────────────────
// LIVESTOCK ILLUSTRATION PAINTER
// Silhouette pastorale : sol ondulé + animaux stylisés
// ─────────────────────────────────────────────────────────────────────────────
class _LivestockIllustrationPainter extends CustomPainter {
  final Color primary;
  final Color accent;
  final bool isDark;
  final double phase;

  const _LivestockIllustrationPainter({
    required this.primary,
    required this.accent,
    required this.isDark,
    required this.phase,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final baseOp = isDark ? 0.22 : 0.15;

    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    // Sol ondulé
    final ground = Path();
    ground.moveTo(0, h);
    ground.lineTo(0, h * 0.68);
    for (double x = 0; x <= w; x += 2) {
      final y = h * 0.68
          + 2.5 * sin(x / w * pi * 2 + phase * 2 * pi * 0.4)
          + 1.2 * sin(x / w * pi * 5 - phase * 2 * pi * 0.6);
      ground.lineTo(x, y);
    }
    ground.lineTo(w, h);
    ground.close();
    fill.color = primary.withOpacity(baseOp);
    canvas.drawPath(ground, fill);

    // Herbe (touffes)
    final grassPaint = Paint()
      ..color = accent.withOpacity(isDark ? 0.32 : 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;
    for (int g = 0; g < 5; g++) {
      final gx = w * (0.08 + g * 0.21);
      final gy = h * 0.68 + 1.5 * sin(gx / w * pi * 2 + phase * 2 * pi * 0.4);
      final sway = 0.8 * sin(phase * 2 * pi + g * 1.3);
      canvas.drawLine(
        Offset(gx, gy),
        Offset(gx + sway - 3, gy - h * 0.06),
        grassPaint,
      );
      canvas.drawLine(
        Offset(gx, gy),
        Offset(gx + sway, gy - h * 0.07),
        grassPaint,
      );
      canvas.drawLine(
        Offset(gx, gy),
        Offset(gx + sway + 3, gy - h * 0.055),
        grassPaint,
      );
    }

    // Animal 1 — bovin stylisé (gauche)
    _drawAnimal(canvas, w * 0.22, h * 0.54, h * 0.20, primary, accent, baseOp, phase, false);

    // Animal 2 — bovin stylisé (droite, plus petit = profondeur)
    _drawAnimal(canvas, w * 0.68, h * 0.57, h * 0.155, primary, accent, baseOp * 0.7, phase, true);
  }

  void _drawAnimal(
    Canvas canvas,
    double cx,
    double cy,
    double size,
    Color primary,
    Color accent,
    double op,
    double phase,
    bool mirrored,
  ) {
    final fill = Paint()..style = PaintingStyle.fill;
    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..strokeCap = StrokeCap.round;

    final dir = mirrored ? -1.0 : 1.0;

    // Corps
    fill.color = primary.withOpacity(op + 0.04);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(cx, cy),
        width: size * 1.8,
        height: size * 0.85,
      ),
      fill,
    );

    // Tête
    fill.color = primary.withOpacity(op + 0.06);
    final headX = cx + dir * size * 0.95;
    final headY = cy - size * 0.18;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headX, headY),
        width: size * 0.55,
        height: size * 0.48,
      ),
      fill,
    );

    // Museau
    fill.color = primary.withOpacity(op + 0.02);
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(headX + dir * size * 0.14, headY + size * 0.08),
        width: size * 0.28,
        height: size * 0.22,
      ),
      fill,
    );

    // Corne
    stroke.color = accent.withOpacity(op + 0.10);
    stroke.strokeWidth = 0.9;
    final hornBase = Offset(headX - dir * size * 0.05, headY - size * 0.20);
    canvas.drawLine(
      hornBase,
      Offset(hornBase.dx + dir * size * 0.12, hornBase.dy - size * 0.14),
      stroke,
    );

    // Jambes (légère oscillation)
    stroke.color = primary.withOpacity(op + 0.05);
    stroke.strokeWidth = size * 0.09;
    final legSwayFront = size * 0.04 * sin(phase * 2 * pi);
    final legSwayBack = size * 0.04 * sin(phase * 2 * pi + pi);
    final legY = cy + size * 0.40;
    final legLen = size * 0.42;

    // Patte avant
    canvas.drawLine(
      Offset(cx + dir * size * 0.48, cy + size * 0.36),
      Offset(cx + dir * size * 0.48 + legSwayFront, legY + legLen),
      stroke,
    );
    // Patte arrière
    canvas.drawLine(
      Offset(cx - dir * size * 0.48, cy + size * 0.36),
      Offset(cx - dir * size * 0.48 + legSwayBack, legY + legLen),
      stroke,
    );
    // Patte milieu avant
    canvas.drawLine(
      Offset(cx + dir * size * 0.18, cy + size * 0.40),
      Offset(cx + dir * size * 0.18 + legSwayFront * 0.5, legY + legLen * 0.95),
      stroke,
    );
    // Patte milieu arrière
    canvas.drawLine(
      Offset(cx - dir * size * 0.18, cy + size * 0.40),
      Offset(cx - dir * size * 0.18 + legSwayBack * 0.5, legY + legLen * 0.95),
      stroke,
    );

    // Queue
    stroke.color = primary.withOpacity(op + 0.04);
    stroke.strokeWidth = 0.9;
    final tailBase = Offset(cx - dir * size * 0.88, cy - size * 0.05);
    final tailEnd = Offset(
      tailBase.dx - dir * size * 0.18,
      tailBase.dy - size * 0.22 + size * 0.08 * sin(phase * 2 * pi + 1.0),
    );
    canvas.drawLine(tailBase, tailEnd, stroke);
  }

  @override
  bool shouldRepaint(_LivestockIllustrationPainter o) =>
      o.phase != phase || o.isDark != isDark;
}

// ─────────────────────────────────────────────────────────────────────────────
// SECTION TITLE — identique au CreateFarmScreen
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
          child: Container(
            height: 1,
            color: AppColors.primary.withOpacity(0.12),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// VISIBILITY OPTION BUTTON
// ─────────────────────────────────────────────────────────────────────────────
class _VisibilityButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final bool selected;
  final VoidCallback onTap;
  final bool isDark;

  const _VisibilityButton({
    required this.icon,
    required this.label,
    required this.description,
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
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: selected
              ? AppColors.primary.withOpacity(isDark ? 0.14 : 0.07)
              : (isDark ? AppColors.darkCardBg : const Color(0xFFFAF8F4)),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected
                ? AppColors.primary.withOpacity(0.50)
                : (isDark ? AppColors.borderDark : AppColors.borderLight),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                color: selected
                    ? AppColors.primary.withOpacity(0.15)
                    : AppColors.primary.withOpacity(0.07),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(
                icon,
                size: 16,
                color: selected
                    ? AppColors.primary
                    : (isDark
                        ? AppColors.textSecondaryDark
                        : AppColors.textSecondaryLight),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: selected ? FontWeight.w400 : FontWeight.w300,
                      color: isDark ? AppColors.textDark : AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    description,
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w300,
                      color: isDark
                          ? AppColors.textSecondaryDark
                          : AppColors.textSecondaryLight,
                    ),
                  ),
                ],
              ),
            ),
            AnimatedOpacity(
              opacity: selected ? 1 : 0,
              duration: const Duration(milliseconds: 180),
              child: Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: Colors.white,
                  size: 11,
                ),
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
class CreateLivestockScreen extends StatefulWidget {
  final int? userId;
  const CreateLivestockScreen({super.key, this.userId});

  @override
  State<CreateLivestockScreen> createState() => _CreateLivestockScreenState();
}

class _CreateLivestockScreenState extends State<CreateLivestockScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();

  final _animalTypeCtrl = TextEditingController();
  final _customAnimalTypeCtrl = TextEditingController();
  final _breedCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController(text: '1');
  final _ageCtrl = TextEditingController();
  final _weightCtrl = TextEditingController();
  final _healthCtrl = TextEditingController();
  final _feedingCtrl = TextEditingController();
  final _notesCtrl = TextEditingController();

  final _breedFocus = FocusNode();
  final _customTypeFocus = FocusNode();
  final _quantityFocus = FocusNode();
  final _ageFocus = FocusNode();
  final _weightFocus = FocusNode();
  final _notesFocus = FocusNode();

  bool _loading = false;
  final List<XFile> _imageFiles = [];
  final List<Uint8List> _imageBytesList = [];
  String _visibility = 'PRIVATE';

  // Animations
  late AnimationController _waveCtrl;
  late AnimationController _grainCtrl;
  late AnimationController _entryCtrl;
  late List<Animation<double>> _fade;
  late List<Animation<Offset>> _slide;

  static const _animalTypes = ['Bovins', 'Chèvres', 'Moutons', 'Volailles', 'Autre'];
  static const _healthStatuses = ['Sain', 'Malade', 'Vacciné', 'À surveiller'];
  static const _feedingTypes = ['Herbe', 'Grains', 'Mixte', 'Aliment composé'];

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
    _animalTypeCtrl.dispose();
    _customAnimalTypeCtrl.dispose();
    _breedCtrl.dispose();
    _quantityCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _healthCtrl.dispose();
    _feedingCtrl.dispose();
    _notesCtrl.dispose();
    _breedFocus.dispose();
    _customTypeFocus.dispose();
    _quantityFocus.dispose();
    _ageFocus.dispose();
    _weightFocus.dispose();
    _notesFocus.dispose();
    super.dispose();
  }

  Widget _s(int i, Widget child) => FadeTransition(
        opacity: _fade[i],
        child: SlideTransition(position: _slide[i], child: child),
      );

  // ─── COLORS ──────────────────────────────────────────────────────────────
  Color _bg(bool isDark) => isDark ? AppColors.darkBg : AppColors.lightBg;
  Color _card(bool isDark) => isDark ? AppColors.darkCardBg : const Color(0xFFFAF8F4);
  Color _border(bool isDark) => isDark ? AppColors.borderDark : AppColors.borderLight;
  Color _text(bool isDark) => isDark ? AppColors.textDark : AppColors.textLight;
  Color _textSec(bool isDark) =>
      isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;

  // ─── IMAGE PICKER ─────────────────────────────────────────────────────────
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
        _imageFiles.add(picked);
        _imageBytesList.add(bytes);
      });
    }
  }

  void _removeImage(int index) {
    HapticFeedback.lightImpact();
    setState(() {
      _imageFiles.removeAt(index);
      _imageBytesList.removeAt(index);
    });
  }

  // ─── SUBMIT ───────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    if (widget.userId == null) {
      _showError('Utilisateur non connecté');
      return;
    }
    String animalType = _animalTypeCtrl.text.trim();
    if (animalType == 'Autre') {
      if (_customAnimalTypeCtrl.text.trim().isEmpty) {
        _showError('Veuillez préciser le type d\'animal');
        return;
      }
      animalType = _customAnimalTypeCtrl.text.trim();
    }
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      String? imageUrl;
      if (_imageFiles.isNotEmpty) {
        imageUrl = await ApiService.uploadImageToCloudinary(_imageFiles[0]);
      }
      final res = await ApiService.createLivestock(
        userId: widget.userId!,
        animalType: animalType,
        breed: _breedCtrl.text.trim(),
        quantity: int.tryParse(_quantityCtrl.text) ?? 1,
        ageMonths: int.tryParse(_ageCtrl.text),
        weightKg: double.tryParse(_weightCtrl.text),
        healthStatus: _healthCtrl.text.trim(),
        feedingType: _feedingCtrl.text.trim(),
        notes: _notesCtrl.text.trim(),
        imageUrl: imageUrl,
        visibility: _visibility,
      );
      if (_imageFiles.length > 1) {
        final livestockId = res['id'] as int;
        for (int i = 1; i < _imageFiles.length; i++) {
          try {
            final url = await ApiService.uploadImageToCloudinary(_imageFiles[i]);
            if (url != null && url.isNotEmpty) {
              await ApiService.addAnimalPhoto(
                livestockId: livestockId,
                imageUrl: url,
              );
            }
          } catch (e) {
            debugPrint('Erreur upload photo $i: $e');
          }
        }
      }
      _showSuccess('Animal ajouté avec succès !');
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

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
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
                      // Type d'animal
                      _s(0, _SectionTitle('Type d\'animal')),
                      const SizedBox(height: 14),
                      _s(0, _buildAnimalTypeSelector(isDark)),
                      if (_animalTypeCtrl.text == 'Autre') ...[
                        const SizedBox(height: 10),
                        _s(0, _buildField(
                          controller: _customAnimalTypeCtrl,
                          focusNode: _customTypeFocus,
                          label: 'PRÉCISEZ LE TYPE',
                          hint: 'Ex: Lapins, Chevaux…',
                          icon: Icons.edit_outlined,
                          isDark: isDark,
                          textInputAction: TextInputAction.next,
                          onSubmitted: () =>
                              FocusScope.of(context).requestFocus(_breedFocus),
                        )),
                      ],
                      const SizedBox(height: 10),
                      _s(0, _buildField(
                        controller: _breedCtrl,
                        focusNode: _breedFocus,
                        label: 'RACE / VARIÉTÉ',
                        hint: 'Ex: Race locale, Zébu, Peul…',
                        icon: Icons.info_outlined,
                        isDark: isDark,
                        textInputAction: TextInputAction.next,
                        onSubmitted: () =>
                            FocusScope.of(context).requestFocus(_quantityFocus),
                      )),
                      const SizedBox(height: 28),

                      // Informations
                      _s(1, _SectionTitle('Informations')),
                      const SizedBox(height: 14),
                      _s(1, Row(
                        children: [
                          Expanded(
                            child: _buildField(
                              controller: _quantityCtrl,
                              focusNode: _quantityFocus,
                              label: 'QUANTITÉ',
                              hint: '1',
                              icon: Icons.format_list_numbered_outlined,
                              isDark: isDark,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              onSubmitted: () =>
                                  FocusScope.of(context).requestFocus(_ageFocus),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _buildField(
                              controller: _ageCtrl,
                              focusNode: _ageFocus,
                              label: 'ÂGE (MOIS)',
                              hint: 'Ex: 24',
                              icon: Icons.calendar_month_outlined,
                              isDark: isDark,
                              keyboardType: TextInputType.number,
                              textInputAction: TextInputAction.next,
                              onSubmitted: () =>
                                  FocusScope.of(context).requestFocus(_weightFocus),
                            ),
                          ),
                        ],
                      )),
                      const SizedBox(height: 10),
                      _s(1, _buildField(
                        controller: _weightCtrl,
                        focusNode: _weightFocus,
                        label: 'POIDS (KG)',
                        hint: 'Ex: 250',
                        icon: Icons.scale_outlined,
                        isDark: isDark,
                        keyboardType:
                            const TextInputType.numberWithOptions(decimal: true),
                        textInputAction: TextInputAction.next,
                        onSubmitted: () => FocusScope.of(context).unfocus(),
                      )),
                      const SizedBox(height: 28),

                      // Santé & Alimentation
                      _s(2, _SectionTitle('Santé & Alimentation')),
                      const SizedBox(height: 14),
                      _s(2, _buildDropdownField(
                        label: 'ÉTAT DE SANTÉ',
                        value: _healthCtrl.text.isEmpty ? null : _healthCtrl.text,
                        items: _healthStatuses,
                        icon: Icons.health_and_safety_outlined,
                        isDark: isDark,
                        onChanged: (v) =>
                            setState(() => _healthCtrl.text = v ?? ''),
                      )),
                      const SizedBox(height: 10),
                      _s(2, _buildDropdownField(
                        label: 'TYPE D\'ALIMENTATION',
                        value: _feedingCtrl.text.isEmpty ? null : _feedingCtrl.text,
                        items: _feedingTypes,
                        icon: Icons.grass_outlined,
                        isDark: isDark,
                        onChanged: (v) =>
                            setState(() => _feedingCtrl.text = v ?? ''),
                      )),
                      const SizedBox(height: 28),

                      // Visibilité
                      _s(3, _SectionTitle('Visibilité')),
                      const SizedBox(height: 14),
                      _s(3, _buildVisibilitySelector(isDark)),
                      const SizedBox(height: 28),

                      // Photos
                      _s(4, _SectionTitle('Photos')),
                      const SizedBox(height: 14),
                      _s(4, _buildImageSection(isDark)),
                      const SizedBox(height: 28),

                      // Notes
                      _s(5, _SectionTitle('Observations')),
                      const SizedBox(height: 14),
                      _s(5, _buildField(
                        controller: _notesCtrl,
                        focusNode: _notesFocus,
                        label: 'NOTES',
                        hint: 'Remarques importantes, comportement, traitements…',
                        icon: Icons.note_outlined,
                        isDark: isDark,
                        maxLines: 4,
                        textInputAction: TextInputAction.done,
                        onSubmitted: () => FocusScope.of(context).unfocus(),
                      )),
                      const SizedBox(height: 36),

                      _s(6, _buildSubmitButton()),
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

  // ─── HERO HEADER ──────────────────────────────────────────────────────────
  Widget _buildHeroHeader(bool isDark) {
    return SafeArea(
      bottom: false,
      child: SizedBox(
        height: 160,
        child: Stack(
          clipBehavior: Clip.hardEdge,
          children: [
            // Gradient — même palette que le dashboard hero
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

            // Grain
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

            // Glow accent
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
                      AppColors.accent.withOpacity(isDark ? 0.18 : 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // Livestock illustration
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: SizedBox(
                height: 100,
                child: AnimatedBuilder(
                  animation: _waveCtrl,
                  builder: (_, __) => CustomPaint(
                    painter: _LivestockIllustrationPainter(
                      primary: AppColors.primary,
                      accent: AppColors.accent,
                      isDark: isDark,
                      phase: _waveCtrl.value,
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
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : Colors.black.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            Icons.close_rounded,
                            color: AppColors.accent,
                            size: 17,
                          ),
                        ),
                      ),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.pets_outlined,
                              size: 10,
                              color: AppColors.accent
                                  .withOpacity(isDark ? 0.85 : 0.70),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'ÉLEVAGE',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w500,
                                letterSpacing: 1.8,
                                color: AppColors.accent
                                    .withOpacity(isDark ? 0.85 : 0.70),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'Ajouter',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: AppColors.accent.withOpacity(0.70),
                      letterSpacing: 0.5,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'un animal',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w200,
                      color: isDark
                          ? AppColors.textDark
                          : AppColors.textLight,
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

  // ─── ANIMAL TYPE SELECTOR ─────────────────────────────────────────────────
  Widget _buildAnimalTypeSelector(bool isDark) {
    const types = [
      {'value': 'Bovins', 'icon': Icons.set_meal_outlined, 'label': 'Bovins'},
      {'value': 'Chèvres', 'icon': Icons.pets_outlined, 'label': 'Chèvres'},
      {'value': 'Moutons', 'icon': Icons.cloud_outlined, 'label': 'Moutons'},
      {'value': 'Volailles', 'icon': Icons.egg_outlined, 'label': 'Volailles'},
      {'value': 'Autre', 'icon': Icons.more_horiz_rounded, 'label': 'Autre'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'TYPE D\'ANIMAL',
          style: TextStyle(
            fontSize: 8,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.8,
            color: _textSec(isDark),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: types.map((t) {
            final isSelected = _animalTypeCtrl.text == t['value'] as String;
            return GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _animalTypeCtrl.text = t['value'] as String;
                  if (t['value'] != 'Autre') _customAnimalTypeCtrl.clear();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                curve: Curves.easeOutCubic,
                padding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? AppColors.darkCardBg : AppColors.primary)
                      : (isDark
                          ? AppColors.darkCardBg
                          : const Color(0xFFFAF8F4)),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isDark
                            ? AppColors.borderDark
                            : AppColors.borderLight),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      t['icon'] as IconData,
                      size: 15,
                      color: isSelected
                          ? (isDark ? AppColors.accent : Colors.white)
                          : (isDark
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      t['label'] as String,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: isSelected
                            ? FontWeight.w400
                            : FontWeight.w300,
                        color: isSelected
                            ? (isDark ? AppColors.textDark : Colors.white)
                            : (isDark
                                ? AppColors.textSecondaryDark
                                : AppColors.textSecondaryLight),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── FIELD ────────────────────────────────────────────────────────────────
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
                  horizontal: 14, vertical: 13),
            ),
          ),
        ),
      ],
    );
  }

  // ─── DROPDOWN ─────────────────────────────────────────────────────────────
  Widget _buildDropdownField({
    required String label,
    required String? value,
    required List<String> items,
    required IconData icon,
    required bool isDark,
    required void Function(String?) onChanged,
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
          child: DropdownButtonFormField<String>(
            value: value,
            items: items
                .map((item) => DropdownMenuItem(
                      value: item,
                      child: Text(
                        item,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w300,
                          color: _text(isDark),
                        ),
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
            decoration: InputDecoration(
              hintText: 'Sélectionner…',
              hintStyle: TextStyle(
                color: _textSec(isDark),
                fontWeight: FontWeight.w300,
                fontSize: 13,
              ),
              prefixIcon: Icon(icon, color: AppColors.primary, size: 18),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14, vertical: 13),
            ),
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w300,
              color: _text(isDark),
            ),
            dropdownColor: _card(isDark),
            icon: Icon(
              Icons.keyboard_arrow_down_rounded,
              color: _textSec(isDark),
              size: 18,
            ),
            isExpanded: true,
          ),
        ),
      ],
    );
  }

  // ─── VISIBILITY SELECTOR ──────────────────────────────────────────────────
  Widget _buildVisibilitySelector(bool isDark) {
    const options = [
      {
        'value': 'PRIVATE',
        'label': 'Privé',
        'description': 'Visible uniquement par vous',
        'icon': Icons.lock_outlined,
      },
      {
        'value': 'PARTIAL',
        'label': 'Partagé',
        'description': 'Visible via vos publications uniquement',
        'icon': Icons.people_outline,
      },
      {
        'value': 'PUBLIC',
        'label': 'Public',
        'description': 'Visible par tous les agriculteurs',
        'icon': Icons.public_outlined,
      },
    ];

    return Column(
      children: options.map((opt) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: _VisibilityButton(
            icon: opt['icon'] as IconData,
            label: opt['label'] as String,
            description: opt['description'] as String,
            selected: _visibility == opt['value'] as String,
            isDark: isDark,
            onTap: () => setState(() => _visibility = opt['value'] as String),
          ),
        );
      }).toList(),
    );
  }

  // ─── IMAGE SECTION ────────────────────────────────────────────────────────
  Widget _buildImageSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Grid of selected images
        if (_imageBytesList.isNotEmpty) ...[
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: _imageBytesList.length,
            itemBuilder: (context, index) {
              return Stack(
                fit: StackFit.expand,
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.memory(
                      _imageBytesList[index],
                      fit: BoxFit.cover,
                      cacheWidth: 400,
                    ),
                  ),
                  Positioned(
                    top: 6,
                    right: 6,
                    child: GestureDetector(
                      onTap: () => _removeImage(index),
                      child: Container(
                        width: 22,
                        height: 22,
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.close_rounded,
                          color: Colors.white,
                          size: 13,
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 10),
        ],

        // Add photo button
        GestureDetector(
          onTap: _loading ? null : _pickImage,
          child: Container(
            height: _imageBytesList.isEmpty ? 130 : 60,
            width: double.infinity,
            decoration: BoxDecoration(
              color: AppColors.primaryLight.withOpacity(isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: AppColors.primary.withOpacity(0.22),
                width: 1.5,
              ),
            ),
            child: _imageBytesList.isEmpty
                ? Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.primaryLight.withOpacity(0.12),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_photo_alternate_outlined,
                          size: 20,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(height: 8),
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
                        'Appuyez pour sélectionner',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          color: _textSec(isDark),
                        ),
                      ),
                    ],
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.add_photo_alternate_outlined,
                        size: 16,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Ajouter une autre photo',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: AppColors.primary,
                        ),
                      ),
                    ],
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
          splashColor: AppColors.accent.withOpacity(0.12),
          child: Center(
            child: _loading
                ? SizedBox(
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
                      const Text(
                        'Ajouter l\'animal',
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