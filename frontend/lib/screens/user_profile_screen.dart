import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/screens/farm_tab/farm_tab.dart';
import 'package:mbaymi/screens/parcel_screen.dart';
import 'package:mbaymi/screens/edit_livestock_screen.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/widgets/skeleton_loader.dart';

// ─────────────────────────────────────────────────────────────────────────────
// DESIGN TOKENS — Zara-inspired luxury minimalism
// ─────────────────────────────────────────────────────────────────────────────
class _Z {
  // Spacing
  static const double s4 = 4;
  static const double s8 = 8;
  static const double s12 = 12;
  static const double s16 = 16;
  static const double s20 = 20;
  static const double s24 = 24;
  static const double s32 = 32;
  static const double s48 = 48;
  static const double s64 = 64;

  // Typography
  static const String font = 'Georgia'; // Serif for Zara editorial feel

  static TextStyle display(Color c) => TextStyle(
        fontFamily: font,
        fontSize: 26,
        fontWeight: FontWeight.w300,
        letterSpacing: 4,
        color: c,
        height: 1.2,
      );

  static TextStyle heading(Color c) => TextStyle(
        fontFamily: font,
        fontSize: 13,
        fontWeight: FontWeight.w400,
        letterSpacing: 3,
        color: c,
      );

  static TextStyle label(Color c) => TextStyle(
        fontFamily: font,
        fontSize: 10,
        fontWeight: FontWeight.w400,
        letterSpacing: 2.5,
        color: c,
      );

  static TextStyle body(Color c) => TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w300,
        letterSpacing: 0.3,
        color: c,
        height: 1.6,
      );

  static TextStyle stat(Color c) => TextStyle(
        fontFamily: font,
        fontSize: 22,
        fontWeight: FontWeight.w300,
        letterSpacing: 1,
        color: c,
      );
}

// ─────────────────────────────────────────────────────────────────────────────
// SCREEN
// ─────────────────────────────────────────────────────────────────────────────
class UserProfileScreen extends StatefulWidget {
  final int userId;
  final bool isDarkMode;

  const UserProfileScreen({
    super.key,
    required this.userId,
    required this.isDarkMode,
  });

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  Future<Map<String, dynamic>>? _profileFuture;
  Future<List<dynamic>>? _farmsFuture;
  Future<List<dynamic>>? _livestockFuture;
  int _tab = 0;
  final _picker = ImagePicker();

  bool get _isOwn =>
      widget.userId == (AuthService.currentSession?.userId ?? 0);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void didUpdateWidget(UserProfileScreen old) {
    super.didUpdateWidget(old);
    if (old.userId != widget.userId) _load();
  }

  void _load() {
    final vid = AuthService.currentSession?.userId ?? 0;
    _profileFuture = ApiService.getUserProfile(widget.userId,
        viewerId: vid > 0 ? vid : null);
    _farmsFuture = ApiService.getPublicUserFarms(widget.userId);
    _livestockFuture = ApiService.getUserLivestock(widget.userId);
    setState(() {});
  }

