import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';

class EditVeterinarianProfileScreen extends StatefulWidget {
  const EditVeterinarianProfileScreen({Key? key}) : super(key: key);

  @override
  State<EditVeterinarianProfileScreen> createState() =>
      _EditVeterinarianProfileScreenState();
}

class _EditVeterinarianProfileScreenState
    extends State<EditVeterinarianProfileScreen> {
  late PageController _pageController;
  int _currentStep = 0;

  // Step 1: Professional Info
  late TextEditingController _specialtyController;
  late TextEditingController _zoneController;
  late TextEditingController _distanceMaxController;
  late TextEditingController _experienceYearsController;
  late TextEditingController _bioController;

  // Step 2: Contact Preference
  String _contactPreference = 'whatsapp';

  // Step 3: Certificate
  File? _certificateFile;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _specialtyController = TextEditingController();
    _zoneController = TextEditingController();
    _distanceMaxController = TextEditingController();
    _experienceYearsController = TextEditingController();
    _bioController = TextEditingController();

    _loadCurrentProfile();
  }

  Future<void> _loadCurrentProfile() async {
    try {
      final profile = await ApiService.getVeterinarianProfile();
      if (profile != null) {
        setState(() {
          _specialtyController.text = profile.specialty;
          _zoneController.text = profile.zone;
          _distanceMaxController.text = profile.distanceMax.toString();
          _experienceYearsController.text = profile.experienceYears.toString();
          _bioController.text = profile.bio ?? '';
          _contactPreference = profile.contactPreference;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur: $e')),
      );
    }
  }

  Future<void> _pickCertificate() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);

    if (file != null) {
      setState(() {
        _certificateFile = File(file.path);
      });
    }
  }

  bool _validateStep1() {
    if (_specialtyController.text.isEmpty) {
      _showError('Veuillez entrer votre spécialité');
      return false;
    }
    if (_zoneController.text.isEmpty) {
      _showError('Veuillez entrer votre zone');
      return false;
    }
    if (_distanceMaxController.text.isEmpty) {
      _showError('Veuillez entrer la distance maximale');
      return false;
    }
    if (_experienceYearsController.text.isEmpty) {
      _showError('Veuillez entrer vos années d\'expérience');
      return false;
    }
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _saveProfile() async {
    setState(() => _isLoading = true);

    try {
      // Call API to update profile
      // TODO: Implement updateVeterinarianProfile API call
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil mise à jour avec succès')),
      );
      Navigator.pop(context);
    } catch (e) {
      _showError('Erreur: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _nextStep() {
    if (_currentStep == 0 && !_validateStep1()) {
      return;
    }

    if (_currentStep < 2) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _saveProfile();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Éditer mon profil'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Progress Bar
          LinearProgressIndicator(
            value: (_currentStep + 1) / 3,
            minHeight: 4,
            backgroundColor: Colors.white10,
            valueColor: const AlwaysStoppedAnimation<Color>(
              Color(0xFF8B6F47),
            ),
          ),

          // Step Counter
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              'Étape ${_currentStep + 1} sur 3',
              style: const TextStyle(
                fontSize: 14,
                color: Colors.grey,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          // Page View
          Expanded(
            child: PageView(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() => _currentStep = index);
              },
              children: [
                // Step 1: Professional Info
                _buildStep1(),

                // Step 2: Contact Preference
                _buildStep2(),

                // Step 3: Certificate
                _buildStep3(),
              ],
            ),
          ),

          // Bottom Navigation
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_currentStep > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousStep,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Précédent'),
                    ),
                  ),
                if (_currentStep > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _nextStep,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      backgroundColor: const Color(0xFF8B6F47),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.white,
                              ),
                            ),
                          )
                        : Text(
                            _currentStep == 2 ? 'Enregistrer' : 'Suivant',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep1() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Informations professionnelles',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Spécialité',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _specialtyController,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'ex: Vétérinaire équin',
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Zone de couverture',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _zoneController,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'ex: Ouest Cameroun',
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Distance maximale de couverture (km)',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _distanceMaxController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'ex: 50',
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Années d\'expérience',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _experienceYearsController,
            keyboardType: TextInputType.number,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'ex: 10',
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Biographie',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _bioController,
            maxLines: 4,
            style: const TextStyle(fontSize: 16),
            decoration: InputDecoration(
              hintText: 'Parlez un peu de vous...',
              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Préférence de contact',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Comment les agriculteurs peuvent-ils vous contacter?',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 20),
          _buildContactOption(
            'whatsapp',
            'WhatsApp',
            Icons.chat_bubble,
            const Color(0xFF25D366),
          ),
          const SizedBox(height: 12),
          _buildContactOption(
            'call',
            'Appel téléphonique',
            Icons.phone,
            Colors.blue,
          ),
          const SizedBox(height: 12),
          _buildContactOption(
            'email',
            'Email',
            Icons.email,
            Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildContactOption(
    String value,
    String label,
    IconData icon,
    Color color,
  ) {
    return GestureDetector(
      onTap: () {
        setState(() => _contactPreference = value);
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(
            color: _contactPreference == value
                ? const Color(0xFF8B6F47)
                : Colors.white10,
            width: 2,
          ),
          borderRadius: BorderRadius.circular(8),
          color: _contactPreference == value
              ? const Color(0xFF8B6F47).withOpacity(0.1)
              : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (_contactPreference == value)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF8B6F47),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildStep3() {
    return SingleChildScrollView(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Certificat professionnel',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Téléchargez votre certificat ou diplôme (PDF, JPG, PNG)',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),
          if (_certificateFile != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    border: Border.all(color: Colors.green),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle, color: Colors.green),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Fichier sélectionné',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              _certificateFile!.path.split('/').last,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          setState(() => _certificateFile = null);
                        },
                        child: const Icon(Icons.close),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _pickCertificate,
                    icon: const Icon(Icons.edit),
                    label: const Text('Changer le fichier'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            )
          else
            GestureDetector(
              onTap: _pickCertificate,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 40),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Colors.white10,
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.cloud_upload,
                      size: 48,
                      color: Color(0xFF8B6F47),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Appuyez pour télécharger',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'ou glissez et déposez votre fichier',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, color: Colors.blue, size: 20),
                SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Votre certificat doit être clair et lisible',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _specialtyController.dispose();
    _zoneController.dispose();
    _distanceMaxController.dispose();
    _experienceYearsController.dispose();
    _bioController.dispose();
    super.dispose();
  }
}
