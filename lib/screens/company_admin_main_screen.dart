// lib/screens/company_admin_main_screen.dart

import 'package:drivesense/screens/company_profile_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'company_admin_dashboard_screen.dart';
import 'add_driver_screen.dart';
import 'open_driver_screen.dart';

class CompanyAdminMainScreen extends StatefulWidget {
  const CompanyAdminMainScreen({Key? key}) : super(key: key);

  @override
  State<CompanyAdminMainScreen> createState() => _CompanyAdminMainScreenState();
}

class _CompanyAdminMainScreenState extends State<CompanyAdminMainScreen> {
  int _currentIndex = 0;
  late final String _companyId;

  @override
  void initState() {
    super.initState();
    _companyId = FirebaseAuth.instance.currentUser!.uid;
  }

  @override
  Widget build(BuildContext context) {
    final pages = [
      CompanyAdminDashboard(),                    // index 0
      OpenDriversTab(companyId: _companyId),      // index 1
      CompanyAdminProfilePage(companyId: _companyId),                              // index 2
    ];

    return Scaffold(
      body: pages[_currentIndex],
      bottomNavigationBar: BottomAppBar(
        color: Colors.white,
        elevation: 4,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _buildTabItem(Icons.dashboard, 'Dashboard', 0),
              _buildTabItem(Icons.business,  'Hire',      1),
              _buildTabItem(Icons.person,    'Profile',   2),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(IconData icon, String label, int idx) {
    final active = _currentIndex == idx;
    final color  = active ? Colors.blueAccent : Colors.grey[600];
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _currentIndex = idx),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(color: color, fontSize: 10)),
          ],
        ),
      ),
    );
  }
}
