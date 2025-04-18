import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_mediapipe/flutter_mediapipe.dart';
import 'package:flutter_mediapipe/gen/landmark.pb.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:image/image.dart' as img;

class Detection {
  final double x1, y1, x2, y2;
  final double confidence;
  final int classIndex;
  Detection({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.confidence,
    required this.classIndex,
  });

  @override
  String toString() {
    return "Class: $classIndex, Conf: ${confidence.toStringAsFixed(2)}, Box: [${x1.toStringAsFixed(1)}, ${y1.toStringAsFixed(1)}, ${x2.toStringAsFixed(1)}, ${y2.toStringAsFixed(1)}]";
  }
}

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
  String _inferenceOutput = "No inference run yet";

  // Flag to indicate when the interpreter is loaded.
  bool _isInterpreterLoaded = false;

  // Instead of using a Timer, use a timestamp to track when eyes closed.
  DateTime? _eyesClosedSince;

  // Landmark indices used to compute eye openness.
  final List<int> leftEyeIndices = [159, 145, 33, 133];
  final List<int> rightEyeIndices = [386, 374, 362, 263];

  // TFLite interpreter.
  late Interpreter _interpreter;

  @override
  void initState() {
    super.initState();
    _loadTFLiteModel();
    _testAssetLoading();
  }

  Future<void> _loadTFLiteModel() async {
    try {
      _interpreter =
      await Interpreter.fromAsset('assets/models/best_float32.tflite');
      setState(() {
        _isInterpreterLoaded = true;
      });
      print('TFLite model loaded successfully.');
    } catch (e) {
      print("Error loading TFLite model: $e");
    }
  }

  // Called whenever a new set of landmarks is available.
  void _onLandmarkStream(NormalizedLandmarkList landmarkList) {
    double leftOpenness = _calculateEyeOpenness(landmarkList, leftEyeIndices);
    double rightOpenness = _calculateEyeOpenness(landmarkList, rightEyeIndices);
    double average = (leftOpenness + rightOpenness) / 2.0;

    setState(() {
      _averageEyeOpenness = average;
    });

    // Use a threshold (e.g., 0.12) to determine if eyes are closed.
    const double threshold = 0.12;
    if (average < threshold) {
      // Record time when eyes first close.
      if (_eyesClosedSince == null) {
        _eyesClosedSince = DateTime.now();
      } else {
        // If eyes remain closed for more than 1 second, trigger an alert.
        if (DateTime.now().difference(_eyesClosedSince!) >=
            const Duration(seconds: 1)) {
          if (!_isDrowsy) {
            setState(() {
              _isDrowsy = true;
              _addRecentAlert("Drowsy detected");
            });
          }
        }
      }
    } else {
      // Eyes are open; reset timer and alert flag.
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

  Future<void> _testAssetLoading() async {
    try {
      final data = await rootBundle.load('assets/models/best_float32.tflite');
      print("Asset loaded, length: ${data.lengthInBytes}");
    } catch (e) {
      print("Error loading asset: $e");
    }
  }

  void _addRecentAlert(String alert) {
    if (!_recentAlerts.contains(alert)) {
      _recentAlerts.add(alert);
      if (_recentAlerts.length > 5) {
        _recentAlerts.removeAt(0);
      }
    }
  }

  // This function simulates receiving a camera frame by loading a sample image
  Future<void> _simulateInference() async {
    if (!_isInterpreterLoaded) {
      setState(() {
        _inferenceOutput = "Interpreter not loaded yet.";
      });
      return;
    }

    try {
      // Load sample image bytes from assets (update path if needed).
      final imageData = await rootBundle.load('assets/sample.jpg');
      final imageBytes = imageData.buffer.asUint8List();
      _onCameraFrame(imageBytes);
    } catch (e) {
      setState(() {
        _inferenceOutput = "Error loading sample image: $e";
      });
      print("Error loading sample image: $e");
    }
  }

  // Callback for processing a raw camera frame as Uint8List.
  void _onCameraFrame(Uint8List imageBytes) async {
    if (!_isInterpreterLoaded) {
      setState(() {
        _inferenceOutput = "Interpreter not loaded yet.";
      });
      return;
    }

    try {
      final input = _preprocessImage(imageBytes);
      // Prepare an output buffer. According to your model, output shape is [1, 6, 8400].
      var output = List.generate(
        1,
            (_) => List.generate(6, (_) => List.filled(8400, 0.0)),
      );
      _interpreter.run(input, output);

      // Post-process the raw output to get detection results.
      List<Detection> detections = _postProcessDetections(output, 0.1);

      // For demonstration, summarize the detections.
      String resultSummary = "Detections: ${detections.length}\n";
      for (var det in detections) {
        resultSummary += "${det.toString()}\n";
      }
      setState(() {
        _inferenceOutput = resultSummary;
      });
    } catch (e) {
      setState(() {
        _inferenceOutput = "Error during inference: $e";
      });
      print("Error during TFLite inference: $e");
    }
  }

  // Preprocess the raw image to match the model's input shape [1, 640, 640, 3].
  List<List<List<List<double>>>> _preprocessImage(Uint8List imageBytes) {
    img.Image? originalImage = img.decodeImage(imageBytes);
    if (originalImage == null) {
      throw Exception("Unable to decode image.");
    }
    // Resize the image to 640x640.
    img.Image resizedImage = img.copyResize(originalImage, width: 640, height: 640);
    // Create a 4D tensor.
    List<List<List<List<double>>>> input = List.generate(
      1,
          (_) => List.generate(
        640,
            (_) => List.generate(
          640,
              (_) => List.filled(3, 0.0),
        ),
      ),
    );

    // Populate the tensor with normalized pixel values.
    for (int y = 0; y < 640; y++) {
      for (int x = 0; x < 640; x++) {
        final pixelObj = resizedImage.getPixel(x, y); // a Pixel object
        // Using the getChannel method from the image package.
        num r = pixelObj.getChannel(img.Channel.red);
        num g = pixelObj.getChannel(img.Channel.green);
        num b = pixelObj.getChannel(img.Channel.blue);

        input[0][y][x][0] = r / 255.0;
        input[0][y][x][1] = g / 255.0;
        input[0][y][x][2] = b / 255.0;
      }
    }
    return input;
  }

  // Post-process the raw model output to detections.
  List<Detection> _postProcessDetections(List output, double confThreshold) {
    // Assuming output shape: [1, 6, 8400]
    final predictions = output[0]; // predictions is List of 6 lists (each of length 8400)
    List<Detection> detections = [];
    int numCandidates = predictions[0].length;

    for (int i = 0; i < numCandidates; i++) {
      double centerX = predictions[0][i];
      double centerY = predictions[1][i];
      double width = predictions[2][i];
      double height = predictions[3][i];
      double confidence = predictions[4][i];
      double classScore = predictions[5][i]; // best class index (or score)

      if (confidence < confThreshold) continue;

      // Convert from center to top-left and bottom-right coordinates.
      double x1 = centerX - width / 2.0;
      double y1 = centerY - height / 2.0;
      double x2 = centerX + width / 2.0;
      double y2 = centerY + height / 2.0;

      detections.add(Detection(
        x1: x1,
        y1: y1,
        x2: x2,
        y2: y2,
        confidence: confidence,
        classIndex: classScore.toInt(),
      ));
    }

    // Apply Non-Maximum Suppression (NMS)
    return _nonMaxSuppression(detections, 0.45);
  }

  // A simple implementation of Non-Maximum Suppression.
  List<Detection> _nonMaxSuppression(List<Detection> detections, double iouThreshold) {
    // Sort by confidence
    detections.sort((a, b) => b.confidence.compareTo(a.confidence));
    List<Detection> finalDetections = [];

    while (detections.isNotEmpty) {
      Detection best = detections.removeAt(0);
      finalDetections.add(best);
      detections = detections.where((det) {
        return _iou(best, det) < iouThreshold;
      }).toList();
    }
    return finalDetections;
  }

  // Compute Intersection over Union (IoU) between two boxes.
  double _iou(Detection a, Detection b) {
    double interX1 = math.max(a.x1, b.x1);
    double interY1 = math.max(a.y1, b.y1);
    double interX2 = math.min(a.x2, b.x2);
    double interY2 = math.min(a.y2, b.y2);
    double interArea = math.max(0, interX2 - interX1) * math.max(0, interY2 - interY1);
    double areaA = (a.x2 - a.x1) * (a.y2 - a.y1);
    double areaB = (b.x2 - b.x1) * (b.y2 - b.y1);
    double unionArea = areaA + areaB - interArea;
    return unionArea == 0 ? 0 : interArea / unionArea;
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
                          // Listen to landmarks for drowsiness detection.
                          controller.landMarksStream.listen(_onLandmarkStream);
                          // Uncomment the next line if your plugin supports raw camera frames.
                          // controller.cameraFrameStream?.listen(_onCameraFrame);
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
              Text(
                _isInterpreterLoaded ? "Interpreter Loaded" : "Loading Interpreter...",
                style: const TextStyle(color: Colors.blue, fontSize: 14),
              ),
              // Test Inference Button
              Center(
                child: ElevatedButton(
                  onPressed: _isInterpreterLoaded ? _simulateInference : null,
                  child: const Text('Simulate Inference'),
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
              const SizedBox(height: 20.0),
              // Inference Output Section
              const Text(
                'TFLite Model Output:',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                _inferenceOutput,
                style: const TextStyle(color: Colors.black),
              ),
            ],
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
