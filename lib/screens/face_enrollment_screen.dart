import 'package:flutter/material.dart';
import '../../services/face_enrollment_service.dart';
import '../components/face_enrollment_screen_components/camera_preview_widget.dart';
import '../components/face_enrollment_screen_components/capture_button.dart';
import '../components/face_enrollment_screen_components/face_overlay_box.dart';

class FaceEnrollmentPage extends StatefulWidget {
  final String email;
  final String password;
  final String displayName;
  final Future<void> Function(
      List<double> embedding,
      String email,
      String password,
      String displayName,
      ) onEnrollmentComplete;

  const FaceEnrollmentPage({
    super.key,
    required this.email,
    required this.password,
    required this.displayName,
    required this.onEnrollmentComplete,
  });

  @override
  State<FaceEnrollmentPage> createState() => _FaceEnrollmentPageState();
}

class _FaceEnrollmentPageState extends State<FaceEnrollmentPage> {
  final _svc = FaceEnrollmentService();
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

  Future<void> _capture() async {
    if (!_ready) return;
    setState(() => _processing = true);

    debugPrint("🔴 Starting captureEmbedding…");
    final emb = await _svc.captureEmbedding();
    debugPrint("🔵 captureEmbedding returned embedding: $emb");

    setState(() => _processing = false);
    if (emb != null) {
      await widget.onEnrollmentComplete(emb, widget.email, widget.password, widget.displayName);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No face detected; try again.')),
        );
      }
    }
  }


  @override
  void dispose() {
    _svc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Face Enrollment'),
        centerTitle: true,
      ),
      body: !_ready
          ? const Center(child: CircularProgressIndicator())
          : Stack(
        fit: StackFit.expand,
        children: [
          CameraPreviewWidget(controller: _svc.controller!),
          // dark overlay with transparent hole
          Container(
            color: Colors.black45,
          ),
          const FaceOverlayBox(),
          Positioned(
            top: 80,
            left: 0,
            right: 0,
            child: const Center(
              child: Text(
                'Align your face inside the frame',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: CaptureButton(
              isProcessing: _processing,
              onCapture: _capture,
            ),
          ),
        ],
      ),
    );
  }
}
