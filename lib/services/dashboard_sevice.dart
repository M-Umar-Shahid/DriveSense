import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/dashboard_stats.dart';
import '../models/trip.dart';

class DashboardService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> fetchUsername() async {
    final user = _auth.currentUser;
    if (user == null) return 'User';
    return user.displayName ?? user.email?.split('@').first ?? 'User';
  }

  Future<DashboardStats> fetchStats() async {
    final user = _auth.currentUser;
    if (user == null) return DashboardStats(alertCount: 0, tripCount: 0, focusPercentage: 0);
    final alertsSnap = await _db.collection('detections').where('uid', isEqualTo: user.uid).get();
    final tripsSnap = await _db.collection('trips').where('uid', isEqualTo: user.uid).get();
    int safeTrips = tripsSnap.docs.where((d) => (d['status'] as String?) == 'Safe').length;
    int totalTrips = tripsSnap.size;
    double focus = totalTrips > 0 ? safeTrips / totalTrips * 100 : 0;
    return DashboardStats(
      alertCount: alertsSnap.size,
      tripCount: totalTrips,
      focusPercentage: focus,
    );
  }

  Future<List<Trip>> fetchRecentTrips({int limit = 3}) async {
    final user = _auth.currentUser;
    if (user == null) return [];
    final snap = await _db
        .collection('trips')
        .where('uid', isEqualTo: user.uid)
        .orderBy('endTime', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((doc) {
      return Trip(
        startTime: (doc['startTime'] as Timestamp).toDate(),
        endTime: (doc['endTime'] as Timestamp).toDate(),
        alerts: doc['alerts'] as int? ?? 0,
        status: doc['status'] as String? ?? 'Unknown',
      );
    }).toList();
  }
}
