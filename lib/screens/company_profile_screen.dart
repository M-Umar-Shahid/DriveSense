import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivesense/screens/login_signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class CompanyAdminProfilePage extends StatefulWidget {
  final String companyId;
  const CompanyAdminProfilePage({super.key, required this.companyId});

  @override
  State<CompanyAdminProfilePage> createState() =>
      _CompanyAdminProfilePageState();
}

class _CompanyAdminProfilePageState extends State<CompanyAdminProfilePage>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _headerAnim;
  late Animation<double> _menuAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _headerAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    );
    _menuAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: const Interval(0.3, 1.0, curve: Curves.easeOut),
    );
    _animCtrl.forward();

    // Light status icons on white
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarIconBrightness: Brightness.dark,
      statusBarColor: Colors.transparent,
    ));
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _showLogoutDialog() async {
    final doIt = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirm Logout'),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (doIt == true) {
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginSignupPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('companies')
            .doc(widget.companyId)
            .snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final data = snap.data!.data()! as Map<String, dynamic>;

          final String name       = data['companyName']  as String? ?? '—';
          final String email      = data['email']        as String? ?? '—';
          final String? logoUrl   = data['logoUrl']      as String?;
          final String desc       = data['description']  as String? ?? 'No description.';
          final List drivers      = data['driverIds']    as List<dynamic>? ?? [];
          final int driverCount   = drivers.length;
          final double avgRating  = (data['avgRating']  as num?)?.toDouble() ?? 0.0;
          final Timestamp createdTs = data['createdAt'] as Timestamp;
          final String createdAt  = DateFormat('yyyy-MM-dd').format(createdTs.toDate());

          return CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              // ─── Header ─────────────────────────────────
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _headerAnim,
                  builder: (context, child) => Opacity(
                    opacity: _headerAnim.value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - _headerAnim.value)),
                      child: child,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 40, 20, 20),
                    child: Column(
                      children: [
                        // Logo
                        GestureDetector(
                          // no edit here
                          child: Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: const LinearGradient(
                                colors: [Color(0xFF1976D2), Color(0xFF42A5F5)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(4),
                              child: CircleAvatar(
                                backgroundColor: Colors.white,
                                backgroundImage:
                                (logoUrl != null) ? NetworkImage(logoUrl) : null,
                                child: logoUrl == null
                                    ? const Icon(Icons.business,
                                    size: 48, color: Colors.grey)
                                    : null,
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 16),
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),

                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.email_outlined,
                                  size: 16, color: Colors.grey),
                              const SizedBox(width: 8),
                              Text(
                                email,
                                style: const TextStyle(
                                    color: Colors.grey, fontSize: 14),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Company Stats ───────────────────────────
              SliverToBoxAdapter(
                child: AnimatedBuilder(
                  animation: _menuAnim,
                  builder: (context, child) => Opacity(
                    opacity: _menuAnim.value,
                    child: Transform.translate(
                      offset: Offset(0, 30 * (1 - _menuAnim.value)),
                      child: child,
                    ),
                  ),
                  child: Padding(
                    padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                iconData: Icons.group_outlined,
                                title: 'Drivers',
                                value: '$driverCount',
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoCard(
                                iconData: Icons.star_border,
                                title: 'Avg Rating',
                                value: avgRating.toStringAsFixed(1),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              child: _buildInfoCard(
                                iconData: Icons.calendar_today_outlined,
                                title: 'Created At',
                                value: createdAt,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: _buildInfoCard(
                                iconData: Icons.description_outlined,
                                title: 'Has Description',
                                value:
                                desc.isNotEmpty ? 'Yes' : 'No',
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Description ──────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Card(
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Description',
                              style: TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(
                            desc,
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              // ─── Logout Button ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: _buildActionButton(
                    title: 'Log Out',
                    iconData: Icons.logout,
                    isPrimary: true,
                    onTap: _showLogoutDialog,
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildInfoCard({
    required IconData iconData,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.blue.withOpacity(0.1),
                  Colors.blue.withOpacity(0.2)
                ],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(iconData, color: Colors.blue, size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value,
                    style:
                    const TextStyle(fontSize: 14, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required String title,
    required IconData iconData,
    required bool isPrimary,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(iconData, size: 20),
        label: Text(title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor:
          isPrimary ? Colors.redAccent : Colors.white,
          foregroundColor:
          isPrimary ? Colors.white : Colors.grey[800],
          elevation: isPrimary ? 4 : 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}
