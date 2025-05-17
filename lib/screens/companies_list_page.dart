import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';

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
                borderRadius: const BorderRadius.vertical(
                    bottom: Radius.circular(32)),
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
                  const Icon(Icons.business,
                      size: 40, color: Colors.white70),
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

            // ─── Stream & List ─────────────────────────────────
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('companies')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return const Center(
                        child: Text('Error loading companies'));
                  }
                  if (snapshot.connectionState ==
                      ConnectionState.waiting) {
                    return Center(
                      child: Lottie.asset(
                        'assets/animations/loading_animation.json',
                        width: 200,
                        height: 200,
                        repeat: true,
                      ),
                    );
                  }
                  final docs = snapshot.data?.docs ?? [];

                  return Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${docs.length} Companie${docs.length==1?"":"s"} Available',
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
                              final data = doc.data()!
                              as Map<String, dynamic>;
                              final name =
                                  data['companyName'] as String? ??
                                      'Unnamed';
                              final drivers = List<String>.from(
                                  data['driverIds'] ?? []);
                              final count = drivers.length;

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
                                                  companyId: doc.id),
                                        ),
                                      );
                                    },
                                    child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 56,
                                            height: 56,
                                            decoration: BoxDecoration(
                                              gradient:
                                              const LinearGradient(
                                                colors: [
                                                  Colors.white,
                                                  Colors.white70
                                                ],
                                              ),
                                              shape: BoxShape.circle,
                                              boxShadow: [
                                                BoxShadow(
                                                  color: Colors.black12,
                                                  blurRadius: 4,
                                                  offset:
                                                  const Offset(0, 2),
                                                ),
                                              ],
                                            ),
                                            child: CircleAvatar(
                                              backgroundColor:
                                              Colors.transparent,
                                              child: Text(
                                                name.isNotEmpty
                                                    ? name[0]
                                                    .toUpperCase()
                                                    : '?',
                                                style: TextStyle(
                                                  color: Theme.of(context)
                                                      .primaryColorDark,
                                                  fontWeight:
                                                  FontWeight.bold,
                                                  fontSize: 24,
                                                ),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 20),
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
                                                    FontWeight.w600,
                                                  ),
                                                ),
                                                const SizedBox(
                                                    height: 4),
                                                Text(
                                                  '$count driver${count == 1 ? "" : "s"}',
                                                  style:
                                                  const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          ElevatedButton(
                                            style: ElevatedButton
                                                .styleFrom(
                                              backgroundColor:
                                              const Color(
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
                                              try {
                                                await RequestService()
                                                    .sendJoinRequest(
                                                    doc.id);
                                                ScaffoldMessenger.of(
                                                    context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Join request sent')),
                                                );
                                              } catch (_) {
                                                ScaffoldMessenger.of(
                                                    context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                      content: Text(
                                                          'Request failed')),
                                                );
                                              }
                                            },
                                            child: const Text(
                                              'Join',
                                              style: TextStyle(
                                                color: Colors.white,
                                                  fontSize: 14,
                                                  fontWeight:
                                                  FontWeight.w600),
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
  }
}
