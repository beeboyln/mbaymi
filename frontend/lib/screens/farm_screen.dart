import 'package:flutter/material.dart';
import 'package:mbaymi/widgets/empty_state.dart';
import 'package:mbaymi/screens/create_farm_screen.dart';
import 'package:mbaymi/screens/edit_farm_screen.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/parcel_screen.dart';
import 'package:mbaymi/screens/farm_profile_screen.dart';

class FarmTab extends StatefulWidget {
  final bool isDarkMode;
  final int? userId;

  const FarmTab({Key? key, this.isDarkMode = false, this.userId}) : super(key: key);

  @override
  State<FarmTab> createState() => _FarmTabState();
}

class _FarmTabState extends State<FarmTab> {
  late Future<List<dynamic>> _farmsFuture;

  @override
  void initState() {
    super.initState();
    _refreshFarms();
  }

  Future<void> _refreshFarms() async {
    setState(() {
      _farmsFuture = widget.userId != null
          ? ApiService.getUserFarms(widget.userId!)
          : Future.value([]);
      // Vider le cache d'images pour éviter les problèmes de persistence
      imageCache.clearLiveImages();
      imageCache.clear();
    });
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
            // Header fixe minimaliste
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
                  'Mes Fermes',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w300,
                    letterSpacing: -0.8,
                    color: widget.isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),

            // Contenu principal
            const SliverPadding(
              padding: EdgeInsets.only(top: 8),
              sliver: SliverToBoxAdapter(
                child: _ContentBuilder(),
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
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => CreateFarmScreen(userId: widget.userId),
                    ),
                  );
                  if (result != null) setState(() {});
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
        if (farms.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: buildEmptyState(
              icon: Icons.agriculture_outlined,
              title: 'Aucune ferme',
              description:
                  'Commencez par créer votre première ferme',
              buttonLabel: 'Créer une ferme',
              color: const Color(0xFF6B8E23),
              isDarkMode: widget.isDarkMode,
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => CreateFarmScreen(userId: widget.userId)),
                );
                if (result != null) setState(() {});
              },
            ),
          );
        }

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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
          // Header avec informations principales
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar de la ferme
                _buildFarmAvatar(farm),
                const SizedBox(width: 16),

                // Informations principales
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

                // Bouton d'accès rapide
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

          // Galerie de photos
          if (hasPhotos) _buildPhotoGallery(farm),

          // Séparateur et actions
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(horizontal: 16),
            color: widget.isDarkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
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
                Row(
                  children: [
                    IconButton(
                      onPressed: () async {
                        final result = await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                EditFarmScreen(farm: farm, userId: widget.userId),
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
              ],
            ),
          ),
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
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FarmProfileScreen(
                farmId: farm['id'] as int,
                userId: widget.userId ?? 0,
                isDarkMode: widget.isDarkMode,
              ),
            ),
          );
          if (result != null && mounted) setState(() {});
        } else if (v == 'edit') {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => EditFarmScreen(farm: farm, userId: widget.userId),
            ),
          );
          if (result != null && mounted) setState(() {});
        } else if (v == 'delete') {
          final ok = await showDialog<bool>(
            context: context,
            builder: (_) => AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              backgroundColor: widget.isDarkMode ? const Color(0xFF2C2C2E) : Colors.white,
              title: Text(
                'Supprimer la ferme',
                style: TextStyle(
                  fontWeight: FontWeight.w400,
                  fontSize: 16,
                  color: widget.isDarkMode ? Colors.white : Colors.black87,
                ),
              ),
              content: Text(
                'Êtes-vous sûr de vouloir supprimer "${farm['name']}" ?',
                style: TextStyle(
                  fontWeight: FontWeight.w300,
                  fontSize: 14,
                  color: widget.isDarkMode ? Colors.white70 : Colors.black54,
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: TextButton.styleFrom(
                    foregroundColor: widget.isDarkMode ? Colors.white70 : Colors.black54,
                  ),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.red,
                  ),
                  child: const Text('Supprimer'),
                ),
              ],
            ),
          );
          if (ok == true) {
            try {
              await ApiService.deleteFarm(farm['id'] as int);
              if (!mounted) return;
              // Vider le cache d'images
              imageCache.clearLiveImages();
              imageCache.clear();
              // Rafraîchir la liste
              await _refreshFarms();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Row(
                    children: [
                      Icon(Icons.check_circle_outline,
                          color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text('Ferme supprimée',
                          style: TextStyle(fontWeight: FontWeight.w400)),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  backgroundColor: const Color(0xFF4CAF50),
                ),
              );
              Navigator.pop(context);
            } catch (e) {
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.error_outline,
                          color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Text('Erreur: $e',
                          style: const TextStyle(fontWeight: FontWeight.w400)),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8)),
                  backgroundColor: Colors.red.shade400,
                ),
              );
            }
          }
        }
      },
      itemBuilder: (_) => [
        PopupMenuItem(
          value: 'profile',
          child: Text(
            'Profil public',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 14,
              color: const Color(0xFF6B8E23),
            ),
          ),
        ),
        PopupMenuItem(
          value: 'edit',
          child: Text(
            'Modifier',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 14,
              color: widget.isDarkMode ? Colors.white : Colors.black87,
            ),
          ),
        ),
        PopupMenuItem(
          value: 'delete',
          child: Text(
            'Supprimer',
            style: TextStyle(
              fontWeight: FontWeight.w300,
              fontSize: 14,
              color: Colors.red.shade400,
            ),
          ),
        ),
      ],
    );
  }
}

// Widget stateless pour éviter les reconstructions inutiles
class _ContentBuilder extends StatelessWidget {
  const _ContentBuilder();

  @override
  Widget build(BuildContext context) {
    final farmTab = context.findAncestorStateOfType<_FarmTabState>();
    return farmTab?._buildContent() ?? const SizedBox.shrink();
  }
}