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
      backgroundColor: Colors.grey[100],
      // — Gradient AppBar with back button & icon —
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(200),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
          ),
          child: SafeArea(
            child: Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white, size: 28),
                  onPressed: () => Navigator.pop(context),
                ),
                const Expanded(
                  child: Text(
                    'Available Drivers',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.only(right: 16),
                  child: Icon(Icons.directions_car, color: Colors.white, size: 28),
                ),
              ],
            ),
          ),
        ),
      ),

      // — Body with driver list —
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'driver')
            .where('openToWork', isEqualTo: true)
            .where('company', isNull: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError) return const Center(child: Text('Error loading drivers'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snap.data!.docs;
          if (docs.isEmpty) return const Center(child: Text('No drivers available'));

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: docs.length,
            itemBuilder: (_, i) {
              final data = docs[i].data()! as Map<String, dynamic>;
              final id    = docs[i].id;
              final name  = data['displayName'] ?? 'Unnamed';
              final email = data['email'] ?? '';

              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => AnalyticsPage(driverId: id)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // 1) Avatar
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

                          // 2) Details: name, email, rating + hire button
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Name
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                // Email (single line, ellipsis)
                                Text(
                                  email,
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 12),

                                // Rating + Hire button row
                                Row(
                                  children: [
                                    // Rating chip
                                    FutureBuilder<double>(
                                      future: _companyService.getAverageRating(id),
                                      builder: (ctx, ratingSnap) {
                                        final rating = ratingSnap.data ?? 0.0;
                                        return Chip(
                                          avatar: const Icon(Icons.star, color: Colors.amber, size: 20),
                                          label: Text(
                                            rating.toStringAsFixed(1),
                                            style: const TextStyle(fontWeight: FontWeight.bold),
                                          ),
                                          backgroundColor: Colors.amber.withOpacity(0.15),
                                          padding: const EdgeInsets.symmetric(horizontal: 8),
                                        );
                                      },
                                    ),
                                    const SizedBox(width: 16),

                                    // Hire button (fills remaining space)
                                    Expanded(
                                      child: SizedBox(
                                        height: 36,
                                        child: ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                            backgroundColor: Colors.green,
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(8),
                                            ),
                                          ),
                                          onPressed: () async {
                                            await _companyService.hireDriver(widget.companyId, id);
                                            if (mounted) {
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(content: Text('Hired $name')),
                                              );
                                            }
                                          },
                                          child: const Text('Hire', style: TextStyle(color: Colors.white)),
                                        ),
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
