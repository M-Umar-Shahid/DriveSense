import 'package:drivesense/screens/monitoring_screen.dart';
import 'package:drivesense/screens/analytics_screen.dart';
import 'package:drivesense/screens/image_alerts_screen.dart';
import 'package:drivesense/screens/profile_page_screen.dart';
import 'package:flutter/material.dart';
import '../components/dashboard_screen_components/dashboard_header.dart';
import '../components/dashboard_screen_components/recent_trips_alert.dart';
import '../components/dashboard_screen_components/summary_box.dart';
import '../components/dashboard_screen_components/rounded_button.dart';
import '../services/dashboard_sevice.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});
  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  final DashboardService _svc = DashboardService();
  String _username = '';
  int _alertCount = 0;
  int _tripCount = 0;
  double _focusPercentage = 0;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final name = await _svc.fetchUsername();
    final stats = await _svc.fetchStats();
    setState(() {
      _username = name;
      _alertCount = stats.alertCount;
      _tripCount = stats.tripCount;
      _focusPercentage = stats.focusPercentage;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF4F6FC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(children: [
            DashboardHeader(
              username: _username,
              onProfileTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage())),
            ),
            SizedBox(height: 20),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [BoxShadow(color: Colors.grey.withOpacity(0.1), blurRadius: 10, offset: Offset(0, 4))],
                ),
                child: Column(children: [
                  Row(children: [
                    Icon(Icons.analytics, color: Colors.deepPurple),
                    SizedBox(width: 8),
                    Text('Summary', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
                  ]),
                  SizedBox(height: 12),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    SummaryBox(title: 'Alerts', value: '$_alertCount', icon: Icons.warning_amber_rounded, iconColor: Colors.redAccent),
                    SummaryBox(title: 'Trips', value: '$_tripCount', icon: Icons.route, iconColor: Colors.green),
                    SummaryBox(title: 'Focus', value: '${_focusPercentage.toStringAsFixed(0)}%', icon: Icons.remove_red_eye, iconColor: Colors.blue),
                  ]),
                ]),
              ),
            ),
            SizedBox(height: 20),
            RoundedButton(
              icon: Icons.shield_rounded,
              label: "Start Detection",
              color: Colors.blueAccent,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const MonitoringPage())),
            ),
            SizedBox(height: 14),
            RoundedButton(
              icon: Icons.pie_chart,
              label: "View Analytics",
              color: Colors.deepPurple,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const AnalyticsPage())),
            ),
            SizedBox(height: 14),
            RoundedButton(
              icon: Icons.photo_library_rounded,
              label: "Detection Gallery",
              color: Colors.teal,
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ImageAlertsPage())),
            ),
            Padding(
              padding: EdgeInsets.fromLTRB(20, 25, 20, 8),
              child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                Text('Recent Trips', style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold)),
                Text('View All', style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w500, color: Colors.blueAccent)),
              ]),
            ),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 20),
              child: RecentTripsList(tripsFuture: _svc.fetchRecentTrips()),
            ),
          ]),
        ),
      ),
    );
  }
}
