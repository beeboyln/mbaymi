// Minimal, clean validators implementation
class FormValidator {
  static String? validateEmail(String? v) {
    if (v == null || v.isEmpty) return 'L\'email est requis';
    final re = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return re.hasMatch(v.trim()) ? null : 'Email invalide';
  }

  static String? validatePhone(String? v) {
    if (v == null || v.isEmpty) return 'Le téléphone est requis';
    final cleaned = v.replaceAll(RegExp(r'\s|-'), '');
    return RegExp(r'^[+]?[0-9]{8,15}$').hasMatch(cleaned) ? null : 'Format téléphone invalide';
  }

  static String? validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Le mot de passe est requis';
    return v.length < 6 ? 'Minimum 6 caractères' : null;
  }

  static String? validateName(String? v) {
    if (v == null || v.isEmpty) return 'Le nom est requis';
    return v.trim().length < 2 ? 'Le nom doit faire au moins 2 caractères' : null;
  }

  static String? validateRegion(String? v) => (v == null || v.isEmpty) ? 'La région est requise' : null;
}

class Validators {
  static String? Function(String?) email = FormValidator.validateEmail;
  static String? Function(String?) phone = FormValidator.validatePhone;
  static String? Function(String?) password = FormValidator.validatePassword;
  static String? Function(String?) name = FormValidator.validateName;
  static String? Function(String?) region = FormValidator.validateRegion;
}
