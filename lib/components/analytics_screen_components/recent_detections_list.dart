import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/detection.dart';

class RecentDetectionsList extends StatelessWidget {
  final List<Detection> detections;
  const RecentDetectionsList({required this.detections, super.key});

  @override
  Widget build(BuildContext context) {
    if (detections.isEmpty) {
      return const Center(child: Text('No recent issues', style: TextStyle(color: Colors.grey)));
    }
    return Column(
      children: detections.map((d) {
        final time = DateFormat('MMM d, hh:mm a').format(d.timestamp);
        final color = d.severity == 'High'
            ? Colors.redAccent
            : d.severity == 'Medium'
            ? Colors.orangeAccent
            : Colors.green;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 8, offset: const Offset(0,4))],
          ),
          child: Row(
            children: [
              Icon(Icons.warning_amber, color: color),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(d.type, style: const TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 4),
                    Text(time, style: const TextStyle(color: Colors.grey, fontSize: 12)),
                  ],
                ),
              ),
              Chip(
                label: Text(d.severity),
                backgroundColor: color.withOpacity(0.2),
                labelStyle: TextStyle(color: color),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}
