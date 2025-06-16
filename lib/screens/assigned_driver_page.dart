import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'company_driver_detail_screen.dart';
import 'package:intl/intl.dart';

class AssignedDriversPage extends StatefulWidget {
  final String companyId;
  const AssignedDriversPage({Key? key, required this.companyId}) : super(key: key);

  @override
  _AssignedDriversPageState createState() => _AssignedDriversPageState();
}

class _AssignedDriversPageState extends State<AssignedDriversPage> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          elevation: 0,
          backgroundColor: Colors.white,
          leading: BackButton(color: Colors.black87),
          title: Text('Drivers', style: theme.textTheme.headlineMedium!.copyWith(color: Colors.black87)),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(56),
            child: Container(
              color: Colors.white,
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: theme.primaryColorLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                labelColor: theme.primaryColor,
                unselectedLabelColor: Colors.grey[600],
                labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w400),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                tabs: const [
                  Tab(text: 'Current'),
                  Tab(text: 'Past'),
                ],
              ),
            ),
          ),
        ),
        body: Column(
          children: [
            // ─── Search & Count ─────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: TextField(
                decoration: InputDecoration(
                  hintText: 'Search drivers...',
                  prefixIcon: const Icon(Icons.search),
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 16),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
                onChanged: (v) => setState(() => _search = v.trim()),
              ),
            ),

            // ─── Tabs Content ────────────────────────────────
            Expanded(
              child: TabBarView(
                children: [
                  _DriverListView(
                    companyId: widget.companyId,
                    isPast: false,
                    search: _search,
                  ),
                  _DriverListView(
                    companyId: widget.companyId,
                    isPast: true,
                    search: _search,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DriverListView extends StatelessWidget {
  final String companyId;
  final bool isPast;
  final String search;
  const _DriverListView({
    required this.companyId,
    required this.isPast,
    required this.search,
  });

  @override
  Widget build(BuildContext context) {
    // choose the right stream
    final Stream<List<QueryDocumentSnapshot>> stream = isPast
        ? FirebaseFirestore.instance
        .collection('users').where('role', isEqualTo: 'driver')
        .where('companyHistory', arrayContains: companyId)
        .snapshots()
        .map((snap) => snap.docs.where((doc) {
      final data = doc.data()! as Map<String, dynamic>;
      final assigns = (data['assignments'] as List).cast<Map>();
      final myAssign = assigns.lastWhere(
            (a) => a['companyId'] == companyId,
        orElse: () => {},
      );
      return myAssign.isNotEmpty && myAssign['status'] != 'active';
    }).toList())
        : FirebaseFirestore.instance
        .collection('companies')
        .doc(companyId)
        .snapshots()
        .asyncMap((snap) {
      final ids = List<String>.from(snap.data()?['driverIds'] ?? []);
      if (ids.isEmpty) return [];
      return FirebaseFirestore.instance
          .collection('users').where('role', isEqualTo: 'driver')
          .where(FieldPath.documentId, whereIn: ids)
          .get()
          .then((q) => q.docs);
    });

    return StreamBuilder<List<QueryDocumentSnapshot>>(
      stream: stream,
      builder: (ctx, snap) {
        if (snap.connectionState != ConnectionState.active) {
          return const Center(child: CircularProgressIndicator());
        }
        var docs = snap.data ?? [];
        // apply search
        if (search.isNotEmpty) {
          docs = docs.where((d) {
            final nm = (d.data()! as Map)['displayName'] as String? ??
                (d.data()! as Map)['email'] as String;
            return nm.toLowerCase().contains(search.toLowerCase());
          }).toList();
        }
        if (docs.isEmpty) {
          return Center(
            child: Text(
              isPast ? 'No past drivers' : 'No current drivers',
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemCount: docs.length,
          itemBuilder: (_, i) {
            final doc = docs[i];
            final data = doc.data()! as Map<String, dynamic>;

            // find assignment
            final assigns = (data['assignments'] as List).cast<Map>();
            final myAssign = assigns.lastWhere(
                  (a) => a['companyId'] == companyId,
              orElse: () => {},
            );
            final status = (myAssign['status'] as String?)?.toUpperCase() ?? '—';
            final dateHired = (myAssign['dateHired'] as Timestamp?)?.toDate();
            final dateLeft = (myAssign['dateLeft'] as Timestamp?)?.toDate();

            // avatar data
            final photoUrl = data['photoURL'] as String?;
            final displayName = data['displayName'] as String? ??
                (data['email'] as String);
            final initial = displayName.isNotEmpty
                ? displayName[0].toUpperCase()
                : '?';

            return InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => DriverDetailPage(driverId: doc.id),
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    )
                  ],
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                child: Row(
                  children: [
                    // ── Avatar with fallback ───────────────
                    CircleAvatar(
                      radius: 30,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                      photoUrl != null ? NetworkImage(photoUrl) : null,
                      // only provide the error handler when there's a NetworkImage
                      onBackgroundImageError: photoUrl != null
                          ? (_, __) {
                        // maybe setState(() => _hadImageError = true);
                      }
                          : null,
                      child: (photoUrl == null)
                          ? Text(initial,
                          style: TextStyle(
                            fontSize: 24,
                            color: Theme.of(context).primaryColorDark,
                            fontWeight: FontWeight.bold,
                          ))
                          : null,
                    ),
                    const SizedBox(width: 16),

                    // ── Details ───────────────────────────
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            displayName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isPast
                                      ? Colors.red.shade50
                                      : Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    color: isPast
                                        ? Colors.red.shade700
                                        : Colors.green.shade700,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              if (dateHired != null)
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_today,
                                        size: 14, color: Colors.grey),
                                    const SizedBox(width: 4),
                                    Text(
                                      DateFormat.yMMMd().format(dateHired),
                                      style: const TextStyle(
                                          fontSize: 13, color: Colors.grey),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text(
                            isPast
                                ? 'Left on ${dateLeft != null ? DateFormat.yMMMd().format(dateLeft) : '—'}'
                                : 'Currently Active',
                            style: TextStyle(
                              fontSize: 13,
                              color: isPast
                                  ? Colors.red.shade700
                                  : Colors.green.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
