import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mbaymi/services/token_storage.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/screens/farm_screen.dart';
import 'package:mbaymi/screens/create_farm_screen.dart';
import 'package:mbaymi/screens/livestock_screen.dart';
import 'package:mbaymi/screens/livestock_management_screen.dart';
import 'package:mbaymi/screens/market_screen.dart';
import 'package:mbaymi/screens/advice_screen.dart';
import 'package:mbaymi/screens/dashboard_tab.dart';
import 'package:mbaymi/screens/farm_network_screen.dart';
import 'package:mbaymi/widgets/notification_icon_widget.dart';

class HomeScreen extends StatefulWidget {
  final int? userId;
  
  const HomeScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;
  late List<Widget> _screens;

  int? _userId;

  bool get isLoggedIn => _userId != null;
  int? get userId => _userId;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;
    
    // Synchroniser _isDarkMode avec le ThemeProvider au démarrage
    Future.microtask(() {
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
      setState(() {
        _isDarkMode = themeProvider.isDarkMode;
      });
    });

    _screens = [
      DashboardTab(key: ValueKey('dashboard_${userId ?? 0}'), isDarkMode: _isDarkMode, userId: userId),
      FarmTab(key: ValueKey('farm_${userId ?? 0}'), userId: userId),
      FarmNetworkScreen(isDarkMode: _isDarkMode),
      LivestockTab(isDarkMode: _isDarkMode),
      MarketTab(isDarkMode: _isDarkMode),
      AdviceTab(isDarkMode: _isDarkMode),
    ];

    if (isLoggedIn) {
      // Profile sync will happen automatically via auth service
    }

