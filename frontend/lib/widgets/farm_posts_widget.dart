import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/screens/social/create_farm_post_dialog.dart';
import 'package:mbaymi/widgets/comments_bottom_sheet.dart';
import 'package:mbaymi/utils/app_colors.dart';

// ─── DESIGN TOKENS ───────────────────────────────────────────────────────────
class _Z {
  static const bg = Color(0xFFF7F6F4);
  static const ink = Color(0xFF111111);
  static const muted = Color(0xFF888888);
  static const faint = Color(0xFFE8E6E1);
  static const cardBg = Color(0xFFFFFFFF);
  static const accent = Color(0xFF8B6B4D); // Terre cuite — couleur identitaire
}
// ─────────────────────────────────────────────────────────────────────────────

class FarmPostsWidget extends StatefulWidget {
  final int farmId;
  final String farmName;
  final bool isOwner;
  final int? livestockId;

  const FarmPostsWidget({
    super.key,
    required this.farmId,
    required this.farmName,
    required this.isOwner,
    this.livestockId,
  });

  @override
  State<FarmPostsWidget> createState() => _FarmPostsWidgetState();
}

class _FarmPostsWidgetState extends State<FarmPostsWidget>
    with SingleTickerProviderStateMixin {
  late Future<List<dynamic>> _postsFuture;
  List<Map<String, dynamic>> _posts = [];
  int _userId = 0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _userId = AuthService.currentSession?.userId ?? 0;
    _postsFuture = _loadPosts();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 500));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Future<List<dynamic>> _loadPosts() async {
    try {
      final posts = widget.livestockId != null
          ? await ApiService.getLivestockPosts(widget.livestockId!,
              userId: _userId)
          : await ApiService.getFarmPosts(widget.farmId, userId: _userId);
      if (mounted) {
        setState(() => _posts = List<Map<String, dynamic>>.from(posts));
      }
      return posts;
    } catch (e) {
      return [];
    }
  }

  void _showError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      AppColors.createSnackBar(
        message: msg,
        isError: true,
      ),
    );
  }

  // ─── BUILD ───────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _fadeAnim,
      child: ListView(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          // ── Section header ──────────────────────────────────────────────
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Row(
              children: [
                const Text('PUBLICATIONS',
                    style: TextStyle(
                        fontSize: 9,
                        letterSpacing: 3,
                        fontWeight: FontWeight.w500,
                        color: _Z.muted)),
                const SizedBox(width: 12),
                Expanded(child: Container(height: 1, color: _Z.faint)),
                if (widget.isOwner) ...[
                  const SizedBox(width: 12),
                  GestureDetector(
                    onTap: _showCreatePostDialog,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      color: _Z.ink,
                      child: const Text('+ NOUVEAU',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              letterSpacing: 2.5,
                              fontWeight: FontWeight.w500)),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Posts list ──────────────────────────────────────────────────
          FutureBuilder<List<dynamic>>(
            future: _postsFuture,
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child:
                        CircularProgressIndicator(color: _Z.ink, strokeWidth: 1),
                  ),
                );
              }

              if (_posts.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 24, vertical: 40),
                  child: Column(
                    children: [
                      Container(
                        width: 64,
                        height: 64,
                        decoration:
                            BoxDecoration(border: Border.all(color: _Z.faint)),
                        child: const Icon(Icons.photo_outlined,
                            size: 28, color: _Z.muted),
                      ),
                      const SizedBox(height: 16),
                      const Text('AUCUN POST',
                          style: TextStyle(
                              fontSize: 9,
                              letterSpacing: 3,
                              color: _Z.muted)),
                      if (widget.isOwner) ...[
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: _showCreatePostDialog,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            color: _Z.ink,
                            child: const Text('CRÉER UN POST',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    letterSpacing: 3,
                                    fontWeight: FontWeight.w500)),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              }

              return ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 24),
                itemCount: _posts.length,
                separatorBuilder: (_, __) =>
                    Container(height: 1, color: _Z.faint, margin: const EdgeInsets.symmetric(vertical: 4)),
                itemBuilder: (context, i) =>
                    _PostCard(
                      post: _posts[i],
                      index: i,
                      userId: _userId,
                      isOwner: widget.isOwner,
                      onLike: _toggleLike,
                      onDelete: _confirmDelete,
                      onShare: _sharePost,
                      onComment: (postId) => _openComments(postId),
                    ),
              );
            },
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  // ─── ACTIONS ─────────────────────────────────────────────────────────────
  void _openComments(int postId) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _Z.bg,
      shape: const RoundedRectangleBorder(),
      builder: (_) => CommentsBottomSheet(
        postId: postId,
        currentUserId: _userId,
        isDarkMode: false,
      ),
    );
  }

  Future<void> _confirmDelete(int postId, int index) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _Z.bg,
        shape: const RoundedRectangleBorder(),
        title: const Text('SUPPRIMER',
            style: TextStyle(
                fontSize: 11,
                letterSpacing: 3,
                fontWeight: FontWeight.w500,
                color: _Z.ink)),
        content: const Text('Cette action est irréversible.',
            style: TextStyle(color: _Z.muted, fontSize: 13)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('ANNULER',
                style: TextStyle(
                    fontSize: 10, letterSpacing: 2, color: _Z.muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SUPPRIMER',
                style: TextStyle(
                    fontSize: 10, letterSpacing: 2, color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await ApiService.deleteFarmPost(postId, _userId);
        setState(() => _posts.removeAt(index));
      } catch (e) {
        _showError(e.toString());
      }
    }
  }

  Future<void> _toggleLike(int postId, int index, bool isLiked) async {
    setState(() {
      _posts[index]['is_liked'] = !isLiked;
      _posts[index]['likes_count'] = isLiked
          ? (_posts[index]['likes_count'] ?? 0) - 1
          : (_posts[index]['likes_count'] ?? 0) + 1;
    });
    try {
      if (isLiked) {
        await ApiService.unlikeFarmPost(postId);
      } else {
        await ApiService.likeFarmPost(postId);
      }
    } catch (e) {
      setState(() {
        _posts[index]['is_liked'] = isLiked;
        _posts[index]['likes_count'] = isLiked
            ? (_posts[index]['likes_count'] ?? 0) + 1
            : (_posts[index]['likes_count'] ?? 0) - 1;
      });
      _showError(e.toString());
    }
  }

  Future<void> _sharePost(int postId) async {
    try {
      await ApiService.shareFarmPost(postId);
      ScaffoldMessenger.of(context).showSnackBar(
        AppColors.createSnackBar(
          message: 'Partagé',
          isError: false,
          durationMs: 800,
        ),
      );
    } catch (e) {
      _showError(e.toString());
    }
  }

  void _showCreatePostDialog() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CreateFarmPostDialog(
          farmId: widget.farmId,
          farmName: widget.farmName,
          onPostCreated: () => setState(() => _postsFuture = _loadPosts()),
          livestockId: widget.livestockId,
        ),
      ),
    );
  }
}

