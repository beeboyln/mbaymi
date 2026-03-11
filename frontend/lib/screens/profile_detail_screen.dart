import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

class _ProfileDetailScreenState extends State<ProfileDetailScreen>
    with AutomaticKeepAliveClientMixin, TickerProviderStateMixin {
  Future<Map<String, dynamic>>? _profileFuture;
  Future<List<dynamic>>? _farmsFuture;

  Map<String, dynamic> _profileData = {};
  int _userId = 0;
  int? _followersCount;
  bool? _isFollowing;
  final Set<int> _followedFarmIds = {};
  bool _isLoadingFollows = false;
  
  // Track followers count per farm ID for real-time updates
  final Map<int, int> _farmFollowersCount = {};

  late AnimationController _pageController;
  late AnimationController _followController;
  late Animation<double> _pageFade;
  late Animation<Offset> _pageSlide;
  late Animation<double> _followScale;

  // ── Palette Zara : blanc/noir/taupe ──────────────────────────────────────
  static const Color _ink = Color(0xFF111111);
  static const Color _inkSoft = Color(0xFF444444);
  static const Color _inkMuted = Color(0xFF999999);
  static const Color _taupe = Color(0xFF9B8B7A);
  static const Color _taupeLight = Color(0xFFD4C8BB);
  static const Color _pageBgLight = Color(0xFFFCFBF9);
  static const Color _pageBgDark = Color(0xFF0C0C0C);
  static const Color _surfaceDark = Color(0xFF161616);
  static const Color _dividerLight = Color(0xFFEAE6E0);
  static const Color _dividerDark = Color(0xFF252525);
  static const Color _inkDark = Color(0xFFF5F5F0);
  static const Color _inkSoftDark = Color(0xFFB0A89E);
  static const Color _inkMutedDark = Color(0xFF5A5A5A);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _userId = AuthService.currentSession?.userId ?? 0;
    _profileFuture ??= ApiService.getUserProfile(
        widget.userId, viewerId: _userId > 0 ? _userId : null);
    _farmsFuture ??= ApiService.getPublicUserFarms(widget.userId);
    _loadFollowedFarms();
    _initAnimations();
  }

  void _initAnimations() {
    _pageController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 640));
    _followController = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 140));

    _pageFade =
        CurvedAnimation(parent: _pageController, curve: Curves.easeOut);
    _pageSlide = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero)
        .animate(CurvedAnimation(
            parent: _pageController, curve: Curves.easeOutCubic));
    _followScale = Tween<double>(begin: 1.0, end: 0.94).animate(
        CurvedAnimation(parent: _followController, curve: Curves.easeInOut));

    Future.microtask(() {
      if (mounted) _pageController.forward();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _followController.dispose();
    super.dispose();
  }

  Future<void> _loadFollowedFarms() async {
    if (_userId == 0) return;
    setState(() => _isLoadingFollows = true);
    try {
      final ids = await ApiService.getFarmFollowingIds(_userId);
      if (mounted) {
        setState(() {
          _followedFarmIds..clear()..addAll(ids);
        });
      }
    } catch (_) {}
    if (mounted) setState(() => _isLoadingFollows = false);
  }

  Future<void> _toggleFollowFarm(int farmId) async {
    if (_userId == 0) { _toast('Connectez-vous pour suivre'); return; }
    if (farmId <= 0) { _toast('Ferme invalide'); return; }
    
    HapticFeedback.selectionClick();
    final following = _followedFarmIds.contains(farmId);
    final currentCount = _farmFollowersCount[farmId] ?? 0;
    
    setState(() {
      if (following) {
        _followedFarmIds.remove(farmId);
        _farmFollowersCount[farmId] = (currentCount - 1).clamp(0, double.infinity).toInt();
      } else {
        _followedFarmIds.add(farmId);
        _farmFollowersCount[farmId] = currentCount + 1;
      }
    });
    
    try {
      if (following) {
        await ApiService.unfollowFarm(farmId: farmId, userId: _userId);
      } else {
        await ApiService.followFarm(farmId: farmId, userId: _userId);
      }
      
      // Refetch farms to sync followers count
      _farmsFuture = ApiService.getPublicUserFarms(widget.userId);
      if (mounted) setState(() {});
      
    } catch (_) {
      // Revert on error
      final revertedCount = _farmFollowersCount[farmId] ?? 0;
      setState(() {
        if (following) {
          _followedFarmIds.add(farmId);
          _farmFollowersCount[farmId] = revertedCount + 1;
        } else {
          _followedFarmIds.remove(farmId);
          _farmFollowersCount[farmId] = (revertedCount - 1).clamp(0, double.infinity).toInt();
        }
      });
    }
  }

  Future<void> _doFollow() async {
    HapticFeedback.mediumImpact();
    final prev = _isFollowing;
    setState(() { _isFollowing = true; _followersCount = (_followersCount ?? 0) + 1; });
    try {
      await ApiService.followUser(userIdToFollow: widget.userId, userId: _userId);
      ApiService.notifyFollowChanged(widget.userId, 'follow');
      // Refresh profile future to sync all data from server
      _profileFuture = ApiService.getUserProfile(widget.userId, viewerId: _userId > 0 ? _userId : null);
      _followersCount = null; // Force re-sync from server on next build
      setState(() {});
    } catch (_) {
      setState(() { _isFollowing = prev; _followersCount = (_followersCount ?? 1) - 1; });
    }
  }

  Future<void> _doUnfollow() async {
    HapticFeedback.lightImpact();
    final prev = _isFollowing;
    setState(() { _isFollowing = false; _followersCount = (_followersCount ?? 1) - 1; });
    try {
      await ApiService.unfollowUser(userIdToUnfollow: widget.userId, userId: _userId);
      ApiService.notifyFollowChanged(widget.userId, 'unfollow');
      // Refresh profile future to sync all data from server
      _profileFuture = ApiService.getUserProfile(widget.userId, viewerId: _userId > 0 ? _userId : null);
      _followersCount = null; // Force re-sync from server on next build
      setState(() {});
    } catch (_) {
      setState(() { _isFollowing = prev; _followersCount = (_followersCount ?? 0) + 1; });
    }
  }

  Future<void> _refresh() async {
    _profileFuture = ApiService.getUserProfile(
        widget.userId, viewerId: _userId > 0 ? _userId : null);
    _farmsFuture = ApiService.getPublicUserFarms(widget.userId);
    _followersCount = null;
    _isFollowing = null;
    _farmFollowersCount.clear(); // Reset farm followers count cache on refresh
    _pageController.reset();
    setState(() {});
    _pageController.forward();
  }

  void _toast(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      AppColors.createSnackBar(
        message: msg,
        isError: false,
        durationMs: 2000,
      ),
    );
  }

  String _fmt(num n) {
    if (n >= 1000000) return '${(n / 1000000).toStringAsFixed(1)}M';
    if (n >= 1000) return '${(n / 1000).toStringAsFixed(1)}k';
    return '$n';
  }

  // ── Build ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final d = widget.isDarkMode;
    final bg = d ? _pageBgDark : _pageBgLight;
    final ink = d ? _inkDark : _ink;
    final inkSoft = d ? _inkSoftDark : _inkSoft;
    final inkMuted = d ? _inkMutedDark : _inkMuted;
    final div = d ? _dividerDark : _dividerLight;

    return Scaffold(
      backgroundColor: bg,
      appBar: AppBar(
        backgroundColor: bg,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Icon(Icons.arrow_back_ios_new_rounded, size: 15, color: inkSoft),
            ),
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Divider(height: 1, thickness: 1, color: div),
        ),
      ),
      body: RefreshIndicator(
        color: _taupe,
        strokeWidth: 1.5,
        onRefresh: _refresh,
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture ??
              ApiService.getUserProfile(widget.userId,
                  viewerId: _userId > 0 ? _userId : null),
          builder: (context, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Center(
                child: SizedBox(
                  width: 20, height: 20,
                  child: CircularProgressIndicator(color: _taupe, strokeWidth: 1.5),
                ),
              );
            }
            if (snap.hasError) {
              return Center(
                child: Text('Une erreur est survenue',
                    style: TextStyle(color: inkMuted, fontSize: 13)),
              );
            }

            _profileData = snap.data ?? {};
            final name = _profileData['name'] ?? 'Utilisateur';
            final email = _profileData['email'] ?? '';
            final imgUrl = _profileData['profile_image'] as String?;
            final totalFollowers =
                _profileData['total_followers'] ?? _profileData['followers'] ?? 0;

            // Force sync from server even if previously set to 0
            if (_followersCount == null || _followersCount == 0) {
              _followersCount = totalFollowers;
            }
            _isFollowing ??= (_profileData['followed_by_user'] ??
                  _profileData['is_following'] ?? false) as bool;

            return FadeTransition(
              opacity: _pageFade,
              child: SlideTransition(
                position: _pageSlide,
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(d, ink, inkSoft, inkMuted, div, name, email, imgUrl),
                      if (widget.userId != _userId)
                        _buildFollowStrip(d, ink, inkSoft, div),
                      _buildFarmsSection(d, ink, inkSoft, inkMuted, div),
                      const SizedBox(height: 56),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Header ─────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool d, Color ink, Color inkSoft, Color inkMuted,
      Color div, String name, String email, String? imgUrl) {
    final count = _followersCount ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 32),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar carré — style éditorial
          _avatar(imgUrl, name, d),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 2),
                Text(
                  name.toUpperCase(),
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: ink,
                    letterSpacing: 2.0,
                    height: 1.2,
                  ),
                ),
                if (email.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(email,
                      style: TextStyle(
                          fontSize: 12, color: inkMuted, letterSpacing: 0.1)),
                ],
                const SizedBox(height: 20),
                // Gros chiffre abonnés
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: count),
                      duration: const Duration(milliseconds: 900),
                      curve: Curves.easeOutCubic,
                      builder: (_, val, __) => Text(
                        _fmt(val),
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w200,
                          color: ink,
                          letterSpacing: -1.5,
                          height: 1,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      count == 1 ? 'abonné' : 'abonnés',
                      style: TextStyle(
                        fontSize: 10,
                        color: inkMuted,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w500,
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

  Widget _avatar(String? imgUrl, String name, bool d) {
    const s = 76.0;
    Widget child;
    if (imgUrl != null && imgUrl.isNotEmpty) {
      child = Image.network(imgUrl, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _letterBox(name, s, d));
    } else {
      child = _letterBox(name, s, d);
    }
    return SizedBox(
      width: s, height: s,
      child: ClipRRect(borderRadius: BorderRadius.circular(2), child: child),
    );
  }

  Widget _letterBox(String name, double s, bool d) => Container(
        width: s, height: s,
        color: d ? _surfaceDark : _dividerLight,
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: TextStyle(
              color: d ? _inkSoftDark : _inkSoft,
              fontSize: s * 0.36,
              fontWeight: FontWeight.w200,
              letterSpacing: -1,
            ),
          ),
        ),
      );

  // ── Follow strip ────────────────────────────────────────────────────────────
  Widget _buildFollowStrip(bool d, Color ink, Color inkSoft, Color div) {
    final isFollowing = _isFollowing ?? false;
    return Column(
      children: [
        Divider(height: 1, thickness: 1, color: div),
        GestureDetector(
          onTapDown: (_) => _followController.forward(),
          onTapUp: (_) {
            _followController.reverse();
            if (_userId == 0) { _toast('Connectez-vous pour vous abonner'); return; }
            isFollowing ? _doUnfollow() : _doFollow();
          },
          onTapCancel: () => _followController.reverse(),
          child: ScaleTransition(
            scale: _followScale,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: SizedBox(
                height: 54,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: Text(
                        isFollowing ? 'ABONNÉ' : "S'ABONNER",
                        key: ValueKey(isFollowing),
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 2.2,
                          color: isFollowing ? _taupe : ink,
                        ),
                      ),
                    ),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      child: Icon(
                        isFollowing ? Icons.check_rounded : Icons.arrow_forward_rounded,
                        key: ValueKey(isFollowing),
                        size: 16,
                        color: isFollowing ? _taupe : inkSoft,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        Divider(height: 1, thickness: 1, color: div),
        const SizedBox(height: 36),
      ],
    );
  }

  // ── Farms ───────────────────────────────────────────────────────────────────
  Widget _buildFarmsSection(
      bool d, Color ink, Color inkSoft, Color inkMuted, Color div) {
    return FutureBuilder<List<dynamic>>(
      future: _farmsFuture ?? ApiService.getPublicUserFarms(widget.userId),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Padding(
            padding: EdgeInsets.all(40),
            child: Center(
              child: SizedBox(
                width: 18, height: 18,
                child: CircularProgressIndicator(color: _taupe, strokeWidth: 1.5),
              ),
            ),
          );
        }

        final farms = snap.data ?? [];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Label section
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('FERMES',
                      style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: inkMuted,
                          letterSpacing: 3)),
                  if (farms.isNotEmpty)
                    Text('${farms.length}',
                        style: TextStyle(fontSize: 9, color: inkMuted, letterSpacing: 1)),
                ],
              ),
            ),

            if (farms.isEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                child: Text('Aucune ferme',
                    style: TextStyle(color: inkMuted, fontSize: 13)),
              )
            else
              ...List.generate(farms.length, (i) => _buildFarmRow(
                  farms[i] as Map<String, dynamic>, i, d, ink, inkSoft, inkMuted, div)),
          ],
        );
      },
    );
  }

  Widget _buildFarmRow(Map<String, dynamic> farm, int i, bool d, Color ink,
      Color inkSoft, Color inkMuted, Color div) {
    final name = farm['farm_name'] ?? farm['name'] ?? farm['title'] ?? 'Ferme';
    final loc = farm['farm_location'] ?? farm['location'] ?? farm['address'] ?? '';
    final imgUrl =
        (farm['profile_image_farm'] ?? farm['image_url'] ?? farm['profile_image'] ?? farm['image'])
            as String?;
    
    final farmId = (farm['farm_id'] ?? farm['id'] ?? 0) as int;
    
    // Initialize followers count from farm data on first load - try multiple field names
    final initialFollowers = farm['followers'] ?? 
                           farm['total_followers'] ?? 
                           farm['followers_count'] ?? 
                           farm['farm_followers'] ??
                           0;
    
    // Only cache if farmId is valid (> 0) to avoid collisions
    if (farmId > 0 && !_farmFollowersCount.containsKey(farmId)) {
      _farmFollowersCount[farmId] = initialFollowers;
    }
    
    // Use tracked followers count if available, otherwise use farm data
    final followers = (farmId > 0 && _farmFollowersCount.containsKey(farmId))
        ? _farmFollowersCount[farmId]!
        : initialFollowers;
    
    final isFollowed = _followedFarmIds.contains(farmId);

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 380 + i * 55),
      curve: Curves.easeOut,
      builder: (_, v, child) =>
          Opacity(opacity: v, child: Transform.translate(offset: Offset(0, 8 * (1 - v)), child: child)),
      child: Column(
        children: [
          Divider(height: 1, thickness: 1, color: div),
          InkWell(
            onTap: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FarmDetailScreen(
                  farmId: farmId,
                  farmData: farm,
                  isDarkMode: widget.isDarkMode,
                  readOnly: true,
                ),
              ),
            ),
            splashColor: Colors.transparent,
            highlightColor: d
                ? Colors.white.withOpacity(0.03)
                : Colors.black.withOpacity(0.02),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
              child: Row(
                children: [
                  // Thumbnail carré
                  _thumb(imgUrl, d),
                  const SizedBox(width: 18),
                  // Infos
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          name.toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.3,
                            color: ink,
                            height: 1.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (loc.isNotEmpty) ...[
                          const SizedBox(height: 3),
                          Text(loc,
                              style: TextStyle(
                                  fontSize: 12, color: inkMuted, height: 1.3),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ],
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            // Followers badge proéminent
                            Text(
                              _fmt(followers as num),
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _taupe,
                                letterSpacing: -0.5,
                                height: 1,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              followers == 1 ? 'abonné' : 'abonnés',
                              style: TextStyle(
                                  fontSize: 9,
                                  color: inkMuted,
                                  letterSpacing: 1.0,
                                  fontWeight: FontWeight.w500),
                            ),
                            const Spacer(),
                            // Follow chip — minimal, borderless sur fond
                            GestureDetector(
                              onTap: () => _toggleFollowFarm(farmId),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 220),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: isFollowed ? _taupe : Colors.transparent,
                                  border:
                                      Border.all(color: isFollowed ? _taupe : _taupeLight, width: 1),
                                ),
                                child: Text(
                                  isFollowed ? 'SUIVI' : 'SUIVRE',
                                  style: TextStyle(
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1.8,
                                    color: isFollowed ? Colors.white : _taupe,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Icon(Icons.arrow_forward_ios_rounded, size: 11, color: inkMuted),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _thumb(String? imgUrl, bool d) {
    const s = 62.0;
    return SizedBox(
      width: s, height: s,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: imgUrl != null && imgUrl.isNotEmpty
            ? Image.network(imgUrl, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _thumbFallback(d))
            : _thumbFallback(d),
      ),
    );
  }

  Widget _thumbFallback(bool d) => Container(
        color: d ? _surfaceDark : _dividerLight,
        child: Center(
          child: Icon(Icons.landscape_outlined,
              size: 20, color: d ? _inkMutedDark : _taupeLight),
        ),
      );
}