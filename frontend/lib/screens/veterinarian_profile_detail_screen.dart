import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/models/veterinarian_model.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/token_storage.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/widgets/skeleton_loader.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS — Minimalist, neutral, airy ("Zara / Apple" style)
// ═══════════════════════════════════════════════════════════════════════════

abstract class _T {
  // Monochromatic neutral palette
  static const ink0 = Color(0xFF1A1C1A);
  static const ink1 = Color(0xFF2C2E2C);
  static const ink2 = Color(0xFF6B6E6B);
  static const ink3 = Color(0xFF9EA29E);

  static const bg = Color(0xFFF8F9F8);
  static const surf = Color(0xFFFFFFFF);
  static const surf2 = Color(0xFFF2F4F2);

  static const border = Color(0xFFE5E8E5);
  static const border2 = Color(0xFFD0D5D0);

  // Single accent — sage, used sparingly
  static const sage = Color(0xFF3B7A4A);
  static const sageLight = Color(0xFFE8F3EB);

  // Other colors (muted)
  static const clay = Color(0xFFD96C6C);
  static const sky = Color(0xFF5A7D9A);
  static const amber = Color(0xFFC69C4A);

  static const radii = Radius.circular(20);
  static const r8 = 8.0;
  static const r10 = 10.0;
  static const r12 = 12.0;
  static const r14 = 14.0;
  static const r16 = 16.0;
  static const r20 = 20.0;
  static const r24 = 24.0;

  static Color specialtyAccent(String spec) => sage;
}

// ═══════════════════════════════════════════════════════════════════════════
// SIMPLE WAVE PAINTER (barely visible, adds depth)
// ═══════════════════════════════════════════════════════════════════════════

class _WavePainter extends CustomPainter {
  final double phase;
  final Color color;
  final double yRatio;
  final double amplitude;
  const _WavePainter({
    required this.phase,
    required this.color,
    this.yRatio = 0.55,
    this.amplitude = 10,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final path = Path();
    final baseY = size.height * yRatio;
    path.moveTo(0, size.height);
    path.lineTo(0, baseY + amplitude * sin(phase));
    for (double x = 0; x <= size.width; x += 2) {
      path.lineTo(
        x,
        baseY + amplitude * sin(x / size.width * 2 * pi + phase),
      );
    }
    path.lineTo(size.width, size.height);
    path.close();
    canvas.drawPath(path, Paint()..color = color..style = PaintingStyle.fill);
  }

  @override
  bool shouldRepaint(_WavePainter o) => o.phase != phase;
}

// ═══════════════════════════════════════════════════════════════════════════
// REUSABLE COMPONENTS
// ═══════════════════════════════════════════════════════════════════════════

class _SectionTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  const _SectionTitle({required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(title, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500,
        letterSpacing: 1.2, color: _T.ink2,
      )),
      if (subtitle != null) ...[
        const SizedBox(height: 4),
        Text(subtitle!, style: const TextStyle(
          fontSize: 11, color: _T.ink3, fontWeight: FontWeight.w300,
        )),
      ],
    ],
  );
}

class _DividerLine extends StatelessWidget {
  const _DividerLine();
  @override
  Widget build(BuildContext context) => Container(
    height: 1, color: _T.border,
    margin: const EdgeInsets.symmetric(vertical: 8),
  );
}

class _OutlinedButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _OutlinedButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_T.r12),
        border: Border.all(color: _T.border2),
      ),
      child: Text(label, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w400, color: _T.ink2,
      )),
    ),
  );
}

class _SolidButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final Color color;
  const _SolidButton({required this.label, required this.onTap, required this.color});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(_T.r12),
      ),
      child: Text(label, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white,
      )),
    ),
  );
}

