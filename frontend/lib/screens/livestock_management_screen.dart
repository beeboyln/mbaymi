import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/create_livestock_screen.dart';
import 'package:mbaymi/screens/edit_livestock_screen.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/utils/app_spacing.dart';
import 'package:mbaymi/utils/app_typography.dart';
import 'package:mbaymi/utils/app_radius.dart';
import 'package:mbaymi/utils/app_shadows.dart';

class LivestockManagementScreen extends StatefulWidget {
  final int userId;
  final bool isDarkMode;

  const LivestockManagementScreen({
    super.key,
    required this.userId,
    required this.isDarkMode,
  });

  @override
  State<LivestockManagementScreen> createState() => _LivestockManagementScreenState();
}

class _LivestockManagementScreenState extends State<LivestockManagementScreen> {
  late Future<List<dynamic>> _livestockFuture;
  String _selectedFilter = 'Tous'; // Filtre sélectionné

  @override
  void initState() {
    super.initState();
    _livestockFuture = ApiService.getUserLivestock(widget.userId);
  }

  Future<void> _refresh() async {
    setState(() {
      _livestockFuture = ApiService.getUserLivestock(widget.userId);
    });
  }

  // Grouper les animaux par type
  // ignore: unused_element
  Map<String, List<dynamic>> _groupLivestockByType(List<dynamic> livestock) {
    final grouped = <String, List<dynamic>>{};
    for (final animal in livestock) {
      final type = animal['animal_type'] ?? 'Autre';
      grouped.putIfAbsent(type, () => []).add(animal);
    }
    return grouped;
  }

  // Obtenir les types uniques pour filtrage
  Set<String> _getAnimalTypes(List<dynamic> livestock) {
    return livestock.map((animal) => (animal['animal_type'] ?? 'Autre') as String).toSet();
  }

