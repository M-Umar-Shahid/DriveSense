import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceEnrollmentService {
  CameraController? controller;
  final _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableContours: false,
      enableLandmarks: false,
    ),
  );
  Interpreter? _interpreter;

  bool get isReady =>
      controller?.value.isInitialized == true && _interpreter != null;

  Future<void> init() async {
    final cams = await availableCameras();
    final front = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cams.first,
    );
    controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await controller!.initialize();
    _interpreter = await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
  }

  Future<List<double>?> captureEmbedding() async {
    if (!isReady) return null;
    try {
      // 1) capture photo
      final pic = await controller!.takePicture();
      final path = pic.path;

      // 2) run ML Kit on the file
      final inputImage = InputImage.fromFilePath(path);
      final faces = await _faceDetector.processImage(inputImage);
      debugPrint("🔍 Face detector found ${faces.length} faces");

      if (faces.isEmpty) {
        // no face → clean up and return
        await File(path).delete();
        return null;
      }

      // 3) read bytes into memory so we can delete the file safely
      final bytes = await File(path).readAsBytes();
      await File(path).delete();

      // 4) decode & mirror
      img.Image frame = img.decodeImage(bytes)!;
      frame = img.flipHorizontal(frame);

      // 5) crop & resize
      final box = faces.first.boundingBox;
      final x = box.left.toInt().clamp(0, frame.width - 1);
      final y = box.top.toInt().clamp(0, frame.height - 1);
      final w = box.width.toInt().clamp(1, frame.width - x);
      final h = box.height.toInt().clamp(1, frame.height - y);
      final crop = img.copyCrop(frame, x: x, y: y, width: w, height: h);
      final face112 = img.copyResizeCropSquare(crop, size: 112);

      // 6) run embedding model
      final embedding = await _getEmbedding(face112);
      debugPrint("✅ Generated embedding length ${embedding.length}");
      return embedding;
    } catch (e) {
      debugPrint("⚠️ captureEmbedding error: $e");
      return null;
    }
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
