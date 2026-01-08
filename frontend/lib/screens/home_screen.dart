import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_storage.dart';
// moved: market UI moved to separate screen
import 'package:mbaymi/models/news_model.dart';
import 'package:mbaymi/screens/news_detail_screen.dart';
import 'package:mbaymi/screens/farm_screen.dart';
import 'package:mbaymi/screens/create_farm_screen.dart';
import 'package:mbaymi/screens/livestock_screen.dart';
import 'package:mbaymi/screens/market_screen.dart';
import 'package:mbaymi/screens/advice_screen.dart';
import 'package:mbaymi/screens/dashboard_tab.dart';
import 'package:mbaymi/screens/farm_network_screen.dart';
// shared empty state is now in widgets/empty_state.dart

class HomeScreen extends StatefulWidget {
  final int? userId;
  
  const HomeScreen({Key? key, this.userId}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;
  bool _isDarkMode = false;
  late final List<Widget> _screens;

  int? _userId;

  bool get isLoggedIn => _userId != null;
  int? get userId => _userId;

  @override
  void initState() {
    super.initState();
    _userId = widget.userId;

    // If no userId provided by route, try to restore from storage
    if (_userId == null) {
      AuthStorage.getUserId().then((v) {
        if (v != null && mounted) {
          setState(() {
            _userId = v;
            // rebuild screens with user context
            _screens[0] = DashboardTab(isDarkMode: _isDarkMode, userId: _userId);
            _screens[1] = FarmTab(isDarkMode: _isDarkMode, userId: _userId);
          });
        }
      });
    }

    _screens = [
      DashboardTab(isDarkMode: _isDarkMode, userId: userId),
      FarmTab(isDarkMode: _isDarkMode, userId: userId),
      FarmNetworkScreen(isDarkMode: _isDarkMode),
      LivestockTab(isDarkMode: _isDarkMode),
      MarketTab(isDarkMode: _isDarkMode),
      AdviceTab(isDarkMode: _isDarkMode),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _isDarkMode ? const Color(0xFF1a1a1a) : const Color(0xFFFAFAFA);
    final appBarBg = _isDarkMode ? const Color(0xFF2a2a2a) : Colors.white;
    final appBarIconColor = _isDarkMode ? const Color(0xFF6B8E23) : const Color(0xFF2D5016);
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: appBarBg,
        title: const Text(
          'Mbaymi',
          style: TextStyle(
            fontWeight: FontWeight.w300,
            letterSpacing: 0.5,
            color: Color.fromARGB(172, 45, 80, 22),
            fontSize: 15,
          ),
        ),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(
              _isDarkMode ? Icons.light_mode_outlined : Icons.dark_mode_outlined,
              color: appBarIconColor,
              size: 22,
            ),
            onPressed: () {
              HapticFeedback.lightImpact();
              setState(() {
                _isDarkMode = !_isDarkMode;
                // Rebuild screens with new theme
                _screens[0] = DashboardTab(isDarkMode: _isDarkMode, userId: userId);
                _screens[1] = FarmTab(isDarkMode: _isDarkMode, userId: userId);
                _screens[2] = LivestockTab(isDarkMode: _isDarkMode);
                _screens[3] = MarketTab(isDarkMode: _isDarkMode);
                _screens[4] = AdviceTab(isDarkMode: _isDarkMode);
              });
            },
          ),
          // Single auth button: shows 'Se connecter' or 'Se déconnecter'
          TextButton(
            onPressed: () async {
              if (isLoggedIn) {
                // logout
                await AuthStorage.clear();
                if (!mounted) return;
                setState(() {
                  _userId = null;
                  // rebuild screens without user
                  _screens[0] = DashboardTab(isDarkMode: _isDarkMode, userId: null);
                  _screens[1] = FarmTab(isDarkMode: _isDarkMode, userId: null);
                });
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Déconnecté')));
              } else {
                // navigate to login
                Navigator.of(context).pushNamed('/login');
              }
            },
            child: Text(
              isLoggedIn ? 'Se déconnecter' : 'Se connecter',
              style: TextStyle(color: appBarIconColor, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
      body: _screens[_selectedIndex],
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
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Bottom nav items
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildNavItem(Icons.home_outlined, Icons.home, 'Accueil', 0, _isDarkMode),
                    _buildNavItem(Icons.agriculture_outlined, Icons.agriculture, 'Fermes', 1, _isDarkMode),
                    const SizedBox(width: 60), // Space for FAB
                    _buildNavItem(Icons.groups_outlined, Icons.groups, 'Réseau', 2, _isDarkMode),
                    _buildNavItem(Icons.pets_outlined, Icons.pets, 'Élevage', 3, _isDarkMode),
                  ],
                ),
                // Central action button
                GestureDetector(
                  onTap: () => _showActionMenu(context),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3D6B1F), Color(0xFF2D5016)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF2D5016).withOpacity(0.35),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.add,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
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
    
    return Expanded(
      child: InkWell(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _selectedIndex = index);
        },
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                isSelected ? activeIcon : icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 26,
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w300,
                  letterSpacing: 0.2,
                  color: isSelected ? activeColor : inactiveTextColor,
                ),
              ),
            ],
          ),
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
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
              const Text(
                'Nouvelle action',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w300,
                  color: Color(0xFF2D5016),
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
                  // Capture the state context so we don't try to use the bottom-sheet's
                  // (possibly disposed) context after awaiting navigation.
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
                      _screens[1] = FarmTab(isDarkMode: _isDarkMode, userId: userId);
                      _screens[0] = DashboardTab(isDarkMode: _isDarkMode, userId: userId);
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
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ajouter un animal - Bientôt disponible')),
                  );
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
                  fontWeight: FontWeight.w300,
                  color: color,
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
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
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
            const Text(
              'Rejoignez Mbaymi',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
                color: Color(0xFF2C2416),
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
            fontWeight: FontWeight.w400,
            letterSpacing: 0.2,
          ),
        ),
      ),
    );
  }
}



