import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:lottie/lottie.dart';
import 'company_driver_detail_screen.dart';

class DriverDetailPage extends StatelessWidget {
  final String driverId;
  const DriverDetailPage({Key? key, required this.driverId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          // ─── Stretchy Gradient Header ───────────────────────
          SliverAppBar(
            backgroundColor: Colors.transparent,
            expandedHeight: 200,
            pinned: true,
            stretch: true,
            elevation: 0,
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground, StretchMode.fadeTitle],
              title: const Text('Driver Overview'),
              centerTitle: true,
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: SafeArea(
                  bottom: false,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: Colors.white,
                      child: StreamBuilder<DocumentSnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('drivers')
                            .doc(driverId)
                            .snapshots(),
                        builder: (_, snap) {
                          if (!snap.hasData) return const CircularProgressIndicator();
                          final d = snap.data!.data() as Map<String, dynamic>;
                          final name = d['name'] as String? ?? 'Unnamed';
                          return Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                            style: const TextStyle(fontSize: 32, color: Color(0xFF1976D2), fontWeight: FontWeight.bold),
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),

          // ─── Details & Stats ────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
              child: StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('drivers').doc(driverId).snapshots(),
                builder: (ctx, snap) {
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }
                  if (snap.connectionState == ConnectionState.waiting) {
                    return Center(
                      child: Lottie.asset('assets/animations/loading_animation.json', width: 150, height: 150),
                    );
                  }

                  final d = snap.data!.data() as Map<String, dynamic>? ?? {};
                  final name     = d['name']     as String?  ?? 'Unnamed';
                  final focusPct = (d['focus']   as num?)?.toDouble() ?? 0.0;
                  final stars    = ((focusPct / 20).ceil()).clamp(1, 5);

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Name
                      Center(
                        child: Text(
                          name,
                          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Stats Grid
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: 1),
                        duration: const Duration(milliseconds: 500),
                        builder: (context, v, child) => Opacity(
                          opacity: v,
                          child: Transform.translate(offset: Offset(0, 30 * (1 - v)), child: child),
                        ),
                        child: Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          elevation: 4,
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: GridView.count(
                              crossAxisCount: 2,
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              mainAxisSpacing: 16,
                              crossAxisSpacing: 16,
                              children: [
                                _StatTile(icon: Icons.directions_car, label: 'Trips', futureQuery: FirebaseFirestore.instance.collection('trips').where('driverId', isEqualTo: driverId).get()),
                                _StatTile(icon: Icons.notifications, label: 'Alerts', futureQuery: FirebaseFirestore.instance.collection('alerts').where('driverId', isEqualTo: driverId).get()),
                                _ValueTile(icon: Icons.track_changes, label: 'Focus', value: '${focusPct.toStringAsFixed(0)}%'),
                                _CustomTile(icon: Icons.star, label: 'Rating', child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: List.generate(5, (j) => Icon(j < stars ? Icons.star : Icons.star_border, color: Colors.amber, size: 20)),
                                )),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),

          // ─── Recent Trips ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: const Text('Recent Trips', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
            ),
          ),
          SliverToBoxAdapter(child: const SizedBox(height: 8)),
          SliverList(
            delegate: SliverChildBuilderDelegate(
                  (ctx, index) {
                return FutureBuilder<QuerySnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('trips')
                      .where('driverId', isEqualTo: driverId)
                      .orderBy('timestamp', descending: true)
                      .limit(5)
                      .get(),
                  builder: (ctx, tripSnap) {
                    if (!tripSnap.hasData) return const Center(child: CircularProgressIndicator());
                    final trips = tripSnap.data!.docs;
                    if (trips.isEmpty) return const Center(child: Text('No recent trips.'));
                    return Column(
                      children: trips.map((doc) {
                        final t = doc.data()! as Map<String, dynamic>;
                        final when = (t['timestamp'] as Timestamp).toDate();
                        return TweenAnimationBuilder<double>(
                          tween: Tween(begin: 0, end: 1),
                          duration: Duration(milliseconds: 300 + index * 100),
                          builder: (context, v, child) => Opacity(
                            opacity: v,
                            child: Transform.translate(offset: Offset(0, 30 * (1 - v)), child: child),
                          ),
                          child: Card(
                            margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            elevation: 2,
                            child: ListTile(
                              leading: const Icon(Icons.history, color: Colors.blueAccent),
                              title: Text('${when.month}/${when.day}/${when.year}'),
                              subtitle: Text('Distance: ${t['distance'] ?? '–'} km'),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                );
              },
              childCount: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Future<QuerySnapshot> futureQuery;

  const _StatTile({required this.icon, required this.label, required this.futureQuery});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: futureQuery,
      builder: (_, snap) {
        final count = snap.hasData ? snap.data!.docs.length : null;
        return _ValueTile(
          icon: icon,
          label: label,
          value: count != null ? count.toString() : '–',
        );
      },
    );
  }
}

class _ValueTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _ValueTile({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      ],
    );
  }
}

class _CustomTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final Widget child;

  const _CustomTile({required this.icon, required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 32, color: Theme.of(context).primaryColor),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.grey)),
        const SizedBox(height: 8),
        child,
      ],
    );
  }
}
