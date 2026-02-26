import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  // 🌍 Configuration géographique - DAKAR PAR DÉFAUT
  static const double DAKAR_LATITUDE = 14.6667;
  static const double DAKAR_LONGITUDE = -17.0382;
  static const String DAKAR_TIMEZONE = 'Africa/Dakar';
  
  // 🌡️ Codes météo
  static const int RAIN_CODE_80 = 80;  // Light rain
  static const int RAIN_CODE_81 = 81;  // Moderate rain
  static const int RAIN_CODE_82 = 82;  // Heavy rain
  
  // 🌤️ Seuils de température
  static const double TEMP_HOT_THRESHOLD = 28.0;
  static const double TEMP_COLD_THRESHOLD = 20.0;
  
  // 🌐 API
  static const String OPENMETEO_API_URL = 'https://api.open-meteo.com/v1/forecast';
  static const String REVERSE_GEOCODING_API = 'https://nominatim.openstreetmap.org/reverse';
  
  /// 🎯 Récupérer les données météo (avec GPS dynamique ou Dakar par défaut)
  static Future<Map<String, dynamic>> getWeather({bool useGPS = false}) async {
    try {
      double lat = DAKAR_LATITUDE;
      double lon = DAKAR_LONGITUDE;
      String location = 'Dakar';
      
      // 🌐 Si GPS demandé, essayer de récupérer les coordonnées
      if (useGPS) {
        try {
          final position = await _getGPSLocation();
          if (position != null) {
            lat = position.latitude;
            lon = position.longitude;
            location = await _reverseGeocode(lat, lon) ?? 'GPS ($lat, $lon)';
            debugPrint('📍 GPS Location: $location ($lat, $lon)');
          }
        } catch (e) {
          debugPrint('⚠️ GPS failed, using Dakar: $e');
          // Fallback to Dakar
        }
      }

      // 🌐 Appel API avec paramètres complétés
      final url = '$OPENMETEO_API_URL'
          '?latitude=$lat'
          '&longitude=$lon'
          '&current=temperature_2m,apparent_temperature,weather_code,is_day'
          '&daily=temperature_2m_max,temperature_2m_min,apparent_temperature_max,apparent_temperature_min,weather_code'
          '&timezone=$DAKAR_TIMEZONE';

      debugPrint('🌐 Weather API Request: $url');
      
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        // 📝 LOG COMPLET DE LA RÉPONSE JSON
        debugPrint('═══════════════════════════════════════════════════════════');
        debugPrint('✅ RÉPONSE MÉTÉO COMPLÈTE (JSON):');
        debugPrint(json.encode(data));
        debugPrint('═══════════════════════════════════════════════════════════');

        final weatherData = {
          'location': location,
          'latitude': lat,
          'longitude': lon,
          'current_temp': data['current']['temperature_2m'],
          'apparent_temp': data['current']['apparent_temperature'], // ⭐ RESSENTI ACTUEL
          'weather_code': data['current']['weather_code'],
          'max_temp': data['daily']['temperature_2m_max'][0],
          'min_temp': data['daily']['temperature_2m_min'][0],
          'apparent_temp_max': data['daily']['apparent_temperature_max'][0], // ⭐ RESSENTI MAX
          'apparent_temp_min': data['daily']['apparent_temperature_min'][0], // ⭐ RESSENTI MIN
          'daily_weather_code': data['daily']['weather_code'][0],
        };
        
        // 📝 LOG DES CHAMPS EXTRAITS
        debugPrint('📊 CHAMPS AFFICHÉS:');
        debugPrint('  Location: ${weatherData['location']}');
        debugPrint('  GPS: (${weatherData['latitude']}, ${weatherData['longitude']})');
        debugPrint('  Temp actuelle: ${weatherData['current_temp']}°C');
        debugPrint('  Ressenti actuel: ${weatherData['apparent_temp']}°C');
        debugPrint('  Max jour: ${weatherData['max_temp']}°C (ressenti: ${weatherData['apparent_temp_max']}°C)');
        debugPrint('  Min jour: ${weatherData['min_temp']}°C (ressenti: ${weatherData['apparent_temp_min']}°C)');
        
        return weatherData;
      } else {
        throw Exception('Erreur météo: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Weather fetch error: $e');
      return _getDefaultWeather();
    }
  }

  /// 📍 Récupérer la position GPS
  static Future<Position?> _getGPSLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        debugPrint('⚠️ Location services disabled');
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        debugPrint('⚠️ Location permission denied');
        return null;
      }

      return await Geolocator.getCurrentPosition(
        timeLimit: const Duration(seconds: 10),
      );
    } catch (e) {
      debugPrint('❌ GPS Error: $e');
      return null;
    }
  }

  /// 🗺️ Reverse geocode (coordonnées → nom de la ville)
  static Future<String?> _reverseGeocode(double lat, double lon) async {
    try {
      final url = '$REVERSE_GEOCODING_API?format=json&lat=$lat&lon=$lon';
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final address = data['address'];
        return address['city'] ?? address['town'] ?? address['village'] ?? 'Localisation inconnue';
      }
      return null;
    } catch (e) {
      debugPrint('⚠️ Reverse geocoding error: $e');
      return null;
    }
  }

  /// 💭 Conseil météo texte
  static String getWeatherAdvice(int weatherCode, double maxTemp) {
    if (_isRaining(weatherCode)) {
      return 'Pluies prévues';
    } else if (maxTemp > TEMP_HOT_THRESHOLD) {
      return 'Forte chaleur prévue';
    } else if (maxTemp < TEMP_COLD_THRESHOLD) {
      return 'Temps frais';
    } else {
      return 'Ciel dégagé';
    }
  }

  /// 💧 Conseil arrosage
  static String getWateringAdvice(int weatherCode, double maxTemp) {
    if (_isRaining(weatherCode)) {
      return 'Pluies en cours - Attendez avant d\'arroser';
    } else if (maxTemp > TEMP_HOT_THRESHOLD) {
      return 'Arrosez vos cultures avant 8h pour limiter l\'évaporation';
    } else {
      return 'Arrosez le matin entre 7h-9h pour une meilleure absorption';
    }
  }

  /// 🌧️ Vérifier si c'est la pluie
  static bool _isRaining(int weatherCode) {
    return weatherCode == RAIN_CODE_80 || 
           weatherCode == RAIN_CODE_81 || 
           weatherCode == RAIN_CODE_82;
  }

  /// 🔧 Valeurs par défaut
  static Map<String, dynamic> _getDefaultWeather() => {
    'location': 'Dakar',
    'latitude': DAKAR_LATITUDE,
    'longitude': DAKAR_LONGITUDE,
    'current_temp': 22.0,
    'apparent_temp': 19.0,
    'weather_code': 0,
    'max_temp': 26.0,
    'min_temp': 18.0,
    'apparent_temp_max': 24.0,
    'apparent_temp_min': 16.0,
    'daily_weather_code': 0,
  };
}
