import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';

// ═══════════════════════════════════════════════════════════════════════════
// DESIGN TOKENS — palette saison sèche / terracotta
// ═══════════════════════════════════════════════════════════════════════════

abstract class _T {
  // Sand — surfaces chaudes
  static const sand     = Color(0xFFF5EDE0);
  static const sand2    = Color(0xFFEDE0CC);
  static const sand3    = Color(0xFFD9C5A8);
  static const white    = Color(0xFFFDFAF6);

  // Terracotta — brand accent
  static const terra    = Color(0xFFC17A4A);
  static const terra2   = Color(0xFFA0612F);
  static const terra3   = Color(0xFF8B5E3C);

  // Ink — textes
  static const brown    = Color(0xFF5C3D1E);
  static const ink      = Color(0xFF2E1A0E);
  static const ink2     = Color(0xFF6B4A2E);
  static const ink3     = Color(0xFF9C7A5A);

  // Dark surfaces
  static const dkBg     = Color(0xFF1A1008);
  static const dkSurf   = Color(0xFF221608);
  static const dkSurf2  = Color(0xFF2A1E0E);
  static const dkBord   = Color(0xFF3A2A18);
  static const dkBord2  = Color(0xFF4A3828);

  // Semantic
  static const error    = Color(0xFFD96C6C);
  static const ok       = Color(0xFF7BAB5A);

  // Radii
  static const r6  =  6.0;
  static const r8  =  8.0;
  static const r10 = 10.0;
  static const r12 = 12.0;
  static const r14 = 14.0;
  static const r16 = 16.0;
}

// ═══════════════════════════════════════════════════════════════════════════
// ADAPTIVE SCHEME HELPERS
// ═══════════════════════════════════════════════════════════════════════════

extension _Dk on bool {
  Color get bg      => this ? _T.dkBg    : _T.sand;
  Color get surf    => this ? _T.dkSurf  : _T.white;
  Color get surf2   => this ? _T.dkSurf2 : _T.sand2;
  Color get border  => this ? _T.dkBord  : _T.sand3;
  Color get border2 => this ? _T.dkBord2 : _T.sand3;
  Color get textPri => this ? const Color(0xFFFAEDD8) : _T.ink;
  Color get textSec => this ? const Color(0xFFB08A60) : _T.ink2;
  Color get textTer => this ? const Color(0xFF7A5C3A) : _T.ink3;
}

// ═══════════════════════════════════════════════════════════════════════════
// SHARED MICRO-WIDGETS
// ═══════════════════════════════════════════════════════════════════════════

