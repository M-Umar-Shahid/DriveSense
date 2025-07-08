import 'package:cloud_firestore/cloud_firestore.dart';

class Detection {
  final String type;
  final DateTime timestamp;
  final String severity;
  final String imageUrl;            // ← new field

  Detection({
    required this.type,
    required this.timestamp,
    required this.severity,
    required this.imageUrl,         // ← include in ctor
  });

  factory Detection.fromMap(Map<String, dynamic> data) {
    return Detection(
      type: data['type'] as String,
      timestamp: (data['timestamp'] as Timestamp).toDate(),
      severity: data['severity'] as String,
      imageUrl: data['imageUrl'] as String,  // ← pull from your Firestore doc
    );
  }
}
