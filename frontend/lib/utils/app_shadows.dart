import 'package:flutter/material.dart';

/// 🎆 Ombres centralisées
/// Utilise ces shadows pour une profondeur cohérente
class AppShadows {
  // Ombre légère (cartes subtiles)
  static const BoxShadow small = BoxShadow(
    color: Color(0x1A000000), // 10% black
    blurRadius: 4,
    offset: Offset(0, 2),
  );

  // Ombre moyenne (éléments normaux)
  static const BoxShadow medium = BoxShadow(
    color: Color(0x24000000), // 14% black
    blurRadius: 8,
    offset: Offset(0, 4),
  );

  // Ombre large (modals, overlays)
  static const BoxShadow large = BoxShadow(
    color: Color(0x33000000), // 20% black
    blurRadius: 16,
    offset: Offset(0, 8),
  );

  // Ombre très large (bottom sheets, dialogs)
  static const BoxShadow extraLarge = BoxShadow(
    color: Color(0x42000000), // 26% black
    blurRadius: 24,
    offset: Offset(0, 12),
  );

  // Liste de shadows pour un effet en couches
  static const List<BoxShadow> elevationSmall = [small];
  static const List<BoxShadow> elevationMedium = [medium];
  static const List<BoxShadow> elevationLarge = [large];
}
