import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final int tripNo;
  final DateTime startTime;
  final DateTime endTime;
  final int alerts;
  final String status;

  Trip({
    required this.id,
    required this.tripNo,
    required this.startTime,
    required this.endTime,
    required this.alerts,
    required this.status,
  });

  /// Create a Trip from a raw map (e.g. doc.data())
  factory Trip.fromMap(String id, Map<String, dynamic> data) {
    return Trip(
      id:        id,
      tripNo:    data['tripNo']   as int?    ?? 0,
      startTime: (data['startTime'] as Timestamp).toDate(),
      endTime:   (data['endTime']   as Timestamp).toDate(),
      alerts:    data['alerts']    as int?    ?? 0,
      status:    data['status']    as String? ?? 'Unknown',
    );
  }

  /// Convenience for building directly from a DocumentSnapshot
  factory Trip.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    return Trip.fromMap(doc.id, doc.data()!);
  }
}
