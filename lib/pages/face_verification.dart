import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

class FaceVerificationPage extends StatefulWidget {
  final List<dynamic> storedEmbedding;
  const FaceVerificationPage({Key? key, required this.storedEmbedding}) : super(key: key);

  @override
  State<FaceVerificationPage> createState() => _FaceVerificationPageState();
}

class _FaceVerificationPageState extends State<FaceVerificationPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isVerifying = false;
  List<XFile> _capturedFrames = [];
  Timer? _captureTimer;
  int _frameCount = 0;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
    );
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );
    await _cameraController!.initialize();
    if (!mounted) return;
    setState(() {
      _isCameraInitialized = true;
    });
  }

  // Start capturing multiple frames (e.g., 3 frames)
  void _startFrameCapture() {
    _capturedFrames.clear();
    _frameCount = 0;
    _captureTimer = Timer.periodic(const Duration(milliseconds: 500), (timer) async {
      if (_cameraController != null && _cameraController!.value.isInitialized) {
        final frame = await _cameraController!.takePicture();
        _capturedFrames.add(frame);
        _frameCount++;
        if (_frameCount >= 3) {
          timer.cancel();
          _sendVerificationData();
        }
      }
    });
  }

  Future<void> _sendVerificationData() async {
    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Replace with your backend server's address
    final uri = Uri.parse('http://192.168.100.59:8000/verify');
    final request = http.MultipartRequest('POST', uri);

    // Add each captured frame to the request
    for (int i = 0; i < _capturedFrames.length; i++) {
      final bytes = await _capturedFrames[i].readAsBytes();
      request.files.add(
        http.MultipartFile.fromBytes('files', bytes, filename: 'frame_$i.jpg'),
      );
    }

    // Send the stored embedding along as a form field (encoded as JSON)
    request.fields['stored_embedding'] = jsonEncode(widget.storedEmbedding);

    final streamedResponse = await request.send();
    final responseString = await streamedResponse.stream.bytesToString();
    Navigator.of(context).pop(); // Dismiss loading indicator

    if (streamedResponse.statusCode == 200) {
      final responseJson = jsonDecode(responseString);
      if (responseJson['authenticated'] == true) {
        Navigator.pop(context, true);
      } else {
        Navigator.pop(context, false);
      }
    } else {
      Navigator.pop(context, false);
    }
  }

  Future<void> _verifyFace() async {
    if (_isVerifying) return;
    setState(() {
      _isVerifying = true;
    });
    _startFrameCapture();
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
      appBar: AppBar(title: const Text('Face Verification')),
      body: _isCameraInitialized
          ? Column(
        children: [
          Expanded(
            // Flip preview for non-mirrored view
            child: Transform(
              alignment: Alignment.center,
              transform: Matrix4.rotationY(math.pi),
              child: CameraPreview(_cameraController!),
            ),
          ),
          ElevatedButton(
            onPressed: _verifyFace,
            child: _isVerifying
                ? const CircularProgressIndicator(color: Colors.white)
                : const Text('Verify Face'),
          ),
          const SizedBox(height: 20),
        ],
      )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
