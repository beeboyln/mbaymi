import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// PAINTERS
// ═══════════════════════════════════════════════════════════════════════════

class _GrainPainter extends CustomPainter {
  final double seed;
  final Color color;
  _GrainPainter({required this.seed, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final rng = Random((seed * 1000).toInt());
    final paint = Paint()..style = PaintingStyle.fill;
    for (int i = 0; i < 220; i++) {
      final x = rng.nextDouble() * size.width;
      final y = rng.nextDouble() * size.height;
      final r = rng.nextDouble() * 0.9 + 0.2;
      paint.color = color.withOpacity(rng.nextDouble() * 0.035 + 0.005);
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
  _WavePainter({required this.phase, required this.color, this.yOffset = 0.6});

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

// ═══════════════════════════════════════════════════════════════════════════
// THEME TOKENS
// ═══════════════════════════════════════════════════════════════════════════

class _Tok {
  final bool dark;
  const _Tok(this.dark);

  Color get bg       => dark ? const Color(0xFF050F06) : const Color(0xFFF2F5F2);
  Color get surface  => dark ? const Color(0xFF0D1A0B) : const Color(0xFFFFFFFF);
  Color get surface2 => dark ? const Color(0xFF112614) : const Color(0xFFECF3EC);
  Color get border   => dark ? const Color(0x0EFFFFFF) : const Color(0x18000000);
  Color get textPri  => dark ? const Color(0xFFF0EDE6) : const Color(0xFF1A2B1B);
  Color get textSec  => dark ? const Color(0xFF8A9E8B) : const Color(0xFF4E6B4F);
  Color get textDim  => dark ? const Color(0xFF4A5E4B) : const Color(0xFF8FAF90);

  static const green  = Color(0xFF2E7D32);
  static const accent = Color(0xFF66BB6A);
  static const amber  = Color(0xFFE8A838);
  static const red    = Color(0xFFE05C5C);
  static const blue   = Color(0xFF5C8DE0);
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN SCREEN
// ═══════════════════════════════════════════════════════════════════════════

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({Key? key}) : super(key: key);

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen>
    with TickerProviderStateMixin {

  int  _selectedTab = 0;
  bool _isDark      = true;

  List<dynamic>        _pendingVets  = [];
  List<dynamic>        _verifiedVets = [];
  List<dynamic>        _pendingAuths = [];
  List<dynamic>        _activeAuths  = [];
  List<dynamic>        _allUsers     = [];
  Map<String, dynamic> _stats        = {};
  List<dynamic>        _activities   = [];

  bool    _isLoading = true;
  String? _error;

  late AnimationController _waveCtrl;
  late AnimationController _grainCtrl;
  late AnimationController _entryCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  static const _tabs = [
    _TabDef(icon: Icons.dashboard_rounded,       label: 'Tableau de bord'),
    _TabDef(icon: Icons.hourglass_top_rounded,   label: 'En attente'),
    _TabDef(icon: Icons.verified_rounded,        label: 'Vérifiés'),
    _TabDef(icon: Icons.pending_actions_rounded, label: 'Demandes auth.'),
    _TabDef(icon: Icons.shield_rounded,          label: 'Auth. actives'),
    _TabDef(icon: Icons.people_rounded,          label: 'Utilisateurs'),
  ];

  @override
  void initState() {
    super.initState();
    _waveCtrl  = AnimationController(vsync: this, duration: const Duration(seconds: 9))..repeat(reverse: true);
    _grainCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120))..repeat();
    _entryCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _fadeAnim  = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.06), end: Offset.zero)
        .animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _loadData();
  }

  @override
  void dispose() {
    _waveCtrl.dispose();
    _grainCtrl.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── DATA ─────────────────────────────────────────────────────────────────

  Future<void> _loadData() async {
    setState(() { _isLoading = true; _error = null; });
    _entryCtrl.forward(from: 0);
    try {
      switch (_selectedTab) {
        case 0:
          // Charger stats + vétérinaires vérifiés + auths actives en parallèle
          // pour construire le feed d'activité depuis les données existantes
          final results = await Future.wait([
            ApiService.getAdminStatistics(),
            ApiService.getAdminVerifiedVeterinarians(),
            ApiService.getAdminActiveAuthorizations(),
            ApiService.getAdminPendingVeterinarians(),
          ]);
          setState(() {
            _stats      = results[0] as Map<String, dynamic>;
            _activities = _buildActivityFeed(
              verified:  results[1] as List<dynamic>,
              active:    results[2] as List<dynamic>,
              pending:   results[3] as List<dynamic>,
            );
          });
          break;
        case 1:
          final v = await ApiService.getAdminPendingVeterinarians();
          setState(() => _pendingVets = v);
          break;
        case 2:
          final v = await ApiService.getAdminVerifiedVeterinarians();
          setState(() => _verifiedVets = v);
          break;
        case 3:
          final a = await ApiService.getAdminPendingAuthorizations();
          setState(() => _pendingAuths = a);
          break;
        case 4:
          final a = await ApiService.getAdminActiveAuthorizations();
          setState(() => _activeAuths = a);
          break;
        case 5:
          final u = await ApiService.getAdminAllUsers();
          setState(() => _allUsers = u);
          break;
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Construit un feed d'activité depuis les données déjà chargées
  List<Map<String, dynamic>> _buildActivityFeed({
    required List<dynamic> verified,
    required List<dynamic> active,
    required List<dynamic> pending,
  }) {
    final items = <Map<String, dynamic>>[];

    for (final v in verified) {
      if (v['verified_at'] != null) {
        items.add({
          'type':        'vet_verified',
          'description': 'Dr. ${v['name'] ?? '?'} vérifié — ${v['specialty'] ?? ''}',
          'created_at':  v['verified_at'],
        });
      }
    }

    for (final a in active) {
      final date = a['created_at'] ?? a['authorized_at'];
      if (date != null) {
        items.add({
          'type':        'auth_created',
          'description': 'Autorisation ${a['farmer_name'] ?? '?'} → ${a['veterinarian_name'] ?? '?'} activée',
          'created_at':  date,
        });
      }
    }

    for (final v in pending) {
      final date = v['created_at'] ?? v['registered_at'];
      if (date != null) {
        items.add({
          'type':        'vet_registered',
          'description': '${v['name'] ?? '?'} a soumis une demande d\'inscription',
          'created_at':  date,
        });
      }
    }

    items.sort((a, b) {
      try {
        return DateTime.parse(b['created_at'] as String)
            .compareTo(DateTime.parse(a['created_at'] as String));
      } catch (_) { return 0; }
    });

    return items.take(8).toList();
  }

  void _switchTab(int idx) {
    HapticFeedback.selectionClick();
    setState(() => _selectedTab = idx);
    _loadData();
  }

  void _toggleTheme() {
    HapticFeedback.selectionClick();
    setState(() => _isDark = !_isDark);
  }

  // ── ACTIONS ──────────────────────────────────────────────────────────────

  Future<void> _verifyVet(int id) async {
    try {
      await ApiService.adminVerifyVeterinarian(id);
      _showSnack('Vétérinaire vérifié ✓', color: _Tok.accent);
      _loadData();
    } catch (e) { _showSnack('Erreur: $e', color: _Tok.red); }
  }

  Future<void> _rejectVet(int id) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => _RejectDialog(isDark: _isDark),
    );
    if (reason == null) return;
    try {
      await ApiService.adminRejectVeterinarian(id, reason: reason);
      _showSnack('Vétérinaire rejeté', color: _Tok.amber);
      _loadData();
    } catch (e) { _showSnack('Erreur: $e', color: _Tok.red); }
  }

  Future<void> _revokeAuth(int id) async {
    try {
      await ApiService.adminRevokeAuthorization(id);
      _showSnack('Autorisation révoquée', color: _Tok.amber);
      _loadData();
    } catch (e) { _showSnack('Erreur: $e', color: _Tok.red); }
  }

  Future<void> _createUser() async {
    final result = await showDialog<Map<String, String>>(
      context: context,
      builder: (_) => _CreateUserDialog(isDark: _isDark),
    );
    if (result == null) return;
    try {
      await ApiService.adminCreateUser(
        name: result['name'] ?? '',
        email: result['email'] ?? '',
        password: result['password'] ?? '',
        role: result['role'] ?? 'user',
      );
      _showSnack('Utilisateur créé ✓', color: _Tok.accent);
      _loadData();
    } catch (e) { _showSnack('Erreur: $e', color: _Tok.red); }
  }

  Future<void> _deleteUser(int userId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        isDark: _isDark,
        title: 'Supprimer l\'utilisateur ?',
        message: 'Cette action est irréversible.',
        confirmText: 'Supprimer',
        isDestructive: true,
      ),
    );
    if (confirm != true) return;
    try {
      await ApiService.adminDeleteUser(userId);
      _showSnack('Utilisateur supprimé', color: _Tok.red);
      _loadData();
    } catch (e) { _showSnack('Erreur: $e', color: _Tok.red); }
  }

  Future<void> _updateUserRole(int userId, String currentRole) async {
    final newRole = await showDialog<String>(
      context: context,
      builder: (_) => _RoleDialog(isDark: _isDark, currentRole: currentRole),
    );
    if (newRole == null) return;
    try {
      await ApiService.adminUpdateUserRole(userId, role: newRole);
      _showSnack('Rôle mis à jour ✓', color: _Tok.accent);
      _loadData();
    } catch (e) { _showSnack('Erreur: $e', color: _Tok.red); }
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _LogoutDialog(isDark: _isDark),
    );
    if (confirm != true || !mounted) return;
    await AuthService.logout();
    if (mounted) Navigator.of(context).pushReplacementNamed('/login');
  }

