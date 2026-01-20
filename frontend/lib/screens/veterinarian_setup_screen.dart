import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:mbaymi/utils/app_colors.dart';

class VeterinarianSetupScreen extends StatefulWidget {
  const VeterinarianSetupScreen({Key? key}) : super(key: key);

  @override
  State<VeterinarianSetupScreen> createState() =>
      _VeterinarianSetupScreenState();
}

class _VeterinarianSetupScreenState extends State<VeterinarianSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  int _currentStep = 0;

  // Step 1: Professional Info
  final _specialtyController = TextEditingController();
  final _zoneController = TextEditingController();
  final _distanceController = TextEditingController();
  final _bioController = TextEditingController();
  final _experienceController = TextEditingController();

  // Focus nodes
  final _specialtyFocus = FocusNode();
  final _zoneFocus = FocusNode();
  final _distanceFocus = FocusNode();
  final _experienceFocus = FocusNode();
  final _bioFocus = FocusNode();

  // Step 2: Contact Preference
  String _contactPreference = 'whatsapp';

  // Step 3: Certificate
  File? _certificateFile;
  final ImagePicker _imagePicker = ImagePicker();

  final ScrollController _scrollController = ScrollController();

  static const Color _primaryColor = Colors.brown;

  bool get isWeb => kIsWeb;

  @override
  void initState() {
    super.initState();
    _restoreSession();
    _setupFocusListeners();
  }

  void _setupFocusListeners() {
    _specialtyFocus.addListener(() {
      if (_specialtyFocus.hasFocus && isWeb) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _smartScroll(100);
        });
      }
    });

    _zoneFocus.addListener(() {
      if (_zoneFocus.hasFocus && isWeb) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _smartScroll(180);
        });
      }
    });

    _distanceFocus.addListener(() {
      if (_distanceFocus.hasFocus && isWeb) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _smartScroll(260);
        });
      }
    });

    _experienceFocus.addListener(() {
      if (_experienceFocus.hasFocus && isWeb) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _smartScroll(340);
        });
      }
    });

    _bioFocus.addListener(() {
      if (_bioFocus.hasFocus && isWeb) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _smartScroll(420);
        });
      }
    });
  }

  void _smartScroll(double offset) {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final targetOffset = offset > maxScroll ? maxScroll : offset;

    _scrollController.animateTo(
      targetOffset,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  Future<void> _restoreSession() async {
    try {
      await AuthService.restoreSession();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Session: ${e.toString()}'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }
  static const Color _accentColor = Color(0xFF8B6F47);

  @override
  void dispose() {
    _specialtyController.dispose();
    _zoneController.dispose();
    _distanceController.dispose();
    _bioController.dispose();
    _experienceController.dispose();

    _specialtyFocus.dispose();
    _zoneFocus.dispose();
    _distanceFocus.dispose();
    _experienceFocus.dispose();
    _bioFocus.dispose();
    _scrollController.dispose();

    super.dispose();
  }

  InputDecoration _inputDecoration(String label) {
    return InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.grey),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8E2D8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFE8E2D8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: _primaryColor, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    );
  }

  Future<void> _pickCertificate() async {
    try {
      final XFile? file = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
      );
      if (file != null) {
        setState(() => _certificateFile = File(file.path));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _submitProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Create veterinarian profile
      await ApiService.createVeterinarianProfile(
        specialty: _specialtyController.text.trim(),
        zone: _zoneController.text.trim(),
        distanceMax: int.tryParse(_distanceController.text) ?? 50,
        bio: _bioController.text.trim(),
        experienceYears: int.tryParse(_experienceController.text) ?? 0,
        contactPreference: _contactPreference,
      );

      if (!mounted) return;

      // If certificate was selected, upload it
      if (_certificateFile != null) {
        try {
          await ApiService.uploadCertificate(_certificateFile!);
        } catch (e) {
          // Certificate upload failed but profile created
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Profil créé, certificat non uploadé: ${e.toString()}'),
                backgroundColor: Colors.orange,
              ),
            );
          }
        }
      }

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profil vétérinaire créé avec succès'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to home screen (which will show veterinarian dashboard)
      Navigator.of(context).pushReplacementNamed('/');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erreur: ${e.toString()}'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF121212) : const Color(0xFFF5F1E8);
    final textColor = isDark ? Colors.white : const Color(0xFF1A1A1A);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: isDark ? const Color(0xFF1E1E1E) : AppColors.lightBg,
        elevation: 0,
        foregroundColor: textColor,
        title: const Text(
          'Profil Vétérinaire',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const ClampingScrollPhysics(),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.manual,
          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 24,
            bottom: isWeb ? 60 : 24,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Progress indicator
                SizedBox(
                  height: 8,
                  child: LinearProgressIndicator(
                    value: (_currentStep + 1) / 3,
                    backgroundColor: Colors.grey[300],
                    valueColor: const AlwaysStoppedAnimation<Color>(_primaryColor),
                  ),
                ),
                const SizedBox(height: 32),

                // Step 1: Professional Info
                if (_currentStep == 0) ...[
                  Text(
                    'Étape 1: Informations Professionnelles',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Specialty
                  TextFormField(
                    controller: _specialtyController,
                    focusNode: _specialtyFocus,
                    style: TextStyle(color: textColor, fontSize: 16),
                    decoration: _inputDecoration('Spécialité'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Spécialité requise' : null,
                  ),
                  const SizedBox(height: 24),

                  // Zone
                  TextFormField(
                    controller: _zoneController,
                    focusNode: _zoneFocus,
                    style: TextStyle(color: textColor, fontSize: 16),
                    decoration: _inputDecoration('Zone de couverture'),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Zone requise' : null,
                  ),
                  const SizedBox(height: 24),

                  // Distance
                  TextFormField(
                    controller: _distanceController,
                    focusNode: _distanceFocus,
                    style: TextStyle(color: textColor, fontSize: 16),
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Distance maximale (km)'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Distance requise';
                      if (int.tryParse(v) == null)
                        return 'Doit être un nombre';
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),

                  // Experience
                  TextFormField(
                    controller: _experienceController,
                    focusNode: _experienceFocus,
                    style: TextStyle(color: textColor, fontSize: 16),
                    keyboardType: TextInputType.number,
                    decoration: _inputDecoration('Années d\'expérience'),
                    validator: (v) {
                      if (v == null || v.isEmpty) return 'Expérience requise';
                      if (int.tryParse(v) == null)
                        return 'Doit être un nombre';
                      return null;
                    },
                  ),
                ] else if (_currentStep == 1) ...[
                  // Step 2: Biography & Contact
                  Text(
                    'Étape 2: Biographie & Contact',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Bio
                  TextFormField(
                    controller: _bioController,
                    focusNode: _bioFocus,
                    style: TextStyle(color: textColor, fontSize: 16),
                    maxLines: 5,
                    decoration: InputDecoration(
                      labelText: 'Biographie professionnelle',
                      labelStyle: const TextStyle(color: Colors.grey),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFE8E2D8)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: Color(0xFFE8E2D8)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: _primaryColor, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                    ),
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Biographie requise' : null,
                  ),
                  const SizedBox(height: 24),

                  // Contact Preference
                  Text(
                    'Préférence de contact',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Column(
                    children: [
                      RadioListTile<String>(
                        title: const Text('WhatsApp'),
                        value: 'whatsapp',
                        groupValue: _contactPreference,
                        onChanged: (v) =>
                            setState(() => _contactPreference = v ?? 'whatsapp'),
                      ),
                      RadioListTile<String>(
                        title: const Text('Appel téléphonique'),
                        value: 'call',
                        groupValue: _contactPreference,
                        onChanged: (v) =>
                            setState(() => _contactPreference = v ?? 'whatsapp'),
                      ),
                      RadioListTile<String>(
                        title: const Text('Email'),
                        value: 'email',
                        groupValue: _contactPreference,
                        onChanged: (v) =>
                            setState(() => _contactPreference = v ?? 'whatsapp'),
                      ),
                    ],
                  ),
                ] else if (_currentStep == 2) ...[
                  // Step 3: Certificate
                  Text(
                    'Étape 3: Certificat Professionnel',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 24),

                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: const Color(0xFFE8E2D8),
                        width: 2,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Icon(
                          _certificateFile != null
                              ? Icons.check_circle
                              : Icons.upload_file,
                          size: 48,
                          color: _certificateFile != null ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          _certificateFile != null
                              ? 'Certificat sélectionné'
                              : 'Aucun certificat sélectionné',
                          style: TextStyle(
                            fontSize: 14,
                            color: textColor,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        if (_certificateFile != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            _certificateFile!.path.split('/').last,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.grey,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _pickCertificate,
                          icon: const Icon(Icons.image),
                          label: const Text('Sélectionner'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.orange[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange[200]!),
                    ),
                    child: const Text(
                      '⚠️ Votre profil sera en attente de vérification. '
                      'Un administrateur examinera votre certificat dans les 24-48 heures.',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                ],

                const SizedBox(height: 40),

                // Navigation buttons
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (_currentStep > 0)
                      ElevatedButton(
                        onPressed: () =>
                            setState(() => _currentStep = _currentStep - 1),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.grey[400],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                        ),
                        child: const Text('Précédent'),
                      )
                    else
                      const SizedBox(width: 1),
                    ElevatedButton(
                      onPressed: _isLoading
                          ? null
                          : () {
                              if (_currentStep < 2) {
                                setState(() => _currentStep = _currentStep + 1);
                              } else {
                                _submitProfile();
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 12,
                        ),
                      ),
                      child: _isLoading
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor:
                                    AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(_currentStep < 2 ? 'Suivant' : 'Créer'),
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
