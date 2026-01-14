import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/models/market_model.dart';
import 'package:mbaymi/models/news_model.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/token_storage.dart';
import 'package:mbaymi/services/simple_cache.dart';
import 'package:mbaymi/services/connectivity_service.dart';
import 'package:mbaymi/services/network_exception.dart';
import 'dart:async' as _async_for_api;

class ApiService {
  // 🔄 Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialDelay = Duration(milliseconds: 500);
  static const Duration _requestTimeout = Duration(seconds: 15);

  // 💾 Cache simple pour les GET
  static final _getCache = SimpleCache<dynamic>(ttl: Duration(minutes: 5));
  
  // 📡 Service de connectivité
  static final ConnectivityService _connectivity = ConnectivityService();

  // 🔔 Stream pour notifier la création d'un farm post afin que l'UI puisse se rafraîchir
  static final _async_for_api.StreamController<void> _farmPostController = _async_for_api.StreamController<void>.broadcast();
  static Stream<void> get onFarmPostCreated => _farmPostController.stream;
  static void notifyFarmPostCreated() => _farmPostController.add(null);

  /// 🔄 Retry helper with exponential backoff et timeout global
  /// Handles transient network errors (timeouts, connection issues)
  static Future<T> _withRetry<T>(
    Future<T> Function() fn, {
    int maxRetries = _maxRetries,
  }) async {
    int attempt = 0;
    Duration delay = _initialDelay;

    while (true) {
      try {
        attempt++;
        final result = await fn().timeout(_requestTimeout);
        // Succès - enregistrer la connexion
        _connectivity.recordConnectionSuccess();
        return result;
      } on TimeoutException {
        _connectivity.recordConnectionError();
        if (attempt >= maxRetries) {
          debugPrint('❌ Request timeout after $maxRetries attempts');
          rethrow;
        }
        debugPrint('⚠️ Timeout attempt $attempt, retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
        delay = Duration(milliseconds: delay.inMilliseconds * 2);
      } on ConnectionException {
        _connectivity.recordConnectionError();
        if (attempt >= maxRetries) {
          debugPrint('❌ Connection error after $maxRetries attempts');
          rethrow;
        }
        debugPrint('⚠️ Connection error attempt $attempt, retrying...');
        await Future.delayed(delay);
        delay = Duration(milliseconds: delay.inMilliseconds * 2);
      } catch (e) {
        _connectivity.recordConnectionError();
        if (attempt >= maxRetries) {
          debugPrint('❌ Request failed after $maxRetries attempts: $e');
          rethrow;
        }
        debugPrint('⚠️ Attempt $attempt failed, retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
        delay = Duration(milliseconds: delay.inMilliseconds * 2);
      }
    }
  }

  /// Helper: Invalider le cache d'une clé
  static void invalidateCache(String cacheKey) {
    _getCache.remove(cacheKey);
    debugPrint('🔄 Invalidated cache for $cacheKey');
  }

  /// Helper: Vider tout le cache
  static void clearCache() {
    _getCache.clear();
    debugPrint('🔄 Cleared all cache');
  }

  /// Logout user and clear all session data + cache
  static Future<void> logout() async {
    await AuthService.logout();
    clearCache();
    debugPrint('🚪 Full logout completed: session and cache cleared');
  }

  // For local development on Windows/Web: use localhost
  // For Android Emulator: use 'http://10.0.2.2:8000/api'
  // Read from .env (API_BASE_URL) if provided; otherwise use production URL
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'https://cuddly-lil-bigboyllmnd-9965fc8f.koyeb.app/api';

  /// Helper: Get auth headers with access token.
  static Future<Map<String, String>> _getAuthHeaders() async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    final accessToken = await TokenStorage.getAccessToken();
    if (accessToken != null && accessToken.isNotEmpty) {
      headers['Authorization'] = 'Bearer $accessToken';
    }
    return headers;
  }

  /// Helper: Handle 401 by refreshing token and retrying request.
  static Future<http.Response> _handleUnauthorized(
    Future<http.Response> Function(Map<String, String>) requestFn,
  ) async {
    debugPrint('⚠️ Got 401, attempting token refresh...');
    final refreshToken = await TokenStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      // No refresh token, user must log in again
      await AuthService.logout();
      throw Exception('Session expired. Please log in again.');
    }

    try {
      // Call refresh endpoint
      final refreshResponse = await http.post(
        Uri.parse('$baseUrl/auth/refresh'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh_token': refreshToken}),
      );

      if (refreshResponse.statusCode == 200) {
        final refreshData = jsonDecode(refreshResponse.body);
        final newAccessToken = refreshData['access_token'] as String?;
        if (newAccessToken != null && newAccessToken.isNotEmpty) {
          // Save new access token
          await TokenStorage.saveTokens(
            accessToken: newAccessToken,
            refreshToken: refreshToken,
            userId: AuthService.currentSession?.userId ?? 0,
            userEmail: AuthService.currentSession?.email ?? '',
          );
          debugPrint('✅ Token refreshed successfully');
          
          // Retry original request with new token
          final headers = await _getAuthHeaders();
          return await requestFn(headers);
        }
      }
      // Refresh failed
      await AuthService.logout();
      throw Exception('Failed to refresh session. Please log in again.');
    } catch (e) {
      debugPrint('❌ Token refresh error: $e');
      await AuthService.logout();
      rethrow;
    }
  }


  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String phone,
    required String password,
    required String role,
    required String region,
    String? village,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'email': email,
          'phone': phone,
          'password': password,
          'role': role,
          'region': region,
          'village': village,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 400) {
        throw Exception('INVALID_REGISTRATION');
      } else if (response.statusCode == 409) {
        throw Exception('EMAIL_EXISTS');
      } else {
        throw Exception('REGISTRATION_FAILED');
      }
    } catch (e) {
      if (e.toString().contains('INVALID_REGISTRATION') ||
          e.toString().contains('EMAIL_EXISTS') ||
          e.toString().contains('REGISTRATION_FAILED')) {
        rethrow;
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('INVALID_CREDENTIALS');
      } else if (response.statusCode == 400) {
        throw Exception('INVALID_REQUEST');
      } else {
        throw Exception('LOGIN_FAILED');
      }
    } catch (e) {
      if (e.toString().contains('INVALID_CREDENTIALS') ||
          e.toString().contains('INVALID_REQUEST') ||
          e.toString().contains('LOGIN_FAILED')) {
        rethrow;
      }
      throw Exception('CONNECTION_ERROR');
    }
  }

  // Farm endpoints
  static Future<Map<String, dynamic>> createFarm({
    required int userId,
    required String name,
    required String location,
    double? sizeHectares,
    String? soilType,
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/farms/?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'location': location,
          'size_hectares': sizeHectares,
          'soil_type': soilType,
          'image_url': imageUrl,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create farm: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating farm: $e');
    }
  }

  static Future<void> addFarmPhoto({
    required int farmId,
    required String imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/farms/$farmId/photos'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_url': imageUrl}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to add farm photo: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding farm photo: $e');
    }
  }

  static Future<void> addCropPhoto({
    required int cropId,
    required String imageUrl,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/crops/$cropId/photo'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'image_url': imageUrl}),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to add crop photo: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding crop photo: $e');
    }
  }

  static Future<List<dynamic>> getFarmPhotos(int farmId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/farms/$farmId/photos'));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      } else {
        throw Exception('Failed to get farm photos');
      }
    } catch (e) {
      throw Exception('Error getting farm photos: $e');
    }
  }

  static Future<void> deleteFarmPhoto({
    required int farmId,
    required int photoId,
  }) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/farms/$farmId/photos/$photoId'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete farm photo: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting farm photo: $e');
    }
  }

  static Future<void> deleteFarmProfilePhoto({
    required int farmId,
  }) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/farms/$farmId/profile'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete farm profile photo: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting farm profile photo: $e');
    }
  }

  static Future<Map<String, dynamic>> updateFarm({
    required int farmId,
    required String name,
    required String location,
    double? sizeHectares,
    String? soilType,
    String? imageUrl,
    double? latitude,
    double? longitude,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/farms/$farmId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name,
          'location': location,
          'size_hectares': sizeHectares,
          'soil_type': soilType,
          'image_url': imageUrl,
          'latitude': latitude,
          'longitude': longitude,
        }),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update farm: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating farm: $e');
    }
  }

  static Future<void> deleteFarm(int farmId) async {
    try {
      final response = await http.delete(Uri.parse('$baseUrl/farms/$farmId'));
      if (response.statusCode != 200) {
        throw Exception('Failed to delete farm: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting farm: $e');
    }
  }

  // Upload image to Cloudinary (requires CLOUDINARY_CLOUD_NAME and UPLOAD_PRESET)
  static Future<String?> uploadImageToCloudinary(XFile file) async {
    try {
      // Read Cloudinary config from environment
      final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME'] ?? '';
      final uploadPreset = dotenv.env['CLOUDINARY_UPLOAD_PRESET'] ?? '';
      final folder = dotenv.env['CLOUDINARY_FOLDER'] ?? 'mbaymi';
      if (cloudName.isEmpty || uploadPreset.isEmpty) {
        throw Exception('Cloudinary configuration missing. Set CLOUDINARY_CLOUD_NAME and CLOUDINARY_UPLOAD_PRESET in .env');
      }
      final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      // Put images under configured folder in Cloudinary
      request.fields['folder'] = folder;

      // Read bytes from the XFile (works on Web and mobile)
      final bytes = await file.readAsBytes();
      final multipartFile = http.MultipartFile.fromBytes('file', bytes, filename: file.name);
      request.files.add(multipartFile);

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        return data['secure_url'] as String?;
      } else {
        final body = resp.body;
        throw Exception('Cloudinary upload failed: ${resp.statusCode} ${body}');
      }
    } catch (e) {
      throw Exception('Image upload error: $e');
    }
  }

  // Crops / Parcels endpoints
  static Future<Map<String, dynamic>> addCrop({
    required int farmId,
    required String cropName,
    DateTime? plantedDate,
    DateTime? expectedHarvestDate,
    double? quantityPlanted,
    double? expectedYield,
    String status = 'growing',
    String? notes,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/farms/$farmId/crops'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'crop_name': cropName,
          'planted_date': plantedDate?.toIso8601String(),
          'expected_harvest_date': expectedHarvestDate?.toIso8601String(),
          'quantity_planted': quantityPlanted,
          'expected_yield': expectedYield,
          'status': status,
          'notes': notes,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add crop: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding crop: $e');
    }
  }

  static Future<List<dynamic>> getFarmCrops(int farmId) async {
    try {
      return await _withRetry(() async {
        final headers = await _getAuthHeaders();
        var response = await http.get(
          Uri.parse('$baseUrl/farms/$farmId/crops'),
          headers: headers,
        );

        // Handle 401 with token refresh and retry
        if (response.statusCode == 401) {
          response = await _handleUnauthorized((newHeaders) async {
            return await http.get(
              Uri.parse('$baseUrl/farms/$farmId/crops'),
              headers: newHeaders,
            );
          });
        }

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as List;
        } else {
          throw Exception('Failed to get farm crops: ${response.statusCode}');
        }
      });
    } catch (e) {
      throw Exception('Error getting farm crops: $e');
    }
  }

  // Activities
  static Future<Map<String, dynamic>> createActivity({
    required int farmId,
    int? cropId,
    int? userId,
    required String activityType,
    DateTime? activityDate,
    String? notes,
    List<String>? imageUrls,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/activities/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'farm_id': farmId,
          'crop_id': cropId,
          'user_id': userId,
          'activity_type': activityType,
          'activity_date': activityDate?.toIso8601String(),
          'notes': notes,
          'image_urls': imageUrls,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create activity: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating activity: $e');
    }
  }

  static Future<List<dynamic>> getActivitiesForFarm(int farmId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/activities/farm/$farmId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      } else {
        throw Exception('Failed to get activities');
      }
    } catch (e) {
      throw Exception('Error getting activities: $e');
    }
  }

  static Future<List<dynamic>> getActivitiesForCrop(int cropId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/activities/crop/$cropId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      } else {
        throw Exception('Failed to get activities for crop');
      }
    } catch (e) {
      throw Exception('Error getting activities for crop: $e');
    }
  }

  static Future<Map<String, dynamic>> updateActivity({
    required int activityId,
    required int farmId,
    int? cropId,
    required String activityType,
    DateTime? activityDate,
    String? notes,
    List<String>? imageUrls,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/activities/$activityId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'farm_id': farmId,
          'crop_id': cropId,
          'activity_type': activityType,
          'activity_date': activityDate?.toIso8601String(),
          'notes': notes,
          'image_urls': imageUrls,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update activity: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating activity: $e');
    }
  }

  static Future<void> deleteActivity(int activityId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/activities/$activityId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete activity: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting activity: $e');
    }
  }

  // Harvests
  static Future<List<dynamic>> getHarvestsForFarm(int farmId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/harvests/farm/$farmId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      } else {
        throw Exception('Failed to get harvests for farm');
      }
    } catch (e) {
      throw Exception('Error getting harvests: $e');
    }
  }

  // Sales
  static Future<List<dynamic>> getSalesByUser(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sales/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      } else {
        throw Exception('Failed to get sales for user');
      }
    } catch (e) {
      throw Exception('Error getting sales: $e');
    }
  }

  static Future<List<dynamic>> getAllSales({int limit = 100}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sales/'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      } else {
        throw Exception('Failed to get sales');
      }
    } catch (e) {
      throw Exception('Error getting sales: $e');
    }
  }

  static Future<Map<String, dynamic>> createSale(Map<String, dynamic> saleData) async {
    try {
      final token = await TokenStorage.getAccessToken();
      final userId = AuthService.currentSession?.userId;

      if (userId == null) {
        throw Exception('User not authenticated');
      }

      final response = await http.post(
        Uri.parse('$baseUrl/sales/'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          ...saleData,
          'user_id': userId,
        }),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        notifyFarmPostCreated(); // Notify to refresh marketplace
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create sale: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating sale: $e');
    }
  }

  static Future<Map<String, dynamic>> getSale(int saleId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/sales/$saleId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to get sale');
      }
    } catch (e) {
      throw Exception('Error getting sale: $e');
    }
  }

  static Future<Map<String, dynamic>> updateSale(int saleId, Map<String, dynamic> saleData) async {
    try {
      final token = await TokenStorage.getAccessToken();

      final response = await http.put(
        Uri.parse('$baseUrl/sales/$saleId'),
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(saleData),
      );

      if (response.statusCode == 200) {
        notifyFarmPostCreated();
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update sale');
      }
    } catch (e) {
      throw Exception('Error updating sale: $e');
    }
  }

  static Future<void> deleteSale(int saleId) async {
    try {
      final token = await TokenStorage.getAccessToken();

      final response = await http.delete(
        Uri.parse('$baseUrl/sales/$saleId'),
        headers: {
          if (token != null) 'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete sale');
      }
      notifyFarmPostCreated();
    } catch (e) {
      throw Exception('Error deleting sale: $e');
    }
  }

  static Future<Map<String, dynamic>> getFarm(int farmId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/farms/$farmId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get farm');
      }
    } catch (e) {
      throw Exception('Error getting farm: $e');
    }
  }

  static Future<List<dynamic>> getUserFarms(int userId) async {
    try {
      return await _withRetry(() async {
        final response = await http.get(
          Uri.parse('$baseUrl/farms/user/$userId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          return jsonDecode(response.body) as List;
        } else {
          throw Exception('Failed to get farms');
        }
      });
    } catch (e) {
      throw Exception('Error getting farms: $e');
    }
  }

  // Livestock endpoints
  static Future<Map<String, dynamic>> addLivestock({
    required int userId,
    required String animalType,
    String? breed,
    int quantity = 1,
    int? ageMonths,
    double? weightKg,
    String? healthStatus,
    String? feedingType,
    String? location,
    String? notes,
    String? imageUrl,
    String visibility = 'PRIVATE',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/livestock/?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'animal_type': animalType,
          'breed': breed,
          'quantity': quantity,
          'age_months': ageMonths,
          'weight_kg': weightKg,
          'health_status': healthStatus ?? 'healthy',
          'feeding_type': feedingType,
          'location': location,
          'notes': notes,
          'image_url': imageUrl,
          'visibility': visibility,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add livestock: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error adding livestock: $e');
    }
  }

  static Future<List<dynamic>> getUserLivestock(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/livestock/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      } else {
        throw Exception('Failed to get livestock');
      }
    } catch (e) {
      throw Exception('Error getting livestock: $e');
    }
  }

  // Alias for addLivestock
  static Future<Map<String, dynamic>> createLivestock({
    required int userId,
    required String animalType,
    String? breed,
    int? quantity,
    int? ageMonths,
    double? weightKg,
    String? healthStatus,
    String? feedingType,
    String? location,
    String? notes,
    String? imageUrl,
    String visibility = 'PRIVATE',
  }) =>
      addLivestock(
        userId: userId,
        animalType: animalType,
        breed: breed,
        quantity: quantity ?? 1,
        ageMonths: ageMonths,
        weightKg: weightKg,
        healthStatus: healthStatus,
        feedingType: feedingType,
        location: location,
        notes: notes,
        imageUrl: imageUrl,
        visibility: visibility,
      );

  static Future<Map<String, dynamic>> updateLivestock({
    required int livestockId,
    required String animalType,
    String? breed,
    int? quantity,
    int? ageMonths,
    double? weightKg,
    String? healthStatus,
    String? feedingType,
    String? location,
    String? notes,
    String? imageUrl,
    String? visibility,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/livestock/$livestockId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'animal_type': animalType,
          'breed': breed,
          'quantity': quantity,
          'age_months': ageMonths,
          'weight_kg': weightKg,
          'health_status': healthStatus,
          'feeding_type': feedingType,
          'location': location,
          'notes': notes,
          'image_url': imageUrl,
          'visibility': visibility,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update livestock: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error updating livestock: $e');
    }
  }

  static Future<void> deleteLivestock(int livestockId) async {
    try {
      final response = await http.delete(
        Uri.parse('$baseUrl/livestock/$livestockId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Failed to delete livestock: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting livestock: $e');
    }
  }

  static Future<List<dynamic>> getAllLivestockWithPhotos({int? userId}) async {
    try {
      final url = userId != null 
        ? '$baseUrl/livestock/public?user_id=$userId'
        : '$baseUrl/livestock/public';
        
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> allLivestock = jsonDecode(response.body) as List;
        
        // Charger les photos pour chaque animal
        final List<dynamic> livestockWithPhotos = [];
        for (var animal in allLivestock) {
          final livestockId = animal['id'] as int?;
          if (livestockId != null) {
            try {
              final photos = await getAnimalPhotos(livestockId);
              animal['photos'] = photos;
              livestockWithPhotos.add(animal);
            } catch (e) {
              // Si erreur photos, garder l'animal sans photos
              debugPrint('⚠️ Error fetching photos for livestock $livestockId: $e');
              animal['photos'] = [];
              livestockWithPhotos.add(animal);
            }
          }
        }
        
        return livestockWithPhotos;
      } else {
        throw Exception('Failed to get livestock: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Error getting livestock: $e');
      throw Exception('Error getting livestock: $e');
    }
  }

  // Market endpoints
  static Future<List<MarketPrice>> getMarketPrices() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/market/prices'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final List<dynamic> jsonList = jsonDecode(response.body) as List;
        return jsonList.map((item) => MarketPrice.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw Exception('Failed to get market prices');
      }
    } catch (e) {
      throw Exception('Error getting market prices: $e');
    }
  }

  static Future<List<dynamic>> getPricesByRegion(String region) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/market/prices/region/$region'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      } else {
        throw Exception('Failed to get prices for region');
      }
    } catch (e) {
      throw Exception('Error getting prices: $e');
    }
  }

  // Advice endpoints
  static Future<Map<String, dynamic>> getAdvice({
    required String type, // crop or livestock
    required String topic,
    String? region,
    String? context,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/advice/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': type,
          'topic': topic,
          'region': region,
          'context': context,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to get advice: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error getting advice: $e');
    }
  }

  // Get agricultural news from backend (which proxies Google News RSS)
  static Future<List<NewsArticle>> getAgriculturalNews() async {
    try {
      return await _withRetry(() async {
        final response = await http.get(
          Uri.parse('$baseUrl/news/agricultural'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final jsonData = jsonDecode(response.body);
          final List<dynamic> articles = jsonData['articles'] ?? [];
          
          return articles.map((item) {
            return NewsArticle(
              title: item['title'] ?? 'Actualité agricole',
              description: item['description'] ?? '',
              imageUrl: item['imageUrl'],
              pubDate: DateTime.parse(item['pubDate'] ?? DateTime.now().toIso8601String()),
              source: item['source'] ?? 'Source',
              category: item['category'] ?? 'Agriculture',
              link: item['link'],
            );
          }).toList();
        } else {
          throw Exception('Failed to load news: ${response.statusCode}');
        }
      });
    } catch (e) {
      // Retourner des actualités par défaut si la requête échoue
      return _getDefaultNews();
    }
  }

  // Actualités par défaut si la requête échoue
  static List<NewsArticle> _getDefaultNews() {
    final now = DateTime.now();
    return [
      NewsArticle(
        title: 'Alerte Météo',
        description: 'Pluie prévue ce weekend - Bonne nouvelle pour les cultures',
        pubDate: now.subtract(const Duration(hours: 2)),
        source: 'Météo',
        category: 'Météo',
      ),
      NewsArticle(
        title: 'Prix en hausse',
        description: 'Le maïs atteint 850 FCFA/kg - Plus haut en 30 jours',
        pubDate: now.subtract(const Duration(hours: 4)),
        source: 'Marché',
        category: 'Prix',
      ),
      NewsArticle(
        title: 'Alerte Ravageurs',
        description: 'Attention aux chenilles légionnaires dans votre région',
        pubDate: now.subtract(const Duration(hours: 6)),
        source: 'Alertes',
        category: 'Santé des cultures',
      ),
      NewsArticle(
        title: 'Conseil Irrigation',
        description: 'Augmentez l\'irrigation de 20% cette semaine',
        pubDate: now.subtract(const Duration(hours: 8)),
        source: 'Conseils',
        category: 'Technique',
      ),
      NewsArticle(
        title: 'Vaccin disponible',
        description: 'Nouveau vaccin pour le bétail arrivé - Réservez maintenant',
        pubDate: now.subtract(const Duration(days: 1)),
        source: 'Vétérinaire',
        category: 'Santé animale',
      ),
    ];
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🌾 CROP PROBLEMS (Maladies & Ravageurs)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> reportCropProblem({
    required int cropId,
    required int farmId,
    required int userId,
    required String problemType,
    String description = '',
    String? photoUrl,
    String severity = 'medium',
  }) async {
    try {
      return await _withRetry(() async {
        final headers = await _getAuthHeaders();
        final response = await http.post(
          Uri.parse('$baseUrl/crop-problems/'),
          headers: headers,
          body: jsonEncode({
            'crop_id': cropId,
            'farm_id': farmId,
            'user_id': userId,
            'problem_type': problemType,
            'description': description,
            'photo_url': photoUrl,
            'severity': severity,
          }),
        );

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          throw Exception('Failed to report problem: ${response.statusCode}');
        }
      });
    } catch (e) {
      throw Exception('Error reporting problem: $e');
    }
  }

  static Future<List<dynamic>> getCropProblems(int cropId) async {
    try {
      return await _withRetry(() async {
        final response = await http.get(
          Uri.parse('$baseUrl/crop-problems/crop/$cropId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['problems'] as List;
        } else {
          throw Exception('Failed to get problems');
        }
      });
    } catch (e) {
      throw Exception('Error getting problems: $e');
    }
  }

  static Future<List<dynamic>> getFarmProblems(int farmId) async {
    try {
      return await _withRetry(() async {
        final response = await http.get(
          Uri.parse('$baseUrl/crop-problems/farm/$farmId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['problems'] as List;
        } else {
          throw Exception('Failed to get farm problems');
        }
      });
    } catch (e) {
      throw Exception('Error getting farm problems: $e');
    }
  }

  static Future<void> updateProblemStatus({
    required int problemId,
    required String status,
    String? treatmentNotes,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.put(
        Uri.parse('$baseUrl/crop-problems/$problemId/status'),
        headers: headers,
        body: jsonEncode({
          'status': status,
          'treatment_notes': treatmentNotes,
        }),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to update problem status');
      }
    } catch (e) {
      throw Exception('Error updating problem: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 🌾 FARM NETWORK (Profils & Publications)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> createFarmProfile({
    required int farmId,
    required int userId,
    String description = '',
    String specialties = '',
    bool isPublic = true,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/farm-network/profiles/$farmId'),
        headers: headers,
        body: jsonEncode({
          'farm_id': farmId,
          'user_id': userId,
          'description': description,
          'specialties': specialties,
          'is_public': isPublic,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create profile');
      }
    } catch (e) {
      throw Exception('Error creating profile: $e');
    }
  }

  static Future<Map<String, dynamic>> getFarmProfile(int farmId) async {
    try {
      return await _withRetry(() async {
        final response = await http.get(
          Uri.parse('$baseUrl/farm-network/profiles/$farmId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          throw Exception('Failed to get profile');
        }
      });
    } catch (e) {
      throw Exception('Error getting profile: $e');
    }
  }

  static Future<List<dynamic>> searchFarmProfiles({
    String query = '',
    String? specialty,
  }) async {
    try {
      return await _withRetry(() async {
        String url = '$baseUrl/farm-network/profiles/search';
        final params = <String, String>{};
        if (query.isNotEmpty) params['q'] = query;
        if (specialty != null && specialty.isNotEmpty) params['specialty'] = specialty;

        final uri = params.isEmpty ? Uri.parse(url) : Uri.parse(url).replace(queryParameters: params);
        debugPrint('🔍 Searching profiles: ${uri.toString()}');
        
        final response = await http.get(
          uri,
          headers: {'Content-Type': 'application/json'},
        );
        debugPrint('📥 Search response: ${response.statusCode}');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['farms'] as List;
        } else {
          throw Exception('Failed to search profiles');
        }
      });
    } catch (e) {
      throw Exception('Error searching profiles: $e');
    }
  }

  // DEPRECATED: Old farm-network method removed - use new farm-posts endpoint below

  static Future<List<dynamic>> getFarmFeed(int userId) async {
    try {
      return await _withRetry(() async {
        final response = await http.get(
          Uri.parse('$baseUrl/farm-network/feed?user_id=$userId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['posts'] as List;
        } else {
          throw Exception('Failed to get feed');
        }
      });
    } catch (e) {
      throw Exception('Error getting feed: $e');
    }
  }

  static Future<void> followUser({required int userIdToFollow, required int userId}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/farm-network/follow-user/$userIdToFollow?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to follow user');
      }
    } catch (e) {
      throw Exception('Error following user: $e');
    }
  }

  static Future<void> unfollowUser({required int userIdToUnfollow, required int userId}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/farm-network/follow-user/$userIdToUnfollow?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to unfollow user');
      }
    } catch (e) {
      throw Exception('Error unfollowing user: $e');
    }
  }
  
  // DEPRECATED: Méthodes anciennes conservées pour compatibilité
  @deprecated
  static Future<void> followFarm({required int farmId, required int userId}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/farm-network/follow/$farmId?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to follow farm');
      }
    } catch (e) {
      throw Exception('Error following farm: $e');
    }
  }

  @deprecated
  static Future<void> unfollowFarm({required int farmId, required int userId}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/farm-network/follow/$farmId?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to unfollow farm');
      }
    } catch (e) {
      throw Exception('Error unfollowing farm: $e');
    }
  }

  static Future<List<dynamic>> getUserFollowing(int userId) async {
    try {
      return await _withRetry(() async {
        final response = await http.get(
          Uri.parse('$baseUrl/farm-network/following/$userId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['farms'] as List;
        } else {
          throw Exception('Failed to get following');
        }
      });
    } catch (e) {
      throw Exception('Error getting following: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // USER PROFILE (Profil personnel)
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<Map<String, dynamic>> getUserProfile(int userId, {int? viewerId}) async {
    try {
      return await _withRetry(() async {
        final uri = viewerId != null
            ? Uri.parse('$baseUrl/users/$userId/profile?viewer_id=$viewerId')
            : Uri.parse('$baseUrl/users/$userId/profile');
        final response = await http.get(
          uri,
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          return jsonDecode(response.body);
        } else {
          throw Exception('Failed to get profile');
        }
      });
    } catch (e) {
      throw Exception('Error getting profile: $e');
    }
  }

  static Future<List<dynamic>> getUserPosts(int userId, {int skip = 0, int limit = 20, int? viewerId}) async {
    try {
      return await _withRetry(() async {
        final uri = viewerId != null
            ? Uri.parse('$baseUrl/users/$userId/posts?skip=$skip&limit=$limit&viewer_id=$viewerId')
            : Uri.parse('$baseUrl/users/$userId/posts?skip=$skip&limit=$limit');
        final response = await http.get(
          uri,
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['posts'] as List;
        } else {
          throw Exception('Failed to get posts');
        }
      });
    } catch (e) {
      throw Exception('Error getting posts: $e');
    }
  }

  static Future<Map<String, dynamic>> toggleFarmVisibility({
    required int userId,
    required int farmId,
    required bool isPublic,
  }) async {
    try {
      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/farms/$farmId/visibility?is_public=$isPublic'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to toggle visibility');
      }
    } catch (e) {
      throw Exception('Error toggling visibility: $e');
    }
  }

  static Future<List<dynamic>> getPublicFarms({int skip = 0, int limit = 10}) async {
    try {
      return await _withRetry(() async {
        final response = await http.get(
          Uri.parse('$baseUrl/farm-network/public-farms?skip=$skip&limit=$limit'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return data['farms'] as List;
        } else {
          throw Exception('Failed to get public farms');
        }
      });
    } catch (e) {
      throw Exception('Error getting public farms: $e');
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required int userId,
    String? name,
    String? email,
    String? profileImage,
  }) async {
    try {
      final params = <String, String>{};
      if (name != null && name.isNotEmpty) params['name'] = name;
      if (email != null && email.isNotEmpty) params['email'] = email;
      if (profileImage != null && profileImage.isNotEmpty) params['profile_image'] = profileImage;

      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/profile').replace(
          queryParameters: params.isNotEmpty ? params : null,
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  // ========== PASTURE IMAGES ==========
  
  static Future<Map<String, dynamic>> addPastureImage({
    required int userId,
    required String imageUrl,
    String? title,
    String? description,
  }) async {
    return _withRetry(() async {
      final body = {
        'image_url': imageUrl,
        if (title != null && title.isNotEmpty) 'title': title,
        if (description != null && description.isNotEmpty) 'description': description,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/pasture/images?user_id=$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await TokenStorage.getAccessToken()}',
        },
        body: jsonEncode(body),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add pasture image: ${response.statusCode}');
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getPastureImages(int userId) async {
    return _withRetry(() async {
      final cacheKey = 'pasture_images_$userId';
      
      // Check cache first
      final cached = _getCache.get(cacheKey);
      if (cached != null) {
        return List<Map<String, dynamic>>.from(cached);
      }

      final response = await http.get(
        Uri.parse('$baseUrl/pasture/images/user/$userId'),
        headers: {'Authorization': 'Bearer ${await TokenStorage.getAccessToken()}'},
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final images = List<Map<String, dynamic>>.from(
          data.map((item) => Map<String, dynamic>.from(item as Map))
        );
        _getCache.set(cacheKey, images);
        return images;
      } else {
        throw Exception('Failed to fetch pasture images: ${response.statusCode}');
      }
    });
  }

  static Future<Map<String, dynamic>> updatePastureImage({
    required int imageId,
    required String imageUrl,
    String? title,
    String? description,
  }) async {
    return _withRetry(() async {
      final body = {
        'image_url': imageUrl,
        if (title != null && title.isNotEmpty) 'title': title,
        if (description != null && description.isNotEmpty) 'description': description,
      };

      final response = await http.put(
        Uri.parse('$baseUrl/pasture/images/$imageId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await TokenStorage.getAccessToken()}',
        },
        body: jsonEncode(body),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to update pasture image: ${response.statusCode}');
      }
    });
  }

  static Future<void> deletePastureImage(int imageId) async {
    return _withRetry(() async {
      final response = await http.delete(
        Uri.parse('$baseUrl/pasture/images/$imageId'),
        headers: {'Authorization': 'Bearer ${await TokenStorage.getAccessToken()}'},
      ).timeout(_requestTimeout);

      if (response.statusCode != 200) {
        throw Exception('Failed to delete pasture image: ${response.statusCode}');
      }
    });
  }

  // ========== ANIMAL PHOTOS ==========
  
  static Future<Map<String, dynamic>> addAnimalPhoto({
    required int livestockId,
    required String imageUrl,
    String? caption,
  }) async {
    return _withRetry(() async {
      final body = {
        'livestock_id': livestockId,
        'image_url': imageUrl,
        if (caption != null && caption.isNotEmpty) 'caption': caption,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/animal-photos/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await TokenStorage.getAccessToken()}',
        },
        body: jsonEncode(body),
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to add animal photo: ${response.statusCode}');
      }
    });
  }

  static Future<List<Map<String, dynamic>>> getAnimalPhotos(int livestockId) async {
    return _withRetry(() async {
      final cacheKey = 'animal_photos_$livestockId';
      
      // Check cache first
      final cached = _getCache.get(cacheKey);
      if (cached != null) {
        return List<Map<String, dynamic>>.from(cached);
      }

      final response = await http.get(
        Uri.parse('$baseUrl/animal-photos/livestock/$livestockId'),
        headers: {'Authorization': 'Bearer ${await TokenStorage.getAccessToken()}'},
      ).timeout(_requestTimeout);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List;
        final photos = List<Map<String, dynamic>>.from(
          data.map((item) => Map<String, dynamic>.from(item as Map))
        );
        _getCache.set(cacheKey, photos);
        return photos;
      } else {
        throw Exception('Failed to fetch animal photos: ${response.statusCode}');
      }
    });
  }

  static Future<void> deleteAnimalPhoto(int photoId) async {
    debugPrint('🗑️ Deleting animal photo with id: $photoId');
    return _withRetry(() async {
      final response = await http.delete(
        Uri.parse('$baseUrl/animal-photos/$photoId'),
        headers: {'Authorization': 'Bearer ${await TokenStorage.getAccessToken()}'},
      ).timeout(_requestTimeout);

      debugPrint('Delete response status: ${response.statusCode}');
      debugPrint('Delete response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to delete animal photo: ${response.statusCode}');
      }
      
      // Invalidate all animal photos cache since we don't know which livestock this belonged to
      _getCache.clear();
    });
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // SOCIAL INTERACTIONS - Likes, Comments, Shares
  // ═══════════════════════════════════════════════════════════════════════════

  static Future<void> likePost(int postId) async {
    try {
      return await _withRetry(() async {
        final headers = await _getAuthHeaders();
        final response = await http.post(
          Uri.parse('$baseUrl/farm-network/posts/$postId/like'),
          headers: headers,
        ).timeout(_requestTimeout);

        // Handle 401 by refreshing token
        if (response.statusCode == 401) {
          debugPrint('⚠️ 401 Unauthorized for like endpoint, refreshing token...');
          await _handleUnauthorized(
            (newHeaders) => http.post(
              Uri.parse('$baseUrl/farm-network/posts/$postId/like'),
              headers: newHeaders,
            ),
          );
          return;
        }

        if (response.statusCode != 200) {
          throw Exception('Failed to like post: ${response.statusCode}');
        }
      });
    } catch (e) {
      throw Exception('Error liking post: $e');
    }
  }

  static Future<void> unlikePost(int postId) async {
    try {
      return await _withRetry(() async {
        final headers = await _getAuthHeaders();
        final response = await http.delete(
          Uri.parse('$baseUrl/farm-network/posts/$postId/like'),
          headers: headers,
        ).timeout(_requestTimeout);

        // Handle 401 by refreshing token
        if (response.statusCode == 401) {
          debugPrint('⚠️ 401 Unauthorized for unlike endpoint, refreshing token...');
          await _handleUnauthorized(
            (newHeaders) => http.delete(
              Uri.parse('$baseUrl/farm-network/posts/$postId/like'),
              headers: newHeaders,
            ),
          );
          return;
        }

        if (response.statusCode != 200) {
          throw Exception('Failed to unlike post: ${response.statusCode}');
        }
      });
    } catch (e) {
      throw Exception('Error unliking post: $e');
    }
  }

  static Future<List<dynamic>> getNetworkPostComments(int postId) async {
    try {
      return await _withRetry(() async {
        final response = await http.get(
          Uri.parse('$baseUrl/farm-network/posts/$postId/comments'),
          headers: {'Content-Type': 'application/json'},
        ).timeout(_requestTimeout);

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          return (data['comments'] as List?) ?? [];
        } else {
          throw Exception('Failed to get comments');
        }
      });
    } catch (e) {
      throw Exception('Error getting comments: $e');
    }
  }

  static Future<void> commentOnPost({
    required int postId,
    required String content,
  }) async {
    try {
      return await _withRetry(() async {
        final headers = await _getAuthHeaders();
        final response = await http.post(
          Uri.parse('$baseUrl/farm-network/posts/$postId/comment'),
          headers: headers,
          body: jsonEncode({'content': content}),
        ).timeout(_requestTimeout);

        // Handle 401 by refreshing token
        if (response.statusCode == 401) {
          debugPrint('⚠️ 401 Unauthorized for comment endpoint, refreshing token...');
          await _handleUnauthorized(
            (newHeaders) => http.post(
              Uri.parse('$baseUrl/farm-network/posts/$postId/comment'),
              headers: newHeaders,
              body: jsonEncode({'content': content}),
            ),
          );
          return;
        }

        if (response.statusCode != 200 && response.statusCode != 201) {
          throw Exception('Failed to comment on post: ${response.statusCode}');
        }
      });
    } catch (e) {
      throw Exception('Error commenting on post: $e');
    }
  }

  static Future<void> sharePost(int postId) async {
    try {
      return await _withRetry(() async {
        final headers = await _getAuthHeaders();
        final response = await http.post(
          Uri.parse('$baseUrl/farm-network/posts/$postId/share'),
          headers: headers,
        ).timeout(_requestTimeout);

        // Handle 401 by refreshing token
        if (response.statusCode == 401) {
          debugPrint('⚠️ 401 Unauthorized for share endpoint, refreshing token...');
          await _handleUnauthorized(
            (newHeaders) => http.post(
              Uri.parse('$baseUrl/farm-network/posts/$postId/share'),
              headers: newHeaders,
            ),
          );
          return;
        }

        if (response.statusCode != 200) {
          throw Exception('Failed to share post: ${response.statusCode}');
        }
      });
    } catch (e) {
      throw Exception('Error sharing post: $e');
    }
  }

  // 🐾 Livestock (Animal) Social Interactions
  static Future<void> likeLivestock(int livestockId) async {
    try {
      return await _withRetry(() async {
        final headers = await _getAuthHeaders();
        final response = await http.post(
          Uri.parse('$baseUrl/farm-network/livestock/$livestockId/like'),
          headers: headers,
        ).timeout(_requestTimeout);

        // Handle 401 by refreshing token
        if (response.statusCode == 401) {
          debugPrint('⚠️ 401 Unauthorized for livestock like endpoint, refreshing token...');
          await _handleUnauthorized(
            (newHeaders) => http.post(
              Uri.parse('$baseUrl/farm-network/livestock/$livestockId/like'),
              headers: newHeaders,
            ),
          );
          return;
        }

        if (response.statusCode != 200) {
          throw Exception('Failed to like livestock: ${response.statusCode}');
        }
      });
    } catch (e) {
      throw Exception('Error liking livestock: $e');
    }
  }

  static Future<void> unlikeLivestock(int livestockId) async {
    try {
      return await _withRetry(() async {
        final headers = await _getAuthHeaders();
        final response = await http.delete(
          Uri.parse('$baseUrl/farm-network/livestock/$livestockId/like'),
          headers: headers,
        ).timeout(_requestTimeout);

        // Handle 401 by refreshing token
        if (response.statusCode == 401) {
          debugPrint('⚠️ 401 Unauthorized for livestock unlike endpoint, refreshing token...');
          await _handleUnauthorized(
            (newHeaders) => http.delete(
              Uri.parse('$baseUrl/farm-network/livestock/$livestockId/like'),
              headers: newHeaders,
            ),
          );
          return;
        }

        if (response.statusCode != 200) {
          throw Exception('Failed to unlike livestock: ${response.statusCode}');
        }
      });
    } catch (e) {
      throw Exception('Error unliking livestock: $e');
    }
  }

  // ====== FARM POSTS (Images avec description) ======
  
  static Future<Map<String, dynamic>> createFarmPost({
    required int farmId,
    required int userId,
    required String imageUrl,
    required String caption,
    String postIntent = "share",
    double? price,
    String unit = "kg",
    int? livestockId,
  }) async {
    try {
      final body = <String, dynamic>{
        'farm_id': livestockId == null ? farmId : null,
        'livestock_id': livestockId,
        'image_url': imageUrl,
        'caption': caption,
        'post_intent': postIntent,
        'unit': unit,
      };
      
      // Remove null values
      body.removeWhere((key, value) => value == null);
      
      if (postIntent == "sell" && price != null) {
        body['price'] = price;
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/farm-posts/?user_id=$userId'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create farm post: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating farm post: $e');
    }
  }

  static Future<List<dynamic>> getFarmPostsFeed({int? userId}) async {
    try {
      final url = userId != null && userId > 0
          ? '$baseUrl/farm-posts/feed?user_id=$userId'
          : '$baseUrl/farm-posts/feed';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lecture posts: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<void> likeFarmPost(int postId) async {
    try {
      final headers = await _getAuthHeaders();
      debugPrint('🔍 likeFarmPost: token = ${headers['Authorization'] == null ? "NULL" : "EXISTS"}');
      
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.post(
        Uri.parse('$baseUrl/farm-posts/$postId/like'),
        headers: headers,
      );
      debugPrint('📤 POST /farm-posts/$postId/like → ${response.statusCode}');

      if (response.statusCode == 401) {
        debugPrint('❌ 401 Unauthorized - Token may be invalid or expired');
        // Handle 401 with token refresh and retry
        await _handleUnauthorized((newHeaders) async {
          return await http.post(
            Uri.parse('$baseUrl/farm-posts/$postId/like'),
            headers: newHeaders,
          );
        });
      } else if (response.statusCode != 200) {
        throw Exception('Failed to like farm post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error liking farm post: $e');
    }
  }

  static Future<void> unlikeFarmPost(int postId) async {
    try {
      final headers = await _getAuthHeaders();
      debugPrint('🔍 unlikeFarmPost: token = ${headers['Authorization'] == null ? "NULL" : "EXISTS"}');
      
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.delete(
        Uri.parse('$baseUrl/farm-posts/$postId/like'),
        headers: headers,
      );
      debugPrint('📤 DELETE /farm-posts/$postId/like → ${response.statusCode}');

      if (response.statusCode == 401) {
        debugPrint('❌ 401 Unauthorized - Token may be invalid or expired');
        // Handle 401 with token refresh and retry
        await _handleUnauthorized((newHeaders) async {
          return await http.delete(
            Uri.parse('$baseUrl/farm-posts/$postId/like'),
            headers: newHeaders,
          );
        });
      } else if (response.statusCode != 200) {
        throw Exception('Failed to unlike farm post: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error unliking farm post: $e');
    }
  }

  static Future<void> shareFarmPost(int postId) async {
    try {
      final token = AuthService.currentSession?.accessToken;
      if (token == null) throw Exception('Token manquant');

      await http.post(
        Uri.parse('$baseUrl/farm-posts/$postId/share'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
    } catch (e) {
      throw Exception('Error sharing farm post: $e');
    }
  }

  static Future<void> deleteFarmPost(int postId, int userId) async {
    try {
      final token = AuthService.currentSession?.accessToken;
      final url = '$baseUrl/farm-posts/$postId?user_id=$userId';

      final response = await http.delete(
        Uri.parse(url),
        headers: token != null
            ? {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $token',
              }
            : {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 401) {
        await _handleUnauthorized((headers) async {
          return await http.delete(Uri.parse(url), headers: headers);
        });
      } else if (response.statusCode != 200) {
        throw Exception('Failed to delete farm post: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Error deleting farm post: $e');
    }
  }

  static Future<List<dynamic>> getFarmPosts(int farmId, {int? userId}) async {
    try {
      final url = userId != null && userId > 0
          ? '$baseUrl/farm-posts/$farmId?user_id=$userId'
          : '$baseUrl/farm-posts/$farmId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<List<dynamic>> getLivestockPosts(int livestockId, {int? userId}) async {
    try {
      final url = userId != null && userId > 0
          ? '$baseUrl/farm-posts/livestock/$livestockId?user_id=$userId'
          : '$baseUrl/farm-posts/livestock/$livestockId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // ====== MARKET PRICES ======
  
  static Future<List<dynamic>> getMarketTrends({
    String? product,
    String? region,
  }) async {
    try {
      String url = '$baseUrl/market-prices/trends';
      List<String> params = [];
      
      if (product != null && product.isNotEmpty) {
        params.add('product=$product');
      }
      if (region != null && region.isNotEmpty) {
        params.add('region=$region');
      }
      
      if (params.isNotEmpty) {
        url += '?${params.join('&')}';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<List<dynamic>> getProductTrends(String product, {String? region}) async {
    try {
      String url = '$baseUrl/market-prices/trends/$product';
      if (region != null && region.isNotEmpty) {
        url += '?region=$region';
      }
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['data'] ?? [];
      } else {
        throw Exception('Produit non trouvé');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<List<String>> getAvailableProducts() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/market-prices/products'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<String>.from(data['products'] ?? []);
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // ====== FARM POST COMMENTS ======

  static Future<List<dynamic>> getPostComments(int postId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/farm-posts/$postId/comments'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  static Future<Map<String, dynamic>> addComment(int postId, String commentText, int userId) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.post(
        Uri.parse('$baseUrl/farm-posts/$postId/comments?comment_text=$commentText&user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await _handleUnauthorized((newHeaders) async {
          return await http.post(
            Uri.parse('$baseUrl/farm-posts/$postId/comments?comment_text=$commentText&user_id=$userId'),
            headers: newHeaders,
          );
        });
        return await addComment(postId, commentText, userId);
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur ajout commentaire: $e');
    }
  }

  static Future<void> deleteComment(int postId, int commentId, int userId) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.delete(
        Uri.parse('$baseUrl/farm-posts/$postId/comments/$commentId?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode == 401) {
        await _handleUnauthorized((newHeaders) async {
          return await http.delete(
            Uri.parse('$baseUrl/farm-posts/$postId/comments/$commentId?user_id=$userId'),
            headers: newHeaders,
          );
        });
      } else if (response.statusCode != 200) {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur suppression commentaire: $e');
    }
  }
}