  void _showSnack(String msg, {Color color = _Tok.accent}) {
    final tok = _Tok(_isDark);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: TextStyle(color: tok.bg, fontWeight: FontWeight.w500)),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final tok = _Tok(_isDark);
    final pendingCount = (_stats['veterinarians']?['pending'] ?? 0) as int;

    return Scaffold(
      backgroundColor: tok.bg,
      body: Row(
        children: [
          _Sidebar(
            tabs: _tabs,
            selected: _selectedTab,
            onSelect: _switchTab,
            pendingCount: pendingCount,
            isDark: _isDark,
            onToggleTheme: _toggleTheme,
            onLogout: _logout,
          ),
          Expanded(
            child: Column(
              children: [
                _TopBar(tabLabel: _tabs[_selectedTab].label, onRefresh: _loadData, isDark: _isDark),
                Expanded(child: _body(tok)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _body(_Tok tok) {
    if (_isLoading) return _LoadingShimmer(tok: tok);
    if (_error != null) return _ErrorView(error: _error!, onRetry: _loadData, tok: tok);
    return FadeTransition(
      opacity: _fadeAnim,
      child: SlideTransition(
        position: _slideAnim,
        child: [
          _StatsTab(stats: _stats, activities: _activities, waveCtrl: _waveCtrl, grainCtrl: _grainCtrl, tok: tok),
          _PendingVetsTab(vets: _pendingVets, onVerify: _verifyVet, onReject: _rejectVet, tok: tok),
          _VerifiedVetsTab(vets: _verifiedVets, tok: tok),
          _PendingAuthsTab(auths: _pendingAuths, tok: tok),
          _ActiveAuthsTab(auths: _activeAuths, onRevoke: _revokeAuth, tok: tok),
          _UsersTab(users: _allUsers, onCreateUser: _createUser, onDeleteUser: _deleteUser, onUpdateRole: _updateUserRole, tok: tok),
        ][_selectedTab],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SIDEBAR
// ═══════════════════════════════════════════════════════════════════════════

class _TabDef {
  final IconData icon;
  final String label;
  const _TabDef({required this.icon, required this.label});
}

class _Sidebar extends StatelessWidget {
  final List<_TabDef> tabs;
  final int selected;
  final ValueChanged<int> onSelect;
  final int pendingCount;
  final bool isDark;
  final VoidCallback onToggleTheme;
  final VoidCallback onLogout;

  const _Sidebar({
    required this.tabs, required this.selected, required this.onSelect,
    required this.pendingCount, required this.isDark,
    required this.onToggleTheme, required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    final tok = _Tok(isDark);
    return Container(
      width: 68,
      decoration: BoxDecoration(
        color: tok.surface,
        border: Border(right: BorderSide(color: tok.border)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 14),
          Container(
            width: 40, height: 40,
            margin: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_Tok.green, _Tok.accent],
                begin: Alignment.topLeft, end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [BoxShadow(color: _Tok.green.withOpacity(0.40), blurRadius: 12, offset: const Offset(0, 4))],
            ),
            child: const Center(child: Text('M', style: TextStyle(
              fontSize: 18, fontWeight: FontWeight.w700, color: Colors.white,
            ))),
          ),
          Container(height: 1, width: 28, color: tok.border, margin: const EdgeInsets.symmetric(vertical: 6)),
          ...List.generate(tabs.length, (i) => _SidebarItem(
            icon: tabs[i].icon, label: tabs[i].label,
            isSelected: selected == i,
            badge: (i == 1 && pendingCount > 0) ? pendingCount : null,
            isDark: isDark, onTap: () => onSelect(i),
          )),
          const Spacer(),
          Container(height: 1, width: 28, color: tok.border, margin: const EdgeInsets.symmetric(vertical: 6)),
          _SidebarItem(
            icon: isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
            label: isDark ? 'Mode clair' : 'Mode sombre',
            isSelected: false, isDark: isDark, onTap: onToggleTheme,
          ),
          _SidebarItem(
            icon: Icons.logout_rounded, label: 'Déconnexion',
            isSelected: false, isDark: isDark, onTap: onLogout, danger: true,
          ),
          const SizedBox(height: 14),
        ],
      ),
    );
  }
}

class _SidebarItem extends StatefulWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int? badge;
  final bool isDark;
  final bool danger;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.icon, required this.label, required this.isSelected,
    required this.isDark, required this.onTap, this.badge, this.danger = false,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final tok = _Tok(widget.isDark);
    final iconColor = widget.danger
        ? _Tok.red.withOpacity(_hovered ? 0.9 : 0.55)
        : widget.isSelected ? _Tok.accent : tok.textDim;

    return Tooltip(
      message: widget.label,
      preferBelow: false,
      decoration: BoxDecoration(color: tok.surface2, borderRadius: BorderRadius.circular(8)),
      textStyle: TextStyle(color: tok.textSec, fontSize: 11),
      child: GestureDetector(
        onTap: widget.onTap,
        child: MouseRegion(
          onEnter: (_) => setState(() => _hovered = true),
          onExit:  (_) => setState(() => _hovered = false),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 44, height: 44,
            margin: const EdgeInsets.symmetric(vertical: 3),
            decoration: BoxDecoration(
              color: widget.isSelected
                  ? _Tok.green.withOpacity(0.18)
                  : _hovered
                    ? (widget.danger ? _Tok.red.withOpacity(0.08) : tok.border)
                    : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: widget.isSelected ? Border.all(color: _Tok.accent.withOpacity(0.22)) : null,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Center(child: Icon(widget.icon, size: 20, color: iconColor)),
                if (widget.badge != null)
                  Positioned(
                    top: 8, right: 8,
                    child: Container(
                      width: 8, height: 8,
                      decoration: BoxDecoration(
                        color: _Tok.amber, shape: BoxShape.circle,
                        border: Border.all(color: tok.surface, width: 1.5),
                      ),
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

// ═══════════════════════════════════════════════════════════════════════════
// TOP BAR — overflow corrigé avec Flexible + pill conditionnelle
// ═══════════════════════════════════════════════════════════════════════════

class _TopBar extends StatelessWidget {
  final String tabLabel;
  final VoidCallback onRefresh;
  final bool isDark;

  const _TopBar({required this.tabLabel, required this.onRefresh, required this.isDark});

  String get _date {
    final n = DateTime.now();
    const days   = ['Lun','Mar','Mer','Jeu','Ven','Sam','Dim'];
    const months = ['jan','fév','mar','avr','mai','jun','jul','aoû','sep','oct','nov','déc'];
    return '${days[n.weekday - 1]} ${n.day} ${months[n.month - 1]}';
  }

  @override
  Widget build(BuildContext context) {
    final tok = _Tok(isDark);
    // Largeur disponible = écran - sidebar (68px) - padding (16*2)
    final availW = MediaQuery.of(context).size.width - 68;
    final showPill = availW > 340;

    return Container(
      height: 60,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: tok.surface,
        border: Border(bottom: BorderSide(color: tok.border)),
      ),
      child: Row(
        children: [
          // Breadcrumb — Flexible pour éviter l'overflow
          Flexible(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tabLabel,
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tok.textPri, letterSpacing: -0.2),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  _date,
                  style: TextStyle(fontSize: 9.5, color: tok.textDim, fontWeight: FontWeight.w300, letterSpacing: 0.3),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Pill — masquée si pas assez de place
          if (showPill) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: _Tok.accent.withOpacity(0.07),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _Tok.accent.withOpacity(0.14)),
              ),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Container(width: 5, height: 5, decoration: const BoxDecoration(color: _Tok.accent, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                const Text('Actif', style: TextStyle(fontSize: 9.5, color: _Tok.accent, fontWeight: FontWeight.w400)),
              ]),
            ),
            const SizedBox(width: 8),
          ],

          // Refresh
          GestureDetector(
            onTap: onRefresh,
            child: Container(
              width: 32, height: 32,
              decoration: BoxDecoration(color: tok.border, borderRadius: BorderRadius.circular(9)),
              child: Icon(Icons.refresh_rounded, color: tok.textSec, size: 15),
            ),
          ),

          const SizedBox(width: 8),

          // Avatar
          Container(
            width: 32, height: 32,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_Tok.green, _Tok.accent]),
              shape: BoxShape.circle,
              border: Border.all(color: _Tok.green.withOpacity(0.5)),
            ),
            child: const Center(child: Text('A', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB 0 — STATISTICS
// ═══════════════════════════════════════════════════════════════════════════

class _StatsTab extends StatelessWidget {
  final Map<String, dynamic> stats;
  final List<dynamic> activities;
  final AnimationController waveCtrl;
  final AnimationController grainCtrl;
  final _Tok tok;

  const _StatsTab({
    required this.stats, required this.activities,
    required this.waveCtrl, required this.grainCtrl, required this.tok,
  });

  @override
  Widget build(BuildContext context) {
    final vets  = stats['veterinarians']  as Map<String, dynamic>? ?? {};
    final auths = stats['authorizations'] as Map<String, dynamic>? ?? {};

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        _AdminHero(waveCtrl: waveCtrl, grainCtrl: grainCtrl, tok: tok, stats: stats),
        const SizedBox(height: 24),

        _SectionLabel(label: 'Vétérinaires', tok: tok),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatCard(value: '${vets['pending']  ?? 0}', label: 'En attente', icon: Icons.hourglass_top_rounded,   color: _Tok.amber,  tok: tok)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(value: '${vets['verified'] ?? 0}', label: 'Vérifiés',   icon: Icons.verified_rounded,         color: _Tok.accent, tok: tok)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(value: '${vets['rejected'] ?? 0}', label: 'Rejetés',    icon: Icons.cancel_rounded,           color: _Tok.red,    tok: tok)),
        ]),
        const SizedBox(height: 24),

        _SectionLabel(label: 'Autorisations', tok: tok),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: _StatCard(value: '${auths['pending'] ?? 0}', label: 'En attente', icon: Icons.pending_actions_rounded,  color: _Tok.amber, tok: tok)),
          const SizedBox(width: 10),
          Expanded(child: _StatCard(value: '${auths['active']  ?? 0}', label: 'Actives',    icon: Icons.shield_rounded,           color: _Tok.blue,  tok: tok)),
          const SizedBox(width: 10),
          const Expanded(child: SizedBox()),
        ]),
        const SizedBox(height: 24),

        _SectionLabel(label: 'Activité récente', tok: tok),
        const SizedBox(height: 12),
        _ActivityCard(activities: activities, tok: tok),
        const SizedBox(height: 20),
      ],
    );
  }
}

// ─── Hero ──────────────────────────────────────────────────────────────────

class _AdminHero extends StatelessWidget {
  final AnimationController waveCtrl;
  final AnimationController grainCtrl;
  final _Tok tok;
  final Map<String, dynamic> stats;

  const _AdminHero({required this.waveCtrl, required this.grainCtrl, required this.tok, required this.stats});

  @override
  Widget build(BuildContext context) {
    final vets  = stats['veterinarians']  as Map<String, dynamic>? ?? {};
    final auths = stats['authorizations'] as Map<String, dynamic>? ?? {};

    return Container(
      height: 156,
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft, end: Alignment.bottomRight,
          colors: tok.dark
              ? [const Color(0xFF0E2210), const Color(0xFF071008)]
              : [const Color(0xFF1B5E20), const Color(0xFF2E7D32)],
        ),
      ),
      child: Stack(
        children: [
          Positioned.fill(child: AnimatedBuilder(
            animation: grainCtrl,
            builder: (_, __) => CustomPaint(painter: _GrainPainter(seed: grainCtrl.value, color: _Tok.accent)),
          )),
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [_Tok.accent.withOpacity(0.16), Colors.transparent]),
              ),
            ),
          ),
          Positioned(
            bottom: 0, left: 0, right: 0,
            child: AnimatedBuilder(
              animation: waveCtrl,
              builder: (_, __) => SizedBox(
                height: 70,
                child: CustomPaint(
                  painter: _WavePainter(phase: waveCtrl.value * 2 * pi, color: Colors.white.withOpacity(0.06), yOffset: 0.45),
                  size: Size(MediaQuery.of(context).size.width, 70),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(5),
                    border: Border.all(color: Colors.white.withOpacity(0.18)),
                  ),
                  child: const Text('ADMIN', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, letterSpacing: 2.5, color: Colors.white)),
                ),
                const Spacer(),
                const Text('Panneau de', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w300, color: Colors.white60, letterSpacing: 0.4)),
                const Text('Gestion', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w200, color: Colors.white, letterSpacing: -2.0, height: 1.0)),
              ],
            ),
          ),
          Positioned(
            right: 22, top: 0, bottom: 0,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _MiniCircleStat(label: 'VETS', value: '${vets['verified'] ?? 0}', color: _Tok.accent),
                const SizedBox(height: 10),
                _MiniCircleStat(label: 'AUTH', value: '${auths['active'] ?? 0}', color: _Tok.blue),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniCircleStat extends StatelessWidget {
  final String label, value;
  final Color color;
  const _MiniCircleStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) => Container(
    width: 54, height: 54,
    decoration: BoxDecoration(
      shape: BoxShape.circle,
      color: Colors.white.withOpacity(0.10),
      border: Border.all(color: Colors.white.withOpacity(0.20)),
    ),
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Text(value, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Colors.white, height: 1.0)),
      const SizedBox(height: 2),
      Text(label, style: TextStyle(fontSize: 6.5, fontWeight: FontWeight.w500, letterSpacing: 1.2, color: Colors.white.withOpacity(0.60))),
    ]),
  );
}

