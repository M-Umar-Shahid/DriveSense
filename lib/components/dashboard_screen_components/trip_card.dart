import 'package:flutter/material.dart';
import '../../models/trip.dart';

class TripCard extends StatelessWidget {
  final Trip trip;
  const TripCard(this.trip, {super.key});
  @override
  Widget build(BuildContext context) {
    final statusColor = trip.status == 'Safe' ? Colors.green : Colors.redAccent;
    final statusIcon = trip.status == 'Safe' ? Icons.check_circle : Icons.warning;
    final start = "${trip.startTime.hour.toString().padLeft(2,'0')}:${trip.startTime.minute.toString().padLeft(2,'0')}";
    final end = "${trip.endTime.hour.toString().padLeft(2,'0')}:${trip.endTime.minute.toString().padLeft(2,'0')}";
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: Colors.black12.withOpacity(0.05), blurRadius: 6, offset: Offset(0, 3))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text("Trip", style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14)),
            Text("$start → $end", style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey)),
          ]),
          Row(children: [
            Icon(statusIcon, color: statusColor, size: 18),
            SizedBox(width: 6),
            Text("${trip.alerts} Alert${trip.alerts != 1 ? 's' : ''}",
                style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: statusColor)),
          ]),
        ],
      ),
    );
  }
}
