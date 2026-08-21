import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

// ─────────────────────────────────────────────────────────────────────────────
// MODÈLES
// ─────────────────────────────────────────────────────────────────────────────
class _UnitOption {
  final String value;
  final String label;
  final String emoji;
  const _UnitOption(this.value, this.label, this.emoji);
}

class _CategoryOption {
  final String value;
  final String emoji;
  const _CategoryOption(this.value, this.emoji);
}

// ─────────────────────────────────────────────────────────────────────────────
// CREATE SALE SCREEN — Minimaliste & épuré
// ─────────────────────────────────────────────────────────────────────────────
class CreateSaleScreen extends StatefulWidget {
  final Map<String, dynamic>? sale;
  final int? saleId;

  const CreateSaleScreen({super.key, this.sale, this.saleId});

  @override
  State<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _productNameCtrl = TextEditingController();
  final _quantityCtrl = TextEditingController();
  final _pricePerUnitCtrl = TextEditingController();
  final _deliveryLocationCtrl = TextEditingController();
  final _contactCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();
  final _customUnitCtrl = TextEditingController();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  final ImagePicker _imagePicker = ImagePicker();
  final List<XFile> _additionalImages = [];

  String _selectedCurrency = 'CFA';
  String _selectedCategory = 'Cultures';
  String _selectedUnit = 'kg';
  bool _useCustomUnit = false;
  bool _isLoading = false;
  int _tabIndex = 0;

  late AnimationController _fadeCtrl;
  late Animation<double> _fadeAnim;

  late SharedPreferences _prefs;
  bool _isDraftLoaded = false;
  String _draftKey = 'sale_draft';

  // ── PALETTE ────────────────────────────────────────────────────────────────
  static const Color _green = Color(0xFF2B5E2B);
  static const Color _greenLight = Color(0xFFF0F7F0);
  static const Color _greenBorder = Color(0xFF8AB88A);

  // ── DONNÉES ────────────────────────────────────────────────────────────────
  static const List<_UnitOption> _units = [
    _UnitOption('kg', 'kg', '⚖️'),
    _UnitOption('g', 'g', '⚖️'),
    _UnitOption('L', 'L', '🫙'),
    _UnitOption('pièce', 'pc', '🐑'),
    _UnitOption('sac', 'sac', '🎒'),
    _UnitOption('botte', 'botte', '🌿'),
    _UnitOption('autre', 'autre', '✏️'),
  ];

  static const List<_CategoryOption> _categories = [
    _CategoryOption('Cultures', '🌾'),
    _CategoryOption('Bétail', '🐄'),
    _CategoryOption('Légumes', '🥬'),
    _CategoryOption('Fruits', '🍋'),
    _CategoryOption('Autre', '📦'),
  ];

  static const List<String> _currencies = ['CFA', 'EUR', 'USD'];

