import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'company_driver_detail_screen.dart';

class CompanyDetailPage extends StatelessWidget {
  final String companyId;
  const CompanyDetailPage({Key? key, required this.companyId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          // ─── Fancy Gradient Header ────────────────────────────────
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
              boxShadow: [
                BoxShadow(color: Colors.black26, blurRadius: 8, offset: Offset(0, 4)),
              ],
            ),
            padding: const EdgeInsets.only(top: 40, bottom: 24, left: 16, right: 16),
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Company Drivers & Ratings',
                    style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                ),
                const Icon(Icons.business, color: Colors.white, size: 28),
              ],
            ),
          ),

          // ─── Body: Company + Drivers Stream ───────────────────────
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: FirebaseFirestore.instance.collection('companies').doc(companyId).snapshots(),
              builder: (ctx, compSnap) {
                if (compSnap.hasError) {
                  return Center(child: Text('Error: ${compSnap.error}'));
                }
                if (compSnap.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: Lottie.asset(
                      'assets/animations/loading_animation.json',
                      width: 200,
                      height: 200,
                      repeat: true,
                    ),
                  );
                }

                final data = compSnap.data!.data() as Map<String, dynamic>? ?? {};
                final driverIds = List<String>.from(data['driverIds'] ?? []);

                if (driverIds.isEmpty) {
                  return const Center(child: Text('No drivers assigned.'));
                }

                return ListView.separated(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                  itemCount: driverIds.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (ctx, i) {
                    final id = driverIds[i];

                    return TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: 1),
                      duration: Duration(milliseconds: 300 + i * 100),
                      builder: (context, v, child) => Opacity(
                        opacity: v,
                        child: Transform.translate(
                          offset: Offset(0, 30 * (1 - v)),
                          child: child,
                        ),
                      ),
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance.collection('users').doc(id).snapshots(),
                        builder: (ctx, drvSnap) {
                          if (drvSnap.hasError) return ListTile(title: Text('Error loading $id'));
                          if (!drvSnap.hasData) return ListTile(title: Text('Loading...'));

                          final d = drvSnap.data!.data() as Map<String, dynamic>? ?? {};
                          final name = d['displayName'] as String? ?? 'Unnamed';

                          return FutureBuilder<DashboardStats>(
                            future: fetchStatsForUser(id),
                            builder: (context, statsSnap) {
                              if (!statsSnap.hasData) {
                                return const SizedBox(); // or a skeleton placeholder
                              }

                              final stats = statsSnap.data!;
                              final focusPct = stats.focusPercentage;
                              final stars = ((focusPct / 20).ceil()).clamp(1, 5);


                              return Container(
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [Colors.white, Colors.blue.shade50],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0,4)),
                                  ],
                                ),
                                child: InkWell(
                                  borderRadius: BorderRadius.circular(20),
                                  onTap: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (_) => DriverDetailPage(driverId: id)),
                                  ),
                                  child: Padding(
                                    padding: const EdgeInsets.all(16),
                                    child: Row(
                                      children: [
                                        Container(
                                          width: 56,
                                          height: 56,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: LinearGradient(
                                              colors: [Colors.blue.shade100, Colors.blue.shade200],
                                              begin: Alignment.topLeft,
                                              end: Alignment.bottomRight,
                                            ),
                                          ),
                                          child: Center(
                                            child: Text(
                                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                                              style: const TextStyle(
                                                fontSize: 24,
                                                color: Colors.white,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                name,
                                                style: const TextStyle(
                                                  fontSize: 18,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                              const SizedBox(height: 8),
                                              Row(
                                                children: List.generate(5, (j) {
                                                  return Icon(
                                                    j < stars ? Icons.star : Icons.star_border,
                                                    color: Colors.amber,
                                                    size: 20,
                                                  );
                                                }),
                                              ),
                                              const SizedBox(height: 4),
                                              Text(
                                                '${focusPct.toStringAsFixed(0)}% focus',
                                                style: const TextStyle(
                                                  fontSize: 14,
                                                  color: Colors.grey,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                        const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  Future<double> getDriverFocus(String driverId) async {
    final tripsSnap = await FirebaseFirestore.instance
        .collection('trips')
        .where('driverId', isEqualTo: driverId)
        .get();

    final total = tripsSnap.size;
    if (total == 0) return 0.0;

    final safeTrips = tripsSnap.docs.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      return data['status'] == 'Safe';
    }).length;

    return (safeTrips / total) * 100;
  }

  Future<DashboardStats> fetchStatsForUser(String uid) async {
    final alertsSnap = await FirebaseFirestore.instance
        .collection('detections')
        .where('uid', isEqualTo: uid)
        .get();

    final tripsSnap = await FirebaseFirestore.instance
        .collection('trips')
        .where('uid', isEqualTo: uid)
        .get();

    final safeTrips = tripsSnap.docs
        .where((d) => (d.data() as Map<String, dynamic>)['status'] == 'Safe')
        .length;

    final totalTrips = tripsSnap.size;
    final focus = totalTrips > 0 ? (safeTrips / totalTrips * 100) : 0.0;

    return DashboardStats(
      alertCount: alertsSnap.size,
      tripCount: totalTrips,
      focusPercentage: focus,
    );
  }


}
class DashboardStats {
  final int alertCount;
  final int tripCount;
  final double focusPercentage;

  DashboardStats({
    required this.alertCount,
    required this.tripCount,
    required this.focusPercentage,
  });
}

