import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class WeedDetector {
  late Interpreter _interpreter;
  late List<String> _labels;

  WeedDetector() {
    loadModel();
  }

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

  Future<void> loadModel() async {
    try {
      _interpreter = await Interpreter.fromAsset(
        'assets/icons/models/weed_detector_compat.tflite',
      );
      print('✅ Modelo carregado com sucesso!');

      _labels = await _loadLabels();
      print('✅ Labels carregados (${_labels.length}): $_labels');
    } catch (e) {
      print('❌ Erro ao carregar modelo/labels: $e');
    }
  }

  Future<List<String>> _loadLabels() async {
    try {
      final raw = await rootBundle.loadString('assets/icons/models/labels.txt');
      return raw
          .split('\n')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    } catch (e) {
      print('⚠️ labels.txt não encontrado.');
      return [];
    }
  }

  Uint8List _preprocess(File imageFile) {
    final imageBytes = imageFile.readAsBytesSync();
    img.Image? image = img.decodeImage(imageBytes);

    if (image == null) {
      throw Exception("Erro ao decodificar imagem");
    }

    img.Image resized = img.copyResize(image, width: 224, height: 224);

    Float32List input = Float32List(224 * 224 * 3);
    int pixelIndex = 0;

    for (int y = 0; y < 224; y++) {
      for (int x = 0; x < 224; x++) {
        final pixel = resized.getPixel(x, y);
        input[pixelIndex++] = pixel.r / 255.0;
        input[pixelIndex++] = pixel.g / 255.0;
        input[pixelIndex++] = pixel.b / 255.0;
      }
    }

    return input.buffer.asUint8List();
  }

  Future<Map<String, dynamic>> predict(File imageFile) async {
    try {
      if (_labels.isEmpty) {
        throw Exception("Labels não carregados");
      }

      var input = _preprocess(imageFile);
      var output = List.filled(
        _labels.length,
        0.0,
      ).reshape([1, _labels.length]);

      _interpreter.run(input, output);

      int maxIndex = 0;
      double maxValue = output[0][0];
      for (int i = 1; i < _labels.length; i++) {
        if (output[0][i] > maxValue) {
          maxValue = output[0][i];
          maxIndex = i;
        }
      }

      String original = _labels[maxIndex];
      String traduzido = _traducao[original] ?? original;

      print(
        '🌿 Predição: $traduzido (${(maxValue * 100).toStringAsFixed(2)}%)',
      );

      return {
        'label': traduzido,
        'confidence': (maxValue * 100).toStringAsFixed(2),
      };
    } catch (e) {
      print('❌ Erro na predição: $e');
      return {'label': 'Erro', 'confidence': '0'};
    }
  }
}
