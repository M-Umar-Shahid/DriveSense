// lib/screens/company_admin_dashboard.dart

import 'package:drivesense/screens/company_driver_detail_screen.dart';
import 'package:drivesense/screens/company_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/company_service.dart';
import 'analytics_screen.dart';         // exports AnalyticsPage
import 'company_requests_page.dart';
import 'driver_chat_list_screen.dart';
import 'login_signup_screen.dart';
import 'assigned_driver_page.dart';     // optional
import 'add_driver_screen.dart';        // optional

class CompanyAdminDashboard extends StatefulWidget {
  const CompanyAdminDashboard({Key? key}) : super(key: key);

  @override
  State<CompanyAdminDashboard> createState() => _CompanyAdminDashboardState();
}

class _CompanyAdminDashboardState extends State<CompanyAdminDashboard> {
  final String companyId = FirebaseAuth.instance.currentUser!.uid;
  final CompanyService _svc = CompanyService();

  String _search = '';
  final _searchCtrl = TextEditingController();

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginSignupPage()),
          (_) => false,
    );
  }

  Future<void> _confirmFire(String driverId, String driverName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Fire Employee?'),
        content: Text('Are you sure you want to remove $driverName?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true),  child: const Text('Fire')),
        ],
      ),
    );
    if (confirm != true) return;

    try {
      final adminId = FirebaseAuth.instance.currentUser!.uid;
      await _svc.fireEmployee(companyId, adminId, driverId);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$driverName has been removed')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error removing employee: $e')),
      );
    }
  }

  /// Streams *all* users who ever worked for this company.
  Stream<QuerySnapshot> get _companyUsers => FirebaseFirestore.instance
      .collection('users')
      .where('role',       isEqualTo: 'driver')            // ← only drivers
      .where('companyHistory', arrayContains: companyId)
      .snapshots();


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,

      // ─── HEADER ───────────────────────────────────────
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 100,
        flexibleSpace: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF4285F4), Color(0xFF1976D2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
          child: Row(
            children: [
              // Company name
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('companies')
                    .doc(companyId)
                    .snapshots(),
                builder: (ctx, snap) {
                  final title = snap.hasData
                      ? snap.data!.get('companyName') as String
                      : 'Loading…';
                  return Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  );
                },
              ),

              const Spacer(),

              // Chat with drivers
              IconButton(
                icon: const Icon(Icons.message, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => DriverListScreen(companyId: companyId),
                  ),
                ),
              ),

              // Hire requests
              IconButton(
                icon: const Icon(Icons.mail, color: Colors.white),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CompanyRequestsPage(companyId: companyId),
                  ),
                ),
              ),

              // Logout
              IconButton(
                icon: const Icon(Icons.account_circle, color: Colors.white),
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => CompanyAdminProfilePage(companyId: companyId)),
                  );
                },
              ),

            ],
          ),
        ),
      ),

      // ─── BODY ────────────────────────────────────────
      body: Column(
        children: [
          // Overview cards: driver count + rating
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Driver count
                StreamBuilder<QuerySnapshot>(
                  stream: _companyUsers,
                  builder: (ctx, snap) {
                    final all = snap.data?.docs ?? [];
                    final activeCount = all.where((doc) {
                      final m       = doc.data() as Map<String, dynamic>;
                      final assigns = (m['assignments'] as List<dynamic>?)
                          ?.cast<Map<String, dynamic>>() ?? [];
                      return assigns.any((a) =>
                      a['companyId'] == companyId && a['status'] == 'active'
                      );
                    }).length;
                    return _OverviewCard(
                      icon: Icons.group,
                      label: 'Drivers',
                      value: '$activeCount',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AssignedDriversPage(companyId: companyId),
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(width: 12),

                // Company rating
                FutureBuilder<double>(
                  future: _svc.getAverageCompanyRating(companyId),
                  builder: (c, rs) {
                    final avg = rs.data?.toStringAsFixed(1) ?? '0.0';
                    return _OverviewCard(
                      icon: Icons.star,
                      label: 'Rating',
                      value: avg,
                      onTap: () {},
                    );
                  },
                ),
              ],
            ),
          ),

          // Search bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search drivers…',
                prefixIcon: const Icon(Icons.search),
                filled: true,
                fillColor: Colors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (t) => setState(() => _search = t.toLowerCase()),
            ),
          ),

          // Drivers list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: StreamBuilder<QuerySnapshot>(
                stream: _companyUsers,
                builder: (ctx, snap) {
                  if (snap.hasError) return const Center(child: Text('Error loading drivers'));
                  if (!snap.hasData) return const Center(child: CircularProgressIndicator());

                  // Filter for active + search
                  final docs = snap.data!.docs.where((doc) {
                    final m       = doc.data() as Map<String, dynamic>;
                    final assigns = (m['assignments'] as List<dynamic>?)
                        ?.cast<Map<String, dynamic>>() ?? [];
                    final isActive = assigns.any((a) =>
                    a['companyId'] == companyId && a['status'] == 'active'
                    );
                    if (!isActive) return false;

                    final name  = (m['displayName'] ?? '').toString().toLowerCase();
                    final email = (m['email']       ?? '').toString().toLowerCase();
                    return name.contains(_search) || email.contains(_search);
                  }).toList();

                  if (docs.isEmpty) return const Center(child: Text('No drivers found'));

                  return ListView.separated(
                    itemCount: docs.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (_, i) {
                      final m    = docs[i].data() as Map<String, dynamic>;
                      final id   = docs[i].id;
                      final name = m['displayName'] as String? ?? 'No name';

                      return Card(
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 2,
                        child: ListTile(
                          title: Text(name),
                          subtitle: Text(m['email'] ?? ''),
                          trailing: IconButton(
                            icon: const Icon(Icons.remove_circle, color: Colors.red),
                            onPressed: () => _confirmFire(id, name),
                          ),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => DriverDetailPage(driverId: id)),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Small reusable card for the overview row
class _OverviewCard extends StatelessWidget {
  final IconData icon;
  final String label, value;
  final VoidCallback onTap;

  const _OverviewCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        elevation: 4,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
            child: Column(
              children: [
                Icon(icon, size: 28, color: Colors.blueAccent),
                const SizedBox(height: 8),
                Text(value, style: const TextStyle(
                    fontSize: 20, fontWeight: FontWeight.bold
                )),
                const SizedBox(height: 4),
                Text(label, style: const TextStyle(color: Colors.grey)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
