import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';

class FaceEnrollmentPage extends StatefulWidget {
  final String email, password, displayName;
  final Future<void> Function(
      List<double> embedding,
      String email,
      String password,
      String displayName,
      ) onEnrollmentComplete;

  const FaceEnrollmentPage({
    Key? key,
    required this.email,
    required this.password,
    required this.displayName,
    required this.onEnrollmentComplete,
  }) : super(key: key);

  @override
  State<FaceEnrollmentPage> createState() => _FaceEnrollmentPageState();
}

class _FaceEnrollmentPageState extends State<FaceEnrollmentPage> {
  late CameraController _camCtrl;
  bool _cameraReady     = false;

  final FaceDetector _faceDetector = GoogleMlKit.vision.faceDetector(
    FaceDetectorOptions(
      performanceMode: FaceDetectorMode.accurate,
      enableContours: false,
      enableLandmarks: false,
    ),
  );

  late Interpreter _faceNet;
  bool _modelLoaded    = false;
  bool _isProcessing   = false;

  @override
  void initState() {
    super.initState();
    _initCamera();
    _loadModel();
  }

  Future<void> _initCamera() async {
    final cams = await availableCameras();
    final front = cams.firstWhere(
          (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cams.first,
    );
    _camCtrl = CameraController(
      front,                        // ← now we choose the front one
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

  @override
  void dispose() {
    _camCtrl.dispose();
    _faceDetector.close();
    if (_modelLoaded) _faceNet.close();
    super.dispose();
  }

  Future<List<double>> _getEmbedding(img.Image faceImg) async {
    // normalize & prepare input tensor [1,112,112,3]
    var input = List.generate(1, (_) =>
        List.generate(112, (_) =>
            List.generate(112, (_) => List.filled(3, 0.0))
        )
    );
    for (int y = 0; y < 112; y++) {
      for (int x = 0; x < 112; x++) {
        final px = faceImg.getPixel(x, y);
        // px is an img.Pixel from `resized.getPixel(x, y)`
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

  Future<void> _captureAndEnroll() async {
    if (!_cameraReady || !_modelLoaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Waiting for camera/model…')),
      );
      return;
    }
    setState(() => _isProcessing = true);
    try {
      final XFile pic = await _camCtrl.takePicture();
      final inputImage = InputImage.fromFilePath(pic.path);
      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No face detected; try again.')),
        );
        setState(() => _isProcessing = false);
        return;
      }
      // use first face
      final box = faces.first.boundingBox;
      final bytes = await File(pic.path).readAsBytes();
      final frame = img.decodeImage(bytes)!;

      // crop & resize to 112×112
      final left   = box.left.toInt().clamp(0, frame.width);
      final top    = box.top.toInt().clamp(0, frame.height);
      final width  = box.width.toInt().clamp(0, frame.width - left);
      final height = box.height.toInt().clamp(0, frame.height - top);
      final crop = img.copyCrop(frame, x: left, y: top, width: width, height: height);
      final face112 = img.copyResize(crop, width:112, height:112);

      // get embedding & complete registration
      final emb = await _getEmbedding(face112);
      await widget.onEnrollmentComplete(
        emb,
        widget.email,
        widget.password,
        widget.displayName,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enrollment error: $e')),
      );
      setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Enrollment')),
      body: _cameraReady
          ? Stack(
        children: [
          Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0, 1.0),
            child: CameraPreview(_camCtrl),
          ),
          // center box
          Center(
            child: Container(
              width: 200, height: 200,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.white70, width: 2),
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
          // instruction
          Positioned(
            top: 48, left: 0, right: 0,
            child: const Center(
              child: Text(
                'Align your face in the box',
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
            ),
          ),
          // capture button
          Positioned(
            bottom: 32, left: 0, right: 0,
            child: Center(
              child: _isProcessing
                  ? const CircularProgressIndicator()
                  : ElevatedButton(
                onPressed: _captureAndEnroll,
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  child: Text('Capture Face'),
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
