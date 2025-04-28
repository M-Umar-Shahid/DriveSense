import 'dart:async';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mediapipe/flutter_mediapipe.dart';
import 'package:flutter_mediapipe/gen/landmark.pb.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:drivesense/pages/dashboard.dart';

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({Key? key}) : super(key: key);

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage>  with WidgetsBindingObserver{
  bool _isAnalyzing = false;
  bool _isDrowsy = false;
  bool _isYawning = false;
  bool _noSeatbelt = false;
  double _averageEyeOpenness = 1.0;
  double _mouthOpenness = 0.0;
  List<Rect> _noSeatbeltBoxes = [];
  img.Image? _lastFrameImage;

  FlutterMediapipe? _mpController;
  Interpreter? _seatbeltInterpreter;
  StreamSubscription? _frameSubscription;
  static const EventChannel _frameStream = EventChannel("flutter_mediapipe/frameStream");

  final List<int> leftEyeIndices = [159, 145, 33, 133];
  final List<int> rightEyeIndices = [386, 374, 362, 263];
  final List<int> mouthIndices = [13, 14, 78, 308];

  DocumentReference? _currentTripRef;
  int _tripAlertCount = 0;
  DateTime? _tripStartTime;
  String _tripFinalStatus = 'Safe';
  DateTime? _eyesClosedSince;
  final Map<String, DateTime> _lastSavedTimes = {};
  final List<String> _recentAlerts = [];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _loadSeatbeltModel();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _frameSubscription?.cancel();
    _mpController = null;
    _seatbeltInterpreter?.close();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      // App went to background (screen turned off or user switched app)
      if (_isAnalyzing) {
        debugPrint("⏸ App Paused → Stopping analysis safely...");
        toggleAnalyzing(); // 👈 STOP analyzing
      }
    }
    if (state == AppLifecycleState.resumed) {
      // App came back
      debugPrint("▶️ App Resumed");
    }
  }

  Future<void> _loadSeatbeltModel() async {
    _seatbeltInterpreter = await Interpreter.fromAsset('assets/models/seatbelt.tflite');
    debugPrint('✅ Seatbelt model loaded');
  }

  Future<void> toggleAnalyzing() async {
    if (!_isAnalyzing) {
      // Start analyzing
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
      // Stop analyzing
      setState(() => _isAnalyzing = false);

      // Very important: cancel the frame subscription FIRST
      await _frameSubscription?.cancel();
      _frameSubscription = null;

      // Also dispose mediapipe controller
      _mpController = null;
      _mpController = null;

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


  void _listenToFrameStream() {
    _frameSubscription = _frameStream.receiveBroadcastStream().listen((event) async {
      if (!_isAnalyzing) return;
      if (event is Uint8List) {
        final image = img.decodeImage(event);
        if (image != null) {
          _lastFrameImage = image;
          await _runSeatbeltDetection(event);
        }
      }
    });
  }

  Future<void> _runSeatbeltDetection(Uint8List frameBytes) async {
    if (_seatbeltInterpreter == null) return;

    // 1. Preprocess & run inference
    final input = _preprocessImage(frameBytes);
    final output = List.generate(1, (_) => List.generate(5, (_) => List.filled(8400, 0.0)));
    _seatbeltInterpreter!.run(input, output);

    // 2. Pull out the no-seatbelt confidences (8400 values)
    final noSeatbeltConfs = output[0][4];

    // 3. Compute the average confidence
    double sum = noSeatbeltConfs.fold(0.0, (acc, c) => acc + c);
    double avgConf = sum / noSeatbeltConfs.length;

    // 4. Compare against your threshold
    const double seatbeltAvgThreshold = 0.3;  // tune this as needed
    bool detectedNoSeatbelt = avgConf > seatbeltAvgThreshold;

    // 5. Log it
    print("➡ Average no-seatbelt conf = ${avgConf.toStringAsFixed(3)} "
        "(threshold = ${seatbeltAvgThreshold.toStringAsFixed(3)})");

    // 6. Update UI / save snapshot if needed
    if (detectedNoSeatbelt && _canSave("NoSeatbelt") && _lastFrameImage != null) {
      setState(() => _noSeatbelt = true);
      _addRecentAlert("No Seatbelt (${(avgConf*100).toStringAsFixed(1)}%)");
      _saveDetectionSnapshot(
        image: _lastFrameImage!,
        alertType: "No Seatbelt",
      );
    } else {
      if (_noSeatbelt) setState(() => _noSeatbelt = false);
    }
  }




  List<List<List<List<double>>>> _preprocessImage(Uint8List imageBytes) {
    final originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) throw Exception("Unable to decode image.");

    final resizedImage = img.copyResize(originalImage, width: 640, height: 640);

    List<List<List<List<double>>>> batch = List.generate(
      1,
          (_) => List.generate(
        640,
            (_) => List.generate(
          640,
              (_) => List.filled(3, 0.0),
        ),
      ),
    );

    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        final pixel = resizedImage.getPixel(x, y);
        batch[0][y][x][0] = pixel.getChannel(img.Channel.red).toDouble();    // 🔥 Notice: No divide by 255.0 now
        batch[0][y][x][1] = pixel.getChannel(img.Channel.green).toDouble();
        batch[0][y][x][2] = pixel.getChannel(img.Channel.blue).toDouble();
      }
    }

    return batch;
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

    if (average < 0.1) {
      _eyesClosedSince ??= DateTime.now();
      if (DateTime.now().difference(_eyesClosedSince!) >= const Duration(seconds: 1)) {
        if (_canSave("Drowsy") && !_isDrowsy && _lastFrameImage != null) {
          setState(() => _isDrowsy = true);
          _addRecentAlert("Drowsy detected");
          _saveDetectionSnapshot(image: _lastFrameImage!, alertType: "Drowsy");
        }
      }
    } else {
      _eyesClosedSince = null;
      if (_isDrowsy) setState(() => _isDrowsy = false);
    }

    if (mouthOpen > 0.4) {
      if (_canSave("Yawning") && !_isYawning && _lastFrameImage != null) {
        setState(() => _isYawning = true);
        _addRecentAlert("Yawning detected");
        _saveDetectionSnapshot(image: _lastFrameImage!, alertType: "Yawning");
      }
    } else {
      if (_isYawning) setState(() => _isYawning = false);
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

                  // ✅ Delay frame listening slightly to allow camera startup
                  Future.delayed(const Duration(milliseconds: 500), () {
                    if (mounted && _isAnalyzing) {
                      _listenToFrameStream();
                    }
                  });
                },
              ),
            ),
          ),
          if (_isAnalyzing)
            Positioned.fill(
              child: CustomPaint(
                painter: SeatbeltBoxPainter(_noSeatbeltBoxes),
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



  Widget _statusIndicator(String label, Color color, double confidence) {
    return Column(
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
        const SizedBox(height: 5),
        Text(label, style: const TextStyle(fontSize: 12)),
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

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        if (_isAnalyzing) {
          await toggleAnalyzing();
        }
        return true;
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
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
                    _statusIndicator(_isDrowsy ? 'Drowsy' : 'Awake', _isDrowsy ? Colors.red : Colors.green, _averageEyeOpenness),
                    _statusIndicator('Yawning', Colors.orange, _isYawning ? 0.8 : 0.2),
                    _statusIndicator('Seatbelt', _noSeatbelt ? Colors.red : Colors.green, _noSeatbelt ? 0.9 : 0.1),
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
    );
  }
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


class SeatbeltBoxPainter extends CustomPainter {
  final List<Rect> boxes;
  SeatbeltBoxPainter(this.boxes);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final box in boxes) {
      canvas.drawRect(box, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SeatbeltBoxPainter oldDelegate) {
    return oldDelegate.boxes != boxes;
  }
}