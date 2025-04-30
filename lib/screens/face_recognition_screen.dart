import 'package:drivesense/screens/dashboard_screen.dart';
import 'package:flutter/material.dart';
import 'package:camera/camera.dart';

import '../components/face_enrollment_screen_components/camera_preview_widget.dart';
import '../components/face_enrollment_screen_components/face_overlay_box.dart';
import '../components/face_recognition_screen_components/verify_button.dart';
import '../services/face_recognition_sevice.dart';

class FaceRecognitionPage extends StatefulWidget {
  const FaceRecognitionPage({super.key});
  @override
  State<FaceRecognitionPage> createState() => _FaceRecognitionPageState();
}

class _FaceRecognitionPageState extends State<FaceRecognitionPage> {
  final _svc = FaceRecognitionService();
  bool _ready = false;
  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    await _svc.init();
    setState(() => _ready = _svc.isReady);
  }

  Future<void> _verify() async {
    if (!_ready) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please wait for setup to complete')),
      );
      return;
    }
    setState(() => _processing = true);
    final liveEmb = await _svc.captureLiveEmbedding();
    if (liveEmb != null && _svc.storedEmbedding != null) {
      final dist = _svc.compare(liveEmb, _svc.storedEmbedding!);
      if (dist < 0.5) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const Dashboard()));
        return;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Face not recognized (dist=${dist.toStringAsFixed(2)})')),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No face detected; try again')),
      );
    }
    setState(() => _processing = false);
  }

  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Face Verification')),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        children: [
          CameraPreviewWidget(controller: _svc.controller as CameraController),
          const FaceOverlayBox(),
          Positioned(
            bottom: 32,
            left: 0,
            right: 0,
            child: VerifyButton(isProcessing: _processing, onPressed: _verify),
          ),
        ],
      ),
    );
  }
}
