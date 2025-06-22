import 'dart:async';
import 'dart:isolate';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:drivesense/screens/main_app_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_mediapipe/flutter_mediapipe.dart';
import 'package:flutter_mediapipe/gen/landmark.pb.dart';
import 'package:image/image.dart' as img;
import 'package:flutter_tts/flutter_tts.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import '../model_inference/seatbelt_isolate.dart';
import '../utils/distraction_detector.dart';


const int maxDet = 8400;
const double detectionThreshold = 0.5;
Size _imageSize = Size.zero;

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
  int _cameraViewKey = 0;
  FlutterMediapipe? _mpController;
  Uint8List? _latestSeatbeltJpeg;
  bool _attached = false;

  StreamSubscription? _frameSubscription;
  StreamSubscription? _fromIsolateSubscription;
  static const EventChannel _frameStream = EventChannel("flutter_mediapipe/frameStream");
  int? _cameraViewId;
  final _detector = DistractionDetector();
  bool _modelLoaded = false;
  bool _isDistracted = false;
  String? _currentDistractionLabel;
  double _currentDistractionConfidence = 0.0;
  // ── 1a) EAR/MR thresholds (per Reddy et al. 2024):
  static const double _earThreshold = 0.15;   // eye aspect ratio threshold
  static const double _mrThreshold  = 0.3;    // mouth ratio threshold

  static const int _eyeClosureFrameThreshold  = 20;  // 20 consecutive frames → drowsy
  static const int _yawnFrameThreshold        = 20;  // 36 consecutive frames → yawning

  // ── 1b) Runtime frame counters (initialized to zero):
  int _eyeClosedFrameCount = 0;
  int _yawningFrameCount   = 0;


  SendPort? _seatbeltSendPort;          // to send frames to the isolate
  late final ReceivePort _fromIsolate;  // to receive bounding boxes back
  Isolate? _seatbeltIsolate;            // the spawned Isolate
  bool _seatbeltIsolateReady = false;   // true once the isolate sends us its SendPort


  final List<String> distractionLabels = [
    "Drinking",
    "Eating",
    "Mobile Use",
    "Smoking"
  ];

  late final FlutterTts _tts;
  String? _currentAlert;
  final Map<String, DateTime> _lastSpoken = {};
  final Map<String, Duration> _cooldowns = {
    'seatbelt':   Duration(seconds: 20),
    'drowsy':     Duration(seconds: 20),
    'distraction':Duration(seconds: 20),
    'yawning':    Duration(seconds: 20),
  };


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
  bool _shouldRestartOnResume = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) setState(() => _attached = true);
    });
    WakelockPlus.enable();


    _tts = FlutterTts()
      ..setLanguage("en-US")
      ..setSpeechRate(0.5)
      ..setVolume(1.0)
      ..setPitch(1.0)
      ..setCompletionHandler(_onUtteranceComplete);
  }


  void _onUtteranceComplete() {
    // once a message finishes, clear current
    _currentAlert = null;
  }

  void _updateAlertSpeech() {
    // 1️⃣ Pick the highest‐priority active alert:
    String? next;

    // ── Seatbelt highest ────────────────────────────────────
    if (_noSeatbelt) {
      next = 'seatbelt';
    }
    // ── Then distraction ───────────────────────────────────
    else if (_isDistracted) {
      next = 'distraction';
    }
    // ── Then drowsy/yawning ────────────────────────────────
    else if (_isDrowsy) {
      next = 'drowsy';
    } else if (_isYawning) {
      next = 'yawning';
    }

    // 2️⃣ If nothing’s active, stop speaking:
    if (next == null) {
      _currentAlert = null;
      _tts.stop();
      return;
    }

    // 3️⃣ Don’t re-speak the same alert if it’s still playing:
    if (_currentAlert == next) return;

    // 4️⃣ Enforce per-alert cooldown:
    final now      = DateTime.now();
    final lastTime = _lastSpoken[next];
    final cooldown = _cooldowns[next]!;
    if (lastTime != null && now.difference(lastTime) < cooldown) return;

    // 5️⃣ Build the message for this alert:
    final messages = {
      'seatbelt':    'Warning: No seatbelt detected. Please buckle up.',
      'distraction': 'Warning: Distraction detected. Keep your eyes on the road.',
      'drowsy':      'Alert: Drowsiness detected. Please stay focused.',
      'yawning':     'Alert: You are yawning. Please remain attentive.',
    };
    final msg = messages[next]!;

    // 6️⃣ Record and speak:
    _currentAlert     = next;
    _lastSpoken[next] = now;
    _tts.stop();
    _tts.speak(msg);
  }

  @override
  void dispose() {
    _tts.stop();
    _stopAnalyzing();
    _frameSubscription?.cancel();
    _mpController = null;
    _seatbeltIsolate?.kill(priority: Isolate.immediate);
    _seatbeltIsolate = null;
    _fromIsolateSubscription?.cancel();
    _fromIsolate.close();
    WidgetsBinding.instance.removeObserver(this);
    WakelockPlus.disable();
    super.dispose();
  }


  void _stopAnalyzing() {
    _stopAnalyzingInternal();
    if (mounted) {
      setState(() => _isAnalyzing = false);
    }
  }

  void _stopAnalyzingInternal() {
    if (_frameSubscription != null) {
      _frameSubscription?.cancel();
      _frameSubscription = null;
    }
    _mpController = null;
  }

  void _spawnSeatbeltIsolate () async{
    print("🚀 [Main] Spawning seatbelt isolate...");

    final modelBytes = await rootBundle.load('assets/models/seatbelt.tflite');
    final modelUint8 = modelBytes.buffer.asUint8List();

    _fromIsolate = ReceivePort();

    Isolate.spawn<List<dynamic>>(
      seatbeltIsolateEntry,
      [_fromIsolate.sendPort, modelUint8],
    ).then((isolateRef) {
      _seatbeltIsolate = isolateRef;

      _fromIsolateSubscription = _fromIsolate.listen((message) async {
        if (message is SendPort) {
          _seatbeltSendPort = message;
          _seatbeltIsolateReady = true;
          print("✅ [Main] Received isolate’s SendPort; seatbelt isolate is ready.");
        } else if (message is Map<String, dynamic>) {
          final bool noSeat = message['noSeatbelt'] as bool;
          final List<dynamic> rawBoxes = message['boxes'] as List<dynamic>;
          print("⬅️ [Main] Got seatbelt data: noSeat=$noSeat, rawBoxesCount=${rawBoxes.length}");

          if (noSeat && _latestSeatbeltJpeg != null && _canSave("NoSeatbelt")) {
            final decoded = img.decodeImage(_latestSeatbeltJpeg!);
            if (decoded != null) {
              _addRecentAlert("No Seatbelt");
              await _saveDetectionSnapshot(image: decoded, alertType: "No Seatbelt");
            }
          }

          final List<Rect> scaledBoxes = rawBoxes.map<Rect>((b) {
            final double l = (b['left'] as num).toDouble();
            final double t = (b['top'] as num).toDouble();
            final double r = (b['right'] as num).toDouble();
            final double bb = (b['bottom'] as num).toDouble();
            return Rect.fromLTRB(l, t, r, bb);
          }).toList();

          if (mounted) {
            setState(() {
              _noSeatbelt = noSeat;
              _noSeatbeltBoxes = scaledBoxes;
            });
            print("🏁 [Main] Updated _noSeatbelt=$_noSeatbelt, boxesLen=${scaledBoxes.length}");
          }
        }
      });
    }).catchError((e, st) {
      print("🚨 [Main] Failed to spawn isolate: $e\n$st");
    });
  }



  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);

    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      // App went to background / screen off
      if (_isAnalyzing) {
        _shouldRestartOnResume = true;
        _stopAnalyzing(); // stops frame stream & controller
      }
    }

    if (state == AppLifecycleState.resumed && _shouldRestartOnResume) {
      // App came back
      _shouldRestartOnResume = false;

      // 1) Force Flutter to dispose & recreate the camera view
      setState(() => _cameraViewKey++);

      // 2) Give it a moment, then restart analysis
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) toggleAnalyzing();
      });
    }
  }

  // Future<void> _loadSeatbeltModel() async {
  //   _seatbeltInterpreter = await Interpreter.fromAsset('assets/models/seatbelt.tflite');
  //   debugPrint('✅ Seatbelt model loaded');
  //   // ← Trigger a rebuild so the button sees the non-null interpreter
  //   if (mounted) setState(() {});
  // }

  Future<void> toggleAnalyzing() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Ensure the seatbelt model is loaded:
    // if (_seatbeltInterpreter == null) {
    //   await _loadSeatbeltModel();
    // }

    if (!_isAnalyzing) {
      // ── START ANALYSIS ──────────────────────────────────
      _tripStartTime   = DateTime.now();
      _tripAlertCount  = 0;
      _tripFinalStatus = 'Safe';

      final userTripsQuery = FirebaseFirestore.instance
          .collection('trips')
          .where('uid', isEqualTo: user.uid);

      final countSnap = await userTripsQuery.count().get();
      final tripNumber = countSnap.count! + 1;

      _currentTripRef = await FirebaseFirestore.instance
          .collection('trips')
          .add({
        'uid':       user.uid,
        'tripNo':    tripNumber,
        'startTime': Timestamp.fromDate(_tripStartTime!),
        'alerts':    0,
        'status':    'Safe',
      });

      setState(() {
        _isAnalyzing = true;
      });

      // Give the SurfaceView ~100 ms to attach before subscribing:
      await Future.delayed(const Duration(milliseconds: 100));

      // Only subscribe if we didn’t already subscribe:
      if (_frameSubscription == null) {
        _listenToFrameStream();
      }
    } else {
      // ── STOP ANALYSIS ───────────────────────────────────
      // 1) Cancel the frame subscription (if it exists)
      await _frameSubscription?.cancel();
      _frameSubscription = null;

      // 2) Null out the Mediapipe controller so it can be recreated on resume
      _mpController = null;

      // 3) Update Firestore with trip end and alerts
      if (_currentTripRef != null && _tripStartTime != null) {
        await _currentTripRef!.update({
          'endTime': Timestamp.now(),
          'alerts':  _tripAlertCount,
          'status':  _tripFinalStatus,
        });
      }
      _currentTripRef = null;

      // 4) Flip the flag so the UI switches back
      setState(() => _isAnalyzing = false);
    }
  }


  void _listenToFrameStream() {
    // If we already have an active subscription, do nothing:
    if (_frameSubscription != null) {
      debugPrint("⚠️ Frame stream already active");
      return;
    }

    debugPrint("🛰️ Subscribed to frame stream");
    _frameSubscription = _frameStream.receiveBroadcastStream().listen(
          (event) async {
        if (!_isAnalyzing) return;

        if (event is Uint8List) {
          final image = img.decodeImage(event);
          if (image == null) return;
          _lastFrameImage = image;
          setState(() {
            _imageSize = Size(image.width.toDouble(), image.height.toDouble());
          });

          if (_seatbeltIsolateReady && _seatbeltSendPort != null) {
            final resizedForModel = img.copyResize(image, width: 640, height: 640);
            final inferenceJpeg = Uint8List.fromList(img.encodeJpg(resizedForModel));

            final originalJpeg = Uint8List.fromList(img.encodeJpg(image));

            _latestSeatbeltJpeg = originalJpeg;

            _seatbeltSendPort!.send(<String, dynamic>{
              'replyPort': _fromIsolate.sendPort,
              'imageBytes': inferenceJpeg,
            });
            debugPrint("📤 Sent a frame into seatbelt isolate");
          }

          if (_modelLoaded) {
            await _runDistractionDetection(image);
          }
        }

          },
      onError: (e) {
        debugPrint('❌ FrameStream error: $e');
      },
      cancelOnError: true,
    );
  }

  Future<void> _runDistractionDetection(img.Image frame) async {
    debugPrint("🚀 Running distraction detection");

    final result = _detector.getTopClass(frame);
    final int predictedClass = result['classIndex'];
    final double confidence = result['confidence'];

    final String predictedLabel = predictedClass == -1
        ? "Safe Driving"
        : distractionLabels[predictedClass];  // e.g., ["Drinking", "Eating", ...]

    final bool distracted = predictedClass != -1;

    setState(() {
      _isDistracted = distracted;
      _currentDistractionLabel = predictedLabel;
      _currentDistractionConfidence = confidence;
    });


    if (distracted && _canSave(predictedLabel, cooldown: const Duration(seconds: 30))) {
      debugPrint("📸 Saving snapshot for: $predictedLabel");
      _addRecentAlert('$predictedLabel detected');
      await _saveDetectionSnapshot(image: frame, alertType: predictedLabel);
    }

    _updateAlertSpeech();
  }


  void _onLandmarkStream(NormalizedLandmarkList landmarkList) {
    if (!_isAnalyzing) return;

    // 1) Compute current EAR (eye aspect ratio) and MR (mouth ratio):
    final leftEAR  = _calculateEyeOpenness(landmarkList, leftEyeIndices);
    final rightEAR = _calculateEyeOpenness(landmarkList, rightEyeIndices);
    final averageEAR = (leftEAR + rightEAR) / 2.0;

    final mouthRatio = _calculateMouthOpenness(landmarkList, mouthIndices);



    // 2) Update UI‐state for progress indicators (optional)
    setState(() {
      _averageEyeOpenness = averageEAR;
      _mouthOpenness      = mouthRatio;
    });

    // ───────────────────────────────────────────────────────────
    // —— DROWSY LOGIC (EAR < 0.25 for 20 consecutive frames) ——
    if (averageEAR < _earThreshold) {
      _eyeClosedFrameCount++;
    } else {
      _eyeClosedFrameCount = 0;
      if (_isDrowsy) {
        // If previously flagged as drowsy but now eyes opened, clear:
        setState(() => _isDrowsy = false);
        _updateAlertSpeech(); // allow speech system to switch/stop
      }
    }

    // Once we’ve seen EAR below threshold for 20 frames straight:
    if (_eyeClosedFrameCount >= _eyeClosureFrameThreshold) {
      // Only trigger once per “drowsy event”:
      if (!_isDrowsy && _lastFrameImage != null && _canSave("Drowsy")) {
        debugPrint("👁️ EAR: $averageEAR");
        setState(() => _isDrowsy = true);
        _addRecentAlert("Drowsy detected");
        _saveDetectionSnapshot(image: _lastFrameImage!, alertType: "Drowsy");
        _updateAlertSpeech(); // speak “drowsy” message
      }
    }

    // ───────────────────────────────────────────────────────────
    // —— YAWNING LOGIC (MR > 0.3 for 36 consecutive frames) ——
    if (mouthRatio > _mrThreshold) {
      _yawningFrameCount++;
      debugPrint("😮 Yawning Frame Count: $_yawningFrameCount");
    } else {
      _yawningFrameCount = 0;
      if (_isYawning) {
        // If previously flagged yawning but mouth ratio dropped, clear:
        setState(() => _isYawning = false);
        _updateAlertSpeech(); // allow speech system to switch/stop
      }
    }

    // Once MR > threshold for 36 frames straight:
    if (_yawningFrameCount >= _yawnFrameThreshold) {
      // Only trigger once per “yawning event”:
      if (!_isYawning && _lastFrameImage != null && _canSave("Yawning")) {
        setState(() => _isYawning = true);
        _addRecentAlert("Yawning detected");
        _saveDetectionSnapshot(image: _lastFrameImage!, alertType: "Yawning");
        _updateAlertSpeech(); // speak “yawning” message
      }
    }

    // ───────────────────────────────────────────────────────────
    // After updating both drowsy/yawn, let the speech logic pick the highest priority:
    _updateAlertSpeech();
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
      // add a dedicated alert‐doc under trips/{tripId}/alerts
      await _currentTripRef!
          .collection('alerts')
          .add({
        'alertType':  alertType,
        'imageUrl':   imageUrl,
        'timestamp':  Timestamp.fromDate(timestamp),
      });

      // then bump the summary fields on the parent trip:
      _tripAlertCount++;
      _tripFinalStatus = 'Alert Detected';
      await _currentTripRef!.update({
        'alerts': _tripAlertCount,
        'status': _tripFinalStatus,
      });
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
          SizedBox(
            key: ValueKey(_cameraViewKey),
            height: 500,
            width: 300,
            child: NativeView(
              onViewCreated: (controller) async {

                _mpController = controller;

                // Now start listening—PixelCopy will succeed:
                controller.landMarksStream.listen((landmarks) {
                  if (_isAnalyzing) _onLandmarkStream(landmarks);
                });

                if (!_seatbeltIsolateReady) _spawnSeatbeltIsolate();
              },
            ),


          ),

          // Black overlay when not analyzing:
          if (!_isAnalyzing)
            Container(
              height: 500,
              width: 300,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.black.withOpacity(0.85),
              ),
              child: const Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.camera_alt, color: Colors.grey, size: 100),
                    SizedBox(height: 10),
                    Text('Not Analyzing Yet', style: TextStyle(color: Colors.white)),
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
                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(builder: (_) => const MainAppScreen()),
                                (route) => false,  // remove all the old routes
                          );
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
                    // (always enabled once the page is visible, because the isolate is loading in parallel)
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
                    _statusIndicator('Yawning',
                        _mouthOpenness > 0.2 ? Colors.red : Colors.green,
                        _mouthOpenness.clamp(0.0, 1.0)),
                    _statusIndicator('Seatbelt', _noSeatbelt ? Colors.red : Colors.green, 1),
                    _statusIndicator(
                      _isDistracted
                          ? (_currentDistractionLabel ?? 'Distracted')
                          : 'Safe Driving',
                      _isDistracted ? Colors.red : Colors.green,
                      _isDistracted ? _currentDistractionConfidence : 1.0,  // show full green
                    ),
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

class SeatbeltBoxPainter extends CustomPainter {
  final List<Rect> boxes;     // in raw image coords
  final Size imageSize;       // e.g. camera.previewSize

  SeatbeltBoxPainter({
    required this.boxes,
    required this.imageSize,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // how much to stretch x/y from image → widget
    final double scaleX = size.width  / imageSize.width;
    final double scaleY = size.height / imageSize.height;

    final paint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke;

    for (final box in boxes) {
      // scale each corner
      final rect = Rect.fromLTRB(
        box.left   * scaleX,
        box.top    * scaleY,
        box.right  * scaleX,
        box.bottom * scaleY,
      );
      canvas.drawRect(rect, paint);
    }
  }

  @override
  bool shouldRepaint(covariant SeatbeltBoxPainter old) {
    return old.boxes    != boxes
        || old.imageSize != imageSize;

  }
}
