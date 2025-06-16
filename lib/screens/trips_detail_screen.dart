// lib/screens/trip_details_page.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

import '../models/alert.dart';
import '../models/trip.dart';
import 'full_screen_image_view.dart';

class TripDetailsPage extends StatefulWidget {
  final Trip trip;
  const TripDetailsPage({Key? key, required this.trip}) : super(key: key);

  @override
  State<TripDetailsPage> createState() => _TripDetailsPageState();
}

class _TripDetailsPageState extends State<TripDetailsPage> {
  List<Alert> _alerts = [];
  String _filter = 'All';
  final List<String> _types = ['All', 'Drowsy', 'Yawning', 'No Seatbelt'];

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  Future<void> _loadAlerts() async {
    final snap = await FirebaseFirestore.instance
        .collection('trips')
        .doc(widget.trip.id)
        .collection('alerts')
        .orderBy('timestamp', descending: true)
        .get();

    setState(() {
      _alerts = snap.docs
          .map((d) => Alert.fromMap(d.id, d.data() as Map<String, dynamic>))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final trip = widget.trip;
    final fullFmt = DateFormat('MMM d, yyyy hh:mm a');

    // apply filter
    final display = _filter == 'All'
        ? _alerts
        : _alerts.where((a) => a.type == _filter).toList();

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ← Back + Title
            Row(
              children: [
                GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.arrow_back, size: 24),
                ),
                const SizedBox(width: 12),
                Text(
                  'Trip #${trip.tripNo}',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Vertical Time Card with full date+time ──
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFE3F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  Text(
                    fullFmt.format(trip.startTime),
                    style: TextStyle(color: Colors.blue[900], fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Icon(Icons.arrow_downward, color: Colors.blue[700]),
                  const SizedBox(height: 4),
                  Text(
                    fullFmt.format(trip.endTime),
                    style: TextStyle(color: Colors.blue[900], fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Summary Panel ───────────────────────
            Container(
              decoration: BoxDecoration(
                color: const Color(0xFFBBDEFB),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: ['Drowsy', 'Yawning', 'No Seatbelt'].map((type) {
                  final count = _alerts.where((a) => a.type == type).length;
                  IconData icon;
                  if (type == 'Drowsy')   icon = Icons.remove_red_eye;
                  else if (type == 'Yawning') icon = Icons.mood_bad;
                  else                       icon = Icons.warning_amber_rounded;
                  return Column(
                    children: [
                      Icon(icon, color: Colors.blue[800]),
                      const SizedBox(height: 4),
                      Text(type, style: TextStyle(color: Colors.blue[900])),
                      Text('$count', style: TextStyle(color: Colors.blue[800])),
                    ],
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),

            // ── Alert Snapshots Header ──────────────
            Center(
              child: Text(
                'Alert Snapshots',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey[800],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // ── Filter Dropdown ─────────────────────
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: DropdownButton<String>(
                value: _filter,
                isExpanded: true,
                underline: const SizedBox(),
                items: _types.map((t) {
                  return DropdownMenuItem(
                    value: t,
                    child: Text(t),
                  );
                }).toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _filter = v);
                },
              ),
            ),
            const SizedBox(height: 16),

            // ── Snapshot Grid ───────────────────────
            if (display.isEmpty)
              const Center(child: Text('No alerts match this filter.'))
            else
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: display.length,
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemBuilder: (ctx, i) {
                  final a = display[i];
                  return InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => FullScreenImageView(imageUrl: a.imageUrl),
                        ),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.shade200),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.03),
                            blurRadius: 6,
                            offset: const Offset(0, 3),
                          )
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            child: ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                              child: Image.network(a.imageUrl, fit: BoxFit.cover),
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(a.type, style: const TextStyle(fontWeight: FontWeight.bold)),
                                ),
                                Text(
                                  DateFormat('hh:mm a').format(a.timestamp),
                                  style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

          ],
        ),
      ),
    );
  }
}
