import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/edit_veterinarian_profile_screen.dart';
import 'package:mbaymi/models/veterinarian_model.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/widgets/skeleton_loader.dart';

class VeterinarianDashboardScreen extends StatefulWidget {
  const VeterinarianDashboardScreen({super.key});

  @override
  State<VeterinarianDashboardScreen> createState() =>
      _VeterinarianDashboardScreenState();
}

class _VeterinarianDashboardScreenState
    extends State<VeterinarianDashboardScreen> {
  bool _isLoading = true;
  VeterinarianProfile? _profile;
  List<dynamic> _availableRequests = [];
  List<dynamic> _acceptedAuthorizations = [];

  @override
  void initState() {
    super.initState();
    _loadDashboard();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);

    try {
      // Charger le profil vétérinaire
      debugPrint('Chargement du profil vétérinaire...');
      final profile = await ApiService.getVeterinarianProfile();
      
      // Si pas de profil (404), rediriger vers setup
      if (profile == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/veterinarian-setup');
        }
        return;
      }
      
      setState(() => _profile = profile);

      // Charger les demandes d'autorisation en attente
      debugPrint('Chargement des demandes d\'autorisation...');
      try {
        final requests = await ApiService.getPendingAuthorizations();
        debugPrint('Demandes reçues: ${requests.length} items');
        debugPrint('Type requests: ${requests.runtimeType}');
        if (requests.isNotEmpty) {
          debugPrint('Premier item type: ${requests[0].runtimeType}');
          debugPrint('Premier item: ${requests[0]}');
        }
        setState(() => _availableRequests = requests);
      } catch (e) {
        debugPrint('Erreur lors du chargement des demandes: $e');
        setState(() => _availableRequests = []);
      }

      // Charger les autorisations acceptées
      debugPrint('Chargement des autorisations acceptées...');
      try {
        final accepted = await ApiService.getAcceptedAuthorizations();
        debugPrint('Autorisations acceptées reçues: ${accepted.length} items');
        setState(() => _acceptedAuthorizations = accepted);
      } catch (e) {
        debugPrint('Erreur lors du chargement des autorisations acceptées: $e');
        setState(() => _acceptedAuthorizations = []);
      }
    } catch (e) {
      // Si 404, rediriger vers setup
      if (e.toString().contains('404') || e.toString().contains('Erreur: 404')) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/veterinarian-setup');
        }
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _openRequestDetails(dynamic request) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _RequestDetailsSheet(
        request: request,
        farmerId: (request['farmer'] as Map<String, dynamic>?)?['id'] as int?,
        onAuthorizationUpdated: _loadDashboard,
      ),
    );
  }

  void _navigateToSetup() {
    Navigator.of(context).pushNamed('/veterinarian-setup');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBgColor(isDark),
      body: _isLoading
          ? SkeletonPageLoader(
              isDarkMode: isDark,
              includeAppBar: true,
              cardCount: 4,
            )
          : _profile == null
              ? _SetupProfileView(onCreateProfile: _navigateToSetup)
              : _DashboardView(
                  profile: _profile!,
                  availableRequests: _availableRequests,
                  acceptedAuthorizations: _acceptedAuthorizations,
                  onRefresh: _loadDashboard,
                  onEditProfile: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const EditVeterinarianProfileScreen(),
                      ),
                    ).then((_) => _loadDashboard());
                  },
                  onRequestTap: _openRequestDetails,
                ),
    );
  }
}

// ============================
// VUE PRINCIPALE DU TABLEAU DE BORD
// ============================

class _DashboardView extends StatefulWidget {
  final VeterinarianProfile profile;
  final List<dynamic> availableRequests;
  final List<dynamic> acceptedAuthorizations;
  final VoidCallback onRefresh;
  final VoidCallback onEditProfile;
  final Function(dynamic) onRequestTap;

  const _DashboardView({
    required this.profile,
    required this.availableRequests,
    required this.acceptedAuthorizations,
    required this.onRefresh,
    required this.onEditProfile,
    required this.onRequestTap,
  });

