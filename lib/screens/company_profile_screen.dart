// lib/screens/company_admin_profile_page.dart

import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:drivesense/screens/login_signup_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
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

  // for picking & uploading logo
  final ImagePicker _picker = ImagePicker();

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
      await FirebaseMessaging.instance.deleteToken();
      final uid = FirebaseAuth.instance.currentUser!.uid;
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .update({ 'fcmToken': FieldValue.delete() });
      await FirebaseAuth.instance.signOut();
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const LoginSignupPage()),
      );
    }
  }

  Future<void> _changeLogo() async {
    final picked = await _picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked == null) return;

    final ref = FirebaseStorage.instance
        .ref('company_logos/${widget.companyId}.jpg');

    await ref.putFile(File(picked.path));
    final url = await ref.getDownloadURL();

    await FirebaseFirestore.instance
        .collection('companies')
        .doc(widget.companyId)
        .update({'photoURL': url});
    // StreamBuilder will rebuild automatically
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
          // use new photoURL first, fall back on old logoUrl
          final String? photoURL  = data['photoURL']     as String?;
          final String? logoUrl   = data['logoUrl']      as String?;
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
                child: Padding(
                  padding: const EdgeInsets.only(top: 64), // extra top padding
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
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: _changeLogo,
                            child: Stack(
                              alignment: Alignment.bottomRight,
                              children: [
                                Container(
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
                                      backgroundImage: (photoURL != null)
                                          ? NetworkImage(photoURL)
                                          : (logoUrl != null)
                                          ? NetworkImage(logoUrl)
                                          : null,
                                      child: (photoURL==null && logoUrl==null)
                                          ? const Icon(Icons.business, size: 48, color: Colors.grey)
                                          : null,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    shape: BoxShape.circle,
                                    boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
                                  ),
                                  child: const Icon(Icons.edit, size: 20, color: Colors.blueAccent),
                                ),
                              ],
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
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.email_outlined, size: 16, color: Colors.grey),
                                const SizedBox(width: 8),
                                Text(email, style: const TextStyle(color: Colors.grey, fontSize: 14)),
                              ],
                            ),
                          ),
                        ],
                      ),
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
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
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
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ─── Logout Button ────────────────────────────
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: _showLogoutDialog,
                      icon: const Icon(Icons.logout, size: 20),
                      label: const Text(
                        'Log Out',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,      // ← here
                        foregroundColor: Colors.white,
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
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
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue.withOpacity(0.1), Colors.blue.withOpacity(0.2)],
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
                Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(value, style: const TextStyle(fontSize: 14, color: Colors.grey)),
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
        label: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? Colors.redAccent : Colors.white,
          foregroundColor: isPrimary ? Colors.white : Colors.grey[800],
          elevation: isPrimary ? 4 : 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