class _IconButtonCircle extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final Color backgroundColor;
  const _IconButtonCircle({
    required this.icon,
    required this.onTap,
    this.backgroundColor = Colors.white,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      width: 40, height: 40,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor,
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Icon(icon, size: 18, color: _T.ink1),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// STAT CARD (minimal)
// ═══════════════════════════════════════════════════════════════════════════

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  const _StatCard({required this.value, required this.label, required this.icon});

  @override
  Widget build(BuildContext context) => Expanded(
    child: Column(children: [
      Container(
        width: 40, height: 40,
        decoration: BoxDecoration(
          color: _T.sageLight,
          borderRadius: BorderRadius.circular(_T.r12),
        ),
        child: Icon(icon, size: 18, color: _T.sage),
      ),
      const SizedBox(height: 8),
      Text(value, style: const TextStyle(
        fontSize: 18, fontWeight: FontWeight.w500, color: _T.ink0,
      )),
      const SizedBox(height: 2),
      Text(label, style: const TextStyle(
        fontSize: 11, fontWeight: FontWeight.w300, color: _T.ink3,
      )),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// HERO SECTION (light, airy)
// ═══════════════════════════════════════════════════════════════════════════

class _HeroSection extends StatelessWidget {
  final VeterinarianProfile profile;
  final AnimationController waveCtrl;

  const _HeroSection({required this.profile, required this.waveCtrl});

  @override
  Widget build(BuildContext context) {
    final topPad = MediaQuery.of(context).padding.top;
    final w = MediaQuery.of(context).size.width;

    return Container(
      color: _T.sage,
      child: Stack(children: [
        // Subtle wave at bottom
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: AnimatedBuilder(
            animation: waveCtrl,
            builder: (_, __) => SizedBox(
              height: 40, // Réduit de 60 à 40
              child: CustomPaint(
                size: Size(w, 40),
                painter: _WavePainter(
                  phase: waveCtrl.value * 2 * pi,
                  amplitude: 6, // Réduit de 8 à 6
                  color: _T.bg.withOpacity(0.12),
                  yRatio: 0.2,
                ),
              ),
            ),
          ),
        ),

        Padding(
          padding: EdgeInsets.fromLTRB(24, topPad + 24, 24, 24), // Réduit les marges verticales
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min, // Important : permet au Column de prendre le minimum d'espace
            children: [
              // Avatar initial
              Container(
                width: 48, height: 48, // Réduit de 56 à 48
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                ),
                child: Center(
                  child: Text(
                    profile.specialty.isNotEmpty ? profile.specialty[0] : 'V',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300, color: Colors.white), // Réduit de 24 à 20
                  ),
                ),
              ),
              const SizedBox(height: 12), // Réduit de 20 à 12
              Text(
                profile.specialty,
                style: const TextStyle(
                  fontSize: 24, // Réduit de 28 à 24
                  fontWeight: FontWeight.w300,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4), // Réduit de 6 à 4
              Text(
                'Vétérinaire · ${profile.zone}',
                style: TextStyle(
                  fontSize: 11, // Réduit de 13 à 11
                  color: Colors.white.withOpacity(0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 12), // Réduit de 16 à 12
              Wrap(
                spacing: 8,
                runSpacing: 4, // Ajouté pour éviter les débordements
                children: [
                  if (profile.isVerified)
                    _Pill(
                      label: 'Vérifié',
                      icon: Icons.verified_rounded,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  _Pill(
                    label: '${profile.experienceYears} ans',
                    icon: Icons.workspace_premium_outlined,
                  ),
                ],
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

class _Pill extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color? color;
  const _Pill({required this.label, required this.icon, this.color});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), // Réduit de 10/5 à 8/4
    decoration: BoxDecoration(
      color: Colors.white.withOpacity(0.15),
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 10, color: color ?? Colors.white70), // Réduit de 11 à 10
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)), // Réduit de 11 à 10
      ],
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// INFO CARD (generic)
// ═══════════════════════════════════════════════════════════════════════════

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) => Container(
    width: double.infinity,
    decoration: BoxDecoration(
      color: _T.surf,
      borderRadius: BorderRadius.circular(_T.r16),
      border: Border.all(color: _T.border),
    ),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
        padding: const EdgeInsets.all(16),
        child: _SectionTitle(title: title.toUpperCase()),
      ),
      const _DividerLine(),
      Padding(padding: const EdgeInsets.all(16), child: child),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class VeterinarianProfileDetailScreen extends StatefulWidget {
  final String veterinarianId;
  const VeterinarianProfileDetailScreen({super.key, required this.veterinarianId});

  @override
  State<VeterinarianProfileDetailScreen> createState() => _VeterinarianProfileDetailScreenState();
}

class _VeterinarianProfileDetailScreenState extends State<VeterinarianProfileDetailScreen>
    with TickerProviderStateMixin {
  late Future<VeterinarianProfile?> _profileFuture;
  bool _isAuthorized = false;
  late AnimationController _waveCtrl;

  @override
  void initState() {
    super.initState();
    _profileFuture = ApiService.getVeterinarianProfileById(int.tryParse(widget.veterinarianId) ?? 0);
    _waveCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 12))..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    super.dispose();
  }

  void _requestAuthorization() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _AuthorizationSheet(
        veterinarianId: widget.veterinarianId,
        onSuccess: () {
          setState(() => _isAuthorized = true);
          _showSnack('Demande envoyée', color: _T.sage);
        },
      ),
    );
  }

  void _showSnack(String msg, {Color color = _T.sage}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r12)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent),
      child: Scaffold(
        backgroundColor: _T.bg,
        body: FutureBuilder<VeterinarianProfile?>(
          future: _profileFuture,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return SkeletonPageLoader(isDarkMode: false, includeAppBar: true, cardCount: 4);
            }
            if (snap.hasError) {
              return _ErrorView(error: snap.error.toString(), onRetry: () {
                setState(() => _profileFuture = ApiService.getVeterinarianProfileById(int.tryParse(widget.veterinarianId) ?? 0));
              });
            }
            if (snap.data == null) return const _EmptyView();

            final p = snap.data!;

            return CustomScrollView(
              physics: const BouncingScrollPhysics(),
              slivers: [
                SliverAppBar(
                  expandedHeight: 220, // Réduit de 260 à 220
                  pinned: true,
                  elevation: 0,
                  backgroundColor: _T.sage,
                  foregroundColor: Colors.white,
                  leading: _IconButtonCircle(
                    icon: Icons.arrow_back_rounded,
                    onTap: () => Navigator.pop(context),
                  ),
                  flexibleSpace: FlexibleSpaceBar(
                    background: _HeroSection(profile: p, waveCtrl: _waveCtrl),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.all(20),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // Stats row
                      Container(
                        decoration: BoxDecoration(
                          color: _T.surf,
                          borderRadius: BorderRadius.circular(_T.r16),
                          border: Border.all(color: _T.border),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(children: [
                          _StatCard(value: '${p.consultationCount ?? 0}', label: 'Consultations', icon: Icons.medical_services_outlined),
                          Container(width: 1, height: 40, color: _T.border),
                          _StatCard(value: p.rating?.toStringAsFixed(1) ?? '—', label: 'Note', icon: Icons.star_outline_rounded),
                          Container(width: 1, height: 40, color: _T.border),
                          _StatCard(value: '${p.experienceYears}', label: 'Expérience', icon: Icons.workspace_premium_outlined),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      // Bio
                      if (p.bio.isNotEmpty) ...[
                        _InfoCard(
                          title: 'À propos',
                          child: Text(p.bio, style: const TextStyle(
                            fontSize: 14, height: 1.5, color: _T.ink2,
                          )),
                        ),
                        const SizedBox(height: 20),
                      ],

                      // Zone
                      _InfoCard(
                        title: 'Zone d\'intervention',
                        child: Column(children: [
                          _InfoRow(icon: Icons.location_on_outlined, label: p.zone),
                          const SizedBox(height: 12),
                          _InfoRow(icon: Icons.straighten_rounded, label: 'Rayon : ${p.distanceMax} km'),
                        ]),
                      ),
                      const SizedBox(height: 20),

                      // Contact
                      _InfoCard(
                        title: 'Contact préféré',
                        child: _ContactCard(profile: p),
                      ),
                      const SizedBox(height: 24),

                      // CTA
                      _CTASection(isAuthorized: _isAuthorized, onTap: _requestAuthorization),
                      const SizedBox(height: 40),
                    ]),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  const _InfoRow({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) => Row(children: [
    Icon(icon, size: 18, color: _T.ink3),
    const SizedBox(width: 12),
    Expanded(child: Text(label, style: const TextStyle(fontSize: 14, color: _T.ink1))),
  ]);
}

class _ContactCard extends StatelessWidget {
  final VeterinarianProfile profile;
  const _ContactCard({required this.profile});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () => HapticFeedback.lightImpact(),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _T.sageLight,
        borderRadius: BorderRadius.circular(_T.r12),
      ),
      child: Row(children: [
        const Icon(Icons.message_outlined, color: _T.sage, size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            profile.contactPreference,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: _T.sage),
          ),
        ),
        const Icon(Icons.arrow_forward_ios, size: 12, color: _T.sage),
      ]),
    ),
  );
}

class _CTASection extends StatelessWidget {
  final bool isAuthorized;
  final VoidCallback onTap;
  const _CTASection({required this.isAuthorized, required this.onTap});

  @override
  Widget build(BuildContext context) {
    if (isAuthorized) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: _T.sageLight,
          borderRadius: BorderRadius.circular(_T.r16),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Icon(Icons.check_circle, color: _T.sage, size: 18),
          SizedBox(width: 8),
          Text('Accès autorisé', style: TextStyle(fontSize: 14, color: _T.sage, fontWeight: FontWeight.w500)),
        ]),
      );
    }
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: _T.sage,
          borderRadius: BorderRadius.circular(_T.r16),
        ),
        child: const Center(
          child: Text('Demander l’accès', style: TextStyle(
            fontSize: 15, fontWeight: FontWeight.w500, color: Colors.white,
          )),
        ),
      ),
    );
  }
}