// ─── POST CARD ────────────────────────────────────────────────────────────────
class _PostCard extends StatelessWidget {
  final Map<String, dynamic> post;
  final int index;
  final int userId;
  final bool isOwner;
  final Future<void> Function(int, int, bool) onLike;
  final Future<void> Function(int, int) onDelete;
  final Future<void> Function(int) onShare;
  final void Function(int) onComment;

  const _PostCard({
    required this.post,
    required this.index,
    required this.userId,
    required this.isOwner,
    required this.onLike,
    required this.onDelete,
    required this.onShare,
    required this.onComment,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = post['image_url'] as String?;
    final caption = post['caption'] as String? ?? '';
    final likesCount = post['likes_count'] ?? 0;
    final commentsCount = post['comments_count'] ?? 0;
    final sharesCount = post['shares_count'] ?? 0;
    final isLiked = post['is_liked'] ?? false;
    final postId = post['id'] as int;
    final postIntent = post['post_intent'] as String? ?? 'share';
    final price = post['price'] as num?;
    final unit = post['unit'] as String? ?? 'kg';
    final canDelete =
        isOwner || (post['user_id'] != null && post['user_id'] == userId);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Image ──────────────────────────────────────────────────────
          if (imageUrl != null && imageUrl.isNotEmpty)
            Stack(
              children: [
                AspectRatio(
                  aspectRatio: 4 / 3,
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: _Z.faint,
                      child: const Icon(Icons.image_not_supported_outlined,
                          color: _Z.muted, size: 32),
                    ),
                  ),
                ),

                // Price badge — style étiquette épurée
                if (postIntent == 'sell' && price != null)
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 8),
                      color: _Z.accent,
                      child: Text(
                        '${price.toStringAsFixed(0)} CFA / $unit',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

          const SizedBox(height: 12),

          // ── Caption ────────────────────────────────────────────────────
          if (caption.isNotEmpty)
            Text(
              caption,
              style: const TextStyle(
                  fontSize: 13,
                  height: 1.6,
                  color: _Z.ink,
                  letterSpacing: 0.2),
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
            ),

          const SizedBox(height: 14),

          // ── Actions ────────────────────────────────────────────────────
          Row(
            children: [
              // Like
              GestureDetector(
                onTap: () => onLike(postId, index, isLiked),
                child: Row(
                  children: [
                    Icon(
                      isLiked ? Icons.favorite : Icons.favorite_border,
                      size: 16,
                      color: isLiked ? _Z.accent : _Z.muted,
                    ),
                    const SizedBox(width: 5),
                    Text('$likesCount',
                        style: const TextStyle(
                            fontSize: 11,
                            color: _Z.muted,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Comments
              GestureDetector(
                onTap: () => onComment(postId),
                child: Row(
                  children: [
                    const Icon(Icons.chat_bubble_outline,
                        size: 16, color: _Z.muted),
                    const SizedBox(width: 5),
                    Text('$commentsCount',
                        style: const TextStyle(
                            fontSize: 11,
                            color: _Z.muted,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),
              const SizedBox(width: 20),

              // Share
              GestureDetector(
                onTap: () => onShare(postId),
                child: Row(
                  children: [
                    const Icon(Icons.share_outlined,
                        size: 16, color: _Z.muted),
                    const SizedBox(width: 5),
                    Text('$sharesCount',
                        style: const TextStyle(
                            fontSize: 11,
                            color: _Z.muted,
                            letterSpacing: 0.5)),
                  ],
                ),
              ),

              const Spacer(),

              // Delete
              if (canDelete)
                GestureDetector(
                  onTap: () => onDelete(postId, index),
                  child: const Text('SUPPRIMER',
                      style: TextStyle(
                          fontSize: 9,
                          letterSpacing: 1.5,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF9E3A3A))),
                ),
            ],
          ),
        ],
      ),
    );
  }
}