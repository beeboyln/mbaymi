import 'package:flutter/material.dart';

/// Widgets de visualisation pour la ferme - Style Zara minimaliste
class FarmWidgets {
  // Badge statistique épuré
  static Widget buildStatBadge(String emoji, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 8),
          Text(
            value.toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w300,
              fontSize: 11,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  // Élément de barre latérale minimaliste
  static Widget buildSidebarItem(
    int section,
    int selectedSection,
    String label,
    IconData icon,
    bool isDarkMode,
    Function(int) onTap,
  ) {
    final isSelected = selectedSection == section;
    return GestureDetector(
      onTap: () => onTap(section),
      child: Container(
        margin: const EdgeInsets.only(left: 16, right: 16, bottom: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected 
              ? (isDarkMode ? Colors.white.withOpacity(0.03) : Colors.black.withOpacity(0.02))
              : Colors.transparent,
          border: Border(
            left: BorderSide(
              color: isSelected 
                  ? const Color(0xFF6B8E23)
                  : Colors.transparent,
              width: 1.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected 
                  ? (isDarkMode ? Colors.white : Colors.black87)
                  : (isDarkMode ? Colors.white38 : Colors.black38),
            ),
            const SizedBox(width: 16),
            Text(
              label.toUpperCase(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
                color: isSelected 
                    ? (isDarkMode ? Colors.white : Colors.black87)
                    : (isDarkMode ? Colors.white38 : Colors.black38),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Carte de parcelle vue aérienne - style architectural
  static Widget buildParcelCard({
    required String title,
    required String subtitle,
    required String details,
    required IconData icon,
    required bool isDarkMode,
  }) {
    return Container(
      width: 180,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0A0A0A) : Colors.white,
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon, 
            size: 20, 
            color: isDarkMode ? Colors.white70 : Colors.black87,
          ),
          const SizedBox(height: 16),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.5,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
              color: isDarkMode ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            details,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w300,
              color: isDarkMode ? Colors.white24 : Colors.black26,
            ),
          ),
        ],
      ),
    );
  }

  // Panel de statistiques épuré
  static Widget buildFarmStatsPanel(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ÉTAT DE LA FERME',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w300,
              letterSpacing: 2.0,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              buildStatItem('🌤️', 'MÉTÉO', 'Ensoleillé', isDarkMode),
              Container(
                width: 1,
                height: 40,
                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              ),
              buildStatItem('💧', 'ARROSAGE', 'Optimal', isDarkMode),
              Container(
                width: 1,
                height: 40,
                color: isDarkMode ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.05),
              ),
              buildStatItem('⚡', 'ÉNERGIE', '85%', isDarkMode),
            ],
          ),
        ],
      ),
    );
  }

  // Élément de statistique minimaliste
  static Widget buildStatItem(String emoji, String label, String value, bool isDarkMode) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            emoji,
            style: const TextStyle(fontSize: 20),
          ),
          const SizedBox(height: 12),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.0,
              color: isDarkMode ? Colors.white38 : Colors.black38,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
              color: isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  // Boutons d'action minimalistes
  static Widget buildActionButtons(bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
      child: Row(
        children: [
          Expanded(child: buildActionButton('📦', 'INVENTAIRE', isDarkMode)),
          const SizedBox(width: 12),
          Expanded(child: buildActionButton('✓', 'TÂCHES', isDarkMode)),
          const SizedBox(width: 12),
          Expanded(child: buildActionButton('🛒', 'MARCHÉ', isDarkMode)),
          const SizedBox(width: 12),
          Expanded(child: buildActionButton('📊', 'RAPPORTS', isDarkMode)),
        ],
      ),
    );
  }

  // Bouton vue aérienne - ultra épuré et immersif
  static Widget buildAerialViewButton({
    required bool isDarkMode,
    required VoidCallback onTap,
  }) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 0, vertical: 16),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: isDarkMode ? const Color(0xFF0A0A0A) : Colors.white,
              border: Border.all(
                color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: isDarkMode ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1),
                      width: 1,
                    ),
                  ),
                  child: Icon(
                    Icons.satellite_outlined,
                    color: isDarkMode ? Colors.white70 : Colors.black87,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'VUE AÉRIENNE',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 2.0,
                          color: isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Visualisez vos parcelles',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w300,
                          letterSpacing: 0.5,
                          color: isDarkMode ? Colors.white38 : Colors.black38,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: isDarkMode ? Colors.white38 : Colors.black38,
                  size: 16,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Bouton d'action individuel
  static Widget buildActionButton(String emoji, String label, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF0A0A0A) : Colors.white,
        border: Border.all(
          color: isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(emoji, style: const TextStyle(fontSize: 20)),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w300,
              letterSpacing: 1.5,
              color: isDarkMode ? Colors.white70 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }
}

