import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/screens/farm/tab/farm_tab.dart';
import 'package:mbaymi/screens/farm/parcel_screen.dart';
import 'package:mbaymi/screens/livestock/edit_livestock_screen.dart';
import 'package:mbaymi/screens/notebook/project_notebook_list_screen.dart';
import 'package:mbaymi/screens/home_screen.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/widgets/skeleton_loader.dart';
import 'package:mbaymi/services/traceability_export_service.dart';
import 'dart:async';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — Zara-inspired luxury minimalism
// ─────────────────────────────────────────────────────────────────────────────
class _Z {
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
  static const double s64 = 64;

  static const String font = 'Georgia';

  // Optimization: Pre-built base text styles to prevent re-instantiation
  static const TextStyle _headingBase = TextStyle(
    fontFamily: font,
    fontSize: 13,
    fontWeight: FontWeight.w400,
    letterSpacing: 3,
  );

  static const TextStyle _labelBase = TextStyle(
    fontFamily: font,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    letterSpacing: 2.5,
  );

  static const TextStyle _bodyBase = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w300,
    letterSpacing: 0.3,
    height: 1.6,
  );

  static const TextStyle _statBase = TextStyle(
    fontFamily: font,
    fontSize: 22,
    fontWeight: FontWeight.w300,
    letterSpacing: 1,
  );

  static TextStyle heading(Color c) => _headingBase.copyWith(color: c);
  static TextStyle label(Color c) => _labelBase.copyWith(color: c);
  static TextStyle body(Color c) => _bodyBase.copyWith(color: c);
  static TextStyle stat(Color c) => _statBase.copyWith(color: c);
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class UserProfileScreen extends StatefulWidget {
  final int userId;
  final bool isDarkMode;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.isDarkMode,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  late Future<Map<String, dynamic>> _profileFuture;
  late Future<List<dynamic>> _farmsFuture;
  late Future<List<dynamic>> _livestockFuture;
  int _tab = 0;
  final _picker = ImagePicker();
  
  static final Map<int, Future<Map<String, dynamic>>> _globalProfileCache = {};
  static final Map<int, Future<List<dynamic>>> _globalFarmsCache = {};
  static final Map<int, Future<List<dynamic>>> _globalLivestockCache = {};
  
  late StreamSubscription<void> _farmPostSub;
  late StreamSubscription<void> _profileUpdateSub;

  bool get _isOwn =>
      widget.userId == (AuthService.currentSession?.userId ?? 0);

  @override
  void initState() {
    super.initState();
    
    _profileFuture = _getOrCreateProfile();
    _farmsFuture = _getOrCreateFarms();
    _livestockFuture = _getOrCreateLivestock();
    
    _farmPostSub = ApiService.onFarmPostCreated.listen((_) {
      if (mounted) _refreshData();
    });
    
    _profileUpdateSub = ApiService.onProfileUpdated.listen((_) {
      if (mounted) _refreshData();
    });
  }

  @override
  void dispose() {
    _farmPostSub.cancel();
    _profileUpdateSub.cancel();
    super.dispose();
  }

  @override
  void didUpdateWidget(UserProfileScreen old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId) {
      _profileFuture = _getOrCreateProfile();
      _farmsFuture = _getOrCreateFarms();
      _livestockFuture = _getOrCreateLivestock();
      setState(() {});
    }
  }
  
  Future<Map<String, dynamic>> _getOrCreateProfile() {
    if (!_globalProfileCache.containsKey(widget.userId)) {
      _globalProfileCache[widget.userId] = _loadProfile();
    }
    return _globalProfileCache[widget.userId]!;
  }
  
  Future<List<dynamic>> _getOrCreateFarms() {
    if (!_globalFarmsCache.containsKey(widget.userId)) {
      _globalFarmsCache[widget.userId] = _loadFarms();
    }
    return _globalFarmsCache[widget.userId]!;
  }
  
  Future<List<dynamic>> _getOrCreateLivestock() {
    if (!_globalLivestockCache.containsKey(widget.userId)) {
      _globalLivestockCache[widget.userId] = _loadLivestock();
    }
    return _globalLivestockCache[widget.userId]!;
  }
  
  void _refreshData() {
    _globalProfileCache.remove(widget.userId);
    _globalFarmsCache.remove(widget.userId);
    _globalLivestockCache.remove(widget.userId);
    
    if (mounted) {
      setState(() {
        _profileFuture = _getOrCreateProfile();
        _farmsFuture = _getOrCreateFarms();
        _livestockFuture = _getOrCreateLivestock();
      });
    }
  }
  
  Future<Map<String, dynamic>> _loadProfile() async {
    final vid = AuthService.currentSession?.userId ?? 0;
    return await ApiService.getUserProfile(widget.userId,
        viewerId: vid > 0 ? vid : null);
  }
  
  Future<List<dynamic>> _loadFarms() async {
    return await ApiService.getPublicUserFarms(widget.userId);
  }
  
  Future<List<dynamic>> _loadLivestock() async {
    return _isOwn
        ? ApiService.getUserLivestock(widget.userId)
        : ApiService.getPublicUserLivestock(widget.userId);
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              letterSpacing: 0.5,
              fontSize: 12,
              color: Colors.white)),
      backgroundColor: error ? AppColors.error : Colors.black87,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      duration: Duration(milliseconds: error ? 2500 : 1200),
    ));
  }

  Future<void> _exportTraceability() {
    return TraceabilityExportService.showExportMenu(
      context: context,
      title: 'Traçabilité du profil',
      loadSections: () async {
        final profile = await _profileFuture;
        final farms = await _farmsFuture;
        final livestock = await _livestockFuture;
        final sections = <TraceabilitySection>[
          TraceabilitySection(title: 'Profil utilisateur', rows: [profile]),
          TraceabilitySection(
            title: 'Fermes',
            rows: farms.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
          ),
          TraceabilitySection(
            title: 'Élevage',
            rows: livestock.map((item) => Map<String, dynamic>.from(item as Map)).toList(),
          ),
        ];

        for (final farmValue in farms) {
          final farm = Map<String, dynamic>.from(farmValue as Map);
          final farmId = int.tryParse('${farm['id']}');
          if (farmId == null) continue;
          final crops = await ApiService.getFarmCrops(farmId);
          for (final cropValue in crops) {
            final crop = Map<String, dynamic>.from(cropValue as Map);
            final cropId = int.tryParse('${crop['id']}');
            if (cropId == null) continue;
            final results = await Future.wait([
              ApiService.getActivitiesForCrop(cropId),
              ApiService.listInputsForCrop(cropId),
              ApiService.listTransactionsForCrop(cropId),
              ApiService.getCropProblems(cropId),
            ]);
            final cropName = crop['name'] ?? crop['crop_name'] ?? cropId;
            sections.addAll([
              TraceabilitySection(
                title: 'Activités · $cropName',
                rows: (results[0] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList(),
              ),
              TraceabilitySection(
                title: 'Intrants · $cropName',
                rows: (results[1] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList(),
              ),
              TraceabilitySection(
                title: 'Finances · $cropName',
                rows: (results[2] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList(),
              ),
              TraceabilitySection(
                title: 'Maladies · $cropName',
                rows: (results[3] as List).map((item) => Map<String, dynamic>.from(item as Map)).toList(),
              ),
            ]);
          }
        }
        return sections;
      },
    );
  }

  // ── Actions ──────────────────────────────────────────────────────────────
  Future<void> _uploadAvatar() async {
    final file = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1024);
    if (file == null) return;
    _snack('Téléchargement...');
    try {
      final url = await ApiService.uploadImageToCloudinary(file);
      if (url == null) throw Exception('Upload échoué');
      await ApiService.updateUserProfile(
          userId: widget.userId, profileImage: url);
      _refreshData();
      _snack('Photo mise à jour');
    } catch (e) {
      _snack('Erreur: $e', error: true);
    }
  }

  Future<void> _updateProfile(
      String name, String email, String phone) async {
    if (name.isEmpty && email.isEmpty && phone.isEmpty) {
      _snack('Aucune modification', error: true);
      return;
    }
    try {
      await ApiService.updateUserProfile(
        userId: widget.userId,
        name: name.isNotEmpty ? name : null,
        email: email.isNotEmpty ? email : null,
        phone: phone.isNotEmpty ? phone : null,
      );
      _refreshData();
      _snack('Profil mis à jour');
    } catch (e) {
      _snack('Erreur: $e', error: true);
    }
  }

  Future<void> _changePassword(
      String current, String next, String confirm) async {
    if (current.isEmpty || next.isEmpty) {
      _snack('Champs requis', error: true);
      return;
    }
    if (next != confirm) {
      _snack('Mots de passe différents', error: true);
      return;
    }
    if (next.length < 6) {
      _snack('Minimum 6 caractères', error: true);
      return;
    }
    try {
      await ApiService.changePassword(
          currentPassword: current, newPassword: next);
      _snack('Mot de passe modifié');
    } catch (e) {
      _snack('Erreur: $e', error: true);
    }
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────
  void _showEditDialog(String name, String email, String phone) {
    showDialog(
      context: context,
      builder: (_) => _EditProfileDialog(
        isDark: widget.isDarkMode,
        initialName: name,
        initialEmail: email,
        initialPhone: phone,
        onConfirm: _updateProfile,
        onChangePasswordTap: () => _showPasswordDialog(),
      ),
    );
  }

  void _showPasswordDialog() {
    showDialog(
      context: context,
      builder: (_) => _ChangePasswordDialog(
        isDark: widget.isDarkMode,
        onConfirm: _changePassword,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => _ZaraDialog(
        isDark: widget.isDarkMode,
        title: 'SE DÉCONNECTER',
        content: Text('Voulez-vous vraiment vous déconnecter ?',
            style: _Z.body(AppColors.getSecondaryTextColor(widget.isDarkMode))),
        confirmLabel: 'DÉCONNECTER',
        confirmColor: Colors.red.shade700,
        onConfirm: () async {
          await ApiService.logout();
          if (mounted) {
            Navigator.of(context).pushAndRemoveUntil(
              MaterialPageRoute(builder: (_) => const HomeScreen()),
              (_) => false,
            );
          }
        },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dark = widget.isDarkMode;
    final bg = AppColors.getBgColor(dark);
    final text = AppColors.getTextColor(dark);
    final sub = AppColors.getSecondaryTextColor(dark);

    return Scaffold(
      backgroundColor: bg,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('PROFIL', style: _Z.label(text)),
        iconTheme: IconThemeData(color: text),
        actions: [
          IconButton(
            tooltip: 'Télécharger la traçabilité',
            icon: Icon(Icons.download_outlined, color: text, size: 20),
            onPressed: _isOwn ? _exportTraceability : null,
          ),
          Padding(
            padding: const EdgeInsets.only(right: _Z.s16),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showLogoutDialog();
              },
              child: Text('SORTIR', style: _Z.label(sub)),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => _refreshData(),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
          builder: (ctx, snap) {
            return AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              transitionBuilder: (child, animation) =>
                  FadeTransition(opacity: animation, child: child),
              child: _buildProfileContent(dark, snap),
            );
          },
        ),
      ),
    );
  }

  Widget _buildProfileContent(
    bool dark,
    AsyncSnapshot<Map<String, dynamic>> snap,
  ) {
    if (snap.connectionState == ConnectionState.waiting) {
      return SkeletonPageLoader(
        isDarkMode: dark,
        cardCount: 4,
        key: const ValueKey('skeleton'),
      );
    }

    if (snap.hasError) {
      return Center(
        key: const ValueKey('error'),
        child: Text(
          'Erreur de chargement',
          style: _Z.body(AppColors.getSecondaryTextColor(dark)),
        ),
      );
    }

    final p = snap.data!;
    final name = (p['name'] as String?) ?? 'Utilisateur';
    final email = (p['email'] as String?) ?? '';
    final avatar = p['profile_image'] as String?;
    final followers = p['total_followers'] ?? 0;
    final posts = p['total_posts'] ?? 0;

    return SingleChildScrollView(
      key: const ValueKey('content'),
      physics: const AlwaysScrollableScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(dark, name, email, avatar, followers, posts),

          if (_isOwn)
            Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: _Z.s24, vertical: _Z.s8),
                  child: _ZaraActionTile(
                    label: 'CRÉER UN POST',
                    icon: Icons.add,
                    dark: dark,
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => FarmTab(userId: widget.userId))),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: _Z.s24, vertical: _Z.s8),
                  child: _ZaraActionTile(
                    label: 'MON CAHIER',
                    icon: Icons.description_outlined,
                    dark: dark,
                    onTap: () async {
                      HapticFeedback.lightImpact();
                      // Optimisation: Récupération dynamique de la première ferme si disponible
                      String targetFarmId = '1';
                      try {
                        final farms = await _farmsFuture;
                        if (farms.isNotEmpty && farms.first['id'] != null) {
                          targetFarmId = farms.first['id'].toString();
                        }
                      } catch (_) {}

                      if (!mounted) return;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ProjectNotebookListScreen(
                            farmId: targetFarmId,
                            userId: widget.userId.toString(),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),

          const SizedBox(height: _Z.s32),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: _Z.s24),
            child: Text('MES RESSOURCES',
                style: _Z.label(AppColors.getSecondaryTextColor(dark))),
          ),
          const SizedBox(height: _Z.s16),

          _buildTabs(dark),

          Padding(
            padding: const EdgeInsets.all(_Z.s24),
            child: _tab == 0 ? _buildFarms(dark) : _buildLivestock(dark),
          ),

          const SizedBox(height: _Z.s64),
        ],
      ),
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────────
  Widget _buildHero(bool dark, String name, String email, String? avatar,
      int followers, int posts) {
    final text = AppColors.getTextColor(dark);
    final sub = AppColors.getSecondaryTextColor(dark);
    final border = AppColors.getBorderColor(dark);
    final bg = AppColors.getBgColor(dark);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 64,
        bottom: _Z.s32,
        left: _Z.s24,
        right: _Z.s24,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _isOwn
                    ? () {
                        HapticFeedback.lightImpact();
                        _uploadAvatar();
                      }
                    : null,
                child: Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: border, width: 1),
                      ),
                      child: ClipOval(
                        child: avatar != null && avatar.isNotEmpty
                            ? Image.network(
                                avatar,
                                fit: BoxFit.cover,
                                cacheWidth: 200, // Mémoire cache optimisée
                                cacheHeight: 200,
                                errorBuilder: (_, __, ___) =>
                                    _defaultAvatar(name, dark),
                              )
                            : _defaultAvatar(name, dark),
                      ),
                    ),
                    if (_isOwn)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: text,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add, size: 12, color: bg),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              _buildStat(followers.toString(), 'ABONNÉS', dark),
              const SizedBox(width: _Z.s32),
              _buildStat(posts.toString(), 'POSTS', dark),
            ],
          ),

          const SizedBox(height: _Z.s20),

          GestureDetector(
            onTap: _isOwn
                ? () {
                    HapticFeedback.lightImpact();
                    _showEditDialog(name, email, '');
                  }
                : null,
            child: Row(
              children: [
                Text(name.toUpperCase(), style: _Z.heading(text)),
                if (_isOwn) ...[
                  const SizedBox(width: _Z.s8),
                  Icon(Icons.edit, size: 12, color: sub),
                ],
              ],
            ),
          ),
          const SizedBox(height: _Z.s4),
          Text(email, style: _Z.body(sub)),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: _Z.stat(AppColors.getTextColor(dark))),
        const SizedBox(height: 2),
        Text(label, style: _Z.label(AppColors.getSecondaryTextColor(dark))),
      ],
    );
  }

  Widget _defaultAvatar(String name, bool dark) {
    return Container(
      color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontFamily: _Z.font,
            fontSize: 28,
            fontWeight: FontWeight.w300,
            color: AppColors.getTextColor(dark),
          ),
        ),
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────
  Widget _buildTabs(bool dark) {
    const tabs = ['FERMES', 'BÉTAIL'];
    final icons = [Icons.landscape_outlined, Icons.pets_outlined];
    final border = AppColors.getBorderColor(dark);
    final text = AppColors.getTextColor(dark);
    final sub = AppColors.getSecondaryTextColor(dark);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: border, width: 0.5),
          bottom: BorderSide(color: border, width: 0.5),
        ),
      ),
      child: Row(
        children: List.generate(
          tabs.length,
          (i) => Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _tab = i);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: _Z.s16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _tab == i ? text : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icons[i],
                        size: 14, color: _tab == i ? text : sub),
                    const SizedBox(width: _Z.s8),
                    Text(
                      tabs[i],
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w400,
                        color: _tab == i ? text : sub,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Farms ─────────────────────────────────────────────────────────────────
  Widget _buildFarms(bool dark) {
    return FutureBuilder<List<dynamic>>(
      future: _farmsFuture,
      builder: (_, snap) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: _buildFarmContent(dark, snap),
        );
      },
    );
  }

  Widget _buildFarmContent(bool dark, AsyncSnapshot<List<dynamic>> snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return SkeletonListLoader(
        itemCount: 3,
        isDarkMode: dark,
        itemHeight: 80,
        key: const ValueKey('farms_skeleton'),
      );
    }
    
    final farms = snap.data ?? [];
    if (farms.isEmpty) return _empty('Aucune ferme', dark);

    // Optimisation UI/UX & performance : ListView.builder au lieu d'une Column exhaustive
    return ListView.builder(
      key: const ValueKey('farms_content'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: farms.length,
      itemBuilder: (context, index) {
        final farm = farms[index] as Map<String, dynamic>;
        final id = farm['id'] as int?;
        return _ZaraResourceTile(
          title: (farm['name'] as String?) ?? 'Ferme',
          subtitle: (farm['location'] as String?) ?? '',
          image: farm['image_url'] as String?,
          dark: dark,
          onTap: id == null
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => ParcelScreen(
                        farmId: id,
                        userId: widget.userId,
                        farmOwnerId: widget.userId,
                        readOnly: false,
                      ))),
        );
      },
    );
  }

  // ── Livestock ─────────────────────────────────────────────────────────────
  Widget _buildLivestock(bool dark) {
    return FutureBuilder<List<dynamic>>(
      future: _livestockFuture,
      builder: (_, snap) {
        return AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          transitionBuilder: (child, animation) =>
              FadeTransition(opacity: animation, child: child),
          child: _buildLivestockContent(dark, snap),
        );
      },
    );
  }

  Widget _buildLivestockContent(bool dark, AsyncSnapshot<List<dynamic>> snap) {
    if (snap.connectionState == ConnectionState.waiting) {
      return SkeletonListLoader(
        itemCount: 3,
        isDarkMode: dark,
        itemHeight: 80,
        key: const ValueKey('livestock_skeleton'),
      );
    }
    
    final animals = snap.data ?? [];
    if (animals.isEmpty) return _empty('Aucun bétail', dark);

    // Optimisation UI/UX & performance : ListView.builder au lieu d'une Column
    return ListView.builder(
      key: const ValueKey('livestock_content'),
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: animals.length,
      itemBuilder: (context, index) {
        final animal = animals[index] as Map<String, dynamic>;
        final id = animal['id'] as int?;
        final qty = animal['quantity'] as int? ?? 1;
        
        // Dynamic casting sécurisé du champ photos
        String? photo = animal['image_url'] as String?;
        if (photo == null && animal['photos'] is List && (animal['photos'] as List).isNotEmpty) {
          photo = (animal['photos'] as List).first.toString();
        }

        return _ZaraResourceTile(
          title: (animal['animal_type'] as String?) ?? 'Animal',
          subtitle: (animal['breed'] as String?) ?? '',
          badge: 'x$qty',
          image: photo,
          dark: dark,
          onTap: id == null
              ? null
              : () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => EditLivestockScreen(
                          livestockId: id, livestock: animal))),
        );
      },
    );
  }

  Widget _empty(String msg, bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _Z.s48),
      child: Center(
        child: Text(
          msg.toUpperCase(),
          style: _Z.label(AppColors.getSecondaryTextColor(dark)),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// DIALOG STATEFUL IMPLEMENTATIONS (Correction Fuite Mémoire TextEditingController)
// ─────────────────────────────────────────────────────────────────────────────

class _EditProfileDialog extends StatefulWidget {
  final bool isDark;
  final String initialName;
  final String initialEmail;
  final String initialPhone;
  final Function(String, String, String) onConfirm;
  final VoidCallback onChangePasswordTap;

  const _EditProfileDialog({
    required this.isDark,
    required this.initialName,
    required this.initialEmail,
    required this.initialPhone,
    required this.onConfirm,
    required this.onChangePasswordTap,
  });

  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  late final TextEditingController _nameC;
  late final TextEditingController _emailC;
  late final TextEditingController _phoneC;

  @override
  void initState() {
    super.initState();
    _nameC = TextEditingController(text: widget.initialName);
    _emailC = TextEditingController(text: widget.initialEmail);
    _phoneC = TextEditingController(text: widget.initialPhone);
  }

  @override
  void dispose() {
    _nameC.dispose();
    _emailC.dispose();
    _phoneC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ZaraDialog(
      isDark: widget.isDark,
      title: 'MODIFIER LE PROFIL',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZaraField(controller: _nameC, label: 'NOM', dark: widget.isDark),
          const SizedBox(height: _Z.s16),
          _ZaraField(
            controller: _emailC,
            label: 'EMAIL',
            dark: widget.isDark,
            type: TextInputType.emailAddress,
          ),
          const SizedBox(height: _Z.s16),
          _ZaraField(
            controller: _phoneC,
            label: 'TÉLÉPHONE',
            dark: widget.isDark,
            type: TextInputType.phone,
          ),
          const SizedBox(height: _Z.s24),
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              widget.onChangePasswordTap();
            },
            child: Row(
              children: [
                const SizedBox(width: 20, height: 1),
                Expanded(
                    child: Container(height: 0.5, color: Colors.red.shade300)),
                const SizedBox(width: _Z.s8),
                Text('CHANGER MOT DE PASSE',
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        color: Colors.red.shade400)),
                const SizedBox(width: _Z.s8),
                Expanded(
                    child: Container(height: 0.5, color: Colors.red.shade300)),
              ],
            ),
          ),
        ],
      ),
      onConfirm: () {
        widget.onConfirm(
          _nameC.text.trim(),
          _emailC.text.trim(),
          _phoneC.text.trim(),
        );
      },
    );
  }
}

