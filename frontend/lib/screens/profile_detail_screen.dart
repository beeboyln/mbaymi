import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/screens/farm_detail_screen.dart';
import 'package:mbaymi/utils/app_colors.dart';

class ProfileDetailScreen extends StatefulWidget {
  final int userId;
  final bool isDarkMode;

  const ProfileDetailScreen({
    super.key,
    required this.userId,
    required this.isDarkMode,
  });

  @override
  State<ProfileDetailScreen> createState() => _ProfileDetailScreenState();
}

class _ProfileDetailScreenState extends State<ProfileDetailScreen> with AutomaticKeepAliveClientMixin {
  // ✅ Futures créées une seule fois et cachées
  Future<Map<String, dynamic>>? _profileFuture;
  Future<List<dynamic>>? _postsFuture;
  Future<List<dynamic>>? _farmsFuture;
  
  Map<String, dynamic> _profileData = {};
  final List<dynamic> _postsData = [];
  int _userId = 0;
  int? _followersCount;
  bool? _isFollowing;

  // Couleurs
  static const Color _primaryColor = Color(0xFF8B6B4D);
  static const Color _primaryLight = Color(0xFFA58A6D);
  static const Color _accentColor = Color(0xFFC4A484);
  static const Color _bgLight = Color(0xFFFAF8F5);
  static const Color _bgDark = Color(0xFF121212);
  static const Color _cardLight = AppColors.lightBg;
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
    _userId = AuthService.currentSession?.userId ?? 0;
    // Créer les futures qu'UNE SEULE FOIS
    _profileFuture ??= ApiService.getUserProfile(widget.userId, viewerId: _userId > 0 ? _userId : null);
    _postsFuture ??= ApiService.getUserPosts(widget.userId, viewerId: _userId > 0 ? _userId : null);
    _farmsFuture ??= ApiService.getPublicUserFarms(widget.userId);
  }

  Future<void> _refresh() async {
    // Recharger UNIQUEMENT si on swipe
    _profileFuture = ApiService.getUserProfile(widget.userId, viewerId: _userId > 0 ? _userId : null);
    _postsFuture = ApiService.getUserPosts(widget.userId, viewerId: _userId > 0 ? _userId : null);
    _farmsFuture = ApiService.getPublicUserFarms(widget.userId);
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
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('Profil', style: TextStyle(fontWeight: FontWeight.w300)),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        leading: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Container(
            decoration: BoxDecoration(
              color: bgColor.withOpacity(0.95),
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.arrow_back, color: textColor),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        // ❌ Pas de bouton logout - c'est un profil de lecture seule
      ),
      body: RefreshIndicator(
        color: _primaryColor,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _profileFuture ?? ApiService.getUserProfile(widget.userId, viewerId: _userId > 0 ? _userId : null),
            builder: (context, profileSnap) {
              if (profileSnap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
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
              final totalFollowers = profile['total_followers'] ?? profile['followers'] ?? 0;
              final totalPosts = profile['total_posts'] ?? 0;

              // Only update from server if local state hasn't been modified
              _followersCount ??= totalFollowers;
              if (_isFollowing == null) {
                if (profile.containsKey('followed_by_user')) {
                  _isFollowing = profile['followed_by_user'] as bool? ?? false;
                } else if (profile.containsKey('is_following')) {
                  _isFollowing = profile['is_following'] as bool? ?? false;
                } else {
                  _isFollowing = false;
                }
              }

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
                                    // Abonnés + follow button
                                    Column(
                                      children: [
                                        const Icon(Icons.people_outline, size: 24, color: _accentColor),
                                        const SizedBox(height: 8),
                                        Text(
                                          '${_followersCount ?? 0}',
                                          style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            color: _accentColor,
                                          ),
                                        ),
                                        const SizedBox(height: 6),
                                        SizedBox(
                                          height: 30,
                                          child: widget.userId == _userId
                                              ? const SizedBox.shrink()
                                              : (_userId == 0
                                                  ? OutlinedButton(
                                                      onPressed: () {
                                                        ScaffoldMessenger.of(context).showSnackBar(
                                                          const SnackBar(content: Text('Veuillez vous connecter pour vous abonner')),
                                                        );
                                                      },
                                                      child: const Text("S'abonner"),
                                                    )
                                                  : (_isFollowing == true
                                                      ? OutlinedButton(
                                                          onPressed: () async {
                                                            // unfollow
                                                            final prev = _isFollowing;
                                                            setState(() {
                                                              _isFollowing = false;
                                                              _followersCount = (_followersCount ?? 0) - 1;
                                                            });
                                                            try {
                                                              await ApiService.unfollowUser(userIdToUnfollow: widget.userId, userId: _userId);
                                                              // notify other components (dashboard) that follow state changed IMMEDIATELY
                                                              ApiService.notifyFollowChanged(widget.userId, 'unfollow');
                                                              // fetch authoritative profile in background and merge results without triggering loader
                                                              ApiService.getUserProfile(widget.userId, viewerId: _userId > 0 ? _userId : null).then((fresh) {
                                                                if (!mounted) return;
                                                                setState(() {
                                                                  _profileData = fresh;
                                                                  _followersCount = fresh['total_followers'] ?? _followersCount;
                                                                  _isFollowing = fresh['followed_by_user'] ?? _isFollowing;
                                                                });
                                                              }).catchError((_) {});
                                                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Désabonné')));
                                                            } catch (e) {
                                                              setState(() {
                                                                _isFollowing = prev;
                                                                _followersCount = (_followersCount ?? 0) + 1;
                                                              });
                                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                                                            }
                                                          },
                                                          child: const Text('Abonné'),
                                                        )
                                                      : ElevatedButton(
                                                          style: ElevatedButton.styleFrom(backgroundColor: _accentColor),
                                                          onPressed: () async {
                                                            final prev = _isFollowing;
                                                            setState(() {
                                                              _isFollowing = true;
                                                              _followersCount = (_followersCount ?? 0) + 1;
                                                            });
                                                            try {
                                                              await ApiService.followUser(userIdToFollow: widget.userId, userId: _userId);
                                                              // fetch authoritative profile in background and merge results without triggering loader
                                                              ApiService.getUserProfile(widget.userId, viewerId: _userId > 0 ? _userId : null).then((fresh) {
                                                                if (!mounted) return;
                                                                setState(() {
                                                                  _profileData = fresh;
                                                                  _followersCount = fresh['total_followers'] ?? _followersCount;
                                                                  _isFollowing = fresh['followed_by_user'] ?? _isFollowing;
                                                                });
                                                              }).catchError((_) {});
                                                              // notify other components (dashboard) that follow state changed
                                                              ApiService.notifyFollowChanged(widget.userId, 'follow');
                                                              if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Abonné')));
                                                            } catch (e) {
                                                              setState(() {
                                                                _isFollowing = prev;
                                                                _followersCount = (_followersCount ?? 0) - 1;
                                                              });
                                                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
                                                            }
                                                          },
                                                          child: const Text("S'abonner"),
                                                        ))),
                                        ),
                                      ],
                                    ),

                                    // Fermes count (replace Posts)
                                    FutureBuilder<List<dynamic>>(
                                      future: _farmsFuture ?? ApiService.getPublicUserFarms(widget.userId),
                                      builder: (context, farmsSnap) {
                                        final farms = farmsSnap.data ?? [];
                                        final count = farms.length;
                                        return _buildStatWidget(
                                          icon: Icons.landscape_outlined,
                                          label: 'Fermes',
                                          value: '$count',
                                          color: _primaryLight,
                                        );
                                      },
                                    ),
                              ],
                            ),
                            // ❌ Pas de bouton "Créer du contenu" - c'est un profil d'autre utilisateur
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    const SizedBox(height: 16),

                      // 🐄 Fermes du profil (lecture seule)
                      Text(
                        'Fermes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      FutureBuilder<List<dynamic>>(
                        future: _farmsFuture ?? ApiService.getPublicUserFarms(widget.userId),
                        builder: (context, farmsSnap) {
                          if (farmsSnap.connectionState == ConnectionState.waiting) {
                            return const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator(color: _primaryColor)));
                          }
                          if (farmsSnap.hasError) {
                            return Text('Erreur: ${farmsSnap.error}', style: TextStyle(color: textColor));
                          }

                          final farms = farmsSnap.data ?? [];
                          if (farms.isEmpty) {
                            return Center(child: Padding(padding: const EdgeInsets.symmetric(vertical: 24), child: Text('Aucune ferme', style: TextStyle(color: secondaryTextColor))));
                          }

                          return DecoratedBox(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: const BorderRadius.all(Radius.circular(16)),
                              border: Border.all(color: borderColor, width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: farms.map<Widget>((f) {
                                  final farm = f as Map<String, dynamic>;
                                  final farmName = farm['farm_name'] ?? farm['name'] ?? farm['title'] ?? 'Ferme';
                                  final location = farm['farm_location'] ?? farm['location'] ?? farm['address'] ?? '';
                                  final imageUrl = (farm['profile_image_farm'] ?? farm['image_url'] ?? farm['profile_image'] ?? farm['image']) as String?;
                                  final followers = farm['followers'] ?? farm['total_followers'] ?? 0;

                                  return ListTile(
                                    contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                                    leading: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(borderRadius: BorderRadius.circular(8), color: Colors.grey[200]),
                                      child: imageUrl != null && imageUrl.isNotEmpty
                                          ? ClipRRect(borderRadius: BorderRadius.circular(8), child: Image.network(imageUrl, fit: BoxFit.cover))
                                          : const Icon(Icons.landscape_outlined, size: 32, color: Colors.grey),
                                    ),
                                    title: Text(farmName, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
                                    subtitle: Text(location, style: TextStyle(color: secondaryTextColor)),
                                    trailing: Column(mainAxisAlignment: MainAxisAlignment.center, children: [const Icon(Icons.favorite, color: _primaryColor, size: 16), const SizedBox(height: 4), Text('$followers', style: const TextStyle(color: _primaryColor))]),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => FarmDetailScreen(
                                            farmId: farm['farm_id'] ?? farm['id'] ?? farm['farmId'] ?? 0,
                                            farmData: farm,
                                            isDarkMode: widget.isDarkMode,
                                            readOnly: true,
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                }).toList(),
                              ),
                            ),
                          );
                        },
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
