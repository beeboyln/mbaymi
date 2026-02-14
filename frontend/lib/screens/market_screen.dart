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
  final int _userId = AuthService.currentSession?.userId ?? 0;
  bool _showMyAds = true;
  bool _showPrices = false;
  
  final List<String> _categories = ['Tous', 'Cultures', 'Bétail', 'Légumes', 'Fruits', 'Grains'];
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _salesFuture = ApiService.getAllSales().catchError((_) => <dynamic>[]);
    _marketPricesFuture = ApiService.getMarketPrices().catchError((_) => <MarketPrice>[]);
    if (_userId > 0) {
      _mySalesFuture = ApiService.getSalesByUser(_userId).catchError((_) => <dynamic>[]);
    }
  }

  Future<void> _refreshData() async {
    setState(() => _loadData());
    await Future.wait([
      _salesFuture,
      _marketPricesFuture,
      if (_userId > 0) _mySalesFuture,
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Scaffold(
      backgroundColor: isDark ? AppTheme.socialDark : AppColors.lightBg,
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CreateSaleScreen()))
            .then((r) => r == true ? _refreshData() : null),
        mini: true,
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add_rounded, size: 20),
      ),
      body: RefreshIndicator(
        onRefresh: _refreshData,
        color: AppColors.primary,
        child: CustomScrollView(
          slivers: [
            _buildHeader(isDark),
            _buildSearchBar(isDark),
            _buildCategoryFilters(isDark),
            if (_userId > 0) _buildMyAdsHeader(isDark),
            if (_userId > 0 && _showMyAds) _buildMyAdsGrid(),
            _buildMarketPricesHeader(isDark),
            if (_showPrices) _buildMarketPrices(),
            _buildRecentOffersHeader(isDark),
            _buildOffersGrid(isDark),
          ],
        ),
      ),
    );
  }

  // Header optimisé
  SliverAppBar _buildHeader(bool isDark) {
    return SliverAppBar(
      automaticallyImplyLeading: false,
      expandedHeight: 120,
      collapsedHeight: 80,
      backgroundColor: isDark ? AppTheme.socialDark : AppColors.lightBg,
      flexibleSpace: FlexibleSpaceBar(
        background: Padding(
          padding: const EdgeInsets.fromLTRB(20, 40, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Marché', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w300, color: AppColors.primary)),
                  IconButton(onPressed: _refreshData, icon: Icon(Icons.refresh_rounded, color: isDark ? Colors.grey.shade600 : Colors.grey.shade400)),
                ],
              ),
              Text('Produits agricoles', style: TextStyle(fontSize: 14, color: isDark ? Colors.grey.shade500 : Colors.grey.shade600)),
            ],
          ),
        ),
      ),
    );
  }

  SliverPadding _buildSearchBar(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      sliver: SliverToBoxAdapter(
        child: Container(
          height: 45,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: BorderRadius.circular(25),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)],
          ),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: 'Rechercher...',
              prefixIcon: Icon(Icons.search_rounded, size: 20, color: isDark ? Colors.grey.shade500 : Colors.grey.shade400),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 20),
            ),
          ),
        ),
      ),
    );
  }

  SliverPadding _buildCategoryFilters(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      sliver: SliverToBoxAdapter(
        child: SizedBox(
          height: 35,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _categories.length,
            itemBuilder: (ctx, i) {
              final cat = _categories[i];
              final sel = _selectedCategory == cat;
              return GestureDetector(
                onTap: () => setState(() => _selectedCategory = sel ? 'Tous' : cat),
                child: Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: sel ? AppColors.primary : (isDark ? const Color(0xFF1A1A1A) : Colors.white),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: sel ? Colors.transparent : (isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
                  ),
                  child: Text(cat, style: TextStyle(fontSize: 13, color: sel ? Colors.white : (isDark ? Colors.grey.shade400 : Colors.grey.shade600))),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  SliverToBoxAdapter _buildMyAdsHeader(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Mes annonces', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: isDark ? Colors.white : const Color(0xFF2C2416))),
            IconButton(
              onPressed: () => setState(() => _showMyAds = !_showMyAds),
              icon: Icon(_showMyAds ? Icons.expand_less : Icons.expand_more, color: AppColors.primary, size: 20),
            ),
          ],
        ),
      ),
    );
  }

  SliverPadding _buildMyAdsGrid() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      sliver: FutureBuilder<List<dynamic>>(
        future: _mySalesFuture,
        builder: (_, snap) {
          if (!snap.hasData || snap.data!.isEmpty) {
            return SliverToBoxAdapter(child: _buildEmptyState('Aucune annonce', Icons.add_photo_alternate_outlined));
          }
          return SliverGrid(
            delegate: SliverChildBuilderDelegate((ctx, i) => _buildSaleCard(snap.data![i], true),
                childCount: snap.data!.length),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.7),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildMarketPricesHeader(bool isDark) {
    return SliverToBoxAdapter(
      child: GestureDetector(
        onTap: () => setState(() => _showPrices = !_showPrices),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Prix du marché', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: isDark ? Colors.white : const Color(0xFF2C2416))),
              Icon(_showPrices ? Icons.expand_less : Icons.expand_more, color: isDark ? Colors.white70 : Colors.grey.shade700),
            ],
          ),
        ),
      ),
    );
  }

  SliverPadding _buildMarketPrices() {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
      sliver: FutureBuilder<List<MarketPrice>>(
        future: _marketPricesFuture,
        builder: (_, snap) {
          if (!snap.hasData || snap.data!.isEmpty) {
            return SliverToBoxAdapter(child: _buildEmptyState('Aucun prix', Icons.trending_up_outlined));
          }
          return SliverList(
            delegate: SliverChildBuilderDelegate((ctx, i) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _buildPriceCard(snap.data![i]),
            ), childCount: snap.data!.length),
          );
        },
      ),
    );
  }

  SliverToBoxAdapter _buildRecentOffersHeader(bool isDark) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text('Offres récentes', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w300, color: isDark ? Colors.white : const Color(0xFF2C2416))),
      ),
    );
  }

  SliverPadding _buildOffersGrid(bool isDark) {
    return SliverPadding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 40),
      sliver: FutureBuilder<List<dynamic>>(
        future: _salesFuture,
        builder: (_, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return SliverToBoxAdapter(child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: SkeletonGridLoader(crossAxisCount: 2, itemCount: 4, isDarkMode: isDark),
            ));
          }
          
          final sales = snap.data ?? [];
          final filtered = sales.where((s) {
            final name = (s['product_name'] as String? ?? '').toLowerCase();
            final cat = s['category'] as String? ?? '';
            return (_searchQuery.isEmpty || name.contains(_searchQuery)) &&
                   (_selectedCategory == 'Tous' || cat == _selectedCategory);
          }).toList();

          if (filtered.isEmpty) {
            return SliverToBoxAdapter(child: _buildEmptyState('Aucun résultat', Icons.search_off_rounded));
          }

          return SliverGrid(
            delegate: SliverChildBuilderDelegate((ctx, i) => _buildSaleCard(filtered[i], false),
                childCount: filtered.length),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2, mainAxisSpacing: 10, crossAxisSpacing: 10, childAspectRatio: 0.7),
          );
        },
      ),
    );
  }

  // Carte de vente unifiée avec images améliorées
  Widget _buildSaleCard(dynamic sale, bool isMyAd) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SaleDetailScreen(sale: sale))),
      child: Stack(
        children: [
          // Image container avec héritage et ratio fixe
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: AspectRatio(
              aspectRatio: 0.7,
              child: Container(
                color: Colors.grey.shade900,
                child: _buildProductImage(sale['image_url']),
              ),
            ),
          ),
          // Overlay gradient pour lisibilité
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: 70,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Colors.black.withOpacity(0.8)],
                ),
              ),
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  Text(sale['product_name'] ?? 'Produit',
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Icon(Icons.place, size: 8, color: Colors.white70),
                      const SizedBox(width: 2),
                      Expanded(
                        child: Text(sale['delivery_location'] ?? '',
                            style: const TextStyle(color: Colors.white70, fontSize: 9),
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                      ),
                      Text('${sale['price_per_unit']} ${sale['currency']}',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 11)),
                    ],
                  ),
                ],
              ),
            ),
          ),
          // Boutons d'édition pour mes annonces
          if (isMyAd) _buildEditButtons(sale['id']),
        ],
      ),
    );
  }

  // Image optimisée avec CachedNetworkImage
  Widget _buildProductImage(String? url) {
    return CachedNetworkImage(
      imageUrl: url ?? '',
      fit: BoxFit.cover,
      memCacheHeight: 200, // Cache optimisé
      memCacheWidth: 150,
      placeholder: (_, __) => Container(
        color: Colors.grey.shade800,
        child: const Center(child: Icon(Icons.image, color: Colors.white54, size: 30)),
      ),
      errorWidget: (_, __, ___) => Container(
        color: Colors.grey.shade800,
        child: const Center(child: Icon(Icons.broken_image, color: Colors.white54, size: 30)),
      ),
    );
  }

  Widget _buildEditButtons(int saleId) {
    return Positioned(
      top: 8,
      right: 8,
      child: Row(
        children: [
          _buildIconButton(Icons.edit, AppColors.primary, () async {
            final r = await Navigator.push(context, MaterialPageRoute(builder: (_) => CreateSaleScreen(saleId: saleId)));
            if (r == true) _refreshData();
          }),
          const SizedBox(width: 6),
          _buildIconButton(Icons.delete, Colors.red, () => _showDeleteDialog(saleId)),
        ],
      ),
    );
  }

  Widget _buildIconButton(IconData icon, Color color, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }

  Widget _buildPriceCard(MarketPrice price) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
            child: const Icon(Icons.eco, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(price.productName, style: const TextStyle(fontWeight: FontWeight.w500)),
                Text(price.region, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Column(
            children: [
              Text('${price.pricePerKg.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.primary)),
              Text('${price.currency}/kg', style: TextStyle(fontSize: 9, color: Colors.grey.shade500)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String msg, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      height: 120,
      margin: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: isDark ? Colors.grey.shade700 : Colors.grey.shade300),
            const SizedBox(height: 8),
            Text(msg, style: TextStyle(color: isDark ? Colors.grey.shade500 : Colors.grey.shade400)),
          ],
        ),
      ),
    );
  }

  void _showDeleteDialog(int saleId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Confirmer la suppression?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await ApiService.deleteSale(saleId);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Annonce supprimée')));
                _refreshData();
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Supprimer'),
          ),
        ],
      ),
    );
  }
}