// ─── Activity Card — données réelles API ────────────────────────────────────

class _ActivityCard extends StatelessWidget {
  final List<dynamic> activities;
  final _Tok tok;
  const _ActivityCard({required this.activities, required this.tok});

  static IconData _iconFor(String? type) {
    switch (type) {
      case 'vet_verified':   return Icons.verified_rounded;
      case 'vet_rejected':   return Icons.cancel_rounded;
      case 'vet_registered': return Icons.person_add_rounded;
      case 'auth_created':   return Icons.shield_rounded;
      case 'auth_revoked':   return Icons.block_rounded;
      default:               return Icons.info_outline_rounded;
    }
  }

  static Color _colorFor(String? type) {
    switch (type) {
      case 'vet_verified':   return _Tok.accent;
      case 'vet_rejected':   return _Tok.red;
      case 'vet_registered': return _Tok.amber;
      case 'auth_created':   return _Tok.blue;
      case 'auth_revoked':   return _Tok.red;
      default:               return _Tok.accent;
    }
  }

  String _timeAgo(String? isoDate) {
    if (isoDate == null) return '';
    try {
      final dt   = DateTime.parse(isoDate).toLocal();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 1)  return 'à l\'instant';
      if (diff.inMinutes < 60) return 'il y a ${diff.inMinutes} min';
      if (diff.inHours   < 24) return 'il y a ${diff.inHours}h';
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) { return ''; }
  }

  @override
  Widget build(BuildContext context) {
    if (activities.isEmpty) {
      return _Card(
        tok: tok,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(child: Text(
            'Aucune activité récente',
            style: TextStyle(color: tok.textDim, fontSize: 12, fontWeight: FontWeight.w300),
          )),
        ),
      );
    }

    return _Card(
      tok: tok,
      child: Column(
        children: List.generate(activities.length, (i) {
          final item    = activities[i];
          final type    = item['type']        as String?;
          // Supporte "description" ou "message" selon l'endpoint
          final message = item['description'] as String? ?? item['message'] as String? ?? '—';
          final dateStr = item['created_at']  as String?;
          final isLast  = i == activities.length - 1;
          final color   = _colorFor(type);

          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
            decoration: BoxDecoration(
              border: isLast ? null : Border(bottom: BorderSide(color: tok.border)),
            ),
            child: Row(
              children: [
                Container(
                  width: 30, height: 30,
                  decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(8)),
                  child: Icon(_iconFor(type), color: color, size: 14),
                ),
                const SizedBox(width: 13),
                Expanded(child: Text(message, style: TextStyle(
                  fontSize: 11.5, color: tok.textSec, fontWeight: FontWeight.w300, height: 1.4,
                ))),
                const SizedBox(width: 10),
                Text(_timeAgo(dateStr), style: TextStyle(
                  fontSize: 9.5, color: tok.textDim, fontWeight: FontWeight.w300,
                )),
              ],
            ),
          );
        }),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB 1 — PENDING VETS
