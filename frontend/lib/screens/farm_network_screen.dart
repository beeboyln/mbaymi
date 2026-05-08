import 'package:flutter/material.dart';
import 'package:mbaymi/screens/social_feed_screen.dart';

/// 🌾 FarmNetworkScreen - Nouvel écran réseau social style Instagram
/// Maintient la compatibilité avec l'ancien code mais utilise SocialFeedScreen
class FarmNetworkScreen extends StatelessWidget {
  const FarmNetworkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const SocialFeedScreen();
  }
}
