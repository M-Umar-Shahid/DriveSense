import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/company_service.dart';
import 'analytics_screen.dart';

class OpenDriversPage extends StatefulWidget {
  final String companyId;
  const OpenDriversPage({Key? key, required this.companyId}) : super(key: key);

  @override
  _OpenDriversPageState createState() => _OpenDriversPageState();
}
class _OpenDriversPageState extends State<OpenDriversPage> {
  final CompanyService _companyService = CompanyService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Available Drivers')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'driver')
            .where('openToWork', isEqualTo: true)
            .where('company', isNull: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError) return const Center(child: Text('Error loading'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No drivers available'));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data()! as Map<String, dynamic>;
              final id   = docs[i].id;
              final name = data['displayName'] ?? 'No name';
              final email= data['email'] ?? 'No email';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: ListTile(
                  title: Text(name),
                  subtitle: Text(email),
                  leading: FutureBuilder<double>(
                    future: _companyService.getAverageRating(id),
                    builder: (_, ratingSnap) {
                      final r = ratingSnap.data ?? 0.0;
                      return Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          Text(r.toStringAsFixed(1)),
                        ],
                      );
                    },
                  ),
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => AnalyticsPage(driverId: id),
                    ),
                  ),
                  trailing: ElevatedButton(
                    child: const Text('Hire'),
                    onPressed: () async {
                      await _companyService.hireDriver(widget.companyId, id);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Hired $name')),
                      );
                    },
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