// ═══════════════════════════════════════════════════════════════════════════

class _PendingVetsTab extends StatelessWidget {
  final List<dynamic> vets;
  final ValueChanged<int> onVerify;
  final ValueChanged<int> onReject;
  final _Tok tok;
  const _PendingVetsTab({required this.vets, required this.onVerify, required this.onReject, required this.tok});

  @override
  Widget build(BuildContext context) {
    if (vets.isEmpty) return _EmptyState(icon: Icons.hourglass_empty_rounded, message: 'Aucune demande en attente', tok: tok);
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: vets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _VetPendingCard(vet: vets[i], onVerify: onVerify, onReject: onReject, tok: tok),
    );
  }
}

class _VetPendingCard extends StatelessWidget {
  final dynamic vet;
  final ValueChanged<int> onVerify;
  final ValueChanged<int> onReject;
  final _Tok tok;
  const _VetPendingCard({required this.vet, required this.onVerify, required this.onReject, required this.tok});

  @override
  Widget build(BuildContext context) {
    final name   = vet['name']             ?? '?';
    final email  = vet['email']            ?? '';
    final spec   = vet['specialty']        ?? '-';
    final zone   = vet['zone']             ?? '-';
    final years  = vet['experience_years'] ?? 0;
    final certFn = vet['certificate_filename'];
    final certUrl = vet['certificate_url'];
    final userId = vet['user_id'] as int;
    final id     = vet['id'] as int;

    return _Card(
      tok: tok,
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 16, 18, 13),
            child: Row(
              children: [
                Container(
                  width: 42, height: 42,
                  decoration: BoxDecoration(
                    color: _Tok.green.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: _Tok.green.withOpacity(0.20)),
                  ),
                  child: Center(child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'V',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: _Tok.accent),
                  )),
                ),
                const SizedBox(width: 13),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(name, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: tok.textPri)),
                  const SizedBox(height: 2),
                  Text(email, style: TextStyle(fontSize: 10.5, color: tok.textDim, fontWeight: FontWeight.w300), overflow: TextOverflow.ellipsis),
                ])),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _Tok.amber.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: _Tok.amber.withOpacity(0.20)),
                  ),
                  child: const Text('EN ATTENTE', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, letterSpacing: 1.5, color: _Tok.amber)),
                ),
              ],
            ),
          ),
          Divider(color: tok.border, height: 1),
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 12, 18, 12),
            child: Wrap(spacing: 8, runSpacing: 6, children: [
              _InfoChip(icon: Icons.medical_services_outlined, label: spec, tok: tok),
              _InfoChip(icon: Icons.location_on_outlined,      label: zone, tok: tok),
              _InfoChip(icon: Icons.work_outline_rounded,      label: '$years ans', tok: tok),
              // Affiche toujours le badge certificat, mais différemment selon s'il existe ou pas
              GestureDetector(
                onTap: certFn != null || certUrl != null 
                  ? () => _showCertificate(context, name, userId, certUrl, certFn)
                  : null,
                child: _InfoChip(
                  icon: certFn != null || certUrl != null 
                    ? Icons.description_outlined 
                    : Icons.block_outlined,
                  label: certFn != null || certUrl != null ? 'Certificat ✓' : 'Pas de certificat',
                  tok: tok,
                  accent: certFn != null || certUrl != null ? true : false,
                ),
              ),
            ]),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            child: Row(children: [
              Expanded(child: _ActionButton(label: 'Vérifier', icon: Icons.check_circle_outline_rounded, color: _Tok.accent, onTap: () => onVerify(id), tok: tok)),
              const SizedBox(width: 10),
              Expanded(child: _ActionButton(label: 'Rejeter',  icon: Icons.cancel_outlined,              color: _Tok.red,    onTap: () => onReject(id), tok: tok, filled: false)),
            ]),
          ),
        ],
      ),
    );
  }

  void _showCertificate(BuildContext context, String vetName, int userId, String? certUrl, String? certFn) {
    final hasCert = certUrl != null && certUrl.isNotEmpty;
    final viewUrl = '${ApiService.baseUrl}/veterinarians/view-certificate/$userId';
    final downloadUrl = '${ApiService.baseUrl}/veterinarians/download-certificate/$userId';
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: tok.surface,
        title: Text('Certificat de $vetName', style: TextStyle(color: tok.textPri, fontSize: 16, fontWeight: FontWeight.w500)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (hasCert) ...[
                Text(
                  'Détails du fichier',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: tok.textPri),
                ),
                const SizedBox(height: 8),
                Text(
                  'Nom: ${certFn ?? certUrl ?? "Non disponible"}',
                  style: TextStyle(fontSize: 12, color: tok.textSec),
                ),
                const SizedBox(height: 16),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: _Tok.amber.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _Tok.amber.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_rounded, color: _Tok.amber, size: 24),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '⚠️ Aucun certificat uploadé',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: _Tok.amber),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Ce vétérinaire n\'a pas fourni de certificat ou diplôme.',
                              style: TextStyle(fontSize: 11, color: tok.textDim),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
              
              // Preview section
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: tok.surface2,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: tok.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Icon(
                      hasCert ? _getIconForCert(certUrl) : Icons.block_outlined,
                      color: hasCert ? _Tok.blue : tok.textDim,
                      size: 48,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      hasCert ? 'Document en attente de vérification' : 'Aucun document fourni',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: tok.textPri),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    if (hasCert)
                      Text(
                        certFn ?? 'Certificat/Diplôme',
                        style: TextStyle(fontSize: 11, color: tok.textDim),
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              
              if (hasCert) ...[
                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: _Tok.blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: _Tok.blue.withOpacity(0.2)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.open_in_new_rounded, color: _Tok.blue, size: 20),
                            const SizedBox(height: 4),
                            Text(
                              'Ouvrir',
                              style: TextStyle(fontSize: 11, color: _Tok.blue, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          Clipboard.setData(ClipboardData(text: downloadUrl));
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Lien de téléchargement copié'),
                              duration: Duration(seconds: 2),
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _Tok.amber.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: _Tok.amber.withOpacity(0.2)),
                          ),
                          child: Column(
                            children: [
                              Icon(Icons.download_rounded, color: _Tok.amber, size: 20),
                              const SizedBox(height: 4),
                              Text(
                                'Copier lien',
                                style: TextStyle(fontSize: 11, color: _Tok.amber, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
              ],
              
              Text(
                hasCert
                  ? '💡 Conseil: Vérifiez attentivement les informations du certificat avant d\'approuver ce vétérinaire. Les diplômes doivent être valides et à jour.'
                  : '⚠️ Conseil: Vous devez demander au vétérinaire d\'uploader son certificat ou diplôme avant de valider son profil.',
                style: TextStyle(fontSize: 11, color: tok.textDim, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Fermer', style: TextStyle(color: tok.textPri)),
          ),
        ],
      ),
    );
  }
  
  IconData _getIconForCert(String? certUrl) {
    if (certUrl == null) return Icons.description_rounded;
    final ext = certUrl.toLowerCase().split('.').last;
    switch (ext) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'jpg':
      case 'jpeg':
      case 'png':
      case 'gif':
        return Icons.image_rounded;
      case 'doc':
      case 'docx':
        return Icons.article_rounded;
      default:
        return Icons.file_present_rounded;
    }
  }
}