  // ── INIT ────────────────────────────────────────────────────────────────────
  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fadeAnim = CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut);
    _fadeCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      _prefs = await SharedPreferences.getInstance();
      _draftKey = widget.saleId != null
          ? 'sale_draft_${widget.saleId}'
          : 'sale_draft_new';

      if (!mounted) return;
      try {
        if (widget.sale != null) {
          setState(() {
            _loadFromSale(widget.sale!);
            _isDraftLoaded = true;
          });
          return;
        }
        if (widget.saleId != null) {
          final saleData = await ApiService.getSale(widget.saleId!);
          if (mounted) {
            setState(() {
              _loadFromSale(saleData);
              _isDraftLoaded = true;
            });
          }
          return;
        }
        setState(() {
          _loadDraft();
          _isDraftLoaded = true;
        });
      } catch (e) {
        if (mounted) {
          setState(() {
            _loadDraft();
            _isDraftLoaded = true;
          });
        }
      }
    });
  }

  void _loadFromSale(Map<String, dynamic> s) {
    _productNameCtrl.text = s['product_name'] ?? '';
    _quantityCtrl.text = s['quantity']?.toString() ?? '';
    _pricePerUnitCtrl.text = s['price_per_unit']?.toString() ?? '';
    _deliveryLocationCtrl.text = s['delivery_location'] ?? '';
    _contactCtrl.text = s['contact'] ?? '';
    _descriptionCtrl.text = s['description'] ?? '';
    _selectedCurrency = s['currency'] ?? _selectedCurrency;
    _selectedCategory = s['category'] ?? _selectedCategory;

    final savedUnit = s['unit'] as String?;
    if (savedUnit != null) {
      final match = _units.any((u) => u.value == savedUnit);
      if (match) {
        _selectedUnit = savedUnit;
      } else {
        _selectedUnit = 'autre';
        _useCustomUnit = true;
        _customUnitCtrl.text = savedUnit;
      }
    }
  }

  void _loadDraft() {
    final draft = _prefs.getString(_draftKey);
    if (draft == null) return;
    try {
      final data = jsonDecode(draft) as Map<String, dynamic>;
      _productNameCtrl.text = data['productName'] ?? '';
      _quantityCtrl.text = data['quantity'] ?? '';
      _pricePerUnitCtrl.text = data['pricePerUnit'] ?? '';
      _deliveryLocationCtrl.text = data['deliveryLocation'] ?? '';
      _contactCtrl.text = data['contact'] ?? '';
      _descriptionCtrl.text = data['description'] ?? '';
      _selectedCurrency = data['currency'] ?? _selectedCurrency;
      _selectedCategory = data['category'] ?? _selectedCategory;
      _selectedUnit = data['unit'] ?? _selectedUnit;
      _useCustomUnit = data['useCustomUnit'] ?? false;
      _customUnitCtrl.text = data['customUnit'] ?? '';
    } catch (_) {}
  }

  Future<void> _saveDraft() async {
    if (!_isDraftLoaded) return;
    await _prefs.setString(
      _draftKey,
      jsonEncode({
        'productName': _productNameCtrl.text,
        'quantity': _quantityCtrl.text,
        'pricePerUnit': _pricePerUnitCtrl.text,
        'deliveryLocation': _deliveryLocationCtrl.text,
        'contact': _contactCtrl.text,
        'description': _descriptionCtrl.text,
        'currency': _selectedCurrency,
        'category': _selectedCategory,
        'unit': _selectedUnit,
        'useCustomUnit': _useCustomUnit,
        'customUnit': _customUnitCtrl.text,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
      }),
    );
  }

  Future<void> _clearDraft() async => _prefs.remove(_draftKey);

  @override
  void dispose() {
    _fadeCtrl.dispose();
    for (final c in [
      _productNameCtrl,
      _quantityCtrl,
      _pricePerUnitCtrl,
      _deliveryLocationCtrl,
      _contactCtrl,
      _descriptionCtrl,
      _customUnitCtrl,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  String get _effectiveUnit =>
      _useCustomUnit ? _customUnitCtrl.text.trim() : _selectedUnit;

  double get _totalPrice {
    final qty = double.tryParse(_quantityCtrl.text) ?? 0;
    final price = double.tryParse(_pricePerUnitCtrl.text) ?? 0;
    return qty * price;
  }

  bool get _isFormValid =>
      _productNameCtrl.text.isNotEmpty &&
      _quantityCtrl.text.isNotEmpty &&
      _pricePerUnitCtrl.text.isNotEmpty &&
      _deliveryLocationCtrl.text.isNotEmpty &&
      _contactCtrl.text.isNotEmpty;

  // ── ACTIONS ─────────────────────────────────────────────────────────────────
  Future<void> _pickMainImage() async {
    final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery, imageQuality: 85, maxWidth: 1024);
    if (image == null) return;
    if (kIsWeb) {
      final bytes = await image.readAsBytes();
      setState(() {
        _selectedImage = image;
        _selectedImageBytes = bytes;
      });
    } else {
      setState(() => _selectedImage = image);
    }
    _saveDraft();
  }

  Future<void> _pickAdditionalImages() async {
    final remaining = 5 - _additionalImages.length;
    if (remaining <= 0) return;
    final picked = await _imagePicker.pickMultiImage(imageQuality: 85);
    if (picked.isNotEmpty) {
      setState(() => _additionalImages.addAll(picked.take(remaining)));
      _saveDraft();
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_useCustomUnit && _customUnitCtrl.text.trim().isEmpty) {
      _snack('Veuillez entrer votre unité', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    try {
      final saleData = <String, dynamic>{
        'product_name': _productNameCtrl.text.trim(),
        'quantity': double.parse(_quantityCtrl.text),
        'unit': _effectiveUnit,
        'price_per_unit': double.parse(_pricePerUnitCtrl.text),
        'currency': _selectedCurrency,
        'delivery_location': _deliveryLocationCtrl.text.trim(),
        'contact': _contactCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'category': _selectedCategory,
      };

      if (_selectedImage != null) {
        final url = await ApiService.uploadImageToCloudinary(_selectedImage!);
        if (url != null) saleData['image_url'] = url;
      } else if (widget.sale?['image_url'] != null) {
        saleData['image_url'] = widget.sale!['image_url'];
      }

      final List<String> additionalUrls = [];
      for (final img in _additionalImages) {
        final url = await ApiService.uploadImageToCloudinary(img);
        if (url != null) additionalUrls.add(url);
      }
      if (additionalUrls.isNotEmpty) saleData['additional_images'] = additionalUrls;

      if (widget.saleId != null) {
        await ApiService.updateSale(widget.saleId!, saleData);
        _snack('Annonce modifiée');
      } else {
        await ApiService.createSale(saleData);
        _snack('Annonce publiée');
      }
      await _clearDraft();
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) _snack('Erreur: ${e.toString()}', isError: true);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _snack(String msg, {bool isError = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg, style: const TextStyle(color: Colors.white)),
        backgroundColor: isError ? Colors.red[700] : _green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  // ── BUILD ────────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (!_isDraftLoaded) {
      return Scaffold(
        backgroundColor: AppColors.getBgColor(isDark),
        body: const Center(
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            color: _green,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.getBgColor(isDark),
      body: FadeTransition(
        opacity: _fadeAnim,
        child: Column(
          children: [
            _buildHeader(isDark),
            _buildTabs(isDark),
            Expanded(
              child: _tabIndex == 0
                  ? _buildEditTab(isDark)
                  : _buildPreviewTab(isDark),
            ),
          ],
        ),
      ),
    );
  }

  // ── HEADER ───────────────────────────────────────────────────────────────────
  Widget _buildHeader(bool isDark) {
    final bg = AppColors.getCardBgColor(isDark);
    final textPrimary = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    final textSec = isDark ? const Color(0xFF888888) : const Color(0xFF9A9A9A);

    return Container(
      color: bg,
      padding: EdgeInsets.only(
        top: MediaQuery.of(context).padding.top + 12,
        left: 20,
        right: 16,
        bottom: 16,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.saleId != null ? 'Modifier l\'annonce' : 'Nouvelle annonce',
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w500,
                    color: textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Brouillon enregistré automatiquement',
                  style: TextStyle(fontSize: 12, color: textSec),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: isDark
                        ? const Color(0xFF2C2C2C)
                        : const Color(0xFFE8E8E8)),
              ),
              child: Icon(Icons.close,
                  size: 16,
                  color: isDark ? const Color(0xFF888888) : const Color(0xFF888888)),
            ),
          ),
        ],
      ),
    );
  }

  // ── TABS ─────────────────────────────────────────────────────────────────────
  Widget _buildTabs(bool isDark) {
    final bg = isDark ? const Color(0xFF161616) : Colors.white;
    final tabBg = isDark ? const Color(0xFF222222) : const Color(0xFFF4F3F1);

    return Container(
      color: bg,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: tabBg,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.all(3),
        child: Row(
          children: [
            _tabBtn('Édition', 0, isDark),
            _tabBtn('Aperçu', 1, isDark),
          ],
        ),
      ),
    );
  }

  Widget _tabBtn(String label, int index, bool isDark) {
    final isActive = _tabIndex == index;
    final activeBg = isDark ? const Color(0xFF2C2C2C) : Colors.white;
    final activeText = AppColors.getTextColor(isDark);
    final inactiveText = AppColors.getSecondaryTextColor(isDark);

    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          decoration: BoxDecoration(
            color: isActive ? activeBg : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: isActive
                ? Border.all(
                    color: isDark
                        ? const Color(0xFF3A3A3A)
                        : const Color(0xFFE0E0E0),
                    width: 0.5)
                : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              color: isActive ? activeText : inactiveText,
            ),
          ),
        ),
      ),
    );
  }

  // ── EDIT TAB ─────────────────────────────────────────────────────────────────
  Widget _buildEditTab(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 48),
      child: Form(
        key: _formKey,
        onChanged: _saveDraft,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Photo
            _sectionLabel('Photo', isDark),
            const SizedBox(height: 10),
            _ImagePickerWidget(
              isDark: isDark,
              selectedImage: _selectedImage,
              selectedImageBytes: _selectedImageBytes,
              existingUrl: widget.sale?['image_url'],
              onTap: _pickMainImage,
              green: _green,
            ),
            const SizedBox(height: 28),

            // Catégorie
            _sectionLabel('Catégorie', isDark),
            const SizedBox(height: 10),
            _CategoryRow(
              categories: _categories,
              selected: _selectedCategory,
              isDark: isDark,
              green: _green,
              greenLight: _greenLight,
              onChanged: (v) => setState(() {
                _selectedCategory = v;
                _saveDraft();
              }),
            ),
            const SizedBox(height: 28),

            // Produit
            _sectionLabel('Produit', isDark),
            const SizedBox(height: 10),
            _cleanField(
              controller: _productNameCtrl,
              hint: 'ex: Tomates cerises fermières',
              isDark: isDark,
              validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null,
            ),
            _hint('Soyez spécifique pour attirer plus d\'acheteurs'),
            const SizedBox(height: 28),

            // Quantité & Unité
            _sectionLabel('Quantité & Unité', isDark),
            const SizedBox(height: 10),
            _UnitRow(
              units: _units,
              selected: _selectedUnit,
              useCustom: _useCustomUnit,
              isDark: isDark,
              green: _green,
              greenLight: _greenLight,
              onChanged: (u) => setState(() {
                _selectedUnit = u.value;
                _useCustomUnit = u.value == 'autre';
                _saveDraft();
              }),
            ),
            if (_useCustomUnit) ...[
              const SizedBox(height: 10),
              _cleanField(
                controller: _customUnitCtrl,
                hint: 'ex: tête, filet...',
                isDark: isDark,
                validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null,
              ),
            ],
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: _cleanField(
                    controller: _quantityCtrl,
                    hint: '0',
                    isDark: isDark,
                    keyboardType: TextInputType.number,
                    suffix: _useCustomUnit
                        ? (_customUnitCtrl.text.isNotEmpty
                            ? _customUnitCtrl.text
                            : 'unité')
                        : _selectedUnit,
                    validator: (v) {
                      if (v?.isEmpty ?? true) return 'Requis';
                      if (double.tryParse(v!) == null) return 'Nombre invalide';
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: _CurrencyDropdown(
                    currencies: _currencies,
                    selected: _selectedCurrency,
                    isDark: isDark,
                    green: _green,
                    onChanged: (v) => setState(() {
                      _selectedCurrency = v;
                      _saveDraft();
                    }),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Prix
            _sectionLabel('Prix unitaire', isDark),
            const SizedBox(height: 10),
            _cleanField(
              controller: _pricePerUnitCtrl,
              hint: '0',
              isDark: isDark,
              keyboardType: TextInputType.number,
              prefix: _selectedCurrency,
              validator: (v) {
                if (v?.isEmpty ?? true) return 'Requis';
                if (double.tryParse(v!) == null) return 'Nombre invalide';
                return null;
              },
            ),
            _hint('Vérifiez les prix du marché avant de publier'),
            if (_isFormValid) ...[
              const SizedBox(height: 10),
              _TotalCard(
                total: _totalPrice,
                currency: _selectedCurrency,
                isDark: isDark,
                green: _green,
                greenLight: _greenLight,
              ),
            ],
            const SizedBox(height: 28),

            // Livraison
            _sectionLabel('Livraison', isDark),
            const SizedBox(height: 10),
            _cleanField(
              controller: _deliveryLocationCtrl,
              hint: 'ex: Dakar, Médina',
              isDark: isDark,
              validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null,
            ),
            _hint('Précisez la ville et le quartier'),
            const SizedBox(height: 28),

            // Contact
            _sectionLabel('Contact', isDark),
            const SizedBox(height: 10),
            _cleanField(
              controller: _contactCtrl,
              hint: '+221 77 123 45 67',
              isDark: isDark,
              keyboardType: TextInputType.phone,
              validator: (v) => (v?.isEmpty ?? true) ? 'Requis' : null,
            ),
            const SizedBox(height: 28),

            // Description
            _sectionLabel('Description', isDark),
            const SizedBox(height: 10),
            _cleanField(
              controller: _descriptionCtrl,
              hint: 'Qualité, origine, particularités...',
              isDark: isDark,
              maxLines: 3,
            ),
            const SizedBox(height: 28),

            // Photos supp
            _sectionLabel('Photos supplémentaires (max 5)', isDark),
            const SizedBox(height: 10),
            _AdditionalImagesRow(
              images: _additionalImages,
              isDark: isDark,
              green: _green,
              border: isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8),
              surface: isDark ? const Color(0xFF1E1E1E) : Colors.white,
              onAdd: _pickAdditionalImages,
              onRemove: (i) => setState(() {
                _additionalImages.removeAt(i);
                _saveDraft();
              }),
            ),
            const SizedBox(height: 40),

            // Submit
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _green,
                  disabledBackgroundColor: _green.withOpacity(0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                child: _isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 1.5, color: Colors.white),
                      )
                    : Text(
                        widget.saleId != null ? 'Enregistrer' : 'Publier',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                          letterSpacing: 0.3,
                        ),
                      ),
              ),
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 44,
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10))),
                child: Text(
                  'Annuler',
                  style: TextStyle(
                    color: isDark
                        ? const Color(0xFF666666)
                        : const Color(0xFF9A9A9A),
                    fontSize: 14,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── PREVIEW TAB ──────────────────────────────────────────────────────────────
  Widget _buildPreviewTab(bool isDark) {
    final textPrimary = isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);
    final textSec = isDark ? const Color(0xFF888888) : const Color(0xFF9A9A9A);
    final cardBg = isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F3F1);
    final border = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8);

    final catEmoji = _categories
        .firstWhere((c) => c.value == _selectedCategory,
            orElse: () => const _CategoryOption('', '📦'))
        .emoji;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Image
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 200,
              width: double.infinity,
              color: cardBg,
              child: _selectedImageBytes != null
                  ? Image.memory(_selectedImageBytes!, fit: BoxFit.cover)
                  : _selectedImage != null && !kIsWeb
                      ? Image.file(File(_selectedImage!.path),
                          fit: BoxFit.cover)
                      : widget.sale?['image_url'] != null
                          ? Image.network(widget.sale!['image_url'],
                              fit: BoxFit.cover)
                          : Center(
                              child: Text('Aucune photo',
                                  style: TextStyle(
                                      color: textSec, fontSize: 13))),
            ),
          ),
          const SizedBox(height: 20),

          // Badge catégorie
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: _greenLight,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              '$catEmoji $_selectedCategory',
              style: TextStyle(
                  color: _green, fontSize: 12, fontWeight: FontWeight.w500),
            ),
          ),
          const SizedBox(height: 10),

          Text(
            _productNameCtrl.text.isEmpty
                ? 'Nom du produit'
                : _productNameCtrl.text,
            style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w500,
                color: textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            '${_quantityCtrl.text.isEmpty ? '0' : _quantityCtrl.text} $_effectiveUnit  ·  $_selectedCurrency',
            style: TextStyle(fontSize: 14, color: textSec),
          ),
          const SizedBox(height: 20),

          // Prix card
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('PRIX UNITAIRE',
                    style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 0.8,
                        color: textSec,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      _pricePerUnitCtrl.text.isEmpty
                          ? '0'
                          : _pricePerUnitCtrl.text,
                      style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w500,
                          color: _green),
                    ),
                    const SizedBox(width: 6),
                    Text(_selectedCurrency,
                        style: TextStyle(fontSize: 14, color: textSec)),
                  ],
                ),
                if (_isFormValid) ...[
                  const SizedBox(height: 12),
                  Divider(color: border, height: 1),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total · ${_quantityCtrl.text} $_effectiveUnit',
                        style: TextStyle(fontSize: 13, color: textSec),
                      ),
                      Text(
                        '${_totalPrice.toStringAsFixed(0)} $_selectedCurrency',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _green),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Infos
          if (_deliveryLocationCtrl.text.isNotEmpty)
            _infoRow(Icons.location_on_outlined,
                _deliveryLocationCtrl.text, border, textPrimary, isDark),
          if (_contactCtrl.text.isNotEmpty)
            _infoRow(Icons.phone_outlined, _contactCtrl.text, border,
                textPrimary, isDark),

          if (_descriptionCtrl.text.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Description',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: textPrimary)),
            const SizedBox(height: 6),
            Text(_descriptionCtrl.text,
                style: TextStyle(
                    fontSize: 13, color: textSec, height: 1.6)),
          ],
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color border, Color textPrimary,
      bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        border: Border.all(color: border, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: _green),
          const SizedBox(width: 12),
          Expanded(
              child:
                  Text(text, style: TextStyle(fontSize: 13, color: textPrimary))),
        ],
      ),
    );
  }

  // ── HELPERS ──────────────────────────────────────────────────────────────────
  Widget _sectionLabel(String label, bool isDark) => Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.8,
          color: AppColors.getSecondaryTextColor(isDark),
        ),
      );

  Widget _hint(String text) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(text,
            style: TextStyle(
                fontSize: 11,
                color: _green.withOpacity(0.7),
                fontStyle: FontStyle.italic)),
      );

  Widget _cleanField({
    required TextEditingController controller,
    required String hint,
    required bool isDark,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
    String? suffix,
    String? prefix,
  }) {
    final surface = AppColors.getCardBgColor(isDark);
    final border = AppColors.getBorderColor(isDark);
    final textColor = AppColors.getTextColor(isDark);
    final hintColor = AppColors.getSecondaryTextColor(isDark);

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      style: TextStyle(
          color: textColor, fontSize: 15, fontWeight: FontWeight.w400),
      validator: validator,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: hintColor, fontSize: 14),
        prefixText: prefix != null ? '$prefix  ' : null,
        prefixStyle:
            TextStyle(color: _green.withOpacity(0.8), fontWeight: FontWeight.w500),
        suffixText: suffix,
        suffixStyle: TextStyle(color: hintColor, fontSize: 13),
        filled: true,
        fillColor: surface,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: border, width: 0.5),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: _green, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: Colors.red[400]!, width: 0.5),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// WIDGETS
