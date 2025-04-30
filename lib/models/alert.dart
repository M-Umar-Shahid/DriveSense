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
    return Alert(
      id: id,
      imageUrl: data['imageUrl'] as String? ?? '',
      type: data['alertType'] as String? ?? 'Unknown',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
