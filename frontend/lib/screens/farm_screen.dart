import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/screens/edit_livestock_screen.dart';
import 'package:mbaymi/screens/edit_farm_screen.dart';
import 'package:mbaymi/screens/create_farm_screen.dart';
import 'package:mbaymi/screens/create_livestock_screen.dart';
import 'package:mbaymi/screens/social_feed_screen.dart';
import 'package:mbaymi/screens/parcel_screen.dart';
import 'package:mbaymi/screens/public_farms_screen.dart';
import 'package:mbaymi/widgets/fading_images_widget.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/widgets/farm_aerial_view.dart';

// ─── Cache global persistant ──────────────────────────────────────────────────
final _dataCache  = <String, Future<List<dynamic>>>{};
final _cropsCache = <int, Future<List<dynamic>>>{};

// ─── Helpers ──────────────────────────────────────────────────────────────────
TextStyle _label({double size = 11, double spacing = 1.5, double opacity = 1, FontWeight w = FontWeight.w300, Color? color}) =>
    TextStyle(fontSize: size, letterSpacing: spacing, fontWeight: w, color: color?.withOpacity(opacity));

// ─── Widget ───────────────────────────────────────────────────────────────────
class FarmTab extends StatefulWidget {
  final int? userId;
  final int initialSection;
  const FarmTab({super.key, this.userId, this.initialSection = 0});

  @override
  State<FarmTab> createState() => _FarmTabState();
}

