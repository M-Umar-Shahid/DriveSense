// lib/screens/companies_list_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../services/company_service.dart';
import '../services/request_service.dart';
import 'company_detail_screen.dart';

class CompaniesListPage extends StatefulWidget {
  const CompaniesListPage({Key? key}) : super(key: key);
  @override
  State<CompaniesListPage> createState() => _CompaniesListPageState();
}

class _CompaniesListPageState extends State<CompaniesListPage> {
  bool _sortDescending = true;

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Companies')),
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

        final u = userSnap.data!.data()! as Map<String, dynamic>;
        final history = (u['companyHistory'] as List<dynamic>?)
            ?.cast<String>() ??
            [];
        final assignsRaw = (u['assignments'] as List<dynamic>?) ?? [];
        final assigns =
        assignsRaw.cast<Map<String, dynamic>>();

        // helper to know if user has an active stint here:
        bool isMemberOf(String companyId) {
          return assigns.any((a) =>
          a['companyId'] == companyId &&
              a['status']    == 'active');
        }

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

                // ─── SORT TOGGLE ───────────────────────────────────
                Padding(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      const Text('Sort by:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 12),
                      ChoiceChip(
                        label: const Text('Highest ★'),
                        selected: _sortDescending,
                        onSelected: (_) => setState(() => _sortDescending = true),
                      ),
                      const SizedBox(width: 8),
                      ChoiceChip(
                        label: const Text('Lowest ★'),
                        selected: !_sortDescending,
                        onSelected: (_) => setState(() => _sortDescending = false),
                      ),
                    ],
                  ),
                ),

                // ─── COMPANIES LIST ───────────────────────────────
                Expanded(
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('companies')
                        .orderBy('avgRating', descending: _sortDescending)
                        .snapshots(),
                    builder: (context, snap) {
                      if (snap.hasError) {
                        return const Center(child: Text('Error loading companies'));
                      }
                      if (!snap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      final docs = snap.data!.docs;
                      return Padding(
                        padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${docs.length} Companies Available',
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
                                  final name =
                                      data['companyName'] as String? ?? 'Unnamed';
                                  final avgRating =
                                      data['avgRating'] as num? ?? 0.0;
                                  final driverIds =
                                  List<String>.from(data['driverIds'] ?? []);
                                  final isMember = isMemberOf(companyId);

                                  return TweenAnimationBuilder<double>(
                                    tween: Tween(begin: 0, end: 1),
                                    duration:
                                    Duration(milliseconds: 300 + index * 100),
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
                                              offset: Offset(0, 4)),
                                        ],
                                      ),
                                      child: InkWell(
                                        borderRadius: BorderRadius.circular(20),
                                        onTap: () => Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                CompanyDetailPage(companyId: companyId),
                                          ),
                                        ),
                                        child: Padding(
                                          padding: const EdgeInsets.all(16),
                                          child: Row(
                                            children: [
                                              // Avatar
                                              CircleAvatar(
                                                radius: 28,
                                                backgroundColor: Colors.blueAccent
                                                    .withOpacity(0.1),
                                                child: Text(
                                                  name.isNotEmpty
                                                      ? name[0].toUpperCase()
                                                      : '?',
                                                  style: const TextStyle(
                                                    fontSize: 24,
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.blueAccent,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 20),

                                              // Info
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      name,
                                                      style: const TextStyle(
                                                        fontSize: 18,
                                                        fontWeight:
                                                        FontWeight.w600,
                                                      ),
                                                    ),
                                                    const SizedBox(height: 4),
                                                    Text(
                                                      '${driverIds.length} driver${driverIds.length == 1 ? "" : "s"}',
                                                      style: const TextStyle(
                                                          fontSize: 14,
                                                          color: Colors.grey),
                                                    ),
                                                    const SizedBox(height: 8),
                                                    Row(
                                                      children: [
                                                        const Icon(
                                                          Icons.star,
                                                          size: 16,
                                                          color: Colors.amber,
                                                        ),
                                                        const SizedBox(width: 4),
                                                        Text(
                                                          avgRating
                                                              .toStringAsFixed(1),
                                                          style:
                                                          const TextStyle(
                                                            fontWeight:
                                                            FontWeight.bold,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                  ],
                                                ),
                                              ),

                                              // Action button
                                              if (!isMember)
                                                ElevatedButton(
                                                  style: ElevatedButton.styleFrom(
                                                    backgroundColor:
                                                    const Color(0xFF1976D2),
                                                    shape:
                                                    RoundedRectangleBorder(
                                                      borderRadius:
                                                      BorderRadius.circular(
                                                          16),
                                                    ),
                                                    padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 20,
                                                        vertical: 12),
                                                  ),
                                                  onPressed: () async {
                                                    final ok = await RequestService()
                                                        .sendJoinRequest(
                                                        companyId);
                                                    ScaffoldMessenger.of(context)
                                                      ..hideCurrentSnackBar()
                                                      ..showSnackBar(
                                                        SnackBar(
                                                          content: Text(ok
                                                              ? 'Join request sent'
                                                              : 'Already requested'),
                                                          behavior: SnackBarBehavior
                                                              .floating,
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
                                              else
                                                Column(
                                                  mainAxisSize: MainAxisSize.min,
                                                  children: [
                                                    // ─── (A) Rate / Edit ────────────────────────────────
                                                    FutureBuilder<int?>(
                                                      future: CompanyService().fetchUserRating(
                                                        companyId,
                                                        FirebaseAuth.instance.currentUser!.uid,
                                                      ),
                                                      builder: (ctx, rs) {
                                                        final existing = rs.data;               // null or 1–5
                                                        final label    = (existing == null) ? 'Rate' : 'Edit';
                                                        return ElevatedButton.icon(
                                                          icon: const Icon(Icons.star, size: 18, color: Colors.white),
                                                          label: Text(label, style: const TextStyle(color: Colors.white)),
                                                          style: ElevatedButton.styleFrom(
                                                            backgroundColor: Colors.orange.shade700,
                                                            shape: RoundedRectangleBorder(
                                                              borderRadius: BorderRadius.circular(16),
                                                            ),
                                                            foregroundColor: Colors.white,
                                                          ),
                                                          onPressed: () => _showRatingDialog(ctx, companyId, existing),
                                                        );
                                                      },
                                                    ),

                                                    const SizedBox(height: 8),

                                                    // ─── (B) Leave Company ───────────────────────────────
                                                    ElevatedButton.icon(
                                                      icon: const Icon(Icons.exit_to_app, size: 18, color: Colors.white),
                                                      label: const Text('Leave', style: TextStyle(color: Colors.white)),
                                                      style: ElevatedButton.styleFrom(
                                                        backgroundColor: Colors.red.shade600,
                                                        shape: RoundedRectangleBorder(
                                                          borderRadius: BorderRadius.circular(16),
                                                        ),
                                                        foregroundColor: Colors.white,
                                                      ),
                                                      onPressed: () async {
                                                        final ok = await showDialog<bool>(
                                                          context: ctx,
                                                          builder: (d) => AlertDialog(
                                                            title: const Text('Leave Company?'),
                                                            content: const Text('Are you sure you want to leave?'),
                                                            actions: [
                                                              TextButton(onPressed: ()=>Navigator.pop(d,false), child: const Text('Cancel')),
                                                              TextButton(onPressed: ()=>Navigator.pop(d,true),  child: const Text('Leave')),
                                                            ],
                                                          ),
                                                        );
                                                        if (ok == true) {
                                                          await CompanyService().leaveCompany(
                                                            companyId,
                                                            FirebaseAuth.instance.currentUser!.uid,
                                                          );
                                                          ScaffoldMessenger.of(ctx).showSnackBar(
                                                            const SnackBar(content: Text('You have left the company')),
                                                          );
                                                        }
                                                      },
                                                    ),
                                                  ],
                                                )
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
  void _showRatingDialog(BuildContext context, String companyId, int? existingStars) {
    int selected = existingStars ?? 0;
    bool submitting = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          return AlertDialog(
            title: Text(existingStars == null ? 'Rate Company' : 'Edit Rating'),
            content: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (i) {
                return IconButton(
                  icon: Icon(
                    i < selected ? Icons.star : Icons.star_border,
                    color: Colors.amber,
                  ),
                  onPressed: submitting
                      ? null
                      : () => setState(() {
                    selected = i + 1;
                  }),
                );
              }),
            ),
            actions: [
              TextButton(
                onPressed: submitting ? null : () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: (selected == 0 || submitting)
                    ? null
                    : () async {
                  setState(() => submitting = true);
                  try {
                    await CompanyService().rateCompany(
                      companyId,
                      FirebaseAuth.instance.currentUser!.uid,
                      selected,
                    );
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          existingStars == null
                              ? 'You rated $selected ★'
                              : 'Rating updated to $selected ★',
                        ),
                        backgroundColor: Colors.green.shade600,
                      ),
                    );
                  } catch (e) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Failed to submit rating: $e'),
                        backgroundColor: Colors.red.shade600,
                      ),
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange.shade700,
                  foregroundColor: Colors.white,
                ),
                child: submitting
                    ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text('Submit'),
              ),
            ],
          );
        },
      ),
    );
  }

}
