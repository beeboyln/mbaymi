import 'package:flutter/material.dart';
import 'package:mbaymi/utils/app_colors.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.getBgColor(isDark);
    final primaryColor = AppColors.primary;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Politique de Confidentialité',
          style: TextStyle(
            fontWeight: FontWeight.w400,
            letterSpacing: -0.2,
          ),
        ),
        centerTitle: true,
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        titleTextStyle: TextStyle(
          color: isDark ? Colors.white : Colors.black,
          fontSize: 18,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.2,
        ),
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            
            // Date de mise à jour
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'Dernière mise à jour: 1er Mars 2026',
                style: TextStyle(
                  color: primaryColor,
                  fontSize: 12,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ),
            
            const SizedBox(height: 32),

            // 1. Introduction
            _buildArticle(context,
              title: '1. Introduction',
              content: 'MBAYMI est une plateforme numérique dédiée aux agriculteurs, aux vétérinaires et à la communauté agricole sénégalaise. Cette politique de confidentialité décrit comment nous collectons, utilisons, protégeons et partageons vos données personnelles.',
            ),
            
            const SizedBox(height: 24),

            // 2. Données Collectées
            _buildArticleWithList(context,
              title: '2. Données Collectées',
              intro: 'Nous collectons les informations suivantes:',
              items: [
                'Informations de compte: nom, email, téléphone',
                'Informations agricoles: fermes, cultures, élevage',
                'Données de localisation: coordonnées GPS',
                'Données de marché: prix, offres, demandes',
                'Données d\'utilisation: pages visitées, actions effectuées',
              ],
            ),
            
            const SizedBox(height: 24),

            // 3. Utilisation des Données
            _buildArticleWithList(context,
              title: '3. Utilisation des Données',
              intro: 'Nous utilisons vos données pour:',
              items: [
                'Fournir et améliorer nos services',
                'Personnaliser votre expérience',
                'Communiquer avec vous',
                'Détecter et prévenir la fraude',
                'Respecter les lois et réglementations',
              ],
            ),
            
            const SizedBox(height: 24),

            // 4. Sécurité des Données
            _buildArticle(context,
              title: '4. Sécurité des Données',
              content: 'MBAYMI met en place des mesures de sécurité appropriées pour protéger vos données personnelles contre l\'accès non autorisé, la modification, la divulgation ou la destruction. Cependant, aucune méthode de transmission sur Internet n\'est 100% sécurisée.',
            ),
            
            const SizedBox(height: 24),

            // 5. Partage des Données
            _buildArticle(context,
              title: '5. Partage des Données',
              content: 'Nous ne vendons pas, n\'échangeons pas et ne louons pas vos informations personnelles à des tiers. Nous pouvons partager des données anonymisées et agrégées avec nos partenaires pour améliorer nos services.',
            ),
            
            const SizedBox(height: 24),

            // 6. Cookies
            _buildArticle(context,
              title: '6. Cookies',
              content: 'MBAYMI utilise des cookies pour améliorer votre expérience utilisateur. Vous pouvez contrôler les cookies dans les paramètres de votre navigateur.',
            ),
            
            const SizedBox(height: 24),

            // 7. Vos Droits
            _buildArticleWithList(context,
              title: '7. Vos Droits',
              intro: 'Vous avez le droit de:',
              items: [
                'Accéder à vos données personnelles',
                'Corriger vos données',
                'Demander la suppression de vos données',
                'Vous opposer au traitement de vos données',
              ],
            ),
            
            const SizedBox(height: 24),

            // 8. Modifications
            _buildArticle(context,
              title: '8. Modifications',
              content: 'MBAYMI se réserve le droit de modifier cette politique de confidentialité à tout moment. Les modifications seront publiées sur cette page.',
            ),
            
            const SizedBox(height: 24),

            // 9. Contact
            _buildArticle(context,
              title: '9. Contact',
              content: 'Pour toute question concernant cette politique de confidentialité, veuillez nous contacter à: support@mbaymi.com',
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildArticle(BuildContext context, {
    required String title,
    required String content,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          content,
          style: TextStyle(
            fontSize: 14,
            height: 1.6,
            color: textColor,
          ),
        ),
      ],
    );
  }

  Widget _buildArticleWithList(BuildContext context, {
    required String title,
    required String intro,
    required List<String> items,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: AppColors.primary,
            letterSpacing: -0.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          intro,
          style: TextStyle(
            fontSize: 14,
            color: textColor,
          ),
        ),
        const SizedBox(height: 4),
        ...items.map((item) => _buildBullet(context, item)).toList(),
      ],
    );
  }

  Widget _buildBullet(BuildContext context, String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 8, right: 12),
            child: Container(
              width: 4,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 14,
                color: textColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}