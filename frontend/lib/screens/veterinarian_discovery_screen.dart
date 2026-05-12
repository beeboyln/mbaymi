import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math';
import 'package:mbaymi/models/veterinarian_model.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/token_storage.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/widgets/skeleton_loader.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS
// ─────────────────────────────────────────────────────────────────────────────

abstract class _T {
  // Palette
  static const teal900  = Color(0xFF003D35);
  static const teal800  = Color(0xFF00574C);
  static const teal600  = Color(0xFF00796B);
  static const teal400  = Color(0xFF4DB6AC);
  static const teal100  = Color(0xFFB2DFDB);
  static const teal050  = Color(0xFFE0F2F1);

  static const gold     = Color(0xFFD4A853);
  static const green    = Color(0xFF34A853);

  // Radii
  static const r4  = 4.0;
  static const r8  = 8.0;
  static const r10 = 10.0;
  static const r12 = 12.0;
  static const r16 = 16.0;
  static const r20 = 20.0;

  // Spacing
  static const p16 = EdgeInsets.all(16);
  static const h16 = SizedBox(height: 16);
  static const h12 = SizedBox(height: 12);
  static const h8  = SizedBox(height: 8);
  static const h24 = SizedBox(height: 24);
  static const h32 = SizedBox(height: 32);
  static const w8  = SizedBox(width: 8);
  static const w12 = SizedBox(width: 12);
}

// ─────────────────────────────────────────────────────────────────────────────
// ADAPTIVE COLOR SCHEME
// ─────────────────────────────────────────────────────────────────────────────

class _Scheme {
  final bool isDark;
  const _Scheme(this.isDark);

  Color get bg        => isDark ? const Color(0xFF050E0C) : const Color(0xFFF5FAF9);
  Color get surface   => isDark ? const Color(0xFF0B1917) : Colors.white;
  Color get surfaceEl => isDark ? const Color(0xFF0F211F) : const Color(0xFFFAFEFD);
  Color get border    => isDark ? const Color(0xFF1A3330).withOpacity(0.90) : const Color(0xFFDDEFED);
  Color get textPri   => isDark ? const Color(0xFFDFF2F0) : const Color(0xFF0A1E1B);
  Color get textSec   => isDark ? const Color(0xFF5F9E97) : const Color(0xFF5A7E79);
  Color get textTer   => isDark ? const Color(0xFF335956) : const Color(0xFF9BBDB9);
  Color get divider   => isDark ? const Color(0xFF132220) : const Color(0xFFECF6F5);
  Color get primary   => _T.teal600;
  Color get accent    => _T.teal400;

  BoxDecoration get card => BoxDecoration(
    color: surface,
    borderRadius: BorderRadius.circular(_T.r16),
    border: Border.all(color: border, width: 1),
  );

  BoxDecoration get cardEl => BoxDecoration(
    color: surfaceEl,
    borderRadius: BorderRadius.circular(_T.r12),
    border: Border.all(color: border, width: 1),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED MICRO-COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

/// Hairline section header
class _Label extends StatelessWidget {
  final String text;
  final _Scheme s;
  const _Label(this.text, {required this.s});

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      letterSpacing: 2.4,
      color: s.textTer,
    ),
  );
}

/// Pill badge
class _Pill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;
  const _Pill(this.text, {required this.bg, required this.fg, this.icon});

  @override
  Widget build(BuildContext context) => Container(
    padding: EdgeInsets.symmetric(horizontal: icon != null ? 8 : 10, vertical: 5),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(_T.r4)),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      if (icon != null) ...[
        Icon(icon, size: 9, color: fg),
        const SizedBox(width: 5),
      ],
      Text(text, style: TextStyle(
        fontSize: 8, fontWeight: FontWeight.w700, letterSpacing: 1.6, color: fg,
      )),
    ]),
  );
}

/// Tap-ripple icon button
class _IconBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onTap;
  final _Scheme s;
  const _IconBtn(this.icon, {this.onTap, required this.s});

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: () { HapticFeedback.lightImpact(); onTap?.call(); },
    child: Container(
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: BorderRadius.circular(_T.r8),
        border: Border.all(color: s.border),
      ),
      child: Icon(icon, color: s.textSec, size: 16),
    ),
  );
}

/// Thin animated divider
class _Divider extends StatelessWidget {
  final _Scheme s;
  const _Divider({required this.s});
  @override
  Widget build(BuildContext context) =>
      Divider(height: 1, thickness: 1, color: s.divider);
}

