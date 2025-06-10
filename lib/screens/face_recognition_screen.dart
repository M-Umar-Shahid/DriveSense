import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'package:drivesense/screens/dashboard_screen.dart';
import '../components/face_enrollment_screen_components/camera_preview_widget.dart';
import '../components/face_enrollment_screen_components/face_overlay_box.dart';
import '../services/face_recognition_sevice.dart';
import 'main_app_screen.dart';

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
    _svc.init().then((_) => setState(() => _ready = _svc.isReady));
  }

  Future<void> _verify() async {
    if (!_ready || _processing) return;

    setState(() => _processing = true);

    final liveEmb = await _svc.captureLiveEmbedding();
    if (liveEmb != null && _svc.storedEmbedding != null) {
      final dist = _svc.compare(liveEmb, _svc.storedEmbedding!);
      if (dist < 0.6) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const MainAppScreen()),
              (route) => false,
        );
        return;
      } else {
        _showMessage('Face not recognized (dist=${dist.toStringAsFixed(2)})');
      }
    } else {
      _showMessage('No face detected; please try again.');
    }

    // on failure, stop processing so button re-appears
    if (mounted) setState(() => _processing = false);
  }

  void _showMessage(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
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
        title: const Text('Face Verification'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
      ),
      body: Column(
        children: [
          // camera + overlay area
          Expanded(
            child: Stack(
              children: [
                if (_ready)
                  CameraPreviewWidget(controller: _svc.controller as CameraController)
                else
                  const Center(child: CircularProgressIndicator()),
                // dark overlay
                Positioned.fill(child: Container(color: Colors.black45)),
                // oval cut-out
                Center(
                  child: ClipOval(
                    child: Container(
                      width: 260,
                      height: 360,
                      color: Colors.transparent,
                    ),
                  ),
                ),
                // oval border
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

          // bottom sheet with instructions + verify button
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
                  'Align your face inside the frame and tap to verify.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.black87),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: 72,
                  height: 72,
                  child: FloatingActionButton(
                    backgroundColor: Colors.green,
                    onPressed: _verify,
                    child: _processing
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Icon(Icons.check, size: 32),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Tap to Verify',
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
