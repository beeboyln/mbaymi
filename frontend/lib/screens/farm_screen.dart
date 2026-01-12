import 'package:flutter/material.dart';
import 'package:mbaymi/widgets/empty_state.dart';
import 'package:mbaymi/screens/create_farm_screen.dart';
import 'package:mbaymi/screens/edit_farm_screen.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/parcel_screen.dart';
import 'package:mbaymi/screens/farm_profile_screen.dart';
import 'package:mbaymi/widgets/create_farm_post_dialog.dart';
import 'package:mbaymi/widgets/farm_posts_widget.dart';
import 'package:mbaymi/screens/create_livestock_screen.dart';
import 'package:mbaymi/screens/animal_detail_screen.dart';

class FarmTab extends StatefulWidget {
  final bool isDarkMode;
  final int? userId;

  const FarmTab({Key? key, this.isDarkMode = false, this.userId}) : super(key: key);

  @override
  State<FarmTab> createState() => _FarmTabState();
}

class _FarmTabState extends State<FarmTab> {
  late Future<List<dynamic>> _farmsFuture;
  final Set<int> _expandedFarmIds = {};
  int _selectedSection = 0;
  Future<List<dynamic>>? _livestockFuture;

  @override
  void initState() {
    super.initState();
    _refreshFarms();
  }

  Future<void> _refreshFarms() async {
    setState(() {
      _farmsFuture = widget.userId != null
          ? ApiService.getUserFarms(widget.userId!)
          : ApiService.getPublicFarms();
      imageCache.clearLiveImages();
      imageCache.clear();
    });
  }

