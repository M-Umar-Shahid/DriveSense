import 'package:drivesense/screens/trips_detail_screen.dart';
import 'package:flutter/material.dart';
import '../../models/trip.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  const TripCard(this.trip, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Determine status styling
    final isSafe     = trip.status.toLowerCase() == 'safe';
    final statusColor = isSafe ? Colors.green : Colors.redAccent;
    final statusIcon  = isSafe ? Icons.check_circle : Icons.warning;

    // Format times as HH:mm
    final start = trip.startTime;
    final end   = trip.endTime;
    final startStr = '${start.hour.toString().padLeft(2, '0')}:${start.minute.toString().padLeft(2, '0')}';
    final endStr   = '${end.hour.toString().padLeft(2, '0')}:${end.minute.toString().padLeft(2, '0')}';

    return InkWell(
      borderRadius: BorderRadius.circular(14),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TripDetailsPage(trip: trip),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black12.withOpacity(0.05),
              blurRadius: 6,
              offset: const Offset(0, 3),
            ),
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
                      fontFamily: 'Poppins',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$startStr → $endStr',
                    style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Status & alerts
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 6),
                Text(
                  '${trip.alerts} Alert${trip.alerts != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 14,
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