class _Label extends StatelessWidget {
  final String text;
  final bool isDark;
  const _Label(this.text, {required this.isDark});

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: TextStyle(
      fontSize: 9,
      fontWeight: FontWeight.w600,
      letterSpacing: 2.4,
      color: isDark.textTer,
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// MAIN DIALOG
// ═══════════════════════════════════════════════════════════════════════════

class CreateFarmPostDialog extends StatefulWidget {
  final int farmId;
  final String farmName;
  final VoidCallback onPostCreated;
  final int? livestockId;

  const CreateFarmPostDialog({
    super.key,
    required this.farmId,
    required this.farmName,
    required this.onPostCreated,
    this.livestockId,
  });

  @override
  State<CreateFarmPostDialog> createState() => _CreateFarmPostDialogState();
}

class _CreateFarmPostDialogState extends State<CreateFarmPostDialog>
    with SingleTickerProviderStateMixin {

  final _imagePicker   = ImagePicker();
  final _captionCtrl   = TextEditingController();
  final _priceCtrl     = TextEditingController();
  final _captionFocus  = FocusNode();

  String? _imageUrl;
  bool   _loading      = false;
  bool   _uploadingImg = false;
  String _intent       = 'share';
  String _unit         = 'kg';

  late AnimationController _entryCtrl;
  late Animation<double>   _fadeAnim;
  late Animation<Offset>   _slideAnim;

  static const _units = ['kg', 'litre', 'pièce', 'panier', 'sac'];

  @override
  void initState() {
    super.initState();
    _entryCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.03),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entryCtrl, curve: Curves.easeOutCubic));
    _entryCtrl.forward();
  }

  @override
  void dispose() {
    _captionCtrl.dispose();
    _priceCtrl.dispose();
    _captionFocus.dispose();
    _entryCtrl.dispose();
    super.dispose();
  }

  // ── ACTIONS ────────────────────────────────────────────────────────────

  Future<void> _pickImage() async {
    HapticFeedback.lightImpact();
    try {
      final img = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (img == null) return;
      setState(() => _uploadingImg = true);
      final url = await ApiService.uploadImageToCloudinary(img);
      if (url != null) {
        setState(() => _imageUrl = url);
        _snack('Image téléchargée', ok: true);
      } else {
        _snack('Erreur de téléchargement');
      }
    } catch (e) {
      _snack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _uploadingImg = false);
    }
  }

  Future<void> _publish() async {
    if (_imageUrl == null || _captionCtrl.text.trim().isEmpty) {
      _snack('Ajoutez une image et une description');
      return;
    }
    HapticFeedback.mediumImpact();
    setState(() => _loading = true);
    try {
      final uid = AuthService.currentSession?.userId;
      if (uid == null) throw Exception('Utilisateur non authentifié');

      await ApiService.createFarmPost(
        farmId:      widget.farmId,
        userId:      uid,
        imageUrl:    _imageUrl!,
        caption:     _captionCtrl.text.trim(),
        postIntent:  _intent,
        price:       _intent == 'sell' ? double.tryParse(_priceCtrl.text) : null,
        unit:        _unit,
        livestockId: widget.livestockId,
      );

      ApiService.clearCache();
      ApiService.notifyFarmPostCreated();
      _snack('Post publié ✓', ok: true);

      if (mounted) {
        Navigator.pop(context);
        widget.onPostCreated();
      }
    } catch (e) {
      _snack('Erreur : $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, {bool ok = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w500,
        fontSize: 13,
      )),
      backgroundColor: ok ? _T.ok : _T.error,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(_T.r12),
      ),
      margin: const EdgeInsets.all(16),
      duration: const Duration(seconds: 2),
    ));
  }

  // ═══════════════════════════════════════════════════════════════════════
  // BUILD
  // ═══════════════════════════════════════════════════════════════════════

  @override
  Widget build(BuildContext context) {
    final dk = Theme.of(context).brightness == Brightness.dark;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: dk ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: dk.bg,
        appBar: _buildAppBar(dk),
        body: FadeTransition(
          opacity: _fadeAnim,
          child: SlideTransition(
            position: _slideAnim,
            child: GestureDetector(
              onTap: () => FocusScope.of(context).unfocus(),
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
                physics: const BouncingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildFarmChip(dk),
                    const SizedBox(height: 24),
                    _buildImagePicker(dk),
                    const SizedBox(height: 20),
                    _buildCaption(dk),
                    const SizedBox(height: 20),
                    _buildIntentRow(dk),
                    if (_intent == 'sell') ...[
                      const SizedBox(height: 20),
                      _buildPriceRow(dk),
                    ],
                    const SizedBox(height: 32),
                    _buildFooter(dk),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── APP BAR ────────────────────────────────────────────────────────────

  PreferredSizeWidget _buildAppBar(bool dk) => AppBar(
    title: Text(
      'NOUVEAU POST',
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w600,
        letterSpacing: 2.8,
        color: dk.textTer,
      ),
    ),
    centerTitle: true,
    backgroundColor: dk.bg,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
      },
      child: Container(
        margin: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: dk.surf2,
          shape: BoxShape.circle,
          border: Border.all(color: dk.border),
        ),
        child: Icon(Icons.close_rounded, size: 15, color: dk.textSec),
      ),
    ),
    bottom: PreferredSize(
      preferredSize: const Size.fromHeight(1),
      child: Container(height: 1, color: dk.border),
    ),
  );

  // ── FARM CHIP ──────────────────────────────────────────────────────────

  Widget _buildFarmChip(bool dk) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: dk.surf2,
      borderRadius: BorderRadius.circular(_T.r10),
      border: Border.all(color: dk.border),
    ),
    child: Row(children: [
      Container(
        width: 6, height: 6,
        decoration: const BoxDecoration(
          color: _T.terra2,
          shape: BoxShape.circle,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(child: Text(widget.farmName, style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w500,
        color: dk ? const Color(0xFFFAEDD8) : _T.brown,
      ))),
      if (widget.livestockId != null) ...[
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            border: Border.all(color: dk.border),
            borderRadius: BorderRadius.circular(_T.r6),
          ),
          child: Text('BÉTAIL', style: TextStyle(
            fontSize: 7,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.4,
            color: dk.textTer,
          )),
        ),
      ],
    ]),
  );

  // ── IMAGE PICKER ───────────────────────────────────────────────────────

  Widget _buildImagePicker(bool dk) {
    final hasImage = _imageUrl != null;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      _Label('Photo', isDark: dk),
      const SizedBox(height: 10),
      GestureDetector(
        onTap: (_loading || _uploadingImg) ? null : _pickImage,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 220,
          decoration: BoxDecoration(
            color: dk.surf2,
            borderRadius: BorderRadius.circular(_T.r16),
            border: Border.all(
              color: hasImage ? _T.terra.withOpacity(0.50) : dk.border,
              width: hasImage ? 1.5 : 1,
            ),
          ),
          child: hasImage
              ? _ImagePreview(url: _imageUrl!, onRemove: () {
                  HapticFeedback.lightImpact();
                  setState(() => _imageUrl = null);
                })
              : _ImagePlaceholder(loading: _uploadingImg, isDark: dk),
        ),
      ),
    ]);
  }

  // ── CAPTION ────────────────────────────────────────────────────────────

  Widget _buildCaption(bool dk) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Label('Description', isDark: dk),
      const SizedBox(height: 10),
      Container(
        decoration: BoxDecoration(
          color: dk.surf,
          borderRadius: BorderRadius.circular(_T.r14),
          border: Border.all(color: dk.border),
        ),
        child: TextField(
          controller: _captionCtrl,
          focusNode: _captionFocus,
          maxLines: 4,
          style: TextStyle(
            fontSize: 14,
            color: dk.textPri,
            height: 1.55,
          ),
          decoration: InputDecoration(
            hintText: 'Décrivez votre publication…',
            hintStyle: TextStyle(
              fontSize: 13,
              color: dk.textTer,
              fontWeight: FontWeight.w300,
            ),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.all(16),
          ),
        ),
      ),
    ],
  );

  // ── INTENT ROW ─────────────────────────────────────────────────────────

  Widget _buildIntentRow(bool dk) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Label('Type de post', isDark: dk),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(child: _IntentTile(
          icon: Icons.image_outlined,
          title: 'Partager',
          subtitle: 'Montrez votre quotidien',
          active: _intent == 'share',
          isDark: dk,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _intent = 'share');
          },
        )),
        const SizedBox(width: 10),
        Expanded(child: _IntentTile(
          icon: Icons.storefront_outlined,
          title: 'Vendre',
          subtitle: 'Proposez un produit',
          active: _intent == 'sell',
          isDark: dk,
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _intent = 'sell');
          },
        )),
      ]),
    ],
  );

  // ── PRICE ROW ──────────────────────────────────────────────────────────

  Widget _buildPriceRow(bool dk) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      _Label('Prix et unité', isDark: dk),
      const SizedBox(height: 10),
      Row(children: [
        Expanded(flex: 3, child: Container(
          decoration: BoxDecoration(
            color: dk.surf,
            borderRadius: BorderRadius.circular(_T.r14),
            border: Border.all(color: dk.border),
          ),
          child: TextField(
            controller: _priceCtrl,
            keyboardType: TextInputType.number,
            style: TextStyle(fontSize: 14, color: dk.textPri),
            decoration: InputDecoration(
              hintText: '0',
              prefixIcon: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
                child: Text('FCFA', style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: dk.textTer,
                  letterSpacing: 0.5,
                )),
              ),
              prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            ),
          ),
        )),
        const SizedBox(width: 10),
        Expanded(flex: 2, child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: dk.surf,
            borderRadius: BorderRadius.circular(_T.r14),
            border: Border.all(color: dk.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _unit,
              isExpanded: true,
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: dk.textTer, size: 18),
              style: TextStyle(fontSize: 13, color: dk.textPri),
              dropdownColor: dk.surf,
              borderRadius: BorderRadius.circular(_T.r12),
              items: _units
                  .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                  .toList(),
              onChanged: (v) {
                if (v != null) setState(() => _unit = v);
              },
            ),
          ),
        )),
      ]),
    ],
  );

  // ── FOOTER ─────────────────────────────────────────────────────────────

  Widget _buildFooter(bool dk) => Row(children: [
    GestureDetector(
      onTap: _loading ? null : () {
        HapticFeedback.lightImpact();
        Navigator.pop(context);
      },
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_T.r14),
          border: Border.all(color: dk.border2),
        ),
        child: Center(child: Text('Annuler', style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: dk.textTer,
        ))),
      ),
    ),
    const SizedBox(width: 10),
    Expanded(child: GestureDetector(
      onTap: _loading ? null : _publish,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 52,
        decoration: BoxDecoration(
          color: _loading ? dk.surf2 : _T.terra,
          borderRadius: BorderRadius.circular(_T.r14),
        ),
        child: Center(
          child: _loading
              ? const SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white,
                  ))
              : const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.send_rounded, color: Colors.white, size: 15),
                  SizedBox(width: 8),
                  Text('Publier', style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.white,
                  )),
                ]),
        ),
      ),
    )),
  ]);
}

