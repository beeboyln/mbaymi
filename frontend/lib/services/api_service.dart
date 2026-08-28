import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/models/market_model.dart';
import 'package:mbaymi/models/news_model.dart';
import 'package:mbaymi/models/veterinarian_model.dart';
import 'package:mbaymi/services/auth_service.dart';
import 'package:mbaymi/services/token_storage.dart';
import 'package:mbaymi/services/simple_cache.dart';
import 'package:mbaymi/services/connectivity_service.dart';
import 'package:mbaymi/services/network_exception.dart';
import 'dart:async' as async_for_api;

class ApiService {
  // 🔄 Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialDelay = Duration(milliseconds: 500);
  // Increased to 45s for Render free tier cold starts
  static const Duration _requestTimeout = Duration(seconds: 45);

  // 💾 Cache simple pour les GET
  static final _getCache = SimpleCache<dynamic>(ttl: const Duration(minutes: 5));
  
  // 📡 Service de connectivité
  static final ConnectivityService _connectivity = ConnectivityService();

  // 🔔 Stream pour notifier la création d'un farm post afin que l'UI puisse se rafraîchir
  static final async_for_api.StreamController<void> _farmPostController = async_for_api.StreamController<void>.broadcast();
  static Stream<void> get onFarmPostCreated => _farmPostController.stream;
  static void notifyFarmPostCreated() => _farmPostController.add(null);
  
  // Stream to notify follow/unfollow changes with payload { 'userId': int, 'action': 'follow'|'unfollow' }
  static final async_for_api.StreamController<Map<String, dynamic>> _followController = async_for_api.StreamController<Map<String, dynamic>>.broadcast();
  static Stream<Map<String, dynamic>> get onFollowChanged => _followController.stream;
  static void notifyFollowChanged(int userId, String action) => _followController.add({'userId': userId, 'action': action});
  
  // Stream to notify profile updates for cache invalidation
  static final async_for_api.StreamController<void> _profileUpdateController = async_for_api.StreamController<void>.broadcast();
  static Stream<void> get onProfileUpdated => _profileUpdateController.stream;
  static void notifyProfileUpdated() => _profileUpdateController.add(null);

  // Notifies screens that cached livestock lists must be refreshed.
  static final async_for_api.StreamController<void> _livestockController = async_for_api.StreamController<void>.broadcast();
  static Stream<void> get onLivestockChanged => _livestockController.stream;
  static void notifyLivestockChanged() => _livestockController.add(null);

