import 'package:drivesense/screens/analytics_screen.dart';
import 'package:drivesense/screens/dashboard_screen.dart';
import 'package:drivesense/screens/profile_page_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';


class MainAppScreen extends StatefulWidget {
  const MainAppScreen({Key? key}) : super(key: key);
  @override
  _MainAppScreenState createState() => _MainAppScreenState();
}

class _MainAppScreenState extends State<MainAppScreen> {
  int _currentIndex = 0;
  late final String _uid;

  @override
  void initState() {
    super.initState();
    _uid = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      const Dashboard(),
      AnalyticsPage(driverId: _uid,showBack: false,),
      const ProfilePage(),
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        shape: const CircularNotchedRectangle(),
        notchMargin: 6,
        // give the bar a fixed height so your Column children won't overflow
        child: SizedBox(
          height: 60,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Home
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _currentIndex = 0),
                  child: _NavBarButton(
                    icon: Icons.dashboard,
                    label: 'Home',
                    active: _currentIndex == 0,
                  ),
                ),
              ),

              // Analytics
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _currentIndex = 1),
                  child: _NavBarButton(
                    icon: Icons.bar_chart,
                    label: 'Analytics',
                    active: _currentIndex == 1,
                  ),
                ),
              ),

              // Profile
              Expanded(
                child: InkWell(
                  onTap: () => setState(() => _currentIndex = 2),
                  child: _NavBarButton(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    active: _currentIndex == 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavBarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  const _NavBarButton({
    required this.icon,
    required this.label,
    required this.active,
  });

  @override
  Widget build(BuildContext context) {
    final color = active ? Colors.blueAccent : Colors.grey[600];
    return Column(
      mainAxisAlignment: MainAxisAlignment.center, // center vertically
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(fontSize: 10, color: color)),
      ],
    );
  }
}
