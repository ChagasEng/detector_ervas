import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:geolocator/geolocator.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'ml/weed_detector.dart';
import 'services/weather_service.dart';
import 'widgets/weather_navbar.dart';
import 'models/history_item.dart';
import 'pages/history_page.dart';
import 'services/connectivity_service.dart';
import 'services/chatbase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);

  await Hive.openBox('history');
  await Hive.openBox('chat_queue');

  final conectado = await ConnectivityService.hasConnection();
  if (conectado) {
    ChatbaseService.verifySetup();
    ChatbaseService.resendPending();
  }

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
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green.shade600),
        scaffoldBackgroundColor: const Color(0xFFF3F5F2),
      ),
      home: const WeedHomePage(),
    );
  }
}

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

  Future<Position?> _getLocation() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) return null;
      }
      if (permission == LocationPermission.deniedForever) return null;

      return await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _selecionarImagem({required ImageSource origem}) async {
    final picker = ImagePicker();

    final foto = await picker.pickImage(
      source: origem,
      imageQuality: 65,
      maxWidth: 1200,
    );

    if (foto == null) return;

    final file = File(foto.path);
    setState(() {
      _image = file;
      _label = null;
      _confidence = null;
      _analisando = true;
    });

    final resultado = await _detector.predict(_image!);
    final posicao = await _getLocation();

    setState(() {
      _label = resultado['label'] as String?;
      _confidence = resultado['confidence'] as String?;
      _analisando = false;
    });

    final box = Hive.box('history');

    await box.add(
      HistoryItem(
        imagePath: _image!.path,
        label: _label ?? 'Desconhecido',
        confidence: _confidence ?? '0',
        date: DateTime.now(),
        latitude: posicao?.latitude,
        longitude: posicao?.longitude,
      ).toMap(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isOk = _label == 'Vegetação comum';

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'PlantScan 🌿',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 22,
            letterSpacing: 0.2,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 1,
        actions: [
          IconButton(
            icon: const Icon(Icons.history_rounded, size: 28),
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
                  CircularProgressIndicator(strokeWidth: 3),
                  SizedBox(height: 20),
                  Text("Carregando modelo...", style: TextStyle(fontSize: 16)),
                ],
              ),
            )
          : Column(
              children: [
                WeatherNavBar(weather: _weather, service: _weatherService),
                _buildBody(theme, isOk),
              ],
            ),
    );
  }

  Widget _buildBody(ThemeData theme, bool isOk) {
    return Expanded(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
        child: Column(
          children: [
            _buildImageCard(theme, isOk),
            const SizedBox(height: 35),
            _buildButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildImageCard(ThemeData theme, bool isOk) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.06),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: _image != null
                  ? Image.file(
                      _image!,
                      height: 260,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 260,
                      width: double.infinity,
                      color: const Color(0xFFE9F3E8),
                      child: Icon(
                        Icons.eco_rounded,
                        size: 90,
                        color: Colors.green.shade600,
                      ),
                    ),
            ),
          ),
          const SizedBox(height: 20),
          if (_analisando) _buildLoadingState(theme),
          if (!_analisando && _label != null) _buildResult(theme, isOk),
          if (!_analisando && _label == null)
            Text(
              "Capture ou selecione uma imagem para começar.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Colors.grey.shade700),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingState(ThemeData theme) {
    return Column(
      children: [
        const LinearProgressIndicator(),
        const SizedBox(height: 16),
        Text(
          "Analisando imagem…",
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildResult(ThemeData theme, bool isOk) {
    return Column(
      children: [
        Icon(
          isOk ? Icons.check_circle_rounded : Icons.warning_rounded,
          size: 58,
          color: isOk ? Colors.green : Colors.redAccent,
        ),
        const SizedBox(height: 14),
        Text(
          _label ?? "",
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: isOk ? Colors.green.shade700 : Colors.redAccent,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          "Confiança: ${_confidence ?? '0'}%",
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 22),
        _buildAgronomicCard(isOk),
        const SizedBox(height: 24),
        _buildClearButton(),
      ],
    );
  }

  Widget _buildAgronomicCard(bool isOk) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isOk ? Colors.green.shade200 : Colors.red.shade200,
          width: 1.4,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            isOk ? "Vegetação Comum" : "Possível Planta Daninha",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isOk ? Colors.green.shade600 : Colors.red.shade600,
            ),
          ),
          const SizedBox(height: 12),
          if (!isOk) ...[
            const Text(
              "Recomendação Agronômica:",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              "• Verifique a área ao redor.\n"
              "• Avalie a densidade da infestação.\n"
              "• Monitore nos próximos dias.\n"
              "• Se aumentar, adote manejo mecânico ou químico.",
              style: TextStyle(
                fontSize: 15,
                height: 1.4,
                color: Colors.grey.shade700,
              ),
            ),
          ],
          if (isOk)
            Text(
              "Esta planta não parece representar risco agronômico.",
              style: TextStyle(fontSize: 15, color: Colors.grey.shade700),
            ),
        ],
      ),
    );
  }

  Widget _buildClearButton() {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: () {
          setState(() {
            _image = null;
            _label = null;
            _confidence = null;
          });
        },
        icon: const Icon(Icons.refresh_rounded),
        label: const Text(
          "Limpar análise",
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600),
        ),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 18),
          backgroundColor: Colors.green.shade600,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
      ),
    );
  }

  Widget _buildButtons() {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: _analisando
                ? null
                : () => _selecionarImagem(origem: ImageSource.camera),
            icon: const Icon(Icons.camera_alt_rounded, size: 24),
            label: const Text("Usar Câmera"),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _analisando
                ? null
                : () => _selecionarImagem(origem: ImageSource.gallery),
            icon: const Icon(Icons.photo_library_rounded, size: 24),
            label: const Text("Escolher da Galeria"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 18),
              foregroundColor: Colors.green.shade700,
              side: BorderSide(color: Colors.green.shade600, width: 1.6),
              textStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
