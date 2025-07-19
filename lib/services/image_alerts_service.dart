// lib/services/image_alerts_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert.dart';

class ImageAlertsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Base query for a specific driver and alert-type filter.
  Query<Map<String, dynamic>> _baseQuery({
    required String driverId,
    required String filter,
  }) {
    var q = _db
        .collection('detections')
        .where('uid', isEqualTo: driverId);

    if (filter != 'All') {
      q = q.where('alertCategory', isEqualTo: filter);
    }

    // Always order by timestamp descending for paging & streaming
    return q
        .orderBy('timestamp', descending: true)
        .withConverter<Map<String, dynamic>>(
      fromFirestore: (snap, _) => snap.data()!,
      toFirestore: (m, _) => m,
    );
  }

  /// Real-time stream of alerts for [driverId] with optional [filter] and [startDate]/[endDate].
  Stream<List<Alert>> streamAlerts({
    required String driverId,
    required String filter,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var q = _baseQuery(driverId: driverId, filter: filter);

    if (startDate != null && endDate != null) {
      final startTs = Timestamp.fromDate(
        DateTime(startDate.year, startDate.month, startDate.day),
      );
      final endTs = Timestamp.fromDate(
        DateTime(endDate.year, endDate.month, endDate.day)
            .add(const Duration(days: 1)),
      );
      q = q
          .where('timestamp', isGreaterThanOrEqualTo: startTs)
          .where('timestamp', isLessThan: endTs);
    }

    return q.snapshots().map((snap) =>
        snap.docs.map((d) => Alert.fromMap(d.id, d.data())).toList()
    );
  }

  /// One-shot fetch of a page of alerts for [driverId] with optional [filter], [startDate]/[endDate], and pagination.
  Future<QuerySnapshot<Map<String, dynamic>>> fetchAlertsPage({
    required String driverId,
    required String filterType,
    int pageSize = 10,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDoc,
    DateTime? startDate,
    DateTime? endDate,
  }) {
    var q = _baseQuery(driverId: driverId, filter: filterType);

    if (startDate != null && endDate != null) {
      final startTs = Timestamp.fromDate(
        DateTime(startDate.year, startDate.month, startDate.day),
      );
      final endTs = Timestamp.fromDate(
        DateTime(endDate.year, endDate.month, endDate.day)
            .add(const Duration(days: 1)),
      );
      q = q
          .where('timestamp', isGreaterThanOrEqualTo: startTs)
          .where('timestamp', isLessThan: endTs);
    }

    q = q.limit(pageSize);
    if (startAfterDoc != null) {
      q = q.startAfterDocument(startAfterDoc);
    }

    return q.get();
  }
}
