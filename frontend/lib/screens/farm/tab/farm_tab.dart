import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/screens/livestock/edit_livestock_screen.dart';
import 'package:mbaymi/screens/farm/edit_farm_screen.dart';
import 'package:mbaymi/screens/farm/create_farm_screen.dart';
import 'package:mbaymi/screens/livestock/create_livestock_screen.dart';
import 'package:mbaymi/screens/social/social_feed_screen.dart';
import 'package:mbaymi/screens/farm/parcel_screen.dart';
import 'package:mbaymi/screens/farm/public_farms_screen.dart';
import 'package:mbaymi/utils/app_colors.dart';

// Import des nouveaux fichiers
import 'package:mbaymi/screens/farm/tab/farm_tab_components.dart';
import 'farm_card.dart';

// ─────────────────────────────────────────────────────────────────────────────
// CACHE GLOBAL
// ─────────────────────────────────────────────────────────────────────────────
final _dataCache = <String, Future<List<dynamic>>>{};
final _cropsCache = <int, Future<List<dynamic>>>{};

// ─────────────────────────────────────────────────────────────────────────────
// WIDGET PRINCIPAL
// ─────────────────────────────────────────────────────────────────────────────
class FarmTab extends StatefulWidget {
  final int? userId;
  final int initialSection;
  const FarmTab({super.key, this.userId, this.initialSection = 0});

  @override
  State<FarmTab> createState() => _FarmTabState();
}

