import 'package:drivesense/screens/trips_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/trip.dart';
import '../services/dashboard_sevice.dart';

class AllTripsPage extends StatefulWidget {
  final String driverId;   // ← new
  const AllTripsPage({
    Key? key,
    required this.driverId,
  }) : super(key: key);

  @override
  State<AllTripsPage> createState() => _AllTripsPageState();
}

class _AllTripsPageState extends State<AllTripsPage> {
  final DashboardService _svc = DashboardService();
  DateTime? _selectedDate;

  Future<void> _pickDate() async {
    final today = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? today,
      firstDate: DateTime(today.year - 1),
      lastDate: today,
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: SafeArea(
        child: Column(
          children: [
            // ─── Custom Header + Filter ───────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: const Icon(Icons.arrow_back, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'All Trips',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const Spacer(),
                  // Show chosen date if any
                  if (_selectedDate != null)
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: Text(
                        DateFormat('MMM d, yyyy').format(_selectedDate!),
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                    ),
                  // Calendar icon
                  IconButton(
                    icon: const Icon(Icons.calendar_today_outlined),
                    onPressed: _pickDate,
                  ),
                  // Clear filter
                  if (_selectedDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear, size: 20),
                      onPressed: () => setState(() => _selectedDate = null),
                    ),
                ],
              ),
            ),

            // ─── Trip List ────────────────────────────────
            Expanded(
              child: FutureBuilder<List<Trip>>(
                future: _svc.fetchAllTrips(driverId: widget.driverId),
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snap.hasError) {
                    return Center(child: Text('Error: ${snap.error}'));
                  }

                  // 1️⃣ Get all trips, then apply date filter if set
                  // 1️⃣ Remove any trips whose startTime or endTime was null in Firestore
                  final allTrips = snap.data!
                      .where((t) =>
                  // only keep trips where both times are non‐null
                  t.startTime != null && t.endTime != null
                  ).toList();

                  // 2️⃣ Now apply your _selectedDate filter as before
                  final trips = _selectedDate == null
                      ? allTrips
                      : allTrips.where((t) {
                    final d = t.startTime;
                    return d.year == _selectedDate!.year
                        && d.month == _selectedDate!.month
                        && d.day == _selectedDate!.day;
                  }).toList();


                  if (trips.isEmpty) {
                    return const Center(child: Text('No trips for selected date.'));
                  }

                  // 2️⃣ Group by date (though with filter you'll usually have one group)
                  final grouped = <String, List<Trip>>{};
                  for (final t in trips) {
                    final dayStr = DateFormat('MMMM d, yyyy').format(t.startTime);
                    grouped.putIfAbsent(dayStr, () => []).add(t);
                  }

                  // 3️⃣ Flatten into [header, trip, trip, header, …]
                  final items = <dynamic>[];
                  grouped.forEach((day, list) {
                    items.add(day);
                    items.addAll(list);
                  });

                  // 4️⃣ Render
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                    itemCount: items.length,
                    itemBuilder: (ctx, i) {
                      final item = items[i];
                      if (item is String) {
                        // Date header
                        return Padding(
                          padding: const EdgeInsets.only(top: 16, bottom: 8),
                          child: Text(
                            item,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey[800],
                            ),
                          ),
                        );
                      } else {
                        final trip = item as Trip;
                        final hasAlerts = trip.alerts > 0;
                        final fmt = DateFormat('hh:mm a');
                        final start = fmt.format(trip.startTime);
                        final end   = fmt.format(trip.endTime);

                        return InkWell(
                            borderRadius: BorderRadius.circular(12),
                      onTap: () {
                      Navigator.push(
                      context,
                      MaterialPageRoute(
                      builder: (_) => TripDetailsPage(trip: trip),
                      ),
                      );
                      },
                      child: Container(
                          margin: const EdgeInsets.only(bottom: 8),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: hasAlerts ? Colors.redAccent : Colors.green,
                              width: 1.2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.03),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              )
                            ],
                          ),
                          child: Row(
                            children: [
                              // Trip info
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Trip #${trip.tripNo}',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$start  →  $end',
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Alerts badge
                              Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    hasAlerts
                                        ? Icons.warning_amber_rounded
                                        : Icons.check_circle_rounded,
                                    size: 28,
                                    color: hasAlerts
                                        ? Colors.redAccent
                                        : Colors.green,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${trip.alerts} Alerts',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500,
                                      color: hasAlerts
                                          ? Colors.redAccent
                                          : Colors.green,
                                    ),
                                  )
                                ],
                              ),
                            ],
                          ),
                        ),
                        );
                      }
                    },
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
