import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/models/market_model.dart';

class MarketTab extends StatelessWidget {
  final bool isDarkMode;

  const MarketTab({Key? key, this.isDarkMode = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Marché',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    color: Color(0xFF2C2416),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Prix et offres en temps réel',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),

        // Prix
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: FutureBuilder<List<MarketPrice>>(
            future: ApiService.getMarketPrices(),
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

              final prices = snapshot.data!;
              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final price = prices[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPriceCard(price),
                    );
                  },
                  childCount: prices.length,
                ),
              );
            },
          ),
        ),

        // Offres
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
          sliver: SliverToBoxAdapter(
            child: Text(
              'Offres récentes',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w300,
                color: const Color(0xFF2C2416),
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              _buildOfferCard(
                'Moussa Sow',
                'Dakar',
                'Récolte de maïs disponible',
                Icons.agriculture,
                const Color(0xFF6B8E23),
              ),
              const SizedBox(height: 12),
              _buildOfferCard(
                'Aïssatou Diallo',
                'Kaolack',
                'Bétail sain à vendre',
                Icons.pets,
                const Color(0xFFD2691E),
              ),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildPriceCard(MarketPrice price) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 300;
        
        return Container(
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 10 : 14),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B8E23).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  Icons.shopping_basket_outlined,
                  color: const Color(0xFF6B8E23),
                  size: isCompact ? 24 : 32,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      price.productName,
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D5016),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isCompact) ...[
                      const SizedBox(height: 6),
                    ] else ...[
                      const SizedBox(height: 3),
                    ],
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: isCompact ? 11 : 13, color: Colors.grey.shade500),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            price.region,
                            style: TextStyle(
                              fontSize: isCompact ? 12 : 13,
                              color: Colors.grey.shade600,
                              height: 1.2,
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
              const SizedBox(width: 8),
              Container(
                padding: EdgeInsets.symmetric(horizontal: isCompact ? 10 : 14, vertical: isCompact ? 8 : 10),
                decoration: BoxDecoration(
                  color: const Color(0xFF6B8E23).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${price.pricePerKg.toStringAsFixed(0)}',
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF6B8E23),
                        letterSpacing: -0.3,
                        height: 1,
                      ),
                    ),
                    Text(
                      '${price.currency}/kg',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade600,
                        fontWeight: FontWeight.w300,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOfferCard(String author, String region, String title, IconData icon, Color color) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isCompact = constraints.maxWidth < 300;
        
        return Container(
          padding: EdgeInsets.all(isCompact ? 14 : 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: EdgeInsets.all(isCompact ? 10 : 14),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: color, size: isCompact ? 24 : 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: isCompact ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF2D5016),
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (!isCompact) ...[
                      const SizedBox(height: 6),
                    ] else ...[
                      const SizedBox(height: 3),
                    ],
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.symmetric(horizontal: isCompact ? 6 : 8, vertical: isCompact ? 2 : 4),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            author,
                            style: TextStyle(
                              fontSize: isCompact ? 12 : 13,
                              color: Colors.grey.shade700,
                              height: 1,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Icon(Icons.location_on_outlined, size: isCompact ? 11 : 13, color: Colors.grey.shade500),
                        const SizedBox(width: 3),
                        Expanded(
                          child: Text(
                            region,
                            style: TextStyle(
                              fontSize: isCompact ? 12 : 13,
                              color: Colors.grey.shade600,
                              height: 1.2,
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
              if (!isCompact) ...[
                Icon(Icons.chevron_right, color: Colors.grey.shade300, size: 24),
              ],
            ],
          ),
        );
      },
    );
  }
}