  // Filtrer les animaux
  List<dynamic> _filterLivestock(List<dynamic> livestock) {
    if (_selectedFilter == 'Tous') return livestock;
    return livestock.where((animal) => animal['animal_type'] == _selectedFilter).toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = AppColors.getBgColor(isDark);
    final cardColor = AppColors.getCardBgColor(isDark);
    final textColor = AppColors.getTextColor(isDark);
    final secondaryTextColor = AppColors.getTextColor(isDark).withOpacity(0.7);
    final borderColor = AppColors.getBorderColor(isDark);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('Mes Animaux', style: TextStyle(fontWeight: FontWeight.w300)),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _livestockFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Text(
                    'Erreur: ${snapshot.error}',
                    style: TextStyle(color: textColor),
                    textAlign: TextAlign.center,
                  ),
                ),
              );
            }

            final livestock = snapshot.data ?? [];

            if (livestock.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.pets_outlined, size: 64, color: secondaryTextColor),
                    SizedBox(height: AppSpacing.md),
                    Text(
                      'Aucun animal',
                      style: AppTypography.h3.copyWith(color: textColor),
                    ),
                    SizedBox(height: AppSpacing.sm),
                    Text(
                      'Ajoutez vos premiers animaux',
                      style: AppTypography.body.copyWith(color: secondaryTextColor),
                    ),
                  ],
                ),
              );
            }

            // Statistiques
            final totalAnimals = livestock.fold(0, (sum, animal) => sum + (animal['quantity'] ?? 1) as int);
            final animalTypes = _getAnimalTypes(livestock);
            final filteredLivestock = _filterLivestock(livestock);

            return Column(
              children: [
                // 📊 STATISTIQUES RAPIDES
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      Expanded(
                        child: _buildStatCard(
                          value: livestock.length.toString(),
                          label: 'Espèces',
                          icon: Icons.category_outlined,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textColor: textColor,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatCard(
                          value: totalAnimals.toString(),
                          label: 'Total',
                          icon: Icons.pets_outlined,
                          cardColor: cardColor,
                          borderColor: borderColor,
                          textColor: textColor,
                        ),
                      ),
                    ],
                  ),
                ),

                // 🔍 FILTRES PAR TYPE
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Tous',
                        isSelected: _selectedFilter == 'Tous',
                        onTap: () => setState(() => _selectedFilter = 'Tous'),
                        textColor: textColor,
                        cardColor: cardColor,
                      ),
                      SizedBox(width: AppSpacing.sm),
                      ...animalTypes.map((type) => Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.sm),
                        child: _buildFilterChip(
                          label: type,
                          isSelected: _selectedFilter == type,
                          onTap: () => setState(() => _selectedFilter = type),
                          textColor: textColor,
                          cardColor: cardColor,
                        ),
                      )),
                    ],
                  ),
                ),
                SizedBox(height: AppSpacing.md),

                // 📋 LISTE DES ANIMAUX FILTRÉS
                Expanded(
                  child: filteredLivestock.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_outlined, size: 48, color: secondaryTextColor),
                              SizedBox(height: AppSpacing.sm),
                              Text(
                                'Aucun animal de ce type',
                                style: AppTypography.body.copyWith(color: secondaryTextColor),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                          itemCount: filteredLivestock.length,
                          itemBuilder: (context, index) {
                            final animal = filteredLivestock[index] as Map<String, dynamic>;
                            return _buildLivestockCard(
                              animal,
                              cardColor,
                              textColor,
                              secondaryTextColor,
                              borderColor,
                            );
                          },
                        ),
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          HapticFeedback.mediumImpact();
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => CreateLivestockScreen(userId: widget.userId),
            ),
          );
          if (result != null) {
            _refresh();
          }
        },
        backgroundColor: AppColors.primary,
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }

  Widget _buildLivestockCard(
    Map<String, dynamic> animal,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    final livestockId = animal['id'] as int?;
    final animalType = animal['animal_type'] ?? 'Animal';
    final breed = animal['breed'] ?? 'Variété inconnue';
    final quantity = animal['quantity'] ?? 1;
    final healthStatus = animal['health_status'] ?? 'Non spécifié';
    final ageMonths = animal['age_months'];
    final weightKg = animal['weight_kg'];
    final imageUrl = animal['image_url'] as String?;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: GestureDetector(
        onTap: livestockId != null
            ? () async {
                HapticFeedback.mediumImpact();
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => EditLivestockScreen(
                      livestockId: livestockId,
                      livestock: animal,
                    ),
                  ),
                );
                if (result != null) {
                  _refresh();
                }
              }
            : null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.all(Radius.circular(AppRadius.md)),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              // Image avec badge photos
              Stack(
                children: [
                  Container(
                    width: 100,
                    height: 140,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.md),
                        bottomLeft: Radius.circular(AppRadius.md),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(AppRadius.md),
                        bottomLeft: Radius.circular(AppRadius.md),
                      ),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: AppColors.primaryLight.withOpacity(0.1),
                                child: Icon(Icons.pets_outlined, color: AppColors.primaryLight),
                              ),
                            )
                          : Container(
                              color: AppColors.primaryLight.withOpacity(0.1),
                              child: Icon(Icons.pets_outlined, color: AppColors.primaryLight),
                            ),
                    ),
                  ),
                  if (livestockId != null)
                    Positioned(
                      bottom: 4,
                      left: 4,
                      child: FutureBuilder<List<Map<String, dynamic>>>(
                        future: ApiService.getAnimalPhotos(livestockId),
                        builder: (context, snapshot) {
                          final photoCount = snapshot.data?.length ?? 0;
                          if (photoCount > 0) {
                            return Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              child: Text(
                                '$photoCount📷',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            );
                          }
                          return const SizedBox.shrink();
                        },
                      ),
                    ),
                ],
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Titre et quantité
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  animalType,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: textColor,
                                  ),
                                ),
                                if (breed.isNotEmpty) ...[
                                  const SizedBox(height: 2),
                                  Text(
                                    breed,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: secondaryTextColor,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.accent.withOpacity(0.1),
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              'x$quantity',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.accent,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // Infos santé, âge, poids
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          // Santé
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _getHealthColor(healthStatus).withOpacity(0.1),
                              borderRadius: const BorderRadius.all(Radius.circular(6)),
                            ),
                            child: Text(
                              healthStatus,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: _getHealthColor(healthStatus),
                              ),
                            ),
                          ),
                          if (ageMonths != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: const BorderRadius.all(Radius.circular(6)),
                              ),
                              child: Text(
                                '$ageMonths m',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: secondaryTextColor,
                                ),
                              ),
                            ),
                          if (weightKg != null)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.grey.withOpacity(0.1),
                                borderRadius: const BorderRadius.all(Radius.circular(6)),
                              ),
                              child: Text(
                                '${weightKg}kg',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: secondaryTextColor,
                                ),
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
      ),
    );
  }

  Color _getHealthColor(String status) {
    switch (status.toLowerCase()) {
      case 'sain':
      case 'healthy':
        return Colors.green;
      case 'malade':
      case 'sick':
        return Colors.red;
      case 'vacciné':
      case 'vaccinated':
        return Colors.blue;
      default:
        return Colors.orange;
    }
  }

  // 📊 Carte de statistiques
  Widget _buildStatCard({
    required String value,
    required String label,
    required IconData icon,
    required Color cardColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: borderColor, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Icon(icon, color: AppColors.primary, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }

  // 🔍 Chip de filtrage
  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required Color textColor,
    required Color cardColor,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : cardColor,
          border: Border.all(
            color: isSelected ? AppColors.primary : const Color(0xFFE8E2D8),
            width: 1.5,
          ),
          borderRadius: const BorderRadius.all(Radius.circular(20)),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : textColor,
          ),
        ),
      ),
    );
  }
}
