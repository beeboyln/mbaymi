import 'package:flutter/material.dart';
import 'package:mbaymi/models/veterinarian_model.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/token_storage.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/widgets/skeleton_loader.dart';
import 'package:url_launcher/url_launcher.dart';

class VeterinarianProfileDetailScreen extends StatefulWidget {
  final String veterinarianId;

  const VeterinarianProfileDetailScreen({
    super.key,
    required this.veterinarianId,
  });

  @override
  State<VeterinarianProfileDetailScreen> createState() =>
      _VeterinarianProfileDetailScreenState();
}

class _VeterinarianProfileDetailScreenState
    extends State<VeterinarianProfileDetailScreen> {
  late Future<VeterinarianProfile?> _profileFuture;
  bool _isAuthorized = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _profileFuture = ApiService.getVeterinarianProfileById(
        int.tryParse(widget.veterinarianId) ?? 0);
    _checkAuthorizationStatus();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _checkAuthorizationStatus() async {
    // TODO: Implement check if current user has authorized this veterinarian
  }

  Future<void> _requestAuthorization() async {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AuthorizationBottomSheet(
        veterinarianId: widget.veterinarianId,
        onSuccess: () {
          setState(() {
            _isAuthorized = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Demande envoyée avec succès'),
              backgroundColor: Theme.of(context).primaryColor,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.all(16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        },
      ),
    );
  }

  void _contactVeterinarian(VeterinarianProfile profile) async {
    // TODO: Implement actual contact methods
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Contact par ${_getContactMethodLabel(profile.contactPreference)}'),
        backgroundColor: Theme.of(context).primaryColor,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  String _getContactMethodLabel(String method) {
    switch (method) {
      case 'whatsapp':
        return 'WhatsApp';
      case 'call':
        return 'Appel';
      case 'email':
        return 'Email';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBgColor(isDark),
      body: FutureBuilder<VeterinarianProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return SkeletonPageLoader(
              isDarkMode: isDark,
              includeAppBar: true,
              cardCount: 5,
            );
          }

          if (snapshot.hasError) {
            return _ErrorState(
              error: snapshot.error.toString(),
              onRetry: () => setState(() {
                _profileFuture = ApiService.getVeterinarianProfileById(
                    int.tryParse(widget.veterinarianId) ?? 0);
              }),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const _EmptyState();
          }

          final profile = snapshot.data!;

          return CustomScrollView(
            controller: _scrollController,
            slivers: [
              // App Bar minimaliste
              SliverAppBar(
                expandedHeight: 0,
                floating: true,
                pinned: true,
                elevation: 0,
                backgroundColor: AppColors.getBgColor(isDark),
                leading: IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: const Icon(Icons.share_outlined),
                    onPressed: () => _shareProfile(profile),
                  ),
                ],
              ),

              // Contenu avec background cohérent
              SliverFillRemaining(
                hasScrollBody: false,
                child: Container(
                  color: AppColors.getBgColor(isDark),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                      // Header simple avec avatar
                      _MinimalHeader(profile: profile),
                      
                      const SizedBox(height: 32),
                      
                      // Stats en ligne
                      _InlineStats(profile: profile),
                      
                      const SizedBox(height: 32),
                      
                      // Biographie
                      if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                        _SectionContent(
                          title: 'À propos',
                          child: Text(
                            profile.bio!,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.6,
                              color: theme.colorScheme.onSurface.withOpacity(0.7),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],
                      
                      // Zone de couverture
                      _SectionContent(
                        title: 'Zone de couverture',
                        child: _CoverageInfo(profile: profile),
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Contact
                      _SectionContent(
                        title: 'Contact',
                        child: _MinimalContactCard(
                          profile: profile,
                          onContact: () => _contactVeterinarian(profile),
                        ),
                      ),
                      
                      const SizedBox(height: 40),
                      
                      // Bouton d'action principal
                      _PrimaryActionButton(
                        isAuthorized: _isAuthorized,
                        onRequestAccess: _requestAuthorization,
                      ),
                      
                      const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  void _shareProfile(VeterinarianProfile profile) {
    // TODO: Implement share functionality
  }
}

// ============================
// COMPOSANTS MINIMALISTES
// ============================

class _MinimalHeader extends StatelessWidget {
  final VeterinarianProfile profile;

  const _MinimalHeader({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar avec initiale
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                theme.colorScheme.primary,
                theme.colorScheme.primary.withOpacity(0.7),
              ],
            ),
          ),
          child: Center(
            child: Text(
              profile.specialty.substring(0, 1).toUpperCase(),
              style: const TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
        ),
        
        const SizedBox(height: 20),
        
        // Spécialité
        Text(
          profile.specialty,
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Badge vérifié
        if (profile.isVerified)
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.verified,
                size: 18,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Vérifié',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.primary,
                ),
              ),
            ],
          ),
      ],
    );
  }
}

class _InlineStats extends StatelessWidget {
  final VeterinarianProfile profile;

  const _InlineStats({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dividerColor = theme.colorScheme.onSurface.withOpacity(0.1);
    
    return IntrinsicHeight(
      child: Row(
        children: [
          _StatItem(
            value: '${profile.consultationCount ?? 0}',
            label: 'Consultations',
          ),
          VerticalDivider(color: dividerColor, thickness: 1, width: 32),
          _StatItem(
            value: profile.rating?.toStringAsFixed(1) ?? 'N/A',
            label: 'Note',
          ),
          VerticalDivider(color: dividerColor, thickness: 1, width: 32),
          _StatItem(
            value: '${profile.experienceYears} ans',
            label: 'Expérience',
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String value;
  final String label;

  const _StatItem({
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionContent extends StatelessWidget {
  final String title;
  final Widget child;

  const _SectionContent({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.3,
          ),
        ),
        const SizedBox(height: 16),
        child,
      ],
    );
  }
}

class _CoverageInfo extends StatelessWidget {
  final VeterinarianProfile profile;

  const _CoverageInfo({required this.profile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _InfoRow(
          icon: Icons.location_on,
          label: profile.zone,
        ),
        const SizedBox(height: 12),
        _InfoRow(
          icon: Icons.route,
          label: 'Rayon d\'intervention : ${profile.distanceMax} km',
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;

  const _InfoRow({
    required this.icon,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Row(
      children: [
        Icon(
          icon,
          size: 20,
          color: theme.colorScheme.onSurface.withOpacity(0.5),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 15,
              color: theme.colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
        ),
      ],
    );
  }
}

class _MinimalContactCard extends StatelessWidget {
  final VeterinarianProfile profile;
  final VoidCallback onContact;

  const _MinimalContactCard({
    required this.profile,
    required this.onContact,
  });

  IconData _getContactIcon(String method) {
    switch (method) {
      case 'whatsapp':
        return Icons.chat_bubble_outline;
      case 'call':
        return Icons.phone;
      case 'email':
        return Icons.email_outlined;
      default:
        return Icons.message;
    }
  }

  String _getContactLabel(String method) {
    switch (method) {
      case 'whatsapp':
        return 'WhatsApp';
      case 'call':
        return 'Appel téléphonique';
      case 'email':
        return 'Email';
      default:
        return method;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return InkWell(
      onTap: onContact,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: theme.colorScheme.onSurface.withOpacity(0.1),
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              _getContactIcon(profile.contactPreference),
              size: 24,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                _getContactLabel(profile.contactPreference),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryActionButton extends StatelessWidget {
  final bool isAuthorized;
  final VoidCallback onRequestAccess;

  const _PrimaryActionButton({
    required this.isAuthorized,
    required this.onRequestAccess,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    if (isAuthorized) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.green.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: Colors.green.withOpacity(0.3),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle, color: Colors.green, size: 24),
            const SizedBox(width: 12),
            const Text(
              'Accès autorisé',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.green,
              ),
            ),
          ],
        ),
      );
    }
    
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: onRequestAccess,
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          'Demander l\'accès',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;

  const _ErrorState({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red.withOpacity(0.5),
            ),
            const SizedBox(height: 24),
            const Text(
              'Erreur de chargement',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
              ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Retour'),
                ),
                const SizedBox(width: 16),
                ElevatedButton(
                  onPressed: onRetry,
                  child: const Text('Réessayer'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.person_off_outlined,
            size: 64,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
          ),
          const SizedBox(height: 24),
          Text(
            'Profil non trouvé',
            style: TextStyle(
              fontSize: 18,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
        ],
      ),
    );
  }
}

class _AuthorizationBottomSheet extends StatefulWidget {
  final String veterinarianId;
  final VoidCallback onSuccess;

  const _AuthorizationBottomSheet({
    required this.veterinarianId,
    required this.onSuccess,
  });

  @override
  State<_AuthorizationBottomSheet> createState() =>
      _AuthorizationBottomSheetState();
}

class _AuthorizationBottomSheetState extends State<_AuthorizationBottomSheet> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;
  List<dynamic> _userFarms = [];
  List<dynamic> _userLivestocks = [];
  dynamic _selectedFarm;
  dynamic _selectedLivestock;
  bool _loadingData = true;
  int _selectedTab = 0; // 0: Fermes/Cultures, 1: Bétail/Animaux
  
  // Sélection des parcelles pour une ferme
  Set<int> _selectedCrops = {};
  dynamic _selectedCrop;
  
  // Sélection des animaux pour un bétail
  Set<int> _selectedAnimals = {};
  dynamic _selectedAnimal;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final farms = await ApiService.getUserFarms();
      
      // Récupérer l'ID de l'utilisateur actuel pour charger son bétail
      final userId = await TokenStorage.getUserId();
      final livestocks = userId != null 
        ? await ApiService.getUserLivestock(userId)
        : [];
      
      setState(() {
        _userFarms = farms;
        _userLivestocks = livestocks;
        _loadingData = false;
      });
    } catch (e) {
      if (mounted) {
        setState(() => _loadingData = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  String _buildDiagnosisSummary() {
    List<String> items = [];
    
    if (_selectedTab == 0 && _selectedCrops.isNotEmpty) {
      items.add('${_selectedCrops.length} parcelle(s)');
    }
    if (_selectedTab == 1 && _selectedAnimals.isNotEmpty) {
      items.add('${_selectedAnimals.length} animal(aux)');
    }
    
    return items.isEmpty ? 'Aucun élément sélectionné' : items.join(' + ');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Handle
            Padding(
              padding: const EdgeInsets.only(top: 24),
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: theme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Titre
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Demander l\'accès vétérinaire',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Sélectionnez ce que vous voulez diagnostiquer',
                    style: TextStyle(
                      fontSize: 15,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Onglets
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedTab = 0;
                        _selectedFarm = null;
                        _selectedCrop = null;
                        _selectedCrops.clear();
                        _selectedAnimals.clear();
                        _selectedAnimal = null;
                        _selectedLivestock = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTab == 0 ? theme.colorScheme.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          '🌾 Cultures',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _selectedTab == 0 ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => setState(() {
                        _selectedTab = 1;
                        _selectedLivestock = null;
                        _selectedAnimal = null;
                        _selectedAnimals.clear();
                        _selectedCrops.clear();
                        _selectedCrop = null;
                        _selectedFarm = null;
                      }),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: _selectedTab == 1 ? theme.colorScheme.primary : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          '🐄 Animaux',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: _selectedTab == 1 ? theme.colorScheme.primary : theme.colorScheme.onSurface.withOpacity(0.5),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Contenu scrollable
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_loadingData)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 32),
                        child: Center(child: CircularProgressIndicator()),
                      )
                    else if (_selectedTab == 0)
                      // Onglet Cultures (Fermes)
                      _buildCulturesTab(theme)
                    else
                      // Onglet Animaux (Bétail)
                      _buildAnimalsTab(theme),
                    
                    const SizedBox(height: 24),
                    
                    // Résumé de la sélection
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            color: theme.colorScheme.primary,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'À diagnostiquer: ${_buildDiagnosisSummary()}',
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Champ de texte
                    Text(
                      'Raison de la demande',
                      style: theme.textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _reasonController,
                      maxLines: 5,
                      decoration: InputDecoration(
                        hintText: 'Décrivez les symptômes ou problèmes observés...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        filled: true,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            // Boutons (au bas, pas scrollable)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Annuler'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: (_isLoading || _loadingData || 
                                 (_selectedTab == 0 && (_selectedFarm == null || _selectedCrops.isEmpty)) ||
                                 (_selectedTab == 1 && (_selectedLivestock == null || _selectedAnimals.isEmpty)))
                        ? null 
                        : _submitRequest,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: theme.colorScheme.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : const Text('Envoyer'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildCulturesTab(ThemeData theme) {
    if (_userFarms.isEmpty) {
      return Text(
        'Vous n\'avez pas de fermes. Créez-en une d\'abord.',
        style: TextStyle(
          fontSize: 14,
          color: theme.colorScheme.error,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Fermes',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        DropdownButton<dynamic>(
          value: _selectedFarm,
          isExpanded: true,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('-- Sélectionner une ferme --'),
            ),
            ..._userFarms.map((farm) {
              return DropdownMenuItem(
                value: farm,
                child: Text(farm['name'] ?? 'Ferme sans nom'),
              );
            }).toList(),
          ],
          onChanged: (farm) {
            setState(() {
              _selectedFarm = farm;
              _selectedCrops.clear();
              _selectedCrop = null;
            });
          },
        ),
        const SizedBox(height: 24),
        
        // Parcelles à diagnostiquer
        if (_selectedFarm != null && (_selectedFarm['crops']?.isNotEmpty ?? false)) ...[
          Text(
            'Parcelles/Cultures à examiner',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          DropdownButton<dynamic>(
            value: _selectedCrop,
            isExpanded: true,
            hint: const Text('+ Ajouter une culture'),
            items: (_selectedFarm['crops'] as List)
                .where((crop) => !_selectedCrops.contains(crop['id']))
                .map((crop) {
              return DropdownMenuItem(
                value: crop,
                child: Text(crop['crop_name'] ?? 'Culture'),
              );
            }).toList(),
            onChanged: (crop) {
              if (crop != null) {
                setState(() {
                  _selectedCrops.add(crop['id'] as int);
                  _selectedCrop = null;
                });
              }
            },
          ),
          const SizedBox(height: 12),
          
          // Cultures sélectionnées
          if (_selectedCrops.isNotEmpty) ...[
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _selectedCrops.map((cropId) {
                final crop = (_selectedFarm['crops'] as List)
                    .firstWhere((c) => c['id'] == cropId, orElse: () => null);
                if (crop == null) return const SizedBox.shrink();
                
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.orange.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.orange.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.agriculture, size: 16, color: Colors.orange),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          crop['crop_name'] ?? 'Culture',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 4),
                      GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedCrops.remove(cropId);
                          });
                        },
                        child: Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.orange.withOpacity(0.7),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ],
    );
  }
  
  Widget _buildAnimalsTab(ThemeData theme) {
    if (_userLivestocks.isEmpty) {
      return Text(
        'Vous n\'avez pas de bétail. Créez-en un d\'abord.',
        style: TextStyle(
          fontSize: 14,
          color: theme.colorScheme.error,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bétail',
          style: theme.textTheme.labelLarge,
        ),
        const SizedBox(height: 8),
        DropdownButton<dynamic>(
          value: _selectedLivestock,
          isExpanded: true,
          items: [
            const DropdownMenuItem(
              value: null,
              child: Text('-- Sélectionner un bétail --'),
            ),
            ..._userLivestocks.map((livestock) {
              return DropdownMenuItem(
                value: livestock,
                child: Text(
                  '${livestock['animal_type']} - ${livestock['breed'] ?? 'Race'} (x${livestock['quantity'] ?? 1})',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
          ],
          onChanged: (livestock) {
            setState(() {
              _selectedLivestock = livestock;
              _selectedAnimals.clear();
              _selectedAnimal = null;
            });
          },
        ),
        const SizedBox(height: 24),
        
        // Animaux à diagnostiquer
        if (_selectedLivestock != null) ...[
          Text(
            'Animaux à examiner',
            style: theme.textTheme.labelLarge,
          ),
          const SizedBox(height: 8),
          Text(
            'Pour ce bétail: ${_selectedLivestock['animal_type']} × ${_selectedLivestock['quantity'] ?? 1}',
            style: TextStyle(
              fontSize: 13,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          const SizedBox(height: 12),
          
          // On affiche des chips pour sélectionner la quantité
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.05),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: theme.colorScheme.primary.withOpacity(0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Animaux à inclure dans le diagnostic',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Nombre d\'animaux',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                        keyboardType: TextInputType.number,
                        onChanged: (value) {
                          final quantity = int.tryParse(value) ?? 0;
                          if (quantity > 0 && quantity <= (_selectedLivestock['quantity'] ?? 1)) {
                            setState(() {
                              _selectedAnimals.clear();
                              for (int i = 0; i < quantity; i++) {
                                _selectedAnimals.add(i);
                              }
                            });
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'sur ${_selectedLivestock['quantity'] ?? 1}',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          if (_selectedAnimals.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${_selectedAnimals.length} animal(aux) sélectionné(s)',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.blue,
                ),
              ),
            ),
          ],
        ],
      ],
    );
  }

  Future<void> _submitRequest() async {
    if (_selectedTab == 0) {
      // Onglet Cultures
      if (_selectedFarm == null || _selectedCrops.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner une ferme et au moins une culture'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    } else {
      // Onglet Animaux
      if (_selectedLivestock == null || _selectedAnimals.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez sélectionner un bétail et au moins un animal'),
            backgroundColor: Colors.orange,
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }
    }

    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez décrire le problème'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final diagnosisSummary = _buildDiagnosisSummary();
      final fullReason = '${_reasonController.text}\n\n[À diagnostiquer: $diagnosisSummary]';
      
      late int farmId;
      String? cropIds;
      String? animalIds;

      if (_selectedTab == 0) {
        // Cultures - on prend l'ID de la ferme et les IDs des cultures sélectionnées
        farmId = _selectedFarm['id'] as int;
        cropIds = _selectedCrops.map((id) => id.toString()).join(',');
      } else {
        // Animaux - on prend l'ID du livestock
        final livestockId = _selectedLivestock['id'] as int;
        animalIds = livestockId.toString();
        // Pour les animaux, on utilise un ID de ferme temporaire ou 0
        // car l'API nécessite un farm_id même si l'autorisation concerne seulement des animaux
        farmId = 0;
      }
      
      await ApiService.createAuthorization(
        farmId: farmId,
        veterinarianId: int.tryParse(widget.veterinarianId) ?? 0,
        authorizationReason: fullReason,
        selectedLivestockIds: animalIds,
        selectedCropIds: cropIds,
      );
      widget.onSuccess();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}