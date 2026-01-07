import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mbaymi/models/market_model.dart';
import 'package:mbaymi/models/news_model.dart';

class ApiService {
  // For local development on Windows/Web: use localhost
  // For Android Emulator: use 'http://10.0.2.2:8000/api'
  // Read from .env (API_BASE_URL) if provided; otherwise default to localhost
  static String get baseUrl => dotenv.env['API_BASE_URL'] ?? 'http://localhost:8000/api';

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
      final response = await http.get(
        Uri.parse('$baseUrl/farms/$farmId/crops'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
      } else {
        throw Exception('Failed to get farm crops');
      }
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
      final response = await http.get(
        Uri.parse('$baseUrl/farms/user/$userId'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body) as List;
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
      final response = await http.get(
        Uri.parse('$baseUrl/news/agricultural'),
        headers: {'Content-Type': 'application/json'},
      ).timeout(const Duration(seconds: 10));

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
}