    if (_userId == null) {
      TokenStorage.getUserId().then((v) {
        if (v != null && mounted) {
          setState(() {
            _userId = v;
            _updateScreens();
          });
        }
      });
    }
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
    _screens = [
      DashboardTab(key: ValueKey('dashboard_${userId ?? 0}'), isDarkMode: _isDarkMode, userId: userId),
      FarmTab(key: ValueKey('farm_${userId ?? 0}'), userId: userId),
      FarmNetworkScreen(isDarkMode: _isDarkMode),
      LivestockTab(isDarkMode: _isDarkMode),
      MarketTab(isDarkMode: _isDarkMode),
      AdviceTab(isDarkMode: _isDarkMode),
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser le ThemeProvider pour savoir si on est en mode sombre
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    final appBarBg = isDarkMode ? const Color(0xFF1a1a1a) : Colors.white;
    final appBarIconColor = isDarkMode ? const Color(0xFF6B8E23) : const Color(0xFF2D5016);
    
    return Scaffold(
      backgroundColor: isDarkMode ? const Color(0xFF0A0A0A) : const Color(0xFFFAFAFA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: appBarBg,
        elevation: 0,
        titleSpacing: 12,
        title: IconButton(
          icon: Icon(
            Icons.search_rounded,
            color: appBarIconColor,
            size: 24,
          ),
          onPressed: () {
            HapticFeedback.lightImpact();
            _showSearchDialog(context);
          },
        ),
        actions: [
          const NotificationIconWidget(),
          IconButton(
            icon: Icon(
              isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: appBarIconColor,
              size: 20,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              // Toggle theme via ThemeProvider (s'applique globalement)
              Provider.of<ThemeProvider>(context, listen: false).toggleDarkMode();
              setState(() {
                _isDarkMode = !_isDarkMode;
              });
            },
          ),
          IconButton(
            tooltip: 'Profil',
            icon: Icon(
              Icons.account_circle_outlined,
              color: appBarIconColor,
              size: 22,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              if (isLoggedIn && _userId != null) {
                Navigator.pushNamed(
                  context,
                  '/user-profile/$_userId',
                  arguments: {
                    'userId': _userId,
                    'isDarkMode': _isDarkMode,
                  },
                );
              } else {
                _showAuthSheet(context);
              }
            },
          ),
        ],
      ),
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: appBarBg,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 20,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_outlined, Icons.home, 'Accueil', 0, _isDarkMode),
                _buildNavItem(Icons.agriculture_outlined, Icons.agriculture, 'Fermes', 1, _isDarkMode),
                _buildCentralActionButton(),
                _buildNavItem(Icons.groups_outlined, Icons.groups, 'Réseau', 2, _isDarkMode),
                _buildNavItem(Icons.shopping_bag_outlined, Icons.shopping_bag, 'Marché', 4, _isDarkMode),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, IconData activeIcon, String label, int index, bool isDarkMode) {
    final isSelected = _selectedIndex == index;
    final activeColor = isDarkMode ? const Color(0xFF6B8E23) : const Color(0xFF2D5016);
    final inactiveColor = isDarkMode ? const Color(0xFF666666) : const Color(0xFFC0C0C0);
    final inactiveTextColor = isDarkMode ? const Color(0xFF888888) : const Color(0xFFA8A8A8);
    
    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _selectedIndex = index);
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? activeIcon : icon,
              color: isSelected ? activeColor : inactiveColor,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                letterSpacing: 0.1,
                color: isSelected ? activeColor : inactiveTextColor,
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
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF3D6B1F), Color(0xFF2D5016)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF2D5016).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(
          Icons.add_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  void _showActionMenu(BuildContext context) {
    HapticFeedback.mediumImpact();
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Nouvelle action',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: _isDarkMode ? Colors.white : const Color(0xFF2D5016),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 24),
              _buildActionButton(
                icon: Icons.local_florist,
                label: 'Ajouter une culture',
                color: const Color(0xFF6B8E23),
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ajouter une culture - Bientôt disponible')),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.agriculture,
                label: 'Ajouter une ferme',
                color: const Color(0xFF2D5016),
                onTap: () async {
                  final rootContext = this.context;
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  final result = await Navigator.push(
                    rootContext,
                    MaterialPageRoute(builder: (_) => CreateFarmScreen(userId: userId)),
                  );
                  if (result != null) {
                    if (!mounted) return;
                    setState(() {
                      _screens[1] = FarmTab(key: ValueKey('farm_${userId ?? 0}'), userId: userId);
                      _screens[0] = DashboardTab(key: ValueKey('dashboard_${userId ?? 0}'), isDarkMode: _isDarkMode, userId: userId);
                    });
                    ScaffoldMessenger.of(rootContext).showSnackBar(const SnackBar(content: Text('Ferme créée')));
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.pets,
                label: 'Ajouter un animal',
                color: const Color(0xFFD2691E),
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  if (userId != null) {
                    Navigator.push(
                      this.context,
                      MaterialPageRoute(
                        builder: (_) => LivestockManagementScreen(
                          userId: userId!,
                          isDarkMode: _isDarkMode,
                        ),
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.warning_rounded,
                label: 'Signaler un problème',
                color: const Color(0xFFE07856),
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Signaler un problème - Bientôt disponible')),
                  );
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.receipt_long,
                label: 'Noter une dépense',
                color: const Color(0xFF4A90E2),
                onTap: () {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Noter une dépense - Bientôt disponible')),
                  );
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
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
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: _isDarkMode ? Colors.white : color,
                ),
              ),
            ),
            Icon(Icons.chevron_right, color: color.withOpacity(0.4), size: 20),
          ],
        ),
      ),
    );
  }

  void _showAuthSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: _isDarkMode ? const Color(0xFF2C2C2C) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Rejoignez Mbaymi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: _isDarkMode ? Colors.white : const Color(0xFF2C2416),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 24),
            _buildAuthButton(
              'Se connecter',
              true,
              () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/login');
              },
            ),
            const SizedBox(height: 12),
            _buildAuthButton(
              'Créer un compte',
              false,
              () {
                Navigator.pop(context);
                Navigator.pushNamed(context, '/register');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildAuthButton(String label, bool isPrimary, VoidCallback onTap) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? const Color(0xFF8B7355) : Colors.white,
          foregroundColor: isPrimary ? Colors.white : const Color(0xFF8B7355),
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: isPrimary ? BorderSide.none : const BorderSide(color: Color(0xFFE5DFD7)),
          ),
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }

  void _showSearchDialog(BuildContext context) {
    final searchController = TextEditingController();
    final cardBg = _isDarkMode ? const Color(0xFF2C2C2C) : Colors.white;
    final textColor = _isDarkMode ? Colors.white : Colors.black;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: cardBg,
        title: TextField(
          controller: searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Rechercher des fermes...',
            hintStyle: TextStyle(color: Colors.grey[500]),
            prefixIcon: Icon(Icons.search_rounded, color: Colors.grey[600]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          style: TextStyle(color: textColor),
          onSubmitted: (query) {
            Navigator.pop(ctx);
            if (query.isNotEmpty) {
              setState(() => _selectedIndex = 2);
            }
          },
        ),
        content: Text(
          'Entrez votre recherche...',
          style: TextStyle(color: textColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              if (searchController.text.isNotEmpty) {
                setState(() => _selectedIndex = 2);
              }
            },
            child: const Text('Rechercher'),
          ),
        ],
      ),
    );
  }
}


