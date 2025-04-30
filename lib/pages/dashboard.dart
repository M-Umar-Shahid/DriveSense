import 'package:drivesense/pages/analytics_page.dart';
import 'package:drivesense/pages/monitoring_screen.dart';
import 'package:drivesense/pages/profile_page.dart';
import 'package:drivesense/pages/image_alerts_page.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../main.dart';


class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> with RouteAware{
  String _username = "";
  int _alertCount = 0;
  int _tripCount = 0;
  double _focusPercentage = 0.0;

  @override
  void initState() {
    super.initState();
    _fetchUserInfo();
    _fetchDashboardData();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    routeObserver.subscribe(this, ModalRoute.of(context)! as PageRoute);
  }

  @override
  void dispose() {
    routeObserver.unsubscribe(this);
    super.dispose();
  }

  @override
  void didPopNext() {
    // This is triggered when coming back to this page from another
    _fetchDashboardData();
  }


  void _fetchUserInfo() {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      setState(() {
        _username = user.displayName ?? user.email?.split('@').first ?? "User";
      });
    }
  }

  Future<void> _fetchDashboardData() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final alertsSnap = await FirebaseFirestore.instance
        .collection('detections')
        .where('uid', isEqualTo: user.uid)
        .get();

    final tripsSnap = await FirebaseFirestore.instance
        .collection('trips')
        .where('uid', isEqualTo: user.uid)
        .get();

    int safeTrips = 0;
    for (var trip in tripsSnap.docs) {
      if ((trip.data()['status'] ?? '') == 'Safe') safeTrips++;
    }

    setState(() {
      _alertCount = alertsSnap.size;
      _tripCount = tripsSnap.size;
      _focusPercentage = tripsSnap.size > 0
          ? (safeTrips / tripsSnap.size * 100)
          : 0.0;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F6FC),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top Header
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF1976D2),
                  borderRadius: BorderRadius.only(
                    bottomLeft: Radius.circular(28.0),
                    bottomRight: Radius.circular(28.0),
                  ),
                ),
                padding: const EdgeInsets.fromLTRB(20, 25, 20, 35),
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Hi, $_username 👋',
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ProfilePage(),
                              ),
                            );
                          },
                          icon: const Icon(Icons.person, color: Colors.white, size: 28),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    const Text(
                      "This Month's Overview",
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        color: Colors.white70,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // Summary Panel
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withOpacity(0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.analytics, color: Colors.deepPurple),
                          SizedBox(width: 8),
                          Text(
                            'Summary',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black87,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _summaryBox("Alerts", "$_alertCount", Icons.warning_amber_rounded, Colors.redAccent),
                          _summaryBox("Trips", "$_tripCount", Icons.route, Colors.green),
                          _summaryBox("Focus", "${_focusPercentage.toStringAsFixed(0)}%", Icons.remove_red_eye, Colors.blue),
                        ],
                      )
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              _roundedButton(
                icon: Icons.shield_rounded,
                label: "Start Detection",
                color: Colors.blueAccent,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const MonitoringPage()),
                  );
                },
              ),

              const SizedBox(height: 14),

              _roundedButton(
                icon: Icons.pie_chart,
                label: "View Analytics",
                color: Colors.deepPurple,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AnalyticsPage()),
                  );
                },
              ),

              const SizedBox(height: 14),

              _roundedButton(
                icon: Icons.photo_library_rounded,
                label: "Detection Gallery",
                color: Colors.teal,
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ImageAlertsPage()),
                  );
                },
              ),

              // Recent Trips
              const Padding(
                padding: EdgeInsets.fromLTRB(20, 25, 20, 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Recent Trips',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'View All',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.blueAccent,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('trips')
                      .where('uid', isEqualTo: FirebaseAuth.instance.currentUser?.uid)
                      .orderBy('endTime', descending: true)
                      .limit(3)
                      .get(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const CircularProgressIndicator();
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return const Text("No trips found");
                    }

                    final trips = snapshot.data!.docs;

                    return Column(
                      children: trips.asMap().entries.map((entry) {
                        final index = entry.key;
                        final trip = entry.value;
                        final start = (trip['startTime'] as Timestamp).toDate();
                        final end = (trip['endTime'] as Timestamp).toDate();
                        final alerts = trip['alerts'] ?? 0;
                        final status = trip['status'] ?? "Unknown";

                        return _tripCard(
                          tripNo: "${index + 1}",
                          start: _formatTime(start),
                          end: _formatTime(end),
                          alerts: alerts,
                          status: status,
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  String _formatTime(DateTime dt) {
    return "${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }


  static Widget _summaryBox(String title, String value, IconData icon, Color iconColor) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: iconColor.withOpacity(0.1),
          child: Icon(icon, color: iconColor),
        ),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 12,
            color: Colors.grey,
          ),
        ),
      ],
    );
  }

  Widget _roundedButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black12.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(width: 12),
              Text(
                label,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static Widget _tripCard({
    required String tripNo,
    required String start,
    required String end,
    required int alerts,
    required String status,
  }) {
    Color statusColor = status == "Safe" ? Colors.green : Colors.redAccent;
    IconData statusIcon = status == "Safe" ? Icons.check_circle : Icons.warning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Trip #$tripNo",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
              Text(
                "$start → $end",
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 18),
              const SizedBox(width: 6),
              Text(
                "$alerts Alert${alerts != 1 ? 's' : ''}",
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: statusColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}