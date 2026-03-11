import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/api_service.dart';
import 'package:mbaymi/utils/app_colors.dart';

class CommentsBottomSheet extends StatefulWidget {
  final int postId;
  final int currentUserId;
  final bool isDarkMode;

  const CommentsBottomSheet({
    super.key,
    required this.postId,
    required this.currentUserId,
    this.isDarkMode = false,
  });

  @override
  State<CommentsBottomSheet> createState() => _CommentsBottomSheetState();
}

class _CommentsBottomSheetState extends State<CommentsBottomSheet> {
  late TextEditingController _commentController;
  late FocusNode _commentFocus;

  // Only top-level comments (no parent_id)
  List<dynamic> _comments = [];
  // Map of parentCommentId -> list of replies
  Map<int, List<dynamic>> _replies = {};
  // Set of comment IDs whose replies are expanded
  final Set<int> _expandedReplies = {};

  bool _isLoading = true;
  bool _isSubmitting = false;
  int? _replyingToCommentId;
  String? _replyingToUserName;

  @override
  void initState() {
    super.initState();
    _commentController = TextEditingController();
    _commentFocus = FocusNode();
    _loadComments();
  }

  @override
  void dispose() {
    _commentController.dispose();
    _commentFocus.dispose();
    super.dispose();
  }

