import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/utils/app_theme.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/models/market_model.dart';
import 'package:mbaymi/screens/create_sale_screen.dart';
import 'package:mbaymi/screens/sale_detail_screen.dart';
import 'package:mbaymi/widgets/skeleton_loader.dart';
import 'dart:async';

class MarketTab extends StatefulWidget {
  final bool isDarkMode;

  const MarketTab({super.key, this.isDarkMode = false});

  @override
  State<MarketTab> createState() => _MarketTabState();
}

class _MarketTabState extends State<MarketTab> {
  late Future<List<dynamic>> _salesFuture;
  late Future<List<dynamic>> _mySalesFuture;
  late Future<List<MarketPrice>> _marketPricesFuture;
  String _searchQuery = '';
  String _selectedCategory = 'Tous';
  int _userId = 0;
  bool _showMyAds = true;
  bool _showPrices = false;
  
  final List<String> _categories = ['Tous', 'Cultures', 'Bétail', 'Légumes', 'Fruits', 'Grains'];
  
  // Enhanced cache with all filter parameters
  List<dynamic> _cachedFilteredSales = [];
  List<dynamic> _cachedAllSales = [];
  String _cachedSearchQuery = '';
  String _cachedCategory = 'Tous';
  
  // Debounce timer for search
  Timer? _searchDebounceTimer;
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _userId = AuthService.currentSession?.userId ?? 0;
    _loadData();
  }
  
  @override
  void dispose() {
    _searchDebounceTimer?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _loadData() {
    _salesFuture = ApiService.getAllSales().catchError((_) => <dynamic>[]);
    _marketPricesFuture = ApiService.getMarketPrices().catchError((_) => <MarketPrice>[]);
    if (_userId > 0) {
      _mySalesFuture = ApiService.getSalesByUser(_userId).catchError((_) => <dynamic>[]);
    }
  }

  Future<void> _refreshData() async {
    setState(() {
      _loadData();
      _cachedFilteredSales.clear();
      _cachedAllSales.clear();
      _cachedSearchQuery = '';
      _cachedCategory = 'Tous';
    });
    
    // Wait for futures to complete
    try {
      await Future.wait([
        _salesFuture,
        _marketPricesFuture,
        if (_userId > 0) _mySalesFuture,
      ]);
    } catch (e) {
      // Handle errors silently or show message
      debugPrint('Error refreshing data: $e');
    }
  }
  
  /// Debounced search handler
  void _onSearchChanged(String value) {
    _searchDebounceTimer?.cancel();
    _searchDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _searchQuery = value.toLowerCase();
          _cachedFilteredSales.clear();
        });
      }
    });
  }
  
  /// Filter sales with complete memoization including category
  List<dynamic> _getFilteredSales(List<dynamic> allSales) {
    // Check if cache is valid
    if (allSales == _cachedAllSales && 
        _selectedCategory == _cachedCategory &&
        _searchQuery == _cachedSearchQuery &&
        _cachedFilteredSales.isNotEmpty) {
      return _cachedFilteredSales;
    }
    
    // Update cache keys
    _cachedAllSales = allSales;
    _cachedCategory = _selectedCategory;
    _cachedSearchQuery = _searchQuery;
    
    // Apply filters
    _cachedFilteredSales = allSales.where((sale) {
      final productName = (sale['product_name'] as String? ?? '').toLowerCase();
      final category = (sale['category'] as String? ?? '');
      
      final matchesSearch = _searchQuery.isEmpty || productName.contains(_searchQuery);
      final matchesCategory = _selectedCategory == 'Tous' || category == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
    
    return _cachedFilteredSales;
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? AppTheme.socialDark : AppColors.lightBg,
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: const Color(0xFF7BA428),
        child: CustomScrollView(
          physics: const ClampingScrollPhysics(),
          cacheExtent: 200.0,
          slivers: [
            // En-tête minimaliste
            SliverAppBar(
              automaticallyImplyLeading: false,
              expandedHeight: 140,
              collapsedHeight: 100,
              backgroundColor: isDarkMode ? AppTheme.socialDark : AppColors.lightBg,
              surfaceTintColor: Colors.transparent,
              flexibleSpace: FlexibleSpaceBar(
                collapseMode: CollapseMode.pin,
                background: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Expanded(
                            child: Text(
                              'Marché',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.w300,
                                color: Color(0xFF7BA428),
                                letterSpacing: -0.8,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          IconButton(
                            onPressed: _refreshData,
                            icon: Icon(
                              Icons.refresh_rounded,
                              color: isDarkMode ? Colors.grey.shade600 : Colors.grey.shade400,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Découvrez les produits agricoles',
                        style: TextStyle(
                          fontSize: 15,
                          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade600,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Barre de recherche avec debouncing
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverToBoxAdapter(
                child: Container(
                  height: 48,
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1A1A1A) : AppColors.lightBg,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(isDarkMode ? 0.1 : 0.04),
                        blurRadius: 12,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Rechercher un produit...',
                      hintStyle: TextStyle(
                        color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                        fontSize: 15,
                        fontWeight: FontWeight.w300,
                      ),
                      prefixIcon: Icon(
                        Icons.search_rounded,
                        color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                        size: 22,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                  ),
                ),
              ),
            ),

            // Filtres minimalistes
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              sliver: SliverToBoxAdapter(
                child: SizedBox(
                  height: 36,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    physics: const ClampingScrollPhysics(),
                    itemCount: _categories.length,
                    cacheExtent: 150,
                    addRepaintBoundaries: true,
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      final isSelected = _selectedCategory == category;
                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCategory = isSelected ? 'Tous' : category;
                            _cachedFilteredSales.clear();
                          });
                        },
                        child: Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xFF7BA428)
                                : isDarkMode
                                    ? const Color(0xFF1A1A1A)
                                    : Colors.white,
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(
                              color: isSelected
                                  ? Colors.transparent
                                  : isDarkMode
                                      ? Colors.grey.shade800
                                      : Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            category,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w400,
                              color: isSelected
                                  ? Colors.white
                                  : isDarkMode
                                      ? Colors.grey.shade400
                                      : Colors.grey.shade600,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),

            // Mes annonces (optimisé avec SliverGrid)
            if (_userId > 0)
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                sliver: SliverToBoxAdapter(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              'Mes annonces',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                                color: isDarkMode ? Colors.white : const Color(0xFF2C2416),
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _showMyAds ? 'Masquer' : 'Afficher',
                                style: const TextStyle(
                                  fontSize: 13,
                                  color: Color.fromARGB(255, 143, 82, 51),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() {
                                    _showMyAds = !_showMyAds;
                                  });
                                },
                                icon: Icon(
                                  _showMyAds
                                      ? Icons.expand_less_rounded
                                      : Icons.expand_more_rounded,
                                  color: const Color.fromARGB(255, 143, 82, 51),
                                  size: 20,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),

            // Grid des annonces personnelles (SliverGrid pour lazy loading)
            if (_userId > 0 && _showMyAds)
              FutureBuilder<List<dynamic>>(
                future: _mySalesFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverToBoxAdapter(
                        child: Center(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 40),
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                const Color.fromARGB(255, 143, 82, 51).withOpacity(0.6),
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                    return SliverPadding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      sliver: SliverToBoxAdapter(
                        child: Container(
                          height: 100,
                          margin: const EdgeInsets.only(top: 16),
                          decoration: BoxDecoration(
                            color: isDarkMode
                                ? const Color(0xFF1A1A1A)
                                : Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: const Color.fromARGB(255, 143, 82, 51).withOpacity(0.1),
                              width: 1,
                            ),
                          ),
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.add_photo_alternate_outlined,
                                  size: 32,
                                  color: isDarkMode
                                      ? Colors.grey.shade700
                                      : Colors.grey.shade300,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Aucune annonce',
                                  style: TextStyle(
                                    color: isDarkMode
                                        ? Colors.grey.shade500
                                        : Colors.grey.shade400,
                                    fontSize: 14,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  final mySales = snapshot.data!;
                  return SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
                    sliver: SliverGrid(
                      delegate: SliverChildBuilderDelegate(
                        (context, index) {
                          final sale = mySales[index];
                          return RepaintBoundary(
                            child: _buildMyOfferCard(sale, isDarkMode, key: ValueKey(sale['id'])),
                          );
                        },
                        childCount: mySales.length,
                        addRepaintBoundaries: true,
                      ),
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 12,
                        crossAxisSpacing: 12,
                        childAspectRatio: 0.72, // Ajusté pour éviter l'overflow
                      ),
                    ),
                  );
                },
              ),

            // Prix du marché (Collapsible)
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with expand/collapse button
                    GestureDetector(
                      onTap: () {
                        setState(() {
                          _showPrices = !_showPrices;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Prix du marché',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w300,
                                color: isDarkMode ? Colors.white : const Color(0xFF2C2416),
                                letterSpacing: -0.3,
                              ),
                            ),
                            Icon(
                              _showPrices ? Icons.expand_less : Icons.expand_more,
                              color: isDarkMode ? Colors.white70 : Colors.grey.shade700,
                              size: 24,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Expandable content
                    if (_showPrices)
                      Padding(
                        padding: const EdgeInsets.only(top: 16),
                        child: FutureBuilder<List<MarketPrice>>(
                          future: _marketPricesFuture,
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(40),
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Color.fromARGB(255, 143, 82, 51),
                                    ),
                                  ),
                                ),
                              );
                            }

                            if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                              return Container(
                                height: 100,
                                decoration: BoxDecoration(
                                  color: isDarkMode ? const Color(0xFF1A1A1A) : AppColors.lightBg,
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.trending_up_outlined,
                                        size: 32,
                                        color: isDarkMode
                                            ? Colors.grey.shade700
                                            : Colors.grey.shade300,
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Aucun prix disponible',
                                        style: TextStyle(
                                          color: isDarkMode
                                              ? Colors.grey.shade500
                                              : Colors.grey.shade400,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w300,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }

                            final prices = snapshot.data!;
                            return Column(
                              children: prices.map((price) {
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 12),
                                  child: RepaintBoundary(
                                    child: _buildPriceCard(price, isDarkMode),
                                  ),
                                );
                              }).toList(),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // Offres récentes
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offres récentes',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w300,
                        color: isDarkMode ? Colors.white : const Color(0xFF2C2416),
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Grille des offres
            FutureBuilder<List<dynamic>>(
              future: _salesFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      child: SkeletonGridLoader(
                        crossAxisCount: 2,
                        itemCount: 6,
                        isDarkMode: isDarkMode,
                      ),
                    ),
                  );
                }

                if (snapshot.hasError || !snapshot.hasData || snapshot.data!.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Container(
                      height: 200,
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1A1A1A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.storefront_outlined,
                              size: 48,
                              color: isDarkMode
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucune offre disponible',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade400,
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                final sales = snapshot.data!;
                final filteredSales = _getFilteredSales(sales);

                if (filteredSales.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Container(
                      height: 200,
                      margin: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                      decoration: BoxDecoration(
                        color: isDarkMode
                            ? const Color(0xFF1A1A1A)
                            : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off_rounded,
                              size: 48,
                              color: isDarkMode
                                  ? Colors.grey.shade700
                                  : Colors.grey.shade300,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              'Aucun résultat',
                              style: TextStyle(
                                color: isDarkMode
                                    ? Colors.grey.shade500
                                    : Colors.grey.shade400,
                                fontSize: 14,
                                fontWeight: FontWeight.w300,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
                  sliver: SliverGrid(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final sale = filteredSales[index];
                        return RepaintBoundary(
                          child: _buildOfferCard(sale, isDarkMode, key: ValueKey(sale['id'])),
                        );
                      },
                      childCount: filteredSales.length,
                      addRepaintBoundaries: true,
                    ),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 0.72, // Ajusté pour éviter l'overflow
                    ),
                  ),
                );
              },
            ),

            const SliverPadding(padding: EdgeInsets.only(bottom: 16)),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => const CreateSaleScreen(),
            ),
          ).then((result) {
            if (result == true) {
              _refreshData();
            }
          });
        },
        heroTag: 'market_fab',
        mini: true,
        backgroundColor: const Color(0xFF7BA428).withOpacity(0.9),
        foregroundColor: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.add_rounded, size: 20),
      ),
    );
  }

  Widget _buildPriceCard(MarketPrice price, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1A1A1A) : AppColors.lightBg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: const Color(0xFF7BA428).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.eco_outlined,
              color: Color(0xFF7BA428),
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  price.productName,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: isDarkMode ? Colors.white : const Color(0xFF2D5016),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Icon(
                      Icons.place_outlined,
                      size: 12,
                      color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                    ),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        price.region,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                          fontWeight: FontWeight.w300,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                price.pricePerKg.toStringAsFixed(0),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF7BA428),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${price.currency}/kg',
                style: TextStyle(
                  fontSize: 11,
                  color: isDarkMode ? Colors.grey.shade500 : Colors.grey.shade400,
                  fontWeight: FontWeight.w300,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOfferCard(dynamic sale, bool isDarkMode, {Key? key}) {
    final productName = sale['product_name'] as String? ?? 'Produit';
    final pricePerUnit = sale['price_per_unit'] as num? ?? 0;
    final currency = sale['currency'] as String? ?? 'CFA';
    final location = sale['delivery_location'] as String? ?? 'Lieu non spécifié';
    final imageUrl = sale['image_url'] as String?;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SaleDetailScreen(sale: sale),
          ),
        );
      },
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF111111) : AppColors.lightBg,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.25 : 0.06),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Image optimisée - Hauteur fixe
            Container(
              height: 130, // Ajusté pour éviter l'overflow
              decoration: BoxDecoration(
                color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey.shade100,
              ),
              child: imageUrl != null
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 250,
                      memCacheHeight: 130,
                      fadeInDuration: const Duration(milliseconds: 200),
                      placeholder: (context, url) => Container(
                        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey.shade100,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              const Color(0xFF7BA428).withOpacity(0.5),
                            ),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey.shade100,
                        child: const Center(
                          child: Icon(
                            Icons.image_outlined,
                            color: Color(0xFF7BA428),
                            size: 28,
                          ),
                        ),
                      ),
                    )
                  : Container(
                      color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey.shade100,
                      child: const Center(
                        child: Icon(
                          Icons.image_outlined,
                          color: Color(0xFF7BA428),
                          size: 28,
                        ),
                      ),
                    ),
            ),
            // Contenu compact
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Flexible(
                      child: Text(
                        productName,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: isDarkMode ? Colors.white : const Color(0xFF233C15),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Flexible(
                      child: Row(
                        children: [
                          Icon(
                            Icons.place_outlined,
                            size: 9,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                          ),
                          const SizedBox(width: 2),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: 9,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                fontWeight: FontWeight.w300,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    Flexible(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              '$pricePerUnit $currency',
                              style: const TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Color(0xFF7BA428),
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(
                            Icons.chevron_right_rounded,
                            size: 12,
                            color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
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

  Widget _buildMyOfferCard(dynamic sale, bool isDarkMode, {Key? key}) {
    final productName = sale['product_name'] as String? ?? 'Produit';
    final pricePerUnit = sale['price_per_unit'] as num? ?? 0;
    final currency = sale['currency'] as String? ?? 'CFA';
    final location = sale['delivery_location'] as String? ?? 'Lieu non spécifié';
    final saleId = sale['id'] as int? ?? 0;
    final imageUrl = sale['image_url'] as String?;
    
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => SaleDetailScreen(sale: sale),
          ),
        );
      },
      child: Stack(
        children: [
          Container(
            clipBehavior: Clip.antiAlias,
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF111111) : AppColors.lightBg,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDarkMode ? 0.22 : 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Image optimisée - Hauteur fixe
                Container(
                  height: 110, // Hauteur réduite
                  decoration: BoxDecoration(
                    color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey.shade100,
                  ),
                  child: imageUrl != null
                      ? CachedNetworkImage(
                          imageUrl: imageUrl,
                          fit: BoxFit.cover,
                          memCacheWidth: 220,
                          memCacheHeight: 110,
                          fadeInDuration: const Duration(milliseconds: 200),
                          placeholder: (context, url) => Container(
                            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey.shade100,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  const Color.fromARGB(255, 143, 82, 51).withOpacity(0.5),
                                ),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey.shade100,
                            child: const Center(
                              child: Icon(
                                Icons.verified_outlined,
                                color: Color.fromARGB(255, 143, 82, 51),
                                size: 24,
                              ),
                            ),
                          ),
                        )
                      : Container(
                          color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.grey.shade100,
                          child: const Center(
                            child: Icon(
                              Icons.verified_outlined,
                              color: Color.fromARGB(255, 143, 82, 51),
                              size: 24,
                            ),
                          ),
                        ),
                ),
                // Contenu
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(7),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Titre flexible
                        Flexible(
                          child: Text(
                            productName,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isDarkMode ? Colors.white : const Color(0xFF233C15),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(height: 3),
                        // Localisation flexible
                        Flexible(
                          child: Row(
                            children: [
                              Icon(
                                Icons.place_outlined,
                                size: 10,
                                color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                              ),
                              const SizedBox(width: 3),
                              Expanded(
                                child: Text(
                                  location,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade600,
                                    fontWeight: FontWeight.w300,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Spacer(),
                        // Prix flexible
                        Flexible(
                          child: Text(
                            '$pricePerUnit $currency',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: Color.fromARGB(255, 143, 82, 51),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          // Boutons édition/suppression
          Positioned(
            right: 4,
            top: 4,
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateSaleScreen(
                          sale: sale,
                          saleId: saleId,
                        ),
                      ),
                    );
                    if (result == true) {
                      _refreshData();
                    }
                  },
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.edit_outlined,
                      size: 12,
                      color: Color.fromARGB(255, 143, 82, 51),
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                GestureDetector(
                  onTap: () => _showDeleteConfirmation(saleId),
                  child: Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.delete_outline,
                      size: 12,
                      color: Colors.red,
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

  void _showDeleteConfirmation(int saleId) {
    showDialog(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
        return Dialog(
          backgroundColor: isDarkMode ? const Color(0xFF1A1A1A) : AppColors.lightBg,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Supprimer l\'annonce',
                  style: TextStyle(
                    color: isDarkMode ? Colors.white : const Color(0xFF2C2416),
                    fontWeight: FontWeight.w400,
                    fontSize: 18,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Êtes-vous sûr de vouloir supprimer cette annonce?',
                  style: TextStyle(
                    color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                    fontSize: 14,
                    fontWeight: FontWeight.w300,
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                      ),
                      child: Text(
                        'Annuler',
                        style: TextStyle(
                          color: isDarkMode ? Colors.grey.shade400 : Colors.grey.shade500,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: TextButton(
                        onPressed: () async {
                          Navigator.pop(context);
                          await _deleteSale(saleId);
                        },
                        style: TextButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                        ),
                        child: const Text(
                          'Supprimer',
                          style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w400,
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
      },
    );
  }

  Future<void> _deleteSale(int saleId) async {
    try {
      await ApiService.deleteSale(saleId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Annonce supprimée'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: const Color(0xFF7BA428),
            margin: const EdgeInsets.all(16),
          ),
        );
        _refreshData();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            backgroundColor: Colors.red,
            margin: const EdgeInsets.all(16),
          ),
        );
      }
    }
  }
}