/// Custom painter pour dessiner la vue aérienne de ferme - Style architectural minimaliste
class FarmMapPainter extends CustomPainter {
  final bool isDarkMode;
  
  FarmMapPainter({required this.isDarkMode});
  
  @override
  void paint(Canvas canvas, Size size) {
    // Fond de base - terre
    final bgPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDarkMode 
          ? const Color(0xFF0A0A0A)
          : const Color(0xFFF5F5F0);
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    
    // Grille topographique ultra fine
    final gridPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.02)
          : Colors.black.withOpacity(0.02);
    
    // Lignes horizontales
    for (int i = 0; i <= 10; i++) {
      final y = (size.height / 10) * i;
      canvas.drawLine(
        Offset(0, y),
        Offset(size.width, y),
        gridPaint,
      );
    }
    
    // Lignes verticales
    for (int i = 0; i <= 12; i++) {
      final x = (size.width / 12) * i;
      canvas.drawLine(
        Offset(x, 0),
        Offset(x, size.height),
        gridPaint,
      );
    }
    
    // Parcelles agricoles - rectangles organiques
    final parcelPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDarkMode
          ? const Color(0xFF1A2A1A).withOpacity(0.3)
          : const Color(0xFFE8F0E8).withOpacity(0.6);
    
    final parcelBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.05)
          : const Color(0xFF6B8E23).withOpacity(0.15);
    
    // Parcelle 1 - Grande parcelle nord
    final parcel1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.05, size.height * 0.1, size.width * 0.4, size.height * 0.35),
      const Radius.circular(4),
    );
    canvas.drawRRect(parcel1, parcelPaint);
    canvas.drawRRect(parcel1, parcelBorderPaint);
    
    // Parcelle 2 - Parcelle est
    final parcel2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.15, size.width * 0.38, size.height * 0.25),
      const Radius.circular(4),
    );
    canvas.drawRRect(parcel2, parcelPaint);
    canvas.drawRRect(parcel2, parcelBorderPaint);
    
    // Parcelle 3 - Parcelle sud-ouest
    final parcel3 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.08, size.height * 0.55, size.width * 0.35, size.height * 0.35),
      const Radius.circular(4),
    );
    canvas.drawRRect(parcel3, parcelPaint);
    canvas.drawRRect(parcel3, parcelBorderPaint);
    
    // Parcelle 4 - Petite parcelle sud-est
    final parcel4 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.55, size.height * 0.5, size.width * 0.38, size.height * 0.38),
      const Radius.circular(4),
    );
    canvas.drawRRect(parcel4, parcelPaint);
    canvas.drawRRect(parcel4, parcelBorderPaint);
    
    // Lignes de culture dans les parcelles - effet de champs labourés
    final rowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.03)
          : const Color(0xFF6B8E23).withOpacity(0.1);
    
    // Lignes dans parcelle 1
    for (int i = 0; i < 15; i++) {
      final y = size.height * 0.1 + (size.height * 0.35 / 15) * i;
      canvas.drawLine(
        Offset(size.width * 0.05, y),
        Offset(size.width * 0.45, y),
        rowPaint,
      );
    }
    
    // Lignes dans parcelle 2
    for (int i = 0; i < 10; i++) {
      final y = size.height * 0.15 + (size.height * 0.25 / 10) * i;
      canvas.drawLine(
        Offset(size.width * 0.55, y),
        Offset(size.width * 0.93, y),
        rowPaint,
      );
    }
    
    // Lignes dans parcelle 3
    for (int i = 0; i < 15; i++) {
      final y = size.height * 0.55 + (size.height * 0.35 / 15) * i;
      canvas.drawLine(
        Offset(size.width * 0.08, y),
        Offset(size.width * 0.43, y),
        rowPaint,
      );
    }
    
    // Lignes dans parcelle 4
    for (int i = 0; i < 15; i++) {
      final y = size.height * 0.5 + (size.height * 0.38 / 15) * i;
      canvas.drawLine(
        Offset(size.width * 0.55, y),
        Offset(size.width * 0.93, y),
        rowPaint,
      );
    }
    
    // Chemin central - style minimaliste
    final pathPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.02)
          : Colors.black.withOpacity(0.02);
    
    final path = Path();
    path.moveTo(size.width * 0.47, 0);
    path.lineTo(size.width * 0.53, 0);
    path.lineTo(size.width * 0.53, size.height);
    path.lineTo(size.width * 0.47, size.height);
    path.close();
    canvas.drawPath(path, pathPaint);
    
    // Lignes de séparation du chemin
    final pathLinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..strokeCap = StrokeCap.round
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.05)
          : Colors.black.withOpacity(0.05);
    
    // Pointillés sur le chemin
    for (double y = 10; y < size.height; y += 20) {
      canvas.drawLine(
        Offset(size.width * 0.5, y),
        Offset(size.width * 0.5, y + 10),
        pathLinePaint,
      );
    }
    
    // Points d'intérêt - bâtiments/équipements (très subtils)
    final poiPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.08)
          : const Color(0xFF6B8E23).withOpacity(0.2);
    
    final poiBorderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.1)
          : const Color(0xFF6B8E23).withOpacity(0.3);
    
    // Bâtiment 1 - Grange
    final building1 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.15, size.height * 0.2, 20, 15),
      const Radius.circular(1),
    );
    canvas.drawRRect(building1, poiPaint);
    canvas.drawRRect(building1, poiBorderPaint);
    
    // Bâtiment 2 - Serre
    final building2 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.7, size.height * 0.25, 15, 10),
      const Radius.circular(1),
    );
    canvas.drawRRect(building2, poiPaint);
    canvas.drawRRect(building2, poiBorderPaint);
    
    // Bâtiment 3 - Hangar
    final building3 = RRect.fromRectAndRadius(
      Rect.fromLTWH(size.width * 0.2, size.height * 0.7, 18, 12),
      const Radius.circular(1),
    );
    canvas.drawRRect(building3, poiPaint);
    canvas.drawRRect(building3, poiBorderPaint);
    
    // Arbres/végétation - points organiques
    final treePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDarkMode
          ? const Color(0xFF1A2A1A).withOpacity(0.4)
          : const Color(0xFF6B8E23).withOpacity(0.15);
    
    // Bosquet 1
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.5), 3, treePaint);
    canvas.drawCircle(Offset(size.width * 0.12, size.height * 0.52), 2.5, treePaint);
    canvas.drawCircle(Offset(size.width * 0.08, size.height * 0.52), 2, treePaint);
    
    // Bosquet 2
    canvas.drawCircle(Offset(size.width * 0.88, size.height * 0.45), 3, treePaint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.47), 2.5, treePaint);
    
    // Lignes de contour subtiles pour donner du relief
    final contourPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.01)
          : Colors.black.withOpacity(0.01);
    
    // Quelques lignes de niveau
    final contourPath1 = Path();
    contourPath1.moveTo(0, size.height * 0.3);
    contourPath1.quadraticBezierTo(
      size.width * 0.3, size.height * 0.28,
      size.width * 0.6, size.height * 0.32,
    );
    contourPath1.quadraticBezierTo(
      size.width * 0.8, size.height * 0.34,
      size.width, size.height * 0.31,
    );
    canvas.drawPath(contourPath1, contourPaint);
    
    final contourPath2 = Path();
    contourPath2.moveTo(0, size.height * 0.7);
    contourPath2.quadraticBezierTo(
      size.width * 0.4, size.height * 0.68,
      size.width * 0.7, size.height * 0.72,
    );
    contourPath2.quadraticBezierTo(
      size.width * 0.85, size.height * 0.74,
      size.width, size.height * 0.71,
    );
    canvas.drawPath(contourPath2, contourPaint);
  }
  
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Painter pour vue aérienne avancée avec effet satellite
class AerialFarmPainter extends CustomPainter {
  final bool isDarkMode;
  final double animationValue;
  
