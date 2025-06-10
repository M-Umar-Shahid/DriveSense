// lib/screens/driver_list_screen.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class DriverListScreen extends StatelessWidget {
  final String companyId;
  const DriverListScreen({Key? key, required this.companyId}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Chat with Drivers"),
        backgroundColor: Colors.white,
        elevation: 1,
        foregroundColor: Colors.black87,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'driver')
            .where('companyHistory', arrayContains: companyId)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error loading drivers'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter only active assignments and exclude self
          final drivers = snapshot.data!.docs.where((doc) {
            if (doc.id == currentUser?.uid) return false;
            final data = doc.data() as Map<String, dynamic>;
            final assignments = (data['assignments'] as List<dynamic>?)
                ?.cast<Map<String, dynamic>>() ??
                [];
            return assignments.any((a) =>
            a['companyId'] == companyId && a['status'] == 'active');
          }).toList();

          if (drivers.isEmpty) {
            return const Center(
              child: Text("No drivers found.",
                  style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: drivers.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final doc = drivers[index];
              final data = doc.data() as Map<String, dynamic>;
              final driverId = doc.id;
              final name = data['displayName'] as String? ?? 'Unnamed';
              final email = data['email'] as String? ?? '';

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 2,
                child: ListTile(
                  contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withOpacity(0.1),
                    child: Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.blueAccent),
                    ),
                  ),
                  title:
                  Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(email),
                  trailing:
                  const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent),
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChatScreen(
                          companyId: companyId,
                          peerId: driverId,
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
