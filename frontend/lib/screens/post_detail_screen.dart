import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/utils/app_colors.dart';

class PostDetailScreen extends StatefulWidget {
  final int postId;
  final Map<String, dynamic> postData;
  final bool isDarkMode;

  const PostDetailScreen({
    super.key,
    required this.postId,
    required this.postData,
    required this.isDarkMode,
  });

  @override
  State<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends State<PostDetailScreen> {
  late Future<List<dynamic>> _commentsFuture;
  final TextEditingController _commentController = TextEditingController();
  bool _isLiked = false;
  int _likesCount = 0;
  int _commentsCount = 0;

  @override
  void initState() {
    super.initState();
    _likesCount = widget.postData['likes_count'] ?? 0;
    _commentsCount = widget.postData['comments_count'] ?? 0;
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
      _showSnackBar('Erreur lors de l\'action', isError: true);
    }
  }

  Future<void> _postComment() async {
    if (_commentController.text.trim().isEmpty) return;

    try {
      await ApiService.commentOnPost(
        postId: widget.postId,
        content: _commentController.text.trim(),
      );

      _commentController.clear();
      setState(() {
        _commentsCount++;
        _commentsFuture = ApiService.getPostComments(widget.postId);
      });

      _showSnackBar('Commentaire ajouté', isError: false);
    } catch (e) {
      _showSnackBar('Erreur: $e', isError: true);
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message.toUpperCase(),
          style: const TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w300,
            letterSpacing: 1.5,
          ),
        ),
        backgroundColor: isError ? Colors.red.shade400 : Colors.black87,
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      ),
    );
  }

  void _deletePost() async {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF0A0A0A) : Colors.white,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'SUPPRIMER LE POST',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.0,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        content: Text(
          'Êtes-vous sûr de vouloir supprimer ce post?',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w300,
            color: isDark ? Colors.white70 : Colors.black54,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'ANNULER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
                color: isDark ? Colors.white60 : Colors.black54,
              ),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                final userId = AuthService.currentSession?.userId ?? 0;
                await ApiService.deleteFarmPost(widget.postId, userId);
                if (mounted) {
                  _showSnackBar('Post supprimé');
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted) Navigator.pop(context);
                  });
                }
              } catch (e) {
                _showSnackBar('Erreur: $e', isError: true);
              }
            },
            child: const Text(
              'SUPPRIMER',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w300,
                letterSpacing: 1.5,
                color: Colors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? const Color(0xFF0A0A0A) : AppColors.lightBg;
    final currentUserId = AuthService.currentSession?.userId ?? 0;
    final postOwnerId = widget.postData['user_id'] as int? ?? 0;
    final isOwner = currentUserId == postOwnerId && currentUserId > 0;

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
            : 'Il y a $daysAgo jours';

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: isDark ? Colors.white : Colors.black87,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'POST',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w300,
            letterSpacing: 2.5,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        centerTitle: true,
        actions: isOwner
            ? [
                IconButton(
                  icon: Icon(
                    Icons.delete_outline,
                    color: Colors.red.shade400,
                    size: 20,
                  ),
                  onPressed: _deletePost,
                ),
              ]
            : null,
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image
                  if (photoUrl != null && photoUrl.isNotEmpty)
                    Container(
                      width: double.infinity,
                      height: 400,
                      color: isDark ? const Color(0xFF151515) : const Color(0xFFF5F5F5),
                      child: Image.network(
                        photoUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Center(
                          child: Icon(
                            Icons.image_outlined,
                            size: 48,
                            color: isDark ? Colors.white12 : Colors.black12,
                          ),
                        ),
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 1,
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                            ),
                          );
                        },
                      ),
                    ),

                  // Contenu
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Métadonnées
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                farmName.toUpperCase(),
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 1.5,
                                  color: isDark ? Colors.white38 : Colors.black38,
                                ),
                              ),
                            ),
                            Text(
                              timeText.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.2,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Titre
                        if (title.isNotEmpty)
                          Text(
                            title.toUpperCase(),
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 2.0,
                              color: isDark ? Colors.white : Colors.black87,
                              height: 1.4,
                            ),
                          ),

                        if (title.isNotEmpty && description != null)
                          const SizedBox(height: 16),

                        // Description
                        if (description != null && description.isNotEmpty)
                          Text(
                            description,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w300,
                              letterSpacing: 0.3,
                              color: isDark ? Colors.white70 : Colors.black87,
                              height: 1.6,
                            ),
                          ),

                        const SizedBox(height: 20),

                        // Auteur
                        Text(
                          'PAR $ownerName'.toUpperCase(),
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.5,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Actions
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                          width: 1,
                        ),
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        _buildActionButton(
                          icon: _isLiked ? Icons.favorite : Icons.favorite_border,
                          label: '$_likesCount',
                          isDark: isDark,
                          isActive: _isLiked,
                          onTap: _toggleLike,
                        ),
                        const SizedBox(width: 32),
                        _buildActionButton(
                          icon: Icons.chat_bubble_outline,
                          label: '$_commentsCount',
                          isDark: isDark,
                          isActive: false,
                          onTap: () {},
                        ),
                        const SizedBox(width: 32),
                        _buildActionButton(
                          icon: Icons.share_outlined,
                          label: '${widget.postData['shares_count'] ?? 0}',
                          isDark: isDark,
                          isActive: false,
                          onTap: () {},
                        ),
                      ],
                    ),
                  ),

                  // Section commentaires
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                    child: Text(
                      'COMMENTAIRES',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 2.0,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Liste des commentaires
                  FutureBuilder<List<dynamic>>(
                    future: _commentsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 1,
                                color: isDark ? Colors.white24 : Colors.black12,
                              ),
                            ),
                          ),
                        );
                      }

                      final comments = snapshot.data ?? [];
                      if (comments.isEmpty) {
                        return Padding(
                          padding: const EdgeInsets.all(32),
                          child: Center(
                            child: Text(
                              'AUCUN COMMENTAIRE',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w300,
                                letterSpacing: 1.5,
                                color: isDark ? Colors.white24 : Colors.black26,
                              ),
                            ),
                          ),
                        );
                      }

                      return ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(horizontal: 24),
                        itemCount: comments.length,
                        separatorBuilder: (_, __) => Divider(
                          height: 1,
                          color: isDark
                              ? Colors.white.withOpacity(0.05)
                              : Colors.black.withOpacity(0.05),
                        ),
                        itemBuilder: (context, index) {
                          final comment = comments[index];
                          return _buildCommentTile(comment, isDark);
                        },
                      );
                    },
                  ),

                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),

          // Barre de commentaire fixe en bas
          Container(
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                top: BorderSide(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.black.withOpacity(0.05),
                  width: 1,
                ),
              ),
            ),
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).padding.bottom + 16,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w300,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                    decoration: InputDecoration(
                      hintText: 'Ajouter un commentaire',
                      hintStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        color: isDark ? Colors.white24 : Colors.black26,
                      ),
                      enabledBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark
                              ? Colors.white.withOpacity(0.1)
                              : Colors.black.withOpacity(0.1),
                          width: 1,
                        ),
                      ),
                      focusedBorder: UnderlineInputBorder(
                        borderSide: BorderSide(
                          color: isDark ? Colors.white : Colors.black87,
                          width: 1,
                        ),
                      ),
                      contentPadding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                GestureDetector(
                  onTap: _postComment,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.black87,
                      border: Border.all(
                        color: isDark
                            ? Colors.white.withOpacity(0.1)
                            : Colors.black.withOpacity(0.1),
                        width: 1,
                      ),
                    ),
                    child: const Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 16,
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required bool isDark,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isActive
                ? Colors.red
                : (isDark ? Colors.white70 : Colors.black87),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w300,
              letterSpacing: 0.5,
              color: isActive
                  ? Colors.red
                  : (isDark ? Colors.white70 : Colors.black87),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCommentTile(Map<String, dynamic> comment, bool isDark) {
    final userName = comment['user_name'] ?? 'Utilisateur';
    final content = comment['content'] ?? '';
    final createdAt = DateTime.tryParse(comment['created_at'] ?? '') ?? DateTime.now();
    final daysAgo = DateTime.now().difference(createdAt).inDays;
    final timeText = daysAgo == 0
        ? 'Maintenant'
        : daysAgo == 1
            ? 'Hier'
            : 'Il y a $daysAgo j';

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.1)
                      : Colors.black.withOpacity(0.1),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : Colors.black.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: Center(
                  child: Text(
                    userName.isNotEmpty ? userName[0].toUpperCase() : '?',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
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
                        Text(
                          userName.toUpperCase(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 1.2,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '•',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          timeText,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w300,
                            letterSpacing: 0.5,
                            color: isDark ? Colors.white24 : Colors.black26,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      content,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                        letterSpacing: 0.3,
                        color: isDark ? Colors.white70 : Colors.black87,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}