  // ── Helpers ─────────────────────────────────────────────────────────────
  Color _bg(bool dark) => AppColors.getBgColor(dark);
  Color _text(bool dark) => AppColors.getTextColor(dark);
  Color _sub(bool dark) => AppColors.getSecondaryTextColor(dark);
  Color _border(bool dark) => AppColors.getBorderColor(dark);
  Color _card(bool dark) => AppColors.getCardBgColor(dark);

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg,
          style: const TextStyle(
              letterSpacing: 0.5,
              fontSize: 12,
              color: Colors.white)),
      backgroundColor: error ? AppColors.error : Colors.black87,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(2)),
      duration: Duration(milliseconds: error ? 2500 : 1200),
    ));
  }

  // ── Actions ──────────────────────────────────────────────────────────────
  Future<void> _uploadAvatar() async {
    final file = await _picker.pickImage(
        source: ImageSource.gallery, imageQuality: 80, maxWidth: 1024);
    if (file == null) return;
    _snack('Téléchargement...');
    try {
      final url = await ApiService.uploadImageToCloudinary(file);
      if (url == null) throw Exception('Upload échoué');
      await ApiService.updateUserProfile(
          userId: widget.userId, profileImage: url);
      _load();
      _snack('Photo mise à jour');
    } catch (e) {
      _snack('Erreur: $e', error: true);
    }
  }

  Future<void> _updateProfile(
      String name, String email, String phone) async {
    if (name.isEmpty && email.isEmpty && phone.isEmpty) {
      _snack('Aucune modification', error: true);
      return;
    }
    try {
      await ApiService.updateUserProfile(
        userId: widget.userId,
        name: name.isNotEmpty ? name : null,
        email: email.isNotEmpty ? email : null,
        phone: phone.isNotEmpty ? phone : null,
      );
      _load();
      _snack('Profil mis à jour');
    } catch (e) {
      _snack('Erreur: $e', error: true);
    }
  }

  Future<void> _changePassword(
      String current, String next, String confirm) async {
    if (current.isEmpty || next.isEmpty) {
      _snack('Champs requis', error: true);
      return;
    }
    if (next != confirm) {
      _snack('Mots de passe différents', error: true);
      return;
    }
    if (next.length < 6) {
      _snack('Minimum 6 caractères', error: true);
      return;
    }
    try {
      await ApiService.changePassword(
          currentPassword: current, newPassword: next);
      _snack('Mot de passe modifié');
    } catch (e) {
      _snack('Erreur: $e', error: true);
    }
  }

  // ── Dialogs ──────────────────────────────────────────────────────────────
  void _showEditDialog(String name, String email, String phone) {
    final dark = widget.isDarkMode;
    final nameC = TextEditingController(text: name);
    final emailC = TextEditingController(text: email);
    final phoneC = TextEditingController(text: phone);

    showDialog(
      context: context,
      builder: (_) => _ZaraDialog(
        isDark: dark,
        title: 'MODIFIER LE PROFIL',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ZaraField(controller: nameC, label: 'NOM', dark: dark),
            const SizedBox(height: _Z.s16),
            _ZaraField(
                controller: emailC,
                label: 'EMAIL',
                dark: dark,
                type: TextInputType.emailAddress),
            const SizedBox(height: _Z.s16),
            _ZaraField(
                controller: phoneC,
                label: 'TÉLÉPHONE',
                dark: dark,
                type: TextInputType.phone),
            const SizedBox(height: _Z.s24),
            GestureDetector(
              onTap: () {
                Navigator.pop(context);
                _showPasswordDialog();
              },
              child: Row(
                children: [
                  const SizedBox(
                    width: 20,
                    height: 1,
                  ),
                  Expanded(
                      child: Container(height: 0.5, color: Colors.red.shade300)),
                  const SizedBox(width: _Z.s8),
                  Text('CHANGER MOT DE PASSE',
                      style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          color: Colors.red.shade400)),
                  const SizedBox(width: _Z.s8),
                  Expanded(
                      child: Container(height: 0.5, color: Colors.red.shade300)),
                ],
              ),
            ),
          ],
        ),
        onConfirm: () {
          _updateProfile(
              nameC.text.trim(), emailC.text.trim(), phoneC.text.trim());
          nameC.dispose();
          emailC.dispose();
          phoneC.dispose();
        },
        onCancel: () {
          nameC.dispose();
          emailC.dispose();
          phoneC.dispose();
        },
      ),
    );
  }

  void _showPasswordDialog() {
    final dark = widget.isDarkMode;
    final curC = TextEditingController();
    final newC = TextEditingController();
    final conC = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => _ZaraDialog(
        isDark: dark,
        title: 'MOT DE PASSE',
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _ZaraField(
                controller: curC, label: 'ACTUEL', dark: dark, obscure: true),
            const SizedBox(height: _Z.s16),
            _ZaraField(
                controller: newC, label: 'NOUVEAU', dark: dark, obscure: true),
            const SizedBox(height: _Z.s16),
            _ZaraField(
                controller: conC, label: 'CONFIRMER', dark: dark, obscure: true),
          ],
        ),
        onConfirm: () {
          _changePassword(curC.text.trim(), newC.text.trim(), conC.text.trim());
          curC.dispose();
          newC.dispose();
          conC.dispose();
        },
        onCancel: () {
          curC.dispose();
          newC.dispose();
          conC.dispose();
        },
        confirmLabel: 'MODIFIER',
        confirmColor: Colors.red.shade700,
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (_) => _ZaraDialog(
        isDark: widget.isDarkMode,
        title: 'SE DÉCONNECTER',
        content: Text('Voulez-vous vraiment vous déconnecter ?',
            style: _Z.body(_sub(widget.isDarkMode))),
        confirmLabel: 'DÉCONNECTER',
        confirmColor: Colors.red.shade700,
        onConfirm: () async {
          await ApiService.logout();
          if (mounted) {
            Navigator.of(context).pushNamedAndRemoveUntil('/login', (_) => false);
          }
        },
      ),
    );
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    super.build(context);
    final dark = widget.isDarkMode;

    return Scaffold(
      backgroundColor: _bg(dark),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text('PROFIL', style: _Z.label(_text(dark))),
        iconTheme: IconThemeData(color: _text(dark)),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: _Z.s16),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                _showLogoutDialog();
              },
              child: Text('SORTIR',
                  style: _Z.label(_sub(dark))),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => _load(),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _profileFuture!,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return SkeletonPageLoader(isDarkMode: dark, cardCount: 4);
            }
            if (snap.hasError) {
              return Center(
                  child: Text('Erreur',
                      style: _Z.body(_sub(dark))));
            }

            final p = snap.data!;
            final name = p['name'] ?? 'Utilisateur';
            final email = p['email'] ?? '';
            final phone = p['phone'] ?? '';
            final avatar = p['profile_image'] as String?;
            final followers = p['total_followers'] ?? 0;
            final posts = p['total_posts'] ?? 0;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Hero header ───────────────────────────────────────
                  _buildHero(dark, name, email, avatar, followers, posts),

                  // ── Quick action ──────────────────────────────────────
                  if (_isOwn)
                    Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: _Z.s24, vertical: _Z.s8),
                      child: _ZaraActionTile(
                        label: 'CRÉER UN POST',
                        icon: Icons.add,
                        dark: dark,
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => FarmTab(userId: widget.userId))),
                      ),
                    ),

                  const SizedBox(height: _Z.s32),

                  // ── Section title ─────────────────────────────────────
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: _Z.s24),
                    child: Text('MES RESSOURCES', style: _Z.label(_sub(dark))),
                  ),
                  const SizedBox(height: _Z.s16),

                  // ── Tab bar ───────────────────────────────────────────
                  _buildTabs(dark),

                  // ── Tab content ───────────────────────────────────────
                  Padding(
                    padding: const EdgeInsets.all(_Z.s24),
                    child: _tab == 0
                        ? _buildFarms(dark)
                        : _buildLivestock(dark),
                  ),

                  const SizedBox(height: _Z.s64),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Hero ─────────────────────────────────────────────────────────────────
  Widget _buildHero(bool dark, String name, String email, String? avatar,
      int followers, int posts) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 64,
        bottom: _Z.s32,
        left: _Z.s24,
        right: _Z.s24,
      ),
      decoration: BoxDecoration(
        border: Border(
            bottom: BorderSide(color: _border(dark), width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Avatar row
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: _isOwn
                    ? () {
                        HapticFeedback.lightImpact();
                        _uploadAvatar();
                      }
                    : null,
                child: Stack(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: _border(dark), width: 1),
                      ),
                      child: ClipOval(
                        child: avatar != null && avatar.isNotEmpty
                            ? Image.network(avatar,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) =>
                                    _defaultAvatar(name, dark))
                            : _defaultAvatar(name, dark),
                      ),
                    ),
                    if (_isOwn)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _text(dark),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.add,
                              size: 12,
                              color: _bg(dark)),
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              // Stats
              _buildStat(followers.toString(), 'ABONNÉS', dark),
              const SizedBox(width: _Z.s32),
              _buildStat(posts.toString(), 'POSTS', dark),
            ],
          ),

          const SizedBox(height: _Z.s20),

          // Name
          GestureDetector(
            onTap: _isOwn
                ? () {
                    HapticFeedback.lightImpact();
                    _showEditDialog(name, email, '');
                  }
                : null,
            child: Row(
              children: [
                Text(name.toUpperCase(), style: _Z.heading(_text(dark))),
                if (_isOwn) ...[
                  const SizedBox(width: _Z.s8),
                  Icon(Icons.edit, size: 12, color: _sub(dark)),
                ],
              ],
            ),
          ),
          const SizedBox(height: _Z.s4),
          Text(email, style: _Z.body(_sub(dark))),
        ],
      ),
    );
  }

  Widget _buildStat(String value, String label, bool dark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(value, style: _Z.stat(_text(dark))),
        const SizedBox(height: 2),
        Text(label, style: _Z.label(_sub(dark))),
      ],
    );
  }

  Widget _defaultAvatar(String name, bool dark) {
    return Container(
      color: dark ? Colors.grey.shade800 : Colors.grey.shade200,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
              fontFamily: _Z.font,
              fontSize: 28,
              fontWeight: FontWeight.w300,
              color: _text(dark)),
        ),
      ),
    );
  }

  // ── Tabs ──────────────────────────────────────────────────────────────────
  Widget _buildTabs(bool dark) {
    const tabs = ['FERMES', 'BÉTAIL'];
    final icons = [Icons.landscape_outlined, Icons.pets_outlined];

    return Container(
      decoration: BoxDecoration(
          border: Border(
        top: BorderSide(color: _border(dark), width: 0.5),
        bottom: BorderSide(color: _border(dark), width: 0.5),
      )),
      child: Row(
        children: List.generate(
          tabs.length,
          (i) => Expanded(
            child: GestureDetector(
              onTap: () {
                HapticFeedback.selectionClick();
                setState(() => _tab = i);
              },
              child: Container(
                padding:
                    const EdgeInsets.symmetric(vertical: _Z.s16),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: _tab == i
                          ? _text(dark)
                          : Colors.transparent,
                      width: 1.5,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(icons[i],
                        size: 14,
                        color: _tab == i ? _text(dark) : _sub(dark)),
                    const SizedBox(width: _Z.s8),
                    Text(tabs[i],
                        style: TextStyle(
                          fontSize: 10,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w400,
                          color: _tab == i ? _text(dark) : _sub(dark),
                        )),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Farms ─────────────────────────────────────────────────────────────────
  Widget _buildFarms(bool dark) {
    return FutureBuilder<List<dynamic>>(
      future: _farmsFuture!,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SkeletonListLoader(
              itemCount: 3, isDarkMode: dark, itemHeight: 80);
        }
        final farms = snap.data ?? [];
        if (farms.isEmpty) return _empty('Aucune ferme', dark);

        return Column(
          children: farms.map((f) {
            final farm = f as Map<String, dynamic>;
            final id = farm['id'] as int?;
            return _ZaraResourceTile(
              title: farm['name'] ?? 'Ferme',
              subtitle: farm['location'] ?? '',
              image: farm['image_url'] as String?,
              dark: dark,
              onTap: id == null
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => ParcelScreen(
                                farmId: id,
                                userId: widget.userId,
                                farmOwnerId: widget.userId,
                                readOnly: false,
                              ))),
            );
          }).toList(),
        );
      },
    );
  }

  // ── Livestock ─────────────────────────────────────────────────────────────
  Widget _buildLivestock(bool dark) {
    return FutureBuilder<List<dynamic>>(
      future: _livestockFuture!,
      builder: (_, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return SkeletonListLoader(
              itemCount: 3, isDarkMode: dark, itemHeight: 80);
        }
        final animals = snap.data ?? [];
        if (animals.isEmpty) return _empty('Aucun bétail', dark);

        return Column(
          children: animals.map((a) {
            final animal = a as Map<String, dynamic>;
            final id = animal['id'] as int?;
            final qty = animal['quantity'] as int? ?? 1;
            final photo = animal['image_url'] ??
                (animal['photos'] is List &&
                        (animal['photos'] as List).isNotEmpty
                    ? (animal['photos'] as List).first
                    : null);
            return _ZaraResourceTile(
              title: animal['animal_type'] ?? 'Animal',
              subtitle: animal['breed'] ?? '',
              badge: 'x$qty',
              image: photo as String?,
              dark: dark,
              onTap: id == null
                  ? null
                  : () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => EditLivestockScreen(
                              livestockId: id, livestock: animal))),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _empty(String msg, bool dark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: _Z.s48),
      child: Center(
          child:
              Text(msg.toUpperCase(), style: _Z.label(_sub(dark)))),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// COMPONENTS
// ─────────────────────────────────────────────────────────────────────────────

/// Zara-style resource tile (Farm / Livestock)
class _ZaraResourceTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String? image;
  final String? badge;
  final bool dark;
  final VoidCallback? onTap;

  const _ZaraResourceTile({
    required this.title,
    required this.subtitle,
    required this.dark,
    this.image,
    this.badge,
    this.onTap,
  });

  Color get _text => AppColors.getTextColor(dark);
  Color get _sub => AppColors.getSecondaryTextColor(dark);
  Color get _border => AppColors.getBorderColor(dark);

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap?.call();
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: _Z.s12),
        padding: const EdgeInsets.all(_Z.s16),
        decoration: BoxDecoration(
          border: Border.all(color: _border, width: 0.5),
        ),
        child: Row(
          children: [
            // Image
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                  border: Border.all(color: _border, width: 0.5)),
              child: image != null && image!.isNotEmpty
                  ? Image.network(image!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Icon(Icons.image_not_supported,
                          size: 18, color: _sub))
                  : Icon(Icons.landscape_outlined,
                      size: 18, color: _sub),
            ),
            const SizedBox(width: _Z.s16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title.toUpperCase(),
                      style: TextStyle(
                          fontSize: 11,
                          letterSpacing: 2,
                          fontWeight: FontWeight.w400,
                          color: _text),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  if (subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(subtitle,
                        style: TextStyle(
                            fontSize: 11,
                            letterSpacing: 0.3,
                            color: _sub),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                  ],
                ],
              ),
            ),
            if (badge != null) ...[
              const SizedBox(width: _Z.s12),
              Text(badge!,
                  style: TextStyle(
                      fontSize: 10, letterSpacing: 1, color: _sub)),
            ],
            const SizedBox(width: _Z.s8),
            Icon(Icons.arrow_forward_ios, size: 12, color: _sub),
          ],
        ),
      ),
    );
  }
}