class _FarmTabState extends State<FarmTab> {
  int _section = 0;
  final _search = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _section = widget.initialSection;
    _search.addListener(() { if (_query != _search.text) setState(() => _query = _search.text); });
  }

  @override
  void dispose() { _search.dispose(); super.dispose(); }

  @override
  void didUpdateWidget(FarmTab old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId) {
      _section = widget.initialSection;
      setState(() {});
    }
  }

  // ─── Data ──────────────────────────────────────────────────────────────────
  Future<List<dynamic>> _farms() {
    final session = AuthService.currentSession;
    if (widget.userId != null) {
      return _dataCache.putIfAbsent('farms_${widget.userId}', () => ApiService.getPublicUserFarms(widget.userId!));
    }
    if (session != null && session.userId != null) {
      return _dataCache.putIfAbsent('farms_user_${session.userId}', () => ApiService.getPublicUserFarms(session.userId!));
    }
    return Future.value([]);
  }

  Future<List<dynamic>> _livestock() {
    if (widget.userId == null) return Future.value([]);
    return _dataCache.putIfAbsent('livestock_${widget.userId}', () => ApiService.getUserLivestock(widget.userId!));
  }

  Future<List<dynamic>> _crops(int farmId) =>
      _cropsCache.putIfAbsent(farmId, () => ApiService.getFarmCrops(farmId));

  List<dynamic> _sorted(List<dynamic> items) => List.from(items)
    ..sort((a, b) {
      try { return DateTime.parse(b['created_at']).compareTo(DateTime.parse(a['created_at'])); }
      catch (_) { return 0; }
    });

  Future<void> _refresh() async {
    final key = _section == 1 ? 'livestock_${widget.userId}' : 'farms_${widget.userId ?? 'user_${AuthService.currentSession?.userId}'}';
    _dataCache.remove(key);
    if (_section == 0) { _cropsCache.clear(); _search.clear(); }
    imageCache.clearLiveImages();
    imageCache.clear();
    setState(() {});
  }

  Future<void> _deleteFarm(int id, String name, bool dark) async {
    final scaffold = context;
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.getBgColor(dark),
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text('SUPPRIMER LA FERME', style: _label(size: 12, spacing: 2, color: dark ? Colors.white : Colors.black87)),
        content: Text('Supprimer "$name" ? Cette action est irréversible.', style: _label(color: dark ? Colors.white70 : Colors.black54)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text('ANNULER', style: _label(size: 10, spacing: 1.5, color: dark ? Colors.white60 : Colors.black54))),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                await ApiService.deleteFarm(id);
                if (mounted) {
                  ScaffoldMessenger.of(scaffold).showSnackBar(_snack('FERME SUPPRIMÉE'));
                  _refresh();
                }
              } catch (e) {
                if (mounted) ScaffoldMessenger.of(scaffold).showSnackBar(_snack('ERREUR: $e', error: true));
              }
            },
            child: const Text('SUPPRIMER', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w300, letterSpacing: 1.5, color: Colors.red)),
          ),
        ],
      ),
    );
  }

  SnackBar _snack(String msg, {bool error = false}) => SnackBar(
    content: Text(msg, style: _label(size: 10, spacing: 1.5, color: Colors.white)),
    backgroundColor: error ? Colors.red.shade400 : Colors.black87,
    behavior: SnackBarBehavior.floating,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
  );

  // ─── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final dark = context.watch<ThemeProvider>().isDarkMode;
    final mobile = MediaQuery.of(context).size.width < 768;
    final bg = AppColors.getBgColor(dark);

    return Scaffold(
      backgroundColor: bg,
      body: mobile ? _mobile(dark) : _desktop(dark),
    );
  }

  Widget _mobile(bool dark) {
    final bg = AppColors.getBgColor(dark);
    final fg = dark ? Colors.white : Colors.black87;
    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text('MA FERME', style: _label(size: 13, spacing: 2.5, color: fg)),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: Icon(Icons.add, color: fg, size: 24),
            onSelected: (v) {
              HapticFeedback.lightImpact();
              final screen = v == 'farm' ? const CreateFarmScreen() : const CreateLivestockScreen();
              Navigator.push(context, MaterialPageRoute(builder: (_) => screen))
                  .then((r) => r == true ? _refresh() : null);
            },
            itemBuilder: (_) => [
              _popItem('farm', Icons.landscape_outlined, 'Ajouter une ferme', dark),
              _popItem('livestock', Icons.pets_outlined, 'Ajouter un animal', dark),
            ],
          ),
        ],
      ),
      drawer: _drawer(dark),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: bg,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: _body(dark)),
        ),
      ),
    );
  }

  Widget _desktop(bool dark) {
    final bg = AppColors.getBgColor(dark);
    return Row(
      children: [
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: bg,
            border: Border(right: BorderSide(color: (dark ? Colors.white : Colors.black).withOpacity(0.05))),
          ),
          child: SingleChildScrollView(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const SizedBox(height: 40),
              Padding(padding: const EdgeInsets.only(left: 24), child: Text('MA FERME', style: _label(size: 13, spacing: 2.5, color: dark ? Colors.white : Colors.black87))),
              const SizedBox(height: 48),
              _sideItem(0, 'VUE D\'ENSEMBLE', Icons.home_outlined, dark),
              _sideItem(0, 'CULTURES', Icons.landscape_outlined, dark),
              _sideItem(1, 'ANIMAUX', Icons.pets_outlined, dark),
              _sideItem(0, 'SERRE', Icons.thermostat_outlined, dark),
              _sideItem(0, 'ÉQUIPEMENTS', Icons.build_outlined, dark),
              const SizedBox(height: 48),
              Padding(padding: const EdgeInsets.only(left: 24, bottom: 16), child: Text('PUBLIC', style: _label(size: 11, spacing: 2, opacity: 0.38, color: dark ? Colors.white : Colors.black))),
              _publicItem(dark),
              const SizedBox(height: 48),
            ]),
          ),
        ),
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refresh,
            color: AppColors.accent,
            backgroundColor: bg,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(padding: const EdgeInsets.all(32), child: _body(dark)),
            ),
          ),
        ),
      ],
    );
  }

  PopupMenuItem<String> _popItem(String val, IconData icon, String label, bool dark) {
    final c = dark ? Colors.white : Colors.black87;
    return PopupMenuItem(
      value: val,
      child: Row(children: [Icon(icon, size: 18, color: c), const SizedBox(width: 12), Text(label, style: TextStyle(color: c, fontSize: 12))]),
    );
  }

  Widget _drawer(bool dark) {
    final bg = AppColors.getBgColor(dark);
    return Drawer(
      backgroundColor: bg,
      child: SafeArea(
        child: ListView(padding: const EdgeInsets.symmetric(vertical: 32), children: [
          Padding(padding: const EdgeInsets.only(left: 24, bottom: 40), child: Text('NAVIGATION', style: _label(size: 11, spacing: 2, opacity: 0.38, color: dark ? Colors.white : Colors.black))),
          _sideItem(0, 'VUE D\'ENSEMBLE', Icons.home_outlined, dark, drawer: true),
          _sideItem(0, 'CULTURES', Icons.landscape_outlined, dark, drawer: true),
          _sideItem(1, 'ANIMAUX', Icons.pets_outlined, dark, drawer: true),
          _sideItem(0, 'SERRE', Icons.thermostat_outlined, dark, drawer: true),
          _sideItem(0, 'ÉQUIPEMENTS', Icons.build_outlined, dark, drawer: true),
          const SizedBox(height: 32),
          Padding(padding: const EdgeInsets.only(left: 24, bottom: 16), child: Text('PUBLIC', style: _label(size: 11, spacing: 2, opacity: 0.38, color: dark ? Colors.white : Colors.black))),
          _publicItem(dark, drawer: true),
        ]),
      ),
    );
  }

  Widget _sideItem(int section, String label, IconData icon, bool dark, {bool drawer = false}) {
    final sel = _section == section;
    final fg = dark ? Colors.white : Colors.black87;
    final dim = (dark ? Colors.white : Colors.black).withOpacity(0.38);
    return GestureDetector(
      onTap: () {
        setState(() => _section = section);
        if (drawer) Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: sel ? (dark ? Colors.white : Colors.black).withOpacity(0.03) : Colors.transparent,
          border: Border(left: BorderSide(color: sel ? AppColors.accent : Colors.transparent, width: 1.5)),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: sel ? fg : dim),
          const SizedBox(width: 16),
          Text(label, style: _label(size: 11, spacing: 1.5, color: sel ? fg : dim)),
        ]),
      ),
    );
  }

  Widget _publicItem(bool dark, {bool drawer = false}) {
    final dim = (dark ? Colors.white : Colors.black).withOpacity(0.38);
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const PublicFarmsScreen())),
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        child: Row(children: [
          Icon(Icons.public_outlined, size: 18, color: dim),
          const SizedBox(width: 16),
          Text('VISITER FERMES', style: _label(size: 11, spacing: 1.5, color: dim)),
        ]),
      ),
    );
  }

  // ─── Main body ─────────────────────────────────────────────────────────────
  Widget _body(bool dark) {
    if (AuthService.currentSession == null) return _welcome(dark);
    return FutureBuilder<List<dynamic>>(
      future: _section == 1 ? _livestock() : _farms(),
      builder: (ctx, snap) {
        if (snap.connectionState == ConnectionState.waiting) return _loader(dark);
        final items = snap.data ?? [];
        if (items.isEmpty) return _empty(dark);
        return _section == 0 ? _farmsGrid(_sorted(items), dark) : _animalsList(items, dark);
      },
    );
  }

  Widget _loader(bool dark) => SizedBox(
    height: 400,
    child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 1, color: (dark ? Colors.white : Colors.black).withOpacity(0.2)))),
  );

  Widget _empty(bool dark) {
    final isLivestock = _section == 1;
    return SizedBox(
      height: 400,
      child: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(isLivestock ? Icons.pets_outlined : Icons.landscape_outlined, size: 36, color: (dark ? Colors.white : Colors.black).withOpacity(0.15)),
          const SizedBox(height: 24),
          Text(isLivestock ? 'AUCUN ANIMAL' : 'AUCUNE FERME', style: _label(size: 11, spacing: 2, color: dark ? Colors.white60 : Colors.black54)),
          const SizedBox(height: 40),
          _actionBtn('CRÉER UNE FERME', filled: true, onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => CreateFarmScreen(userId: AuthService.currentSession?.userId)))
                  .then((_) => _refresh())),
          const SizedBox(height: 12),
          _actionBtn('AJOUTER DU BÉTAIL', filled: false, dark: dark, onTap: () =>
              Navigator.push(context, MaterialPageRoute(builder: (_) => CreateLivestockScreen(userId: AuthService.currentSession?.userId)))
                  .then((_) => _refresh())),
        ]),
      ),
    );
  }

  Widget _actionBtn(String label, {required bool filled, bool dark = false, required VoidCallback onTap}) {
    if (filled) {
      return SizedBox(
        width: 240,
        child: TextButton(
          onPressed: onTap,
          style: TextButton.styleFrom(
            backgroundColor: Colors.black87, foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          ),
          child: Text(label, style: _label(size: 11, spacing: 2, color: Colors.white)),
        ),
      );
    }
    return SizedBox(
      width: 240,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
          side: BorderSide(color: (dark ? Colors.white : Colors.black).withOpacity(0.25)),
        ),
        child: Text(label, style: _label(size: 11, spacing: 2, color: dark ? Colors.white70 : Colors.black87)),
      ),
    );
  }

  // ─── Farms grid ────────────────────────────────────────────────────────────
  Widget _farmsGrid(List<dynamic> farms, bool dark) {
    final mobile = MediaQuery.of(context).size.width < 768;
    if (mobile) {
      // Mobile : liste simple, pas de grille
      return ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(vertical: 16),
        itemCount: farms.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (_, i) => _farmCard(farms[i] as Map<String, dynamic>, dark),
      );
    }
    // Desktop : 2 colonnes
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(vertical: 16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: farms.length,
      itemBuilder: (_, i) => _farmCard(farms[i] as Map<String, dynamic>, dark),
    );
  }

  Widget _farmCard(Map<String, dynamic> farm, bool dark) {
    final name    = (farm['name'] ?? 'Ferme') as String;
    final image   = farm['image_url'] as String?;
    final farmId  = farm['id'] as int? ?? 0;
    final location = farm['location'] as String? ?? '';
    final myId    = AuthService.currentSession?.userId ?? 0;
    final ownerId = farm['user_id'] as int? ?? 0;
    final isOwner = myId == ownerId && myId > 0;

    // La carte entiere = image interactive draggable + overlays fixes
    return _InteractiveFarmCard(
      farm: farm,
      farmId: farmId,
      name: name,
      location: location,
      image: image,
      isOwner: isOwner,
      dark: dark,
      cropsFuture: _crops(farmId),
      onEdit: () => Navigator.push(context, MaterialPageRoute(builder: (_) =>
          EditFarmScreen(farm: farm, isDarkMode: dark, userId: widget.userId)))
          .then((_) => _refresh()),
      onDelete: () => _deleteFarm(farmId, name, dark),
      onParcelles: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => ParcelScreen(farmId: farmId, userId: widget.userId ?? 0))),
      onPhotoTap: _showPhotoOverlay,
    );
  }

  // Dot + tooltip flottant pour une parcelle
  Widget _cropPin(Map<String, dynamic> crop, double dx, double dy,
      bool alignRight, bool alignTop, double w, double h, bool dark) {
    final name     = (crop['crop_name'] ?? '').toString();
    final photo    = (crop['image_url'] ?? crop['photo_url'] ?? crop['photo'] ?? '') as String;
    final hasPhoto = photo.isNotEmpty;
    final accent   = AppColors.accent;

    // Pixel position du dot
    final px = dx * w;
    final py = dy * h;

    // Constantes vignette : 92 × 80 (photo 56 + label 24)
    const tw = 92.0;
    const th = 80.0; // photo+label
    const tTextH = 24.0;
    const tPhotoH = th - tTextH;
    // Tooltip texte seul : 100 × 26
    const ttW = 100.0;
    const ttH = 26.0;

    // Calcul position du tooltip en pixels absolus,
    // en partant du dot et en allant dans le quadrant libre.
    // On clampe pour rester dans les bornes de la carte.
    double tLeft, tTop;
    const gap  = 14.0; // distance dot → coin tooltip
    const lineLen = 28.0;

    if (hasPhoto) {
      tLeft = alignRight ? (px - gap - tw).clamp(2, w - tw - 2) : (px + gap).clamp(2, w - tw - 2);
      tTop  = alignTop   ? (py - lineLen - th).clamp(2, h - th - 40) : (py + lineLen).clamp(2, h - th - 40);
    } else {
      tLeft = alignRight ? (px - gap - ttW).clamp(2, w - ttW - 2) : (px + gap).clamp(2, w - ttW - 2);
      tTop  = alignTop   ? (py - lineLen - ttH).clamp(2, h - ttH - 40) : (py + lineLen).clamp(2, h - ttH - 40);
    }

    return Stack(clipBehavior: Clip.none, children: [
      // Connecteur coudé dot → coin tooltip
      Positioned(
        left: px, top: py,
        child: CustomPaint(
          size: const Size(32, 32),
          painter: _PinLinePainter(right: alignRight, up: alignTop),
        ),
      ),

      // Dot pulsant
      Positioned(
        left: px - 5, top: py - 5,
        child: _PulsingDot(color: accent),
      ),

      // Tooltip
      Positioned(
        left: tLeft, top: tTop,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: hasPhoto ? () => _showPhotoOverlay(context, name, photo) : null,
          child: hasPhoto
              ? _PhotoPin(name: name, photo: photo, accent: accent)
              : Container(
                  width: ttW,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.70),
                    border: Border.all(color: Colors.white.withOpacity(0.18), width: 0.5),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)],
                  ),
                  child: Text(
                    name.length > 13 ? name.substring(0, 13) : name,
                    style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w300, letterSpacing: 0.8, color: Colors.white),
                    maxLines: 1, overflow: TextOverflow.ellipsis,
                  ),
                ),
        ),
      ),
    ]);
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
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Chip nom
                  Container(
                    margin: const EdgeInsets.only(bottom: 20),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white.withOpacity(0.2), width: 0.5),
                    ),
                    child: Text(name.toUpperCase(),
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w300, letterSpacing: 2.5, color: Colors.white70)),
                  ),
                  // Photo
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20),
                    constraints: const BoxConstraints(maxHeight: 460, maxWidth: 560),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.accent.withOpacity(0.4), width: 1),
                    ),
                    child: Image.network(
                      photo,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      loadingBuilder: (_, child, prog) => prog == null
                          ? child
                          : const SizedBox(height: 220,
                              child: Center(child: CircularProgressIndicator(strokeWidth: 1, color: Colors.white24))),
                      errorBuilder: (_, __, ___) => const SizedBox(height: 200,
                          child: Center(child: Icon(Icons.broken_image_outlined, color: Colors.white24, size: 32))),
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text('APPUYER POUR FERMER',
                      style: TextStyle(fontSize: 8, fontWeight: FontWeight.w300, letterSpacing: 2, color: Colors.white24)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _farmPlaceholder(bool dark) => Container(
    color: dark ? AppColors.darkCardBg : AppColors.lightCardBg,
    child: Center(child: Icon(Icons.landscape_outlined, size: 36, color: (dark ? Colors.white : Colors.black).withOpacity(0.08))),
  );

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.9), borderRadius: BorderRadius.circular(4)),
      child: Icon(icon, color: Colors.white, size: 15),
    ),
  );


  // ─── Animals list ──────────────────────────────────────────────────────────
  Widget _animalsList(List<dynamic> animals, bool dark) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: animals.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, i) => _animalCard(animals[i] as Map<String, dynamic>, dark),
    );
  }

  Widget _animalCard(Map<String, dynamic> a, bool dark) {
    final type = (a['animal_type'] ?? 'Animal') as String;
    final breed = a['breed'] as String? ?? '';
    final qty = a['quantity'] as int? ?? 1;
    final photo = a['image_url'] ?? a['imageUrl'] ?? (a['photos'] is List && (a['photos'] as List).isNotEmpty ? (a['photos'] as List).first : null);
    final id = a['id'] as int?;
    final bg = dark ? AppColors.getCardBgColor(dark) : AppColors.lightBgAlt;

    return GestureDetector(
      onTap: id != null ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => EditLivestockScreen(livestockId: id, livestock: a))) : null,
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(color: bg, border: Border.all(color: (dark ? Colors.white : Colors.black).withOpacity(0.08))),
        child: Row(children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: dark ? AppColors.darkCardBg : AppColors.lightCardBg,
              image: photo != null ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover) : null,
            ),
            child: photo == null ? Icon(Icons.pets, size: 22, color: (dark ? Colors.white : Colors.black).withOpacity(0.1)) : null,
          ),
          const SizedBox(width: 18),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(type.toUpperCase(), style: _label(size: 11, spacing: 1.5, color: dark ? Colors.white : Colors.black87)),
            if (breed.isNotEmpty) ...[const SizedBox(height: 3), Text(breed, style: _label(size: 10, spacing: 0.5, color: (dark ? Colors.white : Colors.black).withOpacity(0.38)))],
          ])),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(border: Border.all(color: (dark ? Colors.white : Colors.black).withOpacity(0.1))),
            child: Text('×$qty', style: _label(size: 10, spacing: 1, color: dark ? Colors.white70 : Colors.black87)),
          ),
        ]),
      ),
    );
  }

  // ─── Welcome (non-auth) ────────────────────────────────────────────────────
  Widget _welcome(bool dark) {
    return Column(children: [
      // Hero photo
      SizedBox(
        height: 240,
        width: double.infinity,
        child: Stack(fit: StackFit.expand, children: [
          const FadingImagesWidget(
            imageUrls: [
              'https://res.cloudinary.com/dcs9vkwe0/image/upload/v1769257913/kxbovkugo5ertntwwtgv.jpg',
              'https://res.cloudinary.com/dcs9vkwe0/image/upload/v1769258097/hcrl7a4o7ttp9idaaf4j.jpg',
              'https://res.cloudinary.com/dcs9vkwe0/image/upload/v1769259314/lukvpj3povcqtbahoe0f.jpg',
              'https://res.cloudinary.com/dcs9vkwe0/image/upload/v1769259315/xmyyggmzlwr1w1lti5w8.jpg',
              'https://res.cloudinary.com/dcs9vkwe0/image/upload/v1769259313/ecjpbmfnxdzlmpmk73gy.jpg',
            ],
            height: 240,
            displayDuration: Duration(seconds: 3),
            fadeDuration: Duration(milliseconds: 800),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.black.withOpacity(0.1), Colors.black.withOpacity(0.65)],
                ),
              ),
            ),
          ),
          Positioned(left: 24, bottom: 28, child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('SAVANA', style: TextStyle(fontSize: 30, fontWeight: FontWeight.w200, letterSpacing: 9, color: Colors.white)),
              Text('Agriculture moderne', style: _label(size: 11, spacing: 1.5, color: Colors.white60)),
            ],
          )),
        ]),
      ),

      const SizedBox(height: 48),

      Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(children: [
          _actionBtn('SE CONNECTER', filled: true, onTap: () => Navigator.pushNamed(context, '/login')),
          const SizedBox(height: 14),
          _actionBtn('DÉCOUVRIR', filled: false, dark: dark,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SocialFeedScreen(isDarkMode: dark)))),
          const SizedBox(height: 24),
          Text('Explorez des fermes publiques', style: _label(size: 11, spacing: 0.5, opacity: 0.38, color: dark ? Colors.white : Colors.black), textAlign: TextAlign.center),
          const SizedBox(height: 48),
        ]),
      ),
    ]);
  }
}

