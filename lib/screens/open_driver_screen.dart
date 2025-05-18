// lib/screens/open_drivers_tab.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/company_service.dart';
import '../services/request_service.dart';
import 'analytics_screen.dart';

class OpenDriversTab extends StatelessWidget {
  final String companyId;
  const OpenDriversTab({Key? key, required this.companyId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final companySvc = CompanyService();
    final reqSvc     = RequestService();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('role',       isEqualTo: 'driver')
          .where('openToWork', isEqualTo: true)
          .where('company',    isNull: true)
          .snapshots(),
      builder: (ctx, snap) {
        if (snap.hasError) return const Center(child: Text('Error loading drivers'));
        if (!snap.hasData)  return const Center(child: CircularProgressIndicator());

        final docs = snap.data!.docs;
        if (docs.isEmpty) return const Center(child: Text('No drivers available'));

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          itemCount: docs.length,
          itemBuilder: (ctx, i) {
            final d    = docs[i];
            final data = d.data() as Map<String, dynamic>;
            final id   = d.id;
            final name = data['displayName'] as String? ?? 'Unnamed';
            final mail = data['email']       as String? ?? '';

            return Card(
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              elevation: 3,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
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
                    // name + email + rating + button
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(mail, style: const TextStyle(color: Colors.grey)),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              FutureBuilder<double>(
                                future: companySvc.getAverageRating(id),
                                builder: (c, ratingSnap) {
                                  final r = ratingSnap.data ?? 0.0;
                                  return Chip(
                                    avatar: const Icon(Icons.star, color: Colors.amber, size: 20),
                                    label: Text(r.toStringAsFixed(1)),
                                    backgroundColor: Colors.amber.withOpacity(0.15),
                                    padding: const EdgeInsets.symmetric(horizontal: 8),
                                  );
                                },
                              ),
                              const Spacer(),
                              SizedBox(
                                height: 36,
                                child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.green,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    padding: const EdgeInsets.symmetric(horizontal: 16),
                                  ),
                                  onPressed: () async {
                                    final already = await reqSvc.sendHireRequest(companyId, id);
                                    final msg = already
                                        ? 'Already requested $name'
                                        : 'Hire request sent to $name';
                                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                        margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                        backgroundColor: already ? Colors.red.shade600 : Colors.green.shade600,
                                        content: Text(msg, style: const TextStyle(color: Colors.white)),
                                      ),
                                    );
                                  },
                                  child: const Text('Hire', style: TextStyle(color: Colors.white)),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
