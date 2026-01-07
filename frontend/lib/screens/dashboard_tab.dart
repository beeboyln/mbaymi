import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/models/news_model.dart';
import 'package:mbaymi/screens/news_detail_screen.dart';

class DashboardTab extends StatefulWidget {
  final bool isDarkMode;
  final int? userId;
  
  const DashboardTab({Key? key, this.isDarkMode = false, this.userId}) : super(key: key);

  @override
  State<DashboardTab> createState() => _DashboardTabState();
}

class _DashboardTabState extends State<DashboardTab> {
  String _selectedNewsFilter = 'Local'; // Default to local news
  late Future<Map<String, dynamic>> _countsFuture;

  @override
  void initState() {
    super.initState();
    _countsFuture = _loadCounts();
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

      // Parcels (crops)
      final parcelFutures = (farms as List).map((f) => ApiService.getFarmCrops(f['id'] as int)).toList();
      final parcelsLists = await Future.wait(parcelFutures);
      result['parcels'] = parcelsLists.fold<int>(0, (sum, l) => sum + ((l as List).length));

      // Harvests per farm
      final harvestFutures = (farms as List).map((f) => ApiService.getHarvestsForFarm(f['id'] as int)).toList();
      final harvestsLists = await Future.wait(harvestFutures);
      result['harvests'] = harvestsLists.fold<int>(0, (sum, l) => sum + ((l as List).length));

      // Revenue from sales by user
      final sales = await ApiService.getSalesByUser(widget.userId!);
      double revenue = 0.0;
      for (final s in sales) {
        final qty = (s['quantity'] ?? 0) is int ? (s['quantity'] as int).toDouble() : (s['quantity'] ?? 0.0);
        final price = (s['price_per_unit'] ?? 0) is int ? (s['price_per_unit'] as int).toDouble() : (s['price_per_unit'] ?? 0.0);
        revenue += (qty as double) * (price as double);
      }
      result['revenue'] = revenue;
    } catch (e) {
      // If any call fails, return partial results
      return result;
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = widget.isDarkMode;
    final bgColor = isDarkMode ? const Color(0xFF1a1a1a) : Colors.transparent;
    final textColor = isDarkMode ? Colors.white : const Color(0xFF2D5016);
    final secondaryTextColor = isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500;
    
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        image: DecorationImage(
          image: const AssetImage('assets/images/b.jpg'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            const Color.fromARGB(0, 255, 255, 255),
            BlendMode.lighten,
          ),
        ),
      ),
      child: CustomScrollView(
        slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Bonjour',
                  style: TextStyle(
                    fontSize: 36,
                    fontWeight: FontWeight.w300,
                    color: textColor,
                    letterSpacing: -0.8,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  _getFormattedDate(),
                  style: TextStyle(
                    fontSize: 14,
                    color: secondaryTextColor,
                    fontWeight: FontWeight.w300,
                    letterSpacing: 0.4,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Conseil du jour - Moderne
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF2D5016), Color(0xFF3D6B1F)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(5),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF2D5016).withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.tips_and_updates,
                      color: Colors.white,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Conseil du jour',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            color: Colors.white70,
                            letterSpacing: 0.5,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Arrosez vos cultures tôt le matin',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w300,
                            color: Colors.white,
                            letterSpacing: -0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Stats - Amélioré avec actions
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              children: [
                // Grid de 2 colonnes pour Fermes et Animaux
                Row(
                  children: [
                    // Fermes - Actionnable
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          // Navigate to farms
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromARGB(226, 255, 255, 255),
                                const Color.fromARGB(226, 254, 254, 254),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: const Color(0xFF6B8E23).withOpacity(0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF6B8E23).withOpacity(0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B8E23).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Icon(
                                  Icons.local_florist,
                                  color: Color(0xFF6B8E23),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 10),
                              FutureBuilder<Map<String, dynamic>>(
                                future: _countsFuture,
                                builder: (context, snap) {
                                  final count = (snap.data != null) ? snap.data!['farms'] ?? 0 : 0;
                                  return Text(
                                    '$count',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w300,
                                      color: Color(0xFF2D5016),
                                      letterSpacing: -0.4,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Fermes',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF6B8E23),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color.fromARGB(246, 251, 250, 250),
                                      const Color.fromARGB(238, 255, 255, 255),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: const Color(0xFFE07856).withOpacity(0.2),
                                  ),
                                ),
                                child: const Text(
                                  '🔴 Attention',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFE07856),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Animaux - Actionnable
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          HapticFeedback.lightImpact();
                          // Navigate to livestock
                        },
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                const Color.fromARGB(227, 255, 255, 255),
                                const Color.fromARGB(226, 255, 255, 255),
                              ],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            borderRadius: BorderRadius.circular(5),
                            border: Border.all(
                              color: const Color(0xFFD2691E).withOpacity(0.2),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFD2691E).withOpacity(0.1),
                                blurRadius: 16,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFD2691E).withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(5),
                                ),
                                child: const Icon(
                                  Icons.pets,
                                  color: Color(0xFFD2691E),
                                  size: 24,
                                ),
                              ),
                              const SizedBox(height: 10),
                              FutureBuilder<Map<String, dynamic>>(
                                future: _countsFuture,
                                builder: (context, snap) {
                                  final count = (snap.data != null) ? snap.data!['livestock'] ?? 0 : 0;
                                  return Text(
                                    '$count',
                                    textAlign: TextAlign.center,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w300,
                                      color: Color(0xFF2D5016),
                                      letterSpacing: -0.4,
                                    ),
                                  );
                                },
                              ),
                              const SizedBox(height: 4),
                              const Text(
                                'Animaux',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFFD2691E),
                                  letterSpacing: 0.3,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      const Color(0xFFF39C12).withOpacity(0.15),
                                      const Color(0xFFF39C12).withOpacity(0.08),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(5),
                                  border: Border.all(
                                    color: const Color(0xFFF39C12).withOpacity(0.2),
                                  ),
                                ),
                                child: const Text(
                                  '💉 À vacciner',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFFF39C12),
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Second row: Parcelles & Récoltes
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode ? const Color(0xFF1f1f1f) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.06)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0,4)),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFF8B7355).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.grass, color: Color(0xFF8B7355)),
                            ),
                            const SizedBox(height: 10),
                            FutureBuilder<Map<String, dynamic>>(
                              future: _countsFuture,
                              builder: (context, snap) {
                                final count = (snap.data != null) ? snap.data!['parcels'] ?? 0 : 0;
                                return Text(
                                  '$count',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: Color(0xFF2D5016)),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            const Text('Parcelles', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFF6B8E23))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode ? const Color(0xFF1f1f1f) : Colors.white,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey.withOpacity(0.06)),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0,4)),
                          ],
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF39C12).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.emoji_nature, color: Color(0xFFF39C12)),
                            ),
                            const SizedBox(height: 10),
                            FutureBuilder<Map<String, dynamic>>(
                              future: _countsFuture,
                              builder: (context, snap) {
                                final count = (snap.data != null) ? snap.data!['harvests'] ?? 0 : 0;
                                return Text(
                                  '$count',
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: Color(0xFF2D5016)),
                                );
                              },
                            ),
                            const SizedBox(height: 4),
                            const Text('Récoltes', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w400, color: Color(0xFFD2691E))),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Revenue summary
                FutureBuilder<Map<String, dynamic>>(
                  future: _countsFuture,
                  builder: (context, snap) {
                    final revenue = (snap.data != null) ? (snap.data!['revenue'] ?? 0.0) : 0.0;
                    return Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: widget.isDarkMode ? const Color(0xFF1f1f1f) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 12, offset: const Offset(0,6))],
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.monetization_on, color: Color(0xFF8B7355)),
                          const SizedBox(width: 12),
                          Expanded(child: Text('Revenu estimé', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w400, color: widget.isDarkMode ? Colors.white : const Color(0xFF1A1A1A)))),
                          Text('${revenue.toStringAsFixed(0)} CFA', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: Color(0xFF2D5016))),
                        ],
                      ),
                    );
                  },
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),

        // Section Actualités avec filtres
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
          sliver: SliverToBoxAdapter(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
              decoration: BoxDecoration(
                color: widget.isDarkMode ? const Color(0xFF2a2a2a) : Colors.white.withOpacity(0.98),
                borderRadius: BorderRadius.circular(6),
                gradient: LinearGradient(
                  colors: [
                    widget.isDarkMode ? const Color(0xFF2a2a2a) : Colors.white,
                    widget.isDarkMode ? const Color(0xFF252525) : Colors.grey.shade50,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Text(
                    'Actualités',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w300,
                      color: widget.isDarkMode ? Colors.white : const Color(0xFF2D5016),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(width: 12),
                  // Voir tout button
                  const SizedBox(width: 12),
                  // Filtre icon
                  GestureDetector(
                    onTap: () => _showFilterMenu(context),
                    child: Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6B8E23).withOpacity(isDarkMode ? 0.25 : 0.2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: const Icon(
                        Icons.tune_outlined,
                        color: Color(0xFF6B8E23),
                        size: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SliverToBoxAdapter(child: SizedBox(height: 16)),

        // News
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: FutureBuilder<List<NewsArticle>>(
            future: ApiService.getAgriculturalNews(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Color(0xFF8B7355),
                      ),
                    ),
                  ),
                );
              }

              if (snapshot.hasError || !snapshot.hasData) {
                return const SliverToBoxAdapter(child: SizedBox.shrink());
              }

              final articles = snapshot.data ?? [];
              
              // Filtrer les articles par catégorie sélectionnée
              final filteredArticles = articles.where((article) {
                if (_selectedNewsFilter == 'Local') {
                  return (article.category?.toLowerCase() ?? '').contains('local') || 
                         (article.category?.toLowerCase() ?? '').contains('sénégal') ||
                         (article.category?.toLowerCase() ?? '').contains('senegal') ||
                         (article.source?.toLowerCase() ?? '').contains('local');
                } else if (_selectedNewsFilter == 'Cultures') {
                  return (article.category?.toLowerCase() ?? '').contains('culture') ||
                         (article.category?.toLowerCase() ?? '').contains('agriculture') ||
                         (article.category?.toLowerCase() ?? '').contains('crop');
                } else if (_selectedNewsFilter == 'Élevage') {
                  return (article.category?.toLowerCase() ?? '').contains('élevage') ||
                         (article.category?.toLowerCase() ?? '').contains('santé animale') ||
                         (article.category?.toLowerCase() ?? '').contains('livestock') ||
                         (article.category?.toLowerCase() ?? '').contains('bétail');
                } else if (_selectedNewsFilter == 'International') {
                  return (article.category?.toLowerCase() ?? '').contains('international') ||
                         (article.category?.toLowerCase() ?? '').contains('world');
                }
                return true;
              }).toList();
              
              if (filteredArticles.isEmpty) {
                return SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        children: [
                          Icon(
                            Icons.search_off_outlined,
                            size: 48,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Aucune actualité pour cette catégorie',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }
              
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final article = filteredArticles[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildNewsCard(context, article),
                    );
                  },
                  childCount: filteredArticles.length > 5 ? 5 : filteredArticles.length,
                ),
              );
            },
          ),
        ),
        const SliverToBoxAdapter(child: SizedBox(height: 24)),
      ],
    ),
    );
  }

  void _showFilterMenu(BuildContext context) {
    HapticFeedback.lightImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF2a2a2a) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Filtrer les actualités',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: widget.isDarkMode ? Colors.white : const Color(0xFF2D5016),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildFilterOption('🌾 Cultures', 'Cultures'),
              const SizedBox(height: 12),
              _buildFilterOption('🐄 Élevage', 'Élevage'),
              const SizedBox(height: 12),
              _buildFilterOption('🌍 International', 'International'),
              const SizedBox(height: 12),
              _buildFilterOption('🇸🇳 Local', 'Local'),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFilterOption(String label, String filter) {
    final isSelected = _selectedNewsFilter == filter;
    final bgColor = isSelected 
        ? const Color(0xFF2D5016).withOpacity(widget.isDarkMode ? 0.15 : 0.08) 
        : (widget.isDarkMode ? const Color(0xFF333333) : Colors.grey.shade50);
    final borderColor = isSelected 
        ? const Color(0xFF2D5016) 
        : (widget.isDarkMode ? Colors.grey.shade700 : Colors.grey.shade200);
    
    return GestureDetector(
      onTap: () {
        setState(() => _selectedNewsFilter = filter);
        HapticFeedback.lightImpact();
        Navigator.pop(context);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: bgColor,
          border: Border.all(
            color: borderColor,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(4),
          gradient: isSelected
              ? LinearGradient(
                  colors: [
                    const Color(0xFF2D5016).withOpacity(0.12),
                    const Color(0xFF2D5016).withOpacity(0.04),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: isSelected ? const Color(0xFF2D5016) : (widget.isDarkMode ? Colors.grey.shade400 : Colors.grey.shade700),
                  letterSpacing: 0.2,
                ),
              ),
            ),
            if (isSelected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF2D5016),
                size: 20,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, NewsArticle article) {
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
          color: widget.isDarkMode ? const Color(0xFF2a2a2a) : Colors.white,
          borderRadius: BorderRadius.circular(5),
          gradient: LinearGradient(
            colors: [
              widget.isDarkMode ? const Color(0xFF2a2a2a) : Colors.white,
              widget.isDarkMode ? const Color(0xFF252525) : Colors.grey.shade50,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
              spreadRadius: 2,
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image si disponible
            if (article.imageUrl != null && article.imageUrl!.isNotEmpty)
              Container(
                width: double.infinity,
                height: 180,
                color: const Color(0xFF2D5016).withOpacity(0.1),
                child: Image.network(
                  article.imageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFF2D5016).withOpacity(0.1),
                      child: const Icon(
                        Icons.image_not_supported_outlined,
                        color: Color(0xFF2D5016),
                        size: 32,
                      ),
                    );
                  },
                ),
              ),
            // Contenu
            Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Titre
                  Text(
                    article.title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: widget.isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                      height: 1.5,
                      letterSpacing: -0.2,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 10),
                  // Description
                  if (article.description.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        article.description,
                        style: TextStyle(
                          fontSize: 13,
                          color: widget.isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                          height: 1.6,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.2,
                        ),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  // Date et icône
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        article.timeAgo,
                        style: TextStyle(
                          fontSize: 11,
                          color: widget.isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                          fontWeight: FontWeight.w400,
                          letterSpacing: 0.1,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2D5016).withOpacity(0.05),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 14,
                          color: const Color(0xFF2D5016).withOpacity(0.4),
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
    );
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    final weekdays = ['Lundi', 'Mardi', 'Mercredi', 'Jeudi', 'Vendredi', 'Samedi', 'Dimanche'];
    final months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 
                    'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
    
    final dayName = weekdays[now.weekday - 1];
    final monthName = months[now.month - 1];
    
    return '$dayName, ${now.day} $monthName ${now.year}';
  }
}