  @override
  State<_DashboardView> createState() => _DashboardViewState();
}

class _DashboardViewState extends State<_DashboardView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    
    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 0,
          floating: true,
          pinned: true,
          elevation: 0,
          backgroundColor: AppColors.getBgColor(isDark),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: widget.onRefresh,
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
                // Header du profil
                _ProfileHeader(
                  profile: widget.profile,
                  onEditProfile: widget.onEditProfile,
                ),
                
                const SizedBox(height: 32),
                
                // Stats
                _StatsRow(profile: widget.profile),
                
                const SizedBox(height: 32),
                
                // Tabs
                Container(
                  decoration: BoxDecoration(
                    border: Border(
                      bottom: BorderSide(
                        color: theme.dividerColor,
                        width: 1,
                      ),
                    ),
                  ),
                  child: TabBar(
                    controller: _tabController,
                    labelColor: theme.colorScheme.primary,
                    unselectedLabelColor: theme.colorScheme.onSurface.withOpacity(0.5),
                    indicatorColor: theme.colorScheme.primary,
                    tabs: const [
                      Tab(text: 'Demandes'),
                      Tab(text: 'Autorisations'),
                      Tab(text: 'Consultations'),
                    ],
                  ),
                ),
                
                // Contenu des tabs
                SizedBox(
                  height: 400, // Hauteur fixe pour éviter les overflow
                  child: TabBarView(
                    controller: _tabController,
                    children: [
                      _RequestsTab(
                        requests: widget.availableRequests,
                        onTap: widget.onRequestTap,
                      ),
                      _AuthorizationsTab(
                        authorizations: widget.acceptedAuthorizations,
                      ),
                      const _ConsultationsTab(),
                    ],
                  ),
                ),
              ],
            ),
          ),
        )),
      ],
    );
  }
}

// ============================
// HEADER DU PROFIL
// ============================

class _ProfileHeader extends StatelessWidget {
  final VeterinarianProfile profile;
  final VoidCallback onEditProfile;

