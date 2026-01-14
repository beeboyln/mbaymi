import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/create_livestock_screen.dart';
import 'package:mbaymi/screens/edit_livestock_screen.dart';

class LivestockManagementScreen extends StatefulWidget {
  final int userId;
  final bool isDarkMode;

  const LivestockManagementScreen({
    Key? key,
    required this.userId,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<LivestockManagementScreen> createState() => _LivestockManagementScreenState();
}

class _LivestockManagementScreenState extends State<LivestockManagementScreen> {
  late Future<List<dynamic>> _livestockFuture;
  String _selectedFilter = 'Tous'; // Filtre sélectionné

  static const Color _primaryColor = Color(0xFF8B6B4D);
  static const Color _accentColor = Color(0xFFC4A484);
  static const Color _bgLight = Color(0xFFFAF8F5);
  static const Color _bgDark = Color(0xFF121212);
  static const Color _cardLight = Colors.white;
  static const Color _cardDark = Color(0xFF1E1E1E);
  static const Color _borderLight = Color(0xFFE8E2D8);
  static const Color _borderDark = Color(0xFF2C2C2C);
  static const Color _textLight = Color(0xFF1A1A1A);
  static const Color _textDark = Colors.white;
  static const Color _textSecondaryLight = Color(0xFF6B6B6B);
  static const Color _textSecondaryDark = Color(0xFF8E8E93);

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
    final bgColor = isDark ? _bgDark : _bgLight;
    final cardColor = isDark ? _cardDark : _cardLight;
    final textColor = isDark ? _textDark : _textLight;
    final secondaryTextColor = isDark ? _textSecondaryDark : _textSecondaryLight;
    final borderColor = isDark ? _borderDark : _borderLight;

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
        color: _primaryColor,
        onRefresh: _refresh,
        child: FutureBuilder<List<dynamic>>(
          future: _livestockFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: CircularProgressIndicator(color: _primaryColor),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
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
                    const SizedBox(height: 16),
                    Text(
                      'Aucun animal',
                      style: TextStyle(fontSize: 18, color: textColor),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Ajoutez vos premiers animaux',
                      style: TextStyle(color: secondaryTextColor),
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
                  padding: const EdgeInsets.all(16),
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
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      _buildFilterChip(
                        label: 'Tous',
                        isSelected: _selectedFilter == 'Tous',
                        onTap: () => setState(() => _selectedFilter = 'Tous'),
                        textColor: textColor,
                        cardColor: cardColor,
                      ),
                      const SizedBox(width: 8),
                      ...animalTypes.map((type) => Padding(
                        padding: const EdgeInsets.only(right: 8),
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
                const SizedBox(height: 16),

                // 📋 LISTE DES ANIMAUX FILTRÉS
                Expanded(
                  child: filteredLivestock.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.search_off_outlined, size: 48, color: secondaryTextColor),
                              const SizedBox(height: 12),
                              Text(
                                'Aucun animal de ce type',
                                style: TextStyle(color: secondaryTextColor),
                              ),
                            ],
                          ),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
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
        backgroundColor: _primaryColor,
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
      padding: const EdgeInsets.only(bottom: 12),
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
            borderRadius: const BorderRadius.all(Radius.circular(12)),
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
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: ClipRRect(
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomLeft: Radius.circular(12),
                      ),
                      child: imageUrl != null && imageUrl.isNotEmpty
                          ? Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: _accentColor.withOpacity(0.1),
                                child: const Icon(Icons.pets_outlined, color: _accentColor),
                              ),
                            )
                          : Container(
                              color: _accentColor.withOpacity(0.1),
                              child: const Icon(Icons.pets_outlined, color: _accentColor),
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
                                '${photoCount}📷',
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
                              color: _accentColor.withOpacity(0.1),
                              borderRadius: const BorderRadius.all(Radius.circular(8)),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Text(
                              'x$quantity',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _accentColor,
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
          Icon(icon, color: _primaryColor, size: 28),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: _primaryColor,
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
          color: isSelected ? _primaryColor : cardColor,
          border: Border.all(
            color: isSelected ? _primaryColor : Color(0xFFE8E2D8),
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
