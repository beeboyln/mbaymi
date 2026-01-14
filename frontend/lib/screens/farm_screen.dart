import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mbaymi/widgets/empty_state.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/screens/create_farm_screen.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/screens/parcel_screen.dart';
import 'package:mbaymi/screens/create_livestock_screen.dart';
import 'package:mbaymi/screens/edit_livestock_screen.dart';

class FarmTab extends StatefulWidget {
  final int? userId;

  const FarmTab({Key? key, this.userId}) : super(key: key);


  @override
  State<FarmTab> createState() => _FarmTabState();
}

class _FarmTabState extends State<FarmTab> {
  Future<List<dynamic>>? _farmsFuture;
  Future<List<dynamic>>? _livestockFuture;
  int _selectedSection = 0;
  int? _lastKnownUserId;

  @override
  void initState() {
    super.initState();
    _lastKnownUserId = widget.userId;
    _loadFarms();
  }

  void _loadFarms() {
    _farmsFuture = (widget.userId != null
        ? ApiService.getUserFarms(widget.userId!)
        : ApiService.getPublicFarms());
  }

  @override
  void didUpdateWidget(FarmTab oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Recharger les fermes si l'utilisateur vient de se connecter
    if (oldWidget.userId != widget.userId) {
      // Clear le cache quand l'utilisateur change
      ApiService.clearCache();
      _lastKnownUserId = widget.userId;
      _farmsFuture = null;
      _livestockFuture = null;
      _selectedSection = 0;
      _loadFarms();
      setState(() {});
    }
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Vérifier si l'utilisateur s'est connecté quand on revient au premier plan
    if (state == AppLifecycleState.resumed) {
      _checkForAuthChange();
    }
  }

  void _checkForAuthChange() {
    final currentUserId = AuthService.currentSession?.userId;
    if (_lastKnownUserId != currentUserId && currentUserId != null) {
      _lastKnownUserId = currentUserId;
      _loadFarms();
      _livestockFuture = null;
      _selectedSection = 0;
      if (mounted) {
        setState(() {});
      }
    }
  }

  Future<void> _refreshFarms() async {
    _checkForAuthChange();
    if (_selectedSection == 0) {
      _farmsFuture = widget.userId != null
          ? ApiService.getUserFarms(widget.userId!)
          : ApiService.getPublicFarms();
    } else if (widget.userId != null) {
      _livestockFuture = ApiService.getUserLivestock(widget.userId!);
    }
    setState(() {});
    imageCache.clearLiveImages();
    imageCache.clear();
  }

