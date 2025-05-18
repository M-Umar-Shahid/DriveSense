import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/alert.dart';

class ImageAlertsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Query<Map<String, dynamic>> _baseQuery(String filter) {
    var q = _db
        .collection('detections')
        .where('uid', isEqualTo: _uid)
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

  Stream<List<Alert>> streamAlerts(String filter) {
    return _baseQuery(filter).snapshots().map((snap) {
      return snap.docs
          .map((d) => Alert.fromMap(d.id, d.data()))
          .toList();
    });
  }

  Future<QuerySnapshot<Map<String, dynamic>>> fetchAlertsPage({
    required String filter,
    required int pageSize,
    DocumentSnapshot<Map<String, dynamic>>? startAfterDoc,
  }) {
    var q = _baseQuery(filter).limit(pageSize);
    if (startAfterDoc != null) {
      q = q.startAfterDocument(startAfterDoc);
    }
    return q.get();
  }
}
