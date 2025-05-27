import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'chat_screen.dart';

class DriverListScreen extends StatelessWidget {
  final String companyId;

  const DriverListScreen({super.key, required this.companyId});

  @override
  Widget build(BuildContext context) {
    final currentUser = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Chat with Drivers"),
        backgroundColor: Colors.blueAccent,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('company', isEqualTo: companyId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final users = snapshot.data!.docs
              .where((doc) => doc.id != currentUser!.uid)
              .toList();

          if (users.isEmpty) {
            return const Center(
              child: Text("No drivers found.", style: TextStyle(fontSize: 16, color: Colors.grey)),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: users.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final user = users[index];
              final driverName = user['displayName'] ?? 'Unnamed Driver';
              final driverEmail = user['email'] ?? '';
              final driverId = user.id;

              return Material(
                color: Colors.white,
                elevation: 2,
                borderRadius: BorderRadius.circular(12),
                child: ListTile(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withOpacity(0.2),
                    child: const Icon(Icons.person_outline, color: Colors.blueAccent),
                  ),
                  title: Text(driverName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(driverEmail),
                  trailing: const Icon(Icons.chat_bubble_outline, color: Colors.blueAccent),
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
      backgroundColor: Colors.grey[100],
    );
  }
}