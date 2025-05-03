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
    _companyRef =
        FirebaseFirestore.instance.collection('companies').doc(companyId);
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
    Navigator.of(context)
        .pushNamedAndRemoveUntil('/login', (_) => false); // adjust route
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Company Admin'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddDriverPage(companyId: companyId),
                ),
              );
            },
          ),

          TextButton.icon(
            icon: const Icon(Icons.group_add),
            label: const Text('View Join Requests'),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => CompanyRequestsPage(companyId: companyId),
                ),
              );
            },
          ),


          // ← replace your existing logout button with this:
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Confirm Logout'),
                  content: const Text('Are you sure you want to log out?'),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pushReplacement(context,
                  MaterialPageRoute(builder: (_) => const LoginSignupPage())),
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
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // — Search Bar —
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search drivers…',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onChanged: (val) => setState(() => _search = val.toLowerCase()),
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
            child: ElevatedButton.icon(
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Hire Drivers'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OpenDriversPage(companyId: companyId),
                  ),
                );
              },
            ),
          ),


          // — Driver List —
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

                    // filter by search
                    final docs = usersSnap.data!.docs.where((d) {
                      final data = d.data()! as Map<String, dynamic>;
                      final name = (data['displayName'] ?? '').toString().toLowerCase();
                      final email = (data['email'] ?? '').toString().toLowerCase();
                      return name.contains(_search) || email.contains(_search);
                    }).toList();

                    if (docs.isEmpty) return const Center(child: Text('No matching drivers'));

                    return ListView.builder(
                      itemCount: docs.length,
                      itemBuilder: (_, i) {
                        final d = docs[i].data()! as Map<String, dynamic>;
                        final id = docs[i].id;
                        final name = d['displayName'] ?? 'No name';
                        final email = d['email'] ?? 'No email';

                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: ListTile(
                            title: Text(name),
                            subtitle: Text(email),
                            // make the entire tile tappable:
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AnalyticsPage(driverId: id),
                                ),
                              );
                            },
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                FutureBuilder<double>(
                                  future: _companyService.getAverageRating(id),
                                  builder: (ctx, ratingSnap) {
                                    final rating = ratingSnap.data ?? 0.0;
                                    return Row(
                                      children: [
                                        const Icon(Icons.star, size: 16, color: Colors.amber),
                                        Text(rating.toStringAsFixed(1)),
                                      ],
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
