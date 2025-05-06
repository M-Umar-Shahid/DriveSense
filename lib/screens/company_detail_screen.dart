import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'company_driver_detail_screen.dart';

class CompanyDetailPage extends StatelessWidget {
  final String companyId;
  const CompanyDetailPage({Key? key, required this.companyId}) : super(key: key);

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
                    'Company Drivers & Ratings',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.business, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),

      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .snapshots(),
        builder: (ctx, compSnap) {
          if (compSnap.hasError)
            return Center(child: Text('Error: ${compSnap.error}'));
          if (!compSnap.hasData)
            return const Center(child: CircularProgressIndicator());

          final data = compSnap.data!.data() as Map<String, dynamic>? ?? {};
          final driverIds = List<String>.from(data['driverIds'] ?? []);

          if (driverIds.isEmpty) {
            return const Center(child: Text('No drivers assigned.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: driverIds.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, i) {
              final id = driverIds[i];
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('drivers')
                    .doc(id)
                    .snapshots(),
                builder: (ctx, drvSnap) {
                  if (drvSnap.hasError)
                    return ListTile(title: Text('Error loading $id'));
                  if (!drvSnap.hasData)
                    return const ListTile(title: Text('Loading...'));

                  final d = drvSnap.data!.data() as Map<String, dynamic>? ?? {};
                  final name     = d['name']   as String?  ?? 'Unnamed';
                  final focusPct = (d['focus'] as num?)?.toDouble() ?? 0.0;
                  // convert focusPct [0–100] into stars 1–5
                  final stars    = ((focusPct / 20).ceil()).clamp(1, 5);

                  return Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverDetailPage(driverId: id),
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Row(
                          children: [
                            // Avatar
                            CircleAvatar(
                              radius: 28,
                              backgroundColor: Colors.blueAccent.withOpacity(0.1),
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                                style: const TextStyle(
                                  fontSize: 24,
                                  color: Colors.blueAccent,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),

                            // Name + rating stars
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

                            // chevron icon
                            const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}
