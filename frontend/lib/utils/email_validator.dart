import 'package:flutter/widgets.dart';
import 'package:mbaymi/utils/validators.dart' as core_validators;

/// Compatibility wrapper that provides `FormFieldValidator` getters.
class Validators {
  static FormFieldValidator<String>? get phone => core_validators.Validators.phone;
  static FormFieldValidator<String>? get email => core_validators.Validators.email;
  static FormFieldValidator<String>? get password => core_validators.Validators.password;

  /// Vérifie si un email est valide (regex standard)
  static bool isValidEmail(String email) {
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email.trim());
  }
}