// ═══════════════════════════════════════════════════════════════════════════
// TAB 2 — VERIFIED VETS
// ═══════════════════════════════════════════════════════════════════════════

class _VerifiedVetsTab extends StatelessWidget {
  final List<dynamic> vets;
  final _Tok tok;
  const _VerifiedVetsTab({required this.vets, required this.tok});

  @override
  Widget build(BuildContext context) {
    if (vets.isEmpty) return _EmptyState(icon: Icons.verified_rounded, message: 'Aucun vétérinaire vérifié', tok: tok);
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: vets.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final vet        = vets[i];
        final name       = vet['name']                ?? '?';
        final email      = vet['email']               ?? '';
        final spec       = vet['specialty']           ?? '-';
        final zone       = vet['zone']                ?? '-';
        final consults   = vet['total_consultations'] ?? 0;
        final rating     = (vet['average_rating']     ?? 0.0).toDouble();
        final verifiedAt = vet['verified_at'] != null
            ? DateFormat('dd/MM/yyyy').format(DateTime.parse(vet['verified_at']))
            : null;

        return _Card(
          tok: tok,
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Container(
                  width: 46, height: 46,
                  decoration: BoxDecoration(
                    color: _Tok.green.withOpacity(0.14),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(color: _Tok.green.withOpacity(0.25)),
                  ),
                  child: Center(child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : 'V',
                    style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w300, color: _Tok.accent),
                  )),
                ),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Flexible(child: Text(name, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: tok.textPri), overflow: TextOverflow.ellipsis)),
                    const SizedBox(width: 6),
                    const Icon(Icons.verified_rounded, color: _Tok.accent, size: 13),
                  ]),
                  const SizedBox(height: 3),
                  Text('$spec · $zone', style: TextStyle(fontSize: 10.5, color: tok.textDim, fontWeight: FontWeight.w300)),
                  if (verifiedAt != null)
                    Text('Vérifié le $verifiedAt', style: TextStyle(fontSize: 9.5, color: tok.textDim, fontWeight: FontWeight.w300)),
                ])),
                const SizedBox(width: 14),
                _VerticalStat(value: '$consults', label: 'Consult.', color: _Tok.blue),
                const SizedBox(width: 14),
                _VerticalStat(value: '${rating.toStringAsFixed(1)} ★', label: 'Note', color: _Tok.amber),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _VerticalStat extends StatelessWidget {
  final String value, label;
  final Color color;
  const _VerticalStat({required this.value, required this.label, required this.color});

  @override
  Widget build(BuildContext context) => Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
    Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: color, letterSpacing: -0.5)),
    const SizedBox(height: 2),
    Text(label, style: TextStyle(fontSize: 9, color: color.withOpacity(0.70), letterSpacing: 0.3)),
  ]);
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB 3 — PENDING AUTHS
// ═══════════════════════════════════════════════════════════════════════════

class _PendingAuthsTab extends StatelessWidget {
  final List<dynamic> auths;
  final _Tok tok;
  const _PendingAuthsTab({required this.auths, required this.tok});

  @override
  Widget build(BuildContext context) {
    if (auths.isEmpty) return _EmptyState(icon: Icons.inbox_rounded, message: 'Aucune demande d\'autorisation', tok: tok);
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: auths.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _AuthCard(auth: auths[i], isActive: false, tok: tok),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// TAB 4 — ACTIVE AUTHS
// ═══════════════════════════════════════════════════════════════════════════

class _ActiveAuthsTab extends StatelessWidget {
  final List<dynamic> auths;
  final ValueChanged<int> onRevoke;
  final _Tok tok;
  const _ActiveAuthsTab({required this.auths, required this.onRevoke, required this.tok});

  @override
  Widget build(BuildContext context) {
    if (auths.isEmpty) return _EmptyState(icon: Icons.shield_rounded, message: 'Aucune autorisation active', tok: tok);
    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: auths.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) => _AuthCard(
        auth: auths[i], isActive: true, tok: tok,
        onRevoke: () => onRevoke(auths[i]['id'] as int),
      ),
    );
  }
}

class _AuthCard extends StatelessWidget {
  final dynamic auth;
  final bool isActive;
  final _Tok tok;
  final VoidCallback? onRevoke;
  const _AuthCard({required this.auth, required this.isActive, required this.tok, this.onRevoke});