// ─── Connecteur dynamique dot → centre tooltip ────────────────────────────────
class _DynamicLinePainter extends CustomPainter {
  final Offset from; // position du dot
  final Offset to;   // centre du tooltip
  final bool dragging;
  _DynamicLinePainter({required this.from, required this.to, required this.dragging});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withOpacity(dragging ? 0.7 : 0.45)
      ..strokeWidth = dragging ? 1.2 : 0.7
      ..style = PaintingStyle.stroke;

    // Ligne coudée : verticale jusqu'au milieu, puis horizontale
    final mid = Offset(from.dx, (from.dy + to.dy) / 2);
    final path = Path()
      ..moveTo(from.dx, from.dy)
      ..lineTo(mid.dx, mid.dy)
      ..lineTo(to.dx, mid.dy)
      ..lineTo(to.dx, to.dy);
    canvas.drawPath(path, paint);

    // Petit cercle au bout
    canvas.drawCircle(to, 2, Paint()..color = Colors.white.withOpacity(dragging ? 0.7 : 0.3));
  }

  @override
  bool shouldRepaint(_DynamicLinePainter old) =>
      old.from != from || old.to != to || old.dragging != dragging;
}

// ─── Ancien painter statique (garde pour compat) ──────────────────────────────
class _PinLinePainter extends CustomPainter {
  final bool right, up;
  _PinLinePainter({required this.right, required this.up});

