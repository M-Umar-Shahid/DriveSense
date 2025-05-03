// driver_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverDetailPage extends StatelessWidget {
  final String driverId;
  const DriverDetailPage({Key? key, required this.driverId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Overview'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .doc(driverId)
            .snapshots(),
        builder: (context, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final d = snap.data!.data() as Map<String, dynamic>? ?? {};
          final name     = d['name']   as String? ?? 'Unnamed';
          final focusPct = (d['focus'] as num?)?.toDouble() ?? 0.0;
          final rating   = (focusPct / 20).ceil().clamp(1, 5);

          // load trips & alerts counts in parallel
          return FutureBuilder<List<QuerySnapshot>>(
            future: Future.wait([
              FirebaseFirestore.instance
                  .collection('trips')
                  .where('driverId', isEqualTo: driverId)
                  .get(),
              FirebaseFirestore.instance
                  .collection('alerts')
                  .where('driverId', isEqualTo: driverId)
                  .get(),
            ]),
            builder: (context, statsSnap) {
              if (!statsSnap.hasData) return const Center(child: CircularProgressIndicator());
              final tripsCount  = statsSnap.data![0].docs.length;
              final alertsCount = statsSnap.data![1].docs.length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // header
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Theme.of(context).primaryColorLight,
                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: TextStyle(
                              color: Theme.of(context).primaryColorDark,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Text(name, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 24),

                    // stats grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      children: [
                        _StatCard(
                          icon: Icons.directions_car,
                          label: 'Trips',
                          value: tripsCount.toString(),
                        ),
                        _StatCard(
                          icon: Icons.notifications,
                          label: 'Alerts',
                          value: alertsCount.toString(),
                        ),
                        _StatCard(
                          icon: Icons.track_changes,
                          label: 'Focus %',
                          value: '${focusPct.toStringAsFixed(1)}%',
                        ),
                        _StatCard(
                          icon: Icons.star,
                          label: 'Rating',
                          customChild: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(5, (i) => Icon(
                              i < rating ? Icons.star : Icons.star_border,
                              color: Colors.amber,
                            )),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),

                    // (Example) List last 3 trips
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('trips')
                          .where('driverId', isEqualTo: driverId)
                          .orderBy('timestamp', descending: true)
                          .limit(3)
                          .snapshots(),
                      builder: (context, tripSnap) {
                        if (!tripSnap.hasData) return const Text('Loading trips...');
                        final trips = tripSnap.data!.docs;
                        if (trips.isEmpty) return const Text('No recent trips.');
                        return Column(
                          children: trips.map((doc) {
                            final t = doc.data()! as Map<String, dynamic>;
                            final when = t['timestamp'] is Timestamp
                                ? (t['timestamp'] as Timestamp).toDate()
                                : DateTime.now();
                            return ListTile(
                              dense: true,
                              leading: const Icon(Icons.history),
                              title: Text('Trip on ${when.month}/${when.day}/${when.year}'),
                              subtitle: Text('Distance: ${t['distance'] ?? '–'} km'),
                            );
                          }).toList(),
                        );
                      },
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final Widget? customChild;
  const _StatCard({
    Key? key,
    required this.icon,
    required this.label,
    this.value,
    this.customChild,
  })  : assert(value != null || customChild != null),
        super(key: key);

  @override
  Widget build(BuildContext context) {
    final child = customChild ?? Text(
      value!,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: Theme.of(context).primaryColor),
            const SizedBox(height: 12),
            Text(label, style: const TextStyle(color: Colors.grey)),
            const SizedBox(height: 8),
            child,
          ],
        ),
      ),
    );
  }
}
