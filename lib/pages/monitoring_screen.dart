import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_mediapipe/flutter_mediapipe.dart';
import 'package:flutter_mediapipe/gen/landmark.pb.dart';
import 'package:camera/camera.dart';
import '../utils/distraction_detector.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({Key? key}) : super(key: key);

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  bool _isAnalyzing = false;
  bool _isDrowsy = false;
  bool _isYawning = false;
  double _averageEyeOpenness = 1.0;
  double _mouthOpenness = 0.0;
  final List<String> _recentAlerts = [];
  DateTime? _eyesClosedSince;
  bool _isReady = false;

  // Distraction detection
  bool _isDistracted = false;
  String _distractionLabel = "Safe Driving";
  DistractionDetector? _distractionDetector;
  CameraDescription? _cameraDescription;

  final List<int> leftEyeIndices = [159, 145, 33, 133];
  final List<int> rightEyeIndices = [386, 374, 362, 263];
  final List<int> mouthIndices = [13, 14, 78, 308];

  final List<String> distractionLabels = [
    "Safe Driving",
    "Texting Right",
    "Phone Right",
    "Texting Left",
    "Phone Left",
    "Radio",
    "Drinking",
    "Reaching Behind",
    "Hair/Makeup",
    "Talking to Passenger",
  ];

  @override
  void initState() {
    super.initState();
    _initializeDistractionSystem();
  }

  Future<void> _initializeDistractionSystem() async {
    try {
      final cameras = await availableCameras();
      _cameraDescription = cameras.first;
      _distractionDetector = DistractionDetector();

      await _distractionDetector!.init(
        _cameraDescription!,
        onDetection: (isDistracted, predictedClass) {
          print("🚨 Callback: $predictedClass | ${isDistracted ? "Distracted" : "Safe"}");
          setState(() {
            _isDistracted = isDistracted;
            _distractionLabel = distractionLabels[predictedClass];
            if (isDistracted) {
              _addRecentAlert("Distraction: $_distractionLabel");
            }
          });
        },
      );

      setState(() {
        _isReady = true;
      });

      print("✅ Distraction system initialized");
    } catch (e) {
      print("❌ Failed to initialize distraction system: $e");
    }
  }

  void _onLandmarkStream(NormalizedLandmarkList landmarkList) {
    double leftOpenness = _calculateEyeOpenness(landmarkList, leftEyeIndices);
    double rightOpenness = _calculateEyeOpenness(landmarkList, rightEyeIndices);
    double average = (leftOpenness + rightOpenness) / 2.0;
    double mouthOpen = _calculateMouthOpenness(landmarkList, mouthIndices);

    setState(() {
      _averageEyeOpenness = average;
      _mouthOpenness = mouthOpen;
    });

    const double eyeThreshold = 0.12;
    if (average < eyeThreshold) {
      if (_eyesClosedSince == null) {
        _eyesClosedSince = DateTime.now();
      } else if (DateTime.now().difference(_eyesClosedSince!) >= const Duration(seconds: 1)) {
        if (!_isDrowsy) {
          setState(() {
            _isDrowsy = true;
            _addRecentAlert("Drowsy detected");
          });
        }
      }
    } else {
      _eyesClosedSince = null;
      if (_isDrowsy) {
        setState(() {
          _isDrowsy = false;
        });
      }
    }

    const double mouthThreshold = 0.465;
    if (mouthOpen > mouthThreshold) {
      if (!_isYawning) {
        setState(() {
          _isYawning = true;
          _addRecentAlert("Yawning detected");
        });
      }
    } else {
      if (_isYawning) {
        setState(() {
          _isYawning = false;
        });
      }
    }
  }

  double _calculateEyeOpenness(NormalizedLandmarkList landmarks, List<int> indices) {
    if (landmarks.landmark.length <= indices.reduce(math.max)) return 1.0;
    final upper = landmarks.landmark[indices[0]];
    final lower = landmarks.landmark[indices[1]];
    final left = landmarks.landmark[indices[2]];
    final right = landmarks.landmark[indices[3]];
    double vertical = (upper.y - lower.y).abs();
    double horizontal = (left.x - right.x).abs();
    return horizontal == 0 ? 1.0 : vertical / horizontal;
  }

  double _calculateMouthOpenness(NormalizedLandmarkList landmarks, List<int> indices) {
    if (landmarks.landmark.length <= indices.reduce(math.max)) return 0.0;
    final upperLip = landmarks.landmark[indices[0]];
    final lowerLip = landmarks.landmark[indices[1]];
    final leftCorner = landmarks.landmark[indices[2]];
    final rightCorner = landmarks.landmark[indices[3]];
    double vertical = (upperLip.y - lowerLip.y).abs();
    double horizontal = (leftCorner.x - rightCorner.x).abs();
    return horizontal == 0 ? 0.0 : vertical / horizontal;
  }

  void _addRecentAlert(String alert) {
    if (!_recentAlerts.contains(alert)) {
      _recentAlerts.add(alert);
      if (_recentAlerts.length > 5) {
        _recentAlerts.removeAt(0);
      }
    }
  }

  void toggleAnalyzing() {
    setState(() {
      _isAnalyzing = !_isAnalyzing;
      if (_isAnalyzing) {
        print("📷 Starting distraction detection...");
        _distractionDetector?.startDetection();
      } else {
        print("🛑 Stopping detection...");
        _distractionDetector?.stopDetection();
      }
    });
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
                // Top Navigation
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black),
                      onPressed: () => Navigator.pop(context),
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
                        child: _isAnalyzing
                            ? NativeView(
                          onViewCreated: (FlutterMediapipe controller) {
                            controller.landMarksStream.listen(_onLandmarkStream);
                          },
                        )
                            : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, color: Colors.grey, size: 100),
                              SizedBox(height: 10),
                              Text('Camera not active', style: TextStyle(color: Colors.white)),
                            ],
                          ),
                        ),
                      ),
                      if (_isDrowsy) _warningOverlay("WARNING: Driver Drowsy!", Colors.red, 10),
                      if (_isYawning) _warningOverlay("WARNING: Yawning detected!", Colors.orange, 50),
                      if (_isDistracted) _warningOverlay("WARNING: $_distractionLabel", Colors.purple, 90),
                    ],
                  ),
                ),
                const SizedBox(height: 10.0),
                Center(
                  child: ElevatedButton(
                    onPressed: _isReady ? toggleAnalyzing : null,
                    child: Text(_isAnalyzing ? 'Stop Analyzing' : 'Start Analyzing'),
                  ),
                ),
                const SizedBox(height: 20.0),
                const Text(
                  "Driver's Status",
                  style: TextStyle(color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10.0),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statusIndicator(_isDrowsy ? 'Drowsy' : 'Awake', _isDrowsy ? Colors.red : Colors.green, _averageEyeOpenness),
                    _statusIndicator('Yawning', Colors.orange, _isYawning ? 0.8 : 0.2),
                    _statusIndicator('Distraction', Colors.purple, _isDistracted ? 0.8 : 0.2),
                  ],
                ),
                const SizedBox(height: 20.0),
                const Text('Recent Alerts', style: TextStyle(color: Colors.black, fontSize: 16.0, fontWeight: FontWeight.bold)),
                const SizedBox(height: 10.0),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentAlerts.length,
                  itemBuilder: (context, index) {
                    return _alertTile(_recentAlerts[index], 'Just now');
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _statusIndicator(String label, Color color, double confidence) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60.0,
              height: 60.0,
              child: CircularProgressIndicator(
                value: confidence.clamp(0.0, 1.0),
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
                color: confidence > 0.2 ? color : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5.0),
        Text(label, style: const TextStyle(color: Colors.black, fontSize: 12.0)),
        Text("${(confidence * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 10.0, color: Colors.grey)),
      ],
    );
  }

  Widget _warningOverlay(String message, Color bgColor, double top) {
    return Positioned(
      top: top,
      left: 10,
      child: Container(
        padding: const EdgeInsets.all(8.0),
        color: bgColor.withOpacity(0.8),
        child: Text(
          message,
          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  Widget _alertTile(String alert, String time) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0.0),
      leading: const Icon(Icons.warning, color: Colors.redAccent),
      title: Text(alert, style: const TextStyle(color: Colors.black, fontSize: 14.0)),
      subtitle: Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12.0)),
      trailing: const Text('Clear', style: TextStyle(color: Colors.blueAccent, fontSize: 12.0)),
    );
  }
}
