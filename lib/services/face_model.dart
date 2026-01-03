import 'dart:io';
import 'dart:math' as math;
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceNet {
  static final FaceNet _singleton = FaceNet._();
  factory FaceNet() => _singleton;
  FaceNet._();

  Interpreter? _interpreter;
  bool get isLoaded => _interpreter != null;

  Future<void> loadModel({int threads = 4}) async {
    if (_interpreter != null) return;
    final options = InterpreterOptions()..threads = threads;
    _interpreter = await Interpreter.fromAsset('assets/models/facenet.tflite', options: options);
    // NOTE: some versions want 'models/facenet.tflite' depending on your asset path; use what you declared.
  }

  /// Given a File (image path) and optional faceRect (pixel coordinates),
  /// returns a normalized 128-d embedding.
  Future<List<double>> getEmbedding(File imageFile, {ui.Rect? faceRect}) async {
    if (_interpreter == null) {
      await loadModel();
    }

    // 1) Decode image
    final bytes = await imageFile.readAsBytes();
    img.Image? image = img.decodeImage(bytes);
    if (image == null) throw Exception('Cannot decode image');

    // 2) Crop to faceRect if provided (ensure bounds)
    if (faceRect != null) {
      final left = faceRect.left.clamp(0, image.width - 1).toInt();
      final top = faceRect.top.clamp(0, image.height - 1).toInt();
      final w = faceRect.width.clamp(1, image.width - left).toInt();
      final h = faceRect.height.clamp(1, image.height - top).toInt();
      image = img.copyCrop(image, left, top, w, h);
    }

    // 3) Resize to 160x160 (FaceNet default)
    final resized = img.copyResize(image, width: 160, height: 160);

    // 4) Normalize to float32 [-1,1]
    final input = List.generate(1, (_) => List.generate(160, (_) => List.generate(160, (_) => List.filled(3, 0.0))));
    for (int y = 0; y < 160; y++) {
      for (int x = 0; x < 160; x++) {
        final pixel = resized.getPixel(x, y);
        final r = img.getRed(pixel).toDouble();
        final g = img.getGreen(pixel).toDouble();
        final b = img.getBlue(pixel).toDouble();
        // normalization often used with facenet: (pixel - 127.5) / 128
        input[0][y][x][0] = (r - 127.5) / 128.0;
        input[0][y][x][1] = (g - 127.5) / 128.0;
        input[0][y][x][2] = (b - 127.5) / 128.0;
      }
    }

    // 5) Run interpreter
    var output = List.generate(1, (_) => List.filled(128, 0.0));
    _interpreter!.run(input, output);

    // 6) L2 normalize
    List<double> embedding = List<double>.from(output[0]);
    double sum = 0;
    for (final v in embedding) sum += v * v;
    final norm = math.sqrt(sum);
    if (norm > 0) {
      for (int i = 0; i < embedding.length; i++) {
        embedding[i] = embedding[i] / norm;
      }
    }
    return embedding;
  }

  void close() {
    _interpreter?.close();
    _interpreter = null;
  }
}
