import 'package:flutter/material.dart';

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

class FarmTab extends StatefulWidget {
  final int? userId;
  final int initialSection;

  const FarmTab({super.key, this.userId, this.initialSection = 0});

  @override
  State<FarmTab> createState() => _FarmTabState();
}

class _FarmTabState extends State<FarmTab> {
  Future<List<dynamic>>? _farmsFuture;
  Future<List<dynamic>>? _livestockFuture;
  int _selectedSection = 0;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  
  // STATIC PERSISTENT CACHE - survives widget rebuilds and navigation
  static final Map<String, Future<List<dynamic>>> _globalDataCache = {};
  static final Map<int, Future<List<dynamic>>> _globalCropsCache = {};

  @override
  void initState() {
    super.initState();
    _selectedSection = widget.initialSection;
    _searchController.addListener(() {
      if (_searchQuery != _searchController.text) {
        setState(() => _searchQuery = _searchController.text);
      }
    });
    _loadFarms();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _loadFarms() {
    // Use cached future - reuse if already exists
    _farmsFuture = _getFarmsCached();
  }
  
  /// Get farms with persistent caching by userId
  Future<List<dynamic>> _getFarmsCached() {
    final isAuthenticated = AuthService.currentSession != null;
    final currentUserId = AuthService.currentSession?.userId;
    
    // If authenticated and viewing own farms (userId is null), get user's farms
    if (isAuthenticated && widget.userId == null) {
      final cacheKey = 'farms_user_$currentUserId';
      if (!_globalDataCache.containsKey(cacheKey)) {
        _globalDataCache[cacheKey] = currentUserId != null
            ? ApiService.getPublicUserFarms(currentUserId)
            : Future.value([]);
      }
      return _globalDataCache[cacheKey]!;
    }
    
    // If viewing other user's public farms
    if (widget.userId != null) {
      final cacheKey = 'farms_${widget.userId}';
      if (!_globalDataCache.containsKey(cacheKey)) {
        _globalDataCache[cacheKey] = ApiService.getPublicUserFarms(widget.userId!);
      }
      return _globalDataCache[cacheKey]!;
    }
    
    // Fallback: return empty list
    return Future.value([]);
  }
  
  /// Get livestock with persistent caching by userId
  Future<List<dynamic>> _getLivestockCached() {
    if (widget.userId == null) return Future.value([]);
    final cacheKey = 'livestock_${widget.userId}';
    if (!_globalDataCache.containsKey(cacheKey)) {
      _globalDataCache[cacheKey] = ApiService.getUserLivestock(widget.userId!);
    }
    return _globalDataCache[cacheKey]!;
  }
  
  /// Get crops with persistent caching by farmId
  Future<List<dynamic>> _getCropsCached(int farmId) {
    if (!_globalCropsCache.containsKey(farmId)) {
      _globalCropsCache[farmId] = ApiService.getFarmCrops(farmId);
    }
    return _globalCropsCache[farmId]!;
  }

  /// Sort farms by creation date (newest first)
  List<dynamic> _sortFarmsByDate(List<dynamic> farms) {
    final sorted = List<dynamic>.from(farms);
    sorted.sort((a, b) {
      final dateA = a['created_at'] as String?;
      final dateB = b['created_at'] as String?;
      if (dateA == null || dateB == null) return 0;
      try {
        final parsedA = DateTime.parse(dateA);
        final parsedB = DateTime.parse(dateB);
        return parsedB.compareTo(parsedA); // Descending (newest first)
      } catch (e) {
        return 0;
      }
    });
    return sorted;
  }

  Future<Map<String, dynamic>> _getFirstFarmData() async {
    try {
      final farms = await _farmsFuture;
      if (farms != null && farms.isNotEmpty) {
        final firstFarm = farms.first as Map<String, dynamic>;
        return {
          'id': (firstFarm['id'] as int?) ?? 0,
          'name': (firstFarm['name'] as String?) ?? 'Ferme',
        };
      }
      return {'id': 0, 'name': 'Ferme'};
    } catch (e) {
      return {'id': 0, 'name': 'Ferme'};
    }
  }

  @override
  void didUpdateWidget(FarmTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      // Only clear farm and livestock data when user changes
      // Keep crop cache to avoid reloading when navigating back
      _farmsFuture = null;
      _livestockFuture = null;
      _selectedSection = widget.initialSection;
      _loadFarms();
      setState(() {});
    }
  }

