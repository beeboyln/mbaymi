import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:mbaymi/models/user_model.dart';
import 'package:mbaymi/models/veterinarian_model.dart';
import 'package:mbaymi/models/farm_model.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/veterinarian_profile_detail_screen.dart';
import 'package:mbaymi/screens/farm_detail_screen.dart';
import 'package:mbaymi/screens/profile_detail_screen.dart';

class SearchUsersScreen extends StatefulWidget {
  final bool isDarkMode;

  const SearchUsersScreen({
    super.key,
    this.isDarkMode = false,
  });

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  
  List<dynamic> searchResults = [];
  bool isLoading = false;
  String selectedFilter = 'all';
  String selectedRegion = '';
  String errorMessage = '';
  bool isSearching = false; // true si on est en mode recherche, false si recommandations
  Map<String, List<dynamic>> recommendations = {};

  @override
  void initState() {
    super.initState();
    _loadRecommendations();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> _loadRecommendations() async {
    setState(() {
      isLoading = true;
      errorMessage = '';
    });

    try {
      final uri = Uri.parse('${ApiService.baseUrl}/search/recommended');
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Délai d\'attente dépassé. Vérifie ta connexion.');
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          setState(() {
            recommendations = {
              'farmers': (data['farmers'] as List?)?.map((e) => e as dynamic).toList() ?? [],
              'livestock_breeders': (data['livestock_breeders'] as List?)?.map((e) => e as dynamic).toList() ?? [],
              'veterinarians': (data['veterinarians'] as List?)?.map((e) => e as dynamic).toList() ?? [],
              'farms': (data['farms'] as List?)?.map((e) => e as dynamic).toList() ?? [],
            };
            errorMessage = '';
          });
        } catch (e) {
          throw Exception('Erreur lors du traitement des recommandations: $e');
        }
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Recommendations error: $e');
      setState(() {
        recommendations = {};
        errorMessage = '';
      });
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
        errorMessage = '';
        isSearching = false;
      });
      return;
    }

    setState(() {
      isLoading = true;
      errorMessage = '';
      isSearching = true;
    });

    try {
      final params = {
        'q': query,
        'type': selectedFilter != 'all' ? selectedFilter : null,
        if (selectedRegion.isNotEmpty) 'region': selectedRegion,
      };

      params.removeWhere((key, value) => value == null);

      final uri = Uri.parse('${ApiService.baseUrl}/search/users').replace(queryParameters: params);
      
      final response = await http.get(uri).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Délai d\'attente dépassé. Vérifie ta connexion.');
        },
      );

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          if (data is Map && data.containsKey('results')) {
            setState(() {
              searchResults = data['results'] ?? [];
              errorMessage = '';
            });
          } else {
            throw Exception('Format de réponse invalide');
          }
        } catch (e) {
          throw Exception('Erreur lors du traitement des résultats: $e');
        }
      } else if (response.statusCode == 400) {
        setState(() {
          errorMessage = 'Requête invalide. Vérifie tes paramètres.';
        });
      } else if (response.statusCode == 500) {
        setState(() {
          errorMessage = 'Erreur serveur. Réessaye plus tard.';
        });
      } else {
        throw Exception('Erreur HTTP ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Search error: $e');
      setState(() {
        searchResults = [];
        errorMessage = 'Erreur: ${e.toString()}';
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}', style: const TextStyle(letterSpacing: 0.5)),
            backgroundColor: const Color(0xFFD32F2F),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? const Color(0xFF000000) : const Color(0xFFFFFBF5);
    final textColor = isDark ? const Color(0xFFF5F5F5) : const Color(0xFF1A1A1A);
    final subtleColor = isDark ? const Color(0xFF6B6B6B) : const Color(0xFF757575);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: Text(
          'RECHERCHER',
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 2.5,
          ),
        ),
        centerTitle: true,
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, size: 18, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 0.5,
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          ),
        ),
      ),
      body: Column(
        children: [
          // Section de recherche et filtres
          Container(
            color: bgColor,
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Barre de recherche principale
                _buildSearchField(isDark, textColor, subtleColor),
                
                const SizedBox(height: 20),
                
                // Filtres de type
                _buildTypeFilters(isDark, textColor, subtleColor),
                
                const SizedBox(height: 20),
                
                // Filtre par région
                _buildRegionField(isDark, textColor, subtleColor),
              ],
            ),
          ),
          
          // Divider
          Container(
            height: 1,
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
          ),
          
          // Résultats
          Expanded(
            child: _buildResultsSection(isDark, textColor, subtleColor),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchField(bool isDark, Color textColor, Color subtleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RECHERCHE',
          style: TextStyle(
            color: subtleColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          onChanged: searchUsers,
          autocorrect: false,
          enableSuggestions: false,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
          decoration: InputDecoration(
            hintText: 'Nom, ferme, région...',
            hintStyle: TextStyle(
              color: subtleColor.withOpacity(0.5),
              letterSpacing: 0.3,
            ),
            prefixIcon: Icon(
              Icons.search,
              color: subtleColor,
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF757575) : const Color(0xFF1A1A1A),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTypeFilters(bool isDark, Color textColor, Color subtleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'CATÉGORIE',
          style: TextStyle(
            color: subtleColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildFilterButton('TOUS', 'all', isDark, textColor),
              const SizedBox(width: 12),
              _buildFilterButton('AGRICULTEURS', 'farmer', isDark, textColor),
              const SizedBox(width: 12),
              _buildFilterButton('ÉLEVEURS', 'livestock_breeder', isDark, textColor),
              const SizedBox(width: 12),
              _buildFilterButton('VÉTÉRINAIRES', 'veterinarian', isDark, textColor),
              const SizedBox(width: 12),
              _buildFilterButton('FERMES', 'farm', isDark, textColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFilterButton(String label, String value, bool isDark, Color textColor) {
    final isSelected = selectedFilter == value;
    
    return InkWell(
      onTap: () {
        setState(() {
          selectedFilter = value;
        });
        if (_searchController.text.isNotEmpty) {
          searchUsers(_searchController.text);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(
            color: isSelected
                ? (isDark ? const Color(0xFF757575) : const Color(0xFF1A1A1A))
                : (isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0)),
            width: isSelected ? 1.5 : 1,
          ),
          color: isSelected
              ? (isDark ? const Color(0xFF1A1A1A) : const Color(0xFFF5F5F5))
              : Colors.transparent,
        ),
        child: Text(
          label,
          style: TextStyle(
            color: textColor,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
            letterSpacing: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildRegionField(bool isDark, Color textColor, Color subtleColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'RÉGION',
          style: TextStyle(
            color: subtleColor,
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _regionController,
          onChanged: (value) {
            setState(() {
              selectedRegion = value;
            });
            if (_searchController.text.isNotEmpty) {
              searchUsers(_searchController.text);
            }
          },
          autocorrect: false,
          enableSuggestions: false,
          style: TextStyle(
            color: textColor,
            fontSize: 15,
            fontWeight: FontWeight.w400,
            letterSpacing: 0.3,
          ),
          decoration: InputDecoration(
            hintText: 'Filtrer par région...',
            hintStyle: TextStyle(
              color: subtleColor.withOpacity(0.5),
              letterSpacing: 0.3,
            ),
            prefixIcon: Icon(
              Icons.location_on_outlined,
              color: subtleColor,
              size: 20,
            ),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
                width: 1,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: isDark ? const Color(0xFF757575) : const Color(0xFF1A1A1A),
                width: 1.5,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResultsSection(bool isDark, Color textColor, Color subtleColor) {
    if (isLoading) {
      return Center(
        child: SizedBox(
          height: 24,
          width: 24,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
      );
    }

    if (errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: const Color(0xFFD32F2F),
            ),
            const SizedBox(height: 20),
            Text(
              'ERREUR',
              style: TextStyle(
                color: subtleColor,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Text(
                errorMessage,
                style: TextStyle(
                  color: subtleColor.withOpacity(0.7),
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      );
    }

    // Mode recherche - afficher les résultats de recherche
    if (isSearching) {
      if (searchResults.isEmpty && _searchController.text.isNotEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.search_off,
                size: 48,
                color: subtleColor.withOpacity(0.5),
              ),
              const SizedBox(height: 20),
              Text(
                'AUCUN RÉSULTAT',
                style: TextStyle(
                  color: subtleColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Essayez d\'autres mots-clés ou un filtre différent',
                style: TextStyle(
                  color: subtleColor.withOpacity(0.7),
                  fontSize: 13,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
        );
      }

      return ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        itemCount: searchResults.length,
        itemBuilder: (context, index) {
          final result = searchResults[index];
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: _buildResultCard(result, isDark, textColor, subtleColor),
          );
        },
      );
    }

    // Mode recommandations - afficher par catégorie
    if (recommendations.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.people_outline,
              size: 48,
              color: subtleColor.withOpacity(0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'CHARGEMENT',
              style: TextStyle(
                color: subtleColor,
                fontSize: 12,
                fontWeight: FontWeight.w400,
                letterSpacing: 2,
              ),
            ),
          ],
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      children: [
        // Vétérinaires
        if (recommendations['veterinarians']!.isNotEmpty) ...[
          _buildSectionTitle('VÉTÉRINAIRES', subtleColor),
          ...(recommendations['veterinarians'] as List).map((result) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildResultCard(result, isDark, textColor, subtleColor),
            )
          ).toList(),
          const SizedBox(height: 24),
        ],
        
        // Agriculteurs
        if (recommendations['farmers']!.isNotEmpty) ...[
          _buildSectionTitle('AGRICULTEURS', subtleColor),
          ...(recommendations['farmers'] as List).map((result) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildResultCard(result, isDark, textColor, subtleColor),
            )
          ).toList(),
          const SizedBox(height: 24),
        ],
        
        // Éleveurs
        if (recommendations['livestock_breeders']!.isNotEmpty) ...[
          _buildSectionTitle('ÉLEVEURS', subtleColor),
          ...(recommendations['livestock_breeders'] as List).map((result) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildResultCard(result, isDark, textColor, subtleColor),
            )
          ).toList(),
          const SizedBox(height: 24),
        ],
        
        // Fermes
        if (recommendations['farms']!.isNotEmpty) ...[
          _buildSectionTitle('FERMES', subtleColor),
          ...(recommendations['farms'] as List).map((result) =>
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: _buildResultCard(result, isDark, textColor, subtleColor),
            )
          ).toList(),
        ],
      ],
    );
  }

  Widget _buildSectionTitle(String title, Color subtleColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              color: subtleColor,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  Widget _buildResultCard(dynamic result, bool isDark, Color textColor, Color subtleColor) {
    try {
      final type = result['type'] as String;

      if (type == 'veterinarian') {
        return _buildVeterinarianCard(result, isDark, textColor, subtleColor);
      } else if (type == 'farmer') {
        return _buildFarmerCard(result, true, isDark, textColor, subtleColor);
      } else if (type == 'livestock_breeder') {
        return _buildFarmerCard(result, false, isDark, textColor, subtleColor);
      } else if (type == 'farm') {
        return _buildFarmCard(result, isDark, textColor, subtleColor);
      }
      return const SizedBox.shrink();
    } catch (e) {
      debugPrint('Error building result card: $e');
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Text(
          'Erreur lors de l\'affichage du résultat',
          style: TextStyle(
            color: subtleColor,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
      );
    }
  }

  Widget _buildProfileImage(String? imageUrl, IconData fallbackIcon, bool isDark, Color subtleColor) {
    // Check if URL is valid and not empty
    final isValidUrl = imageUrl != null && 
                       imageUrl.toString().isNotEmpty && 
                       imageUrl.toString().startsWith('http');

    if (isValidUrl) {
      return Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          debugPrint('Error loading image: $error');
          return Icon(fallbackIcon, color: subtleColor, size: 24);
        },
      );
    }

    return Icon(fallbackIcon, color: subtleColor, size: 24);
  }

  Widget _buildVeterinarianCard(dynamic result, bool isDark, Color textColor, Color subtleColor) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => VeterinarianProfileDetailScreen(
              veterinarianId: result['id'].toString(),
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              child: _buildProfileImage(
                result['profile_image'],
                Icons.medical_services_outlined,
                isDark,
                subtleColor,
              ),
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (result['name'] ?? 'VÉTÉRINAIRE').toUpperCase(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result['specialty'] ?? 'Spécialité non spécifiée',
                    style: TextStyle(
                      color: subtleColor,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Text(
                        '${result['experience_years'] ?? 0} ans',
                        style: TextStyle(
                          color: subtleColor,
                          fontSize: 11,
                          letterSpacing: 0.3,
                        ),
                      ),
                      if (result['rating'] != null) ...[
                        const SizedBox(width: 12),
                        Icon(Icons.star_border, size: 14, color: subtleColor),
                        const SizedBox(width: 4),
                        Text(
                          '${result['rating']}',
                          style: TextStyle(
                            color: subtleColor,
                            fontSize: 11,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            
            Icon(Icons.arrow_forward_ios, size: 14, color: subtleColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmerCard(dynamic result, bool isFarmer, bool isDark, Color textColor, Color subtleColor) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProfileDetailScreen(
              userId: result['id'] is int ? result['id'] : int.parse(result['id'].toString()),
              isDarkMode: false,
            ),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                border: Border.all(
                  color: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
                  width: 1,
                ),
              ),
              child: _buildProfileImage(
                result['profile_image'],
                Icons.person_outline,
                isDark,
                subtleColor,
              ),
            ),
            const SizedBox(width: 16),
            
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (result['name'] ?? (isFarmer ? 'AGRICULTEUR' : 'ÉLEVEUR')).toUpperCase(),
                    style: TextStyle(
                      color: textColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    result['role'] ?? (isFarmer ? 'Agriculteur' : 'Éleveur'),
                    style: TextStyle(
                      color: subtleColor,
                      fontSize: 12,
                      letterSpacing: 0.3,
                    ),
                  ),
                  if (result['region'] != null) ...[
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 12, color: subtleColor),
                        const SizedBox(width: 4),
                        Text(
                          result['region'],
                          style: TextStyle(
                            color: subtleColor,
                            fontSize: 11,
                            letterSpacing: 0.3,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            
            Icon(Icons.arrow_forward_ios, size: 14, color: subtleColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmCard(dynamic result, bool isDark, Color textColor, Color subtleColor) {
    try {
      // Validate farm data
      final farmId = result['id'];
      if (farmId == null) {
        throw Exception('Farm ID is missing');
      }

      final farmIdInt = farmId is int ? farmId : int.tryParse(farmId.toString());
      if (farmIdInt == null) {
        throw Exception('Invalid farm ID format');
      }

      return InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FarmDetailScreen(
                farmId: farmIdInt,
                farmData: result,
              ),
            ),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            border: Border.all(
              color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: isDark ? const Color(0xFF404040) : const Color(0xFFE0E0E0),
                    width: 1,
                  ),
                ),
                child: Icon(Icons.agriculture_outlined, color: subtleColor, size: 24),
              ),
              const SizedBox(width: 16),
              
              // Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      (result['name'] ?? 'FERME').toUpperCase(),
                      style: TextStyle(
                        color: textColor,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 1.5,
                      ),
                    ),
                    if (result['owner_name'] != null && result['owner_name'].toString().isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Propriétaire: ${result['owner_name']}',
                        style: TextStyle(
                          color: subtleColor,
                          fontSize: 12,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                    if (result['location'] != null && result['location'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: subtleColor),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              result['location'],
                              style: TextStyle(
                                color: subtleColor,
                                fontSize: 11,
                                letterSpacing: 0.3,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ] else if (result['region'] != null && result['region'].toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.location_on_outlined, size: 12, color: subtleColor),
                          const SizedBox(width: 4),
                          Text(
                            result['region'],
                            style: TextStyle(
                              color: subtleColor,
                              fontSize: 11,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
              
              Icon(Icons.arrow_forward_ios, size: 14, color: subtleColor),
            ],
          ),
        ),
      );
    } catch (e) {
      debugPrint('Error building farm card: $e');
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          border: Border.all(
            color: isDark ? const Color(0xFF2A2A2A) : const Color(0xFFE0E0E0),
            width: 1,
          ),
        ),
        child: Text(
          'Erreur lors de l\'affichage de la ferme',
          style: TextStyle(
            color: subtleColor,
            fontSize: 12,
            letterSpacing: 0.3,
          ),
        ),
      );
    }
  }
}