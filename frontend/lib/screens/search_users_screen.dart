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
    Key? key,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<SearchUsersScreen> createState() => _SearchUsersScreenState();
}

class _SearchUsersScreenState extends State<SearchUsersScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _regionController = TextEditingController();
  
  List<dynamic> searchResults = [];
  bool isLoading = false;
  String selectedFilter = 'all'; // all, farmer, veterinarian, farm
  String selectedRegion = '';

  @override
  void dispose() {
    _searchController.dispose();
    _regionController.dispose();
    super.dispose();
  }

  Future<void> searchUsers(String query) async {
    if (query.isEmpty) {
      setState(() {
        searchResults = [];
      });
      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      final params = {
        'q': query,
        'type': selectedFilter != 'all' ? selectedFilter : null,
        if (selectedRegion.isNotEmpty) 'region': selectedRegion,
      };

      params.removeWhere((key, value) => value == null);

      final uri = Uri.parse('${ApiService.baseUrl}/search/users').replace(queryParameters: params);
      
      final response = await http.get(uri);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          searchResults = data['results'] ?? [];
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erreur lors de la recherche')),
        );
      }
    } catch (e) {
      debugPrint('Search error: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.getBgColor(widget.isDarkMode),
      appBar: AppBar(
        title: const Text('Rechercher'),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              // Barre de recherche
              TextField(
                controller: _searchController,
                onChanged: (value) {
                  searchUsers(value);
                },
                decoration: InputDecoration(
                  hintText: 'Rechercher un agriculteur, vétérinaire...',
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.getCardBgColor(widget.isDarkMode),
                ),
              ),
              const SizedBox(height: 16),

              // Filtres
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _filterChip('Tous', 'all'),
                    const SizedBox(width: 8),
                    _filterChip('Agriculteurs', 'farmer'),
                    const SizedBox(width: 8),
                    _filterChip('Vétérinaires', 'veterinarian'),
                    const SizedBox(width: 8),
                    _filterChip('Fermes', 'farm'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Filtre par région
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
                decoration: InputDecoration(
                  hintText: 'Filtrer par région...',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.getCardBgColor(widget.isDarkMode),
                ),
              ),
              const SizedBox(height: 24),

              // Résultats
              if (isLoading)
                const Center(
                  child: CircularProgressIndicator(),
                )
              else if (searchResults.isEmpty && _searchController.text.isNotEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.search_off,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Aucun résultat trouvé',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              else if (searchResults.isEmpty)
                Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.people_outline,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Tapez pour rechercher',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                )
              else
                ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height - 300,
                  ),
                  child: ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: searchResults.length,
                    itemBuilder: (context, index) {
                      final result = searchResults[index];
                      return _buildResultCard(result);
                    },
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = selectedFilter == value;
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          selectedFilter = value;
        });
        if (_searchController.text.isNotEmpty) {
          searchUsers(_searchController.text);
        }
      },
      backgroundColor: Colors.grey[200],
      selectedColor: AppColors.primary,
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.black,
      ),
    );
  }

  Widget _buildResultCard(dynamic result) {
    final type = result['type'] as String;

    if (type == 'veterinarian') {
      return _buildVeterinarianCard(result);
    } else if (type == 'farmer') {
      return _buildFarmerCard(result);
    } else if (type == 'farm') {
      return _buildFarmCard(result);
    }
    return const SizedBox.shrink();
  }

  Widget _buildVeterinarianCard(dynamic result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.primary,
          backgroundImage: result['profile_image'] != null
              ? NetworkImage(result['profile_image'])
              : null,
          child: result['profile_image'] == null
              ? const Icon(Icons.medical_services, color: Colors.white)
              : null,
        ),
        title: Text(result['name'] ?? 'Vétérinaire'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result['specialty'] ?? 'Spécialité non spécifiée',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '${result['experience_years'] ?? 0} ans d\'expérience',
              style: const TextStyle(fontSize: 12),
            ),
            if (result['rating'] != null)
              Row(
                children: [
                  const Icon(Icons.star, size: 14, color: Colors.amber),
                  const SizedBox(width: 4),
                  Text(
                    '${result['rating']}',
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward),
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
      ),
    );
  }

  Widget _buildFarmerCard(dynamic result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppColors.success,
          backgroundImage: result['profile_image'] != null
              ? NetworkImage(result['profile_image'])
              : null,
          child: result['profile_image'] == null
              ? const Icon(Icons.person, color: Colors.white)
              : null,
        ),
        title: Text(result['name'] ?? 'Agriculteur'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              result['role'] ?? 'Agriculteur',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              result['region'] ?? 'Région non spécifiée',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward),
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
      ),
    );
  }

  Widget _buildFarmCard(dynamic result) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.green,
          child: const Icon(Icons.agriculture, color: Colors.white),
        ),
        title: Text(result['name'] ?? 'Ferme'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (result['owner_name'] != null)
              Text(
                'Propriétaire: ${result['owner_name']}',
                style: const TextStyle(fontSize: 12),
              ),
            Text(
              result['region'] ?? 'Région non spécifiée',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FarmDetailScreen(
                farmId: result['id'] is int ? result['id'] : int.parse(result['id'].toString()),
                farmData: result,
              ),
            ),
          );
        },
      ),
    );
  }
}