  const _ProfileHeader({
    required this.profile,
    required this.onEditProfile,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  profile.specialty,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      Icons.location_on,
                      size: 16,
                      color: theme.colorScheme.onSurface.withOpacity(0.5),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      profile.zone,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            // Badge de statut
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _getStatusColor(profile.verificationStatus),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _getStatusLabel(profile.verificationStatus),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton(
            onPressed: onEditProfile,
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
              ),
            ),
            child: const Text('Éditer le profil'),
          ),
        ),
      ],
    );
  }

  Color _getStatusColor(String? status) {
    switch (status) {
      case 'verified':
        return Colors.green;
      case 'pending':
        return Colors.orange;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getStatusLabel(String? status) {
    switch (status) {
      case 'verified':
        return '✓ Vérifié';
      case 'pending':
        return '⏳ En attente';
      case 'rejected':
        return '✗ Rejeté';
      default:
        return 'Inconnu';
    }
  }
}

// ============================
// STATS EN LIGNE
// ============================

class _StatsRow extends StatelessWidget {
  final VeterinarianProfile profile;

  const _StatsRow({required this.profile});

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
        crossAxisAlignment: CrossAxisAlignment.center,
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

// ============================
// TAB DES DEMANDES
// ============================

class _RequestsTab extends StatelessWidget {
  final List<dynamic> requests;
  final Function(dynamic) onTap;

  const _RequestsTab({
    required this.requests,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (requests.isEmpty) {
      return const _EmptyTabContent(
        icon: Icons.inbox_outlined,
        title: 'Aucune demande',
        subtitle: 'Les nouvelles demandes apparaîtront ici',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      itemCount: requests.length,
      itemBuilder: (context, index) {
        final request = requests[index];
        return _RequestItem(
          request: request,
          onTap: () => onTap(request),
        );
      },
    );
  }
}

class _RequestItem extends StatelessWidget {
  final dynamic request;
  final VoidCallback onTap;

  const _RequestItem({
    required this.request,
    required this.onTap,
  });

  String _extractDiagnosisSummary(String reason) {
    // Cherche le pattern "À diagnostiquer: ..."
    final regex = RegExp(r'À diagnostiquer:\s*(.+?)(?:\n|$)', caseSensitive: false);
    final match = regex.firstMatch(reason);
    return match?.group(1)?.trim() ?? '';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final farm = request['farm'] as Map<String, dynamic>?;
    final farmer = request['farmer'] as Map<String, dynamic>?;
    final livestocks = (farm?['livestocks'] as List?) ?? [];
    final isFarmAuthorization = farm != null && farm['id'] != null;
    final isLivestockAuthorization = !isFarmAuthorization && livestocks.isNotEmpty;
    
    // Déterminer le titre à afficher
    String displayTitle;
    if (isFarmAuthorization) {
      displayTitle = farm['name'] ?? 'Ferme sans nom';
    } else if (isLivestockAuthorization && livestocks.isNotEmpty) {
      final livestock = livestocks[0];
      displayTitle = '${livestock['animal_type']} - ${livestock['breed'] ?? 'Race'}';
    } else {
      displayTitle = 'Autorisation';
    }
    
    final farmerName = farmer?['name'] ?? 'Agriculteur';
    
    debugPrint('=== REQUEST ITEM DEBUG ===');
    debugPrint('Request keys: ${request.keys.toList()}');
    debugPrint('Farm: $farm');
    debugPrint('Is farm authorization: $isFarmAuthorization');
    debugPrint('Is livestock authorization: $isLivestockAuthorization');
    debugPrint('Display title: $displayTitle');
    debugPrint('========================');
    final reason = request['authorization_reason'] ?? 'Pas de raison spécifiée';
    final createdAt = request['created_at'] ?? '';
    final diagnosisSummary = _extractDiagnosisSummary(reason);
    
    // Get first photo from farm or livestock
    final photos = (farm?['photos'] as List?) ?? [];
    dynamic firstPhotoSource;
    if (photos.isNotEmpty) {
      firstPhotoSource = photos[0];
    } else if (isLivestockAuthorization && livestocks.isNotEmpty) {
      firstPhotoSource = livestocks[0];
    }
    final firstPhotoUrl = firstPhotoSource?['image_url'] as String?;
    
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: theme.dividerColor,
              width: 1,
            ),
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo thumbnail
            if (firstPhotoUrl != null)
              Container(
                width: 80,
                height: 80,
                margin: const EdgeInsets.only(right: 12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  color: Colors.grey[200],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    firstPhotoUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(
                      color: Colors.grey[300],
                      child: const Icon(Icons.image_not_supported, size: 30),
                    ),
                  ),
                ),
              ),
            // Info column
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Text(
                          'En attente',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    farmerName,
                    style: TextStyle(
                      fontSize: 13,
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  // Afficher le résumé diagnostic si disponible
                  if (diagnosisSummary.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: theme.colorScheme.primary.withOpacity(0.3),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.health_and_safety,
                            size: 14,
                            color: theme.colorScheme.primary,
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              diagnosisSummary,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: theme.colorScheme.primary,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 12,
                        color: theme.colorScheme.onSurface.withOpacity(0.4),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(createdAt),
                        style: TextStyle(
                          fontSize: 11,
                          color: theme.colorScheme.onSurface.withOpacity(0.4),
                        ),
                      ),
                      const Spacer(),
                      Text(
                        'Détails →',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.primary,
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
      ),
    );
  }

  String _formatDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      final now = DateTime.now();
      final diff = now.difference(date);
      
      if (diff.inHours < 1) {
        return 'Il y a ${diff.inMinutes}m';
      } else if (diff.inHours < 24) {
        return 'Il y a ${diff.inHours}h';
      } else if (diff.inDays < 7) {
        return 'Il y a ${diff.inDays}j';
      }
      return dateStr;
    } catch (e) {
      return 'Récemment';
    }
  }

}

// ============================
// TAB DES AUTORISATIONS
// ============================

class _AuthorizationsTab extends StatelessWidget {
  final List<dynamic> authorizations;

  const _AuthorizationsTab({required this.authorizations});

  @override
  Widget build(BuildContext context) {
    if (authorizations.isEmpty) {
      return const _EmptyTabContent(
        icon: Icons.lock_outline,
        title: 'Aucune autorisation',
        subtitle: 'Les demandes d\'accès apparaîtront ici',
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 16),
      itemCount: authorizations.length,
      itemBuilder: (context, index) {
        final auth = authorizations[index];
        return _AuthorizationItem(authorization: auth);
      },
    );
  }
}

// ============================
// WIDGET D'AUTORISATION ACCEPTÉE
// ============================

class _AuthorizationItem extends StatefulWidget {
  final dynamic authorization;

  const _AuthorizationItem({required this.authorization});

  @override
  State<_AuthorizationItem> createState() => _AuthorizationItemState();
}

class _AuthorizationItemState extends State<_AuthorizationItem> {
  List<dynamic> _livestocks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadLivestocksIfNeeded();
  }

  Future<void> _loadLivestocksIfNeeded() async {
    final farmId = widget.authorization['farm_id'] as int?;
    final farmer = widget.authorization['farmer'] as Map<String, dynamic>?;
    final farmerId = farmer?['id'] as int?;
    
    try {
      // Si c'est une livestock authorization (farm_id null ou 0) et on a un farmerId
      if ((farmId == null || farmId == 0) && farmerId != null) {
        final livestocks = await ApiService.getUserLivestock(farmerId);
        if (mounted) {
          setState(() {
            _livestocks = livestocks;
            _isLoading = false;
          });
          debugPrint('Livestocks chargés pour l\'utilisateur $farmerId: ${livestocks.length}');
        }
      } else {
        // Pour les farm authorizations, pas besoin de charger
        if (mounted) {
          setState(() => _isLoading = false);
        }
      }
    } catch (e) {
      debugPrint('Erreur lors du chargement des livestocks: $e');
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final farm = widget.authorization['farm'] as Map<String, dynamic>?;
    final farmId = widget.authorization['farm_id'] as int?;
    
    // Déterminer le type d'autorisation
    final isFarmAuthorization = farmId != null && farmId > 0;
    final isLivestockAuthorization = farmId == null || farmId == 0;
    
    // Récupérer les photos et livestocks appropriés selon le type
    final photos = isFarmAuthorization ? ((farm?['photos'] as List?) ?? []) : [];
    final livestocks = isLivestockAuthorization ? _livestocks : [];
    
    // Déterminer la photo à afficher
    String? firstPhotoUrl;
    if (isFarmAuthorization && photos.isNotEmpty) {
      // Pour une ferme: prendre la photo de la ferme
      firstPhotoUrl = photos[0]['image_url'] as String?;
    } else if (isLivestockAuthorization && livestocks.isNotEmpty) {
      // Pour un animal: prendre la photo de l'animal
      firstPhotoUrl = livestocks[0]['image_url'] as String?;
    }
    
    // Déterminer le titre et l'ID pour le détail
    String displayTitle;
    dynamic detailId;
    
    if (isFarmAuthorization) {
      displayTitle = farm?['name'] ?? 'Ferme sans nom';
      detailId = farmId;
    } else if (isLivestockAuthorization && livestocks.isNotEmpty) {
      final livestock = livestocks[0];
      displayTitle = '${livestock['animal_type']} - ${livestock['breed'] ?? 'Race'}';
      detailId = livestock['id'];
    } else {
      displayTitle = 'Autorisation';
      detailId = null;
    }
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: theme.colorScheme.primary.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withOpacity(0.04),
              theme.colorScheme.primary.withOpacity(0.02),
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image avec loading state
            Container(
              padding: const EdgeInsets.all(12),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: SizedBox(
                  width: double.infinity,
                  height: 200,
                  child: _isLoading
                      ? Container(
                          color: theme.colorScheme.primary.withOpacity(0.05),
                          child: Center(
                            child: SizedBox(
                              width: 40,
                              height: 40,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.primary,
                                ),
                              ),
                            ),
                          ),
                        )
                      : firstPhotoUrl != null
                          ? Image.network(
                              firstPhotoUrl,
                              fit: BoxFit.cover,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: theme.colorScheme.primary.withOpacity(0.05),
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                      strokeWidth: 2,
                                    ),
                                  ),
                                );
                              },
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported, size: 40),
                              ),
                            )
                          : Container(
                              color: theme.colorScheme.primary.withOpacity(0.1),
                          child: Icon(
                            isFarmAuthorization ? Icons.agriculture : Icons.pets,
                            color: theme.colorScheme.primary,
                            size: 60,
                          ),
                        ),
                ),
              ),
            ),
            
            // Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          displayTitle,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.green, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Acceptée',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Bouton voir détail
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: detailId != null
                          ? () {
                              if (isFarmAuthorization) {
                                Navigator.pushNamed(context, '/farm-detail', arguments: detailId);
                              } else {
                                Navigator.pushNamed(context, '/livestock-detail', arguments: detailId);
                              }
                            }
                          : null,
                      icon: const Icon(Icons.arrow_forward, size: 16),
                      label: const Text('Voir détail'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
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
}

