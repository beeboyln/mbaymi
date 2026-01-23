import 'package:flutter/material.dart';
import 'package:mbaymi/screens/social_feed_screen.dart';

/// 🌾 FarmNetworkScreen - Nouvel écran réseau social style Instagram
/// Maintient la compatibilité avec l'ancien code mais utilise SocialFeedScreen
class FarmNetworkScreen extends StatelessWidget {
  final bool isDarkMode;

  const FarmNetworkScreen({super.key, this.isDarkMode = false});

  @override
  Widget build(BuildContext context) {
    return SocialFeedScreen(isDarkMode: isDarkMode);
  }
}