  void _loadComments() async {
    try {
      final allComments = await ApiService.getPostComments(widget.postId);

      // Separate top-level comments from replies
      // Assumes replies have a 'parent_id' field (non-null) in the API response
      final topLevel = <dynamic>[];
      final repliesMap = <int, List<dynamic>>{};

      for (final c in allComments) {
        final parentId = c['parent_id'];
        if (parentId == null) {
          topLevel.add(c);
        } else {
          repliesMap.putIfAbsent(parentId as int, () => []).add(c);
        }
      }

      setState(() {
        _comments = topLevel;
        _replies = repliesMap;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) {
        _showSnack('Erreur: $e', isError: true);
      }
    }
  }

  void _submitComment() async {
    if (widget.currentUserId <= 0) {
      _showSnack('Connexion requise', isError: true);
      return;
    }

    var text = _commentController.text.trim();
    if (text.isEmpty) return;

    // If replying, ensure @username mention is at the start
    if (_replyingToCommentId != null && _replyingToUserName != null) {
      final mention = '@$_replyingToUserName ';
      if (!text.startsWith(mention)) {
        text = mention + text;
      }
    }

    // Check that there's actual content (not just @username)
    final contentWithoutMention = text.replaceFirst(RegExp(r'^@\w+\s+'), '').trim();
    if (contentWithoutMention.isEmpty) {
      _showSnack('Écrivez un commentaire', isError: true);
      return;
    }

    HapticFeedback.lightImpact();
    setState(() => _isSubmitting = true);

    try {
      // Pass parent_id when replying
      await ApiService.addComment(
        widget.postId,
        text,
        widget.currentUserId,
        parentId: _replyingToCommentId,
      );

      _commentController.clear();

      // Auto-expand the thread we just replied to
      if (_replyingToCommentId != null) {
        _expandedReplies.add(_replyingToCommentId!);
      }

      setState(() {
        _replyingToCommentId = null;
        _replyingToUserName = null;
        _isSubmitting = false;
      });

      _loadComments();
      _showSnack('Commentaire ajouté');
    } catch (e) {
      setState(() => _isSubmitting = false);
      _showSnack('Erreur: $e', isError: true);
    }
  }

  void _deleteComment(int commentId) async {
    HapticFeedback.mediumImpact();
    try {
      await ApiService.deleteComment(widget.postId, commentId, widget.currentUserId);
      _loadComments();
      _showSnack('Commentaire supprimé');
    } catch (e) {
      _showSnack('Erreur: $e', isError: true);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(letterSpacing: 0.5)),
        backgroundColor: isError ? AppColors.error : AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
        duration: Duration(milliseconds: isError ? 2500 : 800),
      ),
    );
  }

  // Build comment thread with nested replies (recursive)
  List<Widget> _buildCommentThread(
    dynamic comment,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
    bool isReply,
  ) {
    final widgets = <Widget>[];
    final commentId = comment['id'] as int;
    final directReplies = _replies[commentId] ?? [];
    final isExpanded = _expandedReplies.contains(commentId);

    // Add the comment itself
    widgets.add(
      _buildCommentTile(
        comment: comment,
        borderColor: borderColor,
        textColor: textColor,
        secondaryTextColor: secondaryTextColor,
        isReply: isReply,
        showBorder: directReplies.isNotEmpty,
      ),
    );

    // Only show "View/Hide replies" toggle for TOP-LEVEL comments (not nested)
    if (directReplies.isNotEmpty && !isReply) {
      widgets.add(
        Padding(
          padding: const EdgeInsets.only(left: 72, bottom: 4, top: 4),
          child: InkWell(
            onTap: () {
              HapticFeedback.selectionClick();
              setState(() {
                if (isExpanded) {
                  _expandedReplies.remove(commentId);
                } else {
                  _expandedReplies.add(commentId);
                }
              });
            },
            child: Text(
              isExpanded
                  ? 'Masquer les réponses'
                  : 'Voir ${directReplies.length} réponse${directReplies.length > 1 ? 's' : ''}',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.3,
              ),
            ),
          ),
        ),
      );
    }

    // If expanded, recursively build nested replies
    if (isExpanded) {
      for (final reply in directReplies) {
        widgets.addAll(
          _buildCommentThread(
            reply,
            borderColor,
            textColor,
            secondaryTextColor,
            true, // nested replies are marked as replies
          ),
        );
      }
    }

    widgets.add(
      Divider(
        height: 1,
        thickness: 0.5,
        color: borderColor,
      ),
    );

    return widgets;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
    final bgColor = AppColors.getBgColor(isDark);
    final textColor = AppColors.getTextColor(isDark);
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDark);
    final borderColor = AppColors.getBorderColor(isDark);

    final totalCount = _comments.length +
        _replies.values.fold(0, (sum, list) => sum + list.length);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      decoration: BoxDecoration(color: bgColor),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'COMMENTAIRES',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                    letterSpacing: 2.5,
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.close, color: textColor, size: 20),
                  onPressed: () {
                    HapticFeedback.lightImpact();
                    Navigator.pop(context);
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ],
            ),
          ),

          // ── Count ────────────────────────────────────────────────────────────
          if (totalCount > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: borderColor, width: 0.5)),
              ),
              child: Row(
                children: [
                  Text(
                    '$totalCount',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    totalCount == 1 ? 'commentaire' : 'commentaires',
                    style: TextStyle(
                      fontSize: 13,
                      color: secondaryTextColor,
                      letterSpacing: 0.3,
                    ),
                  ),
                ],
              ),
            ),

          // ── List ─────────────────────────────────────────────────────────────
          Expanded(
            child: _isLoading
                ? const Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  )
                : _comments.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.chat_bubble_outline,
                              size: 48,
                              color: secondaryTextColor.withOpacity(0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'AUCUN COMMENTAIRE',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w400,
                                letterSpacing: 2,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Soyez le premier à commenter',
                              style: TextStyle(
                                fontSize: 13,
                                color: secondaryTextColor,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _comments.length,
                        itemBuilder: (context, index) {
                          final comment = _comments[index];

                          return Column(
                            children: _buildCommentThread(
                              comment,
                              borderColor,
                              textColor,
                              secondaryTextColor,
                              false, // top-level comments are not replies
                            ),
                          );
                        },
                      ),
          ),

          // ── Input ─────────────────────────────────────────────────────────
          Container(
            padding: EdgeInsets.only(
              left: 24,
              right: 24,
              top: 16,
              bottom: MediaQuery.of(context).viewInsets.bottom + 16,
            ),
            decoration: BoxDecoration(
              color: bgColor,
              border: Border(top: BorderSide(color: borderColor, width: 0.5)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Reply indicator
                if (_replyingToCommentId != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: borderColor, width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.reply, size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Répondre à $_replyingToUserName',
                            style: TextStyle(
                              color: textColor,
                              fontSize: 12,
                              letterSpacing: 0.3,
                            ),
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            HapticFeedback.lightImpact();
                            setState(() {
                              _replyingToCommentId = null;
                              _replyingToUserName = null;
                            });
                          },
                          child: Icon(Icons.close, size: 16, color: secondaryTextColor),
                        ),
                      ],
                    ),
                  ),

                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _commentController,
                        focusNode: _commentFocus,
                        maxLines: null,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 14,
                          letterSpacing: 0.3,
                        ),
                        decoration: InputDecoration(
                          hintText: _replyingToCommentId != null
                              ? 'Ajouter une réponse...'
                              : 'Ajouter un commentaire...',
                          hintStyle: TextStyle(
                            color: secondaryTextColor.withOpacity(0.5),
                            letterSpacing: 0.3,
                          ),
                          contentPadding: const EdgeInsets.symmetric(vertical: 12),
                          enabledBorder: UnderlineInputBorder(
                            borderSide: BorderSide(color: borderColor, width: 1),
                          ),
                          focusedBorder: const UnderlineInputBorder(
                            borderSide: BorderSide(color: AppColors.primary, width: 1.5),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    InkWell(
                      onTap: _isSubmitting ? null : _submitComment,
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _isSubmitting
                              ? secondaryTextColor.withOpacity(0.3)
                              : AppColors.primary,
                          shape: BoxShape.circle,
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : const Icon(
                                Icons.arrow_upward,
                                color: Colors.white,
                                size: 18,
                              ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Reusable comment tile ──────────────────────────────────────────────────
  Widget _buildCommentTile({
    required dynamic comment,
    required Color borderColor,
    required Color textColor,
    required Color secondaryTextColor,
    bool isReply = false,
    bool showBorder = true,
  }) {
    final isAuthor = comment['user_id'] == widget.currentUserId;

    return Container(
      padding: EdgeInsets.only(
        // Indent replies to the right (like Instagram)
        left: isReply ? 72 : 24,
        right: 24,
        top: 12,
        bottom: 12,
      ),
      decoration: showBorder && !isReply
          ? null
          : null, // borders handled by Column separators
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar
          Container(
            width: isReply ? 28 : 36,
            height: isReply ? 28 : 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: borderColor, width: 1),
            ),
            child: ClipOval(
              child: comment['user_profile_image'] != null &&
                      (comment['user_profile_image'] as String).isNotEmpty
                  ? Image.network(
                      comment['user_profile_image'],
                      fit: BoxFit.cover,
                      errorBuilder: (c, e, s) => Icon(
                        Icons.person_outline,
                        color: secondaryTextColor,
                        size: isReply ? 14 : 18,
                      ),
                    )
                  : Icon(
                      Icons.person_outline,
                      color: secondaryTextColor,
                      size: isReply ? 14 : 18,
                    ),
            ),
          ),
          const SizedBox(width: 12),

          // Content
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        (comment['user_name'] ?? 'Utilisateur').toUpperCase(),
                        style: TextStyle(
                          fontSize: isReply ? 10 : 11,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                          color: textColor,
                        ),
                      ),
                    ),
                    Text(
                      _formatTime(comment['created_at']),
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 10,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  comment['comment'] ?? '',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 14,
                    letterSpacing: 0.3,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    // All comments (including replies) can be replied to
                    InkWell(
                      onTap: () {
                        HapticFeedback.lightImpact();
                        final userName = comment['user_name'] ?? 'Utilisateur';
                        setState(() {
                          _replyingToCommentId = comment['id'];
                          _replyingToUserName = userName;
                          // Pre-fill with @username mention
                          _commentController.text = '@$userName ';
                          // Position cursor at end
                          _commentController.selection = TextSelection.fromPosition(
                            TextPosition(offset: _commentController.text.length),
                          );
                        });
                        _commentFocus.requestFocus();
                      },
                      child: const Text(
                        'RÉPONDRE',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ),
                    if (isAuthor) ...[
                      const SizedBox(width: 16),
                      InkWell(
                        onTap: () => _showDeleteDialog(comment['id']),
                        child: const Text(
                          'SUPPRIMER',
                          style: TextStyle(
                            color: AppColors.error,
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(int commentId) {
    final isDark = widget.isDarkMode;
    final bgColor = AppColors.getBgColor(isDark);
    final textColor = AppColors.getTextColor(isDark);
    final secondaryTextColor = AppColors.getSecondaryTextColor(isDark);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: bgColor,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
        title: Text(
          'SUPPRIMER LE COMMENTAIRE',
          style: TextStyle(
            color: textColor,
            fontSize: 13,
            fontWeight: FontWeight.w500,
            letterSpacing: 2,
          ),
        ),
        content: Text(
          'Voulez-vous vraiment supprimer ce commentaire ?',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 14,
            letterSpacing: 0.3,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              HapticFeedback.lightImpact();
              Navigator.pop(ctx);
            },
            child: Text(
              'ANNULER',
              style: TextStyle(color: textColor, fontSize: 11, letterSpacing: 1.5),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _deleteComment(commentId);
            },
            child: const Text(
              'SUPPRIMER',
              style: TextStyle(
                color: Color(0xFFD32F2F),
                fontSize: 11,
                letterSpacing: 1.5,
              ),
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

      if (difference.inSeconds < 60) return 'MAINTENANT';
      if (difference.inMinutes < 60) return '${difference.inMinutes}M';
      if (difference.inHours < 24) return '${difference.inHours}H';
      if (difference.inDays < 7) return '${difference.inDays}J';

      return '${dateTime.day}/${dateTime.month}/${dateTime.year}';
    } catch (e) {
      return '';
    }
  }
}