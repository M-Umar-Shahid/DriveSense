import 'package:drivesense/pages/monitoring_screen.dart';
import 'package:flutter/material.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Back Button
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ),

              SizedBox(height: 20.0),

              // Logo and Title
              Center(
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50.0,
                      backgroundColor: Colors.white,
                      child: Image.asset(
                        'assets/images/logo.png', // Replace with your logo image path
                        fit: BoxFit.contain,
                        width: 60.0,
                        height: 60.0,
                      ),
                    ),

                    SizedBox(height: 10.0),

                    // Title
                    Text(
                      'Drive Sense',
                      style: TextStyle(
                        fontSize: 24.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    SizedBox(height: 5.0),

                    // Subtitle
                    const Text(
                      'Access your tools for a safer drive.',
                      style: TextStyle(
                        fontSize: 16.0,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),

              SizedBox(height: 30.0),

              // Buttons
              Column(
                children: [
                  CircularButton(
                    text: 'Start Recording',
                    logoPath: 'assets/images/camera-icon.png', // Replace with your camera logo path
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MonitoringPage()),
                      );
                    },
                  ),
                  SizedBox(height: 20.0),
                  CircularButton(
                    text: 'Start Navigation',
                    logoPath: 'assets/images/map-icon.png', // Replace with your microphone logo path
                    onPressed: () {},
                  ),
                  SizedBox(height: 20.0),
                  CircularButton(
                    text: 'View Analytics',
                    logoPath: 'assets/images/analytics-icon.png', // Replace with your navigation logo path
                    onPressed: () {},
                  ),
                ],
              ),

              SizedBox(height: 40.0),
            ],
          ),
        ),
      ),
    );
  }
}

class CircularButton extends StatelessWidget {
  final String text;
  final String logoPath;
  final VoidCallback onPressed;

  const CircularButton({
    required this.text,
    required this.logoPath,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        shape: CircleBorder(), backgroundColor: Color(0xFF1976D2),
        padding: EdgeInsets.all(30.0),
        elevation: 5.0,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(
            logoPath,
            width: 30.0,
            height: 30.0,
          ),
          SizedBox(height: 5.0),
          Text(
            text,
            style: TextStyle(
              color: Colors.white,
              fontSize: 14.0,
            ),
          ),
        ],
      ),
    );
  }
}

void main() => runApp(MaterialApp(
  home: DashboardPage(),
));
