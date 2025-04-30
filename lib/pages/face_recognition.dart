// lib/pages/face_recognition.dart

import 'dart:async';
import 'dart:io';
import 'dart:math' as math;
import 'package:drivesense/pages/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FaceRecognitionPage extends StatefulWidget {
  const FaceRecognitionPage({Key? key}) : super(key: key);

  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  // camera + ML Kit
  late CameraController _camCtrl;
  bool _cameraReady = false;
  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
    ),
  );

  // TFLite model
  late Interpreter _faceNet;
  bool _modelLoaded = false;

  // Firestore embedding
  List<double>? _storedEmbedding;

  // UI state
  bool _isProcessing = false;
  bool _authenticated = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadModel();
    _fetchStoredEmbedding();
  }

  Future<void> _initCamera() async {
    final cams = await availableCameras();
    final front = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cams.first,
    );
    _camCtrl = CameraController(
      front,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _camCtrl.initialize();
    setState(() => _cameraReady = true);
  }

  Future<void> _loadModel() async {
    _faceNet = await Interpreter.fromAsset('assets/models/mobilefacenet.tflite');
    setState(() => _modelLoaded = true);
  }

  Future<void> _fetchStoredEmbedding() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .get();
    if (doc.exists && doc.data()!['faceEmbedding'] != null) {
      _storedEmbedding = (doc.data()!['faceEmbedding'] as List)
          .map((e) => (e as num).toDouble())
          .toList();
    }
  }

  @override
  void dispose() {
    _camCtrl.dispose();
    _faceDetector.close();
    if (_modelLoaded) _faceNet.close();
    super.dispose();
  }

  Future<List<double>> _getEmbedding(img.Image faceImg) async {
    // Prepare input tensor
    var input = List.generate(1, (_) =>
        List.generate(112, (_) =>
            List.generate(112, (_) => List.filled(3, 0.0))
        )
    );
    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        final px = faceImg.getPixel(x, y);
        final double r = px.r.toDouble();
        final double g = px.g.toDouble();
        final double b = px.b.toDouble();
        input[0][y][x][0] = (r - 127.5) / 128.0;
        input[0][y][x][1] = (g - 127.5) / 128.0;
        input[0][y][x][2] = (b - 127.5) / 128.0;
      }
    }
    final outShape = _faceNet.getOutputTensor(0).shape;
    var output = List.generate(1, (_) => List.filled(outShape[1], 0.0));
    _faceNet.run(input, output);
    return List<double>.from(output[0]);
  }

  double _cosineDistance(List<double> a, List<double> b) {
    double dot = 0, magA = 0, magB = 0;
    for (var i = 0; i < a.length; i++) {
      dot   += a[i] * b[i];
      magA  += a[i] * a[i];
      magB  += b[i] * b[i];
    }
    return 1 - (dot / (math.sqrt(magA) * math.sqrt(magB)));
  }

  Future<void> _captureAndVerify() async {
    if (!_cameraReady || !_modelLoaded || _storedEmbedding == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for setup to complete')),
      );
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final pic = await _camCtrl.takePicture();
      final inputImg = InputImage.fromFilePath(pic.path);
      final faces = await _faceDetector.processImage(inputImg);
      if (faces.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No face detected; try again')),
        );
        setState(() => _isProcessing = false);
        return;
      }
      final box = faces.first.boundingBox;
      final bytes = await File(pic.path).readAsBytes();
      final frame = img.decodeImage(bytes)!;

      // Crop + resize
      final left   = box.left.toInt().clamp(0, frame.width);
      final top    = box.top.toInt().clamp(0, frame.height);
      final width  = box.width.toInt().clamp(0, frame.width - left);
      final height = box.height.toInt().clamp(0, frame.height - top);
      final crop   = img.copyCrop(frame, x:left, y:top, width:width, height:height);
      final face112= img.copyResize(crop, width:112, height:112);

      // Embedding & distance
      final emb = await _getEmbedding(face112);
      final dist = _cosineDistance(emb, _storedEmbedding!);
      if (dist < 0.5) {
        // Success: navigate into app
        setState(() => _authenticated = true);
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => const Dashboard(),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Face not recognized (dist=${dist.toStringAsFixed(2)})')),
        );
        setState(() => _isProcessing = false);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Verification error: $e')),
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext ctx) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Verification')),
      body: _cameraReady
          ? Stack(
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
            child: CameraPreview(_camCtrl),
          ),
          Center(
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          Positioned(
            bottom: 32, left: 0, right: 0,
            child: Center(
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _captureAndVerify,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Verify Face'),
                ),
              ),
            ),
          ),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
