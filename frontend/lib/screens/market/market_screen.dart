import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/services/data_repository.dart';
import 'package:mbaymi/services/cart_provider.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/models/market_model.dart';
import 'package:mbaymi/screens/market/create_sale_screen.dart';
import 'package:mbaymi/screens/market/sale_detail_screen.dart';
import 'package:mbaymi/screens/market/cart_screen.dart';
import 'package:mbaymi/widgets/skeleton_loader.dart';

class MarketTab extends StatefulWidget {
  final bool isDarkMode;
  const MarketTab({super.key, this.isDarkMode = false});

  @override
  State<MarketTab> createState() => _MarketTabState();
}

class _MarketTabState extends State<MarketTab> {
  String _searchQuery = '';
  String _selectedCategory = 'Tous';
  final int _userId = AuthService.currentSession?.userId ?? 0;
  bool _showMyAds = true;
  bool _showPrices = false;
  
  // Filtres avancés
  double _minPrice = 0;
  double _maxPrice = 1000000;
  String _selectedLocation = 'Tous';
  bool _showAdvancedFilters = false;
  
  final List<String> _locations = [
    'Tous',
    'Dakar',
    'Thiès',
    'Kaolack',
    'Kolda',
    'Tambacounda',
    'Saint-Louis',
    'Louga',
    'Matam',
    'Kédougou',
    'Sédhiou',
    'Ziguinchor',
    'Fatick'
  ];
  
  // ✅ STATIC PERSISTENT CACHE
  static final Map<String, Future<List<dynamic>>> _globalSalesCache = {};
  static final Map<String, Future<List<MarketPrice>>> _globalPricesCache = {};
  final DataRepository _repository = DataRepository();
  
  final List<String> _categories = [
    'Tous',
    'Cultures',
    'Bétail',
    'Légumes',
    'Fruits',
    'Grains'
  ];
  
  final TextEditingController _searchController = TextEditingController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
  
  Future<List<dynamic>> _getSalesCached() {
    const cacheKey = 'sales_all';
    if (!_globalSalesCache.containsKey(cacheKey)) {
      _globalSalesCache[cacheKey] = _repository.getMarketSales().catchError((_) => <dynamic>[]);
    }
    return _globalSalesCache[cacheKey]!;
  }
  
  Future<List<dynamic>> _getMyCliSalesCached() {
    if (_userId <= 0) return Future.value([]);
    final cacheKey = 'sales_user_$_userId';
    if (!_globalSalesCache.containsKey(cacheKey)) {
      _globalSalesCache[cacheKey] = ApiService.getSalesByUser(_userId).catchError((_) => <dynamic>[]);
    }
    return _globalSalesCache[cacheKey]!;
  }
  
  Future<List<MarketPrice>> _getMarketPricesCached() {
    const cacheKey = 'prices_market';
    if (!_globalPricesCache.containsKey(cacheKey)) {
      _globalPricesCache[cacheKey] = ApiService.getMarketPrices().catchError((_) => <MarketPrice>[]);
    }
    return _globalPricesCache[cacheKey]!;
  }

  void _invalidateAllCaches() {
    _repository.invalidateMarketCaches();
    _globalSalesCache.clear();
    _globalPricesCache.clear();
  }

