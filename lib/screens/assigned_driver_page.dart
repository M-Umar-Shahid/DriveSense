import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'company_driver_detail_screen.dart';

class AssignedDriversPage extends StatefulWidget {
  final String companyId;
  const AssignedDriversPage({Key? key, required this.companyId}) : super(key: key);

  @override
  _AssignedDriversPageState createState() => _AssignedDriversPageState();
}

class _AssignedDriversPageState extends State<AssignedDriversPage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Drivers'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Current'),
              Tab(text: 'Past'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _buildCurrentDrivers(),
            _buildPastDrivers(),
          ],
        ),
      ),
    );
  }

  /// Tab 1: only those still in driverIds
  Widget _buildCurrentDrivers() {
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('companies')
          .doc(widget.companyId)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final driverIds = List<String>.from(snap.data!.get('driverIds') ?? []);
        if (driverIds.isEmpty) return const Center(child: Text('No current drivers'));
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('users')
              .where(FieldPath.documentId, whereIn: driverIds)
              .snapshots(),
          builder: (ctx, usersSnap) {
            if (!usersSnap.hasData) return const Center(child: CircularProgressIndicator());
            final docs = usersSnap.data!.docs;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: docs.length,
              itemBuilder: (_, i) {
                final data = docs[i].data()! as Map<String, dynamic>;
                return _buildDriverTile(docs[i].id, data);
              },
            );
          },
        );
      },
    );
  }

  /// Tab 2: everyone who ever worked here, but no longer active
  Widget _buildPastDrivers() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('users')
          .where('companyHistory', arrayContains: widget.companyId)
          .snapshots(),
      builder: (ctx, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final past = snap.data!.docs.where((doc) {
          final data = doc.data()! as Map<String, dynamic>;
          final assigns = (data['assignments'] as List).cast<Map>();
          // find the assignment for this company
          final myAssign = assigns.lastWhere(
                (a) => a['companyId'] == widget.companyId,
            orElse: () => {},
          );
          // only include if it’s not active
          return myAssign.isNotEmpty && myAssign['status'] != 'active';
        }).toList();

        if (past.isEmpty) return const Center(child: Text('No past drivers'));
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: past.length,
          itemBuilder: (_, i) {
            final data = past[i].data()! as Map<String, dynamic>;
            return _buildDriverTile(past[i].id, data);
          },
        );
      },
    );
  }

  /// Shared tile builder
  Widget _buildDriverTile(String uid, Map<String, dynamic> data) {
    final assigns = (data['assignments'] as List).cast<Map>();
    // find the assignment for this company
    final myAssign = assigns.lastWhere(
          (a) => a['companyId'] == widget.companyId,
      orElse: () => {},
    );

    final status = myAssign['status'] ?? '—';
    final hired  = myAssign['dateHired']?.toDate().toLocal().toString().split(' ')[0] ?? '—';
    final left   = myAssign['dateLeft']  != null
        ? myAssign['dateLeft'].toDate().toLocal().toString().split(' ')[0]
        : 'Present';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        title: Text(data['displayName'] ?? data['email']),
        subtitle: Text('Status: $status\nHired: $hired  •  Left: $left'),
        isThreeLine: true,
        onTap: () {
          Navigator.of(context).push(MaterialPageRoute(
            builder: (_) => DriverDetailPage(driverId: uid),
          ));
        },
      ),
    );
  }
}
