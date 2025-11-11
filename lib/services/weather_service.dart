import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
  /// Busca a previsão do tempo e o nome da cidade
  Future<Map<String, dynamic>?> getWeather() async {
    try {
      print('🌍 Iniciando busca de clima...');

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('❌ Serviço de localização desativado.');
        return _loadCachedWeather();
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('⚠️ Permissão negada pelo usuário.');
          return _loadCachedWeather();
        }
      }

      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.low,
      );
      print('📍 Localização: ${position.latitude}, ${position.longitude}');

      final lat = position.latitude;
      final lon = position.longitude;

      // Consulta clima
      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true',
      );
      final weatherResp = await http.get(weatherUrl);
      print('🌦️ Clima: ${weatherResp.statusCode}');

      if (weatherResp.statusCode != 200) {
        return _loadCachedWeather();
      }

      final weatherData = jsonDecode(weatherResp.body);
      final weather = weatherData['current_weather'];
      if (weather == null) {
        print('⚠️ API retornou sem campo current_weather.');
        return _loadCachedWeather();
      }

      // Consulta cidade
      final geoUrl = Uri.parse(
        'https://geocode.maps.co/reverse?lat=$lat&lon=$lon',
      );
      final geoResp = await http.get(geoUrl);
      print('📡 Geolocalização: ${geoResp.statusCode}');

      String? cidade;
      if (geoResp.statusCode == 200) {
        final geoData = jsonDecode(geoResp.body);
        cidade =
            geoData['address']?['city'] ??
            geoData['address']?['town'] ??
            geoData['address']?['village'] ??
            geoData['address']?['state'];
      }

      final prefs = await SharedPreferences.getInstance();
      final cachedData = {
        'time': DateTime.now().toIso8601String(),
        'temperature': weather['temperature'] ?? 0.0,
        'windspeed': weather['windspeed'] ?? 0.0,
        'weathercode': weather['weathercode'] ?? 0,
        'city': cidade ?? 'Local desconhecido',
      };

      await prefs.setString('weather_cache', jsonEncode(cachedData));
      print('✅ Clima salvo e retornado: $cachedData');
      return cachedData;
    } catch (e) {
      print('⚠️ Erro inesperado: $e');
      return _loadCachedWeather();
    }
  }

  /// 🔄 Carrega cache local caso não haja conexão
  Future<Map<String, dynamic>?> _loadCachedWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString('weather_cache');
    if (cached != null) {
      print('🌤️ Dados de clima carregados do cache.');
      return jsonDecode(cached);
    }
    print('⚠️ Nenhum cache de clima encontrado.');
    return null;
  }

  /// 🌦️ Converte o código da condição (Open-Meteo) em texto + emoji
  String describeWeather(int code) {
    switch (code) {
      case 0:
        return "☀️ Céu limpo";
      case 1:
      case 2:
      case 3:
        return "🌤️ Parcialmente nublado";
      case 45:
      case 48:
        return "🌫️ Neblina";
      case 51:
      case 53:
      case 55:
      case 61:
      case 63:
      case 65:
        return "🌧️ Chuva leve";
      case 71:
      case 73:
      case 75:
        return "❄️ Neve";
      case 95:
      case 96:
      case 99:
        return "⛈️ Tempestade";
      default:
        return "🌦️ Tempo instável";
    }
  }
}
