import 'package:flutter/material.dart';
import 'dart:async';
import 'package:camera/camera.dart';
import 'package:http/http.dart' as http;
import 'dart:math' as math;
import 'dart:convert';
import 'package:logging/logging.dart';
import '../utils/logger_util.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  final Logger _logger = LoggerUtil.getLogger('MonitoringPage');
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;
  Map<String, dynamic>? _detectionData;
  Timer? _timer;
  int _consecutiveDrowsyCount = 0;
  bool _isDrowsy = false;
  int _consecutiveDistractedCount = 0; // Track consecutive distracted frames
  bool _isDistracted = false; // Track distracted state

  @override
  void initState() {
    super.initState();
    initializeCamera();
  }

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _logger.info('Camera: ${frontCamera.name}');

    // Test different resolution presets
    for (var preset in [
      ResolutionPreset.low,
      ResolutionPreset.medium,
      ResolutionPreset.high,
      ResolutionPreset.veryHigh,
      ResolutionPreset.ultraHigh,
      ResolutionPreset.max,
    ]) {
      _cameraController = CameraController(
        frontCamera,
        preset,
        enableAudio: false,
      );

      try {
        await _cameraController!.initialize();
        final previewSize = _cameraController!.value.previewSize;
        _logger.info(
            'Preset $preset: ${previewSize?.width}x${previewSize?.height}');
        await _cameraController!.dispose();
      } catch (e) {
        _logger.warning('Preset $preset not supported: $e');
      }
    }

    // Reinitialize with the desired preset
    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.medium,
      enableAudio: false,
    );

    await _cameraController!.initialize();
    if (!mounted) return;

    final previewSize = _cameraController!.value.previewSize;
    _logger.info(
        'Final Preview Size: ${previewSize?.width}x${previewSize?.height}');

    setState(() {
      _isCameraInitialized = true;
    });
  }

  void toggleAnalyzing() {
    if (_isAnalyzing) {
      _stopAnalyzing();
    } else {
      _startAnalyzing();
    }
  }

  void _startAnalyzing() {
    if (!_isCameraInitialized || _cameraController == null) return;

    setState(() {
      _isAnalyzing = true;

    });

    _timer = Timer.periodic(const Duration(milliseconds: 200), (timer) async {
      if (_isAnalyzing) {
        XFile imageFile = await _cameraController!.takePicture();
        await _processCapturedImage(imageFile);
      }
    });
  }

  void _stopAnalyzing() {
    _timer?.cancel();
    setState(() {
      _isAnalyzing = false;
      _detectionData = null;
      _consecutiveDrowsyCount = 0;
      _isDrowsy = false;
      _consecutiveDistractedCount = 0; // Reset distracted counter
      _isDistracted = false; // Reset distracted state
    });
  }

  Future<void> _processCapturedImage(XFile imageFile) async {
    try {
      final bytes = await imageFile.readAsBytes();
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://192.168.100.59:8000/detect'),
      );
      request.files.add(
          http.MultipartFile.fromBytes('file', bytes, filename: 'frame.jpg'));
      var response = await request.send();
      if (response.statusCode == 200) {
        var result = await response.stream.bytesToString();
        var jsonResult = jsonDecode(result);
        setState(() {
          _detectionData = jsonResult;
          bool isDrowsy = _detectionData?['is_drowsy'] ?? false;
          bool isYawning = _detectionData?['is_yawning'] ?? false;
          bool isDistracted = _detectionData?['is_distracted'] ?? false;

          if (isDrowsy || isYawning) {
            _consecutiveDrowsyCount++;
            if (_consecutiveDrowsyCount >= 5) {
              _isDrowsy = true;
            }
          } else {
            _consecutiveDrowsyCount = 0;
            _isDrowsy = false;
          }

          if (isDistracted) {
            _consecutiveDistractedCount++;
            if (_consecutiveDistractedCount >= 5) {
              _isDistracted = true;
            }
          } else {
            _consecutiveDistractedCount = 0;
            _isDistracted = false;
          }
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Failed to process image: ${response.statusCode}')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Navigation Bar
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () {
                        Navigator.pop(context);
                      },
                    ),
                    const Text(
                      'Real-time Monitoring',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 18.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.settings, color: Colors.black),
                      onPressed: () {},
                    ),
                  ],
                ),
                const SizedBox(height: 20.0),

                // Driver's View Section
                const Center(
                  child: Text(
                    "Driver's View",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10.0),
                Center(
                  child: Stack(
                    children: [
                      Container(
                        height: 475.0,
                        width: 350.0,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12.0),
                          color: Colors.black,
                        ),
                        child: _isAnalyzing &&
                            _isCameraInitialized &&
                            _cameraController != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..rotateY(math.pi),
                            child: CameraPreview(_cameraController!),
                          ),
                        )
                            : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt,
                                  color: Colors.grey, size: 100),
                              SizedBox(height: 10),
                              Text(
                                'Camera not active',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isAnalyzing && _detectionData != null)
                        CustomPaint(
                          painter: FaceOverlayPainter(
                            faceCircle: _detectionData!['face_circle'],
                            leftEyeCircle: _detectionData!['left_eye_circle'],
                            rightEyeCircle: _detectionData!['right_eye_circle'],
                            axes: _detectionData!['axes'],
                            containerWidth: 300.0,
                            containerHeight: 500.0,
                            imageWidth: _cameraController!.value.previewSize!.height,
                            imageHeight: _cameraController!.value.previewSize!.width,
                          ),
                          child: const SizedBox(
                            height: 500.0,
                            width: 300.0,
                          ),
                        ),
                      if (_isAnalyzing && _detectionData != null)
                        Positioned(
                          top: 10,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            color: Colors.black.withOpacity(0.6),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Eye Openness: ${_detectionData!['eye_openness'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.0,
                                  ),
                                ),
                                Text(
                                  'Mouth Openness: ${_detectionData!['mouth_openness'].toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.0,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      if (_isDrowsy)
                        Positioned(
                          top: 50,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            color: Colors.red.withOpacity(0.8),
                            child: const Text(
                              'WARNING: Driver Drowsy!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      if (_isDistracted)
                        Positioned(
                          top: 90,
                          left: 10,
                          child: Container(
                            padding: const EdgeInsets.all(8.0),
                            color: Colors.orange.withOpacity(0.8),
                            child: const Text(
                              'WARNING: Driver Distracted!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 10.0),
                Center(
                  child: ElevatedButton(
                    onPressed: toggleAnalyzing,
                    child: Text(
                        _isAnalyzing ? 'Stop Analyzing' : 'Start Analyzing'),
                  ),
                ),
                const SizedBox(height: 20.0),

                // Driver's Status Section
                const Text(
                  "Driver's Status",
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statusIndicator('Awake', Colors.green),
                    _statusIndicator('Drowsy', Colors.red),
                    _statusIndicator('Seat belt', Colors.green),
                  ],
                ),
                const SizedBox(height: 20.0),

                // Recent Alerts Section
                const Text(
                  'Recent Alerts',
                  style: TextStyle(
                    color: Colors.black,
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10.0),
                ListView(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  children: [
                    if (_detectionData != null && _detectionData!['is_drowsy'])
                      _alertTile('Drowsy detected', 'Just now'),
                    if (_detectionData != null && _detectionData!['is_yawning'])
                      _alertTile('Yawning detected', 'Just now'),
                    _alertTile('Seatbelt not fastened', '5 minutes ago'),
                    _alertTile('Phone usage detected', '10 minutes ago'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusIndicator(String label, Color color) {
    bool isActive = false;
    if (label == 'Drowsy' && _isDrowsy) {
      isActive = true;
    } else if (label == 'Awake' && !_isDrowsy && _detectionData != null) {
      isActive = true;
    } else if (label == 'Seat belt') {
      // Placeholder for seatbelt detection (not implemented in this example)
      isActive = false;
    }

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60.0,
              height: 60.0,
              child: CircularProgressIndicator(
                value: isActive ? 0.7 : 0.3,
                strokeWidth: 5.0,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                backgroundColor: Colors.grey[300],
              ),
            ),
            Container(
              width: 30.0,
              height: 30.0,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isActive ? color : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5.0),
        Text(
          label,
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12.0,
          ),
        ),
      ],
    );
  }

  Widget _alertTile(String alert, String time) {
    return Column(
      children: [
        ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
          leading: const Icon(Icons.warning, color: Colors.redAccent),
          title: Text(
            alert,
            style: const TextStyle(
              color: Colors.black,
              fontSize: 14.0,
            ),
          ),
          subtitle: Text(
            time,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 12.0,
            ),
          ),
          trailing: const Text(
            'Clear',
            style: TextStyle(
              color: Colors.blueAccent,
              fontSize: 12.0,
            ),
          ),
        ),
      ],
    );
  }
}

// Custom painter to draw face circle, eye circles, and axes
class FaceOverlayPainter extends CustomPainter {
  final Map<String, dynamic> faceCircle;
  final Map<String, dynamic> leftEyeCircle;
  final Map<String, dynamic> rightEyeCircle;
  final Map<String, dynamic> axes;
  final double containerWidth;
  final double containerHeight;
  final double imageWidth;
  final double imageHeight;

  FaceOverlayPainter({
    required this.faceCircle,
    required this.leftEyeCircle,
    required this.rightEyeCircle,
    required this.axes,
    required this.containerWidth,
    required this.containerHeight,
    required this.imageWidth,
    required this.imageHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final xScale = containerWidth / imageWidth;
    final yScale = containerHeight / imageHeight;

    // Draw face circle
    final faceCenter = Offset(
      containerWidth - (faceCircle['center'][0] * xScale), // Mirror horizontally
      faceCircle['center'][1] * yScale,
    );
    final faceRadius = faceCircle['radius'] * xScale;
    final facePaint = Paint()
      ..color = Colors.green
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(faceCenter, faceRadius, facePaint);

    // Draw left eye circle
    final leftEyeCenter = Offset(
      containerWidth - (leftEyeCircle['center'][0] * xScale), // Mirror
      leftEyeCircle['center'][1] * yScale,
    );
    final leftEyeRadius = leftEyeCircle['radius'] * xScale;
    final eyePaint = Paint()
      ..color = Colors.yellow
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    canvas.drawCircle(leftEyeCenter, leftEyeRadius, eyePaint);

    // Draw right eye circle
    final rightEyeCenter = Offset(
      containerWidth - (rightEyeCircle['center'][0] * xScale), // Mirror
      rightEyeCircle['center'][1] * yScale,
    );
    final rightEyeRadius = rightEyeCircle['radius'] * xScale;
    canvas.drawCircle(rightEyeCenter, rightEyeRadius, eyePaint);

    // Draw axes
    final noseTip = Offset(
      containerWidth - (axes['x_axis'][0][0] * xScale), // Mirror
      axes['x_axis'][0][1] * yScale,
    );

    // X-axis (red)
    final xEnd = Offset(
      containerWidth - (axes['x_axis'][1][0] * xScale), // Mirror
      axes['x_axis'][1][1] * yScale,
    );
    final xPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;
    canvas.drawLine(noseTip, xEnd, xPaint);

    // Y-axis (green)
    final yEnd = Offset(
      containerWidth - (axes['y_axis'][1][0] * xScale), // Mirror
      axes['y_axis'][1][1] * yScale,
    );
    final yPaint = Paint()
      ..color = Colors.green
      ..strokeWidth = 2.0;
    canvas.drawLine(noseTip, yEnd, yPaint);

    // Z-axis (blue)
    final zEnd = Offset(
      containerWidth - (axes['z_axis'][1][0] * xScale), // Mirror
      axes['z_axis'][1][1] * yScale,
    );
    final zPaint = Paint()
      ..color = Colors.blue
      ..strokeWidth = 2.0;
    canvas.drawLine(noseTip, zEnd, zPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

void main() => runApp(const MaterialApp(
  home: MonitoringPage(),
));