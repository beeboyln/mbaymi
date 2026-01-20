import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/screens/veterinarian_profile_detail_screen.dart';
import 'package:mbaymi/utils/app_colors.dart';

class VeterinarianDiscoveryScreen extends StatefulWidget {
  const VeterinarianDiscoveryScreen({Key? key}) : super(key: key);

  @override
  State<VeterinarianDiscoveryScreen> createState() =>
      _VeterinarianDiscoveryScreenState();
}

class _VeterinarianDiscoveryScreenState extends State<VeterinarianDiscoveryScreen> {
  bool _isLoading = true;
  List<dynamic> _veterinarians = [];
  String? _selectedZone;
  String _searchQuery = '';

  static const Color _primaryColor = Colors.brown;

  @override
  void initState() {
    super.initState();
    _loadVeterinarians();
  }

  Future<void> _loadVeterinarians() async {
    if (_selectedZone == null || _selectedZone!.isEmpty) {
      setState(() {
        _veterinarians = [];
        _isLoading = false;
      });
      return;
    }

    setState(() => _isLoading = true);

    try {
      final vets = await ApiService.getVeterinariansByZone(_selectedZone!);
      setState(() {
        _veterinarians = vets;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
    }
  }

  Future<void> _requestAuthorization(Map<String, dynamic> vet) async {
    // Show authorization dialog
    showDialog(
      context: context,
      builder: (context) => AuthorizationDialog(
        veterinarian: vet,
        onSubmit: (reason) async {
          try {
            // Get user's farm
            // Note: In a real app, you would get this from user context
            // For now, using a placeholder
            await ApiService.createAuthorization(
              farmId: 1, // TODO: Get from user context
              veterinarianId: vet['id'] ?? vet['user_id'],
              canViewData: true,
              canGiveAdvice: true,
              canVisit: true,
              authorizationReason: reason,
            );

            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Demande d\'autorisation envoyée'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          } catch (e) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Erreur: ${e.toString()}'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }
        },
      ),
    );
  }

  List<dynamic> get _filteredVeterinarians {
    if (_searchQuery.isEmpty) return _veterinarians;
    return _veterinarians
        .where((v) =>
            (v['specialty']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false) ||
            (v['zone']?.toString().toLowerCase().contains(_searchQuery.toLowerCase()) ?? false))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : AppColors.lightBg;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppColors.lightBg,
        elevation: 0,
        foregroundColor: textColor,
        title: const Text(
          'Trouver un Vétérinaire',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Zone Selection
            Padding(
              padding: const EdgeInsets.all(16),
              child: TextFormField(
                onChanged: (value) {
                  setState(() => _selectedZone = value.isEmpty ? null : value);
                  _loadVeterinarians();
                },
                style: TextStyle(color: textColor),
                decoration: InputDecoration(
                  hintText: 'Saisir votre zone',
                  prefixIcon: const Icon(Icons.location_on),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: Color(0xFFE8E2D8)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(color: _primaryColor),
                  ),
                ),
              ),
            ),

            // Search within results
            if (_veterinarians.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextFormField(
                  onChanged: (value) =>
                      setState(() => _searchQuery = value),
                  style: TextStyle(color: textColor),
                  decoration: InputDecoration(
                    hintText: 'Chercher par spécialité...',
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: Color(0xFFE8E2D8)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide:
                          const BorderSide(color: _primaryColor),
                    ),
                  ),
                ),
              ),

            const SizedBox(height: 16),

            // Veterinarians List
            if (_isLoading)
              const Expanded(
                child: Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                  ),
                ),
              )
            else if (_filteredVeterinarians.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.person_search,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        _selectedZone == null
                            ? 'Entrez votre zone pour voir les vétérinaires'
                            : 'Aucun vétérinaire trouvé',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _filteredVeterinarians.length,
                  itemBuilder: (context, index) {
                    final vet = _filteredVeterinarians[index];
                    return VeterinarianCard(
                      veterinarian: vet,
                      onRequest: () => _requestAuthorization(vet),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class VeterinarianCard extends StatelessWidget {
  final dynamic veterinarian;
  final VoidCallback onRequest;

  const VeterinarianCard({
    Key? key,
    required this.veterinarian,
    required this.onRequest,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgCard = isDark ? const Color(0xFF1E1E1E) : AppColors.lightBg;
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    final rating = (veterinarian['average_rating'] as num?)?.toDouble() ?? 0.0;
    final consultations = veterinarian['total_consultations'] ?? 0;

    return Card(
      color: bgCard,
      margin: const EdgeInsets.only(bottom: 16),
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
            // Name & Specialty
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        veterinarian['specialty'] ?? 'Vétérinaire',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 14,
                            color: Colors.grey,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            veterinarian['zone'] ?? 'Zone inconnue',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Verification badge
                if (veterinarian['verification_status'] == 'verified')
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.verified,
                      size: 20,
                      color: Colors.green,
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 12),

            // Bio
            if (veterinarian['bio'] != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Text(
                  veterinarian['bio'],
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13,
                    color: Colors.grey,
                    height: 1.4,
                  ),
                ),
              ),

            // Experience & Rating
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Experience
                Row(
                  children: [
                    const Icon(
                      Icons.school,
                      size: 16,
                      color: Colors.brown,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${veterinarian['experience_years'] ?? 0} ans',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),

                // Consultations
                Row(
                  children: [
                    const Icon(
                      Icons.work,
                      size: 16,
                      color: Colors.brown,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '$consultations consultations',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),

                // Rating
                Row(
                  children: [
                    Icon(
                      Icons.star,
                      size: 16,
                      color: rating > 0 ? Colors.amber : Colors.grey,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      rating > 0
                          ? rating.toStringAsFixed(1)
                          : 'Nouveau',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Request Button
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => VeterinarianProfileDetailScreen(
                            veterinarianId: veterinarian['id']?.toString() ?? 
                                           veterinarian['user_id']?.toString() ?? '1',
                          ),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown.withOpacity(0.1),
                      foregroundColor: Colors.brown,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Voir le profil'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton(
                    onPressed: onRequest,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.brown,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Demander accès'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class AuthorizationDialog extends StatefulWidget {
  final dynamic veterinarian;
  final Function(String) onSubmit;

  const AuthorizationDialog({
    Key? key,
    required this.veterinarian,
    required this.onSubmit,
  }) : super(key: key);

  @override
  State<AuthorizationDialog> createState() => _AuthorizationDialogState();
}

class _AuthorizationDialogState extends State<AuthorizationDialog> {
  final _reasonController = TextEditingController();

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F1E8);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return AlertDialog(
      backgroundColor: bgColor,
      title: Text(
        'Demander l\'accès',
        style: TextStyle(color: textColor),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'À: ${widget.veterinarian['specialty']}',
            style: TextStyle(
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            style: TextStyle(color: textColor),
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Pourquoi avez-vous besoin de ce vétérinaire?',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Color(0xFFE8E2D8)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: Colors.brown),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_reasonController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Veuillez entrer une raison'),
                ),
              );
              return;
            }
            widget.onSubmit(_reasonController.text.trim());
            Navigator.pop(context);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.brown,
          ),
          child: const Text('Envoyer'),
        ),
      ],
    );
  }
}
