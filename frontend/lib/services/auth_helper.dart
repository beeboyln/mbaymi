import 'package:flutter/material.dart';
import 'package:mbaymi/services/auth_service.dart';

/// Helper to check if user is authenticated before protected actions.
/// If not authenticated, shows a dialog and navigates to login.
/// Returns true if authenticated, false otherwise.
Future<bool> requireAuth(BuildContext context, String actionName) async {
  if (AuthService.isAuthenticated) {
    return true; // User is authenticated
  }

  // Show dialog explaining why login is needed
  if (!context.mounted) return false;
  
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Connexion requise'),
      content: Text(
        'Vous devez vous connecter pour $actionName.',
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Annuler'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          child: const Text('Se connecter'),
        ),
      ],
    ),
  ) ?? false;

  if (confirmed && context.mounted) {
    // Navigate to login screen
    await Navigator.of(context).pushNamed('/login');
  }

  return false; // User cancelled or login incomplete
}
