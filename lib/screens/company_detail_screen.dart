// company_detail_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'company_driver_detail_screen.dart';

class CompanyDetailPage extends StatelessWidget {
  final String companyId;
  const CompanyDetailPage({Key? key, required this.companyId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Drivers & Ratings'),
        centerTitle: true,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .snapshots(),
        builder: (context, compSnap) {
          if (compSnap.hasError) return Center(child: Text('Error: ${compSnap.error}'));
          if (!compSnap.hasData)   return const Center(child: CircularProgressIndicator());

          final data = compSnap.data!.data() as Map<String, dynamic>? ?? {};
          final driverIds = List<String>.from(data['driverIds'] ?? []);

          if (driverIds.isEmpty) {
            return const Center(child: Text('No drivers assigned.'));
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: driverIds.length,
            separatorBuilder: (_,__) => const SizedBox(height: 12),
            itemBuilder: (context, i) {
              final id = driverIds[i];
              return StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance.collection('drivers').doc(id).snapshots(),
                builder: (context, drvSnap) {
                  if (drvSnap.hasError) return ListTile(title: Text('Error loading $id'));
                  if (!drvSnap.hasData) return const ListTile(title: Text('Loading...'));

                  final d = drvSnap.data!.data() as Map<String, dynamic>? ?? {};
                  final name     = d['name']   as String? ?? 'Unnamed';
                  final focusPct = (d['focus'] as num?)?.toDouble() ?? 0.0;
                  var   rating   = (focusPct / 20).ceil().clamp(1, 5);

                  return Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: ListTile(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverDetailPage(driverId: id),
                        ),
                      ),
                      leading: CircleAvatar(
                        backgroundColor: Theme.of(context).primaryColorLight,
                        child: Text(
                          name.isNotEmpty ? name[0].toUpperCase() : '?',
                          style: TextStyle(
                            color: Theme.of(context).primaryColorDark,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Row(
                        children: List.generate(5, (j) => Icon(
                          j < rating ? Icons.star : Icons.star_border,
                          size: 20, color: Colors.amber,
                        )),
                      ),
                      trailing: const Icon(Icons.arrow_forward_ios, size: 16),
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
