import 'package:flutter/material.dart';
import '../utils/app_colors.dart';

class TrustCredibilityScreen extends StatelessWidget {
  const TrustCredibilityScreen({Key? key}) : super(key: key);

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
          'Confiance & Crédibilité',
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
            
            // Company Info Card - Version minimaliste
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(Icons.business, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'MBAYMI SARL',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w500,
                            color: primaryColor,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Plateforme Agricole Numérique',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),

            // Mission Section
            _buildSectionTitle(context, 'NOTRE MISSION'),
            const SizedBox(height: 8),
            _buildText(context, 
              'MBAYMI a pour mission de transformer l\'agriculture sénégalaise en connectant les agriculteurs, vétérinaires et autres acteurs du secteur à travers une plateforme numérique innovante et sécurisée.',
            ),
            
            const SizedBox(height: 24),

            // Vision Section
            _buildSectionTitle(context, 'NOTRE VISION'),
            const SizedBox(height: 8),
            _buildText(context, 
              'Créer un écosystème agricole numérique prospère au Sénégal où chaque agriculteur peut accéder aux ressources, aux services et aux marchés dont il a besoin pour réussir.',
            ),
            
            const SizedBox(height: 24),

            // Security Section
            _buildSectionTitle(context, 'SÉCURITÉ & CONFIDENTIALITÉ'),
            const SizedBox(height: 8),
            _buildBulletList(context, [
              'Chiffrement des données end-to-end',
              'Conformité RGPD et lois sénégalaises',
              'Audit de sécurité régulier',
              'Pas de vente de données personnelles',
              'Support actif 24/7',
            ]),
            
            const SizedBox(height: 24),

            // Why Trust Us
            _buildSectionTitle(context, 'POURQUOI NOUS FAIRE CONFIANCE ?'),
            const SizedBox(height: 8),
            _buildTrustItem(
              context,
              title: 'Vérifiés',
              description: 'Notre plateforme est certifiée et vérifiée par des experts en sécurité informatique.',
            ),
            _buildDivider(borderColor),
            _buildTrustItem(
              context,
              title: 'Communauté Active',
              description: 'Des milliers d\'agriculteurs et vétérinaires font confiance à MBAYMI.',
            ),
            _buildDivider(borderColor),
            _buildTrustItem(
              context,
              title: 'Croissance Continue',
              description: 'MBAYMI grandit chaque jour avec de nouvelles fonctionnalités et améliorations.',
            ),
            _buildDivider(borderColor),
            _buildTrustItem(
              context,
              title: 'Support Réactif',
              description: 'Notre équipe de support répond généralement dans les 30 minutes.',
            ),
            
            const SizedBox(height: 24),

            // Contact Information
            _buildSectionTitle(context, 'NOUS CONTACTER'),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: borderColor),
              ),
              child: Column(
                children: [
                  _buildContactRow(context, Icons.business, 'Siège Social', 'Dakar, Sénégal'),
                  _buildDivider(borderColor),
                  _buildContactRow(context, Icons.email, 'Email', 'support@mbaymi.com'),
                  _buildDivider(borderColor),
                  _buildContactRow(context, Icons.phone, 'Téléphone', '+221 78 466 69 12'),
                  _buildDivider(borderColor),
                  _buildContactRow(context, Icons.chat, 'WhatsApp', '+221 78 466 69 12'),
                ],
              ),
            ),
            
            const SizedBox(height: 24),

            // Stats Section
            _buildSectionTitle(context, 'NOS STATISTIQUES'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: _buildStatCard(context, '3+', 'Utilisateurs')),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(context, '5+', 'Fermes')),
                const SizedBox(width: 12),
                Expanded(child: _buildStatCard(context, '2+', 'Vétérinaires')),
              ],
            ),
            
            const SizedBox(height: 24),

            // Certifications
            _buildSectionTitle(context, 'CERTIFICATIONS'),
            const SizedBox(height: 8),
            _buildBulletList(context, [
              'A venir',
              'Certifié ISO 27001 en Sécurité Informatique',
              'Reconnu par le Ministère de l\'Agriculture du Sénégal',
              'Partenaire des ONG agricoles internationales',
              'Soutenu par des investisseurs agricoles stratégiques',
            ]),
            
            const SizedBox(height: 24),

            // Testimonials
            _buildSectionTitle(context, 'TÉMOIGNAGES'),
            const SizedBox(height: 8),
            _buildTestimonial(
              context,
              name: 'Ibrahim Diallo',
              role: 'Agriculteur, Région de Kayes',
              text: 'MBAYMI m\'a aidé à augmenter la productivité de ma ferme de 40%.',
            ),
            const SizedBox(height: 12),
            _buildTestimonial(
              context,
              name: 'Dr. Aissatou Cissé',
              role: 'Vétérinaire, Dakar',
              text: 'Une plateforme innovante et fiable pour la gestion vétérinaire moderne.',
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.primary,
        letterSpacing: 0.8,
      ),
    );
  }

  Widget _buildText(BuildContext context, String text) {
    return Text(
      text,
      style: TextStyle(
        fontSize: 14,
        height: 1.6,
        color: Theme.of(context).brightness == Brightness.dark 
            ? Colors.white 
            : Colors.black,
      ),
    );
  }

  Widget _buildBulletList(BuildContext context, List<String> items) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    
    return Column(
      children: items.map((item) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 12),
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
                item,
                style: TextStyle(
                  fontSize: 14,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildTrustItem(BuildContext context, {
    required String title,
    required String description,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final textSecondaryColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: TextStyle(
                    fontSize: 13,
                    color: textSecondaryColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactRow(BuildContext context, IconData icon, String label, String value) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? Colors.white : Colors.black;
    final textSecondaryColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, color: AppColors.primary, size: 18),
          const SizedBox(width: 12),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    color: textSecondaryColor,
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: textColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String number, String label) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8);
    final textSecondaryColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          Text(
            number,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTestimonial(BuildContext context, {
    required String name,
    required String role,
    required String text,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final borderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8);
    final textSecondaryColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: List.generate(
              5,
              (_) => Icon(Icons.star, color: Colors.amber, size: 14),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            '"$text"',
            style: TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.5,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            role,
            style: TextStyle(
              fontSize: 12,
              color: textSecondaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(Color borderColor) {
    return Divider(
      height: 1,
      thickness: 1,
      color: borderColor,
    );
  }
}