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
  static const String _baseUrl = 'http://localhost:8000/api';

  late Future<Map<String, dynamic>> _farmDetailsFuture;
  int _userId = 0;

  @override
  void initState() {
    super.initState();
    _userId = AuthService.currentSession?.userId ?? 0;
    print('🌾 FarmDetailScreen - farmId: ${widget.farmId}');
    // Use the new comprehensive endpoint
    _farmDetailsFuture = _getFarmDetails(widget.farmId);
  }

  Future<Map<String, dynamic>> _getFarmDetails(int farmId) async {
    try {
      final response = await http.get(
        Uri.parse('${_baseUrl}/farm-network/details/$farmId'),
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
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, color: borderColor, thickness: 1),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(
          children: [
            // Farm Info Card
            DecoratedBox(
              decoration: BoxDecoration(
                color: cardColor,
                border: Border(
                  bottom: BorderSide(color: borderColor, width: 1),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Farm Name & Farmer
                    Text(
                      farmName,
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w300,
                        color: textColor,
                        letterSpacing: -0.8,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(Icons.person_outline, size: 16, color: secondaryTextColor),
                        const SizedBox(width: 6),
                        Text(
                          farmerName,
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    // Description
                    Text(
                      farmDesc,
                      style: TextStyle(
                        fontSize: 14,
                        color: secondaryTextColor,
                        fontWeight: FontWeight.w300,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // Photos Section
            FutureBuilder<Map<String, dynamic>>(
              future: _farmDetailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting || !snapshot.hasData) {
                  return const SizedBox.shrink();
                }

                final photos = (snapshot.data?['photos'] as List?) ?? [];
                if (photos.isEmpty) {
                  return const SizedBox.shrink();
                }

                return DecoratedBox(
                  decoration: BoxDecoration(
                    color: cardColor,
                    border: Border(
                      bottom: BorderSide(color: borderColor, width: 1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Photos',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w400,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          height: 150,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: photos.length,
                            separatorBuilder: (_, __) => const SizedBox(width: 12),
                            itemBuilder: (context, index) {
                              final photo = photos[index] as Map<String, dynamic>;
                              final imageUrl = photo['image_url'] ?? '';
                              
                              return ClipRRect(
                                borderRadius: const BorderRadius.all(Radius.circular(10)),
                                child: Container(
                                  width: 150,
                                  decoration: BoxDecoration(
                                    color: borderColor,
                                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                                  ),
                                  child: imageUrl.isNotEmpty
                                      ? Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Icon(Icons.image_not_supported, color: secondaryTextColor),
                                        )
                                      : Icon(Icons.image_outlined, color: secondaryTextColor),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

            // Crops/Parcels Section
            Padding(
              padding: const EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 8),
              child: Row(
                children: [
                  Text(
                    'Parcelles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),

            FutureBuilder<Map<String, dynamic>>(
              future: _farmDetailsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: _primaryColor,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Chargement des parcelles...',
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

                if (snapshot.hasError) {
                  print('❌ Error fetching farm details: ${snapshot.error}');
                  print('📱 FarmId: ${widget.farmId}');
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
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
                        const SizedBox(height: 8),
                        Text(
                          '${snapshot.error}',
                          style: TextStyle(
                            fontSize: 12,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 40,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: _primaryColor,
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                            ),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _refresh,
                                borderRadius: const BorderRadius.all(Radius.circular(8)),
                                child: const Center(
                                  child: Text(
                                    'Réessayer',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                final crops = (snapshot.data?['crops'] as List?) ?? [];
                print('🌾 Crops loaded: ${crops.length}');

                if (crops.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(40),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.landscape_outlined,
                          size: 56,
                          color: Color(0xFFA58A6D),
                        ),
                        const SizedBox(height: 24),
                        Text(
                          'Aucune parcelle',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w400,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Cette ferme n\'a pas encore créé de parcelles',
                          style: TextStyle(
                            fontSize: 14,
                            color: secondaryTextColor,
                            fontWeight: FontWeight.w300,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  );
                }

                return Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                  child: Column(
                    children: List.generate(
                      crops.length,
                      (index) {
                        final crop = crops[index] as Map<String, dynamic>;
                        return _buildCropCard(crop, cardColor, textColor, secondaryTextColor, borderColor, isDark);
                      },
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCropCard(
    Map<String, dynamic> crop,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
    bool isDark,
  ) {
    final Map<String, Map<String, dynamic>> statusColors = const {
      'En préparation': {'color': Colors.orange, 'icon': Icons.construction_outlined},
      'Semé': {'color': Colors.green, 'icon': Icons.grass_outlined},
      'En croissance': {'color': Colors.blue, 'icon': Icons.trending_up_outlined},
      'Récolté': {'color': Colors.purple, 'icon': Icons.check_circle_outlined},
    };

    final status = crop['status'] ?? 'En préparation';
    final statusInfo = statusColors[status] ?? const {'color': Colors.grey, 'icon': Icons.help_outline_outlined};

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: const BorderRadius.all(Radius.circular(12)),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Icon
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(10)),
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: _primaryColor.withOpacity(0.1),
                        borderRadius: const BorderRadius.all(Radius.circular(10)),
                      ),
                      child: Icon(
                        Icons.landscape_outlined,
                        size: 30,
                        color: _primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Info
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          crop['crop_name'] ?? 'Parcelle',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w400,
                            color: textColor,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DecoratedBox(
                          decoration: BoxDecoration(
                            color: (statusInfo['color'] as Color).withOpacity(0.1),
                            borderRadius: const BorderRadius.all(Radius.circular(6)),
                          ),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  statusInfo['icon'] as IconData,
                                  size: 14,
                                  color: statusInfo['color'] as Color,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: statusInfo['color'] as Color,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  
                  // Arrow
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: Color(0xFF6B6B6B),
                  ),
                ],
              ),
            ),
            
            // Action Buttons
            Row(
              children: [
                // Détails Button
                Expanded(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: borderColor, width: 1),
                      ),
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ActivityScreen(
                                farmId: widget.farmId,
                                cropId: _toInt(crop['id']) ?? 0,
                                userId: _userId,
                              ),
                            ),
                          ).then((_) => _refresh());
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Center(
                            child: Text(
                              'Activités',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w300,
                                color: _primaryColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        // Could show harvest details here
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Center(
                          child: Text(
                            'Récoltes',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w300,
                              color: _primaryColor,
                            ),
                          ),
                        ),
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
  }
}
