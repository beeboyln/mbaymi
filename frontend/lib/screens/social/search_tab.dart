import 'package:flutter/material.dart';
import 'package:mbaymi/screens/social/search_users_screen.dart';

class SearchTab extends StatelessWidget {
  final bool isDarkMode;

  const SearchTab({
    super.key,
    this.isDarkMode = false,
  });

  @override
  Widget build(BuildContext context) {
    return const SearchUsersScreen();
  }
}