class _ChangePasswordDialog extends StatefulWidget {
  final bool isDark;
  final Function(String, String, String) onConfirm;

  const _ChangePasswordDialog({
    required this.isDark,
    required this.onConfirm,
  });

  @override
  State<_ChangePasswordDialog> createState() => _ChangePasswordDialogState();
}

class _ChangePasswordDialogState extends State<_ChangePasswordDialog> {
  late final TextEditingController _curC;
  late final TextEditingController _newC;
  late final TextEditingController _conC;

  @override
  void initState() {
    super.initState();
    _curC = TextEditingController();
    _newC = TextEditingController();
    _conC = TextEditingController();
  }

  @override
  void dispose() {
    _curC.dispose();
    _newC.dispose();
    _conC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ZaraDialog(
      isDark: widget.isDark,
      title: 'MOT DE PASSE',
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _ZaraField(
              controller: _curC, label: 'ACTUEL', dark: widget.isDark, obscure: true),
          const SizedBox(height: _Z.s16),
          _ZaraField(
              controller: _newC, label: 'NOUVEAU', dark: widget.isDark, obscure: true),
          const SizedBox(height: _Z.s16),
          _ZaraField(
              controller: _conC, label: 'CONFIRMER', dark: widget.isDark, obscure: true),
        ],
      ),
      onConfirm: () {
        widget.onConfirm(
          _curC.text.trim(),
          _newC.text.trim(),
          _conC.text.trim(),
        );
      },
      confirmLabel: 'MODIFIER',
      confirmColor: Colors.red.shade700,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

class _ZaraResourceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? image;
  final String? badge;
  final bool dark;
  final VoidCallback? onTap;

