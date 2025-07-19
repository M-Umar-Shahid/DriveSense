import 'package:cloud_firestore/cloud_firestore.dart';

class Detection {
  final String uid;
  final String type;
  final String imageUrl;
  final DateTime timestamp;
  final String severity;

  Detection({
    required this.uid,
    required this.type,
    required this.imageUrl,
    required this.timestamp,
    required this.severity,
  });

  factory Detection.fromMap(Map<String, dynamic> map) {
    // Firestore stores timestamp as a Timestamp
    final Timestamp? ts = map['timestamp'] as Timestamp?;

    // Determine the alert type (fallback to category if type missing)
    final String alertType = map['alertType'] as String? ?? map['alertCategory'] as String? ?? 'Unknown';

    // Severity isn't stored by default; you can add it to your Firestore docs,
    // or derive a default based on alertType. Here we default to 'Medium'.
    final String severity = map['severity'] as String? ?? 'Medium';

    return Detection(
      uid: map['uid'] as String? ?? '',
      type: alertType,
      imageUrl: map['imageUrl'] as String? ?? '',
      timestamp: ts != null ? ts.toDate() : DateTime.now(),
      severity: severity,
    );
  }
}