  @override
  Widget build(BuildContext context) {
    final farmerName = auth['farmer_name']        ?? '?';
    final vetName    = auth['veterinarian_name']  ?? '?';
    final farmName   = auth['farm_name']          ?? '?';
    final vetEmail   = auth['veterinarian_email'] ?? '';
    final canView    = auth['can_view_data']   == true;
    final canAdvise  = auth['can_give_advice'] == true;
    final canVisit   = auth['can_visit']       == true;
    final reason     = auth['authorization_reason'] as String?;
    final color      = isActive ? _Tok.blue : _Tok.amber;

    return _Card(
      tok: tok,
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(9)),
              child: Icon(isActive ? Icons.shield_rounded : Icons.pending_actions_rounded, color: color, size: 15),
            ),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Flexible(child: Text(farmerName, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: tok.textPri), overflow: TextOverflow.ellipsis)),
                Icon(Icons.arrow_forward_rounded, size: 11, color: tok.textDim),
                Flexible(child: Text(vetName, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w400, color: tok.textPri), overflow: TextOverflow.ellipsis)),
              ]),
              const SizedBox(height: 2),
              Text('Ferme: $farmName · $vetEmail', style: TextStyle(fontSize: 10, color: tok.textDim, fontWeight: FontWeight.w300), overflow: TextOverflow.ellipsis),
            ])),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: color.withOpacity(0.20)),
              ),
              child: Text(isActive ? 'ACTIVE' : 'EN ATT.', style: TextStyle(fontSize: 7.5, fontWeight: FontWeight.w600, letterSpacing: 1.2, color: color)),
            ),
          ]),
          const SizedBox(height: 13),
          Divider(color: tok.border, height: 1),
          const SizedBox(height: 13),
          Row(children: [
            if (canView)   _PermChip(label: 'Données',  icon: Icons.bar_chart_rounded, tok: tok),
            if (canAdvise) ...[const SizedBox(width: 6), _PermChip(label: 'Conseils', icon: Icons.lightbulb_outline_rounded, tok: tok)],
            if (canVisit)  ...[const SizedBox(width: 6), _PermChip(label: 'Visite',   icon: Icons.home_outlined, tok: tok)],
            const Spacer(),
            if (isActive && onRevoke != null)
              _ActionButton(label: 'Révoquer', icon: Icons.block_rounded, color: _Tok.red, onTap: onRevoke!, tok: tok, filled: false, compact: true),
          ]),
          if (reason != null && reason.isNotEmpty) ...[
            const SizedBox(height: 9),
            Text('Raison: $reason', style: TextStyle(fontSize: 10.5, color: tok.textDim, fontWeight: FontWeight.w300, fontStyle: FontStyle.italic)),
          ],
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _Card extends StatelessWidget {
  final Widget child;
  final _Tok tok;
  const _Card({required this.child, required this.tok});

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: tok.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: tok.border),
      boxShadow: [BoxShadow(
        color: Colors.black.withOpacity(tok.dark ? 0.28 : 0.06),
        blurRadius: 18, offset: const Offset(0, 5), spreadRadius: -4,
      )],
    ),
    child: child,
  );
}

class _SectionLabel extends StatelessWidget {
  final String label;
  final _Tok tok;
  const _SectionLabel({required this.label, required this.tok});

  @override
  Widget build(BuildContext context) => Row(children: [
    Container(width: 16, height: 1, color: _Tok.green),
    const SizedBox(width: 8),
    Text(label.toUpperCase(), style: TextStyle(fontSize: 8, fontWeight: FontWeight.w500, letterSpacing: 2.5, color: tok.textDim)),
    const SizedBox(width: 8),
    Expanded(child: Container(height: 1, color: tok.border)),
  ]);
}

class _StatCard extends StatelessWidget {
  final String value, label;
  final IconData icon;
  final Color color;
  final _Tok tok;
  const _StatCard({required this.value, required this.label, required this.icon, required this.color, required this.tok});

  @override
  Widget build(BuildContext context) => _Card(
    tok: tok,
    child: Padding(
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
          width: 32, height: 32,
          decoration: BoxDecoration(color: color.withOpacity(0.10), borderRadius: BorderRadius.circular(9)),
          child: Icon(icon, color: color, size: 15),
        ),
        const SizedBox(height: 14),
        Text(value, style: TextStyle(fontSize: 38, fontWeight: FontWeight.w200, color: color, letterSpacing: -2.5, height: 1.0)),
        const SizedBox(height: 5),
        Text(label.toUpperCase(), style: TextStyle(fontSize: 8.5, fontWeight: FontWeight.w400, letterSpacing: 1.6, color: tok.textDim)),
      ]),
    ),
  );
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final _Tok tok;
  final bool accent;
  const _InfoChip({required this.icon, required this.label, required this.tok, this.accent = false});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: accent ? _Tok.accent.withOpacity(0.08) : tok.border,
      borderRadius: BorderRadius.circular(7),
      border: accent ? Border.all(color: _Tok.accent.withOpacity(0.18)) : null,
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: accent ? _Tok.accent : tok.textDim),
      const SizedBox(width: 5),
      Text(label, style: TextStyle(fontSize: 10, color: accent ? _Tok.accent : tok.textSec, fontWeight: FontWeight.w300)),
    ]),
  );
}

class _PermChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final _Tok tok;
  const _PermChip({required this.label, required this.icon, required this.tok});

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: _Tok.green.withOpacity(0.08),
      borderRadius: BorderRadius.circular(6),
      border: Border.all(color: _Tok.green.withOpacity(0.14)),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 10, color: _Tok.accent),
      const SizedBox(width: 5),
      Text(label, style: const TextStyle(fontSize: 10, color: _Tok.accent, fontWeight: FontWeight.w300)),
    ]),
  );
}

class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool filled;
  final bool compact;
  final _Tok tok;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label, required this.icon, required this.color,
    required this.onTap, required this.tok,
    this.filled = true, this.compact = false,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 12 : 14, vertical: compact ? 8 : 12),
      decoration: BoxDecoration(
        color: filled ? color : color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
        border: filled ? null : Border.all(color: color.withOpacity(0.22)),
        boxShadow: filled ? [BoxShadow(color: color.withOpacity(0.22), blurRadius: 8, offset: const Offset(0, 3))] : null,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        children: [
          Icon(icon, size: 13, color: filled ? tok.bg : color),
          const SizedBox(width: 6),
          Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w500, color: filled ? tok.bg : color)),
        ],
      ),
    ),
  );
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final _Tok tok;
  const _EmptyState({required this.icon, required this.message, required this.tok});

  @override
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 60, height: 60,
        decoration: BoxDecoration(
          color: _Tok.green.withOpacity(0.08), shape: BoxShape.circle,
          border: Border.all(color: _Tok.green.withOpacity(0.14)),
        ),
        child: Icon(icon, size: 26, color: tok.textDim),
      ),
      const SizedBox(height: 14),
      Text(message, style: TextStyle(fontSize: 12.5, color: tok.textDim, fontWeight: FontWeight.w300)),
    ]),
  );
}

