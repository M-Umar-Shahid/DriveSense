import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/alert.dart';

class ImageAlertsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  /// Base query for a specific driver and filter.
  Query<Map<String, dynamic>> _baseQuery({
    required String driverId,
    required String filter,
  }) {
    var q = _db
        .collection('detections')
        .where('uid', isEqualTo: driverId)
        .orderBy('timestamp', descending: true)
        .withConverter<Map<String, dynamic>>(
      fromFirestore: (snap, _) => snap.data()!,
      toFirestore: (m, _) => m,
    );

    if (filter != 'All') {
      q = q.where('alertCategory', isEqualTo: filter);
    }
    return q;
  }

  /// Real-time stream of alerts for [driverId] with optional [filter].
  Stream<List<Alert>> streamAlerts({
    required String driverId,
    required String filter,
  }) {
    return _baseQuery(driverId: driverId, filter: filter)
        .snapshots()
        .map((snap) => snap.docs
        .map((d) => Alert.fromMap(d.id, d.data()))
        .toList());
  }

  /// One-shot fetch of a page of alerts for [driverId] with optional [filter].
  Future<QuerySnapshot<Map<String, dynamic>>> fetchAlertsPage({
    required String driverId,
    required String filter,
    required int pageSize,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDoc,
  }) {
    var q = _baseQuery(driverId: driverId, filter: filter).limit(pageSize);
    if (startAfterDoc != null) {
      q = q.startAfterDocument(startAfterDoc);
    }
    return q.get();
  }
}