  /// 🔄 Retry helper with exponential backoff et timeout global
  /// Handles transient network errors (timeouts, connection issues)
  /// Special handling for cold starts with progressive delays
  static Future<T> _withRetry<T>(
    Future<T> Function() fn, {
    int maxRetries = _maxRetries,
  }) async {
    int attempt = 0;

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
          debugPrint('❌ Request timeout after $maxRetries attempts (cold start?)');
          rethrow;
        }
        // Exponential backoff: 1s, 2s, 4s (better for cold starts)
        final backoffDuration = Duration(seconds: attempt * 2);
        debugPrint('⏳ Timeout attempt $attempt/$maxRetries, waiting ${backoffDuration.inSeconds}s before retry (cold start recovery)...');
        await Future.delayed(backoffDuration);
      } on ConnectionException {
        _connectivity.recordConnectionError();
        if (attempt >= maxRetries) {
          debugPrint('❌ Connection error after $maxRetries attempts');
          rethrow;
        }
        final backoffDuration = Duration(seconds: attempt * 2);
        debugPrint('⚠️ Connection error attempt $attempt, retrying in ${backoffDuration.inSeconds}s...');
        await Future.delayed(backoffDuration);
      } catch (e) {
        _connectivity.recordConnectionError();
        if (attempt >= maxRetries) {
          debugPrint('❌ Request failed after $maxRetries attempts: $e');
          rethrow;
        }
        final backoffDuration = Duration(seconds: attempt * 2);
        debugPrint('⚠️ Attempt $attempt failed, retrying in ${backoffDuration.inSeconds}s...');
        await Future.delayed(backoffDuration);
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

  /// 🏥 Health check endpoint (for waking up cold-start backends)
  /// Returns True if backend responds successfully, False on timeout/error
  static Future<bool> healthCheck() async {
    try {
      final url = Uri.parse('$baseUrl/health');
      debugPrint('🏥 Health check: GET $url');
      
      final response = await http.get(url).timeout(
        const Duration(seconds: 3),
      );
      
      final isHealthy = response.statusCode == 200;
      if (isHealthy) {
        debugPrint('✅ Backend is alive (status ${response.statusCode})');
      } else {
        debugPrint('⚠️ Backend returned ${response.statusCode}');
      }
      return isHealthy;
    } on TimeoutException {
      debugPrint('⚠️ Health check timeout');
      return false;
    } catch (e) {
      debugPrint('❌ Health check error: $e');
      return false;
    }
  }

  // For local development on Windows/Web: use localhost
  // For Android Emulator: use 'http://10.0.2.2:8000/api'
  // API_BASE_URL selects localhost in development and Koyeb in production.
  static String get baseUrl {
    final configuredUrl = dotenv.env['API_BASE_URL']?.trim();
    if (configuredUrl == null || configuredUrl.isEmpty) {
      throw StateError('API_BASE_URL is missing from the environment');
    }
    return configuredUrl.replaceFirst(RegExp(r'/+$'), '');
  }

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
            userRole: AuthService.currentSession?.role,
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
    String? email,
    String? phone,
    required String password,
    required String role,
    required String region,
    String? village,
  }) async {
    try {
      // Envoyer null au lieu de strings vides
      final payload = {
        'name': name,
        'email': email?.isNotEmpty == true ? email : null,
        'phone': phone?.isNotEmpty == true ? phone : null,
        'password': password,
        'role': role,
        'region': region,
        'village': village?.isNotEmpty == true ? village : null,
      };
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(payload),
      );
      if (response.statusCode == 200) {
        final livestock = jsonDecode(response.body);
        notifyLivestockChanged();
        return livestock;
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

  /// Login with email or phone
  static Future<Map<String, dynamic>> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    try {
      final identifier = email ?? phone;
      if (identifier == null) {
        throw Exception('INVALID_REQUEST');
      }
      
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': identifier,  // Backend accepte email ou phone
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final livestock = jsonDecode(response.body);
        notifyLivestockChanged();
        return livestock;
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
      final token = AuthService.currentSession?.accessToken;
      final url = '$baseUrl/farms/$farmId';

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
        throw Exception('Failed to delete farm: ${response.statusCode} ${response.body}');
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

      debugPrint('☁️ Uploading to Cloudinary...');
      debugPrint('   Cloud Name: $cloudName');
      debugPrint('   Upload Preset: $uploadPreset');
      debugPrint('   Folder: $folder');
      debugPrint('   File: ${file.name}');
      
      final request = http.MultipartRequest('POST', uri);
      request.fields['upload_preset'] = uploadPreset;
      // Put images under configured folder in Cloudinary
      request.fields['folder'] = folder;

      // Read bytes from the XFile (works on Web and mobile)
      final bytes = await file.readAsBytes();
      debugPrint('   File size: ${bytes.length} bytes');
      
      final multipartFile = http.MultipartFile.fromBytes('file', bytes, filename: file.name);
      request.files.add(multipartFile);

      final streamed = await request.send();
      final resp = await http.Response.fromStream(streamed);
      debugPrint('   Response status: ${resp.statusCode}');
      
      if (resp.statusCode == 200 || resp.statusCode == 201) {
        final data = jsonDecode(resp.body);
        debugPrint('✅ Cloudinary success: ${data['secure_url']}');
        return data['secure_url'] as String?;
      } else {
        final body = resp.body;
        debugPrint('❌ Cloudinary error (${resp.statusCode}): $body');
        throw Exception('Cloudinary upload failed: ${resp.statusCode} $body');
      }
    } catch (e) {
      debugPrint('❌ Image upload exception: $e');
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
    double? area,
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
          'area': area,
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

  // ------------------------- Crops API -------------------------
  static Future<Map<String, dynamic>> createCrop({
    required int farmId,
    required String cropName,
    DateTime? plantedDate,
    DateTime? expectedHarvestDate,
    double? quantityPlanted,
    double? expectedYield,
    String? variety,
    int? cycleDurationDays,
    String? objective,
    String? status,
    String? notes,
    String? imageUrl,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final body = jsonEncode({
        'crop_name': cropName,
        'planted_date': plantedDate?.toIso8601String(),
        'expected_harvest_date': expectedHarvestDate?.toIso8601String(),
        'quantity_planted': quantityPlanted,
        'expected_yield': expectedYield,
        'variety': variety,
        'cycle_duration_days': cycleDurationDays,
        'objective': objective,
        'status': status,
        'notes': notes,
        'image_url': imageUrl,
      });

      var response = await _withRetry(() async {
        return await http.post(
          Uri.parse('$baseUrl/crops/?farm_id=$farmId'),
          headers: headers,
          body: body,
        );
      });

      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.post(
            Uri.parse('$baseUrl/crops/?farm_id=$farmId'),
            headers: newHeaders,
            body: body,
          );
        });
      }

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else {
        throw Exception('Failed to create crop: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error creating crop: $e');
    }
  }

  static Future<Map<String, dynamic>> getCrop(int cropId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.get(Uri.parse('$baseUrl/crops/$cropId'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.get(Uri.parse('$baseUrl/crops/$cropId'), headers: newHeaders);
        });
      }
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to fetch crop');
    } catch (e) {
      throw Exception('Error fetching crop: $e');
    }
  }

  static Future<List<dynamic>> listCropsForFarm(int farmId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.get(Uri.parse('$baseUrl/crops/farm/$farmId'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.get(Uri.parse('$baseUrl/crops/farm/$farmId'), headers: newHeaders);
        });
      }
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      }
      throw Exception('Failed to list crops');
    } catch (e) {
      throw Exception('Error listing crops: $e');
    }
  }

  static Future<Map<String, dynamic>> updateCrop({
    required int cropId,
    required Map<String, dynamic> updates,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.patch(Uri.parse('$baseUrl/crops/$cropId'), headers: headers, body: jsonEncode(updates));
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.patch(Uri.parse('$baseUrl/crops/$cropId'), headers: newHeaders, body: jsonEncode(updates));
        });
      }
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
      throw Exception('Failed to update crop');
    } catch (e) {
      throw Exception('Error updating crop: $e');
    }
  }

  static Future<bool> deleteCrop(int cropId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.delete(Uri.parse('$baseUrl/crops/$cropId'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.delete(Uri.parse('$baseUrl/crops/$cropId'), headers: newHeaders);
        });
      }
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting crop: $e');
    }
  }

  // ------------------------- Inputs API -------------------------
  static Future<Map<String, dynamic>> createInput(Map<String, dynamic> payload) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.post(Uri.parse('$baseUrl/inputs/'), headers: headers, body: jsonEncode(payload));
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.post(Uri.parse('$baseUrl/inputs/'), headers: newHeaders, body: jsonEncode(payload));
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('Failed to create input: ${response.body}');
    } catch (e) {
      throw Exception('Error creating input: $e');
    }
  }

  static Future<List<dynamic>> listInputsForFarm(int farmId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.get(Uri.parse('$baseUrl/inputs/farm/$farmId'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.get(Uri.parse('$baseUrl/inputs/farm/$farmId'), headers: newHeaders);
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as List;
      throw Exception('Failed to list inputs');
    } catch (e) {
      throw Exception('Error listing inputs: $e');
    }
  }

  static Future<List<dynamic>> listInputsForCrop(int cropId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.get(Uri.parse('$baseUrl/inputs/crop/$cropId'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.get(Uri.parse('$baseUrl/inputs/crop/$cropId'), headers: newHeaders);
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as List;
      throw Exception('Failed to list inputs for crop');
    } catch (e) {
      throw Exception('Error listing inputs for crop: $e');
    }
  }

  static Future<Map<String, dynamic>> getInput(int inputId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.get(Uri.parse('$baseUrl/inputs/$inputId'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.get(Uri.parse('$baseUrl/inputs/$inputId'), headers: newHeaders);
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('Failed to get input');
    } catch (e) {
      throw Exception('Error getting input: $e');
    }
  }

  static Future<Map<String, dynamic>> updateInput(int inputId, Map<String, dynamic> updates) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.patch(Uri.parse('$baseUrl/inputs/$inputId'), headers: headers, body: jsonEncode(updates));
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.patch(Uri.parse('$baseUrl/inputs/$inputId'), headers: newHeaders, body: jsonEncode(updates));
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('Failed to update input');
    } catch (e) {
      throw Exception('Error updating input: $e');
    }
  }

  static Future<bool> deleteInput(int inputId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.delete(Uri.parse('$baseUrl/inputs/$inputId'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.delete(Uri.parse('$baseUrl/inputs/$inputId'), headers: newHeaders);
        });
      }
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting input: $e');
    }
  }

  // ------------------------- Finance API -------------------------
  static Future<Map<String, dynamic>> createTransaction(Map<String, dynamic> payload) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.post(Uri.parse('$baseUrl/finance/transactions/'), headers: headers, body: jsonEncode(payload));
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.post(Uri.parse('$baseUrl/finance/transactions/'), headers: newHeaders, body: jsonEncode(payload));
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('Failed to create transaction: ${response.body}');
    } catch (e) {
      throw Exception('Error creating transaction: $e');
    }
  }

  static Future<List<dynamic>> listTransactionsForFarm(int farmId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.get(Uri.parse('$baseUrl/finance/transactions/farm/$farmId'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.get(Uri.parse('$baseUrl/finance/transactions/farm/$farmId'), headers: newHeaders);
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as List;
      throw Exception('Failed to list transactions');
    } catch (e) {
      throw Exception('Error listing transactions: $e');
    }
  }

  static Future<List<dynamic>> listTransactionsForCrop(int cropId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.get(Uri.parse('$baseUrl/finance/transactions/crop/$cropId'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.get(Uri.parse('$baseUrl/finance/transactions/crop/$cropId'), headers: newHeaders);
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as List;
      throw Exception('Failed to list transactions for crop');
    } catch (e) {
      throw Exception('Error listing transactions for crop: $e');
    }
  }

  static Future<Map<String, dynamic>> getTransaction(int transactionId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.get(Uri.parse('$baseUrl/finance/transactions/$transactionId'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.get(Uri.parse('$baseUrl/finance/transactions/$transactionId'), headers: newHeaders);
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('Failed to get transaction');
    } catch (e) {
      throw Exception('Error getting transaction: $e');
    }
  }

  static Future<Map<String, dynamic>> updateTransaction(int transactionId, Map<String, dynamic> updates) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.patch(Uri.parse('$baseUrl/finance/transactions/$transactionId'), headers: headers, body: jsonEncode(updates));
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.patch(Uri.parse('$baseUrl/finance/transactions/$transactionId'), headers: newHeaders, body: jsonEncode(updates));
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('Failed to update transaction');
    } catch (e) {
      throw Exception('Error updating transaction: $e');
    }
  }

  static Future<bool> deleteTransaction(int transactionId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.delete(Uri.parse('$baseUrl/finance/transactions/$transactionId'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.delete(Uri.parse('$baseUrl/finance/transactions/$transactionId'), headers: newHeaders);
        });
      }
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting transaction: $e');
    }
  }

  static Future<Map<String, dynamic>> getFinanceSummary(int farmId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.get(Uri.parse('$baseUrl/finance/summary/$farmId'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.get(Uri.parse('$baseUrl/finance/summary/$farmId'), headers: newHeaders);
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('Failed to get finance summary');
    } catch (e) {
      throw Exception('Error getting finance summary: $e');
    }
  }

  static Future<Map<String, dynamic>> getFinanceSummaryForCrop(int cropId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.get(Uri.parse('$baseUrl/finance/summary/crop/$cropId'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.get(Uri.parse('$baseUrl/finance/summary/crop/$cropId'), headers: newHeaders);
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('Failed to get crop finance summary');
    } catch (e) {
      throw Exception('Error getting crop finance summary: $e');
    }
  }

  // ------------------------- Reminders API -------------------------
  static Future<Map<String, dynamic>> createReminder(Map<String, dynamic> payload) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.post(Uri.parse('$baseUrl/reminders/'), headers: headers, body: jsonEncode(payload));
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.post(Uri.parse('$baseUrl/reminders/'), headers: newHeaders, body: jsonEncode(payload));
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('Failed to create reminder: ${response.body}');
    } catch (e) {
      throw Exception('Error creating reminder: $e');
    }
  }

  static Future<List<dynamic>> listRemindersForFarm(int farmId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.get(Uri.parse('$baseUrl/reminders/farm/$farmId'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.get(Uri.parse('$baseUrl/reminders/farm/$farmId'), headers: newHeaders);
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as List;
      throw Exception('Failed to list reminders');
    } catch (e) {
      throw Exception('Error listing reminders: $e');
    }
  }

  static Future<Map<String, dynamic>> getReminder(int reminderId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.get(Uri.parse('$baseUrl/reminders/$reminderId'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.get(Uri.parse('$baseUrl/reminders/$reminderId'), headers: newHeaders);
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('Failed to get reminder');
    } catch (e) {
      throw Exception('Error getting reminder: $e');
    }
  }

  static Future<Map<String, dynamic>> updateReminder(int reminderId, Map<String, dynamic> updates) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.patch(Uri.parse('$baseUrl/reminders/$reminderId'), headers: headers, body: jsonEncode(updates));
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.patch(Uri.parse('$baseUrl/reminders/$reminderId'), headers: newHeaders, body: jsonEncode(updates));
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('Failed to update reminder');
    } catch (e) {
      throw Exception('Error updating reminder: $e');
    }
  }

  static Future<Map<String, dynamic>> markReminderDone(int reminderId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.post(Uri.parse('$baseUrl/reminders/$reminderId/done/'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.post(Uri.parse('$baseUrl/reminders/$reminderId/done/'), headers: newHeaders);
        });
      }
      if (response.statusCode == 200) return jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception('Failed to mark reminder done');
    } catch (e) {
      throw Exception('Error marking reminder done: $e');
    }
  }

  static Future<bool> deleteReminder(int reminderId) async {
    try {
      final headers = await _getAuthHeaders();
      var response = await http.delete(Uri.parse('$baseUrl/reminders/$reminderId'), headers: headers);
      if (response.statusCode == 401) {
        response = await _handleUnauthorized((newHeaders) async {
          return await http.delete(Uri.parse('$baseUrl/reminders/$reminderId'), headers: newHeaders);
        });
      }
      return response.statusCode == 200;
    } catch (e) {
      throw Exception('Error deleting reminder: $e');
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

  /// Get farms for any user (public endpoint)
  static Future<List<dynamic>> getPublicUserFarms(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/farms/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Failed to get farms');
      }
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
        final livestock = jsonDecode(response.body);
        notifyLivestockChanged();
        return livestock;
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

  static Future<List<dynamic>> getPublicUserLivestock(int userId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/livestock/public/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      }
      throw Exception('Failed to get public livestock');
    } catch (e) {
      throw Exception('Error getting public livestock: $e');
    }
  }

  static Future<Map<String, dynamic>> getLivestockById(int livestockId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/livestock/$livestockId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return Map<String, dynamic>.from(jsonDecode(response.body) as Map);
      }

      if (response.statusCode == 404) {
        final publicResponse = await http.get(
          Uri.parse('$baseUrl/livestock/public'),
          headers: {'Content-Type': 'application/json'},
        );
        if (publicResponse.statusCode == 200) {
          final animals = jsonDecode(publicResponse.body) as List<dynamic>;
          for (final animal in animals) {
            final data = Map<String, dynamic>.from(animal as Map);
            if (data['id'].toString() == livestockId.toString()) {
              return data;
            }
          }
        }
      }
      throw Exception('Failed to get livestock: ${response.statusCode}');
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
        final livestock = jsonDecode(response.body);
        notifyLivestockChanged();
        return livestock;
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
      notifyLivestockChanged();
    } catch (e) {
      throw Exception('Error deleting livestock: $e');
    }
  }

  // Get livestock - supports both farmId and userId (livestock is user-level)
  static Future<List<dynamic>> getLivestock({
    int? farmId,
    int? userId,
  }) async {
    try {
      // If userId is provided, use it; otherwise use the current user's ID
      final effectiveUserId = userId ?? (AuthService.currentSession?.userId ?? 0);
      
      if (effectiveUserId == 0) {
        return [];
      }

      return getUserLivestock(effectiveUserId);
    } catch (e) {
      return [];
    }
  }

  static Future<List<dynamic>> getAllLivestockWithPhotos({int? userId}) async {
    try {
        final url = userId != null
          ? '$baseUrl/livestock/mine'
          : '$baseUrl/livestock/public';
        final headers = userId != null
          ? await _getAuthHeaders()
          : {'Content-Type': 'application/json'};
        
      final response = await http.get(
        Uri.parse(url),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final List<dynamic> allLivestock = jsonDecode(response.body) as List;
        
        // Filtrer les animaux supprimés et charger les photos
        final List<dynamic> livestockWithPhotos = [];
        for (var animal in allLivestock) {
          // Exclure les bétails supprimés (deleted_at != null)
          if (animal['deleted_at'] != null) {
            continue;
          }
          
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

  /// Try to fetch a list of short tips from the backend.
  /// Returns a list of strings on success.
  static Future<List<String>> getTips({String? region}) async {
    try {
      return await _withRetry(() async {
        final uri = Uri.parse('$baseUrl/advice/tips${region != null ? '?region=${Uri.encodeComponent(region)}' : ''}');
        final response = await http.get(uri, headers: {'Content-Type': 'application/json'});

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          if (data is List) {
            return data.map((e) => e.toString()).toList();
          }
          if (data is Map && data['tips'] is List) {
            return (data['tips'] as List).map((e) => e.toString()).toList();
          }
          // If backend returns a single string, wrap it
          if (data is String) return [data];
          throw Exception('Unexpected tips format');
        } else {
          throw Exception('Failed to get tips: ${response.statusCode}');
        }
      });
    } catch (e) {
      debugPrint('Error fetching tips: $e');
      rethrow;
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
              content: item['content'] ?? item['description'] ?? '',
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
        content: 'Les prévisions météorologiques indiquent une arrivée de pluies ce weekend. Cela représente une excellente nouvelle pour vos cultures qui bénéficieront de cette humidité naturelle. Les agriculteurs doivent se préparer à arrêter l\'irrigation si elle était prévue. Les accumulations de pluie devraient être de 20 à 40 mm selon les régions.',
        pubDate: now.subtract(const Duration(hours: 2)),
        source: 'Météo',
        category: 'Météo',
      ),
      NewsArticle(
        title: 'Prix en hausse',
        description: 'Le maïs atteint 850 FCFA/kg - Plus haut en 30 jours',
        content: 'Le cours du maïs a atteint 850 FCFA par kilogramme, marquant le plus haut niveau depuis 30 jours. Cette hausse est due à la baisse des stocks nationaux et à la demande croissante des marchés régionaux. Les experts recommandent aux producteurs de bien évaluer leurs stocks avant de vendre, car cette tendance pourrait s\'accentuer dans les semaines à venir.',
        pubDate: now.subtract(const Duration(hours: 4)),
        source: 'Marché',
        category: 'Prix',
      ),
      NewsArticle(
        title: 'Alerte Ravageurs',
        description: 'Attention aux chenilles légionnaires dans votre région',
        content: 'Une alerte a été émise concernant la présence de chenilles légionnaires (Spodoptera frugiperda) dans plusieurs zones agricoles de la région. Ces ravageurs sont particulièrement destructeurs pour le maïs et le sorgho. Les agriculteurs doivent inspecter régulièrement leurs cultures et appliquer des mesures de lutte intégrée. Consultez un agent vétérinaire pour les options de traitement recommandées.',
        pubDate: now.subtract(const Duration(hours: 6)),
        source: 'Alertes',
        category: 'Santé des cultures',
      ),
      NewsArticle(
        title: 'Conseil Irrigation',
        description: 'Augmentez l\'irrigation de 20% cette semaine',
        content: 'En raison de l\'augmentation des températures et de la baisse de l\'humidité relative, il est recommandé d\'augmenter l\'irrigation de vos cultures de 20% cette semaine. Les cultures au stade de croissance active consomment plus d\'eau. Assurez-vous que votre système d\'irrigation fonctionne correctement et que l\'eau atteint les racines. Un arrosage adéquat améliora la productivité de vos cultures.',
        pubDate: now.subtract(const Duration(hours: 8)),
        source: 'Conseils',
        category: 'Technique',
      ),
      NewsArticle(
        title: 'Vaccin disponible',
        description: 'Nouveau vaccin pour le bétail arrivé - Réservez maintenant',
        content: 'Un nouveau vaccin polyvalent pour le bétail est maintenant disponible dans les cliniques vétérinaires agréées. Ce vaccin offre une protection contre les principales maladies infectieuses du bétail. La campagne de vaccination est fortement recommandée, particulièrement pour les jeunes animaux et lors de la transition des saisons. Contactez votre vétérinaire local pour prendre un rendez-vous et en savoir plus sur les tarifs.',
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

  static Future<List<int>> getUserFollowingIds(int userId) async {
    try {
      return await _withRetry(() async {
        final response = await http.get(
          Uri.parse('$baseUrl/farm-network/user-following/$userId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final followingList = data['following'] as List? ?? [];
          return followingList.map<int>((f) => f['following_id'] as int).toList();
        } else {
          return [];
        }
      });
    } catch (e) {
      debugPrint('Error getting user following IDs: $e');
      return [];
    }
  }

  static Future<List<int>> getFarmFollowingIds(int userId) async {
    try {
      return await _withRetry(() async {
        final response = await http.get(
          Uri.parse('$baseUrl/farm-network/farm-following/$userId'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final farmList = data['following'] as List? ?? [];
          return farmList.map<int>((f) => f['farm_id'] as int).toList();
        } else {
          return [];
        }
      });
    } catch (e) {
      debugPrint('Error getting farm following IDs: $e');
      return [];
    }
  }

  static Future<void> followFarm({required int farmId, required int userId}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/farm-network/follow-farm/$farmId?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to follow farm');
      }
    } catch (e) {
      throw Exception('Error following farm: $e');
    }
  }

  static Future<void> unfollowFarm({required int farmId, required int userId}) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.delete(
        Uri.parse('$baseUrl/farm-network/follow-farm/$farmId?user_id=$userId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to unfollow farm');
      }
    } catch (e) {
      throw Exception('Error unfollowing farm: $e');
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

  static Future<List<dynamic>> getPublicFarmCrops(int farmId) async {
    try {
      return await _withRetry(() async {
        final response = await http.get(
          Uri.parse('$baseUrl/farm-network/public-farms/$farmId/crops'),
          headers: {'Content-Type': 'application/json'},
        );

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          // Handle both array and object response formats
          if (data is List) {
            return data;
          } else if (data is Map && data.containsKey('crops')) {
            return data['crops'] as List;
          }
          return [];
        } else if (response.statusCode == 404) {
          // Farm not found or no crops
          return [];
        } else {
          throw Exception('Failed to get public farm crops: ${response.statusCode}');
        }
      });
    } catch (e) {
      // Return empty list instead of throwing to handle gracefully
      return [];
    }
  }

  static Future<Map<String, dynamic>> updateUserProfile({
    required int userId,
    String? name,
    String? email,
    String? phone,
    String? profileImage,
  }) async {
    try {
      final params = <String, String>{};
      if (name != null && name.isNotEmpty) params['name'] = name;
      if (email != null && email.isNotEmpty) params['email'] = email;
      if (phone != null && phone.isNotEmpty) params['phone'] = phone;
      if (profileImage != null && profileImage.isNotEmpty) params['profile_image'] = profileImage;

      final response = await http.put(
        Uri.parse('$baseUrl/users/$userId/profile').replace(
          queryParameters: params.isNotEmpty ? params : null,
        ),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        notifyProfileUpdated(); // Notify listeners of profile update
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to update profile');
      }
    } catch (e) {
      throw Exception('Error updating profile: $e');
    }
  }

  static Future<Map<String, dynamic>> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${await TokenStorage.getAccessToken()}',
        },
        body: jsonEncode({
          'current_password': currentPassword,
          'new_password': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['detail'] ?? 'Failed to change password');
      }
    } catch (e) {
      throw Exception('Error changing password: $e');
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

  static Future<List<dynamic>> getSubscriptionsFeed({required int userId}) async {
    try {
      final url = '$baseUrl/farm-posts/subscriptions-feed/$userId';
      
      final response = await http.get(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Erreur lecture posts abonnements: ${response.statusCode}');
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

  static Future<Map<String, dynamic>> addComment(
    int postId,
    String commentText,
    int userId, {
    int? parentId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.post(
        Uri.parse('$baseUrl/farm-posts/$postId/comments'),
        headers: headers,
        body: jsonEncode({
          'comment_text': commentText,
          'user_id': userId,
          'parent_id': parentId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        await _handleUnauthorized((newHeaders) async {
          return await http.post(
            Uri.parse('$baseUrl/farm-posts/$postId/comments'),
            headers: newHeaders,
            body: jsonEncode({
              'comment_text': commentText,
              'user_id': userId,
              'parent_id': parentId,
            }),
          );
        });
        return await addComment(postId, commentText, userId, parentId: parentId);
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

  // 👨‍⚕️ VETERINARIAN ENDPOINTS
  
  /// Create veterinarian profile
  static Future<Map<String, dynamic>> createVeterinarianProfile({
    required String specialty,
    required String zone,
    required int distanceMax,
    required String bio,
    required int experienceYears,
    required String contactPreference,
    String? certificateUrl,
    String? certificateFilename,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final body = {
        'specialty': specialty,
        'zone': zone,
        'distance_max': distanceMax,
        'bio': bio,
        'experience_years': experienceYears,
        'contact_preference': contactPreference,
      };
      
      if (certificateUrl != null && certificateUrl.isNotEmpty) {
        body['certificate_url'] = certificateUrl;
      }
      if (certificateFilename != null && certificateFilename.isNotEmpty) {
        body['certificate_filename'] = certificateFilename;
      }

      final response = await http.post(
        Uri.parse('$baseUrl/veterinarians/profile'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur création profil vétérinaire: $e');
    }
  }

  /// Upload veterinarian certificate
  static Future<void> uploadCertificate(File certificateFile) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/veterinarians/upload-certificate'),
      );
      request.headers.addAll(headers);
      request.files.add(
        await http.MultipartFile.fromPath(
          'certificate',
          certificateFile.path,
        ),
      );

      final response = await request.send();
      await response.stream.drain();

      if (response.statusCode != 200) {
        throw Exception('Erreur upload: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur upload certificat: $e');
    }
  }

  /// Get veterinarian profile
  static Future<VeterinarianProfile?> getVeterinarianProfile() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.get(
        Uri.parse('$baseUrl/veterinarians/my-profile'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return VeterinarianProfile.fromJson(json);
      } else if (response.statusCode == 404) {
        // Profile not found - vet needs to create one
        return null;
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération profil: $e');
    }
  }

  static Future<VeterinarianProfile?> getVeterinarianProfileById(int veterinarianId) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/veterinarians/profile/$veterinarianId'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return VeterinarianProfile.fromJson(json);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération profil vétérinaire: $e');
    }
  }

  /// Get veterinarians by zone
  static Future<List<dynamic>> getVeterinariansByZone(String zone) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/veterinarians/by-zone/$zone'),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération vétérinaires: $e');
    }
  }

  // 🆘 SERVICE REQUEST ENDPOINTS

  /// Create service request
  static Future<Map<String, dynamic>> createServiceRequest({
    required String serviceType,
    required String title,
    required String description,
    String? symptoms,
    int? animalId,
    int? cropId,
    String priority = 'medium',
    List<String>? photos,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.post(
        Uri.parse('$baseUrl/service-requests/'),
        headers: headers,
        body: jsonEncode({
          'service_type': serviceType,
          'title': title,
          'description': description,
          'symptoms': symptoms,
          'animal_id': animalId,
          'crop_id': cropId,
          'priority': priority,
          'photos': photos,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur création demande: $e');
    }
  }

  /// Get user's service requests
  static Future<List<dynamic>> getMyServiceRequests() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.get(
        Uri.parse('$baseUrl/service-requests/my-requests'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération demandes: $e');
    }
  }

  /// Get available service requests for veterinarian
  static Future<List<dynamic>> getAvailableRequests() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.get(
        Uri.parse('$baseUrl/service-requests/available-for-me'),
        headers: headers,
      );

      debugPrint('ApiService.getAvailableRequests: status=${response.statusCode}, body=${response.body}');
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié');
      } else if (response.statusCode == 404) {
        // No profile or no requests
        return <dynamic>[];
      } else if (response.statusCode == 422) {
        // Unprocessable content - log and return empty list to avoid crashing the UI
        debugPrint('Warning: getAvailableRequests returned 422 Unprocessable Content');
        return <dynamic>[];
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération demandes disponibles: $e');
    }
  }

  // 🔐 AUTHORIZATION ENDPOINTS

  /// Get current user's farms (authenticated endpoint)
  static Future<List<dynamic>> getUserFarms() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      // Try to fetch farms - the backend route should be /api/farms or similar
      // If that doesn't work, we'll need to add a dedicated endpoint
      final response = await http.get(
        Uri.parse('$baseUrl/farms/'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération fermes: $e');
    }
  }

  /// Create authorization request
  static Future<Map<String, dynamic>> createAuthorization({
    required int farmId,
    required int veterinarianId,
    bool canViewData = true,
    bool canGiveAdvice = true,
    bool canVisit = false,
    String? authorizationReason,
    String? selectedLivestockIds,  // Comma-separated IDs
    String? selectedCropIds,  // Comma-separated IDs
  }) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final payload = {
        'farm_id': farmId,
        'veterinarian_id': veterinarianId,
        'can_view_data': canViewData,
        'can_give_advice': canGiveAdvice,
        'can_visit': canVisit,
        'authorization_reason': authorizationReason,
        'selected_livestock_ids': selectedLivestockIds,
        'selected_crop_ids': selectedCropIds,
      };
      
      debugPrint('📤 POST /api/authorizations/');
      debugPrint('Payload: $payload');
      debugPrint('Headers: $headers');

      final response = await http.post(
        Uri.parse('$baseUrl/authorizations/'),
        headers: headers,
        body: jsonEncode(payload),
      );

      debugPrint('Response status: ${response.statusCode}');
      debugPrint('Response body: ${response.body}');

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur création autorisation: $e');
    }
  }

  /// Get pending authorizations for current veterinarian
  static Future<List<dynamic>> getPendingAuthorizations() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.get(
        Uri.parse('$baseUrl/authorizations/pending'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        debugPrint('=== API RESPONSE DEBUG ===');
        debugPrint('Response body: ${response.body}');
        debugPrint('Parsed data: $data');
        if (data.isNotEmpty) {
          debugPrint('First item: ${data[0]}');
          debugPrint('First item type: ${data[0].runtimeType}');
          if (data[0] is Map) {
            final firstMap = data[0] as Map<String, dynamic>;
            debugPrint('First item keys: ${firstMap.keys.toList()}');
            debugPrint('Farm in first item: ${firstMap['farm']}');
          }
        }
        debugPrint('========================');
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération autorisations: $e');
    }
  }

  /// Accept an authorization request
  static Future<Map<String, dynamic>> acceptAuthorization(int authorizationId) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.post(
        Uri.parse('$baseUrl/authorizations/$authorizationId/accept'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié');
      } else if (response.statusCode == 404) {
        throw Exception('Autorisation non trouvée');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur acceptation autorisation: $e');
    }
  }

  /// Reject an authorization request
  static Future<Map<String, dynamic>> rejectAuthorization(int authorizationId) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.post(
        Uri.parse('$baseUrl/authorizations/$authorizationId/reject'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié');
      } else if (response.statusCode == 404) {
        throw Exception('Autorisation non trouvée');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur rejet autorisation: $e');
    }
  }

  /// Get accepted authorizations for current veterinarian
  static Future<List<dynamic>> getAcceptedAuthorizations() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final currentUser = AuthService.currentSession?.userId;
      if (currentUser == null) throw Exception('Utilisateur non authentifié');

      final response = await http.get(
        Uri.parse('$baseUrl/authorizations/veterinarian/$currentUser'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as List<dynamic>;
        return data;
      } else if (response.statusCode == 401) {
        throw Exception('Non authentifié');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération autorisations acceptées: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // 👨‍💼 ADMIN ENDPOINTS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Get pending veterinarian profiles
  static Future<List<dynamic>> getAdminPendingVeterinarians() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/veterinarians/pending'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé - administrateur requis');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération vétérinaires en attente: $e');
    }
  }

  /// Get verified veterinarians
  static Future<List<dynamic>> getAdminVerifiedVeterinarians() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/veterinarians/verified'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé - administrateur requis');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération vétérinaires vérifiés: $e');
    }
  }

  /// Get rejected veterinarians
  static Future<List<dynamic>> getAdminRejectedVeterinarians() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/veterinarians/rejected'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé - administrateur requis');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération vétérinaires rejetés: $e');
    }
  }

  /// Verify a veterinarian
  static Future<Map<String, dynamic>> adminVerifyVeterinarian(int veterinarianId) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.patch(
        Uri.parse('$baseUrl/admin/veterinarians/$veterinarianId/verify'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé');
      } else if (response.statusCode == 404) {
        throw Exception('Vétérinaire non trouvé');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur vérification vétérinaire: $e');
    }
  }

  /// Reject a veterinarian
  static Future<Map<String, dynamic>> adminRejectVeterinarian(
    int veterinarianId, {
    String? reason,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.patch(
        Uri.parse('$baseUrl/admin/veterinarians/$veterinarianId/reject'),
        headers: headers,
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé');
      } else if (response.statusCode == 404) {
        throw Exception('Vétérinaire non trouvé');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur rejet vétérinaire: $e');
    }
  }

  /// Get pending authorizations (admin view)
  static Future<List<dynamic>> getAdminPendingAuthorizations() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/authorizations/pending'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé - administrateur requis');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération demandes en attente: $e');
    }
  }

  /// Get active authorizations (admin view)
  static Future<List<dynamic>> getAdminActiveAuthorizations() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/authorizations/active'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé - administrateur requis');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération autorisations actives: $e');
    }
  }

  /// Revoke authorization (admin)
  static Future<Map<String, dynamic>> adminRevokeAuthorization(
    int authorizationId, {
    String? reason,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.patch(
        Uri.parse('$baseUrl/admin/authorizations/$authorizationId/revoke'),
        headers: headers,
        body: jsonEncode({'reason': reason}),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé');
      } else if (response.statusCode == 404) {
        throw Exception('Autorisation non trouvée');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur révocation autorisation: $e');
    }
  }

  /// Get admin statistics
  static Future<Map<String, dynamic>> getAdminStatistics() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/statistics'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé - administrateur requis');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération statistiques: $e');
    }
  }

  // 👥 USER MANAGEMENT (ADMIN)

  /// Get all users (admin view)
  static Future<List<dynamic>> getAdminAllUsers() async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List<dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé - administrateur requis');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération utilisateurs: $e');
    }
  }

  /// Create new user (admin)
  static Future<Map<String, dynamic>> adminCreateUser({
    required String name,
    required String email,
    required String password,
    required String role,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final body = {
        'name': name,
        'email': email,
        'password': password,
        'role': role,
      };

      final response = await http.post(
        Uri.parse('$baseUrl/admin/users'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé - administrateur requis');
      } else if (response.statusCode == 409) {
        throw Exception('Email déjà utilisé');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur création utilisateur: $e');
    }
  }

  /// Delete user (admin)
  static Future<Map<String, dynamic>> adminDeleteUser(int userId) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé - administrateur requis');
      } else if (response.statusCode == 404) {
        throw Exception('Utilisateur non trouvé');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur suppression utilisateur: $e');
    }
  }

  /// Update user role/permissions (admin)
  static Future<Map<String, dynamic>> adminUpdateUserRole(
    int userId, {
    required String role,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final body = {'role': role};

      final response = await http.patch(
        Uri.parse('$baseUrl/admin/users/$userId/role'),
        headers: headers,
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé - administrateur requis');
      } else if (response.statusCode == 404) {
        throw Exception('Utilisateur non trouvé');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur mise à jour rôle: $e');
    }
  }

  /// Get user by ID (admin)
  static Future<Map<String, dynamic>> adminGetUser(int userId) async {
    try {
      final headers = await _getAuthHeaders();
      if (headers['Authorization'] == null) throw Exception('Token manquant');

      final response = await http.get(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } else if (response.statusCode == 403) {
        throw Exception('Accès refusé - administrateur requis');
      } else if (response.statusCode == 404) {
        throw Exception('Utilisateur non trouvé');
      } else {
        throw Exception('Erreur: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération utilisateur: $e');
    }
  }
}

