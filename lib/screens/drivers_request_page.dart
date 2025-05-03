import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/request_service.dart';


class DriverRequestsPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    return Scaffold(
      appBar: AppBar(title: const Text('Hire Requests')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('type',   isEqualTo: 'hire_driver')
            .where('toId',   isEqualTo: uid)
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) return CircularProgressIndicator();
          final docs = snap.data!.docs;
          if (docs.isEmpty) return Center(child: Text('No requests'));
          return ListView(
            children: docs.map((doc) {
              final data     = doc.data()! as Map<String, dynamic>;
              final companyId= data['fromId'] as String;
              return FutureBuilder<DocumentSnapshot>(
                future: FirebaseFirestore.instance.collection('companies').doc(companyId).get(),
                builder: (ctx, compSnap) {
                  if (!compSnap.hasData) return ListTile(title: Text('Loading…'));
                  final comp = compSnap.data!;
                  return ListTile(
                    title: Text(comp['name'] ?? 'Company'),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextButton(
                          child: const Text('Accept'),
                          onPressed: () {
                            RequestService()
                                .respondToRequest(doc.id, true)
                                .then((_) => (context as Element).markNeedsBuild());
                          },
                        ),
                        TextButton(
                          child: const Text('Reject'),
                          onPressed: () {
                            RequestService()
                                .respondToRequest(doc.id, false)
                                .then((_) => (context as Element).markNeedsBuild());
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
