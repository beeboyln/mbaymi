import 'package:flutter/material.dart';

class AerialParcelsView extends StatefulWidget {
  final List<dynamic> parcels;
  final List<dynamic>? livestock;
  final bool isDarkMode;
  final Function(int)? onParcelTap;
  final Function(int)? onLivestockTap;
  final VoidCallback? onRefresh;
  final String farmName;

  const AerialParcelsView({
    super.key,
    required this.parcels,
    this.livestock,
    required this.isDarkMode,
    this.onParcelTap,
    this.onLivestockTap,
    this.onRefresh,
    this.farmName = 'Ferme',
  });

  @override
  State<AerialParcelsView> createState() => _AerialParcelsViewState();
}

class _AerialParcelsViewState extends State<AerialParcelsView> {
  late ScrollController _scrollController;
  int _selectedTab = 0; // 0: Ferme, 1: Bétail

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  String _getEmojiForCropType(String? name) {
    if (name == null) return '🌾';
    final lower = name.toLowerCase();
    if (lower.contains('blé') || lower.contains('riz')) return '🌾';
    if (lower.contains('légume') || lower.contains('salade') || lower.contains('carotte')) return '🥬';
    if (lower.contains('verger') || lower.contains('fruit')) return '🍎';
    if (lower.contains('poule') || lower.contains('poulet')) return '🐔';
    if (lower.contains('vache') || lower.contains('boeuf')) return '🐄';
    if (lower.contains('solaire') || lower.contains('énergie')) return '⚡';
    if (lower.contains('grange') || lower.contains('ferme')) return '🏠';
    return '🌾';
  }

  @override
  Widget build(BuildContext context) {
    final hasLivestock = widget.livestock != null && widget.livestock!.isNotEmpty;
    final itemsToShow = _selectedTab == 0 ? widget.parcels : (widget.livestock ?? []);

    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [
          // Header avec tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: widget.isDarkMode 
                  ? const Color(0xFF1A1A1A) 
                  : Colors.white,
              border: Border(
                bottom: BorderSide(
                  color: widget.isDarkMode 
                      ? Colors.white12 
                      : Colors.black12,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab(
                    '🏠 Ferme',
                    0,
                    '${widget.parcels.length} parcelles',
                  ),
                ),
                if (hasLivestock) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildTab(
                      '🐄 Bétail',
                      1,
                      '${widget.livestock!.length} animaux',
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Contenu aérien
          Expanded(
            child: Stack(
              children: [
                // Fond aérien stylisé
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: widget.isDarkMode
                          ? [
                              const Color(0xFF0D1A0D),
                              const Color(0xFF1A2A1A),
                            ]
                          : [
                              const Color(0xFFD4E4D4),
                              const Color(0xFFE8F0E8),
                            ],
                    ),
                  ),
                  child: CustomPaint(
                    painter: AerialMapPainter(isDarkMode: widget.isDarkMode),
                    size: Size.infinite,
                  ),
                ),

                // Contenu scrollable
                SingleChildScrollView(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  child: itemsToShow.isEmpty
                      ? _buildEmptyState()
                      : GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: MediaQuery.of(context).size.width < 768 ? 1 : 2,
                            childAspectRatio: MediaQuery.of(context).size.width < 768 ? 0.75 : 0.8,
                            crossAxisSpacing: 16,
                            mainAxisSpacing: 16,
                          ),
                          itemCount: itemsToShow.length,
                          itemBuilder: (context, index) {
                            return _selectedTab == 0
                                ? _buildParcelCard(index, itemsToShow[index])
                                : _buildLivestockCard(index, itemsToShow[index]);
                          },
                        ),
                ),

                // Bouton de rafraîchissement
                if (widget.onRefresh != null)
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.95),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: widget.onRefresh,
                          customBorder: const CircleBorder(),
                          child: const Padding(
                            padding: EdgeInsets.all(8),
                            child: Icon(
                              Icons.refresh,
                              color: Color(0xFF6B8E23),
                              size: 20,
                            ),
                          ),
                        ),
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

