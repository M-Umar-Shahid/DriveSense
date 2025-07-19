import 'package:cloud_firestore/cloud_firestore.dart';

class Alert {
  final String id;
  final String imageUrl;
  final String type;
  final DateTime timestamp;

  Alert({
    required this.id,
    required this.imageUrl,
    required this.type,
    required this.timestamp,
  });

  factory Alert.fromMap(String id, Map<String, dynamic> data) {
    // read the raw field
    final rawTs = data['timestamp'];

    // convert only if it really is a Timestamp
    final timestamp = (rawTs is Timestamp)
        ? rawTs.toDate()
        : DateTime.fromMillisecondsSinceEpoch(0);
    // ← or whatever “fallback” makes sense

    return Alert(
      id:        id,
      imageUrl:  data['imageUrl'] as String? ?? '',
      type:      data['alertType'] as String? ?? 'Unknown',
      timestamp: timestamp,
    );
  }

}
