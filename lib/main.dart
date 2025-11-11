import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'ml/weed_detector.dart';
import 'services/weather_service.dart';
import 'widgets/weather_navbar.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'models/history_item.dart';
import 'pages/history_page.dart';
import 'pages/chat_page.dart'; // 💬 tela de chat IA
import 'services/connectivity_service.dart'; // 🌐 checa conexão
import 'services/chatbase_service.dart'; // 🤖 integração com Chatbase

// =====================================================
// APP PRINCIPAL
// =====================================================
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 📦 Inicializa Hive
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  await Hive.openBox('history');     // histórico de análises
  await Hive.openBox('chat_queue');  // fila de mensagens offline

  // 🌐 Verifica conexão inicial
  await ConnectivityService.hasConnection();

  // 🤖 Valida configuração da IA Chatbase
  await ChatbaseService.verifySetup();

  // 📡 Reenvia mensagens pendentes se houver
  await ChatbaseService.resendPending();

  runApp(const WeedApp());
}

class WeedApp extends StatelessWidget {
  const WeedApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PlantScan 🌿',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primarySwatch: Colors.green,
        scaffoldBackgroundColor: const Color(0xFFF7F7FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          centerTitle: true,
        ),
      ),
      home: const WeedHomePage(),
    );
  }
}

// =====================================================
// TELA PRINCIPAL (Detecção de Ervas Daninhas)
// =====================================================
class WeedHomePage extends StatefulWidget {
  const WeedHomePage({super.key});

  @override
  State<WeedHomePage> createState() => _WeedHomePageState();
}

class _WeedHomePageState extends State<WeedHomePage> {
  final WeedDetector _detector = WeedDetector();
  final WeatherService _weatherService = WeatherService();

  File? _image;
  String? _label;
  String? _confidence;
  bool _carregandoModelo = true;
  bool _analisando = false;
  Map<String, dynamic>? _weather;

  @override
  void initState() {
    super.initState();
    _initModel();
    _loadWeather();
  }

  Future<void> _initModel() async {
    await _detector.loadModel();
    setState(() => _carregandoModelo = false);
  }

  Future<void> _loadWeather() async {
    final w = await _weatherService.getWeather();
    setState(() => _weather = w);
  }

  /// 🧭 Obter localização atual
  Future<Position?> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        await Geolocator.openLocationSettings();
        return null;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }

      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (e) {
      debugPrint('Erro ao obter localização: $e');
      return null;
    }
  }

  /// 📸 Escolher imagem (câmera ou galeria)
  Future<void> _selecionarImagem({required ImageSource origem}) async {
    final picker = ImagePicker();
    final foto = await picker.pickImage(
      source: origem,
      imageQuality: 60,
      maxWidth: 1024,
    );

    if (foto == null) return;

    setState(() {
      _image = File(foto.path);
      _label = null;
      _confidence = null;
      _analisando = true;
    });

    await Future.delayed(const Duration(milliseconds: 200));
    final resultado = await _detector.predict(_image!);
    await Future.delayed(const Duration(milliseconds: 500));

    final posicao = await _getLocation();

    setState(() {
      _label = resultado['label'] as String?;
      _confidence = resultado['confidence'] as String?;
      _analisando = false;
    });

    // 💾 salva no histórico Hive
    final box = Hive.box('history');
    final item = HistoryItem(
      imagePath: _image!.path,
      label: _label ?? 'Desconhecido',
      confidence: _confidence ?? '0',
      date: DateTime.now(),
      latitude: posicao?.latitude,
      longitude: posicao?.longitude,
    );
    await box.add(item.toMap());
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bool isVegetacaoComum = _label == 'Vegetação comum';

    return Scaffold(
      appBar: AppBar(
        title: const Text('PlantScan 🌿', style: TextStyle(fontWeight: FontWeight.w600)),
        actions: [
          // 🕓 Histórico
          IconButton(
            icon: const Icon(Icons.history_rounded, color: Colors.green),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HistoryPage()),
              );
            },
          ),
        ],
      ),
      body: _carregandoModelo
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 16),
                  Text(
                    'Carregando modelo de IA...\nAguarde um instante.',
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          : Column(
              children: [
                // 🌦️ Clima no topo
                WeatherNavBar(weather: _weather, service: _weatherService),

                // Conteúdo principal
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        // CARD IMAGEM
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(24),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 15,
                                offset: const Offset(0, 8),
                              ),
                            ],
                          ),
                          child: Column(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(18),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 300),
                                  child: _image != null
                                      ? Image.file(
                                          _image!,
                                          key: ValueKey(_image?.path),
                                          height: 260,
                                          width: double.infinity,
                                          fit: BoxFit.cover,
                                        )
                                      : Container(
                                          key: const ValueKey('placeholder'),
                                          height: 260,
                                          width: double.infinity,
                                          color: const Color(0xFFE8F5E9),
                                          child: Icon(
                                            Icons.nature,
                                            size: 80,
                                            color: Colors.green.shade700,
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(height: 16),
                              if (_analisando) ...[
                                const LinearProgressIndicator(),
                                const SizedBox(height: 12),
                                Text(
                                  '🔎 Analisando imagem...',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                              ] else if (_label != null && _confidence != null) ...[
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      isVegetacaoComum
                                          ? Icons.check_circle_outline
                                          : Icons.warning_amber_rounded,
                                      color: isVegetacaoComum
                                          ? Colors.green
                                          : Colors.redAccent,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Resultado:',
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  '$_label (${_confidence}%)',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleLarge?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: isVegetacaoComum
                                        ? Colors.green.shade700
                                        : Colors.redAccent,
                                  ),
                                ),
                              ] else ...[
                                const SizedBox(height: 8),
                                Text(
                                  'Tire ou selecione uma foto da planta para iniciar a análise.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    color: Colors.grey[700],
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                        // BOTÕES
                        Row(
                          children: [
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _analisando
                                    ? null
                                    : () => _selecionarImagem(origem: ImageSource.camera),
                                icon: const Icon(Icons.camera_alt),
                                label: const Text('Câmera'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.green.shade600,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: _analisando
                                    ? null
                                    : () => _selecionarImagem(origem: ImageSource.gallery),
                                icon: const Icon(Icons.photo_library_outlined),
                                label: const Text('Galeria'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.teal.shade400,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                  textStyle: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
