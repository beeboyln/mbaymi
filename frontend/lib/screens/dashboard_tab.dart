import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/services/weather_service.dart';
import 'package:mbaymi/models/news_model.dart';
import 'package:mbaymi/screens/profile_detail_screen.dart';
import 'package:mbaymi/screens/farm_detail_screen.dart';
import 'package:mbaymi/screens/animal_detail_screen.dart';
import 'package:mbaymi/screens/news_detail_screen.dart';
import 'package:mbaymi/widgets/farm_posts_widget.dart';
import 'package:mbaymi/widgets/comments_bottom_sheet.dart';
import 'package:mbaymi/widgets/stat_card.dart';

class DashboardTab extends StatefulWidget {
  final bool isDarkMode;
  final int? userId;
  
  const DashboardTab({Key? key, this.isDarkMode = false, this.userId}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String _selectedNewsFilter = 'Local';
  late Future<Map<String, dynamic>> _countsFuture;
  late Future<Map<String, dynamic>> _weatherFuture;
  late Future<List<dynamic>> _followedPostsFuture;
  List<Map<String, dynamic>> _followedPosts = [];
  int _viewerId = 0;
  late StreamSubscription<Map<String, dynamic>> _followSub;
  int _currentNewsPage = 0;
  bool _postsInitialized = false;
  
  Future<List<dynamic>>? get _followedFarmsFuture => null;

  @override
  void initState() {
    super.initState();
    ApiService.clearCache();
    _countsFuture = _loadCounts();
    _weatherFuture = _loadWeather();
    final viewerId = widget.userId ?? AuthService.currentSession?.userId ?? 0;
    _viewerId = viewerId;
    _followedPostsFuture = viewerId > 0 ? ApiService.getFarmPostsFeed(userId: viewerId) : Future.value(<dynamic>[]);
    // Listen for follow/unfollow changes to update dashboard feed in real-time
    _followSub = ApiService.onFollowChanged.listen((payload) async {
      final uid = payload['userId'] as int?;
      final action = payload['action'] as String?;
      if (uid == null || action == null) return;

      if (action == 'unfollow') {
        // remove posts from that user
        setState(() {
          _followedPosts.removeWhere((p) => (p['user_id'] as int?) == uid);
        });
      } else if (action == 'follow') {
        try {
          final newPosts = await ApiService.getUserPosts(uid, viewerId: _viewerId > 0 ? _viewerId : null);
          if (newPosts.isNotEmpty) {
            final List<Map<String, dynamic>> incoming = List<Map<String, dynamic>>.from(newPosts.cast<Map<String, dynamic>>());
            final existingIds = _followedPosts.map<int?>((p) => p['id'] as int?).where((id) => id != null).cast<int>().toSet();

            // Filter out duplicates
            final filtered = incoming.where((p) {
              final id = p['id'] as int?;
              return id != null && !existingIds.contains(id);
            }).toList();

            if (filtered.isNotEmpty) {
              setState(() {
                // prepend then sort by created_at desc
                _followedPosts.insertAll(0, filtered);
                _followedPosts.sort((a, b) {
                  DateTime ta = DateTime.tryParse(a['created_at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
                  DateTime tb = DateTime.tryParse(b['created_at'] as String? ?? '') ?? DateTime.fromMillisecondsSinceEpoch(0);
                  return tb.compareTo(ta);
                });
                // keep cap to 200 posts
                if (_followedPosts.length > 200) _followedPosts = _followedPosts.sublist(0, 200);
              });
            }
          }
        } catch (_) {}
      }
    });
  }

  @override
  void didUpdateWidget(DashboardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      ApiService.clearCache();
      _countsFuture = _loadCounts();
      _weatherFuture = _loadWeather();
      final viewerId = widget.userId ?? AuthService.currentSession?.userId ?? 0;
      _viewerId = viewerId;
      _followedPostsFuture = viewerId > 0 ? ApiService.getFarmPostsFeed(userId: viewerId) : Future.value(<dynamic>[]);
      _followedPosts = [];
      _postsInitialized = false;
      setState(() {});
    }
  }

  @override
  void dispose() {
    try {
      _followSub.cancel();
    } catch (_) {}
    super.dispose();
  }

  void _refreshFollowedPosts() {
    // Reset initialization flag and reload posts from server
    _postsInitialized = false;
    _followedPostsFuture = _viewerId > 0 
        ? ApiService.getFarmPostsFeed(userId: _viewerId) 
        : Future.value(<dynamic>[]);
  }

  Future<Map<String, dynamic>> _loadWeather() async {
    return WeatherService.getWeather();
  }

  String _getWeatherAdvice(int weatherCode, double maxTemp) {
    return WeatherService.getWeatherAdvice(weatherCode, maxTemp);
  }

  String _getWateringAdvice(int weatherCode, double maxTemp) {
    return WeatherService.getWateringAdvice(weatherCode, maxTemp);
  }

  Future<Map<String, dynamic>> _loadCounts() async {
    final Map<String, dynamic> result = {
      'farms': 0,
      'livestock': 0,
      'parcels': 0,
      'harvests': 0,
      'revenue': 0.0,
    };

    if (widget.userId == null) return result;

    try {
      final farms = await ApiService.getUserFarms(widget.userId!);
      final livestock = await ApiService.getUserLivestock(widget.userId!);
      result['farms'] = farms.length;
      result['livestock'] = livestock.length;

      final parcelFutures = farms.map((f) => ApiService.getFarmCrops(f['id'] as int)).toList();
      final parcelsLists = await Future.wait(parcelFutures);
      result['parcels'] = parcelsLists.fold<int>(0, (sum, l) => sum + (l.length));

      final harvestFutures = farms.map((f) => ApiService.getHarvestsForFarm(f['id'] as int)).toList();
      final harvestsLists = await Future.wait(harvestFutures);
      result['harvests'] = harvestsLists.fold<int>(0, (sum, l) => sum + (l.length));

      final sales = await ApiService.getSalesByUser(widget.userId!);
      double revenue = 0.0;
      for (final s in sales) {
        final qty = (s['quantity'] ?? 0) is int ? (s['quantity'] as int).toDouble() : (s['quantity'] ?? 0.0);
        final price = (s['price_per_unit'] ?? 0) is int ? (s['price_per_unit'] as int).toDouble() : (s['price_per_unit'] ?? 0.0);
        revenue += (qty as double) * (price as double);
      }
      result['revenue'] = revenue;
    } catch (e) {
      return result;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Container(
      decoration: BoxDecoration(
        image: DecorationImage(
          image: const AssetImage('assets/images/aa.png'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            Colors.black.withOpacity(isDarkMode ? 0.15 : 0.03),
            BlendMode.darken,
          ),
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          _refreshFollowedPosts();
          setState(() {});
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          cacheExtent: 200.0,
          slivers: [
          // Date Header - Minimaliste
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 30, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Text(
                _getFormattedDate(),
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w300,
                  color: isDarkMode ? Colors.white : const Color(0xFF2D5016),
                ),
              ),
            ),
          ),

          // Conseil du jour - Simplifié
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            sliver: SliverToBoxAdapter(
              child: FutureBuilder<Map<String, dynamic>>(
                future: _weatherFuture,
                builder: (context, snapshot) {
                  final weather = snapshot.data ?? {'current_temp': 22, 'max_temp': 26};
                  final maxTemp = (weather['max_temp'] as num).toDouble();
                  final weatherCode = (weather['daily_weather_code'] as int?) ?? 0;
                  final advice = _getWeatherAdvice(weatherCode, maxTemp);
                  final wateringAdvice = _getWateringAdvice(weatherCode, maxTemp);

                  final isLoading = snapshot.connectionState == ConnectionState.waiting;

                  return Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDarkMode
                            ? [const Color(0xFF2D5016).withOpacity(0.7), const Color(0xFF3A6122).withOpacity(0.7)]
                            : [const Color(0xFF2D5016), const Color(0xFF3D6B1F)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D5016).withOpacity(0.15),
                          blurRadius: 10,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '☀️ Aujourd\'hui',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                                Text(
                                  '${maxTemp.toStringAsFixed(0)}°C - $advice',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            ),
                            if (!isLoading)
                              Text(
                                '${maxTemp.toStringAsFixed(0)}°',
                                style: const TextStyle(
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.water_drop_outlined, color: Colors.white70, size: 16),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  wateringAdvice,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),

          // 📊 STATS RAPIDES
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Row(
                children: [
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _countsFuture,
                      builder: (context, snapshot) {
                        return StatCard(
                          icon: Icons.agriculture,
                          iconColor: const Color(0xFF6B8E23),
                          label: 'Fermes',
                          value: snapshot.data?['farms'] ?? 0,
                          isDarkMode: isDarkMode,
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FutureBuilder<Map<String, dynamic>>(
                      future: _countsFuture,
                      builder: (context, snapshot) {
                        return StatCard(
                          icon: Icons.pets,
                          iconColor: const Color(0xFFD2691E),
                          label: 'Animaux',
                          value: snapshot.data?['livestock'] ?? 0,
                          isDarkMode: isDarkMode,
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),

          // News Section Header avec fond
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 16),
            sliver: SliverToBoxAdapter(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  color: isDarkMode 
                    ? const Color(0xFF0D0D0D).withOpacity(0.95)
                    : Colors.white.withOpacity(0.85),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Actualités',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: isDarkMode ? Colors.white : const Color(0xFF2D5016),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: isDarkMode
                                    ? const Color(0xFF2D5016).withOpacity(0.3)
                                    : const Color(0xFF2D5016).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.filter_alt, size: 14, color: Color(0xFF6B8E23)),
                                  const SizedBox(width: 6),
                                  Text(
                                    _selectedNewsFilter,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w500,
                                      color: Color(0xFF6B8E23),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            GestureDetector(
                              onTap: () => _showFilterMenu(context, isDarkMode),
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isDarkMode
                                      ? const Color(0xFF2D5016).withOpacity(0.3)
                                      : const Color(0xFF2D5016).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(
                                  Icons.tune,
                                  size: 18,
                                  color: Color(0xFF6B8E23),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sélection des meilleures actualités agricoles',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF666666),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // News Carousel
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
            sliver: FutureBuilder<List<NewsArticle>>(
              future: ApiService.getAgriculturalNews(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverToBoxAdapter(
                    child: Container(
                      height: 300,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                          ? const Color(0xFF1a1a1a).withOpacity(0.85)
                          : Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF6B8E23),
                        ),
                      ),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData) {
                  return SliverToBoxAdapter(
                    child: Container(
                      height: 200,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                          ? const Color(0xFF1a1a1a).withOpacity(0.85)
                          : Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Impossible de charger les actualités',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final articles = snapshot.data ?? [];
                final filteredArticles = _filterArticles(articles);

                if (filteredArticles.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Container(
                      height: 200,
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                          ? const Color(0xFF1a1a1a).withOpacity(0.85)
                          : Colors.white.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_outlined,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Aucune actualité disponible',
                              style: TextStyle(
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverToBoxAdapter(
                  child: Column(
                    children: [
                      // Carousel
                      SizedBox(
                        height: 320,
                        child: ListView.builder(
                          scrollDirection: Axis.horizontal,
                          physics: const ClampingScrollPhysics(),
                          itemCount: filteredArticles.length,
                          cacheExtent: 200,
                          addRepaintBoundaries: true,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemBuilder: (context, index) {
                            final article = filteredArticles[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width - 80,
                                child: _buildNewsCard(article, index == _currentNewsPage, isDarkMode),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(height: 16),
                      
                      // Indicators
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          filteredArticles.length,
                          (index) => Container(
                            width: 8,
                            height: 8,
                            margin: const EdgeInsets.symmetric(horizontal: 4),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _currentNewsPage == index
                                  ? const Color(0xFF6B8E23)
                                  : Colors.grey.withOpacity(0.3),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
        ),
      );
  }



  Widget _buildNewsCard(NewsArticle article, bool isActive, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => NewsDetailScreen(article: article),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF0D0D0D).withOpacity(0.9) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Journal Header Image
            Container(
              height: 160,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/b.png'),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
                color: Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
            ),
            
            // Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    Flexible(
                      child: Text(
                        article.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w300,
                          color: isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    
                    // Summary
                    if (article.description.isNotEmpty)
                      Flexible(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            article.description,
                            style: TextStyle(
                              fontSize: 11,
                              color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF666666),
                              height: 1.2,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                    
                    // Source and Time
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          // Source
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'SOURCE',
                                  style: TextStyle(
                                    fontSize: 7,
                                    fontWeight: FontWeight.w600,
                                    color: isDarkMode ? Colors.grey.shade600 : const Color(0xFF888888),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  article.source ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF444444),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          
                          // Time
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'PUBLIÉ',
                                style: TextStyle(
                                  fontSize: 7,
                                  fontWeight: FontWeight.w600,
                                  color: isDarkMode ? Colors.grey.shade600 : const Color(0xFF888888),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                article.timeAgo,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: isDarkMode ? Colors.grey.shade400 : const Color(0xFF444444),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
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

  List<NewsArticle> _filterArticles(List<NewsArticle> articles) {
    return articles.where((article) {
      final category = (article.category ?? '').toLowerCase();
      final source = (article.source ?? '').toLowerCase();

      switch (_selectedNewsFilter) {
        case 'Local':
          return category.contains('local') ||
              category.contains('sénégal') ||
              category.contains('senegal') ||
              source.contains('local') ||
              source.contains('senegal');
        case 'Cultures':
          return category.contains('culture') ||
              category.contains('agriculture') ||
              category.contains('crop') ||
              category.contains('récolte');
        case 'Élevage':
          return category.contains('élevage') ||
              category.contains('santé animale') ||
              category.contains('livestock') ||
              category.contains('bétail') ||
              category.contains('animal');
        case 'International':
          return category.contains('international') ||
              category.contains('world') ||
              category.contains('global');
        default:
          return true;
      }
    }).toList();
  }

  void _showFilterMenu(BuildContext context, bool isDarkMode) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: isDarkMode 
            ? const Color(0xFF1a1a1a).withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 20),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Sélectionnez une catégorie',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF2D5016),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...['Local', 'Cultures', 'Élevage', 'International'].map((filter) {
              return _buildFilterOption(filter, isDarkMode);
            }).toList(),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color(0xFF2D5016),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'APPLIQUER',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterOption(String filter, bool isDarkMode) {
    final isSelected = _selectedNewsFilter == filter;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedNewsFilter = filter;
        });
        HapticFeedback.lightImpact();
        Future.delayed(const Duration(milliseconds: 300), () {
          Navigator.pop(context);
        });
      },
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF2D5016).withOpacity(isDarkMode ? 0.3 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2D5016)
                : isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              _getFilterIcon(filter),
              size: 20,
              color: isSelected ? const Color(0xFF6B8E23) : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? const Color(0xFF2D5016)
                      : isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                size: 20,
                color: Color(0xFF6B8E23),
              ),
          ],
        ),
      ),
    );
  }

  IconData _getFilterIcon(String filter) {
    switch (filter) {
      case 'Local':
        return Icons.location_on;
      case 'Cultures':
        return Icons.grass;
      case 'Élevage':
        return Icons.pets;
      case 'International':
        return Icons.public;
      default:
        return Icons.newspaper;
    }
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 
                    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    
    final dayName = weekdays[now.weekday - 1];
    final monthName = months[now.month - 1];
    
    return '$dayName ${now.day} $monthName ${now.year}';
  }

  // ignore: unused_element
  Color _getHealthColor(String status) {
    switch (status.toLowerCase()) {
      case 'sain':
      case 'healthy':
        return Colors.green;
      case 'malade':
      case 'sick':
        return Colors.red;
      case 'vacciné':
      case 'vaccinated':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }
}