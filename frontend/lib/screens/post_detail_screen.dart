import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/utils/app_colors.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  final Map<String, dynamic> postData;
  final bool isDarkMode;

  const PostDetailScreen({
    Key? key,
    required this.postId,
    required this.postData,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  // ignore: unused_field
  late Future<Map<String, dynamic>> _postDetailFuture;
  late Future<List<dynamic>> _commentsFuture;
  final TextEditingController _commentController = TextEditingController();
  bool _isLiked = false;
  int _likesCount = 0;
  int _commentsCount = 0;

  static const Color _primaryColor = Color(0xFF8B6B4D);
  // ignore: unused_field
  static const Color _primaryLight = Color(0xFFA58A6D);
  // ignore: unused_field
  static const Color _accentColor = Color(0xFFC4A484);

  @override
  void initState() {
    super.initState();
    _likesCount = widget.postData['likes_count'] ?? 0;
    _commentsCount = widget.postData['comments_count'] ?? 0;
    _postDetailFuture = Future.value(widget.postData);
    _commentsFuture = ApiService.getPostComments(widget.postId);
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _toggleLike() async {
    try {
      if (_isLiked) {
        await ApiService.unlikePost(widget.postId);
        setState(() {
          _isLiked = false;
          _likesCount--;
        });
      } else {
        await ApiService.likePost(widget.postId);
        setState(() {
          _isLiked = true;
          _likesCount++;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.isEmpty) return;

    try {
      await ApiService.commentOnPost(
        postId: widget.postId,
        content: _commentController.text,
      );

      _commentController.clear();
      setState(() {
        _commentsCount++;
        _commentsFuture = ApiService.getPostComments(widget.postId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commentaire ajouté ✅'),
          backgroundColor: _primaryColor,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFFAFAFA);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : AppColors.lightBg;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryTextColor = isDark ? Colors.white60 : Colors.black54;

    final postTypeEmoji = {
      'crop_update': '🌱',
      'harvest_result': '🌾',
      'problem_report': '🚨',
      'tip': '💡',
    };

    final postType = widget.postData['post_type'] ?? 'crop_update';
    final emoji = postTypeEmoji[postType] ?? '📝';
    final title = widget.postData['title'] ?? '';
    final description = widget.postData['description'];
    final photoUrl = widget.postData['photo_url'];
    final farmName = widget.postData['farm_name'] ?? 'Ferme';
    final ownerName = widget.postData['owner_name'] ?? 'Agriculteur';
    final createdAt = DateTime.tryParse(widget.postData['created_at'] ?? '') ?? DateTime.now();
    final daysAgo = DateTime.now().difference(createdAt).inDays;
    final timeText = daysAgo == 0
        ? 'Aujourd\'hui'
        : daysAgo == 1
            ? 'Hier'
            : '$daysAgo jours';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: cardColor,
        elevation: 0.5,
        iconTheme: IconThemeData(color: textColor),
        title: Text(
          'Post Détail',
          style: TextStyle(color: textColor, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 📋 En-tête du post
            Container(
              color: cardColor,
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profil
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 24,
                        backgroundColor: _primaryColor,
                        child: Text(
                          ownerName.isNotEmpty ? ownerName[0].toUpperCase() : '?',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
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
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 15,
                                      color: textColor,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Text(
                                  emoji,
                                  style: const TextStyle(fontSize: 18),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'par $ownerName • $timeText',
                              style: TextStyle(
                                fontSize: 12,
                                color: secondaryTextColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Titre
                  if (title.isNotEmpty)
                    Text(
                      title,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                        color: textColor,
                      ),
                    ),
                  
                  if (title.isNotEmpty && description != null)
                    const SizedBox(height: 12),
                  
                  // Description
                  if (description != null && description.isNotEmpty)
                    Text(
                      description,
                      style: TextStyle(
                        fontSize: 14,
                        color: textColor,
                        height: 1.5,
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 8),

            // 🖼️ Image
            if (photoUrl != null && photoUrl.isNotEmpty)
              Container(
                width: double.infinity,
                height: 350,
                color: Colors.grey[300],
                child: Image.network(
                  photoUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    color: _primaryColor.withOpacity(0.1),
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        size: 64,
                        color: _primaryColor.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // ❤️ Actions
            Container(
              color: cardColor,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  _buildActionButton(
                    icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                    label: '$_likesCount',
                    color: _isLiked ? Colors.red : textColor,
                    onTap: _toggleLike,
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: Icons.chat_bubble_outline,
                    label: '$_commentsCount',
                    color: textColor,
                    onTap: () {},
                  ),
                  const SizedBox(width: 24),
                  _buildActionButton(
                    icon: Icons.share_outlined,
                    label: '${widget.postData['shares_count'] ?? 0}',
                    color: textColor,
                    onTap: () {},
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 💬 Commentaires
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Commentaires',
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 16,
                  color: textColor,
                ),
              ),
            ),

            const SizedBox(height: 12),

            // Liste des commentaires
            FutureBuilder<List<dynamic>>(
              future: _commentsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _primaryColor,
                      ),
                    ),
                  );
                }

                final comments = snapshot.data ?? [];
                if (comments.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: Text(
                        'Aucun commentaire pour l\'instant',
                        style: TextStyle(color: secondaryTextColor),
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: comments.length,
                  itemBuilder: (context, index) {
                    final comment = comments[index];
                    return _buildCommentTile(comment, cardColor, textColor, secondaryTextColor);
                  },
                );
              },
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      bottomSheet: Container(
        color: cardColor,
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 12,
          bottom: 12,
        ),
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _commentController,
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Ajouter un commentaire...',
                  hintStyle: TextStyle(color: secondaryTextColor),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide(color: secondaryTextColor),
                  ),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                ),
              ),
            ),
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _postComment,
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: _primaryColor,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.send,
                  color: Colors.white,
                  size: 20,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(
    Map<String, dynamic> comment,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    final userName = comment['user_name'] ?? 'Utilisateur';
    final content = comment['content'] ?? '';
    final createdAt = DateTime.tryParse(comment['created_at'] ?? '') ?? DateTime.now();
    final daysAgo = DateTime.now().difference(createdAt).inDays;
    final timeText = daysAgo == 0 ? 'Maintenant' : daysAgo == 1 ? 'Hier' : '$daysAgo j';

    return Container(
      margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: widget.isDarkMode ? const Color(0xFF262626) : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: _primaryColor,
                child: Text(
                  userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      timeText,
                      style: TextStyle(
                        fontSize: 11,
                        color: secondaryTextColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: TextStyle(
              fontSize: 13,
              color: textColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
