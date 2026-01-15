import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/edit_veterinarian_profile_screen.dart';
import 'package:mbaymi/models/veterinarian_model.dart';

class VeterinarianDashboardScreen extends StatefulWidget {
  const VeterinarianDashboardScreen({Key? key}) : super(key: key);

  @override
  State<VeterinarianDashboardScreen> createState() =>
      _VeterinarianDashboardScreenState();
}

class _VeterinarianDashboardScreenState
    extends State<VeterinarianDashboardScreen>
    with SingleTickerProviderStateMixin {
  bool _isLoading = true;
  VeterinarianProfile? _profile;
  int _pendingAuthorizations = 0;
  List<dynamic> _availableRequests = [];

  late TabController _tabController;

  static const Color _primaryColor = Colors.brown;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadDashboard();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadDashboard() async {
    setState(() => _isLoading = true);

    try {
      // Load veterinarian profile
      debugPrint('🔎 VeterinarianDashboard: calling ApiService.getVeterinarianProfile()');
      final profile = await ApiService.getVeterinarianProfile();
      if (profile != null) {
        debugPrint('✅ VeterinarianDashboard: received profile -> ${profile.toJson()}');
      } else {
        debugPrint('⚠️ VeterinarianDashboard: profile returned null (404)');
      }
      
      // If profile doesn't exist (404), redirect to setup screen
      if (profile == null) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/veterinarian-setup');
        }
        return;
      }
      
      setState(() => _profile = profile);

      // Load available requests
      debugPrint('🔎 VeterinarianDashboard: calling ApiService.getAvailableRequests()');
      final requests = await ApiService.getAvailableRequests();
      debugPrint('✅ VeterinarianDashboard: available requests count=${requests.length}');
      setState(() => _availableRequests = requests);

      // TODO: Load pending authorizations and active consultations
      // For now, using placeholder data
      setState(() {
        _pendingAuthorizations = 2;
      });
    } catch (e) {
      // If 404, redirect to setup screen
      if (e.toString().contains('404') || e.toString().contains('Erreur: 404')) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed('/veterinarian-setup');
        }
        return;
      }
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur chargement: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          elevation: 0,
          foregroundColor: textColor,
          title: const Text(
            'Tableau de Bord',
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          centerTitle: true,
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadDashboard,
            ),
          ],
        ),
        body: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  valueColor:
                      const AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              )
            : _profile == null
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.assignment_ind,
                          size: 64,
                          color: _primaryColor,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'Créez votre profil vétérinaire',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 32),
                          child: Text(
                            'Configurez votre profil professionnel pour commencer à recevoir des demandes de consultation',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () {
                            Navigator.of(context).pushNamed('/veterinarian-setup');
                          },
                          icon: const Icon(Icons.add),
                          label: const Text('Créer mon profil'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : Column(
                children: [
                  // Profile Summary Card
                  if (_profile != null)
                    Container(
                      padding: const EdgeInsets.all(16),
                      margin: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: _primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    _profile!.specialty,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.white,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(
                                        Icons.location_on,
                                        size: 14,
                                        color: Colors.white70,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        _profile!.zone,
                                        style: const TextStyle(
                                          fontSize: 13,
                                          color: Colors.white70,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              // Status Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: _getStatusColor(
                                    _profile!.verificationStatus,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Text(
                                  _getStatusLabel(
                                    _profile!.verificationStatus,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Stats Row
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildStatColumn(
                                '${_profile!.consultationCount ?? 0}',
                                'Consultations',
                              ),
                              _buildStatColumn(
                                '${(_profile!.rating ?? 0).toStringAsFixed(1)}⭐',
                                'Note',
                              ),
                              _buildStatColumn(
                                '${_profile!.experienceYears} ans',
                                'Expérience',
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Edit Profile Button
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        const EditVeterinarianProfileScreen(),
                                  ),
                                ).then((_) {
                                  _loadDashboard();
                                });
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.white,
                                foregroundColor: _primaryColor,
                              ),
                              icon: const Icon(Icons.edit),
                              label: const Text('Éditer mon profil'),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Tabs
                  TabBar(
                    controller: _tabController,
                    labelColor: _primaryColor,
                    unselectedLabelColor: Colors.grey,
                    indicatorColor: _primaryColor,
                    tabs: [
                      Tab(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Demandes'),
                            if (_availableRequests.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${_availableRequests.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Tab(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text('Autorisations'),
                            if (_pendingAuthorizations > 0)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.orange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '$_pendingAuthorizations',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const Tab(
                        child: Text('Consultations'),
                      ),
                    ],
                  ),

                  // Tab Views
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        // Demandes de Service
                        _buildRequestsList(),

                        // Autorisations en Attente
                        _buildAuthorizationsList(),

                        // Consultations Actives
                        _buildConsultationsList(),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 11,
            color: Colors.white70,
          ),
        ),
      ],
    );
  }

  Widget _buildRequestsList() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    if (_availableRequests.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'Aucune demande en attente',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _availableRequests.length,
      itemBuilder: (context, index) {
        final request = _availableRequests[index];
        return Card(
          color: bgCard,
          margin: const EdgeInsets.only(bottom: 12),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(
              color: const Color(0xFFE8E2D8).withOpacity(0.5),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            request['title'] ?? 'Demande',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _getServiceTypeLabel(request['service_type']),
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: _getPriorityColor(request['priority']),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _getPriorityLabel(request['priority']),
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  request['description'] ?? '',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      // TODO: Open request details
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 0,
                    ),
                    child: const Text('Voir détails'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildAuthorizationsList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.lock_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune autorisation en attente',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les demandes d\'accès des fermiers\napparaîtront ici',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsultationsList() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.check_circle_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Aucune consultation active',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Les consultations que vous acceptez\napparaîtront ici',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
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

  String _getServiceTypeLabel(String? type) {
    switch (type) {
      case 'animal_problem':
        return '🐄 Problème animal';
      case 'crop_problem':
        return '🌾 Problème culture';
      case 'general_advice':
        return '💡 Conseil général';
      default:
        return 'Demande';
    }
  }

  String _getPriorityLabel(String? priority) {
    switch (priority) {
      case 'low':
        return 'Basse';
      case 'medium':
        return 'Moyen';
      case 'high':
        return 'Haute';
      case 'urgent':
        return 'Urgent';
      default:
        return 'Moyen';
    }
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'low':
        return Colors.green;
      case 'medium':
        return Colors.blue;
      case 'high':
        return Colors.orange;
      case 'urgent':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