// Error / Empty
class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _T.bg,
    body: Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          const Icon(Icons.error_outline, size: 48, color: _T.clay),
          const SizedBox(height: 16),
          const Text('Erreur de chargement', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Text(error, style: const TextStyle(fontSize: 12, color: _T.ink3), textAlign: TextAlign.center),
          const SizedBox(height: 24),
          _SolidButton(label: 'Réessayer', onTap: onRetry, color: _T.sage),
        ]),
      ),
    ),
  );
}

class _EmptyView extends StatelessWidget {
  const _EmptyView();
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: _T.bg,
    body: const Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.person_off_outlined, size: 48, color: _T.ink3),
        SizedBox(height: 16),
        Text('Profil non trouvé', style: TextStyle(fontSize: 14, color: _T.ink2)),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// AUTHORIZATION SHEET — STEP BY STEP, CLEAR
// ═══════════════════════════════════════════════════════════════════════════

class _AuthorizationSheet extends StatefulWidget {
  final String veterinarianId;
  final VoidCallback onSuccess;
  const _AuthorizationSheet({required this.veterinarianId, required this.onSuccess});

  @override
  State<_AuthorizationSheet> createState() => _AuthorizationSheetState();
}

class _AuthorizationSheetState extends State<_AuthorizationSheet> {
  final _reasonCtrl = TextEditingController();
  bool _loading = false;
  bool _loadingData = true;