class _LoadingShimmer extends StatefulWidget {
  final _Tok tok;
  const _LoadingShimmer({required this.tok});
  @override
  State<_LoadingShimmer> createState() => _LoadingShimmerState();
}
class _LoadingShimmerState extends State<_LoadingShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _c;
  @override void initState() { super.initState(); _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 1400))..repeat(); }
  @override void dispose() { _c.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final tok = widget.tok;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: List.generate(4, (i) => AnimatedBuilder(
        animation: _c,
        builder: (_, __) => Container(
          height: i == 0 ? 156 : 76,
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment(-2 + 4 * _c.value, 0),
              end: Alignment(-2 + 4 * _c.value + 2, 0),
              colors: tok.dark
                  ? [const Color(0xFF0D1A0B), const Color(0xFF152B14), const Color(0xFF0D1A0B)]
                  : [const Color(0xFFE8EEE8), const Color(0xFFF2F5F2), const Color(0xFFE8EEE8)],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
        ),
      )),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  final _Tok tok;
  const _ErrorView({required this.error, required this.onRetry, required this.tok});

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(24),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(color: _Tok.red.withOpacity(0.08), shape: BoxShape.circle),
          child: const Icon(Icons.error_outline_rounded, color: _Tok.red, size: 26),
        ),
        const SizedBox(height: 14),
        Text(error, style: TextStyle(color: tok.textDim, fontSize: 11.5), textAlign: TextAlign.center),
        const SizedBox(height: 18),
        GestureDetector(
          onTap: onRetry,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: _Tok.green.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _Tok.green.withOpacity(0.20)),
            ),
            child: const Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(Icons.refresh_rounded, color: _Tok.accent, size: 13),
              SizedBox(width: 6),
              Text('Réessayer', style: TextStyle(color: _Tok.accent, fontSize: 11.5)),
            ]),
          ),
        ),
      ]),
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// REJECT DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class _RejectDialog extends StatefulWidget {
  final bool isDark;
  const _RejectDialog({required this.isDark});
  @override
  State<_RejectDialog> createState() => _RejectDialogState();
}
class _RejectDialogState extends State<_RejectDialog> {
  final _ctrl = TextEditingController();
  @override void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final tok = _Tok(widget.isDark);
    return Dialog(
      backgroundColor: tok.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: _Tok.red.withOpacity(0.10), borderRadius: BorderRadius.circular(9)),
              child: const Icon(Icons.cancel_outlined, color: _Tok.red, size: 17),
            ),
            const SizedBox(width: 12),
            Flexible(child: Text('Rejeter ce vétérinaire', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w400, color: tok.textPri))),
          ]),
          const SizedBox(height: 18),
          TextField(
            controller: _ctrl,
            maxLines: 3,
            style: TextStyle(color: tok.textPri, fontSize: 12.5, fontWeight: FontWeight.w300),
            decoration: InputDecoration(
              hintText: 'Raison du rejet (optionnel)…',
              hintStyle: TextStyle(color: tok.textDim, fontSize: 12.5),
              filled: true, fillColor: tok.bg,
              border:        OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tok.border)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: tok.border)),
              focusedBorder: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)), borderSide: BorderSide(color: _Tok.green)),
            ),
          ),
          const SizedBox(height: 18),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 42,
                decoration: BoxDecoration(color: tok.border, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('Annuler', style: TextStyle(color: tok.textSec, fontSize: 12.5))),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context, _ctrl.text),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: _Tok.red, borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: _Tok.red.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Center(child: Text('Rejeter', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500))),
              ),
            )),
          ]),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LOGOUT DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class _LogoutDialog extends StatelessWidget {
  final bool isDark;
  const _LogoutDialog({required this.isDark});

  @override
  Widget build(BuildContext context) {
    final tok = _Tok(isDark);
    return Dialog(
      backgroundColor: tok.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _Tok.red.withOpacity(0.10), shape: BoxShape.circle,
              border: Border.all(color: _Tok.red.withOpacity(0.20)),
            ),
            child: const Icon(Icons.logout_rounded, color: _Tok.red, size: 22),
          ),
          const SizedBox(height: 16),
          Text('Déconnexion', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: tok.textPri)),
          const SizedBox(height: 8),
          Text(
            'Voulez-vous vraiment vous déconnecter du panneau admin ?',
            style: TextStyle(fontSize: 12, color: tok.textSec, fontWeight: FontWeight.w300, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 22),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context, false),
              child: Container(
                height: 42,
                decoration: BoxDecoration(color: tok.border, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('Annuler', style: TextStyle(color: tok.textSec, fontSize: 12.5))),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context, true),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: _Tok.red, borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: _Tok.red.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(Icons.logout_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 6),
                  Text('Se déconnecter', style: TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w500)),
                ]),
              ),
            )),
          ]),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// USERS TAB
// ═══════════════════════════════════════════════════════════════════════════

class _UsersTab extends StatelessWidget {
  final List<dynamic> users;
  final VoidCallback onCreateUser;
  final Function(int) onDeleteUser;
  final Function(int, String) onUpdateRole;
  final _Tok tok;

  const _UsersTab({
    required this.users,
    required this.onCreateUser,
    required this.onDeleteUser,
    required this.onUpdateRole,
    required this.tok,
  });

  @override
  Widget build(BuildContext context) {
    return _Card(
      tok: tok,
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestion des utilisateurs',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tok.textPri),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${users.length} utilisateur${users.length != 1 ? 's' : ''}',
                      style: TextStyle(fontSize: 12, color: tok.textDim),
                    ),
                  ],
                ),
                GestureDetector(
                  onTap: onCreateUser,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: _Tok.green, borderRadius: BorderRadius.circular(8),
                      boxShadow: [BoxShadow(color: _Tok.green.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3))],
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.person_add_rounded, color: Colors.white, size: 16),
                      SizedBox(width: 6),
                      Text('Ajouter', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
                    ]),
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: tok.border),
          
          // Users List
          if (users.isEmpty)
            Padding(
              padding: const EdgeInsets.all(32),
              child: Center(child: Text(
                'Aucun utilisateur',
                style: TextStyle(color: tok.textDim, fontSize: 13, fontWeight: FontWeight.w300),
              )),
            )
          else
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: List.generate(users.length, (i) {
                    final user = users[i];
                    final isLast = i == users.length - 1;
                    return Column(
                      children: [
                        _UserRow(
                          user: user,
                          tok: tok,
                          onDelete: () => onDeleteUser(user['id'] as int),
                          onUpdateRole: () => onUpdateRole(user['id'] as int, user['role'] as String),
                        ),
                        if (!isLast) Container(height: 1, color: tok.border),
                      ],
                    );
                  }),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _UserRow extends StatefulWidget {
  final Map<String, dynamic> user;
  final _Tok tok;
  final VoidCallback onDelete;
  final VoidCallback onUpdateRole;

  const _UserRow({
    required this.user,
    required this.tok,
    required this.onDelete,
    required this.onUpdateRole,
  });

  @override
  State<_UserRow> createState() => _UserRowState();
}

class _UserRowState extends State<_UserRow> {
  bool _hovered = false;

