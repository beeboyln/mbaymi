import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/widgets/skeleton_loader.dart';

class SelectCropScreen extends StatefulWidget {
  final int farmId;
  final int userId;
  final bool isDarkMode;

  const SelectCropScreen({
    super.key,
    required this.farmId,
    required this.userId,
    this.isDarkMode = false,
  });

  @override
  State<SelectCropScreen> createState() => _SelectCropScreenState();
}

class _SelectCropScreenState extends State<SelectCropScreen> {
  late Future<List<dynamic>> _cropsFuture;

  @override
  void initState() {
    super.initState();
    _cropsFuture = ApiService.getFarmCrops(widget.farmId);
  }

  DecorationImage? _getImageDecoration(dynamic crop) {
    // Essayer d'obtenir l'image depuis différentes sources
    final imageUrl = crop['image_url'] ?? 
                     crop['imageUrl'] ?? 
                     (crop['photos'] is List && (crop['photos'] as List).isNotEmpty 
                         ? (crop['photos'] as List).first 
                         : null);
    
    if (imageUrl != null && imageUrl.toString().isNotEmpty) {
      return DecorationImage(
        image: NetworkImage(imageUrl.toString()),
        fit: BoxFit.cover,
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : AppColors.lightBg,
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : AppColors.lightBg,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Sélectionner une culture',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
        ),
      ),
      body: FutureBuilder<List<dynamic>>(
        future: _cropsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SkeletonListLoader(
              isDarkMode: widget.isDarkMode,
              itemCount: 5,
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                  const SizedBox(height: 16),
                  Text(
                    'Erreur de chargement',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black,
                    ),
                  ),
                ],
              ),
            );
          }

          final crops = snapshot.data ?? [];

          if (crops.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.agriculture, size: 48, color: Color(0xFF6B8E23)),
                  const SizedBox(height: 16),
                  Text(
                    'Aucune culture trouvée',
                    style: TextStyle(
                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: crops.length,
            itemBuilder: (context, index) {
              final crop = crops[index];
              final cropName = crop['crop_name'] ?? crop['name'] ?? 'Culture sans nom';
              final cropId = crop['id'] as int;

              return GestureDetector(
                onTap: () {
                  Navigator.pop(context, {'cropId': cropId, 'cropName': cropName});
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: widget.isDarkMode
                          ? Colors.white.withOpacity(0.08)
                          : Colors.black.withOpacity(0.04),
                    ),
                  ),
                  child: Row(
                    children: [
                      // Photo de profil de la parcelle
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          color: widget.isDarkMode ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
                          image: _getImageDecoration(crop),
                        ),
                        child: _getImageDecoration(crop) == null
                            ? const Icon(
                                Icons.agriculture,
                                color: Color(0xFF6B8E23),
                                size: 24,
                              )
                            : null,
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              cropName.toString(),
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w500,
                                color: widget.isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (crop['status'] != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  crop['status'],
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        size: 16,
                        color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
