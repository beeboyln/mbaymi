import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:math';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:provider/provider.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/utils/app_spacing.dart';
import 'package:mbaymi/utils/app_typography.dart';
import 'package:mbaymi/utils/app_radius.dart';
import 'package:mbaymi/utils/app_shadows.dart';
import 'package:mbaymi/services/weather_service.dart';
import 'package:mbaymi/models/news_model.dart';
import 'package:mbaymi/screens/profile_detail_screen.dart';
import 'package:mbaymi/screens/farm_detail_screen.dart';
import 'package:mbaymi/screens/animal_detail_screen.dart';
import 'package:mbaymi/screens/news_detail_screen.dart';
import 'package:mbaymi/screens/farm_screen.dart';
import 'package:mbaymi/widgets/farm_posts_widget.dart';
import 'package:mbaymi/widgets/comments_bottom_sheet.dart';
import 'package:mbaymi/widgets/stat_card.dart';

class DashboardTab extends StatefulWidget {
  final bool isDarkMode;
  final int? userId;
  
  const DashboardTab({super.key, this.isDarkMode = false, this.userId});

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String _selectedNewsFilter = 'Local';
  late Future<Map<String, dynamic>> _countsFuture;
  late Future<Map<String, dynamic>> _weatherFuture;
  late Future<List<NewsArticle>> _newsFuture;
  final int _currentNewsPage = 0;
  final ScrollController _newsScrollController = ScrollController();
  bool _isWeatherExpanded = false;
  
  // Random tip feature
  final List<String> _tips = [
    'Arrosez tôt le matin pour réduire l\'évaporation et économiser l\'eau.',
    'Utilisez du compost pour améliorer la rétention d\'eau du sol.',
    'Diversifiez les cultures pour réduire les risques de ravageurs.',
    'Surveillez régulièrement l\'état des feuilles pour détecter les maladies tôt.',
    'Plantez des haies pour protéger les cultures du vent.',
    'Récupérez l\'eau de pluie pour l\'irrigation des petits jardins.',
  ];
  String _currentTip = '';

  @override
  void initState() {
    super.initState();
    // Load data asynchronously - NO CACHE CLEARING ON INIT
    _countsFuture = _loadCounts();
    _weatherFuture = _loadWeather();
    _newsFuture = ApiService.getAgriculturalNews();
    // Initialize random tip
    _currentTip = _tips[Random().nextInt(_tips.length)];
  }

  @override
  void didUpdateWidget(DashboardTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Only reload if userId actually changed
    if (oldWidget.userId != widget.userId) {
      _countsFuture = _loadCounts();
      _weatherFuture = _loadWeather();
      _newsFuture = ApiService.getAgriculturalNews();
      setState(() {});
    }
  }

