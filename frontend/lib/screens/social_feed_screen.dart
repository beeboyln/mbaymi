import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/utils/app_theme.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/screens/post_detail_screen.dart';
import 'package:mbaymi/screens/farm_detail_screen.dart';
import 'package:mbaymi/screens/profile_detail_screen.dart';
import 'package:mbaymi/screens/animal_detail_screen.dart';
import 'package:mbaymi/screens/planning_detail_screen.dart';
import 'package:mbaymi/widgets/comments_bottom_sheet.dart';
import 'package:mbaymi/screens/create_farm_post_dialog.dart';

class SocialFeedScreen extends StatefulWidget {
  final bool isDarkMode;

  const SocialFeedScreen({super.key, this.isDarkMode = false});

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> with TickerProviderStateMixin {
  int _userId = 0;
  late StreamSubscription<void> _farmPostSub;
  late StreamSubscription<dynamic> _followChangedSub;
  
  late Future<Map<String, dynamic>> _feedFuture;
  List<Map<String, dynamic>> _combinedItems = [];
  
  static final Map<String, Future<Map<String, dynamic>>> _globalFeedCache = {};
  static final Map<String, Future<List<dynamic>>> _globalExploreCache = {};
  
  // Animation controllers pour le double-tap like
  final Map<int, AnimationController> _likeAnimations = {};
  final Set<int> _viewedPosts = {};
  
  // Filtre de feed: 'all' ou 'following'
  String _feedFilter = 'all';
  
  // Scaffold key pour contrôler le drawer
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  
  Color? get secondaryTextColor => null;

  @override
  void initState() {
    super.initState();
    _userId = AuthService.currentSession?.userId ?? 0;
    _feedFuture = _getOrCreateFeed();
    _farmPostSub = ApiService.onFarmPostCreated.listen((_) {
      if (mounted) _refreshFeed();
    });
    _followChangedSub = ApiService.onFollowChanged.listen((payload) {
      if (mounted) _refreshFeed();
    });
  }

  @override
  void dispose() {
    _farmPostSub.cancel();
    _followChangedSub.cancel();
    for (var controller in _likeAnimations.values) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _extractImageUrl(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map) {
      return (value['url'] ?? value['image_url'] ?? value['image'] ?? value['photo'] ?? value['src'])?.toString();
    }
    return null;
  }
  
  AnimationController _getLikeAnimation(int postId) {
    if (!_likeAnimations.containsKey(postId)) {
      _likeAnimations[postId] = AnimationController(
        duration: const Duration(milliseconds: 400),
        vsync: this,
      );
    }
    return _likeAnimations[postId]!;
  }
  
  void _changeFeedFilter(String filter) {
    if (_feedFilter != filter) {
      setState(() {
        _feedFilter = filter;
      });
      Navigator.pop(context); // Fermer le drawer
    }
  }
  
  Future<Map<String, dynamic>> _getOrCreateFeed() {
    final cacheKey = 'feed_$_userId';
    if (!_globalFeedCache.containsKey(cacheKey)) {
      _globalFeedCache[cacheKey] = _loadCombinedFeed();
    }
    return _globalFeedCache[cacheKey]!;
  }
  
  void _refreshFeed() {
    final cacheKey = 'feed_$_userId';
    _globalFeedCache.remove(cacheKey);
    if (mounted) {
      setState(() {
        _feedFuture = _getOrCreateFeed();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final bgColor = AppColors.getBgColor(isDarkMode);
    final textColor = AppColors.getTextColor(isDarkMode);

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.menu, color: textColor, size: 24),
          onPressed: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        title: Text(
          'MBAYMI',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 18,
            fontWeight: FontWeight.w200,
            letterSpacing: 2,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IconButton(
              icon: const Icon(Icons.add, size: 20),
              color: textColor,
              tooltip: 'Nouveau post',
              onPressed: () => _onAddPostPressed(isDarkMode),
            ),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 0.5,
            color: AppColors.getBorderColor(isDarkMode),
          ),
        ),
      ),
      drawer: _buildDrawer(isDarkMode),
      body: _buildFeedTab(isDarkMode),
    );
  }

  Future<void> _onAddPostPressed(bool isDarkMode) async {
    if (_userId <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppColors.createSnackBar(
          message: 'Connectez-vous pour créer une publication',
          isError: true,
        ),
      );
      return;
    }

