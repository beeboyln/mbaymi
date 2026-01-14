import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/services/api_service.dart';

class ProfileDetailScreen extends StatefulWidget {
  final int userId;
  final bool isDarkMode;

  const ProfileDetailScreen({
    Key? key,
    required this.userId,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> with AutomaticKeepAliveClientMixin {
  // ✅ Futures créées une seule fois et cachées
  Future<Map<String, dynamic>>? _profileFuture;
  Future<List<dynamic>>? _postsFuture;
  
  Map<String, dynamic> _profileData = {};
  List<dynamic> _postsData = [];

  // Couleurs
  static const Color _primaryColor = Color(0xFF8B6B4D);
  static const Color _primaryLight = Color(0xFFA58A6D);
  static const Color _accentColor = Color(0xFFC4A484);
  static const Color _bgLight = Color(0xFFFAF8F5);
  static const Color _bgDark = Color(0xFF121212);
  static const Color _cardLight = Colors.white;
  static const Color _cardDark = Color(0xFF1E1E1E);
  static const Color _borderLight = Color(0xFFE8E2D8);
  static const Color _borderDark = Color(0xFF2C2C2C);
  static const Color _textLight = Color(0xFF1A1A1A);
  static const Color _textDark = Colors.white;
  static const Color _textSecondaryLight = Color(0xFF6B6B6B);
  static const Color _textSecondaryDark = Color(0xFF8E8E93);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Créer les futures qu'UNE SEULE FOIS
    _profileFuture ??= ApiService.getUserProfile(widget.userId);
    _postsFuture ??= ApiService.getUserPosts(widget.userId);
  }

  Future<void> _refresh() async {
    // Recharger UNIQUEMENT si on swipe
    _profileFuture = ApiService.getUserProfile(widget.userId);
    _postsFuture = ApiService.getUserPosts(widget.userId);
    setState(() {});
  }

  Widget _buildDefaultAvatar(String name) => Container(
    width: 80,
    height: 80,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(40),
      color: _primaryColor,
      border: Border.all(
        color: _primaryColor,
        width: 2,
      ),
    ),
    child: Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 32,
          fontWeight: FontWeight.bold,
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final isDark = widget.isDarkMode;
    final bgColor = isDark ? _bgDark : _bgLight;
    final cardColor = isDark ? _cardDark : _cardLight;
    final textColor = isDark ? _textDark : _textLight;
    final secondaryTextColor = isDark ? _textSecondaryDark : _textSecondaryLight;
    final borderColor = isDark ? _borderDark : _borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.w300)),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        // ❌ Pas de bouton logout - c'est un profil de lecture seule
      ),
      body: RefreshIndicator(
        color: _primaryColor,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _profileFuture ?? ApiService.getUserProfile(widget.userId),
            builder: (context, profileSnap) {
              if (profileSnap.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: _primaryColor),
                  ),
                );
              }

              if (profileSnap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Erreur: ${profileSnap.error}',
                      style: TextStyle(color: textColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              // Store profile data in state
              _profileData = profileSnap.data ?? {};
              
              final profile = _profileData;
              final name = profile['name'] ?? 'Utilisateur';
              final email = profile['email'] ?? '';
              final profileImage = profile['profile_image'] as String?;
              final totalFollowers = profile['total_followers'] ?? 0;
              final totalPosts = profile['total_posts'] ?? 0;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 👤 En-tête du profil (LECTURE SEULE)
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar + Nom (pas d'édition)
                            Row(
                              children: [
                                // Avatar - pas de GestureDetector (lecture seule)
                                profileImage != null && profileImage.isNotEmpty
                                    ? Container(
                                        width: 80,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(40),
                                          border: Border.all(
                                            color: _primaryColor,
                                            width: 2,
                                          ),
                                        ),
                                        child: ClipRRect(
                                          borderRadius: BorderRadius.circular(40),
                                          child: Image.network(
                                            profileImage,
                                            fit: BoxFit.cover,
                                            errorBuilder: (_, __, ___) =>
                                                _buildDefaultAvatar(name),
                                          ),
                                        ),
                                      )
                                    : _buildDefaultAvatar(name),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      // Nom - pas de bouton edit
                                      Text(
                                        name,
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w400,
                                          color: textColor,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      // Email - pas de bouton edit
                                      Text(
                                        email,
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: secondaryTextColor,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Stats simplifiées (uniquement abonnés et posts)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatWidget(
                                  icon: Icons.people_outline,
                                  label: 'Abonnés',
                                  value: '$totalFollowers',
                                  color: _accentColor,
                                ),
                                _buildStatWidget(
                                  icon: Icons.newspaper,
                                  label: 'Posts',
                                  value: '$totalPosts',
                                  color: _primaryLight,
                                ),
                              ],
                            ),
                            // ❌ Pas de bouton "Créer du contenu" - c'est un profil d'autre utilisateur
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 📰 Publications - Section regroupée
                    if (_postsData.isNotEmpty || true) // Show section even while loading
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Publications',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w500,
                              color: textColor,
                              letterSpacing: -0.3,
                            ),
                          ),
                          const SizedBox(height: 12),
                          FutureBuilder<List<dynamic>>(
                            future: _postsFuture ?? ApiService.getUserPosts(widget.userId),
                            builder: (context, postsSnap) {
                              if (postsSnap.connectionState == ConnectionState.waiting) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(20),
                                    child: CircularProgressIndicator(color: _primaryColor),
                                  ),
                                );
                              }

                              if (postsSnap.hasError) {
                                return Text(
                                  'Erreur: ${postsSnap.error}',
                                  style: TextStyle(color: textColor),
                                );
                              }

                              // Store posts data in state
                              _postsData = postsSnap.data ?? [];
                              
                              final posts = _postsData;
                              if (posts.isEmpty) {
                                return Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 40),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.newspaper_outlined,
                                          size: 48,
                                          color: _primaryColor.withOpacity(0.5),
                                        ),
                                        const SizedBox(height: 16),
                                        Text(
                                          'Aucune publication',
                                          style: TextStyle(
                                            fontSize: 16,
                                            color: secondaryTextColor,
                                            fontWeight: FontWeight.w300,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }

                              // Conteneur regroupant tous les posts
                              return DecoratedBox(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: const BorderRadius.all(Radius.circular(16)),
                                  border: Border.all(color: borderColor, width: 1),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    children: posts.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final post = entry.value;
                                      final title = post['title'] ?? '';
                                      final farmName = post['farm_name'] ?? '';
                                      final createdAt = post['created_at'] ?? '';
                                      final postType = post['post_type'] ?? 'crop_update';
                                      
                                      DateTime? dateTime;
                                      try {
                                        dateTime = DateTime.parse(createdAt);
                                      } catch (_) {}
                                      
                                      final formattedDate = dateTime != null
                                          ? DateFormat('dd/MM/yyyy').format(dateTime)
                                          : 'Date inconnue';

                                      final postTypeEmoji = _getPostTypeEmoji(postType);
                                      final isLastPost = index == posts.length - 1;

                                      return Column(
                                        children: [
                                          Padding(
                                            padding: const EdgeInsets.symmetric(vertical: 12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Text(
                                                      postTypeEmoji,
                                                      style: const TextStyle(fontSize: 18),
                                                    ),
                                                    const SizedBox(width: 8),
                                                    Expanded(
                                                      child: Text(
                                                        title,
                                                        style: TextStyle(
                                                          fontSize: 15,
                                                          fontWeight: FontWeight.w500,
                                                          color: textColor,
                                                        ),
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                const SizedBox(height: 8),
                                                Row(
                                                  children: [
                                                    Icon(Icons.landscape_outlined,
                                                        size: 14, color: secondaryTextColor),
                                                    const SizedBox(width: 6),
                                                    Text(
                                                      farmName,
                                                      style: TextStyle(
                                                        fontSize: 12,
                                                        color: secondaryTextColor,
                                                      ),
                                                    ),
                                                    const Spacer(),
                                                    Text(
                                                      formattedDate,
                                                      style: TextStyle(
                                                        fontSize: 11,
                                                        color: secondaryTextColor,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          if (!isLastPost)
                                            Divider(
                                              color: borderColor,
                                              height: 1,
                                              thickness: 1,
                                            ),
                                        ],
                                      );
                                    }).toList(),
                                  ),
                                ),
                              );
                            },
                          ),
                        ],
                      ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatWidget({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = widget.isDarkMode;
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? _textSecondaryDark : _textSecondaryLight,
          ),
        ),
      ],
    );
  }

  String _getPostTypeEmoji(String postType) {
    switch (postType) {
      case 'crop_update':
        return '🌱';
      case 'harvest_result':
        return '🌾';
      case 'problem_report':
        return '🚨';
      case 'tip':
        return '💡';
      default:
        return '📝';
    }
  }
}