  Widget _buildSectionTabs() {
    final selectedColor = const Color(0xFF6B8E23);
    return Row(
      children: [
        Expanded(
          child: InkWell(
            onTap: () {
              setState(() {
                _selectedSection = 0;
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _selectedSection == 0 ? selectedColor.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Fermes',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _selectedSection == 0 ? FontWeight.w600 : FontWeight.w300,
                    color: _selectedSection == 0 ? selectedColor : (widget.isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: InkWell(
            onTap: () {
              if (widget.userId == null) {
                _showAuthSheet(context);
                return;
              }
              setState(() {
                _selectedSection = 1;
                _livestockFuture ??= ApiService.getUserLivestock(widget.userId!);
              });
            },
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: _selectedSection == 1 ? selectedColor.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  'Bétail',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: _selectedSection == 1 ? FontWeight.w600 : FontWeight.w300,
                    color: _selectedSection == 1 ? selectedColor : (widget.isDarkMode ? Colors.white70 : Colors.black54),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: RefreshIndicator(
        color: const Color(0xFF6B8E23),
        backgroundColor: widget.isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        onRefresh: _refreshFarms,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: widget.isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
              elevation: 0,
              pinned: true,
              floating: false,
              snap: false,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 80.0,
              title: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: widget.isDarkMode 
                          ? Colors.white.withOpacity(0.08) 
                          : Colors.black.withOpacity(0.06),
                      width: 1,
                    ),
                  ),
                ),
                child: Text(
                  'Gestion',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.8,
                    color: widget.isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: SliverToBoxAdapter(
                child: _buildContent(),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: widget.userId != null
          ? Container(
              margin: EdgeInsets.only(
                bottom: 16 + MediaQuery.of(context).padding.bottom,
              ),
              child: FloatingActionButton(
                onPressed: () async {
                  if (_selectedSection == 1) {
                    // Section Bétail - ouvrir la page d'ajout d'animal
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateLivestockScreen(userId: widget.userId),
                      ),
                    );
                    if (result != null) {
                      // Recharger le bétail après ajout
                      setState(() {
                        _livestockFuture = ApiService.getUserLivestock(widget.userId!);
                      });
                    }
                  } else {
                    // Section Fermes - créer une ferme
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => CreateFarmScreen(userId: widget.userId),
                      ),
                    );
                    if (result != null) setState(() {});
                  }
                },
                backgroundColor: widget.isDarkMode 
                    ? const Color(0xFF2C2C2E) 
                    : Colors.white,
                foregroundColor: const Color(0xFF6B8E23),
                elevation: 1,
                shape: const CircleBorder(),
                child: const Icon(Icons.add, size: 24),
              ),
            )
          : null,
    );
  }

  Widget _buildContent() {
    if (widget.userId == null) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: buildEmptyState(
          icon: Icons.agriculture_outlined,
          title: 'Gestion des Fermes',
          description: 'Créez et gérez vos parcelles agricoles',
          buttonLabel: 'Commencer',
          color: const Color(0xFF6B8E23),
          isDarkMode: widget.isDarkMode,
          onPressed: () async {
            final result = await Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const CreateFarmScreen()),
            );
            if (result != null) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Ferme créée avec succès',
                          style: TextStyle(fontWeight: FontWeight.w400)),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  backgroundColor: const Color(0xFF6B8E23),
                ),
              );
            }
          },
        ),
      );
    }

    return FutureBuilder<List<dynamic>>(
      future: _farmsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF6B8E23),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chargement de vos fermes...',
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 14,
                      color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 100),
            child: Column(
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
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    color: widget.isDarkMode ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Text(
                    'Veuillez réessayer ou contacter le support',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 14,
                      color: widget.isDarkMode ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                TextButton(
                  onPressed: _refreshFarms,
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF6B8E23),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  ),
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          );
        }

        final farms = snapshot.data ?? [];

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTabs(),
              const SizedBox(height: 12),
              if (_selectedSection == 0) ...[
                if (farms.isEmpty)
                  Text(
                    'Aucune ferme',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w300,
                      color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, left: 4),
                    child: Text(
                      '${farms.length} ferme${farms.length > 1 ? 's' : ''}',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w300,
                        color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                      ),
                    ),
                  ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: farms.length,
                  itemBuilder: (context, index) {
                    final farm = farms[index] as Map<String, dynamic>;
                    return _buildFarmCard(context, farm);
                  },
                ),
              ] else ...[
                FutureBuilder<List<dynamic>>(
                  future: _livestockFuture,
                  builder: (context, lsnap) {
                    if (lsnap.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 24),
                        child: Center(
                          child: Column(
                            children: [
                              const CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFF6B8E23),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'Chargement du bétail...',
                                style: TextStyle(
                                  fontWeight: FontWeight.w300,
                                  fontSize: 14,
                                  color: widget.isDarkMode ? Colors.white60 : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }
                    if (lsnap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text('Erreur de chargement', style: TextStyle(color: widget.isDarkMode ? Colors.white70 : Colors.black87)),
                      );
                    }
                    final animals = lsnap.data ?? [];
                    if (animals.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Text('Aucun animal répertorié', style: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black45)),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: animals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (context, index) {
                        final animal = animals[index] as Map<String, dynamic>;
                        return _buildAnimalCard(animal);
                      },
                    );
                  },
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildFarmCard(BuildContext context, Map<String, dynamic> farm) {
    final hasPhotos = farm['photos'] != null && (farm['photos'] as List).isNotEmpty;
    final parcelsCount = farm['parcels_count'] ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: widget.isDarkMode
              ? Colors.white.withOpacity(0.08)
              : Colors.black.withOpacity(0.04),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                _buildFarmAvatar(farm),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        farm['name'] ?? 'Ferme',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w400,
                          color: widget.isDarkMode ? Colors.white : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (farm['location'] != null &&
                          (farm['location'] as String).isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Row(
                            children: [
                              Icon(
                                Icons.location_on_outlined,
                                size: 14,
                                color: widget.isDarkMode
                                    ? Colors.white60
                                    : Colors.black45,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  farm['location'],
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w300,
                                    color: widget.isDarkMode
                                        ? Colors.white60
                                        : Colors.black45,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 4,
                          children: [
                            Text(
                              '$parcelsCount parcelle${parcelsCount > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w300,
                                color: Color(0xFF6B8E23),
                              ),
                            ),
                            if (farm['size'] != null &&
                                (farm['size'] as String).isNotEmpty)
                              Text(
                                '• ${farm['size']}',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w300,
                                  color: widget.isDarkMode
                                      ? Colors.white60
                                      : Colors.black45,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ParcelScreen(
                          farmId: farm['id'] as int,
                          userId: widget.userId!,
                        ),
                      ),
                    );
                  },
                  style: IconButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(8),
                  ),
                  icon: Icon(
                    Icons.arrow_forward_rounded,
                    size: 20,
                    color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          if (hasPhotos) _buildPhotoGallery(farm),
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParcelScreen(
                            farmId: farm['id'] as int,
                            userId: widget.userId!,
                          ),
                        ),
                      );
                    },
                    style: TextButton.styleFrom(
                      foregroundColor: widget.isDarkMode
                          ? Colors.white70
                          : Colors.black54,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 8),
                    ),
                    child: const Text(
                      'Voir parcelles',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (context) => CreateFarmPostDialog(
                          farmId: farm['id'] as int,
                          farmName: farm['name'] ?? 'Ferme',
                          onPostCreated: () {
                            _refreshFarms();
                          },
                        ),
                      );
                    },
                    icon: const Icon(
                      Icons.photo_camera_outlined,
                      size: 16,
                      color: Color(0xFF8B6B4D),
                    ),
                    label: const Text(
                      'Poster',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: Color(0xFF8B6B4D),
                      ),
                    ),
                  ),
                  TextButton.icon(
                    onPressed: () async {
                      try {
                        final isPublic = farm['is_public'] ?? false;
                        final result = await ApiService.toggleFarmVisibility(
                          userId: widget.userId!,
                          farmId: farm['id'] as int,
                          isPublic: !isPublic,
                        );
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(result['message'] ?? 'Visibilité mise à jour'),
                              backgroundColor: const Color(0xFF6B8E23),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          _refreshFarms();
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Erreur: $e'),
                              backgroundColor: Colors.red.shade400,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      }
                    },
                    icon: Icon(
                      (farm['is_public'] ?? false) ? Icons.public : Icons.lock_outlined,
                      size: 16,
                      color: (farm['is_public'] ?? false) ? const Color(0xFF6B8E23) : Colors.orange,
                    ),
                    label: Text(
                      (farm['is_public'] ?? false) ? 'Publique' : 'Privée',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: (farm['is_public'] ?? false) ? const Color(0xFF6B8E23) : Colors.orange,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              EditFarmScreen(farm: farm as Map<String, dynamic>, userId: widget.userId, isDarkMode: widget.isDarkMode),
                        ),
                      );
                      if (result != null && mounted) setState(() {});
                    },
                    icon: const Icon(
                      Icons.edit_outlined,
                      size: 18,
                      color: Color(0xFF6B8E23),
                    ),
                  ),
                  _buildPopupMenu(context, farm),
                ],
              ),
            ),
          ),
          Builder(builder: (context) {
            final farmId = farm['id'] as int;
            final isExpanded = _expandedFarmIds.contains(farmId);
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        FutureBuilder<List<dynamic>>(
                          future: ApiService.getFarmPosts(farmId),
                          builder: (context, snap) {
                            final count = (snap.data ?? []).length;
                            return Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: const Color(0xFF6B8E23).withOpacity(0.12),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.image_outlined, size: 14, color: Color(0xFF6B8E23)),
                                  const SizedBox(width: 6),
                                  Text('$count', style: const TextStyle(color: Color(0xFF6B8E23), fontWeight: FontWeight.w600)),
                                ],
                              ),
                            );
                          },
                        ),
                        TextButton.icon(
                          onPressed: () {
                            setState(() {
                              if (isExpanded) {
                                _expandedFarmIds.remove(farmId);
                              } else {
                                _expandedFarmIds.add(farmId);
                              }
                            });
                          },
                          icon: AnimatedRotation(
                            turns: isExpanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            child: Icon(Icons.expand_more, color: const Color(0xFF6B8E23)),
                          ),
                          label: Text(isExpanded ? 'Masquer les posts' : 'Voir les posts', style: const TextStyle(color: Color(0xFF6B8E23))),
                          style: TextButton.styleFrom(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            foregroundColor: const Color(0xFF6B8E23),
                          ),
                        ),
                      ],
                    ),
                  ),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.easeInOut,
                    child: ConstrainedBox(
                      constraints: isExpanded ? const BoxConstraints() : const BoxConstraints(maxHeight: 0),
                      child: isExpanded
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: FarmPostsWidget(
                                farmId: farmId,
                                farmName: farm['name'] ?? 'Ferme',
                                isOwner: widget.userId != null && (farm['user_id'] as int? ?? 0) == widget.userId,
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildFarmAvatar(Map<String, dynamic> farm) {
    final hasPhotos = farm['photos'] != null && (farm['photos'] as List).isNotEmpty;

    if (hasPhotos) {
      final first = (farm['photos'] as List).first;
      final url = first is String ? first : (first['image_url'] ?? first['imageUrl']);

      if (url != null) {
        return Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            image: DecorationImage(
              image: NetworkImage(url),
              fit: BoxFit.cover,
            ),
          ),
        );
      }
    }

    final imageUrl = farm['image_url'] ?? farm['imageUrl'];
    if (imageUrl != null && (imageUrl as String).isNotEmpty) {
      return Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          image: DecorationImage(
            image: NetworkImage(imageUrl),
            fit: BoxFit.cover,
          ),
        ),
      );
    }

    return Container(
      width: 60,
      height: 60,
      decoration: BoxDecoration(
        color: widget.isDarkMode
            ? Colors.white.withOpacity(0.05)
            : const Color(0xFF6B8E23).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Icon(
        Icons.agriculture_outlined,
        size: 24,
        color: Color(0xFF6B8E23),
      ),
    );
  }

  Widget _buildPhotoGallery(Map<String, dynamic> farm) {
    final photos = farm['photos'] as List;

    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
      child: SizedBox(
        height: 100,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: photos.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final photo = photos[index];
            final url = photo is String ? photo : (photo['image_url'] ?? photo['imageUrl']);

            return Container(
              width: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  url,
                  width: 140,
                  height: 100,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    width: 140,
                    height: 100,
                    color: widget.isDarkMode
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.03),
                    child: Icon(
                      Icons.image_outlined,
                      size: 32,
                      color: widget.isDarkMode
                          ? Colors.white30
                          : Colors.black26,
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildAnimalCard(Map<String, dynamic> animal) {
    final animalType = animal['animal_type'] as String? ?? 'Animal';
    final breed = animal['breed'] as String? ?? '';
    final quantity = animal['quantity'] as int? ?? 1;
    final photo = animal['image_url'] ?? animal['imageUrl'] ?? (animal['photos'] is List && (animal['photos'] as List).isNotEmpty ? (animal['photos'] as List).first : null);
    final livestockId = animal['id'] as int?;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: livestockId != null
            ? () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => AnimalDetailScreen(
                      livestockId: livestockId,
                      animal: animal,
                      isDarkMode: widget.isDarkMode,
                    ),
                  ),
                );
              }
            : null,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: widget.isDarkMode ? Colors.white10 : Colors.black12),
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: widget.isDarkMode ? Colors.white10 : Colors.black12,
                  image: photo != null ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover) : null,
                ),
                child: photo == null ? Icon(Icons.pets, color: const Color(0xFF6B8E23)) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      animalType,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w500, color: widget.isDarkMode ? Colors.white : Colors.black87),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      breed.isNotEmpty ? breed : 'Race inconnue',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w300, color: widget.isDarkMode ? Colors.white60 : Colors.black54),
                    ),
                  ],
                ),
              ),
              Text('x$quantity', style: TextStyle(fontWeight: FontWeight.w600, color: const Color(0xFF6B8E23))),
            ],
          ),
        ),
      ),
    );
  }

  void _showAuthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Connexion requise',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Connectez-vous pour voir votre bétail',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF6B8E23),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Se connecter', style: TextStyle(color: Colors.white)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopupMenu(BuildContext context, Map<String, dynamic> farm) {
    return PopupMenuButton<String>(
      icon: Icon(
        Icons.more_vert_rounded,
        size: 18,
        color: widget.isDarkMode ? Colors.white60 : Colors.black45,
      ),
      offset: const Offset(0, 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      color: widget.isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
      onSelected: (v) async {
        if (v == 'profile') {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FarmProfileScreen(
                farmId: farm['id'] as int,
                userId: widget.userId ?? 0,
                isDarkMode: widget.isDarkMode,
              ),
            ),
          );
        } else if (v == 'edit') {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditFarmScreen(farm: farm, userId: widget.userId, isDarkMode: widget.isDarkMode),
            ),
          );
          if (result != null && mounted) setState(() {});
        } else if (v == 'delete') {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: widget.isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
              title: const Text('Supprimer la ferme'),
              content: Text('Êtes-vous sûr?'),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  child: const Text('Supprimer'),
                ),
              ],
            ),
          );
          if (ok == true) {
            try {
              await ApiService.deleteFarm(farm['id'] as int);
              if (!mounted) return;
              imageCache.clearLiveImages();
              imageCache.clear();
              await _refreshFarms();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Ferme supprimée')),
              );
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Erreur: $e')),
              );
            }
          }
        }
      },
      itemBuilder: (_) => [
        const PopupMenuItem(value: 'profile', child: Text('Profil public')),
        const PopupMenuItem(value: 'edit', child: Text('Modifier')),
        const PopupMenuItem(value: 'delete', child: Text('Supprimer')),
      ],
    );
  }
}
