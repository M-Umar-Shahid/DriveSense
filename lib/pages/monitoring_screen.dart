import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import 'dart:math' as math;

class MonitoringPage extends StatefulWidget {
  const MonitoringPage({super.key});

  @override
  State<MonitoringPage> createState() => _MonitoringPageState();
}

class _MonitoringPageState extends State<MonitoringPage> {
  CameraController? _cameraController;
  List<CameraDescription>? _cameras;
  bool _isCameraInitialized = false;
  bool _isAnalyzing = false;

  Future<void> initializeCamera() async {
    _cameras = await availableCameras();
    final frontCamera = _cameras!.firstWhere(
          (camera) => camera.lensDirection == CameraLensDirection.front,
    );

    _cameraController = CameraController(
      frontCamera,
      ResolutionPreset.high,
    );

    await _cameraController!.initialize();
    setState(() {
      _isCameraInitialized = true;
    });
  }

  void toggleAnalyzing() async {
    if (_isAnalyzing) {
      // Stop analyzing: Dispose of the camera
      await _cameraController?.dispose();
      setState(() {
        _isCameraInitialized = false;
        _isAnalyzing = false;
        _cameraController = null;
      });
    } else {
      // Start analyzing: Initialize the camera
      await initializeCamera();
      setState(() {
        _isAnalyzing = true;
      });
    }
  }

  @override
  void dispose() {
    _cameraController?.dispose();
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
                        child: _isAnalyzing && _isCameraInitialized && _cameraController != null
                            ? ClipRRect(
                          borderRadius: BorderRadius.circular(12.0),
                          child: Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()..rotateY(math.pi),
                            child: CameraPreview(_cameraController!),
                          ),
                        )
                            : Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.camera_alt, color: Colors.grey, size: 100),
                              const SizedBox(height: 10),
                              const Text(
                                'Camera not active',
                                style: TextStyle(color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ),
                      if (_isAnalyzing)
                        Positioned(
                          bottom: 10.0,
                          right: 10.0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8.0, vertical: 4.0),
                            decoration: BoxDecoration(
                              color: Colors.black54,
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: const Text(
                              'Camera is Active',
                              style: TextStyle(
                                color: Colors.greenAccent,
                                fontSize: 12.0,
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
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            SizedBox(
              width: 60.0,
              height: 60.0,
              child: CircularProgressIndicator(
                value: 0.5, // Adjust value dynamically as needed
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
                color: color,
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