  @override
  void paint(Canvas canvas, Size size) {
    final p = Paint()
      ..color = Colors.white.withOpacity(0.5)
      ..strokeWidth = 0.8
      ..style = PaintingStyle.stroke;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(0, up ? -size.height * 0.5 : size.height * 0.5)
      ..lineTo(right ? size.width : -size.width, up ? -size.height * 0.5 : size.height * 0.5);
    canvas.drawPath(path, p);
  }

  @override
  bool shouldRepaint(_) => false;
}

// ─── Photo tooltip sur la carte aérienne ──────────────────────────────────────
class _PhotoPin extends StatelessWidget {
  final String name;
  final String photo;
  final Color accent;
  const _PhotoPin({required this.name, required this.photo, required this.accent});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 90,
      decoration: BoxDecoration(
        border: Border.all(color: accent.withOpacity(0.6), width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.4), blurRadius: 8)],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Vignette photo
          SizedBox(
            height: 56,
            child: Image.network(
              photo,
              fit: BoxFit.cover,
              width: double.infinity,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.black54,
                child: const Icon(Icons.grass_outlined, size: 18, color: Colors.white24),
              ),
            ),
          ),
          // Nom en dessous
          Container(
            color: Colors.black.withOpacity(0.75),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Row(children: [
              Expanded(
                child: Text(
                  name.length > 10 ? name.substring(0, 10) : name,
                  style: const TextStyle(fontSize: 7, fontWeight: FontWeight.w300, letterSpacing: 0.8, color: Colors.white),
                  maxLines: 1,
                ),
              ),
              Icon(Icons.open_in_full, size: 7, color: Colors.white.withOpacity(0.4)),
            ]),
          ),
        ],
      ),
    );
  }
}

