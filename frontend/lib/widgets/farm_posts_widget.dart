import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/screens/create_farm_post_dialog.dart';
import 'package:mbaymi/widgets/comments_bottom_sheet.dart';

class FarmPostsWidget extends StatefulWidget {
  final int farmId;
  final String farmName;
  final bool isOwner;
  final int? livestockId;

  const FarmPostsWidget({
    Key? key,
    required this.farmId,
    required this.farmName,
    required this.isOwner,
    this.livestockId,
  }) : super(key: key);

  @override
  State<FarmPostsWidget> createState() => _FarmPostsWidgetState();
}

class _FarmPostsWidgetState extends State<FarmPostsWidget> {
  late Future<List<dynamic>> _postsFuture;
  List<Map<String, dynamic>> _posts = [];
  int _userId = 0;

  static const Color _primaryColor = Color(0xFF8B6B4D);

  @override
  void initState() {
    super.initState();
    _userId = AuthService.currentSession?.userId ?? 0;
    _postsFuture = _loadPosts();
  }

  Future<List<dynamic>> _loadPosts() async {
    try {
      final posts = widget.livestockId != null
          ? await ApiService.getLivestockPosts(widget.livestockId!, userId: _userId)
          : await ApiService.getFarmPosts(widget.farmId, userId: _userId);
      setState(() => _posts = List<Map<String, dynamic>>.from(posts));
      return posts;
    } catch (e) {
      print('Erreur chargement posts: $e');
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return ListView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        // Header avec bouton +
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Posts de la ferme',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
              ),
              if (widget.isOwner)
                FloatingActionButton(
                  mini: true,
                  backgroundColor: _primaryColor,
                  onPressed: () => _showCreatePostDialog(),
                  child: const Icon(Icons.add, color: Colors.white),
                ),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // Posts list
        FutureBuilder<List<dynamic>>(
          future: _postsFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(20),
                  child: CircularProgressIndicator(color: _primaryColor),
                ),
              );
            }

            if (_posts.isEmpty) {
              return Padding(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.image_not_supported, size: 48, color: Colors.grey),
                      const SizedBox(height: 12),
                      Text(
                        'Aucun post pour le moment',
                        style: TextStyle(color: Colors.grey[600]),
                      ),
                      if (widget.isOwner) ...[
                        const SizedBox(height: 12),
                        ElevatedButton.icon(
                          onPressed: _showCreatePostDialog,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('Créer un post'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                          ),
                        ),
                      ]
                    ],
                  ),
                ),
              );
            }

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: _posts.length,
              itemBuilder: (context, index) {
                final post = _posts[index];
                return _buildPostCard(post, index, cardColor, textColor, isDark);
              },
            );
          },
        ),
      ],
    );
  }

  Widget _buildPostCard(
    Map<String, dynamic> post,
    int index,
    Color cardColor,
    Color textColor,
    bool isDark,
  ) {
    final imageUrl = post['image_url'] as String?;
    final caption = post['caption'] as String? ?? '';
    final likesCount = post['likes_count'] ?? 0;
    final commentsCount = post['comments_count'] ?? 0;
    final sharesCount = post['shares_count'] ?? 0;
    final isLiked = post['is_liked'] ?? false;
    final postId = post['id'] as int;
    
    // Pricing info
    final postIntent = post['post_intent'] as String? ?? 'share';
    final price = post['price'] as num?;
    final unit = post['unit'] as String? ?? 'kg';

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image with price badge
          Stack(
            children: [
              if (imageUrl != null && imageUrl.isNotEmpty)
                Container(
                  height: 250,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    color: Colors.grey[300],
                  ),
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (c, e, s) => Icon(
                      Icons.image,
                      size: 40,
                      color: Colors.grey[400],
                    ),
                  ),
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
          ),

          // Caption and product info
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (caption.isNotEmpty)
                  Text(
                    caption,
                    style: TextStyle(fontSize: 14, height: 1.4, color: textColor),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),

          // Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => _toggleLike(postId, index, isLiked),
                  child: Row(
                    children: [
                      Icon(
                        isLiked ? Icons.favorite : Icons.favorite_border,
                        size: 20,
                        color: isLiked ? Colors.red : _primaryColor,
                      ),
                      const SizedBox(width: 4),
                      Text('$likesCount'),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Delete button for owner of farm or author of post
                if (widget.isOwner || (post['user_id'] != null && post['user_id'] == _userId))
                  IconButton(
                    icon: const Icon(Icons.delete_outline, size: 20, color: Colors.redAccent),
                    onPressed: () => _confirmDelete(postId, index),
                    tooltip: 'Supprimer',
                  ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (context) => CommentsBottomSheet(
                        postId: postId,
                        currentUserId: _userId,
                      ),
                    );
                  },
                  child: Row(
                    children: [
                      Icon(Icons.chat_bubble_outline, size: 20, color: _primaryColor),
                      const SizedBox(width: 4),
                      Text('$commentsCount'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: () => _sharePost(postId),
                  child: Row(
                    children: [
                      Icon(Icons.share_outlined, size: 20, color: _primaryColor),
                      const SizedBox(width: 4),
                      Text('$sharesCount'),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Future<void> _confirmDelete(int postId, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer le post'),
        content: const Text('Voulez-vous vraiment supprimer ce post ? Cette action est irréversible.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Supprimer', style: TextStyle(color: Colors.red))),
        ],
      ),
    );

    if (confirmed == true) {
      await _deletePost(postId, index);
    }
  }

  Future<void> _deletePost(int postId, int index) async {
    try {
      final userId = _userId;
      await ApiService.deleteFarmPost(postId, userId);

      setState(() {
        _posts.removeAt(index);
      });

      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Post supprimé'), backgroundColor: Colors.green));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur suppression: $e'), backgroundColor: Colors.red));
    }
  }

  Future<void> _toggleLike(int postId, int index, bool isLiked) async {
    try {
      // Update UI optimistically
      setState(() {
        _posts[index]['is_liked'] = !isLiked;
        _posts[index]['likes_count'] = isLiked
            ? (_posts[index]['likes_count'] ?? 0) - 1
            : (_posts[index]['likes_count'] ?? 0) + 1;
      });

      // API call in background
      if (isLiked) {
        await ApiService.unlikeFarmPost(postId);
      } else {
        await ApiService.likeFarmPost(postId);
      }
    } catch (e) {
      // Revert on error
      setState(() {
        _posts[index]['is_liked'] = isLiked;
        _posts[index]['likes_count'] = isLiked
            ? (_posts[index]['likes_count'] ?? 0) + 1
            : (_posts[index]['likes_count'] ?? 0) - 1;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _sharePost(int postId) async {
    try {
      await ApiService.shareFarmPost(postId);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('✅ Partagé'), backgroundColor: _primaryColor),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red),
      );
    }
  }

  void _showCreatePostDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => CreateFarmPostDialog(
          farmId: widget.farmId,
          farmName: widget.farmName,
          onPostCreated: () {
            setState(() {
              _postsFuture = _loadPosts();
            });
          },
          livestockId: widget.livestockId,
        ),
      ),
    );
  }
}
