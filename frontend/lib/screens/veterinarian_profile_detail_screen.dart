import 'package:flutter/material.dart';
import 'package:mbaymi/models/veterinarian_model.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';

class VeterinarianProfileDetailScreen extends StatefulWidget {
  final String veterinarianId;

  const VeterinarianProfileDetailScreen({
    Key? key,
    required this.veterinarianId,
  }) : super(key: key);

  @override
  State<VeterinarianProfileDetailScreen> createState() =>
      _VeterinarianProfileDetailScreenState();
}

class _VeterinarianProfileDetailScreenState
    extends State<VeterinarianProfileDetailScreen> {
  late Future<VeterinarianProfile?> _profileFuture;
  bool _isAuthorized = false;

  @override
  void initState() {
    super.initState();
    _profileFuture = ApiService.getVeterinarianProfile();
    _checkAuthorizationStatus();
  }

  Future<void> _checkAuthorizationStatus() async {
    // TODO: Implement check if current user has authorized this veterinarian
    // This would require an API endpoint to check authorization status
  }

  Future<void> _requestAuthorization() async {
    showDialog(
      context: context,
      builder: (context) => _AuthorizationDialog(
        veterinarianId: widget.veterinarianId,
        onSuccess: () {
          setState(() {
            _isAuthorized = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Demande d\'autorisation envoyée')),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profil du Vétérinaire'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<VeterinarianProfile?>(
        future: _profileFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error_outline,
                    size: 48,
                    color: Colors.red,
                  ),
                  const SizedBox(height: 16),
                  Text('Erreur: ${snapshot.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Retour'),
                  ),
                ],
              ),
            );
          }

          if (!snapshot.hasData || snapshot.data == null) {
            return const Center(
              child: Text('Profil non trouvé'),
            );
          }

          final profile = snapshot.data!;

          return SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Profile Header
                Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF8B6F47),
                        const Color(0xFF6B5838),
                      ],
                    ),
                  ),
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 60,
                        backgroundColor: Colors.white10,
                        child: Text(
                          profile.specialty.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                            fontSize: 48,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        profile.specialty,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (profile.isVerified)
                        Chip(
                          label: const Text('Vérifié'),
                          backgroundColor: Colors.green.withOpacity(0.3),
                          labelStyle: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w600,
                          ),
                          avatar: const Icon(
                            Icons.verified,
                            color: Colors.green,
                            size: 16,
                          ),
                        ),
                    ],
                  ),
                ),

                // Stats Row
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _StatCard(
                        label: 'Consultations',
                        value: '${profile.consultationCount ?? 0}',
                        icon: Icons.medical_services,
                      ),
                      _StatCard(
                        label: 'Évaluation',
                        value: profile.rating?.toStringAsFixed(1) ?? 'N/A',
                        icon: Icons.star,
                      ),
                      _StatCard(
                        label: 'Expérience',
                        value: '${profile.experienceYears} ans',
                        icon: Icons.school,
                      ),
                    ],
                  ),
                ),

                // Bio Section
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'À propos',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        profile.bio ?? 'Pas de bio disponible',
                        style: const TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),

                // Zone & Coverage
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Zone de couverture',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(
                            Icons.location_on,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            profile.zone,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.directions_car,
                            color: Colors.orange,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Max ${profile.distanceMax} km',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Contact Preference
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Préférence de contact',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            _ContactMethodIcon(profile.contactPreference),
                            const SizedBox(width: 12),
                            Text(
                              _getContactMethodLabel(profile.contactPreference),
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Reviews Section (placeholder)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Avis des agriculteurs',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white10,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Pas d\'avis disponibles pour le moment',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Action Buttons
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (!_isAuthorized)
                        ElevatedButton.icon(
                          onPressed: _requestAuthorization,
                          icon: const Icon(Icons.person_add),
                          label: const Text('Demander l\'accès'),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: const Color(0xFF8B6F47),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            border: Border.all(color: Colors.green),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle, color: Colors.green),
                              SizedBox(width: 8),
                              Text(
                                'Accès autorisé',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      OutlinedButton.icon(
                        onPressed: () {
                          // TODO: Implement WhatsApp contact
                        },
                        icon: const Icon(Icons.chat),
                        label: const Text('Envoyer un message'),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  String _getContactMethodLabel(String method) {
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
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF8B6F47), size: 24),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }
}

class _ContactMethodIcon extends StatelessWidget {
  final String method;

  const _ContactMethodIcon(this.method);

  @override
  Widget build(BuildContext context) {
    switch (method) {
      case 'whatsapp':
        return const Icon(Icons.chat_bubble, color: Color(0xFF25D366));
      case 'call':
        return const Icon(Icons.phone, color: Colors.blue);
      case 'email':
        return const Icon(Icons.email, color: Colors.orange);
      default:
        return const Icon(Icons.contact_mail);
    }
  }
}

class _AuthorizationDialog extends StatefulWidget {
  final String veterinarianId;
  final VoidCallback onSuccess;

  const _AuthorizationDialog({
    required this.veterinarianId,
    required this.onSuccess,
  });

  @override
  State<_AuthorizationDialog> createState() => _AuthorizationDialogState();
}

class _AuthorizationDialogState extends State<_AuthorizationDialog> {
  final TextEditingController _reasonController = TextEditingController();
  bool _isLoading = false;

  Future<void> _submitRequest() async {
    if (_reasonController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez indiquer la raison')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.createAuthorization(
        veterinarianId: int.tryParse(widget.veterinarianId) ?? 0,
        authorizationReason: _reasonController.text,
      );
      widget.onSuccess();
      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Demander l\'accès'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Pourquoi souhaitez-vous travailler avec ce vétérinaire?',
            style: TextStyle(fontSize: 14),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _reasonController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Décrivez vos besoins ou votre situation...',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
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
          onPressed: _isLoading ? null : _submitRequest,
          child: _isLoading
              ? const SizedBox(
                  height: 16,
                  width: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Envoyer'),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }
}