// ═════════════════════════════════════════════════════════════════════════════

class _ImagePickerWidget extends StatelessWidget {
  final bool isDark;
  final XFile? selectedImage;
  final Uint8List? selectedImageBytes;
  final String? existingUrl;
  final VoidCallback onTap;
  final Color green;

  const _ImagePickerWidget({
    required this.isDark,
    required this.selectedImage,
    required this.selectedImageBytes,
    required this.existingUrl,
    required this.onTap,
    required this.green,
  });

  @override
  Widget build(BuildContext context) {
    final border = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE0E0E0);
    final surface = isDark ? const Color(0xFF1A1A1A) : const Color(0xFFFAF9F7);
    final textSec = isDark ? const Color(0xFF666666) : const Color(0xFFBBBBBB);

    final hasImage =
        selectedImage != null || selectedImageBytes != null || existingUrl != null;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 140,
        width: double.infinity,
        decoration: BoxDecoration(
          color: surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
              color: border,
              width: hasImage ? 0.5 : 1.5,
              style: hasImage ? BorderStyle.solid : BorderStyle.solid),
        ),
        child: hasImage
            ? ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (selectedImageBytes != null)
                      Image.memory(selectedImageBytes!, fit: BoxFit.cover)
                    else if (selectedImage != null && !kIsWeb)
                      Image.file(File(selectedImage!.path),
                          fit: BoxFit.cover)
                    else if (existingUrl != null)
                      Image.network(existingUrl!, fit: BoxFit.cover),
                    Positioned(
                      bottom: 10,
                      right: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.55),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text('Changer',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.w400)),
                      ),
                    ),
                  ],
                ),
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF0F7F0),
                      border: Border.all(
                          color: green.withOpacity(0.3), width: 0.5),
                    ),
                    child: Icon(Icons.add_photo_alternate_outlined,
                        color: green, size: 18),
                  ),
                  const SizedBox(height: 8),
                  Text('Ajouter une photo',
                      style: TextStyle(
                          color: green,
                          fontSize: 13,
                          fontWeight: FontWeight.w400)),
                  const SizedBox(height: 3),
                  Text('Optionnel  ·  augmente les ventes de 70%',
                      style: TextStyle(color: textSec, fontSize: 11)),
                ],
              ),
      ),
    );
  }
}