    try {
      final farms = await ApiService.getUserFarms();
      if (!mounted) return;
      
      final livestocks = await ApiService.getAllLivestockWithPhotos(userId: _userId);
      if (!mounted) return;
      
      if (farms.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          AppColors.createSnackBar(
            message: 'Vous n\'avez aucune ferme. Créez-en une d\'abord.',
            isError: true,
          ),
        );
        return;
      }

      final selected = await showModalBottomSheet<Map<String, dynamic>>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.getBgColor(isDarkMode),
        builder: (ctx) {
          return SingleChildScrollView(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text('Choisissez une ferme ou un bétail', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.getTextColor(isDarkMode))),
                  ),
                  Divider(height: 1, color: AppColors.getBorderColor(isDarkMode)),

                  // FARMS SECTION
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Fermes', style: TextStyle(fontSize: 12, color: AppColors.getSecondaryTextColor(isDarkMode), fontWeight: FontWeight.w600)),
                    ),
                  ),
                  SizedBox(
                    height: 140,
                    child: ListView.separated(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      scrollDirection: Axis.horizontal,
                      itemCount: farms.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, i) {
                        final f = farms[i] as Map<String, dynamic>;
                        final fid = (f['farm_id'] ?? f['id'] ?? 0) as int;
                        final fname = (f['farm_name'] ?? f['name'] ?? 'Ferme') as String;
                        final img = _extractImageUrl(f['profile_image_farm'] ?? f['profile_image'] ?? f['image_url'] ?? f['image']);
                        return GestureDetector(
                          onTap: () => Navigator.of(ctx).pop({'type': 'farm', 'id': fid, 'name': fname}),
                          child: Column(
                            children: [
                              Container(
                                width: 84,
                                height: 84,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  color: AppColors.getCardBgColor(isDarkMode),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: img != null && img.isNotEmpty
                                      ? Image.network(img, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.landscape_outlined, color: AppColors.getSecondaryTextColor(isDarkMode)))
                                      : Icon(Icons.landscape_outlined, color: AppColors.getSecondaryTextColor(isDarkMode)),
                                ),
                              ),
                              const SizedBox(height: 8),
                              SizedBox(width: 88, child: Text(fname, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                            ],
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 12),

                  // LIVESTOCK SECTION
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 0, 12, 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Bétail', style: TextStyle(fontSize: 12, color: AppColors.getSecondaryTextColor(isDarkMode), fontWeight: FontWeight.w600)),
                    ),
                  ),
                  if (livestocks.isEmpty)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      child: Text('Aucun bétail', style: TextStyle(color: AppColors.getSecondaryTextColor(isDarkMode))),
                    )
                  else
                    SizedBox(
                      height: 120,
                      child: ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        scrollDirection: Axis.horizontal,
                        itemCount: livestocks.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, j) {
                          final a = livestocks[j] as Map<String, dynamic>;
                          final lid = (() {
                            final v = a['id'] ?? a['livestock_id'];
                            if (v is int) return v;
                            return int.tryParse(v?.toString() ?? '') ?? 0;
                          })();
                          final lname = (a['animal_type'] ?? 'Bétail').toString();
                          final photos = (a['photos'] as List?) ?? [];
                          final thumb = photos.isNotEmpty ? _extractImageUrl(photos[0]) : null;
                          final farmIdFromAnimal = (() {
                            final fv = a['farm_id'] ?? a['farmId'] ?? a['owner_farm_id'];
                            if (fv == null) return 0;
                            if (fv is int) return fv;
                            return int.tryParse(fv.toString()) ?? 0;
                          })();
                          return GestureDetector(
                            onTap: () => Navigator.of(ctx).pop({'type': 'livestock', 'id': lid, 'name': lname, 'farm_id': farmIdFromAnimal}),
                            child: Column(
                              children: [
                                Container(
                                  width: 84,
                                  height: 84,
                                  decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: AppColors.getCardBgColor(isDarkMode)),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: thumb != null && thumb.isNotEmpty
                                        ? Image.network(thumb, fit: BoxFit.cover, errorBuilder: (_, __, ___) => Icon(Icons.pets, color: AppColors.getSecondaryTextColor(isDarkMode)))
                                        : Icon(Icons.pets, color: AppColors.getSecondaryTextColor(isDarkMode)),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(width: 88, child: Text(lname, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.center)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                ],
              ),
            ),
          ));
        },
      );

      if (!mounted) return;
      if (selected != null && selected['id'] != null && selected['id'] > 0) {
        final selType = selected['type'] as String? ?? 'farm';
        if (selType == 'farm') {
          final farmId = selected['id'] as int;
          final farmName = selected['name'] as String? ?? 'Ferme';
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateFarmPostDialog(
                farmId: farmId,
                farmName: farmName,
                onPostCreated: () => _refreshFeed(),
              ),
            ),
          );
        } else if (selType == 'livestock') {
          final livestockId = selected['id'] as int;
          final name = selected['name'] as String? ?? 'Bétail';
          final farmId = (selected['farm_id'] as int?) ?? 0;
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateFarmPostDialog(
                farmId: farmId,
                farmName: name,
                onPostCreated: () => _refreshFeed(),
                livestockId: livestockId,
              ),
            ),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        AppColors.createSnackBar(
          message: 'Erreur: $e',
          isError: true,
        ),
      );
    }
  }
  
  Widget _buildDrawer(bool isDarkMode) {
    final bgColor = AppColors.getBgColor(isDarkMode);
    final textColor = AppColors.getTextColor(isDarkMode);
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDarkMode);
    final borderColor = AppColors.getBorderColor(isDarkMode);
    
    return Drawer(
      backgroundColor: bgColor,
      width: 280,
      child: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header avec logo
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 12),
                child: Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        AppColors.primary,
                        AppColors.primary.withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: const Icon(
                    Icons.agriculture,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Section NAVIGATION
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Text(
                  'NAVIGATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                    color: secondaryTextColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Tous (Vue d'ensemble)
              _buildDrawerItem(
                icon: Icons.home_outlined,
                selectedIcon: Icons.home,
                label: 'TOUS',
                isSelected: _feedFilter == 'all',
                isDarkMode: isDarkMode,
                onTap: () => _changeFeedFilter('all'),
              ),
              
              // Abonnés
              _buildDrawerItem(
                icon: Icons.favorite_outline,
                selectedIcon: Icons.favorite,
                label: 'ABONNÉS',
                isSelected: _feedFilter == 'following',
                isDarkMode: isDarkMode,
                onTap: () => _changeFeedFilter('following'),
              ),
              
              const SizedBox(height: 12),
              
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Divider(
                  color: borderColor,
                  thickness: 0.5,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Section PUBLIC
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 6),
                child: Text(
                  'DÉCOUVRIR',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                    color: secondaryTextColor,
                  ),
                ),
              ),
              
              const SizedBox(height: 4),
              
              // Explorer
              _buildDrawerItem(
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore,
                label: 'EXPLORER',
                isSelected: false,
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigation vers explore
                },
              ),
              
              // Tendances
              _buildDrawerItem(
                icon: Icons.local_fire_department_outlined,
                selectedIcon: Icons.local_fire_department,
                label: 'TENDANCES',
                isSelected: false,
                isDarkMode: isDarkMode,
                onTap: () {
                  Navigator.pop(context);
                  // TODO: Navigation vers tendances
                },
              ),
              
              const SizedBox(height: 24),
              
              // Version
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text(
                  'MBAYMI v1.0',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1,
                    color: secondaryTextColor.withOpacity(0.5),
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
  
  Widget _buildDrawerItem({
    required IconData icon,
    required IconData selectedIcon,
    required String label,
    required bool isSelected,
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    final textColor = AppColors.getTextColor(isDarkMode);
    final borderColor = AppColors.getBorderColor(isDarkMode);
    
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: isSelected
              ? const Border(
                  left: BorderSide(
                    color: AppColors.primary,
                    width: 3,
                  ),
                )
              : null,
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? selectedIcon : icon,
              size: 20,
              color: isSelected ? AppColors.primary : textColor,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                letterSpacing: 1.5,
                color: isSelected ? AppColors.primary : textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedTab(bool isDarkMode) {
    const primaryColor = AppColors.primary;
    
    return RefreshIndicator(
      onRefresh: () async {
        _refreshFeed();
      },
      color: primaryColor,
      backgroundColor: AppColors.getCardBgColor(isDarkMode),
      child: FutureBuilder<Map<String, dynamic>>(
        future: _feedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget(isDarkMode);
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString(), isDarkMode);
          }

          final data = snapshot.data ?? {};
          final rawItems = data['items'] as List<dynamic>? ?? [];
          _combinedItems = rawItems.cast<Map<String, dynamic>>();
          
          // Filtrer selon le choix
          List<Map<String, dynamic>> filteredItems;
          if (_feedFilter == 'following') {
            // Afficher uniquement les posts des abonnements
            filteredItems = _combinedItems.where((item) {
              return item['isSubscription'] == true;
            }).toList();
          } else {
            // Afficher tous les posts
            filteredItems = _combinedItems;
          }

          if (filteredItems.isEmpty) {
            return _buildEmptyFeedWidget(isDarkMode, _feedFilter == 'following');
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 0),
            itemCount: filteredItems.length,
            itemBuilder: (context, index) {
              final item = filteredItems[index];
              if (item['type'] == 'farm_post') {
                return _buildFarmPostCard(item['data'], item, isDarkMode);
              } else if (item['type'] == 'planning') {
                return _buildPlanningCard(item['data'], isDarkMode);
              }
              return const SizedBox();
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadCombinedFeed() async {
    try {
      List<dynamic> items = [];
      Set<int> subscriptionPostIds = {};

      try {
        if (_userId > 0) {
          final results = await Future.wait<dynamic>([
            ApiService.getSubscriptionsFeed(userId: _userId),
            ApiService.getFarmPostsFeed(userId: _userId),
            ApiService.getPublicPlanningsFeed(page: 1, pageSize: 10),
          ], eagerError: false);

          final subscriptionPosts = (results[0] as List<dynamic>?) ?? [];
          final farmPosts = (results[1] as List<dynamic>?) ?? [];
          final planningsResponse = (results[2] as Map<String, dynamic>?) ?? {};
          final plannings = (planningsResponse['items'] as List<dynamic>?) ?? [];

          subscriptionPostIds = subscriptionPosts.map((post) => post['id'] as int).toSet();

          items.addAll(farmPosts.map((post) {
            final postId = post['id'] as int;
            final isSubscription = subscriptionPostIds.contains(postId);
            return {
              'type': 'farm_post',
              'data': post,
              'timestamp': DateTime.tryParse(post['created_at'] ?? '') ?? DateTime.now(),
              'isSubscription': isSubscription,
            };
          }));

          items.addAll(plannings.map((planning) {
            return {
              'type': 'planning',
              'data': planning,
              'timestamp': DateTime.tryParse(planning['created_at'] ?? '') ?? DateTime.now(),
              'isSubscription': false,
            };
          }));
        } else {
          final results = await Future.wait<dynamic>([
            ApiService.getFarmPostsFeed(userId: _userId),
            ApiService.getPublicPlanningsFeed(page: 1, pageSize: 10),
          ], eagerError: false);

          final farmPosts = (results[0] as List<dynamic>?) ?? [];
          final planningsResponse = (results[1] as Map<String, dynamic>?) ?? {};
          final plannings = (planningsResponse['items'] as List<dynamic>?) ?? [];

          items.addAll(farmPosts.map((post) => {
            'type': 'farm_post',
            'data': post,
            'timestamp': DateTime.tryParse(post['created_at'] ?? '') ?? DateTime.now(),
            'isSubscription': false,
          }));

          items.addAll(plannings.map((planning) => {
            'type': 'planning',
            'data': planning,
            'timestamp': DateTime.tryParse(planning['created_at'] ?? '') ?? DateTime.now(),
            'isSubscription': false,
          }));
        }
      } catch (e) {
        print('Erreur chargement feed: $e');
      }

      items.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      return {'items': items};
    } catch (e) {
      throw Exception('Erreur chargement: $e');
    }
  }

  Widget _buildFarmPostCard(dynamic post, Map<String, dynamic> itemWrapper, bool isDarkMode) {
    final farmName = post['farm_name']?.toString() ?? 'Ferme';
    final ownerName = post['owner_name']?.toString() ?? 'Agriculteur';
    final caption = post['caption']?.toString() ?? '';
    final imageUrl = _extractImageUrl(post['image_url']);
    final postId = post['id'] as int? ?? 0;
    final farmId = post['farm_id'] as int? ?? 0;
    final livestockId = post['livestock_id'] as int?;
    final userId = post['user_id'] as int? ?? 0;
    final likesCount = post['likes_count'] ?? 0;
    final commentsCount = post['comments_count'] ?? 0;
    final sharesCount = post['shares_count'] ?? 0;
    final viewsCount = post['views_count'] ?? 0;
    final isVerified = post['is_verified'] ?? false;
    final createdAt = DateTime.tryParse(post['created_at'] as String? ?? '') ?? DateTime.now();
    final daysAgo = DateTime.now().difference(createdAt).inDays;
    final timeText = daysAgo == 0 ? 'AUJOURD\'HUI' : daysAgo == 1 ? 'HIER' : '${daysAgo}J';
    final isSubscription = itemWrapper['isSubscription'] as bool? ?? false;

    final bgColor = AppColors.getBgColor(isDarkMode);
    final textColor = AppColors.getTextColor(isDarkMode);
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDarkMode);
    final borderColor = AppColors.getBorderColor(isDarkMode);

    // Track view
    if (!_viewedPosts.contains(postId)) {
      _viewedPosts.add(postId);
      // TODO: Implement incrementPostView in ApiService
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 1),
      decoration: BoxDecoration(
        color: bgColor,
        border: Border(
          bottom: BorderSide(
            color: borderColor,
            width: 0.5,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          GestureDetector(
            onTap: () {
              if (userId > 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileDetailScreen(
                      userId: userId,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Avatar circulaire style Instagram
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: isSubscription
                          ? Border.all(
                              color: AppColors.primary,
                              width: 2,
                            )
                          : null,
                    ),
                    child: ClipOval(
                      child: (() {
                        final ownerImg = _extractImageUrl(post['owner_profile_image']);
                        if (ownerImg != null && ownerImg.isNotEmpty) {
                          return Image.network(
                            ownerImg,
                            fit: BoxFit.cover,
                            errorBuilder: (c, e, s) => Container(
                              color: AppColors.primary.withOpacity(0.2),
                              child: const Icon(
                                Icons.person_outline,
                                color: AppColors.primary,
                                size: 20,
                              ),
                            ),
                          );
                        }
                        return Container(
                          color: AppColors.primary.withOpacity(0.2),
                          child: const Icon(
                            Icons.person_outline,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        );
                      })(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nom de la ferme/bétail avec badge
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  if (livestockId != null && livestockId > 0) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AnimalDetailScreen(
                                          livestockId: livestockId,
                                          animal: post,
                                          isDarkMode: isDarkMode,
                                        ),
                                      ),
                                    );
                                  } else if (farmId > 0) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FarmDetailScreen(
                                          farmId: farmId,
                                          farmData: post,
                                          isDarkMode: isDarkMode,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // Titre principal
                                    Text(
                                      farmName.toUpperCase(),
                                      style: TextStyle(
                                        fontWeight: FontWeight.w600,
                                        fontSize: 13,
                                        letterSpacing: 1.2,
                                        color: textColor,
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    // Badge type (Ferme ou Bétail)
                                    if (livestockId != null && livestockId > 0)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 2),
                                        child: Text(
                                          post['livestock_type']?.toString().toUpperCase() ?? 'BÉTAIL',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            letterSpacing: 0.8,
                                            color: AppColors.primary,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      )
                                    else
                                      const Padding(
                                        padding: EdgeInsets.only(top: 2),
                                        child: Text(
                                          'FERME',
                                          style: TextStyle(
                                            fontSize: 9,
                                            letterSpacing: 0.8,
                                            color: AppColors.accent,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            if (isVerified) ...[
                              const SizedBox(width: 6),
                              const Icon(
                                Icons.verified,
                                size: 16,
                                color: AppColors.primary,
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$ownerName • $timeText',
                          style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.3,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.more_vert,
                    size: 20,
                    color: textColor,
                  ),
                ],
              ),
            ),
          ),

          // Image avec double-tap pour like
          if (imageUrl != null && imageUrl.isNotEmpty)
            GestureDetector(
              onDoubleTap: () async {
                if (_userId <= 0) return;
                
                final isLiked = post['is_liked'] ?? false;
                if (!isLiked) {
                  // Haptic feedback
                  HapticFeedback.mediumImpact();
                  
                  // Update state immédiatement
                  post['is_liked'] = true;
                  post['likes_count'] = (post['likes_count'] ?? 0) + 1;
                  itemWrapper['data'] = post;
                  setState(() {});
                  
                  // API call
                  try {
                    await ApiService.likeFarmPost(postId);
                  } catch (e) {
                    // Revert on error
                    post['is_liked'] = false;
                    post['likes_count'] = (post['likes_count'] ?? 0) - 1;
                    itemWrapper['data'] = post;
                    setState(() {});
                  }
                }
              },
              child: AspectRatio(
                aspectRatio: 1,
                child: Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (c, e, s) => Container(
                    color: AppColors.getCardBgColor(isDarkMode),
                    child: Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              ),
            )
          else
            AspectRatio(
              aspectRatio: 1,
              child: Container(
                color: AppColors.getCardBgColor(isDarkMode),
                child: Icon(
                  Icons.image_outlined,
                  size: 48,
                  color: secondaryTextColor,
                ),
              ),
            ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Like
                GestureDetector(
                  onTap: () async {
                    if (_userId <= 0) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        AppColors.createSnackBar(
                          message: 'Connexion requise',
                          isError: true,
                        ),
                      );
                      return;
                    }
                    
                    HapticFeedback.lightImpact();
                    
                    try {
                      final isLiked = post['is_liked'] ?? false;
                      final currentLikes = likesCount;
                      
                      post['is_liked'] = !isLiked;
                      post['likes_count'] = isLiked ? currentLikes - 1 : currentLikes + 1;
                      itemWrapper['data'] = post;
                      setState(() {});
                      
                      if (isLiked) {
                        await ApiService.unlikeFarmPost(postId);
                      } else {
                        await ApiService.likeFarmPost(postId);
                      }
                    } catch (e) {
                      final isLiked = post['is_liked'] ?? false;
                      final currentLikes = post['likes_count'] ?? 0;
                      post['is_liked'] = !isLiked;
                      post['likes_count'] = isLiked ? currentLikes - 1 : currentLikes + 1;
                      itemWrapper['data'] = post;
                      setState(() {});
                    }
                  },
                  child: Row(
                    children: [
                      Icon(
                        (post['is_liked'] ?? false) 
                            ? Icons.favorite 
                            : Icons.favorite_border,
                        size: 24,
                        color: (post['is_liked'] ?? false) 
                            ? Colors.red 
                            : textColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post['likes_count'] ?? 0}',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 0.3,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                
                // Comment
                GestureDetector(
                  onTap: () {
                    HapticFeedback.lightImpact();
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: bgColor,
                      builder: (context) => CommentsBottomSheet(
                        postId: post['id'],
                        currentUserId: _userId,
                        isDarkMode: isDarkMode,
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 24, color: textColor),
                      const SizedBox(width: 6),
                      Text(
                        '$commentsCount',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 0.3,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                
                // Share
                GestureDetector(
                  onTap: () async {
                    HapticFeedback.lightImpact();
                    
                    try {
                      final currentShares = sharesCount;
                      post['shares_count'] = currentShares + 1;
                      itemWrapper['data'] = post;
                      setState(() {});
                      
                      await ApiService.shareFarmPost(postId);
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text(
                              'Partagé',
                              style: TextStyle(letterSpacing: 0.5),
                            ),
                            backgroundColor: AppColors.success,
                            behavior: SnackBarBehavior.floating,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            duration: const Duration(milliseconds: 600),
                          ),
                        );
                      }
                    } catch (e) {
                      post['shares_count'] = (post['shares_count'] ?? 0) - 1;
                      itemWrapper['data'] = post;
                      setState(() {});
                    }
                  },
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined, size: 24, color: textColor),
                      const SizedBox(width: 6),
                      Text(
                        '${post['shares_count'] ?? 0}',
                        style: TextStyle(
                          fontSize: 13,
                          letterSpacing: 0.3,
                          color: textColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                
                // Bookmark
                Icon(Icons.bookmark_border, size: 24, color: textColor),
              ],
            ),
          ),

          // Likes count
          if (likesCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                likesCount == 1 ? '1 j\'aime' : '$likesCount j\'aimes',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                  letterSpacing: 0.3,
                ),
              ),
            ),

          // Caption
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: RichText(
                text: TextSpan(
                  style: TextStyle(
                    fontSize: 13,
                    color: textColor,
                    letterSpacing: 0.3,
                    height: 1.5,
                  ),
                  children: [
                    TextSpan(
                      text: '$farmName ',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    TextSpan(text: caption),
                  ],
                ),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          // View all comments
          if (commentsCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 4),
              child: GestureDetector(
                onTap: () {
                  HapticFeedback.lightImpact();
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: bgColor,
                    builder: (context) => CommentsBottomSheet(
                      postId: post['id'],
                      currentUserId: _userId,
                      isDarkMode: isDarkMode,
                    ),
                  );
                },
                child: Text(
                  commentsCount == 1 
                      ? 'Voir 1 commentaire'
                      : 'Voir les $commentsCount commentaires',
                  style: TextStyle(
                    fontSize: 12,
                    color: secondaryTextColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),

          // Views count
          if (viewsCount > 0)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
              child: Row(
                children: [
                  Icon(
                    Icons.visibility_outlined,
                    size: 14,
                    color: secondaryTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$viewsCount vues',
                    style: TextStyle(
                      fontSize: 11,
                      color: secondaryTextColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            )
          else
            const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget(bool isDarkMode) {
    return const Center(
      child: SizedBox(
        height: 24,
        width: 24,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
        ),
      ),
    );
  }

  Widget _buildErrorWidget(String error, bool isDarkMode) {
    final textColor = AppColors.getTextColor(isDarkMode);
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDarkMode);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: AppColors.error,
            ),
            const SizedBox(height: 20),
            Text(
              'ERREUR',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 2,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 0.3,
                color: secondaryTextColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFeedWidget(bool isDarkMode, [bool isFollowingFilter = false]) {
    final textColor = AppColors.getTextColor(isDarkMode);
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDarkMode);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isFollowingFilter ? Icons.favorite_outline : Icons.chat_bubble_outline,
            size: 48,
            color: AppColors.primary.withOpacity(0.5),
          ),
          const SizedBox(height: 20),
          Text(
            isFollowingFilter ? 'AUCUN ABONNEMENT' : 'AUCUN POST',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 2,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              isFollowingFilter 
                  ? 'Suivez des agriculteurs pour voir leurs publications ici'
                  : 'Aucune publication disponible pour le moment',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                letterSpacing: 0.3,
                color: secondaryTextColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlanningCard(dynamic planning, bool isDarkMode) {
    final title = planning['title']?.toString() ?? 'Planification';
    final userName = planning['user_name']?.toString() ?? 'Agriculteur';
    final planningId = planning['id'] as int? ?? 0;
    final likesCount = planning['likes_count'] ?? 0;
    final commentsCount = planning['comments_count'] ?? 0;
    final progress = planning['total_tasks'] ?? 0 > 0
        ? (planning['completed_tasks'] ?? 0) / (planning['total_tasks'] ?? 1) * 100
        : 0;
    final textColor = AppColors.getTextColor(isDarkMode);
    final cardBgColor = AppColors.getCardBgColor(isDarkMode);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 8),
      elevation: 0,
      color: cardBgColor,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PlanningDetailScreen(
                planningId: planningId,
              ),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header with title and icon
              Row(
                children: [
                  Icon(
                    Icons.calendar_today_outlined,
                    size: 20,
                    color: Color(0xFF80CBC4),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Author info
              Text(
                'Par $userName',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.getSecondaryTextColor(isDarkMode),
                ),
              ),
              const SizedBox(height: 12),
              // Progress bar
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress / 100,
                  minHeight: 6,
                  backgroundColor: isDarkMode ? Color(0xFF1A2F2E) : Colors.grey[300],
                  valueColor: AlwaysStoppedAnimation(Color(0xFF80CBC4)),
                ),
              ),
              const SizedBox(height: 8),
              // Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${progress.toStringAsFixed(0)}% complété',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.getSecondaryTextColor(isDarkMode),
                    ),
                  ),
                  Row(
                    children: [
                      Icon(Icons.favorite_outline, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('$likesCount', style: const TextStyle(fontSize: 12)),
                      const SizedBox(width: 12),
                      Icon(Icons.comment_outlined, size: 14, color: Colors.grey),
                      const SizedBox(width: 4),
                      Text('$commentsCount', style: const TextStyle(fontSize: 12)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}