/// Zara-style action tile
class _ZaraActionTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool dark;
  final VoidCallback onTap;

  const _ZaraActionTile({
    required this.label,
    required this.icon,
    required this.dark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppColors.getBorderColor(dark);
    final text = AppColors.getTextColor(dark);

    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
            vertical: _Z.s16, horizontal: _Z.s20),
        decoration: BoxDecoration(
          border: Border.all(color: border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 14, color: text),
            const SizedBox(width: _Z.s12),
            Text(label,
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 2.5,
                    fontWeight: FontWeight.w400,
                    color: text)),
          ],
        ),
      ),
    );
  }
}

/// Zara-style text field
class _ZaraField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final bool dark;
  final TextInputType type;
  final bool obscure;

  const _ZaraField({
    required this.controller,
    required this.label,
    required this.dark,
    this.type = TextInputType.text,
    this.obscure = false,
  });

  @override
  Widget build(BuildContext context) {
    final border = AppColors.getBorderColor(dark);
    final text = AppColors.getTextColor(dark);
    final sub = AppColors.getSecondaryTextColor(dark);

    return TextField(
      controller: controller,
      keyboardType: type,
      obscureText: obscure,
      style: TextStyle(
          fontSize: 13,
          letterSpacing: 0.3,
          color: text,
          fontWeight: FontWeight.w300),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(
            fontSize: 10, letterSpacing: 2, color: sub),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 12, horizontal: 0),
        enabledBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: border, width: 0.5)),
        focusedBorder: UnderlineInputBorder(
            borderSide: BorderSide(color: text, width: 1)),
      ),
    );
  }
}

