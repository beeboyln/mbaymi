import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/cart_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:mbaymi/screens/social/profile_detail_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mbaymi/utils/app_colors.dart';

class SaleDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? sale;
  final int? saleId;
  final bool? isDarkMode;

  const SaleDetailScreen({super.key, this.sale, this.saleId, this.isDarkMode});

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  Future<Map<String, dynamic>>? _saleFuture;
  Future<Map<String, dynamic>>? _ownerFuture;
  int _userId = 0;
  int _cartQuantity = 1;

  @override
  void initState() {
    super.initState();
    _userId = AuthService.currentSession?.userId ?? 0;
    if (widget.sale != null) {
      _saleFuture = Future.value(widget.sale!);
      final uid = widget.sale!['user_id'] as int?;
      if (uid != null) _ownerFuture = ApiService.getUserProfile(uid, viewerId: _userId > 0 ? _userId : null);
    } else if (widget.saleId != null) {
      _saleFuture = ApiService.getSale(widget.saleId!);
      _saleFuture!.then((s) {
        final uid = s['user_id'] as int?;
        if (uid != null) _ownerFuture = ApiService.getUserProfile(uid, viewerId: _userId > 0 ? _userId : null);
      });
    }
  }

  /// Safely convert additional_images from string or list to List<String>
  List<String> _getAdditionalImages(dynamic value) {
    if (value == null) return [];
    if (value is List) {
      return value.whereType<String>().toList();
    }
    if (value is String && value.isNotEmpty) {
      // Try to parse as JSON array if it looks like one
      if (value.startsWith('[') && value.endsWith(']')) {
        try {
          final parsed = Uri.decodeComponent(value);
          final urls = parsed.replaceAll('[', '').replaceAll(']', '').replaceAll('"', '').split(',');
          return urls.map((u) => u.trim()).where((u) => u.isNotEmpty).toList();
        } catch (_) {
          return [];
        }
      }
    }
    return [];
  }

  /// Ouvrir WhatsApp avec le numéro de téléphone
  void _openWhatsApp(String phoneNumber) async {
    // Nettoyer le numéro (enlever les espaces, tirets, etc.)
    final cleanedPhone = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
    
    // S'assurer que le numéro commence par +
    final formattedPhone = cleanedPhone.startsWith('+') ? cleanedPhone : '+$cleanedPhone';
    
    // Créer l'URL WhatsApp
    final whatsappUrl = Uri.parse('https://wa.me/$formattedPhone');
    
    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl, mode: LaunchMode.externalApplication);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Erreur lors de l\'ouverture de WhatsApp')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDarkMode ?? (Theme.of(context).brightness == Brightness.dark);
    return Scaffold(
      backgroundColor: isDark ? Colors.grey[900] : Colors.grey[50],
      body: FutureBuilder<Map<String, dynamic>>(
        future: _saleFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error_outline, size: 64, color: Colors.red[300]),
                  const SizedBox(height: 16),
                  Text('Erreur de chargement', style: TextStyle(fontSize: 18, color: Colors.red[300])),
                ],
              ),
            );
          }

          final sale = snapshot.data!;

          return CustomScrollView(
            slivers: [
              // AppBar avec image en arrière-plan
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: isDark ? Colors.black : AppColors.lightBg,
                foregroundColor: Colors.white,
                iconTheme: const IconThemeData(color: Colors.white),
                leading: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    decoration: BoxDecoration(
                      color: (isDark ? Colors.black : Colors.white).withOpacity(0.9),
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: Icon(Icons.arrow_back, color: isDark ? Colors.white : Colors.black87),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                ),
                flexibleSpace: FlexibleSpaceBar(
                  background: Stack(
                    fit: StackFit.expand,
                    children: [
                      if (sale['image_url'] != null)
                        Image.network(
                          sale['image_url'],
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                            child: const Icon(Icons.image_not_supported, size: 64),
                          ),
                        )
                      else
                        Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: isDark 
                                ? [Colors.grey[800]!, Colors.grey[900]!]
                                : [Colors.blue[100]!, Colors.blue[200]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Icon(Icons.shopping_bag, size: 80, color: Colors.white54),
                        ),
                      // Gradient overlay
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              Colors.black.withOpacity(0.7),
                            ],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              // Contenu
              SliverToBoxAdapter(
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark ? Colors.grey[900] : AppColors.lightBg,
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(24),
                      topRight: Radius.circular(24),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Titre et prix
                        Text(
                          sale['product_name'] ?? 'Produit',
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Prix et unité
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Prix ${_getPriceUnitLabel(sale['unit'] ?? 'kg')}',
                                        style: TextStyle(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w500,
                                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${sale['price_per_unit'] ?? ''} ${sale['currency'] ?? 'FCFA'}',
                                        style: const TextStyle(
                                          fontSize: 24,
                                          color: Colors.green,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: isDark ? Colors.grey[800] : AppColors.lightBg,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Row(
                                      children: [
                                        Icon(Icons.inventory_2, size: 18, color: Colors.green[700]),
                                        const SizedBox(width: 6),
                                        Text(
                                          '${sale['quantity']?.toString() ?? '0'} ${sale['unit'] ?? 'kg'}',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.local_shipping_outlined, size: 16, color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Text(
                                            'Stock: ${sale['quantity']?.toString() ?? '0'} ${sale['unit'] ?? 'kg'}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w500,
                                              color: isDark ? Colors.grey[300] : Colors.grey[700],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isDark ? Colors.grey[800] : Colors.grey[200],
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(Icons.update, size: 16, color: AppColors.primary),
                                          const SizedBox(width: 6),
                                          Expanded(
                                            child: Text(
                                              'Maj: ${_formatDate(sale['updated_at'] ?? sale['created_at'])}',
                                              style: TextStyle(
                                                fontSize: 12,
                                                fontWeight: FontWeight.w500,
                                                color: isDark ? Colors.grey[300] : Colors.grey[700],
                                              ),
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Photos additionnelles
                        if (_getAdditionalImages(sale['additional_images']).isNotEmpty) ...[
                          _buildSectionTitle('Galerie', Icons.photo_library, isDark),
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            physics: const ClampingScrollPhysics(),
                            child: Row(
                              children: _getAdditionalImages(sale['additional_images']).map<Widget>((imageUrl) {
                                return GestureDetector(
                                  onTap: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => Dialog(
                                        child: Image.network(imageUrl, fit: BoxFit.contain),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    margin: const EdgeInsets.only(right: 12),
                                    width: 120,
                                    height: 120,
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(color: Colors.grey.withOpacity(0.3)),
                                    ),
                                    child: ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, progress) {
                                          if (progress == null) return child;
                                          return const Center(
                                            child: SizedBox(
                                              width: 18,
                                              height: 18,
                                              child: CircularProgressIndicator(strokeWidth: 1.5),
                                            ),
                                          );
                                        },
                                        errorBuilder: (c, e, s) => Center(
                                          child: Icon(Icons.broken_image, color: Colors.grey[400]),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        // Description
                        if ((sale['description'] as String?)?.isNotEmpty ?? false) ...[
                          _buildSectionTitle('Description', Icons.description, isDark),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? Colors.grey[850] : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              sale['description'],
                              style: TextStyle(
                                fontSize: 15,
                                height: 1.5,
                                color: isDark ? Colors.grey[300] : Colors.grey[800],
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],
                        
                        // Informations de livraison
                        _buildSectionTitle('Informations', Icons.info_outline, isDark),
                        const SizedBox(height: 12),
                        _buildInfoCard(
                          icon: Icons.location_on,
                          title: 'Lieu de livraison',
                          value: sale['delivery_location'] ?? 'Non spécifié',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoCard(
                          icon: Icons.phone,
                          title: 'Contact',
                          value: sale['contact'] ?? 'Non spécifié',
                          isDark: isDark,
                        ),
                        const SizedBox(height: 8),
                        _buildInfoCard(
                          icon: Icons.calendar_today,
                          title: 'Publié le',
                          value: _formatDate(sale['created_at']),
                          isDark: isDark,
                        ),
                        const SizedBox(height: 24),
                        
                        // Vendeur
                        _buildSectionTitle('Vendeur', Icons.person, isDark),
                        const SizedBox(height: 12),
                        FutureBuilder<Map<String, dynamic>>(
                          future: _ownerFuture,
                          builder: (context, ownerSnap) {
                            if (ownerSnap.connectionState == ConnectionState.waiting) {
                              return Container(
                                height: 80,
                                alignment: Alignment.center,
                                child: const CircularProgressIndicator(),
                              );
                            }
                            if (ownerSnap.hasError || !ownerSnap.hasData) {
                              return Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('Vendeur: ${sale['user_id'] ?? 'Inconnu'}'),
                              );
                            }
                            final owner = ownerSnap.data!;
                            return Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: isDark ? Colors.grey[850] : Colors.grey[100],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      border: Border.all(color: Colors.green, width: 2),
                                    ),
                                    child: owner['profile_image'] != null
                                        ? CircleAvatar(
                                            radius: 30,
                                            backgroundImage: NetworkImage(owner['profile_image']),
                                          )
                                        : const CircleAvatar(
                                            radius: 30,
                                            child: Icon(Icons.person, size: 30),
                                          ),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          owner['name'] ?? 'Utilisateur',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: isDark ? Colors.white : Colors.black87,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          owner['phone'] ?? owner['email'] ?? '',
                                          style: TextStyle(
                                            fontSize: 14,
                                            color: isDark ? Colors.grey[400] : Colors.grey[600],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  // Bouton WhatsApp
                                  if (owner['phone'] != null && (owner['phone'] as String).isNotEmpty)
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.green,
                                        borderRadius: BorderRadius.circular(50),
                                      ),
                                      child: IconButton(
                                        onPressed: () {
                                          _openWhatsApp(owner['phone']);
                                        },
                                        icon: const Icon(Icons.chat, color: Colors.white),
                                        tooltip: 'WhatsApp',
                                        constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                      ),
                                    ),
                                  const SizedBox(width: 8),
                                  ElevatedButton(
                                    onPressed: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => ProfileDetailScreen(
                                            userId: owner['id'],
                                            isDarkMode: isDark,
                                          ),
                                        ),
                                      );
                                    },
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      foregroundColor: Colors.white,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 16,
                                        vertical: 8,
                                      ),
                                    ),
                                    child: const Text('Voir'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 24),
                        
                        // Bouton Ajouter au panier
                        _buildAddToCartSection(sale, isDark),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Construire la section "Ajouter au panier"
  Widget _buildAddToCartSection(Map<String, dynamic> sale, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.green.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.green.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Quantité à commander',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              Container(
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
                child: Row(
                  children: [
                    InkWell(
                      onTap: _cartQuantity > 1
                          ? () => setState(() => _cartQuantity--)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Icon(
                          Icons.remove,
                          size: 18,
                          color: _cartQuantity > 1
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                      ),
                    ),
                    Container(
                      color: AppColors.primary.withOpacity(0.1),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                      child: Text(
                        _cartQuantity.toString(),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    InkWell(
                      onTap: _cartQuantity < (sale['quantity'] as int? ?? 0)
                          ? () => setState(() => _cartQuantity++)
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        child: Icon(
                          Icons.add,
                          size: 18,
                          color: _cartQuantity < (sale['quantity'] as int? ?? 0)
                              ? AppColors.primary
                              : Colors.grey,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Consumer<CartProvider>(
            builder: (context, cartProvider, _) {
              return ElevatedButton(
                onPressed: () {
                  HapticFeedback.mediumImpact();
                  cartProvider.addItem(
                    id: sale['id'],
                    name: sale['product_name'] ?? 'Produit',
                    price: sale['price_per_unit'] as double? ?? 0.0,
                    quantity: _cartQuantity,
                    image: sale['image_url'],
                    unit: sale['unit'] ?? 'kg',
                    sellerId: sale['user_id'] as int? ?? 0,
                  );
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        '$_cartQuantity ${sale['unit'] ?? "kg"} ajoutée au panier',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                      backgroundColor: Colors.green,
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  setState(() => _cartQuantity = 1);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.shopping_cart, size: 18),
                    SizedBox(width: 8),
                    Text(
                      'AJOUTER AU PANIER',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  /// Obtenir le label de l'unité de prix
  String _getPriceUnitLabel(String unit) {
    final unitLower = unit.toLowerCase();
    if (unitLower == 'kg' || unitLower == 'kilogramme') {
      return 'au kilogramme';
    } else if (unitLower == 'unit' || unitLower == 'unité' || unitLower == '') {
      return 'à l\'unité';
    } else if (unitLower == 'litre' || unitLower == 'l') {
      return 'au litre';
    } else if (unitLower == 'botte' || unitLower == 'bunch' || unitLower == 'bouquet') {
      return 'à la botte';
    }
    return 'par ${unit.toLowerCase()}';
  }

  Widget _buildSectionTitle(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 20, color: Colors.green),
        const SizedBox(width: 8),
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Colors.green),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic raw) {
    if (raw == null) return 'Non spécifié';
    try {
      final s = raw.toString();
      final dt = DateTime.parse(s);
      return DateFormat('dd/MM/yyyy').format(dt);
    } catch (_) {
      return raw.toString();
    }
  }
}