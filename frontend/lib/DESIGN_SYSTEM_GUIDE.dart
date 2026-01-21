/// 📚 GUIDE D'UTILISATION - Design System Mbaymi
/// 
/// Ce fichier explique comment utiliser le nouveau design system
/// pour maintenir une cohérence visuelle dans toute l'app
///
/// ============================================================

// IMPORTS (à ajouter en haut de chaque fichier)
// import 'package:mbaymi/utils/app_colors.dart';
// import 'package:mbaymi/utils/app_spacing.dart';
// import 'package:mbaymi/utils/app_typography.dart';
// import 'package:mbaymi/utils/app_radius.dart';
// import 'package:mbaymi/utils/app_shadows.dart';

/// ============================================================
/// 1️⃣ COULEURS
/// ============================================================

// ✅ BON - Utiliser AppColors
// Container(
//   color: AppColors.primary,
//   child: Text('Hello', style: TextStyle(color: AppColors.textLight)),
// )

// ❌ MAUVAIS - Hardcoded
// Container(
//   color: Color(0xFF2D5016),
//   child: Text('Hello', style: TextStyle(color: Colors.black87)),
// )

// USAGE EXEMPLE:
// final isDark = Theme.of(context).brightness == Brightness.dark;
// final bgColor = AppColors.getBgColor(isDark);
// final textColor = AppColors.getTextColor(isDark);
// final cardBg = AppColors.getCardBgColor(isDark);

/// ============================================================
/// 2️⃣ SPACING
/// ============================================================

// ✅ BON
// Padding(
//   padding: EdgeInsets.all(AppSpacing.md),
//   child: ...
// )

// ❌ MAUVAIS
// Padding(
//   padding: EdgeInsets.all(16),
//   child: ...
// )

// ESPACEMENTS DISPONIBLES:
// AppSpacing.xs = 4.0
// AppSpacing.sm = 8.0
// AppSpacing.md = 16.0   <- Le plus utilisé
// AppSpacing.lg = 24.0
// AppSpacing.xl = 32.0
// AppSpacing.xxl = 48.0

/// ============================================================
/// 3️⃣ TYPOGRAPHIE
/// ============================================================

// ✅ BON - Utiliser AppTypography
// Text('Titre', style: AppTypography.h2)
// Text('Corps', style: AppTypography.body)
// Text('Petit', style: AppTypography.bodySmall)

// ❌ MAUVAIS
// Text('Titre', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600))

// STYLES DISPONIBLES:
// AppTypography.h1, h2, h3 - Titres
// AppTypography.bodyLarge, body, bodySmall - Corps
// AppTypography.label, labelSmall - Étiquettes
// AppTypography.button - Texte de bouton
// AppTypography.caption - Très petit texte

/// ============================================================
/// 4️⃣ RADIUS
/// ============================================================

// ✅ BON
// BorderRadius.circular(AppRadius.md)

// ❌ MAUVAIS
// BorderRadius.circular(12)

// VALEURS:
// AppRadius.sm = 8.0
// AppRadius.md = 12.0   <- Le plus utilisé
// AppRadius.lg = 16.0
// AppRadius.xl = 24.0
// AppRadius.full = 99.0 (pour cerles)

/// ============================================================
/// 5️⃣ SHADOWS
/// ============================================================

// ✅ BON
// boxShadow: AppShadows.elevationSmall

// ❌ MAUVAIS
// boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)]

// OMBRES DISPONIBLES:
// AppShadows.small - Cartes subtiles
// AppShadows.medium - Éléments normaux
// AppShadows.large - Modals, overlays
// AppShadows.extraLarge - Bottom sheets, dialogs

/// ============================================================
/// 6️⃣ WIDGETS RÉUTILISABLES
/// ============================================================

// 🔘 BOUTONS
// AppButton(label: 'Envoyer', onPressed: () {})
// AppSecondaryButton(label: 'Annuler', onPressed: () {})
// AppTextButton(label: 'En savoir plus', onPressed: () {})

// 📦 CARTES
// AppCard(child: Text('Contenu'))
// AppElevatedCard(child: Text('Contenu'))
// AppCompactCard(child: Text('Contenu'))

// 🔤 INPUTS
// AppInput(label: 'Email', keyboardType: TextInputType.emailAddress)
// AppSearchInput(hint: 'Rechercher...')

/// ============================================================
/// 7️⃣ EXEMPLE COMPLET
/// ============================================================

/*
import 'package:flutter/material.dart';
import 'package:mbaymi/utils/app_colors.dart';
import 'package:mbaymi/utils/app_spacing.dart';
import 'package:mbaymi/utils/app_typography.dart';
import 'package:mbaymi/utils/app_radius.dart';
import 'package:mbaymi/widgets/app_button.dart';
import 'package:mbaymi/widgets/app_card.dart';

class ExampleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.getBgColor(isDark),
      appBar: AppBar(
        backgroundColor: AppColors.primary,
        title: Text('Mon App', style: AppTypography.h2),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(AppSpacing.lg),
        child: Column(
          children: [
            // Titre
            Text('Bienvenue', style: AppTypography.h2),
            SizedBox(height: AppSpacing.md),
            
            // Carte
            AppCard(
              isDarkMode: isDark,
              child: Column(
                children: [
                  Text('Contenu', style: AppTypography.body),
                  SizedBox(height: AppSpacing.md),
                  AppButton(
                    label: 'Continuer',
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
*/

/// ============================================================
/// 8️⃣ CHECKLIST - Avant de soumettre du code
/// ============================================================

// ☑️ Toutes les couleurs viennent de AppColors
// ☑️ Tous les espacements utilisent AppSpacing
// ☑️ Toute la typographie utilise AppTypography
// ☑️ Tous les radius utilisent AppRadius
// ☑️ Toutes les ombres utilisent AppShadows
// ☑️ Les boutons utilisent AppButton/AppSecondaryButton
// ☑️ Les cartes utilisent AppCard
// ☑️ Les inputs utilisent AppInput
// ☑️ Pas de Color(0xFF...) hardcodé
// ☑️ Pas de fontSize/FontWeight hardcodé
// ☑️ Pas de EdgeInsets.all(16) hardcodé
// ☑️ Aucune bordure hardcodée
