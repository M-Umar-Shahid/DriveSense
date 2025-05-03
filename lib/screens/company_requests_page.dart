import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../services/request_service.dart';

class CompanyRequestsPage extends StatelessWidget {
  final String companyId;
  const CompanyRequestsPage({required this.companyId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('type',   isEqualTo: 'join_company')
            .where('toId',   isEqualTo: companyId)
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return CircularProgressIndicator();
          final docs = snap.data!.docs;
          if (docs.isEmpty) return Center(child: Text('No requests'));
          return ListView(
            children: docs.map((doc) {
              final data = doc.data()! as Map<String, dynamic>;
              final driverId = data['fromId'] as String;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('users').doc(driverId).get(),
                builder: (ctx, userSnap) {
                  if (!userSnap.hasData) return ListTile(title: Text('Loading…'));
                  final user = userSnap.data!;
                  return ListTile(
                    title: Text(user['displayName'] ?? 'Driver'),
                    subtitle: Text(user['email'] ?? ''),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          child: const Text('Accept'),
                          onPressed: () {
                            RequestService()
                                .respondToRequest(doc.id, true)
                                .then((_) => Navigator.of(context).setState((){}));
                          },
                        ),
                        TextButton(
                          child: const Text('Reject'),
                          onPressed: () {
                            RequestService()
                                .respondToRequest(doc.id, false)
                                .then((_) => Navigator.of(context).setState((){}));
                          },
                        ),
                      ],
                    ),
                  );
                },
              );
            }).toList(),
          );
        },
      ),
    );
  }
}
