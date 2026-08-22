import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:mbaymi/screens/farm/farm_detail_screen.dart';
import 'package:mbaymi/screens/livestock/animal_detail_screen_legacy.dart';
import 'package:mbaymi/screens/social/create_farm_post_dialog.dart';
import 'package:mbaymi/screens/social/profile_detail_screen.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/widgets/comments_bottom_sheet.dart';

// ── MODEL TYPÉ POUR LES POSTS ──────────────────────────────────────────────────

class FeedItem {
  final Map<String, dynamic> data;
  final DateTime timestamp;
  final bool isSubscription;

  const FeedItem({
    required this.data,
    required this.timestamp,
    required this.isSubscription,
  });

  factory FeedItem.fromPostMap(Map<String, dynamic> map, {bool isSub = false}) {
    return FeedItem(
      data: map,
      timestamp: DateTime.tryParse(map['created_at']?.toString() ?? '') ?? DateTime.now(),
      isSubscription: isSub,
    );
  }
}

// ── MAIN SCREEN ───────────────────────────────────────────────────────────────

class SocialFeedScreen extends StatefulWidget {
  const SocialFeedScreen({super.key});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen>
  with SingleTickerProviderStateMixin {
  late final int _userId;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  bool _headerVisible = true;
  late final AnimationController _headerController;
  final ValueNotifier<String> _feedFilter = ValueNotifier<String>('all');

  late StreamSubscription<void> _farmPostSub;
  late StreamSubscription<dynamic> _followChangedSub;
  late StreamSubscription<void> _livestockChangedSub;

  late Future<List<FeedItem>> _feedFuture;
  static final Map<String, Future<List<FeedItem>>> _globalFeedCache = {};

  Future<List<dynamic>>? _farmsFuture;
  Future<List<dynamic>>? _livestockFuture;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      value: 1,
      duration: const Duration(milliseconds: 260),
    );
    _userId = AuthService.currentSession?.userId ?? 0;
    _feedFuture = _getOrCreateFeed();

    if (_userId > 0) {
      _farmsFuture = ApiService.getUserFarms();
      _livestockFuture = _getOwnLivestockWithPhotos();
    }