  Future<void> _refreshData() async {
    HapticFeedback.mediumImpact();
    _invalidateAllCaches();
    _searchController.clear();
    _searchQuery = '';
    if (mounted) {
      setState(() {});
    }
    await Future.wait([
      _getSalesCached(),
      _getMarketPricesCached(),
      if (_userId > 0) _getMyCliSalesCached(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    final bgColor = AppColors.getBgColor(isDark);
    final textColor = AppColors.getTextColor(isDark);
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDark);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isDesktop = constraints.maxWidth >= 768;

        return Scaffold(
          key: _scaffoldKey,
          backgroundColor: bgColor,
          appBar: AppBar(
            backgroundColor: bgColor,
            elevation: 0,
            leading: isDesktop
                ? null
                : IconButton(
                    icon: Icon(Icons.menu, color: textColor, size: 24),
                    onPressed: () {
                      HapticFeedback.lightImpact();
                      _scaffoldKey.currentState?.openDrawer();
                    },
                  ),
            title: Text(
              'MARCHÉ',
              style: TextStyle(
                color: textColor,
                fontSize: 13,
                fontWeight: FontWeight.w400,
                letterSpacing: 2.5,
              ),
            ),
            centerTitle: !isDesktop,
            actions: [
              Consumer<CartProvider>(
                builder: (context, cartProvider, _) {
                  return Stack(
                    children: [
                      IconButton(
                        icon: Icon(Icons.shopping_basket_outlined, color: textColor, size: 24),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => const CartScreen()),
                          );
                        },
                      ),
                      if (cartProvider.itemCount > 0)
                        Positioned(
                          right: 8,
                          top: 8,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            constraints: const BoxConstraints(
                              minWidth: 18,
                              minHeight: 18,
                            ),
                            child: Text(
                              '${cartProvider.itemCount}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                    ],
                  );
                },
              ),
              IconButton(
                icon: Icon(Icons.add, color: textColor, size: 24),
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const CreateSaleScreen()),
                  ).then((r) => r == true ? _refreshData() : null);
                },
              ),
            ],
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 0.5,
                color: AppColors.getBorderColor(isDark),
              ),
            ),
          ),
          drawer: isDesktop ? null : _buildDrawer(isDark, textColor, secondaryTextColor),
          body: isDesktop
              ? _buildDesktopLayout(isDark, textColor, secondaryTextColor)
              : _buildMobileLayout(isDark, textColor, secondaryTextColor),
        );
      },
    );
  }

  // ── CONTENU DU MENU (UTILISÉ POUR LE DRAWER MOBILE ET LA SIDEBAR DESKTOP) ──

  Widget _buildFilterContent(bool isDark, Color textColor, Color secondaryTextColor, {bool isDrawer = false}) {
    final borderColor = AppColors.getBorderColor(isDark);

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
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
                    Icons.shopping_bag_outlined,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'FILTRES',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 2,
                    color: secondaryTextColor,
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: borderColor, thickness: 0.5),
          ),

          const SizedBox(height: 16),

          // Section CATÉGORIES
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: Text(
              'CATÉGORIES',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
                color: secondaryTextColor,
              ),
            ),
          ),

          const SizedBox(height: 8),

          ..._categories.map((cat) => _buildDrawerCategoryItem(
                cat,
                _selectedCategory == cat,
                isDark,
                textColor,
                () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedCategory = cat);
                  if (isDrawer) Navigator.pop(context);
                },
              )),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: borderColor, thickness: 0.5),
          ),

          const SizedBox(height: 16),

          // Section PRIX DU MARCHÉ
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _showPrices = !_showPrices);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'PRIX DU MARCHÉ',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                      color: secondaryTextColor,
                    ),
                  ),
                  Icon(
                    _showPrices ? Icons.expand_less : Icons.expand_more,
                    color: textColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_showPrices) ...[
            const SizedBox(height: 8),
            _buildDrawerMarketPrices(isDark, textColor, secondaryTextColor),
          ],

          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Divider(color: borderColor, thickness: 0.5),
          ),

          const SizedBox(height: 16),

          // Section FILTRES AVANCÉS
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              setState(() => _showAdvancedFilters = !_showAdvancedFilters);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'FILTRES AVANCÉS',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                      color: secondaryTextColor,
                    ),
                  ),
                  Icon(
                    _showAdvancedFilters ? Icons.expand_less : Icons.expand_more,
                    color: textColor,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),

          if (_showAdvancedFilters) ...[
            const SizedBox(height: 12),
            _buildAdvancedFiltersSection(isDark, textColor, secondaryTextColor),
          ],

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildDrawer(bool isDark, Color textColor, Color secondaryTextColor) {
    final bgColor = AppColors.getBgColor(isDark);
    return Drawer(
      backgroundColor: bgColor,
      width: 280,
      child: SafeArea(
        child: _buildFilterContent(isDark, textColor, secondaryTextColor, isDrawer: true),
      ),
    );
  }

  // ── DESKTOP & MOBILE LAYOUTS ───────────────────────────────────────────────

  Widget _buildDesktopLayout(bool isDark, Color textColor, Color secondaryTextColor) {
    final borderColor = AppColors.getBorderColor(isDark);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Sidebar fixe à gauche
        SizedBox(
          width: 280,
          child: Container(
            decoration: BoxDecoration(
              border: Border(right: BorderSide(color: borderColor, width: 0.5)),
            ),
            child: SafeArea(
              child: _buildFilterContent(isDark, textColor, secondaryTextColor, isDrawer: false),
            ),
          ),
        ),

        // Zone principale du marché à droite
        Expanded(
          child: RefreshIndicator(
            onRefresh: _refreshData,
            color: AppColors.primary,
            backgroundColor: AppColors.getCardBgColor(isDark),
            child: CustomScrollView(
              slivers: [
                _buildSearchBar(isDark, textColor, secondaryTextColor),

                if (_userId > 0) ...[
                  _buildMyAdsHeader(isDark, textColor, secondaryTextColor),
                  if (_showMyAds) _buildMyAdsGrid(isDark, crossAxisCount: 3),
                ],

                _buildRecentOffersHeader(isDark, textColor, secondaryTextColor),
                _buildOffersGrid(isDark, crossAxisCount: 3),

                const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, Color textColor, Color secondaryTextColor) {
    return RefreshIndicator(
      onRefresh: _refreshData,
      color: AppColors.primary,
      backgroundColor: AppColors.getCardBgColor(isDark),
      child: CustomScrollView(
        slivers: [
          _buildSearchBar(isDark, textColor, secondaryTextColor),

          if (_userId > 0) ...[
            _buildMyAdsHeader(isDark, textColor, secondaryTextColor),
            if (_showMyAds) _buildMyAdsGrid(isDark, crossAxisCount: 2),
          ],

          _buildRecentOffersHeader(isDark, textColor, secondaryTextColor),
          _buildOffersGrid(isDark, crossAxisCount: 2),

          const SliverPadding(padding: EdgeInsets.only(bottom: 40)),
        ],
      ),
    );
  }

  // ── WIDGET COMPONENTS ──────────────────────────────────────────────────────

  Widget _buildDrawerCategoryItem(
    String category,
    bool isSelected,
    bool isDark,
    Color textColor,
    VoidCallback onTap,
  ) {
    return InkWell(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
        child: Text(
          category.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            letterSpacing: 1.5,
            color: isSelected ? AppColors.primary : textColor,
          ),
        ),
      ),
    );
  }
  
  Widget _buildDrawerMarketPrices(bool isDark, Color textColor, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FutureBuilder<List<MarketPrice>>(
        future: _getMarketPricesCached(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                  ),
                ),
              ),
            );
          }
          
          if (!snap.hasData || snap.data!.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Aucun prix disponible',
                style: TextStyle(
                  fontSize: 11,
                  color: secondaryTextColor,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            );
          }
          
          return Column(
            children: snap.data!.map((price) => 
              _buildDrawerPriceItem(price, isDark, textColor, secondaryTextColor)
            ).toList(),
          );
        },
      ),
    );
  }
  
  Widget _buildDrawerPriceItem(
    MarketPrice price,
    bool isDark,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final borderColor = AppColors.getBorderColor(isDark);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.eco_outlined,
            color: AppColors.primary,
            size: 16,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price.productName,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.5,
                    color: textColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  price.region,
                  style: TextStyle(
                    fontSize: 9,
                    color: secondaryTextColor,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          Text(
            price.pricePerKg.toStringAsFixed(0),
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
              letterSpacing: 0.3,
            ),
          ),
        ],
      ),
    );
  }

  SliverPadding _buildSearchBar(bool isDark, Color textColor, Color secondaryTextColor) {
    final borderColor = AppColors.getBorderColor(isDark);
    
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 20),
      sliver: SliverToBoxAdapter(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'RECHERCHER',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
                color: secondaryTextColor,
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w400,
                letterSpacing: 0.3,
              ),
              decoration: InputDecoration(
                hintText: 'Nom du produit...',
                hintStyle: TextStyle(
                  color: secondaryTextColor.withOpacity(0.5),
                  letterSpacing: 0.3,
                ),
                prefixIcon: Icon(
                  Icons.search,
                  color: secondaryTextColor,
                  size: 20,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
                enabledBorder: UnderlineInputBorder(
                  borderSide: BorderSide(color: borderColor, width: 1),
                ),
                focusedBorder: UnderlineInputBorder(
                  borderSide: BorderSide(
                    color: isDark 
                        ? AppColors.primary.withOpacity(0.5)
                        : AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildMyAdsHeader(bool isDark, Color textColor, Color secondaryTextColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 16, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'MES ANNONCES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
                color: textColor,
              ),
            ),
            IconButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() => _showMyAds = !_showMyAds);
              },
              icon: Icon(
                _showMyAds ? Icons.expand_less : Icons.expand_more,
                color: textColor,
                size: 20,
              ),
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding _buildMyAdsGrid(bool isDark, {int crossAxisCount = 2}) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      sliver: FutureBuilder<List<dynamic>>(
        future: _getMyCliSalesCached(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SkeletonGridLoader(
                  crossAxisCount: crossAxisCount,
                  itemCount: 4,
                  isDarkMode: isDark,
                ),
              ),
            );
          }
          if (!snap.hasData || snap.data!.isEmpty) {
            return SliverToBoxAdapter(
              child: _buildEmptyState(
                'Aucune annonce',
                'Créez votre première annonce',
                Icons.add_photo_alternate_outlined,
                isDark,
              ),
            );
          }
          return SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildSaleCard(snap.data![i], true, isDark),
              childCount: snap.data!.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildRecentOffersHeader(bool isDark, Color textColor, Color secondaryTextColor) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'TOUTES LES OFFRES',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                letterSpacing: 2,
                color: textColor,
              ),
            ),
            if (_selectedCategory != 'Tous')
              InkWell(
                onTap: () {
                  HapticFeedback.lightImpact();
                  setState(() => _selectedCategory = 'Tous');
                },
                child: const Text(
                  'Réinitialiser',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 1,
                    color: AppColors.primary,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  SliverPadding _buildOffersGrid(bool isDark, {int crossAxisCount = 2}) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      sliver: FutureBuilder<List<dynamic>>(
        future: _getSalesCached(),
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: SkeletonGridLoader(
                  crossAxisCount: crossAxisCount,
                  itemCount: 4,
                  isDarkMode: isDark,
                ),
              ),
            );
          }
          
          final sales = snap.data ?? [];
          final filtered = sales.where((s) {
            final name = (s['product_name'] as String? ?? '').toLowerCase();
            final cat = s['category'] as String? ?? '';
            final price = (s['price_per_unit'] as num? ?? 0).toDouble();
            final location = s['delivery_location'] as String? ?? '';
            
            return (_searchQuery.isEmpty || name.contains(_searchQuery)) &&
                   (_selectedCategory == 'Tous' || cat == _selectedCategory) &&
                   (price >= _minPrice && price <= _maxPrice) &&
                   (_selectedLocation == 'Tous' || location.toLowerCase().contains(_selectedLocation.toLowerCase()));
          }).toList();

          if (filtered.isEmpty) {
            return SliverToBoxAdapter(
              child: _buildEmptyState(
                'Aucun résultat',
                'Essayez d\'autres filtres',
                Icons.search_off,
                isDark,
              ),
            );
          }

          return SliverGrid(
            delegate: SliverChildBuilderDelegate(
              (ctx, i) => _buildSaleCard(filtered[i], false, isDark),
              childCount: filtered.length,
            ),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              mainAxisSpacing: 16,
              crossAxisSpacing: 16,
              childAspectRatio: 0.7,
            ),
          );
        },
      ),
    );
  }

  Widget _buildSaleCard(dynamic sale, bool isMyAd, bool isDark) {
    final textColor = AppColors.getTextColor(isDark);
    final borderColor = AppColors.getBorderColor(isDark);
    
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => SaleDetailScreen(sale: sale)),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image
            Expanded(
              flex: 7,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  _buildProductImage(sale['image_url'], isDark),
                  if (isMyAd) _buildEditButtons(sale, isDark),
                ],
              ),
            ),
            
            // Info
            Expanded(
              flex: 3,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      (sale['product_name'] ?? 'Produit').toUpperCase(),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 12,
                                color: AppColors.getSecondaryTextColor(isDark),
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  sale['delivery_location'] ?? '',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.getSecondaryTextColor(isDark),
                                    letterSpacing: 0.3,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          '${sale['price_per_unit']} ${sale['currency']}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
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

  Widget _buildProductImage(String? url, bool isDark) {
    return CachedNetworkImage(
      imageUrl: url ?? '',
      fit: BoxFit.cover,
      memCacheHeight: 400,
      memCacheWidth: 300,
      placeholder: (_, __) => Container(
        color: AppColors.getCardBgColor(isDark),
        child: Icon(
          Icons.image_outlined,
          color: AppColors.getSecondaryTextColor(isDark),
          size: 40,
        ),
      ),
      errorWidget: (_, __, ___) => Container(
        color: AppColors.getCardBgColor(isDark),
        child: Icon(
          Icons.broken_image_outlined,
          color: AppColors.getSecondaryTextColor(isDark),
          size: 40,
        ),
      ),
    );
  }

  Widget _buildEditButtons(dynamic sale, bool isDark) {
    return Positioned(
      top: 8,
      right: 8,
      child: Row(
        children: [
          InkWell(
            onTap: () async {
              HapticFeedback.lightImpact();
              final r = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CreateSaleScreen(saleId: sale['id'], sale: sale),
                ),
              );
              if (r == true) _refreshData();
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              color: Colors.black.withOpacity(0.7),
              child: const Icon(Icons.edit_outlined, size: 16, color: Colors.white),
            ),
          ),
          const SizedBox(width: 4),
          InkWell(
            onTap: () {
              HapticFeedback.lightImpact();
              _showDeleteDialog(sale['id']);
            },
            child: Container(
              padding: const EdgeInsets.all(6),
              color: Colors.black.withOpacity(0.7),
              child: const Icon(Icons.delete_outline, size: 16, color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon, bool isDark) {
    final textColor = AppColors.getTextColor(isDark);
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDark);
    final borderColor = AppColors.getBorderColor(isDark);
    
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 48,
            color: secondaryTextColor.withOpacity(0.5),
          ),
          const SizedBox(height: 16),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w400,
              letterSpacing: 2,
              color: textColor,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 13,
              color: secondaryTextColor,
              letterSpacing: 0.3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(int saleId) {
    final isDark = Provider.of<ThemeProvider>(context, listen: false).isDarkMode;
    final bgColor = AppColors.getBgColor(isDark);
    final textColor = AppColors.getTextColor(isDark);
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'SUPPRIMER L\'ANNONCE',
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer cette annonce ?',
          style: TextStyle(
            color: AppColors.getSecondaryTextColor(isDark),
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'ANNULER',
              style: TextStyle(
                color: textColor,
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              HapticFeedback.mediumImpact();
              Navigator.pop(ctx);
              await ApiService.deleteSale(saleId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text(
                      'Annonce supprimée',
                      style: TextStyle(letterSpacing: 0.5),
                    ),
                    backgroundColor: AppColors.success,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
                _refreshData();
              }
            },
            child: const Text(
              'SUPPRIMER',
              style: TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 11,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildAdvancedFiltersSection(bool isDark, Color textColor, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filtre de prix
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Gamme de prix (FCFA)',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Min',
                          hintStyle: TextStyle(color: secondaryTextColor, fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.getBorderColor(isDark), width: 1),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        onChanged: (v) {
                          setState(() {
                            _minPrice = double.tryParse(v) ?? 0;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextField(
                        keyboardType: TextInputType.number,
                        style: TextStyle(color: textColor, fontSize: 12),
                        decoration: InputDecoration(
                          hintText: 'Max',
                          hintStyle: TextStyle(color: secondaryTextColor, fontSize: 12),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.getBorderColor(isDark), width: 1),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                        onChanged: (v) {
                          setState(() {
                            _maxPrice = double.tryParse(v) ?? 1000000;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Filtre de localisation
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Localisation',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: AppColors.getBorderColor(isDark), width: 1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: DropdownButton<String>(
                    value: _selectedLocation,
                    isExpanded: true,
                    underline: const SizedBox.shrink(),
                    style: TextStyle(color: textColor, fontSize: 12),
                    dropdownColor: AppColors.getCardBgColor(isDark),
                    items: _locations.map((location) {
                      return DropdownMenuItem<String>(
                        value: location,
                        child: Text(location),
                      );
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) {
                        HapticFeedback.lightImpact();
                        setState(() => _selectedLocation = value);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Bouton réinitialiser les filtres
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                HapticFeedback.lightImpact();
                setState(() {
                  _minPrice = 0;
                  _maxPrice = 1000000;
                  _selectedLocation = 'Tous';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary.withOpacity(0.2),
                foregroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 10),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: const Text(
                'Réinitialiser filtres',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 1,
                ),
              ),
            ),
          ),
          
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}