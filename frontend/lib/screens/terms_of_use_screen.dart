import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class TermsOfUseScreen extends StatelessWidget {
  const TermsOfUseScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = AppColors.getBgColor(isDark);
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8);
    final textSecondaryColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    final primaryColor = AppColors.primary;
    
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          'Conditions d\'Utilisation',
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
            
            // Date de mise à jour - Version minimaliste
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

            // 1. Acceptation des Conditions
            _buildArticle(context, 
              title: '1. Acceptation des Conditions',
              content: 'En accédant et en utilisant MBAYMI, vous acceptez d\'être lié par ces conditions d\'utilisation. Si vous n\'acceptez pas ces conditions, veuillez ne pas utiliser notre plateforme.',
            ),
            
            const SizedBox(height: 24),

            // 2. Description du Service
            _buildArticle(context,
              title: '2. Description du Service',
              content: 'MBAYMI est une plateforme numérique qui connecte les agriculteurs, vétérinaires, et autres acteurs du secteur agricole sénégalais. Les services incluent la gestion de fermes, le marché agricole, les services vétérinaires, et les informations agricoles.',
            ),
            
            const SizedBox(height: 24),

            // 3. Compte Utilisateur
            _buildArticleWithList(context,
              title: '3. Compte Utilisateur',
              intro: 'En créant un compte:',
              items: [
                'Fournir des informations exactes et à jour',
                'Être responsable de la sécurité de votre mot de passe',
                'Ne pas partager votre compte',
                'Notifier MBAYMI de tout accès non autorisé',
              ],
            ),
            
            const SizedBox(height: 24),

            // 4. Utilisation Acceptable
            _buildArticleWithList(context,
              title: '4. Utilisation Acceptable',
              intro: 'Vous acceptez de ne pas:',
              items: [
                'Utiliser la plateforme à des fins illégales',
                'Harceler, menacer ou abuser d\'autres utilisateurs',
                'Publier du contenu offensant, diffamatoire ou contraire à l\'éthique',
                'Spammer ou utiliser des bots automatisés',
                'Accéder non autorisé aux systèmes de MBAYMI',
              ],
            ),
            
            const SizedBox(height: 24),

            // 5. Propriété Intellectuelle
            _buildArticle(context,
              title: '5. Propriété Intellectuelle',
              content: 'Tous les contenus de MBAYMI, y compris les textes, images, logos, sont protégés par les droits d\'auteur. Vous acceptez de ne pas reproduire, distribuer ou transmettre ces contenus sans autorisation.',
            ),
            
            const SizedBox(height: 24),

            // 6. Responsabilité Limitée
            _buildArticle(context,
              title: '6. Responsabilité Limitée',
              content: 'MBAYMI n\'est pas responsable des dommages directs, indirects, accidentels ou consécutifs résultant de votre utilisation de la plateforme. MBAYMI fournit les services "tels quels".',
            ),
            
            const SizedBox(height: 24),

            // 7. Liens Externes
            _buildArticle(context,
              title: '7. Liens Externes',
              content: 'MBAYMI n\'est pas responsable du contenu des liens externes. Nous vous recommandons de consulter les conditions d\'utilisation des sites externes.',
            ),
            
            const SizedBox(height: 24),

            // 8. Modifications des Conditions
            _buildArticle(context,
              title: '8. Modifications des Conditions',
              content: 'MBAYMI se réserve le droit de modifier ces conditions d\'utilisation à tout moment. Les modifications seront publiées sur cette page. Votre utilisation continue de la plateforme après les modifications signifie que vous acceptez les nouvelles conditions.',
            ),
            
            const SizedBox(height: 24),

            // 9. Résiliation
            _buildArticle(context,
              title: '9. Résiliation',
              content: 'MBAYMI se réserve le droit de suspendre ou de terminer votre compte si vous violez ces conditions d\'utilisation.',
            ),
            
            const SizedBox(height: 24),

            // 10. Loi Applicable
            _buildArticle(context,
              title: '10. Loi Applicable',
              content: 'Ces conditions d\'utilisation sont régies par les lois du Sénégal. Tout différend sera soumis aux tribunaux compétents au Sénégal.',
            ),
            
            const SizedBox(height: 24),

            // 11. Contact
            _buildArticle(context,
              title: '11. Contact',
              content: 'Pour toute question concernant ces conditions d\'utilisation, veuillez nous contacter à: support@mbaymi.com',
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