// lib/screens/company_requests_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/company_service.dart';
import '../services/request_service.dart';
import 'company_driver_detail_screen.dart';

class CompanyRequestsPage extends StatelessWidget {
  final String companyId;
  const CompanyRequestsPage({Key? key, required this.companyId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      // ── AppBar ───────────────────────────────────────────
      appBar: AppBar(
        title: const Text(
          'Join Requests',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('type', isEqualTo: 'join_company')
            .where('toId', isEqualTo: companyId)
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError) return Center(child: Text('Error: ${snap.error}'));
          if (!snap.hasData)  return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No join requests'));

          return ListView.separated(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            itemCount: docs.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (ctx, idx) {
              final reqDoc = docs[idx];
              final data   = reqDoc.data()! as Map<String, dynamic>;
              final driverId  = data['fromId'] as String;
              final timestamp = (data['timestamp'] as Timestamp).toDate();

              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(driverId).get(),
                builder: (ctx, userSnap) {
                  if (!userSnap.hasData) {
                    return const SizedBox(
                      height: 100,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }
                  final udata = userSnap.data!.data() as Map<String, dynamic>? ?? {};
                  final name  = udata['displayName'] as String? ?? 'Driver';
                  final email = udata['email']       as String? ?? '';

                  return InkWell(
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => DriverDetailPage(driverId: driverId),
                        ),
                      );
                    },
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // ── header row: avatar + name/email ───────────
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blueAccent,
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
                                      const SizedBox(height: 4),
                                      Text(
                                        email,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Text(
                                  DateFormat.yMMMd().format(timestamp),
                                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                                ),
                              ],
                            ),

                            const SizedBox(height: 12),

                            // ── Accept / Reject buttons ───────────────────
                            Row(
                              mainAxisAlignment: MainAxisAlignment.end,
                              children: [
                                TextButton.icon(
                                  icon: const Icon(Icons.check, color: Colors.green),
                                  label: const Text('Accept', style: TextStyle(color: Colors.green)),
                                  onPressed: () async {
                                    await RequestService().respondToRequest(reqDoc.id, true);
                                    await CompanyService().addDriverToCompany(
                                      companyId: companyId,
                                      driverId: driverId,
                                    );
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Request accepted — driver added')),
                                    );
                                  },
                                ),
                                const SizedBox(width: 8),
                                TextButton.icon(
                                  icon: const Icon(Icons.close, color: Colors.redAccent),
                                  label: const Text('Reject', style: TextStyle(color: Colors.redAccent)),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (c) => AlertDialog(
                                        title: const Text('Confirm Rejection'),
                                        content: const Text('Reject this driver’s request?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('No')),
                                          TextButton(onPressed: () => Navigator.pop(c, true),  child: const Text('Yes')),
                                        ],
                                      ),
                                    );
                                    if (confirm == true) {
                                      await RequestService().respondToRequest(reqDoc.id, false);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Request rejected')),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
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
