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

class ApiService {
  // 🔄 Retry configuration
  static const int _maxRetries = 3;
  static const Duration _initialDelay = Duration(milliseconds: 500);
  static const Duration _requestTimeout = Duration(seconds: 15);

  // 💾 Cache simple pour les GET
  static final _getCache = SimpleCache<dynamic>(ttl: Duration(minutes: 5));
  
  // 📡 Service de connectivité
  static final ConnectivityService _connectivity = ConnectivityService();

  /// 🔄 Retry helper with exponential backoff et timeout global
  /// Handles transient network errors (timeouts, connection issues)
  static Future<T> _withRetry<T>(
    Future<T> Function() fn, {
    int maxRetries = _maxRetries,
  }) async {
    int attempt = 0;
    Duration delay = _initialDelay;
    NetworkException? lastError;

    while (true) {
      try {
        attempt++;
        final result = await fn().timeout(_requestTimeout);
        // Succès - enregistrer la connexion
        _connectivity.recordConnectionSuccess();
        return result;
      } on TimeoutException catch (e) {
        lastError = e;
        _connectivity.recordConnectionError();
        if (attempt >= maxRetries) {
          debugPrint('❌ Request timeout after $maxRetries attempts');
          rethrow;
        }
        debugPrint('⚠️ Timeout attempt $attempt, retrying in ${delay.inMilliseconds}ms...');
        await Future.delayed(delay);
        delay = Duration(milliseconds: delay.inMilliseconds * 2);
      } on ConnectionException catch (e) {
        lastError = e;
        _connectivity.recordConnectionError();
        if (attempt >= maxRetries) {
          debugPrint('❌ Connection error after $maxRetries attempts');
          rethrow;
        }
        debugPrint('⚠️ Connection error attempt $attempt, retrying...');
        await Future.delayed(delay);
        delay = Duration(milliseconds: delay.inMilliseconds * 2);
      } catch (e) {
        lastError = NetworkExceptionHandler.handleError(error: e);
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
  /// Helper: Get avec cache pour les requêtes fréquentes
  static Future<T> _getCached<T>(
    String cacheKey,
    Future<T> Function() fn,
  ) async {
    // Vérifier le cache d'abord
    final cached = _getCache.get(cacheKey);
    if (cached != null) {
      debugPrint('✅ Cache hit for $cacheKey');
      return cached as T;
    }

    // Faire la requête
    final result = await fn();
    
    // Mettre en cache
    _getCache.set(cacheKey, result);
    return result;
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
  // Read from .env (API_BASE_URL) if provided; otherwise default to localhost
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api';

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
      } else {
        throw Exception('Failed to register: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during registration: $e');
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
      } else {
        throw Exception('Failed to login: ${response.body}');
      }
    } catch (e) {
      throw Exception('Error during login: $e');
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
        final response = await http.get(
          uri,
          headers: {'Content-Type': 'application/json'},
        );

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

  static Future<Map<String, dynamic>> createFarmPost({
    required int farmId,
    required int userId,
    required String title,
    String description = '',
    String? photoUrl,
    String postType = 'crop_update',
    int? cropId,
  }) async {
    try {
      final headers = await _getAuthHeaders();
      final response = await http.post(
        Uri.parse('$baseUrl/farm-network/posts'),
        headers: headers,
        body: jsonEncode({
          'farm_id': farmId,
          'user_id': userId,
          'title': title,
          'description': description,
          'photo_url': photoUrl,
          'post_type': postType,
          'crop_id': cropId,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception('Failed to create post');
      }
    } catch (e) {
      throw Exception('Error creating post: $e');
    }
  }

  static Future<List<dynamic>> getFarmPosts(int farmId) async {
    try {
      return await _withRetry(() async {
        final response = await http.get(
          Uri.parse('$baseUrl/farm-network/posts/farm/$farmId'),
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

  static Future<Map<String, dynamic>> getUserProfile(int userId) async {
    try {
      return await _withRetry(() async {
        final response = await http.get(
          Uri.parse('$baseUrl/users/$userId/profile'),
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

  static Future<List<dynamic>> getUserPosts(int userId, {int skip = 0, int limit = 20}) async {
    try {
      return await _withRetry(() async {
        final response = await http.get(
          Uri.parse('$baseUrl/users/$userId/posts?skip=$skip&limit=$limit'),
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
}
