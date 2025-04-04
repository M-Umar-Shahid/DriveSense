import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FaceEnrollmentPage extends StatefulWidget {
  const FaceEnrollmentPage({Key? key}) : super(key: key);

  @override
  _FaceEnrollmentPageState createState() => _FaceEnrollmentPageState();
}

class _FaceEnrollmentPageState extends State<FaceEnrollmentPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  List<XFile> _capturedImages = [];
  Timer? _captureTimer;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    // Select the front camera
    final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    _cameraController = CameraController(frontCamera, ResolutionPreset.medium, enableAudio: false);
    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {
      _isCameraInitialized = true;
    });
  }

  void _startEnrollment() {
    _capturedImages.clear();
    _frameCount = 0;
    // Capture one frame every 500ms until we have 10 frames.
    _captureTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        XFile image = await _cameraController!.takePicture();
        _capturedImages.add(image);
        _frameCount++;
        if (_frameCount >= 10) {
          timer.cancel();
          _sendEnrollmentData();
        }
      }
    });
  }

  Future<void> _sendEnrollmentData() async {
    // Show a loading indicator while waiting
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    // Replace with your backend server IP or domain.
    var uri = Uri.parse('http://192.168.100.59:8000/enroll');
    var request = http.MultipartRequest('POST', uri);
    for (int i = 0; i < _capturedImages.length; i++) {
      final bytes = await _capturedImages[i].readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('files', bytes, filename: 'frame_$i.jpg'),
      );
    }

    var response = await request.send();
    Navigator.of(context).pop(); // Dismiss the loading indicator

    if (response.statusCode == 200) {
      // Parse the JSON response.
      final result = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(result);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Face enrollment successful')),
      );
      // Return the enrollment result to the previous screen.
      Navigator.pop(context, jsonResponse);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Enrollment failed: ${response.statusCode}')),
      );
      Navigator.pop(context, null);
    }
  }

  @override
  void dispose() {
    _captureTimer?.cancel();
    _cameraController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Face Enrollment'),
      ),
      body: Column(
        children: [
          Expanded(
            child: _isCameraInitialized
                ? Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: CameraPreview(_cameraController!),
            )
                : const Center(child: CircularProgressIndicator()),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _startEnrollment,
            child: const Text('Start Enrollment'),
          ),
          const SizedBox(height: 16),
          const Text('Please ensure your face is clearly visible for enrollment.'),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
