import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/screens/farm_detail_screen.dart';

class FarmNetworkScreen extends StatefulWidget {
  final bool isDarkMode;

  const FarmNetworkScreen({Key? key, this.isDarkMode = false}) : super(key: key);

  @override
  State<FarmNetworkScreen> createState() => _FarmNetworkScreenState();
}

class _FarmNetworkScreenState extends State<FarmNetworkScreen> {
  late Future<List<dynamic>> _feedFuture;
  late Future<List<dynamic>> _publicFarmsFuture;
  int _userId = 0;
  final Set<int> _followedFarmIds = {};

  @override
  void initState() {
    super.initState();
    _initData();
  }

  void _initData() async {
    _userId = AuthService.currentSession?.userId ?? 0;
    _feedFuture = _userId > 0 
        ? ApiService.getFarmFeed(_userId)
        : Future.value([]);
    _publicFarmsFuture = ApiService.getPublicFarms();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '🌾 Réseau Agricole',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w400,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.search, color: widget.isDarkMode ? Colors.white : Colors.black),
            onPressed: () => _showSearchDialog(),
          ),
        ],
      ),
      body: _userId == 0
          ? _buildNotAuthenticatedView()
          : RefreshIndicator(
              onRefresh: () async {
                setState(() {
                  _feedFuture = ApiService.getFarmFeed(_userId);
                  _publicFarmsFuture = ApiService.getPublicFarms();
                });
              },
              child: FutureBuilder<List<dynamic>>(
                future: _feedFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: const Color(0xFF6B8E23)),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                          const SizedBox(height: 16),
                          Text('Erreur de chargement',
                              style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
                        ],
                      ),
                    );
                  }

                  final posts = snapshot.data ?? [];

                  if (posts.isEmpty) {
                    // Afficher les fermes publiques à découvrir
                    return FutureBuilder<List<dynamic>>(
                      future: _publicFarmsFuture,
                      builder: (context, farmSnap) {
                        final publicFarms = farmSnap.data ?? [];
                        
                        if (publicFarms.isEmpty) {
                          return Center(
                            child: SingleChildScrollView(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.grass_outlined, size: 48, color: const Color(0xFF6B8E23)),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucune publication pour le moment',
                                    style: TextStyle(
                                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Commencez à suivre des fermes',
                                    style: TextStyle(
                                      color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const SizedBox(height: 24),
                                  ElevatedButton.icon(
                                    onPressed: () => _showSearchDialog(),
                                    icon: const Icon(Icons.search),
                                    label: const Text('Découvrir des fermes'),
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xFF6B8E23),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return ListView(
                          padding: const EdgeInsets.all(12),
                          children: [
                            // En-tête "Fermes à découvrir"
                            Padding(
                              padding: const EdgeInsets.fromLTRB(0, 12, 0, 16),
                              child: Row(
                                children: [
                                  const Icon(Icons.explore_outlined, color: Color(0xFF6B8E23), size: 24),
                                  const SizedBox(width: 8),
                                  Text(
                                    '🌾 Fermes à découvrir',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                      color: widget.isDarkMode ? Colors.white : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            ...publicFarms.map((farm) => _buildPublicFarmCard(farm)).toList(),
                          ],
                        );
                      },
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: posts.length,
                    itemBuilder: (context, index) {
                      return _buildPostCard(posts[index]);
                    },
                  );
                },
              ),
            ),
    );
  }

  Widget _buildNotAuthenticatedView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.lock_outlined, size: 48, color: const Color(0xFF6B8E23)),
          const SizedBox(height: 16),
          Text(
            'Connectez-vous pour voir le réseau',
            style: TextStyle(
              color: widget.isDarkMode ? Colors.white : Colors.black87,
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pushNamed(context, '/login'),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF6B8E23),
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
            ),
            child: const Text('Se connecter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildPublicFarmCard(dynamic farm) {
    final farmName = farm['farm_name'] as String? ?? 'Ferme';
    final ownerName = farm['owner_name'] as String? ?? 'Agriculteur';
    final ownerId = farm['user_id'] as int? ?? 0;
    final location = farm['location'] as String? ?? 'Localisation inconnue';
    final description = farm['description'] as String? ?? '';
    final specialties = (farm['specialties'] as List?)?.cast<String>() ?? [];
    final followers = farm['followers'] as int? ?? 0;
    final farmId = farm['farm_id'] as int;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => FarmDetailScreen(
              farmId: farmId,
              farmData: farm,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: widget.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // En-tête
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: const Color(0xFF6B8E23).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.agriculture, color: Color(0xFF6B8E23), size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          farmName,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: widget.isDarkMode ? Colors.white : Colors.black87,
                          ),
                        ),
                        Text(
                          'par $ownerName',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Localisation
              Row(
                children: [
                  Icon(Icons.location_on_outlined, size: 14, color: const Color(0xFF6B8E23)),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      location,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Description
              if (description.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    description,
                    style: TextStyle(
                      fontSize: 13,
                      color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                      height: 1.4,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),

              // Spécialités
              if (specialties.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: specialties.take(3).map((spec) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF6B8E23).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          spec.trim(),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: Color(0xFF6B8E23),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),

              // Boutons
              Row(
                children: [
                  Icon(Icons.people_outline, size: 14, color: widget.isDarkMode ? Colors.white60 : Colors.black45),
                  const SizedBox(width: 4),
                  Text(
                    '$followers abonné${followers > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                    ),
                  ),
                  const Spacer(),
                  ElevatedButton(
                    onPressed: () async {
                      if (_userId == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Connectez-vous pour suivre des agriculteurs'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        Navigator.pushNamed(context, '/login');
                        return;
                      }
                      
                      if (ownerId == 0) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Erreur: propriétaire introuvable'),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }
                      
                      if (_userId == ownerId) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Vous ne pouvez pas vous suivre vous-même'),
                            backgroundColor: Colors.orange,
                          ),
                        );
                        return;
                      }
                      
                      try {
                        final isFollowed = _followedFarmIds.contains(ownerId);
                        if (isFollowed) {
                          // Arrêter de suivre
                          await ApiService.unfollowUser(
                            userIdToUnfollow: ownerId,
                            userId: _userId,
                          );
                          if (mounted) {
                            setState(() {
                              _followedFarmIds.remove(ownerId);
                              _feedFuture = ApiService.getFarmFeed(_userId);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✓ Vous ne suivez plus cet agriculteur'),
                                backgroundColor: Colors.orange,
                              ),
                            );
                          }
                        } else {
                          // Suivre
                          await ApiService.followUser(
                            userIdToFollow: ownerId,
                            userId: _userId,
                          );
                          if (mounted) {
                            setState(() {
                              _followedFarmIds.add(ownerId);
                              _feedFuture = ApiService.getFarmFeed(_userId);
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('✅ Vous suivez maintenant cet agriculteur'),
                                backgroundColor: Color(0xFF6B8E23),
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Erreur: $e')),
                          );
                        }
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _followedFarmIds.contains(ownerId) 
                          ? const Color(0xFF6B8E23).withOpacity(0.2)
                          : const Color(0xFF6B8E23),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    ),
                    child: Text(
                      _followedFarmIds.contains(ownerId) ? '✓ Ne plus suivre' : 'Suivre',
                      style: TextStyle(
                        fontSize: 12,
                        color: _followedFarmIds.contains(ownerId)
                            ? const Color(0xFF6B8E23)
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    final farmName = post['farm_name'] as String? ?? 'Ferme';
    final ownerName = post['owner_name'] as String? ?? 'Agriculteur';
    final title = post['title'] as String;
    final description = post['description'] as String?;
    final photoUrl = post['photo_url'] as String?;
    final postType = post['post_type'] as String? ?? 'crop_update';
    final createdAt = DateTime.parse(post['created_at'] as String);
    final daysAgo = DateTime.now().difference(createdAt).inDays;

    final postTypeEmoji = {
      'crop_update': '🌱',
      'harvest_result': '🌾',
      'problem_report': '🚨',
      'tip': '💡',
    };

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDarkMode ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.04),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header avec infos ferme
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFF6B8E23).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.agriculture, color: Color(0xFF6B8E23), size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farmName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'par $ownerName',
                        style: TextStyle(
                          fontSize: 12,
                          color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                        ),
                      ),
                    ],
                  ),
                ),
                Text(
                  'il y a $daysAgo j',
                  style: TextStyle(
                    fontSize: 11,
                    color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                  ),
                ),
              ],
            ),
          ),

          // Contenu
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      postTypeEmoji[postType] ?? '📝',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 13,
                        color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                        height: 1.4,
                      ),
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ),

          // Photo si disponible
          if (photoUrl != null && photoUrl.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  photoUrl,
                  height: 250,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 250,
                    color: Colors.grey[300],
                    child: const Icon(Icons.image_not_supported),
                  ),
                ),
              ),
            ),

          // Bouton Voir plus
          Padding(
            padding: const EdgeInsets.all(12),
            child: SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => _showPostDetails(post),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF6B8E23),
                ),
                child: const Text('Voir plus'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      isScrollControlled: true,
      builder: (_) => _FarmSearchWidget(
        isDarkMode: widget.isDarkMode,
        onFarmSelected: (farmId) {
          Navigator.pop(context);
          // Naviguer vers le profil de la ferme
        },
      ),
    );
  }

  void _showPostDetails(dynamic post) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
        title: Text(
          post['title'],
          style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Ferme: ${post['farm_name']}',
                style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
              ),
              const SizedBox(height: 8),
              if (post['description'] != null)
                Text(
                  post['description'],
                  style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black54),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }
}

