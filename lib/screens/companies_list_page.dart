// lib/screens/companies_list_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/company_service.dart';
import '../services/request_service.dart';
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

        final userData = userSnap.data!.data() as Map<String, dynamic>? ?? {};
        final String? currentCompany = userData['company'] as String?;

        return Scaffold(
          backgroundColor: Colors.grey[50],
          body: SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── HEADER ───────────────────────────────────────
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
                            icon:
                            const Icon(Icons.arrow_back, color: Colors.white),
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

                // ─── COMPANIES LIST ─────────────────────────────
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
                                    builder: (_, v, child) => Opacity(
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
                                        borderRadius: BorderRadius.circular(20),
                                        boxShadow: const [
                                          BoxShadow(
                                            color: Colors.black12,
                                            blurRadius: 8,
                                            offset: Offset(0, 4),
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
                                              // ── AVATAR ─────────────
                                              CircleAvatar(
                                                radius: 28,
                                                backgroundColor: Colors
                                                    .blueAccent
                                                    .withOpacity(0.1),
                                                child: Text(
                                                  name.isNotEmpty
                                                      ? name[0]
                                                      .toUpperCase()
                                                      : '?',
                                                  style:
                                                  const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight:
                                                    FontWeight.bold,
                                                    color:
                                                    Colors.blueAccent,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 20),

                                              // ── INFO ────────────────
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment
                                                      .start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style:
                                                      const TextStyle(
                                                          fontSize: 18,
                                                          fontWeight:
                                                          FontWeight
                                                              .w600),
                                                    ),
                                                    const SizedBox(
                                                        height: 4),
                                                    Text(
                                                      '$driverCount driver${driverCount == 1 ? "" : "s"}',
                                                      style:
                                                      const TextStyle(
                                                          fontSize: 14,
                                                          color:
                                                          Colors.grey),
                                                    ),
                                                    const SizedBox(
                                                        height: 8),
                                                    Row(
                                                      children: [
                                                        FutureBuilder<double>(
                                                          future: CompanyService()
                                                              .getAverageCompanyRating(
                                                              companyId),
                                                          builder:
                                                              (_, snap) {
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
                                                                Text(avg
                                                                    .toStringAsFixed(
                                                                    1)),
                                                              ],
                                                            );
                                                          },
                                                        ),
                                                        const SizedBox(
                                                            width: 12),
                                                        FutureBuilder<int>(
                                                          future: CompanyService()
                                                              .getCompanyRatingCount(
                                                              companyId),
                                                          builder:
                                                              (_, snap) {
                                                            final count =
                                                                snap.data ??
                                                                    0;
                                                            return Text(
                                                              '($count reviews)',
                                                              style: const TextStyle(
                                                                  fontSize:
                                                                  12,
                                                                  color: Colors
                                                                      .black54),
                                                            );
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // ── ACTION BUTTON ─────────────
                                              if (canJoin)
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor: const Color(
                                                        0xFF1976D2),
                                                    shape:
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          16),
                                                    ),
                                                    padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                                  ),
                                                  onPressed: () async {
                                                    final ok =
                                                    await RequestService()
                                                        .sendJoinRequest(
                                                        companyId);
                                                    ScaffoldMessenger.of(
                                                        context)
                                                        .showSnackBar(
                                                      SnackBar(
                                                        content: Row(
                                                          children: const [
                                                            Icon(
                                                              Icons
                                                                  .check_circle,
                                                              color: Colors
                                                                  .white,
                                                            ),
                                                            SizedBox(
                                                                width: 8),
                                                            Text(
                                                              'Join request sent',
                                                              style: TextStyle(
                                                                  color: Colors
                                                                      .white),
                                                            ),
                                                          ],
                                                        ),
                                                        backgroundColor:
                                                        Colors.green
                                                            .shade600,
                                                        behavior:
                                                        SnackBarBehavior
                                                            .floating,
                                                        margin:
                                                        const EdgeInsets
                                                            .symmetric(
                                                            horizontal:
                                                            16,
                                                            vertical:
                                                            8),
                                                        shape:
                                                        const RoundedRectangleBorder(
                                                          borderRadius:
                                                          BorderRadius.all(
                                                            Radius.circular(12),
                                                          ),
                                                        ),
                                                        duration:
                                                        const Duration(
                                                            seconds: 2),
                                                      ),
                                                    );
                                                  },
                                                  child: const Text(
                                                    'Join',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                    ),
                                                  ),
                                                )
                                              else if (isMember)
                                                ElevatedButton.icon(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                    Colors.orange
                                                        .shade700,
                                                    shape:
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          16),
                                                    ),
                                                    padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                                  ),
                                                  icon: const Icon(
                                                    Icons.rate_review,
                                                    color: Colors.white,
                                                    size: 18,
                                                  ),
                                                  label: const Text(
                                                    'Rate',
                                                    style: TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 14,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                    ),
                                                  ),
                                                  onPressed: () {
                                                    // star-picker dialog
                                                    int _selected = 0;
                                                    showDialog(
                                                      context: context,
                                                      builder:
                                                          (dialogCtx) {
                                                        return StatefulBuilder(
                                                          builder:
                                                              (ctx, setState) {
                                                            return AlertDialog(
                                                              title: const Text(
                                                                  'Rate this company'),
                                                              content: Row(
                                                                mainAxisAlignment:
                                                                MainAxisAlignment
                                                                    .center,
                                                                children: List
                                                                    .generate(
                                                                    5,
                                                                        (i) {
                                                                      return IconButton(
                                                                        icon:
                                                                        Icon(
                                                                          i <
                                                                              _selected
                                                                              ? Icons
                                                                              .star
                                                                              : Icons
                                                                              .star_border,
                                                                          color: Colors
                                                                              .amber,
                                                                          size:
                                                                          32,
                                                                        ),
                                                                        onPressed:
                                                                            () {
                                                                          setState(
                                                                                  () {
                                                                                _selected =
                                                                                    i +
                                                                                        1;
                                                                              });
                                                                        },
                                                                      );
                                                                    }),
                                                              ),
                                                              actions: [
                                                                TextButton(
                                                                  onPressed: () =>
                                                                      Navigator.of(ctx)
                                                                          .pop(),
                                                                  child: const Text(
                                                                      'Cancel'),
                                                                ),
                                                                ElevatedButton(
                                                                  onPressed:
                                                                  _selected ==
                                                                      0
                                                                      ? null
                                                                      : () async {
                                                                    await CompanyService().rateCompany(companyId, _selected);
                                                                    Navigator.of(ctx).pop();
                                                                    ScaffoldMessenger.of(context)
                                                                      ..hideCurrentSnackBar()
                                                                      ..showSnackBar(
                                                                        SnackBar(
                                                                          behavior: SnackBarBehavior.floating,
                                                                          margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                                                          backgroundColor: Colors.green.shade600,
                                                                          content: Row(
                                                                            children: [
                                                                              const Icon(Icons.check_circle, color: Colors.white),
                                                                              const SizedBox(width: 8),
                                                                              Expanded(child: Text('You rated $_selected ★', style: const TextStyle(color: Colors.white))),
                                                                            ],
                                                                          ),
                                                                        ),
                                                                      );
                                                                  },
                                                                  child:
                                                                  const Text(
                                                                    'Submit',
                                                                  ),
                                                                ),
                                                              ],
                                                            );
                                                          },
                                                        );
                                                      },
                                                    );
                                                  },
                                                )
                                              else
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                    Colors.grey,
                                                    shape:
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          16),
                                                    ),
                                                    padding:
                                                    const EdgeInsets
                                                        .symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                                  ),
                                                  onPressed: null,
                                                  child: const Text(
                                                    'Member',
                                                    style: TextStyle(
                                                        color: Colors.white,
                                                        fontSize: 14),
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