// ─────────────────────────────────────────────────────────────────────────────
// MAIN SCREEN
// ─────────────────────────────────────────────────────────────────────────────

class VeterinarianProfileDetailScreen extends StatefulWidget {
  final String veterinarianId;
  const VeterinarianProfileDetailScreen({super.key, required this.veterinarianId});

  @override
  State<VeterinarianProfileDetailScreen> createState() =>
      _VeterinarianProfileDetailScreenState();
}

class _VeterinarianProfileDetailScreenState
    extends State<VeterinarianProfileDetailScreen>
    with TickerProviderStateMixin {

  late Future<VeterinarianProfile?> _profileFuture;
  bool _isAuthorized = false;

  late AnimationController _entryCtrl;
  late List<Animation<double>>  _fadeAnims;
  late List<Animation<Offset>>  _slideAnims;

  @override
  void initState() {
    super.initState();
    _profileFuture = ApiService.getVeterinarianProfileById(
      int.tryParse(widget.veterinarianId) ?? 0,
    );

    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    _fadeAnims  = List.generate(7, (i) => Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _entryCtrl,
        curve: Interval(i * 0.07, min(i * 0.07 + 0.55, 1.0), curve: Curves.easeOut),
      ),
    ));
    _slideAnims = List.generate(7, (i) => Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _entryCtrl,
      curve: Interval(i * 0.07, min(i * 0.07 + 0.55, 1.0), curve: Curves.easeOutCubic),
    )));
  }

  @override
  void dispose() {
    _entryCtrl.dispose();
    super.dispose();
  }

  Widget _reveal(int i, Widget child) => FadeTransition(
    opacity: _fadeAnims[i],
    child: SlideTransition(position: _slideAnims[i], child: child),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final s = _Scheme(Theme.of(context).brightness == Brightness.dark);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: s.isDark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: s.bg,
        body: FutureBuilder<VeterinarianProfile?>(
          future: _profileFuture,
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return _buildLoading(s);
            }
            if (snap.hasError) {
              return _buildError(snap.error.toString(), s);
            }
            if (!snap.hasData || snap.data == null) {
              return _buildEmpty(s);
            }

            final p = snap.data!;
            _entryCtrl.forward(from: 0);

            return CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                // ── App bar ──
                SliverToBoxAdapter(child: _buildAppBar(s)),

                // ── Profile header ──
                SliverToBoxAdapter(
                  child: _reveal(0, _buildProfileHeader(p, s)),
                ),

                // ── Stats ──
                _pad(child: _reveal(1, _buildStats(p, s))),

                // ── Verified badge ──
                if (p.isVerified)
                  _pad(child: _reveal(2, _buildVerifiedBadge(s))),

                // ── Bio ──
                if (p.bio.isNotEmpty)
                  _pad(child: _reveal(3, _buildBio(p, s))),

                // ── Coverage ──
                _pad(child: _reveal(4, _buildCoverage(p, s))),

                // ── Contact ──
                _pad(child: _reveal(5, _buildContact(p, s))),

                // ── CTA ──
                _pad(
                  top: 8, bottom: 0,
                  child: _reveal(6, _buildCTA(s)),
                ),

                const SliverPadding(padding: EdgeInsets.only(bottom: 96)),
              ],
            );
          },
        ),
      ),
    );
  }

  SliverPadding _pad({
    required Widget child,
    double top = 16,
    double bottom = 0,
  }) => SliverPadding(
    padding: EdgeInsets.fromLTRB(20, top, 20, bottom),
    sliver: SliverToBoxAdapter(child: child),
  );

  // ═══════════════════════════════════════════════════════════════════════════
  // APP BAR (scrolls with content)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildAppBar(_Scheme s) {
    final top = MediaQuery.of(context).padding.top;
    return Padding(
      padding: EdgeInsets.fromLTRB(20, top + 14, 20, 0),
      child: Row(children: [
        _IconBtn(Icons.arrow_back_rounded, s: s,
            onTap: () => Navigator.of(context).pop()),
        const Spacer(),
        _IconBtn(Icons.share_outlined, s: s),
        const SizedBox(width: 8),
        _IconBtn(Icons.bookmark_border_rounded, s: s),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // PROFILE HEADER — avatar + name + meta
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildProfileHeader(VeterinarianProfile p, _Scheme s) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

        // Avatar row
        Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
          // Avatar container
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _T.teal600.withOpacity(s.isDark ? 0.14 : 0.08),
              borderRadius: BorderRadius.circular(_T.r16),
              border: Border.all(color: s.border, width: 1.5),
            ),
            child: Center(
              child: Icon(
                Icons.person_outline_rounded,
                color: _T.teal600.withOpacity(0.45),
                size: 30,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Name + specialty
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              _Pill(
                'VÉTÉRINAIRE',
                bg: _T.teal600.withOpacity(s.isDark ? 0.15 : 0.08),
                fg: _T.teal600.withOpacity(0.85),
                icon: Icons.medical_services_outlined,
              ),
              const SizedBox(height: 8),
              Text(
                p.specialty,
                style: TextStyle(
                  fontSize: 21,
                  fontWeight: FontWeight.w600,
                  color: s.textPri,
                  letterSpacing: -0.8,
                  height: 1.15,
                ),
              ),
            ]),
          ),
        ]),

        const SizedBox(height: 16),

        // Location + availability row
        Row(children: [
          if (p.zone.isNotEmpty) ...[
            Icon(Icons.location_on_outlined, size: 12, color: s.textTer),
            const SizedBox(width: 4),
            Text(p.zone, style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: s.textSec,
            )),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 10),
              width: 3, height: 3,
              decoration: BoxDecoration(
                color: s.textTer,
                shape: BoxShape.circle,
              ),
            ),
          ],
          Icon(Icons.radio_button_checked, size: 8, color: _T.green),
          const SizedBox(width: 5),
          Text('Disponible', style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: _T.green.withOpacity(0.85),
          )),
        ]),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATS — inline horizontal
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildStats(VeterinarianProfile p, _Scheme s) {
    return Container(
      decoration: s.card,
      child: Column(children: [
        IntrinsicHeight(
          child: Row(children: [
            _StatCell(
              value: '${p.consultationCount ?? 0}',
              label: 'Consultations',
              icon: Icons.video_call_outlined,
              color: _T.teal600,
              s: s,
            ),
            VerticalDivider(width: 1, thickness: 1, color: s.divider),
            _StatCell(
              value: p.rating?.toStringAsFixed(1) ?? '—',
              label: 'Note',
              icon: Icons.star_outline_rounded,
              color: _T.gold,
              s: s,
            ),
            VerticalDivider(width: 1, thickness: 1, color: s.divider),
            _StatCell(
              value: '${p.experienceYears} ans',
              label: 'Expérience',
              icon: Icons.timeline_outlined,
              color: _T.teal400,
              s: s,
            ),
          ]),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // VERIFIED BADGE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildVerifiedBadge(_Scheme s) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _T.green.withOpacity(s.isDark ? 0.08 : 0.05),
        borderRadius: BorderRadius.circular(_T.r12),
        border: Border.all(color: _T.green.withOpacity(0.18)),
      ),
      child: Row(children: [
        Icon(Icons.verified_rounded, color: _T.green, size: 15),
        const SizedBox(width: 10),
        Text('Vétérinaire certifié et vérifié', style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: _T.green.withOpacity(0.90),
          letterSpacing: 0.1,
        )),
        const Spacer(),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: _T.green.withOpacity(0.12),
            borderRadius: BorderRadius.circular(_T.r4),
          ),
          child: Text('CERTIFIÉ', style: TextStyle(
            fontSize: 7, fontWeight: FontWeight.w700,
            letterSpacing: 1.5, color: _T.green,
          )),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // BIO
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildBio(VeterinarianProfile p, _Scheme s) {
    return Container(
      decoration: s.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: _Label('À propos', s: s),
        ),
        _Divider(s: s),
        Padding(
          padding: const EdgeInsets.all(18),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Accent bar
            Container(
              width: 2,
              height: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _T.teal400.withOpacity(0.85),
                    _T.teal400.withOpacity(0.08),
                  ],
                ),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(p.bio, style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w300,
                color: s.textSec,
                height: 1.70,
                letterSpacing: 0.08,
              )),
            ),
          ]),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // COVERAGE
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCoverage(VeterinarianProfile p, _Scheme s) {
    return Container(
      decoration: s.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: _Label('Zone de couverture', s: s),
        ),
        _Divider(s: s),
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: 'Zone',
          value: p.zone,
          s: s,
        ),
        _Divider(s: s),
        _InfoRow(
          icon: Icons.radar_rounded,
          label: "Rayon d'intervention",
          value: '${p.distanceMax} km',
          s: s,
          isLast: true,
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CONTACT
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildContact(VeterinarianProfile p, _Scheme s) {
    const meta = {
      'whatsapp': (icon: Icons.chat_bubble_outline_rounded, label: 'WhatsApp', sub: 'Messages et appels'),
      'call':     (icon: Icons.phone_outlined,              label: 'Téléphone', sub: 'Contact direct'),
      'email':    (icon: Icons.mail_outline_rounded,        label: 'Email',     sub: 'Messagerie électronique'),
    };
    final ct = meta[p.contactPreference] ??
        (icon: Icons.contact_phone_outlined, label: p.contactPreference.toUpperCase(), sub: '');

    return Container(
      decoration: s.card,
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 12),
          child: _Label('Contact préféré', s: s),
        ),
        _Divider(s: s),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => HapticFeedback.lightImpact(),
            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(_T.r16)),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 14, 14, 14),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _T.teal400.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(_T.r10),

                  ),
                  child: Icon(ct.icon, color: _T.teal400, size: 17),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(ct.label, style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: s.textPri,
                    )),
                    const SizedBox(height: 2),
                    Text(ct.sub, style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: s.textTer,
                    )),
                  ],
                )),
                Icon(Icons.arrow_forward_ios_rounded,
                    color: s.textTer, size: 13),
              ]),
            ),
          ),
        ),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // CTA
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildCTA(_Scheme s) {
    if (_isAuthorized) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: _T.green.withOpacity(s.isDark ? 0.08 : 0.05),
          borderRadius: BorderRadius.circular(_T.r16),
          border: Border.all(color: _T.green.withOpacity(0.18)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.check_circle_outline_rounded,
              color: _T.green.withOpacity(0.80), size: 16),
          const SizedBox(width: 10),
          Text('Accès autorisé', style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _T.green.withOpacity(0.90),
          )),
        ]),
      );
    }

    return GestureDetector(
      onTap: _requestAuthorization,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 17),
        decoration: BoxDecoration(
          color: _T.teal900,
          borderRadius: BorderRadius.circular(_T.r16),
          border: Border.all(color: _T.teal600.withOpacity(0.30)),
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.lock_open_rounded, color: Colors.white.withOpacity(0.70), size: 15),
          const SizedBox(width: 10),
          const Text("Demander l'accès", style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.white,
            letterSpacing: 0.1,
          )),
        ]),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // ACTIONS
  // ═══════════════════════════════════════════════════════════════════════════

  void _requestAuthorization() {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        final s = _Scheme(Theme.of(context).brightness == Brightness.dark);
        return _AuthorizationSheet(
          veterinarianId: widget.veterinarianId,
          s: s,
          onSuccess: () {
            setState(() => _isAuthorized = true);
            ScaffoldMessenger.of(context).showSnackBar(SnackBar(
              content: const Text('Demande envoyée avec succès'),
              backgroundColor: _T.teal900,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(_T.r12)),
            ));
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // STATES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLoading(_Scheme s) => Column(children: [
    _buildAppBar(s),
    Expanded(child: SkeletonPageLoader(isDarkMode: s.isDark, includeAppBar: false, cardCount: 4)),
  ]);

  Widget _buildError(String err, _Scheme s) => Scaffold(
    backgroundColor: s.bg,
    body: SafeArea(child: Padding(
      padding: const EdgeInsets.all(36),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.07),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.error_outline_rounded,
              color: Colors.red.withOpacity(0.55), size: 32),
        ),
        const SizedBox(height: 20),
        Text('Erreur de chargement', style: TextStyle(
          fontSize: 17, fontWeight: FontWeight.w500,
          color: s.textPri, letterSpacing: -0.3,
        )),
        const SizedBox(height: 8),
        Text(err, style: TextStyle(
          fontSize: 12, color: s.textTer,
          fontWeight: FontWeight.w300,
        ), textAlign: TextAlign.center),
        const SizedBox(height: 32),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          _OutlineButton(
            label: 'Retour',
            onTap: () => Navigator.pop(context),
            s: s,
          ),
          const SizedBox(width: 10),
          _SolidButton(
            label: 'Réessayer',
            onTap: () => setState(() => _profileFuture =
                ApiService.getVeterinarianProfileById(
                    int.tryParse(widget.veterinarianId) ?? 0)),
            s: s,
          ),
        ]),
      ]),
    )),
  );

  Widget _buildEmpty(_Scheme s) => Scaffold(
    backgroundColor: s.bg,
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      Container(
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          color: _T.teal600.withOpacity(0.07),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.person_off_outlined,
            color: _T.teal600.withOpacity(0.35), size: 32),
      ),
      const SizedBox(height: 18),
      Text('Profil introuvable', style: TextStyle(
        fontSize: 16, fontWeight: FontWeight.w400,
        color: s.textSec,
      )),
    ])),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// STAT CELL (for stats row inside card)
