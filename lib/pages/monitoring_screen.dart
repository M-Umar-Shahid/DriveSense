import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_mediapipe/flutter_mediapipe.dart';
import 'package:flutter_mediapipe/gen/landmark.pb.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({Key? key}) : super(key: key);

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  bool _isAnalyzing = false;
  bool _isDrowsy = false;
  double _averageEyeOpenness = 1.0;
  final List<String> _recentAlerts = [];

  // Instead of a Timer, use a timestamp to track when eyes closed.
  DateTime? _eyesClosedSince;

  // Landmark indices used to compute eye openness.
  final List<int> leftEyeIndices = [159, 145, 33, 133];
  final List<int> rightEyeIndices = [386, 374, 362, 263];

  void _onLandmarkStream(NormalizedLandmarkList landmarkList) {
    double leftOpenness = _calculateEyeOpenness(landmarkList, leftEyeIndices);
    double rightOpenness = _calculateEyeOpenness(landmarkList, rightEyeIndices);
    double average = (leftOpenness + rightOpenness) / 2.0;

    setState(() {
      _averageEyeOpenness = average;
    });

    // Use a threshold (e.g., 0.1) to determine if eyes are closed.
    const double threshold = 0.12;
    if (average < threshold) {
      // If eyes just closed, record the time.
      if (_eyesClosedSince == null) {
        _eyesClosedSince = DateTime.now();
      } else {
        // If eyes remain closed for more than 1 second, trigger the alert.
        if (DateTime.now().difference(_eyesClosedSince!) >= const Duration(seconds: 1)) {
          if (!_isDrowsy) { // Only update if not already flagged.
            setState(() {
              _isDrowsy = true;
              _addRecentAlert("Drowsy detected");
            });
          }
        }
      }
    } else {
      // Reset the timer if eyes open.
      _eyesClosedSince = null;
      if (_isDrowsy) {
        setState(() {
          _isDrowsy = false;
        });
      }
    }
  }

  double _calculateEyeOpenness(
      NormalizedLandmarkList landmarks, List<int> indices) {
    if (landmarks.landmark.length <= indices.reduce(math.max)) return 1.0;
    NormalizedLandmark upper = landmarks.landmark[indices[0]];
    NormalizedLandmark lower = landmarks.landmark[indices[1]];
    NormalizedLandmark left = landmarks.landmark[indices[2]];
    NormalizedLandmark right = landmarks.landmark[indices[3]];

    double vertical = (upper.y - lower.y).abs();
    double horizontal = (left.x - right.x).abs();
    return horizontal == 0 ? 1.0 : vertical / horizontal;
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
      if (!_isAnalyzing) {
        _eyesClosedSince = null;
        _isDrowsy = false;
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
                // Top Navigation Bar
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
                        child: _isAnalyzing
                            ? NativeView(
                          onViewCreated: (FlutterMediapipe controller) {
                            controller.landMarksStream.listen(_onLandmarkStream);
                            controller.platformVersion.then((version) =>
                                print("Platform Version: $version"));
                          },
                        )
                            : const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, color: Colors.grey, size: 100),
                              SizedBox(height: 10),
                              Text(
                                'Camera not active',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
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
                    child: Text(_isAnalyzing ? 'Stop Analyzing' : 'Start Analyzing'),
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
                    _statusIndicator('Awake', Colors.green, !_isDrowsy),
                    _statusIndicator('Drowsy', Colors.red, _isDrowsy),
                    _statusIndicator('Seat belt', Colors.green, true), // placeholder
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

  Widget _statusIndicator(String label, Color color, bool isActive) {
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
    return ListTile(
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
    );
  }
}

void main() => runApp(const MaterialApp(home: MonitoringPage()));
