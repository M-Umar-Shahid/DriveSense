import 'dart:async';
import 'dart:typed_data';
import 'package:drivesense/pages/dashboard.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mediapipe/flutter_mediapipe.dart';
import 'package:flutter_mediapipe/gen/landmark.pb.dart';
import 'package:image/image.dart' as img;
import '../utils/distraction_detector.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({Key? key}) : super(key: key);

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  bool _isAnalyzing = false;
  bool _isDrowsy = false;
  bool _isYawning = false;
  DocumentReference? _currentTripRef;
  int _tripAlertCount = 0;
  DateTime? _tripStartTime;
  String _tripFinalStatus = 'Safe'; // Initially safe
  bool _isDistracted = false;
  img.Image? _lastFrameImage;
  double _averageEyeOpenness = 1.0;
  double _mouthOpenness = 0.0;
  String _distractionLabel = "Safe Driving";
  Map<String, DateTime> _lastSavedTimes = {};
  DateTime? _eyesClosedSince;
  final List<String> _recentAlerts = [];
  final DistractionDetector _distractionDetector = DistractionDetector();

  FlutterMediapipe? _mpController;
  static const EventChannel _frameStream = EventChannel("flutter_mediapipe/frameStream");
  StreamSubscription? _frameSubscription;

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
    _initDistractionModel();
  }

  @override
  void dispose() {
    _frameSubscription?.cancel();
    _mpController = null;
    super.dispose();
  }

  Future<void> _initDistractionModel() async {
    await _distractionDetector.loadModel();
    debugPrint("✅ Distraction model loaded");
  }

  Future<void> _saveDetectionSnapshot({
    required img.Image image,
    required String alertType,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final timestamp = DateTime.now();
    final fileName = "detections/${user.uid}/${timestamp.millisecondsSinceEpoch}_${alertType}_${Random().nextInt(9999)}.jpg";

    // Convert image to JPEG bytes
    final jpeg = img.encodeJpg(image, quality: 85);

    // Upload to Firebase Storage
    final ref = FirebaseStorage.instance.ref().child(fileName);
    final uploadTask = await ref.putData(Uint8List.fromList(jpeg));
    final imageUrl = await ref.getDownloadURL();

    // Save alert metadata to Firestore
    await FirebaseFirestore.instance.collection("detections").add({
      "uid": user.uid,
      "alertType": alertType,
      "alertCategory": _getAlertCategory(alertType),
      "imageUrl": imageUrl,
      "timestamp": Timestamp.fromDate(timestamp),
    });

// 🔄 Update trip alert count
    if (_currentTripRef != null) {
      _tripAlertCount++;
      _tripFinalStatus = _getAlertCategory(alertType) == 'Distraction' ? 'Distracted' : _tripFinalStatus;
    }



    debugPrint("📸 Snapshot saved: $imageUrl");
  }

  String _getAlertCategory(String type) {
    const distractions = [
      'Texting Right',
      'Phone Right',
      'Texting Left',
      'Phone Left',
      'Radio',
      'Drinking',
      'Reaching Behind',
      'Hair/Makeup',
      'Talking to Passenger',
    ];

    if (distractions.contains(type)) return 'Distraction';
    if (type == 'Yawning') return 'Yawning';
    if (type == 'Drowsy') return 'Drowsy';
    return 'Other';
  }


  bool _canSave(String alertType, {Duration cooldown = const Duration(seconds: 10)}) {
    final now = DateTime.now();
    final lastSaved = _lastSavedTimes[alertType];
    if (lastSaved == null || now.difference(lastSaved) >= cooldown) {
      _lastSavedTimes[alertType] = now;
      return true;
    }
    return false;
  }


  void _listenToFrameStream() {
    _frameSubscription = _frameStream.receiveBroadcastStream().listen(
          (event) {
        if (!_isAnalyzing) return;

        if (event is Uint8List) {
          final image = img.decodeImage(event);
          if (image != null) {
            _lastFrameImage = image;
            final input = _distractionDetector.preprocessImage(image);
            final output = _distractionDetector.run(input);
            final int predictedClass =
            output.indexWhere((e) => e == output.reduce((a, b) => a > b ? a : b));
            final bool isDistracted = predictedClass != 0;

            setState(() {
              _isDistracted = isDistracted;
              _distractionLabel = distractionLabels[predictedClass];
              if (isDistracted) {
                _addRecentAlert("Distraction: $_distractionLabel");
                _saveDetectionSnapshot(
                  image: image,
                  alertType: _distractionLabel,
                );
              }
            });
          }
        }
      },
      onError: (error) => debugPrint("❌ Frame stream error: $error"),
      cancelOnError: true,
    );
  }

  void _onLandmarkStream(NormalizedLandmarkList landmarkList) {
    if (!_isAnalyzing) return;

    final left = _calculateEyeOpenness(landmarkList, leftEyeIndices);
    final right = _calculateEyeOpenness(landmarkList, rightEyeIndices);
    final average = (left + right) / 2;
    final mouthOpen = _calculateMouthOpenness(landmarkList, mouthIndices);

    setState(() {
      _averageEyeOpenness = average;
      _mouthOpenness = mouthOpen;
    });

    const eyeThreshold = 0.12;
    if (average < eyeThreshold) {
      _eyesClosedSince ??= DateTime.now();
      if (DateTime.now().difference(_eyesClosedSince!) >= const Duration(seconds: 1)) {
        if (_canSave("Drowsy")&&!_isDrowsy && _lastFrameImage != null) {
          setState(() => _isDrowsy = true);
          _addRecentAlert("Drowsy detected");

          _saveDetectionSnapshot(
            image: _lastFrameImage!,
            alertType: "Drowsy",
          );
        }
      }
    } else {
      _eyesClosedSince = null;
      if (_isDrowsy) {
        setState(() => _isDrowsy = false);
      }
    }

    const mouthThreshold = 0.465;
    if (mouthOpen > mouthThreshold) {
      if (_canSave("Yawning")&&!_isYawning && _lastFrameImage != null) {
        setState(() => _isYawning = true);
        _addRecentAlert("Yawning detected");

        _saveDetectionSnapshot(
          image: _lastFrameImage!,
          alertType: "Yawning",
        );
      }
    } else {
      if (_isYawning) {
        setState(() => _isYawning = false);
      }
    }
  }

  double _calculateEyeOpenness(NormalizedLandmarkList l, List<int> i) {
    final upper = l.landmark[i[0]];
    final lower = l.landmark[i[1]];
    final left = l.landmark[i[2]];
    final right = l.landmark[i[3]];
    final vertical = (upper.y - lower.y).abs();
    final horizontal = (left.x - right.x).abs();
    return horizontal == 0 ? 1.0 : vertical / horizontal;
  }

  double _calculateMouthOpenness(NormalizedLandmarkList l, List<int> i) {
    final upper = l.landmark[i[0]];
    final lower = l.landmark[i[1]];
    final left = l.landmark[i[2]];
    final right = l.landmark[i[3]];
    final vertical = (upper.y - lower.y).abs();
    final horizontal = (left.x - right.x).abs();
    return horizontal == 0 ? 0.0 : vertical / horizontal;
  }

  void _addRecentAlert(String alert) {
    if (!_recentAlerts.contains(alert)) {
      _recentAlerts.add(alert);
      if (_recentAlerts.length > 5) _recentAlerts.removeAt(0);
    }
  }

  Future<void> toggleAnalyzing() async {
    setState(() {
      _isAnalyzing = !_isAnalyzing;
    });

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    if (_isAnalyzing) {
      debugPrint("▶️ Start analyzing");

      // 🚀 Start new trip
      _tripAlertCount = 0;
      _tripFinalStatus = 'Safe';
      _tripStartTime = DateTime.now();
      _currentTripRef = await FirebaseFirestore.instance.collection('trips').add({
        'uid': user.uid,
        'startTime': Timestamp.fromDate(_tripStartTime!),
        'alerts': 0,
        'status': 'Safe',
      });

      _listenToFrameStream();
    } else {
      debugPrint("⏹️ Stop analyzing");

      _frameSubscription?.cancel();
      _frameSubscription = null;
      _mpController = null;

      // ✅ End the trip
      if (_currentTripRef != null && _tripStartTime != null) {
        await _currentTripRef!.update({
          'endTime': Timestamp.now(),
          'alerts': _tripAlertCount,
          'status': _tripFinalStatus,
        });
      }

      _currentTripRef = null;
    }
  }


  Widget _buildCameraView() {
    return Center(
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: _isAnalyzing ? 1.0 : 0.0,
            child: SizedBox(
              height: 500,
              width: 300,
              child: NativeView(
                onViewCreated: (FlutterMediapipe controller) {
                  _mpController = controller;
                  controller.landMarksStream.listen((landmarks) {
                    if (_isAnalyzing) _onLandmarkStream(landmarks);
                  });
                  _listenToFrameStream();
                },
              ),
            ),
          ),
          if (!_isAnalyzing)
            Container(
              height: 500,
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black,
              ),
              child: const Center(
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
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
        onWillPop: () async {
          if (_isAnalyzing) toggleAnalyzing();
          return true;
        },
    child:  Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  alignment: Alignment.center,
                  children: [
                    const Text(
                      'Real-time Monitoring',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                    ),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () async {
                          if (_isAnalyzing) await toggleAnalyzing();  // Await it first
                          if (mounted) {
                            Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(builder: (context) => const Dashboard()),
                            );
                          }
                          // Only pop after cleanup
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const Center(
                  child: Text("Driver's View", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 10),
                _buildCameraView(),
                const SizedBox(height: 10),
                Center(
                  child: ElevatedButton(
                    onPressed: toggleAnalyzing,
                    child: Text(_isAnalyzing ? 'Stop Analyzing' : 'Start Analyzing'),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Driver's Status", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _statusIndicator(_isDrowsy ? 'Drowsy' : 'Awake', _isDrowsy ? Colors.red : Colors.green, _averageEyeOpenness),
                    _statusIndicator('Yawning', Colors.orange, _isYawning ? 0.8 : 0.2),
                    _statusIndicator('Distraction', Colors.purple, _isDistracted ? 0.8 : 0.2),
                  ],
                ),
                const SizedBox(height: 20),
                const Text('Recent Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentAlerts.length,
                  itemBuilder: (context, index) => _alertTile(_recentAlerts[index], 'Just now'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),);
  }

  Widget _statusIndicator(String label, Color color, double confidence) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: confidence.clamp(0.0, 1.0),
                strokeWidth: 5,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                backgroundColor: Colors.grey[300],
              ),
            ),
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: confidence > 0.2 ? color : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
        Text("${(confidence * 100).toStringAsFixed(0)}%", style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }

  Widget _alertTile(String alert, String time) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      leading: const Icon(Icons.warning, color: Colors.redAccent),
      title: Text(alert),
      subtitle: Text(time, style: const TextStyle(color: Colors.grey)),
      trailing: const Text('Clear', style: TextStyle(color: Colors.blueAccent, fontSize: 12)),
    );
  }
}
