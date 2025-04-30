import 'dart:io';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceRecognitionService {
  CameraController? controller;
  Interpreter? _interpreter;
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(performanceMode: FaceDetectorMode.accurate),
  );
  List<double>? storedEmbedding;

  bool get isReady =>
      controller?.value.isInitialized == true &&
          _interpreter != null &&
          storedEmbedding != null;

  Future<void> init() async {
    final cams = await availableCameras();
    final front = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cams.first,
    );
    controller = CameraController(front, ResolutionPreset.medium, enableAudio: false);
    await controller!.initialize();
    _interpreter = await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
    await _loadStoredEmbedding();
  }

  Future<void> _loadStoredEmbedding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    if (!doc.exists) return;
    final data = doc.data()!;
    if (data['faceEmbedding'] is List) {
      storedEmbedding = List<double>.from((data['faceEmbedding'] as List).map((e) => (e as num).toDouble()));
    }
  }

  Future<List<double>?> captureLiveEmbedding() async {
    if (!isReady) return null;
    final pic = await controller!.takePicture();
    final bytes = await File(pic.path).readAsBytes();
    final frame = img.decodeImage(bytes)!;
    final inputImg = InputImage.fromFilePath(pic.path);
    final faces = await _faceDetector.processImage(inputImg);
    if (faces.isEmpty) return null;
    final box = faces.first.boundingBox;
    final left   = box.left.toInt().clamp(0, frame.width);
    final top    = box.top.toInt().clamp(0, frame.height);
    final width  = box.width.toInt().clamp(0, frame.width - left);
    final height = box.height.toInt().clamp(0, frame.height - top);
    final crop   = img.copyCrop(frame, x: left, y: top, width: width, height: height);
    final face112= img.copyResize(crop, width: 112, height: 112);
    return _getEmbedding(face112);
  }

  Future<List<double>> _getEmbedding(img.Image faceImg) async {
    final input = List.generate(1, (_) =>
        List.generate(112, (_) =>
            List.generate(112, (_) => List.filled(3, 0.0))
        )
    );
    for (var y = 0; y < 112; y++) {
      for (var x = 0; x < 112; x++) {
        final px = faceImg.getPixel(x, y);
        input[0][y][x][0] = (px.r - 127.5) / 128.0;
        input[0][y][x][1] = (px.g - 127.5) / 128.0;
        input[0][y][x][2] = (px.b - 127.5) / 128.0;
      }
    }
    final outShape = _interpreter!.getOutputTensor(0).shape;
    final output = List.generate(1, (_) => List.filled(outShape[1], 0.0));
    _interpreter!.run(input, output);
    return List<double>.from(output[0]);
  }

  double compare(List<double> a, List<double> b) {
    var dot = 0.0, magA = 0.0, magB = 0.0;
    for (var i = 0; i < a.length; i++) {
      dot   += a[i] * b[i];
      magA  += a[i] * a[i];
      magB  += b[i] * b[i];
    }
    return 1 - (dot / (math.sqrt(magA) * math.sqrt(magB)));
  }

  void dispose() {
    controller?.dispose();
    _faceDetector.close();
    _interpreter?.close();
  }
}
