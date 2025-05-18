import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../services/request_service.dart';
import '../services/company_service.dart';
import 'company_detail_screen.dart';

class CompaniesListPage extends StatelessWidget {
  const CompaniesListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Companies'),
          centerTitle: true,
        ),
        body: const Center(child: Text('Please log in to view companies.')),
      );
    }

    // 1) Listen to current user's document to get `company` field
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .snapshots(),
      builder: (ctx, userSnap) {
        if (userSnap.hasError) {
          return const Scaffold(
            body: Center(child: Text('Error loading user data')),
          );
        }
        if (!userSnap.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final userData = userSnap.data!.data() as Map<String, dynamic>;
        final String? currentCompany = userData['company'] as String?;

        // 2) Now build the companies list
        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header ─────────────────────────────────────────
                Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF4285F4), Color(0xFF1976D2)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(32)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.arrow_back,
                                color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                          const Spacer(),
                        ],
                      ),
                      const SizedBox(height: 8),
                      const Icon(Icons.business, size: 40, color: Colors.white70),
                      const SizedBox(height: 8),
                      const Text(
                        'Our Partner Companies',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),

                // ─── Companies ──────────────────────────────────────
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('companies')
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return const Center(
                            child: Text('Error loading companies'));
                      }
                      if (snap.connectionState == ConnectionState.waiting) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }
                      final docs = snap.data!.docs;

                      return Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${docs.length} Companie${docs.length == 1 ? "" : "s"} Available',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.black54,
                              ),
                            ),
                            const SizedBox(height: 12),
                            Expanded(
                              child: ListView.separated(
                                physics: const BouncingScrollPhysics(),
                                itemCount: docs.length,
                                separatorBuilder: (_, __) =>
                                const SizedBox(height: 12),
                                itemBuilder: (context, index) {
                                  final doc = docs[index];
                                  final data =
                                  doc.data()! as Map<String, dynamic>;
                                  final companyId = doc.id;
                                  final name = data['companyName']
                                  as String? ??
                                      'Unnamed';
                                  final drivers = List<String>.from(
                                      data['driverIds'] ?? []);
                                  final driverCount = drivers.length;

                                  final isMember =
                                      currentCompany == companyId;
                                  final canJoin =
                                      currentCompany == null && !isMember;

                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration: Duration(
                                        milliseconds: 300 + index * 100),
                                    builder: (context, v, child) => Opacity(
                                      opacity: v,
                                      child: Transform.translate(
                                        offset: Offset(0, 30 * (1 - v)),
                                        child: child,
                                      ),
                                    ),
                                    child: Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.blue.shade50,
                                            Colors.blue.shade100
                                          ],
                                          begin: Alignment.topLeft,
                                          end: Alignment.bottomRight,
                                        ),
                                        borderRadius:
                                        BorderRadius.circular(20),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 8,
                                            offset: const Offset(0, 4),
                                          ),
                                        ],
                                      ),
                                      child: InkWell(
                                        borderRadius:
                                        BorderRadius.circular(20),
                                        onTap: () {
                                          Navigator.push(
                                            context,
                                            MaterialPageRoute(
                                              builder: (_) =>
                                                  CompanyDetailPage(
                                                      companyId:
                                                      companyId),
                                            ),
                                          );
                                        },
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              // Avatar
                                              /* … your avatar code … */

                                              const SizedBox(width: 20),

                                              // Info Column
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    // Company name
                                                    Text(
                                                      name,
                                                      style:
                                                      const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                        FontWeight
                                                            .w600,
                                                      ),
                                                    ),

                                                    const SizedBox(
                                                        height: 4),

                                                    // Driver count
                                                    Text(
                                                      '$driverCount driver${driverCount == 1 ? "" : "s"}',
                                                      style:
                                                      const TextStyle(
                                                        fontSize: 14,
                                                        color:
                                                        Colors.grey,
                                                      ),
                                                    ),

                                                    const SizedBox(
                                                        height: 8),

                                                    // Rating & Reviews
                                                    Row(
                                                      children: [
                                                        FutureBuilder<
                                                            double>(
                                                          future: CompanyService()
                                                              .getAverageCompanyRating(
                                                              companyId),
                                                          builder:
                                                              (ctx, snap) {
                                                            final avg =
                                                                snap.data ??
                                                                    0.0;
                                                            return Row(
                                                              children: [
                                                                const Icon(
                                                                    Icons
                                                                        .star,
                                                                    size: 16,
                                                                    color: Colors
                                                                        .amber),
                                                                const SizedBox(
                                                                    width:
                                                                    4),
                                                                Text(
                                                                    avg.toStringAsFixed(1)),
                                                              ],
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        FutureBuilder<
                                                            int>(
                                                          future: CompanyService()
                                                              .getCompanyRatingCount(
                                                              companyId),
                                                          builder:
                                                              (ctx, snap) {
                                                            final count =
                                                                snap.data ??
                                                                    0;
                                                            return Text(
                                                              '($count reviews)',
                                                              style:
                                                              const TextStyle(
                                                                fontSize:
                                                                12,
                                                                color: Colors
                                                                    .black54,
                                                              ),
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Join / Member button
                                              ElevatedButton(
                                                style: ElevatedButton.styleFrom(
                                                  backgroundColor:
                                                  canJoin
                                                      ? const Color(
                                                      0xFF1976D2)
                                                      : Colors.grey,
                                                  shape:
                                                  RoundedRectangleBorder(
                                                    borderRadius:
                                                    BorderRadius.circular(
                                                        16),
                                                  ),
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 20,
                                                      vertical: 12),
                                                ),
                                                onPressed: canJoin
                                                    ? () async {
                                                  await RequestService()
                                                      .sendJoinRequest(
                                                      companyId);
                                                  ScaffoldMessenger.of(context).showSnackBar(
                                                    SnackBar(
                                                      content: const Row(
                                                        children: [
                                                          Icon(Icons.check_circle, color: Colors.white),
                                                          SizedBox(width: 8),
                                                          Expanded(child: Text('Join request sent')),
                                                        ],
                                                      ),
                                                      backgroundColor: Colors.green.shade600,
                                                      behavior: SnackBarBehavior.floating,
                                                      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                                      shape: const RoundedRectangleBorder(
                                                        borderRadius: BorderRadius.all(Radius.circular(12)),
                                                      ),
                                                      duration: const Duration(seconds: 2),
                                                    ),
                                                  );
                                                }
                                                    : null,
                                                child: Text(
                                                  isMember
                                                      ? 'Member'
                                                      : 'Join',
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontSize: 14,
                                                    fontWeight:
                                                    FontWeight.w600,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