// ============================
// TAB DES CONSULTATIONS
// ============================

class _ConsultationsTab extends StatelessWidget {
  const _ConsultationsTab();

  @override
  Widget build(BuildContext context) {
    return const _EmptyTabContent(
      icon: Icons.video_call_outlined,
      title: 'Aucune consultation',
      subtitle: 'Vos consultations actives apparaîtront ici',
    );
  }
}

// ============================
// CONTENU VIDE DES TABS
// ============================

class _EmptyTabContent extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _EmptyTabContent({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                color: theme.colorScheme.onSurface.withOpacity(0.5),
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================
// VUE DE CRÉATION DE PROFIL
// ============================

class _SetupProfileView extends StatelessWidget {
  final VoidCallback onCreateProfile;

  const _SetupProfileView({required this.onCreateProfile});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.person_add_alt_1,
              size: 64,
              color: theme.colorScheme.onSurface.withOpacity(0.3),
            ),
            const SizedBox(height: 32),
            const Text(
              'Créez votre profil',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              'Configurez votre profil pour commencer à recevoir des demandes',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: theme.colorScheme.onSurface.withOpacity(0.6),
                height: 1.4,
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: onCreateProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                child: const Text(
                  'Créer mon profil',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
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

// ============================
// FEUILLE DE DÉTAILS DE LA DEMANDE
// ============================

class _RequestDetailsSheet extends StatefulWidget {
  final dynamic request;
  final int? farmerId;
  final VoidCallback? onAuthorizationUpdated;

  const _RequestDetailsSheet({
    required this.request,
    this.farmerId,
    this.onAuthorizationUpdated,
  });

  @override
  State<_RequestDetailsSheet> createState() => _RequestDetailsSheetState();
}

class _RequestDetailsSheetState extends State<_RequestDetailsSheet> {
  bool _isLoading = false;
  List<dynamic> _livestocks = [];

  @override
  void initState() {
    super.initState();
    _loadLivestocksIfNeeded();
  }

  Future<void> _loadLivestocksIfNeeded() async {
    final farmId = widget.request['farm_id'] as int?;
    final farmer = widget.request['farmer'] as Map<String, dynamic>?;
    final farmerId = farmer?['id'] as int?;
    
    // Si c'est une livestock authorization (farm_id null ou 0) et on a un farmerId
    if ((farmId == null || farmId == 0) && farmerId != null) {
      try {
        final livestocks = await ApiService.getUserLivestock(farmerId);
        if (mounted) {
          setState(() => _livestocks = livestocks);
          debugPrint('Livestocks chargés pour l\'utilisateur $farmerId: ${livestocks.length}');
        }
      } catch (e) {
        debugPrint('Erreur lors du chargement des livestocks: $e');
      }
    }
  }

  Color _getStatusColor(String? status) {
    switch (status?.toLowerCase()) {
      case 'active':
      case 'sain':
        return Colors.green;
      case 'pending':
      case 'en attente':
        return Colors.orange;
      case 'sick':
      case 'malade':
        return Colors.red;
      case 'completed':
      case 'terminé':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  Future<void> _acceptAuthorization() async {
    setState(() => _isLoading = true);
    try {
      final authId = widget.request['id'] as int?;
      if (authId == null) throw Exception('ID d\'autorisation manquant');

      await ApiService.acceptAuthorization(authId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autorisation acceptée')),
        );
        // Rafraîchir le dashboard parent
        widget.onAuthorizationUpdated?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _rejectAuthorization() async {
    setState(() => _isLoading = true);
    try {
      final authId = widget.request['id'] as int?;
      if (authId == null) throw Exception('ID d\'autorisation manquant');

      await ApiService.rejectAuthorization(authId);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Autorisation rejetée')),
        );
        // Rafraîchir le dashboard parent
        widget.onAuthorizationUpdated?.call();
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final farm = widget.request['farm'] as Map<String, dynamic>?;
    final farmer = widget.request['farmer'] as Map<String, dynamic>?;
    final farmerId = widget.farmerId ?? farmer?['id'];
    final farmId = widget.request['farm_id'] as int?;
    final crops = (farm?['crops'] as List?) ?? [];
    final photos = (farm?['photos'] as List?) ?? [];
    
    // Déterminer le type d'autorisation
    final isFarmAuthorization = farmId != null && farmId > 0;
    final isLivestockAuthorization = farmId == null || farmId == 0;
    
    final farmName = farm?['name'] ?? 'Ferme sans nom';
    final farmerName = farmer?['name'] ?? 'Agriculteur';
    
    debugPrint('=== DETAILS SHEET DEBUG ===');
    debugPrint('Request keys: ${widget.request.keys.toList()}');
    debugPrint('Farm ID: $farmId');
    debugPrint('Farm: $farm');
    debugPrint('Farmer: $farmer');
    debugPrint('Is farm authorization: $isFarmAuthorization');
    debugPrint('Is livestock authorization: $isLivestockAuthorization');
    debugPrint('farmerId: $farmerId');
    debugPrint('Loaded livestocks: ${_livestocks.length}');
    debugPrint('========================');
    
    final reason = widget.request['authorization_reason'] ?? 'Pas de raison spécifiée';
    
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.background,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Handle
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: theme.dividerColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Titre
                const Text(
                  'Demande d\'autorisation',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Header agriculteur et ferme/bétail
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Agriculteur
                      Text(
                        'Agriculteur',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        farmerName,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      
                      // Afficher Ferme seulement si c'est une autorisation ferme
                      if (isFarmAuthorization) ...[
                        const SizedBox(height: 16),
                        Text(
                          'Ferme',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          farmName,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        if (farm?['location'] != null) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(
                                Icons.location_on,
                                size: 16,
                                color: theme.colorScheme.primary,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                farm?['location'] ?? '',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: theme.colorScheme.onSurface.withOpacity(0.7),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ] else if (isLivestockAuthorization && _livestocks.isNotEmpty) ...[
                        // Afficher le bétail si c'est une autorisation livestock
                        const SizedBox(height: 16),
                        Text(
                          'Bétail',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${_livestocks[0]['animal_type']} - ${_livestocks[0]['breed'] ?? 'Race'}',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Quantité: ${_livestocks[0]['quantity'] ?? 0}',
                          style: TextStyle(
                            fontSize: 13,
                            color: theme.colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                
                // Agriculteur (detail)
                _DetailRow(label: 'Agriculteur', value: farmerName),
                const SizedBox(height: 16),
                
                // Ferme ou Bétail
                if (isFarmAuthorization)
                  _DetailRow(label: 'Ferme', value: farmName)
                else if (isLivestockAuthorization && _livestocks.isNotEmpty)
                  _DetailRow(label: 'Bétail', value: '${_livestocks[0]['animal_type']} - ${_livestocks[0]['breed'] ?? 'Race'}'),
                if (isFarmAuthorization || (isLivestockAuthorization && _livestocks.isNotEmpty))
                  const SizedBox(height: 16),
                
                // Raison
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Raison de la demande',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      reason,
                      style: TextStyle(
                        fontSize: 15,
                        height: 1.6,
                        color: theme.colorScheme.onSurface.withOpacity(0.8),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                
                // Cultures (afficher seulement si ferme)
                if (isFarmAuthorization && crops.isNotEmpty) ...[
                  Text(
                    'Cultures (${crops.length})',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  ...crops.map((crop) {
                    final cropImageUrl = crop['image_url'];
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Photo de la culture si disponible
                          if (cropImageUrl != null) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(6),
                              child: Image.network(
                                cropImageUrl,
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: double.infinity,
                                  height: 120,
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image_not_supported),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                          ],
                          Text(
                            '${crop['crop_name'] ?? 'Culture'} - ${crop['variety'] ?? 'Variété non spécifiée'}',
                            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                          ),
                          const SizedBox(height: 6),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getStatusColor(crop['status']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              'Statut: ${crop['status'] ?? 'Non spécifié'}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: _getStatusColor(crop['status']),
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                ],
                
                // Photos de la ferme
                if (isFarmAuthorization && photos.isNotEmpty) ...[
                  Text(
                    'Photos de la ferme',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: photos.length,
                      itemBuilder: (context, index) {
                        final photo = photos[index];
                        return Container(
                          margin: const EdgeInsets.only(right: 8),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[200],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              photo['image_url'] ?? '',
                              width: 120,
                              height: 120,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                color: Colors.grey[300],
                                child: const Icon(Icons.image_not_supported),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
                
                // Animaux
                if (_livestocks.isNotEmpty) ...[
                  Text(
                    'Animaux (${_livestocks.length})',
                    style: Theme.of(context).textTheme.labelLarge,
                  ),
                  const SizedBox(height: 8),
                  ..._livestocks.map((animal) {
                    final animalImageUrl = animal['image_url'];
                    final animalId = animal['id'] as int?;
                    
                    return GestureDetector(
                      onTap: animalId != null
                          ? () => Navigator.pushNamed(
                                context,
                                '/livestock-detail',
                                arguments: animalId,
                              )
                          : null,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Photo de l'animal si disponible
                            if (animalImageUrl != null) ...[
                              ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: Image.network(
                                  animalImageUrl,
                                  width: double.infinity,
                                  height: 120,
                                  fit: BoxFit.cover,
                                  errorBuilder: (_, __, ___) => Container(
                                    width: double.infinity,
                                    height: 120,
                                    color: Colors.grey[300],
                                    child: const Icon(Icons.image_not_supported),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Text(
                              '${animal['animal_type'] ?? 'Animal'} - ${animal['breed'] ?? 'Race non spécifiée'}',
                              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Quantité: ${animal['quantity'] ?? 0}',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Santé: ${animal['health_status'] ?? 'Non spécifiée'}',
                              style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                            ),
                            if (animal['age_months'] != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Âge: ${animal['age_months']} mois',
                                style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                              ),
                            ],
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                  const SizedBox(height: 24),
                ],
                
                // Bouton visiter la ferme (seulement si c'est une ferme)
                if (isFarmAuthorization) ...[
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        final farmId = farm?['id'];
                        if (farmId != null) {
                          Navigator.pop(context);
                          Navigator.pushNamed(context, '/farm-detail', arguments: farmId);
                        }
                      },
                      icon: const Icon(Icons.location_on),
                      label: const Text('Visiter la ferme'),
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                
                // Boutons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isLoading ? null : _rejectAuthorization,
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Refuser'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _acceptAuthorization,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          backgroundColor: theme.colorScheme.primary,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: const Text('Accepter'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}