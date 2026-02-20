import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/parcel_screen.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/widgets/farm_aerial_view.dart';

class ParcelsAerialScreen extends StatefulWidget {
  final int farmId;
  final int userId;
  final String? farmName;

  const ParcelsAerialScreen({
    super.key,
    required this.farmId,
    required this.userId,
    this.farmName,
  });

  @override
  State<ParcelsAerialScreen> createState() => _ParcelsAerialScreenState();
}

class _ParcelsAerialScreenState extends State<ParcelsAerialScreen> {
  late Future<List<dynamic>> _parcelsFuture;
  late Future<List<dynamic>> _livestockFuture;

  static const Color _primaryColor = Color(0xFF6B8E23);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    _parcelsFuture = ApiService.getFarmCrops(widget.farmId);
    _livestockFuture = ApiService.getLivestock(userId: widget.userId);
  }

  Future<void> _refresh() async {
    setState(() {
      _loadData();
    });
  }

  void _openParcelDetail(int cropId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParcelScreen(
          farmId: widget.farmId,
          userId: widget.userId,
        ),
      ),
    ).then((_) => _refresh());
  }

  Widget _buildParcelProfile(Map<String, dynamic> parcel, bool isDark, int index) {
    final cropName = parcel['crop_name'] ?? 'Parcelle';
    final status = parcel['status'] ?? 'En préparation';
    final plantedDate = parcel['planted_date'] ?? '—';
    final expectedHarvest = parcel['expected_harvest_date'] ?? '—';
    final area = parcel['area'] ?? '—';
    final soilType = parcel['soil_type'] ?? '—';
    final irrigation = parcel['irrigation_type'] ?? '—';
    
    return GestureDetector(
      onTap: () => _openParcelDetail(parcel['id'] ?? 0),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F0F0F) : Colors.white,
          border: Border.all(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image de la parcelle
            if (parcel['image_url'] != null && (parcel['image_url'] as String).isNotEmpty)
              Container(
                width: double.infinity,
                height: 120,
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    parcel['image_url'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(
                          strokeWidth: 1.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            _primaryColor.withOpacity(0.5),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            // En-tête avec numéro et nom
            Row(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: _primaryColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        cropName.toUpperCase(),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 1.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _getStatusColor(status).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          status,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
                            color: _getStatusColor(status),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward_ios,
                  size: 14,
                  color: isDark ? Colors.white38 : Colors.black38,
                ),
              ],
            ),
            const SizedBox(height: 12),
            Divider(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              height: 1,
            ),
            const SizedBox(height: 12),
            // Grille de détails
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: [
                _buildDetailItem('📅', 'SEMIS', plantedDate, isDark),
                _buildDetailItem('🎯', 'RÉCOLTE', expectedHarvest, isDark),
                _buildDetailItem('📐', 'SURFACE', area, isDark),
                _buildDetailItem('🌍', 'SOL', soilType, isDark),
                _buildDetailItem('💧', 'ARROSAGE', irrigation, isDark),
                _buildDetailItem('🔢', 'ID', parcel['id'].toString(), isDark),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String emoji, String label, String value, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.02) : Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
              color: isDark ? Colors.white38 : Colors.black38,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w300,
              color: isDark ? Colors.white : Colors.black87,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'en préparation':
        return Colors.orange;
      case 'semé':
        return Colors.green;
      case 'en croissance':
        return Colors.blue;
      case 'récolte':
        return Colors.purple;
      default:
        return _primaryColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : AppColors.lightBg;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.farmName ?? 'Vue Aérienne',
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: Future.wait([_parcelsFuture, _livestockFuture]),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(
              child: CircularProgressIndicator(
                color: _primaryColor,
              ),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.warning_outlined,
                    size: 64,
                    color: Colors.red.withOpacity(0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                ],
              ),
            );
          }

          final results = snapshot.data ?? [];
          final parcels = results.isNotEmpty ? (results[0] as List<dynamic>?) ?? [] : [];
          final livestock = results.length > 1 ? (results[1] as List<dynamic>?) ?? [] : [];

          return RefreshIndicator(
            onRefresh: _refresh,
            backgroundColor: bgColor,
            color: _primaryColor,
            child: CustomScrollView(
              slivers: [
                // Vue aérienne
                
                // Divider et titre
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Divider(
                          color: isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                          height: 1,
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'PROFILS DES PARCELLES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 2.0,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${parcels.length} parcelle${parcels.length > 1 ? 's' : ''}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
                            color: isDark ? Colors.white38 : Colors.black38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                // Liste des parcelles détaillées
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final parcel = parcels[index] as Map<String, dynamic>;
                        return _buildParcelProfile(parcel, isDark, index);
                      },
                      childCount: parcels.length,
                    ),
                  ),
                ),
                SliverToBoxAdapter(
                  child: const SizedBox(height: 32),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
