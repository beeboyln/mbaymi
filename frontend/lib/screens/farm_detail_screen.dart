import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/screens/activity_screen.dart';
import 'package:mbaymi/widgets/farm_posts_widget.dart';

class FarmDetailScreen extends StatefulWidget {
  final int farmId;
  final Map<String, dynamic> farmData;
  final bool isDarkMode;
  final bool readOnly;
  
  const FarmDetailScreen({
    Key? key,
    required this.farmId,
    required this.farmData,
    this.isDarkMode = false,
    this.readOnly = false,
  }) : super(key: key);

  @override
  State<FarmDetailScreen> createState() => _FarmDetailScreenState();
}

class _FarmDetailScreenState extends State<FarmDetailScreen> {
  static const Color _primaryColor = Color(0xFF6B8E23);
  static const Color _bgLight = Color(0xFFF8F9FA);
  static const Color _bgDark = Color(0xFF0A0A0A);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _cardDark = Color(0xFF1A1A1A);
  static const Color _borderLight = Color(0xFFE5E5E5);
  static const Color _borderDark = Color(0xFF2C2C2C);

  late Future<Map<String, dynamic>> _farmDetailsFuture;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _userId = AuthService.currentSession?.userId ?? 0;
    _farmDetailsFuture = _getFarmDetails(widget.farmId);
  }

  Future<Map<String, dynamic>> _getFarmDetails(int farmId) async {
    try {
      final response = await http.get(
        Uri.parse('${ApiService.baseUrl}/farm-network/details/$farmId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to load farm details');
      }
    } catch (e) {
      rethrow;
    }
  }

  Future<void> _refresh() async {
    setState(() {
      _farmDetailsFuture = _getFarmDetails(widget.farmId);
    });
  }

  int? _toInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    return int.tryParse(v.toString());
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? _bgDark : _bgLight;
    final cardColor = isDark ? _cardDark : _cardLight;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white60 : Colors.black54;
    final borderColor = isDark ? _borderDark : _borderLight;

    final farmName = widget.farmData['farm_name'] ?? widget.farmData['name'] ?? widget.farmData['title'] ?? 'Ferme';
    final farmerName = widget.farmData['farmer_name'] ?? widget.farmData['user_name'] ?? widget.farmData['owner_name'] ?? widget.farmData['owner'] ?? 'Agriculteur';
    final farmDesc = widget.farmData['description'] ?? widget.farmData['bio'] ?? '';

    return Scaffold(
      backgroundColor: bgColor,
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: _primaryColor,
        child: CustomScrollView(
          slivers: [
            // AppBar élégante
            SliverAppBar(
              expandedHeight: 200,
              pinned: true,
              backgroundColor: cardColor,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.9),
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.arrow_back, color: textColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: FutureBuilder<Map<String, dynamic>>(
                  future: _farmDetailsFuture,
                  builder: (context, snapshot) {
                    final photos = (snapshot.data?['photos'] as List?) ?? [];
                    final photoImage = photos.isNotEmpty ? (photos.first as Map<String, dynamic>)['image_url'] : null;
                    final profileImage = widget.farmData['profile_image'] ?? widget.farmData['image_url'] ?? widget.farmData['profile_image_farm'] ?? widget.farmData['image'];
                    final imageUrl = photoImage ?? (profileImage is String && profileImage.isNotEmpty ? profileImage : null);

                    if (imageUrl != null) {
                      return Stack(
                        fit: StackFit.expand,
                        children: [
                          Image.network(
                            imageUrl,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildPlaceholderHeader(),
                          ),
                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  Colors.transparent,
                                  bgColor.withOpacity(0.3),
                                ],
                              ),
                            ),
                          ),
                        ],
                      );
                    }
                    return _buildPlaceholderHeader();
                  },
                ),
              ),
            ),

            // Contenu principal
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(24),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête avec nom et propriétaire
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            farmName,
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 16),
                          
                          // Propriétaire
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: borderColor),
                            ),
                            child: Row(
                              children: [
                                Container(
                                  width: 40,
                                  height: 40,
                                  decoration: const BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _primaryColor,
                                  ),
                                  child: const Icon(
                                    Icons.person,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        farmerName,
                                        style: TextStyle(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w500,
                                          color: textColor,
                                        ),
                                      ),
                                      Text(
                                        'Propriétaire',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          
                          // Description
                          if (farmDesc.isNotEmpty) ...[
                            const SizedBox(height: 20),
                            Text(
                              farmDesc,
                              style: TextStyle(
                                fontSize: 15,
                                color: secondaryTextColor,
                                height: 1.5,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    
                    // Section Parcelles
                    _buildParcellesSection(
                      textColor,
                      secondaryTextColor,
                      cardColor,
                      borderColor,
                      isDark,
                    ),

                    const SizedBox(height: 24),

                    // Posts de la ferme (lecture seule si demandé)
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Publications',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: textColor),
                          ),
                          const SizedBox(height: 12),
                          DecoratedBox(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: const BorderRadius.all(Radius.circular(16)),
                              border: Border.all(color: borderColor, width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: FarmPostsWidget(
                                farmId: widget.farmId,
                                farmName: farmName,
                                isOwner: !widget.readOnly && (_toInt(widget.farmData['user_id']) == _userId || _toInt(widget.farmData['owner_id']) == _userId),
                                livestockId: null,
                              ),
                            ),
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

  Widget _buildPlaceholderHeader() {
    return Container(
      color: _primaryColor.withOpacity(0.1),
      child: Center(
        child: Icon(
          Icons.agriculture_outlined,
          size: 80,
          color: _primaryColor.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildParcellesSection(
    Color textColor,
    Color secondaryTextColor,
    Color cardColor,
    Color borderColor,
    bool isDark,
  ) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _farmDetailsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(60),
            child: Center(
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: _primaryColor,
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.all(40),
            child: Column(
              children: [
                Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  'Erreur de chargement',
                  style: TextStyle(color: textColor),
                ),
              ],
            ),
          );
        }

        final crops = (snapshot.data?['crops'] as List?) ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Parcelles',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryColor.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${crops.length}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 20),
              
              // Liste des parcelles
              if (crops.isEmpty)
                _buildEmptyState(textColor, secondaryTextColor)
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: crops.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final crop = crops[index] as Map<String, dynamic>;
                    return _buildParcelCard(
                      crop,
                      textColor,
                      secondaryTextColor,
                      cardColor,
                      borderColor,
                      isDark,
                    );
                  },
                ),
              
              const SizedBox(height: 100),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(Color textColor, Color secondaryTextColor) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(
            Icons.landscape_outlined,
            size: 64,
            color: _primaryColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune parcelle',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: textColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les parcelles apparaîtront ici',
            style: TextStyle(
              fontSize: 14,
              color: secondaryTextColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildParcelCard(
    Map<String, dynamic> crop,
    Color textColor,
    Color secondaryTextColor,
    Color cardColor,
    Color borderColor,
    bool isDark,
  ) {
    final Map<String, Map<String, dynamic>> statusConfig = {
      'En préparation': {
        'color': const Color(0xFFFFA726),
        'icon': Icons.construction_outlined,
      },
      'Semé': {
        'color': const Color(0xFF66BB6A),
        'icon': Icons.grass_outlined,
      },
      'En croissance': {
        'color': const Color(0xFF42A5F5),
        'icon': Icons.trending_up_outlined,
      },
      'Récolté': {
        'color': const Color(0xFFAB47BC),
        'icon': Icons.check_circle_outlined,
      },
    };

    final status = crop['status'] ?? 'En préparation';
    final config = statusConfig[status] ?? statusConfig['En préparation']!;
    final statusColor = config['color'] as Color;
    final statusIcon = config['icon'] as IconData;

    return GestureDetector(
      onTap: () => _showActivitiesModal(crop, textColor, secondaryTextColor, borderColor, isDark),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: borderColor),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec badge de statut
            Stack(
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(16),
                  ),
                  child: Container(
                    height: 140,
                    width: double.infinity,
                    color: _primaryColor.withOpacity(0.1),
                    child: crop['image_url'] != null
                        ? Image.network(
                            crop['image_url'],
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => _buildParcelPlaceholder(),
                          )
                        : _buildParcelPlaceholder(),
                  ),
                ),
                
                // Badge de statut
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: statusColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(statusIcon, size: 14, color: Colors.white),
                        const SizedBox(width: 6),
                        Text(
                          status,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            // Informations
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    crop['crop_name'] ?? 'Parcelle',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Détails en grille
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.calendar_today_outlined,
                          label: crop['planted_date'] ?? 'Non défini',
                          color: secondaryTextColor,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoItem(
                          icon: Icons.agriculture_outlined,
                          label: crop['crop_type'] ?? 'Type inconnu',
                          color: secondaryTextColor,
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Bouton action
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: borderColor),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.timeline,
                          size: 16,
                          color: _primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Voir les activités',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: _primaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildParcelPlaceholder() {
    return Center(
      child: Icon(
        Icons.landscape_outlined,
        size: 48,
        color: _primaryColor.withOpacity(0.3),
      ),
    );
  }

  void _showActivitiesModal(
    Map<String, dynamic> crop,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
    bool isDark,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? _cardDark : _cardLight,
          borderRadius: const BorderRadius.vertical(
            top: Radius.circular(24),
          ),
        ),
        child: Column(
          children: [
            // Handle
            Container(
              margin: const EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: secondaryTextColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            
            // En-tête
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop['crop_name'] ?? 'Parcelle',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Activités',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: secondaryTextColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            // ActivityScreen
            Expanded(
              child: ActivityScreen(
                farmId: widget.farmId,
                cropId: _toInt(crop['id']) ?? 0,
                userId: _userId,
                readOnly: true,
              ),
            ),
          ],
        ),
      ),
    );
  }
}