// ─── Dot pulsant ──────────────────────────────────────────────────────────────
class _PulsingDot extends StatefulWidget {
  final Color color;
  const _PulsingDot({required this.color});

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1600))..repeat();
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        final t = Curves.easeOut.transform(_ctrl.value);
        return SizedBox(
          width: 20, height: 20,
          child: Stack(alignment: Alignment.center, children: [
            // Anneau
            Container(
              width: 8 + t * 14, height: 8 + t * 14,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: widget.color.withOpacity((1 - t) * 0.7), width: 1),
              ),
            ),
            // Centre
            Container(
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white,
                border: Border.all(color: widget.color, width: 1.5),
              ),
            ),
          ]),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Carte ferme interactive : image draggable + zoom + pins fixes par dessus
// ═══════════════════════════════════════════════════════════════════════════════
class _InteractiveFarmCard extends StatefulWidget {
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
  final void Function(BuildContext, String, String) onPhotoTap;

  const _InteractiveFarmCard({
    required this.farm, required this.farmId, required this.name,
    required this.location, required this.image, required this.isOwner,
    required this.dark, required this.cropsFuture, required this.onEdit,
    required this.onDelete, required this.onParcelles, required this.onPhotoTap,
  });

  @override
  State<_InteractiveFarmCard> createState() => _InteractiveFarmCardState();
}

