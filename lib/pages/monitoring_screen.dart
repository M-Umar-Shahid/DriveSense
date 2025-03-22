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
  List<Map<String, dynamic>> _detections = [];
  Timer? _timer; // Timer for periodic requests
  int _consecutiveDrowsyCount = 0; // Track consecutive drowsy detections
  bool _isDrowsy = false; // Track drowsy state

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

    _timer = Timer.periodic(const Duration(milliseconds: 1000), (timer) async {
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
      _detections.clear();
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
          _detections =
              List<Map<String, dynamic>>.from(jsonResult['detections']);
          if (_detections.isNotEmpty && _detections.any((d) => d['class_id'] == 0)) {
            _consecutiveDrowsyCount++;
            if (_consecutiveDrowsyCount >= 5) {
              _isDrowsy = true;
            }
          } else {
            _consecutiveDrowsyCount = 0; // Reset if no drowsy detection
            _isDrowsy = false;
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
                        height: 500.0,
                        width: 300.0,
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
                      if (_detections.isNotEmpty)
                        ..._detections.map((detection) {
                          const xScale =
                              300.0 / 480; // Container width / backend width
                          const yScale =
                              500.0 / 720; // Container height / backend height

                          final mirroredX1 = 300 -
                              (detection['x2'].toDouble() *
                                  xScale); // Flip horizontally
                          final mirroredWidth =
                              (detection['x2'] - detection['x1']).toDouble() *
                                  xScale;

                          return Positioned(
                            left: mirroredX1
                                .toDouble(), // Convert to double explicitly
                            top: detection['y1'].toDouble() * yScale,
                            width: mirroredWidth,
                            height:
                                (detection['y2'] - detection['y1']).toDouble() *
                                    yScale,
                            child: Container(
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.red, width: 2),
                              ),
                              child: Text(
                                'Class: ${detection['class_id']}, Confidence: ${detection['confidence'].toStringAsFixed(2)}',
                                style: const TextStyle(
                                  color: Colors.red,
                                  backgroundColor: Colors.white,
                                ),
                              ),
                            ),
                          );
                        }),
                      if (_isDrowsy)
                        Positioned(
                          top: 10,
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
                    _alertTile('Distract detected', '5 minutes ago'),
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
    } else if (label == 'Awake' && !_isDrowsy && _detections.isNotEmpty && !_detections.any((d) => d['class_id'] == 0)) {
      isActive = true;
    } else if (label == 'Seat belt' && _detections.isNotEmpty && _detections.any((d) => d['class_id'] == 2)) { // Adjust class_id for seat belt
      isActive = true;
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

void main() => runApp(const MaterialApp(
      home: MonitoringPage(),
    ));