class _FarmTabState extends State<FarmTab> with TickerProviderStateMixin {
  int _section = 0;
  bool _headerVisible = true;
  late final AnimationController _headerController;
  late AnimationController _sectionAnim;
  late Animation<double> _sectionSlide;
  late Animation<double> _sectionFade;
  final _pageScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      value: 1,
      duration: const Duration(milliseconds: 260),
    );
    _section = widget.initialSection;
    _sectionAnim = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 280));
    _sectionFade = CurvedAnimation(parent: _sectionAnim, curve: Curves.easeOut);
    _sectionSlide = Tween<double>(begin: 0.03, end: 0).animate(
      CurvedAnimation(parent: _sectionAnim, curve: Curves.easeOut),
    );
    _sectionAnim.forward();
  }

  @override
  void dispose() {
    _headerController.dispose();
    _sectionAnim.dispose();
    _pageScrollController.dispose();
    super.dispose();
  }

  bool _handleScroll(ScrollNotification notification) {
    if (notification is UserScrollNotification) {
      if (notification.direction == ScrollDirection.reverse && _headerVisible) {
        setState(() => _headerVisible = false);
        _headerController.animateTo(0, curve: Curves.easeOutCubic);
      } else if (notification.direction == ScrollDirection.forward && !_headerVisible) {
        setState(() => _headerVisible = true);
        _headerController.animateTo(1, curve: Curves.easeOutCubic);
      }
    }
    return false;
  }

  @override
  void didUpdateWidget(FarmTab old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId) {
      _section = widget.initialSection;
      setState(() {});
    }
  }

  // ── Data ──────────────────────────────────────────────────────────────────
  Future<List<dynamic>> _farms() {
    final session = AuthService.currentSession;
    if (widget.userId != null) {
      return _dataCache.putIfAbsent(
          'farms_${widget.userId}',
          () => ApiService.getPublicUserFarms(widget.userId!));
    }
    if (session?.userId != null) {
      return _dataCache.putIfAbsent(
          'farms_user_${session!.userId}',
          () => ApiService.getPublicUserFarms(session.userId));
    }
    return Future.value([]);
  }

  Future<List<dynamic>> _livestock() {
    if (widget.userId == null) return Future.value([]);
    return _dataCache.putIfAbsent(
        'livestock_${widget.userId}',
        () => ApiService.getUserLivestock(widget.userId!));
  }

  Future<List<dynamic>> _crops(int farmId) =>
      _cropsCache.putIfAbsent(farmId, () => ApiService.getFarmCrops(farmId));

  List<dynamic> _sorted(List<dynamic> items) => List.from(items)
    ..sort((a, b) {
      try {
        return DateTime.parse(b['created_at'])
            .compareTo(DateTime.parse(a['created_at']));
      } catch (_) {
        return 0;
      }
    });

  Future<void> _refresh() async {
    final previousOffset = _pageScrollController.hasClients
        ? _pageScrollController.offset
        : 0.0;
    final cacheKey = _section == 1
        ? 'livestock_${widget.userId}'
        : 'farms_${widget.userId ?? 'user_${AuthService.currentSession?.userId}'}';
    _dataCache.remove(cacheKey);
    if (_section == 0) _cropsCache.clear();
    setState(() {});
    _sectionAnim.forward(from: 0);

    await (_section == 1 ? _livestock() : _farms());
    if (!mounted) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (!_pageScrollController.hasClients) return;
      final maxOffset = _pageScrollController.position.maxScrollExtent;
      _pageScrollController.jumpTo(previousOffset.clamp(0.0, maxOffset));
    });
  }

  void _switchSection(int s) {
    if (s == _section) return;
    HapticFeedback.selectionClick();
    _sectionAnim.forward(from: 0);
    setState(() => _section = s);
  }

  // ── Snack ─────────────────────────────────────────────────────────────────
  SnackBar _snack(String msg, {bool error = false}) => SnackBar(
        content: Text(msg,
            style: const TextStyle(fontSize: 10, letterSpacing: 1.5, color: Colors.white)),
        backgroundColor: error ? Colors.red.shade700 : Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      );

  // ── Delete dialog ─────────────────────────────────────────────────────────
  Future<void> _deleteFarm(int id, String name, bool dark) async {
    final bg = AppColors.getBgColor(dark);
    final fg = dark ? Colors.white : Colors.black87;
    final sub = (dark ? Colors.white : Colors.black).withOpacity(0.45);

    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
              color: bg,
              border: Border.all(
                  color: (dark ? Colors.white : Colors.black).withOpacity(0.1),
                  width: 0.5)),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SUPPRIMER LA FERME',
                  style: TextStyle(fontSize: 10, letterSpacing: 3, color: fg)),
              const SizedBox(height: 6),
              Divider(
                  height: 1,
                  color: (dark ? Colors.white : Colors.black).withOpacity(0.08)),
              const SizedBox(height: 20),
              Text('Supprimer "$name" ? Cette action est irréversible.',
                  style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 0.2,
                      fontWeight: FontWeight.w300,
                      color: sub)),
              const SizedBox(height: 28),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(ctx);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: (dark ? Colors.white : Colors.black)
                                  .withOpacity(0.15),
                              width: 0.5)),
                      child: Center(
                          child: Text('ANNULER',
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: sub))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () async {
                      HapticFeedback.heavyImpact();
                      Navigator.pop(ctx);
                      try {
                        await ApiService.deleteFarm(id);
                        if (mounted) {
                          ScaffoldMessenger.of(context)
                              .showSnackBar(_snack('FERME SUPPRIMÉE'));
                          _refresh();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              _snack('ERREUR: $e', error: true));
                        }
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: Colors.red.shade700,
                      child: const Center(
                          child: Text('SUPPRIMER',
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: Colors.white))),
                    ),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteLivestock(int id, String name, bool dark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Container(
          decoration: BoxDecoration(
              color: AppColors.getBgColor(dark),
              border: Border.all(
                  color: Colors.red.shade700.withOpacity(0.3),
                  width: 0.5)),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('RETIRER "$name"',
                  style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 3,
                      color: dark ? Colors.white : Colors.black87)),
              const SizedBox(height: 20),
              Text('Cette action est irréversible.',
                  style: TextStyle(
                      fontSize: 13,
                      letterSpacing: 0.2,
                      color: (dark ? Colors.white : Colors.black)
                          .withOpacity(0.45))),
              const SizedBox(height: 28),
              Row(children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () => Navigator.pop(ctx, false),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: (dark ? Colors.white : Colors.black)
                                  .withOpacity(0.15),
                              width: 0.5)),
                      child: Center(
                          child: Text('ANNULER',
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: (dark ? Colors.white : Colors.black)
                                      .withOpacity(0.45)))),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.heavyImpact();
                      Navigator.pop(ctx, true);
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: Colors.red.shade700,
                      child: const Center(
                          child: Text('SUPPRIMER',
                              style: TextStyle(
                                  fontSize: 10,
                                  letterSpacing: 2,
                                  color: Colors.white))),
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
      try {
        await ApiService.deleteLivestock(id);
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(_snack('ANIMAL RETIRÉ'));
          _refresh();
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context)
              .showSnackBar(_snack('ERREUR: $e', error: true));
        }
      }
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeProvider>().isDarkMode;
    final mobile = MediaQuery.of(context).size.width < 768;
    return Scaffold(
      backgroundColor: AppColors.getBgColor(dark),
      body: mobile ? _mobile(dark) : _desktop(dark),
    );
  }

  Widget _mobile(bool dark) {
    final bg = AppColors.getBgColor(dark);
    final fg = dark ? Colors.white : Colors.black87;

    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) => Scaffold(
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight * _headerController.value),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: kToolbarHeight * _headerController.value,
          child: ClipRect(
            child: AnimatedSlide(
              offset: _headerVisible ? Offset.zero : const Offset(0, -1),
              duration: const Duration(milliseconds: 180),
              curve: Curves.easeOutCubic,
              child: AnimatedOpacity(
                opacity: _headerVisible ? 1 : 0,
                duration: const Duration(milliseconds: 120),
                child: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('MA FERME',
            style: TextStyle(fontSize: 13, letterSpacing: 2.5, color: fg)),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.add, color: fg, size: 22),
            color: bg,
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            onSelected: (v) {
              HapticFeedback.lightImpact();
              final screen = v == 'farm'
                  ? const CreateFarmScreen()
                  : const CreateLivestockScreen();
              Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
                  .then((r) => r == true ? _refresh() : null);
            },
            itemBuilder: (_) => [
              _popItem('farm', Icons.landscape_outlined, 'AJOUTER UNE FERME', dark),
              _popItem('livestock', Icons.pets_outlined, 'AJOUTER UN ANIMAL', dark),
            ],
          ),
        ],
                ),
              ),
            ),
          ),
        ),
      ),
      drawer: _drawer(dark),
      body: Column(children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          height: 56 * _headerController.value,
          child: ClipRect(
            child: SectionBar(
              selected: _section,
              onSelect: _switchSection,
              dark: dark,
            ),
          ),
        ),
        Expanded(
          child: NotificationListener<ScrollNotification>(
            onNotification: _handleScroll,
            child: RefreshIndicator(
            color: AppColors.accent,
            backgroundColor: bg,
            onRefresh: _refresh,
            child: SingleChildScrollView(
              controller: _pageScrollController,
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: SlideTransition(
                  position: Tween<Offset>(begin: const Offset(0.02, 0), end: Offset.zero)
                      .animate(_sectionSlide),
                  child: FadeTransition(
                    opacity: _sectionFade,
                    child: _body(dark),
                  ),
                ),
              ),
            ),
            ),
          ),
        ),
      ]),
      ),
    );
  }

  Widget _desktop(bool dark) {
    final bg = AppColors.getBgColor(dark);
    final sub = (dark ? Colors.white : Colors.black).withOpacity(0.08);
    return Row(children: [
      Container(
        width: 240,
        decoration: BoxDecoration(
            color: bg,
            border: Border(right: BorderSide(color: sub))),
        child: SingleChildScrollView(
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text('MA FERME',
                      style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 2.5,
                          color: dark ? Colors.white : Colors.black87)),
                ),
                const SizedBox(height: 48),
                _sideItem(0, 'FERMES', Icons.landscape_outlined, dark),
                _sideItem(1, 'ANIMAUX', Icons.pets_outlined, dark),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 16),
                  child: Text('PUBLIC',
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2,
                          color: (dark ? Colors.white : Colors.black)
                              .withOpacity(0.38))),
                ),
                _publicItem(dark),
              ]),
        ),
      ),
      Expanded(
        child: RefreshIndicator(
          onRefresh: _refresh,
          color: AppColors.accent,
          backgroundColor: bg,
          child: SingleChildScrollView(
            controller: _pageScrollController,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: SlideTransition(
                position: Tween<Offset>(begin: const Offset(0.02, 0), end: Offset.zero)
                    .animate(_sectionSlide),
                child: FadeTransition(
                  opacity: _sectionFade,
                  child: _body(dark),
                ),
              ),
            ),
          ),
        ),
      ),
    ]);
  }

  // ── Sidebar items ────────────────────────────────────────────────────────
  PopupMenuItem<String> _popItem(
      String val, IconData icon, String label, bool dark) {
    final c = dark ? Colors.white : Colors.black87;
    return PopupMenuItem(
      value: val,
      child: Row(children: [
        Icon(icon, size: 16, color: c),
        const SizedBox(width: 12),
        Text(label, style: TextStyle(fontSize: 10, letterSpacing: 1.5, color: c)),
      ]),
    );
  }

  Widget _drawer(bool dark) {
    final bg = AppColors.getBgColor(dark);
    return Drawer(
      backgroundColor: bg,
      child: SafeArea(
        child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 32),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 40),
                child: Text('NAVIGATION',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: (dark ? Colors.white : Colors.black)
                            .withOpacity(0.38))),
              ),
              _sideItem(0, 'FERMES', Icons.landscape_outlined, dark, drawer: true),
              _sideItem(1, 'ANIMAUX', Icons.pets_outlined, dark, drawer: true),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 16),
                child: Text('PUBLIC',
                    style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 2,
                        color: (dark ? Colors.white : Colors.black)
                            .withOpacity(0.38))),
              ),
              _publicItem(dark, drawer: true),
            ]),
      ),
    );
  }

  Widget _sideItem(int section, String label, IconData icon, bool dark,
      {bool drawer = false}) {
    final sel = _section == section;
    final fg = dark ? Colors.white : Colors.black87;
    final dim = (dark ? Colors.white : Colors.black).withOpacity(0.38);
    return GestureDetector(
      onTap: () {
        _switchSection(section);
        if (drawer) Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: sel
              ? (dark ? Colors.white : Colors.black).withOpacity(0.03)
              : Colors.transparent,
          border: Border(
              left: BorderSide(
                  color: sel ? AppColors.accent : Colors.transparent,
                  width: 1.5)),
        ),
        child: Row(children: [
          Icon(icon, size: 16, color: sel ? fg : dim),
          const SizedBox(width: 16),
          Text(label,
              style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: sel ? fg : dim)),
        ]),
      ),
    );
  }

  Widget _publicItem(bool dark, {bool drawer = false}) {
    final dim = (dark ? Colors.white : Colors.black).withOpacity(0.38);
    return GestureDetector(
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PublicFarmsScreen())),
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(children: [
          Icon(Icons.public_outlined, size: 16, color: dim),
          const SizedBox(width: 16),
          Text('VISITER FERMES',
              style: TextStyle(fontSize: 11, letterSpacing: 1.5, color: dim)),
        ]),
      ),
    );
  }

  // ── Body ──────────────────────────────────────────────────────────────────
  Widget _body(bool dark) {
    if (AuthService.currentSession == null) {
      return WelcomeScreen(
        dark: dark,
        onLogin: () => Navigator.pushNamed(context, '/login'),
        onDiscover: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => const SocialFeedScreen())),
      );
    }
    return FutureBuilder<List<dynamic>>(
      future: _section == 1 ? _livestock() : _farms(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return FarmLoader(dark: dark);
        }
        final items = snap.data ?? [];
        if (items.isEmpty) {
          return EmptyState(
            isLivestock: _section == 1,
            dark: dark,
            onCreateFarm: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CreateFarmScreen(
                        userId: AuthService.currentSession?.userId)))
                .then((_) => _refresh()),
            onCreateLivestock: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => CreateLivestockScreen(
                        userId: AuthService.currentSession?.userId)))
                .then((_) => _refresh()),
          );
        }
        return _section == 0
            ? _farmsGrid(_sorted(items), dark)
            : _livestockList(items, dark);
      },
    );
  }

  // ── Farms grid ────────────────────────────────────────────────────────────
  Widget _farmsGrid(List<dynamic> farms, bool dark) {
    final mobile = MediaQuery.of(context).size.width < 768;
    if (mobile) {
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 12),
        itemCount: farms.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) =>
            _buildFarmCard(farms[i] as Map<String, dynamic>, dark),
      );
    }
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: farms.length,
      itemBuilder: (_, i) =>
          _buildFarmCard(farms[i] as Map<String, dynamic>, dark),
    );
  }

  Widget _buildFarmCard(Map<String, dynamic> farm, bool dark) {
    final name = (farm['name'] ?? 'Ferme') as String;
    final image = farm['image_url'] as String?;
    final farmId = farm['id'] as int? ?? 0;
    final location = farm['location'] as String? ?? '';
    final myId = AuthService.currentSession?.userId ?? 0;
    final ownerId = farm['user_id'] as int? ?? 0;
    final isOwner = myId == ownerId && myId > 0;

    return FarmCard(
      farm: farm,
      farmId: farmId,
      name: name,
      location: location,
      image: image,
      isOwner: isOwner,
      dark: dark,
      aspectRatio: 1.15,
      cropsFuture: _crops(farmId),
      onEdit: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => EditFarmScreen(
                      farm: farm,
                      isDarkMode: dark,
                      userId: widget.userId)))
          .then((_) => _refresh()),
      onDelete: () => _deleteFarm(farmId, name, dark),
      onParcelles: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ParcelScreen(
                  farmId: farmId, userId: widget.userId ?? 0))),
      onParcelTap: (parcelId) => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => ParcelScreen(
                  farmId: farmId,
                  userId: widget.userId ?? 0,
                  selectedParcelId: parcelId))),
      onPhotoTap: _showPhotoOverlay,
    );
  }

  void _showPhotoOverlay(BuildContext ctx, String name, String photo) {
    showDialog(
      context: ctx,
      barrierColor: Colors.black.withOpacity(0.92),
      builder: (_) => GestureDetector(
        onTap: () => Navigator.pop(ctx),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          body: SafeArea(
            child: Center(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 20),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: Colors.white.withOpacity(0.2),
                          width: 0.5)),
                  child: Text(name.toUpperCase(),
                      style: const TextStyle(
                          fontSize: 11,
                          letterSpacing: 2.5,
                          color: Colors.white70)),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  constraints: const BoxConstraints(maxHeight: 460, maxWidth: 560),
                  decoration: BoxDecoration(
                      border: Border.all(
                          color: AppColors.accent.withOpacity(0.4),
                          width: 1)),
                  child: Image.network(photo,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (_, child, prog) => prog == null
                          ? child
                          : const SizedBox(
                              height: 220,
                              child: Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 1,
                                      color: Colors.white24))),
                      errorBuilder: (_, __, ___) => const SizedBox(
                          height: 200,
                          child: Center(
                              child: Icon(
                                  Icons.broken_image_outlined,
                                  color: Colors.white24,
                                  size: 32)))),
                ),
                const SizedBox(height: 20),
                const Text('APPUYER POUR FERMER',
                    style: TextStyle(
                        fontSize: 8,
                        letterSpacing: 2,
                        color: Colors.white24)),
              ]),
            ),
          ),
        ),
      ),
    );
  }

  // ── Livestock list ────────────────────────────────────────────────────────
  Widget _livestockList(List<dynamic> animals, bool dark) {
    return Column(children: [
      const Padding(
        padding: EdgeInsets.only(bottom: 16, top: 4),
        child: Row(mainAxisAlignment: MainAxisAlignment.end, children: [
          StatusDot(color: Colors.green, label: 'SAIN'),
          SizedBox(width: 12),
          StatusDot(color: Colors.amber, label: 'ATTENTION'),
          SizedBox(width: 12),
          StatusDot(color: Colors.red, label: 'CRITIQUE'),
        ]),
      ),
      ...animals.asMap().entries.map((e) {
        final a = e.value as Map<String, dynamic>;
        final id = a['id'] as int?;
        return Dismissible(
          key: Key('animal_${a['id']}'),
          direction: DismissDirection.endToStart,
          background: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20),
            color: Colors.red.shade700,
            child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.delete_outline,
                      color: Colors.white, size: 20),
                  SizedBox(height: 4),
                  Text('SUPPRIMER',
                      style: TextStyle(
                          fontSize: 9, letterSpacing: 1.5, color: Colors.white)),
                ]),
          ),
          confirmDismiss: (_) async {
            final name = (a['animal_type'] ?? 'Animal') as String;
            if (id == null) return false;
            HapticFeedback.heavyImpact();
            await _deleteLivestock(id, name, dark);
            return false;
          },
          child: Container(
            margin: const EdgeInsets.only(bottom: 10),
            child: _AnimalCard(
              animal: a,
              dark: dark,
              onTap: id == null
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EditLivestockScreen(
                              livestockId: id, livestock: a))),
            ),
          ),
        );
      }),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ANIMAL CARD (gardé ici car spécifique à FarmTab)