  Future<void> _deleteFarm(int farmId, String farmName, bool isDarkMode) async {
    final scaffoldContext = context; // Save outer context before dialog
    
    await showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: isDarkMode ? AppColors.darkBg : AppColors.lightBgAlt,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'SUPPRIMER LA FERME',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "$farmName"? Cette action est irréversible.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: isDarkMode ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(
              'ANNULER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
                color: isDarkMode ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              try {
                await ApiService.deleteFarm(farmId);
                if (mounted) {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: const Text(
                        'FERME SUPPRIMÉE',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.5,
                        ),
                      ),
                      backgroundColor: Colors.black87,
                      behavior: SnackBarBehavior.floating,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                  );
                  _refreshFarms();
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(scaffoldContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'ERREUR: ${e.toString().replaceAll('Exception: ', '')}',
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.5,
                        ),
                      ),
                      backgroundColor: Colors.red.shade400,
                      behavior: SnackBarBehavior.floating,
                      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                    ),
                  );
                }
              }
            },
            child: const Text(
              'SUPPRIMER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _refreshFarms() async {
    if (_selectedSection == 0) {
      // Clear farms cache and reload
      final farmsCacheKey = 'farms_${widget.userId ?? 'public'}';
      _globalDataCache.remove(farmsCacheKey);
      _farmsFuture = _getFarmsCached();
      _searchController.clear();
      _searchQuery = '';
      // Clear crops cache on explicit refresh
      _globalCropsCache.clear();
    } else if (widget.userId != null) {
      // Clear livestock cache and reload
      final livestockCacheKey = 'livestock_${widget.userId}';
      _globalDataCache.remove(livestockCacheKey);
      _livestockFuture = _getLivestockCached();
    }
    setState(() {});
    imageCache.clearLiveImages();
    imageCache.clear();
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    final isMobile = MediaQuery.of(context).size.width < 768;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBg : AppColors.lightBg,
      body: isMobile 
          ? _buildMobileLayout(isDarkMode)
          : _buildDesktopLayout(isDarkMode),
    );
  }

  Widget _buildMobileLayout(bool isDarkMode) {
    return Scaffold(
      backgroundColor: isDarkMode ? AppColors.darkBg : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: isDarkMode ? AppColors.darkBg : AppColors.lightBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          'MA FERME',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.5,
            color: isDarkMode ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
      ),
      drawer: Drawer(
        backgroundColor: isDarkMode ? AppColors.darkBg : AppColors.lightBg,
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.symmetric(vertical: 32),
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 40),
                child: Text(
                  'NAVIGATION',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              _buildMinimalSidebarItem(0, 'VUE D\'ENSEMBLE', Icons.home_outlined, isDarkMode),
              _buildMinimalSidebarItem(0, 'CULTURES', Icons.landscape_outlined, isDarkMode),
              _buildMinimalSidebarItem(1, 'ANIMAUX', Icons.pets_outlined, isDarkMode),
              _buildMinimalSidebarItem(0, 'SERRE', Icons.thermostat_outlined, isDarkMode),
              _buildMinimalSidebarItem(0, 'ÉQUIPEMENTS', Icons.build_outlined, isDarkMode),
              const SizedBox(height: 32),
              Padding(
                padding: const EdgeInsets.only(left: 24, bottom: 16),
                child: Text(
                  'PUBLIC',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              _buildPublicNavItem('VISITER FERMES', Icons.public_outlined, isDarkMode),
            ],
          ),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.accent,
        backgroundColor: isDarkMode ? AppColors.darkBg : AppColors.lightBg,
        onRefresh: _refreshFarms,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: _buildFarmMapView(isDarkMode),
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalSidebarItem(int section, String label, IconData icon, bool isDarkMode) {
    final isSelected = _selectedSection == section;
    return GestureDetector(
      onTap: () {
        setState(() => _selectedSection = section);
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02))
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected 
                  ? AppColors.accent
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected 
                  ? (isDarkMode ? Colors.white : Colors.black87)
                  : (isDarkMode ? Colors.white38 : Colors.black38),
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
                color: isSelected 
                    ? (isDarkMode ? Colors.white : Colors.black87)
                    : (isDarkMode ? Colors.white38 : Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPublicNavItem(String label, IconData icon, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => const PublicFarmsScreen(),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.transparent,
          border: Border(
            left: BorderSide(
              color: Colors.transparent,
              width: 1.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isDarkMode ? Colors.white38 : Colors.black38,
            ),
            const SizedBox(width: 16),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
                color: isDarkMode ? Colors.white38 : Colors.black38,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopLayout(bool isDarkMode) {
    return Row(
      children: [
        // Sidebar minimaliste
        Container(
          width: 240,
          decoration: BoxDecoration(
            color: isDarkMode ? AppColors.darkBg : AppColors.lightBg,
            border: Border(
              right: BorderSide(
                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
          ),
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),
                Padding(
                  padding: const EdgeInsets.only(left: 24),
                  child: Text(
                    'MA FERME',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 2.5,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                ),
                const SizedBox(height: 48),
                _buildMinimalSidebarItem(0, 'VUE D\'ENSEMBLE', Icons.home_outlined, isDarkMode),
                _buildMinimalSidebarItem(0, 'CULTURES', Icons.landscape_outlined, isDarkMode),
                _buildMinimalSidebarItem(1, 'ANIMAUX', Icons.pets_outlined, isDarkMode),
                _buildMinimalSidebarItem(0, 'SERRE', Icons.thermostat_outlined, isDarkMode),
                _buildMinimalSidebarItem(0, 'ÉQUIPEMENTS', Icons.build_outlined, isDarkMode),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.only(left: 24, bottom: 24),
                  child: Text(
                    'PUBLIC',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      color: isDarkMode ? Colors.white38 : Colors.black38,
                      letterSpacing: 2.0,
                    ),
                  ),
                ),
                _buildPublicNavItem('VISITER FERMES', Icons.public_outlined, isDarkMode),
                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
        // Main content
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshFarms,
            color: AppColors.accent,
            backgroundColor: isDarkMode ? AppColors.darkBg : AppColors.lightBg,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: _buildFarmMapView(isDarkMode),
                  ),
                  if (widget.userId == null)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
                      child: _buildAerialViewButton(isDarkMode),
                    ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAerialViewButton(bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FutureBuilder<Map<String, dynamic>>(
              future: _getFirstFarmData(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null) {
                  final farmData = snapshot.data!;
                  return ParcelScreen(
                    farmId: farmData['id'] as int? ?? 0,
                    userId: widget.userId ?? 0,
                  );
                }
                return const Scaffold(
                  body: Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 24),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.satellite_outlined,
              size: 16,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
            const SizedBox(width: 12),
            Text(
              'VUE AÉRIENNE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
                color: isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmMapView(bool isDarkMode) {
    final isAuthenticated = AuthService.currentSession != null;

    // If not authenticated, show welcome screen directly
    if (!isAuthenticated) {
      return _buildWelcomeScreen(isDarkMode);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FutureBuilder<List<dynamic>>(
          future: _selectedSection == 1 ? _getLivestockCached() : _getFarmsCached(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return SizedBox(
                height: 400,
                child: Center(
                  child: SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 1,
                      color: isDarkMode ? Colors.white24 : Colors.black12,
                    ),
                  ),
                ),
              );
            }
            
            final items = snapshot.data ?? [];

            if (items.isEmpty) {
              return _buildEmptyAuthenticatedState(isDarkMode);
            }

            if (_selectedSection == 0) {
              return _buildFarmsGrid(items, isDarkMode);
            }
            
            return _buildContent(isDarkMode);
          },
        ),
      ],
    );
  }

  Widget _buildWelcomeScreen(bool isDarkMode) {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Hero section épuré
          SizedBox(
            height: 220,
            width: double.infinity,
            child: Stack(
              fit: StackFit.expand,
              children: [
                const FadingImagesWidget(
                  imageUrls: [
                    'https://res.cloudinary.com/dcs9vkwe0/image/upload/v1769257913/kxbovkugo5ertntwwtgv.jpg',
                    'https://res.cloudinary.com/dcs9vkwe0/image/upload/v1769258097/hcrl7a4o7ttp9idaaf4j.jpg',
                    'https://res.cloudinary.com/dcs9vkwe0/image/upload/v1769259314/lukvpj3povcqtbahoe0f.jpg',
                    'https://res.cloudinary.com/dcs9vkwe0/image/upload/v1769259315/xmyyggmzlwr1w1lti5w8.jpg',
                    'https://res.cloudinary.com/dcs9vkwe0/image/upload/v1769259313/ecjpbmfnxdzlmpmk73gy.jpg',
                    'https://res.cloudinary.com/dcs9vkwe0/image/upload/v1769259314/l6sbxk2stvbossbgjlyn.jpg',
                  ],
                  height: 220,
                  displayDuration: Duration(seconds: 3),
                  fadeDuration: Duration(milliseconds: 800),
                ),
                // Overlay minimal
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.2),
                          Colors.black.withOpacity(0.6),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 40),
          
          // Branding minimaliste
          Column(
            children: [
              Text(
                'SAVANA',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w200,
                  letterSpacing: 8.0,
                  color: isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Agriculture moderne',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.5,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                ),
              ),
            ],
          ),

          const SizedBox(height: 64),
          
          // Boutons minimalistes
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pushNamed('/login'),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text(
                      'SE CONNECTER',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SocialFeedScreen(isDarkMode: isDarkMode),
                        ),
                      );
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 18),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      side: BorderSide(
                        color: isDarkMode ? Colors.white24 : Colors.black26,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'DÉCOUVRIR',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2.0,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Explorez des fermes publiques',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.5,
                    color: isDarkMode ? Colors.white38 : Colors.black38,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 64),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyAuthenticatedState(bool isDarkMode) {
    return Container(
      height: 400,
      alignment: Alignment.center,
      color: isDarkMode ? AppColors.darkBg : Colors.transparent,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            _selectedSection == 1 ? Icons.pets_outlined : Icons.landscape_outlined,
            size: 40,
            color: isDarkMode ? Colors.white38 : Colors.black26,
          ),
          const SizedBox(height: 32),
          Text(
            _selectedSection == 1 ? 'AUCUN ANIMAL' : 'AUCUNE FERME',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              letterSpacing: 2.0,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 48),
          // Two action buttons
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                // Button 1: Create Farm
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateFarmScreen(
                            userId: AuthService.currentSession?.userId,
                          ),
                        ),
                      ).then((_) => _refreshFarms());
                    },
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black87,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                    ),
                    child: const Text(
                      'CRÉER UNE FERME',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2.0,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Button 2: Add Livestock
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => CreateLivestockScreen(
                            userId: AuthService.currentSession?.userId,
                          ),
                        ),
                      ).then((_) => _refreshFarms());
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.zero,
                      ),
                      side: BorderSide(
                        color: isDarkMode ? Colors.white24 : Colors.black26,
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'AJOUTER DU BÉTAIL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2.0,
                        color: isDarkMode ? Colors.white70 : Colors.black87,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFarmsGrid(List<dynamic> farms, bool isDarkMode) {
    final sortedFarms = _sortFarmsByDate(farms);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: MediaQuery.of(context).size.width < 768 ? 1 : 2,
          childAspectRatio: 0.85,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
        ),
        itemCount: sortedFarms.length,
        itemBuilder: (context, index) {
          final farm = sortedFarms[index] as Map<String, dynamic>;
          return _buildFarmCard(farm, isDarkMode);
        },
      ),
    );
  }

  Widget _buildFarmCard(Map<String, dynamic> farm, bool isDarkMode) {
    final farmName = farm['name'] ?? 'Ferme';
    final farmImage = farm['image_url'] as String?;
    final farmId = farm['id'] as int?;
    final location = farm['location'] ?? '';
    final currentUserId = AuthService.currentSession?.userId ?? 0;
    final farmOwnerId = farm['user_id'] as int? ?? 0;
    final isOwner = currentUserId == farmOwnerId && currentUserId > 0;
    
    return GestureDetector(
      onTap: () {
        // Navigate to farm details
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkBg : AppColors.lightBgAlt,
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec delete button
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    color: isDarkMode ? AppColors.darkCardBg : AppColors.lightCardBg,
                    child: farmImage != null && farmImage.isNotEmpty
                        ? Image.network(
                            farmImage,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) {
                              return Center(
                                child: Icon(
                                  Icons.landscape_outlined,
                                  size: 32,
                                  color: isDarkMode ? Colors.white12 : Colors.black12,
                                ),
                              );
                            },
                          )
                        : Center(
                            child: Icon(
                              Icons.landscape_outlined,
                              size: 32,
                              color: isDarkMode ? Colors.white12 : Colors.black12,
                            ),
                          ),
                  ),
                  // Edit & Delete buttons - visible only to owner
                  if (isOwner)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Row(
                        children: [
                          // Edit button
                          GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => EditFarmScreen(
                                    farm: farm,
                                    isDarkMode: isDarkMode,
                                    userId: widget.userId,
                                  ),
                                ),
                              ).then((_) => _refreshFarms());
                            },
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.accent.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.edit_outlined,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Delete button
                          GestureDetector(
                            onTap: () => _deleteFarm(farmId ?? 0, farmName, isDarkMode),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.error.withOpacity(0.9),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(
                                Icons.delete_outline,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            // Info et parcelles
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farmName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.5,
                            color: isDarkMode ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (location.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            location,
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0.5,
                              color: isDarkMode ? Colors.white38 : Colors.black38,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                    // Parcelles dynamiques (with caching)
                    FutureBuilder<List<dynamic>>(
                      future: _getCropsCached(farmId ?? 0),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Column(
                            children: [
                              SizedBox(
                                height: 8,
                                child: LinearProgressIndicator(
                                  minHeight: 1,
                                  color: AppColors.accent.withOpacity(0.5),
                                  backgroundColor: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                                ),
                              ),
                            ],
                          );
                        }

                        final parcels = snapshot.data ?? [];
                        
                        if (parcels.isEmpty) {
                          return GestureDetector(
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ParcelScreen(
                                    farmId: farmId ?? 0,
                                    userId: widget.userId ?? 0,
                                  ),
                                ),
                              );
                            },
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'VOIR PARCELLES',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1.5,
                                  color: isDarkMode ? Colors.white70 : Colors.black87,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          );
                        }

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'PARCELLES (${parcels.length})',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.0,
                                color: isDarkMode ? Colors.white38 : Colors.black38,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: parcels.take(3).map((parcel) {
                                final cropName = parcel['crop_name'] ?? 'N/A';
                                return Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: AppColors.accent.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: AppColors.accent.withOpacity(0.3),
                                      width: 0.5,
                                    ),
                                  ),
                                  child: Text(
                                    cropName.length > 12 ? '${cropName.substring(0, 12)}...' : cropName,
                                    style: const TextStyle(
                                      fontSize: 8,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 0.5,
                                      color: Color(0xFF6B8E23),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            if (parcels.length > 3) ...[
                              const SizedBox(height: 6),
                              Text(
                                '+${parcels.length - 3} autres',
                                style: TextStyle(
                                  fontSize: 8,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 0.5,
                                  color: isDarkMode ? Colors.white24 : Colors.black26,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            GestureDetector(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => ParcelScreen(
                                      farmId: farmId ?? 0,
                                      userId: widget.userId ?? 0,
                                    ),
                                  ),
                                );
                              },
                              child: Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: AppColors.accent.withOpacity(0.3),
                                    width: 1,
                                  ),
                                ),
                                child: const Text(
                                  'VOIR TOUT',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w300,
                                    letterSpacing: 1.5,
                                    color: Color(0xFF6B8E23),
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDarkMode) {
    if (widget.userId == null) {
      return _buildWelcomeScreen(isDarkMode);
    }

    return FutureBuilder<List<dynamic>>(
      future: _getFarmsCached(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 1,
                  color: isDarkMode ? Colors.white24 : Colors.black12,
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
            child: Column(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 32,
                  color: isDarkMode ? Colors.white12 : Colors.black12,
                ),
                const SizedBox(height: 24),
                Text(
                  'ERREUR',
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 11,
                    letterSpacing: 2.0,
                    color: isDarkMode ? Colors.white24 : Colors.black26,
                  ),
                ),
                const SizedBox(height: 24),
                TextButton(
                  onPressed: _refreshFarms,
                  child: Text(
                    'RÉESSAYER',
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 10,
                      letterSpacing: 1.5,
                      color: isDarkMode ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final farms = snapshot.data ?? [];

        return SingleChildScrollView(
          physics: const NeverScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (_selectedSection == 0) ...[
                // Search bar minimaliste
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
                  child: TextField(
                    controller: _searchController,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Rechercher',
                      hintStyle: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 1.0,
                        color: isDarkMode ? Colors.white24 : Colors.black26,
                      ),
                      prefixIcon: Icon(
                        Icons.search,
                        size: 18,
                        color: isDarkMode ? Colors.white24 : Colors.black26,
                      ),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: Icon(
                                Icons.close,
                                size: 18,
                                color: isDarkMode ? Colors.white24 : Colors.black26,
                              ),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: false,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.zero,
                        borderSide: BorderSide(
                          color: isDarkMode ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.2),
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                  ),
                ),

                if (farms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.agriculture_outlined,
                            size: 32,
                            color: isDarkMode ? Colors.white12 : Colors.black12,
                          ),
                          const SizedBox(height: 24),
                          Text(
                            'AUCUNE FERME',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2.0,
                              color: isDarkMode ? Colors.white24 : Colors.black26,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                else
                  Builder(builder: (context) {
                    final query = _searchQuery.trim().toLowerCase();
                    final filtered = query.isEmpty
                        ? farms
                        : farms.where((f) {
                            final name = (f['name'] ?? '').toString().toLowerCase();
                            final location = (f['location'] ?? '').toString().toLowerCase();
                            return name.contains(query) || location.contains(query);
                          }).toList();

                    // Sort by date (newest first)
                    final sortedFiltered = _sortFarmsByDate(filtered);

                    if (sortedFiltered.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 80),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 32,
                                color: isDarkMode ? Colors.white12 : Colors.black12,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'AUCUN RÉSULTAT',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 2.0,
                                  color: isDarkMode ? Colors.white24 : Colors.black26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: sortedFiltered.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemBuilder: (context, index) => _buildFarmCard(
                        sortedFiltered[index] as Map<String, dynamic>,
                        isDarkMode,
                      ),
                    );
                  }),
              ] else if (_selectedSection == 1) ...[
                FutureBuilder<List<dynamic>>(
                  future: _getLivestockCached(),
                  builder: (context, lsnap) {
                    if (lsnap.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Center(
                          child: SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 1,
                              color: isDarkMode ? Colors.white24 : Colors.black12,
                            ),
                          ),
                        ),
                      );
                    }
                    if (lsnap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.error_outline,
                                size: 32,
                                color: isDarkMode ? Colors.white12 : Colors.black12,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'ERREUR',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 2.0,
                                  color: isDarkMode ? Colors.white24 : Colors.black26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    final animals = lsnap.data ?? [];
                    if (animals.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 80),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.pets_outlined,
                                size: 32,
                                color: isDarkMode ? Colors.white12 : Colors.black12,
                              ),
                              const SizedBox(height: 24),
                              Text(
                                'AUCUN ANIMAL',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 2.0,
                                  color: isDarkMode ? Colors.white24 : Colors.black26,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: animals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) => _buildAnimalCard(
                        animals[index] as Map<String, dynamic>,
                        isDarkMode,
                      ),
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildAnimalCard(Map<String, dynamic> animal, bool isDarkMode) {
    final animalType = animal['animal_type'] as String? ?? 'Animal';
    final breed = animal['breed'] as String? ?? '';
    final quantity = animal['quantity'] as int? ?? 1;
    final photo = animal['image_url'] ?? 
                  animal['imageUrl'] ?? 
                  (animal['photos'] is List && (animal['photos'] as List).isNotEmpty 
                      ? (animal['photos'] as List).first 
                      : null);
    final livestockId = animal['id'] as int?;

    return GestureDetector(
      onTap: livestockId != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditLivestockScreen(
                    livestockId: livestockId,
                    livestock: animal,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: isDarkMode ? AppColors.darkBg : AppColors.lightBgAlt,
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: isDarkMode ? AppColors.darkCardBg : AppColors.lightCardBg,
                image: photo != null 
                    ? DecorationImage(
                        image: NetworkImage(photo),
                        fit: BoxFit.cover,
                      ) 
                    : null,
              ),
              child: photo == null 
                  ? Icon(
                      Icons.pets,
                      color: isDarkMode ? Colors.white12 : Colors.black12,
                      size: 24,
                    ) 
                  : null,
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animalType.toUpperCase(),
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 1.5,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                  ),
                  if (breed.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      breed,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.5,
                        color: isDarkMode ? Colors.white38 : Colors.black38,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                'x$quantity',
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 1.0,
                  color: isDarkMode ? Colors.white70 : Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Custom painter pour la carte minimaliste (optionnel)
class FarmMapPainter extends CustomPainter {
  final bool isDarkMode;

  FarmMapPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = isDarkMode ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // Lignes de grille minimalistes
    for (var i = 0; i < 6; i++) {
      final y = size.height / 6 * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }

    for (var i = 0; i < 8; i++) {
      final x = size.width / 8 * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}