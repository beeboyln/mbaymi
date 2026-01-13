import 'package:flutter/material.dart';

/// 🛡️ Input Validation Service
/// Valide les entrées utilisateur avant les appels API
class ValidationService {
  /// Valider un email
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'email est requis';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Veuillez entrer un email valide';
    }
    return null;
  }

  /// Valider un mot de passe
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le mot de passe est requis';
    }
    if (value.length < 6) {
      return 'Le mot de passe doit contenir au moins 6 caractères';
    }
    return null;
  }

  /// Valider un champ requis
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName est requis';
    }
    return null;
  }

  /// Valider un nom de ferme
  static String? validateFarmName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Le nom de la ferme est requis';
    }
    if (value.length < 3) {
      return 'Le nom doit contenir au moins 3 caractères';
    }
    return null;
  }

  /// Valider un nombre positif
  static String? validatePositiveNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName est requis';
    }
    final number = int.tryParse(value);
    if (number == null || number <= 0) {
      return '$fieldName doit être un nombre positif';
    }
    return null;
  }

  /// Valider une URL
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return 'L\'URL est requise';
    }
    try {
      Uri.parse(value);
      return null;
    } catch (e) {
      return 'Veuillez entrer une URL valide';
    }
  }
}