  Widget _buildSectionTabs(bool isDarkMode) {
    final selectedColor = const Color(0xFF6B8E23);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () => setState(() => _selectedSection = 0),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedSection == 0 ? selectedColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  '🌾 Fermes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _selectedSection == 0 ? selectedColor : (isDarkMode ? Colors.white60 : Colors.black45),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
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
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _selectedSection == 1 ? selectedColor : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  '🐄 Bétail',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: _selectedSection == 1 ? selectedColor : (isDarkMode ? Colors.white60 : Colors.black45),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Lire le mode sombre directement du ThemeProvider
    final isDarkMode = Provider.of<ThemeProvider>(context).isDarkMode;
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
      body: RefreshIndicator(
        color: const Color(0xFF6B8E23),
        backgroundColor: isDarkMode ? const Color(0xFF1C1C1E) : Colors.white,
        onRefresh: _refreshFarms,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              backgroundColor: isDarkMode ? const Color(0xFF121212) : const Color(0xFFFAFAFA),
              elevation: 0,
              pinned: true,
              floating: false,
              snap: false,
              surfaceTintColor: Colors.transparent,
              toolbarHeight: 80.0,
              automaticallyImplyLeading: false,
              title: Container(
                width: double.infinity,
                padding: EdgeInsets.only(
                  top: MediaQuery.of(context).padding.top + 16,
                  bottom: 16,
                ),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isDarkMode 
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
                    color: isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                  ),
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.only(top: 8),
              sliver: SliverToBoxAdapter(
                child: _buildContent(isDarkMode),
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
                backgroundColor: isDarkMode 
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

  Widget _buildContent(bool isDarkMode) {
    if (widget.userId == null) {
      return SingleChildScrollView(
        child: Column(
          children: [
            // Image de la ferme - Hero section
            Container(
              width: double.infinity,
              height: 300,
              decoration: BoxDecoration(
                image: const DecorationImage(
                  image: AssetImage('assets/images/ferme.jpg'),
                  fit: BoxFit.cover,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              // Gradient overlay
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.3),
                      Colors.black.withOpacity(0.6),
                    ],
                  ),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        '🌾',
                        style: TextStyle(fontSize: 64),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Gestion des Fermes',
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            
            // Contenu descriptif
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Créez et gérez vos fermes',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Organisez vos parcelles, suivez vos cultures et gérez votre inventaire agricole en un seul endroit.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: isDarkMode ? Colors.white70 : const Color(0xFF666666),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Caractéristiques
                  ...['📊 Suivez vos cultures', '🐄 Gérez votre bétail', '📈 Analysez vos rendements'].map((feature) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Row(
                        children: [
                          Container(
                            width: 4,
                            height: 4,
                            decoration: BoxDecoration(
                              color: const Color(0xFF8B6B4D),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            feature,
                            style: TextStyle(
                              fontSize: 14,
                              color: isDarkMode ? Colors.white60 : const Color(0xFF555555),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  
                  const SizedBox(height: 32),
                  
                  // Bouton Commencer vert
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
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
                              backgroundColor: const Color(0xFF3D6B1F),
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF3D6B1F),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Commencer',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
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

    return FutureBuilder<List<dynamic>>(
      future: _farmsFuture ?? (widget.userId != null
          ? ApiService.getUserFarms(widget.userId!)
          : ApiService.getPublicFarms()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.only(top: 100),
            child: Center(
              child: Column(
                children: [
                  const CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Color(0xFF2D5016),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Chargement de vos fermes...',
                    style: TextStyle(
                      fontWeight: FontWeight.w300,
                      fontSize: 14,
                      color: isDarkMode ? Colors.white60 : Colors.black45,
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
                    color: isDarkMode ? Colors.white : Colors.black87,
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
                      color: isDarkMode ? Colors.white60 : Colors.black54,
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
          padding: const EdgeInsets.only(top: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTabs(isDarkMode),
              const SizedBox(height: 16),
              if (_selectedSection == 0) ...[
                if (farms.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 60, horizontal: 20),
                    child: Center(
                      child: Column(
                        children: [
                          Icon(Icons.agriculture_outlined, size: 48, color: const Color(0xFF6B8E23).withOpacity(0.4)),
                          const SizedBox(height: 12),
                          Text('Aucune ferme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: isDarkMode ? Colors.white60 : Colors.black45)),
                        ],
                      ),
                    ),
                  )
                else
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: farms.length,
                    itemBuilder: (context, index) => _buildFarmCard(context, farms[index] as Map<String, dynamic>, isDarkMode),
                  ),
              ] else ...[
                FutureBuilder<List<dynamic>>(
                  future: _livestockFuture ?? (widget.userId != null ? ApiService.getUserLivestock(widget.userId!) : Future.value([])),
                  builder: (context, lsnap) {
                    if (lsnap.connectionState == ConnectionState.waiting) {
                      return Padding(
                        padding: const EdgeInsets.only(top: 80),
                        child: Center(
                          child: Column(
                            children: [
                              const CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF6B8E23)),
                              const SizedBox(height: 16),
                              Text('Chargement...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w300, color: isDarkMode ? Colors.white60 : Colors.black45)),
                            ],
                          ),
                        ),
                      );
                    }
                    if (lsnap.hasError) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.red.shade400),
                              const SizedBox(height: 12),
                              Text('Erreur de chargement', style: TextStyle(fontSize: 14, color: isDarkMode ? Colors.white60 : Colors.black45)),
                            ],
                          ),
                        ),
                      );
                    }
                    final animals = lsnap.data ?? [];
                    if (animals.isEmpty) {
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 60),
                        child: Center(
                          child: Column(
                            children: [
                              Icon(Icons.pets_outlined, size: 48, color: const Color(0xFF6B8E23).withOpacity(0.4)),
                              const SizedBox(height: 12),
                              Text('Aucun animal', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w300, color: isDarkMode ? Colors.white60 : Colors.black45)),
                            ],
                          ),
                        ),
                      );
                    }
                    return ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: animals.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) => _buildAnimalCard(animals[index] as Map<String, dynamic>, isDarkMode),
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

  Widget _buildFarmCard(BuildContext context, Map<String, dynamic> farm, bool isDarkMode) {
    return GestureDetector(
      onTap: () {
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
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDarkMode
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.06),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            _buildFarmAvatar(farm, isDarkMode),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    farm['name'] ?? 'Ferme',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isDarkMode ? Colors.white : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (farm['location'] != null && (farm['location'] as String).isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        farm['location'],
                        style: TextStyle(
                          fontSize: 12,
                          color: isDarkMode ? Colors.white60 : Colors.black45,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: isDarkMode ? Colors.white30 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmAvatar(Map<String, dynamic> farm, bool isDarkMode) {
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
        color: isDarkMode
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

  Widget _buildAnimalCard(Map<String, dynamic> animal, bool isDarkMode) {
    final animalType = animal['animal_type'] as String? ?? 'Animal';
    final breed = animal['breed'] as String? ?? '';
    final quantity = animal['quantity'] as int? ?? 1;
    final photo = animal['image_url'] ?? animal['imageUrl'] ?? (animal['photos'] is List && (animal['photos'] as List).isNotEmpty ? (animal['photos'] as List).first : null);
    final livestockId = animal['id'] as int?;

    return GestureDetector(
      onTap: livestockId != null
          ? () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => EditLivestockScreen(
                    livestockId: livestockId,
                    livestock: animal,
                  ),
                ),
              );
            }
          : null,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: isDarkMode ? Colors.white10 : Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: isDarkMode ? Colors.white10 : Colors.black12,
                image: photo != null ? DecorationImage(image: NetworkImage(photo), fit: BoxFit.cover) : null,
              ),
              child: photo == null ? const Icon(Icons.pets, color: Color(0xFF6B8E23), size: 24) : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    animalType,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: isDarkMode ? Colors.white : Colors.black87),
                  ),
                  if (breed.isNotEmpty)
                    Text(
                      breed,
                      style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white60 : Colors.black54),
                    ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6B8E23).withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('x$quantity', style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF6B8E23))),
            ),
          ],
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
}
