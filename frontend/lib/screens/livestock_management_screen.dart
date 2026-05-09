import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/screens/animal_photo_carousel_screen.dart';
import 'package:mbaymi/widgets/farm_posts_widget.dart';
import 'package:mbaymi/utils/app_colors.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PAINTERS (same visual language as dashboard)
// ─────────────────────────────────────────────────────────────────────────────

class _GrainPainter extends CustomPainter {
  final double seed;
  final Color color;
  const _GrainPainter({required this.seed, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random((seed * 1000).toInt());
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 220; i++) {
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

class _WavePainter extends CustomPainter {
  final double phase;
  final Color color;
  final double yOffset;
  const _WavePainter({required this.phase, required this.color, this.yOffset = 0.6});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = color..style = PaintingStyle.fill;
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
    final paint = Paint()..style = PaintingStyle.stroke..strokeWidth = 0.6;
    final cx = size.width * 0.5;
    final cy = size.height * 0.5;
    for (int i = 1; i <= 5; i++) {
      paint.color = color.withOpacity(0.022 + i * 0.004);
      canvas.drawCircle(Offset(cx, cy), i * 38.0, paint);
    }
  }

  @override
  bool shouldRepaint(_RingsPainter o) => false;
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class EditLivestockScreen extends StatefulWidget {
  final int livestockId;
  final Map<String, dynamic> livestock;

  const EditLivestockScreen({
    super.key,
    required this.livestockId,
    required this.livestock,
  });

  @override
  State<EditLivestockScreen> createState() => _EditLivestockScreenState();
}

class _EditLivestockScreenState extends State<EditLivestockScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _animalTypeCtrl;
  late TextEditingController _customAnimalTypeCtrl;
  late TextEditingController _breedCtrl;
  late TextEditingController _quantityCtrl;
  late TextEditingController _ageCtrl;
  late TextEditingController _weightCtrl;
  late TextEditingController _healthCtrl;
  late TextEditingController _feedingCtrl;
  late TextEditingController _notesCtrl;



  bool _loading = false;
  XFile? _imageFile;
  Uint8List? _imageBytes;
  String? _existingImageUrl;
  late Future<List<dynamic>> _photosFuture;
  late String _visibility;
  late int _userId;

  // Animations
  AnimationController? _waveCtrl;
  AnimationController? _entryCtrl;
  List<Animation<double>>? _fade;
  List<Animation<Offset>>?  _slide;

  static const Color _primaryColor = Color(0xFF6B8E23);
  static const Color _accentColor  = Color(0xFFA0C878);

  final List<String> _animalTypes    = ['Bovins', 'Chèvres', 'Moutons', 'Volailles', 'Autre'];
  final List<String> _healthStatuses = ['Sain', 'Malade', 'Vacciné', 'À surveiller'];
  final List<String> _feedingTypes   = ['Herbe', 'Grains', 'Mixte', 'Aliment composé'];

  static const Map<String, IconData> _typeIcons = {
    'Bovins':    Icons.set_meal_outlined,
    'Chèvres':   Icons.spa_outlined,
    'Moutons':   Icons.cloud_outlined,
    'Volailles': Icons.egg_outlined,
    'Autre':     Icons.pets,
  };

  static const Map<String, Color> _healthColors = {
    'Sain':         Color(0xFF4CAF50),
    'Malade':       Color(0xFFE53935),
    'Vacciné':      Color(0xFF42A5F5),
    'À surveiller': Color(0xFFFFB300),
  };

  @override
  void initState() {
    super.initState();
    _userId = AuthService.currentSession?.userId ?? 0;
    _existingImageUrl = widget.livestock['image_url'];
    _photosFuture = ApiService.getAnimalPhotos(widget.livestockId);
    _visibility = widget.livestock['visibility'] ?? 'PRIVATE';

    final existingType = (widget.livestock['animal_type'] ?? '').toString();
    if (existingType.isNotEmpty && !_animalTypes.contains(existingType)) {
      _animalTypeCtrl = TextEditingController(text: 'Autre');
      _customAnimalTypeCtrl = TextEditingController(text: existingType);
    } else {
      _animalTypeCtrl = TextEditingController(text: existingType);
      _customAnimalTypeCtrl = TextEditingController();
    }
    _breedCtrl    = TextEditingController(text: widget.livestock['breed']          ?? '');
    _quantityCtrl = TextEditingController(text: '${widget.livestock['quantity']    ?? 1}');
    _ageCtrl      = TextEditingController(text: widget.livestock['age_months']?.toString()  ?? '');
    _weightCtrl   = TextEditingController(text: widget.livestock['weight_kg']?.toString()   ?? '');
    _healthCtrl   = TextEditingController(text: widget.livestock['health_status']   ?? '');
    _feedingCtrl  = TextEditingController(text: widget.livestock['feeding_type']    ?? '');
    _notesCtrl    = TextEditingController(text: widget.livestock['notes']           ?? '');

    // Animations — grain est statique (évite les rebuilds rapides qui
    // déclenchent !_debugDuringDeviceUpdate sur Flutter Web)
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);

    final ec = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400));
    _entryCtrl = ec;
    _fade  = List.generate(8, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: ec, curve: Interval(i * 0.07, min(i * 0.07 + 0.45, 1.0), curve: Curves.easeOut)),
    ));
    _slide = List.generate(8, (i) =>
      Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
        CurvedAnimation(parent: ec, curve: Interval(i * 0.07, min(i * 0.07 + 0.45, 1.0), curve: Curves.easeOutCubic)),
      ));

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entryCtrl?.forward();
    });
  }

  @override
  void dispose() {
    _waveCtrl?.dispose();
    _entryCtrl?.dispose();
    _animalTypeCtrl.dispose();
    _customAnimalTypeCtrl.dispose();
    _breedCtrl.dispose();
    _quantityCtrl.dispose();
    _ageCtrl.dispose();
    _weightCtrl.dispose();
    _healthCtrl.dispose();
    _feedingCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Widget _s(int i, Widget child) {
    final f = _fade; final s = _slide;
    if (f == null || s == null) return child;
    return FadeTransition(
      opacity: f[i],
      child: SlideTransition(position: s[i], child: child),
    );
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1600, maxHeight: 1600, imageQuality: 85,
    );
    if (image != null) {
      final bytes = await image.readAsBytes();
      setState(() { _imageFile = image; _imageBytes = bytes; });
    }
  }

  Future<void> _submit() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.heavyImpact();
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      String? imageUrl = _existingImageUrl;
      if (_imageFile != null) {
        imageUrl = await ApiService.uploadImageToCloudinary(_imageFile!);
      }
      final res = await ApiService.updateLivestock(
        livestockId: widget.livestockId,
        animalType: _animalTypeCtrl.text.trim() == 'Autre'
            ? _customAnimalTypeCtrl.text.trim()
            : _animalTypeCtrl.text.trim(),
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
      _showSnackBar('Animal modifié avec succès', isError: false);
      await Future.delayed(const Duration(milliseconds: 500));
      Navigator.pop(context, res);
    } catch (e) {
      _showSnackBar('Erreur: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _delete() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.delete_outline_rounded, color: Colors.red, size: 22),
              ),
              const SizedBox(height: 16),
              Text('Supprimer cet animal?',
                style: TextStyle(
                  fontSize: 17, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black87,
                )),
              const SizedBox(height: 8),
              Text('Cette action est irréversible. L\'animal et toutes ses données seront définitivement supprimés.',
                style: TextStyle(fontSize: 13, color: isDark ? Colors.white54 : Colors.black45, height: 1.5)),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('Annuler',
                        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400,
                          color: isDark ? Colors.white70 : Colors.black54)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, true),
                    child: Container(
                      height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.30), blurRadius: 12, offset: const Offset(0, 4))],
                      ),
                      child: const Text('Supprimer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true) {
      setState(() => _loading = true);
      try {
        await ApiService.deleteLivestock(widget.livestockId);
        _showSnackBar('Animal supprimé', isError: false);
        await Future.delayed(const Duration(milliseconds: 500));
        Navigator.pop(context, {'deleted': true});
      } catch (e) {
        _showSnackBar('Erreur: ${e.toString()}', isError: true);
        setState(() => _loading = false);
      }
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Row(children: [
        Icon(isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
          color: Colors.white, size: 16),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: const TextStyle(fontSize: 13))),
      ]),
      backgroundColor: isError ? const Color(0xFFE53935) : _primaryColor,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 6,
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark        = Theme.of(context).brightness == Brightness.dark;
    final bg            = AppColors.getBgColor(isDark);
    final cardColor     = AppColors.getCardBgColor(isDark);
    final textColor     = AppColors.getTextColor(isDark);
    final secondaryText = textColor.withOpacity(0.55);

    return Scaffold(
      backgroundColor: bg,
      body: DefaultTabController(
        length: 2,
        child: Column(
          children: [
            // ── HERO (fixe en haut) ──
            _buildHero(isDark, bg, textColor),
            // ── TAB BAR (collé sous le hero, toujours visible) ──
            _buildTabBar(isDark, cardColor, textColor, secondaryText),
            // ── CONTENU (scrollable) ──
            Expanded(
              child: TabBarView(
                children: [
                  _buildInfoTab(isDark, bg, cardColor, textColor, secondaryText),
                  _buildPostsTab(isDark, cardColor),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HERO
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHero(bool isDark, Color bg, Color textColor) {
    final animalType = widget.livestock['animal_type'] ?? 'Animal';
    final breed      = widget.livestock['breed'] ?? '';
    final typeIcon   = _typeIcons[animalType] ?? Icons.pets;

    return SizedBox(
      height: 200,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Fond dégradé
          Positioned.fill(child: Container(
            decoration: BoxDecoration(gradient: LinearGradient(
              begin: Alignment.topLeft, end: Alignment.bottomRight,
              colors: isDark
                  ? [const Color(0xFF18100A), const Color(0xFF0C0804)]
                  : [const Color(0xFFFFF8EE), const Color(0xFFEEE2CC)],
            )),
          )),

          // Grain statique (seed fixe = 0 rebuilds, évite !_debugDuringDeviceUpdate)
          const Positioned.fill(child: RepaintBoundary(
            child: CustomPaint(painter: _GrainPainter(seed: 0.42, color: _primaryColor)),
          )),

          // Rings décoratifs
          const Positioned(top: -40, right: -50, child: SizedBox(
            width: 220, height: 220,
            child: CustomPaint(painter: _RingsPainter(color: _primaryColor)),
          )),

          // Glow
          Positioned(top: -60, right: -60, child: Container(
            width: 200, height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _accentColor.withOpacity(isDark ? 0.16 : 0.10),
                Colors.transparent,
              ]),
            ),
          )),

          // Vagues — RepaintBoundary isole les repaints du wave loin du mouse tracker
          Positioned(bottom: 0, left: 0, right: 0, child: RepaintBoundary(child: AnimatedBuilder(
            animation: _waveCtrl ?? const AlwaysStoppedAnimation(0),
            builder: (_, __) => SizedBox(height: 70, child: CustomPaint(
              painter: _WavePainter(
                phase: (_waveCtrl?.value ?? 0) * 2 * pi,
                color: _primaryColor.withOpacity(isDark ? 0.20 : 0.10),
                yOffset: 0.45,
              ),
              size: Size(MediaQuery.of(context).size.width, 70),
            )),
          ))),
          Positioned(bottom: 0, left: 0, right: 0, child: RepaintBoundary(child: AnimatedBuilder(
            animation: _waveCtrl ?? const AlwaysStoppedAnimation(0),
            builder: (_, __) => SizedBox(height: 70, child: CustomPaint(
              painter: _WavePainter(
                phase: (_waveCtrl?.value ?? 0) * 2 * pi + 1.8,
                color: _primaryColor.withOpacity(isDark ? 0.10 : 0.06),
                yOffset: 0.65,
              ),
              size: Size(MediaQuery.of(context).size.width, 70),
            )),
          ))),

          // Grand icône animal flottant — isolé aussi
          Positioned(right: 20, top: 0, bottom: 20, child: RepaintBoundary(child: AnimatedBuilder(
            animation: _waveCtrl ?? const AlwaysStoppedAnimation(0),
            builder: (_, __) {
              final sway = 3.0 * sin((_waveCtrl?.value ?? 0) * 2 * pi);
              return Transform.translate(
                offset: Offset(0, sway),
                child: Icon(typeIcon, size: 100,
                  color: _primaryColor.withOpacity(isDark ? 0.14 : 0.10)),
              );
            },
          ))),

          // Contenu texte
          Padding(
            padding: EdgeInsets.fromLTRB(22, MediaQuery.of(context).padding.top + 10, 22, 28),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Back + delete row
                Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: (isDark ? Colors.white : Colors.black).withOpacity(0.06),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(Icons.arrow_back_rounded, size: 18,
                        color: isDark ? Colors.white70 : Colors.black54),
                    ),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _delete,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        const Icon(Icons.delete_outline_rounded, size: 14, color: Colors.red),
                        const SizedBox(width: 5),
                        Text('Supprimer', style: TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w400, color: Colors.red.withOpacity(0.85))),
                      ]),
                    ),
                  ),
                ]),

                const Spacer(),

                // Label
                Text('MODIFIER', style: TextStyle(
                  fontSize: 8, fontWeight: FontWeight.w400, letterSpacing: 3.0,
                  color: _accentColor.withOpacity(0.70),
                )),
                const SizedBox(height: 4),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(animalType, style: TextStyle(
                      fontSize: 26, fontWeight: FontWeight.w200,
                      color: isDark ? const Color(0xFFF0E8D8) : Colors.black87,
                      letterSpacing: -1.5, height: 1.0,
                    )),
                    if (breed.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Flexible(child: Text('— $breed', style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w300,
                        color: _primaryColor.withOpacity(0.65), letterSpacing: 0.2,
                      ), overflow: TextOverflow.ellipsis)),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // TAB BAR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildTabBar(bool isDark, Color cardColor, Color textColor, Color secondaryText) {
    return Container(
      color: cardColor,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TabBar(
            indicatorColor: _primaryColor,
            indicatorWeight: 2,
            labelColor: _primaryColor,
            unselectedLabelColor: secondaryText,
            labelStyle: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13, letterSpacing: 0.5),
            unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w300, fontSize: 13),
            tabs: const [
              Tab(text: 'Informations'),
              Tab(text: 'Publications'),
            ],
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // INFO TAB
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildInfoTab(bool isDark, Color bg, Color cardColor, Color textColor, Color secondaryText) {
    return SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(16, 24, 16, 40 + MediaQuery.of(context).padding.bottom),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            _s(0, _buildPhotoSection(isDark, cardColor, textColor, secondaryText)),
            const SizedBox(height: 32),

            // Informations de base
            _s(1, _buildSectionHeader(isDark, 'IDENTITÉ', textColor, secondaryText)),
            const SizedBox(height: 14),
            _s(1, _buildAnimalTypeSelector(isDark, cardColor, textColor, secondaryText)),
            if (_animalTypeCtrl.text == 'Autre') ...[
              const SizedBox(height: 10),
              _s(1, _buildStyledField(
                controller: _customAnimalTypeCtrl,
                label: 'Précisez le type',
                hint: 'Ex: Lapins, Chevaux…',
                icon: Icons.edit_outlined,
                isDark: isDark, cardColor: cardColor,
                textColor: textColor, secondaryText: secondaryText,
              )),
            ],
            const SizedBox(height: 10),
            _s(1, _buildStyledField(
              controller: _breedCtrl,
              label: 'Race',
              hint: 'Ex: Race locale',
              icon: Icons.bookmark_border_rounded,
              isDark: isDark, cardColor: cardColor,
              textColor: textColor, secondaryText: secondaryText,
            )),
            const SizedBox(height: 10),
            _s(1, Row(children: [
              Expanded(child: _buildStyledField(
                controller: _quantityCtrl,
                label: 'Quantité',
                hint: '1',
                icon: Icons.format_list_numbered_rounded,
                keyboardType: TextInputType.number,
                isDark: isDark, cardColor: cardColor,
                textColor: textColor, secondaryText: secondaryText,
              )),
              const SizedBox(width: 10),
              Expanded(child: _buildStyledField(
                controller: _ageCtrl,
                label: 'Âge (mois)',
                hint: '12',
                icon: Icons.calendar_today_rounded,
                keyboardType: TextInputType.number,
                isDark: isDark, cardColor: cardColor,
                textColor: textColor, secondaryText: secondaryText,
              )),
            ])),
            const SizedBox(height: 10),
            _s(1, _buildStyledField(
              controller: _weightCtrl,
              label: 'Poids (kg)',
              hint: '250',
              icon: Icons.monitor_weight_outlined,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              isDark: isDark, cardColor: cardColor,
              textColor: textColor, secondaryText: secondaryText,
            )),

            const SizedBox(height: 32),

            // Santé
            _s(2, _buildSectionHeader(isDark, 'SANTÉ & ALIMENTATION', textColor, secondaryText)),
            const SizedBox(height: 14),
            _s(2, _buildHealthSelector(isDark, cardColor, textColor, secondaryText)),
            const SizedBox(height: 10),
            _s(2, _buildFeedingSelector(isDark, cardColor, textColor, secondaryText)),

            const SizedBox(height: 32),

            // Notes
            _s(3, _buildSectionHeader(isDark, 'OBSERVATIONS', textColor, secondaryText)),
            const SizedBox(height: 14),
            _s(3, _buildStyledField(
              controller: _notesCtrl,
              label: 'Notes',
              hint: 'Remarques importantes…',
              icon: Icons.notes_rounded,
              maxLines: 4,
              isDark: isDark, cardColor: cardColor,
              textColor: textColor, secondaryText: secondaryText,
            )),

            const SizedBox(height: 32),

            // Visibilité
            _s(4, _buildSectionHeader(isDark, 'VISIBILITÉ', textColor, secondaryText)),
            const SizedBox(height: 14),
            _s(4, _buildVisibilityOptions(isDark, cardColor, textColor, secondaryText)),

            const SizedBox(height: 36),

            // Bouton save
            _s(5, _buildSaveButton()),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SECTION HEADER — same dashboard style
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSectionHeader(bool isDark, String title, Color textColor, Color secondaryText) {
    return Row(children: [
      Container(width: 20, height: 1, color: _primaryColor),
      const SizedBox(width: 8),
      Text(title, style: TextStyle(
        fontSize: 7.5, fontWeight: FontWeight.w500,
        letterSpacing: 2.8, color: secondaryText.withOpacity(0.6),
      )),
      const SizedBox(width: 8),
      Expanded(child: Container(height: 1, color: secondaryText.withOpacity(0.08))),
    ]);
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PHOTO SECTION
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPhotoSection(bool isDark, Color cardColor, Color textColor, Color secondaryText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Container(width: 20, height: 1, color: _primaryColor),
          const SizedBox(width: 8),
          Text('PHOTO', style: TextStyle(
            fontSize: 7.5, fontWeight: FontWeight.w500, letterSpacing: 2.8,
            color: secondaryText.withOpacity(0.6),
          )),
          const SizedBox(width: 8),
          Expanded(child: Container(height: 1, color: secondaryText.withOpacity(0.08))),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(
              builder: (_) => AnimalPhotoCarouselScreen(
                livestockId: widget.livestockId,
                animalType: widget.livestock['animal_type'] ?? 'Animal',
                userId: widget.livestock['user_id'] ?? 0,
                isDarkMode: isDark,
              ),
            )),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(7),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.photo_library_outlined, size: 11, color: _primaryColor.withOpacity(0.80)),
                const SizedBox(width: 5),
                Text('Galerie', style: TextStyle(
                  fontSize: 10, fontWeight: FontWeight.w400,
                  color: _primaryColor.withOpacity(0.80), letterSpacing: 0.5,
                )),
              ]),
            ),
          ),
        ]),
        const SizedBox(height: 14),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: 190,
            decoration: BoxDecoration(
              color: cardColor,
              boxShadow: [BoxShadow(
                color: isDark ? Colors.black.withOpacity(0.25) : _primaryColor.withOpacity(0.07),
                blurRadius: 20, offset: const Offset(0, 6), spreadRadius: -2,
              )],
            ),
            clipBehavior: Clip.hardEdge,
            child: Stack(children: [
              // Image ou placeholder
              if (_imageBytes != null)
                Positioned.fill(child: Image.memory(_imageBytes!, fit: BoxFit.cover))
              else if (_existingImageUrl != null)
                Positioned.fill(child: Image.network(
                  _existingImageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _buildPhotoPlaceholder(isDark, textColor, secondaryText),
                ))
              else
                _buildPhotoPlaceholder(isDark, textColor, secondaryText),

              // Overlay edit badge
              Positioned(bottom: 12, right: 12, child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.50),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(mainAxisSize: MainAxisSize.min, children: const [
                  Icon(Icons.photo_camera_outlined, size: 13, color: Colors.white),
                  SizedBox(width: 5),
                  Text('Changer', style: TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.w300)),
                ]),
              )),
            ]),
          ),
        ),
        if (_imageBytes != null)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: () => setState(() { _imageFile = null; _imageBytes = null; }),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.close_rounded, size: 13, color: Colors.red),
                const SizedBox(width: 4),
                Text('Annuler', style: TextStyle(fontSize: 11, color: Colors.red.withOpacity(0.80))),
              ]),
            ),
          ),
      ],
    );
  }

  Widget _buildPhotoPlaceholder(bool isDark, Color textColor, Color secondaryText) {
    return Container(
      color: isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F2EE),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.add_photo_alternate_outlined, size: 40, color: _primaryColor.withOpacity(0.45)),
        const SizedBox(height: 10),
        Text('Ajouter une photo', style: TextStyle(
          fontSize: 14, fontWeight: FontWeight.w300, color: textColor.withOpacity(0.60))),
        const SizedBox(height: 3),
        Text('Appuyez pour sélectionner', style: TextStyle(
          fontSize: 11, color: secondaryText.withOpacity(0.50))),
      ]),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // ANIMAL TYPE SELECTOR — horizontal chips
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildAnimalTypeSelector(bool isDark, Color cardColor, Color textColor, Color secondaryText) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.22) : _primaryColor.withOpacity(0.05),
          blurRadius: 18, offset: const Offset(0, 5), spreadRadius: -2,
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bande accent top
          Container(height: 1.5, decoration: BoxDecoration(gradient: LinearGradient(colors: [
            _accentColor.withOpacity(0.50), _primaryColor.withOpacity(0.20), Colors.transparent,
          ]))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.pets_rounded, size: 13, color: _primaryColor.withOpacity(0.65)),
                  const SizedBox(width: 6),
                  Text("TYPE D'ANIMAL", style: TextStyle(
                    fontSize: 7, fontWeight: FontWeight.w500, letterSpacing: 2.0,
                    color: secondaryText.withOpacity(0.50),
                  )),
                ]),
                const SizedBox(height: 12),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    children: _animalTypes.map((type) {
                      final sel = _animalTypeCtrl.text == type;
                      final icon = _typeIcons[type] ?? Icons.pets;
                      return GestureDetector(
                        onTap: () {
                          HapticFeedback.selectionClick();
                          setState(() => _animalTypeCtrl.text = type);
                        },
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                            color: sel ? _primaryColor : _primaryColor.withOpacity(0.05),
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: sel ? [BoxShadow(
                              color: _primaryColor.withOpacity(0.25),
                              blurRadius: 10, offset: const Offset(0, 3),
                            )] : null,
                          ),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(icon, size: 13,
                              color: sel ? Colors.white : _primaryColor.withOpacity(0.55)),
                            const SizedBox(width: 6),
                            Text(type, style: TextStyle(
                              fontSize: 12, fontWeight: sel ? FontWeight.w500 : FontWeight.w300,
                              color: sel ? Colors.white : textColor.withOpacity(0.65),
                            )),
                          ]),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // HEALTH SELECTOR — visual chips with colors
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHealthSelector(bool isDark, Color cardColor, Color textColor, Color secondaryText) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.22) : _primaryColor.withOpacity(0.05),
          blurRadius: 18, offset: const Offset(0, 5), spreadRadius: -2,
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1.5, decoration: BoxDecoration(gradient: LinearGradient(colors: [
            _accentColor.withOpacity(0.50), _primaryColor.withOpacity(0.20), Colors.transparent,
          ]))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.favorite_outline_rounded, size: 13, color: _primaryColor.withOpacity(0.65)),
                  const SizedBox(width: 6),
                  Text("ÉTAT DE SANTÉ", style: TextStyle(
                    fontSize: 7, fontWeight: FontWeight.w500, letterSpacing: 2.0,
                    color: secondaryText.withOpacity(0.50),
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: _healthStatuses.map((status) {
                  final sel = _healthCtrl.text == status;
                  final color = _healthColors[status] ?? _primaryColor;
                  return Expanded(child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _healthCtrl.text = status);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: status == _healthStatuses.last ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        color: sel ? color : color.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: sel ? [BoxShadow(
                          color: color.withOpacity(0.28), blurRadius: 10, offset: const Offset(0, 3),
                        )] : null,
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(Icons.circle, size: 6,
                          color: sel ? Colors.white : color.withOpacity(0.70)),
                        const SizedBox(height: 5),
                        Text(status, textAlign: TextAlign.center, style: TextStyle(
                          fontSize: 9.5, fontWeight: sel ? FontWeight.w600 : FontWeight.w300,
                          color: sel ? Colors.white : textColor.withOpacity(0.60),
                          letterSpacing: 0.2,
                        )),
                      ]),
                    ),
                  ));
                }).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // FEEDING SELECTOR
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildFeedingSelector(bool isDark, Color cardColor, Color textColor, Color secondaryText) {
    const feedIcons = {
      'Herbe':           Icons.grass_rounded,
      'Grains':          Icons.grain_rounded,
      'Mixte':           Icons.shuffle_rounded,
      'Aliment composé': Icons.inventory_2_outlined,
    };

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.22) : _primaryColor.withOpacity(0.05),
          blurRadius: 18, offset: const Offset(0, 5), spreadRadius: -2,
        )],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 1.5, decoration: BoxDecoration(gradient: LinearGradient(colors: [
            _accentColor.withOpacity(0.50), _primaryColor.withOpacity(0.20), Colors.transparent,
          ]))),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.restaurant_outlined, size: 13, color: _primaryColor.withOpacity(0.65)),
                  const SizedBox(width: 6),
                  Text("ALIMENTATION", style: TextStyle(
                    fontSize: 7, fontWeight: FontWeight.w500, letterSpacing: 2.0,
                    color: secondaryText.withOpacity(0.50),
                  )),
                ]),
                const SizedBox(height: 12),
                Row(children: _feedingTypes.map((type) {
                  final sel = _feedingCtrl.text == type;
                  final icon = feedIcons[type] ?? Icons.eco_rounded;
                  return Expanded(child: GestureDetector(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _feedingCtrl.text = type);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: EdgeInsets.only(right: type == _feedingTypes.last ? 0 : 8),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: sel ? _primaryColor : _primaryColor.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        boxShadow: sel ? [BoxShadow(
                          color: _primaryColor.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 3),
                        )] : null,
                      ),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Icon(icon, size: 16,
                          color: sel ? Colors.white : _primaryColor.withOpacity(0.55)),
                        const SizedBox(height: 5),
                        Text(type, textAlign: TextAlign.center, style: TextStyle(
                          fontSize: 9, fontWeight: sel ? FontWeight.w500 : FontWeight.w300,
                          color: sel ? Colors.white : textColor.withOpacity(0.60),
                        )),
                      ]),
                    ),
                  ));
                }).toList()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // STYLED FIELD — shadow only, accent top bar
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildStyledField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color secondaryText,
    TextInputType? keyboardType,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        boxShadow: [BoxShadow(
          color: isDark ? Colors.black.withOpacity(0.22) : _primaryColor.withOpacity(0.05),
          blurRadius: 18, offset: const Offset(0, 5), spreadRadius: -2,
        )],
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(height: 1.5, decoration: BoxDecoration(gradient: LinearGradient(colors: [
            _accentColor.withOpacity(0.40), _primaryColor.withOpacity(0.15), Colors.transparent,
          ]))),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            maxLines: maxLines,
            style: TextStyle(fontSize: 15, color: textColor, fontWeight: FontWeight.w300),
            decoration: InputDecoration(
              labelText: label,
              hintText: hint,
              labelStyle: TextStyle(fontSize: 12, color: secondaryText.withOpacity(0.55), letterSpacing: 0.3),
              hintStyle: TextStyle(color: secondaryText.withOpacity(0.35), fontSize: 13),
              prefixIcon: Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Icon(icon, color: _primaryColor.withOpacity(0.55), size: 18),
              ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.fromLTRB(4, 18, 20, 18),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // VISIBILITY OPTIONS
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildVisibilityOptions(bool isDark, Color cardColor, Color textColor, Color secondaryText) {
    final options = [
      {'value': 'PRIVATE',  'label': 'Privé',    'desc': 'Visible uniquement par vous',  'icon': Icons.lock_outline_rounded,   'color': const Color(0xFFE53935)},
      {'value': 'PARTIAL',  'label': 'Partagé',  'desc': 'Visible via vos publications', 'icon': Icons.people_outline_rounded,  'color': const Color(0xFFFFB300)},
      {'value': 'PUBLIC',   'label': 'Public',   'desc': 'Visible par toute la communauté','icon': Icons.public_rounded,       'color': _primaryColor},
    ];

    return Column(
      children: options.map((opt) {
        final isSelected = _visibility == opt['value'];
        final color = opt['color'] as Color;
        return GestureDetector(
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _visibility = opt['value'] as String);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: const EdgeInsets.only(bottom: 10),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(isDark ? 0.12 : 0.08) : cardColor,
              boxShadow: [BoxShadow(
                color: isSelected
                    ? color.withOpacity(0.18)
                    : (isDark ? Colors.black.withOpacity(0.18) : _primaryColor.withOpacity(0.04)),
                blurRadius: isSelected ? 16 : 14,
                offset: const Offset(0, 4), spreadRadius: -2,
              )],
            ),
            child: IntrinsicHeight(
              child: Row(children: [
                // Accent bar
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  width: 3,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter, end: Alignment.bottomCenter,
                      colors: isSelected
                          ? [color.withOpacity(0.3), color, color.withOpacity(0.3)]
                          : [Colors.transparent, Colors.transparent],
                    ),
                    borderRadius: const BorderRadius.horizontal(left: Radius.circular(0)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 14, 14),
                    child: Row(children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: color.withOpacity(isSelected ? 0.15 : 0.08),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(opt['icon'] as IconData, color: color, size: 16),
                      ),
                      const SizedBox(width: 14),
                      Expanded(child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(opt['label'] as String, style: TextStyle(
                            fontSize: 14, fontWeight: FontWeight.w400,
                            color: isSelected ? color : textColor,
                          )),
                          const SizedBox(height: 2),
                          Text(opt['desc'] as String, style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w300,
                            color: secondaryText.withOpacity(0.55),
                          )),
                        ],
                      )),
                      if (isSelected)
                        Icon(Icons.check_circle_rounded, color: color, size: 18),
                    ]),
                  ),
                ),
              ]),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SAVE BUTTON
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSaveButton() {
    return GestureDetector(
      onTap: _loading ? null : _submit,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: _loading
                ? [_primaryColor.withOpacity(0.5), _primaryColor.withOpacity(0.5)]
                : [const Color(0xFF7BA833), _primaryColor],
            begin: Alignment.topLeft, end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          boxShadow: _loading ? [] : [
            BoxShadow(color: _primaryColor.withOpacity(0.35), blurRadius: 20, offset: const Offset(0, 6)),
          ],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          if (_loading)
            const SizedBox(width: 18, height: 18,
              child: CircularProgressIndicator(valueColor: AlwaysStoppedAnimation(Colors.white), strokeWidth: 2))
          else ...[
            const Icon(Icons.check_rounded, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            const Text('Enregistrer', style: TextStyle(
              color: Colors.white, fontSize: 15,
              fontWeight: FontWeight.w500, letterSpacing: 0.5,
            )),
          ],
        ]),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // POSTS TAB
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildPostsTab(bool isDark, Color cardColor) {
    return Container(
      color: isDark ? const Color(0xFF0A0A0A) : const Color(0xFFF8F9FA),
      child: FarmPostsWidget(
        farmId: widget.livestock['farm_id'] ?? 0,
        farmName: '${widget.livestock['animal_type'] ?? 'Animal'} — ${widget.livestock['breed'] ?? ''}',
        isOwner: _userId == widget.livestock['user_id'],
        livestockId: widget.livestock['id'],
      ),
    );
  }
}