import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/screens/post_detail_screen.dart';
import 'package:mbaymi/screens/farm_detail_screen.dart';

class SocialFeedScreen extends StatefulWidget {
  final bool isDarkMode;

  const SocialFeedScreen({Key? key, this.isDarkMode = false}) : super(key: key);

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  int _currentTabIndex = 0;
  int _userId = 0;
  
  // ✅ STORE FEED DATA IN STATE - NOT REBUILT ON EACH setState()
  late Future<Map<String, dynamic>> _feedFuture;
  List<Map<String, dynamic>> _combinedItems = [];
  bool _isLoadingFeed = false;
  
  // ✅ STORE EXPLORE & TRENDING DATA
  late Future<List<dynamic>> _exploreFuture;
  late Future<List<dynamic>> _trendingFuture;
  
  static const Color _primaryColor = Color(0xFF8B6B4D);
  static const Color _accentColor = Color(0xFF6B8E23);
  static const Color _bgLight = Color(0xFFFAFAFA);
  static const Color _bgDark = Color(0xFF121212);

  @override
  void initState() {
    super.initState();
    _userId = AuthService.currentSession?.userId ?? 0;
    // Load all data ONCE and store in futures
    _feedFuture = _loadCombinedFeed();
    _exploreFuture = ApiService.getPublicFarms();
    _trendingFuture = ApiService.getPublicFarms(); // Same data for now
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? _bgDark : _bgLight;
    final appBarColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: appBarColor,
        elevation: 0.5,
        surfaceTintColor: Colors.transparent,
        automaticallyImplyLeading: false,
        // Logo corrigé - a.png sans color filter
        title: const Text(
          'Mbaymi',
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Color.fromARGB(255, 107, 83, 61),
            letterSpacing: 1,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search_rounded, color: _primaryColor),
            onPressed: () => _showSearchDialog(),
          ),
          IconButton(
            icon: const Icon(Icons.favorite_border, color: _primaryColor),
            onPressed: () => _showLikesDialog(),
          ),
        ],
      ),
      body: IndexedStack(
        index: _currentTabIndex,
        children: [
          _buildFeedTab(),
          _buildExploreTab(),
          _buildTrendingTab(),
        ],
      ),
      bottomNavigationBar: Container(
        color: appBarColor,
        child: BottomNavigationBar(
          backgroundColor: appBarColor,
          elevation: 0.5,
          currentIndex: _currentTabIndex,
          onTap: (index) {
            setState(() => _currentTabIndex = index);
          },
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.home_filled), label: 'Accueil'),
            BottomNavigationBarItem(icon: Icon(Icons.explore), label: 'Découvrir'),
            BottomNavigationBarItem(icon: Icon(Icons.local_fire_department), label: 'Tendance'),
          ],
          selectedItemColor: _primaryColor,
          unselectedItemColor: Colors.grey,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }

  // 📰 TAB 1: FEED (Connecté ou pas)
  Widget _buildFeedTab() {
    return RefreshIndicator(
      onRefresh: () async {
        // Reload the feed from server
        setState(() {
          _feedFuture = _loadCombinedFeed();
        });
      },
      color: _primaryColor,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _feedFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget();
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          final data = snapshot.data ?? {};
          _combinedItems = data['items'] as List<Map<String, dynamic>>? ?? [];
          final combinedItems = _combinedItems;

          if (combinedItems.isEmpty) {
            return _buildEmptyFeedWidget();
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: combinedItems.length,
            itemBuilder: (context, index) {
              final item = combinedItems[index];
              if (item['type'] == 'post') {
                return _buildPostCard(item['data'], item);
              } else if (item['type'] == 'animal') {
                return _buildAnimalCard(item['data'], item);
              }
              return const SizedBox();
            },
          );
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _loadCombinedFeed() async {
    try {
      List<dynamic> posts = [];
      List<dynamic> animals = [];

      // Si connecté, charger le feed personnel ET les fermes publiques
      if (_userId > 0) {
        posts = await ApiService.getFarmFeed(_userId);
        // Ajouter aussi les fermes publiques
        final publicFarms = await ApiService.getPublicFarms();
        posts.addAll(publicFarms.map((f) => {
          'id': f['farm_id'],
          'farm_name': f['farm_name'],
          'owner_name': f['owner_name'] ?? 'Agriculteur',
          'title': f['farm_name'],
          'description': f['description'] ?? '',
          'photo_url': f['profile_image_farm'],
          'post_type': 'farm_update',
          'created_at': DateTime.now().toIso8601String(),
          'likes_count': f['followers'] ?? 0,
          'comments_count': 0,
          'shares_count': 0,
        }).toList());
      } else {
        // Sinon, charger les fermes publiques
        final farms = await ApiService.getPublicFarms();
        posts = farms.map((f) => {
          'id': f['farm_id'],
          'farm_name': f['farm_name'],
          'owner_name': f['owner_name'] ?? 'Agriculteur',
          'title': f['farm_name'],
          'description': f['description'] ?? '',
          'photo_url': f['profile_image_farm'],
          'post_type': 'farm_update',
          'created_at': DateTime.now().toIso8601String(),
          'likes_count': f['followers'] ?? 0,
          'comments_count': 0,
          'shares_count': 0,
        }).toList();
      }

      // Charger les animaux
      animals = await ApiService.getAllLivestockWithPhotos(userId: _userId);

      // Combiner
      List<Map<String, dynamic>> combinedItems = [];

      for (var post in posts) {
        combinedItems.add({
          'type': 'post',
          'data': post,
          'timestamp': DateTime.tryParse(post['created_at'] ?? '') ?? DateTime.now(),
        });
      }

      for (var animal in animals) {
        combinedItems.add({
          'type': 'animal',
          'data': animal,
          'timestamp': DateTime.tryParse(animal['created_at'] ?? '') ?? DateTime.now(),
        });
      }

      // Trier par date décroissante
      combinedItems.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      return {'items': combinedItems};
    } catch (e) {
      throw Exception('Erreur chargement: $e');
    }
  }

  // 🔍 TAB 2: EXPLORE
  Widget _buildExploreTab() {
    return RefreshIndicator(
      onRefresh: () async {
        // Reload explore data on pull-to-refresh
        setState(() {
          _exploreFuture = ApiService.getPublicFarms();
        });
      },
      color: _primaryColor,
      child: FutureBuilder<List<dynamic>>(
        future: _exploreFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget();
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          final farms = snapshot.data ?? [];

          if (farms.isEmpty) {
            return _buildEmptyExploreWidget();
          }

          return GridView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              childAspectRatio: 0.85,
            ),
            itemCount: farms.length,
            itemBuilder: (context, index) => _buildExploreFarmCard(farms[index]),
          );
        },
      ),
    );
  }

  // 🔥 TAB 3: TRENDING
  Widget _buildTrendingTab() {
    return RefreshIndicator(
      onRefresh: () async {
        // Reload trending data on pull-to-refresh
        setState(() {
          _trendingFuture = ApiService.getPublicFarms();
        });
      },
      color: _primaryColor,
      child: FutureBuilder<List<dynamic>>(
        future: _trendingFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoadingWidget();
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString());
          }

          final farms = snapshot.data ?? [];

          if (farms.isEmpty) {
            return _buildEmptyTrendingWidget();
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: farms.length,
            itemBuilder: (context, index) => _buildTrendingFarmCard(farms[index]),
          );
        },
      ),
    );
  }

  // 📱 POST CARD
  Widget _buildPostCard(dynamic post, Map<String, dynamic> itemWrapper) {
    final farmName = post['farm_name'] as String? ?? 'Ferme';
    final ownerName = post['owner_name'] as String? ?? 'Agriculteur';
    final title = post['title'] as String? ?? '';
    final description = post['description'] as String?;
    final photoUrl = post['photo_url'] as String?;
    final postType = post['post_type'] as String? ?? 'crop_update';
    final createdAt = DateTime.tryParse(post['created_at'] as String? ?? '') ?? DateTime.now();
    final postId = post['id'] as int? ?? 0;
    final likesCount = post['likes_count'] ?? 0;
    final commentsCount = post['comments_count'] ?? 0;
    final sharesCount = post['shares_count'] ?? 0;

    final postTypeEmoji = {
      'crop_update': '🌱',
      'harvest_result': '🌾',
      'problem_report': '🚨',
      'tip': '💡',
      'farm_update': '🌾',
    };

    final emoji = postTypeEmoji[postType] ?? '📝';
    final daysAgo = DateTime.now().difference(createdAt).inDays;
    final timeText = daysAgo == 0 ? 'Aujourd\'hui' : daysAgo == 1 ? 'Hier' : '$daysAgo j';

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PostDetailScreen(
              postId: postId,
              postData: post,
              isDarkMode: widget.isDarkMode,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(widget.isDarkMode ? 0.2 : 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 👤 En-tête
            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: _primaryColor,
                    child: Text(
                      ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                farmName,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            Text(emoji, style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'par $ownerName • $timeText',
                          style: TextStyle(
                            fontSize: 12,
                            color: widget.isDarkMode ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 🖼️ Image
            if (photoUrl != null && photoUrl.isNotEmpty)
              Container(
                height: 300,
                width: double.infinity,
                color: Colors.grey[300],
                child: Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.image, size: 40, color: Colors.grey[400])),
              )
            else
              Container(
                height: 200,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [_primaryColor.withOpacity(0.2), _accentColor.withOpacity(0.2)],
                  ),
                ),
                child: Center(child: Icon(Icons.image_outlined, size: 48, color: widget.isDarkMode ? Colors.white30 : Colors.black12)),
              ),

            // ❤️ Actions
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () async {
                      try {
                        final isLiked = post['is_liked'] ?? false;
                        final currentLikes = likesCount;
                        
                        // Update both post object AND stored list
                        post['is_liked'] = !isLiked;
                        post['likes_count'] = isLiked ? currentLikes - 1 : currentLikes + 1;
                        itemWrapper['data'] = post;
                        
                        // Trigger minimal rebuild
                        setState(() {});
                        
                        // API call in background
                        if (isLiked) {
                          await ApiService.unlikePost(postId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('🤍 Like retiré'), backgroundColor: _primaryColor, duration: Duration(milliseconds: 600)),
                          );
                        } else {
                          await ApiService.likePost(postId);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('❤️ J\'aime!'), backgroundColor: _primaryColor, duration: Duration(milliseconds: 600)),
                          );
                        }
                      } catch (e) {
                        // Revert on error
                        final isLiked = post['is_liked'] ?? false;
                        final currentLikes = post['likes_count'] ?? 0;
                        post['is_liked'] = !isLiked;
                        post['likes_count'] = isLiked ? currentLikes - 1 : currentLikes + 1;
                        itemWrapper['data'] = post;
                        setState(() {});
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: Row(
                      children: [
                        Icon(
                          (post['is_liked'] ?? false) ? Icons.favorite : Icons.favorite_border,
                          size: 20,
                          color: (post['is_liked'] ?? false) ? Colors.red : _primaryColor,
                        ),
                        const SizedBox(width: 4),
                        Text('${post['likes_count'] ?? 0}'),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('💬 Commentaires'), backgroundColor: _primaryColor),
                      );
                    },
                    child: Row(children: [Icon(Icons.chat_bubble_outline, size: 20, color: _primaryColor), const SizedBox(width: 4), Text('$commentsCount')]),
                  ),
                  const SizedBox(width: 16),
                  GestureDetector(
                    onTap: () async {
                      try {
                        final currentShares = sharesCount;
                        
                        // Update both post object AND stored list
                        post['shares_count'] = currentShares + 1;
                        itemWrapper['data'] = post;
                        
                        // Trigger minimal rebuild
                        setState(() {});
                        
                        // API call in background
                        await ApiService.sharePost(postId);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('📤 Partagé!'), backgroundColor: _primaryColor, duration: Duration(milliseconds: 600)),
                        );
                      } catch (e) {
                        // Revert on error
                        post['shares_count'] = (post['shares_count'] ?? 0) - 1;
                        itemWrapper['data'] = post;
                        setState(() {});
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                        );
                      }
                    },
                    child: Row(children: [Icon(Icons.share_outlined, size: 20, color: _primaryColor), const SizedBox(width: 4), Text('${post['shares_count'] ?? 0}')]),
                  ),
                  const Spacer(),
                  Icon(Icons.bookmark_border, size: 20, color: _primaryColor),
                ],
              ),
            ),

            // 📝 Contenu
            if (title.isNotEmpty || (description != null && description.isNotEmpty))
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (title.isNotEmpty)
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
                    if (title.isNotEmpty && description != null && description.isNotEmpty) const SizedBox(height: 4),
                    if (description != null && description.isNotEmpty)
                      Text(
                        description,
                        style: TextStyle(fontSize: 13, color: widget.isDarkMode ? Colors.white70 : Colors.black87, height: 1.4),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // 🐄 ANIMAL CARD
  Widget _buildAnimalCard(dynamic animal, Map<String, dynamic> itemWrapper) {
    final animalType = animal['animal_type'] as String? ?? 'Animal';
    final breed = animal['breed'] as String? ?? 'Race';
    final quantity = animal['quantity'] as int? ?? 1;
    final userName = animal['user_name'] as String? ?? 'Éleveur';
    final userProfileImage = animal['user_profile_image'] as String?;
    final photos = animal['photos'] as List? ?? [];
    final firstPhotoUrl = photos.isNotEmpty ? photos[0]['image_url'] : null;
    final healthStatus = animal['health_status'] as String? ?? 'Sain';

    final animalEmojis = {
      'vache': '🐄', 'chèvre': '🐐', 'mouton': '🐑', 'porc': '🐷', 'poule': '🐔',
      'canard': '🦆', 'cheval': '🐴', 'âne': '🫏', 'lapin': '🐰',
    };

    final emoji = animalEmojis[animalType.toLowerCase()] ?? '🐾';
    final createdAt = DateTime.tryParse(animal['created_at'] as String? ?? '') ?? DateTime.now();
    final daysAgo = DateTime.now().difference(createdAt).inDays;
    final timeText = daysAgo == 0 ? 'Aujourd\'hui' : daysAgo == 1 ? 'Hier' : '$daysAgo j';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(widget.isDarkMode ? 0.2 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: _primaryColor,
                  backgroundImage: userProfileImage != null && userProfileImage.isNotEmpty
                      ? NetworkImage(userProfileImage)
                      : null,
                  child: (userProfileImage == null || userProfileImage.isEmpty)
                      ? Text(userName.isNotEmpty ? userName[0].toUpperCase() : '?', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14))
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text('$animalType - $breed', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                          Text(emoji, style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text('par $userName • $timeText', style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white54 : Colors.black54)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (firstPhotoUrl != null && firstPhotoUrl.isNotEmpty)
            Container(height: 300, width: double.infinity, color: Colors.grey[300], child: Image.network(firstPhotoUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.image, size: 40, color: Colors.grey[400])))
          else
            Container(height: 200, width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryColor.withOpacity(0.2), _accentColor.withOpacity(0.2)])), child: Center(child: Icon(Icons.pets_outlined, size: 48, color: widget.isDarkMode ? Colors.white30 : Colors.black12))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () async {
                    try {
                      final isLiked = animal['is_liked'] ?? false;
                      final currentLikes = animal['likes_count'] ?? 0;
                      
                      // Update both animal object AND stored list - so it persists
                      animal['is_liked'] = !isLiked;
                      animal['likes_count'] = isLiked ? currentLikes - 1 : currentLikes + 1;
                      itemWrapper['data'] = animal;
                      
                      // Trigger minimal rebuild - just the like button, not the whole widget
                      setState(() {});
                      
                      // API call in background
                      if (isLiked) {
                        await ApiService.unlikeLivestock(animal['id'] ?? 0);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('🤍 Like retiré'), backgroundColor: _primaryColor, duration: Duration(milliseconds: 600)),
                        );
                      } else {
                        await ApiService.likeLivestock(animal['id'] ?? 0);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('❤️ J\'aime!'), backgroundColor: _primaryColor, duration: Duration(milliseconds: 600)),
                        );
                      }
                    } catch (e) {
                      // Revert on error
                      final isLiked = animal['is_liked'] ?? false;
                      final currentLikes = animal['likes_count'] ?? 0;
                      animal['is_liked'] = !isLiked;
                      animal['likes_count'] = isLiked ? currentLikes - 1 : currentLikes + 1;
                      itemWrapper['data'] = animal;
                      setState(() {});
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: Row(
                    children: [
                      Icon(
                        (animal['is_liked'] ?? false) ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: (animal['is_liked'] ?? false) ? Colors.red : _primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text('${animal['likes_count'] ?? 0}'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('💬 Commentaires'), backgroundColor: _primaryColor),
                    );
                  },
                  child: Row(children: [Icon(Icons.chat_bubble_outline, size: 20, color: _primaryColor), const SizedBox(width: 4), Text('${animal['comments_count'] ?? 0}')]),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () async {
                    try {
                      await ApiService.sharePost(animal['id'] ?? 0);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('📤 Partagé!'), backgroundColor: _primaryColor, duration: Duration(milliseconds: 800)),
                      );
                      setState(() {});
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
                      );
                    }
                  },
                  child: Row(children: [Icon(Icons.share_outlined, size: 20, color: _primaryColor), const SizedBox(width: 4), Text('${animal['shares_count'] ?? 0}')]),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(children: [Text('Qty: $quantity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: widget.isDarkMode ? Colors.white : Colors.black87)), const SizedBox(width: 16), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _getHealthStatusColor(healthStatus).withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(healthStatus, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _getHealthStatusColor(healthStatus))))]),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Color _getHealthStatusColor(String status) {
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

  // 🏠 EXPLORE CARD
  Widget _buildExploreFarmCard(dynamic farm) {
    final farmName = farm['farm_name'] as String? ?? 'Ferme';
    final farmId = farm['farm_id'] as int? ?? 0;
    final imageUrl = farm['profile_image_farm'] as String?;
    final followers = farm['followers'] as int? ?? 0;

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
        decoration: BoxDecoration(
          color: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(widget.isDarkMode ? 0.2 : 0.05), blurRadius: 6)],
        ),
        child: Stack(
          children: [
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(borderRadius: BorderRadius.circular(12), color: Colors.grey[300]),
                child: imageUrl != null && imageUrl.isNotEmpty
                    ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.landscape_outlined, size: 40, color: Colors.grey[400]))
                    : Icon(Icons.landscape_outlined, size: 40, color: Colors.grey[400]),
              ),
            ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(begin: Alignment.bottomCenter, end: Alignment.topCenter, colors: [Colors.black.withOpacity(0.6), Colors.transparent]),
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(farmName, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                    const SizedBox(height: 4),
                    Row(children: [const Icon(Icons.favorite, color: Colors.red, size: 14), const SizedBox(width: 4), Text('$followers', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600))]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔥 TRENDING CARD
  Widget _buildTrendingFarmCard(dynamic farm) {
    final farmName = farm['farm_name'] as String? ?? 'Ferme';
    final farmId = farm['farm_id'] as int? ?? 0;
    final ownerName = farm['owner_name'] as String? ?? 'Agriculteur';
    final imageUrl = farm['profile_image_farm'] as String?;
    final followers = farm['followers'] as int? ?? 0;

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
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(widget.isDarkMode ? 0.2 : 0.05), blurRadius: 6)],
        ),
        child: Row(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)), color: Colors.grey[300]),
              child: imageUrl != null && imageUrl.isNotEmpty
                  ? Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.landscape_outlined, size: 40, color: Colors.grey[400]))
                  : Icon(Icons.landscape_outlined, size: 40, color: Colors.grey[400]),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.red[400], size: 18),
                        const SizedBox(width: 6),
                        Expanded(child: Text(farmName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14), maxLines: 1, overflow: TextOverflow.ellipsis)),
                      ],
                    ),
                    Text(ownerName, style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white60 : Colors.black54)),
                    Row(children: [const Icon(Icons.favorite, color: Colors.red, size: 14), const SizedBox(width: 4), Text('$followers', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12))]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 🔧 HELPERS
  Widget _buildLoadingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primaryColor),
          const SizedBox(height: 16),
          Text('Chargement...', style: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 48, color: Colors.red[400]),
            const SizedBox(height: 16),
            const Text('Erreur', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(error, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: widget.isDarkMode ? Colors.white60 : Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFeedWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: _primaryColor),
          const SizedBox(height: 16),
          const Text('Aucun post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Suivez des agriculteurs pour voir les posts', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: widget.isDarkMode ? Colors.white60 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildEmptyExploreWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_outlined, size: 64, color: _accentColor),
          const SizedBox(height: 16),
          const Text('Aucune ferme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Revenez bientôt', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: widget.isDarkMode ? Colors.white60 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildEmptyTrendingWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_fire_department, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          const Text('Aucune tendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Bientôt disponible', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: widget.isDarkMode ? Colors.white60 : Colors.black54)),
        ],
      ),
    );
  }

  void _showSearchDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (context) => _SearchWidget(isDarkMode: widget.isDarkMode),
    );
  }

  void _showLikesDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: widget.isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('❤️ Vos aimes'),
        content: const Text('Liste de vos posts aimés'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }
}

