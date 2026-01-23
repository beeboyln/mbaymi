import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:mbaymi/services/token_storage.dart';
import 'package:mbaymi/services/theme_provider.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/farm_screen.dart';
import 'package:mbaymi/screens/create_farm_screen.dart';
import 'package:mbaymi/screens/livestock_screen.dart';
import 'package:mbaymi/screens/livestock_management_screen.dart';
import 'package:mbaymi/screens/market_screen.dart';
import 'package:mbaymi/screens/advice_screen.dart';
import 'package:mbaymi/screens/dashboard_tab.dart';
import 'package:mbaymi/screens/farm_network_screen.dart';
import 'package:mbaymi/screens/veterinarian_dashboard_screen.dart';
import 'package:mbaymi/screens/parcel_screen.dart';
import 'package:mbaymi/screens/parcel_finance_screen.dart';
import 'package:mbaymi/screens/select_crop_screen.dart';
import 'package:mbaymi/screens/crop_problems_screen.dart';
import 'package:mbaymi/widgets/notification_icon_widget.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/utils/app_spacing.dart';

class HomeScreen extends StatefulWidget {
  final int? userId;
  
  const HomeScreen({super.key, this.userId});

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

    // Ensure screens reflect current role (e.g. veterinarian) at startup
    if (mounted) {
      setState(() {
        _updateScreens();
      });
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
    // Check if user is a veterinarian
    final isVeterinarian = AuthService.currentSession?.role == 'veterinarian' || 
                          AuthService.currentSession?.role == 'expert';
    
    if (isVeterinarian) {
      // For veterinarians, show different screens
      _screens = [
        const VeterinarianDashboardScreen(),
        FarmNetworkScreen(isDarkMode: _isDarkMode),
        LivestockTab(isDarkMode: _isDarkMode),
        MarketTab(isDarkMode: _isDarkMode),
        AdviceTab(isDarkMode: _isDarkMode),
      ];
    } else {
      // For farmers/regular users, show the normal screens
      _screens = [
        DashboardTab(key: ValueKey('dashboard_${userId ?? 0}'), isDarkMode: _isDarkMode, userId: userId),
        FarmTab(key: ValueKey('farm_${userId ?? 0}'), userId: userId),
        FarmNetworkScreen(isDarkMode: _isDarkMode),
        LivestockTab(isDarkMode: _isDarkMode),
        MarketTab(isDarkMode: _isDarkMode),
        AdviceTab(isDarkMode: _isDarkMode),
      ];
    }
  }

  @override
  Widget build(BuildContext context) {
    // Utiliser le ThemeProvider pour savoir si on est en mode sombre
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    
    final appBarBg = AppColors.getBgColor(isDarkMode);
    final appBarIconColor = AppColors.accent;
    
    return Scaffold(
      backgroundColor: AppColors.getBgColor(isDarkMode),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: appBarBg,
        elevation: 0,
        titleSpacing: AppSpacing.md,
        title: GestureDetector(
          onTap: () {
            HapticFeedback.lightImpact();
            if (isLoggedIn && _userId != null) {
              final isVeterinarian = AuthService.currentSession?.role == 'veterinarian' ||
                  AuthService.currentSession?.role == 'expert';
              if (isVeterinarian) {
                Navigator.pushNamed(context, '/veterinarian-profile');
              } else {
                Navigator.pushNamed(
                  context,
                  '/user-profile/$_userId',
                  arguments: {
                    'userId': _userId,
                    'isDarkMode': _isDarkMode,
                  },
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
              future: _userId != null ? ApiService.getUserProfile(_userId!, viewerId: _userId) : Future.value(<String, dynamic>{}),
              builder: (context, snap) {
                final img = snap.data?['profile_image'] as String?;
                if (img != null && img.isNotEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [_isDarkMode ? const Color(0xFF8FBF6B) : const Color(0xFFf0932b), _isDarkMode ? const Color(0xFF2D5016) : const Color(0xFFc13584)],
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
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.account_circle_outlined,
                          color: appBarIconColor,
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }

                return CircleAvatar(
                  radius: 20,
                  backgroundColor: appBarBg,
                  child: Icon(
                    Icons.account_circle_outlined,
                    color: appBarIconColor,
                    size: 24,
                  ),
                );
              },
            ),
          ),
        ),
        actions: [
          NotificationIconWidget(iconColor: appBarIconColor),
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
          // Profile moved to AppBar title (avatar)
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
            child: _buildNavBar(isDarkMode),
          ),
        ),
      ),
    );
  }

