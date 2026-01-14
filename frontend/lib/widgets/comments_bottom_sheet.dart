import 'package:flutter/material.dart';
import '../services/api_service.dart';

class CommentsBottomSheet extends StatefulWidget {
  final int postId;
  final int currentUserId;
  final bool isDarkMode;

  const CommentsBottomSheet({
    Key? key,
    required this.postId,
    required this.currentUserId,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  late TextEditingController _commentController;
  List<dynamic> _comments = [];
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  void _loadComments() async {
    try {
      final comments = await ApiService.getPostComments(widget.postId);
      setState(() {
        _comments = comments;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur chargement commentaires: $e')),
        );
      }
    }
  }

  void _submitComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty) return;

    setState(() => _isSubmitting = true);

    try {
      await ApiService.addComment(widget.postId, text, widget.currentUserId);
      _commentController.clear();
      _loadComments();
      setState(() => _isSubmitting = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commentaire ajouté')),
        );
      }
    } catch (e) {
      setState(() => _isSubmitting = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    }
  }

  void _deleteComment(int commentId) async {
    try {
      await ApiService.deleteComment(widget.postId, commentId, widget.currentUserId);
      _loadComments();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Commentaire supprimé')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur suppression: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final secondaryColor = isDark ? Colors.white60 : Colors.grey[600];
    final borderColor = isDark ? Colors.white12 : Colors.grey[300];

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: borderColor!),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Commentaires',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(color: textColor),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textColor),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          // Comments list
          Expanded(
            child: _isLoading
                ? Center(child: CircularProgressIndicator(color: Theme.of(context).primaryColor))
                : _comments.isEmpty
                    ? Center(
                        child: Text(
                          'Aucun commentaire',
                          style: TextStyle(color: secondaryColor),
                        ),
                      )
                    : ListView.builder(
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];
                          final isAuthor = comment['user_id'] == widget.currentUserId;

                          return Padding(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // User avatar
                                CircleAvatar(
                                  radius: 20,
                                  backgroundColor: isDark ? Colors.grey[800] : null,
                                  backgroundImage: comment['user_profile_image'] != null
                                    ? NetworkImage(comment['user_profile_image'])
                                    : null,
                                  child: comment['user_profile_image'] == null
                                    ? Icon(Icons.person, color: isDark ? Colors.white70 : null)
                                    : null,
                                ),
                                const SizedBox(width: 12),

                                // Comment content
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        comment['user_name'] ?? 'Utilisateur',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(comment['comment'] ?? '', style: TextStyle(color: textColor)),
                                      const SizedBox(height: 4),
                                      Text(
                                        _formatTime(comment['created_at']),
                                        style: TextStyle(
                                          color: secondaryColor,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),

                                // Delete button (only for author)
                                if (isAuthor)
                                  PopupMenuButton(
                                    itemBuilder: (context) => [
                                      PopupMenuItem(
                                        child: const Text('Supprimer'),
                                        onTap: () => _deleteComment(comment['id']),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
          ),

          // Comment input
          Container(
            padding: EdgeInsets.only(
              left: 16,
              right: 16,
              top: 12,
              bottom: MediaQuery.of(context).viewInsets.bottom + 12,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(
                top: BorderSide(color: borderColor!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: 'Votre commentaire...',
                      hintStyle: TextStyle(color: secondaryColor),
                      filled: true,
                      fillColor: isDark ? Colors.white10 : Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide(color: borderColor!),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: Theme.of(context).primaryColor,
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _isSubmitting ? null : _submitComment,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(String? dateString) {
    if (dateString == null) return '';
    try {
      final dateTime = DateTime.parse(dateString);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inSeconds < 60) return 'À l\'instant';
      if (difference.inMinutes < 60) return '${difference.inMinutes}m';
      if (difference.inHours < 24) return '${difference.inHours}h';
      if (difference.inDays < 7) return '${difference.inDays}j';

      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return '';
    }
  }
}