    _setupListeners();
  }

  void _setupListeners() {
    _farmPostSub = ApiService.onFarmPostCreated.listen((_) {
      if (mounted) _refreshFeed();
    });
    _followChangedSub = ApiService.onFollowChanged.listen((_) {
      if (mounted) _refreshFeed();
    });
    _livestockChangedSub = ApiService.onLivestockChanged.listen((_) {
      if (mounted && _userId > 0) {
        setState(() {
          _livestockFuture = _getOwnLivestockWithPhotos();
        });
      }
    });
  }

  @override
  void dispose() {
    _headerController.dispose();
    _farmPostSub.cancel();
    _followChangedSub.cancel();
    _livestockChangedSub.cancel();
    _feedFilter.dispose();
    super.dispose();
  }

  // ── LOGIQUE DE CACHE ET CHARGEMENT ──────────────────────────────────────────

  Future<List<dynamic>> _getOwnLivestockWithPhotos() async {
    final livestock = await ApiService.getAllLivestockWithPhotos(userId: _userId);
    return livestock.where((animal) {
      if (animal is! Map) return false;
      final ownerId = animal['user_id'] ?? animal['owner_id'];
      final parsedId = ownerId is int ? ownerId : int.tryParse(ownerId?.toString() ?? '');
      return parsedId == _userId;
    }).toList();
  }

  Future<List<FeedItem>> _getOrCreateFeed() {
    final key = 'feed_$_userId';
    return _globalFeedCache.putIfAbsent(key, _loadCombinedFeed);
  }
  void _refreshFeed() {
    _globalFeedCache.remove('feed_$_userId');
    _livestockFuture = null;
    if (mounted) {
      setState(() {
        _feedFuture = _getOrCreateFeed();
      });
    }
  }

  Future<List<FeedItem>> _loadCombinedFeed() async {
    try {
      List<FeedItem> items = [];

      if (_userId > 0) {
        final results = await Future.wait<dynamic>([
          ApiService.getSubscriptionsFeed(userId: _userId),
          ApiService.getFarmPostsFeed(userId: _userId),
        ], eagerError: false);

        final subIds = ((results[0] as List?)?.map((p) => p['id'] as int).toSet()) ?? <int>{};
        final farmPosts = (results[1] as List?) ?? [];

        items = farmPosts.map((post) {
          final mapData = post as Map<String, dynamic>;
          final id = mapData['id'] as int? ?? 0;
          return FeedItem.fromPostMap(mapData, isSub: subIds.contains(id));
        }).toList();
      } else {
        final farmPosts = await ApiService.getFarmPostsFeed(userId: 0);
        items = farmPosts
            .map((post) => FeedItem.fromPostMap(post as Map<String, dynamic>, isSub: false))
            .toList();
      }

      items.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return items;
    } catch (e) {
      throw Exception('Erreur chargement: $e');
    }
  }

  String? _extractImageUrl(dynamic value) {
    if (value == null) return null;
    if (value is String) return value.isNotEmpty ? value : null;
    if (value is Map) {
      return (value['url'] ?? value['image_url'] ?? value['image'] ?? value['photo'] ?? value['src'])?.toString();
    }
    return null;
  }

  // ── UI BUILD ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bg = AppColors.getBgColor(isDark);
    final text = AppColors.getTextColor(isDark);

    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) => Scaffold(
      key: _scaffoldKey,
      backgroundColor: bg,
      appBar: PreferredSize(
        preferredSize: Size.fromHeight(kToolbarHeight * _headerController.value),
        child: ClipRect(
          child: OverflowBox(
            alignment: Alignment.topCenter,
            minHeight: 0,
            maxHeight: kToolbarHeight,
            child: Align(
              alignment: Alignment.topCenter,
              heightFactor: _headerController.value,
              child: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: text, size: 22),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'MBAYMI',
          style: TextStyle(
            color: text,
            fontSize: 16,
            fontWeight: FontWeight.w200,
            letterSpacing: 3,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(Icons.add, size: 22, color: text),
            tooltip: 'Nouveau post',
            onPressed: () => _onAddPostPressed(isDark),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(0.5),
          child: Container(height: 0.5, color: AppColors.getBorderColor(isDark)),
        ),
            ),
          ),
        ),
      ),
      ),
      drawer: _buildDrawer(isDark),
      body: _buildFeedBody(isDark),
      ),
    );
  }

  // ── DRAWER ──────────────────────────────────────────────────────────────────

  Widget _buildDrawer(bool isDark) {
    final bg = AppColors.getBgColor(isDark);
    final sub = AppColors.getSecondaryTextColor(isDark);
    final border = AppColors.getBorderColor(isDark);

    return Drawer(
      backgroundColor: bg,
      width: 260,
      child: SafeArea(
        child: ValueListenableBuilder<String>(
          valueListenable: _feedFilter,
          builder: (context, currentFilter, _) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                  child: CircleAvatar(
                    radius: 22,
                    backgroundColor: AppColors.primary.withOpacity(0.15),
                    child: const Icon(Icons.agriculture, color: AppColors.primary, size: 22),
                  ),
                ),
                _drawerLabel('NAVIGATION', sub),
                _drawerItem(Icons.home_outlined, Icons.home, 'TOUS', currentFilter == 'all', isDark, () => _setFilter('all')),
                _drawerItem(Icons.favorite_outline, Icons.favorite, 'ABONNÉS', currentFilter == 'following', isDark, () => _setFilter('following')),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  child: Divider(height: 1, color: border),
                ),
                _drawerLabel('DÉCOUVRIR', sub),
                _drawerItem(Icons.explore_outlined, Icons.explore, 'EXPLORER', false, isDark, () => Navigator.pop(context)),
                _drawerItem(Icons.local_fire_department_outlined, Icons.local_fire_department, 'TENDANCES', false, isDark, () => Navigator.pop(context)),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                  child: Text('MBAYMI v1.0', style: TextStyle(fontSize: 10, letterSpacing: 1, color: sub.withOpacity(0.4))),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  void _setFilter(String filter) {
    Navigator.pop(context);
    _feedFilter.value = filter;
  }

  Widget _drawerLabel(String label, Color color) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w500, letterSpacing: 2, color: color)),
      );

  Widget _drawerItem(IconData icon, IconData selIcon, String label, bool selected, bool isDark, VoidCallback onTap) {
    final text = AppColors.getTextColor(isDark);
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          border: selected ? const Border(left: BorderSide(color: AppColors.primary, width: 2.5)) : null,
        ),
        child: Row(
          children: [
            Icon(selected ? selIcon : icon, size: 18, color: selected ? AppColors.primary : text),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 1.5,
                color: selected ? AppColors.primary : text,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── FEED LIST ───────────────────────────────────────────────────────────────

  Widget _buildFeedBody(bool isDark) {
    return RefreshIndicator(
      onRefresh: () async => _refreshFeed(),
      color: AppColors.primary,
      backgroundColor: AppColors.getCardBgColor(isDark),
      child: NotificationListener<ScrollNotification>(
        onNotification: (notification) {
          if (notification.depth != 0 || notification.metrics.outOfRange) {
            return false;
          }
          if (notification is UserScrollNotification &&
              notification.direction != ScrollDirection.idle) {
            final shouldShow = notification.direction == ScrollDirection.forward &&
                notification.metrics.pixels > 0;
            if (shouldShow != _headerVisible && mounted) {
              setState(() => _headerVisible = shouldShow);
              _headerController.animateTo(
                shouldShow ? 1 : 0,
                curve: Curves.easeOutCubic,
              );
            }
          }
          return false;
        },
        child: FutureBuilder<List<FeedItem>>(
        future: _feedFuture,
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 1.5, valueColor: AlwaysStoppedAnimation(AppColors.primary)),
              ),
            );
          }
          if (snap.hasError) return _buildError(snap.error.toString(), isDark);

          final allItems = snap.data ?? [];

          return ValueListenableBuilder<String>(
            valueListenable: _feedFilter,
            builder: (context, filter, _) {
              final filteredItems = filter == 'following'
                  ? allItems.where((i) => i.isSubscription).toList()
                  : allItems;

              if (filteredItems.isEmpty) return _buildEmpty(isDark, filter == 'following');

              return ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: EdgeInsets.only(
                  bottom: MediaQuery.of(context).padding.bottom + 56,
                ),
                itemCount: filteredItems.length,
                itemBuilder: (_, i) => _buildPostCard(filteredItems[i], isDark),
              );
            },
          );
        },
        ),
      ),
    );
  }

  // ── ADD POST & SHEETS ───────────────────────────────────────────────────────

  Future<void> _onAddPostPressed(bool isDark) async {
    if (_userId <= 0) {
      _showSnack('Connectez-vous pour créer une publication', error: true);
      return;
    }

    final type = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.getBgColor(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => _buildTypeSheet(isDark),
    );
    if (type == null || !mounted) return;

    try {
      if (type == 'farm') {
        final farms = await _withLoading(() => (_farmsFuture ??= ApiService.getUserFarms()));
        if (!mounted) return;
        if (farms.isEmpty) { _showSnack('Aucune ferme. Créez-en une d\'abord.', error: true); return; }

        final selected = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.getBgColor(isDark),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (_) => _buildSelectionSheet(
            title: 'Sélectionnez une ferme',
            items: farms.map((f) => _SelectItem(
              id: (f['farm_id'] ?? f['id'] ?? 0) as int,
              name: (f['farm_name'] ?? f['name'] ?? 'Ferme') as String,
              imageUrl: _extractImageUrl(f['profile_image_farm'] ?? f['profile_image'] ?? f['image_url']),
              icon: Icons.landscape_outlined,
              extra: const {},
            )).toList(),
            isDark: isDark,
          ),
        );
        if (!mounted || selected == null) return;
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CreateFarmPostDialog(
            farmId: selected['id'] as int,
            farmName: selected['name'] as String,
            onPostCreated: _refreshFeed,
          ),
        ));
      } else {
        final livestocks = await _withLoading(() => (_livestockFuture ??= _getOwnLivestockWithPhotos()));
        if (!mounted) return;
        if (livestocks.isEmpty) { _showSnack('Aucun bétail. Créez-en d\'abord.', error: true); return; }

        final selected = await showModalBottomSheet<Map<String, dynamic>>(
          context: context,
          isScrollControlled: true,
          backgroundColor: AppColors.getBgColor(isDark),
          shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
          builder: (_) => _buildSelectionSheet(
            title: 'Sélectionnez un bétail',
            items: livestocks.map((a) {
              final photos = (a['photos'] as List?) ?? [];
              final farmId = (() {
                final v = a['farm_id'] ?? a['farmId'] ?? a['owner_farm_id'];
                if (v is int) return v;
                return int.tryParse(v?.toString() ?? '') ?? 0;
              })();
              return _SelectItem(
                id: (() { final v = a['id'] ?? a['livestock_id']; if (v is int) return v; return int.tryParse(v?.toString() ?? '') ?? 0; })(),
                name: (a['animal_type'] ?? 'Bétail').toString(),
                imageUrl: photos.isNotEmpty ? _extractImageUrl(photos[0]) : null,
                icon: Icons.pets,
                extra: {'farm_id': farmId},
              );
            }).toList(),
            isDark: isDark,
          ),
        );
        if (!mounted || selected == null) return;
        Navigator.push(context, MaterialPageRoute(
          builder: (_) => CreateFarmPostDialog(
            farmId: (selected['farm_id'] as int?) ?? 0,
            farmName: selected['name'] as String,
            onPostCreated: _refreshFeed,
            livestockId: selected['id'] as int,
          ),
        ));
      }
    } catch (e) {
      _showSnack('Erreur: $e', error: true);
    }
  }

  Future<T> _withLoading<T>(Future<T> Function() action) async {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _LoadingDialog(),
    );
    try {
      return await action();
    } finally {
      if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  Widget _buildTypeSheet(bool isDark) {
    final text = AppColors.getTextColor(isDark);
    final sub = AppColors.getSecondaryTextColor(isDark);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nouvelle publication', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: text, letterSpacing: 0.5)),
            const SizedBox(height: 4),
            Text('Que voulez-vous partager ?', style: TextStyle(fontSize: 13, color: sub)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(child: _typeButton('🌾', 'Ferme', 'farm')),
                const SizedBox(width: 12),
                Expanded(child: _typeButton('🐄', 'Bétail', 'livestock')),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _typeButton(String emoji, String label, String value) {
    return OutlinedButton(
      onPressed: () => Navigator.pop(context, value),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 16),
        side: const BorderSide(color: AppColors.primary, width: 1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 6),
          Text(label, style: const TextStyle(color: AppColors.primary, fontSize: 12, letterSpacing: 1)),
        ],
      ),
    );
  }

  Widget _buildSelectionSheet({
    required String title,
    required List<_SelectItem> items,
    required bool isDark,
  }) {
    final text = AppColors.getTextColor(isDark);
    final border = AppColors.getBorderColor(isDark);
    final card = AppColors.getCardBgColor(isDark);
    final sub = AppColors.getSecondaryTextColor(isDark);

    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 36,
            height: 3,
            decoration: BoxDecoration(color: border, borderRadius: BorderRadius.circular(2)),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: text, letterSpacing: 0.5)),
          ),
          Divider(height: 1, color: border),
          SizedBox(
            height: 116,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              scrollDirection: Axis.horizontal,
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (ctx, i) {
                final it = items[i];
                return GestureDetector(
                  onTap: () => Navigator.of(ctx).pop({'id': it.id, 'name': it.name, ...it.extra}),
                  child: SizedBox(
                    width: 76,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: SizedBox(
                            width: 64,
                            height: 64,
                            child: it.imageUrl != null
                                ? Image.network(
                                    it.imageUrl!,
                                    fit: BoxFit.cover,
                                    loadingBuilder: (context, child, progress) {
                                      if (progress == null) return child;
                                      return Center(
                                        child: SizedBox(
                                          width: 18,
                                          height: 18,
                                          child: CircularProgressIndicator(
                                            strokeWidth: 1.5,
                                            value: progress.expectedTotalBytes != null
                                                ? progress.cumulativeBytesLoaded / progress.expectedTotalBytes!
                                                : null,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      );
                                    },
                                    errorBuilder: (_, __, ___) => Container(color: card, child: Icon(it.icon, size: 24, color: sub)),
                                  )
                                : Container(color: card, child: Icon(it.icon, size: 24, color: sub)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          it.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 10, color: text, letterSpacing: 0.3),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── POST CARD ────────────────────────────────────────────────────────────────

  Widget _buildPostCard(FeedItem item, bool isDark) {
    final post = item.data;
    final farmName = post['farm_name']?.toString() ?? 'Ferme';
    final ownerName = post['owner_name']?.toString() ?? 'Agriculteur';
    final caption = post['caption']?.toString() ?? '';
    final imageUrl = _extractImageUrl(post['image_url']);
    final postId = (post['id'] as int?) ?? 0;
    final farmId = (post['farm_id'] as int?) ?? 0;
    final livestockId = post['livestock_id'] as int?;
    final userId = (post['user_id'] as int?) ?? 0;
    final isVerified = post['is_verified'] == true;

    final bg = AppColors.getBgColor(isDark);
    final text = AppColors.getTextColor(isDark);
    final sub = AppColors.getSecondaryTextColor(isDark);
    final border = AppColors.getBorderColor(isDark);

    final diff = DateTime.now().difference(item.timestamp);
    final timeText = diff.inDays == 0 ? 'AUJOURD\'HUI' : diff.inDays == 1 ? 'HIER' : '${diff.inDays}J';

    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: () => userId > 0 ? _pushProfile(userId, isDark) : null,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  _avatar(post, item.isSubscription),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        GestureDetector(
                          onTap: () {
                            if (livestockId != null && livestockId > 0) {
                              _pushAnimal(livestockId, post, isDark);
                            } else if (farmId > 0) {
                              _pushFarm(farmId, post, isDark);
                            }
                          },
                          child: Row(
                            children: [
                              Flexible(
                                child: Text(
                                  farmName.toUpperCase(),
                                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, letterSpacing: 1, color: text),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(Icons.verified, size: 14, color: AppColors.primary),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${livestockId != null ? (post['livestock_type']?.toString().toUpperCase() ?? 'BÉTAIL') : 'FERME'}  ·  $ownerName  ·  $timeText',
                          style: TextStyle(fontSize: 10, color: sub, letterSpacing: 0.4),
                        ),
                      ],
                    ),
                  ),
                  Icon(Icons.more_vert, size: 18, color: sub),
                ],
              ),
            ),
          ),

          // Image
          GestureDetector(
            onDoubleTap: () async {
              if (_userId <= 0 || post['is_liked'] == true) return;
              HapticFeedback.mediumImpact();
              _toggleLike(post, postId, like: true);
            },
            child: AspectRatio(
              aspectRatio: 1,
              child: imageUrl != null
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(isDark),
                    )
                  : _imagePlaceholder(isDark),
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                _actionBtn(
                  icon: post['is_liked'] == true ? Icons.favorite : Icons.favorite_border,
                  color: post['is_liked'] == true ? Colors.red : text,
                  label: '${post['likes_count'] ?? 0}',
                  textColor: text,
                  onTap: () async {
                    if (_userId <= 0) { _showSnack('Connexion requise', error: true); return; }
                    HapticFeedback.lightImpact();
                    _toggleLike(post, postId, like: post['is_liked'] != true);
                  },
                ),
                const SizedBox(width: 18),
                _actionBtn(
                  icon: Icons.chat_bubble_outline,
                  label: '${post['comments_count'] ?? 0}',
                  color: text,
                  textColor: text,
                  onTap: () => _openComments(post, isDark),
                ),
                const SizedBox(width: 18),
                _actionBtn(
                  icon: Icons.share_outlined,
                  label: '${post['shares_count'] ?? 0}',
                  color: text,
                  textColor: text,
                  onTap: () {
                    HapticFeedback.lightImpact();
                    _sharePost(post);
                  },
                ),
                const Spacer(),
                Icon(Icons.bookmark_border, size: 22, color: text),
              ],
            ),
          ),

          // Details
          if ((post['likes_count'] ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Text(
                (post['likes_count'] == 1) ? '1 j\'aime' : '${post['likes_count']} j\'aimes',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: text),
              ),
            ),

          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 6, 14, 4),
              child: RichText(
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                text: TextSpan(
                  style: TextStyle(fontSize: 13, color: text, height: 1.4),
                  children: [
                    TextSpan(text: '${farmName.toUpperCase()} ', style: const TextStyle(fontWeight: FontWeight.w600)),
                    TextSpan(text: caption),
                  ],
                ),
              ),
            ),

          if ((post['comments_count'] ?? 0) > 0)
            GestureDetector(
              onTap: () => _openComments(post, isDark),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 2, 14, 2),
                child: Text(
                  (post['comments_count'] == 1) ? 'Voir 1 commentaire' : 'Voir les ${post['comments_count']} commentaires',
                  style: TextStyle(fontSize: 12, color: sub),
                ),
              ),
            ),

          if ((post['views_count'] ?? 0) > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 4, 14, 14),
              child: Row(
                children: [
                  Icon(Icons.visibility_outlined, size: 12, color: sub),
                  const SizedBox(width: 4),
                  Text('${post['views_count']} vues', style: TextStyle(fontSize: 10, color: sub)),
                ],
              ),
            )
          else
            const SizedBox(height: 14),
        ],
      ),
    );
  }

  // ── HELPERS & ACTIONS ───────────────────────────────────────────────────────

  Widget _avatar(dynamic post, bool isSub) {
    final img = _extractImageUrl(post['owner_profile_image']);
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: isSub ? Border.all(color: AppColors.primary, width: 1.8) : null,
      ),
      child: ClipOval(
        child: img != null
            ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => _avatarFallback())
            : _avatarFallback(),
      ),
    );
  }

  Widget _avatarFallback() => Container(
        color: AppColors.primary.withOpacity(0.15),
        child: const Icon(Icons.person_outline, color: AppColors.primary, size: 18),
      );

  Widget _imagePlaceholder(bool isDark) => Container(
        color: AppColors.getCardBgColor(isDark),
        child: Icon(Icons.image_outlined, size: 40, color: AppColors.getSecondaryTextColor(isDark)),
      );

  Widget _actionBtn({
    required IconData icon,
    required String label,
    required Color color,
    required Color textColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(width: 5),
          Text(label, style: TextStyle(fontSize: 12, color: textColor, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _toggleLike(dynamic post, int postId, {required bool like}) async {
    final old = post['is_liked'] as bool? ?? false;
    final oldCount = (post['likes_count'] ?? 0) as int;

    setState(() {
      post['is_liked'] = like;
      post['likes_count'] = like ? oldCount + 1 : oldCount - 1;
    });

    try {
      if (like) {
        await ApiService.likeFarmPost(postId);
      } else {
        await ApiService.unlikeFarmPost(postId);
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          post['is_liked'] = old;
          post['likes_count'] = oldCount;
        });
      }
    }
  }

  void _openComments(dynamic post, bool isDark) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.getBgColor(isDark),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => CommentsBottomSheet(
        postId: post['id'],
        currentUserId: _userId,
        isDarkMode: isDark,
      ),
    );
  }

  void _pushProfile(int uid, bool isDark) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => ProfileDetailScreen(userId: uid, isDarkMode: isDark)));

  void _pushFarm(int fid, dynamic post, bool isDark) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => FarmDetailScreen(farmId: fid, farmData: post, isDarkMode: isDark)));

  void _pushAnimal(int lid, dynamic post, bool isDark) => Navigator.push(context,
      MaterialPageRoute(builder: (_) => AnimalDetailScreen(livestockId: lid, animal: post, isDarkMode: isDark)));

  Future<void> _sharePost(dynamic post) async {
    final postId = (post['id'] as int?) ?? 0;
    final farmName = post['farm_name']?.toString() ?? 'Ferme';
    final ownerName = post['owner_name']?.toString() ?? 'Agriculteur';
    final caption = post['caption']?.toString() ?? '';
    final imageUrl = _extractImageUrl(post['image_url']);
    final text = '$farmName - par $ownerName\n${caption.isNotEmpty ? '$caption\n' : ''}Découvrez cette publication sur MBAYMI.';

    try {
      XFile? imageFile;
      if (!kIsWeb && imageUrl != null && imageUrl.isNotEmpty) {
        final response = await http.get(Uri.parse(imageUrl)).timeout(const Duration(seconds: 15));
        if (response.statusCode == 200) {
          imageFile = XFile.fromData(
            response.bodyBytes,
            name: 'mbaymi_post_$postId.jpg',
            mimeType: response.headers['content-type'] ?? 'image/jpeg',
          );
        }
      }

      if (!mounted) return;
      if (imageFile != null) {
        await Share.shareXFiles([imageFile], text: text, subject: farmName);
      } else {
        final whatsappUri = Uri.parse('whatsapp://send?text=${Uri.encodeComponent(text)}');
        if (!kIsWeb && await canLaunchUrl(whatsappUri)) {
          await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
        } else {
          await Share.share(text, subject: farmName);
        }
      }

      _recordShare(post);
      ApiService.shareFarmPost(postId).catchError((_) {});
    } catch (error) {
      if (mounted) _showSnack('Partage impossible', error: true);
    }
  }

  void _recordShare(dynamic post) {
    if (mounted) {
      setState(() {
        final old = (post['shares_count'] ?? 0) as int;
        post['shares_count'] = old + 1;
      });
    }
  }

  void _showSnack(String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppColors.createSnackBar(message: msg, isError: error),
    );
  }

  // ── EMPTY / ERROR STATES ────────────────────────────────────────────────────

  Widget _buildEmpty(bool isDark, bool isFollowing) {
    final text = AppColors.getTextColor(isDark);
    final sub = AppColors.getSecondaryTextColor(isDark);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isFollowing ? Icons.favorite_outline : Icons.image_outlined,
              size: 40,
              color: AppColors.primary.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              isFollowing ? 'AUCUN ABONNEMENT' : 'AUCUN POST',
              style: TextStyle(fontSize: 11, letterSpacing: 2, color: text, fontWeight: FontWeight.w400),
            ),
            const SizedBox(height: 8),
            Text(
              isFollowing
                  ? 'Suivez des agriculteurs pour voir leurs publications'
                  : 'Aucune publication disponible pour le moment',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12, color: sub, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildError(String error, bool isDark) {
    final text = AppColors.getTextColor(isDark);
    final sub = AppColors.getSecondaryTextColor(isDark);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 36, color: AppColors.error),
            const SizedBox(height: 12),
            Text('ERREUR', style: TextStyle(fontSize: 11, letterSpacing: 2, color: text)),
            const SizedBox(height: 6),
            Text(error, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: sub)),
          ],
        ),
      ),
    );
  }
}

// ── DATA CLASSES & DIALOGS ────────────────────────────────────────────────----

class _SelectItem {
  final int id;
  final String name;
  final String? imageUrl;
  final IconData icon;
  final Map<String, dynamic> extra;

  const _SelectItem({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.icon,
    required this.extra,
  });
}

class _LoadingDialog extends StatelessWidget {
  const _LoadingDialog();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: AppColors.getCardBgColor(isDark).withOpacity(0.94),
            shape: BoxShape.circle,
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}