import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/screens/farm_screen.dart';
import 'package:mbaymi/screens/livestock_screen.dart';

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

class _UserProfileScreenState extends State<UserProfileScreen> {
  late Future<Map<String, dynamic>> _profileFuture;
  late Future<List<dynamic>> _postsFuture;
  final ImagePicker _imagePicker = ImagePicker();

  // Couleurs
  static const Color _primaryColor = Color(0xFF8B6B4D);
  static const Color _primaryLight = Color(0xFFA58A6D);
  static const Color _accentColor = Color(0xFFC4A484);
  static const Color _bgLight = Color(0xFFFAF8F5);
  static const Color _bgDark = Color(0xFF121212);
  static const Color _cardLight = Colors.white;
  static const Color _cardDark = Color(0xFF1E1E1E);
  static const Color _borderLight = Color(0xFFE8E2D8);
  static const Color _borderDark = Color(0xFF2C2C2C);
  static const Color _textLight = Color(0xFF1A1A1A);
  static const Color _textDark = Colors.white;
  static const Color _textSecondaryLight = Color(0xFF6B6B6B);
  static const Color _textSecondaryDark = Color(0xFF8E8E93);

  @override
  void initState() {
    super.initState();
    _profileFuture = ApiService.getUserProfile(widget.userId);
    _postsFuture = ApiService.getUserPosts(widget.userId);
  }