  Widget _buildNavBar(bool isDarkMode) {
    final isVeterinarian = AuthService.currentSession?.role == 'veterinarian' || 
                          AuthService.currentSession?.role == 'expert';
    
    if (isVeterinarian) {
      // Veterinarian nav: Accueil → Réseau → Suivis → Conseils
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_outlined, Icons.home, 'Accueil', 0, isDarkMode),
          _buildNavItem(Icons.groups_outlined, Icons.groups, 'Réseau', 1, isDarkMode),
          _buildCentralActionButton(),
          _buildNavItem(Icons.pets_outlined, Icons.pets, 'Suivis', 2, isDarkMode),
          _buildNavItem(Icons.lightbulb_outline, Icons.lightbulb, 'Conseils', 4, isDarkMode),
        ],
      );
    } else {
      // Farmer nav: Accueil → Fermes → Réseau → Animaux → Marché
      return Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(Icons.home_outlined, Icons.home, 'Accueil', 0, isDarkMode),
          _buildNavItem(Icons.agriculture_outlined, Icons.agriculture, 'Fermes', 1, isDarkMode),
          _buildCentralActionButton(),
          _buildNavItem(Icons.groups_outlined, Icons.groups, 'Réseau', 2, isDarkMode),
          _buildNavItem(Icons.shopping_bag_outlined, Icons.shopping_bag, 'Marché', 4, isDarkMode),
        ],
      );
    }
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
          color: _isDarkMode ? const Color(0xFF2C2C2C) : AppColors.lightBg,
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
                onTap: () async {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  // Get user's farms
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez vous connecter d\'abord')),
                    );
                    return;
                  }

                  try {
                    final farms = await ApiService.getUserFarms(userId!);
                    if (!mounted) return;
                    if (farms.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Créez une ferme d\'abord')),
                      );
                      return;
                    }
                    // Si une seule ferme, ouvrir directement la modale d'ajout de culture
                    if (farms.length == 1) {
                      final farmId = farms[0]['id'] as int;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParcelScreen(
                            farmId: farmId,
                            userId: userId!,
                            openAddCultureModal: true,
                          ),
                        ),
                      );
                    } else {
                      // Sinon, demander de choisir la ferme puis ouvrir la modale
                      final rootContext = this.context;
                      _showFarmSelectionDialog(farms, (selectedFarmId) {
                        Navigator.push(
                          rootContext,
                          MaterialPageRoute(
                            builder: (_) => ParcelScreen(
                              farmId: selectedFarmId,
                              userId: userId!,
                              openAddCultureModal: true,
                            ),
                          ),
                        );
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: \'${e.toString()}\'')),
                    );
                  }
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
                onTap: () async {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez vous connecter d\'abord')),
                    );
                    return;
                  }

                  try {
                    final farms = await ApiService.getUserFarms(userId!);
                    if (!mounted) return;
                    
                    if (farms.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Créez une ferme d\'abord')),
                      );
                      return;
                    }

                    // If only one farm, go directly to crop selection
                    if (farms.length == 1) {
                      final farmId = farms[0]['id'] as int;
                      final result = await Navigator.push<Map<String, dynamic>>(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SelectCropScreen(
                            farmId: farmId,
                            userId: userId!,
                            isDarkMode: _isDarkMode,
                          ),
                        ),
                      );
                      
                      if (result != null && mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => CropProblemsScreen(
                              farmId: farmId,
                              cropId: result['cropId'] as int,
                              userId: userId!,
                              cropName: result['cropName'] as String,
                              isDarkMode: _isDarkMode,
                            ),
                          ),
                        );
                      }
                    } else {
                      // Show farm selection dialog
                      final rootContext = this.context;
                      _showFarmSelectionDialog(farms, (selectedFarmId) async {
                        final result = await Navigator.push<Map<String, dynamic>>(
                          rootContext,
                          MaterialPageRoute(
                            builder: (_) => SelectCropScreen(
                              farmId: selectedFarmId,
                              userId: userId!,
                              isDarkMode: _isDarkMode,
                            ),
                          ),
                        );
                        
                        if (result != null && mounted) {
                          Navigator.push(
                            rootContext,
                            MaterialPageRoute(
                              builder: (_) => CropProblemsScreen(
                                farmId: selectedFarmId,
                                cropId: result['cropId'] as int,
                                userId: userId!,
                                cropName: result['cropName'] as String,
                                isDarkMode: _isDarkMode,
                              ),
                            ),
                          );
                        }
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: ${e.toString()}')),
                    );
                  }
                },
              ),
              const SizedBox(height: 12),
              _buildActionButton(
                icon: Icons.receipt_long,
                label: 'Noter une dépense',
                color: const Color(0xFF4A90E2),
                onTap: () async {
                  Navigator.pop(context);
                  HapticFeedback.lightImpact();
                  
                  if (userId == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Veuillez vous connecter d\'abord')),
                    );
                    return;
                  }

                  try {
                    final farms = await ApiService.getUserFarms(userId!);
                    if (!mounted) return;
                    
                    if (farms.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Créez une ferme d\'abord')),
                      );
                      return;
                    }

                    // If only one farm, open directly
                    if (farms.length == 1) {
                      final farmId = farms[0]['id'] as int;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ParcelFinanceScreen(
                            farmId: farmId,

                          ),
                        ),
                      );
                    } else {
                      // Show farm selection dialog
                      final rootContext = this.context;
                      _showFarmSelectionDialog(farms, (selectedFarmId) {
                        Navigator.push(
                          rootContext,
                          MaterialPageRoute(
                            builder: (_) => ParcelFinanceScreen(
                              farmId: selectedFarmId,
                            ),
                          ),
                        );
                      });
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erreur: ${e.toString()}')),
                    );
                  }
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

  void _showFarmSelectionDialog(
    List<dynamic> farms,
    Function(int) onFarmSelected,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _isDarkMode ? const Color(0xFF2C2C2C) : AppColors.lightBg,
        title: Text(
          'Sélectionnez une ferme',
          style: TextStyle(
            color: _isDarkMode ? Colors.white : const Color(0xFF2D5016),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: farms.length,
            itemBuilder: (context, index) {
              final farm = farms[index];
              final farmName = farm['name'] ?? farm['farm_name'] ?? 'Ferme sans nom';
              final farmId = farm['id'] as int;
              final farmImage = farm['image_url'] ?? farm['imageUrl'];

              return GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  onFarmSelected(farmId);
                },
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 6),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    color: _isDarkMode ? const Color(0xFF3A3A3A) : Colors.grey[100],
                  ),
                  child: Row(
                    children: [
                      // Farm Image
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(8),
                          bottomLeft: Radius.circular(8),
                        ),
                        child: farmImage != null && farmImage.toString().isNotEmpty
                            ? Image.network(
                                farmImage.toString(),
                                width: 80,
                                height: 80,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    width: 80,
                                    height: 80,
                                    color: Colors.grey[400],
                                    child: Icon(
                                      Icons.landscape,
                                      color: _isDarkMode ? Colors.grey[600] : Colors.grey[700],
                                    ),
                                  );
                                },
                              )
                            : Container(
                                width: 80,
                                height: 80,
                                color: Colors.grey[400],
                                child: Icon(
                                  Icons.landscape,
                                  color: _isDarkMode ? Colors.grey[600] : Colors.grey[700],
                                ),
                              ),
                      ),
                      // Farm Name
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          child: Text(
                            farmName.toString(),
                            style: TextStyle(
                              color: _isDarkMode ? Colors.white : Colors.black87,
                              fontWeight: FontWeight.w500,
                              fontSize: 14,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
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
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Annuler',
              style: TextStyle(
                color: _isDarkMode ? Colors.white70 : Colors.black54,
              ),
            ),
          ),
        ],
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
          color: _isDarkMode ? const Color(0xFF2C2C2C) : AppColors.lightBg,
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
              'Rejoignez Savana',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w300,
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
          backgroundColor: isPrimary ? const Color.fromARGB(255, 109, 72, 55) : AppColors.lightBg,
          foregroundColor: isPrimary ? Colors.white : const Color.fromARGB(255, 139, 100, 85),
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
}