  int _step = 0; // 0: type, 1: selection, 2: reason
  String _type = ''; // 'crop' or 'animal'

  List<dynamic> _farms = [];
  List<dynamic> _livestocks = [];
  dynamic _selectedFarm;
  dynamic _selectedLivestock;
  Set<int> _selectedCrops = {};
  int _animalCount = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final farms = await ApiService.getUserFarms();
      final uid = await TokenStorage.getUserId();
      final lives = uid != null ? await ApiService.getUserLivestock(uid) : [];
      if (mounted) setState(() {
        _farms = farms;
        _livestocks = lives;
        _loadingData = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  void _nextStep() => setState(() => _step++);
  void _prevStep() => setState(() => _step--);

  String get _selectionSummary {
    if (_type == 'crop') return '${_selectedCrops.length} parcelle(s)';
    return '$_animalCount animal(aux)';
  }

  bool get _canProceedToReason {
    if (_type == 'crop') return _selectedFarm != null && _selectedCrops.isNotEmpty;
    return _selectedLivestock != null && _animalCount > 0;
  }

  Future<void> _submit() async {
    if (_reasonCtrl.text.trim().isEmpty) {
      _showSnack('Décrivez le problème', color: _T.amber);
      return;
    }
    setState(() => _loading = true);
    try {
      await ApiService.createAuthorization(
        farmId: _type == 'crop' ? (_selectedFarm['id'] as int) : 0,
        veterinarianId: int.tryParse(widget.veterinarianId) ?? 0,
        authorizationReason: '${_reasonCtrl.text.trim()}\n\n[À diagnostiquer : $_selectionSummary]',
        selectedLivestockIds: _type == 'animal' ? (_selectedLivestock['id'] as int).toString() : null,
        selectedCropIds: _type == 'crop' ? _selectedCrops.map((e) => e.toString()).join(',') : null,
      );
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      _showSnack('Erreur : $e', color: _T.clay);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, {required Color color}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_T.r12)),
      margin: const EdgeInsets.all(16),
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: _T.bg,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(children: [
        // Handle
        Container(margin: const EdgeInsets.only(top: 12), width: 40, height: 4, decoration: BoxDecoration(color: _T.border2, borderRadius: BorderRadius.circular(2))),
        // Header
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
          child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
            Text(_step == 0 ? 'Demander l’accès' : _step == 1 ? 'Sélection' : 'Raison', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w300)),
            GestureDetector(onTap: () => Navigator.pop(context), child: const Icon(Icons.close, size: 20, color: _T.ink2)),
          ]),
        ),
        // Progress indicator
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          child: Row(children: [
            _StepDot(active: _step >= 0, done: _step > 0),
            Expanded(child: Container(height: 1, color: _step > 0 ? _T.sage : _T.border)),
            _StepDot(active: _step >= 1, done: _step > 1),
            Expanded(child: Container(height: 1, color: _step > 1 ? _T.sage : _T.border)),
            _StepDot(active: _step >= 2, done: false),
          ]),
        ),
        // Body
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _loadingData
                ? const Center(child: CircularProgressIndicator(strokeWidth: 2, color: _T.sage))
                : _step == 0 ? _TypeStep(onSelect: (type) { _type = type; _nextStep(); })
                : _step == 1 ? _SelectionStep(
                    type: _type,
                    farms: _farms,
                    livestocks: _livestocks,
                    selectedFarm: _selectedFarm,
                    selectedLivestock: _selectedLivestock,
                    selectedCrops: _selectedCrops,
                    animalCount: _animalCount,
                    onFarmChanged: (f) => setState(() { _selectedFarm = f; _selectedCrops.clear(); }),
                    onLivestockChanged: (l) => setState(() { _selectedLivestock = l; _animalCount = 0; }),
                    onToggleCrop: (id, add) => setState(() => add ? _selectedCrops.add(id) : _selectedCrops.remove(id)),
                    onAnimalCountChanged: (c) => setState(() => _animalCount = c),
                    onNext: _canProceedToReason ? _nextStep : null,
                    onBack: _prevStep,
                  )
                : _ReasonStep(
                    controller: _reasonCtrl,
                    summary: _selectionSummary,
                    loading: _loading,
                    onSubmit: _submit,
                    onBack: _prevStep,
                  ),
          ),
        ),
      ]),
    );
  }
}

