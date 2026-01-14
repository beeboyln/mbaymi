import 'package:flutter/material.dart';
import 'dart:async';
import 'package:mbaymi/utils/app_logger.dart';

/// 🚨 Types d'erreurs réseau
enum NetworkErrorType {
  timeout,
  connectionFailed,
  serverError,
  notFound,
  unauthorized,
  forbidden,
  badRequest,
  unknown,
}

/// 📱 Gestion centralisée des erreurs réseau
class NetworkErrorHandler {
  /// 🎯 Convertir un exception HTTP en message utilisateur
  static String getErrorMessage(dynamic error, {String? fallback}) {
    AppLogger.error('Network error caught', error);
    
    final message = fallback ?? 'Une erreur est survenue. Veuillez réessayer.';
    
    if (error is TimeoutException) {
      return 'Délai d\'attente dépassé. Vérifiez votre connexion.';
    }
    
    final errorStr = error.toString().toLowerCase();
    
    if (errorStr.contains('socket') || errorStr.contains('connection')) {
      return 'Impossible de se connecter au serveur.';
    }
    
    if (errorStr.contains('timeout')) {
      return 'Le serveur met trop de temps à répondre.';
    }
    
    return message;
  }
  
  /// 🎨 Afficher un snackbar d'erreur
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFE74C3C),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  /// ✅ Afficher un snackbar de succès
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 2),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF27AE60),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  /// ⚠️ Afficher un snackbar d'avertissement
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber, color: Color(0xFF1A1A1A), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Color(0xFF1A1A1A)),
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFFF39C12),
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
  
  /// Identifierle type d'erreur HTTP
  static NetworkErrorType getErrorType(int? statusCode) {
    if (statusCode == null) return NetworkErrorType.unknown;
    
    switch (statusCode) {
      case 400:
        return NetworkErrorType.badRequest;
      case 401:
        return NetworkErrorType.unauthorized;
      case 403:
        return NetworkErrorType.forbidden;
      case 404:
        return NetworkErrorType.notFound;
      case 500:
      case 502:
      case 503:
        return NetworkErrorType.serverError;
      default:
        return NetworkErrorType.unknown;
    }
  }
}
