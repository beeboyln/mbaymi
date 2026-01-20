import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/screens/create_farm_post_dialog.dart';
import 'package:mbaymi/screens/farm_screen.dart';
import 'package:mbaymi/utils/app_colors.dart';

class UserProfileScreen extends StatefulWidget {
  final int userId;
  final bool isDarkMode;

  const UserProfileScreen({
    Key? key,
    required this.userId,
    required this.isDarkMode,
  }) : super(key: key);

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with AutomaticKeepAliveClientMixin {
  // ✅ Futures créées une seule fois et cachées
  Future<Map<String, dynamic>>? _profileFuture;
  Future<List<dynamic>>? _postsFuture;
  
  Map<String, dynamic> _profileData = {};
  List<dynamic> _postsData = [];
  
  final ImagePicker _imagePicker = ImagePicker();

  // Couleurs
  static const Color _primaryColor = Color(0xFF8B6B4D);
  static const Color _primaryLight = Color(0xFFA58A6D);
  static const Color _accentColor = Color(0xFFC4A484);
  static const Color _bgLight = Color(0xFFFAF8F5);
  static const Color _bgDark = Color(0xFF121212);
  static const Color _cardLight = AppColors.lightBg;
  static const Color _cardDark = Color(0xFF1E1E1E);
  static const Color _borderLight = Color(0xFFE8E2D8);
  static const Color _borderDark = Color(0xFF2C2C2C);
  static const Color _textLight = Color(0xFF1A1A1A);
  static const Color _textDark = Colors.white;
  static const Color _textSecondaryLight = Color(0xFF6B6B6B);
  static const Color _textSecondaryDark = Color(0xFF8E8E93);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    // Créer les futures qu'UNE SEULE FOIS
    final viewerId = AuthService.currentSession?.userId ?? 0;
    _profileFuture ??= ApiService.getUserProfile(widget.userId, viewerId: viewerId > 0 ? viewerId : null);
    _postsFuture ??= ApiService.getUserPosts(widget.userId, viewerId: viewerId > 0 ? viewerId : null);
  }

  @override
  void didUpdateWidget(UserProfileScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Ne recharger que si l'userId change
    if (oldWidget.userId != widget.userId) {
      final viewerId = AuthService.currentSession?.userId ?? 0;
      _profileFuture = ApiService.getUserProfile(widget.userId, viewerId: viewerId > 0 ? viewerId : null);
      _postsFuture = ApiService.getUserPosts(widget.userId, viewerId: viewerId > 0 ? viewerId : null);
      setState(() {});
    }
  }

  Future<void> _refresh() async {
    // Recharger UNIQUEMENT si on swipe
    final viewerId = AuthService.currentSession?.userId ?? 0;
    _profileFuture = ApiService.getUserProfile(widget.userId, viewerId: viewerId > 0 ? viewerId : null);
    _postsFuture = ApiService.getUserPosts(widget.userId, viewerId: viewerId > 0 ? viewerId : null);
    setState(() {});
  }

  Future<void> _pickAndUploadProfileImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (image == null) return;