class _CategoryRow extends StatelessWidget {
  final List<_CategoryOption> categories;
  final String selected;
  final bool isDark;
  final Color green;
  final Color greenLight;
  final ValueChanged<String> onChanged;

  const _CategoryRow({
    required this.categories,
    required this.selected,
    required this.isDark,
    required this.green,
    required this.greenLight,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border =
        isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8);

    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = categories[i];
          final isSel = cat.value == selected;
          return GestureDetector(
            onTap: () => onChanged(cat.value),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 120),
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isSel
                    ? greenLight
                    : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: isSel ? green : border,
                  width: isSel ? 1.5 : 0.5,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(cat.emoji, style: const TextStyle(fontSize: 13)),
                  const SizedBox(width: 6),
                  Text(
                    cat.value,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight:
                          isSel ? FontWeight.w500 : FontWeight.w400,
                      color: isSel
                          ? green
                          : (isDark
                              ? const Color(0xFF888888)
                              : const Color(0xFF666666)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _UnitRow extends StatelessWidget {
  final List<_UnitOption> units;
  final String selected;
  final bool useCustom;
  final bool isDark;
  final Color green;
  final Color greenLight;
  final ValueChanged<_UnitOption> onChanged;

  const _UnitRow({
    required this.units,
    required this.selected,
    required this.useCustom,
    required this.isDark,
    required this.green,
    required this.greenLight,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final border =
        isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8);

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: units.map((u) {
        final isSel =
            useCustom ? u.value == 'autre' : u.value == selected;
        return GestureDetector(
          onTap: () => onChanged(u),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 120),
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: isSel
                  ? greenLight
                  : (isDark ? const Color(0xFF1E1E1E) : Colors.white),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isSel ? green : border,
                width: isSel ? 1.5 : 0.5,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(u.emoji, style: const TextStyle(fontSize: 12)),
                const SizedBox(width: 5),
                Text(
                  u.label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight:
                        isSel ? FontWeight.w500 : FontWeight.w400,
                    color: isSel
                        ? green
                        : (isDark
                            ? const Color(0xFF888888)
                            : const Color(0xFF666666)),
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _CurrencyDropdown extends StatelessWidget {
  final List<String> currencies;
  final String selected;
  final bool isDark;
  final Color green;
  final ValueChanged<String> onChanged;

  const _CurrencyDropdown({
    required this.currencies,
    required this.selected,
    required this.isDark,
    required this.green,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final border =
        isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8);
    final textColor =
        isDark ? const Color(0xFFF0F0F0) : const Color(0xFF1A1A1A);

    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: surface,
        border: Border.all(color: border, width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selected,
          isExpanded: true,
          dropdownColor: surface,
          style: TextStyle(color: textColor, fontSize: 14),
          icon: Icon(Icons.keyboard_arrow_down_rounded,
              color: green.withOpacity(0.7), size: 18),
          items: currencies
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c,
                        style: TextStyle(color: textColor, fontSize: 14)),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

class _TotalCard extends StatelessWidget {
  final double total;
  final String currency;
  final bool isDark;
  final Color green;
  final Color greenLight;

  const _TotalCard({
    required this.total,
    required this.currency,
    required this.isDark,
    required this.green,
    required this.greenLight,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: greenLight,
        border: Border.all(color: green.withOpacity(0.2), width: 0.5),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text('Total estimé',
              style: TextStyle(
                  fontSize: 13,
                  color: green.withOpacity(0.8))),
          Text(
            '${total.toStringAsFixed(0)} $currency',
            style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w500,
                color: green),
          ),
        ],
      ),
    );
  }
}

class _AdditionalImagesRow extends StatelessWidget {
  final List<XFile> images;
  final bool isDark;
  final Color green;
  final Color border;
  final Color surface;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _AdditionalImagesRow({
    required this.images,
    required this.isDark,
    required this.green,
    required this.border,
    required this.surface,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        ...images.asMap().entries.map((e) {
          final index = e.key;
          final img = e.value;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: border, width: 0.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: kIsWeb
                    ? FutureBuilder<Uint8List>(
                        future: img.readAsBytes(),
                        builder: (_, snap) => snap.hasData
                            ? Image.memory(snap.data!, fit: BoxFit.cover)
                            : Container(color: surface),
                      )
                    : Image.file(File(img.path), fit: BoxFit.cover),
              ),
              Positioned(
                top: -5,
                right: -5,
                child: GestureDetector(
                  onTap: () => onRemove(index),
                  child: Container(
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      color: Colors.red[400],
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.close,
                        color: Colors.white, size: 11),
                  ),
                ),
              ),
            ],
          );
        }),
        if (images.length < 5)
          GestureDetector(
            onTap: onAdd,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: border, width: 0.5, style: BorderStyle.solid),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add, color: green, size: 22),
                  const SizedBox(height: 2),
                  Text(
                    '${5 - images.length}',
                    style: TextStyle(
                        color: green,
                        fontSize: 10,
                        fontWeight: FontWeight.w400),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }
}