import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';

class CreateSaleScreen extends StatefulWidget {
  final Map<String, dynamic>? sale;
  final int? saleId;

  const CreateSaleScreen({Key? key, this.sale, this.saleId}) : super(key: key);

  @override
  State<CreateSaleScreen> createState() => _CreateSaleScreenState();
}

class _CreateSaleScreenState extends State<CreateSaleScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _productNameCtrl = TextEditingController();
  final TextEditingController _quantityCtrl = TextEditingController();
  final TextEditingController _pricePerUnitCtrl = TextEditingController();
  final TextEditingController _deliveryLocationCtrl = TextEditingController();
  final TextEditingController _contactCtrl = TextEditingController();
  final TextEditingController _descriptionCtrl = TextEditingController();

  XFile? _selectedImage;
  Uint8List? _selectedImageBytes;
  final ImagePicker _imagePicker = ImagePicker();
  List<XFile> _additionalImages = [];

  String _selectedCurrency = 'CFA';
  String _selectedCategory = 'Cultures';
  String _selectedUnit = 'kg';
  bool _isLoading = false;

  final List<String> _currencies = ['CFA', 'EUR', 'USD'];
  final List<String> _categories = ['Cultures', 'Bétail', 'Légumes', 'Fruits', 'Grains'];
  final List<String> _units = ['kg', 'L', 'tonnes', 'pièces', 'sacs', 'cartons', 'boîtes', 'paires'];

  // Couleurs
  static const Color _primaryColor = Color(0xFF8B6B4D);
  static const Color _accentColor = Color(0xFF6B8E23);
  static const Color _bgLight = Color(0xFFFAF8F5);
  static const Color _bgDark = Color(0xFF121212);
  static const Color _cardLight = Colors.white;
  static const Color _cardDark = Color(0xFF1E1E1E);
  static const Color _borderLight = Color(0xFFE8E2D8);
  static const Color _borderDark = Color(0xFF2C2C2C);

  @override
  void initState() {
    super.initState();
    // Si une annonce est fournie, pré-remplir le formulaire pour l'édition
    if (widget.sale != null) {
      final s = widget.sale!;
      _productNameCtrl.text = (s['product_name'] as String?) ?? '';
      _quantityCtrl.text = (s['quantity']?.toString()) ?? '';
      _pricePerUnitCtrl.text = (s['price_per_unit']?.toString()) ?? '';
      _deliveryLocationCtrl.text = (s['delivery_location'] as String?) ?? '';
      _contactCtrl.text = (s['contact'] as String?) ?? '';
      _descriptionCtrl.text = (s['description'] as String?) ?? '';
      _selectedCurrency = (s['currency'] as String?) ?? _selectedCurrency;
      _selectedCategory = (s['category'] as String?) ?? _selectedCategory;
      if ((s['image_url'] as String?) != null) {
        // leave _selectedImage null but we can show existing URL in preview
      }
    }
  }

  @override
  void dispose() {
    _productNameCtrl.dispose();
    _quantityCtrl.dispose();
    _pricePerUnitCtrl.dispose();
    _deliveryLocationCtrl.dispose();
    _contactCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _createOrUpdateSale() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final saleData = {
        'product_name': _productNameCtrl.text.trim(),
        'quantity': double.parse(_quantityCtrl.text),
        'unit': _selectedUnit,
        'price_per_unit': double.parse(_pricePerUnitCtrl.text),
        'currency': _selectedCurrency,
        'delivery_location': _deliveryLocationCtrl.text.trim(),
        'contact': _contactCtrl.text.trim(),
        'description': _descriptionCtrl.text.trim(),
        'category': _selectedCategory,
      };

      // Upload main image
      if (_selectedImage != null) {
        final imageUrl = await ApiService.uploadImageToCloudinary(_selectedImage!);
        if (imageUrl != null) {
          saleData['image_url'] = imageUrl;
        }
      } else if (widget.sale != null && (widget.sale!['image_url'] as String?) != null) {
        saleData['image_url'] = widget.sale!['image_url'];
      }

      // Upload additional images
      List<String> additionalImageUrls = [];
      for (final image in _additionalImages) {
        final imageUrl = await ApiService.uploadImageToCloudinary(image);
        if (imageUrl != null) {
          additionalImageUrls.add(imageUrl);
        }
      }
      if (additionalImageUrls.isNotEmpty) {
        saleData['additional_images'] = additionalImageUrls;
      }

      if (widget.saleId != null) {
        // Edition
        await ApiService.updateSale(widget.saleId!, saleData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Annonce mise à jour avec succès!'),
              backgroundColor: Color(0xFF4A90E2),
            ),
          );
          Navigator.pop(context, true);
        }
      } else {
        // Création
        await ApiService.createSale(saleData);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Annonce créée avec succès!'),
              backgroundColor: Color(0xFF6B8E23),
            ),
          );
          Navigator.pop(context, true);
        }
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
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDarkMode ? _bgDark : _bgLight;
    final cardColor = isDarkMode ? _cardDark : _cardLight;
    final borderColor = isDarkMode ? _borderDark : _borderLight;
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final secondaryTextColor = isDarkMode ? Colors.grey[400] : Colors.grey[700];

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Créer une annonce'),
        backgroundColor: cardColor,
        foregroundColor: textColor,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: 20,
        ),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section: Informations du produit
              _buildSectionTitle('Informations du produit', isDarkMode),
              const SizedBox(height: 16),

                // Image picker preview
                GestureDetector(
                  onTap: () async {
                    final XFile? image = await _imagePicker.pickImage(
                      source: ImageSource.gallery,
                      imageQuality: 80,
                      maxWidth: 1024,
                      maxHeight: 1024,
                    );
                    if (image != null) {
                      if (kIsWeb) {
                        final bytes = await image.readAsBytes();
                        setState(() {
                          _selectedImage = image;
                          _selectedImageBytes = bytes;
                        });
                      } else {
                        setState(() {
                          _selectedImage = image;
                          _selectedImageBytes = null;
                        });
                      }
                    }
                  },
                  child: Container(
                    height: 120,
                    decoration: BoxDecoration(
                      color: isDarkMode ? const Color(0xFF1E1E1E) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: borderColor),
                    ),
                    child: Center(
                      child: () {
                        if (_selectedImageBytes != null) {
                          return Image.memory(_selectedImageBytes!, fit: BoxFit.cover, width: double.infinity);
                        }
                        if (_selectedImage != null && !kIsWeb) {
                          return Image.file(File(_selectedImage!.path), fit: BoxFit.cover, width: double.infinity);
                        }
                        if (widget.sale != null && (widget.sale!['image_url'] as String?) != null) {
                          return Image.network(widget.sale!['image_url'], fit: BoxFit.cover, width: double.infinity);
                        }
                        return Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.photo, color: _accentColor),
                            const SizedBox(height: 6),
                            Text('Ajouter une photo (optionnel)', style: TextStyle(color: secondaryTextColor)),
                          ],
                        );
                      }(),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

              // Photos additionnelles
              _buildSectionTitle('Photos additionnelles', isDarkMode),
              const SizedBox(height: 16),
              
              // Liste des photos additionnelles
              if (_additionalImages.isNotEmpty)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _additionalImages.asMap().entries.map((entry) {
                    final index = entry.key;
                    final image = entry.value;
                    return Stack(
                      children: [
                        Container(
                          width: 100,
                          height: 100,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: borderColor),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: !kIsWeb
                                ? Image.file(File(image.path), fit: BoxFit.cover)
                                : FutureBuilder<Uint8List>(
                                    future: image.readAsBytes(),
                                    builder: (context, snapshot) {
                                      if (snapshot.hasData) {
                                        return Image.memory(snapshot.data!, fit: BoxFit.cover);
                                      }
                                      return const Center(child: CircularProgressIndicator());
                                    },
                                  ),
                          ),
                        ),
                        Positioned(
                          top: -8,
                          right: -8,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _additionalImages.removeAt(index);
                              });
                            },
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.red,
                                shape: BoxShape.circle,
                              ),
                              padding: const EdgeInsets.all(4),
                              child: const Icon(Icons.close, color: Colors.white, size: 16),
                            ),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              const SizedBox(height: 12),
              
              // Bouton ajouter photos
              GestureDetector(
                onTap: () async {
                  final List<XFile> images = await _imagePicker.pickMultiImage(
                    imageQuality: 80,
                    maxWidth: 1024,
                    maxHeight: 1024,
                  );
                  if (images.isNotEmpty) {
                    setState(() {
                      _additionalImages.addAll(images.take(5 - _additionalImages.length));
                    });
                  }
                },
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDarkMode ? _cardDark : _cardLight,
                    border: Border.all(color: borderColor, width: 1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.add_photo_alternate_outlined, color: _accentColor, size: 24),
                      const SizedBox(height: 8),
                      Text(
                        'Ajouter d\'autres photos (max ${5 - _additionalImages.length} restantes)',
                        style: TextStyle(color: secondaryTextColor, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Nom du produit
              _buildTextField(
                controller: _productNameCtrl,
                label: 'Nom du produit',
                hint: 'ex: Tomates fraîches',
                icon: Icons.shopping_bag_outlined,
                isDarkMode: isDarkMode,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Veuillez entrer le nom du produit';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Catégorie
              _buildCategoryDropdown(isDarkMode, cardColor, borderColor, secondaryTextColor),
              const SizedBox(height: 16),

              // Description
              _buildTextField(
                controller: _descriptionCtrl,
                label: 'Description (optionnel)',
                hint: 'Décrivez votre produit...',
                icon: Icons.description_outlined,
                isDarkMode: isDarkMode,
                maxLines: 3,
              ),
              const SizedBox(height: 24),

              // Section: Prix et quantité
              _buildSectionTitle('Prix et quantité', isDarkMode),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: _buildTextField(
                      controller: _quantityCtrl,
                      label: 'Quantité',
                      hint: '0',
                      icon: Icons.numbers,
                      isDarkMode: isDarkMode,
                      keyboardType: TextInputType.number,
                      validator: (value) {
                        if (value?.isEmpty ?? true) {
                          return 'Obligatoire';
                        }
                        if (double.tryParse(value!) == null) {
                          return 'Invalide';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: isDarkMode ? _cardDark : _cardLight,
                        border: Border.all(color: borderColor, width: 1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: DropdownButton<String>(
                          value: _selectedUnit,
                          onChanged: (newUnit) {
                            setState(() => _selectedUnit = newUnit ?? 'kg');
                          },
                          items: _units.map((unit) {
                            return DropdownMenuItem(
                              value: unit,
                              child: Text(unit, style: TextStyle(color: isDarkMode ? Colors.white : Colors.black)),
                            );
                          }).toList(),
                          isExpanded: true,
                          underline: const SizedBox(),
                          dropdownColor: isDarkMode ? _cardDark : _cardLight,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildPricePerUnitField(isDarkMode, cardColor, borderColor),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Prix par unité
              _buildTextField(
                controller: _pricePerUnitCtrl,
                label: 'Prix par unité',
                hint: '0',
                icon: Icons.local_offer_outlined,
                isDarkMode: isDarkMode,
                keyboardType: TextInputType.number,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Veuillez entrer le prix';
                  }
                  if (double.tryParse(value!) == null) {
                    return 'Prix invalide';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),

              // Section: Livraison et contact
              _buildSectionTitle('Livraison et contact', isDarkMode),
              const SizedBox(height: 16),

              // Localisation
              _buildTextField(
                controller: _deliveryLocationCtrl,
                label: 'Lieu de livraison',
                hint: 'ex: Dakar, Kaolack',
                icon: Icons.location_on_outlined,
                isDarkMode: isDarkMode,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Veuillez entrer le lieu';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Contact
              _buildTextField(
                controller: _contactCtrl,
                label: 'Numéro de contact',
                hint: 'ex: +221 77 123 4567',
                icon: Icons.phone_outlined,
                isDarkMode: isDarkMode,
                keyboardType: TextInputType.phone,
                validator: (value) {
                  if (value?.isEmpty ?? true) {
                    return 'Veuillez entrer votre contact';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 32),

              // Bouton de création
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _createOrUpdateSale,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _accentColor,
                    disabledBackgroundColor: Colors.grey,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Text(
                          'Valider',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // Bouton Annuler
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: borderColor),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Annuler',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: _primaryColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDarkMode) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: isDarkMode ? Colors.white : const Color(0xFF2C2416),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    required bool isDarkMode,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    final borderColor = isDarkMode ? const Color(0xFF2C2C2C) : const Color(0xFFE8E2D8);
    final fillColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return TextFormField(
      controller: controller,
      autocorrect: false,
      enableSuggestions: false,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: 1,
      style: TextStyle(color: textColor),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, color: _accentColor),
        filled: true,
        fillColor: fillColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _accentColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red, width: 2),
        ),
        labelStyle: TextStyle(color: isDarkMode ? Colors.grey[400] : Colors.grey[700]),
        hintStyle: TextStyle(color: isDarkMode ? Colors.grey[600] : Colors.grey[500]),
      ),
    );
  }

  Widget _buildCategoryDropdown(bool isDarkMode, Color cardColor, Color borderColor, Color? secondaryTextColor) {
    final fillColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedCategory,
        isExpanded: true,
        underline: const SizedBox(),
        style: TextStyle(color: textColor, fontSize: 16),
        items: _categories.map((String category) {
          return DropdownMenuItem<String>(
            value: category,
            child: Text(category),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedCategory = newValue;
            });
          }
        },
      ),
    );
  }

  Widget _buildPricePerUnitField(bool isDarkMode, Color cardColor, Color borderColor) {
    final fillColor = isDarkMode ? const Color(0xFF1E1E1E) : Colors.white;
    final textColor = isDarkMode ? Colors.white : Colors.black;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: fillColor,
        border: Border.all(color: borderColor),
        borderRadius: BorderRadius.circular(12),
      ),
      child: DropdownButton<String>(
        value: _selectedCurrency,
        isExpanded: true,
        underline: const SizedBox(),
        style: TextStyle(color: textColor, fontSize: 16),
        items: _currencies.map((String currency) {
          return DropdownMenuItem<String>(
            value: currency,
            child: Text(currency),
          );
        }).toList(),
        onChanged: (String? newValue) {
          if (newValue != null) {
            setState(() {
              _selectedCurrency = newValue;
            });
          }
        },
      ),
    );
  }
}
