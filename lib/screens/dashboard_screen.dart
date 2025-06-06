import 'package:drivesense/components/dashboard_screen_components/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:lottie/lottie.dart';
import '../services/dashboard_sevice.dart';
import '../models/trip.dart';
import '../components/dashboard_screen_components/trip_card.dart';
import '../screens/image_alerts_screen.dart';
import '../screens/all_trips_screen.dart';
import '../screens/monitoring_screen.dart';
import '../screens/companies_list_page.dart';
import 'analytics_screen.dart';
import 'package:drivesense/screens/drivers_request_page.dart';

import 'chat_screen.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({Key? key}) : super(key: key);
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<Dashboard>
    with SingleTickerProviderStateMixin {
  final _svc = DashboardService();
  final _uid = FirebaseAuth.instance.currentUser!.uid;

  bool _loading = true;
  String _username = '';
  int _alerts = 0, _trips = 0;
  double _focus = 0;
  bool _openToWork = false;
  List<Trip> _recent = [];
  late String companyId;

  late final AnimationController _animC;
  late final Animation<double> _fadeIn;

  @override
  void initState() {
    super.initState();
    _animC = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fadeIn = CurvedAnimation(parent: _animC, curve: Curves.easeIn);

    _loadData();
  }

  Future<void> _loadData() async {
    final name    = await _svc.fetchUsername();
    final stats   = await _svc.fetchStatsForUser(_uid);
    final docSnap = await FirebaseFirestore.instance
        .collection('users')
        .doc(_uid)
        .get();
    final data = docSnap.data();
    companyId = data?['company'];

    final recentTrips = await _svc.fetchRecentTrips(limit: 3);

    setState(() {
      _username   = name;
      _alerts     = stats.alertCount;
      _trips      = stats.tripCount;
      _focus      = stats.focusPercentage;
      _openToWork = (docSnap.data()?['openToWork'] as bool?) ?? false;
      _recent     = recentTrips;
      _loading    = false;
    });

    _animC.forward();
  }

  @override
  void dispose() {
    _animC.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
        if (_loading) {
          return Scaffold(
            backgroundColor: Colors.white,
            body: Center(
              child: Lottie.asset(
                'assets/animations/loading_animation.json',
                width: 180,
                height: 180,
                fit: BoxFit.contain,
                repeat: true,
              ),
            ),
          );
        }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('DriveSense', style: TextStyle(color: Colors.blueAccent,fontWeight: FontWeight.w600,fontFamily: 'Poppins')),
        actions: [
          if (_openToWork)
              IconButton(
                icon: const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent),
                tooltip: "Chat with Admin",
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ChatScreen(
                        companyId: companyId,
                        peerId: _uid,
                      ),
                    ),
                  );
                },
              ),
          IconButton(
              icon: Icon(Icons.business, color: Colors.blueAccent),
              onPressed: () {
                Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const CompaniesListPage()));
              },
            ),
          IconButton(
            icon: const Icon(Icons.mail_outline, color: Colors.blueAccent),
            tooltip: 'Hire Requests',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const DriverRequestsPage()),
              );
            },
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fadeIn,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildWelcomeCard(),
            const SizedBox(height: 24),
            _buildOverviewCards(),
            const SizedBox(height: 24),
            _buildActionButtons(),
            const SizedBox(height: 24),
            _buildRecentHeader(),
            ..._recent.map((t) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: TripCard(t),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Colors.blueAccent, Colors.purpleAccent],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        const CircleAvatar(
          backgroundColor: Colors.white24,
          child: Icon(Icons.person, color: Colors.white),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Welcome back,',
                  style: TextStyle(color: Colors.white70)),
              const SizedBox(height: 4),
              Text(_username,
                  style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 6),
              Text('Month Summary Dashboard',
                  style: TextStyle(color: Colors.white70)),
            ],
          ),
        ),
      ]),
    );
  }

  Widget _buildOverviewCards() {
    return Row(
      children: [
        // Trips card
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const AllTripsPage())
              );
            },
            child: _overviewCard(
              Icons.route,
              '$_trips',
              'Total Trips',
              Colors.blue,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Alerts card
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const ImageAlertsPage())
              );
            },
            child: _overviewCard(
              Icons.warning_amber_rounded,
              '$_alerts',
              'Total Alerts',
              Colors.orange,
            ),
          ),
        ),
        const SizedBox(width: 12),

        // Focus card
        Expanded(
          child: InkWell(
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (_) => AnalyticsPage(driverId: _uid))
              );
            },
            child: _overviewCard(
              Icons.remove_red_eye,
              '${_focus.toStringAsFixed(0)}%',
              'Focus',
              Colors.green,
            ),
          ),
        ),
      ],
    );
  }

  Widget _overviewCard(
      IconData icon, String value, String label, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text(value,
                style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.document_scanner_outlined, size: 20),
            label: const Text('Detect'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,     // ← here
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MonitoringPage()),
              ).then((_) {
                // Called when MonitoringPage is popped (even with system back)
                _loadData(); // 🔁 refresh dashboard data
              });

            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.photo_library, size: 20),
            label: const Text('Gallery'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blueAccent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImageAlertsPage()),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildRecentHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Recent Trips',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        TextButton(
          onPressed: () {
            Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AllTripsPage()));
          },
          child: const Text('View All'),
        )
      ],
    );
  }
}