  const _ZaraResourceTile({
    required this.title,
    required this.subtitle,
    required this.dark,
    this.image,
    this.badge,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final text = AppColors.getTextColor(dark);
    final sub = AppColors.getSecondaryTextColor(dark);
    final border = AppColors.getBorderColor(dark);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: _Z.s12),
        padding: const EdgeInsets.all(_Z.s16),
        decoration: BoxDecoration(
          border: Border.all(color: border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                border: Border.all(color: border, width: 0.5),
              ),
              child: image != null && image!.isNotEmpty
                  ? Image.network(
                      image!,
                      fit: BoxFit.cover,
                      cacheWidth: 120, // Image cache resize
                      cacheHeight: 120,
                      errorBuilder: (_, __, ___) => Icon(
                        Icons.image_not_supported,
                        size: 18,
                        color: sub,
                      ),
                    )
                  : Icon(Icons.landscape_outlined, size: 18, color: sub),
            ),
            const SizedBox(width: _Z.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w400,
                      color: text,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 11,
                        letterSpacing: 0.3,
                        color: sub,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: _Z.s12),
              Text(
                badge!,
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1,
                  color: sub,
                ),
              ),
            ],
            const SizedBox(width: _Z.s8),
            Icon(Icons.arrow_forward_ios, size: 12, color: sub),
          ],
        ),
      ),
    );
  }
}

