import 'package:flutter/material.dart';
import 'package:mbaymi/screens/search_users_screen.dart';

class SearchTab extends StatelessWidget {
  final bool isDarkMode;

  const SearchTab({
    Key? key,
    this.isDarkMode = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const SearchUsersScreen();
  }
}
