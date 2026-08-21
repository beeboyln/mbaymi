import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/theme_provider.dart';
import '../services/auth_service.dart';
import '../utils/app_colors.dart';
import 'legal/privacy_policy_screen.dart';
import 'legal/terms_of_use_screen.dart';
import 'legal/trust_credibility_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> with TickerProviderStateMixin { // Ajout du mixin
  // Animation controllers
  late AnimationController _themeAnimationController;
  late Animation<double> _themeAnimation;
  
  // Cache des couleurs
  late Color _primaryColor;
  late Color _bgColor;
  late Color _cardColor;
  late Color _borderColor;
  late Color _textSecondaryColor;

  @override
  void initState() {
    super.initState();
    
    // Initialisation avec 'this' qui est maintenant un TickerProvider grâce au mixin
    _themeAnimationController = AnimationController(
      vsync: this, // Maintenant 'this' est valide
      duration: const Duration(milliseconds: 150),
    );
    
    _themeAnimation = CurvedAnimation(
      parent: _themeAnimationController,
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _themeAnimationController.dispose();
    super.dispose();
  }

  // Version ultra-rapide sans animation pour le switch
  void _onThemeChanged(bool value) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    themeProvider.toggleDarkMode();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDark = themeProvider.isDarkMode;
    
    // Mise à jour des couleurs en cache
    _primaryColor = AppColors.primary;
    _bgColor = AppColors.getBgColor(isDark);
    _cardColor = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    _borderColor = isDark ? const Color(0xFF2C2C2C) : const Color(0xFFE8E8E8);
    _textSecondaryColor = isDark ? Colors.grey.shade400 : Colors.grey.shade600;
    
    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        title: const Text(
          'Paramètres',
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
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
          const SizedBox(height: 16),
          
          // Apparence Section
          _buildSection(
            title: 'APPARENCE',
            children: [
              _buildOptimizedSwitchTile(
                icon: isDark ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                title: isDark ? 'Mode sombre' : 'Mode clair',
                value: isDark,
                onChanged: _onThemeChanged,
              ),
            ],
          ),
          
          const SizedBox(height: 32),

          // Confiance Section
          _buildSection(
            title: 'CONFIANCE & CRÉDIBILITÉ',
            children: [
              _buildOptimizedTile(
                icon: Icons.verified_outlined,
                title: 'Confiance & Crédibilité',
                subtitle: 'En savoir plus sur MBAYMI',
                onTap: () => _navigateTo(context, const TrustCredibilityScreen()),
              ),
            ],
          ),
          
          const SizedBox(height: 32),

          // Juridique Section
          _buildSection(
            title: 'JURIDIQUE',
            children: [
              _buildOptimizedTile(
                icon: Icons.lock_outlined,
                title: 'Politique de Confidentialité',
                subtitle: 'Vos données sont protégées',
                onTap: () => _navigateTo(context, const PrivacyPolicyScreen()),
              ),
              _buildMinimalistDivider(),
              _buildOptimizedTile(
                icon: Icons.description_outlined,
                title: "Conditions d'Utilisation",
                subtitle: 'Nos conditions générales',
                onTap: () => _navigateTo(context, const TermsOfUseScreen()),
              ),
            ],
          ),
          
          const SizedBox(height: 32),

          // Support Section
          _buildSection(
            title: 'SUPPORT',
            children: [
              _buildOptimizedTile(
                icon: Icons.email_outlined,
                title: 'Nous Contacter',
                subtitle: 'support@mbaymi.com',
                onTap: () => _showContactDialog(),
              ),
              _buildMinimalistDivider(),
              _buildOptimizedTile(
                icon: Icons.chat_outlined,
                title: 'Assistance WhatsApp',
                subtitle: '+221 78 466 69 12',
                onTap: () => _showWhatsAppDialog(),
              ),
              _buildMinimalistDivider(),
              _buildOptimizedTile(
                icon: Icons.phone_outlined,
                title: 'Appeler',
                subtitle: '+221 78 466 69 12',
                onTap: () => _showCallDialog(),
              ),
            ],
          ),
          
          const SizedBox(height: 32),

          // Admin Section (only for admins)
          if (AuthService.currentSession?.role == 'admin') ...[
            _buildSection(
              title: '👨‍💼 ADMINISTRATION',
              children: [
                _buildOptimizedTile(
                  icon: Icons.admin_panel_settings_outlined,
                  title: 'Tableau de Bord Admin',
                  subtitle: 'Gérer vétérinaires et autorisations',
                  onTap: () => Navigator.pushNamed(context, '/admin-dashboard'),
                ),
              ],
            ),
            const SizedBox(height: 32),
          ],

          // À Propos Section
          _buildSection(
            title: 'À PROPOS',
            children: [
              _buildInfoItem('Entreprise', 'MBAYMI'),
              _buildMinimalistDivider(),
              _buildInfoItem('Siège Social', 'Dakar, Sénégal'),
              _buildMinimalistDivider(),
              _buildInfoItem('Email', 'support@mbaymi.com'),
              _buildMinimalistDivider(),
              _buildInfoItem('Téléphone', '+221 78 466 69 12'),
            ],
          ),
          
          const SizedBox(height: 32),
          
          Center(
            child: Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 12,
                color: _textSecondaryColor,
                letterSpacing: -0.1,
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // Switch Tile ultra-rapide
  Widget _buildOptimizedSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Container(
      color: Colors.transparent,
      child: Row(
        children: [
          const SizedBox(width: 16),
          Icon(icon, size: 20, color: _textSecondaryColor),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: _primaryColor,
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
          ),
          const SizedBox(width: 16),
        ],
      ),
    );
  }

  // Tile optimisé
  Widget _buildOptimizedTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Icon(icon, size: 20, color: _textSecondaryColor),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w400),
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(fontSize: 12, color: _textSecondaryColor),
                      ),
                    ],
                  ],
                ),
              ),
              Icon(Icons.chevron_right, size: 18, color: _textSecondaryColor),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSection({required String title, required List<Widget> children}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 12, bottom: 8),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: _textSecondaryColor,
              letterSpacing: 0.8,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _cardColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: _borderColor),
          ),
          child: Column(
            children: children,
          ),
        ),
      ],
    );
  }

  Widget _buildMinimalistDivider() {
    return Divider(
      height: 1,
      thickness: 1,
      indent: 52,
      color: _borderColor,
    );
  }

  Widget _buildInfoItem(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 14, color: _textSecondaryColor)),
          Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  void _navigateTo(BuildContext context, Widget screen) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => screen,
      ),
    );
  }

  void _showContactDialog() {
    _showMinimalistDialog(
      title: 'Nous Contacter',
      content: 'support@mbaymi.com\n\nNous vous répondrons dans les 24h.',
    );
  }

  void _showWhatsAppDialog() {
    _showMinimalistDialog(
      title: 'Assistance WhatsApp',
      content: '+221 78 466 69 12\n\nRéponse généralement en moins de 30 minutes.',
    );
  }

  void _showCallDialog() {
    _showMinimalistDialog(
      title: 'Appeler',
      content: '+221 78 466 69 12\n\nHoraires: Lundi - Vendredi, 8h - 17h',
    );
  }

  void _showMinimalistDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: _cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: _borderColor),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
              ),
              const SizedBox(height: 16),
              Text(
                content,
                style: TextStyle(fontSize: 14, color: _textSecondaryColor, height: 1.5),
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => Navigator.pop(context),
                  style: TextButton.styleFrom(foregroundColor: _primaryColor),
                  child: const Text('Fermer'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}