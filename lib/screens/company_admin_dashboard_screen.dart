import 'package:drivesense/screens/login_signup_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/company_service.dart';
import 'add_driver_screen.dart';
import 'analytics_screen.dart';
import 'company_requests_page.dart';
import 'open_driver_screen.dart';

class CompanyAdminDashboard extends StatefulWidget {
  const CompanyAdminDashboard({Key? key}) : super(key: key);

  @override
  State<CompanyAdminDashboard> createState() => _CompanyAdminDashboardState();
}

class _CompanyAdminDashboardState extends State<CompanyAdminDashboard> {
  final _searchCtrl = TextEditingController();
  String _search = '';
  final String companyId = FirebaseAuth.instance.currentUser!.uid;
  late final DocumentReference _companyRef;
  final CompanyService _companyService = CompanyService();

  @override
  void initState() {
    super.initState();
    _companyRef = FirebaseFirestore.instance.collection('companies').doc(companyId);
  }

  Future<void> _removeDriver(String driverId) async {
    await _companyRef.update({
      'driverIds': FieldValue.arrayRemove([driverId]),
    });
    await FirebaseFirestore.instance
        .collection('users')
        .doc(driverId)
        .update({'company': null});
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Driver removed from your company')),
    );
  }

  void _logout() async {
    await FirebaseAuth.instance.signOut();

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginSignupPage()),
          (route) => false,
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: Column(
        children: [
          // Gradient Header
          Container(
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF4285F4), Color(0xFF1976D2)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(32),
                bottomRight: Radius.circular(32),
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Title
                    const Text(
                      'Company Admin',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.person_add, color: Colors.white),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => AddDriverPage(companyId: companyId),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.mail, color: Colors.white),
                          onPressed: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => CompanyRequestsPage(companyId: companyId),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.logout, color: Colors.white),
                          onPressed: () => showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Confirm Logout'),
                              content: const Text('Are you sure you want to log out?'),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.of(ctx).pop();
                                    _logout();
                                  },
                                  child: const Text('Logout'),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Search & Actions
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search drivers...',
                      prefixIcon: const Icon(Icons.search),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (val) => setState(() => _search = val.toLowerCase()),
                  ),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  icon: const Icon(Icons.person_add_alt_1),
                  label: const Text('Hire Drivers'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white, backgroundColor: const Color(0xFF1976D2),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => OpenDriversPage(companyId: companyId),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Driver List
          Expanded(
            child: StreamBuilder<DocumentSnapshot>(
              stream: _companyRef.snapshots(),
              builder: (ctx, snap) {
                if (snap.hasError) return const Center(child: Text('Error'));
                if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                final driverIds = List<String>.from(snap.data!.get('driverIds') ?? []);
                if (driverIds.isEmpty) return const Center(child: Text('No drivers assigned'));

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .where(FieldPath.documentId, whereIn: driverIds)
                      .snapshots(),
                  builder: (ctx, usersSnap) {
                    if (usersSnap.hasError) return const Center(child: Text('Error loading drivers'));
                    if (!usersSnap.hasData) return const Center(child: CircularProgressIndicator());

                    final docs = usersSnap.data!.docs.where((d) {
                      final data = d.data()! as Map<String, dynamic>;
                      final name = (data['displayName'] ?? '').toString().toLowerCase();
                      final email = (data['email'] ?? '').toString().toLowerCase();
                      return name.contains(_search) || email.contains(_search);
                    }).toList();

                    if (docs.isEmpty) return const Center(child: Text('No matching drivers'));

                    return ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final d = docs[i].data()! as Map<String, dynamic>;
                        final id = docs[i].id;
                        final name = d['displayName'] ?? 'No name';
                        final email = d['email'] ?? 'No email';

                        return Card(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          elevation: 2,
                          margin: const EdgeInsets.symmetric(vertical: 6),
                          child: ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            title: Text(name, style: const TextStyle(fontWeight: FontWeight.w600)),
                            subtitle: Text(email),
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => AnalyticsPage(driverId: id)),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FutureBuilder<double>(
                                  future: _companyService.getAverageRating(id),
                                  builder: (ctx, ratingSnap) {
                                    final rating = ratingSnap.data ?? 0.0;
                                    return Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        children: [
                                          const Icon(Icons.star, size: 16, color: Colors.amber),
                                          const SizedBox(width: 4),
                                          Text(rating.toStringAsFixed(1)),
                                        ],
                                      ),
                                    );
                                  },
                                ),
                                const SizedBox(width: 12),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.redAccent),
                                  onPressed: () => _removeDriver(id),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
