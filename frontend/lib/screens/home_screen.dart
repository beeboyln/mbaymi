import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mbaymi/services/token_storage.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/farm/tab/farm_tab.dart';
import 'package:mbaymi/screens/farm/create_farm_screen.dart';
import 'package:mbaymi/screens/livestock/livestock_screen.dart';
import 'package:mbaymi/screens/livestock/create_livestock_screen.dart';
import 'package:mbaymi/screens/market/market_screen.dart';
import 'package:mbaymi/screens/veterinarian/advice_screen.dart';
import 'package:mbaymi/screens/dashboard_tab.dart';
import 'package:mbaymi/screens/farm/farm_network_screen.dart';
import 'package:mbaymi/screens/veterinarian/veterinarian_dashboard_screen.dart';
import 'package:mbaymi/screens/admin/admin_dashboard_screen.dart';
import 'package:mbaymi/screens/farm/parcel_screen.dart';
import 'package:mbaymi/screens/farm/parcel_finance_screen.dart';
import 'package:mbaymi/screens/farm/select_crop_screen.dart';
import 'package:mbaymi/screens/farm/crop_problems_screen.dart';
import 'package:mbaymi/screens/social/search_users_screen.dart';
import 'package:mbaymi/widgets/notification_icon_widget.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/utils/app_spacing.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mbaymi/services/notebook_service.dart';