  AerialFarmPainter({
    required this.isDarkMode,
    this.animationValue = 0.0,
  });
  
  @override
  void paint(Canvas canvas, Size size) {
    // Fond - vue satellite
    final gradient = RadialGradient(
      center: Alignment.center,
      radius: 1.2,
      colors: isDarkMode 
          ? [
              const Color(0xFF0D1A0D),
              const Color(0xFF0A0A0A),
            ]
          : [
              const Color(0xFFEEF5EE),
              const Color(0xFFF8F8F8),
            ],
    );
    
    final bgPaint = Paint()
      ..shader = gradient.createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);
    
    // Grille de coordonnées GPS ultra fine
    final gpsPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.3
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.015)
          : Colors.black.withOpacity(0.015);
    
    for (int i = 0; i <= 20; i++) {
      final y = (size.height / 20) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gpsPaint);
      
      final x = (size.width / 20) * i;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gpsPaint);
    }
    
    // Parcelles avec différentes cultures
    _drawCropField(
      canvas, 
      size, 
      Rect.fromLTWH(size.width * 0.05, size.height * 0.1, size.width * 0.42, size.height * 0.38),
      const Color(0xFF8DB600), // Blé - vert-jaune
      isDarkMode,
      density: 20,
    );
    
    _drawCropField(
      canvas,
      size,
      Rect.fromLTWH(size.width * 0.53, size.height * 0.12, size.width * 0.42, size.height * 0.28),
      const Color(0xFF6B8E23), // Maïs - vert olive
      isDarkMode,
      density: 15,
    );
    
    _drawCropField(
      canvas,
      size,
      Rect.fromLTWH(size.width * 0.05, size.height * 0.54, size.width * 0.38, size.height * 0.4),
      const Color(0xFF9ACD32), // Légumes - vert clair
      isDarkMode,
      density: 25,
    );
    
    _drawCropField(
      canvas,
      size,
      Rect.fromLTWH(size.width * 0.53, size.height * 0.46, size.width * 0.42, size.height * 0.48),
      const Color(0xFF556B2F), // Soja - vert foncé
      isDarkMode,
      density: 18,
    );
  }
  
  void _drawCropField(
    Canvas canvas,
    Size size,
    Rect bounds,
    Color cropColor,
    bool isDarkMode,
    {int density = 20}
  ) {
    // Fond de la parcelle
    final fieldPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = isDarkMode
          ? cropColor.withOpacity(0.15)
          : cropColor.withOpacity(0.25);
    
    final rrect = RRect.fromRectAndRadius(bounds, const Radius.circular(2));
    canvas.drawRRect(rrect, fieldPaint);
    
    // Bordure
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8
      ..color = isDarkMode
          ? Colors.white.withOpacity(0.08)
          : cropColor.withOpacity(0.3);
    
    canvas.drawRRect(rrect, borderPaint);
    
    // Lignes de culture
    final rowPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.4
      ..color = isDarkMode
          ? cropColor.withOpacity(0.1)
          : cropColor.withOpacity(0.2);
    
    for (int i = 0; i < density; i++) {
      final y = bounds.top + (bounds.height / density) * i;
      canvas.drawLine(
        Offset(bounds.left, y),
        Offset(bounds.right, y),
        rowPaint,
      );
    }
  }
  
  @override
  bool shouldRepaint(AerialFarmPainter oldDelegate) => 
      animationValue != oldDelegate.animationValue;
}
