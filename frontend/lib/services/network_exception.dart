/// Exceptions réseau personnalisées pour meilleure gestion des erreurs
abstract class NetworkException implements Exception {
  final String message;
  final int? statusCode;
  
  NetworkException({required this.message, this.statusCode});
  
  @override
  String toString() => message;
}

/// Erreur de timeout (pas de réponse dans le délai imparti)
class TimeoutException extends NetworkException {
  TimeoutException({
    super.message = 'La requête a pris trop de temps. Vérifiez votre connexion.',
  });
}

/// Erreur de connexion (pas de réseau)
class ConnectionException extends NetworkException {
  ConnectionException({
    super.message = 'Pas de connexion Internet. Vérifiez votre réseau.',
  });
}

/// Erreur 404 - Ressource non trouvée
class NotFoundException extends NetworkException {
  NotFoundException({
    super.message = 'La ressource demandée n\'existe pas.',
    int? statusCode,
  }) : super(statusCode: statusCode ?? 404);
}

/// Erreur 401/403 - Non autorisé
class UnauthorizedException extends NetworkException {
  UnauthorizedException({
    super.message = 'Vous n\'êtes pas autorisé. Reconnectez-vous.',
    int? statusCode,
  }) : super(statusCode: statusCode ?? 401);
}

/// Erreur 500+ - Erreur serveur
class ServerException extends NetworkException {
  ServerException({
    super.message = 'Erreur serveur. Réessayez plus tard.',
    int? statusCode,
  }) : super(statusCode: statusCode ?? 500);
}

/// Erreur générique
class BadRequestException extends NetworkException {
  BadRequestException({
    super.message = 'Requête invalide.',
    int? statusCode,
  }) : super(statusCode: statusCode ?? 400);
}

/// Classe helper pour convertir les erreurs HTTP en exceptions personnalisées
class NetworkExceptionHandler {
  static NetworkException handleError({
    required dynamic error,
    int? statusCode,
  }) {
    if (error is TimeoutException) {
      return error;
    }
    
    if (error is ConnectionException) {
      return error;
    }

    // Erreurs de timeout
    if (error.toString().contains('timeout') || 
        error.toString().contains('TimeoutException')) {
      return TimeoutException();
    }

    // Erreurs de connexion
    if (error.toString().contains('SocketException') ||
        error.toString().contains('No address associated') ||
        error.toString().contains('Failed to connect')) {
      return ConnectionException();
    }

    // Erreurs HTTP
    if (statusCode != null) {
      if (statusCode == 404) {
        return NotFoundException();
      } else if (statusCode == 401 || statusCode == 403) {
        return UnauthorizedException();
      } else if (statusCode >= 500) {
        return ServerException();
      } else if (statusCode == 400 || statusCode == 422) {
        return BadRequestException(
          message: error.toString(),
          statusCode: statusCode,
        );
      }
    }

    // Default case: return a generic bad request exception
    return BadRequestException(
      message: error.toString(),
      statusCode: statusCode,
    );
  }
}
