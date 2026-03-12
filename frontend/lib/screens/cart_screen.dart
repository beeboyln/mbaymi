import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:mbaymi/services/cart_provider.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> {
  Future<void> _openWhatsApp(CartProvider cartProvider) async {
    // Générer le message de la commande
    String message = _generateOrderMessage(cartProvider);
    
    try {
      // Créer l'URL WhatsApp
      String whatsappUrl = "https://wa.me/?text=${Uri.encodeComponent(message)}";
      
      if (await canLaunchUrl(Uri.parse(whatsappUrl))) {
        await launchUrl(Uri.parse(whatsappUrl), mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('WhatsApp n\'est pas installé'),
              backgroundColor: Colors.red,
              duration: Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: ${e.toString()}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    }
  }

  String _generateOrderMessage(CartProvider cartProvider) {
    String message = "🛒 *COMMANDE MBAYMI*\n\n";
    message += "*Détails de la commande:*\n";
    message += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n\n";
    
    // Ajouter les produits
    for (final item in cartProvider.items) {
      final subtotal = item.price * item.quantity;
      message += "📦 ${item.name}\n";
      message += "  Prix: ${item.price.toStringAsFixed(0)} FCFA/${item.unit}\n";
      message += "  Quantité: ${item.quantity} ${item.unit}\n";
      message += "  Sous-total: ${subtotal.toStringAsFixed(0)} FCFA\n\n";
    }
    
    message += "━━━━━━━━━━━━━━━━━━━━━━━━━━━━\n";
    message += "*TOTAL: ${cartProvider.totalPrice.toStringAsFixed(0)} FCFA*\n\n";
    message += "Merci de confirmer cette commande! 🙏";
    
    return message;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.getBgColor(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.getBgColor(isDark),
        elevation: 0,
        title: Text(
          'PANIER',
          style: TextStyle(
            color: AppColors.getTextColor(isDark),
            fontSize: 13,
            fontWeight: FontWeight.w400,
            letterSpacing: 2.5,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.getTextColor(isDark)),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Consumer<CartProvider>(
        builder: (context, cartProvider, _) {
          if (cartProvider.items.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.shopping_cart_outlined,
                    size: 64,
                    color: AppColors.getSecondaryTextColor(isDark),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'PANIER VIDE',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      letterSpacing: 2,
                      color: AppColors.getTextColor(isDark),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Découvrez nos produits',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.getSecondaryTextColor(isDark),
                    ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: cartProvider.items.length,
                  itemBuilder: (ctx, idx) =>
                      _buildCartItem(cartProvider.items[idx], cartProvider, isDark),
                ),
              ),
              _buildCartSummary(cartProvider, isDark),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cartProvider, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.getCardBgColor(isDark),
        border: Border.all(
          color: AppColors.getBorderColor(isDark),
          width: 1,
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          // Image
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.grey[300],
              borderRadius: BorderRadius.circular(6),
              image: item.image != null
                  ? DecorationImage(
                      image: NetworkImage(item.image!),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            child: item.image == null
                ? Icon(
                    Icons.image_outlined,
                    color: Colors.grey[600],
                  )
                : null,
          ),
          const SizedBox(width: 12),
          // Détails
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.getTextColor(isDark),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.price.toStringAsFixed(0)} FCFA/${item.unit}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    InkWell(
                      onTap: item.quantity > 1
                          ? () => cartProvider.updateQuantity(item.id, item.quantity - 1)
                          : null,
                      child: Icon(
                        Icons.remove_circle_outline,
                        size: 18,
                        color: item.quantity > 1
                            ? AppColors.primary
                            : Colors.grey,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${item.quantity}',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.getTextColor(isDark),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => cartProvider.updateQuantity(item.id, item.quantity + 1),
                      child: const Icon(
                        Icons.add_circle_outline,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () => cartProvider.removeItem(item.id),
                      child: Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red[400],
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

  Widget _buildCartSummary(CartProvider cartProvider, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.getCardBgColor(isDark),
        border: Border(
          top: BorderSide(
            color: AppColors.getBorderColor(isDark),
            width: 1,
          ),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.getTextColor(isDark),
                ),
              ),
              Text(
                '${cartProvider.totalPrice.toStringAsFixed(0)} FCFA',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton(
            onPressed: () => _openWhatsApp(cartProvider),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'PASSER LA COMMANDE',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Continuer vos achats',
              style: TextStyle(
                fontSize: 12,
                color: AppColors.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
