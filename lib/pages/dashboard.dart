import 'package:drivesense/pages/monitoring_screen.dart';
import 'package:drivesense/pages/navigation_screen.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatelessWidget {
  const Dashboard({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white, // Light mode background
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.settings, size: 28.0, color: Colors.black54),
                ),
              ),
            ),

            const SizedBox(height: 40.0),

            // Car Image Section
            Center(
              child: Image.asset(
                'assets/images/car_image.png',
                width: 400.0,
                fit: BoxFit.cover,
              ),
            ),

            const SizedBox(height: 40.0),

            // Detection Card (Full-width Button)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MonitoringPage()),
                  );
                },
                child: _fullWidthCard(
                  icon: Icons.lock,
                  label: "Detection",
                  color: Colors.blueAccent,
                ),
              ),
            ),

            const SizedBox(height: 20.0),

            // Bottom Section: Analytics and Map
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const SignUpPage()),
                      );
                    },
                    child: _bottomWidget(
                      icon: Icons.analytics,
                      label: "Analytics",
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const MapScreen()),
                      );
                    },
                    child: _mapContainer(
                      mapPath: 'assets/images/map.png',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Full Width Card Widget for Detection
  Widget _fullWidthCard({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      height: 150.0,
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40.0, color: color),
          const SizedBox(width: 10.0),
          Text(
            label,
            style: TextStyle(
              fontSize: 20.0,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  // Custom Analytics Widget
  Widget _bottomWidget({
    required IconData icon,
    String? label,
  }) {
    return Container(
      width: 160.0,
      height: 160.0,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40.0, color: Colors.blueAccent),
            const SizedBox(height: 10.0),
            if (label != null)
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
              ),
          ],
        ),
      ),
    );
  }

  // Full Map Container
  Widget _mapContainer({required String mapPath}) {
    return Container(
      width: 200.0,
      height: 160.0,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16.0),
        boxShadow: const [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8.0,
            offset: Offset(0, 4),
          ),
        ],
        image: DecorationImage(
          image: AssetImage(mapPath),
          fit: BoxFit.fill,
        ),
      ),
    );
  }
}