class _StepDot extends StatelessWidget {
  final bool active;
  final bool done;
  const _StepDot({required this.active, required this.done});

  @override
  Widget build(BuildContext context) => Container(
    width: 8, height: 8,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: active ? _T.sage : _T.border2,
    ),
  );
}

class _TypeStep extends StatelessWidget {
  final void Function(String) onSelect;
  const _TypeStep({required this.onSelect});

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _TypeCard(icon: Icons.agriculture, label: 'Cultures', onTap: () => onSelect('crop')),
      const SizedBox(height: 16),
      _TypeCard(icon: Icons.pets, label: 'Animaux', onTap: () => onSelect('animal')),
    ],
  );
}

class _TypeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _TypeCard({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _T.surf,
        borderRadius: BorderRadius.circular(_T.r16),
        border: Border.all(color: _T.border),
      ),
      child: Row(children: [
        Icon(icon, size: 28, color: _T.sage),
        const SizedBox(width: 20),
        Expanded(child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500))),
        const Icon(Icons.arrow_forward_ios, size: 14, color: _T.ink3),
      ]),
    ),
  );
}

class _SelectionStep extends StatelessWidget {
  final String type;
  final List<dynamic> farms;
  final List<dynamic> livestocks;
  final dynamic selectedFarm;
  final dynamic selectedLivestock;
  final Set<int> selectedCrops;
  final int animalCount;
  final void Function(dynamic) onFarmChanged;
  final void Function(dynamic) onLivestockChanged;
  final void Function(int, bool) onToggleCrop;
  final void Function(int) onAnimalCountChanged;
  final VoidCallback? onNext;
  final VoidCallback onBack;