class _FarmSearchWidget extends StatefulWidget {
  final bool isDarkMode;
  final Function(int) onFarmSelected;

  const _FarmSearchWidget({
    required this.isDarkMode,
    required this.onFarmSelected,
  });

  @override
  State<_FarmSearchWidget> createState() => __FarmSearchWidgetState();
}

class __FarmSearchWidgetState extends State<_FarmSearchWidget> {
  String _query = '';
  String _selectedSpecialty = '';
  late Future<List<dynamic>> _searchFuture;

  final List<String> _specialties = [
    'tomate', 'riz', 'mil', 'maïs', 'oignon', 'carotte', 'arachide', 'niébé',
    'chou', 'courge', 'navet', 'poivron', 'aubergine', 'légumes', 'fruits'
  ];

  @override
  void initState() {
    super.initState();
    _searchFuture = ApiService.searchFarmProfiles();
  }

  void _updateSearch() {
    setState(() {
      _searchFuture = ApiService.searchFarmProfiles(
        query: _query,
        specialty: _selectedSpecialty.isNotEmpty ? _selectedSpecialty : null,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🔍 Découvrir des fermes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              // Recherche par texte
              TextField(
                onChanged: (value) {
                  _query = value;
                  _updateSearch();
                },
                style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
                decoration: InputDecoration(
                  hintText: 'Rechercher une ferme...',
                  hintStyle: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black45),
                  prefixIcon: const Icon(Icons.search),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  contentPadding: const EdgeInsets.all(12),
                ),
              ),
              const SizedBox(height: 16),

              // Filtres par spécialité
              Text(
                'Spécialités',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _specialties.map((specialty) {
                  final isSelected = _selectedSpecialty == specialty;
                  return FilterChip(
                    label: Text(specialty),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedSpecialty = selected ? specialty : '';
                      });
                      _updateSearch();
                    },
                    backgroundColor: widget.isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
                    selectedColor: const Color(0xFF6B8E23).withOpacity(0.3),
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Résultats
              FutureBuilder<List<dynamic>>(
                future: _searchFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: CircularProgressIndicator(color: const Color(0xFF6B8E23)),
                    );
                  }

                  final farms = snapshot.data ?? [];
                  if (farms.isEmpty) {
                    return Center(
                      child: Text(
                        'Aucune ferme trouvée',
                        style: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black45),
                      ),
                    );
                  }

                  return ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: farms.length,
                    itemBuilder: (context, index) {
                      final farm = farms[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: widget.isDarkMode ? const Color(0xFF2C2C2E) : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              farm['farm_name'] ?? 'Ferme',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                color: widget.isDarkMode ? Colors.white : Colors.black87,
                              ),
                            ),
                            if (farm['location'] != null)
                              Text(
                                '📍 ${farm['location']}',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                                ),
                              ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Wrap(
                                  spacing: 4,
                                  children: (farm['specialties'] as List?)?.cast<String>().take(2).map((spec) {
                                        return Chip(
                                          label: Text(
                                            spec,
                                            style: const TextStyle(fontSize: 11),
                                          ),
                                          padding: const EdgeInsets.symmetric(horizontal: 6),
                                        );
                                      }).toList() ??
                                      [],
                                ),
                                ElevatedButton(
                                  onPressed: () {
                                    widget.onFarmSelected(farm['farm_id']);
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF6B8E23),
                                  ),
                                  child: const Text('Suivre', style: TextStyle(fontSize: 12, color: Colors.white)),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
