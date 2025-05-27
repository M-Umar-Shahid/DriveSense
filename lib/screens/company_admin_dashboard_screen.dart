// lib/screens/company_admin_dashboard.dart

import 'package:drivesense/components/dashboard_screen_components/rounded_button.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../services/company_service.dart';
import 'add_driver_screen.dart';
import 'analytics_screen.dart';
import 'assigned_driver_page.dart';
import 'company_requests_page.dart';
import 'driver_chat_list_screen.dart';
import 'login_signup_screen.dart';
import 'open_driver_screen.dart';

class CompanyAdminDashboard extends StatefulWidget {
  const CompanyAdminDashboard({Key? key}) : super(key: key);

  @override
  State<CompanyAdminDashboard> createState() => _CompanyAdminDashboardState();
}

class _CompanyAdminDashboardState extends State<CompanyAdminDashboard> {
  final String companyId = FirebaseAuth.instance.currentUser!.uid;
  late final DocumentReference _companyRef;
  final CompanyService _svc = CompanyService();

  String _search = '';
  final _searchCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _companyRef = FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId);
  }

  Future<void> _logout() async {
    await FirebaseAuth.instance.signOut();
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginSignupPage()),
          (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _companyRef.snapshots(),
      builder: (ctx, snap) {
        if (snap.hasError) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: Text("Couldn't load company")),
          );
        }
        if (!snap.hasData) {
          return const Scaffold(
            backgroundColor: Colors.white,
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snap.data!.data() as Map<String, dynamic>;
        final name = data['companyName'] as String? ?? 'Company Admin';
        final drivers = List<String>.from(data['driverIds'] ?? []);
        final totalDrivers = drivers.length;

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
                borderRadius:
                BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.message, color: Colors.white),
                    tooltip: "Chat with Drivers",
                    onPressed: () async {
                      final uid = FirebaseAuth.instance.currentUser!.uid;

                      final userSnap = await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .get();

                      final userData = userSnap.data();
                      final companyId = userData?['company'] ?? uid; // fallback to uid if missing

                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => DriverListScreen(companyId: companyId),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: const Icon(Icons.mail,
                        color: Colors.white), onPressed: () {Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => CompanyRequestsPage(companyId: companyId)));
                  },

                  ),
                  IconButton(
                    icon: const Icon(Icons.exit_to_app,
                        color: Colors.white),
                    onPressed: () => showDialog(
                      context: context,
                      builder: (d) => AlertDialog(
                        title: const Text('Log out?'),
                        content: const Text(
                            'Are you sure you want to log out?'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(d),
                              child: const Text('Cancel')),
                          TextButton(
                              onPressed: () {
                                Navigator.pop(d);
                                _logout();
                              },
                              child: const Text('Log out')),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ─── BODY ────────────────────────────────────────
          body: Column(
            children: [
              // Overview Cards
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    _OverviewCard(
                      icon: Icons.group,
                      label: 'Drivers',
                      value: '$totalDrivers',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => AssignedDriversPage(companyId: companyId)),
                      ),
                    ),
                    const SizedBox(width: 12),
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

              // Search & Hire
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 48,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                        ),
                        child: TextField(
                          controller: _searchCtrl,
                          decoration: const InputDecoration(
                            hintText: 'Search drivers…',
                            border: InputBorder.none,
                            prefixIcon: Icon(Icons.search),
                          ),
                          onChanged: (t) => setState(() => _search = t.toLowerCase()),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Drivers List (wrapped in Expanded!)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where(FieldPath.documentId, whereIn: drivers.isEmpty ? [''] : drivers)
                        .snapshots(),
                    builder: (c, us) {
                      if (us.hasError) return const Center(child: Text('Error'));
                      if (!us.hasData) return const Center(child: CircularProgressIndicator());
                      final docs = us.data!.docs.where((d) {
                        final m = d.data() as Map<String, dynamic>;
                        final name = (m['displayName'] ?? '').toString().toLowerCase();
                        final email = (m['email'] ?? '').toString().toLowerCase();
                        return name.contains(_search) || email.contains(_search);
                      }).toList();
                      if (docs.isEmpty) return const Center(child: Text('No drivers found'));

                      return ListView.separated(
                        itemCount: docs.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (_, i) {
                          final m  = docs[i].data() as Map<String, dynamic>;
                          final id = docs[i].id;
                          return Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(12),
                              boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
                            ),
                            child: ListTile(
                              title: Text(m['displayName'] ?? 'No name'),
                              subtitle: Text(m['email'] ?? ''),
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => AnalyticsPage(driverId: id)),
                              ),
                              trailing: FutureBuilder<double>(
                                future: _svc.getAverageRating(id),
                                builder: (c, r) {
                                  final rr = r.data?.toStringAsFixed(1) ?? '0.0';
                                  return ConstrainedBox(
                                    // give the trailing a max width
                                    constraints: const BoxConstraints(maxWidth: 60),
                                    child: Container(
                                      alignment: Alignment.center, // center the contents
                                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          const Icon(Icons.star, color: Colors.amber, size: 16),
                                          const SizedBox(width: 2),
                                          Text(rr, style: const TextStyle(fontSize: 14)),
                                        ],
                                      ),
                                    ),
                                  );
                                },
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
      },
    );
  }
}

/// A reusable overview card widget
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
                Text(value,
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
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
