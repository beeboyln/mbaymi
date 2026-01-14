import 'package:flutter/material.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:intl/intl.dart';
import 'package:mbaymi/screens/profile_detail_screen.dart';

class SaleDetailScreen extends StatefulWidget {
  final Map<String, dynamic>? sale;
  final int? saleId;
  final bool? isDarkMode;

  const SaleDetailScreen({Key? key, this.sale, this.saleId, this.isDarkMode}) : super(key: key);

  @override
  State<SaleDetailScreen> createState() => _SaleDetailScreenState();
}

class _SaleDetailScreenState extends State<SaleDetailScreen> {
  Future<Map<String, dynamic>>? _saleFuture;
  Future<Map<String, dynamic>>? _ownerFuture;
  int _userId = 0;

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
                backgroundColor: isDark ? Colors.black : Colors.white,
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
                    color: isDark ? Colors.grey[900] : Colors.white,
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
                        
                        // Prix et quantité
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Prix unitaire',
                                    style: TextStyle(
                                      fontSize: 12,
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
                                  color: isDark ? Colors.grey[800] : Colors.white,
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.inventory_2, size: 18, color: Colors.green[700]),
                                    const SizedBox(width: 6),
                                    Text(
                                      '${sale['quantity']?.toString() ?? '0'}',
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
                        ),
                        const SizedBox(height: 24),
                        
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