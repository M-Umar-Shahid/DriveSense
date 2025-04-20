import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ImageAlertsPage extends StatefulWidget {
  const ImageAlertsPage({super.key});

  @override
  State<ImageAlertsPage> createState() => _ImageAlertsPageState();
}

class _ImageAlertsPageState extends State<ImageAlertsPage> {
  String selectedFilter = 'All';
  final user = FirebaseAuth.instance.currentUser;

  void _showFilterDialog() {
    showDialog(
      context: context,
      builder: (context) => SimpleDialog(
        title: const Text('Filter Alerts'),
        children: ['All', 'Drowsy', 'Yawning', 'Distraction']
            .map((type) => RadioListTile<String>(
          value: type,
          groupValue: selectedFilter,
          title: Text(type),
          onChanged: (value) {
            setState(() => selectedFilter = value!);
            Navigator.pop(context);
          },
        ))
            .toList(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text(
          "Image Alerts",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        elevation: 0.5,
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_alt_rounded, color: Colors.blueAccent),
            onPressed: _showFilterDialog,
          ),
        ],
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? const Center(child: Text("User not logged in"))
          : StreamBuilder<QuerySnapshot>(
        stream: selectedFilter == 'All'
            ? FirebaseFirestore.instance
            .collection('detections')
            .where('uid', isEqualTo: user!.uid)
            .orderBy('timestamp', descending: true)
            .snapshots()
            : FirebaseFirestore.instance
            .collection('detections')
            .where('uid', isEqualTo: user!.uid)
            .where('alertCategory', isEqualTo: selectedFilter)
            .orderBy('timestamp', descending: true)
            .snapshots(),

        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No alerts found"));
          }


          final docs = snapshot.data!.docs;


          return Padding(
            padding: const EdgeInsets.all(12),
            child: GridView.builder(
              itemCount: docs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 3 / 4,
              ),
              itemBuilder: (context, index) {
                final doc = docs[index];
                final imageUrl = doc['imageUrl'] ?? '';
                final alertType = doc['alertType'] ?? 'Unknown';
                final timestamp = (doc['timestamp'] as Timestamp).toDate();

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FullScreenImageView(imageUrl: imageUrl),
                      ),
                    );
                  },
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 4,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                            child: Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(Icons.broken_image),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                alertType,
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "${timestamp.toLocal()}".split('.')[0],
                                style: const TextStyle(fontSize: 11, color: Colors.grey),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class FullScreenImageView extends StatelessWidget {
  final String imageUrl;
  const FullScreenImageView({super.key, required this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(backgroundColor: Colors.black),
      body: Center(
        child: Hero(
          tag: imageUrl,
          child: InteractiveViewer(
            child: Image.network(imageUrl),
          ),
        ),
      ),
    );
  }
}