      // Afficher un indicateur de chargement
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Téléchargement de la photo...'),
            duration: Duration(seconds: 3),
          ),
        );
      }

      // Upload vers Cloudinary (comme pour les fermes)
      final imageUrl = await ApiService.uploadImageToCloudinary(image);
      
      if (imageUrl == null) {
        throw Exception('Impossible de télécharger l\'image');
      }

      // Mettre à jour le profil avec l'URL Cloudinary
      final result = await ApiService.updateUserProfile(
        userId: widget.userId,
        profileImage: imageUrl,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['success'] == true ? 'Photo de profil mise à jour ✅' : 'Erreur'),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showEditProfileDialog(String currentName, String currentEmail, String currentPhone) async {
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);
    final phoneController = TextEditingController(text: currentPhone);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final isDark = widget.isDarkMode;
        final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F1E8);
        final textColor = isDark ? Colors.white : Colors.black87;

        return AlertDialog(
          backgroundColor: bgColor,
          title: Text(
            'Modifier mon profil',
            style: TextStyle(color: textColor),
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // TextField pour le nom
                  TextField(
                    controller: nameController,
                    autofocus: false,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: textColor),
                    decoration: InputDecoration(
                      labelText: 'Nom',
                      labelStyle: TextStyle(color: textColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _primaryColor.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // TextField pour l'email
                  TextField(
                    controller: emailController,
                    autofocus: false,
                    textInputAction: TextInputAction.next,
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      labelText: 'Email',
                      labelStyle: TextStyle(color: textColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _primaryColor.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // TextField pour le téléphone
                  TextField(
                    controller: phoneController,
                    autofocus: false,
                    textInputAction: TextInputAction.done,
                    style: TextStyle(color: textColor),
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: 'Numéro de téléphone',
                      labelStyle: TextStyle(color: textColor),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(
                          color: _primaryColor.withOpacity(0.3),
                        ),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: _primaryColor, width: 2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Bouton pour changer le mot de passe
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        _showChangePasswordDialog();
                      },
                      icon: const Icon(Icons.lock),
                      label: const Text('Changer mon mot de passe'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[400],
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                emailController.dispose();
                phoneController.dispose();
                Navigator.pop(context);
              },
              child: Text(
                'Annuler',
                style: TextStyle(color: textColor),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
              ),
              onPressed: () async {
                nameController.dispose();
                emailController.dispose();
                phoneController.dispose();
                Navigator.pop(context);
                await _updateProfile(
                  nameController.text.trim(),
                  emailController.text.trim(),
                  phoneController.text.trim(),
                );
              },
              child: const Text(
                'Enregistrer',
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateProfile(String name, String email, String phone) async {
    try {
      if (name.isEmpty && email.isEmpty && phone.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez modifier au moins un champ'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      final result = await ApiService.updateUserProfile(
        userId: widget.userId,
        name: name.isNotEmpty ? name : null,
        email: email.isNotEmpty ? email : null,
        phone: phone.isNotEmpty ? phone : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Profil mis à jour'),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
        _refresh();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _showChangePasswordDialog() async {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    bool showPassword = false;

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final isDark = widget.isDarkMode;
        final bgColor = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF5F1E8);
        final textColor = isDark ? Colors.white : Colors.black87;

        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              backgroundColor: bgColor,
              title: Text(
                'Changer mon mot de passe',
                style: TextStyle(color: textColor),
              ),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Mot de passe actuel
                      TextField(
                        controller: currentPasswordController,
                        autofocus: false,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(color: textColor),
                        obscureText: !showPassword,
                        decoration: InputDecoration(
                          labelText: 'Mot de passe actuel',
                          labelStyle: TextStyle(color: textColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _primaryColor.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _primaryColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Nouveau mot de passe
                      TextField(
                        controller: newPasswordController,
                        autofocus: false,
                        textInputAction: TextInputAction.next,
                        style: TextStyle(color: textColor),
                        obscureText: !showPassword,
                        decoration: InputDecoration(
                          labelText: 'Nouveau mot de passe',
                          labelStyle: TextStyle(color: textColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _primaryColor.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _primaryColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Confirmer le mot de passe
                      TextField(
                        controller: confirmPasswordController,
                        autofocus: false,
                        textInputAction: TextInputAction.done,
                        style: TextStyle(color: textColor),
                        obscureText: !showPassword,
                        decoration: InputDecoration(
                          labelText: 'Confirmer le mot de passe',
                          labelStyle: TextStyle(color: textColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(
                              color: _primaryColor.withOpacity(0.3),
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: const BorderSide(color: _primaryColor, width: 2),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Checkbox pour afficher/masquer le mot de passe
                      Row(
                        children: [
                          Checkbox(
                            value: showPassword,
                            onChanged: (value) {
                              setState(() {
                                showPassword = value ?? false;
                              });
                            },
                          ),
                          Text(
                            'Afficher le mot de passe',
                            style: TextStyle(color: textColor),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    currentPasswordController.dispose();
                    newPasswordController.dispose();
                    confirmPasswordController.dispose();
                    Navigator.pop(context);
                  },
                  child: Text(
                    'Annuler',
                    style: TextStyle(color: textColor),
                  ),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[400],
                  ),
                  onPressed: () async {
                    Navigator.pop(context);
                    await _changePassword(
                      currentPasswordController.text.trim(),
                      newPasswordController.text.trim(),
                      confirmPasswordController.text.trim(),
                    );
                    currentPasswordController.dispose();
                    newPasswordController.dispose();
                    confirmPasswordController.dispose();
                  },
                  child: const Text(
                    'Changer',
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _changePassword(String currentPassword, String newPassword, String confirmPassword) async {
    try {
      // Validations
      if (currentPassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer votre mot de passe actuel'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (newPassword.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Veuillez entrer un nouveau mot de passe'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (newPassword != confirmPassword) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Les mots de passe ne correspondent pas'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      if (newPassword.length < 6) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Le mot de passe doit contenir au moins 6 caractères'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }

      // Appeler l'API pour changer le mot de passe
      final result = await ApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message'] ?? 'Mot de passe changé avec succès'),
            backgroundColor: _primaryColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: Colors.red.shade400,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    
    final isDark = widget.isDarkMode;
    final isOwnProfile = widget.userId == (AuthService.currentSession?.userId ?? 0);
    final bgColor = isDark ? _bgDark : _bgLight;
    final cardColor = isDark ? _cardDark : _cardLight;
    final textColor = isDark ? _textDark : _textLight;
    final secondaryTextColor = isDark ? _textSecondaryDark : _textSecondaryLight;
    final borderColor = isDark ? _borderDark : _borderLight;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: const Text('Mon Profil', style: TextStyle(fontWeight: FontWeight.w300)),
        centerTitle: true,
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.logout, color: textColor, size: 22),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Se déconnecter'),
                  content: const Text('Êtes-vous sûr de vouloir vous déconnecter ?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: const Text('Annuler'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: const Text('Déconnecter', style: TextStyle(color: Colors.red)),
                    ),
                  ],
                ),
              );
              
              if (confirm == true) {
                await ApiService.logout();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Déconnecté avec succès')),
                  );
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    '/login',
                    (route) => false,
                  );
                }
              }
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: _primaryColor,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _profileFuture!,
            builder: (context, profileSnap) {
              if (profileSnap.connectionState == ConnectionState.waiting) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(40),
                    child: CircularProgressIndicator(color: _primaryColor),
                  ),
                );
              }

              if (profileSnap.hasError) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Text(
                      'Erreur: ${profileSnap.error}',
                      style: TextStyle(color: textColor),
                      textAlign: TextAlign.center,
                    ),
                  ),
                );
              }

              // Store profile data in state
              _profileData = profileSnap.data ?? {};
              
              final profile = _profileData;
              final name = profile['name'] ?? 'Utilisateur';
              final email = profile['email'] ?? '';
              final phone = profile['phone'] ?? '';
              final profileImage = profile['profile_image'] as String?;
              final totalFollowers = profile['total_followers'] ?? 0;
              final totalPosts = profile['total_posts'] ?? 0;

              return Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 👤 En-tête du profil
                    DecoratedBox(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: const BorderRadius.all(Radius.circular(16)),
                        border: Border.all(color: borderColor, width: 1),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Avatar + Nom
                            Row(
                              children: [
                                GestureDetector(
                                  onTap: isOwnProfile ? _pickAndUploadProfileImage : null,
                                  child: Stack(
                                    children: [
                                      profileImage != null && profileImage.isNotEmpty
                                          ? Container(
                                              width: 80,
                                              height: 80,
                                              decoration: BoxDecoration(
                                                borderRadius: BorderRadius.circular(40),
                                                border: Border.all(
                                                  color: _primaryColor,
                                                  width: 2,
                                                ),
                                              ),
                                              child: ClipRRect(
                                                borderRadius: BorderRadius.circular(40),
                                                child: Image.network(
                                                  profileImage,
                                                  fit: BoxFit.cover,
                                                  errorBuilder: (_, __, ___) =>
                                                      _buildDefaultAvatar(name),
                                                ),
                                              ),
                                            )
                                          : _buildDefaultAvatar(name),
                                      // Bouton d'édition (seulement si mon profil)
                                      if (isOwnProfile)
                                        Positioned(
                                          bottom: 0,
                                          right: 0,
                                          child: Container(
                                            decoration: BoxDecoration(
                                              color: _primaryColor,
                                              shape: BoxShape.circle,
                                              border: Border.all(
                                                color: cardColor,
                                                width: 2,
                                              ),
                                            ),
                                            padding: const EdgeInsets.all(6),
                                            child: const Icon(
                                              Icons.camera_alt,
                                              color: Colors.white,
                                              size: 16,
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      GestureDetector(
                                        onTap: isOwnProfile ? () => _showEditProfileDialog(name, email, phone) : null,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                name,
                                                style: TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w400,
                                                  color: textColor,
                                                ),
                                              ),
                                            ),
                                            if (isOwnProfile)
                                              Icon(
                                                Icons.edit_outlined,
                                                size: 16,
                                                color: _primaryColor,
                                              ),
                                          ],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      GestureDetector(
                                        onTap: isOwnProfile ? () => _showEditProfileDialog(name, email, phone) : null,
                                        child: Row(
                                          children: [
                                            Expanded(
                                              child: Text(
                                                email,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: secondaryTextColor,
                                                ),
                                              ),
                                            ),
                                            if (isOwnProfile)
                                              Icon(
                                                Icons.edit_outlined,
                                                size: 14,
                                                color: secondaryTextColor,
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            
                            // Stats simplifiées (uniquement abonnés et posts)
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                _buildStatWidget(
                                  icon: Icons.people_outline,
                                  label: 'Abonnés',
                                  value: '$totalFollowers',
                                  color: _accentColor,
                                ),
                                _buildStatWidget(
                                  icon: Icons.newspaper,
                                  label: 'Posts',
                                  value: '$totalPosts',
                                  color: _primaryLight,
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),
                            
                            // Accès rapide - Action pour créer du contenu
                            _buildQuickActionButton(
                              context: context,
                              icon: Icons.add_circle_outline,
                              label: 'Créer un post',
                              color: _primaryColor,
                              onTap: () {
                                HapticFeedback.lightImpact();
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => FarmTab(userId: widget.userId),
                                  ),
                                );
                              },
                              isDark: isDark,
                              cardColor: cardColor,
                              borderColor: borderColor,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 📰 Mes publications
                    Text(
                      'Mes Publications',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<dynamic>>(
                      future: _postsFuture!,
                      builder: (context, postsSnap) {
                        if (postsSnap.connectionState == ConnectionState.waiting) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: CircularProgressIndicator(color: _primaryColor),
                            ),
                          );
                        }

                        if (postsSnap.hasError) {
                          return Text(
                            'Erreur: ${postsSnap.error}',
                            style: TextStyle(color: textColor),
                          );
                        }

                        // Store posts data in state
                        _postsData = postsSnap.data ?? [];
                        
                        final posts = _postsData;
                        if (posts.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 40),
                              child: Column(
                                children: [
                                  Icon(
                                    Icons.newspaper_outlined,
                                    size: 48,
                                    color: _primaryColor.withOpacity(0.5),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Aucune publication',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: secondaryTextColor,
                                      fontWeight: FontWeight.w300,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Créez votre première publication',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: secondaryTextColor.withOpacity(0.7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          shrinkWrap: true,
                          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 1,
                          ),
                          itemCount: posts.length,
                          itemBuilder: (context, index) {
                            final post = posts[index];
                            final title = post['title'] ?? '';
                            final farmName = post['farm_name'] ?? '';
                            final imageUrl = post['image_url'] as String?;
                            final createdAt = post['created_at'] ?? '';
                            final postType = post['post_type'] ?? 'crop_update';
                            
                            DateTime? dateTime;
                            try {
                              dateTime = DateTime.parse(createdAt);
                            } catch (_) {}
                            
                            final formattedDate = dateTime != null
                                ? DateFormat('dd/MM/yyyy').format(dateTime)
                                : 'Date inconnue';

                            final postTypeEmoji = _getPostTypeEmoji(postType);

                            return GestureDetector(
                              onTap: () {
                                // Afficher les détails du post
                                _showPostDetails(context, post, cardColor, textColor, secondaryTextColor, borderColor);
                              },
                              child: Container(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: borderColor, width: 1),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Stack(
                                  children: [
                                    // Image de fond
                                    if (imageUrl != null && imageUrl.isNotEmpty)
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(12),
                                        child: Image.network(
                                          imageUrl,
                                          fit: BoxFit.cover,
                                          width: double.infinity,
                                          height: double.infinity,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: _primaryColor.withOpacity(0.1),
                                            child: const Icon(Icons.image_not_supported_outlined, size: 32),
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        decoration: BoxDecoration(
                                          color: _primaryColor.withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: const Icon(Icons.image_outlined, size: 32),
                                      ),
                                    
                                    // Overlay au hover
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(12),
                                        gradient: LinearGradient(
                                          begin: Alignment.bottomCenter,
                                          end: Alignment.topCenter,
                                          colors: [
                                            Colors.black.withOpacity(0.8),
                                            Colors.transparent,
                                          ],
                                        ),
                                      ),
                                    ),
                                    
                                    // Contenu en bas
                                    Positioned(
                                      bottom: 0,
                                      left: 0,
                                      right: 0,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                Text(
                                                  postTypeEmoji,
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    title,
                                                    style: const TextStyle(
                                                      fontSize: 11,
                                                      fontWeight: FontWeight.w600,
                                                      color: Colors.white,
                                                    ),
                                                    maxLines: 1,
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 2),
                                            Text(
                                              formattedDate,
                                              style: const TextStyle(
                                                fontSize: 9,
                                                color: Colors.white70,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStatWidget({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    final isDark = widget.isDarkMode;
    return Column(
      children: [
        Icon(icon, size: 24, color: color),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isDark ? _textSecondaryDark : _textSecondaryLight,
          ),
        ),
      ],
    );
  }

  Widget _buildQuickActionButton({
    required BuildContext context,
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardColor,
    required Color borderColor,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                color.withOpacity(0.1),
                color.withOpacity(0.05),
              ],
            ),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(color: color.withOpacity(0.2), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 12),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPostTypeEmoji(String postType) {
    switch (postType) {
      case 'crop_update':
        return '🌱';
      case 'harvest_result':
        return '🌾';
      case 'problem_report':
        return '🚨';
      case 'tip':
        return '💡';
      default:
        return '📝';
    }
  }

  void _showPostDetails(
    BuildContext context,
    Map<String, dynamic> post,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => Container(
        color: cardColor,
        child: ListView(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        post['title'] ?? '',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.close, color: textColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (post['image_url'] != null && (post['image_url'] as String).isNotEmpty)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        post['image_url'],
                        height: 250,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  const SizedBox(height: 16),
                  Text(
                    'Ferme: ${post['farm_name'] ?? 'N/A'}',
                    style: TextStyle(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Date: ${DateFormat('dd/MM/yyyy').format(DateTime.parse(post['created_at'] ?? ''))}',
                    style: TextStyle(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (post['caption'] != null && (post['caption'] as String).isNotEmpty)
                    Text(
                      post['caption'],
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: textColor,
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

  Widget _buildDefaultAvatar(String name) {
    return CircleAvatar(
      radius: 40,
      backgroundColor: _primaryColor,
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}