class _InteractiveFarmCardState extends State<_InteractiveFarmCard>
    {
  // Suivi drag pins
  bool _hasInteracted = false;

  // Positions draggables des tooltips — clé = index parcelle
  // Stockées en offsets absolus pixels dans le repère de la carte
  final Map<int, Offset> _pinOffsets = {};
  // Indique quel pin est en cours de drag (pour z-order)
  int? _draggingPin;

  @override
  void initState() {
    super.initState();

  }

  @override
  void dispose() {
    super.dispose();
  }

  static const _dotZones = [
    (dx: 0.22, dy: 0.28),
    (dx: 0.58, dy: 0.20),
    (dx: 0.78, dy: 0.40),
    (dx: 0.16, dy: 0.55),
    (dx: 0.62, dy: 0.54),
    (dx: 0.40, dy: 0.38),
  ];

  @override
  Widget build(BuildContext context) {
    final accent = AppColors.accent;

    return AspectRatio(
      aspectRatio: 3 / 2,
      child: ClipRect(
        child: Stack(children: [

          // ── Image + pins (Stack simple, pas de zoom) ──────────────
          Positioned.fill(child: Stack(fit: StackFit.expand, children: [

            // Image
            widget.image != null && widget.image!.isNotEmpty
                ? Image.network(widget.image!, fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => _placeholder())
                : _placeholder(),

            // Gradient bas
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

            // Vignette radiale
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center, radius: 1.0,
                    colors: [Colors.transparent, Colors.black.withOpacity(0.22)],
                  ),
                ),
              ),
            ),

            // Pins draggables
            FutureBuilder<List<dynamic>>(
              future: widget.cropsFuture,
              builder: (ctx, snap) {
                if ((snap.data ?? []).isEmpty) return const SizedBox.shrink();
                final crops = snap.data!.take(6).toList();
                return LayoutBuilder(builder: (_, box) {
                  final w = box.maxWidth;
                  final h = box.maxHeight;
                  return Stack(children: [
                    for (var i = 0; i < crops.length && i < _dotZones.length; i++)
                      if (i != _draggingPin)
                        _buildPin(crops[i] as Map<String, dynamic>, _dotZones[i].dx,
                            _dotZones[i].dy, w, h, accent, ctx, i),
                    if (_draggingPin != null && _draggingPin! < crops.length)
                      _buildPin(crops[_draggingPin!] as Map<String, dynamic>, _dotZones[_draggingPin!].dx,
                          _dotZones[_draggingPin!].dy, w, h, accent, ctx, _draggingPin!),
                  ]);
                });
              },
            ),
          ])),

          // ── Overlays fixes ─────────────────────────────────────────

          // Gradient bas pour le nom (toujours visible)
          Positioned(
            left: 0, right: 0, bottom: 0, height: 80,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter, end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.90)],
                ),
              ),
            ),
          ),

          // Nom + lieu + bouton parcelles
          Positioned(
            left: 0, right: 0, bottom: 0,
            child: GestureDetector(
              onTap: widget.onParcelles,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                        Text(widget.name.toUpperCase(),
                            maxLines: 1, overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w300, letterSpacing: 2.5, color: Colors.white)),
                        if (widget.location.isNotEmpty) ...[
                          const SizedBox(height: 4),
                          Row(children: [
                            const Icon(Icons.place_outlined, size: 10, color: Colors.white54),
                            const SizedBox(width: 3),
                            Expanded(child: Text(widget.location,
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w300, letterSpacing: 0.4, color: Colors.white54))),
                          ]),
                        ],
                      ]),
                    ),
                    GestureDetector(
                      onTap: widget.onParcelles,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.50),
                          border: Border.all(color: Colors.white.withOpacity(0.25), width: 0.5),
                        ),
                        child: Row(mainAxisSize: MainAxisSize.min, children: const [
                          Text('PARCELLES', style: TextStyle(fontSize: 8, fontWeight: FontWeight.w300, letterSpacing: 1.4, color: Colors.white70)),
                          SizedBox(width: 5),
                          Icon(Icons.arrow_forward_ios, size: 8, color: Colors.white54),
                        ]),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Boutons owner (haut droite)
          if (widget.isOwner)
            Positioned(top: 10, right: 10, child: Row(children: [
              _iconBtn(Icons.edit_outlined, accent, widget.onEdit),
              const SizedBox(width: 6),
              _iconBtn(Icons.delete_outline, AppColors.error, widget.onDelete),
            ])),

          // Badge satellite (haut gauche)
          Positioned(
            top: 10, left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              color: Colors.black.withOpacity(0.42),
              child: Row(mainAxisSize: MainAxisSize.min, children: const [
                Icon(Icons.satellite_alt_outlined, size: 9, color: Colors.white38),
                SizedBox(width: 4),
                Text('VUE AÉRIENNE', style: TextStyle(fontSize: 7, fontWeight: FontWeight.w300, letterSpacing: 1.2, color: Colors.white38)),
              ]),
            ),
          ),
        ]),
      ),
    );
  }

  Widget _placeholder() => Container(
    color: widget.dark ? AppColors.darkCardBg : AppColors.lightCardBg,
    child: Center(child: Icon(Icons.landscape_outlined, size: 36,
        color: (widget.dark ? Colors.white : Colors.black).withOpacity(0.08))),
  );

  /// Calcule la position initiale du tooltip (première fois)
  Offset _defaultTooltipOffset(int idx, double dx, double dy,
      double w, double h, bool hasPhoto) {
    final px = dx * w;
    final py = dy * h;
    final alignRight = dx > 0.5;
    final alignTop   = dy < 0.5;
    const tw = 92.0; const th = 80.0;
    const ttW = 100.0; const ttH = 26.0;
    const gap = 14.0; const lineLen = 28.0;
    if (hasPhoto) {
      final l = alignRight ? (px - gap - tw).clamp(2.0, w - tw - 2) : (px + gap).clamp(2.0, w - tw - 2);
      final t = alignTop   ? (py - lineLen - th).clamp(2.0, h - th - 36) : (py + lineLen).clamp(2.0, h - th - 36);
      return Offset(l, t);
    } else {
      final l = alignRight ? (px - gap - ttW).clamp(2.0, w - ttW - 2) : (px + gap).clamp(2.0, w - ttW - 2);
      final t = alignTop   ? (py - lineLen - ttH).clamp(2.0, h - ttH - 36) : (py + lineLen).clamp(2.0, h - ttH - 36);
      return Offset(l, t);
    }
  }

  Widget _buildPin(Map<String, dynamic> crop, double dx, double dy,
      double w, double h, Color accent, BuildContext ctx, int idx) {
    final name     = (crop['crop_name'] ?? '').toString();
    final photo    = (crop['image_url'] ?? crop['photo_url'] ?? crop['photo'] ?? '') as String;
    final hasPhoto = photo.isNotEmpty;
    final px = dx * w;
    final py = dy * h;
    const tw = 92.0; const th = 80.0;
    const ttW = 100.0; const ttH = 26.0;

    // Initialise l'offset la première fois
    _pinOffsets.putIfAbsent(idx, () => _defaultTooltipOffset(idx, dx, dy, w, h, hasPhoto));
    final offset = _pinOffsets[idx]!;
    final isDragging = _draggingPin == idx;

    // Connecteur dynamique : du dot vers le coin du tooltip
    final dotPos   = Offset(px, py);
    final tipCenter = Offset(offset.dx + (hasPhoto ? tw : ttW) / 2, offset.dy + (hasPhoto ? th : ttH) / 2);

    return Stack(clipBehavior: Clip.none, children: [
      // ── Connecteur dynamique dot → tooltip ─────────────────────
      Positioned.fill(
        child: CustomPaint(
          painter: _DynamicLinePainter(from: dotPos, to: tipCenter, dragging: isDragging),
        ),
      ),

      // ── Dot pulsant (fixe, ancré à la position relative) ───────
      Positioned(
        left: px - 5, top: py - 5,
        child: _PulsingDot(color: isDragging ? accent : Colors.white),
      ),

      // ── Tooltip DRAGGABLE ───────────────────────────────────────
      Positioned(
        left: offset.dx, top: offset.dy,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: hasPhoto && !isDragging ? () => widget.onPhotoTap(ctx, name, photo) : null,
          onPanStart: (_) => setState(() => _draggingPin = idx),
          onPanUpdate: (details) {
            setState(() {
              final newOffset = _pinOffsets[idx]! + details.delta;
              // Clamper dans la carte
              final maxLeft = w - (hasPhoto ? tw : ttW) - 2;
              final maxTop  = h - (hasPhoto ? th : ttH) - 2;
              _pinOffsets[idx] = Offset(
                newOffset.dx.clamp(2.0, maxLeft),
                newOffset.dy.clamp(2.0, maxTop),
              );
            });
          },
          onPanEnd: (_) => setState(() => _draggingPin = null),
          child: AnimatedScale(
            scale: isDragging ? 1.08 : 1.0,
            duration: const Duration(milliseconds: 150),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              decoration: BoxDecoration(
                boxShadow: isDragging
                    ? [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 16, spreadRadius: 1)]
                    : [BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 6)],
              ),
              child: hasPhoto
                  ? _PhotoPin(name: name, photo: photo, accent: isDragging ? accent : accent.withOpacity(0.6))
                  : Container(
                      width: ttW,
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(isDragging ? 0.88 : 0.70),
                        border: Border.all(
                          color: isDragging ? accent.withOpacity(0.6) : Colors.white.withOpacity(0.18),
                          width: isDragging ? 1 : 0.5,
                        ),
                      ),
                      child: Text(name.length > 13 ? name.substring(0, 13) : name,
                          style: const TextStyle(fontSize: 8, fontWeight: FontWeight.w300, letterSpacing: 0.8, color: Colors.white),
                          maxLines: 1, overflow: TextOverflow.ellipsis),
                    ),
            ),
          ),
        ),
      ),
    ]);
  }

  Widget _iconBtn(IconData icon, Color color, VoidCallback onTap) => GestureDetector(
    onTap: onTap,
    child: Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(color: color.withOpacity(0.88), borderRadius: BorderRadius.circular(4)),
      child: Icon(icon, color: Colors.white, size: 15),
    ),
  );
}