  const _SelectionStep({required this.type, required this.farms, required this.livestocks, required this.selectedFarm, required this.selectedLivestock, required this.selectedCrops, required this.animalCount, required this.onFarmChanged, required this.onLivestockChanged, required this.onToggleCrop, required this.onAnimalCountChanged, this.onNext, required this.onBack});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (type == 'crop') ...[
        const _SectionTitle(title: 'FERME'),
        const SizedBox(height: 8),
        _Dropdown(
          hint: 'Choisir une ferme',
          value: selectedFarm,
          items: farms.map((f) => DropdownMenuItem(value: f, child: Text(f['name'] ?? ''))).toList(),
          onChanged: onFarmChanged,
        ),
        if (selectedFarm != null && (selectedFarm['crops']?.isNotEmpty ?? false)) ...[
          const SizedBox(height: 20),
          const _SectionTitle(title: 'PARCELLES À DIAGNOSTIQUER'),
          const SizedBox(height: 12),
          Wrap(spacing: 8, children: (selectedFarm['crops'] as List).map((c) => _SelectableChip(
            label: c['crop_name'] ?? 'Parcelle',
            selected: selectedCrops.contains(c['id']),
            onTap: () => onToggleCrop(c['id'], !selectedCrops.contains(c['id'])),
          )).toList()),
        ],
      ] else ...[
        const _SectionTitle(title: 'BÉTAIL'),
        const SizedBox(height: 8),
        _Dropdown(
          hint: 'Choisir un bétail',
          value: selectedLivestock,
          items: livestocks.map((l) => DropdownMenuItem(
            value: l,
            child: Text('${l['animal_type']} · ${l['quantity']} animaux'),
          )).toList(),
          onChanged: onLivestockChanged,
        ),
        if (selectedLivestock != null) ...[
          const SizedBox(height: 20),
          const _SectionTitle(title: 'NOMBRE D\'ANIMAUX À EXAMINER'),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(border: Border.all(color: _T.border), borderRadius: BorderRadius.circular(_T.r12)),
            child: Row(children: [
              Expanded(child: TextField(
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(border: InputBorder.none, hintText: 'ex: 3', hintStyle: TextStyle(fontSize: 13)),
                onChanged: (v) => onAnimalCountChanged(int.tryParse(v) ?? 0),
              )),
              Text('/ ${selectedLivestock['quantity'] ?? 1}', style: const TextStyle(color: _T.ink3)),
            ]),
          ),
        ],
      ],
      const SizedBox(height: 32),
      Row(children: [
        _OutlinedButton(label: 'Retour', onTap: onBack),
        const Spacer(),
        if (onNext != null) _SolidButton(label: 'Suivant', onTap: onNext!, color: _T.sage),
      ]),
    ]);
  }
}

class _SelectableChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _SelectableChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: selected ? _T.sageLight : _T.surf,
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: selected ? _T.sage : _T.border),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 13, color: selected ? _T.sage : _T.ink2,
      )),
    ),
  );
}

class _ReasonStep extends StatelessWidget {
  final TextEditingController controller;
  final String summary;
  final bool loading;
  final VoidCallback onSubmit;
  final VoidCallback onBack;

  const _ReasonStep({required this.controller, required this.summary, required this.loading, required this.onSubmit, required this.onBack});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: _T.sageLight, borderRadius: BorderRadius.circular(_T.r12)),
      child: Row(children: const [
        Icon(Icons.info_outline, size: 16, color: _T.sage),
        SizedBox(width: 8),
        Expanded(child: Text('À diagnostiquer : ...', style: TextStyle(fontSize: 13, color: _T.sage))),
      ]),
    ),
    const SizedBox(height: 20),
    const _SectionTitle(title: 'DÉCRIVEZ LE PROBLÈME'),
    const SizedBox(height: 8),
    TextField(
      controller: controller,
      maxLines: 5,
      decoration: InputDecoration(
        hintText: 'Symptômes, comportements, observations...',
        filled: true,
        fillColor: _T.surf,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(_T.r12), borderSide: const BorderSide(color: _T.border)),
      ),
    ),
    const SizedBox(height: 32),
    Row(children: [
      _OutlinedButton(label: 'Retour', onTap: onBack),
      const Spacer(),
      if (!loading)
        _SolidButton(label: 'Envoyer', onTap: onSubmit, color: _T.sage)
      else
        const SizedBox(width: 40, height: 40, child: CircularProgressIndicator(strokeWidth: 2, color: _T.sage)),
    ]),
  ]);
}

class _Dropdown extends StatelessWidget {
  final String hint;
  final dynamic value;
  final List<DropdownMenuItem<dynamic>> items;
  final ValueChanged<dynamic> onChanged;

  const _Dropdown({required this.hint, required this.value, required this.items, required this.onChanged});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16),
    decoration: BoxDecoration(
      color: _T.surf,
      borderRadius: BorderRadius.circular(_T.r12),
      border: Border.all(color: _T.border),
    ),
    child: DropdownButtonHideUnderline(
      child: DropdownButton<dynamic>(
        value: value,
        hint: Text(hint, style: const TextStyle(color: _T.ink3)),
        isExpanded: true,
        icon: const Icon(Icons.expand_more, size: 18),
        items: items,
        onChanged: onChanged,
      ),
    ),
  );
}