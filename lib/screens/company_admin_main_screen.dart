// lib/screens/company_admin_main_screen.dart

import 'package:drivesense/screens/open_driver_screen.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'company_admin_dashboard_screen.dart';
import 'add_driver_screen.dart';

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
    // these are now “bare” widgets, not full Scaffolds
    final pages = [
      CompanyAdminDashboard(),
      OpenDriversTab(companyId: _companyId),
    ];

    return Scaffold(

      appBar: _currentIndex == 1
          ? AppBar(
        title: const Text('Available Drivers'),
        backgroundColor: const Color(0xFF1976D2),
        elevation: 0,
      )
          : null,

      body: pages[_currentIndex],

      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF1976D2),
        child: const Icon(Icons.person_add, color: Colors.white),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddDriverPage(companyId: _companyId),
            ),
          );
        },
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

      bottomNavigationBar: BottomAppBar(
        shape: const CircularNotchedRectangle(),
        color: Colors.white,
        notchMargin: 6,
        child: SizedBox(
          height: 60,
          child: Row(
            children: [
              _buildTabItem(Icons.dashboard, 'Dashboard', 0),
              const Spacer(),
              _buildTabItem(Icons.business, 'Hire', 1),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabItem(IconData icon, String label, int idx) {
    final active = _currentIndex == idx;
    final color = active ? Colors.blueAccent : Colors.grey[600];
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