// ═══════════════════════════════════════════════════════════════════════════
// IMAGE PREVIEW
// ═══════════════════════════════════════════════════════════════════════════

class _ImagePreview extends StatelessWidget {
  final String url;
  final VoidCallback onRemove;
  const _ImagePreview({required this.url, required this.onRemove});

  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(_T.r14),
    child: Stack(fit: StackFit.expand, children: [
      Image.network(url, fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Center(
          child: Icon(Icons.broken_image_outlined, color: _T.ink3, size: 36),
        ),
      ),
      Positioned(
        top: 0, left: 0, right: 0, height: 60,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                _T.ink.withOpacity(0.30),
                Colors.transparent,
              ],
            ),
          ),
        ),
      ),
      Positioned(
        top: 10, right: 10,
        child: GestureDetector(
          onTap: onRemove,
          child: Container(
            width: 30, height: 30,
            decoration: BoxDecoration(
              color: _T.ink.withOpacity(0.50),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.close_rounded,
                size: 14, color: Colors.white),
          ),
        ),
      ),
      Positioned(
        bottom: 12, left: 12,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
          decoration: BoxDecoration(
            color: _T.ink.withOpacity(0.45),
            borderRadius: BorderRadius.circular(20),
          ),
          child: const Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.edit_outlined, size: 10, color: Colors.white),
            SizedBox(width: 5),
            Text('Changer', style: TextStyle(
              fontSize: 10,
              color: Colors.white,
              fontWeight: FontWeight.w400,
            )),
          ]),
        ),
      ),
    ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// IMAGE PLACEHOLDER