  @override
  Widget build(BuildContext context) {
    final user = widget.user;
    final role = user['role'] as String? ?? 'user';
    final name = user['name'] as String? ?? '?';
    final email = user['email'] as String? ?? '?';

    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        color: _hovered ? widget.tok.border.withOpacity(0.5) : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _getRoleColor(role).withOpacity(0.15),
                border: Border.all(color: _getRoleColor(role).withOpacity(0.30)),
              ),
              child: Center(
                child: Text(
                  name.substring(0, 1).toUpperCase(),
                  style: TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w600,
                    color: _getRoleColor(role),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: widget.tok.textPri),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    email,
                    style: TextStyle(fontSize: 12, color: widget.tok.textDim),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            
            // Role Badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _getRoleColor(role).withOpacity(0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: _getRoleColor(role).withOpacity(0.24)),
              ),
              child: Text(
                _getRoleLabel(role),
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: _getRoleColor(role)),
              ),
            ),
            const SizedBox(width: 12),
            
            // Actions
            if (_hovered) ...[
              GestureDetector(
                onTap: widget.onUpdateRole,
                child: Tooltip(
                  message: 'Modifier le rôle',
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(color: widget.tok.border, borderRadius: BorderRadius.circular(8)),
                    child: Icon(Icons.edit_rounded, color: widget.tok.textSec, size: 16),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: widget.onDelete,
                child: Tooltip(
                  message: 'Supprimer',
                  child: Container(
                    width: 36, height: 36,
                    decoration: BoxDecoration(
                      color: _Tok.red.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: _Tok.red.withOpacity(0.24)),
                    ),
                    child: const Icon(Icons.delete_rounded, color: _Tok.red, size: 16),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return _Tok.red;
      case 'veterinarian': return _Tok.blue;
      case 'farmer': return _Tok.green;
      default: return _Tok.accent;
    }
  }

  String _getRoleLabel(String role) {
    switch (role.toLowerCase()) {
      case 'admin': return 'Admin';
      case 'veterinarian': return 'Vétérinaire';
      case 'farmer': return 'Agriculteur';
      default: return role;
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CREATE USER DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class _CreateUserDialog extends StatefulWidget {
  final bool isDark;
  const _CreateUserDialog({required this.isDark});

  @override
  State<_CreateUserDialog> createState() => _CreateUserDialogState();
}

class _CreateUserDialogState extends State<_CreateUserDialog> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  String _selectedRole = 'user';
  bool _showPass = false;

  @override
  Widget build(BuildContext context) {
    final tok = _Tok(widget.isDark);
    return Dialog(
      backgroundColor: tok.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 52, height: 52,
              decoration: BoxDecoration(
                color: _Tok.green.withOpacity(0.10), shape: BoxShape.circle,
                border: Border.all(color: _Tok.green.withOpacity(0.20)),
              ),
              child: const Icon(Icons.person_add_rounded, color: _Tok.green, size: 24),
            ),
            const SizedBox(height: 16),
            Text('Nouvel utilisateur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tok.textPri)),
            const SizedBox(height: 20),
            
            // Name
            TextField(
              controller: _nameCtrl,
              style: TextStyle(color: tok.textPri, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Nom complet',
                hintStyle: TextStyle(color: tok.textDim),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tok.border),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Email
            TextField(
              controller: _emailCtrl,
              style: TextStyle(color: tok.textPri, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Email',
                hintStyle: TextStyle(color: tok.textDim),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tok.border),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Password
            TextField(
              controller: _passCtrl,
              obscureText: !_showPass,
              style: TextStyle(color: tok.textPri, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Mot de passe',
                hintStyle: TextStyle(color: tok.textDim),
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tok.border),
                ),
                suffixIcon: GestureDetector(
                  onTap: () => setState(() => _showPass = !_showPass),
                  child: Icon(
                    _showPass ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                    color: tok.textDim, size: 18,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            
            // Role
            DropdownButtonFormField<String>(
              value: _selectedRole,
              style: TextStyle(color: tok.textPri, fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Rôle',
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: tok.border),
                ),
              ),
              items: [
                DropdownMenuItem(value: 'user', child: Text('Utilisateur')),
                DropdownMenuItem(value: 'farmer', child: Text('Agriculteur')),
                DropdownMenuItem(value: 'veterinarian', child: Text('Vétérinaire')),
                DropdownMenuItem(value: 'admin', child: Text('Administrateur')),
              ],
              onChanged: (val) => setState(() => _selectedRole = val ?? 'user'),
            ),
            const SizedBox(height: 24),
            
            // Actions
            Row(children: [
              Expanded(child: GestureDetector(
                onTap: () => Navigator.pop(context),
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(color: tok.border, borderRadius: BorderRadius.circular(10)),
                  child: Center(child: Text('Annuler', style: TextStyle(color: tok.textSec, fontSize: 13, fontWeight: FontWeight.w500))),
                ),
              )),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: () {
                  if (_nameCtrl.text.isEmpty || _emailCtrl.text.isEmpty || _passCtrl.text.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: const Text('Remplissez tous les champs'), backgroundColor: _Tok.red),
                    );
                    return;
                  }
                  Navigator.pop(context, {
                    'name': _nameCtrl.text,
                    'email': _emailCtrl.text,
                    'password': _passCtrl.text,
                    'role': _selectedRole,
                  });
                },
                child: Container(
                  height: 42,
                  decoration: BoxDecoration(
                    color: _Tok.green, borderRadius: BorderRadius.circular(10),
                    boxShadow: [BoxShadow(color: _Tok.green.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3))],
                  ),
                  child: const Center(child: Text('Créer', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
                ),
              )),
            ]),
          ]),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ROLE DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class _RoleDialog extends StatefulWidget {
  final bool isDark;
  final String currentRole;
  const _RoleDialog({required this.isDark, required this.currentRole});

  @override
  State<_RoleDialog> createState() => _RoleDialogState();
}

class _RoleDialogState extends State<_RoleDialog> {
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.currentRole;
  }

  @override
  Widget build(BuildContext context) {
    final tok = _Tok(widget.isDark);
    const roles = ['user', 'farmer', 'veterinarian', 'admin'];
    const labels = ['Utilisateur', 'Agriculteur', 'Vétérinaire', 'Administrateur'];

    return Dialog(
      backgroundColor: tok.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: _Tok.blue.withOpacity(0.10), shape: BoxShape.circle,
              border: Border.all(color: _Tok.blue.withOpacity(0.20)),
            ),
            child: const Icon(Icons.security_rounded, color: _Tok.blue, size: 24),
          ),
          const SizedBox(height: 16),
          Text('Modifier le rôle', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tok.textPri)),
          const SizedBox(height: 20),
          
          ...List.generate(roles.length, (i) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: GestureDetector(
              onTap: () => setState(() => _selectedRole = roles[i]),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: _selectedRole == roles[i] ? _Tok.blue.withOpacity(0.08) : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _selectedRole == roles[i] ? _Tok.blue : tok.border,
                    width: _selectedRole == roles[i] ? 1.5 : 1,
                  ),
                ),
                child: Row(children: [
                  Container(
                    width: 20, height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: _selectedRole == roles[i] ? _Tok.blue : tok.textDim, width: 2),
                    ),
                    child: _selectedRole == roles[i]
                        ? Center(child: Container(width: 10, height: 10, decoration: const BoxDecoration(shape: BoxShape.circle, color: _Tok.blue)))
                        : null,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    labels[i],
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: tok.textPri),
                  ),
                ]),
              ),
            ),
          )),
          
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                height: 42,
                decoration: BoxDecoration(color: tok.border, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('Annuler', style: TextStyle(color: tok.textSec, fontSize: 13, fontWeight: FontWeight.w500))),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context, _selectedRole),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: _Tok.blue, borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: _Tok.blue.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: const Center(child: Text('Confirmer', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
              ),
            )),
          ]),
        ]),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// CONFIRM DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class _ConfirmDialog extends StatelessWidget {
  final bool isDark;
  final String title;
  final String message;
  final String confirmText;
  final bool isDestructive;

  const _ConfirmDialog({
    required this.isDark,
    required this.title,
    required this.message,
    required this.confirmText,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final tok = _Tok(isDark);
    final color = isDestructive ? _Tok.red : _Tok.accent;

    return Dialog(
      backgroundColor: tok.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10), shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.20)),
            ),
            child: Icon(isDestructive ? Icons.delete_rounded : Icons.warning_rounded, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: tok.textPri)),
          const SizedBox(height: 8),
          Text(
            message,
            style: TextStyle(fontSize: 12, color: tok.textSec, fontWeight: FontWeight.w300, height: 1.5),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          Row(children: [
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context, false),
              child: Container(
                height: 42,
                decoration: BoxDecoration(color: tok.border, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Text('Annuler', style: TextStyle(color: tok.textSec, fontSize: 13, fontWeight: FontWeight.w500))),
              ),
            )),
            const SizedBox(width: 10),
            Expanded(child: GestureDetector(
              onTap: () => Navigator.pop(context, true),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: color, borderRadius: BorderRadius.circular(10),
                  boxShadow: [BoxShadow(color: color.withOpacity(0.28), blurRadius: 8, offset: const Offset(0, 3))],
                ),
                child: Center(child: Text(confirmText, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))),
              ),
            )),
          ]),
        ]),
      ),
    );
  }
}