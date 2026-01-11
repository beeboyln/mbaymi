/// Classe helper pour la validation des formulaires critiques
class FormValidator {
  /// Valide un email avec une regex stricte
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    
    // Regex email standard
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$'
    );
    
    if (!emailRegex.hasMatch(value)) {
      return 'Email invalide (ex: utilisateur@exemple.com)';
    }
    
    return null;
  }

  /// Valide un mot de passe fort
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    
    if (value.length < 6) {
      return 'Minimum 6 caractères';
    }
    
    // Options plus strictes:
    // - Au moins 1 majuscule: [A-Z]
    // - Au moins 1 minuscule: [a-z]
    // - Au moins 1 chiffre: [0-9]
    // Pour maintenant, on garde simple
    
    return null;
  }

  /// Valide la confirmation du mot de passe
  static String? validatePasswordConfirmation(String? value, String password) {
    if (value == null || value.isEmpty) {
      return 'Confirmez votre mot de passe';
    }
    
    if (value != password) {
      return 'Les mots de passe ne correspondent pas';
    }
    
    return null;
  }

  /// Valide un nom (non vide et au moins 2 caractères)
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom est requis';
    }
    
    if (value.trim().length < 2) {
      return 'Le nom doit faire au moins 2 caractères';
    }
    
    return null;
  }

  /// Valide un numéro de téléphone
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le téléphone est requis';
    }
    
    // Accepter 9-15 chiffres (format international)
    final phoneRegex = RegExp(r'^[+]?[0-9]{9,15}$');
    
    if (!phoneRegex.hasMatch(value.replaceAll(' ', '').replaceAll('-', ''))) {
      return 'Format téléphone invalide';
    }
    
    return null;
  }

  /// Valide une région (non vide)
  static String? validateRegion(String? value) {
    if (value == null || value.isEmpty) {
      return 'La région est requise';
    }
    
    return null;
  }

  /// Valide un nom de ferme
  static String? validateFarmName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom de ferme est requis';
    }
    
    if (value.trim().length < 2) {
      return 'Le nom doit faire au moins 2 caractères';
    }
    
    return null;
  }

  /// Valide une superficie en hectares
  static String? validateSize(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optionnel
    }
    
    final size = double.tryParse(value);
    if (size == null) {
      return 'Entrez un nombre valide';
    }
    
    if (size <= 0) {
      return 'La superficie doit être positive';
    }
    
    if (size > 10000) {
      return 'Vérifiez la superficie (max 10000 ha)';
    }
    
    return null;
  }

  /// Valide une URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // Optionnel
    }
    
    try {
      Uri.parse(value);
      if (!value.startsWith('http://') && !value.startsWith('https://')) {
        return 'L\'URL doit commencer par http:// ou https://';
      }
      return null;
    } catch (e) {
      return 'URL invalide';
    }
  }

  /// Valide une description
  static String? validateDescription(String? value, {int minLength = 0, int maxLength = 5000}) {
    if (value == null || value.isEmpty) {
      if (minLength > 0) {
        return 'La description est requise';
      }
      return null;
    }
    
    if (value.length < minLength) {
      return 'Minimum $minLength caractères';
    }
    
    if (value.length > maxLength) {
      return 'Maximum $maxLength caractères';
    }
    
    return null;
  }
}

/// Classe helper pour afficher les messages d'erreur user-friendly
class ErrorMessages {
  /// Traduit les codes d'erreur en messages français sécurisés
  /// NE JAMAIS afficher les détails du backend ou les erreurs brutes
  static String getHumanReadableError(dynamic error) {
    final errorString = error.toString().toUpperCase();
    
    // ====== Messages spécifiques à la BASE DE DONNÉES ======
    if (errorString.contains('DUPLICATE') && errorString.contains('PHONE')) {
      return 'Ce numéro de téléphone est déjà utilisé.';
    }
    
    if (errorString.contains('UNIQUE') && errorString.contains('PHONE')) {
      return 'Ce numéro de téléphone est déjà utilisé.';
    }
    
    if (errorString.contains('DUPLICATE') && errorString.contains('EMAIL')) {
      return 'Cet email est déjà utilisé.';
    }
    
    if (errorString.contains('UNIQUE') && errorString.contains('EMAIL')) {
      return 'Cet email est déjà utilisé.';
    }
    
    if (errorString.contains('UNIQUE') || errorString.contains('DUPLICATE')) {
      return 'Cette ressource existe déjà.';
    }
    
    // ====== Messages de VALIDATION EMAIL ======
    if (errorString.contains('NOT A VALID EMAIL') || 
        errorString.contains('INVALID EMAIL') ||
        errorString.contains('PART AFTER THE @-SIGN')) {
      return 'Veuillez entrer une adresse email valide (ex: user@example.com).';
    }
    
    // ====== Messages LOGIN/INSCRIPTION spécifiques ======
    if (errorString.contains('INVALID_CREDENTIALS')) {
      return 'Email ou mot de passe incorrect.';
    }
    
    if (errorString.contains('EMAIL_EXISTS')) {
      return 'Cet email est déjà utilisé.';
    }
    
    if (errorString.contains('INVALID_REQUEST')) {
      return 'Les informations fournies sont invalides.';
    }
    
    if (errorString.contains('INVALID_REGISTRATION')) {
      return 'Les informations d\'inscription sont invalides.';
    }
    
    if (errorString.contains('REGISTRATION_FAILED')) {
      return 'L\'inscription a échoué. Réessayez plus tard.';
    }
    
    if (errorString.contains('LOGIN_FAILED')) {
      return 'La connexion a échoué. Réessayez plus tard.';
    }
    
    // ====== Messages CONNEXION RÉSEAU ======
    if (errorString.contains('TIMEOUT') || errorString.contains('TIMEOUTEXCEPTION')) {
      return 'Connexion lente. Vérifiez votre Internet et réessayez.';
    }
    
    if (errorString.contains('SOCKETEXCEPTION') || 
        errorString.contains('CONNECTION_ERROR') ||
        errorString.contains('NO ADDRESS') ||
        errorString.contains('FAILED TO CONNECT') ||
        errorString.contains('NETWORK')) {
      return 'Vérifiez votre connexion Internet et réessayez.';
    }
    
    // ====== Messages HTTP statuts ======
    if (errorString.contains('401') || errorString.contains('UNAUTHORIZED')) {
      return 'Session expirée. Reconnectez-vous.';
    }
    
    if (errorString.contains('403') || errorString.contains('FORBIDDEN')) {
      return 'Vous n\'avez pas accès à cette action.';
    }
    
    if (errorString.contains('404') || errorString.contains('NOT FOUND')) {
      return 'La ressource demandée n\'existe pas.';
    }
    
    if (errorString.contains('500') || errorString.contains('INTERNAL SERVER')) {
      return 'Erreur serveur. Réessayez plus tard.';
    }
    
    if (errorString.contains('503') || errorString.contains('UNAVAILABLE')) {
      return 'Le serveur est temporairement indisponible. Réessayez plus tard.';
    }
    
    // ====== Message par défaut - JAMAIS afficher l'erreur brute ======
    return 'Une erreur s\'est produite. Réessayez plus tard.';
  }}