// ═══════════════════════════════════════════════════════════════════════════

class _ImagePlaceholder extends StatelessWidget {
  final bool loading;
  final bool isDark;
  const _ImagePlaceholder({required this.loading, required this.isDark});

  @override
  Widget build(BuildContext context) => Center(
    child: loading
        ? Column(mainAxisSize: MainAxisSize.min, children: [
            const SizedBox(
              width: 28, height: 28,
              child: CircularProgressIndicator(
                strokeWidth: 2, color: _T.terra,
              ),
            ),
            const SizedBox(height: 12),
            Text('Envoi en cours…', style: TextStyle(
              fontSize: 12,
              color: isDark.textTer,
              fontWeight: FontWeight.w300,
            )),
          ])
        : Column(mainAxisSize: MainAxisSize.min, children: [
            Container(
              width: 56, height: 56,
              decoration: BoxDecoration(
                color: _T.terra.withOpacity(0.08),
                shape: BoxShape.circle,
                border: Border.all(color: _T.terra.withOpacity(0.20)),
              ),
              child: Icon(
                Icons.add_photo_alternate_outlined,
                size: 26,
                color: _T.terra.withOpacity(0.60),
              ),
            ),
            const SizedBox(height: 14),
            Text('Ajouter une photo', style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark.textSec,
            )),
            const SizedBox(height: 4),
            Text('JPG, PNG  ·  max 1024 px', style: TextStyle(
              fontSize: 11,
              color: isDark.textTer,
              fontWeight: FontWeight.w300,
            )),
          ]),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// INTENT TILE
// ═══════════════════════════════════════════════════════════════════════════

class _IntentTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool active;
  final bool isDark;
  final VoidCallback onTap;

  const _IntentTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.active,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) => GestureDetector(
    onTap: onTap,
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 14),
      decoration: BoxDecoration(
        color: active
            ? _T.terra.withOpacity(isDark ? 0.12 : 0.06)
            : isDark.surf,
        borderRadius: BorderRadius.circular(_T.r14),
        border: Border.all(
          color: active ? _T.terra.withOpacity(0.45) : isDark.border,
          width: active ? 1.5 : 1,
        ),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          width: 34, height: 34,
          decoration: BoxDecoration(
            color: active
                ? _T.terra
                : isDark.surf2,
            borderRadius: BorderRadius.circular(_T.r8),
          ),
          child: Icon(icon, size: 16,
              color: active ? Colors.white : isDark.textTer),
        ),
        const SizedBox(height: 10),
        Text(title, style: TextStyle(
          fontSize: 13,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          color: active ? _T.terra2 : isDark.textSec,
          letterSpacing: 0.1,
        )),
        const SizedBox(height: 3),
        Text(subtitle, style: TextStyle(
          fontSize: 10.5,
          color: active
              ? _T.terra.withOpacity(0.70)
              : isDark.textTer,
          fontWeight: FontWeight.w300,
        )),
      ]),
    ),
  );
}