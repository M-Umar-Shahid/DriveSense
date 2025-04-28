import 'dart:async';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_mediapipe/flutter_mediapipe.dart';
import 'package:flutter_mediapipe/gen/landmark.pb.dart';
import 'package:image/image.dart' as img;
import 'package:drivesense/pages/dashboard.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({Key? key}) : super(key: key);

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> with WidgetsBindingObserver {
  bool _isAnalyzing = false;
  bool _isDrowsy = false;
  bool _isYawning = false;
  double _seatbeltConfidence = 0.0;
  bool _noSeatbelt = false;
  double _averageEyeOpenness = 1.0;
  double _mouthOpenness = 0.0;
  img.Image? _lastFrameImage;
  static const double eyeThreshold   = 0.12;
  static const double mouthThreshold = 0.40;
  final List<String> _recentAlerts = [];
  final Map<String, DateTime> _lastSavedTimes = {};
  double _drowsyConfidence = 0.0;
  double _yawnConfidence   = 0.0;


  FlutterMediapipe? _mpController;
  static const EventChannel _frameStream = EventChannel("flutter_mediapipe/frameStream");
  StreamSubscription? _frameSubscription;

  final List<int> leftEyeIndices = [159, 145, 33, 133];
  final List<int> rightEyeIndices = [386, 374, 362, 263];
  final List<int> mouthIndices = [13, 14, 78, 308];

  DocumentReference? _currentTripRef;
  int _tripAlertCount = 0;
  DateTime? _tripStartTime;
  String _tripFinalStatus = 'Safe';
  DateTime? _eyesClosedSince;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _frameSubscription?.cancel();
    _mpController = null;
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      if (_isAnalyzing) toggleAnalyzing();
    }
  }

  Future<void> toggleAnalyzing() async {
    if (!_isAnalyzing) {
      setState(() => _isAnalyzing = true);

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      _tripStartTime = DateTime.now();
      _tripAlertCount = 0;
      _tripFinalStatus = 'Safe';
      _currentTripRef = await FirebaseFirestore.instance.collection('trips').add({
        'uid': user.uid,
        'startTime': Timestamp.fromDate(_tripStartTime!),
        'alerts': 0,
        'status': 'Safe',
      });

      _listenToFrameStream();
    } else {
      setState(() => _isAnalyzing = false);
      await _frameSubscription?.cancel();
      _mpController = null;

      if (_currentTripRef != null && _tripStartTime != null) {
        await _currentTripRef!.update({
          'endTime': Timestamp.now(),
          'alerts': _tripAlertCount,
          'status': _tripFinalStatus,
        });
      }
    }
  }

  void _listenToFrameStream() {
    _frameSubscription = _frameStream
        .receiveBroadcastStream()
        .listen((dynamic event) async {
      if (!_isAnalyzing) return;

      // a) raw JPEG bytes from native → cache locally
      if (event is Uint8List) {
        final frame = img.decodeImage(event);
        if (frame != null) {
          _lastFrameImage = frame;
        }
        return;
      }

      // b) structured seatbelt payload
      if (event is Map<String, dynamic> && event['type'] == 'seatbelt') {
        final double noSeat = (event['noSeat'] as num).toDouble().clamp(0.0, 1.0);
        final bool detected = noSeat > 0.50;

        // Save snapshot before updating state
        if (detected
            && _lastFrameImage != null
            && _canSave("NoSeatbelt", cooldown: Duration(seconds: 2))) {
          await _saveDetectionSnapshot(
            image: _lastFrameImage!,
            alertType: "NoSeatbelt",
          );
        }

        setState(() {
          _seatbeltConfidence = 1.0 - noSeat;
          _noSeatbelt         = detected;
        });

        if (detected && _currentTripRef != null) {
          _tripAlertCount++;
          _tripFinalStatus = 'Alert Detected';
          _addRecentAlert("No Seatbelt ${(noSeat * 100).toStringAsFixed(0)}%");
        }
      }
    },
      onError: (err) => debugPrint("Frame stream error: $err"),
    );
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

  Future<void> _saveDetectionSnapshot({required img.Image image, required String alertType}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final timestamp = DateTime.now();
    final fileName = "detections/${user.uid}/${timestamp.millisecondsSinceEpoch}_${alertType}_${math.Random().nextInt(9999)}.jpg";
    final jpeg = img.encodeJpg(image, quality: 85);

    final ref = FirebaseStorage.instance.ref().child(fileName);
    await ref.putData(Uint8List.fromList(jpeg));
    final imageUrl = await ref.getDownloadURL();

    await FirebaseFirestore.instance.collection("detections").add({
      "uid": user.uid,
      "alertType": alertType,
      "alertCategory": alertType,
      "imageUrl": imageUrl,
      "timestamp": Timestamp.fromDate(timestamp),
    });

    if (_currentTripRef != null) {
      _tripAlertCount++;
      _tripFinalStatus = 'Alert Detected';
    }
  }

  Future<void> _onLandmarkStream(NormalizedLandmarkList l) async {
    if (!_isAnalyzing) return;

    // compute raw metrics
    final double left    = _calculateEyeOpenness(l, leftEyeIndices);
    final double right   = _calculateEyeOpenness(l, rightEyeIndices);
    final double average = (left + right) / 2;
    final double mouth   = _calculateMouthOpenness(l, mouthIndices);

    // compute confidences
    final double dConf = ((eyeThreshold - average) / eyeThreshold).clamp(0.0, 1.0);
    final double yConf = ((mouth - mouthThreshold) / (1 - mouthThreshold)).clamp(0.0, 1.0);

    setState(() {
      _averageEyeOpenness = average;
      _mouthOpenness      = mouth;
      _drowsyConfidence   = dConf;
      _yawnConfidence     = yConf;
    });

    // Drowsy @ >20%
    if (dConf > 0.20
        && !_isDrowsy
        && _lastFrameImage != null
        && _canSave("Drowsy", cooldown: Duration(seconds: 2))) {
      await _saveDetectionSnapshot(
        image: _lastFrameImage!,
        alertType: "Drowsy",
      );
      setState(() => _isDrowsy = true);
      _addRecentAlert("Drowsy ${(dConf * 100).toStringAsFixed(0)}%");
      _tripAlertCount++;
      _tripFinalStatus = 'Alert Detected';
    } else if (dConf <= 0.20 && _isDrowsy) {
      setState(() => _isDrowsy = false);
    }

    // Yawn @ >25%
    if (yConf > 0.25
        && !_isYawning
        && _lastFrameImage != null
        && _canSave("Yawning", cooldown: Duration(seconds: 2))) {
      await _saveDetectionSnapshot(
        image: _lastFrameImage!,
        alertType: "Yawning",
      );
      setState(() => _isYawning = true);
      _addRecentAlert("Yawning ${(yConf * 100).toStringAsFixed(0)}%");
      _tripAlertCount++;
      _tripFinalStatus = 'Alert Detected';
    } else if (yConf <= 0.25 && _isYawning) {
      setState(() => _isYawning = false);
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
      _recentAlerts.insert(0, alert);
      if (_recentAlerts.length > 5) _recentAlerts.removeLast();
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
                onViewCreated: (controller) {
                  _mpController = controller;
                  controller.landMarksStream.listen((landmarks) {
                    if (_isAnalyzing) _onLandmarkStream(landmarks);
                  });

                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted && _isAnalyzing) {
                      _listenToFrameStream();
                    }
                  });
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
    final drowsyColor   = _drowsyConfidence  > 0.20 ? Colors.red   : Colors.green;
    final yawnColor     = _yawnConfidence    > 0.25 ? Colors.red   : Colors.green;
    final seatbeltColor = (1 - _seatbeltConfidence) > 0.50 ? Colors.red : Colors.green;
    return WillPopScope(
      onWillPop: () async {
        if (_isAnalyzing) await toggleAnalyzing();
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: ScrollConfiguration(behavior: ScrollConfiguration.of(context).copyWith(overscroll: false), child:
          SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () async {
                        if (_isAnalyzing) await toggleAnalyzing();
                        if (mounted) {
                          Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const Dashboard()));
                        }
                      },
                    ),
                    const Text('Real-time Monitoring', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  ],
                ),
                const SizedBox(height: 20),
                const Center(child: Text("Driver's View", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold))),
                const SizedBox(height: 10),
                _buildCameraView(),
                const SizedBox(height: 20),
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


          _statusIndicator('Drowsy',   drowsyColor,   _drowsyConfidence),
      _statusIndicator('Yawning',  yawnColor,     _yawnConfidence),
      _statusIndicator('Seatbelt', seatbeltColor, 1 - _seatbeltConfidence),
      ],
    ),

    const SizedBox(height: 20),
                const Text('Recent Alerts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 10),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _recentAlerts.length,
                  itemBuilder: (context, index) => _alertTile(_recentAlerts[index]),
                ),
              ],
            ),
          ),
        ),
      ),
    ),);
  }

  Widget _statusIndicator(String label, Color color, double confidence) {
    // make sure it’s in [0,1]
    final display = confidence.clamp(0.0, 1.0);

    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(
                value: display,
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
                // fill if it’s at least 20% confident
                color: display > 0.2 ? color : Colors.grey,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
        // optional: show the numeric confidence
        Text(
          "${(display * 100).toStringAsFixed(0)}%",
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }


  Widget _alertTile(String alert) {
    return ListTile(
      leading: const Icon(Icons.warning, color: Colors.redAccent),
      title: Text(alert, style: const TextStyle(fontSize: 14)),
      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
    );
  }
}