// ─────────────────────────────────────────────────────────────────────────────
class _AnimalCard extends StatelessWidget {
  final Map<String, dynamic> animal;
  final bool dark;
  final VoidCallback? onTap;

  const _AnimalCard({
    required this.animal,
    required this.dark,
    this.onTap,
  });

  Color _statusColor(Map<String, dynamic> crop) {
    // Version simplifiée pour les animaux
    try {
      final health = crop['health_status']?.toString().toLowerCase() ?? '';
      if (health.contains('malade') || health.contains('blessé')) {
        return Colors.red;
      }
      if (health.contains('attention') || health.contains('surveillance')) {
        return Colors.amber;
      }
    } catch (_) {}
    return Colors.green;
  }

  @override
  Widget build(BuildContext context) {
    final type = (animal['animal_type'] ?? 'Animal') as String;
    final breed = animal['breed'] as String? ?? '';
    final qty = animal['quantity'] as int? ?? 1;
    final ageMonths = animal['age_months'];
    final weightKg = animal['weight_kg'];
    final photo = animal['image_url'] ??
        animal['imageUrl'] ??
        (animal['photos'] is List && (animal['photos'] as List).isNotEmpty
            ? (animal['photos'] as List).first
            : null);
    final health = _statusColor(animal);
    final fg = dark ? Colors.white : Colors.black87;
    final sub = (dark ? Colors.white : Colors.black).withOpacity(0.38);
    final border = (dark ? Colors.white : Colors.black).withOpacity(0.08);
    final bg = AppColors.getCardBgColor(dark);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
            color: bg,
            border: Border.all(color: border, width: 0.5)),
        child: Row(children: [
          Stack(children: [
            Container(
              width: 72,
              height: 72,
              color: dark ? AppColors.darkCardBg : AppColors.lightCardBg,
                child: photo != null
                  ? Image.network(photo.toString(),
                      errorBuilder: (_, __, ___) => Icon(
                          Icons.pets,
                          size: 24,
                          color: sub))
                  : Icon(Icons.pets, size: 24, color: sub),
            ),
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(width: 3, color: health),
            ),
          ]),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(type.toUpperCase(),
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w400,
                          color: fg)),
                  if (breed.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(breed,
                        style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 0.5,
                            color: sub)),
                  ],
                  if (ageMonths != null || weightKg != null) ...[
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        if (ageMonths != null)
                          Flexible(
                            child: Text(
                              '$ageMonths mois',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: sub),
                            ),
                          ),
                        if (ageMonths != null && weightKg != null)
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 6),
                            child: Text('|', style: TextStyle(color: sub)),
                          ),
                        if (weightKg != null)
                          Flexible(
                            child: Text(
                              '$weightKg kg',
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: 11, color: sub),
                            ),
                          ),
                      ],
                    ),
                  ],
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: health.withOpacity(0.12),
                        border: Border.all(
                            color: health.withOpacity(0.4),
                            width: 0.5)),
                    child: Text(
                      health == Colors.green
                          ? 'SAIN'
                          : health == Colors.amber
                              ? 'ATTENTION'
                              : 'CRITIQUE',
                      style: TextStyle(
                          fontSize: 8,
                          letterSpacing: 1.5,
                          color: health),
                    ),
                  ),
                ]),
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                        border: Border.all(color: border, width: 0.5)),
                    child: Text('×$qty',
                        style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 1,
                            color: fg)),
                  ),
                  const SizedBox(height: 6),
                  Icon(Icons.chevron_right,
                      size: 14, color: sub),
                ]),
          ),
        ]),
      ),
    );
  }
}