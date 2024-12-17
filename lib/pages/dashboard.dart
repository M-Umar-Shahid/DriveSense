import 'package:curved_navigation_bar/curved_navigation_bar.dart';
import 'package:flutter/material.dart';

import 'monitoring_screen.dart';
import 'navigation_screen.dart';

class DashboardPage extends StatefulWidget {
  const DashboardPage({super.key});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  int _currentIndex = 0; // Track the selected tab

  // Pages to display based on selected index
  final List<Widget> _pages = [
    const DashboardContent(),
    const MonitoringPage(),
    const MapScreen(),
    const Center(
      child: Text(
        'Analytics Page',
        style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
      ),
    ),
    const Center(
      child: Text(
        'Profile Page',
        style: TextStyle(fontSize: 24.0, fontWeight: FontWeight.bold),
      ),
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: _pages[_currentIndex], // Dynamically load pages
      ),

      // Curved Bottom Navigation Bar
      bottomNavigationBar: CurvedNavigationBar(
        backgroundColor: Colors.transparent,
        color: Colors.blueAccent,
        buttonBackgroundColor: Colors.blueAccent,
        height: 60.0,
        index: _currentIndex, // Current index
        animationDuration: const Duration(milliseconds: 300),
        items: const <Widget>[
          Icon(Icons.home, size: 30, color: Colors.white),
          Icon(Icons.camera_alt, size: 30, color: Colors.white),
          Icon(Icons.map, size: 30, color: Colors.white),
          Icon(Icons.analytics, size: 30, color: Colors.white),
          Icon(Icons.person, size: 30, color: Colors.white),
        ],
        onTap: (index) {
          setState(() {
            _currentIndex = index; // Update the selected index
          });
        },
      ),
    );
  }
}

// This widget is the content for the "Home" tab
class DashboardContent extends StatelessWidget {
  const DashboardContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const SizedBox(height: 60.0),

          // Logo and Title
          Center(
            child: Column(
              children: [
                CircleAvatar(
                  radius: 50.0,
                  backgroundColor: Colors.white,
                  child: Image.asset(
                    'assets/images/logo.png',
                    fit: BoxFit.contain,
                    width: 60.0,
                    height: 60.0,
                  ),
                ),
                const SizedBox(height: 10.0),
                const Text(
                  'Drive Sense',
                  style: TextStyle(
                    fontSize: 24.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5.0),
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
          const SizedBox(height: 30.0),

          // Buttons
          Column(
            children: [
              CircularButton(
                text: 'Start Recording',
                logoPath: 'assets/images/camera-icon.png',
                onPressed: () {},
              ),
              const SizedBox(height: 20.0),
              CircularButton(
                text: 'Start Navigation',
                logoPath: 'assets/images/map-icon.png',
                onPressed: () {},
              ),
              const SizedBox(height: 20.0),
              CircularButton(
                text: 'View Analytics',
                logoPath: 'assets/images/analytics-icon.png',
                onPressed: () {},
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// Custom Circular Button
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
        shape: const CircleBorder(),
        backgroundColor: const Color(0xFF1976D2),
        padding: const EdgeInsets.all(30.0),
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
          const SizedBox(height: 5.0),
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14.0,
            ),
          ),
        ],
      ),
    );
  }
}
