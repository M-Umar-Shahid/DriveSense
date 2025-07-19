// lib/screens/driver_requests_page.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import '../services/company_service.dart';
import '../services/request_service.dart';
import 'company_detail_screen.dart';

class DriverRequestsPage extends StatefulWidget {
  const DriverRequestsPage({Key? key}) : super(key: key);

  @override
  State<DriverRequestsPage> createState() => _DriverRequestsPageState();
}

class _DriverRequestsPageState extends State<DriverRequestsPage> {
  bool _loading = true;
  bool _sortDesc = true;

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      return const Scaffold(
        body: Center(child: Text('Please log in to view requests.')),
      );
    }

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: const Color(0xFF1976D2),
        // 1️⃣ Make the leading/back icon white:
        iconTheme: const IconThemeData(color: Colors.white),
        // 2️⃣ Make the title text white:
        title: const Text(
          'Hire Requests',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<bool>(
            icon: const Icon(Icons.sort, color: Colors.white),
            onSelected: (desc) => setState(() { _sortDesc = desc; }),
            itemBuilder: (_) => [
              const PopupMenuItem(value: true, child: Text('Highest Rating First')),
              const PopupMenuItem(value: false, child: Text('Lowest Rating First')),
            ],
          )
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('requests')
            .where('type', isEqualTo: 'hire_driver')
            .where('toId', isEqualTo: uid)
            .where('status', isEqualTo: 'pending')
            .orderBy('timestamp', descending: true)
            .snapshots(),
        builder: (ctx, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Error loading requests'));
          }
          if (!snap.hasData) {
            return Center(
              child: Lottie.asset('assets/animations/loading_animation.json',
                  width: 150, height: 150),
            );
          }

          final requests = snap.data!.docs;
          if (requests.isEmpty) {
            return const Center(child: Text('No pending requests'));
          }

          // Build a list of futures that fetch each company’s data
          final futures = requests.map((doc) async {
            final data = doc.data()! as Map<String, dynamic>;
            final companyId = data['fromId'] as String;
            final ts = (data['timestamp'] as Timestamp).toDate();

            final compSnap = await FirebaseFirestore.instance
                .collection('companies')
                .doc(companyId)
                .get();
            final comp = compSnap.data()!;

            return _ReqWithCompany(
              requestId: doc.id,
              companyId: companyId,
              timestamp: ts,
              companyName: comp['companyName'] as String? ?? 'Company',
              logoUrl: comp['logoUrl'] as String?,
              avgRating: (comp['avgRating'] as num?)?.toDouble() ?? 0.0,
            );
          }).toList();

          return FutureBuilder<List<_ReqWithCompany>>(
            future: Future.wait(futures),
            builder: (ctx2, fb) {
              if (!fb.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              var list = fb.data!;
              list.sort((a, b) => _sortDesc
                  ? b.avgRating.compareTo(a.avgRating)
                  : a.avgRating.compareTo(b.avgRating));

              return ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                itemCount: list.length,
                itemBuilder: (ctx3, i) {
                  final item = list[i];
                  return TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: Duration(milliseconds: 300 + i * 50),
                    builder: (ctx4, v, child) => Opacity(
                      opacity: v,
                      child: Transform.translate(
                        offset: Offset(0, 30 * (1 - v)),
                        child: child,
                      ),
                    ),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (_) =>
                                CompanyDetailPage(companyId: item.companyId),
                          ));
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 28,
                                backgroundColor: Colors.grey[200],
                                backgroundImage: item.logoUrl != null
                                    ? NetworkImage(item.logoUrl!)
                                    : null,
                                child: item.logoUrl == null
                                    ? Text(
                                  item.companyName[0].toUpperCase(),
                                  style: const TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                                    : null,
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.companyName,
                                        style: const TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.w600)),
                                    const SizedBox(height: 4),
                                    Text(
                                      MaterialLocalizations.of(context)
                                          .formatShortDate(item.timestamp
                                          .toLocal()) +
                                          ' ' +
                                          MaterialLocalizations.of(context)
                                              .formatTimeOfDay(
                                              TimeOfDay.fromDateTime(
                                                  item.timestamp)),
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.grey),
                                    ),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.star,
                                            size: 16, color: Colors.amber),
                                        const SizedBox(width: 4),
                                        Text(item.avgRating
                                            .toStringAsFixed(1)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              Column(
                                children: [
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.green,
                                      minimumSize: const Size(80, 36),
                                    ),
                                    onPressed: () async {
                                      await RequestService().respondToRequest(item.requestId, true);
                                      await CompanyService().addDriverToCompany(
                                        companyId: item.companyId,
                                        driverId: uid,
                                      );
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Request accepted — you have been hired'),
                                        ),
                                      );
                                      setState(() {
                                        // <-- this forces the StreamBuilder/FutureBuilder to re-run
                                      });
                                    },
                                    child: const Text('Accept'),
                                  ),
                                  const SizedBox(height: 6),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      minimumSize: const Size(80, 36),
                                    ),
                                    onPressed: () async {
                                      await RequestService().respondToRequest(item.requestId, false);
                                      if (!mounted) return;
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('Request rejected')),
                                      );
                                      setState(() {
                                        // <-- trigger rebuild so the snapshot filter drops this doc
                                      });
                                    },
                                    child: const Text('Reject'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }
}

/// Simple holder for one request + its company’s data
class _ReqWithCompany {
  final String requestId;
  final String companyId;
  final DateTime timestamp;
  final String companyName;
  final String? logoUrl;
  final double avgRating;

  _ReqWithCompany({
    required this.requestId,
    required this.companyId,
    required this.timestamp,
    required this.companyName,
    this.logoUrl,
    required this.avgRating,
  });
}