class _SearchWidget extends StatefulWidget {
  final bool isDarkMode;

  const _SearchWidget({required this.isDarkMode});

  @override
  State<_SearchWidget> createState() => _SearchWidgetState();
}

class _SearchWidgetState extends State<_SearchWidget> {
  String _query = '';
  late Future<List<dynamic>> _searchFuture;

  @override
  void initState() {
    super.initState();
    _searchFuture = ApiService.searchFarmProfiles(query: '');
  }

  void _updateSearch() {
    setState(() {
      _searchFuture = ApiService.searchFarmProfiles(query: _query);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom, left: 16, right: 16, top: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('🔍 Rechercher', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          TextField(
            onChanged: (value) {
              _query = value;
              _updateSearch();
            },
            decoration: InputDecoration(hintText: 'Chercher...', prefixIcon: const Icon(Icons.search), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          ),
          const SizedBox(height: 16),
          FutureBuilder<List<dynamic>>(
            future: _searchFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator());
              }

              final results = snapshot.data ?? [];

              if (results.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(_query.isEmpty ? 'Tapez...' : 'Aucun résultat', style: TextStyle(color: widget.isDarkMode ? Colors.white60 : Colors.black54)),
                );
              }

              return SizedBox(
                height: 300,
                child: ListView.builder(
                  itemCount: results.length,
                  itemBuilder: (context, index) {
                    final farm = results[index];
                    return ListTile(
                      leading: const Icon(Icons.agriculture, color: Color(0xFF6B8E23)),
                      title: Text(farm['farm_name'] ?? 'Ferme'),
                      subtitle: Text(farm['location'] ?? ''),
                      onTap: () {
                        Navigator.pop(context);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => FarmDetailScreen(
                              farmId: farm['farm_id'] ?? 0,
                              farmData: farm,
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              );
            },
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
