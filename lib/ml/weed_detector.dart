import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class WeedDetector {
  late Interpreter _interpreter;
  late List<String> _labels;

  /// Dicionário de tradução dos nomes das classes (Inglês → Português)
  final Map<String, String> _traducao = {
    "Chinee apple": "Maçã Chinesa",
    "Lantana": "Lantana",
    "Parkinsonia": "Parkinsonia",
    "Parthenium": "Parthênio",
    "Prickly acacia": "Acácia-espinhosa",
    "Rubber vine": "Cipó-de-borracha",
    "Siam weed": "Erva-de-Siam",
    "Snake weed": "Erva-de-cobra",
    "Negatives": "Vegetação comum",
  };

  /// Inicializa o modelo e carrega os labels
  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/icons/models/weed_detector.tflite',
      );
      print('✅ Modelo carregado com sucesso');

      _labels = await _loadLabels();
      print('✅ Labels carregados: $_labels');
    } catch (e) {
      print('❌ Erro ao carregar modelo: $e');
    }
  }

  /// Carrega o arquivo labels.txt com os nomes das classes
  Future<List<String>> _loadLabels() async {
    try {
      final raw = await rootBundle.loadString('assets/icons/models/labels.txt');
      return raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      print('⚠️ Nenhum arquivo labels.txt encontrado.');
      return [];
    }
  }

  /// Pré-processa a imagem (redimensiona e normaliza)
  Uint8List _preprocess(File imageFile) {
    final imageBytes = imageFile.readAsBytesSync();
    img.Image? image = img.decodeImage(imageBytes);
    img.Image resized = img.copyResize(image!, width: 224, height: 224);

    Float32List input = Float32List(224 * 224 * 3);
    int pixelIndex = 0;

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        final int red = pixel.r.toInt();
        final int green = pixel.g.toInt();
        final int blue = pixel.b.toInt();
        input[pixelIndex++] = red.toDouble() / 255.0;
        input[pixelIndex++] = green.toDouble() / 255.0;
        input[pixelIndex++] = blue.toDouble() / 255.0;
      }
    }

    return input.buffer.asUint8List();
  }

  /// Executa a predição e retorna o nome traduzido
  Future<Map<String, dynamic>> predict(File imageFile) async {
    try {
      var input = _preprocess(imageFile);
      var output = List.filled(_labels.length, 0.0).reshape([1, _labels.length]);

      _interpreter.run(input, output);

      // Encontra o índice da maior probabilidade
      int maxIndex = 0;
      double maxValue = 0.0;
      for (int i = 0; i < _labels.length; i++) {
        if (output[0][i] > maxValue) {
          maxValue = output[0][i];
          maxIndex = i;
        }
      }

      // Nome original da classe
      String labelOriginal =
          _labels.isNotEmpty ? _labels[maxIndex] : 'Classe ${maxIndex + 1}';

      // Tradução (caso exista no mapa)
      String labelTraduzido = _traducao[labelOriginal] ?? labelOriginal;

      print(
          '🌿 Predição: $labelTraduzido (${(maxValue * 100).toStringAsFixed(2)}%)');

      return {
        'label': labelTraduzido,
        'confidence': (maxValue * 100).toStringAsFixed(2),
      };
    } catch (e) {
      print('❌ Erro na predição: $e');
      return {'label': 'Erro', 'confidence': '0'};
    }
  }
}
