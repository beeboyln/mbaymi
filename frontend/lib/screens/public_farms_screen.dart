import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/screens/parcel_screen.dart';
import 'package:mbaymi/utils/app_colors.dart';

class PublicFarmsScreen extends StatefulWidget {
  const PublicFarmsScreen({super.key});

  @override
  State<PublicFarmsScreen> createState() => _PublicFarmsScreenState();
}

class _PublicFarmsScreenState extends State<PublicFarmsScreen>
    with TickerProviderStateMixin {
  Future<List<dynamic>>? _farmsFuture;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _sortMode = 'followers'; // 'followers' | 'name' | 'recent'

  Set<int> _followedFarmIds = {};
  bool _isLoadingFollows = false;
  
  // Track followers count per farm ID for real-time updates
  final Map<int, int> _farmFollowersCount = {};

  // Animated follow states
  final Map<int, AnimationController> _followAnimControllers = {};

  static final Map<String, Future<List<dynamic>>> _globalDataCache = {};
  static final Map<int, Future<List<dynamic>>> _globalCropsCache = {};
  static final Map<int, Future<List<dynamic>>> _globalLivestockCache = {};
  
  // Track selected tab per farm (true = crops, false = livestock)
  final Map<int, bool> _farmTabSelection = {};

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() => _searchQuery = _searchController.text);
      }
    });
    _loadPublicFarms();
    _loadFollowedFarms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    for (final ctrl in _followAnimControllers.values) {
      ctrl.dispose();
    }
    super.dispose();
  }

  void _loadPublicFarms() {
    _farmsFuture = _getPublicFarmsCached();
  }

  AnimationController _getFollowController(int farmId) {
    if (!_followAnimControllers.containsKey(farmId)) {
      _followAnimControllers[farmId] = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 300),
      );
    }
    return _followAnimControllers[farmId]!;
  }

  Future<void> _loadFollowedFarms() async {
    final currentUserId = AuthService.currentSession?.userId;
    if (currentUserId == null) {
      setState(() => _followedFarmIds = {});
      return;
    }
    try {
      setState(() => _isLoadingFollows = true);
      final followingFarmIds = await ApiService.getFarmFollowingIds(currentUserId);
      setState(() {
        _followedFarmIds = followingFarmIds.toSet();
      });
    } catch (e) {
      debugPrint('Error loading followed farms: $e');
      setState(() => _followedFarmIds = {});
    } finally {
      setState(() => _isLoadingFollows = false);
    }
  }

  Future<void> _toggleFollowFarm(int farmId) async {
    final currentUserId = AuthService.currentSession?.userId;
    if (currentUserId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.lock_outline, color: Colors.white, size: 16),
              SizedBox(width: 10),
              Text('Connectez-vous pour suivre des fermes',
                  style: TextStyle(fontWeight: FontWeight.w300)),
            ],
          ),
          backgroundColor: Colors.black87,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        ),
      );
      return;
    }

    final ctrl = _getFollowController(farmId);
    ctrl.forward().then((_) => ctrl.reverse());

    try {
      if (_followedFarmIds.contains(farmId)) {
        // Unfollow - decrement followers count
        final currentCount = _farmFollowersCount[farmId] ?? 0;
        await ApiService.unfollowFarm(farmId: farmId, userId: currentUserId);
        setState(() {
          _followedFarmIds.remove(farmId);
          _farmFollowersCount[farmId] = (currentCount - 1).clamp(0, double.infinity).toInt();
        });
        if (mounted) {
          _showToast('Vous ne suivez plus cette ferme', Colors.black87, Icons.person_remove_outlined);
        }
      } else {
        // Follow - increment followers count
        final currentCount = _farmFollowersCount[farmId] ?? 0;
        await ApiService.followFarm(farmId: farmId, userId: currentUserId);
        setState(() {
          _followedFarmIds.add(farmId);
          _farmFollowersCount[farmId] = currentCount + 1;
        });
        if (mounted) {
          _showToast('Ferme ajoutée à vos abonnements', AppColors.primary, Icons.check_circle_outline);
        }
      }
    } catch (e) {
      if (mounted) {
        _showToast('Erreur: ${e.toString()}', Colors.red.shade400, Icons.error_outline);
      }
    }
  }

  void _showToast(String message, Color color, IconData icon) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(message,
                  style: const TextStyle(fontWeight: FontWeight.w300, fontSize: 13)),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Future<List<dynamic>> _getPublicFarmsCached() {
    const cacheKey = 'public_farms';
    if (!_globalDataCache.containsKey(cacheKey)) {
      _globalDataCache[cacheKey] = ApiService.getPublicFarms();
    }
    return _globalDataCache[cacheKey]!;
  }

  Future<List<dynamic>> _getCropsCached(int farmId) {
    if (!_globalCropsCache.containsKey(farmId)) {
      _globalCropsCache[farmId] = ApiService.getPublicFarmCrops(farmId);
    }
    return _globalCropsCache[farmId]!;
  }

  Future<List<dynamic>> _getLivestockCached(int farmId) {
    if (!_globalLivestockCache.containsKey(farmId)) {
      _globalLivestockCache[farmId] = ApiService.getUserLivestock(farmId).catchError((_) => <dynamic>[]);
    }
    return _globalLivestockCache[farmId]!;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;

    return Scaffold(
      backgroundColor: AppColors.getBgColor(isDarkMode),
      appBar: _buildAppBar(isDarkMode),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: AppColors.getBgColor(isDarkMode),
        onRefresh: () async {
          _globalDataCache.remove('public_farms');
          _globalCropsCache.clear();
          _globalLivestockCache.clear();
          _farmsFuture = _getPublicFarmsCached();
          _searchController.clear();
          _searchQuery = '';
          setState(() {});
          imageCache.clearLiveImages();
          imageCache.clear();
          await _loadFollowedFarms();
        },
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _buildSearchAndFilters(isDarkMode),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
              sliver: _buildFarmList(isDarkMode),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool isDarkMode) {
    return AppBar(
      backgroundColor: AppColors.getBgColor(isDarkMode),
      elevation: 0,
      surfaceTintColor: Colors.transparent,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1),
        child: Divider(
          height: 1,
          thickness: 1,
          color: isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
        ),
      ),
      title: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.agriculture_outlined,
              size: 16,
              color: isDarkMode ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5)),
          const SizedBox(width: 10),
          Text(
            'FERMES PUBLIQUES',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 3,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(Icons.arrow_back_outlined,
            color: isDarkMode ? Colors.white : Colors.black87),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        if (_isLoadingFollows)
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.accent.withOpacity(0.5),
                ),
              ),
            ),
          )
        else
          const SizedBox(width: 48),
      ],
    );
  }

  Widget _buildSearchAndFilters(bool isDarkMode) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        // Search
        TextField(
          controller: _searchController,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
          decoration: InputDecoration(
            hintText: 'Rechercher par nom ou localisation…',
            hintStyle: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.3,
              color: isDarkMode ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.26),
            ),
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 14, right: 10),
              child: Icon(Icons.search,
                  size: 18,
                  color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.close,
                        size: 16,
                        color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() => _searchQuery = '');
                    },
                  )
                : null,
            filled: true,
            fillColor: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(
                color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: BorderSide(color: AppColors.accent.withOpacity(0.5), width: 1),
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          ),
        ),
        const SizedBox(height: 12),
        // Sort chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              Text(
                'TRIER PAR :',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.5,
                  color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                ),
              ),
              const SizedBox(width: 12),
              _buildSortChip('followers', 'ABONNÉS', Icons.people_outline, isDarkMode),
              const SizedBox(width: 8),
              _buildSortChip('name', 'NOM', Icons.sort_by_alpha, isDarkMode),
              const SizedBox(width: 8),
              _buildSortChip('parcels', 'PARCELLES', Icons.grid_view_outlined, isDarkMode),
            ],
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  Widget _buildSortChip(String value, String label, IconData icon, bool isDarkMode) {
    final isSelected = _sortMode == value;
    return GestureDetector(
      onTap: () => setState(() => _sortMode = value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.accent.withOpacity(0.15)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isSelected
                ? AppColors.accent.withOpacity(0.5)
                : isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 11,
                color: isSelected
                    ? AppColors.accent
                    : isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4)),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                letterSpacing: 1.0,
                color: isSelected
                    ? AppColors.accent
                    : isDarkMode ? Colors.white.withOpacity(0.5) : Colors.black.withOpacity(0.5),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmList(bool isDarkMode) {
    return FutureBuilder<List<dynamic>>(
      future: _farmsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 1.5,
                      color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'CHARGEMENT',
                    style: TextStyle(
                      fontSize: 9,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w300,
                      color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.wifi_off_outlined,
                      size: 28,
                      color: isDarkMode ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12)),
                  const SizedBox(height: 16),
                  Text('ERREUR DE CONNEXION',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w300,
                        color: isDarkMode ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.24),
                      )),
                  const SizedBox(height: 8),
                  Text('Glissez vers le bas pour réessayer',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        color: isDarkMode ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15),
                      )),
                ],
              ),
            ),
          );
        }

        List<dynamic> farms = List.from(snapshot.data ?? []);

        // Search filter
        final query = _searchQuery.trim().toLowerCase();
        if (query.isNotEmpty) {
          farms = farms.where((f) {
            final name = (f['farm_name'] ?? '').toString().toLowerCase();
            final location = (f['location'] ?? '').toString().toLowerCase();
            return name.contains(query) || location.contains(query);
          }).toList();
        }

        // Sort
        if (_sortMode == 'followers') {
          farms.sort((a, b) {
            final af = (a['followers'] ?? a['total_followers'] ?? 0) as int;
            final bf = (b['followers'] ?? b['total_followers'] ?? 0) as int;
            return bf.compareTo(af);
          });
        } else if (_sortMode == 'name') {
          farms.sort((a, b) =>
              (a['farm_name'] ?? '').toString().compareTo((b['farm_name'] ?? '').toString()));
        }

        if (farms.isEmpty) {
          return SliverFillRemaining(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    query.isNotEmpty ? Icons.search_off : Icons.agriculture_outlined,
                    size: 28,
                    color: isDarkMode ? Colors.white.withOpacity(0.12) : Colors.black.withOpacity(0.12),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    query.isNotEmpty ? 'AUCUN RÉSULTAT' : 'AUCUNE FERME PUBLIQUE',
                    style: TextStyle(
                      fontSize: 10,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w300,
                      color: isDarkMode ? Colors.white.withOpacity(0.24) : Colors.black.withOpacity(0.24),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        // Count header
        return SliverList(
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              if (index == 0) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Row(
                    children: [
                      Text(
                        '${farms.length} FERME${farms.length > 1 ? 'S' : ''}',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.5,
                          color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3),
                        ),
                      ),
                      if (_followedFarmIds.isNotEmpty) ...[
                        const SizedBox(width: 16),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppColors.accent.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: Text(
                            '${_followedFarmIds.length} SUIVI${_followedFarmIds.length > 1 ? 'ES' : 'E'}',
                            style: const TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w400,
                              letterSpacing: 1.0,
                              color: AppColors.accent,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }
              final farm = farms[index - 1] as Map<String, dynamic>;
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildPublicFarmCard(farm, isDarkMode),
              );
            },
            childCount: farms.length + 1,
          ),
        );
      },
    );
  }

  Widget _buildPublicFarmCard(Map<String, dynamic> farm, bool isDarkMode) {
    final farmName = farm['farm_name'] ?? 'Ferme';
    final farmImage = (farm['profile_image_farm'] ?? farm['image_url']) as String?;
    final farmId = (farm['farm_id'] ?? farm['id']) as int?;
    final farmOwnerId = (farm['user_id']) as int?;
    final location = farm['location'] ?? '';
    
    // Initialize followers count from farm data on first load
    final initialFollowers = farm['followers'] ?? farm['total_followers'] ?? 0;
    if (farmId != null && !_farmFollowersCount.containsKey(farmId)) {
      _farmFollowersCount[farmId] = initialFollowers;
    }
    
    // Use tracked followers count if available, otherwise use farm data
    final followers = (farmId != null && _farmFollowersCount.containsKey(farmId))
        ? _farmFollowersCount[farmId]!
        : initialFollowers;
    
    final isFollowed = farmId != null && _followedFarmIds.contains(farmId);

    final borderColor = isDarkMode ? Colors.white.withOpacity(0.07) : Colors.black.withOpacity(0.07);
    final cardBg = isDarkMode ? AppColors.getCardBgColor(isDarkMode) : Colors.white;

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        border: Border.all(color: borderColor, width: 1),
        borderRadius: BorderRadius.circular(6),
        boxShadow: [
          BoxShadow(
            color: isDarkMode ? Colors.black.withOpacity(0.15) : Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image section ──────────────────────────────────────────
          ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            child: SizedBox(
              height: 180,
              width: double.infinity,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background image
                  farmImage != null && farmImage.isNotEmpty
                      ? Image.network(
                          farmImage,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => _imagePlaceholder(isDarkMode),
                        )
                      : _imagePlaceholder(isDarkMode),

                  // Gradient overlay for bottom readability
                  Positioned.fill(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          stops: const [0.45, 1.0],
                          colors: [
                            Colors.transparent,
                            Colors.black.withOpacity(0.55),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // ── FOLLOWERS BADGE (prominent, bottom-left) ──────
                  Positioned(
                    bottom: 12,
                    left: 12,
                    child: _buildFollowersBadge(followers, isDarkMode),
                  ),

                  // ── FOLLOW BUTTON (top-right) ─────────────────────
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _buildFollowButton(farmId, isFollowed, isDarkMode),
                  ),

                  // ── Followed indicator dot (top-left) ──────────────
                  if (isFollowed)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.accent.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check, size: 10, color: Colors.white),
                            SizedBox(width: 4),
                            Text(
                              'ABONNÉ',
                              style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.8,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // ── Info section ───────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Farm name + location
                Text(
                  farmName.toUpperCase(),
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1.8,
                    color: isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.place_outlined,
                          size: 12,
                          color: isDarkMode
                              ? Colors.white.withOpacity(0.35)
                              : Colors.black.withOpacity(0.35)),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            color: isDarkMode
                                ? Colors.white.withOpacity(0.35)
                                : Colors.black.withOpacity(0.40),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 14),

                // Divider
                Divider(
                  height: 1,
                  thickness: 1,
                  color: isDarkMode ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.06),
                ),
                const SizedBox(height: 14),

                // Onglets CULTURES / BÉTAIL
                _buildResourceTabs(farmId, isDarkMode),
                const SizedBox(height: 12),
                // Contenu des onglets
                _buildResourceContent(farmId, farmOwnerId, isDarkMode),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFollowersBadge(dynamic followers, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.55),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(
          color: Colors.white.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.people_outline, size: 13, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            _formatFollowers(followers),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'abonné${(followers as int) > 1 ? 's' : ''}',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w300,
              color: Colors.white.withOpacity(0.75),
            ),
          ),
        ],
      ),
    );
  }

  String _formatFollowers(dynamic raw) {
    final n = (raw is int) ? raw : int.tryParse(raw.toString()) ?? 0;
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return n.toString();
  }

  Widget _buildFollowButton(int? farmId, bool isFollowed, bool isDarkMode) {
    return GestureDetector(
      onTap: farmId != null ? () => _toggleFollowFarm(farmId) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isFollowed
              ? Colors.white.withOpacity(0.15)
              : Colors.white,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: isFollowed ? Colors.white.withOpacity(0.3) : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isFollowed ? Icons.person_remove_outlined : Icons.person_add_outlined,
              size: 13,
              color: isFollowed ? Colors.white : Colors.black87,
            ),
            const SizedBox(width: 6),
            Text(
              isFollowed ? 'SE DÉSABONNER' : 'SUIVRE',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.8,
                color: isFollowed ? Colors.white : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResourceTabs(int? farmId, bool isDarkMode) {
    if (farmId == null) return const SizedBox();
    
    final isCropsTab = _farmTabSelection[farmId] ?? true;
    
    return Row(
      children: [
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _farmTabSelection[farmId] = true),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: isCropsTab ? AppColors.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.landscape_outlined,
                    size: 14,
                    color: isCropsTab
                        ? AppColors.accent
                        : (isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'CULTURES',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCropsTab ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: 1.2,
                      color: isCropsTab
                          ? AppColors.accent
                          : (isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _farmTabSelection[farmId] = false),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: !isCropsTab ? AppColors.accent : Colors.transparent,
                    width: 2,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pets_outlined,
                    size: 14,
                    color: !isCropsTab
                        ? AppColors.accent
                        : (isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4)),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'BÉTAIL',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: !isCropsTab ? FontWeight.w600 : FontWeight.w400,
                      letterSpacing: 1.2,
                      color: !isCropsTab
                          ? AppColors.accent
                          : (isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.4)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResourceContent(int? farmId, int? farmOwnerId, bool isDarkMode) {
    if (farmId == null) return const SizedBox();
    
    final isCropsTab = _farmTabSelection[farmId] ?? true;
    
    if (isCropsTab) {
      return FutureBuilder<List<dynamic>>(
        future: _getCropsCached(farmId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                minHeight: 2,
                borderRadius: BorderRadius.circular(2),
                color: AppColors.accent.withOpacity(0.3),
                backgroundColor: isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
              ),
            );
          }
          final parcels = snapshot.data ?? [];
          return _buildParcelsSection(farmId, farmOwnerId, parcels, isDarkMode);
        },
      );
    } else {
      return FutureBuilder<List<dynamic>>(
        future: _getLivestockCached(farmId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SizedBox(
              height: 4,
              child: LinearProgressIndicator(
                minHeight: 2,
                borderRadius: BorderRadius.circular(2),
                color: AppColors.accent.withOpacity(0.3),
                backgroundColor: isDarkMode
                    ? Colors.white.withOpacity(0.05)
                    : Colors.black.withOpacity(0.05),
              ),
            );
          }
          final livestock = snapshot.data ?? [];
          return _buildLivestockSection(livestock, isDarkMode);
        },
      );
    }
  }

  Widget _buildParcelsSection(
      int? farmId, int? farmOwnerId, List<dynamic> parcels, bool isDarkMode) {
    if (parcels.isEmpty) {
      return _buildViewParcelsButton(
        farmId,
        farmOwnerId,
        label: 'VOIR LES PARCELLES',
        isDarkMode: isDarkMode,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.grid_view_outlined,
                size: 12,
                color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
            const SizedBox(width: 6),
            Text(
              '${parcels.length} PARCELLE${parcels.length > 1 ? 'S' : ''}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.2,
                color: isDarkMode ? Colors.white.withOpacity(0.35) : Colors.black.withOpacity(0.35),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: parcels.take(4).map((parcel) {
            final cropName = (parcel['crop_name'] ?? 'N/A').toString();
            final display = cropName.length > 14 ? '${cropName.substring(0, 14)}…' : cropName;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: AppColors.accent.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Text(
                display,
                style: const TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                  color: Color(0xFF5A7A1E),
                ),
              ),
            );
          }).toList(),
        ),
        if (parcels.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '+${parcels.length - 4} autres cultures',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w300,
                color: isDarkMode ? Colors.white.withOpacity(0.22) : Colors.black.withOpacity(0.22),
              ),
            ),
          ),
        const SizedBox(height: 12),
        _buildViewParcelsButton(
          farmId,
          farmOwnerId,
          label: 'VOIR TOUTES LES PARCELLES →',
          isDarkMode: isDarkMode,
          accent: true,
        ),
      ],
    );
  }

  Widget _buildViewParcelsButton(
    int? farmId,
    int? farmOwnerId, {
    required String label,
    required bool isDarkMode,
    bool accent = false,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParcelScreen(
              farmId: farmId ?? 0,
              userId: 0,
              farmOwnerId: farmOwnerId,
              readOnly: true,
            ),
          ),
        );
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: accent ? AppColors.accent.withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: accent
                ? AppColors.accent.withOpacity(0.35)
                : isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
            color: accent
                ? AppColors.accent
                : isDarkMode ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Widget _buildLivestockSection(List<dynamic> livestock, bool isDarkMode) {
    if (livestock.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.pets_outlined,
                  size: 12,
                  color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
              const SizedBox(width: 6),
              Text(
                'AUCUN ANIMAL',
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 1.2,
                  color: isDarkMode ? Colors.white.withOpacity(0.35) : Colors.black.withOpacity(0.35),
                ),
              ),
            ],
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.pets_outlined,
                size: 12,
                color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.3)),
            const SizedBox(width: 6),
            Text(
              '${livestock.length} ANIMAL${livestock.length > 1 ? 'UX' : ''}',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w400,
                letterSpacing: 1.2,
                color: isDarkMode ? Colors.white.withOpacity(0.35) : Colors.black.withOpacity(0.35),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: livestock.take(4).map((animal) {
            final animalType = (animal['animal_type'] ?? 'N/A').toString();
            final breed = (animal['breed'] ?? '').toString();
            final display = breed.isNotEmpty
                ? '$animalType ($breed)'
                : animalType;
            final truncated = display.length > 16 ? '${display.substring(0, 16)}…' : display;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.orange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(
                  color: Colors.orange.withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Text(
                truncated,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 0.3,
                  color: Colors.orange[700],
                ),
              ),
            );
          }).toList(),
        ),
        if (livestock.length > 4)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
              '+${livestock.length - 4} autres animaux',
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w300,
                color: isDarkMode ? Colors.white.withOpacity(0.22) : Colors.black.withOpacity(0.22),
              ),
            ),
          ),
      ],
    );
  }

  Widget _imagePlaceholder(bool isDarkMode) {
    return Container(
      color: isDarkMode ? Colors.white.withOpacity(0.04) : Colors.black.withOpacity(0.03),
      child: Center(
        child: Icon(
          Icons.landscape_outlined,
          size: 36,
          color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
        ),
      ),
    );
  }
}