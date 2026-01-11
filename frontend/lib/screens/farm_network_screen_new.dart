import 'package:flutter/material.dart';
import 'package:mbaymi/screens/social_feed_screen.dart';

/// 🌾 Wrapper - FarmNetworkScreen maintient la compatibilité avec l'ancien code
/// mais utilise maintenant le nouveau SocialFeedScreen en arrière-plan
class FarmNetworkScreen extends StatelessWidget {
  final bool isDarkMode;

  const FarmNetworkScreen({Key? key, this.isDarkMode = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SocialFeedScreen(isDarkMode: isDarkMode);
  }
}
