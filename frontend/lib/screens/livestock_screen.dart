import 'package:flutter/material.dart';
import 'package:mbaymi/widgets/empty_state.dart';

class LivestockTab extends StatelessWidget {
  final bool isDarkMode;
  
  const LivestockTab({Key? key, this.isDarkMode = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildEmptyState(
      icon: Icons.pets_outlined,
      title: 'Gestion du bétail',
      description: 'Suivez la santé de vos animaux',
      buttonLabel: 'Ajouter du bétail',
      color: const Color(0xFFD2691E),
      isDarkMode: isDarkMode,
    );
  }
}