// ─────────────────────────────────────────────────────────────────────────────

class _StatCell extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;
  final _Scheme s;
  const _StatCell({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
    required this.s,
  });

  @override
  Widget build(BuildContext context) => Expanded(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 16, 18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: color, size: 13),
        ),
        const SizedBox(height: 10),
        Text(value, style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: s.textPri,
          letterSpacing: -0.8,
          height: 1.0,
        )),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w400,
          color: s.textTer,
          letterSpacing: 0.2,
        )),
      ]),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// INFO ROW (inside coverage / contact cards)
// ─────────────────────────────────────────────────────────────────────────────

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final _Scheme s;
  final bool isLast;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.s,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.fromLTRB(18, 14, 18, isLast ? 14 : 14),
    child: Row(children: [
      Icon(icon, color: _T.teal400, size: 15),
      const SizedBox(width: 12),
      Expanded(child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
            color: s.textTer,
          )),
          const SizedBox(height: 3),
          Text(value, style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: s.textPri,
          )),
        ],
      )),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// REUSABLE BUTTONS
// ─────────────────────────────────────────────────────────────────────────────

class _OutlineButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final _Scheme s;
  const _OutlineButton({required this.label, required this.onTap, required this.s});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(_T.r12),
        border: Border.all(color: s.border, width: 1.5),
      ),
      child: Text(label, style: TextStyle(
        fontSize: 13, fontWeight: FontWeight.w400, color: s.textSec,
      )),
    ),
  );
}

