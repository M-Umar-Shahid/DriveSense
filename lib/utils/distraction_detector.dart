import 'dart:async';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class DistractionDetector {
  late Interpreter _interpreter;

  /// Loads the TFLite model from assets
  Future<void> loadModel() async {
    _interpreter = await Interpreter.fromAsset('assets/models/distraction_model.tflite');
    print("✅ Distraction model loaded.");
  }

  /// Runs inference and returns the 10-class output
  List<double> run(List<List<List<List<double>>>> input) {
    final output = List.generate(1, (_) => List.filled(10, 0.0));
    _interpreter.run(input, output);
    return output[0];
  }

  /// Preprocesses image to MobileNet input format: 224x224 RGB [-1, 1]
  List<List<List<List<double>>>> preprocessImage(img.Image image) {
    final resized = img.copyResize(image, width: 224, height: 224);
    return List.generate(1, (_) =>
        List.generate(224, (y) =>
            List.generate(224, (x) {
              final pixel = resized.getPixel(x, y);
              final r = (pixel.r.toDouble() / 127.5) - 1.0;
              final g = (pixel.g.toDouble() / 127.5) - 1.0;
              final b = (pixel.b.toDouble() / 127.5) - 1.0;
              return [r, g, b];
            })
        ));
  }
}
