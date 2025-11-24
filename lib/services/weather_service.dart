import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';

class WeatherService {
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

      final lat = position.latitude;
      final lon = position.longitude;

      print("📍 Posição: $lat, $lon");

      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current_weather=true',
      );

      final weatherResp = await http.get(weatherUrl);
      print("🌦️ Status clima: ${weatherResp.statusCode}");

      if (weatherResp.statusCode != 200) {
        return _loadCachedWeather();
      }

      final weatherJson = jsonDecode(weatherResp.body);
      final weather = weatherJson["current_weather"];

      if (weather == null) {
        print("⚠️ Clima retornou nulo");
        return _loadCachedWeather();
      }

      final geoUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/reverse?format=jsonv2&lat=$lat&lon=$lon&zoom=18&addressdetails=1',
      );

      final geoResp = await http.get(
        geoUrl,
        headers: {
          'User-Agent': 'PlantScanApp/1.0 (matheus@app.com)',
        },
      );

      print("📡 Status geocodificação: ${geoResp.statusCode}");

      String? cidade;
      String? estado;

      if (geoResp.statusCode == 200) {
        final geoData = jsonDecode(geoResp.body);
        final addr = geoData["address"] ?? {};

        cidade =
            addr["city"] ??
            addr["town"] ??
            addr["village"] ??
            addr["municipality"] ??
            addr["county"];

        estado = addr["state"];
      }

      cidade ??= "Cidade não localizada";
      estado ??= "Estado não identificado";

      final prefs = await SharedPreferences.getInstance();
      final cachedData = {
        "time": DateTime.now().toIso8601String(),
        "temperature": weather["temperature"] ?? 0.0,
        "windspeed": weather["windspeed"] ?? 0.0,
        "weathercode": weather["weathercode"] ?? 0,
        "city": cidade,
        "state": estado,
      };

      await prefs.setString("weather_cache", jsonEncode(cachedData));
      print("✅ Salvo no cache: $cachedData");

      return cachedData;
    } catch (e) {
      print("❌ Erro inesperado: $e");
      return _loadCachedWeather();
    }
  }

  Future<Map<String, dynamic>?> _loadCachedWeather() async {
    final prefs = await SharedPreferences.getInstance();
    final data = prefs.getString("weather_cache");

    if (data != null) {
      print("🌤️ Recuperado do cache!");
      return jsonDecode(data);
    }

    print("⚠️ Cache vazio.");
    return null;
  }

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
        return "🌧️ Chuva";
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