class _SolidButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final _Scheme s;
  const _SolidButton({required this.label, required this.onTap, required this.s});
  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 13),
      decoration: BoxDecoration(
        color: _T.teal900,
        borderRadius: BorderRadius.circular(_T.r12),
      ),
      child: Text(label, style: const TextStyle(
        fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white,
      )),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// AUTHORIZATION BOTTOM SHEET
// ─────────────────────────────────────────────────────────────────────────────

class _AuthorizationSheet extends StatefulWidget {
  final String veterinarianId;
  final VoidCallback onSuccess;
  final _Scheme s;
  const _AuthorizationSheet({
    required this.veterinarianId,
    required this.onSuccess,
    required this.s,
  });

  @override
  State<_AuthorizationSheet> createState() => _AuthorizationSheetState();
}

class _AuthorizationSheetState extends State<_AuthorizationSheet>
    with SingleTickerProviderStateMixin {

  final _reasonCtrl = TextEditingController();
  bool _isLoading   = false;
  bool _loadingData = true;
  List<dynamic> _farms     = [];
  List<dynamic> _livestocks = [];
  dynamic _selectedFarm;
  dynamic _selectedLivestock;
  dynamic _selectedCrop;
  final Set<int> _selectedCrops   = {};
  final Set<int> _selectedAnimals = {};
  int _tab = 0;

  late TabController _tabCtrl;

  _Scheme get s => widget.s;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this)
      ..addListener(() {
        if (!_tabCtrl.indexIsChanging) {
          setState(() { _tab = _tabCtrl.index; _clearSelections(); });
        }
      });
    _loadData();
  }

  @override
  void dispose() {
    _reasonCtrl.dispose();
    _tabCtrl.dispose();
    super.dispose();
  }

  void _clearSelections() {
    _selectedFarm = null;
    _selectedLivestock = null;
    _selectedCrop = null;
    _selectedCrops.clear();
    _selectedAnimals.clear();
  }

  Future<void> _loadData() async {
    try {
      final farms  = await ApiService.getUserFarms();
      final userId = await TokenStorage.getUserId();
      final ls = userId != null ? await ApiService.getUserLivestock(userId) : <dynamic>[];
      if (mounted) setState(() { _farms = farms; _livestocks = ls; _loadingData = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingData = false);
    }
  }

  String _diagnosisSummary() {
    if (_tab == 0 && _selectedCrops.isNotEmpty)   return '${_selectedCrops.length} culture(s)';
    if (_tab == 1 && _selectedAnimals.isNotEmpty) return '${_selectedAnimals.length} animal(aux)';
    return 'Aucune sélection';
  }

  bool get _canSubmit {
    if (_loadingData || _isLoading) return false;
    if (_tab == 0) return _selectedFarm != null && _selectedCrops.isNotEmpty;
    return _selectedLivestock != null && _selectedAnimals.isNotEmpty;
  }

  Future<void> _submit() async {
    if (_reasonCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Décrivez le problème'),
        backgroundColor: Colors.orange,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _isLoading = true);
    try {
      final reason =
          '${_reasonCtrl.text.trim()}\n\n[À diagnostiquer: ${_diagnosisSummary()}]';
      await ApiService.createAuthorization(
        farmId:              _tab == 0 ? (_selectedFarm['id'] as int) : 0,
        veterinarianId:      int.tryParse(widget.veterinarianId) ?? 0,
        authorizationReason: reason,
        selectedLivestockIds: _tab == 1 ? (_selectedLivestock['id'].toString()) : null,
        selectedCropIds:      _tab == 0 ? _selectedCrops.join(',') : null,
      );
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Erreur : $e'),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SHEET BUILD
  // ═══════════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.88,
      decoration: BoxDecoration(
        color: s.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(children: [
          _buildSheetHandle(),
          _buildSheetHeader(),
          _Divider(s: s),
          _buildSheetTabs(),
          const SizedBox(height: 4),
          Expanded(child: _buildSheetBody()),
          _buildSheetFooter(),
        ]),
      ),
    );
  }

  Widget _buildSheetHandle() => Padding(
    padding: const EdgeInsets.only(top: 16, bottom: 4),
    child: Center(child: Container(
      width: 36, height: 3.5,
      decoration: BoxDecoration(
        color: s.border,
        borderRadius: BorderRadius.circular(2),
      ),
    )),
  );

  Widget _buildSheetHeader() => Padding(
    padding: const EdgeInsets.fromLTRB(22, 16, 22, 16),
    child: Row(children: [
      Container(
        padding: const EdgeInsets.all(9),
        decoration: BoxDecoration(
          color: _T.teal400.withOpacity(0.10),
          borderRadius: BorderRadius.circular(_T.r10),
        ),
        child: Icon(Icons.lock_open_rounded, color: _T.teal400, size: 15),
      ),
      const SizedBox(width: 14),
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Accès vétérinaire', style: TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w600,
          color: s.textPri,
          letterSpacing: -0.4,
        )),
        Text('Complétez la demande', style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w300,
          color: s.textTer,
        )),
      ]),
    ]),
  );

  Widget _buildSheetTabs() => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
    child: Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: _T.teal900.withOpacity(s.isDark ? 0.35 : 0.06),
        borderRadius: BorderRadius.circular(_T.r10),
      ),
      child: TabBar(
        controller: _tabCtrl,
        indicator: BoxDecoration(
          color: s.isDark ? _T.teal800 : Colors.white,
          borderRadius: BorderRadius.circular(_T.r8),
          border: Border.all(color: s.border),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        labelColor: s.textPri,
        unselectedLabelColor: s.textTer,
        labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w300),
        dividerColor: Colors.transparent,
        tabs: const [
          Tab(text: '🌾  Cultures'),
          Tab(text: '🐄  Animaux'),
        ],
      ),
    ),
  );

  Widget _buildSheetBody() => SingleChildScrollView(
    padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
    physics: const BouncingScrollPhysics(),
    child: _loadingData
        ? SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator(
              strokeWidth: 1.5,
              valueColor: AlwaysStoppedAnimation(_T.teal400),
            )),
          )
        : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            if (_tab == 0) _culturesTab() else _animalsTab(),
            const SizedBox(height: 20),

            // Summary
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: _T.teal600.withOpacity(s.isDark ? 0.07 : 0.04),
                borderRadius: BorderRadius.circular(_T.r10),
                border: Border.all(color: _T.teal600.withOpacity(0.12)),
              ),
              child: Row(children: [
                Icon(Icons.assignment_outlined, color: _T.teal400, size: 14),
                const SizedBox(width: 10),
                Expanded(child: Text(
                  'Diagnostic : ${_diagnosisSummary()}',
                  style: TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w400,
                    color: _T.teal600,
                  ),
                )),
              ]),
            ),
            const SizedBox(height: 20),

            // Reason field
            _Label('Raison de la demande', s: s),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: s.surfaceEl,
                borderRadius: BorderRadius.circular(_T.r12),
                border: Border.all(color: s.border),
              ),
              child: TextField(
                controller: _reasonCtrl,
                maxLines: 5,
                style: TextStyle(fontSize: 13, color: s.textPri,
                    fontWeight: FontWeight.w300),
                decoration: InputDecoration(
                  hintText: 'Décrivez les symptômes ou problèmes observés…',
                  hintStyle: TextStyle(
                    color: s.textTer, fontSize: 12,
                    fontWeight: FontWeight.w300,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
          ]),
  );

  Widget _buildSheetFooter() => Container(
    padding: EdgeInsets.fromLTRB(
        20, 14, 20, MediaQuery.of(context).padding.bottom + 14),
    decoration: BoxDecoration(
      color: s.surface,
      border: Border(top: BorderSide(color: s.border)),
    ),
    child: Row(children: [
      _OutlineButton(label: 'Annuler',
          onTap: () { HapticFeedback.lightImpact(); Navigator.pop(context); },
          s: s),
      const SizedBox(width: 10),
      Expanded(child: GestureDetector(
        onTap: _canSubmit ? _submit : null,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(vertical: 15),
          decoration: BoxDecoration(
            color: _canSubmit ? _T.teal900 : _T.teal900.withOpacity(0.25),
            borderRadius: BorderRadius.circular(_T.r12),
          ),
          child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            if (_isLoading)
              const SizedBox(width: 18, height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 1.5,
                    valueColor: AlwaysStoppedAnimation(Colors.white),
                  ))
            else ...[
              const Icon(Icons.send_rounded, color: Colors.white, size: 14),
              const SizedBox(width: 8),
              const Text('Envoyer la demande', style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w500, color: Colors.white,
              )),
            ],
          ]),
        ),
      )),
    ]),
  );

  // ─── CULTURES TAB ───────────────────────────────────────────────────────────

  Widget _culturesTab() {
    if (_farms.isEmpty) return _emptyTab("Aucune ferme enregistrée.");
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Label('Ferme', s: s),
      const SizedBox(height: 10),
      _SheetDropdown(
        value: _selectedFarm,
        hint: 'Sélectionner une ferme',
        icon: Icons.agriculture_rounded,
        items: _farms.map((f) => DropdownMenuItem(value: f,
            child: Text(f['name'] ?? 'Ferme sans nom'))).toList(),
        onChanged: (v) => setState(() {
          _selectedFarm = v; _selectedCrops.clear(); _selectedCrop = null;
        }),
        s: s,
      ),
      if (_selectedFarm != null &&
          (_selectedFarm['crops']?.isNotEmpty ?? false)) ...[
        const SizedBox(height: 20),
        _Label('Cultures à examiner', s: s),
        const SizedBox(height: 10),
        _SheetDropdown(
          value: _selectedCrop,
          hint: '+ Ajouter une culture',
          icon: Icons.grass_rounded,
          items: (_selectedFarm['crops'] as List)
              .where((c) => !_selectedCrops.contains(c['id']))
              .map((c) => DropdownMenuItem(value: c,
                  child: Text(c['crop_name'] ?? 'Culture'))).toList(),
          onChanged: (c) {
            if (c != null) setState(() {
              _selectedCrops.add(c['id'] as int); _selectedCrop = null;
            });
          },
          s: s,
        ),
        if (_selectedCrops.isNotEmpty) ...[
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 8,
            children: _selectedCrops.map((id) {
              final c = (_selectedFarm['crops'] as List)
                  .firstWhere((x) => x['id'] == id, orElse: () => null);
              if (c == null) return const SizedBox.shrink();
              return _CropChip(
                label: c['crop_name'] ?? 'Culture',
                s: s,
                onRemove: () => setState(() => _selectedCrops.remove(id)),
              );
            }).toList(),
          ),
        ],
      ],
    ]);
  }

  // ─── ANIMALS TAB ────────────────────────────────────────────────────────────

  Widget _animalsTab() {
    if (_livestocks.isEmpty) return _emptyTab("Aucun bétail enregistré.");
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Label('Bétail', s: s),
      const SizedBox(height: 10),
      _SheetDropdown(
        value: _selectedLivestock,
        hint: 'Sélectionner un bétail',
        icon: Icons.pets_rounded,
        items: _livestocks.map((l) => DropdownMenuItem(value: l,
            child: Text(
              '${l['animal_type']} — ${l['breed'] ?? 'Race'} (×${l['quantity'] ?? 1})',
              overflow: TextOverflow.ellipsis,
            ))).toList(),
        onChanged: (v) => setState(() {
          _selectedLivestock = v; _selectedAnimals.clear();
        }),
        s: s,
      ),
      if (_selectedLivestock != null) ...[
        const SizedBox(height: 20),
        _Label("Nombre d'animaux", s: s),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: s.surfaceEl,
            borderRadius: BorderRadius.circular(_T.r12),
            border: Border.all(color: s.border),
          ),
          child: Row(children: [
            Icon(Icons.pets_rounded, color: _T.teal400, size: 15),
            const SizedBox(width: 12),
            Expanded(child: TextField(
              keyboardType: TextInputType.number,
              style: TextStyle(fontSize: 13, color: s.textPri),
              decoration: InputDecoration(
                hintText: "Nombre d'animaux à examiner",
                hintStyle: TextStyle(color: s.textTer, fontSize: 12),
                border: InputBorder.none,
                isDense: true,
                contentPadding: EdgeInsets.zero,
              ),
              onChanged: (v) {
                final q   = int.tryParse(v) ?? 0;
                final max = _selectedLivestock['quantity'] as int? ?? 1;
                setState(() {
                  _selectedAnimals.clear();
                  for (int i = 0; i < q.clamp(0, max); i++) {
                    _selectedAnimals.add(i);
                  }
                });
              },
            )),
            Text('sur ${_selectedLivestock['quantity'] ?? 1}',
                style: TextStyle(fontSize: 11, color: s.textTer)),
          ]),
        ),
        if (_selectedAnimals.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: _T.green.withOpacity(s.isDark ? 0.08 : 0.05),
              borderRadius: BorderRadius.circular(_T.r8),
              border: Border.all(color: _T.green.withOpacity(0.15)),
            ),
            child: Row(children: [
              Icon(Icons.check_circle_outline_rounded,
                  color: _T.green.withOpacity(0.80), size: 13),
              const SizedBox(width: 8),
              Text('${_selectedAnimals.length} animal(aux) sélectionné(s)',
                  style: TextStyle(fontSize: 11, color: _T.green.withOpacity(0.85))),
            ]),
          ),
        ],
      ],
    ]);
  }

  Widget _emptyTab(String msg) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 28),
    child: Row(children: [
      Icon(Icons.info_outline_rounded, color: s.textTer, size: 14),
      const SizedBox(width: 10),
      Expanded(child: Text(msg, style: TextStyle(
        fontSize: 12, fontWeight: FontWeight.w300, color: s.textSec,
      ))),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHEET DROPDOWN
// ─────────────────────────────────────────────────────────────────────────────

class _SheetDropdown extends StatelessWidget {
  final dynamic value;
  final String hint;
  final IconData icon;
  final List<DropdownMenuItem<dynamic>> items;
  final ValueChanged<dynamic> onChanged;
  final _Scheme s;

  const _SheetDropdown({
    required this.value,
    required this.hint,
    required this.icon,
    required this.items,
    required this.onChanged,
    required this.s,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
    decoration: BoxDecoration(
      color: s.surfaceEl,
      borderRadius: BorderRadius.circular(_T.r12),
      border: Border.all(color: s.border),
    ),
    child: Row(children: [
      Icon(icon, color: _T.teal400.withOpacity(0.60), size: 15),
      const SizedBox(width: 10),
      Expanded(child: DropdownButtonHideUnderline(
        child: DropdownButton<dynamic>(
          value: value,
          isExpanded: true,
          dropdownColor: s.surface,
          style: TextStyle(fontSize: 13, color: s.textPri),
          hint: Text(hint, style: TextStyle(
            fontSize: 12, color: s.textTer, fontWeight: FontWeight.w300,
          )),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: s.textTer, size: 18),
          items: items,
          onChanged: onChanged,
        ),
      )),
    ]),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// CROP CHIP
// ─────────────────────────────────────────────────────────────────────────────

class _CropChip extends StatelessWidget {
  final String label;
  final _Scheme s;
  final VoidCallback onRemove;
  const _CropChip({required this.label, required this.s, required this.onRemove});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.fromLTRB(10, 6, 8, 6),
    decoration: BoxDecoration(
      color: _T.teal400.withOpacity(0.08),
      borderRadius: BorderRadius.circular(_T.r8),
      border: Border.all(color: _T.teal400.withOpacity(0.20)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(Icons.grass_rounded, size: 11, color: _T.teal400),
      const SizedBox(width: 6),
      Text(label, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w500, color: s.textPri,
      )),
      const SizedBox(width: 6),
      GestureDetector(
        onTap: onRemove,
        child: Icon(Icons.close_rounded, size: 12, color: s.textTer),
      ),
    ]),
  );
}