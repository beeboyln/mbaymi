import 'package:http/http.dart' as http;
import 'package:mbaymi/models/notification_model.dart';
import 'package:mbaymi/services/api_service.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/token_storage.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

/// 🔔 Service pour gérer les notifications
class NotificationService {
  /// Gérer les erreurs 401 (token expiré)
  /// Au lieu de forcer la déconnexion, on enregistre simplement l'erreur
  static Future<void> _handleUnauthorized() async {
    debugPrint('⚠️ 401 Unauthorized - Token may be expired');
    // NOTE: On ne déconnecte plus automatiquement ici
    // Le token sera régénéré au prochain appel d'API via le refresh mechanism
    // ou l'utilisateur se reconnectera au prochain besoin d'authentification
  }

  /// Récupérer les notifications de l'utilisateur
  /// 
  /// ⚠️ GUARD: Raises exception if user is not authenticated
  /// This prevents accidental requests or loops with restoreSession()
  static Future<List<NotificationModel>> getNotifications({
    int skip = 0,
    int limit = 20,
  }) async {
    try {
      // GUARD: Strict check - do NOT restore session here
      final userId = AuthService.currentSession?.userId;
      if (userId == null) {
        throw Exception('User not authenticated - cannot fetch notifications');
      }

      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('No access token available - session is invalid');
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/users/$userId/notifications?skip=$skip&limit=$limit',
      );

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(
        const Duration(seconds: 30),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final List<dynamic> notificationsJson = data['notifications'] ?? [];
        
        return notificationsJson
            .map((n) => NotificationModel.fromJson(n as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 401) {
        await _handleUnauthorized();
        throw Exception('Unauthorized - Token expired');
      } else {
        throw Exception('Failed to load notifications: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ NotificationService.getNotifications error: $e');
      rethrow;
    }
  }

  /// Marquer une notification comme lue
  static Future<void> markAsRead(int notificationId) async {
    try {
      final userId = AuthService.currentSession?.userId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('No access token available');
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/users/$userId/notifications/$notificationId/read',
      );

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 401) {
        await _handleUnauthorized();
        throw Exception('Unauthorized - Token expired');
      } else if (response.statusCode != 200) {
        throw Exception('Failed to mark notification as read');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Marquer toutes les notifications comme lues
  static Future<void> markAllAsRead() async {
    try {
      final userId = AuthService.currentSession?.userId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('No access token available');
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/users/$userId/notifications/read-all',
      );

      final response = await http.put(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 401) {
        await _handleUnauthorized();
        throw Exception('Unauthorized - Token expired');
      } else if (response.statusCode != 200) {
        throw Exception('Failed to mark all notifications as read');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Supprimer une notification
  static Future<void> deleteNotification(int notificationId) async {
    try {
      final userId = AuthService.currentSession?.userId;
      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        throw Exception('No access token available');
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/users/$userId/notifications/$notificationId',
      );

      final response = await http.delete(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 401) {
        await _handleUnauthorized();
        throw Exception('Unauthorized - Token expired');
      } else if (response.statusCode != 200) {
        throw Exception('Failed to delete notification');
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Compter les notifications non lues
  /// 
  /// ⚠️ GUARD: Returns 0 silently if user is not authenticated
  /// Does NOT restore session (prevents loops)
  /// 
  /// Idéal pour widget de badge (ne doit pas bloquer ou crasher)
  static Future<int> getUnreadCount() async {
    try {
      // GUARD: Strict check - no restore here
      final userId = AuthService.currentSession?.userId;
      if (userId == null) {
        // Silent return - user is not logged in
        debugPrint('ℹ️ getUnreadCount: User not authenticated, returning 0');
        return 0;
      }

      final token = await TokenStorage.getAccessToken();
      if (token == null) {
        debugPrint('ℹ️ getUnreadCount: No token available, returning 0');
        return 0;
      }

      final url = Uri.parse(
        '${ApiService.baseUrl}/users/$userId/notifications/unread-count',
      );

      final headers = {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      };

      final response = await http.get(
        url,
        headers: headers,
      ).timeout(
        const Duration(seconds: 15),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        final count = data['unread_count'] as int? ?? 0;
        return count;
      } else if (response.statusCode == 401) {
        await _handleUnauthorized();
        return 0;
      } else {
        // Any other error - return 0 (UI keeps running)
        debugPrint('⚠️ getUnreadCount failed: status ${response.statusCode}');
        return 0;
      }
    } catch (e) {
      debugPrint('⚠️ NotificationService.getUnreadCount error (returning 0): $e');
      return 0;
    }
  }
}
