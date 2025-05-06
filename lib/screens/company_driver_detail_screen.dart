import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DriverDetailPage extends StatelessWidget {
  final String driverId;
  const DriverDetailPage({Key? key, required this.driverId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],

      // — Gradient AppBar with back arrow & icon —
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(80),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Driver Overview',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.person_pin, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('drivers')
            .doc(driverId)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final d = snap.data!.data() as Map<String, dynamic>? ?? {};
          final name     = d['name']     as String? ?? 'Unnamed';
          final focusPct = (d['focus']  as num?)?.toDouble() ?? 0.0;
          final stars    = ((focusPct / 20).ceil()).clamp(1, 5);

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
            builder: (ctx, statsSnap) {
              if (!statsSnap.hasData) return const Center(child: CircularProgressIndicator());
              final tripsCount  = statsSnap.data![0].docs.length;
              final alertsCount = statsSnap.data![1].docs.length;

              return SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // — Profile Card —
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 32,
                              backgroundColor: Colors.blueAccent.withOpacity(0.1),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 28,
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                name,
                                style: const TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    // — Stats Grid Card —
                    Card(
                      elevation: 3,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: GridView.count(
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
                              label: 'Focus',
                              value: '${focusPct.toStringAsFixed(0)}%',
                            ),
                            _StatCard(
                              icon: Icons.star,
                              label: 'Rating',
                              customChild: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: List.generate(5, (i) {
                                  return Icon(
                                    i < stars ? Icons.star : Icons.star_border,
                                    color: Colors.amber,
                                    size: 20,
                                  );
                                }),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),
                    const Text(
                      'Recent Trips',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 12),

                    // — Recent Trips List —
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection('trips')
                          .where('driverId', isEqualTo: driverId)
                          .orderBy('timestamp', descending: true)
                          .limit(5)
                          .snapshots(),
                      builder: (ctx, tripSnap) {
                        if (tripSnap.hasError) return const Text('Error loading trips');
                        if (!tripSnap.hasData) return const Text('Loading trips...');
                        final trips = tripSnap.data!.docs;
                        if (trips.isEmpty) return const Text('No recent trips.');

                        return Column(
                          children: trips.map((doc) {
                            final t = doc.data()! as Map<String, dynamic>;
                            final when = t['timestamp'] is Timestamp
                                ? (t['timestamp'] as Timestamp).toDate()
                                : DateTime.now();
                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 6),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              child: ListTile(
                                leading: const Icon(Icons.history, color: Colors.blueAccent),
                                title: Text(
                                  '${when.month}/${when.day}/${when.year}',
                                  style: const TextStyle(fontWeight: FontWeight.w600),
                                ),
                                subtitle: Text('Distance: ${t['distance'] ?? '–'} km'),
                              ),
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
    final display = customChild ??
        Text(
          value!,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        );

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        display,
      ],
    );
  }
}
