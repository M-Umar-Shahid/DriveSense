import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class DistractionDetector {
  late Interpreter _interpreter;
  CameraController? _cameraController;
  Timer? _timer;
  bool _initialized = false;

  /// Callback: isDistracted = true if class != 0, predictedClass ∈ 0–9
  Function(bool isDistracted, int predictedClass)? onResult;

  /// Initialize model & camera
  Future<void> init(CameraDescription camera, {Function(bool, int)? onDetection}) async {
    if (_initialized) {
      print("⚠️ DistractionDetector already initialized.");
      return;
    }

    try {
      _interpreter = await Interpreter.fromAsset('assets/models/distraction_model.tflite');
      _cameraController = CameraController(camera, ResolutionPreset.medium, enableAudio: false);
      await _cameraController!.initialize();
      onResult = onDetection;
      _initialized = true;
      print("✅ DistractionDetector initialized.");
    } catch (e) {
      print("❌ Failed to initialize DistractionDetector: $e");
    }
  }

  /// Start periodic detection
  void startDetection() {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      print("❌ CameraController not ready.");
      return;
    }
    print("▶️ Starting distraction detection every 15 seconds.");
    _timer = Timer.periodic(const Duration(seconds: 15), (_) => _analyzeFrame());
  }

  /// Stop detection and dispose camera safely
  void stopDetection() {
    print("⏹️ Stopping detection and disposing camera.");
    _timer?.cancel();
    _timer = null;
    _cameraController?.dispose();
    _cameraController = null;
    _initialized = false;
  }

  /// Analyze one frame for distraction
  Future<void> _analyzeFrame() async {
    if (_cameraController == null ||
        !_cameraController!.value.isInitialized ||
        _cameraController!.value.isTakingPicture) return;

    try {
      final file = await _cameraController!.takePicture();
      final imageBytes = await File(file.path).readAsBytes();
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return;

      final input = _preprocessImage(originalImage);
      final output = List.generate(1, (_) => List.filled(10, 0.0));
      _interpreter.run(input, output);

      final int predictedClass =
      output[0].indexWhere((e) => e == output[0].reduce(max));
      final isDistracted = predictedClass != 0;

      print("🧠 Distraction check → class: $predictedClass (${isDistracted ? "Distracted" : "Safe"})");

      onResult?.call(isDistracted, predictedClass);
    } catch (e) {
      print("❌ Error during frame analysis: $e");
    }
  }

  /// Preprocess image for model input
  List<List<List<List<double>>>> _preprocessImage(img.Image image) {
    final resized = img.copyResize(image, width: 224, height: 224);
    return List.generate(1, (_) =>
        List.generate(224, (y) =>
            List.generate(224, (x) {
              final pixel = resized.getPixel(x, y);
              final r = pixel.r.toDouble();
              final g = pixel.g.toDouble();
              final b = pixel.b.toDouble();
              return [r / 255.0, g / 255.0, b / 255.0];
            })));
  }

  CameraController? get cameraController => _cameraController;
}
