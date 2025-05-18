import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/company_service.dart';

class AssignedDriversPage extends StatelessWidget {
  final String companyId;
  const AssignedDriversPage({Key? key, required this.companyId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final _companyService = CompanyService();

    return Scaffold(
      appBar: AppBar(title: const Text('Hired Drivers')),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('companies')
            .doc(companyId)
            .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final driverIds = List<String>.from(snap.data!.get('driverIds') ?? []);
          if (driverIds.isEmpty) return const Center(child: Text('No drivers hired yet'));

          return StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('users')
                .where(FieldPath.documentId, whereIn: driverIds)
                .snapshots(),
            builder: (ctx, usersSnap) {
              if (!usersSnap.hasData) return const Center(child: CircularProgressIndicator());
              final docs = usersSnap.data!.docs;
              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: docs.length,
                itemBuilder: (_, i) {
                  final data = docs[i].data()! as Map<String, dynamic>;
                  final name = data['displayName'] ?? 'No name';
                  final email = data['email'] ?? 'No email';
                  return Card(
                    margin: const EdgeInsets.symmetric(vertical: 6),
                    child: ListTile(
                      title: Text(name),
                      subtitle: Text(email),
                      trailing: FutureBuilder<double>(
                        future: _companyService.getAverageRating(docs[i].id),
                        builder: (_, rSnap) {
                          final r = rSnap.data ?? 0.0;
                          return Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.star, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text(r.toStringAsFixed(1)),
                            ],
                          );
                        },
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
