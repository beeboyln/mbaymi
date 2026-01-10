import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/models/news_model.dart';
import 'package:mbaymi/screens/news_detail_screen.dart';
import 'package:mbaymi/screens/create_livestock_screen.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

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
  int _currentNewsPage = 0;

  @override
  void initState() {
    super.initState();
    _countsFuture = _loadCounts();
    _weatherFuture = _loadWeather();
  }

  Future<Map<String, dynamic>> _loadWeather() async {
    try {
      // Coordonnées du Sénégal (Dakar)
      final latitude = 14.6667;
      final longitude = -17.0382;
      
      final response = await http.get(
        Uri.parse(
          'https://api.open-meteo.com/v1/forecast?latitude=$latitude&longitude=$longitude&current=temperature_2m,weather_code,is_day&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=Africa/Dakar',
        ),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'current_temp': data['current']['temperature_2m'],
          'weather_code': data['current']['weather_code'],
          'max_temp': data['daily']['temperature_2m_max'][0],
          'min_temp': data['daily']['temperature_2m_min'][0],
          'daily_weather_code': data['daily']['weather_code'][0],
        };
      } else {
        throw Exception('Erreur météo');
      }
    } catch (e) {
      return {
        'current_temp': 22,
        'weather_code': 0,
        'max_temp': 26,
        'min_temp': 18,
        'daily_weather_code': 0,
      };
    }
  }

  String _getWeatherAdvice(int weatherCode, double maxTemp) {
    if (weatherCode == 80 || weatherCode == 81 || weatherCode == 82) {
      return 'Pluies prévues';
    } else if (maxTemp > 28) {
      return 'Forte chaleur prévue';
    } else if (maxTemp < 20) {
      return 'Temps frais';
    } else {
      return 'Ciel dégagé';
    }
  }

  String _getWateringAdvice(int weatherCode, double maxTemp) {
    if (weatherCode == 80 || weatherCode == 81 || weatherCode == 82) {
      return 'Pluies en cours - Attendez avant d\'arroser';
    } else if (maxTemp > 28) {
      return 'Arrosez vos cultures avant 8h pour limiter l\'évaporation';
    } else {
      return 'Arrosez le matin entre 7h-9h pour une meilleure absorption';
    }
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
      result['farms'] = (farms as List).length;
      result['livestock'] = (livestock as List).length;

      final parcelFutures = (farms as List).map((f) => ApiService.getFarmCrops(f['id'] as int)).toList();
      final parcelsLists = await Future.wait(parcelFutures);
      result['parcels'] = parcelsLists.fold<int>(0, (sum, l) => sum + ((l as List).length));

      final harvestFutures = (farms as List).map((f) => ApiService.getHarvestsForFarm(f['id'] as int)).toList();
      final harvestsLists = await Future.wait(harvestFutures);
      result['harvests'] = harvestsLists.fold<int>(0, (sum, l) => sum + ((l as List).length));

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
    final isDarkMode = widget.isDarkMode;
    
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
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(),
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
                    child: _buildStatCard(
                      icon: Icons.agriculture,
                      iconColor: const Color(0xFF6B8E23),
                      valueKey: 'farms',
                      label: 'Fermes',
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      icon: Icons.pets,
                      iconColor: const Color(0xFFD2691E),
                      valueKey: 'livestock',
                      label: 'Animaux',
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
                    ? const Color(0xFF1a1a1a).withOpacity(0.85)
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
                              onTap: () => _showFilterMenu(context),
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
                          physics: const BouncingScrollPhysics(),
                          itemCount: filteredArticles.length,
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          itemBuilder: (context, index) {
                            final article = filteredArticles[index];
                            return Padding(
                              padding: const EdgeInsets.only(right: 12),
                              child: SizedBox(
                                width: MediaQuery.of(context).size.width - 80,
                                child: _buildNewsCard(article, index == _currentNewsPage),
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
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String valueKey,
    required String label,
    String? subtitle,
    Color? subtitleColor,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap ?? () => HapticFeedback.lightImpact(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: widget.isDarkMode 
            ? const Color(0xFF1a1a1a)
            : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.isDarkMode ? 0.3 : 0.1),
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
                color: iconColor.withOpacity(widget.isDarkMode ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(height: 12),
            FutureBuilder<Map<String, dynamic>>(
              future: _countsFuture,
              builder: (context, snapshot) {
                final count = snapshot.data?[valueKey] ?? 0;
                return Text(
                  '$count',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w300,
                    color: widget.isDarkMode ? Colors.white : const Color(0xFF2D5016),
                    height: 1,
                  ),
                );
              },
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: subtitleColor?.withOpacity(0.1) ??
                      const Color(0xFF2D5016).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: subtitleColor ?? const Color(0xFF2D5016),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(NewsArticle article, bool isActive) {
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
          color: widget.isDarkMode ? const Color(0xFF1a1a1a) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.isDarkMode ? 0.3 : 0.1),
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
                          color: widget.isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
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
                              color: widget.isDarkMode ? Colors.grey.shade400 : const Color(0xFF666666),
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
                                    color: widget.isDarkMode ? Colors.grey.shade600 : const Color(0xFF888888),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                                const SizedBox(height: 1),
                                Text(
                                  article.source ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 9,
                                    fontWeight: FontWeight.w500,
                                    color: widget.isDarkMode ? Colors.grey.shade400 : const Color(0xFF444444),
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
                                  color: widget.isDarkMode ? Colors.grey.shade600 : const Color(0xFF888888),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 1),
                              Text(
                                article.timeAgo,
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w500,
                                  color: widget.isDarkMode ? Colors.grey.shade400 : const Color(0xFF444444),
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

  void _showFilterMenu(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: widget.isDarkMode 
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
                color: widget.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
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
                  color: widget.isDarkMode ? Colors.white : const Color(0xFF2D5016),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ...['Local', 'Cultures', 'Élevage', 'International'].map((filter) {
              return _buildFilterOption(filter);
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

  Widget _buildFilterOption(String filter) {
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
              ? const Color(0xFF2D5016).withOpacity(widget.isDarkMode ? 0.3 : 0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF2D5016)
                : widget.isDarkMode ? Colors.grey.shade800 : Colors.grey.shade200,
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
                      : widget.isDarkMode ? Colors.grey.shade300 : Colors.grey.shade700,
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

  @override
  void dispose() {
    super.dispose();
  }
}