  @override
  void dispose() {
    _newsScrollController.dispose();
    super.dispose();
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
      final farms = await ApiService.getUserFarms();
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
          image: const AssetImage('assets/images/ba.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            isDarkMode 
              ? Colors.black.withAlpha((0.75 * 255).toInt())
              : Colors.white.withAlpha((0.2 * 255).toInt()),
            BlendMode.lighten,
          ),
        ),
      ),
      child: RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _countsFuture = _loadCounts();
            _weatherFuture = _loadWeather();
            _newsFuture = ApiService.getAgriculturalNews();
          });
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          cacheExtent: 200.0,
          slivers: [
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    _getFormattedDate(),
                    style: AppTypography.bodySmall.copyWith(
                      color: isDarkMode 
                        ? Colors.white.withAlpha((0.5 * 255).toInt())
                        : Colors.black.withAlpha((0.4 * 255).toInt()),
                      fontWeight: FontWeight.w300,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Conseil météorologique minimaliste
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
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

                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _isWeatherExpanded = !_isWeatherExpanded;
                      });
                      HapticFeedback.lightImpact();
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      decoration: BoxDecoration(
                        color: isDarkMode 
                            ? const Color(0xFF1A1A1A).withAlpha((0.7 * 255).toInt())
                            : Colors.white.withAlpha((0.75 * 255).toInt()),
                        border: Border.all(
                          color: isDarkMode
                              ? Colors.white.withAlpha((0.08 * 255).toInt())
                              : Colors.black.withAlpha((0.03 * 255).toInt()),
                          width: 1,
                        ),
                      ),
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Météo',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isDarkMode 
                                        ? Colors.white.withAlpha((0.5 * 255).toInt())
                                        : Colors.black.withAlpha((0.4 * 255).toInt()),
                                      fontWeight: FontWeight.w400,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    advice,
                                    style: AppTypography.bodySmall.copyWith(
                                      color: isDarkMode 
                                        ? Colors.white.withAlpha((0.8 * 255).toInt())
                                        : Colors.black.withAlpha((0.65 * 255).toInt()),
                                      fontWeight: FontWeight.w300,
                                      height: 1.4,
                                    ),
                                  ),
                                ],
                              ),
                              if (!isLoading)
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary.withAlpha((0.1 * 255).toInt()),
                                  ),
                                  child: Text(
                                    '${maxTemp.toStringAsFixed(0)}°C',
                                    style: AppTypography.h3.copyWith(
                                      color: AppColors.primary,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          if (_isWeatherExpanded) ...[
                            const SizedBox(height: 12),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: isDarkMode 
                                    ? Colors.white.withAlpha((0.05 * 255).toInt())
                                    : Colors.black.withAlpha((0.02 * 255).toInt()),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.water_drop_outlined,
                                    color: AppColors.primary.withAlpha((0.6 * 255).toInt()),
                                    size: 16,
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      wateringAdvice,
                                      style: AppTypography.bodySmall.copyWith(
                                        color: isDarkMode 
                                          ? Colors.white.withAlpha((0.7 * 255).toInt())
                                          : Colors.black.withAlpha((0.55 * 255).toInt()),
                                        fontWeight: FontWeight.w300,
                                        height: 1.4,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Astuce aléatoire minimaliste
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            sliver: SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: isDarkMode 
                    ? const Color(0xFF1A1A1A).withAlpha((0.7 * 255).toInt())
                    : Colors.white.withAlpha((0.75 * 255).toInt()),
                  border: Border.all(
                    color: isDarkMode
                        ? Colors.white.withAlpha((0.08 * 255).toInt())
                        : Colors.black.withAlpha((0.03 * 255).toInt()),
                    width: 1,
                  ),
                ),
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha((0.08 * 255).toInt()),
                      ),
                      child: Icon(Icons.lightbulb_outline, 
                        color: AppColors.primary.withAlpha((0.6 * 255).toInt()),
                        size: 20
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _currentTip.isNotEmpty ? _currentTip : 'Chargement...',
                        style: AppTypography.bodySmall.copyWith(
                          color: isDarkMode 
                            ? Colors.white.withAlpha((0.75 * 255).toInt())
                            : Colors.black.withAlpha((0.6 * 255).toInt()),
                          fontWeight: FontWeight.w300,
                          height: 1.4,
                        ),
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.refresh,
                        color: isDarkMode 
                          ? Colors.white.withAlpha((0.4 * 255).toInt())
                          : Colors.black.withAlpha((0.3 * 255).toInt()),
                        size: 18,
                      ),
                      onPressed: () {
                        setState(() {
                          _currentTip = _tips[Random().nextInt(_tips.length)];
                        });
                        HapticFeedback.selectionClick();
                      },
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Stats minimalistes - aperçu des fermes
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
            sliver: SliverToBoxAdapter(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => FarmTab(userId: widget.userId, initialSection: 0),
                    ),
                  );
                },
                child: Container(
                  height: 140,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: const NetworkImage('https://res.cloudinary.com/dcs9vkwe0/image/upload/v1770190752/gestion_de_boutique/duoglvpzhtwlbym4hbns.jpg'),
                      fit: BoxFit.cover,
                      colorFilter: ColorFilter.mode(
                        Colors.black.withAlpha((0.2 * 255).toInt()),
                        BlendMode.lighten,
                      ),
                    ),
                    border: Border.all(
                      color: isDarkMode
                          ? Colors.white.withAlpha((0.08 * 255).toInt())
                          : Colors.black.withAlpha((0.03 * 255).toInt()),
                      width: 1,
                    ),
                  ),
                  child: Align(
                    alignment: Alignment.bottomLeft,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Text(
                        'Fermes',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withAlpha((0.95 * 255).toInt()),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // News Section Header
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 32, 20, 16),
            sliver: SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Actualités',
                    style: AppTypography.h3.copyWith(
                      color: isDarkMode ? Colors.white : const Color(0xFF0A0A0A),
                      fontWeight: FontWeight.w400,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                      border: Border.all(
                        color: isDarkMode
                            ? Colors.white.withAlpha((0.1 * 255).toInt())
                            : Colors.black.withAlpha((0.05 * 255).toInt()),
                        width: 1,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: DropdownButton<String>(
                      value: _selectedNewsFilter,
                      underline: const SizedBox(),
                      icon: Icon(
                        Icons.expand_more,
                        color: AppColors.primary,
                        size: 20,
                      ),
                      dropdownColor: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
                      items: ['Local', 'National', 'International', 'Liens utiles']
                          .map((filter) => DropdownMenuItem<String>(
                                value: filter,
                                child: Text(
                                  filter,
                                  style: TextStyle(
                                    color: isDarkMode ? Colors.white : Colors.black87,
                                    fontSize: 13,
                                  ),
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _selectedNewsFilter = value;
                            _newsFuture = ApiService.getAgriculturalNews();
                          });
                        }
                      },
                      style: TextStyle(
                        color: isDarkMode ? Colors.white : Colors.black87,
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                      isExpanded: true,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // News Carousel
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(0, 0, 0, 30),
            sliver: FutureBuilder<List<NewsArticle>>(
              future: _newsFuture,
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
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: const Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color.fromARGB(233, 15, 89, 36),
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
                        borderRadius: BorderRadius.circular(4),
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
                          controller: _newsScrollController,
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
                      
                      // Scroll Indicator Arrow
                      Center(
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
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
          color: isDarkMode ? const Color(0xFF0D0D0D).withOpacity(0.9) : AppColors.lightBg,
          borderRadius: BorderRadius.circular(4),
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
                  image: AssetImage('assets/images/d.jpg'),
                  fit: BoxFit.contain,
                  alignment: Alignment.center,
                ),
                color: Color.fromARGB(255, 255, 255, 255),
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
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
                  color: isDarkMode ? Colors.white : const Color.fromARGB(233, 15, 89, 36),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...['Local', 'Cultures', 'Élevage', 'International'].map((filter) {
                      return _buildFilterOption(filter, isDarkMode);
                    }),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: const Color.fromARGB(233, 15, 89, 36),
                    shape: RoundedRectangleBorder(
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
              ? const Color.fromARGB(233, 15, 89, 36).withOpacity(isDarkMode ? 0.3 : 0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(
              _getFilterIcon(filter),
              size: 20,
              color: isSelected ? const Color.fromARGB(233, 15, 89, 36) : Colors.grey,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                filter,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  color: isSelected
                      ? const Color.fromARGB(233, 15, 89, 36)
                      : isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                size: 20,
                color: Color.fromARGB(233, 15, 89, 36),
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

  Widget _buildSkeletonStatCard(bool isDarkMode) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDarkMode 
            ? const Color(0xFF0D0D0D).withOpacity(0.9)
            : Colors.grey.shade100,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Colors.grey.shade300.withOpacity(0.5),
              ),
              child: const SizedBox(width: 20, height: 20),
            ),
            const SizedBox(height: 12),
            Container(
              height: 16,
              width: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade300.withOpacity(0.5),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              height: 12,
              width: 60,
              decoration: BoxDecoration(
                color: Colors.grey.shade300.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
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

  void _showStatsModal(BuildContext context, Map<String, dynamic> data, bool isDarkMode) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDarkMode 
                ? const Color(0xFF1A1A1A).withAlpha((0.95 * 255).toInt())
                : Colors.white.withAlpha((0.95 * 255).toInt()),
            border: Border.all(
              color: isDarkMode
                  ? Colors.white.withAlpha((0.1 * 255).toInt())
                  : Colors.black.withAlpha((0.05 * 255).toInt()),
              width: 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Text(
                'Aperçu rapide',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                  color: isDarkMode 
                      ? Colors.white.withAlpha((0.9 * 255).toInt())
                      : Colors.black.withAlpha((0.8 * 255).toInt()),
                ),
              ),
              const SizedBox(height: 24),

              // Stats Grid
              Row(
                children: [
                  // Fermes
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FarmTab(userId: widget.userId, initialSection: 0),
                          ),
                        );
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color.fromARGB(233, 15, 89, 36).withAlpha((0.1 * 255).toInt()),
                            ),
                            child: Icon(
                              Icons.agriculture,
                              color: const Color.fromARGB(233, 15, 89, 36).withAlpha((0.7 * 255).toInt()),
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${data['farms'] ?? 0}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: isDarkMode 
                                  ? Colors.white.withAlpha((0.95 * 255).toInt())
                                  : Colors.black.withAlpha((0.85 * 255).toInt()),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Ferme${(data['farms'] ?? 0) > 1 ? 's' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: isDarkMode 
                                  ? Colors.white.withAlpha((0.5 * 255).toInt())
                                  : Colors.black.withAlpha((0.4 * 255).toInt()),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  // Animaux
                  Expanded(
                    child: GestureDetector(
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FarmTab(userId: widget.userId, initialSection: 1),
                          ),
                        ).then((_) {
                          setState(() {
                            _countsFuture = _loadCounts();
                          });
                        });
                      },
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD2691E).withAlpha((0.1 * 255).toInt()),
                            ),
                            child: Icon(
                              Icons.pets,
                              color: const Color(0xFFD2691E).withAlpha((0.7 * 255).toInt()),
                              size: 20,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '${data['livestock'] ?? 0}',
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w300,
                              color: isDarkMode 
                                  ? Colors.white.withAlpha((0.95 * 255).toInt())
                                  : Colors.black.withAlpha((0.85 * 255).toInt()),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Animal${(data['livestock'] ?? 0) > 1 ? 'aux' : ''}',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                              color: isDarkMode 
                                  ? Colors.white.withAlpha((0.5 * 255).toInt())
                                  : Colors.black.withAlpha((0.4 * 255).toInt()),
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
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