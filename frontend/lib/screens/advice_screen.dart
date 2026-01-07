import 'package:flutter/material.dart';
import 'package:mbaymi/widgets/empty_state.dart';

class AdviceTab extends StatelessWidget {
  final bool isDarkMode;
  
  const AdviceTab({Key? key, this.isDarkMode = false}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return buildEmptyState(
      icon: Icons.tips_and_updates_outlined,
      title: 'Conseils agricoles',
      description: 'Recevez des conseils adaptés à vos cultures',
      buttonLabel: 'Obtenir un conseil',
      color: const Color(0xFFE8A317),
      isDarkMode: isDarkMode,
    );
  }
}
