import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/detection.dart';

class RecentDetectionsList extends StatelessWidget {
  final List<Detection> detections;
  const RecentDetectionsList({
    required this.detections,
    super.key
  });
  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty) {
      return Text('No alerts recorded this month.');
    }
    return Column(
        children: detections.map((d) {
          final time = DateFormat('MMM d, yyyy – hh:mm a').format(d.timestamp);
          final color = d.severity == 'High'
              ? Colors.redAccent
              : d.severity == 'Medium'
              ? Colors.orangeAccent
              : Colors.green;
          return Container(
              margin: EdgeInsets.only(bottom: 10),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)]
              ),
              child: Row(
                  children: [
                    Icon(Icons.warning_amber, color: color),
                    SizedBox(width: 10),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.type, style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(time, style: TextStyle(color: Colors.grey, fontSize: 12)),
                            ]
                        )
                    ),
                    Chip(
                        label: Text(d.severity),
                        backgroundColor: color.withOpacity(0.1),
                        labelStyle: TextStyle(color: color)
                    )
                  ]
              )
          );
        }).toList()
    );
  }
}