  Widget _buildTab(String label, int tabIndex, String subtitle) {
    final isSelected = _selectedTab == tabIndex;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedTab = tabIndex),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF6B8E23).withOpacity(0.15)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border(
              bottom: BorderSide(
                color: isSelected
                    ? const Color(0xFF6B8E23)
                    : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isSelected
                      ? const Color(0xFF6B8E23)
                      : (widget.isDarkMode
                          ? Colors.white60
                          : Colors.black54),
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isSelected
                      ? const Color(0xFF6B8E23)
                      : (widget.isDarkMode
                          ? Colors.white30
                          : Colors.black38),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildParcelCard(int index, Map<String, dynamic> parcel) {
    final statusConfig = {
      'En préparation': {'color': const Color(0xFFFFA726)},
      'Semé': {'color': const Color(0xFF66BB6A)},
      'En croissance': {'color': const Color(0xFF42A5F5)},
      'Récolté': {'color': const Color(0xFFAB47BC)},
    };

    final status = parcel['status'] ?? 'En préparation';
    final config = statusConfig[status] ?? statusConfig['En préparation']!;
    final statusColor = config['color'] as Color;
    final cropName = parcel['crop_name'] ?? 'Parcelle';
    final emoji = _getEmojiForCropType(cropName);
    final imageUrl = parcel['image_url'] as String?;
    final plantedDate = parcel['planted_date'] ?? '—';

    return GestureDetector(
      onTap: () => widget.onParcelTap?.call(parcel['id'] as int? ?? 0),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF0A0A0A) : Colors.white,
          border: Border.all(
            color: widget.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image (3/5 de la hauteur)
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: widget.isDarkMode ? const Color(0xFF151515) : const Color(0xFFF5F5F5),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: widget.isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8),
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    emoji,
                                    style: const TextStyle(fontSize: 36),
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Container(
                            color: widget.isDarkMode ? const Color(0xFF151515) : const Color(0xFFF5F5F5),
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 1.5,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  statusColor.withOpacity(0.5),
                                ),
                              ),
                            ),
                          );
                        },
                      )
                    : Container(
                        color: widget.isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFE8E8E8),
                        child: Center(
                          child: Text(
                            emoji,
                            style: const TextStyle(fontSize: 36),
                          ),
                        ),
                      ),
              ),
            ),
            // Infos (2/5 de la hauteur)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          cropName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: widget.isDarkMode ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w300,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today_outlined,
                          size: 11,
                          color: widget.isDarkMode ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            plantedDate,
                            style: TextStyle(
                              fontSize: 8,
                              color: widget.isDarkMode ? Colors.white38 : Colors.black38,
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLivestockCard(int index, Map<String, dynamic> animal) {
    final animalType = animal['animal_type'] ?? 'Animal';
    final name = animal['name'] ?? 'Animal';
    final status = animal['health_status'] ?? 'Normal';
    final statusColor = status == 'Healthy' || status == 'Normal'
        ? const Color(0xFF66BB6A)
        : status == 'Sick'
            ? Colors.red
            : Colors.orange;

    final animalEmoji = _getAnimalEmoji(animalType);

    return GestureDetector(
      onTap: () => widget.onLivestockTap?.call(animal['id'] as int? ?? 0),
      child: Container(
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF0A0A0A) : Colors.white,
          border: Border.all(
            color: widget.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Emoji background (3/5)
            Expanded(
              flex: 3,
              child: Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(10),
                    topRight: Radius.circular(10),
                  ),
                ),
                child: Center(
                  child: Text(
                    animalEmoji,
                    style: const TextStyle(fontSize: 36),
                  ),
                ),
              ),
            ),
            // Infos (2/5)
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.5,
                            color: widget.isDarkMode ? Colors.white : Colors.black87,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w300,
                              color: statusColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Icon(
                          Icons.pets_outlined,
                          size: 11,
                          color: widget.isDarkMode ? Colors.white38 : Colors.black38,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            animalType,
                            style: TextStyle(
                              fontSize: 8,
                              color: widget.isDarkMode ? Colors.white38 : Colors.black38,
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
            ),
          ],
        ),
      ),
    );
  }

  String _getAnimalEmoji(String? type) {
    if (type == null) return '🐄';
    final lower = type.toLowerCase();
    if (lower.contains('vache') || lower.contains('bovine') || lower.contains('cattle')) return '🐄';
    if (lower.contains('chèvre') || lower.contains('goat')) return '🐐';
    if (lower.contains('mouton') || lower.contains('sheep')) return '🐑';
    if (lower.contains('poule') || lower.contains('poulet') || lower.contains('chicken')) return '🐔';
    if (lower.contains('porc') || lower.contains('pig')) return '🐷';
    if (lower.contains('âne') || lower.contains('donkey')) return '🐴';
    return '🐄';
  }

  Widget _buildEmptyState() {
    return SizedBox(
      height: 200,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              _selectedTab == 0 ? Icons.landscape_outlined : Icons.pets_outlined,
              size: 48,
              color: const Color(0xFF6B8E23).withOpacity(0.3),
            ),
            const SizedBox(height: 12),
            Text(
              _selectedTab == 0
                  ? 'Aucune parcelle'
                  : 'Pas d\'animaux',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: widget.isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Custom painter pour la carte aérienne
class AerialMapPainter extends CustomPainter {
  final bool isDarkMode;

  AerialMapPainter({required this.isDarkMode});

  @override
  void paint(Canvas canvas, Size size) {
    // Grille légère
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05);

    const gridSpacing = 80.0;
    for (double x = 0; x < size.width; x += gridSpacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSpacing) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Lignes courbes décoratives
    final curvePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = isDarkMode
          ? const Color(0xFF6B8E23).withOpacity(0.1)
          : const Color(0xFF6B8E23).withOpacity(0.08);

    final path = Path();
    for (int i = 0; i < 3; i++) {
      path.reset();
      final y = 60 + i * 100;
      path.moveTo(0, y.toDouble());
      path.quadraticBezierTo(
        size.width * 0.25,
        y - 30,
        size.width * 0.5,
        y + 15,
      );
      path.quadraticBezierTo(
        size.width * 0.75,
        y + 60,
        size.width,
        y - 5,
      );
      canvas.drawPath(path, curvePaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