  Future<void> _refresh() async {
    setState(() {
      _profileFuture = ApiService.getUserProfile(widget.userId);
      _postsFuture = ApiService.getUserPosts(widget.userId);
    });
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

  Future<void> _showEditProfileDialog(String currentName, String currentEmail) async {
    final nameController = TextEditingController(text: currentName);
    final emailController = TextEditingController(text: currentEmail);

    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        final isDark = widget.isDarkMode;
        final bgColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
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
                  textInputAction: TextInputAction.done,
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
              ],
            ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                nameController.dispose();
                emailController.dispose();
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
                Navigator.pop(context);
                await _updateProfile(
                  nameController.text.trim(),
                  emailController.text.trim(),
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

  Future<void> _updateProfile(String name, String email) async {
    try {
      if (name.isEmpty && email.isEmpty) {
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

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode;
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
      ),
      body: RefreshIndicator(
        color: _primaryColor,
        onRefresh: _refresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: FutureBuilder<Map<String, dynamic>>(
            future: _profileFuture,
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

              final profile = profileSnap.data ?? {};
              final name = profile['name'] ?? 'Utilisateur';
              final email = profile['email'] ?? '';
              final profileImage = profile['profile_image'] as String?;
              final totalFarms = profile['total_farms'] ?? 0;
              final totalFollowers = profile['total_followers'] ?? 0;
              final totalPosts = profile['total_posts'] ?? 0;
              final farms = (profile['farms'] as List?) ?? [];

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
                                  onTap: _pickAndUploadProfileImage,
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
                                      // Bouton d'édition
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
                                        onTap: () => _showEditProfileDialog(name, email),
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
                                        onTap: () => _showEditProfileDialog(name, email),
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
                            
                            // Stats
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _buildStatWidget(
                                  icon: Icons.landscape_outlined,
                                  label: 'Fermes',
                                  value: '$totalFarms',
                                  color: _primaryColor,
                                ),
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
                            
                            // 🚀 Accès rapide - Fermes & Élevages
                            Row(
                              children: [
                                // Carousel des fermes avec images
                                if (farms.isNotEmpty)
                                  Expanded(
                                    child: GestureDetector(
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        _showFarmsModal(context, isDark, cardColor, textColor, secondaryTextColor, borderColor);
                                      },
                                      child: _buildFarmsCarousel(farms, isDark, borderColor, textColor, secondaryTextColor),
                                    ),
                                  )
                                else
                                  Expanded(
                                    child: _buildQuickAccessButton(
                                      context: context,
                                      icon: Icons.landscape_outlined,
                                      label: 'Mes Fermes',
                                      color: _primaryColor,
                                      onTap: () {
                                        HapticFeedback.lightImpact();
                                        _showFarmsModal(context, isDark, cardColor, textColor, secondaryTextColor, borderColor);
                                      },
                                      isDark: isDark,
                                      cardColor: cardColor,
                                      borderColor: borderColor,
                                    ),
                                  ),
                                const SizedBox(width: 12),
                                // Carousel des élevages (ou bouton par défaut si vide)
                                Expanded(
                                  child: GestureDetector(
                                    onTap: () {
                                      HapticFeedback.lightImpact();
                                      _showLivestockModal(context, isDark, cardColor, textColor, secondaryTextColor, borderColor);
                                    },
                                    child: _buildLivestockCarousel(isDark, borderColor, textColor, secondaryTextColor),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // 🌾 Mes Fermes - Affichée par défaut
                    if (farms.isNotEmpty) ...[
                      Text(
                        'Mes Fermes',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: textColor,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 16),
                      ...farms.asMap().entries.map((entry) {
                        final farm = entry.value as Map<String, dynamic>;
                        final isPublic = farm['is_public'] ?? false;
                        
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              color: cardColor,
                              borderRadius: const BorderRadius.all(Radius.circular(12)),
                              border: Border.all(color: borderColor, width: 1),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Titre et visibilité
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              farm['name'] ?? 'Ferme',
                                              style: TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.w500,
                                                color: textColor,
                                              ),
                                            ),
                                            if (farm['location'] != null && (farm['location'] as String).isNotEmpty) ...[
                                              const SizedBox(height: 4),
                                              Text(
                                                farm['location'] as String,
                                                style: TextStyle(
                                                  fontSize: 13,
                                                  color: secondaryTextColor,
                                                  fontWeight: FontWeight.w300,
                                                ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: isPublic
                                              ? Colors.green.withOpacity(0.1)
                                              : Colors.orange.withOpacity(0.1),
                                          borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Icon(
                                              isPublic ? Icons.public : Icons.lock_outlined,
                                              size: 14,
                                              color: isPublic ? Colors.green : Colors.orange,
                                            ),
                                            const SizedBox(width: 4),
                                            Text(
                                              isPublic ? 'Publique' : 'Privée',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: isPublic ? Colors.green : Colors.orange,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  
                                  // Bouton toggle visibilité
                                  SizedBox(
                                    width: double.infinity,
                                    child: Material(
                                      color: Colors.transparent,
                                      child: InkWell(
                                        onTap: () async {
                                          try {
                                            final result = await ApiService.toggleFarmVisibility(
                                              userId: widget.userId,
                                              farmId: farm['id'] as int,
                                              isPublic: !isPublic,
                                            );
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text(result['message'] ?? 'Visibilité mise à jour'),
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
                                        },
                                        borderRadius: const BorderRadius.all(Radius.circular(8)),
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          child: Row(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(
                                                isPublic ? Icons.visibility : Icons.visibility_off_outlined,
                                                size: 16,
                                                color: _primaryColor,
                                              ),
                                              const SizedBox(width: 8),
                                              Text(
                                                isPublic ? 'Rendre privée' : 'Rendre publique',
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w500,
                                                  color: _primaryColor,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                      const SizedBox(height: 32),
                    ],

                    // 📰 Mes publications
                    Text(
                      'Mes Publications',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 12),
                    FutureBuilder<List<dynamic>>(
                      future: _postsFuture,
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

                        final posts = postsSnap.data ?? [];
                        if (posts.isEmpty) {
                          return Center(
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Text(
                                'Aucune publication',
                                style: TextStyle(color: secondaryTextColor),
                              ),
                            ),
                          );
                        }

                        return Column(
                          children: posts.map((post) {
                            final title = post['title'] ?? '';
                            final farmName = post['farm_name'] ?? '';
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

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  color: cardColor,
                                  borderRadius: const BorderRadius.all(Radius.circular(12)),
                                  border: Border.all(color: borderColor, width: 1),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(16),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            postTypeEmoji,
                                            style: const TextStyle(fontSize: 18),
                                          ),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              title,
                                              style: TextStyle(
                                                fontSize: 15,
                                                fontWeight: FontWeight.w500,
                                                color: textColor,
                                              ),
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.landscape_outlined,
                                              size: 14, color: secondaryTextColor),
                                          const SizedBox(width: 6),
                                          Text(
                                            farmName,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                          const Spacer(),
                                          Text(
                                            formattedDate,
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: secondaryTextColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }).toList(),
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

  Widget _buildQuickAccessButton({
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
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: const BorderRadius.all(Radius.circular(12)),
            border: Border.all(color: color.withOpacity(0.3), width: 1),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 10),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: color,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showFarmsModal(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle et titre
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondaryTextColor.withOpacity(0.3),
                      borderRadius: const BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Titre
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.landscape_outlined, color: _primaryColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mes Fermes',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Gérez vos fermes',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: secondaryTextColor, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu - FarmTab
            Expanded(
              child: FarmTab(
                isDarkMode: isDark,
                userId: widget.userId,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLivestockModal(
    BuildContext context,
    bool isDark,
    Color cardColor,
    Color textColor,
    Color secondaryTextColor,
    Color borderColor,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            // Handle et titre
            Padding(
              padding: const EdgeInsets.only(top: 12, bottom: 16),
              child: Column(
                children: [
                  // Handle
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: secondaryTextColor.withOpacity(0.3),
                      borderRadius: const BorderRadius.all(Radius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Titre
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: Row(
                      children: [
                        Icon(Icons.pets_outlined, color: _accentColor, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Mes Élevages',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Suivez votre bétail',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: secondaryTextColor,
                                  fontWeight: FontWeight.w300,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close_rounded, color: secondaryTextColor, size: 24),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            // Contenu - LivestockTab
            Expanded(
              child: LivestockTab(
                isDarkMode: isDark,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmsCarousel(
    List<dynamic> farms,
    bool isDark,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return ClipRRect(
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: Container(
        decoration: BoxDecoration(
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Stack(
        children: [
          // Image de fond de la première ferme
          SizedBox(
            height: 140,
            width: double.infinity,
            child: _buildFarmImage(farms[0]),
          ),
          
          // Overlay sombre
          Container(
            height: 140,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  Colors.black.withOpacity(0.4),
                ],
              ),
            ),
          ),
          
          // Contenu - Titre et indicateur
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Nom de la ferme
                  Row(
                    children: [
                      Icon(Icons.landscape_outlined, size: 16, color: Colors.white),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          farms[0]['name'] ?? 'Ferme',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                            overflow: TextOverflow.ellipsis,
                          ),
                          maxLines: 1,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Indicateur de carousel
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: const BorderRadius.all(Radius.circular(4)),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: Text(
                          '1 / ${farms.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                      if (farms.length > 1)
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.9),
                            borderRadius: const BorderRadius.all(Radius.circular(4)),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          child: Text(
                            '+${farms.length - 1} autres',
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    ));
  }

  Widget _buildFarmImage(Map<String, dynamic> farm) {
    // DEBUG: Afficher les données de la ferme
    print('DEBUG FARM DATA: $farm');
    print('DEBUG FARM KEYS: ${farm.keys.toList()}');
    
    // Essayer de récupérer une image de ferme
    String? imageUrl;
    
    // Chercher dans l'image_url directement
    if (farm['image_url'] != null && (farm['image_url'] as String).isNotEmpty) {
      imageUrl = farm['image_url'] as String;
      print('DEBUG IMAGE FOUND: $imageUrl');
    }
    // Chercher dans les photos de la ferme
    else if (farm['photos'] != null && (farm['photos'] as List).isNotEmpty) {
      final photos = farm['photos'] as List;
      if (photos.isNotEmpty) {
        final firstPhoto = photos.first;
        if (firstPhoto is Map<String, dynamic>) {
          imageUrl = firstPhoto['image_url'] as String?;
        } else {
          imageUrl = firstPhoto.toString();
        }
      }
    }
    
    // Si pas d'image, afficher une couleur par défaut
    if (imageUrl == null || imageUrl.isEmpty) {
      return Container(
        color: _UserProfileScreenState._primaryColor.withOpacity(0.2),
        child: Center(
          child: Icon(
            Icons.landscape_outlined,
            size: 48,
            color: _UserProfileScreenState._primaryColor.withOpacity(0.5),
          ),
        ),
      );
    }
    
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) => Container(
        color: _UserProfileScreenState._primaryColor.withOpacity(0.2),
        child: Center(
          child: Icon(
            Icons.landscape_outlined,
            size: 48,
            color: _UserProfileScreenState._primaryColor.withOpacity(0.5),
          ),
        ),
      ),
    );
  }

  Widget _buildLivestockCarousel(
    bool isDark,
    Color borderColor,
    Color textColor,
    Color secondaryTextColor,
  ) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border.all(color: borderColor, width: 1),
        color: _accentColor.withOpacity(0.08),
      ),
      child: Stack(
        children: [
          // Icône et gradient de fond
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    _UserProfileScreenState._accentColor.withOpacity(0.1),
                    _UserProfileScreenState._accentColor.withOpacity(0.05),
                  ],
                ),
                borderRadius: const BorderRadius.all(Radius.circular(12)),
              ),
              child: Center(
                child: Icon(
                  Icons.pets_outlined,
                  size: 40,
                  color: _accentColor.withOpacity(0.6),
                ),
              ),
            ),
          ),
          
          // Contenu
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mes Élevages',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _accentColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Gérez votre bétail',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w300,
                        color: _accentColor.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}