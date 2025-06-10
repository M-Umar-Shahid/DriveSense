// lib/screens/driver_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/dashboard_stats.dart';
import '../services/company_service.dart';
import '../services/dashboard_sevice.dart';   // for rating

class DriverDetailPage extends StatelessWidget {
  final String driverId;
  const DriverDetailPage({super.key, required this.driverId});

  @override
  Widget build(BuildContext context) {
    final dashSvc   = DashboardService();
    final companySvc = CompanyService();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // ─── Curved Header + Avatar ───────────────────────────────
          SliverAppBar(
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                onPressed: () { /* your camera action */ },
              ),
            ],
            backgroundColor: Colors.transparent,
            expandedHeight: 260,
            pinned: true,
            elevation: 0,
            title: const Text(
              'Driver Overview',
              style: TextStyle(color: Colors.white),
            ),
            centerTitle: true,
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.pin,
              background: ClipPath(
                clipper: _AppBarWaveClipper(),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [BoxShadow(
                      color: Colors.black26,
                      blurRadius: 8,
                      offset: Offset(0, 4),
                    )],
                  ),
                  child: SafeArea(
                    bottom: false,
                    child: Column(
                      children: [
                        const SizedBox(height: 48), // leave room for status bar
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users').doc(driverId).snapshots(),
                          builder: (_, snap) {
                            if (!snap.hasData) {
                              return const CircleAvatar(
                                radius: 48,
                                backgroundColor: Colors.white24,
                                child: CircularProgressIndicator(color: Colors.white),
                              );
                            }
                            final data = snap.data!.data()! as Map<String, dynamic>;
                            final name = data['displayName'] as String? ?? '';
                            return CircleAvatar(
                              radius: 48,
                              backgroundColor: Colors.white,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 32,
                                  color: Color(0xFF1976D2),
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        StreamBuilder<DocumentSnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('users').doc(driverId).snapshots(),
                          builder: (_, snap) {
                            final data = snap.data?.data() as Map<String, dynamic>?;
                            final name = data?['displayName'] as String? ?? '';
                            return Text(
                              name,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                              ),
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Stats Grid ────────────────────────────────────────────
          SliverToBoxAdapter(
            child: FutureBuilder<DashboardStats>(
              future: dashSvc.fetchStatsForUser(driverId),
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Center(child: Text('Error: ${snap.error}')),
                  );
                }

                final stats = snap.data!;  // ← Now you have a `stats` variable to use

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  child: GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.3,
                    ),
                    children: [
                      _ColorStatCard(
                        icon: Icons.directions_car,
                        label: 'Trips',
                        value: stats.tripCount.toString(),
                        color: Colors.teal,
                      ),
                      _ColorStatCard(
                        icon: Icons.warning_amber,
                        label: 'Alerts',
                        value: stats.alertCount.toString(),
                        color: Colors.redAccent,
                      ),
                      _ColorStatCard(
                        icon: Icons.remove_red_eye,
                        label: 'Focus',
                        value: '${stats.focusPercentage.toStringAsFixed(0)}%',
                        color: Colors.blue,
                      ),
                      FutureBuilder<double>(
                        future: companySvc.getAverageRating(driverId),
                        builder: (ctx, r) {
                          final rating = r.data ?? 0.0;
                          return _ColorStatCard(
                            icon: Icons.star,
                            label: 'Rating',
                            value: rating.toStringAsFixed(1),
                            color: Colors.amber,
                          );
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // ─── Employment Timeline ───────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Employment History',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                  SizedBox(height: 8),
                  StreamBuilder<DocumentSnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users').doc(driverId).snapshots(),
                    builder: (_, snap) {
                      if (!snap.hasData) return SizedBox();
                      final assigns = (snap.data!.data()! as Map)['assignments'] as List;
                      return Column(
                        children: assigns.map((a) {
                          final hired = (a['dateHired'] as Timestamp).toDate();
                          final left = a['dateLeft'] != null
                              ? (a['dateLeft'] as Timestamp).toDate()
                              : null;
                          final active = a['status'] == 'active';
                          return _TimelineTile(
                            title: active ? 'Active' : 'Fired',
                            dateRange:
                            '${hired.toLocal().toIso8601String().split("T").first}'
                                ' → '
                                '${left!=null?left.toLocal().toIso8601String().split("T").first:"Present"}',
                            color: active? Colors.green : Colors.red,
                          );
                        }).toList(),
                      );
                    },
                  ),
                  SizedBox(height: 24),
                ],
              ),
            ),
          ),

          // ─── Recent Alerts Carousel ─────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text('Recent Alerts',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
          SliverToBoxAdapter(child: SizedBox(height: 8)),
          SliverToBoxAdapter(
            child: SizedBox(
              height: 140,
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('detections')
                    .where('uid', isEqualTo: driverId)
                    .orderBy('timestamp', descending: true)
                    .limit(5)
                    .snapshots(),
                builder: (_, s) {
                  if (!s.hasData) return Center(child: CircularProgressIndicator());
                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    itemCount: s.data!.docs.length,
                    separatorBuilder: (_,__) => SizedBox(width: 12),
                    itemBuilder: (_, i) {
                      final doc = s.data!.docs[i].data() as Map;
                      final ts = (doc['timestamp'] as Timestamp).toDate();
                      return _AlertCard(
                        type: doc['alertType'] ?? 'Alert',
                        time: '${ts.hour.toString().padLeft(2,'0')}:'
                            '${ts.minute.toString().padLeft(2,'0')}',
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColorStatCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final Color color;
  const _ColorStatCard({
    required this.icon, required this.label,
    required this.value, required this.color,
  });
  @override
  Widget build(BuildContext c) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Row(
        children: [
          Container(width: 6, height: double.infinity, color: color),
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 28, color: color),
                  SizedBox(height: 8),
                  Text(value,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  Text(label, style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
/// A simple timeline entry with a colored circle and left border
class _TimelineTile extends StatelessWidget {
  final String title, dateRange;
  final Color color;
  const _TimelineTile({
    required this.title, required this.dateRange, required this.color,
  });
  @override
  Widget build(BuildContext c) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Column(
            children: [
              Container(width: 12, height: 12, decoration: BoxDecoration(
                  color: color, shape: BoxShape.circle)),
              Container(width: 2, height: 60, color: Colors.grey[300]),
            ],
          ),
          SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 4),
                  Text(dateRange, style: TextStyle(color: Colors.grey)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// A compact alert card you can tap later
class _AlertCard extends StatelessWidget {
  final String type, time;
  const _AlertCard({required this.type, required this.time});
  @override
  Widget build(BuildContext c) {
    return Container(
      width: 140,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
      ),
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.notification_important,
                color: Colors.orange, size: 28),
            Spacer(),
            Text(type,
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 4),
            Text(time, style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}

/// Clips the bottom of the appbar into a smooth wave
class _AppBarWaveClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    // start at top-left
    path.lineTo(0, size.height - 40);
    // make a quadratic Bézier curve to bottom center, then to bottom-right
    path.quadraticBezierTo(
      size.width * 0.5, size.height,
      size.width, size.height - 40,
    );
    // line to top-right, then close
    path.lineTo(size.width, 0);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}
