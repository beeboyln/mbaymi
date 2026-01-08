import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';

class FarmProfileScreen extends StatefulWidget {
  final int farmId;
  final int userId;
  final bool isDarkMode;

  const FarmProfileScreen({
    Key? key,
    required this.farmId,
    required this.userId,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<FarmProfileScreen> createState() => _FarmProfileScreenState();
}

class _FarmProfileScreenState extends State<FarmProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<List<dynamic>> _postsFuture;
  bool _isEditing = false;
  bool _isPublic = true;
  String _description = '';
  String _specialties = '';

  @override
  void initState() {
    super.initState();
    _profileFuture = ApiService.getFarmProfile(widget.farmId);
    _postsFuture = ApiService.getFarmPosts(widget.farmId);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : Colors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: widget.isDarkMode ? Colors.white : Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profil de Ferme',
          style: TextStyle(
            color: widget.isDarkMode ? Colors.white : Colors.black87,
            fontWeight: FontWeight.w400,
            fontSize: 16,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _isEditing ? Icons.check : Icons.edit,
              color: widget.isDarkMode ? Colors.white : Colors.black,
            ),
            onPressed: () {
              if (_isEditing) {
                _saveProfile();
              }
              setState(() => _isEditing = !_isEditing);
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 100),
                  child: CircularProgressIndicator(color: const Color(0xFF6B8E23)),
                ),
              );
            }

            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                    const SizedBox(height: 16),
                    Text('Profil non trouvé', style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black)),
                  ],
                ),
              );
            }

            final profile = snapshot.data!;
            final farmName = profile['farm_name'] as String? ?? 'Ma Ferme';
            final farmLocation = profile['farm_location'] as String?;
            final ownerName = profile['owner_name'] as String? ?? 'Agriculteur';
            final followers = profile['total_followers'] as int? ?? 0;

            if (!_isEditing) {
              _description = profile['description'] as String? ?? '';
              _specialties = _parseSpecialties(profile['specialties']).join(', ');
              _isPublic = profile['is_public'] as bool? ?? true;
            }

            return Column(
              children: [
                // Header avec infos principales
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                    borderRadius: const BorderRadius.only(
                      bottomLeft: Radius.circular(16),
                      bottomRight: Radius.circular(16),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Nom et location
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            farmName,
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.w600,
                              color: widget.isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          if (farmLocation != null && farmLocation.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Row(
                                children: [
                                  Icon(Icons.location_on_outlined, size: 16, color: const Color(0xFF6B8E23)),
                                  const SizedBox(width: 6),
                                  Text(
                                    farmLocation,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Stats
                      Row(
                        children: [
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B8E23).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Text(
                                    '$followers',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF6B8E23),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Suiveur${followers > 1 ? 's' : ''}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B8E23).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  FutureBuilder<List<dynamic>>(
                                    future: _postsFuture,
                                    builder: (_, snapshot) {
                                      final count = snapshot.data?.length ?? 0;
                                      return Text(
                                        '$count',
                                        style: const TextStyle(
                                          fontSize: 20,
                                          fontWeight: FontWeight.w600,
                                          color: Color(0xFF6B8E23),
                                        ),
                                      );
                                    },
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Publication',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Contenu éditable
                if (_isEditing) _buildEditForm(),

                // Description
                if (!_isEditing && _description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                          Text(
                            'À propos',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: widget.isDarkMode ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _description,
                            style: TextStyle(
                              fontSize: 13,
                              color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Spécialités
                if (_specialties.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                            children: _specialties.split(', ').map((spec) {
                              if (spec.isEmpty) return const SizedBox.shrink();
                              return Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF6B8E23).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  spec.trim(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF6B8E23),
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                    ),
                  ),

                // Publications
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dernières Publications',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<dynamic>>(
                        future: _postsFuture,
                        builder: (context, snapshot) {
                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return CircularProgressIndicator(color: const Color(0xFF6B8E23));
                          }

                          final posts = snapshot.data ?? [];
                          if (posts.isEmpty) {
                            return Text(
                              'Aucune publication pour le moment',
                              style: TextStyle(
                                color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                              ),
                            );
                          }

                          return ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: posts.length,
                            itemBuilder: (context, index) {
                              final post = posts[index];
                              return _buildPostCard(post);
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildEditForm() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Column(
        children: [
          // Description
          TextField(
            controller: TextEditingController(text: _description),
            onChanged: (value) => _description = value,
            maxLines: 3,
            style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              labelText: 'Description',
              hintText: 'Décrivez votre ferme...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),

          // Spécialités
          TextField(
            controller: TextEditingController(text: _specialties),
            onChanged: (value) => _specialties = value,
            style: TextStyle(color: widget.isDarkMode ? Colors.white : Colors.black87),
            decoration: InputDecoration(
              labelText: 'Spécialités',
              hintText: 'Exemple: tomate, riz, mil (séparé par virgule)',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
              contentPadding: const EdgeInsets.all(12),
            ),
          ),
          const SizedBox(height: 12),

          // Visibilité
          CheckboxListTile(
            value: _isPublic,
            onChanged: (value) => setState(() => _isPublic = value ?? true),
            title: const Text('Visible dans le réseau agricole'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ],
      ),
    );
  }

  Widget _buildPostCard(dynamic post) {
    final title = post['title'] as String;
    final description = post['description'] as String?;
    final photoUrl = post['photo_url'] as String?;
    final createdAt = DateTime.parse(post['created_at'] as String);
    final daysAgo = DateTime.now().difference(createdAt).inDays;

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
          if (photoUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              child: Image.network(
                photoUrl,
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 200,
                  color: Colors.grey[300],
                  child: const Icon(Icons.image_not_supported),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                if (description != null && description.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      description,
                      style: TextStyle(
                        fontSize: 12,
                        color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'il y a $daysAgo jour${daysAgo > 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 11,
                      color: widget.isDarkMode ? Colors.white60 : Colors.black45,
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

  void _saveProfile() async {
    try {
      await ApiService.createFarmProfile(
        farmId: widget.farmId,
        userId: widget.userId,
        description: _description,
        specialties: _specialties,
        isPublic: _isPublic,
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Profil mis à jour'),
          backgroundColor: Color(0xFF6B8E23),
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: Colors.red),
      );
    }
  }

  List<String> _parseSpecialties(dynamic spec) {
    if (spec is List) {
      return List<String>.from(spec);
    } else if (spec is String) {
      return spec.split(',').map((s) => s.trim()).toList();
    }
    return [];
  }
}