class HomeScreen extends StatefulWidget {
  final int? userId;
  const HomeScreen({super.key, this.userId});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> with TickerProviderStateMixin {
  int _selectedIndex = 0;
  bool _headerVisible = true;
  late final AnimationController _headerController;
  late Map<int, Widget> _screens;
  late List<int> _screenIndices;

  int? _userId;
  bool _isDarkMode = false;

  bool get isLoggedIn => _userId != null;
  int? get userId => _userId;

  @override
  void initState() {
    super.initState();
    _headerController = AnimationController(
      vsync: this,
      value: 1,
      duration: const Duration(milliseconds: 260),
    );
    _userId = widget.userId;
    _screens = {};
    _screenIndices = [];
    _createDashboard();
    _updateScreens();
    
    // Sync notebooks from server on login - MUST complete before showing screens
    _initializeNotebooks();

    if (_userId == null) {
      TokenStorage.getUserId().then((v) {
        if (v != null && mounted) {
          setState(() {
            _userId = v;
            _updateScreens();
          });
          _initializeNotebooks();
        }
      });
    }
  }

  @override
  void dispose() {
    _headerController.dispose();
    super.dispose();
  }

  /// Initialize notebooks - must complete before displaying content
  Future<void> _initializeNotebooks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final notebookService = NotebookService(prefs);
      
      // WAIT for sync to complete before continuing
      final notebooks = await notebookService.syncNotebooksFromServer();
      print('[HOME] ✅ ${notebooks.length} notebooks loaded from server');
      
      if (mounted) {
        setState(() {
          // Force rebuild to show notebooks
        });
      }
    } catch (e) {
      print('[HOME] ⚠️ Failed to sync notebooks: $e');
      // Continue anyway - use local cache if sync fails
    }
  }

  void _createDashboard() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final userRole = AuthService.currentSession?.role;

    if (userRole == 'admin') {
      _screens[0] = const AdminDashboardScreen();
    } else if (userRole == 'veterinarian' || userRole == 'expert') {
      _screens[0] = const VeterinarianDashboardScreen();
    } else {
      _screens[0] = DashboardTab(
        key: ValueKey('dashboard_${userId ?? 0}'),
        isDarkMode: isDarkMode,
        userId: userId,
        onNavigateToFarmTab: () => setState(() => _selectedIndex = 1),
      );
    }
    if (!_screenIndices.contains(0)) _screenIndices.add(0);
  }

  Widget _getScreen(int index) {
    if (_screens.containsKey(index)) return _screens[index]!;
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final userRole = AuthService.currentSession?.role;
    final isAdmin = userRole == 'admin';
    final isVeterinarian = userRole == 'veterinarian' || userRole == 'expert';

    Widget screen;
    if (isAdmin) {
      screen = const AdminDashboardScreen();
    } else if (isVeterinarian) {
      switch (index) {
        case 0: screen = const VeterinarianDashboardScreen(); break;
        case 1: screen = const FarmNetworkScreen(); break;
        case 2: screen = LivestockTab(isDarkMode: isDarkMode); break;
        case 3: screen = AdviceTab(isDarkMode: isDarkMode); break;
        default: screen = const Placeholder();
      }
    } else {
      switch (index) {
        case 0:
          screen = DashboardTab(
            key: ValueKey('dashboard_${userId ?? 0}'),
            isDarkMode: isDarkMode,
            userId: userId,
            onNavigateToFarmTab: () => setState(() => _selectedIndex = 1),
          );
          break;
        case 1: screen = FarmTab(key: ValueKey('farm_${userId ?? 0}'), userId: userId); break;
        case 2: screen = const FarmNetworkScreen(); break;
        case 3: screen = LivestockTab(isDarkMode: isDarkMode); break;
        case 4: screen = MarketTab(isDarkMode: isDarkMode); break;
        case 5: screen = AdviceTab(isDarkMode: isDarkMode); break;
        default: screen = const Placeholder();
      }
    }

    _screens[index] = screen;
    if (!_screenIndices.contains(index)) _screenIndices.add(index);
    return screen;
  }

  @override
  void didUpdateWidget(HomeScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.userId != widget.userId) {
      _userId = widget.userId;
      _updateScreens();
    }
  }

  void _updateScreens() {
    final isVeterinarian = AuthService.currentSession?.role == 'veterinarian' ||
        AuthService.currentSession?.role == 'expert';
    if (isVeterinarian && _screens.containsKey(4)) {
      _screens.remove(4);
      _screens.remove(5);
    }
    _createDashboard();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    if (notification is! ScrollUpdateNotification) return false;
    final delta = notification.scrollDelta ?? 0;
    if (delta.abs() < 2) return false;
    final shouldShow = delta < 0 || notification.metrics.pixels <= 0;
    if (shouldShow != _headerVisible && mounted) {
      setState(() => _headerVisible = shouldShow);
      _headerController.animateTo(shouldShow ? 1 : 0, curve: Curves.easeOutCubic);
    }
    return false;
  }

  // ─── AUTH GUARD — même comportement pour toutes les actions ──────────────
  /// Returns true if user is logged in, otherwise shows the auth sheet
  bool _requireAuth(BuildContext ctx) {
    if (isLoggedIn && userId != null) return true;
    _showAuthSheet(ctx);
    return false;
  }

  // ─────────────────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    _isDarkMode = isDarkMode;

    final isVeterinarian = AuthService.currentSession?.role == 'veterinarian' ||
        AuthService.currentSession?.role == 'expert';
    final appBarBg = isVeterinarian
        ? (isDarkMode ? const Color(0xFF060E0D) : const Color(0xFFF4FAF9))
        : AppColors.getBgColor(isDarkMode);

    return AnimatedBuilder(
      animation: _headerController,
      builder: (context, child) => PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) setState(() {});
      },
      child: Scaffold(
        backgroundColor: AppColors.getBgColor(isDarkMode),
        appBar: PreferredSize(
          preferredSize: Size.fromHeight(kToolbarHeight * _headerController.value),
          child: ClipRect(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOutCubic,
              height: kToolbarHeight * _headerController.value,
              child: _buildAppBar(isDarkMode, appBarBg),
            ),
          ),
        ),
        body: NotificationListener<ScrollNotification>(
          onNotification: _handleScrollNotification,
          child: _getScreen(_selectedIndex),
        ),
        bottomNavigationBar: _buildBottomBar(isDarkMode, appBarBg, isVeterinarian),
      ),
      ),
    );
  }

  // ─── APP BAR ──────────────────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool isDarkMode, Color appBarBg) {
    const iconColor = AppColors.accent;

    return AppBar(
      automaticallyImplyLeading: false,
      backgroundColor: appBarBg,
      elevation: 0,
      titleSpacing: AppSpacing.md,
      title: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          if (isLoggedIn && _userId != null) {
            final isVet = AuthService.currentSession?.role == 'veterinarian' ||
                AuthService.currentSession?.role == 'expert';
            if (isVet) {
              Navigator.pushNamed(context, '/veterinarian-profile');
            } else {
              Navigator.pushNamed(
                context,
                '/user-profile/$_userId',
                arguments: {'userId': _userId, 'isDarkMode': isDarkMode},
              );
            }
          } else {
            _showAuthSheet(context);
          }
        },
        child: SizedBox(
          width: 44,
          height: 44,
          child: FutureBuilder<Map<String, dynamic>>(
            future: _userId != null
                ? ApiService.getUserProfile(_userId!, viewerId: _userId)
                : Future.value(<String, dynamic>{}),
            builder: (context, snap) {
              final img = snap.data?['profile_image'] as String?;
              if (img != null && img.isNotEmpty) {
                return Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        isDarkMode ? const Color(0xFF8FBF6B) : const Color(0xFFf0932b),
                        isDarkMode ? const Color(0xFF2D5016) : const Color(0xFFc13584),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Image.network(
                      img,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => const Icon(
                        Icons.account_circle_outlined,
                        color: iconColor,
                        size: 24,
                      ),
                    ),
                  ),
                );
              }
              return CircleAvatar(
                radius: 20,
                backgroundColor: appBarBg,
                child: const Icon(
                  Icons.account_circle_outlined,
                  color: iconColor,
                  size: 24,
                ),
              );
            },
          ),
        ),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.search, color: iconColor),
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => SearchUsersScreen(isDarkMode: _isDarkMode),
            ),
          ),
        ),
        const NotificationIconWidget(iconColor: iconColor),
        IconButton(
          icon: const Icon(Icons.menu, color: iconColor, size: 24),
          onPressed: () {
            HapticFeedback.lightImpact();
            Navigator.pushNamed(context, '/settings');
          },
        ),
      ],
    );
  }

  // ─── BOTTOM BAR ───────────────────────────────────────────────────────────
  Widget _buildBottomBar(bool isDarkMode, Color bg, bool isVeterinarian) {
    return Container(
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          top: BorderSide(
            color: isDarkMode
                ? AppColors.borderDark
                : AppColors.borderLight,
            width: 0.5,
          ),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: isVeterinarian
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home_outlined, Icons.home, 'Accueil', 0, isDarkMode),
                    _buildNavItem(Icons.groups_outlined, Icons.groups, 'Réseau', 1, isDarkMode),
                    _buildCentralActionButton(),
                    _buildNavItem(Icons.pets_outlined, Icons.pets, 'Suivis', 2, isDarkMode),
                    _buildNavItem(Icons.lightbulb_outline, Icons.lightbulb, 'Conseils', 3, isDarkMode),
                  ],
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home_outlined, Icons.home, 'Accueil', 0, isDarkMode),
                    _buildNavItem(Icons.agriculture_outlined, Icons.agriculture, 'Fermes', 1, isDarkMode),
                    _buildCentralActionButton(),
                    _buildNavItem(Icons.groups_outlined, Icons.groups, 'Réseau', 2, isDarkMode),
                    _buildNavItem(Icons.shopping_bag_outlined, Icons.shopping_bag, 'Marché', 4, isDarkMode),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    IconData activeIcon,
    String label,
    int index,
    bool isDarkMode,
  ) {
    final isSelected = _selectedIndex == index;
    final inactiveColor = isDarkMode
        ? const Color(0xFF666666)
        : const Color(0xFFC0C0C0);
    final inactiveText = isDarkMode
        ? const Color(0xFF888888)
        : const Color(0xFFA8A8A8);

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedIndex = index);
      },
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(0.08)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? AppColors.primary : inactiveColor,
              size: 22,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                letterSpacing: 0.1,
                color: isSelected ? AppColors.primary : inactiveText,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCentralActionButton() {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        _showActionMenu(context);
      },
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.28),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 26,
        ),
      ),
    );
  }

  // ─── ACTION MENU — redesigné dans le style dashboard ─────────────────────
  void _showActionMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _ActionMenuSheet(
        isDarkMode: _isDarkMode,
        isLoggedIn: isLoggedIn,
        userId: userId,
        onRequireAuth: () => _showAuthSheet(ctx),
        onFarmCreated: (result) {
          if (!mounted) return;
          setState(() {
            _screens[1] = FarmTab(
              key: ValueKey('farm_${userId ?? 0}'),
              userId: userId,
            );
            _screens[0] = DashboardTab(
              key: ValueKey('dashboard_${userId ?? 0}'),
              isDarkMode: _isDarkMode,
              userId: userId,
              onNavigateToFarmTab: () => setState(() => _selectedIndex = 1),
            );
          });
          ScaffoldMessenger.of(this.context).showSnackBar(
            AppColors.createSnackBar(
              message: 'Ferme créée avec succès',
              isError: false,
              durationMs: 800,
            ),
          );
        },
        isDarkModeRef: () => _isDarkMode,
        getUserFarms: () => ApiService.getUserFarms(),
        homeContext: this.context,
      ),
    );
  }

  // ─── FARM SELECTION DIALOG ────────────────────────────────────────────────
  void _showFarmSelectionDialog(
    List<dynamic> farms,
    Function(int) onFarmSelected,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: _isDarkMode ? AppColors.darkCardBg : AppColors.lightBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sélectionnez une ferme',
          style: TextStyle(
            color: _isDarkMode ? AppColors.textDark : AppColors.textLight,
            fontWeight: FontWeight.w400,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: farms.length,
            itemBuilder: (_, index) {
              final farm = farms[index];
              final farmName =
                  farm['name'] ?? farm['farm_name'] ?? 'Ferme sans nom';
              final farmId = farm['id'] as int;
              final farmImage = farm['image_url'] ?? farm['imageUrl'];

              return GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  onFarmSelected(farmId);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 5),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: _isDarkMode
                        ? AppColors.darkCardBg
                        : const Color(0xFFF5F2ED),
                    border: Border.all(
                      color: _isDarkMode
                          ? AppColors.borderDark
                          : AppColors.borderLight,
                    ),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(9),
                          bottomLeft: Radius.circular(9),
                        ),
                        child: farmImage != null &&
                                farmImage.toString().isNotEmpty
                            ? Image.network(
                                farmImage.toString(),
                                width: 70,
                                height: 70,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _farmImagePlaceholder(),
                              )
                            : _farmImagePlaceholder(),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          child: Text(
                            farmName.toString(),
                            style: TextStyle(
                              color: _isDarkMode
                                  ? AppColors.textDark
                                  : AppColors.textLight,
                              fontWeight: FontWeight.w400,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: _isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          size: 18,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: _isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w300,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _farmImagePlaceholder() {
    return Container(
      width: 70,
      height: 70,
      color: _isDarkMode
          ? AppColors.borderDark
          : AppColors.borderLight,
      child: Icon(
        Icons.landscape_outlined,
        color: _isDarkMode
            ? AppColors.textSecondaryDark
            : AppColors.textSecondaryLight,
        size: 24,
      ),
    );
  }

  // ─── AUTH SHEET ───────────────────────────────────────────────────────────
  void _showAuthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: _isDarkMode ? AppColors.darkCardBg : AppColors.lightBg,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Handle
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: (_isDarkMode ? AppColors.borderDark : AppColors.borderLight),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 28),
            // Icon
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.lock_outline_rounded,
                color: AppColors.primary,
                size: 24,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Connexion requise',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: _isDarkMode ? AppColors.textDark : AppColors.textLight,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Créez un compte ou connectez-vous\npour accéder à cette fonctionnalité.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w300,
                color: _isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                height: 1.55,
              ),
            ),
            const SizedBox(height: 28),
            // Se connecter
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Material(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/login');
                  },
                  child: const Center(
                    child: Text(
                      'Se connecter',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: Colors.white,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Créer un compte
            SizedBox(
              width: double.infinity,
              height: 48,
              child: Material(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.pushNamed(context, '/register');
                  },
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isDarkMode
                            ? AppColors.borderDark
                            : AppColors.borderLight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        'Créer un compte',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w300,
                          color: _isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// ACTION MENU SHEET — widget séparé pour la lisibilité
// ─────────────────────────────────────────────────────────────────────────────
class _ActionMenuSheet extends StatelessWidget {
  final bool isDarkMode;
  final bool isLoggedIn;
  final int? userId;
  final VoidCallback onRequireAuth;
  final void Function(Map<String, dynamic>) onFarmCreated;
  final bool Function() isDarkModeRef;
  final Future<List<dynamic>> Function() getUserFarms;
  final BuildContext homeContext;

  const _ActionMenuSheet({
    required this.isDarkMode,
    required this.isLoggedIn,
    required this.userId,
    required this.onRequireAuth,
    required this.onFarmCreated,
    required this.isDarkModeRef,
    required this.getUserFarms,
    required this.homeContext,
  });

  // Consistent auth guard used by every action
  bool _requireAuth(BuildContext ctx) {
    if (isLoggedIn && userId != null) return true;
    Navigator.pop(ctx);
    onRequireAuth();
    return false;
  }

  Future<T> _withLoading<T>(Future<T> Function() action) async {
    showDialog<void>(
      context: homeContext,
      barrierDismissible: false,
      builder: (_) => _ActionLoadingDialog(isDarkMode: isDarkMode),
    );
    try {
      return await action();
    } finally {
      if (Navigator.of(homeContext, rootNavigator: true).canPop()) {
        Navigator.of(homeContext, rootNavigator: true).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bg = isDarkMode ? AppColors.darkCardBg : AppColors.lightBg;
    final textPrimary =
        isDarkMode ? AppColors.textDark : AppColors.textLight;
    final textSec = isDarkMode
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;
    final border =
        isDarkMode ? AppColors.borderDark : AppColors.borderLight;

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        border: Border(top: BorderSide(color: border, width: 0.5)),
      ),
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Header row
              Row(
                children: [
                  Container(width: 18, height: 1, color: AppColors.primary),
                  const SizedBox(width: 8),
                  Text(
                    'NOUVELLE ACTION',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2.8,
                      color: textSec,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      height: 1,
                      color: AppColors.primary.withOpacity(0.12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Actions
              _buildAction(
                context: context,
                icon: Icons.agriculture_outlined,
                label: 'Ajouter une ferme',
                sublabel: 'Créer et gérer une exploitation',
                color: AppColors.primary,
                onTap: () async {
                  if (!_requireAuth(context)) return;
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  final result = await Navigator.push<Map<String, dynamic>>(
                    homeContext,
                    MaterialPageRoute(
                      builder: (_) => CreateFarmScreen(userId: userId),
                    ),
                  );
                  if (result != null) onFarmCreated(result);
                },
              ),
              const SizedBox(height: 8),

              _buildAction(
                context: context,
                icon: Icons.local_florist_outlined,
                label: 'Ajouter une culture',
                sublabel: 'Associer une culture à une parcelle',
                color: AppColors.primary,
                onTap: () async {
                  if (!_requireAuth(context)) return;
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  try {
                    final farms = await _withLoading(getUserFarms);
                    if (farms.isEmpty) {
                      ScaffoldMessenger.of(homeContext).showSnackBar(
                        AppColors.createSnackBar(
                          message: 'Créez une ferme d\'abord',
                          isError: true,
                        ),
                      );
                      return;
                    }
                    if (farms.length == 1) {
                      Navigator.push(
                        homeContext,
                        MaterialPageRoute(
                          builder: (_) => ParcelScreen(
                            farmId: farms[0]['id'] as int,
                            userId: userId!,
                            openAddCultureModal: true,
                          ),
                        ),
                      );
                    } else {
                      _showFarmPicker(homeContext, farms, (id) {
                        Navigator.push(
                          homeContext,
                          MaterialPageRoute(
                            builder: (_) => ParcelScreen(
                              farmId: id,
                              userId: userId!,
                              openAddCultureModal: true,
                            ),
                          ),
                        );
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(homeContext).showSnackBar(
                      AppColors.createSnackBar(
                        message: 'Erreur : ${e.toString()}',
                        isError: true,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),

              _buildAction(
  context: context,
  icon: Icons.pets_outlined,
  label: 'Ajouter un animal',
  sublabel: 'Gérer votre cheptel',
  color: AppColors.accent,
  onTap: () {
    if (!_requireAuth(context)) return;
    Navigator.pop(context);
    HapticFeedback.lightImpact();
    Navigator.push(
      homeContext,
      MaterialPageRoute(
        builder: (_) => CreateLivestockScreen(userId: userId),
      ),
    );
  },
),            const SizedBox(height: 8),

              _buildAction(
                context: context,
                icon: Icons.warning_amber_outlined,
                label: 'Signaler un problème',
                sublabel: 'Déclarer un problème sur une culture',
                color: const Color(0xFFE07856),
                onTap: () async {
                  if (!_requireAuth(context)) return;
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  try {
                    final farms = await _withLoading(getUserFarms);
                    if (farms.isEmpty) {
                      ScaffoldMessenger.of(homeContext).showSnackBar(
                        AppColors.createSnackBar(
                          message: 'Créez une ferme d\'abord',
                          isError: true,
                        ),
                      );
                      return;
                    }
                    Future<void> openCropProblem(int farmId) async {
                      final result =
                          await Navigator.push<Map<String, dynamic>>(
                        homeContext,
                        MaterialPageRoute(
                          builder: (_) => SelectCropScreen(
                            farmId: farmId,
                            userId: userId!,
                            isDarkMode: isDarkModeRef(),
                          ),
                        ),
                      );
                      if (result != null) {
                        Navigator.push(
                          homeContext,
                          MaterialPageRoute(
                            builder: (_) => CropProblemsScreen(
                              farmId: farmId,
                              cropId: result['cropId'] as int,
                              userId: userId!,
                              cropName: result['cropName'] as String,
                              isDarkMode: isDarkModeRef(),
                            ),
                          ),
                        );
                      }
                    }

                    if (farms.length == 1) {
                      await openCropProblem(farms[0]['id'] as int);
                    } else {
                      _showFarmPicker(
                          homeContext, farms, (id) => openCropProblem(id));
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(homeContext).showSnackBar(
                      AppColors.createSnackBar(
                        message: 'Erreur : ${e.toString()}',
                        isError: true,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 8),

              _buildAction(
                context: context,
                icon: Icons.receipt_long_outlined,
                label: 'Noter une dépense',
                sublabel: 'Suivre les finances de votre ferme',
                color: const Color(0xFF4A90E2),
                onTap: () async {
                  if (!_requireAuth(context)) return;
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  try {
                    final farms = await _withLoading(getUserFarms);
                    if (farms.isEmpty) {
                      ScaffoldMessenger.of(homeContext).showSnackBar(
                        AppColors.createSnackBar(
                          message: 'Créez une ferme d\'abord',
                          isError: true,
                        ),
                      );
                      return;
                    }
                    if (farms.length == 1) {
                      Navigator.push(
                        homeContext,
                        MaterialPageRoute(
                          builder: (_) => ParcelFinanceScreen(
                            farmId: farms[0]['id'] as int,
                          ),
                        ),
                      );
                    } else {
                      _showFarmPicker(homeContext, farms, (id) {
                        Navigator.push(
                          homeContext,
                          MaterialPageRoute(
                            builder: (_) => ParcelFinanceScreen(farmId: id),
                          ),
                        );
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(homeContext).showSnackBar(
                      AppColors.createSnackBar(
                        message: 'Erreur : ${e.toString()}',
                        isError: true,
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── ACTION ITEM ──────────────────────────────────────────────────────────
  Widget _buildAction({
    required BuildContext context,
    required IconData icon,
    required String label,
    required String sublabel,
    required Color color,
    required VoidCallback onTap,
  }) {
    final bg = isDarkMode ? AppColors.darkCardBg : const Color(0xFFFAF8F4);
    final border = isDarkMode ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDarkMode ? AppColors.textDark : AppColors.textLight;
    final textSec = isDarkMode
        ? AppColors.textSecondaryDark
        : AppColors.textSecondaryLight;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: border, width: 0.5),
        ),
        child: Row(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: textPrimary,
                      letterSpacing: 0.1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sublabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w300,
                      color: textSec,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: textSec,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  // ─── FARM PICKER ──────────────────────────────────────────────────────────
  void _showFarmPicker(
     BuildContext ctx,
     List<dynamic> farms,
     void Function(int) onSelected,
   ) {
    final bg = isDarkMode ? AppColors.darkCardBg : AppColors.lightBg;
    final border = isDarkMode ? AppColors.borderDark : AppColors.borderLight;
    final textPrimary = isDarkMode ? AppColors.textDark : AppColors.textLight;

    showDialog(
      context: ctx,
      builder: (_) => AlertDialog(
        backgroundColor: bg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Sélectionnez une ferme',
          style: TextStyle(
            color: textPrimary,
            fontWeight: FontWeight.w400,
            fontSize: 18,
            letterSpacing: -0.3,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: farms.length,
            itemBuilder: (_, index) {
              final farm = farms[index];
              final name =
                  farm['name'] ?? farm['farm_name'] ?? 'Ferme sans nom';
              final farmId = farm['id'] as int;
              final img = farm['image_url'] ?? farm['imageUrl'];
              return GestureDetector(
                onTap: () {
                  Navigator.pop(ctx);
                  onSelected(farmId);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: isDarkMode
                        ? AppColors.darkBg
                        : const Color(0xFFF5F2ED),
                    border: Border.all(color: border, width: 0.5),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(9),
                          bottomLeft: Radius.circular(9),
                        ),
                        child: img != null && img.toString().isNotEmpty
                            ? Image.network(
                                img.toString(),
                                width: 64,
                                height: 64,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _imgPlaceholder(border),
                              )
                            : _imgPlaceholder(border),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 8),
                          child: Text(
                            name.toString(),
                            style: TextStyle(
                              color: textPrimary,
                              fontWeight: FontWeight.w400,
                              fontSize: 15,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.only(right: 12),
                        child: Icon(
                          Icons.chevron_right_rounded,
                          color: isDarkMode
                              ? AppColors.textSecondaryDark
                              : AppColors.textSecondaryLight,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: isDarkMode
                    ? AppColors.textSecondaryDark
                    : AppColors.textSecondaryLight,
                fontWeight: FontWeight.w300,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _imgPlaceholder(Color border) => Container(
        width: 64,
        height: 64,
        color: border,
        child: Icon(
          Icons.landscape_outlined,
          color: isDarkMode
              ? AppColors.textSecondaryDark
              : AppColors.textSecondaryLight,
          size: 22,
        ),
      );
}

class _ActionLoadingDialog extends StatelessWidget {
  final bool isDarkMode;

  const _ActionLoadingDialog({required this.isDarkMode});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Center(
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            color: (isDarkMode ? AppColors.darkCardBg : AppColors.lightBg).withOpacity(0.94),
            shape: BoxShape.circle,
          ),
          child: const Padding(
            padding: EdgeInsets.all(16),
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: AppColors.primary,
            ),
          ),
        ),
      ),
    );
  }
}