import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:provider/provider.dart';
import 'dart:math' show min;
import 'package:mbaymi/widgets/empty_state.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/utils/app_theme.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/utils/app_spacing.dart';
import 'package:mbaymi/utils/app_typography.dart';
import 'package:mbaymi/utils/app_radius.dart';
import 'package:mbaymi/screens/create_farm_screen.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/widgets/random_tip_widget.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/screens/parcel_screen.dart';
import 'package:mbaymi/screens/create_livestock_screen.dart';
import 'package:mbaymi/screens/edit_livestock_screen.dart';
import 'package:mbaymi/screens/social_feed_screen.dart';
import 'package:mbaymi/widgets/fading_images_widget.dart';

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
  int? _lastKnownUserId;

  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _lastKnownUserId = widget.userId;
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
    _farmsFuture = (widget.userId != null
        ? ApiService.getPublicUserFarms(widget.userId!)
        : ApiService.getPublicFarms());
  }

  @override
  void didUpdateWidget(FarmTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      ApiService.clearCache();
      _lastKnownUserId = widget.userId;
      _farmsFuture = null;
      _livestockFuture = null;
      _selectedSection = widget.initialSection;
      _loadFarms();
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkForAuthChange();
    }
  }

  void _checkForAuthChange() {
    final currentUserId = AuthService.currentSession?.userId;
    if (_lastKnownUserId != currentUserId && currentUserId != null) {
      _lastKnownUserId = currentUserId;
      _loadFarms();
      _livestockFuture = null;
      _selectedSection = 0;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _refreshFarms() async {
    _checkForAuthChange();
    if (_selectedSection == 0) {
      _farmsFuture = widget.userId != null
          ? ApiService.getPublicUserFarms(widget.userId!)
          : ApiService.getPublicFarms();
      // clear search on manual refresh
      _searchController.clear();
      _searchQuery = '';
    } else if (widget.userId != null) {
      _livestockFuture = ApiService.getUserLivestock(widget.userId!);
    }
    setState(() {});
    imageCache.clearLiveImages();
    imageCache.clear();
  }

  Widget _buildFeatureCard({
    required String icon,
    required String title,
    required String description,
    required bool isDarkMode,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.getCardBgColor(isDarkMode),
        borderRadius: BorderRadius.circular(AppRadius.xl),
        border: Border.all(
          color: isDarkMode
              ? Colors.white.withOpacity(0.03)
              : Colors.black.withOpacity(0.02),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(
            icon,
            style: AppTypography.h2,
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.body.copyWith(
                    color: AppColors.getTextColor(isDarkMode),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  description,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.getTextColor(isDarkMode).withOpacity(0.7),
                    height: 1.5,
                    letterSpacing: 0.1,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTabs(bool isDarkMode) {
    const selectedColor = Color(0xFF6B8E23);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSection = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedSection == 0 ? selectedColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  '🌾 Fermes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    color: _selectedSection == 0 ? selectedColor : (isDarkMode ? Colors.white60 : Colors.black45),
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                if (widget.userId == null) {
                  _showAuthSheet(context);
                  return;
                }
                setState(() {
                  _selectedSection = 1;
                  _livestockFuture ??= ApiService.getUserLivestock(widget.userId!);
                });
              },
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedSection == 1 ? selectedColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  '🐄 Bétail',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w300,
                    color: _selectedSection == 1 ? selectedColor : (isDarkMode ? Colors.white60 : Colors.black45),
                    letterSpacing: -0.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _smallFeature({required String icon, required String label, required bool isDark}) {
    return Expanded(
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : AppColors.lightBg,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(child: Text(icon, style: const TextStyle(fontSize: 24))),
          ),
          const SizedBox(height: 8),
          Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : Colors.black87, fontWeight: FontWeight.w400)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.socialDark : AppColors.lightBg,
      body: RefreshIndicator(
        color: const Color(0xFF6B8E23),
        backgroundColor: isDarkMode ? AppTheme.socialDark : AppColors.lightBg,
        onRefresh: _refreshFarms,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: isDarkMode ? AppTheme.socialDark : AppColors.lightBg,
              elevation: 0,
              pinned: true,
              floating: false,
              snap: false,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 80.0,
              automaticallyImplyLeading: true,
              title: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode 
                          ? Colors.white.withOpacity(0.05) 
                          : Colors.black.withOpacity(0.03),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  'Fermes',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w200,
                    letterSpacing: -1,
                    color: isDarkMode ? Colors.white : const Color(0xFF0A0A0A),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: SliverToBoxAdapter(
                child: _buildContent(isDarkMode),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.userId != null
          ? Container(
              margin: EdgeInsets.only(
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
              child: FloatingActionButton(
                onPressed: () async {
                  if (_selectedSection == 1) {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateLivestockScreen(userId: widget.userId),
                      ),
                    );
                    if (result != null) {
                      setState(() {
                        _livestockFuture = ApiService.getUserLivestock(widget.userId!);
                      });
                    }
                  } else {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateFarmScreen(userId: widget.userId),
                      ),
                    );
                    if (result != null) setState(() {});
                  }
                },
                backgroundColor: isDarkMode 
                    ? const Color(0xFF0A0A0A) 
                    : Colors.white,
                foregroundColor: const Color(0xFF6B8E23),
                elevation: 0,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, size: 24),
              ),
            )
          : null,
    );
  }

  Widget _buildContent(bool isDarkMode) {
    if (widget.userId == null) {
      return SingleChildScrollView(
        child: Column(
          children: [
            // Clean hero - Images alternées avec fade
            Stack(
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
                  height: 200,
                  displayDuration: Duration(seconds: 2),
                  fadeDuration: Duration(milliseconds: 500),
                ),
                // Overlay dégradé + Emoji
                Positioned.fill(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.black.withOpacity(0.35),
                              AppTheme.socialDark.withOpacity(0.55),
                            ],
                          ),
                        ),
                      ),
                      // Emoji centré
                      Center(
                        child: Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.black.withOpacity(0.25),
                          ),
                          child: const Center(child: Text('🌾', style: TextStyle(fontSize: 32))),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),
            // Textes en dehors de la vidéo, centrés
            const Center(
              child: Column(
                children: [
                  Text(
                    'Savana',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0A0A0A),
                      letterSpacing: -0.6,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Plateforme agricole, simple & utile',
                    style: TextStyle(
                      fontSize: 13,
                      color: Color(0xFF666666),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.of(context).pushNamed('/login'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(154, 106, 142, 35),
                        foregroundColor: isDarkMode ? Colors.white : Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        elevation: 0,
                      ),
                      child: const Text('Se connecter', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => SocialFeedScreen(isDarkMode: isDarkMode)),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text('Découvrir', style: TextStyle(color: isDarkMode ? Colors.white70 : Colors.black87, fontSize: 15)),
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Explorez des fermes publiques et découvrez des producteurs locaux.',
                    style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white70 : Colors.black54, fontWeight: FontWeight.w300),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ],
        ),
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: _farmsFuture ?? (widget.userId != null
          ? ApiService.getPublicUserFarms(widget.userId!)
          : ApiService.getPublicFarms()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Center(
              child: Column(
                children: [
                  CircularProgressIndicator(
                    strokeWidth: 1.5,
                    color: const Color(0xFF6B8E23).withOpacity(0.3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chargement...',
                    style: TextStyle(
                      fontWeight: FontWeight.w200,
                      fontSize: 13,
                      color: isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3),
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
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
                  size: 40,
                  color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                ),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 15,
                    color: isDarkMode ? Colors.white.withOpacity(0.6) : Colors.black.withOpacity(0.5),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _refreshFarms,
                  child: const Text(
                    'Réessayer',
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      color: Color(0xFF6B8E23),
                    ),
                  ),
                ),
              ],
            ),
          );
        }

        final farms = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTabs(isDarkMode),
              const SizedBox(height: 16),
              if (_selectedSection == 0) ...[
                // Search bar for farms
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une ferme...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: isDarkMode ? const Color(0xFF0A0A0A) : AppColors.lightBg,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),

                if (farms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(
                            Icons.agriculture_outlined,
                            size: 40,
                            color: isDarkMode ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune ferme',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w200,
                              color: isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3),
                              letterSpacing: 0.3,
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

                    if (filtered.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 80, horizontal: 20),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(
                                Icons.search_off,
                                size: 40,
                                color: isDarkMode ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucune ferme trouvée',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w200,
                                  color: isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }

                    return Column(
                      children: [
                        // Vue carte géographique minimaliste
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: isDarkMode ? const Color(0xFF0A0A0A) : AppColors.lightBg,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: isDarkMode
                                    ? Colors.white.withOpacity(0.05)
                                    : Colors.black.withOpacity(0.03),
                                width: 1,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(24),
                              child: Stack(
                                children: [
                                  // Fond de carte stylisé
                                  CustomPaint(
                                    size: Size.infinite,
                                    painter: _MapPainter(isDarkMode: isDarkMode),
                                  ),
                                  
                                  // Marqueurs de fermes
                                  ...List.generate(
                                    min(filtered.length, 6),
                                    (index) {
                                      final farm = filtered[index];
                                      return Positioned(
                                        left: 20 + (index * 35) % 200,
                                        top: 30 + (index * 25) % 120,
                                        child: GestureDetector(
                                          onTap: () {
                                            Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                builder: (_) => ParcelScreen(
                                                  farmId: farm['id'] as int,
                                                  userId: widget.userId!,
                                                ),
                                              ),
                                            );
                                          },
                                          child: Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: const Color(0xFF6B8E23).withOpacity(0.9),
                                              borderRadius: BorderRadius.circular(12),
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black.withOpacity(0.15),
                                                  blurRadius: 8,
                                                  offset: const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: Center(
                                              child: Text(
                                                '🌾',
                                                style: TextStyle(
                                                  fontSize: 16,
                                                  color: Colors.white.withOpacity(0.9),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                  
                                  // Overlay dégradé subtil
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.transparent,
                                            isDarkMode
                                                ? Colors.black.withOpacity(0.3)
                                                : Colors.white.withOpacity(0.2),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ),
                                  
                                  // Légende
                                  Positioned(
                                    bottom: 12,
                                    right: 12,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: isDarkMode
                                            ? Colors.black.withOpacity(0.5)
                                            : Colors.white.withOpacity(0.7),
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF6B8E23),
                                              shape: BoxShape.circle,
                                            ),
                                          ),
                                          const SizedBox(width: 6),
                                          Text(
                                            '${filtered.length} ferme${filtered.length > 1 ? 's' : ''}',
                                            style: TextStyle(
                                              fontSize: 11,
                                              fontWeight: FontWeight.w300,
                                              color: isDarkMode ? Colors.white70 : Colors.black87,
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
                        ),
                        
                        // Liste des fermes
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) => _buildFarmCard(context, filtered[index] as Map<String, dynamic>, isDarkMode),
                        ),
                      ],
                    );
                  }),
              ] else if (_selectedSection == 1) ...[
                FutureBuilder<List<dynamic>>(
                  future: _livestockFuture ?? (widget.userId != null ? ApiService.getUserLivestock(widget.userId!) : Future.value([])),
                  builder: (context, lsnap) {
                    if (lsnap.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Center(
                          child: Column(
                            children: [
                              CircularProgressIndicator(
                                strokeWidth: 1.5,
                                color: const Color(0xFF6B8E23).withOpacity(0.3),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Chargement...',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w200,
                                  color: isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3),
                                ),
                              ),
                            ],
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
                                size: 40,
                                color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Erreur',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w200,
                                  color: isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3),
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
                                size: 40,
                                color: isDarkMode ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.1),
                              ),
                              const SizedBox(height: 16),
                              Text(
                                'Aucun animal',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w200,
                                  color: isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3),
                                  letterSpacing: 0.3,
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
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _buildAnimalCard(animals[index] as Map<String, dynamic>, isDarkMode),
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

  Widget _buildFarmCard(BuildContext context, Map<String, dynamic> farm, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ParcelScreen(
              farmId: farm['id'] as int,
              userId: widget.userId!,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0A0A0A) : AppColors.lightBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.02),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _buildFarmAvatar(farm, isDarkMode),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm['name'] ?? 'Ferme',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w300,
                      color: isDarkMode ? Colors.white : const Color(0xFF0A0A0A),
                      letterSpacing: -0.2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (farm['location'] != null && (farm['location'] as String).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        farm['location'],
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          color: isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3),
                          letterSpacing: 0.1,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  _showDeleteFarmDialog(context, farm['id'] as int, farm['name'] as String? ?? 'Ferme');
                }
              },
              itemBuilder: (BuildContext context) => [
                PopupMenuItem<String>(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, size: 18, color: Colors.red.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      const Text('Supprimer', style: TextStyle(fontSize: 13, color: Colors.red)),
                    ],
                  ),
                ),
              ],
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
              offset: const Offset(-50, 0),
              child: Icon(
                Icons.more_vert,
                size: 20,
                color: isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteFarmDialog(BuildContext context, int farmId, String farmName) {
    showDialog(
      context: context,
      builder: (BuildContext context) => AlertDialog(
        backgroundColor: Provider.of<ThemeProvider>(context, listen: false).isDarkMode 
            ? const Color(0xFF0A0A0A) 
            : Colors.white,
        title: Text(
          'Supprimer la ferme',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w300,
            color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.white : const Color(0xFF0A0A0A),
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer "$farmName" ? Cette action est irréversible.',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w300,
            color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode 
                ? Colors.white.withOpacity(0.7)
                : Colors.black.withOpacity(0.7),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(
                fontSize: 13,
                color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteFarm(farmId);
            },
            child: const Text(
              'Supprimer',
              style: TextStyle(fontSize: 13, color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteFarm(int farmId) async {
    try {
      await ApiService.deleteFarm(farmId);
      if (mounted) {
        _refreshFarms();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Ferme supprimée avec succès'),
            backgroundColor: const Color(0xFF6B8E23),
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur : ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Widget _buildFarmAvatar(Map<String, dynamic> farm, bool isDarkMode) {
    final hasPhotos = farm['photos'] != null && (farm['photos'] as List).isNotEmpty;

    if (hasPhotos) {
      final first = (farm['photos'] as List).first;
      final url = first is String ? first : (first['image_url'] ?? first['imageUrl']);

      if (url != null) {
        return Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            image: DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    }

    final imageUrl = farm['image_url'] ?? farm['imageUrl'];
    if (imageUrl != null && (imageUrl as String).isNotEmpty) {
      return Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        color: isDarkMode
            ? Colors.white.withOpacity(0.03)
            : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Icon(
        Icons.agriculture_outlined,
        size: 22,
        color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2),
      ),
    );
  }

  Widget _buildAnimalCard(Map<String, dynamic> animal, bool isDarkMode) {
    final animalType = animal['animal_type'] as String? ?? 'Animal';
    final breed = animal['breed'] as String? ?? '';
    final quantity = animal['quantity'] as int? ?? 1;
    final photo = animal['image_url'] ?? animal['imageUrl'] ?? (animal['photos'] is List && (animal['photos'] as List).isNotEmpty ? (animal['photos'] as List).first : null);
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
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0A0A0A) : AppColors.lightBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02),
                image: photo != null ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover) : null,
              ),
              child: photo == null ? Icon(Icons.pets, color: isDarkMode ? Colors.white.withOpacity(0.3) : Colors.black.withOpacity(0.2), size: 22) : null,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animalType,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: isDarkMode ? Colors.white : const Color(0xFF0A0A0A),
                      letterSpacing: -0.1,
                    ),
                  ),
                  if (breed.isNotEmpty)
                    Text(
                      breed,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: isDarkMode ? Colors.white.withOpacity(0.4) : Colors.black.withOpacity(0.3),
                        letterSpacing: 0.1,
                      ),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6B8E23).withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'x$quantity',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF6B8E23),
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Provider.of<ThemeProvider>(context, listen: false).isDarkMode 
              ? const Color(0xFF0A0A0A) 
              : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 3,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 32),
            const Text(
              'Connexion requise',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w200,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Connectez-vous pour voir votre bétail',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: Colors.grey.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
                style: TextButton.styleFrom(
                  backgroundColor: const Color(0xFF6B8E23),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Se connecter',
                  style: TextStyle(
                    fontWeight: FontWeight.w300,
                    fontSize: 13,
                    letterSpacing: 0.3,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// CustomPainter pour dessiner une carte géographique stylisée
class _MapPainter extends CustomPainter {
  final bool isDarkMode;
  
  _MapPainter({required this.isDarkMode});
  
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDarkMode 
          ? const Color(0xFF1A2A1A) 
          : const Color(0xFFE8F0E8);
    
    // Fond
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
    
    // Lignes de contour (comme des courbes de niveau)
    final linePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.1)
          : const Color(0xFF6B8E23).withOpacity(0.2);
    
    // Dessiner des courbes organiques
    final path = Path();
    for (int i = 0; i < 5; i++) {
      path.reset();
      final y = 40 + i * 30;
      path.moveTo(0, y.toDouble());
      path.quadraticBezierTo(size.width * 0.3, y - 15, size.width * 0.6, y + 10);
      path.quadraticBezierTo(size.width * 0.8, y + 20, size.width, y - 5);
      canvas.drawPath(path, linePaint);
    }
    
    // Petits points pour représenter les cultures
    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = const Color(0xFF6B8E23).withOpacity(0.3);
    
    for (int i = 0; i < 20; i++) {
      final x = 20 + (i * 25) % (size.width - 40);
      final y = 20 + (i * 15) % (size.height - 40);
      canvas.drawCircle(Offset(x, y), 2, dotPaint);
    }
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}