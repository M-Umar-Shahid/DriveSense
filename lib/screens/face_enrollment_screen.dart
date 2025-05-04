import 'package:flutter/material.dart';
import '../../services/face_enrollment_service.dart';
import '../components/face_enrollment_screen_components/camera_preview_widget.dart';

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
    _svc.init().then((_) => setState(() => _ready = _svc.isReady));
  }

  Future<void> _capture() async {
    if (!_ready || _processing) return;

    setState(() => _processing = true);

    debugPrint("🔴 Starting captureEmbedding…");
    final emb = await _svc.captureEmbedding();
    debugPrint("🔵 captureEmbedding returned: $emb");

    if (emb != null) {
      // Try to save/embed; keep showing the loader until callback completes or throws
      try {
        await widget.onEnrollmentComplete(
          emb,
          widget.email,
          widget.password,
          widget.displayName,
        );
        // Success path: presumably you navigate away in onEnrollmentComplete,
        // so we deliberately do NOT call setState(false) here.
      } catch (err) {
        // If saving fails, stop the loader and show an error
        setState(() => _processing = false);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Enrollment failed: $err')),
          );
        }
      }
    } else {
      // No face detected: stop loader and show message
      setState(() => _processing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No face detected; please try again.')),
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
      body: Column(
        children: [
          // Top camera + overlay area
          Expanded(
            child: Stack(
              children: [
                // Live feed
                if (_ready)
                  CameraPreviewWidget(controller: _svc.controller!)
                else
                  const Center(child: CircularProgressIndicator()),
                // Dark overlay
                Positioned.fill(
                  child: Container(color: Colors.black45),
                ),
                // Oval cut-out
                Center(
                  child: ClipOval(
                    child: Container(
                      width: 260,
                      height: 360,
                      color: Colors.transparent,
                    ),
                  ),
                ),
                // Oval border
                Center(
                  child: Container(
                    width: 260,
                    height: 360,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white70, width: 3),
                      borderRadius: BorderRadius.circular(180),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom sheet with instructions + capture
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Align your face inside the frame and press the button to enroll.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                // Big circular FAB
                SizedBox(
                  width: 72,
                  height: 72,
                  child: FloatingActionButton(
                    backgroundColor: Colors.blueAccent,
                    onPressed: _processing ? null : _capture,
                    child: _processing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.camera_alt, size: 32),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap to Capture',
                  style: TextStyle(fontSize: 14, color: Colors.grey),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