/// Zara-style dialog — sharp corners, minimal decoration
class _ZaraDialog extends StatelessWidget {
  final bool isDark;
  final String title;
  final Widget content;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final String confirmLabel;
  final Color? confirmColor;

  const _ZaraDialog({
    required this.isDark,
    required this.title,
    required this.content,
    required this.onConfirm,
    this.onCancel,
    this.confirmLabel = 'CONFIRMER',
    this.confirmColor,
  });

  @override
  Widget build(BuildContext context) {
    final bg = AppColors.getBgColor(isDark);
    final text = AppColors.getTextColor(isDark);
    final sub = AppColors.getSecondaryTextColor(isDark);
    final border = AppColors.getBorderColor(isDark);
    final actionColor = confirmColor ?? text;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(_Z.s24),
      child: Container(
        decoration: BoxDecoration(
          color: bg,
          border: Border.all(color: border, width: 0.5),
        ),
        padding: const EdgeInsets.all(_Z.s24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Text(title,
                style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 3,
                    fontWeight: FontWeight.w400,
                    color: text)),
            const SizedBox(height: _Z.s4),
            Container(height: 0.5, color: border),
            const SizedBox(height: _Z.s24),

            // Content
            content,

            const SizedBox(height: _Z.s32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      Navigator.pop(context);
                      onCancel?.call();
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      decoration: BoxDecoration(
                          border:
                              Border.all(color: border, width: 0.5)),
                      child: Center(
                        child: Text('ANNULER',
                            style: TextStyle(
                                fontSize: 10,
                                letterSpacing: 2,
                                color: sub)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: _Z.s12),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.mediumImpact();
                      Navigator.pop(context);
                      onConfirm();
                    },
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(vertical: 14),
                      color: actionColor,
                      child: Center(
                        child: Text(confirmLabel,
                            style: const TextStyle(
                                fontSize: 10,
                                letterSpacing: 2,
                                color: Colors.white)),
                      ),
                    ),
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