class _ZaraActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool dark;
  final VoidCallback onTap;

  const _ZaraActionTile({
    required this.label,
    required this.icon,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppColors.getBorderColor(dark);
    final text = AppColors.getTextColor(dark);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: _Z.s16,
          horizontal: _Z.s20,
        ),
        decoration: BoxDecoration(
          border: Border.all(color: border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: text),
            const SizedBox(width: _Z.s12),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 2.5,
                fontWeight: FontWeight.w400,
                color: text,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ZaraField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool dark;
  final TextInputType type;
  final bool obscure;

  const _ZaraField({
    required this.controller,
    required this.label,
    required this.dark,
    this.type = TextInputType.text,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppColors.getBorderColor(dark);
    final text = AppColors.getTextColor(dark);
    final sub = AppColors.getSecondaryTextColor(dark);

    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      style: TextStyle(
        fontSize: 13,
        letterSpacing: 0.3,
        color: text,
        fontWeight: FontWeight.w300,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(fontSize: 10, letterSpacing: 2, color: sub),
        contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        enabledBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        focusedBorder: UnderlineInputBorder(
          borderSide: BorderSide(color: text, width: 1),
        ),
      ),
    );
  }
}

class _ZaraDialog extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget content;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final String confirmLabel;
  final Color? confirmColor;

  const _ZaraDialog({
    required this.isDark,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.onCancel,
    this.confirmLabel = 'CONFIRMER',
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBgColor(isDark);
    final text = AppColors.getTextColor(isDark);
    final sub = AppColors.getSecondaryTextColor(isDark);
    final border = AppColors.getBorderColor(isDark);
    final actionColor = confirmColor ?? text;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(_Z.s24),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 0.5),
        ),
        padding: const EdgeInsets.all(_Z.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 10,
                letterSpacing: 3,
                fontWeight: FontWeight.w400,
                color: text,
              ),
            ),
            const SizedBox(height: _Z.s4),
            Container(height: 0.5, color: border),
            const SizedBox(height: _Z.s24),
            content,
            const SizedBox(height: _Z.s32),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      onCancel?.call();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                        border: Border.all(color: border, width: 0.5),
                      ),
                      child: Center(
                        child: Text(
                          'ANNULER',
                          style: TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: sub,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _Z.s12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      color: actionColor,
                      child: Center(
                        child: Text(
                          confirmLabel,
                          style: const TextStyle(
                            fontSize: 10,
                            letterSpacing: 2,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}