import 'dart:io';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceEnrollmentService {
  CameraController? controller;
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
      FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate, enableContours: false, enableLandmarks: false)
  );
  Interpreter? _interpreter;
  bool get isReady => controller?.value.isInitialized == true && _interpreter != null;

  Future<void> init() async {
    final cams = await availableCameras();
    final front = cams.firstWhere((c) => c.lensDirection == CameraLensDirection.front, orElse: () => cams.first);
    controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await controller!.initialize();
    _interpreter = await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
  }

  Future<List<double>?> captureEmbedding() async {
    if (!isReady) return null;
    final pic = await controller!.takePicture();
    final bytes = await File(pic.path).readAsBytes();
    final frame = img.decodeImage(bytes)!;
    final inputImage = InputImage.fromFilePath(pic.path);
    final faces = await _faceDetector.processImage(inputImage);
    if (faces.isEmpty) return null;
    final box = faces.first.boundingBox;
    final crop = img.copyCrop(
        frame,
        x: box.left.toInt().clamp(0, frame.width),
        y: box.top.toInt().clamp(0, frame.height),
        width: box.width.toInt().clamp(0, frame.width),
        height: box.height.toInt().clamp(0, frame.height)
    );
    final face112 = img.copyResize(crop, width: 112, height: 112);
    return _getEmbedding(face112);
  }

  Future<List<double>> _getEmbedding(img.Image faceImg) async {
    final input = List.generate(1, (_) =>
        List.generate(112, (_) =>
            List.generate(112, (_) => List.filled(3, 0.0))
        )
    );
    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        final px = faceImg.getPixel(x, y);
        input[0][y][x][0] = (px.r - 127.5) / 128;
        input[0][y][x][1] = (px.g - 127.5) / 128;
        input[0][y][x][2] = (px.b - 127.5) / 128;
      }
    }
    final outShape = _interpreter!.getOutputTensor(0).shape;
    final output = List.generate(1, (_) => List.filled(outShape[1], 0.0));
    _interpreter!.run(input, output);
    return List<double>.from(output[0]);
  }

  void dispose() {
    controller?.dispose();
    _faceDetector.close();
    _interpreter?.close();
  }
}
