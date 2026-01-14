import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/screens/post_detail_screen.dart';
import 'package:mbaymi/screens/farm_detail_screen.dart';
import 'package:mbaymi/screens/profile_detail_screen.dart';
import 'package:mbaymi/screens/animal_detail_screen.dart';
import 'package:mbaymi/widgets/comments_bottom_sheet.dart';

class SocialFeedScreen extends StatefulWidget {
  final bool isDarkMode;

  const SocialFeedScreen({Key? key, this.isDarkMode = false}) : super(key: key);

  @override
  State<SocialFeedScreen> createState() => _SocialFeedScreenState();
}

class _SocialFeedScreenState extends State<SocialFeedScreen> {
  int _userId = 0;
  late StreamSubscription<void> _farmPostSub;
  
  // ✅ STORE FEED DATA IN STATE - NOT REBUILT ON EACH setState()
  late Future<Map<String, dynamic>> _feedFuture;
  List<Map<String, dynamic>> _combinedItems = [];
  
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
    // Listen for farm post creations and refresh feed
    _farmPostSub = ApiService.onFarmPostCreated.listen((_) {
      if (mounted) {
        setState(() {
          _feedFuture = _loadCombinedFeed();
        });
      }
    });
    // Listen for follow/unfollow changes
    ApiService.onFollowChanged.listen((payload) {
      if (mounted) {
        setState(() {
          _feedFuture = _loadCombinedFeed();
        });
      }
    });
  }

  @override
  void dispose() {
    _farmPostSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final isDark = isDarkMode;
    final bgColor = isDark ? _bgDark : _bgLight;

    return Scaffold(
      backgroundColor: bgColor,
      body: _buildFeedTab(isDarkMode),
    );
  }

  // 📰 TAB 1: FEED (Connecté ou pas)
  Widget _buildFeedTab(bool isDarkMode) {
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
            return _buildLoadingWidget(isDarkMode);
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString(), isDarkMode);
          }

          final data = snapshot.data ?? {};
          final rawItems = data['items'] as List<dynamic>? ?? [];
          _combinedItems = rawItems.cast<Map<String, dynamic>>();
          final combinedItems = _combinedItems;

          if (combinedItems.isEmpty) {
            return _buildEmptyFeedWidget(isDarkMode);
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(12),
            itemCount: combinedItems.length + 1,
            itemBuilder: (context, index) {
              // First item: subscriptions section
              if (index == 0) {
                return _buildSubscriptionsSection(isDarkMode);
              }
              
              final item = combinedItems[index - 1];
              if (item['type'] == 'farm_post') {
                return _buildFarmPostCard(item['data'], item, isDarkMode);
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
      List<dynamic> items = [];

      // Charger les posts d'images des fermes (farm posts)
      try {
        final farmPosts = await ApiService.getFarmPostsFeed(userId: _userId);
        items.addAll(farmPosts.map((post) => {
          'type': 'farm_post',
          'data': post,
          'timestamp': DateTime.tryParse(post['created_at'] ?? '') ?? DateTime.now(),
        }));
      } catch (e) {
        print('Erreur chargement farm posts: $e');
      }

      // Trier par date décroissante
      items.sort((a, b) => (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      return {'items': items};
    } catch (e) {
      throw Exception('Erreur chargement: $e');
    }
  }

  // 🔍 TAB 2: EXPLORE
  // ignore: unused_element
  Widget _buildExploreTab(bool isDarkMode) {
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
            return _buildLoadingWidget(isDarkMode);
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString(), isDarkMode);
          }

          final farms = snapshot.data ?? [];

          if (farms.isEmpty) {
            return _buildEmptyExploreWidget(isDarkMode);
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
            itemBuilder: (context, index) => _buildExploreFarmCard(farms[index], isDarkMode),
          );
        },
      ),
    );
  }

  // 🔥 TAB 3: TRENDING
  // ignore: unused_element
  Widget _buildTrendingTab(bool isDarkMode) {
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
            return _buildLoadingWidget(isDarkMode);
          }

          if (snapshot.hasError) {
            return _buildErrorWidget(snapshot.error.toString(), isDarkMode);
          }

          final farms = snapshot.data ?? [];

          if (farms.isEmpty) {
            return _buildEmptyTrendingWidget(isDarkMode);
          }

          return ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(8),
            itemCount: farms.length,
            itemBuilder: (context, index) => _buildTrendingFarmCard(farms[index], isDarkMode),
          );
        },
      ),
    );
  }

  // 🏞️ FARM POST CARD (Images avec caption)
  Widget _buildFarmPostCard(dynamic post, Map<String, dynamic> itemWrapper, bool isDarkMode) {
    final farmName = post['farm_name'] as String? ?? 'Ferme';
    final ownerName = post['owner_name'] as String? ?? 'Agriculteur';
    final caption = post['caption'] as String? ?? '';
    final imageUrl = post['image_url'] as String?;
    final postId = post['id'] as int? ?? 0;
    final farmId = post['farm_id'] as int? ?? 0;
    final livestockId = post['livestock_id'] as int?;
    final userId = post['user_id'] as int? ?? 0;
    final likesCount = post['likes_count'] ?? 0;
    final commentsCount = post['comments_count'] ?? 0;
    final sharesCount = post['shares_count'] ?? 0;
    final createdAt = DateTime.tryParse(post['created_at'] as String? ?? '') ?? DateTime.now();
    final daysAgo = DateTime.now().difference(createdAt).inDays;
    final timeText = daysAgo == 0 ? 'Aujourd\'hui' : daysAgo == 1 ? 'Hier' : '$daysAgo j';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 En-tête (clickable profil et ferme)
          GestureDetector(
            onTap: () {
              // Clicking anywhere in the header navigates to owner profile (read-only)
              if (userId > 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileDetailScreen(
                      userId: userId,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                );
              }
            },
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                      backgroundColor: _primaryColor,
                      backgroundImage: (post['owner_profile_image'] != null && (post['owner_profile_image'] as String).isNotEmpty)
                          ? NetworkImage(post['owner_profile_image'] as String)
                          : null,
                      child: (post['owner_profile_image'] == null || (post['owner_profile_image'] as String).isEmpty)
                          ? Text(
                              ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            )
                          : null,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Si c'est un animal (livestockId existe), naviguer vers AnimalDetailScreen
                                  if (livestockId != null && livestockId > 0) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AnimalDetailScreen(
                                          livestockId: livestockId,
                                          animal: post,
                                          isDarkMode: isDarkMode,
                                        ),
                                      ),
                                    );
                                  } else if (farmId > 0) {
                                    // Click on farm name navigates to farm detail
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => FarmDetailScreen(
                                          farmId: farmId,
                                          farmData: post,
                                          isDarkMode: isDarkMode,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Text(
                                  farmName,
                                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF8B6B4D)),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ),
                            const Text('🌾', style: TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'par $ownerName • $timeText',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDarkMode ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 🖼️ Image
          if (imageUrl != null && imageUrl.isNotEmpty)
            Container(
              height: 300,
              width: double.infinity,
              color: Colors.grey[300],
              child: Image.network(imageUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.image, size: 40, color: Colors.grey[400])),
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
              child: Center(child: Icon(Icons.image_outlined, size: 48, color: isDarkMode ? Colors.white30 : Colors.black12)),
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
                        await ApiService.unlikeFarmPost(postId);
                      } else {
                        await ApiService.likeFarmPost(postId);
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
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => CommentsBottomSheet(
                        postId: post['id'],
                        currentUserId: _userId,
                        isDarkMode: isDarkMode,
                      ),
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
                      await ApiService.shareFarmPost(postId);
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

          // 📝 Caption
          if (caption.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Text(
                caption,
                style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white70 : Colors.black87, height: 1.4),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // 📱 POST CARD
  // ignore: unused_element
  Widget _buildPostCard(dynamic post, Map<String, dynamic> itemWrapper, bool isDarkMode) {
    final farmName = post['farm_name'] as String? ?? 'Ferme';
    final ownerName = post['owner_name'] as String? ?? 'Agriculteur';
    final title = post['title'] as String? ?? '';
    final description = post['description'] as String?;
    final photoUrl = post['photo_url'] as String? ?? post['image_url'] as String?;
    final postType = post['post_type'] as String? ?? 'crop_update';
    final createdAt = DateTime.tryParse(post['created_at'] as String? ?? '') ?? DateTime.now();
    final postId = post['id'] as int? ?? 0;
    final likesCount = post['likes_count'] ?? 0;
    final commentsCount = post['comments_count'] ?? 0;
    final sharesCount = post['shares_count'] ?? 0;
    
    // Pricing info
    final postIntent = post['post_intent'] as String? ?? 'share';
    final price = post['price'] as num?;
    final unit = post['unit'] as String? ?? 'kg';

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
              isDarkMode: isDarkMode,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
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
                            color: isDarkMode ? Colors.white54 : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Image
            if (photoUrl != null && photoUrl.isNotEmpty)
              Stack(
                children: [
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: Colors.grey[300],
                    child: Image.network(photoUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.image, size: 40, color: Colors.grey[400])),
                  ),
                  // Price badge
                  if (postIntent == 'sell' && price != null)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _primaryColor,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 4,
                            ),
                          ],
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.local_atm, color: Colors.white, size: 14),
                            const SizedBox(width: 4),
                            Text(
                              '${price.toStringAsFixed(0)} CFA/$unit',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
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
                child: Center(child: Icon(Icons.image_outlined, size: 48, color: isDarkMode ? Colors.white30 : Colors.black12)),
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
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (context) => CommentsBottomSheet(
                          postId: post['id'],
                          currentUserId: _userId,
                          isDarkMode: isDarkMode,
                        ),
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
                        style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white70 : Colors.black87, height: 1.4),
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
  // ignore: unused_element
  Widget _buildAnimalCard(dynamic animal, Map<String, dynamic> itemWrapper, bool isDarkMode) {
    final animalType = animal['animal_type'] as String? ?? 'Animal';
    final breed = animal['breed'] as String? ?? 'Race';
    final quantity = animal['quantity'] as int? ?? 1;
    final userName = animal['user_name'] as String? ?? 'Éleveur';
    final userProfileImage = animal['user_profile_image'] as String?;
    final userId = animal['user_id'] as int? ?? 0;
    final animalId = animal['id'] as int? ?? 0;
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
        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 👤 En-tête (clickable profil et animal)
          GestureDetector(
            onTap: () {
              // Clicking anywhere in the header navigates to owner profile (read-only)
              if (userId > 0) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProfileDetailScreen(
                      userId: userId,
                      isDarkMode: isDarkMode,
                    ),
                  ),
                );
              }
            },
            child: Padding(
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
                            Expanded(
                              child: GestureDetector(
                                onTap: () {
                                  // Click on animal name navigates to animal detail
                                  if (animalId > 0) {
                                    Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => AnimalDetailScreen(
                                          livestockId: animalId,
                                          animal: animal,
                                          isDarkMode: isDarkMode,
                                        ),
                                      ),
                                    );
                                  }
                                },
                                child: Text('$animalType - $breed', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: Color(0xFF8B6B4D)), maxLines: 1, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                            Text(emoji, style: const TextStyle(fontSize: 16)),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text('par $userName • $timeText', style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white54 : Colors.black54)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (firstPhotoUrl != null && firstPhotoUrl.isNotEmpty)
            Container(height: 300, width: double.infinity, color: Colors.grey[300], child: Image.network(firstPhotoUrl, fit: BoxFit.cover, errorBuilder: (c, e, s) => Icon(Icons.image, size: 40, color: Colors.grey[400])))
          else
            Container(height: 200, width: double.infinity, decoration: BoxDecoration(gradient: LinearGradient(colors: [_primaryColor.withOpacity(0.2), _accentColor.withOpacity(0.2)])), child: Center(child: Icon(Icons.pets_outlined, size: 48, color: isDarkMode ? Colors.white30 : Colors.black12))),
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
                      } else {
                        await ApiService.likeLivestock(animal['id'] ?? 0);
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
                      const SnackBar(content: Text('Les commentaires ne sont pas disponibles pour les animaux'), backgroundColor: _primaryColor),
                    );
                  },
                  child: Row(children: [Icon(Icons.chat_bubble_outline, size: 20, color: Colors.grey[400]), const SizedBox(width: 4), Text('${animal['comments_count'] ?? 0}')]),
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
            child: Row(children: [Text('Qty: $quantity', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDarkMode ? Colors.white : Colors.black87)), const SizedBox(width: 16), Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: _getHealthStatusColor(healthStatus).withOpacity(0.2), borderRadius: BorderRadius.circular(8)), child: Text(healthStatus, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _getHealthStatusColor(healthStatus))))]),
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
  Widget _buildExploreFarmCard(dynamic farm, bool isDarkMode) {
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
              isDarkMode: isDarkMode,
            ),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05), blurRadius: 6)],
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
  Widget _buildTrendingFarmCard(dynamic farm, bool isDarkMode) {
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
              isDarkMode: isDarkMode,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05), blurRadius: 6)],
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
                    Text(ownerName, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white60 : Colors.black54)),
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
  Widget _buildLoadingWidget(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: _primaryColor),
          const SizedBox(height: 16),
          Text('Chargement...', style: TextStyle(color: isDarkMode ? Colors.white60 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(String error, bool isDarkMode) {
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
            Text(error, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, color: isDarkMode ? Colors.white60 : Colors.black54)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyFeedWidget(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.chat_bubble_outline, size: 64, color: _primaryColor),
          const SizedBox(height: 16),
          const Text('Aucun post', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Suivez des agriculteurs pour voir les posts', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white60 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildEmptyExploreWidget(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.explore_outlined, size: 64, color: _accentColor),
          const SizedBox(height: 16),
          const Text('Aucune ferme', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Revenez bientôt', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white60 : Colors.black54)),
        ],
      ),
    );
  }

  Widget _buildEmptyTrendingWidget(bool isDarkMode) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.local_fire_department, size: 64, color: Colors.red[400]),
          const SizedBox(height: 16),
          const Text('Aucune tendance', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Text('Bientôt disponible', textAlign: TextAlign.center, style: TextStyle(fontSize: 13, color: isDarkMode ? Colors.white60 : Colors.black54)),
        ],
      ),
    );
  }

  // ignore: unused_element
  void _showSearchDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    showModalBottomSheet(
      context: context,
      backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      isScrollControlled: true,
      builder: (context) => _SearchWidget(isDarkMode: isDarkMode),
    );
  }

  // ignore: unused_element
  void _showLikesDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
        title: const Text('❤️ Vos aimes'),
        content: const Text('Liste de vos posts aimés'),
        actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Fermer'))],
      ),
    );
  }

  // 📝 Build Subscriptions Section (affiche les posts des abonnements en carrousel)
  Widget _buildSubscriptionsSection(bool isDarkMode) {
    return FutureBuilder<List<dynamic>>(
      future: _userId > 0 ? ApiService.getFarmPostsFeed(userId: _userId) : Future.value(<dynamic>[]),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const SizedBox.shrink();
        if (snapshot.hasError) return const SizedBox.shrink();
        
        final posts = snapshot.data ?? [];
        if (posts.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Text(
                'Abonnements',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: isDarkMode ? Colors.white : const Color(0xFF1A1A1A),
                ),
              ),
            ),
            SizedBox(
              height: 220,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 0),
                itemCount: posts.take(10).length,
                itemBuilder: (context, index) {
                  final post = posts[index];
                  final ownerName = post['owner_name'] as String? ?? 'Agriculteur';
                  final farmName = post['farm_name'] as String? ?? 'Ferme';
                  final imageUrl = post['image_url'] as String?;
                  final userId = post['user_id'] as int? ?? 0;

                  return GestureDetector(
                    onTap: () {
                      if (userId > 0) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ProfileDetailScreen(userId: userId, isDarkMode: isDarkMode),
                          ),
                        );
                      }
                    },
                    child: Container(
                      width: 160,
                      margin: const EdgeInsets.only(right: 12),
                      decoration: BoxDecoration(
                        color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(isDarkMode ? 0.2 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Stack(
                        children: [
                          // Image de fond
                          if (imageUrl != null && imageUrl.isNotEmpty)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                imageUrl,
                                width: double.infinity,
                                height: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  color: _primaryColor.withOpacity(0.1),
                                  child: const Icon(Icons.image_not_supported_outlined),
                                ),
                              ),
                            )
                          else
                            Container(
                              decoration: BoxDecoration(
                                color: _primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.image_outlined),
                            ),

                          // Gradient overlay
                          Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                          ),

                          // Contenu en bas
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    farmName,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'par $ownerName',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: Colors.white70,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        );
      },
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
                              isDarkMode: widget.isDarkMode,
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
