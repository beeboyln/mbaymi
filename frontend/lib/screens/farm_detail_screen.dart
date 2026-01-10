import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/screens/activity_screen.dart';

class FarmDetailScreen extends StatefulWidget {
  final int farmId;
  final Map<String, dynamic> farmData;

  const FarmDetailScreen({
    Key? key,
    required this.farmId,
    required this.farmData,
  }) : super(key: key);

  @override
  State<FarmDetailScreen> createState() => _FarmDetailScreenState();
}

class _FarmDetailScreenState extends State<FarmDetailScreen> {
  static const Color _primaryColor = Color(0xFF8B6B4D);
  static const Color _bgLight = Color(0xFFFAF8F5);
  static const Color _bgDark = Color(0xFF0F0F0F);
  static const Color _cardLight = Color(0xFFFFFFFF);
  static const Color _cardDark = Color(0xFF1E1E1E);
  static const Color _borderLight = Color(0xFFE8E2D8);
  static const Color _borderDark = Color(0xFF2C2C2C);
  static const Color _textLight = Color(0xFF1A1A1A);
  static const Color _textDark = Colors.white;
  static const Color _textSecondaryLight = Color(0xFF6B6B6B);
  static const Color _textSecondaryDark = Color(0xFF8E8E93);

  late Future<Map<String, dynamic>> _farmDetailsFuture;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _userId = AuthService.currentSession?.userId ?? 0;
    print('🌾 FarmDetailScreen - farmId: ${widget.farmId}');
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
        throw Exception('Failed to load farm details: ${response.statusCode}');
      }
    } catch (e) {
      print('❌ Error fetching farm details: $e');
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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? _bgDark : _bgLight;
    final cardColor = isDark ? _cardDark : _cardLight;
    final textColor = isDark ? _textDark : _textLight;
    final secondaryTextColor = isDark ? _textSecondaryDark : _textSecondaryLight;
    final borderColor = isDark ? _borderDark : _borderLight;

    final farmName = widget.farmData['farm_name'] ?? 'Ferme';
    final farmerName = widget.farmData['farmer_name'] ?? widget.farmData['user_name'] ?? 'Agriculteur';
    final farmDesc = widget.farmData['description'] ?? 'Une belle ferme';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: cardColor,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded, color: secondaryTextColor, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          farmName,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w400,
            color: textColor,
          ),
        ),
        centerTitle: false,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: _primaryColor,
        backgroundColor: cardColor,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête minimaliste
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom de la ferme
                    Text(
                      farmName,
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.w300,
                        color: textColor,
                        letterSpacing: -1,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    
                    // Propriétaire avec avatar compact
                    FutureBuilder<Map<String, dynamic>>(
                      future: _farmDetailsFuture,
                      builder: (context, snapshot) {
                        final ownerName = snapshot.data?['owner_name'] ?? farmerName;
                        
                        return Row(
                          children: [
                            Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _primaryColor,
                                border: Border.all(
                                  color: cardColor,
                                  width: 2,
                                ),
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.person,
                                  color: Colors.white,
                                  size: 14,
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    ownerName,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w400,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    'Propriétaire',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: secondaryTextColor,
                                      fontWeight: FontWeight.w300,
                                      letterSpacing: 0.3,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        );
                      },
                    ),
                    
                    // Description
                    if (farmDesc.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Text(
                        farmDesc,
                        style: TextStyle(
                          fontSize: 15,
                          color: secondaryTextColor,
                          fontWeight: FontWeight.w300,
                          height: 1.6,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              
              // Photos Section (si disponibles)
              FutureBuilder<Map<String, dynamic>>(
                future: _farmDetailsFuture,
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox.shrink();
                  
                  final photos = (snapshot.data?['photos'] as List?) ?? [];
                  if (photos.isEmpty) return const SizedBox.shrink();
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Text(
                            'Galerie',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 120,
                          child: ListView.separated(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            scrollDirection: Axis.horizontal,
                            itemCount: photos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final photo = photos[index] as Map<String, dynamic>;
                              final imageUrl = photo['image_url'] ?? '';
                              
                              return ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(12)),
                                child: Container(
                                  width: 160,
                                  decoration: BoxDecoration(
                                    color: borderColor,
                                    borderRadius: const BorderRadius.all(Radius.circular(12)),
                                  ),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Center(
                                                child: Icon(
                                                  Icons.photo_outlined,
                                                  color: secondaryTextColor,
                                                  size: 40,
                                                ),
                                              ),
                                        )
                                      : Center(
                                          child: Icon(
                                            Icons.photo_outlined,
                                            color: secondaryTextColor,
                                            size: 40,
                                          ),
                                        ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              
              // Section Parcelles avec titre élégant
              Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: Border.all(color: borderColor, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // En-tête de section
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Parcelles',
                            style: TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w300,
                              color: textColor,
                              letterSpacing: -0.5,
                            ),
                          ),
                          FutureBuilder<Map<String, dynamic>>(
                            future: _farmDetailsFuture,
                            builder: (context, snapshot) {
                              final crops = (snapshot.data?['crops'] as List?) ?? [];
                              return Text(
                                '${crops.length}',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w300,
                                  color: _primaryColor,
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                    
                    // Liste des parcelles
                    FutureBuilder<Map<String, dynamic>>(
                      future: _farmDetailsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.waiting) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60),
                            child: Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: _primaryColor,
                                ),
                              ),
                            ),
                          );
                        }
                        
                        if (snapshot.hasError) {
                          return Padding(
                            padding: const EdgeInsets.all(40),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.error_outline_rounded,
                                  size: 48,
                                  color: Colors.red.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'Erreur de chargement',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    color: textColor,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        final crops = (snapshot.data?['crops'] as List?) ?? [];
                        
                        if (crops.isEmpty) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                            child: Column(
                              children: [
                                Icon(
                                  Icons.landscape_outlined,
                                  size: 56,
                                  color: _primaryColor.withOpacity(0.5),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Aucune parcelle',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w300,
                                    color: textColor,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Les parcelles apparaîtront ici',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: secondaryTextColor,
                                    fontWeight: FontWeight.w300,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                        
                        return Padding(
                          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                          child: Column(
                            children: List.generate(
                              crops.length,
                              (index) {
                                final crop = crops[index] as Map<String, dynamic>;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _buildMinimalistCropCard(
                                    crop,
                                    cardColor,
                                    textColor,
                                    secondaryTextColor,
                                    borderColor,
                                    isDark,
                                  ),
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMinimalistCropCard(
    Map<String, dynamic> crop,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
    bool isDark,
  ) {
    final Map<String, Map<String, dynamic>> statusColors = const {
      'En préparation': {'color': Color(0xFFFFA726), 'icon': Icons.construction_outlined},
      'Semé': {'color': Color(0xFF66BB6A), 'icon': Icons.grass_outlined},
      'En croissance': {'color': Color(0xFF42A5F5), 'icon': Icons.trending_up_outlined},
      'Récolté': {'color': Color(0xFFAB47BC), 'icon': Icons.check_circle_outlined},
    };

    final status = crop['status'] ?? 'En préparation';
    final statusInfo = statusColors[status] ?? const {'color': Colors.grey, 'icon': Icons.help_outline_outlined};
    final statusColor = statusInfo['color'] as Color;

    return Material(
      color: cardColor,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: () {
          _showActivitiesModal(crop, textColor, secondaryTextColor, borderColor, isDark);
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            border: Border.all(color: borderColor, width: 1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image avec overlay minimal
              Stack(
                children: [
                  // Image
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: Container(
                      width: double.infinity,
                      height: 140,
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                      ),
                      child: crop['image_url'] != null && crop['image_url'].toString().isNotEmpty
                          ? Image.network(
                              crop['image_url'] as String,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => 
                                  _buildPlaceholderImage(),
                            )
                          : _buildPlaceholderImage(),
                    ),
                  ),
                  
                  // Badge de statut flottant
                  Positioned(
                    top: 12,
                    left: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.95),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            statusInfo['icon'] as IconData,
                            size: 12,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            status,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              
              // Contenu texte
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom de la parcelle
                    Text(
                      crop['crop_name'] ?? 'Parcelle',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Détails secondaires
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 14,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          crop['planted_date'] ?? 'Date non définie',
                          style: TextStyle(
                            fontSize: 13,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Icon(
                          Icons.agriculture_outlined,
                          size: 14,
                          color: secondaryTextColor,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            crop['crop_type'] ?? 'Type non spécifié',
                            style: TextStyle(
                              fontSize: 13,
                              color: secondaryTextColor,
                              fontWeight: FontWeight.w300,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    
                    // Indicateur d'action
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(color: borderColor, width: 0.5),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Voir les activités',
                            style: TextStyle(
                              fontSize: 13,
                              color: _primaryColor,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 12,
                            color: _primaryColor,
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
      ),
    );
  }

  Widget _buildPlaceholderImage() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.landscape_outlined,
            size: 40,
            color: _primaryColor.withOpacity(0.3),
          ),
        ],
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
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
            const SizedBox(height: 16),
            
            // En-tête modal
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
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
                            fontWeight: FontWeight.w400,
                            color: textColor,
                          ),
                        ),
                        Text(
                          'Activités',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: secondaryTextColor),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 16),
            
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