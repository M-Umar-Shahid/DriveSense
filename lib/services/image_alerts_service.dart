import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/alert.dart';

class ImageAlertsService {
  final _db = FirebaseFirestore.instance;
  String get _uid => FirebaseAuth.instance.currentUser!.uid;

  Stream<List<Alert>> streamAlerts(String filter) {
    Query q = _db.collection('detections').where('uid', isEqualTo: _uid);
    if (filter != 'All') {
      q = q.where('alertCategory', isEqualTo: filter);
    }
    q = q.orderBy('timestamp', descending: true);
    return q.snapshots().map((snap) =>
    snap.docs.map((d) {
    final data = d.data() as Map<String, dynamic>;
    return Alert.fromMap(d.id, data);
    }).toList()
    );
  }
}
