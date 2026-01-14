import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/foundation.dart';

class WeatherService {
  // 🌍 Configuration géographique
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
  
  /// 🎯 Récupérer les données météo pour Dakar
  static Future<Map<String, dynamic>> getWeather() async {
    try {
      final response = await http.get(
        Uri.parse(
          '$OPENMETEO_API_URL?latitude=$DAKAR_LATITUDE&longitude=$DAKAR_LONGITUDE&current=temperature_2m,weather_code,is_day&daily=temperature_2m_max,temperature_2m_min,weather_code&timezone=$DAKAR_TIMEZONE',
        ),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'current_temp': data['current']['temperature_2m'],
          'weather_code': data['current']['weather_code'],
          'max_temp': data['daily']['temperature_2m_max'][0],
          'min_temp': data['daily']['temperature_2m_min'][0],
          'daily_weather_code': data['daily']['weather_code'][0],
        };
      } else {
        throw Exception('Erreur météo: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('❌ Weather fetch error: $e');
      // Retourner des valeurs par défaut en cas d'erreur
      return _getDefaultWeather();
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
    'current_temp': 22.0,
    'weather_code': 0,
    'max_temp': 26.0,
    'min_temp': 18.0,
    'daily_weather_code': 0,
  };
}
